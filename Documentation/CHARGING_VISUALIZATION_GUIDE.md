# Spacecraft Charging Mitigation - Visualization & Data Export Guide

## Overview

The DART mission now includes comprehensive spacecraft charging mitigation monitoring, visualization, and data export capabilities. This document explains what data is collected, how it's visualized, and where to find the outputs.

---

## Features Added

### 1. Real-Time Telemetry Collection

During the mission simulation, the following data is collected at each time step:

**Charging Data:**
- `time_sec` - Simulation time [seconds]
- `x_AU` - Heliocentric distance [AU]
- `isSunlit` - Boolean flag (1 = sunlit, 0 = eclipse)
- `phi_pred` - Predicted spacecraft potential [V]
- `phiOff_pred` - Predicted potential with thruster OFF [V]
- `phiOn_pred` - Predicted potential with thruster ON [V]

**Mitigation Control:**
- `thruster_is_on` - Previous thruster state
- `thruster_cmd` - Current thruster command (1 = ON, 0 = OFF)
- `reason_code` - Controller decision reason (string)
- `power_consumption` - EP thruster power draw [W] (50W when ON, 0W when OFF)

**Configuration:**
- `V_ON` - Threshold to turn thruster ON [V] (default: -20V)
- `V_OFF` - Threshold to turn thruster OFF [V] (default: -12V)

**Storage Location:** `mission.true_SC{i_SC}.software_SC_executive.store.charging`

---

## Visualization

### Charging Mitigation Figure

After running `Mission_DART`, a new figure is automatically generated:

**Figure Name:** "Spacecraft Charging & Mitigation"

**Contains 3 Subplots:**

#### Subplot 1: Spacecraft Potential vs Time
- **Blue solid line:** Actual predicted spacecraft potential
- **Red dashed line:** Predicted potential with thruster OFF (phiOff)
- **Green dashed line:** Predicted potential with thruster ON (phiOn)
- **Red horizontal line:** V_ON threshold (-20V)
- **Green horizontal line:** V_OFF threshold (-12V)
- **Black dotted line:** Zero reference

This shows how the spacecraft potential varies over the mission and compares it to the control thresholds.

#### Subplot 2: EP Thruster Activation
- **Blue stairs plot:** Thruster command state (1 = ON, 0 = OFF)
- **Gray shaded regions:** Eclipse periods (when spacecraft is in shadow)

This shows when the EP thruster was activated for charging mitigation.

#### Subplot 3: Power Consumption
- **Red stairs plot:** Power consumption for mitigation [W]

This shows the 50W power draw when the EP thruster is active for charging mitigation.

**Saved To:**
- `Output/charging_mitigation.fig` (MATLAB format - can be reopened and edited)
- `Output/charging_mitigation.png` (PNG image for reports/presentations)

---

## Console Summary

After the simulation completes, a detailed summary is printed to the console:

```
================================================================================
           SPACECRAFT CHARGING MITIGATION SUMMARY - SC 1
================================================================================

SPACECRAFT POTENTIAL:
  Minimum Potential:        +9.04 V (at t = 12.50 hours)
  Maximum Potential:        +9.15 V
  Mean Potential:           +9.10 V

CONTROLLER CONFIGURATION:
  V_ON Threshold:           -20 V (turn thruster ON)
  V_OFF Threshold:          -12 V (turn thruster OFF)
  Hysteresis Gap:           8 V

THRUSTER ACTIVATION:
  Total Time ON:            0.00 hours (0.0 minutes)
  Percentage of Mission:    0.00%
  Number of Activations:    0

POWER & ENERGY:
  EP Thruster Power:        50 W (when ON)
  Total Energy Used:        0.00 W-hr (0.0000 kW-hr)

MISSION DURATION:
  Total Simulation Time:    24.00 hours (1.00 days)

RESULT: No charging mitigation required - spacecraft potential remained safe
================================================================================
```

**Key Metrics Explained:**

- **Minimum/Maximum Potential:** Range of spacecraft potential during mission
- **Mean Potential:** Average spacecraft potential
- **Total Time ON:** How long the EP thruster was active for mitigation
- **Percentage of Mission:** What fraction of the mission used active mitigation
- **Number of Activations:** How many times the thruster was turned ON
- **Total Energy Used:** Energy consumed by EP thruster for mitigation

---

## Data Export

### Charging Mitigation Data File

**Filename:** `Output/charging_mitigation_data.mat`

**Contents:**

```matlab
charging_data = 
    % Time vectors
    time_sec: [n×1 double]           % Time in seconds
    time_hours: [n×1 double]         % Time in hours
    
    % Environmental data
    x_AU: [n×1 double]               % Heliocentric distance [AU]
    isSunlit: [n×1 double]           % Sunlight flag (1/0)
    
    % Potential predictions
    phi_pred: [n×1 double]           % Predicted potential [V]
    phiOff_pred: [n×1 double]        % Potential with thruster OFF [V]
    phiOn_pred: [n×1 double]         % Potential with thruster ON [V]
    
    % Thruster state
    thruster_is_on: [n×1 double]     % Previous state
    thruster_cmd: [n×1 double]       % Current command (1/0)
    power_consumption: [n×1 double]  % Power draw [W]
    reason_code: {n×1 cell}          % Decision reason strings
    
    % Configuration
    V_ON: -20                        % Turn ON threshold [V]
    V_OFF: -12                       % Turn OFF threshold [V]
    
    % Summary statistics
    summary: 
        min_potential: 9.04          % [V]
        max_potential: 9.15          % [V]
        mean_potential: 9.10         % [V]
        time_min_potential: 45000    % [sec]
        thruster_on_time_sec: 0      % [sec]
        thruster_on_time_hours: 0    % [hours]
        thruster_on_percent: 0       % [%]
        thruster_activations: 0      % [count]
        total_energy_Wh: 0           % [W-hr]
        total_energy_kWh: 0          % [kW-hr]
        total_time_sec: 86400        % [sec]
```

