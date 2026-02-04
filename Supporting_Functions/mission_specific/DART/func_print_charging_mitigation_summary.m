%% func_print_charging_mitigation_summary
% Print and save summary statistics for spacecraft charging mitigation
%
% This function:
% - Calculates summary statistics (min/max potential, thruster ON time, energy)
% - Prints summary to console
% - Saves charging data to MAT file
%
% Inputs:
%   mission - Mission structure containing charging telemetry
%   i_SC    - Spacecraft index

function func_print_charging_mitigation_summary(mission, i_SC)

    % Check if charging data exists
    if ~isfield(mission.true_SC{i_SC}.software_SC_executive.store, 'charging')
        warning('No charging mitigation data available');
        return;
    end
    
    charging = mission.true_SC{i_SC}.software_SC_executive.store.charging;
    
    % Get the number of stored data points
    kd = mission.storage.k_storage;
    
    % Extract data
    time_sec = charging.time_sec(1:kd);
    phi_pred = charging.phi_pred(1:kd);
    thruster_cmd = charging.thruster_cmd(1:kd);
    power_consumption = charging.power_consumption(1:kd);
    isSunlit = charging.isSunlit(1:kd);
    
    % Get cumulative energy if available
    if isfield(charging, 'cumulative_energy')
        cumulative_energy = charging.cumulative_energy(1:kd);
        total_energy_Wh = cumulative_energy(end);  % [W-hr] From tracking
    else
        % Fallback to calculation from power consumption
        dt = mission.true_time.time_step;  % [sec]
        total_energy_Wh = sum(power_consumption) * dt / 3600;  % [W-hr]
    end
    
    %% Calculate Summary Statistics
    
    % Min and max potential
    min_potential = min(phi_pred);
    max_potential = max(phi_pred);
    mean_potential = mean(phi_pred);
    
    % Find when potential was most negative
    [~, idx_min] = min(phi_pred);
    time_min_potential = time_sec(idx_min);
    
    % Calculate thruster ON time
    dt = mission.true_time.time_step;  % [sec]
    thruster_on_time = sum(thruster_cmd) * dt;  % [sec]
    thruster_on_time_hours = thruster_on_time / 3600;  % [hours]
    
    % Calculate percentage of time thruster was ON
    total_time = time_sec(end) - time_sec(1);
    thruster_on_percent = (thruster_on_time / total_time) * 100;
    
    % Total energy already calculated above from cumulative tracking
    total_energy_kWh = total_energy_Wh / 1000;  % [kW-hr]
    
    % Calculate separate statistics for sunlit vs eclipse
    sunlit_idx = (isSunlit > 0);
    eclipse_idx = (isSunlit == 0);
    
    if any(sunlit_idx)
        mean_potential_sunlit = mean(phi_pred(sunlit_idx));
    else
        mean_potential_sunlit = NaN;
    end
    
    if any(eclipse_idx)
        mean_potential_eclipse = mean(phi_pred(eclipse_idx));
    else
        mean_potential_eclipse = NaN;
    end
    
    % Count number of activation events
    thruster_activations = sum(diff([0; thruster_cmd]) > 0);
    
    % Get threshold values
    V_ON_val = charging.V_ON(find(charging.V_ON ~= 0, 1));
    V_OFF_val = charging.V_OFF(find(charging.V_OFF ~= 0, 1));
    if isempty(V_ON_val), V_ON_val = -20; end
    if isempty(V_OFF_val), V_OFF_val = -12; end
    
    %% Print Summary to Console
    
    fprintf('\n');
    fprintf('================================================================================\n');
    fprintf('           SPACECRAFT CHARGING MITIGATION SUMMARY - SC %d\n', i_SC);
    fprintf('================================================================================\n');
    fprintf('\n');
    
    fprintf('SPACECRAFT POTENTIAL:\n');
    fprintf('  Minimum Potential:        %+.2f V (at t = %.2f hours)\n', min_potential, time_min_potential/3600);
    fprintf('  Maximum Potential:        %+.2f V\n', max_potential);
    fprintf('  Mean Potential:           %+.2f V\n', mean_potential);
    if ~isnan(mean_potential_sunlit)
        fprintf('  Mean (Sunlit):            %+.2f V\n', mean_potential_sunlit);
    end
    if ~isnan(mean_potential_eclipse)
        fprintf('  Mean (Eclipse):           %+.2f V\n', mean_potential_eclipse);
    end
    fprintf('\n');
    
    fprintf('CONTROLLER CONFIGURATION:\n');
    fprintf('  V_ON Threshold:           %.0f V (turn thruster ON)\n', V_ON_val);
    fprintf('  V_OFF Threshold:          %.0f V (turn thruster OFF)\n', V_OFF_val);
    fprintf('  Hysteresis Gap:           %.0f V\n', V_OFF_val - V_ON_val);
    fprintf('\n');
    
    fprintf('THRUSTER ACTIVATION:\n');
    fprintf('  Total Time ON:            %.2f hours (%.1f minutes)\n', thruster_on_time_hours, thruster_on_time/60);
    fprintf('  Percentage of Mission:    %.2f%%\n', thruster_on_percent);
    fprintf('  Number of Activations:    %d\n', thruster_activations);
    fprintf('\n');
    
    fprintf('POWER & ENERGY:\n');
    fprintf('  EP Thruster Power:        50 W (when ON)\n');
    fprintf('  Total Energy Used:        %.2f W-hr (%.4f kW-hr)\n', total_energy_Wh, total_energy_kWh);
    fprintf('\n');
    
    fprintf('MISSION DURATION:\n');
    fprintf('  Total Simulation Time:    %.2f hours (%.2f days)\n', total_time/3600, total_time/86400);
    fprintf('\n');
    
    % Check if thruster was ever activated
    if thruster_activations == 0
        fprintf('RESULT: No charging mitigation required - spacecraft potential remained safe\n');
    else
        fprintf('RESULT: Charging mitigation active - thruster activated %d times\n', thruster_activations);
    end
    
    fprintf('================================================================================\n');
    fprintf('\n');
    
    %% Save Charging Data to MAT File
    
    if isfield(mission.storage, 'output_folder')
        % Create structure with all charging data and summary
        charging_data = struct();
        
        % Telemetry data
        charging_data.time_sec = time_sec;
        charging_data.time_hours = time_sec / 3600;
        charging_data.x_AU = charging.x_AU(1:kd);
        charging_data.isSunlit = charging.isSunlit(1:kd);
        charging_data.phi_pred = phi_pred;
        charging_data.phiOff_pred = charging.phiOff_pred(1:kd);
        charging_data.phiOn_pred = charging.phiOn_pred(1:kd);
        charging_data.thruster_is_on = charging.thruster_is_on(1:kd);
        charging_data.thruster_cmd = thruster_cmd;
        charging_data.power_consumption = power_consumption;
        charging_data.reason_code = charging.reason_code(1:kd);
        
        % Add cumulative energy if available
        if isfield(charging, 'cumulative_energy')
            charging_data.cumulative_energy = charging.cumulative_energy(1:kd);
        end
        
        % Configuration
        charging_data.V_ON = V_ON_val;
        charging_data.V_OFF = V_OFF_val;
        
        % Summary statistics
        charging_data.summary = struct();
        charging_data.summary.min_potential = min_potential;
        charging_data.summary.max_potential = max_potential;
        charging_data.summary.mean_potential = mean_potential;
        charging_data.summary.mean_potential_sunlit = mean_potential_sunlit;
        charging_data.summary.mean_potential_eclipse = mean_potential_eclipse;
        charging_data.summary.time_min_potential = time_min_potential;
        charging_data.summary.thruster_on_time_sec = thruster_on_time;
        charging_data.summary.thruster_on_time_hours = thruster_on_time_hours;
        charging_data.summary.thruster_on_percent = thruster_on_percent;
        charging_data.summary.thruster_activations = thruster_activations;
        charging_data.summary.total_energy_Wh = total_energy_Wh;
        charging_data.summary.total_energy_kWh = total_energy_kWh;
        charging_data.summary.total_time_sec = total_time;
        
        % Save to file
        filename = [mission.storage.output_folder, 'charging_mitigation_data.mat'];
        save(filename, 'charging_data', '-v7.3');
        fprintf('Charging mitigation data saved to: %s\n', filename);
        fprintf('\n');
    end
    
end
