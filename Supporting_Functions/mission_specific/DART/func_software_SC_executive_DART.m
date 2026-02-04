%% [ ] Methods: DART Executive
% Main Executive Function for DART mission

function obj = func_software_SC_executive_DART(obj, mission, i_SC)
% Executive logic for DART mission

mission.true_SC{i_SC}.software_SC_estimate_attitude.flag_executive = 1;
mission.true_SC{i_SC}.software_SC_control_attitude.flag_executive = 1;

% %% 1. Check for Power Emergency
% if mission.true_SC{i_SC}.true_SC_power.power_emergency
%     warning('POWER EMERGENCY: Power deficit of %.2f W-hr detected. Entering safe mode.', ...
%         mission.true_SC{i_SC}.true_SC_power.power_deficit);
%
%     % Enter power-saving mode by maximizing solar panel exposure
%     obj.this_sc_mode = 'Maximize SP Power';
%
%     % Disable non-critical subsystems
%     % - Keep only essential attitude determination and control active
%     % - Disable science instruments
%     for i_HW = 1:mission.true_SC{i_SC}.true_SC_body.num_hardware_exists.num_camera
%         mission.true_SC{i_SC}.true_SC_camera{i_HW}.flag_executive = 0;
%     end
%
%     % Disable orbit control and planned maneuvers
%     mission.true_SC{i_SC}.software_SC_control_orbit.flag_executive = 0;
%     mission.true_SC{i_SC}.software_SC_control_orbit.desired_DeltaV_needs_to_be_executed = false;
%     return;
% end


% Check if this is a new mode transition
if ~strcmp(obj.this_sc_mode, obj.data.previous_mode)
    obj.data.last_mode_change_time = mission.true_time.time;
    disp(['Mode transition: ', obj.data.previous_mode, ' -> ', obj.this_sc_mode, ' at t=', num2str(mission.true_time.time)]);

    % Store previous mode
    obj.data.previous_mode = obj.this_sc_mode;
end

% Add a small delay to prevent rapid mode switching
% Only allow mode changes after minimum time threshold, to not
% overload the attitude control system
time_since_last_mode_change = mission.true_time.time - obj.data.last_mode_change_time;
if time_since_last_mode_change < 100 && obj.data.last_mode_change_time > 0
    % Skip evaluation of mode changes to avoid rapid oscillation
    % Just maintain the current mode
    return;
end

%% 2. Power Check - Prioritize Survival if under 30%
if mission.true_SC{i_SC}.software_SC_power.mean_state_of_charge < 30
    obj.this_sc_mode = 'Maximize SP Power';
    return; % Highest priority - exit early
end

%% 2.5. Spacecraft Charging Mitigation Control (EP Thruster)
% Call charging mitigation controller to manage EP thruster for charging mitigation
if isfield(mission.true_SC{i_SC}, 'charging_mitigation_config')
    
    % Compute heliocentric distance (x_AU)
    pos_sun = mission.true_solar_system.SS_body{mission.true_solar_system.index_Sun}.position; % [km]
    pos_sc = mission.true_SC{i_SC}.true_SC_navigation.position; % [km]
    r_sun_to_sc = norm(pos_sc - pos_sun); % [km]
    x_AU = r_sun_to_sc / 149597870.7; % Convert km to AU (1 AU = 149597870.7 km)
    
    % Get sunlight status from navigation
    isSunlit = mission.true_SC{i_SC}.true_SC_navigation.flag_visible_Sun;
    
    % Get current EP thruster state (assuming first EP thruster if it exists)
    thruster_is_on = false;
    if isfield(mission.true_SC{i_SC}.true_SC_body.num_hardware_exists, 'num_ep_thruster') && ...
       mission.true_SC{i_SC}.true_SC_body.num_hardware_exists.num_ep_thruster > 0
        % Check if EP thruster is currently firing
        thruster_is_on = mission.true_SC{i_SC}.true_SC_EP_thruster{1}.flag_executive;
    end
    
    % Call charging mitigation controller
    [thruster_cmd, telemetry] = func_control_charging_mitigation_EP(...
        mission.true_SC{i_SC}.charging_mitigation_config, ...
        x_AU, ...
        isSunlit, ...
        thruster_is_on);
    
    % Apply thruster command to EP thruster (if it exists)
    if isfield(mission.true_SC{i_SC}.true_SC_body.num_hardware_exists, 'num_ep_thruster') && ...
       mission.true_SC{i_SC}.true_SC_body.num_hardware_exists.num_ep_thruster > 0
        mission.true_SC{i_SC}.true_SC_EP_thruster{1}.flag_executive = thruster_cmd;
    end
    
    % Store telemetry if storage is active
    if mission.storage.flag_store_this_time_step == 1
        k = mission.storage.k_storage;
        obj.store.charging.time_sec(k) = mission.true_time.time;
        obj.store.charging.x_AU(k) = telemetry.x_AU;
        obj.store.charging.isSunlit(k) = telemetry.isSunlit;
        obj.store.charging.phiOff_pred(k) = telemetry.phiOff_pred;
        obj.store.charging.phiOn_pred(k) = telemetry.phiOn_pred;
        obj.store.charging.phi_pred(k) = telemetry.phi_pred;
        obj.store.charging.thruster_is_on(k) = telemetry.thruster_is_on;
        obj.store.charging.thruster_cmd(k) = telemetry.thruster_cmd;
        obj.store.charging.reason_code{k} = telemetry.reason_code;
        
        % Calculate power consumption for mitigation (50W when thruster is ON for mitigation)
        if telemetry.thruster_cmd && ~telemetry.thruster_is_on
            % Thruster just turned ON for mitigation
            obj.store.charging.power_consumption(k) = 50.0;  % [W] EP thruster power
        elseif telemetry.thruster_cmd
            % Thruster remains ON
            obj.store.charging.power_consumption(k) = 50.0;  % [W] EP thruster power
        else
            obj.store.charging.power_consumption(k) = 0.0;
        end
        
        % Store threshold values
        obj.store.charging.V_ON(k) = mission.true_SC{i_SC}.charging_mitigation_config.V_ON;
        obj.store.charging.V_OFF(k) = mission.true_SC{i_SC}.charging_mitigation_config.V_OFF;
    end
