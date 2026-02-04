# Spacecraft Charging Mitigation - Quick Reference

## What You Get After Running Mission_DART

### 📊 New Figure: "Spacecraft Charging & Mitigation"
- **3 subplots** showing potential, thruster state, and power consumption
- Saved as `Output/charging_mitigation.fig` and `.png`

### 📝 Console Summary
```
SPACECRAFT POTENTIAL:
  Minimum/Maximum/Mean potential values
  
THRUSTER ACTIVATION:
  Total time ON, number of activations
  
POWER & ENERGY:
  Total energy used for mitigation
```

### 💾 Data File: `Output/charging_mitigation_data.mat`
Contains all telemetry + summary statistics

---

## Quick Start

### Run Mission
```matlab
cd Mission
Mission_DART
```

### View Charging Data
```matlab
load('Output/charging_mitigation_data.mat');
charging_data.summary  % View summary stats
```

### Open Saved Figure
```matlab
openfig('Output/charging_mitigation.fig');
```

---

## Key Values for DART at Bennu

| Parameter | Expected Value | Status |
|-----------|---------------|--------|
| Spacecraft Potential | +9V ± 1V | ✅ SAFE |
| Thruster Activations | 0 | ✅ No mitigation needed |
| Energy Used | 0 W-hr | ✅ Minimal impact |

**Reason:** At 0.896 AU from Sun, charging is minimal and well above critical threshold (-20V)

---

## Understanding the Plots

### Plot 1: Spacecraft Potential
- **Blue line:** Actual potential
- **Red/Green dashed:** Predictions (OFF/ON)
- **Horizontal lines:** Thresholds (-20V ON, -12V OFF)

**Interpretation:**
- Above -12V = Safe
- Below -20V = Thruster activates

### Plot 2: Thruster State
- **1 = ON, 0 = OFF**
- Gray regions = Eclipse

### Plot 3: Power
- **50W when thruster is ON**
- **0W when thruster is OFF**

---

## Threshold Meanings

| Threshold | Value | Purpose |
|-----------|-------|---------|
| V_ON | -20V | Turn thruster ON |
| V_OFF | -12V | Turn thruster OFF |
| Gap | 8V | Hysteresis (prevents chatter) |

---

## Files Created

1. `Output/charging_mitigation.fig` - MATLAB figure
2. `Output/charging_mitigation.png` - PNG image  
3. `Output/charging_mitigation_data.mat` - All data

---

## Customization

### Change Thresholds
In `Mission_DART.m`:
```matlab
init_data_charging.V_ON = -20;   % Lower = less sensitive
init_data_charging.V_OFF = -12;  % Higher = more aggressive
```

### Eclipse Policy
```matlab
init_data_charging.policy_require_sunlight_for_ep = false;  % Allow in eclipse
```

---

## Common Questions

**Q: Why is potential positive (+9V)?**  
A: At Bennu's distance (0.896 AU), solar radiation is moderate and spacecraft charges slightly positive in sunlight.

**Q: Why no thruster activations?**  
A: +9V is well above the -20V threshold. No mitigation needed!

**Q: What if I was closer to the Sun?**  
A: At <0.3 AU, potential would be highly negative (-50V to -500V) and thruster would activate frequently.

**Q: How do I see data from the simulation?**  
A: Load `Output/charging_mitigation_data.mat` in MATLAB.

---

## For More Information

See full documentation:
- `Documentation/CHARGING_VISUALIZATION_GUIDE.md` - Complete guide
- `Documentation/CHARGING_MITIGATION_README.md` - Technical details
- `Documentation/ECLIPSE_CHARGING_ANALYSIS.md` - Eclipse scenarios

---

**Quick Help:** For any issues, check that:
1. ✅ EP thruster is configured in Mission_DART.m
2. ✅ Charging mitigation config exists
3. ✅ Simulation completed successfully
