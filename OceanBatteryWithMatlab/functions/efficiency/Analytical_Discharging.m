%% Overview

% 1  - Measurement compare case
% 2  - Model Timestep
% 3  - Prototype Model Parameters
% 4  - Loss Coefficient K
% 5  - Preallocation Variables
% 6  - Model Input Parameters 
% 7  - Model Timestep Calculations 
% 8  - Model Input Parameters 
% 9  - Display Calculated Analytical Values
% 10 - Loading Input Data Measurement Case
% 11 - Model Losses Calc
% 12 - Display Calculated Analytical Value
% 13 - Model Analysis - Error Calculation
% 14 - Plotting Output Figures

%% clear
%clear
%close all

%% Begin Time Measurement
tic

%% -----------------------------------------------------------------------
%                       1 - Measurement Compare Case
%  -----------------------------------------------------------------------

% %% 1 - Data Allocation
% This version uses a preconstructed dataset extracted from the experimental measurements                                               
% See line 582 for the extraction of the measurement parameters 

%% ------------------------------------------------------------------------
%                            2 - Model Timestep
%  ------------------------------------------------------------------------

% Discharge Times
t_open  = 60.5;          %[s] Time BV Open     
t_close = 660.5;         %[s] Time BV Closed
t_move  = 10;            %[s] Opening/Closing Time BV
t_end   = 700;           %[s] End test

% Timestep
ts = 0.001; %[s]


%% ------------------------------------------------------------------------
%                      3 - Prototype Model Parameters
%  ------------------------------------------------------------------------

% Constant
g            = 9.81;         %[m/s^2]  Gravity Constant 

% % Efficiency Parameters
n_P          = N_pump;         % [-]  Pump Efficiency, Default: 0.88
n_T          = N_turbine;         % [-] Turbine Efficiency, Default: 0.92
% 
% n_m         = 0.98;        % [-]  Motor Efficiency
% n_trans     = 0.99;        % [-]  Motor Efficiency
% 
% n_P         = 0.9;         %[m/s^2]  Gravity Constant
% n_T         = 0.9;         %[m/s^2]  Gravity Constant

%--------------------------------------------------------------
%----------------- Working Fluid Parameters -------------------
%--------------------------------------------------------------

%-----------------------------------
%------- Temperature Water ---------
%-----------------------------------

T_Wc        = 10;           %[C]    Water temperature celcius
T_Wk        = T_Wc + 273;   %[K]    Water temperature kelvin

%   Control range water temp
if T_Wk<273 || T_Wk>313
    disp(T_water)
    error('OB:Deterministic:WaterTempRange', 'Water temperature outside accepted range')
end

%-----------------------------------
%--------- Density Water -----------
%-----------------------------------

%   Temp range 0-40 degree celcius
a1 = -3.983035;     %[Celcius]
a2 = 301.797;       %[Celcius]
a3 = 522528.9;      %[Celcius^2]
a4 = 69.34881;      %[Celcius]
a5 = 999.974950;    %[kg/m^3]
Dens_W = a5 * (1-(((T_Wc+a1)^2 * (T_Wc+a2))/(a3*(T_Wc+a4))));               %[kg/m^3]

%-----------------------------------
%-------- Viscosity Water ----------
%-----------------------------------

%   Dynamic viscosity water
%   Temp range 0-80 degree celcius
Visc_W = 2.414e-5*10^(247.8/(T_Wk-140));                                    %[kg/(m*s)]

%------------------------------------
%----- Prototype Volume Capacity ----
%------------------------------------

% Sizes rigid reservoir and barge
% Length
Lout         = Lout;                                      %[m]    Total length outer rigid reservoir
Lin          = Lin;                                       %[m]    Total length inner rigid reservoir
L_rigid      = Lout+Lin;                                                    %[m]	Total length of the rigid reservoir

D_rigid      = D_rigid;                                                         %[m]    Diameter rigid reservoir
r_rigid      = 0.5*D_rigid;                                                 %[m]    Radius rigid reservoir
A_rigid      = pi * r_rigid^2;                                              %[m]    Surface rigid reservoir

% Barge0.315; 
A_barge      = 6*1.04;                                                      %[m^2]  Top view surface of barge.
%
%
V_rigid_in   = pi*r_rigid^2*Lin;                                            %[m^3]  Volume rigid inner
V_rigid_out  = pi*r_rigid^2*Lout;                                           %[m^3]  Volume rigide outer

