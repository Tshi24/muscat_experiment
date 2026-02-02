%% [ ] Methods: Main for NISAR with EP Thrusters

function obj = func_update_software_SC_control_orbit_NISAR(obj, mission, i_SC)

% Main control loop for NISAR spacecraft orbit using Electric Propulsion
% This function handles delta-V maneuvers using EP thrusters

% Check if there are any EP thrusters available
if mission.true_SC{i_SC}.true_SC_body.num_hardware_exists.num_ep_thruster == 0
    warning('No EP thrusters configured for NISAR mission');
    return;
end

% Always verify the capacity of the fuel tanks
total_fuel = 0;
if mission.true_SC{i_SC}.true_SC_body.num_hardware_exists.num_fuel_tank > 0
    for i_tank = 1:mission.true_SC{i_SC}.true_SC_body.num_hardware_exists.num_fuel_tank
        total_fuel = total_fuel + mission.true_SC{i_SC}.true_SC_fuel_tank{i_tank}.instantaneous_fuel_mass;
    end

    % Log fuel level if it falls below certain thresholds
    if total_fuel < 0.5
        warning('CRITICAL: Spacecraft fuel level below 0.5 kg. Remaining: %.3f kg', total_fuel);
    elseif total_fuel < 1.0
        warning('WARNING: Spacecraft fuel level below 1.0 kg. Remaining: %.3f kg', total_fuel);
    end
end

% If Delta-V hasn't been computed yet, compute it
if ~obj.desired_DeltaV_computed
    
    % First, assess whether a maneuver calculation is needed
    [is_maneuver_needed, reason] = func_assess_maneuver_necessity(obj, mission, i_SC);
    
    if ~is_maneuver_needed
        % Log the reason we're skipping the maneuver calculation
        disp(['Skipping maneuver calculation: ', reason]);
        
        % If we're skipping, make sure to reset the flags
        func_reset_after_completion(obj, mission, i_SC);
        return;
    end
    
    % Maneuver seems necessary, proceed with calculations
    func_estimate_target_intercept_location_time(obj, mission, i_SC);
    func_compute_TCM_Lambert_Battin(obj, mission, i_SC);
    
    % Log the computed maneuver for mission awareness
    if obj.desired_DeltaV_computed
        disp(['Computed maneuver: DeltaV magnitude = ', num2str(norm(obj.desired_control_DeltaV)), ' m/s']);
        disp(['Execution time: ', datestr(datetime('now') + seconds(obj.time_DeltaV - mission.true_time.time))]);
        disp(['Estimated fuel required: ', num2str(obj.estimated_fuel_required), ' kg']);
    end
end

% Validate attitude and execute DeltaV if conditions are met
if obj.desired_DeltaV_needs_to_be_executed && ...
        (mission.true_time.time >= obj.time_DeltaV) && ...
        (norm(func_get_attitude_error(mission.true_SC{i_SC}.software_SC_control_attitude, mission, i_SC)) < 0.03) && ... % rad
        ~obj.flag_insufficient_fuel
    func_command_DeltaV_EP(obj, mission, i_SC);
end

