# Spacecraft Charging Mitigation Controller

## Overview

This charging mitigation system predicts spacecraft potential (sunlit charging) and autonomously toggles the electric propulsion (EP) thruster ON/OFF to mitigate strong negative charging. This is particularly important for spacecraft operating close to the Sun where intense solar radiation can cause significant negative charging.

## Components

### 1. Phi_sunlit_models.m
**Location:** `/Supporting_Functions/Phi_sunlit_models.m`

SPIS-based curve-fit models for predicting spacecraft potential.

**Inputs:**
- `x_AU` - Heliocentric distance in AU (can be scalar or vector)

**Outputs:**
- `phiOff` - Predicted potential (V) with thruster OFF
- `phiOn` - Predicted potential (V) with thruster ON

**Valid Range:** 0.044 to 1.0 AU

**Models:**
```matlab
phiOff = 8.39628 - 0.000770893/(xi^4) + 0.029318/(xi^3) - 0.362418/(xi^2) + 0.541516/xi + 0.623116*(xi^2)
phiOn  = -5.6241689717 - 0.0001905435754/(xi^4) + 0.0060468979089/(xi^3) - 0.0319720512141/(xi^2) - 1.0811794594*(xi^2)
```

### 2. func_control_charging_mitigation_EP.m
**Location:** `/Supporting_Functions/func_control_charging_mitigation_EP.m`

Main controller function that implements the charging mitigation logic.

**Inputs:**
- `config` - Configuration struct with fields:
  - `V_ON` - Threshold to turn thruster ON (default: -20 V)
  - `V_OFF` - Threshold to turn thruster OFF (default: -12 V)
  - `policy_require_sunlight_for_ep` - Only allow EP ON in sunlight (default: true)
  - `clamp_range` - [min max] for x_AU clamping (default: [0.044, 1.0])
- `x_AU` - Heliocentric distance in AU
- `isSunlit` - Boolean (true if spacecraft is in sunlight)
- `thruster_is_on` - Current EP thruster state (true/false)

**Outputs:**
- `thruster_cmd` - Commanded thruster state (true=ON, false=OFF)
- `telemetry` - Struct with detailed telemetry data

**Control Logic:**
1. Clamp x_AU to valid model range [0.044, 1.0] AU
2. Compute predicted potentials using Phi_sunlit_models
3. Select phi_pred based on current thruster state
4. Apply hysteresis-based decision logic:
   - If thruster OFF and phi_pred ≤ V_ON → Turn ON
   - If thruster ON and phi_pred ≥ V_OFF → Turn OFF
   - Otherwise → HOLD current state
5. Apply sunlight policy if enabled

### 3. Integration with DART Mission

**Mission Configuration:** `/Mission/Mission_DART.m`
- Added EP thruster hardware (1 EP thruster)
- Added charging mitigation configuration parameters

**Executive Integration:** `/Supporting_Functions/mission_specific/DART/func_software_SC_executive_DART.m`
- Controller is called at each time step (section 2.5)
- Computes heliocentric distance from Sun position
- Gets sunlight status from navigation
- Commands EP thruster based on controller output
- Stores telemetry for post-processing

**Storage:** `/Supporting_Functions/mission_specific/DART/func_software_SC_executive_Dart_constructor.m`
- Telemetry stored in `mission.true_SC{i_SC}.software_SC_executive.store.charging`

## Configuration Parameters

The charging mitigation system can be configured in the mission file with these parameters:

```matlab
init_data_charging.V_ON = -20;   % [V] Turn thruster ON when phi <= -20 V
init_data_charging.V_OFF = -12;  % [V] Allow thruster OFF when phi >= -12 V
init_data_charging.policy_require_sunlight_for_ep = true;  % Only allow EP ON in sunlight
init_data_charging.clamp_range = [0.044, 1.0];  % [AU] Valid model range
```

### Tuning Guidelines

- **V_ON:** More negative values = less sensitive (thruster activates less often)
- **V_OFF:** Less negative values = more conservative (thruster turns off sooner)
- **Hysteresis Gap (V_OFF - V_ON):** Larger gap prevents chatter but may be less responsive
- **policy_require_sunlight_for_ep:** Set to `false` if you want charging mitigation even in eclipse

## Telemetry

The controller stores the following telemetry at each time step:

