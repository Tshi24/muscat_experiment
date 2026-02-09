%% Mission_EVS.m - Earth-Venus-Sun Charging Mitigation Mission
%
% Mission Profile:
%   - Earth departure (1.0 AU)
%   - Venus gravity assist flyby (0.72 AU)  
%   - Near-Sun perihelion approach (0.044 AU)
%   - Inspired by Parker Solar Probe trajectory
%   - NO SPICE DATA REQUIRED - uses Keplerian orbit propagation
%
% Key Features:
%   - Autonomous mode management (Point to Sun, Maximize Power, Charging Mitigation)
%   - Spacecraft charging monitoring and mitigation
%   - EP thruster with realistic specifications (723 W, 35 mN, 1840s ISP)
%   - Propellant consumption tracking
%   - Battery and solar power coupling
%   - Attitude performance monitoring
%
% Mission Duration: ~357 days (default)
%
% Author: Charging Mitigation Team
% Date: 2026-02-09
% Based on: Mission_DART.m

clear mission
close all

%% Mission Parameters
mission_duration_days = 357; % ~1 year mission (Earth → Venus → Sun)
mission.name = 'EVS_Charging_Mitigation';
mission.description = 'Earth-Venus-Sun mission with autonomous charging mitigation';

% Charging scenario (for compatibility with existing code)
mission.charging_scenario = 'EVS_PARKER'; % Parker Solar Probe-inspired trajectory

fprintf('\n========================================\n');
fprintf('  MISSION: %s\n', mission.name);
fprintf('  Duration: %.0f days (%.1f months)\n', mission_duration_days, mission_duration_days/30);
fprintf('  Trajectory: Parker Solar Probe-inspired\n');
fprintf('  Earth (1.0 AU) → Venus (0.72 AU) → Sun (0.044 AU)\n');
fprintf('========================================\n\n');

%% Timing
mission.start_date_str = '1-Jan-2026 00:00:00.00';
mission.start_date_JD = 2460676.5; % JD for 2026-01-01 00:00:00
mission.duration_days = mission_duration_days;
mission.duration_sec = mission_duration_days * 86400;

% Timestep
mission.timestep_sec = 3600; % 1 hour timestep (good balance)
mission.num_timesteps = ceil(mission.duration_sec / mission.timestep_sec);

fprintf('Simulation setup:\n');
fprintf('  Start date: %s\n', mission.start_date_str);
fprintf('  Duration: %.0f days\n', mission.duration_days);
fprintf('  Timestep: %.0f seconds (%.1f hours)\n', mission.timestep_sec, mission.timestep_sec/3600);
fprintf('  Total steps: %d\n\n', mission.num_timesteps);

%% Generate Parker-Inspired Trajectory
fprintf('Generating Parker Solar Probe-inspired trajectory...\n');
trajectory = func_compute_parker_trajectory(mission_duration_days);

% Store trajectory in mission structure
mission.trajectory = trajectory;
mission.use_trajectory = true; % Flag to use pre-computed trajectory

fprintf('Trajectory generated successfully!\n');
fprintf('  Distance range: %.3f - %.3f AU\n', min(trajectory.r_sun), max(trajectory.r_sun));
fprintf('  Mission phases: %d\n\n', length(trajectory.phase_names));

%% Environment
mission.environment = 'Solar_System';

% Solar system bodies (simplified - Sun only for now)
mission.true_solar_system.SS_body_names = {'Sun'};
mission.true_solar_system.num_bodies = 1;

% Sun properties
mission.true_solar_system.SS_body{1}.name = 'Sun';
mission.true_solar_system.SS_body{1}.ID = 10; % SPICE ID for Sun
mission.true_solar_system.SS_body{1}.radius = 696000; % km
mission.true_solar_system.SS_body{1}.mass = 1.989e30; % kg
mission.true_solar_system.SS_body{1}.mu = 1.32712440018e11; % km^3/s^2

%% Target (Sun for this mission)
mission.num_target = 1;
mission.target_names = {'Sun'};

