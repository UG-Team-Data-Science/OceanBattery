function [H_loss_total_discharging, H_loss_minor_discharging, H_loss_major_discharging, H_loss_major_umbilical_discharging, H_loss_minor_umbilical_discharging,...
            H_static_discharging, H_turbine, Q_turbine, V_wat_rigid_discharging, V_wat_bladder, P_generator, N_roundtrip, T_empty_discharging, E_elec_out_kWh, i]=Discharging(OB_GUI_parameters,V_wat_rigid_charging,E_elec_in_J, opts)
%% DISCHARGING MODEL
%   This model simulates the discharging phase of the Ocean Battery.

%% Charging the Ocean Battery 
% Charging; %Runs the charging script. 

if nargin < 4 || isempty(opts)
    opts = struct();
end
on_json = [];
if isstruct(opts) && isfield(opts, 'on_json') && ~isempty(opts.on_json)
    on_json = opts.on_json;
end
do_plot = true;
if isstruct(opts) && isfield(opts, 'plot') && ~isempty(opts.plot)
    do_plot = logical(opts.plot);
end

%% Setting parameters
OB_parameters; %Sets the parameters specified in OB parameters.

%% Initial calculations
A_turbine = pi * (0.5*D_turbine)^2; %[m^2] Area of the turbine outlet.
Interp_steps = (1/Delta_t)+1; %Calculates the required amount of steps between two seconds based on Delta_t. Is used in interpolation. 
startup_steps = (1/Delta_t)*t_open_ball_valve; %[-] Number of iterations that passes while the ball valve opens up.

%% Model initialization
i = 1; %Initial value for i.
V_wat_bladder(1) = V_wat_rigid_charging(1)-V_wat_rigid_charging(end) + (Capacity_rigid - V_wat_rigid_charging(1)); %[m^3] Initial value for the volume of water present in the bladder.
Q_turbine_a(1) = 2.6e-3; %[m^3/s] Initial guess of the flow throught the turbine. 

%% Overshoot correction
%   The volume that is left in the reservoir is almost always a negative
%   number because charging script slightly "overshoots" the emptying of 
%   the rigid reservoir. This if-statement ensures that the starting volume
%   of the rigid reservoir is either zero (empty) or larger than zero. 
if V_wat_rigid_charging(end) < 0
    V_wat_rigid_discharging(1) = 0;
else
    V_wat_rigid_discharging(1) = V_wat_rigid_charging(end);
end

%% Reality check
if V_wat_bladder(1) < V_wat_bladder_end
    error('ERROR: End volume of the bladder exceeds the starting volume of the bladder during the discharge phase. Impossible situation.');
end

%% Calculation of the starting flow
%   The behaviour of the system during the first "t_open_ball_valve" 
%   seconds of operation is calculated. "t_open_ball_valve" seconds is the 
%   time required to open the ball valve. When the ball valve is fully 
%   opened, the "startup-phase" is completed. The flow (Q_turbine) after 12
%   seconds will be used to model this phase. The startup is assumed to be
%   instant in this part. 