%
Cap_rigid    = V_rigid_in + V_rigid_out;                                    %[m^3]  Capaciteit rigid reservoir


%----------------------------------------------------------------
%------------------ Pressure Sensor Location --------------------
%----------------------------------------------------------------

%---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
% Sensor location - relative to reference point (sensor 5 (druk rigide % reservoir))
SH_p1          = 13e-3;          %[m]    Height sensor p1    - hydrostatic pressure      location distance vs P5_T sensor location
SH_p2          = 205e-3;         %[m]    Height sensor p2    - flexible bladder          location distance vs P5_T sensor location
SH_p3          = 107e-3;         %[m]    Height sensor p3    - turbine inlet             location distance vs P5_T sensor location
SH_p4          = 15e-3;          %[m]    Height sensor p4    - turbine outlet            location distance vs P5_T sensor location
SH_p5          = 0;              %[m]    Height sensor p5_T  - rigide reservoir pump     location distance vs P5_T sensor location
SH_ref         = 0.0355;         %[m]    Height sensor ref underside of rigid reservoir above p5_T - location distance vs P5_T sensor location  

% SH_p1        = 13e-3;           %[m]    Height sensor p1    - hydrostatic pressure      location distance vs P5_T sensor location
% SH_p2        = 203e-3;          %[m]    Height sensor p2    - flexible bladder          location distance vs P5_T sensor location
% SH_p3        = 107e-3;          %[m]    Height sensor p3    - turbine inlet             location distance vs P5_T sensor location
% SH_p4        = 15e-3;           %[m]    Height sensor p4    - turbine outlet            location distance vs P5_T sensor location
% SH_p5        = 0;               %[m]    Height sensor p5_T  - rigide reservoir pump     location distance vs P5_T sensor location

%---------------------------------------------------------------
%------------ Internal Ducting System Parameters ---------------
%---------------------------------------------------------------

%------------------------------------------
%----- Ducting and Fitting Dimensions -----
%------------------------------------------

% Diameter in ascending order
D4_1            = 4.1e-3;       %[m]

D13             = 13e-3;        %[m]
D17_5           = 17.5e-3;      %[m] 

D22             = 22e-3;        %[m] 
D23_9           = 23.9e-3;      %[m] 
D25             = 25e-3;        %[m] 
D25_6           = 25.6e-3;      %[m]     
D27_2           = 27.2e-3;      %[m] 

D32             = 32e-3;        %[m] 

D40             = 40e-3;        %[m]

% Surface Area in ascending order
A4_1            = (0.5*D4_1)^2*pi;              %[m^2] 

A17_5           = (0.5*D17_5)^2*pi;             %[m^2]

A22             = (0.5*D22)^2*pi;               %[m^2]                      
A23_9           = (0.5*D23_9)^2*pi;             %[m^2] e.g. ball valve                      
A25_6           = (0.5*D25_6)^2*pi;             %[m^2]
A27_2           = (0.5*D27_2)^2 * pi;           %[m^2]                      
A25             = (0.5*D25)^2*pi;               %[m^2]                      

A32             = (0.5*D32)^2*pi;               %[m^2]
             
A40             = (0.5*D40)^2 * pi;             %[m^2]             

%------------------------------------------
%--------- Ducting Section Length ---------
%------------------------------------------

% Section Length HL1
HL1_Lpipe_1    = 1598.34e-3;                    %[m]    Length between between entrance flexible reservoir (p2) and entrance turbine (p3)

% Section Length HL2
HL2_Lpipe_21   = 771.81e-3;                     %[m]    Lengte tussen sensor "turbine ingang" en ingang turbine systeem
HL2_Lpipe_22   = 796.22e-3;                     %[m]    Lengte in turbine systeem met 1/3*Q
HL2_Lpipe_23   = 158.72e-3;                     %[m]    Lengte in turbine systeem met 2/3*Q
HL2_Lpipe_24   = 711.47e-3;                     %[m]    Lengte tussen uitgang turbine systeem en sensor "turbine uitgang"

% Section Length
HL3_Lpipe_3    = 565.02e-3;                     %[m]    Minor head loss of pipe section between exit turbine (p4) and rigid reservoir (p5).
    

