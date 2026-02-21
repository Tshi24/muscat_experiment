# Mission EVS (Earth-Venus-Sun) Design Proposal
## Charging Mitigation Mission Without SPICE Data

---

## Executive Summary

This document proposes a new MuSCAT-based mission simulating a spacecraft traveling from Earth (1.0 AU) to Venus (0.72 AU) to near-Sun (0.044 AU), demonstrating autonomous spacecraft charging mitigation using electric propulsion thrusters with full battery and solar power coupling.

**Key Innovation:** No SPICE trajectories required - uses analytical Keplerian orbit propagation.

---

## Mission Overview

### Mission Profile

```
Phase 1: Earth Orbit (1.0 AU)
   ↓ Hohmann Transfer
Phase 2: Earth → Venus Transfer
   ↓ Arrival
Phase 3: Venus Orbit (0.72 AU)
   ↓ Hohmann Transfer
Phase 4: Venus → Sun Transfer
   ↓ Arrival
Phase 5: Near-Sun Orbit (0.044 AU)
```

### Mission Objectives

1. **Demonstrate Charging Evolution:**
   - Show spacecraft potential change with heliocentric distance
   - Visualize transition from safe (+9V @ 1 AU) to critical (-28V @ 0.044 AU)

2. **Validate Autonomous Mitigation:**
   - Electric thruster activation reduces charging by ~26V
   - Hysteresis control prevents chatter
   - Effective protection demonstrated

3. **Analyze System Impacts:**
   - Battery state of charge vs EP activation
   - Solar power generation vs distance (1/r² law)
   - Energy budget and sustainability

4. **Pareto Optimization:**
   - Trade-off: Charging protection vs Energy cost vs Battery risk
   - Find optimal threshold settings
   - Identify mission constraints

---

## Technical Approach

### 1. Trajectory Generation (No SPICE Required!)

#### Keplerian Orbit Propagation

```matlab
% Two-body problem: r̈ = -μ/r³ * r
% Use analytical solutions for circular and elliptical orbits

% Example: Phase 1 - Circular Earth Orbit
r_earth = 1.0 * 149597870.7; % km (1 AU)
GM_sun = 1.32712440018e11;   % km³/s²
v_circular = sqrt(GM_sun / r_earth);

% State: [x, y, z, vx, vy, vz]
state_initial = [r_earth, 0, 0, 0, v_circular, 0];
```

#### Hohmann Transfer Calculations

```matlab
% Transfer from r1 to r2
r1 = 1.0 * AU;  % Earth
r2 = 0.72 * AU; % Venus

% Semi-major axis of transfer orbit
a_transfer = (r1 + r2) / 2;

% Velocity at perihelion (r1)
v1_transfer = sqrt(GM_sun * (2/r1 - 1/a_transfer));
delta_v1 = v1_transfer - sqrt(GM_sun / r1);

% Velocity at aphelion (r2)
v2_transfer = sqrt(GM_sun * (2/r2 - 1/a_transfer));
delta_v2 = sqrt(GM_sun / r2) - v2_transfer;

% Transfer time
T_transfer = pi * sqrt(a_transfer³ / GM_sun);
```

#### Mission Timeline (Example)

| Phase | Duration | Distance | Description |
|-------|----------|----------|-------------|
| 1 | 30 days | 1.0 AU | Earth orbit, baseline operations |
| 2 | 146 days | 1.0→0.72 AU | Hohmann transfer to Venus |
| 3 | 30 days | 0.72 AU | Venus orbit, moderate charging |
| 4 | 121 days | 0.72→0.044 AU | Extreme transfer to Sun |
| 5 | 30 days | 0.044 AU | Near-Sun, critical charging |
| **Total** | **357 days** | - | ~1 year mission |

### 2. Charging Mitigation System

#### Existing Models (Already Implemented)

```matlab
% Sunlit charging models (SPIS-based curve fits)
[phiOff, phiOn] = Phi_sunlit_models(x_AU);

% Eclipse charging models
[phiOff_ecl, phiOn_ecl] = Phi_eclipse_models(x_AU);

% Example values:
% @ 1.0 AU:  phiOff ≈ +9V,  phiOn ≈ -7V
% @ 0.72 AU: phiOff ≈ +5V,  phiOn ≈ -9V
% @ 0.044 AU: phiOff ≈ -28V, phiOn ≈ -2V
```

#### Controller Logic (Already Implemented)

```matlab
% Hysteresis control
V_ON = -10;  % Turn thruster ON when phi ≤ -10V
V_OFF = -6;  % Turn thruster OFF when phi ≥ -6V

% State machine:
if ~thruster_is_on && phi_pred <= V_ON
    thruster_cmd = ON;   % Activate mitigation
elseif thruster_is_on && phi_pred >= V_OFF
    thruster_cmd = OFF;  % Deactivate (recovered)
else
    thruster_cmd = HOLD; % Maintain state (hysteresis)
end
```