end

%% 3. Periodic Data Transmission (Every 5 Hour)
time_since_last_comm = mission.true_time.time - mission.true_SC{i_SC}.software_SC_communication.last_communication_time;

% Check if we're already in communication mode with an active link
already_communicating = strcmp(obj.this_sc_mode, 'DTE Comm') && mission.true_SC{i_SC}.true_SC_communication_link{1}.flag_executive == 1;

% Check if transmission just completed (to exit comm mode)
transmission_complete = isfield(mission.true_SC{i_SC}.software_SC_communication.data, 'transmission_complete') && ...
    mission.true_SC{i_SC}.software_SC_communication.data.transmission_complete;

% Start comm if:
% 1. Time threshold is met (3600 seconds since last communication) AND memory usage is significant OR
% 2. We're already communicating AND haven't completed yet
% 3. Earth is visible AND
% 4. No orbit maneuver is in progress
if ((time_since_last_comm >= 3600 * 5) || ...
        (already_communicating && ~transmission_complete)) && ...
        (mission.true_SC{i_SC}.true_SC_navigation.flag_visible_Earth) && ...
        ~mission.true_SC{i_SC}.software_SC_control_orbit.desired_DeltaV_needs_to_be_executed

    obj.this_sc_mode = 'DTE Comm';

    % Make sure data handling is activated to track data storage
    mission.true_SC{i_SC}.software_SC_data_handling.flag_executive = 1;

    % Activate communication software last to ensure proper sequencing
    mission.true_SC{i_SC}.software_SC_communication.flag_executive = 1;

    return;
end

%% 4. Collision Check & Orbit Control
mission.true_SC{i_SC}.software_SC_control_orbit = mission.true_SC{i_SC}.software_SC_control_orbit;
time_since_last_orbit_check = mission.true_time.time - mission.true_SC{i_SC}.software_SC_control_orbit.last_time_control;

if (time_since_last_orbit_check >= mission.true_SC{i_SC}.software_SC_control_orbit.max_time_before_control) && ...
        ~mission.true_SC{i_SC}.software_SC_control_orbit.desired_DeltaV_needs_to_be_executed  && ...
        ~mission.true_SC{i_SC}.true_SC_navigation.flag_SC_crashed

    % Activate orbit control system to compute necessary corrections
    mission.true_SC{i_SC}.software_SC_control_orbit.flag_executive = 1;
    mission.true_SC{i_SC}.software_SC_estimate_orbit.flag_executive = 1;
end

%% 5. Execute DeltaV to Ensure Collision
if mission.true_SC{i_SC}.software_SC_control_orbit.desired_DeltaV_needs_to_be_executed && ...
        mission.true_SC{i_SC}.software_SC_control_orbit.desired_DeltaV_computed && ...
        ~mission.true_SC{i_SC}.true_SC_navigation.flag_SC_crashed

    % Keep turning the spacecraft to the right orientation
    obj.this_sc_mode = 'Point Thruster along DeltaV direction';

    % Make sure orbit control stays active
    mission.true_SC{i_SC}.software_SC_control_orbit.flag_executive = 1;
    mission.true_SC{i_SC}.software_SC_estimate_orbit.flag_executive = 1;

    return;
end

%% 6. Default Mode: Camera Pointing
obj.this_sc_mode = 'Point camera to Target';
mission.true_SC{i_SC}.true_SC_camera{1}.flag_executive = 1; % Activate primary camera
mission.true_SC{i_SC}.software_SC_estimate_orbit.flag_executive = 1; % Regular updates


end