- `time_sec` - Simulation time (seconds)
- `x_AU` - Heliocentric distance (AU) after clamping
- `isSunlit` - Boolean sunlight status
- `phiOff_pred` - Predicted potential with thruster OFF (V)
- `phiOn_pred` - Predicted potential with thruster ON (V)
- `phi_pred` - Predicted potential based on current state (V)
- `thruster_is_on` - Input thruster state
- `thruster_cmd` - Commanded thruster state
- `reason_code` - Decision reason string:
  - `'NEGATIVE_THRESHOLD_ON'` - Thruster turned ON due to negative threshold
  - `'RECOVERY_OFF'` - Thruster turned OFF due to recovery
  - `'HOLD'` - Maintaining current state (hysteresis zone)
  - `'SUNLIGHT_POLICY_OFF'` - Thruster prevented from turning ON due to sunlight policy

## Testing

### Unit Tests
**Location:** `/Supporting_Functions/test_charging_mitigation_controller.m`

Run the unit tests in MATLAB:
```matlab
addpath(genpath('Supporting_Functions'));
test_charging_mitigation_controller;
```

The test suite validates:
1. Threshold detection (OFF → ON transition)
2. Recovery threshold (ON → OFF transition)
3. Hysteresis (no chatter in intermediate zone)
4. Sunlight policy enforcement
5. x_AU clamping to valid range
6. Sweep test for consistent behavior

### Integration Testing

To verify the integration with the DART mission:

1. Run the DART mission simulation:
```matlab
cd Mission
Mission_DART
cd ../Main
main_v3
```

2. Check telemetry after simulation:
```matlab
% Access charging mitigation telemetry
charging_data = mission.true_SC{1}.software_SC_executive.store.charging;

% Plot predicted potentials
figure;
plot(charging_data.time_sec, charging_data.phiOff_pred, 'b-', 'DisplayName', 'Phi OFF');
hold on;
plot(charging_data.time_sec, charging_data.phiOn_pred, 'r-', 'DisplayName', 'Phi ON');
plot(charging_data.time_sec, charging_data.phi_pred, 'k-', 'LineWidth', 2, 'DisplayName', 'Phi Pred');
xlabel('Time (sec)');
ylabel('Potential (V)');
legend('show');
title('Spacecraft Potential Predictions');
grid on;

% Plot thruster commands
figure;
subplot(2,1,1);
plot(charging_data.time_sec, charging_data.x_AU, 'b-');
xlabel('Time (sec)');
ylabel('Heliocentric Distance (AU)');
title('Heliocentric Distance');
grid on;

subplot(2,1,2);
stairs(charging_data.time_sec, charging_data.thruster_cmd, 'r-', 'LineWidth', 2);
xlabel('Time (sec)');
ylabel('Thruster Command (ON=1, OFF=0)');
title('EP Thruster Commands');
grid on;
ylim([-0.1, 1.1]);
```

## Safety Features

1. **Range Clamping:** x_AU is automatically clamped to [0.044, 1.0] AU to prevent model extrapolation
2. **Hysteresis:** V_OFF > V_ON prevents rapid ON/OFF cycling (chatter)
3. **Sunlight Policy:** Optional policy to prevent EP operation outside sunlight
4. **Graceful Degradation:** Controller handles missing EP thruster hardware gracefully

## Known Limitations

1. Models are valid only for x_AU in [0.044, 1.0] AU
2. Models assume sunlit conditions (eclipse conditions may differ)
3. Single EP thruster is assumed (controller uses first thruster if multiple exist)
4. No minimum ON/OFF time constraints currently implemented (can be added if needed)

## Future Enhancements

Potential improvements for future versions:

1. **Minimum ON/OFF Times:** Add `min_on_time` and `min_off_time` to prevent rapid cycling
2. **Eclipse Models:** Separate models for eclipse conditions
3. **Multi-thruster Support:** Distribute charging mitigation across multiple EP thrusters
4. **Adaptive Thresholds:** Adjust V_ON/V_OFF based on mission phase or battery state
5. **Predictive Control:** Use trajectory prediction to anticipate charging conditions

## References

- SPIS (Spacecraft Plasma Interaction Software) simulation data
- MuSCAT (Multi-Spacecraft Simulation and Analysis Tool) framework
- NASA charging mitigation standards and practices

## Author and Maintenance

This charging mitigation controller was implemented as part of the MuSCAT experiment for spacecraft charging research.

**Date:** 2024
**Version:** 1.0