L_Duct = HL1_Lpipe_1 + HL2_Lpipe_21 + HL2_Lpipe_22 + HL2_Lpipe_23 + HL2_Lpipe_24 + HL3_Lpipe_3; % Total length pipe sections
 
%-------------------------------------------------------------------------%
%------------------------------------
%---------- Pipe Roughness ----------
%------------------------------------

% Material Properties
D_pipe           = 27.2e-3;                  %[m] Pipe diameter           
AR_pipe          = 0.0015e-3;                %[m] Absolute roughness PVC (EPSILON)
RR_pipe          = AR_pipe/D_pipe;           %[-] Relatieve roughness 


%% ------------------------------------------------------------------------
%                      4 - Loss Coefficient K 
%  ------------------------------------------------------------------------

%---------------------------------------------------------
%--------------------- Ball Valve ------------------------
%---------------------------------------------------------
% k_BV = [fully closed / half-open / fully open]
k_BV = [200 5.5 0];                                                         % k-values of different states Ball Valve

%---------------------------------------------------------
%---------------- Ducting Section - HL1 ------------------
%---------------------------------------------------------
% HL_minor_1(i) = P3_Minor_HL1(HL1_contr_k, v27_2,g, HL1_90bend_n, HL1_90bend_k, v22, HL1_90elbowbend_k, v32);

% Contraction (1x)
HL1_contr_n  = 1; 
HL1_contr_k  = 0.27;               
% Connected to: 
% v27_2

% Bend 90 degrees (3x)
HL1_90bend_n  = 3;                         
HL1_90bend_k  = 0.19;       
% Connected to: 
% v22

% Elbow bend 90 degrees (1x)
HL1_90elbowbend_n  = 1;
HL1_90elbowbend_k  = 0.9;                     
% Connected to: 
% v32

%---------------------------------------------------------
%---------------- Ducting Section - HL2 ------------------
%---------------------------------------------------------
% HL_minor_2(i)  =
% P4_Minor_HL2(HL2_90bend_n,HL2_TU_90elbowbend_n,HL2_TU_contr_n,HL2_TU_enl_n,HL2_90bend_k,HL2_Sbend_k,HL2_TU_90elbowbend_k,HL2_90elbowbend_k,...
% HL2_TU_TBR_k,HL2_TU_TLI_k,HL2_TU_contr_k,HL2_TU_enl_k,v4_1_1_3,v17_5_1_3,v22,v27_2_1_3,v32,v32_1_3,v32_2_3, g);

% Bend 90 graden (5x)
HL2_90bend_n  = 5;
HL2_90bend_k  = 0.19;
% Connected to: 
% v22 

% S-Bend  (1x)
HL2_Sbend_n  = 1;
k_bend45     = 0.4;
% *Assuming k-value s-bend = 2 x 45 degree bend

HL2_Sbend_k  = 2*k_bend45;
% Connected to: 
% v22

% Elbow bend 90 degrees (1x)
HL2_90elbowbend_n  = 1;
HL2_90elbowbend_k  = 0.9;
% Connected to: 
% v32

%---------- Turbine Unit ----------%

% Turbine T-Branch  (4x)
HL2_TU_TBR_k  = 1.8;
% Connected to: 
% TU 1 - v17_5_1_3
% TU 2 - v17_2_1_3
% TU 3 - v27_2_1_3
% TU 4 - v27_2_1_3

% TU connection line piece (4x)
HL2_TU_TLI_k  = 0.4;
% Connected to: 
% TU 1 - v32_2_3    
% TU 2 - v32_1_3    
% TU 3 - v32_2_3    
% TU 4 - v32^2     

% TU elbow bend 90 degrees (2x)
HL2_TU_90elbowbend_n  = 2;
HL2_TU_90elbowbend_k  = 0.9;
% Connected to: 
% v32_1_3

% TU contraction (3x)
HL2_TU_contr_n  = 3;
HL2_TU_contr_k  = 0.005;
% Connected to: 
% v4_1_1_3

% TU enlargement (3x)
HL2_TU_enl_n  = 3;     
HL2_TU_enl_k  = 0.3;
% Connected to: 
% v4_1_1_3


%---------------------------%

