%% example_charging_mitigation_visualization
% Script to visualize the charging mitigation controller behavior
% This demonstrates how the controller responds to different heliocentric distances

clear;
close all;
clc;

% Add path
addpath(genpath('../Supporting_Functions'));

%% Configuration
config.V_ON = -20;   % [V] Turn thruster ON when phi <= -20 V
config.V_OFF = -12;  % [V] Allow thruster OFF when phi >= -12 V
config.policy_require_sunlight_for_ep = true;
config.clamp_range = [0.044, 1.0];

fprintf('=== Charging Mitigation Controller Visualization ===\n\n');
fprintf('Configuration:\n');
fprintf('  V_ON  = %.1f V (turn ON threshold)\n', config.V_ON);
fprintf('  V_OFF = %.1f V (turn OFF threshold)\n', config.V_OFF);
fprintf('  Hysteresis gap = %.1f V\n', config.V_OFF - config.V_ON);
fprintf('  Valid range = [%.3f, %.1f] AU\n\n', config.clamp_range(1), config.clamp_range(2));

%% Scenario 1: Sweep from far to close to Sun (decreasing x_AU)
fprintf('Scenario 1: Spacecraft approaching the Sun\n');
fprintf('--------------------------------------------\n');

x_AU_sweep = linspace(1.0, 0.044, 200);  % From 1 AU to 0.044 AU
thruster_state = false;  % Start with thruster OFF
isSunlit = true;  % In sunlight

% Preallocate storage
phiOff_array = zeros(size(x_AU_sweep));
phiOn_array = zeros(size(x_AU_sweep));
phi_pred_array = zeros(size(x_AU_sweep));
thruster_cmd_array = zeros(size(x_AU_sweep));

% Run controller through sweep
for i = 1:length(x_AU_sweep)
    [thruster_cmd, telem] = func_control_charging_mitigation_EP(...
        config, x_AU_sweep(i), isSunlit, thruster_state);
    
    % Store results
    phiOff_array(i) = telem.phiOff_pred;
    phiOn_array(i) = telem.phiOn_pred;
    phi_pred_array(i) = telem.phi_pred;
    thruster_cmd_array(i) = thruster_cmd;
    
    % Update state for next iteration
    if thruster_cmd ~= thruster_state
        fprintf('  State change at x_AU = %.3f AU: %s -> %s (Reason: %s)\n', ...
            x_AU_sweep(i), ...
            thruster_state ? 'ON' : 'OFF', ...
            thruster_cmd ? 'ON' : 'OFF', ...
            telem.reason_code);
        thruster_state = thruster_cmd;
    end
end

fprintf('\n');

%% Scenario 2: Return sweep (increasing x_AU)
fprintf('Scenario 2: Spacecraft receding from the Sun\n');
fprintf('---------------------------------------------\n');

x_AU_return = linspace(0.044, 1.0, 200);  % From 0.044 AU to 1 AU
thruster_state = true;  % Start with thruster ON (from previous scenario)

% Preallocate storage
phiOff_return = zeros(size(x_AU_return));
phiOn_return = zeros(size(x_AU_return));
phi_pred_return = zeros(size(x_AU_return));
thruster_cmd_return = zeros(size(x_AU_return));

% Run controller through return sweep
for i = 1:length(x_AU_return)
    [thruster_cmd, telem] = func_control_charging_mitigation_EP(...
        config, x_AU_return(i), isSunlit, thruster_state);
    
    % Store results
    phiOff_return(i) = telem.phiOff_pred;
    phiOn_return(i) = telem.phiOn_pred;
    phi_pred_return(i) = telem.phi_pred;
    thruster_cmd_return(i) = thruster_cmd;
    
    % Update state for next iteration
    if thruster_cmd ~= thruster_state
        fprintf('  State change at x_AU = %.3f AU: %s -> %s (Reason: %s)\n', ...
            x_AU_return(i), ...
            thruster_state ? 'ON' : 'OFF', ...
            thruster_cmd ? 'ON' : 'OFF', ...
            telem.reason_code);
        thruster_state = thruster_cmd;
    end
end

fprintf('\n');

%% Plotting
figure('Position', [100, 100, 1200, 800]);

