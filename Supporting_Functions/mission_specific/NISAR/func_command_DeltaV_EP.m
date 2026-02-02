%% [ ] Methods: Command DeltaV for EP Thrusters

function obj = func_command_DeltaV_EP(obj, mission, i_SC)
% Command Electric Propulsion thrusters to execute Delta-V maneuver
% This is different from chemical thrusters - EP thrusters are continuous low-thrust

% Constants
THROTTLE_DOWN_STEPS = 10; % Number of steps to spread throttled thrust over

% Initialize desired control thrust to zero
obj.desired_control_thrust = 0;

% Get spacecraft parameters
sc_mass = mission.true_SC{i_SC}.true_SC_body.total_mass;
dt = mission.true_time.time_step;

% Check for healthy EP thrusters
healthy_thrusters = [];
for i_thruster = 1:mission.true_SC{i_SC}.true_SC_body.num_hardware_exists.num_ep_thruster
    if mission.true_SC{i_SC}.true_SC_ep_thruster{i_thruster}.health
        healthy_thrusters = [healthy_thrusters, i_thruster];
    end
end

if isempty(healthy_thrusters)
    warning('No healthy EP thrusters available for DeltaV execution.');
    return;
end

% Check execution conditions
if (mission.true_time.time < obj.time_DeltaV) || obj.desired_DeltaV_achieved || obj.flag_insufficient_fuel
    return;
end

% Calculate remaining Delta-V
remaining_DeltaV = obj.desired_control_DeltaV - obj.total_DeltaV_executed;
remaining_magnitude = norm(remaining_DeltaV);

if remaining_magnitude > 0
    % Record start time if this is the first thrust of a maneuver
    if obj.maneuver_start_time == 0
        obj.maneuver_start_time = mission.true_time.time;
        obj.thruster_fired_successfully = false;
        disp(['Starting EP thruster maneuver execution at time ', num2str(mission.true_time.time), ' s']);
        disp(['  Target Delta-V: ', num2str(norm(obj.desired_control_DeltaV)), ' m/s']);
        disp(['  Remaining Delta-V: ', num2str(remaining_magnitude), ' m/s']);
    end
    
    % Get thruster parameters
    max_thrusts = zeros(1, length(healthy_thrusters));
    for i = 1:length(healthy_thrusters)
        max_thrusts(i) = mission.true_SC{i_SC}.true_SC_ep_thruster{healthy_thrusters(i)}.maximum_thrust;
    end
    
    % Get current attitude matrix
    current_attitude = mission.true_SC{i_SC}.true_SC_adc.attitude;
    R = quaternionToRotationMatrix(current_attitude);
    
    % Rotate thruster directions to inertial frame
    thruster_body_directions = zeros(3, length(healthy_thrusters));
    for i = 1:length(healthy_thrusters)
        thruster_body_directions(:, i) = mission.true_SC{i_SC}.true_SC_ep_thruster{healthy_thrusters(i)}.orientation';
    end
    orientations = R * thruster_body_directions;
    A = orientations;
    
    % Calculate maximum available thrust in desired direction
    max_thrust_dir = A * max_thrusts';
    max_DeltaV_per_step = (norm(max_thrust_dir) * dt) / sc_mass;
    
    % For EP thrusters, we typically use maximum thrust continuously
    % until we get close to the target, then throttle down
    if remaining_magnitude > max_DeltaV_per_step * THROTTLE_DOWN_STEPS
        % Far from target - use maximum thrust
        thrust_vector = max_thrusts;
        disp(['EP thruster firing at maximum thrust: ', num2str(max_thrusts(1)), ' N']);
    else
        % Close to target - throttle down to avoid overshoot
        required_thrust_magnitude = (remaining_magnitude * sc_mass) / (dt * THROTTLE_DOWN_STEPS); % Spread over multiple steps
        
        % Distribute thrust among thrusters (equal distribution for simplicity)
        thrust_vector = zeros(1, length(healthy_thrusters));
        for i = 1:length(healthy_thrusters)
            thrust_vector(i) = required_thrust_magnitude / length(healthy_thrusters);
            
            % Clamp to thruster limits
            thrust_vector(i) = min(max(thrust_vector(i),...
                mission.true_SC{i_SC}.true_SC_ep_thruster{healthy_thrusters(i)}.minimum_thrust), ...
                mission.true_SC{i_SC}.true_SC_ep_thruster{healthy_thrusters(i)}.maximum_thrust);
        end
        disp(['EP thruster throttling down: ', num2str(thrust_vector(1)), ' N']);
    end
    
    % Apply thrust commands to EP thrusters
    for i = 1:length(healthy_thrusters)
        mission.true_SC{i_SC}.true_SC_ep_thruster{healthy_thrusters(i)}.commanded_thrust = thrust_vector(i);
        mission.true_SC{i_SC}.true_SC_ep_thruster{healthy_thrusters(i)}.flag_executive = true;
        
        % Optionally set gimbal angles to zero (pointing along thruster axis)
        mission.true_SC{i_SC}.true_SC_ep_thruster{healthy_thrusters(i)}.commanded_gimbal = [0, 0];
        
        % Save that we commanded a thrust (needed for completion checks)
        obj.desired_control_thrust = obj.desired_control_thrust + thrust_vector(i);
    end
    
    % Note: We no longer calculate applied DeltaV here - that's now done in the EP thruster itself
    % which will directly update obj.total_DeltaV_executed
    
    % Mark that thruster has fired successfully
    obj.thruster_fired_successfully = true;
else
    % No remaining Delta-V, turn off thrusters
    for i = 1:length(healthy_thrusters)
        mission.true_SC{i_SC}.true_SC_ep_thruster{healthy_thrusters(i)}.commanded_thrust = 0;
        mission.true_SC{i_SC}.true_SC_ep_thruster{healthy_thrusters(i)}.flag_executive = false;
    end
end

end