%---------------------------------------------------------
%---------------- Ducting Section - HL3 ------------------
%---------------------------------------------------------
% HL_minor_3(i) = P5_Minor_HL3(k_BV_mtrx(i),HL3_90elbow_k,HL3_enl_k, v23_9,v27_2,v32,HL3_90elbow_n,g); 
   
% Elbow bend 90 degree (2x)
HL3_90elbow_n  = 2;
HL3_90elbow_k  = 0.9;
% Connected to: 
% v32^2

% Enlargement (1x)
HL3_enl_n  = 1;
HL3_enl_k  = 0.41;
% Connected to: 
% v27_2


%% ------------------------------------------------------------------------
%                      5 - Preallocation Variables
%  ------------------------------------------------------------------------

%//////////////////////////////////////////////////
% Set Array
%//////////////////////////////////////////////////

%---------------------------------------------------------
%-------------------- Volume and Flow --------------------
%---------------------------------------------------------

% Flow en velocity 
Q           = zeros(t_end/ts,1);                                            % Creating Array for
v_outlet    = zeros(t_end/ts,1);                                            % Creating Array for

% Other
V_W_rigid   = zeros(t_end/ts,1);                                            % Creating Array for
Depth_rigid = zeros(t_end/ts,1);                                            % Creating Array for
H_hyd_exp   = zeros(t_end/ts,1);                                            % Creating Array for

Output_Power     = zeros(t_end/ts,1);                                       % Creating Array

k_BV_mtrx   = zeros(t_end/ts,1)+ 200;                                       % Creating Array for ball-valve k-value over time

%---------------------------------------------------------
%---------------- Ducting Section - HL1 ------------------
%---------------------------------------------------------
% HL1 - between between entrance flexible reservoir (p2) and entrance turbine (p3)
HL_major_1  = zeros(t_end/ts,1);                                            % Creating Array for 
HL_minor_1  = zeros(t_end/ts,1);                                            % Creating Array for 
HL_1_Total  = zeros(t_end/ts,1);                                            % Creating Array for 

%---------------------------------------------------------
%---------------- Ducting Section - HL2 ------------------
%---------------------------------------------------------
% HL2 - between between entrance turbine (p3) and exit turbine (p4)
HL_major_21 = zeros(t_end/ts,1);                                            % Creating Array for 
HL_major_22 = zeros(t_end/ts,1);                                            % Creating Array for 
HL_major_23 = zeros(t_end/ts,1);                                            % Creating Array for 
HL_major_24 = zeros(t_end/ts,1);                                            % Creating Array for 
HL_minor_2  = zeros(t_end/ts,1);                                            % Creating Array for  
HL_2_Total  = zeros(t_end/ts,1);                                            % Creating Array for 

%---------------------------------------------------------
%---------------- Ducting Section - HL3 ------------------
%---------------------------------------------------------
% HL3 - between between exit turbine (p4) and entrance rigid reservoir (p5)
HL_major_3  = zeros(t_end/ts,1);                                            % Creating Array for 
HL_minor_3  = zeros(t_end/ts,1);                                            % Creating Array for 
HL_3_Total  = zeros(t_end/ts,1);                                            % Creating Array for 
f_pipe = zeros(t_end/ts,1);
%---------------------------------------------------------
%----------------------- HL Total-------------------------
%---------------------------------------------------------

% HL  total
HL_total    = zeros(t_end/ts,1);                                            % Creating Array for 

%--------------------------------------------------------------------------------------

H_static  = zeros(t_end/ts,1);                                              % Creating Array for 
v_outlet_no_interp = zeros(t_end/ts,1);                                     % Creating Array for 
z = zeros(t_end/ts,1);                                                      % Creating Array for 
H_dyn = zeros(t_end/ts,1);                                                  % Creating Array for 

%% ------------------------------------------------------------------------
%                      6 - Model Input Parameters
%  ------------------------------------------------------------------------


%--------------------------------------------
%------------ Ball Valve Input --------------
%--------------------------------------------

% Set Ball Valve Behaviour Opening
t_BV = [round(t_open+t_move*(1/3),2) round(t_open+t_move*(2/3),2) t_open+t_move];        % Times Determining Behaviour of BV reacting on Signal corresponding to K_BV values
t_BV_new = round(t_open+t_move*(1/3),2):ts:t_open+t_move;                                % Amount of iterations between opening and fully open
t_opened   = t_close - (t_open+t_move);                                                  % Time BV fully opened
k_BV_open  = interp1(t_BV,k_BV,t_BV_new);                                                % k_BV behaviour Opening BV 