for i = 1:startup_steps
    %[m] Major head loss of the discharging phase.
    H_loss_major_discharging(i) = Major_head_loss_discharging(Q_turbine_a(i), OB_GUI_parameters);
    
    %[m] Minor head loss of the discharging phase.
    H_loss_minor_discharging(i) = Minor_head_loss_discharging(Q_turbine_a(i),OB_GUI_parameters);   

    %[m] Major head loss umbilical cord during the discharging phase. 
    H_loss_major_umbilical_discharging(i) = Major_head_loss_umbilical(Q_turbine_a(i), OB_GUI_parameters);
    
    %[m] Minor head loss umbilical cord during the discharging phase.
    H_loss_minor_umbilical_discharging(i) = Minor_head_loss_umbilical(Q_turbine_a(i), OB_GUI_parameters);
    
    %[m] Total head loss of the discharging phase.
    H_loss_total_discharging(i) = H_loss_major_discharging(i)  + H_loss_minor_discharging(i) + H_loss_major_umbilical_discharging(i) + H_loss_minor_umbilical_discharging(i);
    
    %[m] Vertical difference between the surface of the water in the rigid reservoir and the
    %surface of the body of water above the system.
    H_static_discharging(i) = Depth - Water_level_rigid_reservoir(V_wat_rigid_discharging(i), D_rigid, Capacity_rigid); 
    
    if H_static_discharging(i)<H_loss_total_discharging(i)
        error('ERROR: Head loss is larger than the static head. The system will not work because of too much losses.');
    end
    
    %[m] Head on the turbine (this does not yet include the losses incurred in the turbine). 
    H_turbine(i) = H_static_discharging(i) - H_loss_total_discharging (i);
    
    %[m] Head loss of the turbine.
    H_loss_turbine(i) = H_turbine(i)*N_turbine;
    
    %[m] Final head. This is the head that determines the flow through the turbine. The head loss of the turbine is included here. 
    H_final(i) = H_turbine(i) - H_loss_turbine(i);
        
    %[m^3] Volume of water present in the rigid reservoir.
    V_wat_rigid_discharging(i+1) = V_wat_rigid_discharging(i) + (Q_turbine_a(i)*Delta_t);
    
    %[m^3/s] Volumetric flowrate through the turbine. 
    Q_turbine_no_interp = A_turbine * sqrt(2*g*H_final(i)); %[m^3/s] Calculates the volumetric flowrate 1 second after the current flowrate. 
    x = [i i+1]; %Creates vector x. This vector contains the current loop number (i) and the next interation number (i+1).
    y = [Q_turbine_a(i) Q_turbine_no_interp]; %Creates vector y. This vector contains the current flowrate and the flowrate one second later.
    t_new = linspace(i, i+1, Interp_steps); %Creates vector t_new. This vector contains a number of points (Interp_steps) between i and i+1.
    Q_turbine_interp = interp1(x,y,t_new); %Linear interpolation between the current flowrate and the flowrate one second later. The number of points is specified by t_new.
    Q_turbine_a(i+1) = Q_turbine_interp(2); %[m^3/s] Takes the second value of matrix Q_turbine_interp. This is an estimation of the flowrate Delta_t seconds after the current flowrate.  
end

%% Flow during the startup phase
%   A liniar line is plotted between 0 and the flow (Q_turbine) after 
%   "t_open_ball_valve" seconds. This represents the increasing flow due to
%   the opening of the ball valve. This "startup phase" is assumed to be 
%   linear. 
Q_turbine = linspace(0,Q_turbine_a(startup_steps),startup_steps); %[m^3/s] Linear line between 0 and Q_turbine after "t_open_ball_valve" seconds. 

%% Other parameters during startup phase
%   The other parameters during the startup phase are determined in this
%   for loop, based on the flow throught the turbine during the first 
%   "t_open_ball_valve" seconds of operation.  

