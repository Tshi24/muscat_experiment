%% func_plot_charging_mitigation_enhanced
% Enhanced plot showing spacecraft charging with battery and solar panel integration
%
% This function generates a comprehensive 6-panel visualization showing:
% - Heliocentric distance and sunlight status
% - Spacecraft potential (sunlit vs eclipse)
% - Thruster activation for mitigation
% - Power consumption breakdown
% - Battery state of charge
% - Solar panel power generation
%
% Inputs:
%   mission - Mission structure containing all telemetry
%   i_SC    - Spacecraft index

function func_plot_charging_mitigation_enhanced(mission, i_SC)

    % Check if charging data exists
    if ~isfield(mission.true_SC{i_SC}.software_SC_executive.store, 'charging')
        warning('No charging mitigation data available for enhanced plotting');
        return;
    end
    
    charging = mission.true_SC{i_SC}.software_SC_executive.store.charging;
    
    % Get the number of stored data points
    kd = mission.storage.k_storage;
    
    % Extract time vector (convert to hours)
    time_hours = charging.time_sec(1:kd) / 3600;  % [hours]
    
    % Get threshold values
    V_ON_val = charging.V_ON(find(charging.V_ON ~= 0, 1));
    V_OFF_val = charging.V_OFF(find(charging.V_OFF ~= 0, 1));
    if isempty(V_ON_val), V_ON_val = -20; end
    if isempty(V_OFF_val), V_OFF_val = -12; end
    
    % Get battery and power data
    if isfield(mission.true_SC{i_SC}.true_SC_battery{1}, 'store')
        battery_charge = mission.true_SC{i_SC}.true_SC_battery{1}.store.state_of_charge(1:kd);  % [%]
        battery_current = mission.true_SC{i_SC}.true_SC_battery{1}.store.battery_current(1:kd);  % [A]
    else
        battery_charge = zeros(kd, 1);
        battery_current = zeros(kd, 1);
    end
    
    % Get solar panel power
    if isfield(mission.true_SC{i_SC}.true_SC_solar_panel{1}, 'store')
        solar_power = mission.true_SC{i_SC}.true_SC_solar_panel{1}.store.instantaneous_power_generated(1:kd);  % [W]
    else
        solar_power = zeros(kd, 1);
    end
    
    % Get total power consumption
    if isfield(mission.true_SC{i_SC}.true_SC_power, 'store')
        power_consumed = mission.true_SC{i_SC}.true_SC_power.store.instantaneous_power_consumed(1:kd);  % [W]
    else
        power_consumed = zeros(kd, 1);
    end
    
    % Standard font size
    if isfield(mission.storage, 'plot_parameters')
        font_size = mission.storage.plot_parameters.standard_font_size;
    else
        font_size = 11;
    end
    
    % Create figure with 6 subplots
    figure('Name', 'Spacecraft Charging & System Integration', 'NumberTitle', 'off', ...
           'Position', [50, 50, 1400, 1000]);
    
    %% Subplot 1: Heliocentric Distance and Sunlight Status
    subplot(3, 2, 1);
    hold on; grid on;
    
    % Plot heliocentric distance
    yyaxis left
    plot(time_hours, charging.x_AU(1:kd), 'b-', 'LineWidth', 2);
    ylabel('Distance [AU]', 'FontSize', font_size);
    ylim([min(charging.x_AU(1:kd))*0.95, max(charging.x_AU(1:kd))*1.05]);
    
    % Plot sunlight status
    yyaxis right
    stairs(time_hours, charging.isSunlit(1:kd), 'r-', 'LineWidth', 1.5);
    ylabel('Sunlight (1=Sun, 0=Eclipse)', 'FontSize', font_size);
    ylim([-0.1, 1.1]);
    yticks([0, 1]);
    yticklabels({'Eclipse', 'Sunlit'});
    
    xlabel('Time [hours]', 'FontSize', font_size);
    title('Environmental Conditions', 'FontSize', font_size, 'FontWeight', 'bold');
    legend({'Distance from Sun', 'Sunlight Status'}, 'Location', 'best', 'FontSize', font_size-2);
    set(gca, 'FontSize', font_size);
    hold off;
    
    %% Subplot 2: Spacecraft Potential with Thresholds
    subplot(3, 2, 2);
    hold on; grid on;
    
    % Plot actual potential
    plot(time_hours, charging.phi_pred(1:kd), 'b-', 'LineWidth', 2.5, 'DisplayName', 'S/C Potential');
    
    % Plot predictions
    plot(time_hours, charging.phiOff_pred(1:kd), 'r--', 'LineWidth', 1, 'DisplayName', '\phi (Thruster OFF)');
    plot(time_hours, charging.phiOn_pred(1:kd), 'g--', 'LineWidth', 1, 'DisplayName', '\phi (Thruster ON)');
    
    % Threshold lines
    yline(V_ON_val, 'r-', 'LineWidth', 2, 'DisplayName', sprintf('V_{ON} = %.0f V (Turn ON)', V_ON_val));
    yline(V_OFF_val, 'g-', 'LineWidth', 2, 'DisplayName', sprintf('V_{OFF} = %.0f V (Turn OFF)', V_OFF_val));
    yline(0, 'k:', 'LineWidth', 1, 'HandleVisibility', 'off');
    
    % Highlight regions where potential is critical
    critical_idx = find(charging.phi_pred(1:kd) <= V_ON_val);
    if ~isempty(critical_idx)
        scatter(time_hours(critical_idx), charging.phi_pred(critical_idx), 50, 'r', 'filled', ...
                'DisplayName', 'Critical Charging');
    end
    
    xlabel('Time [hours]', 'FontSize', font_size);
    ylabel('Potential [V]', 'FontSize', font_size);
    title('Spacecraft Charging Potential', 'FontSize', font_size, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', font_size-3);
    set(gca, 'FontSize', font_size);
    hold off;
    
    %% Subplot 3: Thruster Activation
    subplot(3, 2, 3);
    hold on; grid on;
    
    stairs(time_hours, charging.thruster_cmd(1:kd), 'b-', 'LineWidth', 2.5);
    
    % Shade eclipse periods
    eclipse_idx = find(charging.isSunlit(1:kd) == 0);
    if ~isempty(eclipse_idx)
        y_lim = [-0.1, 1.2];
        patch_handles = [];
        d_eclipse = diff([0; eclipse_idx; kd+1]);
        eclipse_starts = eclipse_idx(d_eclipse(1:end-1) > 1);
        eclipse_ends = eclipse_idx(d_eclipse(2:end) > 1);
        for i = 1:length(eclipse_starts)
            h = patch([time_hours(eclipse_starts(i)), time_hours(eclipse_ends(i)), ...
                   time_hours(eclipse_ends(i)), time_hours(eclipse_starts(i))], ...
                  [y_lim(1), y_lim(1), y_lim(2), y_lim(2)], ...
                  [0.9, 0.9, 0.9], 'FaceAlpha', 0.3, 'EdgeColor', 'none');
            if i == 1
                patch_handles = h;
            end
        end
        if ~isempty(patch_handles)
            set(patch_handles, 'DisplayName', 'Eclipse Period');
        end
    end
    
    ylim([-0.1, 1.2]);
    xlabel('Time [hours]', 'FontSize', font_size);
    ylabel('Thruster State', 'FontSize', font_size);
    yticks([0, 1]);
    yticklabels({'OFF', 'ON'});
    title('Electric Thruster for Charging Mitigation', 'FontSize', font_size, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', font_size-2);
    set(gca, 'FontSize', font_size);
    hold off;
    
    %% Subplot 4: Power Budget
    subplot(3, 2, 4);
    hold on; grid on;
    
    % Plot solar power generation
    plot(time_hours, solar_power, 'g-', 'LineWidth', 2, 'DisplayName', 'Solar Power Generated');
    
    % Plot total power consumption
    plot(time_hours, power_consumed, 'r-', 'LineWidth', 2, 'DisplayName', 'Total Power Consumed');
    
    % Plot EP thruster contribution
    plot(time_hours, charging.power_consumption(1:kd), 'b--', 'LineWidth', 1.5, ...
         'DisplayName', 'EP Thruster Power (Mitigation)');
    
    % Net power
    net_power = solar_power - power_consumed;
    plot(time_hours, net_power, 'k:', 'LineWidth', 1.5, 'DisplayName', 'Net Power (Gen - Cons)');
    yline(0, 'k-', 'LineWidth', 0.5, 'HandleVisibility', 'off');
    
    xlabel('Time [hours]', 'FontSize', font_size);
    ylabel('Power [W]', 'FontSize', font_size);
    title('Power Budget', 'FontSize', font_size, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', font_size-3);
    set(gca, 'FontSize', font_size);
    hold off;
    
    %% Subplot 5: Battery State of Charge
    subplot(3, 2, 5);
    hold on; grid on;
    
    yyaxis left
    plot(time_hours, battery_charge, 'b-', 'LineWidth', 2);
    ylabel('State of Charge [%]', 'FontSize', font_size);
    ylim([0, 100]);
    
    yyaxis right
    plot(time_hours, battery_current, 'r-', 'LineWidth', 1.5);
    ylabel('Battery Current [A]', 'FontSize', font_size);
    yline(0, 'k:', 'LineWidth', 0.5);
    
    xlabel('Time [hours]', 'FontSize', font_size);
    title('Battery Performance', 'FontSize', font_size, 'FontWeight', 'bold');
    legend({'State of Charge', 'Current (+ = Charging)'}, 'Location', 'best', 'FontSize', font_size-2);
    set(gca, 'FontSize', font_size);
    hold off;
    
    %% Subplot 6: Summary Statistics
    subplot(3, 2, 6);
    axis off;
    
    % Calculate statistics
    min_potential = min(charging.phi_pred(1:kd));
    max_potential = max(charging.phi_pred(1:kd));
    mean_potential = mean(charging.phi_pred(1:kd));
    
    % Sunlit vs Eclipse statistics
    sunlit_idx = charging.isSunlit(1:kd) == 1;
    eclipse_idx = charging.isSunlit(1:kd) == 0;
    
    if any(sunlit_idx)
        mean_pot_sunlit = mean(charging.phi_pred(sunlit_idx));
    else
        mean_pot_sunlit = NaN;
    end
    
    if any(eclipse_idx)
        mean_pot_eclipse = mean(charging.phi_pred(eclipse_idx));
    else
        mean_pot_eclipse = NaN;
    end
    
    dt = mission.true_time.time_step;
    thruster_on_time = sum(charging.thruster_cmd(1:kd)) * dt / 3600;  % hours
    total_energy = sum(charging.power_consumption(1:kd)) * dt / 3600;  % W-hr
    
    % Create text summary
    summary_text = {
        '\bf\fontsize{12}CHARGING MITIGATION SUMMARY';
        ' ';
        '\bf Heliocentric Distance:';
        sprintf('  Range: %.3f - %.3f AU', min(charging.x_AU(1:kd)), max(charging.x_AU(1:kd)));
        ' ';
        '\bf Spacecraft Potential:';
        sprintf('  Overall: %.2f V (min) to %.2f V (max)', min_potential, max_potential);
        sprintf('  In Sunlight: %.2f V (mean)', mean_pot_sunlit);
        sprintf('  In Eclipse: %.2f V (mean)', mean_pot_eclipse);
        ' ';
        '\bf Threshold Configuration:';
        sprintf('  V_{ON} = %.0f V  (Turn thruster ON)', V_ON_val);
        sprintf('  V_{OFF} = %.0f V  (Turn thruster OFF)', V_OFF_val);
        ' ';
        '\bf Thruster Activation:';
        sprintf('  Time ON: %.2f hours (%.1f min)', thruster_on_time, thruster_on_time*60);
        sprintf('  Energy Used: %.2f W-hr', total_energy);
        ' ';
        '\bf Battery:';
        sprintf('  Min SoC: %.1f%%', min(battery_charge));
        sprintf('  Max SoC: %.1f%%', max(battery_charge));
        ' ';
        '\bf Power:';
        sprintf('  Solar (mean): %.1f W', mean(solar_power));
        sprintf('  Consumed (mean): %.1f W', mean(power_consumed));
    };
    
    text(0.1, 0.95, summary_text, 'VerticalAlignment', 'top', ...
         'FontSize', font_size-1, 'Interpreter', 'tex');
    
    % Overall title
    sgtitle(sprintf('Spacecraft Charging & System Integration - SC %d', i_SC), ...
            'FontSize', font_size+3, 'FontWeight', 'bold');
    
    % Save figure
    if isfield(mission.storage, 'output_folder')
        saveas(gcf, [mission.storage.output_folder, 'charging_system_integration.fig']);
        saveas(gcf, [mission.storage.output_folder, 'charging_system_integration.png']);
        fprintf('Enhanced charging visualization saved to Output/\n');
    end
    
end