% Target 1: Sun
init_target.name = 'Sun';
init_target.SPICE_name = 'SUN';
init_target.SPICE_ID = 10;
init_target.shape = 'Sphere';
init_target.radius = 696000; % km
init_target.use_trajectory = false; % Sun is stationary at origin

mission.true_target{1} = True_Target_Simple();
mission.true_target{1}.name = init_target.name;
mission.true_target{1}.radius = init_target.radius;
mission.true_target{1}.position = [0, 0, 0]; % Sun at origin
mission.true_target{1}.velocity = [0, 0, 0];

fprintf('Target: %s (radius: %.0f km)\n\n', mission.true_target{1}.name, mission.true_target{1}.radius);

%% Spacecraft Configuration
mission.num_SC = 1;
i_SC = 1;

fprintf('========================================\n');
fprintf('  SPACECRAFT CONFIGURATION\n');
fprintf('========================================\n\n');

%% SC Basic Properties
init_data.name = 'EVS_Spacecraft';
init_data.mass = 685; % kg (similar to Parker Solar Probe)
init_data.area = 4.5; % m^2
init_data.drag_coefficient = 2.2;

fprintf('Spacecraft: %s\n', init_data.name);
fprintf('  Mass: %.0f kg\n', init_data.mass);
fprintf('  Area: %.1f m^2\n\n', init_data.area);

%% SC Initial State (from trajectory)
% Use first point of Parker trajectory
init_data.position = trajectory.position(1, :); % [km] (row vector)
init_data.velocity = trajectory.velocity(1, :); % [km/s] (row vector)

fprintf('Initial state (Earth orbit):\n');
fprintf('  Position: [%.3f, %.3f, %.3f] km\n', init_data.position);
fprintf('  Velocity: [%.3f, %.3f, %.3f] km/s\n', init_data.velocity);
fprintf('  Distance from Sun: %.3f AU\n\n', trajectory.r_sun(1));

%% Dynamics Mode
init_data.dynamics_true_SC = 'None'; % Use pre-computed trajectory
fprintf('Dynamics: Pre-computed trajectory (Parker-inspired)\n\n');

%% Attitude and Control
init_data.attitude_true_SC = 'Nadir';
init_data.attitude_control_mode = 'Point Thruster along DeltaV direction'; % Will be overridden by mode manager

% Attitude parameters
init_data.I_SC = [100, 0, 0; 0, 150, 0; 0, 0, 120]; % kg*m^2 (simplified)
init_data.max_wheel_torque = 0.2; % N*m
init_data.max_wheel_momentum = 10; % N*m*s

fprintf('Attitude control: Autonomous mode management\n');
fprintf('  Initial mode: Point Thruster along DeltaV direction\n');
fprintf('  Inertia: diag([%.0f, %.0f, %.0f]) kg*m^2\n\n', init_data.I_SC(1,1), init_data.I_SC(2,2), init_data.I_SC(3,3));

%% Navigation
init_data.navigation = 'Perfect'; % Perfect navigation for this study
fprintf('Navigation: Perfect (simplified for charging study)\n\n');

%% Power System
fprintf('========================================\n');
fprintf('  POWER SYSTEM\n');
fprintf('========================================\n\n');

% Solar Panels
init_data.solar_panel_area = 2.0; % m^2 (Parker has ~0.38 m^2, we use larger)
init_data.solar_panel_efficiency = 0.30; % 30% efficiency
init_data.solar_constant = 1361; % W/m^2 at 1 AU

fprintf('Solar Panels:\n');
fprintf('  Area: %.2f m^2\n', init_data.solar_panel_area);
fprintf('  Efficiency: %.0f%%\n', init_data.solar_panel_efficiency*100);
fprintf('  Power @ 1 AU: %.0f W\n', init_data.solar_panel_area * init_data.solar_panel_efficiency * init_data.solar_constant);
fprintf('  Power @ 0.044 AU: %.0f kW\n\n', init_data.solar_panel_area * init_data.solar_panel_efficiency * init_data.solar_constant / 0.044^2 / 1000);

% Battery
init_data.battery_capacity = 100; % Ah
init_data.battery_voltage = 28; % V
init_data.battery_initial_SOC = 0.95; % 95% charged