% Set Ball Valve Behaviour Closing
k_BV_open  = k_BV_open';                                                                 % Transponing
k_BV_close = flip(k_BV_open);                                                            % k_BV behaviour Closing BV 


% Filling up Matrix BV  
k_BV_mtrx(round(t_open+t_move*(1/3),2)/ts:(t_open+t_move)/ts) = k_BV_open;               % Filling up k-values opening BV in matrix 
k_BV_mtrx((t_open+t_move)/ts:t_close/ts) = zeros(round(t_opened/ts+1),1);                % Filling up k-values BV=0 in matrix
k_BV_mtrx(round(t_close/ts):round(t_close+t_move*(2/3),2)/ts) = k_BV_close;              % Filling up k-values closing BV in matrix

%% ------------------------------------------------------------------------
%                      7 - Model Timestep Calculations
%  ------------------------------------------------------------------------

t = 1:t_end/ts;
t = t';
t_2 = t.*ts;

Q(1) = 0;                       % [m^3/s] Starting volumetric flow at t=0
V_W_rigid(1) = 0.0210;          % [m^3] Starting volume rigid reservoir at t=0
H_hyd_exp(1) = 3.4485;          % [m] Starting Hydraulic Head at t=0 mean (H_hyd_Data)
R_WL_start = 0.0405;            % [m] Starting water level in rigid reservoir

%//////////////////////////////////////////////////
% Fill Array
%//////////////////////////////////////////////////

