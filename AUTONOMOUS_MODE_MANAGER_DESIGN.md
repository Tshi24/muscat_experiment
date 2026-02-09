# Autonomous Mode Management System Design

## Executive Summary

This document details the design for an autonomous mode management system that allows the spacecraft to intelligently switch between operational modes during cruise based on spacecraft state, environmental conditions, and mission priorities.

---

## User Requirements

### Autonomous Mode Selection

During cruise from Earth → Venus → Sun, the spacecraft should autonomously:

1. **Point towards Sun** - for thermal control and visibility
2. **Check surface potential** - monitor charging state
3. **Activate charging mitigation** - EP thruster ON if needed
4. **Maximize solar power** - when safe to do so
5. **Additional modes** - as mission requires

### Key Outputs Required

1. **Spacecraft Potential:**
   - Evolution over time and distance
   - Critical threshold crossings
   - Protection effectiveness

2. **Thruster Activation:**
   - ON/OFF events
   - Protection effect on potential
   - Duty cycle statistics

3. **Battery Impact:**
   - State of Charge evolution
   - Charge/discharge rates
   - EP thruster power drain

4. **Solar Panel Performance:**
   - Power generation vs distance
   - Impact of attitude mode
   - Efficiency tracking

5. **Propellant Consumption:**
   - Mass flow tracking
   - Total propellant used
   - Remaining propellant

6. **Attitude Performance:**
   - Pointing accuracy
   - Control effort
   - EP thruster disturbance effects

---

## Updated EP Thruster Specifications

### User-Provided Parameters

| Parameter | Value | Previous | Notes |
|-----------|-------|----------|-------|
| Mass Flow | 1.99e-6 kg/s | N/A | New tracking |
| Current | 1.44 A | N/A | New tracking |
| Thrust | 35 mN | 0.1 N | Reduced by 65% |
| Power | 723 W | 50 W | Increased 14.5x |
| ISP | 1840 s | 3000 s | Reduced 39% |

**Implications:**
- Much higher power consumption (723 W vs 50 W)
- Significant battery drain during activation
- Lower thrust and ISP (less efficient)
- Need to track current and mass flow

---

## Current MuSCAT Mode Structure

### Existing Modes

1. **'Point camera to Target'** - Science observation mode
   - Primary: Camera → Target
   - Secondary: Solar panel → Sun

2. **'Maximize SP Power'** - Power generation mode
   - Primary: Solar panel → Sun
   - Secondary: Antenna → Earth

3. **'Point Thruster along DeltaV direction'** - Maneuver mode
   - Primary: Thruster → ΔV direction
   - Secondary: Solar panel → Sun

4. **'DTE Comm'** - Communications mode
   - Primary: Antenna → Earth
   - Secondary: Solar panel → Sun

### Current Mode Manager

**Location:** `func_software_SC_executive_DART.m`

**Existing Logic:**
```matlab
% Section 2: Power survival check
if battery_SoC < 30%
    mode = 'Maximize SP Power'
    return  % Highest priority
end

% Section 2.5: Charging mitigation
% Already calls charging controller
% Already commands EP thruster
```

**Limitations:**
- No autonomous mode switching beyond power emergency
- No integration of charging mitigation with mode selection
- Manual mode setting for most operations

---

## Proposed Autonomous Mode Manager

### Mode Hierarchy (Priority Order)

```
1. POWER EMERGENCY (SoC < 30%)
   → 'Maximize SP Power'
   
2. CHARGING CRITICAL (φ ≤ V_ON = -10V)
   → 'Charging Mitigation Mode' (NEW)
   → Point towards Sun + EP thruster ON
   
3. CHARGING SAFE (φ ≥ V_OFF = -6V)
   → Deactivate EP thruster
   → Resume normal operations
   
4. CRUISE OPERATIONS (Normal)
   → 'Point towards Sun' or 'Maximize SP Power'
   → Depends on battery SoC and mission phase
   
5. SCIENCE OPERATIONS (When at target)
   → 'Point camera to Target'
   
6. MANEUVER OPERATIONS (Delta-V execution)
   → 'Point Thruster along DeltaV direction'
   
7. COMMUNICATIONS (Scheduled)
   → 'DTE Comm'
```

### New Mode: 'Charging Mitigation Mode'

**Purpose:** Active protection against spacecraft charging

**Pointing:**
- Primary: Solar panel → Sun (maximize visibility and power)
- Secondary: Maintain stable attitude
- Constraint: Allow EP thruster operation