for i = 1:startup_steps
    %[m] Major head loss of the discharging phase.
    H_loss_major_discharging(i) = Major_head_loss_discharging(Q_turbine(i), OB_GUI_parameters);
    
    %[m] Minor head loss of the discharging phase.
    H_loss_minor_discharging(i) = Minor_head_loss_discharging(Q_turbine(i),OB_GUI_parameters);   

    %[m] Major head loss umbilical cord during the discharging phase. 
    H_loss_major_umbilical_discharging(i) = Major_head_loss_umbilical(Q_turbine(i), OB_GUI_parameters);

    %[m] Minor head loss umbilical cord during the discharging phase.
    H_loss_minor_umbilical_discharging(i) = Minor_head_loss_umbilical(Q_turbine(i), OB_GUI_parameters);   
    
    %[m] Total head loss of the discharging phase.
    H_loss_total_discharging(i) = H_loss_major_discharging(i)  + H_loss_minor_discharging(i) + H_loss_major_umbilical_discharging(i) + H_loss_minor_umbilical_discharging(i);
    
    %[m] Vertical difference between the surface of the water in the rigid reservoir and the
    %surface of the body of water above the system.
    H_static_discharging(i) = Depth - Water_level_rigid_reservoir(V_wat_rigid_discharging(i), D_rigid, Capacity_rigid); 
    
    if H_static_discharging(i)<H_loss_total_discharging(i)
        error('ERROR: Head loss is larger than the static head. The system will not work because of too much losses.');
    end
    
    %[m] Head on the turbine (this does not yet include the losses incurred in the turbine). 
    H_turbine(i) = H_static_discharging(i) - H_loss_total_discharging (i);
    
    %[m] Head loss of the turbine.
    H_loss_turbine(i) = H_turbine(i)*N_turbine;
    
    %[m] Final head. This is the head that determines the flow through the turbine. The head loss of the turbine is included here. 
    H_final(i) = H_turbine(i) - H_loss_turbine(i);
    
    %[W] Mechanical output power of the turbine 
    %REMARK: check this equation, the efficiency of the turbine might be
    %taken into account two times. One time while calculating the flow and
    %one time in the equation below. 
    P_turbine(i) = Q_turbine(i)* H_turbine(i) * Dens_wat * g * N_turbine; 
    
    %[W] Electrical power produced by the generator. 
    P_generator(i) = P_turbine(i) * N_generator;
        
    %[m^3] Volume of water present in the rigid reservoir.
    V_wat_rigid_discharging(i+1) = V_wat_rigid_discharging(i) + (Q_turbine(i)*Delta_t);
    
    %[m^3] Volume of water present in the bladder. 
    V_wat_bladder (i+1) = V_wat_bladder(i) - (Q_turbine(i)*Delta_t);   

    if ~isempty(on_json)
        t = (i-1) * Delta_t;
        on_json(struct( ...
            'type','timeseries', ...
            'phase','discharging', ...
            't',t, ...
            'H_loss_total',H_loss_total_discharging(i), ...
            'H_loss_major',H_loss_major_discharging(i), ...
            'H_loss_minor',H_loss_minor_discharging(i), ...
            'H_loss_major_umbilical',H_loss_major_umbilical_discharging(i), ...
            'H_loss_minor_umbilical',H_loss_minor_umbilical_discharging(i), ...
            'H_static',H_static_discharging(i), ...
            'H_turbine',H_turbine(i), ...
            'Q',Q_turbine(i), ...
            'V_rigid',V_wat_rigid_discharging(i), ...
            'V_bladder',V_wat_bladder(i), ...
            'P_generator',P_generator(i)));
    end
end