for  i = 1:(t_end/ts)
    
    
    %---------------------------------------------------------
    %---------------- Flow Velocity Turbine ------------------
    %---------------------------------------------------------
    
    %Flow in turbine unit
    Q_1_3 = Q(i)*(1/3);                                                     
    Q_2_3 = Q(i)*(2/3);                                                     
    
    
    %---------------------------------------------------------
    %---------------- Flow Velocity Ducting ------------------
    %---------------------------------------------------------
    
    v4_1_1_3 =      Q_1_3 /  A4_1;
    
    v17_5_1_3 =     Q_1_3 /  A17_5;
    
    v22 =           Q(i)  /  A22;
    v23_9 =         Q(i)  /  A23_9;
    v27_2 =         Q(i)  /  A27_2;
    v27_2_1_3 =     Q_1_3 /  A27_2;
    
    v32 =           Q(i)  /  A32;
    v32_1_3 =       Q_1_3 /  A32;
    v32_2_3 =       Q_2_3 /  A32;
    
    
    v40 =           Q(i)  /  A40;
    
    %---------------------------------------------------------
    %----------------- Friction Coefficient ------------------
    %---------------------------------------------------------
    
    Re_pipe = (v27_2*D27_2*Dens_W)/Visc_W;                                  % [-] Reynolds number
    f_pipe(i) = P6_FF(RR_pipe,Re_pipe);                                     % [-] Pipe friction factor
    
    %---------------------------------------------------------
    %------------------ Head Loss Ducting --------------------
    %---------------------------------------------------------
    
    %-------- Ducting Section - HL1 ----------
    % HL1 - between between entrance flexible reservoir (p2) and entrance turbine (p3)
    HL_major_1(i) = P2_Major_HL(HL1_Lpipe_1,D27_2,v27_2,g,f_pipe(i));
    HL_minor_1(i) = P3_Minor_HL1(HL1_contr_k, v27_2,g, HL1_90bend_n, HL1_90bend_k, v22, HL1_90elbowbend_k, v32);
    
    HL_1_Total(i) = HL_major_1(i) + HL_minor_1(i);
    
    %-------- Ducting Section - HL2 ----------
    % HL2 - between between entrance turbine (p3) and exit turbine (p4)
    HL_major_21(i) = P2_Major_HL(HL2_Lpipe_21,D27_2,v27_2,g,f_pipe(i));
    HL_major_22(i) = P2_Major_HL(HL2_Lpipe_22,D27_2,v27_2,g,f_pipe(i));
    HL_major_23(i) = P2_Major_HL(HL2_Lpipe_23,D27_2,v27_2,g,f_pipe(i));
    HL_major_24(i) = P2_Major_HL(HL2_Lpipe_24,D27_2,v27_2,g,f_pipe(i));
    
    HL_minor_2(i)  = P4_Minor_HL2(HL2_90bend_n,HL2_TU_90elbowbend_n,HL2_TU_contr_n,HL2_TU_enl_n,HL2_90bend_k,HL2_Sbend_k,HL2_TU_90elbowbend_k,HL2_90elbowbend_k,HL2_TU_TBR_k,HL2_TU_TLI_k,HL2_TU_contr_k,HL2_TU_enl_k,...
    v4_1_1_3,v17_5_1_3,v22,v27_2_1_3,v32,v32_1_3,v32_2_3, g);
    
    HL_2_Total(i) = HL_major_21(i) + HL_major_22(i) + HL_major_23(i) + HL_major_24(i) + HL_minor_2(i);
    
    %-------- Ducting Section - HL3 ----------
    % HL3 - between between exit turbine (p4) and entrance rigid reservoir (p5)
    HL_major_3(i) = P2_Major_HL(HL3_Lpipe_3,D27_2,v27_2,g,f_pipe(i));
    HL_minor_3(i) = P5_Minor_HL3(k_BV_mtrx(i),HL3_90elbow_k,HL3_enl_k, v23_9,v27_2,v32,HL3_90elbow_n,g);   
    
    HL_3_Total(i) = HL_major_3(i) + HL_minor_3(i);    
    
    %----------- Head Loss Total -------------
    %[m] Total Head Loss
    HL_total(i) = HL_1_Total(i) + HL_2_Total(i) + HL_3_Total(i);  

    %---------------------------------------------------------
    %-------------------- Dynamic Head -----------------------
    %---------------------------------------------------------
    %[m] Waterheight rigid reservoir
    
    Depth_rigid(i) = R_WL_start + P9_VRIGID_Proto(V_W_rigid(i),D_rigid,r_rigid,Cap_rigid,L_rigid);
    
    %[m^3] Volume rigid reservoir
    V_W_rigid(i+1) = V_W_rigid(i) + (Q(i)*ts);
    
    %[m] Depth to sensor hydrostatic pressure
    H_hyd_exp(i+1) = H_hyd_exp(i) + (Q(i)*ts)/A_barge;
    
    %---------------------------------------------------------
    %-------- Volumetric Flow Calculation Ball Valve ---------
    %---------------------------------------------------------
    
    % Calculating Ball Valve Open %
    % Ball Valve Check
    if k_BV_mtrx(i) >= 30 
        Q(i+1) = 0; 
        v_outlet(i+1) = 0;
    else
   
    % Head calculation at point at height of  Ball-Valve exit into rigid reservoir accounting for water level rise in rigid reservoir and total headloss
    z(i)                   = H_hyd_exp(i)             + ( SH_p1 - SH_p4 )                 - ( HL_total(i) )     -   (Depth_rigid(i) - SH_p4); 
    
    % Negative Head Check
    if z(i)<0
        error('OB:Deterministic:NegativeHead', 'negative head')
    end
    
    v_outlet_no_interp(i) = sqrt(z(i)*2*g);                                 % Defining new fluid velocity value based on the new head over turbine updated for dynamic head (water level rise in rigid reservoir and total headloss)
    x = [i (i+1/ts)];                                                       % Defining current and subsequent timestep
    y = [v_outlet(i) v_outlet_no_interp(i)];                                % Defining current and subsequently calculated fluid velocity
    v_outlet(i+1) = interp1(x,y,i+1);                                       % Interpolate fluid velocity             
    Q(i+1) = v_outlet(i+1)*A40;                                             % Calculate new volumetric flow
            
    end

end

%---------------------------------------------------------
%------------------ Head Loss Ducting --------------------
%---------------------------------------------------------

O = Q  /  A27_2;
O(end) = [];
Re = (O*D27_2*Dens_W)/Visc_W;

Q_2 = Q.*1000;  %[l/s] Flow
Q_2(end) = [];  % Removing last element flow vector



%---------------------------------------------------------
%------------------ Head Loss Ducting --------------------
%---------------------------------------------------------

h_s         = H_hyd_exp;        
h_s(end)    = [];          % removing last element static head
   

