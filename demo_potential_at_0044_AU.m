%% demo_potential_at_0044_AU
% Demonstration: Compute spacecraft potential at 0.044 AU
% This shows the CRITICAL charging condition at closest solar approach

clear;
clc;

fprintf('\n');
fprintf('======================================================================\n');
fprintf('    SPACECRAFT POTENTIAL CALCULATION AT 0.044 AU\n');
fprintf('======================================================================\n');
fprintf('\n');

%% Setup
x_AU = 0.044;  % Closest approach in valid model range (perihelion)

fprintf('Heliocentric Distance: %.3f AU\n', x_AU);
fprintf('  (This is the CLOSEST approach in the valid model range)\n');
fprintf('  (Typical perihelion for Parker Solar Probe-like mission)\n');
fprintf('\n');

%% Compute Potentials using SPIS Models
[phiOff, phiOn] = Phi_sunlit_models(x_AU);

fprintf('----------------------------------------------------------------------\n');
fprintf('EQUATION DETAILS:\n');
fprintf('----------------------------------------------------------------------\n');
fprintf('\n');
fprintf('Thruster OFF model:\n');
fprintf('  phi_OFF = 8.39628\n');
fprintf('          - 0.000770893 / (x_AU^4)\n');
fprintf('          + 0.029318    / (x_AU^3)\n');
fprintf('          - 0.362418    / (x_AU^2)\n');
fprintf('          + 0.541516    / (x_AU)\n');
fprintf('          + 0.623116    * (x_AU^2)\n');
fprintf('\n');
fprintf('Thruster ON model:\n');
fprintf('  phi_ON  = -5.6241689717\n');
fprintf('          - 0.0001905435754 / (x_AU^4)\n');
fprintf('          + 0.0060468979089 / (x_AU^3)\n');
fprintf('          - 0.0319720512141 / (x_AU^2)\n');
fprintf('          - 1.0811794594    * (x_AU^2)\n');
fprintf('\n');

fprintf('----------------------------------------------------------------------\n');
fprintf('COMPUTED RESULTS:\n');
fprintf('----------------------------------------------------------------------\n');
fprintf('\n');
fprintf('  Potential with Thruster OFF (phi_OFF): %+.2f V\n', phiOff);
fprintf('  Potential with Thruster ON  (phi_ON):  %+.2f V\n', phiOn);
fprintf('\n');
fprintf('  Delta (phi_ON - phi_OFF): %+.2f V\n', phiOn - phiOff);
fprintf('  → Thruster improves potential by %.2f V\n', abs(phiOff - phiOn));
fprintf('\n');

%% Interpret Results
fprintf('----------------------------------------------------------------------\n');
fprintf('CONTROLLER INTERPRETATION:\n');
fprintf('----------------------------------------------------------------------\n');
fprintf('\n');

% Controller thresholds
V_ON = -20;   % Turn thruster ON threshold
V_OFF = -12;  % Turn thruster OFF threshold

fprintf('Controller Thresholds:\n');
fprintf('  V_ON  = %.0f V (turn thruster ON when phi <= %.0f V)\n', V_ON, V_ON);
fprintf('  V_OFF = %.0f V (turn thruster OFF when phi >= %.0f V)\n', V_OFF, V_OFF);
fprintf('\n');

% Check thruster OFF condition
fprintf('Step 1: Check if thruster should turn ON\n');
if phiOff <= V_ON
    fprintf('  ✓ phi_OFF (%.2f V) <= V_ON (%.0f V)\n', phiOff, V_ON);
    fprintf('  → CRITICAL CHARGING DETECTED!\n');
    fprintf('  → Thruster should turn ON to mitigate\n');
else
    fprintf('  ✗ phi_OFF (%.2f V) > V_ON (%.0f V)\n', phiOff, V_ON);
    fprintf('  → No critical charging, thruster stays OFF\n');
end
fprintf('\n');

% Check thruster ON condition
fprintf('Step 2: Check if thruster successfully mitigates\n');
if phiOn >= V_OFF
    fprintf('  ✓ phi_ON (%.2f V) >= V_OFF (%.0f V)\n', phiOn, V_OFF);
    fprintf('  → Charging SUCCESSFULLY mitigated!\n');
    fprintf('  → Thruster can turn OFF when potential recovers\n');
elseif phiOn <= V_ON
    fprintf('  ! phi_ON (%.2f V) <= V_ON (%.0f V)\n', phiOn, V_ON);
    fprintf('  → SEVERE charging - even with thruster ON!\n');
    fprintf('  → Thruster helps but cannot fully eliminate charging\n');
else
    fprintf('  ~ phi_ON (%.2f V) in hysteresis zone [%.0f, %.0f] V\n', phiOn, V_ON, V_OFF);
    fprintf('  → Partial mitigation, thruster should stay ON\n');