fprintf('Battery:\n');
fprintf('  Capacity: %.0f Ah @ %.0f V = %.1f kWh\n', ...
    init_data.battery_capacity, init_data.battery_voltage, ...
    init_data.battery_capacity * init_data.battery_voltage / 1000);
fprintf('  Initial SoC: %.0f%%\n\n', init_data.battery_initial_SOC*100);

% Baseline power consumption
init_data.baseline_power = 150; % W (spacecraft bus)

fprintf('Baseline power: %.0f W\n\n', init_data.baseline_power);

%% Electric Propulsion Thruster (Updated User Specs)
fprintf('========================================\n');
fprintf('  ELECTRIC THRUSTER (USER SPECS)\n');
fprintf('========================================\n\n');

i_HW = 1;
init_data.num_true_SC_EP_thruster = 1;

% USER-PROVIDED SPECIFICATIONS (from problem statement)
init_data.thruster_ISP = 1840; % seconds (was 3000)
init_data.thrust = 0.035; % N = 35 mN (was 0.1 N)
init_data.power = 723; % W (was 50 W) ← 14.5x higher!
init_data.mass_flow = 1.99e-6; % kg/s (NEW)
init_data.thruster_current = 1.44; % A (NEW)

% Propellant
init_data.propellant_mass_initial = 15; % kg (generous budget for long mission)

fprintf('EP Thruster Specifications:\n');
fprintf('  Thrust: %.1f mN\n', init_data.thrust * 1000);
fprintf('  ISP: %.0f seconds\n', init_data.thruster_ISP);
fprintf('  Power: %.0f W\n', init_data.power);
fprintf('  Mass flow: %.2e kg/s\n', init_data.mass_flow);
fprintf('  Current: %.2f A\n', init_data.thruster_current);
fprintf('  Initial propellant: %.1f kg\n\n', init_data.propellant_mass_initial);

% Verify consistency (F = mdot * Isp * g0)
g0 = 9.80665; % m/s^2
thrust_check = init_data.mass_flow * init_data.thruster_ISP * g0;
fprintf('Thrust verification: F = mdot * Isp * g0\n');
fprintf('  Calculated: %.1f mN\n', thrust_check * 1000);
fprintf('  Specified: %.1f mN\n', init_data.thrust * 1000);
fprintf('  Match: %s\n\n', iif(abs(thrust_check - init_data.thrust) < 0.001, 'YES ✓', 'NO (using specified)'));

% Create EP thruster
init_data.EP_thruster_pointing_direction = [1, 0, 0]; % Body-fixed direction

mission.true_SC{i_SC}.true_SC_EP_thruster{i_HW} = True_SC_EP_Thruster(init_data, mission, i_SC, i_HW);

fprintf('EP Thruster created successfully!\n\n');

%% Charging Mitigation Configuration
fprintf('========================================\n');
fprintf('  CHARGING MITIGATION\n');
fprintf('========================================\n\n');

% Charging mitigation thresholds
init_data_charging.V_ON = -10; % V - Turn thruster ON when potential ≤ this
init_data_charging.V_OFF = -6; % V - Turn thruster OFF when potential ≥ this
init_data_charging.hysteresis_gap = init_data_charging.V_ON - init_data_charging.V_OFF; % 4V

% Policy
init_data_charging.policy_require_sunlight_for_ep = false; % Allow in eclipse (comprehensive protection)

% Clamp range for models (valid from 0.044 to 1.0 AU)
init_data_charging.x_AU_min = 0.044;
init_data_charging.x_AU_max = 1.0;

% EP thruster power (for tracking)
init_data_charging.P_thruster = init_data.power; % W

% Store in init_data
init_data.charging_mitigation = init_data_charging;

fprintf('=== CHARGING MITIGATION CONFIGURATION ===\n');
fprintf('  V_ON Threshold:  %.0f V (thruster turns ON when potential <= %.0f V)\n', ...
    init_data_charging.V_ON, init_data_charging.V_ON);
fprintf('  V_OFF Threshold: %.0f V (thruster turns OFF when potential >= %.0f V)\n', ...
    init_data_charging.V_OFF, init_data_charging.V_OFF);