**EP Thruster:**
- State: ON (for ion emission)
- Duration: Until φ ≥ V_OFF
- Power: 723 W continuous

**Telemetry:**
- Record activation time
- Track potential evolution
- Monitor battery drain

---

## Decision Logic Flow

### Mode Selection Algorithm

```
FUNCTION autonomous_mode_selection(SC_state, mission_state)

    % 1. HIGHEST PRIORITY: Power Emergency
    IF battery_SoC < 30% THEN
        RETURN 'Maximize SP Power'
    END
    
    % 2. CRITICAL: Charging Protection
    IF spacecraft_potential <= V_ON (-10V) THEN
        RETURN 'Charging Mitigation Mode'
    END
    
    % 3. If currently in charging mode, check if safe to exit
    IF current_mode == 'Charging Mitigation Mode' THEN
        IF spacecraft_potential >= V_OFF (-6V) THEN
            % Safe to exit, decide next mode
            % Fall through to normal operations
        ELSE
            % Stay in charging mode
            RETURN 'Charging Mitigation Mode'
        END
    END
    
    % 4. NORMAL OPERATIONS: Mission phase dependent
    IF mission_phase == 'CRUISE' THEN
        IF battery_SoC < 50% THEN
            RETURN 'Maximize SP Power'
        ELSE
            RETURN 'Point towards Sun'  % Default cruise attitude
        END
    END
    
    % 5. SCIENCE: At target
    IF mission_phase == 'SCIENCE' AND battery_SoC > 40% THEN
        RETURN 'Point camera to Target'
    END
    
    % 6. MANEUVER: Delta-V execution
    IF deltaV_execution_needed THEN
        RETURN 'Point Thruster along DeltaV direction'
    END
    
    % 7. COMMUNICATIONS: Scheduled
    IF comm_window_active THEN
        RETURN 'DTE Comm'
    END
    
    % 8. DEFAULT: Maximize power
    RETURN 'Maximize SP Power'
    
END FUNCTION
```

### Hysteresis Protection

**Prevent Mode Chatter:**
- Minimum dwell time: 100 seconds (already implemented)
- Hysteresis gap: V_OFF - V_ON = 4V
- Emergency overrides allowed

---

## Implementation Details

### Phase 1: Mode Manager Enhancement

**File:** `func_software_SC_executive_DART.m`

**Changes:**
1. Add new mode: 'Charging Mitigation Mode'
2. Implement decision logic after section 2
3. Integrate charging state into mode selection
4. Add mode history tracking

```matlab
%% 3. Autonomous Mode Selection (NEW)

% Get charging state
charging_critical = telemetry.thruster_cmd;  % Controller decided ON
charging_safe = (telemetry.phi_pred >= mission.true_SC{i_SC}.charging_mitigation_config.V_OFF);

% Mode decision tree
if charging_critical
    obj.this_sc_mode = 'Charging Mitigation Mode';
elseif strcmp(obj.this_sc_mode, 'Charging Mitigation Mode') && ~charging_safe
    % Stay in charging mode until safe
    % (do nothing, keep current mode)
elseif mission.true_time.time < mission.science_start_time
    % Cruise phase
    if mission.true_SC{i_SC}.software_SC_power.mean_state_of_charge < 50
        obj.this_sc_mode = 'Maximize SP Power';
    else
        obj.this_sc_mode = 'Point towards Sun';
    end
else
    % Science phase (or default)
    obj.this_sc_mode = 'Point camera to Target';
end
```

### Phase 2: New Pointing Mode

**File:** `func_set_pointing_vectors_DART.m`

**Add new case:**
```matlab
case 'Charging Mitigation Mode'
    % Point solar panels to Sun for max power and visibility
    obj.data.primary_vector = func_normalize_vec(...
        mission.true_SC{i_SC}.true_SC_solar_panel{1}.shape_model.Face_orientation_solar_cell_side);
    obj.data.desired_primary_vector = func_normalize_vec(...
        mission.true_solar_system.SS_body{mission.true_solar_system.index_Sun}.position - ...
        mission.true_SC{i_SC}.software_SC_estimate_orbit.position);
    
    % Secondary: maintain stable attitude (point antenna to Earth)
    obj.data.secondary_vector = func_normalize_vec(...
        mission.true_SC{i_SC}.true_SC_radio_antenna{1}.orientation);
    obj.data.desired_secondary_vector = func_normalize_vec(...
        mission.true_solar_system.SS_body{mission.true_solar_system.index_Earth}.position - ...
        mission.true_SC{i_SC}.software_SC_estimate_orbit.position);
```