%% While loop
%   The behaviour of the system after the "startup phase" is described by
%   this while loop. 
while  V_wat_bladder(i) > V_wat_bladder_end 
       
    %[m] Major head loss of the discharging phase.
    H_loss_major_discharging(i) = Major_head_loss_discharging(Q_turbine(i), OB_GUI_parameters);
    
    %[m] Minor head loss of the discharging phase.
    H_loss_minor_discharging(i) = Minor_head_loss_discharging(Q_turbine(i),OB_GUI_parameters);   

    %[m] Major head loss umbilical cord during the discharging phase. 
    H_loss_major_umbilical_discharging(i) = Major_head_loss_umbilical(Q_turbine(i), OB_GUI_parameters);
    
    %[m] Minor head loss umbilical cord during the discharging phase.
    H_loss_minor_umbilical_discharging(i) = Minor_head_loss_umbilical(Q_turbine(i), OB_GUI_parameters);       
    
    %[m] Total head loss of the discharging phase.
    H_loss_total_discharging(i) = H_loss_major_discharging(i)  + H_loss_minor_discharging(i) + H_loss_major_umbilical_discharging(i) + H_loss_minor_umbilical_discharging(i);
    
    %[m] Vertical difference between the surface of the water in the rigid reservoir and the
    %surface of the body of water above the system.
    H_static_discharging(i) = Depth - Water_level_rigid_reservoir(V_wat_rigid_discharging(i), D_rigid, Capacity_rigid); 
    
    if H_static_discharging(i)<H_loss_total_discharging(i)
        error('ERROR: Head loss is larger than the static head. The system will not work because of too much losses.');
    end
    
    %[m] Head on the turbine (this does not yet include the losses incurred in the turbine). 
    H_turbine(i) = H_static_discharging(i) - H_loss_total_discharging (i);
    
    %[m] Head loss of the turbine.
    H_loss_turbine(i) = H_turbine(i)*N_turbine;
    
    %[m] Final head. This is the head that determines the flow through the turbine. The head loss of the turbine is included here. 
    H_final(i) = H_turbine(i) - H_loss_turbine(i);
    
    %[W] Mechanical output power of the turbine 
    %REMARK: check this equation, the efficiency of the turbine might be
    %taken into account two times. One time while calculating the flow and
    %one time in the equation below. 
    P_turbine(i) = Q_turbine(i)* H_turbine(i) * Dens_wat * g * N_turbine; 
    
    %[W] Electrical power produced by the generator. 
    P_generator(i) = P_turbine(i) * N_generator;
        
    %[m^3] Volume of water present in the rigid reservoir.
    V_wat_rigid_discharging(i+1) = V_wat_rigid_discharging(i) + (Q_turbine(i)*Delta_t);
    
    %[m^3] Volume of water present in the bladder. 
    V_wat_bladder (i+1) = V_wat_bladder(i) - (Q_turbine(i)*Delta_t);
    
    %[m^3/s] Volumetric flowrate through the turbine. 
    Q_turbine_no_interp = A_turbine * sqrt(2*g*H_final(i)); %[m^3/s] Calculates the volumetric flowrate 1 second after the current flowrate. 
    x = [i i+1]; %Creates vector x. This vector contains the current loop number (i) and the next interation number (i+1).
    y = [Q_turbine(i) Q_turbine_no_interp]; %Creates vector y. This vector contains the current flowrate and the flowrate one second later.
    t_new = linspace(i, i+1, Interp_steps); %Creates vector t_new. This vector contains a number of points (Interp_steps) between i and i+1.
    Q_turbine_interp = interp1(x,y,t_new); %Linear interpolation between the current flowrate and the flowrate one second later. The number of points is specified by t_new.
    Q_turbine(i+1) = Q_turbine_interp(2); %[m^3/s] Takes the second value of matrix Q_turbine_interp. This is an estimation of the flowrate Delta_t seconds after the current flowrate. 

    if ~isempty(on_json)
        t = (i-1) * Delta_t;
        on_json(struct( ...
            'type','timeseries', ...
            'phase','discharging', ...
            't',t, ...
            'H_loss_total',H_loss_total_discharging(i), ...
            'H_loss_major',H_loss_major_discharging(i), ...
            'H_loss_minor',H_loss_minor_discharging(i), ...
            'H_loss_major_umbilical',H_loss_major_umbilical_discharging(i), ...
            'H_loss_minor_umbilical',H_loss_minor_umbilical_discharging(i), ...
            'H_static',H_static_discharging(i), ...
            'H_turbine',H_turbine(i), ...
            'Q',Q_turbine(i), ...
            'V_rigid',V_wat_rigid_discharging(i), ...
            'V_bladder',V_wat_bladder(i), ...
            'P_generator',P_generator(i)));
    end

% Move to the next iteration.     
i = i+1;
end

if ~isempty(on_json)
    on_json(struct( ...
        'type','heartbeat', ...
        'phase','discharging', ...
        'message','simulation done, computing T_empty_discharging', ...
        'i',i));
end

%% Output variables
T_empty_discharging = i*Delta_t; %[s] Time it takes to discharge the battery.

if ~isempty(on_json)
    on_json(struct( ...
        'type','heartbeat', ...
        'phase','discharging', ...
        'message','simulation done, computing E_elec_out_J', ...
        'i',i));
end
E_elec_out_J = sum(P_generator.*Delta_t); %[J] Amount of energy generated by the generator during the discharging.