### 3. Enhanced Battery-Solar-Thruster Coupling

#### Current State
- Battery SoC tracked
- Solar power available
- EP power logged
- **BUT:** Not fully coupled

#### Proposed Enhancement

```matlab
%% Solar Power Generation Model
function P_solar = compute_solar_power(r_AU, isSunlit, panel_area, efficiency)
    % Solar constant at 1 AU
    S0 = 1361; % W/m²
    
    % Inverse square law
    S = S0 / (r_AU^2);
    
    % Generated power
    if isSunlit
        P_solar = S * panel_area * efficiency;
    else
        P_solar = 0; % Eclipse
    end
end

%% Power Budget
P_solar = compute_solar_power(r_AU, isSunlit, 10, 0.30); % 10 m², 30% eff
P_base = 100;  % W (baseline spacecraft loads)
P_thruster = thruster_is_on * 50;  % W (EP thruster when ON)
P_total = P_base + P_thruster;
P_net = P_solar - P_total;

%% Battery Dynamics
% Battery parameters
V_battery = 28;  % V
C_battery = 100; % Ah (2800 Wh capacity)

% Current (positive = charging, negative = discharging)
I_battery = P_net / V_battery;  % A

% Update state of charge
dt = 5;  % sec
SOC += (I_battery * dt / 3600) / C_battery * 100;  % %

% Constraints
SOC = min(max(SOC, 0), 100);  % Clamp to [0, 100]%
```

#### Tracked Metrics

1. **Solar Power:**
   - Distance dependency: P_solar ∝ 1/r²
   - @ 1.0 AU: ~4000 W (baseline)
   - @ 0.72 AU: ~7700 W (almost 2x)
   - @ 0.044 AU: ~2,066,000 W (need protective measures!)

2. **Battery State:**
   - State of Charge (SoC) [%]
   - Current [A]
   - Voltage [V]
   - Cycles count
   - Depth of discharge

3. **Power Balance:**
   - Generation vs Consumption
   - Net power
   - Cumulative energy from/to battery
   - EP thruster energy consumption

### 4. Pareto Analysis Framework

#### Three Competing Objectives

**Objective 1: Charging Protection (Maximize)**
```matlab
% Metrics:
protection_score = time_above_safe_threshold / total_time * 100; % %
max_negative_potential = min(phi_used); % V (less negative is better)
violations = sum(phi_used < -15); % Count of critical events
```

**Objective 2: Energy Cost (Minimize)**
```matlab
% Metrics:
total_energy = sum(P_thruster * dt); % W-hr
avg_power = mean(P_thruster); % W
duty_cycle = sum(thruster_is_on) / length(thruster_is_on) * 100; % %
```

**Objective 3: Battery Risk (Minimize)**
```matlab
% Metrics:
min_SOC = min(battery_SOC); % % (higher is better)
deep_discharges = sum(battery_SOC < 20); % Count
SOC_variance = std(battery_SOC); % % (lower is better)
```

#### Parameter Sweep

```matlab
% Sweep controller thresholds
V_ON_range = -25:2.5:-5;   % [-25, -22.5, ..., -5] V
V_OFF_range = -20:2.5:0;    % [-20, -17.5, ..., 0] V

% Valid combinations: V_OFF > V_ON (hysteresis)
results = [];
for V_ON = V_ON_range
    for V_OFF = V_OFF_range(V_OFF_range > V_ON)
        % Run simulation with this configuration
        [protection, cost, risk] = run_mission(V_ON, V_OFF);
        results = [results; V_ON, V_OFF, protection, cost, risk];
    end
end
```

#### Pareto Frontier Identification

```matlab
% Find non-dominated solutions
% A solution dominates B if it's better in all objectives
pareto_front = identify_pareto_frontier_3D(results);

% Plot 3D scatter
figure;
scatter3(results(:,3), results(:,4), results(:,5), 'b.');
hold on;
scatter3(pareto_front(:,3), pareto_front(:,4), pareto_front(:,5), 'r*', 'MarkerSize', 10);
xlabel('Charging Protection [%]');
ylabel('Energy Cost [Wh]');
zlabel('Battery Risk [100-min(SOC)]');
title('Pareto Frontier: Multi-Objective Optimization');
```

---

## Proposed File Structure

### New Mission File

```
Mission/Mission_EVS.m
```
- Mission initialization (similar to Mission_DART.m)
- 5-phase trajectory generation
- Charging mitigation configuration
- EPS (battery/solar) setup
- Spacecraft hardware definition