### Phase 3: Update EP Thruster Configuration

**File:** `Mission_DART.m`

**Update thruster parameters:**
```matlab
% EP Thruster configuration (User specifications)
init_data.thruster_ISP = 1840;           % seconds (was 3000)
init_data.thruster_Thrust = 0.035;       % N (35 mN, was 0.1 N)
init_data.thruster_Power = 723;          % W (was 50 W)
init_data.mass_flow_rate = 1.99e-6;      % kg/s (NEW)
init_data.thruster_current = 1.44;       % A (NEW)
init_data.propellant_mass_initial = 5.0; % kg (NEW - to be determined)
```

### Phase 4: Propellant Tracking

**Constructor:** Add storage arrays
```matlab
obj.store.charging.propellant_mass = zeros(num_storage_steps, 1);
obj.store.charging.propellant_consumed = zeros(num_storage_steps, 1);
obj.store.charging.thruster_current = zeros(num_storage_steps, 1);
```

**Executive:** Update tracking
```matlab
% Track propellant consumption
if thruster_cmd
    % Compute propellant consumed this timestep
    mass_flow = 1.99e-6;  % kg/s
    dt_sec = mission.true_time.time - obj.data.last_energy_update_time;
    propellant_used = mass_flow * dt_sec;  % kg
    
    obj.data.propellant_consumed += propellant_used;
    obj.data.propellant_mass = obj.data.propellant_mass_initial - obj.data.propellant_consumed;
    
    % Store current draw
    obj.store.charging.thruster_current(k) = 1.44;  % A
end

obj.store.charging.propellant_mass(k) = obj.data.propellant_mass;
obj.store.charging.propellant_consumed(k) = obj.data.propellant_consumed;
```

### Phase 5: Attitude Performance Tracking

**Add metrics:**
```matlab
% Attitude error tracking
attitude_error = compute_attitude_error(mission, i_SC);  % degrees
obj.store.charging.attitude_error(k) = attitude_error;

% Control effort
control_torque = mission.true_SC{i_SC}.software_SC_control_attitude.control_torque;
obj.store.charging.control_effort(k) = norm(control_torque);

% Mode history
obj.store.charging.mode_id(k) = find(strcmp(obj.sc_modes, obj.this_sc_mode));
```

---

## Enhanced Telemetry Structure

### Charging Telemetry (Expanded)

```matlab
charging_data = {
    % Existing fields
    'time_sec'              % Time [s]
    'x_AU'                  % Distance from Sun [AU]
    'isSunlit'              % Sunlight flag [bool]
    'phiOff_pred'           % Potential with thruster OFF [V]
    'phiOn_pred'            % Potential with thruster ON [V]
    'phi_used'              % Actual potential [V]
    'thruster_is_on'        % Thruster state [bool]
    'thruster_cmd'          % Thruster command [bool]
    'power_W'               % Power consumption [W]
    'cumulative_energy_Wh'  % Energy used [W-hr]
    'V_ON'                  % ON threshold [V]
    'V_OFF'                 % OFF threshold [V]
    
    % NEW fields
    'propellant_mass'       % Remaining propellant [kg]
    'propellant_consumed'   % Total consumed [kg]
    'thruster_current'      % Current draw [A]
    'battery_SoC'           % State of Charge [%]
    'solar_power'           % Solar power [W]
    'attitude_error'        % Pointing error [deg]
    'control_effort'        % Control torque [N-m]
    'mode_id'               % Active mode ID
    'mode_name'             % Active mode name
}
```

---

## Visualization Enhancements

### New Plot: Mode Timeline

**Purpose:** Show mode transitions over mission

**Content:**
- Time history of active mode
- Color-coded mode regions
- Transition markers
- Charging events highlighted

### Enhanced Plot: Propellant Budget

**Purpose:** Track propellant consumption

**Subplots:**
1. Propellant mass remaining [kg]
2. Propellant consumption rate [mg/s]
3. Cumulative propellant used [kg]
4. Projected depletion time

### Enhanced Plot: Attitude Performance

**Purpose:** Assess attitude control quality

**Subplots:**
1. Attitude error [deg]
2. Control torque [N-m]
3. Mode vs time
4. EP thruster impact analysis

### Integrated System View

**Purpose:** Show all systems together

**Subplots:**
1. Spacecraft potential + thresholds
2. Mode timeline
3. Battery SoC + solar power
4. Propellant mass
5. Attitude error
6. Distance from Sun

---

## Expected Results

