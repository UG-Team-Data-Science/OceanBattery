function [T_empty_charging, E_elec_in_kWh,H_loss_total_charging, ...
    H_loss_major_charging, H_loss_minor_charging, H_loss_major_umbilical_charging,...
    H_loss_minor_umbilical_charging, H_static_charging, H_pump, Q_pump, V_wat_rigid_charging,E_elec_in_J,i]=Charging(OB_GUI_parameters, opts)
%% CHARGING MODEL
%   This model symulates the charging phase of the Ocean Battery.

%% Clearing previous data
% clear all;
% clc;

if nargin < 2 || isempty(opts)
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
OB_parameters; %Loads the script OB_parameters

%% Initial calcuations
P_mechanical_motor = P_electrical * N_motor; %[W] Mechanical output power motor
P_pump = P_mechanical_motor * N_pump; %[W] Power of the pump
Interp_steps = (1/Delta_t)+1; %Calculates the required amount of steps between two seconds based on Delta_t. Is used in interpolation.  

%% Model initialization
i = 1; %Initial value for i.
V_wat_rigid_charging(1) = V_wat_rigid_start; %[m^3] Sets the initial volume of water present in the rigid reservoir.
Q_pump(1) = 0.00067; %[m^3/second] Initial guess of the flow throug the pump.

%% Reality check
if  V_wat_rigid_end > V_wat_rigid_charging(1)
    error('ERROR: End volume of the rigid reservoir exceeds the starting volume. Impossible situation.');
end

%% While loop
while  V_wat_rigid_charging(i) > V_wat_rigid_end 
    
    %[m] Minor head loss of the charging phase. 
    H_loss_minor_charging(i) = Minor_head_loss_charging(Q_pump(i),OB_GUI_parameters);
    
    %[m] Major head loss of the charging phase. 
    H_loss_major_charging(i) = Major_head_loss_charging(Q_pump(i),OB_GUI_parameters);
    
    %[m] Major head loss umbilical cord during the charging phase. 
    H_loss_major_umbilical_charging(i) = Major_head_loss_umbilical(Q_pump(i),OB_GUI_parameters);
    
    %[m] Minor head loss umbilical cord during the charging phase. 
    H_loss_minor_umbilical_charging(i) = Minor_head_loss_umbilical(Q_pump(i), OB_GUI_parameters);
    
    %[m] Total head loss of the charging phase.
    H_loss_total_charging(i) = H_loss_major_charging(i) + H_loss_minor_charging(i) + H_loss_major_umbilical_charging(i) + H_loss_minor_umbilical_charging(i);
    
    %[m] Vertical difference between the surface of the water in the rigid reservoir and the 
    %surface of the body of water above the system.
    H_static_charging(i) = Depth - Water_level_rigid_reservoir(V_wat_rigid_charging(i), D_rigid, Capacity_rigid);
    
    %[m] Total head of the pump.
    H_pump(i) = H_static_charging(i) + H_loss_total_charging(i);

    %[m^3/s] Volumetric flowrate through the pump. 
    Q_pump_no_interp = P_pump / (Dens_wat * g * H_pump(i)); %[m^3/s] Calculates the volumetric flowrate 1 second after the current flowrate. 
    x = [i i+1]; %Creates vector x. This vector contains the current loop number (i) and the next interation number (i+1).
    y = [Q_pump(i) Q_pump_no_interp]; %Creates vector y. This vector contains the current flowrate and the flowrate one second later.
    t_new = linspace(i, i+1, Interp_steps); %Creates vector t_new. This vector contains a number of points (Interp_steps) between i and i+1.
    Q_pump_interp = interp1(x,y,t_new); %Linear interpolation between the current flowrate and the flowrate one second later. The number of points is specified by t_new.
    Q_pump(i+1) = Q_pump_interp(2); %[m^3/s] Takes the second value of matrix Q_pump_interp. This is an estimation of the flowrate Delta_t seconds after the current flowrate. 
    
    %[m^3] Volume of water present in the rigid reservoir.
    V_wat_rigid_charging(i+1) = V_wat_rigid_charging(i) - (Q_pump(i)*Delta_t);

    if ~isempty(on_json)
        t = (i-1) * Delta_t;
        on_json(struct( ...
            'type','timeseries', ...
            'phase','charging', ...
            't',t, ...
            'H_loss_total',H_loss_total_charging(i), ...
            'H_loss_major',H_loss_major_charging(i), ...
            'H_loss_minor',H_loss_minor_charging(i), ...
            'H_loss_major_umbilical',H_loss_major_umbilical_charging(i), ...
            'H_loss_minor_umbilical',H_loss_minor_umbilical_charging(i), ...
            'H_static',H_static_charging(i), ...
            'H_pump',H_pump(i), ...
            'Q',Q_pump(i), ...
            'V_rigid',V_wat_rigid_charging(i)));
    end

% Move to the next iteration.    
i = i+1;
end

%% Output variables
T_empty_charging = i*Delta_t; %[s] Time it takes to empty the rigid reservoir.
E_elec_in_J = T_empty_charging * P_electrical; %[J] Amount of electrical energy invested in the motor.
E_elec_in_Wh =  E_elec_in_J/3600; %[Wh] Amount of electrical energy invested in the motor.
E_elec_in_kWh = E_elec_in_J/(1000*3600); %[kWh] Amount of electrical energy invested in the motor.

if ~isempty(on_json)
    on_json(struct( ...
        'type','summary', ...
        'phase','charging', ...
        'T_empty',T_empty_charging, ...
        'E_elec_in_kWh',E_elec_in_kWh, ...
        'i',i));
end

%% Plots
if do_plot
    x_for_plot = 1:i-1;

    figure(1)
    plot(Q_pump)
    title('Flow through the pump(Charging)')
    if Delta_t == 0.1
        xlabel('Time [ds]');
    elseif Delta_t == 0.01
        xlabel('Time [cs]');
    elseif Delta_t == 0.001
        xlabel('Time [ms]');
    end
    ylabel('Volumetric flowrate [m^3/s]')

    figure(2)
    plot(V_wat_rigid_charging)
    title('Volume of fluid present in the rigid reservoir(Charging)')
    if Delta_t == 0.1
        xlabel('Time [ds]');
    elseif Delta_t == 0.01
        xlabel('Time [cs]');
    elseif Delta_t == 0.001
        xlabel('Time [ms]');
    end
    ylabel('Volume [m^3]')

    figure(3)
    plot(x_for_plot, H_loss_total_charging, x_for_plot, H_loss_minor_charging, x_for_plot, H_loss_major_charging, x_for_plot, H_loss_major_umbilical_charging, x_for_plot, H_loss_minor_umbilical_charging)
    title('Head loss (Charging)')
    if Delta_t == 0.1
        xlabel('Time [ds]');
    elseif Delta_t == 0.01
        xlabel('Time [cs]');
    elseif Delta_t == 0.001
        xlabel('Time [ms]');
    end
    ylabel('Head loss [m]')
    legend('Total head loss','Minor head loss','Major head loss','Major head loss umbilical','Minor head loss umbilical')

    figure(4)
    plot(x_for_plot, H_static_charging, x_for_plot, H_pump, x_for_plot, H_loss_total_charging)
    title('Pump head (Charging)')
    if Delta_t == 0.1
        xlabel('Time [ds]');
    elseif Delta_t == 0.01
        xlabel('Time [cs]');
    elseif Delta_t == 0.001
        xlabel('Time [ms]');
    end
    ylabel('Head [m]')
    legend('Static head','Pump head','Total head loss')
end

end