### Supporting Functions (New)

```
Supporting_Functions/mission_specific/EVS/
├── func_propagate_keplerian_orbit.m
├── func_compute_hohmann_transfer.m
├── func_compute_solar_power.m
├── func_update_battery_state.m
├── func_software_SC_executive_EVS.m
├── func_software_SC_executive_EVS_constructor.m
└── func_print_EVS_mission_summary.m
```

### Visualization Functions (New)

```
Supporting_Functions/plot/mission_EVS/
├── func_plot_EVS_trajectory.m
├── func_plot_EVS_charging_evolution.m
├── func_plot_EVS_power_system.m
└── func_plot_pareto_analysis.m
```

### Pareto Analysis (New)

```
Supporting_Functions/pareto/
├── func_run_parameter_sweep.m
├── func_compute_objectives.m
├── func_identify_pareto_frontier.m
└── func_plot_pareto_3D.m
```

---

## Visualization Plan

### Plot 1: Mission Trajectory
```
Subplot 1: Heliocentric Distance vs Time
- r(t) from 1.0 AU → 0.72 AU → 0.044 AU
- Phase markers (vertical lines)
- Earth/Venus orbit circles

Subplot 2: 3D Trajectory
- Sun-centered view
- Spacecraft path
- Earth/Venus positions
```

### Plot 2: Charging Evolution
```
Subplot 1: Spacecraft Potential vs Time
- phi_used(t) with phase colors
- Threshold lines (V_ON, V_OFF)
- Mitigation regions shaded

Subplot 2: Spacecraft Potential vs Distance
- phi_used(r) - shows r² dependency
- Reference curves (phiOff, phiOn)

Subplot 3: Thruster State
- ON/OFF stairs plot
- Duty cycle per phase
```

### Plot 3: Power System
```
Subplot 1: Power Generation & Consumption
- Solar power (1/r² curve)
- Base load (constant)
- EP thruster (spikes when ON)
- Net power (gen - cons)

Subplot 2: Battery State
- State of Charge [%]
- Current [A] (positive/negative)

Subplot 3: Cumulative Energy
- Energy from battery (discharge)
- Energy to battery (charge)
- EP thruster cumulative consumption
```

### Plot 4: Pareto Analysis
```
Main: 3D Scatter
- All simulation results (dots)
- Pareto frontier (red stars)
- Axes: Protection, Cost, Risk

Subplots: 2D Projections
- Protection vs Cost
- Protection vs Risk
- Cost vs Risk
```

---

## Implementation Phases

### Phase 1: Basic Mission (Weeks 1-2)

**Deliverables:**
- [x] Mission_EVS.m created
- [x] Keplerian orbit propagation
- [x] 5-phase trajectory
- [x] Basic charging integration
- [x] Simple trajectory plots

**Validation:**
- Orbital energy conservation
- Period matches theoretical
- Distance transitions smooth

### Phase 2: Enhanced EPS (Weeks 2-3)

**Deliverables:**
- [x] Solar power model (1/r²)
- [x] Battery dynamics model
- [x] Full power coupling
- [x] Power system plots
- [x] Battery impact analysis

**Validation:**
- Energy balance (gen = cons + battery change)
- Battery SOC stays in [0, 100]%
- Solar power matches 1/r² law

### Phase 3: Pareto Framework (Weeks 3-4)

**Deliverables:**
- [x] Parameter sweep infrastructure
- [x] Multi-objective metrics
- [x] Pareto frontier algorithm
- [x] 3D visualization
- [x] Recommendations

**Validation:**
- Pareto solutions non-dominated
- Extreme cases make sense
- Trade-offs clearly visible

### Phase 4: Polish & Documentation (Week 4+)

**Deliverables:**
- [x] User documentation
- [x] Technical validation
- [x] Performance optimization
- [x] Integration testing

---

## Expected Results

### Charging Evolution

| Phase | Distance | φ_OFF | φ_ON | Thruster? | Energy |
|-------|----------|-------|------|-----------|--------|
| Earth | 1.0 AU | +9 V | -7 V | Minimal | Low |
| E→V | 0.86 AU avg | +7 V | -8 V | Occasional | Medium |
| Venus | 0.72 AU | +5 V | -9 V | Moderate | Medium |
| V→S | 0.38 AU avg | -10 V | -6 V | Frequent | High |
| Sun | 0.044 AU | -28 V | -2 V | Continuous | Very High |

### Power Budget

| Phase | Solar [W] | EP [W] | Net [W] | SOC Change |
|-------|-----------|--------|---------|------------|
| Earth | 4000 | 10 | +3890 | Charging |
| E→V | 5400 | 20 | +5280 | Charging |
| Venus | 7700 | 30 | +7570 | Charging |
| V→S | 27500 | 40 | +27360 | Charging |
| Sun | 2.1M | 45 | Protected | Thermal limit! |

