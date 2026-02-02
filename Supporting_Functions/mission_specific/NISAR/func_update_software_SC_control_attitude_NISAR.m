%% [ ] Methods: Control Attitude NISAR

function obj = func_update_software_SC_control_attitude_NISAR(obj, mission, i_SC)

obj.instantaneous_data_generated_per_sample = (1e-3)*8*7; % [kb] i.e. 7 Bytes per sample

% Navigation and Guidance
% Set pointing vectors based on SC mode
obj = func_set_pointing_vectors_NISAR(obj, mission, i_SC);

% Compute Desired Attitude using Array Search
obj = func_compute_desired_attitude_Array_Search(obj);
obj.desired_angular_velocity = zeros(1,3); % [rad/sec]

% Control
switch obj.mode_software_SC_control_attitude_selector

    case 'NISAR Oracle'
        % Use Oracle
        obj = func_update_software_SC_control_attitude_Oracle(obj, mission, i_SC);
    
    case 'NISAR Control Asymptotically Stable send to thrusters'
        % Use asymptotically stable control with microthrusters
        obj = function_update_desired_control_torque_asymptotically_stable(obj, mission, i_SC);
        func_decompose_control_torque_into_thrusters_optimization_kkt(obj, mission, i_SC);
    
    case 'NISAR Control Asymptotically Stable send to actuators'
        % Use asymptotically stable control with actuator selection
        obj = function_update_desired_control_torque_asymptotically_stable(obj, mission, i_SC);
        % If microthrusters are available, use them (NISAR has no reaction wheels)
        if mission.true_SC{i_SC}.true_SC_body.num_hardware_exists.num_micro_thruster > 0
            func_decompose_control_torque_into_thrusters_optimization_kkt(obj, mission, i_SC);
        else
            % Fallback: apply torque directly to ADC
            mission.true_SC{i_SC}.true_SC_adc.control_torque = obj.desired_control_torque';
        end
   
    otherwise
        error('NISAR Attitude Control mode not defined!')
end
end