end
fprintf('\n');

%% Charging Severity Assessment
fprintf('======================================================================\n');
fprintf('CHARGING SEVERITY AT 0.044 AU: CRITICAL\n');
fprintf('======================================================================\n');
fprintf('\n');
fprintf('Assessment:\n');
fprintf('  • This is the WORST-CASE scenario in the model range\n');
fprintf('  • Spacecraft experiences extreme negative charging\n');
fprintf('  • phi_OFF = %.2f V (extremely negative without mitigation)\n', phiOff);
fprintf('  • phi_ON  = %.2f V (much improved with thruster ON)\n', phiOn);
fprintf('  • Thruster reduces charging by %.2f V (%.1f%% improvement)\n', ...
    abs(phiOff - phiOn), abs((phiOn - phiOff) / phiOff * 100));
fprintf('\n');
fprintf('Conclusion:\n');
fprintf('  The electric thruster SIGNIFICANTLY improves the charging condition\n');
fprintf('  at close solar approach, making the mission safer.\n');
fprintf('\n');

%% Visualization
fprintf('----------------------------------------------------------------------\n');
fprintf('Creating visualization...\n');
fprintf('----------------------------------------------------------------------\n');

% Create comparison plot
figure('Position', [100, 100, 800, 600]);

% Plot potentials across range
x_range = linspace(0.044, 1.0, 200);
[phiOff_range, phiOn_range] = Phi_sunlit_models(x_range);

subplot(2,1,1);
plot(x_range, phiOff_range, 'b-', 'LineWidth', 2, 'DisplayName', '\phi_{OFF} (thruster OFF)');
hold on;
plot(x_range, phiOn_range, 'r-', 'LineWidth', 2, 'DisplayName', '\phi_{ON} (thruster ON)');
yline(V_ON, 'k--', 'LineWidth', 1.5, 'DisplayName', 'V_{ON} = -20V');
yline(V_OFF, 'k:', 'LineWidth', 1.5, 'DisplayName', 'V_{OFF} = -12V');
plot(x_AU, phiOff, 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b', ...
    'DisplayName', sprintf('0.044 AU: \\phi_{OFF} = %.2f V', phiOff));
plot(x_AU, phiOn, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r', ...
    'DisplayName', sprintf('0.044 AU: \\phi_{ON} = %.2f V', phiOn));
xlabel('Heliocentric Distance (AU)');
ylabel('Spacecraft Potential (V)');
title('Spacecraft Potential vs Distance from Sun');
legend('Location', 'best');
grid on;
set(gca, 'FontSize', 11);

% Zoom in on critical region
subplot(2,1,2);
x_critical = linspace(0.044, 0.3, 200);
[phiOff_crit, phiOn_crit] = Phi_sunlit_models(x_critical);
plot(x_critical, phiOff_crit, 'b-', 'LineWidth', 2, 'DisplayName', '\phi_{OFF}');
hold on;
plot(x_critical, phiOn_crit, 'r-', 'LineWidth', 2, 'DisplayName', '\phi_{ON}');
yline(V_ON, 'k--', 'LineWidth', 1.5);
yline(V_OFF, 'k:', 'LineWidth', 1.5);
plot(x_AU, phiOff, 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b');
plot(x_AU, phiOn, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
xlabel('Heliocentric Distance (AU)');
ylabel('Spacecraft Potential (V)');
title('Critical Region (0.044 - 0.3 AU) - Zoomed View');
legend('Location', 'best');
grid on;
set(gca, 'FontSize', 11);

sgtitle(sprintf('Spacecraft Potential at 0.044 AU: \\phi_{OFF} = %.2f V, \\phi_{ON} = %.2f V', ...
    phiOff, phiOn), 'FontSize', 13, 'FontWeight', 'bold');

fprintf('\n✓ Visualization complete!\n');
fprintf('\n');
fprintf('======================================================================\n');
fprintf('DEMONSTRATION COMPLETE\n');
fprintf('======================================================================\n');
fprintf('\n');
fprintf('Summary:\n');
fprintf('  At 0.044 AU (closest approach):\n');
fprintf('    • phi_OFF = %.2f V → Thruster must turn ON\n', phiOff);
fprintf('    • phi_ON  = %.2f V → Charging successfully mitigated\n', phiOn);
fprintf('    • Improvement: %.2f V (%.1f%%)\n', ...
    abs(phiOff - phiOn), abs((phiOn - phiOff) / phiOff * 100));
fprintf('\n');
fprintf('  The charging mitigation controller is essential for\n');
fprintf('  spacecraft safety at close solar approaches!\n');
fprintf('\n');