**How to Load and Use:**

```matlab
% Load the data
load('Output/charging_mitigation_data.mat');

% Plot custom analysis
figure;
plot(charging_data.time_hours, charging_data.phi_pred);
xlabel('Time [hours]');
ylabel('Spacecraft Potential [V]');
title('Custom Charging Analysis');

% Access summary
disp(['Minimum potential: ', num2str(charging_data.summary.min_potential), ' V']);
disp(['Thruster was ON for: ', num2str(charging_data.summary.thruster_on_time_hours), ' hours']);
```

---

## Expected Results for DART Mission

### At Bennu (0.896 - 1.356 AU)

**Sunlit Conditions:**
- Predicted potential: ~+9V (slightly positive)
- Assessment: **SAFE** - no mitigation needed
- Thruster state: OFF

**Eclipse Conditions (if applicable):**
- Predicted potential: ~-15V (moderately negative)
- Assessment: Above -20V threshold, **ACCEPTABLE**
- Thruster state: OFF (above critical threshold)

**Charging Severity:** **MINIMAL**
- Distance from Sun: 0.896 - 1.356 AU
- Charging model valid range: 0.044 - 1.0 AU
- At Bennu, charging is not severe enough to require mitigation

**Expected Output:**
- Spacecraft potential: +9V ± 1V
- Thruster activations: 0
- Energy used: 0 W-hr
- Result: "No charging mitigation required - spacecraft potential remained safe"

---

## Interpretation Guide

### Spacecraft Potential Values

| Potential Range | Severity | Action |
|-----------------|----------|--------|
| > -12V | SAFE | No action needed |
| -12V to -20V | HYSTERESIS ZONE | Maintain current state |
| ≤ -20V | CRITICAL | Thruster turns ON |

### Reason Codes

- `'HOLD'` - Maintaining current state (within hysteresis zone)
- `'NEGATIVE_THRESHOLD_ON'` - Thruster turned ON (potential ≤ -20V)
- `'RECOVERY_OFF'` - Thruster turned OFF (potential ≥ -12V)
- `'SUNLIGHT_POLICY_OFF'` - Thruster prevented by sunlight policy

### Typical Charging Scenarios

**Scenario 1: Far from Sun (>0.8 AU) - DART at Bennu**
- Potential: Slightly positive (+5V to +10V)
- Mitigation: Not needed
- Thruster: OFF throughout mission

**Scenario 2: Moderate Distance (0.3 - 0.8 AU)**
- Potential: Varies, may reach -15V to -5V
- Mitigation: Occasional activation if below -20V
- Thruster: ON during critical periods

**Scenario 3: Close to Sun (<0.3 AU) - Solar Probe**
- Potential: Highly negative (-50V to -500V)
- Mitigation: Continuously active
- Thruster: ON most of the time

---

## Troubleshooting

### No Charging Data Available

If you see: `Warning: No charging mitigation data available`

**Possible Causes:**
1. Charging mitigation not configured in Mission file
2. No EP thruster in spacecraft configuration
3. Simulation didn't complete

**Solution:**
Check that `mission.true_SC{i_SC}.charging_mitigation_config` exists and contains:
```matlab
charging_mitigation_config.V_ON = -20;
charging_mitigation_config.V_OFF = -12;
charging_mitigation_config.policy_require_sunlight_for_ep = false;
charging_mitigation_config.clamp_range = [0.044, 1.0];
```

### Empty or Zero Data

**Possible Causes:**
1. Simulation time too short
2. Storage not activated
3. Mission didn't run to completion

**Solution:**
Check `mission.storage.num_storage_steps` and ensure simulation completed.

---

## Customization

### Changing Thresholds

Edit in `Mission_DART.m`:
```matlab
init_data_charging.V_ON = -20;   % More negative = less sensitive
init_data_charging.V_OFF = -12;  % Less negative = more conservative
```

Larger hysteresis gap (V_OFF - V_ON) reduces thruster cycling but may leave spacecraft at higher potential for longer.

### Changing EP Thruster Power

Edit in `Mission_DART.m`:
```matlab
init_data.instantaneous_power_consumption = 50.0;  % [W] Change this value
init_data.command_actuation_power_consumed = 50.0; % [W] Keep in sync
```

And update in `func_software_SC_executive_DART.m` where power is logged.

---

## References

- **Charging Model:** `Supporting_Functions/Phi_sunlit_models.m`
- **Controller:** `Supporting_Functions/func_control_charging_mitigation_EP.m`
- **Visualization:** `Supporting_Functions/plot/mission_small_bodies/func_plot_charging_mitigation.m`
- **Summary:** `Supporting_Functions/mission_specific/DART/func_print_charging_mitigation_summary.m`
- **Documentation:** `Documentation/CHARGING_MITIGATION_README.md`

---

**Last Updated:** 2024-02-04  
**Version:** 1.0  
**Status:** Implemented and tested