if ~isempty(on_json)
    on_json(struct( ...
        'type','heartbeat', ...
        'phase','discharging', ...
        'message','simulation done, computing E_elec_out_Wh', ...
        'i',i));
end
E_elec_out_Wh = E_elec_out_J/3600; %[Wh] Amount of energy generated by the generator during the discharging.


if ~isempty(on_json)
    on_json(struct( ...
        'type','heartbeat', ...
        'phase','discharging', ...
        'message','simulation done, computing E_elec_out_kWh', ...
        'i',i));
end
E_elec_out_kWh = E_elec_out_Wh/1000; %[kWh] Amount of energy generated by the generator during the discharging.

if ~isempty(on_json)
    on_json(struct( ...
        'type','heartbeat', ...
        'phase','discharging', ...
        'message','simulation done, skipping plots', ...
        'i',i));
end

%% Plots 
if do_plot
    x_for_plot = 1:i-1;
    x_for_plot_2 = 1:i;
    x_for_plot_3 = 1:startup_steps+1;

    figure(5)
    plot(Q_turbine)
    title('Flow through the turbine (Discharging)')
    if Delta_t == 0.1
        xlabel('Time [ds]');
    elseif Delta_t == 0.01
        xlabel('Time [cs]');
    elseif Delta_t == 0.001
        xlabel('Time [ms]');
    end
    ylabel('Volumetric flowrate [m^3/s]')


    figure(6)
    plot(x_for_plot_2, V_wat_rigid_discharging, x_for_plot_2, V_wat_bladder)
    title('Water in bladder and rigid reservoir (Discharging)')
    if Delta_t == 0.1
        xlabel('Time [ds]');
    elseif Delta_t == 0.01
        xlabel('Time [cs]');
    elseif Delta_t == 0.001
        xlabel('Time [ms]');
    end
    ylabel('Volume [m^3]')
    legend('Rigid reservoir','Bladder')

    figure(7)
    plot(x_for_plot, H_loss_total_discharging, x_for_plot, H_loss_minor_discharging, x_for_plot, H_loss_major_discharging, x_for_plot, H_loss_major_umbilical_discharging, x_for_plot, H_loss_minor_umbilical_discharging)
    title('Head loss (Discharging)')
    if Delta_t == 0.1
        xlabel('Time [ds]');
    elseif Delta_t == 0.01
        xlabel('Time [cs]');
    elseif Delta_t == 0.001
        xlabel('Time [ms]');
    end
    ylabel('Head loss [m]')
    legend('Total head loss','Minor head loss','Major head loss','Major head loss umbilical','Minor head loss umbilical')

    figure(8)
    plot(x_for_plot, H_static_discharging, x_for_plot, H_loss_total_discharging, x_for_plot, H_turbine)
    title('Turbine head (Discharging)')
    if Delta_t == 0.1
        xlabel('Time [ds]');
    elseif Delta_t == 0.01
        xlabel('Time [cs]');
    elseif Delta_t == 0.001
        xlabel('Time [ms]');
    end
    ylabel('Head [m]')
    legend('Static head','Total head loss','Turbine head')

    figure(9)
    plot(P_generator)
    title('Power of the generator (Discharging)')
    if Delta_t == 0.1
        xlabel('Time [ds]');
    elseif Delta_t == 0.01
        xlabel('Time [cs]');
    elseif Delta_t == 0.001
        xlabel('Time [ms]');
    end
    ylabel('Power of the generator [W]')
end

if ~isempty(on_json)
    on_json(struct( ...
        'type','heartbeat', ...
        'phase','discharging', ...
        'message','simulation done, plots skipped', ...
        'i',i));
end

%% Roundtrip efficiency calculation
Analytical_Discharging;
N_roundtrip = n_Total;

if ~isempty(on_json)
    on_json(struct( ...
        'type','summary', ...
        'phase','discharging', ...
        'T_empty',T_empty_discharging, ...
        'E_elec_out_kWh',E_elec_out_kWh, ...
        'N_roundtrip',N_roundtrip, ...
        'i',i));
end

end