H_blad_exp      = h_s + (SH_p1-SH_p2);                                      %Flexible Bladder head           (SH_p1-SH_p2) = (P5_T-P1)-(p5_T+p2) = (p2 - P1)
H_Tin_exp       = H_blad_exp - HL_1_Total + (SH_p2-SH_p3);                  %Head turbine inlet side         (SH_p2-SH_p3) = (P5_T-P2)-(p5_T+p3) = (p3 - P2)
H_Tout_exp      = H_Tin_exp - HL_2_Total + (SH_p3-SH_p4);                   %Head turbine outlet side        (SH_p3-SH_p4) = (P5_T-P3)-(p5_T+p4) = (p4 - P3)
H_R_exp         = Depth_rigid;                                              %Head rigid reservoir           


%% ------------------------------------------------------------------------
%                      09 - Loading Input Data Measurement Case
%  ------------------------------------------------------------------------

% Laden data
Q_MData = xlsread('Data_raw.xlsx',1,'B2:B70001');  %[l/s] Flow
Q_MData(isnan(Q_MData))=0;
Q_M_real = Q_MData;


H_hyd_MData = xlsread('Data_raw.xlsx',1,'D2:D70001');   %[m] Hydrostatic pressure head
H_hyd_MData(isnan(H_hyd_MData))=0;
H_M_hyd = H_hyd_MData;

H_blad_MData = xlsread('Data_raw.xlsx',1,'E2:E70001');  %[m] Flexible Bladder head
H_blad_MData(isnan(H_blad_MData))=0;
H_M_blad = H_blad_MData;

H_Tin_MData = xlsread('Data_raw.xlsx',1,'F2:F70001');   %[m] Turbine input head
H_Tin_MData(isnan(H_Tin_MData))=0;
H_M_Tin = H_Tin_MData;

H_Tout_MData = xlsread('Data_raw.xlsx',1,'G2:G70001');  %[m] Turbine output head
H_Tout_MData(isnan(H_Tout_MData))=0;
H_M_Tout = H_Tout_MData;

H_Rin_MData = xlsread('Data_raw.xlsx',1,'H2:H70001');   %[m] Rigid inner head
H_Rin_MData(isnan(H_Rin_MData))=0;
H_M_Rin = H_Rin_MData;

H_Rout_MData = xlsread('Data_raw.xlsx',1,'I2:I70001');  %[m] Rigid outer head
H_Rout_MData(isnan(H_Rout_MData))=0;
H_M_Rout = H_Rout_MData;

%-----------------------------------%
% Interpolation Experimental Measurements
%-----------------------------------%
t_emp = 1:height(Q_M_real);                   % Current Iterations size
int_step = height(Q_M_real)/height(t_2);      % Interpolation step size
t_emp_new = 0.01:int_step:height(Q_M_real);   % Calculating size based on interpolation step size 

Q_int_emp = (interp1(t_emp,Q_M_real,t_emp_new))';

p1_int_emp = (interp1(t_emp,H_M_hyd,t_emp_new))';
p2_int_emp = (interp1(t_emp,H_M_blad,t_emp_new))';
p3_int_emp = (interp1(t_emp,H_M_Tin,t_emp_new))';
p4_int_emp = (interp1(t_emp,H_M_Tout,t_emp_new))';
p5_RTint_emp = (interp1(t_emp,H_M_Rin,t_emp_new))';
p5_RPint_emp = interp1(t_emp,H_M_Rout,t_emp_new)';

%-----------------------------------%
% Experimental Measurement Parameters
%-----------------------------------%
Q_emp     =   Q_int_emp;

p1_emp    =   p1_int_emp        +0.159-0.182;          %  Hydrodynamic                    
p2_emp    =   p2_int_emp        +0.159+0.01;           %  Bladder
p3_emp    =   p3_int_emp        +0.159-0.088;          %  Tin
p4_emp    =   p4_int_emp        +0.159-0.180;          %  Tout
p5_RT_emp =   p5_RTint_emp      +0.159-0.1945;         %  Rigid inner
p5_RP_emp =   p5_RPint_emp      +0.159-0.1945;         %  Rigid outer