fprintf('  Hysteresis Gap:  %.0f V\n', abs(init_data_charging.hysteresis_gap));
fprintf('  Eclipse Policy:  %s\n', iif(init_data_charging.policy_require_sunlight_for_ep, ...
    'Require sunlight for EP', 'Allow in eclipse (comprehensive protection)'));
fprintf('  Valid Range:     %.3f - %.3f AU\n', init_data_charging.x_AU_min, init_data_charging.x_AU_max);
fprintf('  EP Power:        %.0f W\n', init_data_charging.P_thruster);
fprintf('=========================================\n\n');

%% Software Executive with Autonomous Mode Manager
fprintf('Creating Software Executive with Autonomous Mode Manager...\n\n');

% Initialize navigation
mission.true_SC{i_SC}.true_SC_navigation = True_SC_Navigation(init_data, mission);

% Initialize software executive (includes mode manager and charging controller)
mission.true_SC{i_SC}.software_SC_executive = Software_SC_Executive(init_data, mission, i_SC);

fprintf('Software Executive created!\n');
fprintf('  Includes: Autonomous mode manager\n');
fprintf('  Includes: Charging mitigation controller\n');
fprintf('  Includes: Propellant tracking\n');
fprintf('  Includes: Attitude performance monitoring\n\n');

%% Storage Configuration
mission.storage.num_storage_steps = mission.num_timesteps;
mission.storage.k_storage = 0; % Initialize counter

fprintf('Storage configured: %d timesteps\n\n', mission.storage.num_storage_steps);

%% Mission Summary
fprintf('========================================\n');
fprintf('  MISSION SUMMARY\n');
fprintf('========================================\n\n');

fprintf('Mission: %s\n', mission.name);
fprintf('Duration: %.0f days (%.1f months)\n', mission.duration_days, mission.duration_days/30);
fprintf('Trajectory: Parker Solar Probe-inspired\n');
fprintf('  Phase 1: Earth departure (1.0 AU) - 30 days\n');
fprintf('  Phase 2: Earth-Venus transfer - 146 days\n');
fprintf('  Phase 3: Venus flyby (0.72 AU) - 30 days\n');
fprintf('  Phase 4: Venus-Sun transfer - 121 days\n');
fprintf('  Phase 5: Near-Sun operations (0.044 AU) - remainder\n\n');

fprintf('Spacecraft: %s (%.0f kg)\n', init_data.name, init_data.mass);
fprintf('Power: Solar (%.1f m^2) + Battery (%.0f Ah)\n', ...
    init_data.solar_panel_area, init_data.battery_capacity);
fprintf('Propulsion: EP thruster (%.1f mN, %.0f W, %.0f s ISP)\n', ...
    init_data.thrust*1000, init_data.power, init_data.thruster_ISP);
fprintf('  Propellant budget: %.1f kg\n', init_data.propellant_mass_initial);

fprintf('\nAutonomous Operations:\n');
fprintf('  1. Point towards Sun (default cruise)\n');
fprintf('  2. Check spacecraft potential\n');
fprintf('  3. Activate charging mitigation if φ ≤ %.0f V\n', init_data_charging.V_ON);
fprintf('  4. Maximize solar power if battery low\n');
fprintf('  5. Monitor and track all systems\n\n');

fprintf('Expected Behavior:\n');
fprintf('  @ Earth (1.0 AU):   φ ≈ +9V  → Thruster OFF\n');
fprintf('  @ Venus (0.72 AU):  φ ≈ +5V  → Thruster occasional\n');
fprintf('  @ Sun (0.044 AU):   φ ≈ -28V → Thruster ON (protection: φ → -2V)\n\n');

fprintf('========================================\n');
fprintf('  MISSION CONFIGURATION COMPLETE!\n');
fprintf('========================================\n\n');

fprintf('Next step: Run main_v3 to execute the mission simulation.\n');
fprintf('Command: cd ../Main; main_v3\n\n');

%% Save mission
save('mission_EVS_config.mat', 'mission');
fprintf('Mission configuration saved to: mission_EVS_config.mat\n\n');

% Helper function for inline if
function result = iif(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end
