%% Drukverlies prototype
clear
%% Start tijdmeting
tic

%% Laad variabelen
P7_vars; 
P8_vars_minor_HL;

%% Dichtheid water
%   Controle bereik watertemperatuur
if T_Wk<273 || T_Wk>313
    disp(T_water)
    error('OB:Deterministic:WaterTempRange', 'Water temperature outside accepted range')
end

%   Dichtheid water (CIPM standard) 
%       Temp range 0-40 degrees celcius
a1 = -3.983035;     %[Celcius]
a2 = 301.797;       %[Celcius]
a3 = 522528.9;      %[Celcius^2]
a4 = 69.34881;      %[Celcius]
a5 = 999.974950;    %[kg/m^3]
Dens_W = a5 * (1-(((T_Wc+a1)^2 * (T_Wc+a2))/(a3*(T_Wc+a4)))); %[kg/m^3]

%% Viscositeit water
%   Dynamische viscositeit water
%       Temp range 0-80 degrees celcius
Visc_W = 2.414e-5*10^(247.8/(T_Wk-140)); %[kg/(m*s)]

%% Model input (BV K-waarde)
%Ball Valve K-waarde
k_BV_mtrx = zeros(t_end/ts,1)+200;                  %Hoogst mogelijke K-waarde
t_BV = [round(t_open+t_move*(1/3),2) ...
    round(t_open+t_move*(2/3),2) t_open+t_move];    %Tijden overeenkomend met de bekende K-waarden
k_BV = [200 5.5 0];                                 %K-waarden voor verschillende standen van de Ball Valve
t_BV_new = round(t_open+t_move*(1/3),2):ts:t_open+t_move;                 %Hoeveelheid iteraties tijdens openen
k_BV_open = interp1(t_BV,k_BV,t_BV_new);            %K_BV tijdens sluiten BV
k_BV_open = k_BV_open';                             %Transponatie
k_BV_close = flip(k_BV_open);                       %K_BV tijdens openen BV
k_BV_mtrx(round(t_open+t_move*(1/3),2)/ts:(t_open+t_move)/ts) = k_BV_open;%Invullen K-waarden openen BV in matrix 
t_opened = t_close - (t_open+t_move);               %Tijd dat de BV is geopend
k_BV_mtrx((t_open+t_move)/ts:t_close/ts)...         
    = zeros(round(t_opened/ts+1),1);                %K-waarde BV=0 invullen in matrix
k_BV_mtrx(round(t_close/ts):round(t_close+t_move*(2/3),2)/ts)...
    = k_BV_close;                                   %Invullen K-waarden sluiten BV in matrix

%% Preallocation
%HL voor turbine input sensor
HL_major_1 = zeros(t_end/ts,1);
HL_minor_1 = zeros(t_end/ts,1);
HL_1 = zeros(t_end/ts,1);

%HL tussen turbine input en output sensor
HL_major_21 = zeros(t_end/ts,1);
HL_major_22 = zeros(t_end/ts,1);
HL_major_23 = zeros(t_end/ts,1);
HL_major_24 = zeros(t_end/ts,1);
HL_minor_2 = zeros(t_end/ts,1);
HL_2 = zeros(t_end/ts,1);

%HL na turbine output sensor
HL_major_3 = zeros(t_end/ts,1);
HL_minor_3 = zeros(t_end/ts,1);
HL_3 = zeros(t_end/ts,1);

%HL totaal
HL_total = zeros(t_end/ts,1);

%Flow en snelheden
Q = zeros(t_end/ts,1);
v_outlet = zeros(t_end/ts,1);

%Overig
V_W_rigid = zeros(t_end/ts,1);
Depth_rigid = zeros(t_end/ts,1);
H_hyd_exp = zeros(t_end/ts,1);

%% Flow en head loss
%Beginwaarden
Q(1) = 0;                   %[m^3/s]
V_W_rigid(1) = 0.0210;      %[m^3]
H_hyd_exp(1) = 3.436492343; %[m]