% Check if remaining DeltaV is below threshold
if obj.desired_DeltaV_needs_to_be_executed && obj.desired_DeltaV_computed
    remaining_DeltaV = obj.desired_control_DeltaV - obj.total_DeltaV_executed;
    
    if norm(remaining_DeltaV) < obj.threshold_minimum_deltaV
        % If DeltaV is below threshold, consider it complete
        disp(['Maneuver complete - remaining DeltaV (', num2str(norm(remaining_DeltaV)), ...
            ' m/s) below threshold (', num2str(obj.threshold_minimum_deltaV), ' m/s)']);
        
        % Stop EP thruster
        for i_thruster = 1:mission.true_SC{i_SC}.true_SC_body.num_hardware_exists.num_ep_thruster
            if mission.true_SC{i_SC}.true_SC_ep_thruster{i_thruster}.health
                mission.true_SC{i_SC}.true_SC_ep_thruster{i_thruster}.flag_executive = false;
                mission.true_SC{i_SC}.true_SC_ep_thruster{i_thruster}.commanded_thrust = 0;
            end
        end
        
        func_reset_after_completion(obj, mission, i_SC);
        return;
    end
    
    % Check for sufficient fuel before proceeding
    if mission.true_SC{i_SC}.true_SC_body.num_hardware_exists.num_fuel_tank > 0
        total_fuel = 0;
        for i_tank = 1:mission.true_SC{i_SC}.true_SC_body.num_hardware_exists.num_fuel_tank
            total_fuel = total_fuel + mission.true_SC{i_SC}.true_SC_fuel_tank{i_tank}.instantaneous_fuel_mass;
        end
        
        % Add safety margin
        fuel_with_margin = obj.estimated_fuel_required * 1.1; % 10% margin
        
        if total_fuel < fuel_with_margin
            warning('Insufficient fuel for DeltaV execution. Required: %.3f kg (with margin), Available: %.3f kg', ...
                fuel_with_margin, total_fuel);
            
            % Cancel the maneuver
            obj.flag_insufficient_fuel = true;
            obj.desired_DeltaV_needs_to_be_executed = false;
            obj.desired_DeltaV_computed = false;
            
            % Stop EP thruster
            for i_thruster = 1:mission.true_SC{i_SC}.true_SC_body.num_hardware_exists.num_ep_thruster
                if mission.true_SC{i_SC}.true_SC_ep_thruster{i_thruster}.health
                    mission.true_SC{i_SC}.true_SC_ep_thruster{i_thruster}.flag_executive = false;
                    mission.true_SC{i_SC}.true_SC_ep_thruster{i_thruster}.commanded_thrust = 0;
                end
            end
            return;
        end
    end
end

% Check if maneuver is complete - simplified approach
if obj.desired_DeltaV_needs_to_be_executed && obj.desired_DeltaV_computed
    % Check remaining DeltaV - this is updated directly by the thruster
    remaining_DeltaV = obj.desired_control_DeltaV - obj.total_DeltaV_executed;
    
    % Check timeout conditions
    maneuver_timeout = false;
    time_since_planned = mission.true_time.time - obj.time_DeltaV;
    
    % Timeout if running too long since start
    if obj.maneuver_start_time > 0 && (mission.true_time.time - obj.maneuver_start_time) > 300
        maneuver_timeout = true;
        warning('Maneuver timeout reached after %d seconds from maneuver start', ...
            mission.true_time.time - obj.maneuver_start_time);
    end
    
    % Timeout if waiting too long after planned execution
    if time_since_planned > 300 && ~maneuver_timeout
        maneuver_timeout = true;
        warning('Maneuver timeout: %d seconds since planned execution time', time_since_planned);
    end
    
    % Check if we should complete the maneuver
    is_deltaV_complete = norm(remaining_DeltaV) < obj.threshold_minimum_deltaV;
    if is_deltaV_complete || maneuver_timeout
        % Report reason for completion
        if is_deltaV_complete
            disp(['Maneuver completed: Target DeltaV achieved within ', ...
                num2str(obj.threshold_minimum_deltaV), ' m/s threshold']);
        elseif maneuver_timeout
            disp(['Maneuver timeout after ', num2str(mission.true_time.time - obj.maneuver_start_time), ' seconds']);
        end
        
        % Reset everything
        func_reset_after_completion(obj, mission, i_SC);
        
        % Turn off EP thruster
        for i_thruster = 1:mission.true_SC{i_SC}.true_SC_body.num_hardware_exists.num_ep_thruster
            if mission.true_SC{i_SC}.true_SC_ep_thruster{i_thruster}.health
                mission.true_SC{i_SC}.true_SC_ep_thruster{i_thruster}.flag_executive = false;
                mission.true_SC{i_SC}.true_SC_ep_thruster{i_thruster}.commanded_thrust = 0;
            end
        end
        
        disp('Maneuver completed and all flags reset');
    end
end

end