% Plot 1: Potential predictions vs heliocentric distance
subplot(3,1,1);
plot(x_AU_sweep, phiOff_array, 'b-', 'LineWidth', 2, 'DisplayName', '\phi_{OFF} (thruster OFF)');
hold on;
plot(x_AU_sweep, phiOn_array, 'r-', 'LineWidth', 2, 'DisplayName', '\phi_{ON} (thruster ON)');
yline(config.V_ON, 'k--', 'LineWidth', 1.5, 'DisplayName', 'V_{ON} threshold');
yline(config.V_OFF, 'k:', 'LineWidth', 1.5, 'DisplayName', 'V_{OFF} threshold');
xlabel('Heliocentric Distance (AU)');
ylabel('Spacecraft Potential (V)');
title('Predicted Spacecraft Potential vs Distance from Sun');
legend('Location', 'best');
grid on;
set(gca, 'FontSize', 12);

% Plot 2: Approach trajectory (decreasing distance)
subplot(3,1,2);
plot(x_AU_sweep, phi_pred_array, 'k-', 'LineWidth', 2, 'DisplayName', 'Predicted \phi');
hold on;
yline(config.V_ON, 'r--', 'LineWidth', 1.5, 'DisplayName', 'V_{ON}');
yline(config.V_OFF, 'g--', 'LineWidth', 1.5, 'DisplayName', 'V_{OFF}');
% Shade hysteresis zone
fill([min(x_AU_sweep), max(x_AU_sweep), max(x_AU_sweep), min(x_AU_sweep)], ...
     [config.V_ON, config.V_ON, config.V_OFF, config.V_OFF], ...
     [0.9 0.9 0.9], 'EdgeColor', 'none', 'DisplayName', 'Hysteresis zone');
% Re-plot phi on top of shading
plot(x_AU_sweep, phi_pred_array, 'k-', 'LineWidth', 2, 'DisplayName', 'Predicted \phi (approaching)');

% Overlay thruster commands
yyaxis right;
stairs(x_AU_sweep, thruster_cmd_array, 'b-', 'LineWidth', 2);
ylabel('Thruster Command (ON=1, OFF=0)');
ylim([-0.1, 1.1]);
set(gca, 'YColor', 'b');

yyaxis left;
xlabel('Heliocentric Distance (AU)');
ylabel('Spacecraft Potential (V)');
title('Scenario 1: Approaching Sun (decreasing distance)');
legend('Location', 'best');
grid on;
set(gca, 'FontSize', 12);

% Plot 3: Return trajectory (increasing distance)
subplot(3,1,3);
plot(x_AU_return, phi_pred_return, 'k-', 'LineWidth', 2, 'DisplayName', 'Predicted \phi');
hold on;
yline(config.V_ON, 'r--', 'LineWidth', 1.5, 'DisplayName', 'V_{ON}');
yline(config.V_OFF, 'g--', 'LineWidth', 1.5, 'DisplayName', 'V_{OFF}');
% Shade hysteresis zone
fill([min(x_AU_return), max(x_AU_return), max(x_AU_return), min(x_AU_return)], ...
     [config.V_ON, config.V_ON, config.V_OFF, config.V_OFF], ...
     [0.9 0.9 0.9], 'EdgeColor', 'none', 'DisplayName', 'Hysteresis zone');
% Re-plot phi on top of shading
plot(x_AU_return, phi_pred_return, 'k-', 'LineWidth', 2, 'DisplayName', 'Predicted \phi (receding)');

% Overlay thruster commands
yyaxis right;
stairs(x_AU_return, thruster_cmd_return, 'b-', 'LineWidth', 2);
ylabel('Thruster Command (ON=1, OFF=0)');
ylim([-0.1, 1.1]);
set(gca, 'YColor', 'b');

yyaxis left;
xlabel('Heliocentric Distance (AU)');
ylabel('Spacecraft Potential (V)');
title('Scenario 2: Receding from Sun (increasing distance)');
legend('Location', 'best');
grid on;
set(gca, 'FontSize', 12);

% Overall title
sgtitle('Spacecraft Charging Mitigation Controller Behavior', 'FontSize', 14, 'FontWeight', 'bold');

fprintf('Visualization complete!\n');
fprintf('Note the hysteresis: Turn-ON distance != Turn-OFF distance\n');
fprintf('This prevents chattering when distance is constant.\n');