for  i = 1:(t_end/ts)

    %Flow in turbine unit
    Q_1_3 = Q(i)*(1/3);
    Q_2_3 = Q(i)*(2/3);
   
    %Snelheid fittingen
    v4_1_1_3 =      Q_1_3/  A4_1;
    v17_5_1_3 =     Q_1_3/  A17_5;
    v22 =           Q(i)/   A22;
    v23_9 =         Q(i)/   A23_9;
    v27_2 =         Q(i)/   A27_2;
    v27_2_1_3 =     Q_1_3/  A27_2;
    v32 =           Q(i)/   A32;
    v32_1_3 =       Q_1_3/  A32;
    v32_2_3 =       Q_2_3/  A32;
    v40 =           Q(i)/   A40;
    
    %Wrijfings factor
    Re_pipe = (v27_2*D27_2*Dens_W)/Visc_W;  %[-] Reynolds number
    f_pipe = P6_FF(RR_pipe,Re_pipe);        %[-] Pipe friction factor
    
    %[m] Head loss tot turbine input sensor
    HL_major_1(i) = P2_Major_HL(L_pipe_1,D27_2,v27_2,g,f_pipe);
    HL_minor_1(i) = P3_Minor_HL1(k_cont_1,v27_2,g,N_bend90_1,...
        k_bend90_1,v22,k_elbow90_1,v32);
    HL_1(i) = HL_major_1(i) + HL_minor_1(i);
    
    %[m] Head loss tussen turbine input en output sensor
    HL_major_21(i) = P2_Major_HL(L_pipe_21,D27_2,v27_2,g,f_pipe);
    HL_major_22(i) = P2_Major_HL(L_pipe_22,D27_2,v27_2,g,f_pipe);
    HL_major_23(i) = P2_Major_HL(L_pipe_23,D27_2,v27_2,g,f_pipe);
    HL_major_24(i) = P2_Major_HL(L_pipe_24,D27_2,v27_2,g,f_pipe);
    HL_minor_2(i) = P4_Minor_HL2(N_bend90_2,N_elbow90_TU,N_cont_TU,N_enl_TU,...
    k_bend90_2,k_sbend_2,k_elbow90_TU,k_elbow90_2,k_TBR,k_TLI,k_cont_TU,k_enl_TU,...
    v4_1_1_3,v17_5_1_3,v22,v27_2_1_3,v32,v32_1_3,v32_2_3,...
    g);
    HL_2(i) = HL_major_21(i) + HL_major_22(i) + HL_major_23(i) +...
        HL_major_24(i) + HL_minor_2(i);
    
    %[m] Head loss na turbine output sensor
    HL_major_3(i) = P2_Major_HL(L_pipe_3,D27_2,v27_2,g,f_pipe);
    HL_minor_3(i) = P5_Minor_HL3(k_BV_mtrx(i),k_elbow90_3,k_enl_3,...
    v23_9,v27_2,v32,N_elbow90_3,g);   
    HL_3(i) = HL_major_3(i) + HL_minor_3(i);    
    
    %[m] Head loss totaal
    HL_total(i) = HL_1(i) + HL_2(i) + HL_3(i);  

    %[m] Waterhoogte rigide reservoir
    Depth_rigid(i) = 0.0405 + P9_WLRR_2(V_W_rigid(i));
    
    %[m^3] Volume rigide reservoir
    V_W_rigid(i+1) = V_W_rigid(i) + (Q(i)*ts);
    
    %[m] Diepte tot sensor hydrostatische druk
    H_hyd_exp(i+1) = H_hyd_exp(i) + (Q(i)*ts)/A_barge;
    
    %Berekening flow
    if k_BV_mtrx(i) >= 30 
        Q(i+1) = 0; 
        v_outlet(i+1) = 0;
    else
        
    z = (H_hyd_exp(i)-(SH_2-SH_1)-Depth_rigid(i))+(SH_2-SH_5)-HL_total(i);
    if z<0
        error('negative head')
    end
   
    v_outlet_no_interp = sqrt(z*2*g);
    x = [i (i+1/ts)];
    y = [v_outlet(i) v_outlet_no_interp];
    v_outlet(i+1) = interp1(x,y,i+1);
    Q(i+1) = v_outlet(i+1)*A40;
    end
end

%% Einde tijdmeting
toc