### At Earth (1.0 AU)

**State:**
- Potential: +9V (safe)
- Mode: 'Point towards Sun' or 'Maximize SP Power'
- Thruster: OFF
- Battery: Charging (solar surplus)
- Propellant: No consumption

### At Venus (0.72 AU)

**State:**
- Potential: +5V to 0V (borderline)
- Mode: 'Point towards Sun'
- Thruster: Occasional activation
- Battery: Stable
- Propellant: Minimal consumption

### Near Sun (0.044 AU)

**State:**
- Potential: -28V → -2V (with thruster)
- Mode: 'Charging Mitigation Mode' (continuous)
- Thruster: ON (high duty cycle)
- Battery: Draining (723 W load)
- Propellant: Significant consumption

**Protection Effectiveness:**
- Without thruster: φ = -28V (CRITICAL)
- With thruster: φ = -2V (SAFE)
- Improvement: +26V (92.9%)

**Resource Cost:**
- Power: 723 W continuous
- Propellant: ~0.007 kg/hr
- Battery drain: depends on solar surplus

---

## Performance Metrics

### Charging Protection

1. **Coverage:** % of time with φ > -10V
2. **Max Negative:** Most negative potential reached
3. **Response Time:** Time to activate after threshold crossing

### Energy Cost

1. **Total Energy:** Cumulative W-hr for mitigation
2. **Average Power:** Mean power during mission
3. **Peak Power:** Maximum power draw

### Propellant Budget

1. **Total Consumed:** kg used for mitigation
2. **Efficiency:** kg per V of protection
3. **Remaining:** kg left at mission end

### Attitude Performance

1. **Pointing Accuracy:** Mean attitude error
2. **Stability:** RMS attitude error
3. **Control Effort:** Mean torque magnitude

### Battery Health

1. **Min SoC:** Lowest battery level reached
2. **Discharge Cycles:** Number of deep cycles
3. **Recovery Time:** Time to recharge

---

## Risk Mitigation

### Propellant Depletion

**Risk:** Run out of propellant before mission end

**Mitigation:**
- Monitor propellant budget
- Adjust thresholds if needed
- Prioritize critical phases

### Battery Drain

**Risk:** Excessive drain during charging mitigation

**Mitigation:**
- Power emergency overrides charging mode
- Solar power maximization when SoC < 30%
- Smart mode switching

### Attitude Disturbance

**Risk:** EP thruster affects pointing accuracy

**Mitigation:**
- Track attitude errors
- Compensate with reaction wheels
- Accept reduced accuracy during mitigation

---

## Implementation Phases

### Phase 1: Core Mode Manager (Week 1)
- [x] Design complete
- [ ] Implement autonomous mode selection
- [ ] Add 'Charging Mitigation Mode'
- [ ] Update pointing vectors
- [ ] Test mode transitions

### Phase 2: EP Thruster Update (Week 1-2)
- [ ] Update configuration parameters
- [ ] Implement propellant tracking
- [ ] Add current tracking
- [ ] Test with new power consumption

### Phase 3: Enhanced Telemetry (Week 2)
- [ ] Expand storage arrays
- [ ] Add new tracked variables
- [ ] Implement attitude metrics
- [ ] Validate data collection

### Phase 4: Visualization (Week 2-3)
- [ ] Create mode timeline plot
- [ ] Create propellant plot
- [ ] Create attitude performance plot
- [ ] Create integrated system view

### Phase 5: Integration & Testing (Week 3)
- [ ] Test with EVS mission
- [ ] Validate autonomous switching
- [ ] Verify resource tracking
- [ ] Generate results

---

## Questions for User

Before implementation, please confirm:

1. **Propellant Budget:**
   - Initial propellant mass: 5 kg? (TBD)
   - Acceptable consumption: how many kg?
   
2. **Mode Priorities:**
   - Is the proposed hierarchy correct?
   - Any additional modes needed?
   
3. **Thresholds:**
   - Keep V_ON = -10V, V_OFF = -6V?
   - Or adjust based on new power consumption?
   
4. **Battery Limits:**
   - Min SoC for charging mode: 30%? (same as power emergency)
   - Or different threshold?

5. **Attitude Requirements:**
   - Acceptable pointing error during mitigation?
   - Control torque limits?

---

## Next Steps

Awaiting user approval to:
1. Implement autonomous mode manager
2. Update EP thruster parameters
3. Add propellant and attitude tracking
4. Create enhanced visualizations
5. Integrate with EVS mission (if approved)

**Ready to begin implementation upon approval!**