% % % Calibrating for p1 (extracted from meanp1_2)
% cf = 1;
% order = 1;
% Hz = 100;
% % 
% % Calibrating for p1 extracted from p2 measurements at idle time
% p1_2c_emp   = mean((bf(Hz,cf,order,p2_emp(10000:60000)-p1_emp(10000:60000))));                    % Calibrating hydrostatic pressure 
% 
% p1c_emp     = bf(Hz,cf,order,p1_emp) + p1_2c_emp;           %  Hydrodynamic                             
% p2c_emp     = bf(Hz,cf,order,p2_emp);                       %  Bladder
% p3c_emp     = bf(Hz,cf,order,p3_emp);                       %  Tin
% p4c_emp     = bf(Hz,cf,order,p4_emp);                       %  Tout
% p5_Tc_emp   = bf(Hz,cf,order,p5_RT_emp);                    %  Rigid inner
% p5_Pc_emp   = bf(Hz,cf,order,p5_RP_emp);                    %  Rigid inner
%  
% Qc_emp    = bf(Hz,0.1,1,Q_emp);

% %-------------------------------------------------------%  


%% ------------------------------------------------------------------------
%                      10 - Loading Input Data Measurement Case
%  ------------------------------------------------------------------------
% Info:
% From Getdata2 - Sensor location 
% p1           = p1+0.159-0.182;                                 % [m] Distance p1 (Hydrostatic Sensor) from top plate = 0.182 [m]
% p2           = p2+0.159+0.01;                                  % [m] Distance p2 (Flexible Bladder) from top plate = 0.01 [m] (thickness bottom plate)
% p3           = p3+0.159-0.088;                                 % [m] Distance p3 (Turbine Input) from top plate = 0.088 [m]
% p4           = p4+0.159-0.180;                                 % [m] Distance p4 (Turbine Output) from top plate = 0.188 [m]
% p5_P         = p5_P+0.159-0.1945;                              % [m] Distance p5_P (Rigid Outer Pump Side) from top plate = 0.1945 [m]
% p5_T         = p5_T+0.159-0.1945;                              % [m] Distance p5_T (Rigid Inner Turbine Side) from top plate = 0.1945 [m]
%  ------------------------------------------------------------------------

%-----------------------------------%
% Analytical Model Parameters
%-----------------------------------%
p1_analytic       = h_s;
p2_analytic       = H_blad_exp;
p3_analytic       = H_Tin_exp;
p4_analytic       = H_Tout_exp;
p5_R_analytic     = H_R_exp;

p1_analytic2      = h_s                +0.159  -0.182;
p2_analytic2      = H_blad_exp         +0.159  +0.01;
p3_analytic2      = H_Tin_exp          +0.159  -0.088;
p4_analytic2      = H_Tout_exp         +0.159  -0.180;
p5_R_analytic2    = H_R_exp            +0.159  -0.1945;

% p1_analytic      = H_hyd_exp_2        +0.159  -0.182;
% p2_analytic      = H_blad_exp         +0.159  +0.01;
% p3_analytic      = H_Tin_exp          +0.159  -0.088;
% p4_analytic      = H_Tout_exp         +0.159  -0.180;
% p5_R_analytic    = H_R_exp            +0.159  -0.1945;


%% ------------------------------------------------------------------------
%                     11 - Model Losses Calc
%  ------------------------------------------------------------------------ 

% Efficiency Parameters
% n_P              = 0.88;                         % [-]  Pump Efficiency
% n_T              = 0.92;                         % [-]  Turbine Efficiency
n_flex = 0.99;
n_umb  = 1;

Hydr_mean            = round(mean(H_hyd_exp),2);                                % Mean dynamic head 1
HL_meantotal_loss    = round(mean (HL_1_Total(100000:600000) + HL_3_Total(100000:600000)),2);                 % Mean Total losses in ducting system HL1 + HL3
HL_meantotal_loss2   = round(mean (HL_1_Total(100000:600000) + HL_3_Total(100000:600000)),2);                % Mean Total losses in ducting system HL1 + HL3

n_duct               =  (Hydr_mean - HL_meantotal_loss) / (Hydr_mean);
n_duct2              =  (Hydr_mean - HL_meantotal_loss2) / (Hydr_mean);
%  ------------------------------------------------------------------------
n_C                  = n_P  * n_umb * n_duct * n_flex;           % Overall efficiency during Charging
n_D                  = n_flex * n_duct  * n_T * n_umb;           % Overall efficiency during Discharging
n_Total              = n_C * n_D;                                % Total Efficiency 1 cycle 