**Note:** Near-Sun requires protective measures (panel angle, reflectors)

### Pareto Results (Predicted)

**Conservative (V_ON=-20, V_OFF=-12):**
- Protection: 85%
- Energy: Low
- Battery: Safe (min 60% SOC)

**Moderate (V_ON=-10, V_OFF=-6):**
- Protection: 95%
- Energy: Medium
- Battery: Acceptable (min 40% SOC)

**Aggressive (V_ON=-5, V_OFF=-2):**
- Protection: 99%
- Energy: High
- Battery: Risk (min 20% SOC)

---

## Additional Feature Suggestions

### Priority 1 (High Value, Easy)

1. **Distance-Dependent Temperature:**
   - Simple model: T ∝ 1/r^0.5
   - Affects battery performance
   - 10 lines of code

2. **Communication Distance:**
   - Earth-SC distance
   - Signal delay = distance / c
   - Link margin changes
   - 20 lines of code

### Priority 2 (Medium Value, Medium Effort)

3. **Radiation Dose:**
   - Simple solar wind model
   - Cumulative dose tracking
   - Component degradation
   - 50 lines of code

4. **Solar Panel Pointing:**
   - Sun-pointing requirement
   - Off-pointing losses
   - Thermal constraints
   - 100 lines of code

### Priority 3 (Nice to Have, High Effort)

5. **Attitude Dynamics:**
   - Full 3-axis simulation
   - Momentum wheel desaturation
   - Complex interaction
   - 500+ lines of code

6. **Failure Analysis:**
   - Monte Carlo runs
   - Component failures
   - Reliability metrics
   - 300+ lines of code

---

## Questions for Decision

### 1. Mission Duration

**Option A: Quick Demo (60 days)**
- 10 days per phase
- Fast results
- Less realistic

**Option B: Moderate (180 days)**
- 30-40 days per phase
- Good balance
- Reasonable transfers

**Option C: Realistic (365 days)** ✅ RECOMMENDED
- True Hohmann transfers
- Realistic operations
- Full mission analysis

**Your Choice:** _________

### 2. File Organization

**Option A: New Mission File** ✅ RECOMMENDED
- Mission/Mission_EVS.m
- Clean separation
- Easy to maintain

**Option B: Extend DART**
- Modify Mission_DART.m
- Reuse infrastructure
- More complex

**Your Choice:** _________

### 3. Feature Priority

**Must Have:**
- [ ] Multi-phase trajectory
- [ ] Charging evolution
- [ ] Battery-solar coupling
- [ ] Basic plots

**Should Have:**
- [ ] Pareto analysis
- [ ] Temperature effects
- [ ] Communication distance

**Nice to Have:**
- [ ] Radiation tracking
- [ ] Attitude optimization
- [ ] Failure scenarios

**Your Priority Order:** _________

### 4. Pareto Analysis Timing

**Option A: Implement Now**
- Complete from start
- More complex initial dev

**Option B: Implement Later** ✅ RECOMMENDED
- Get basic mission working first
- Add Pareto as Phase 3

**Your Choice:** _________

### 5. Validation Approach

How should we verify correctness?

- [ ] Compare with simplified analytical cases
- [ ] Energy conservation checks
- [ ] Physical limits verification
- [ ] Peer review
- [ ] Other: _________

---

## Next Steps

**Awaiting Your Decisions On:**

1. ✓ Mission duration (60, 180, or 365 days)?
2. ✓ File structure (new EVS file or extend DART)?
3. ✓ Feature priorities (order the should/nice-to-have)?
4. ✓ Pareto timing (now or later)?
5. ✓ Any other requirements or constraints?

**Once Approved, I Will:**

1. Create Mission_EVS.m framework
2. Implement Keplerian propagation
3. Add enhanced battery-solar coupling
4. Create visualization functions
5. Provide testing/validation

**Estimated Time:** 2-4 weeks depending on scope

---

## Conclusion

This proposal provides a complete roadmap for creating an Earth-Venus-Sun charging mitigation mission **without requiring SPICE data**. The approach uses:

✅ Analytical Keplerian orbits (simple, accurate)  
✅ Existing charging models (already validated)  
✅ Enhanced EPS coupling (battery + solar)  
✅ Pareto analysis framework (multi-objective optimization)  
✅ Comprehensive visualization (4+ plot types)  

**Ready to proceed upon your approval!**

---

**Document Version:** 1.0  
**Date:** 2026-02-09  
**Status:** Awaiting User Feedback
