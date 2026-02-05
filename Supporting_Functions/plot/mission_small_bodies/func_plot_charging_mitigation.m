%% func_plot_charging_mitigation
% Plot spacecraft charging and mitigation controller performance
%
% This function generates a comprehensive visualization of:
% - Spacecraft potential vs time
% - Threshold lines (V_ON and V_OFF)
% - Thruster ON/OFF state
% - Power consumption for mitigation
%
% Inputs:
%   mission - Mission structure containing charging telemetry
%   i_SC    - Spacecraft index

function func_plot_charging_mitigation(mission, i_SC)

    % Check if charging data exists
    if ~isfield(mission.true_SC{i_SC}.software_SC_executive.store, 'charging')
        warning('No charging mitigation data available for plotting');
        return;
    end
    
    charging = mission.true_SC{i_SC}.software_SC_executive.store.charging;
    
    % Get the number of stored data points
    kd = mission.storage.k_storage;
    
    % Extract time vector (convert to hours for better readability)
    time_hours = charging.time_sec(1:kd) / 3600;  % [hours]
    
    % Get threshold values (they should be constant, take first non-zero value)
    V_ON_val = charging.V_ON(find(charging.V_ON ~= 0, 1));
    V_OFF_val = charging.V_OFF(find(charging.V_OFF ~= 0, 1));
    if isempty(V_ON_val)
        V_ON_val = -20;  % Default
    end
    if isempty(V_OFF_val)
        V_OFF_val = -12;  % Default
    end
    
    % Create figure
    figure('Name', 'Spacecraft Charging & Mitigation', 'NumberTitle', 'off', ...
           'Position', [100, 100, 1200, 1000]);
    
    % Define standard font size
    if isfield(mission.storage, 'plot_parameters') && isfield(mission.storage.plot_parameters, 'standard_font_size')
        font_size = mission.storage.plot_parameters.standard_font_size;
    else
        font_size = 12;
    end
    
    %% Subplot 1: Spacecraft Potential vs Time
    subplot(4, 1, 1);
    hold on;
    grid on;
    
    % Plot actual spacecraft potential (phi_used) - main curve
    plot(time_hours, charging.phi_used(1:kd), 'b-', 'LineWidth', 2.5, 'DisplayName', 'Spacecraft Potential (actual)');
    
    % Plot potential with thruster OFF (prediction) - reference line
    plot(time_hours, charging.phiOff_pred(1:kd), 'r--', 'LineWidth', 1, 'DisplayName', '\phi_{OFF} (predicted)');
    
    % Plot potential with thruster ON (prediction) - reference line
    plot(time_hours, charging.phiOn_pred(1:kd), 'g--', 'LineWidth', 1, 'DisplayName', '\phi_{ON} (predicted)');
    
    % Plot threshold lines
    yline(V_ON_val, 'r--', 'LineWidth', 1.5, 'DisplayName', sprintf('V_{ON} = %.0f V', V_ON_val));
    yline(V_OFF_val, 'g--', 'LineWidth', 1.5, 'DisplayName', sprintf('V_{OFF} = %.0f V', V_OFF_val));
    yline(0, 'k:', 'LineWidth', 1, 'HandleVisibility', 'off');
    
    xlabel('Time [hours]', 'FontSize', font_size);
    ylabel('Potential [V]', 'FontSize', font_size);
    title('Spacecraft Charging Potential', 'FontSize', font_size, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', font_size-2);
    set(gca, 'FontSize', font_size);
    hold off;
    
    %% Subplot 2: Thruster State (ON/OFF)
    subplot(4, 1, 2);
    hold on;
    grid on;
    
    % Plot thruster command as stairs
    stairs(time_hours, charging.thruster_cmd(1:kd), 'b-', 'LineWidth', 2, 'DisplayName', 'Thruster Command');
    
    % Highlight sunlit vs eclipse periods (if applicable)
    if any(charging.isSunlit(1:kd) == 0)
        % Create shaded regions for eclipse
        eclipse_idx = find(charging.isSunlit(1:kd) == 0);
        if ~isempty(eclipse_idx)
            % Group consecutive eclipse indices
            d_eclipse = diff([0; eclipse_idx; kd+1]);
            eclipse_starts = eclipse_idx(d_eclipse(1:end-1) > 1);
            eclipse_ends = eclipse_idx(d_eclipse(2:end) > 1);
            
            % Add eclipse regions as patches
            y_lim = [0, 1.2];
            for i = 1:length(eclipse_starts)
                patch([time_hours(eclipse_starts(i)), time_hours(eclipse_ends(i)), ...
                       time_hours(eclipse_ends(i)), time_hours(eclipse_starts(i))], ...
                      [y_lim(1), y_lim(1), y_lim(2), y_lim(2)], ...
                      [0.9, 0.9, 0.9], 'FaceAlpha', 0.3, 'EdgeColor', 'none', ...
                      'DisplayName', 'Eclipse');
            end
        end
    end
    
    ylim([0, 1.2]);
    xlabel('Time [hours]', 'FontSize', font_size);
    ylabel('Thruster State', 'FontSize', font_size);
    yticks([0, 1]);
    yticklabels({'OFF', 'ON'});
    title('EP Thruster Activation for Charging Mitigation', 'FontSize', font_size, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', font_size-2);
    set(gca, 'FontSize', font_size);
    hold off;
    
    %% Subplot 3: Power Consumption
    subplot(4, 1, 3);
    hold on;
    grid on;
    
    % Plot power consumption
    stairs(time_hours, charging.power_consumption(1:kd), 'r-', 'LineWidth', 2, 'DisplayName', 'Mitigation Power');
    
    xlabel('Time [hours]', 'FontSize', font_size);
    ylabel('Power [W]', 'FontSize', font_size);
    title('Power Consumption for Charging Mitigation', 'FontSize', font_size, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', font_size-2);
    set(gca, 'FontSize', font_size);
    hold off;
    
    %% Subplot 4: Cumulative Energy
    subplot(4, 1, 4);
    hold on;
    grid on;
    
    % Plot cumulative energy if available
    if isfield(charging, 'cumulative_energy')
        plot(time_hours, charging.cumulative_energy(1:kd), 'k-', 'LineWidth', 2, 'DisplayName', 'Cumulative Energy');
    else
        % Calculate cumulative energy from power consumption
        dt = mission.true_time.time_step;  % [sec]
        cumulative = cumsum(charging.power_consumption(1:kd)) * dt / 3600;  % [W-hr]
        plot(time_hours, cumulative, 'k-', 'LineWidth', 2, 'DisplayName', 'Cumulative Energy');
    end
    
    xlabel('Time [hours]', 'FontSize', font_size);
    ylabel('Energy [W-hr]', 'FontSize', font_size);
    title('Cumulative Energy Used for Mitigation', 'FontSize', font_size, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', font_size-2);
    set(gca, 'FontSize', font_size);
    hold off;
    
    % Overall title
    sgtitle(sprintf('Spacecraft Charging & Mitigation - SC %d', i_SC), ...
            'FontSize', font_size+2, 'FontWeight', 'bold');
    
    % Save figure
    if isfield(mission.storage, 'output_folder')
        saveas(gcf, [mission.storage.output_folder, 'charging_mitigation.fig']);
        saveas(gcf, [mission.storage.output_folder, 'charging_mitigation.png']);
    end
    
end
