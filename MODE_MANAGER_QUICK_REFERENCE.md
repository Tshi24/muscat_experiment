# Autonomous Mode Manager - Quick Reference

## TL;DR

You want the spacecraft to **automatically decide** what to do as it cruises from Earth → Venus → Sun:
1. Point towards Sun for visibility
2. Check spacecraft charging
3. Turn ON electric thruster if charging is critical
4. Maximize solar power when safe
5. Track everything: potential, battery, propellant, attitude

**Answer:** ✅ **YES, WE CAN DO THIS!**

---

## What You'll Get

### Autonomous Decision Making

The spacecraft will automatically switch between modes based on:
- Battery state of charge
- Spacecraft potential (charging level)
- Distance from Sun
- Mission phase

### Complete Tracking

**All outputs you requested:**
- ✅ Spacecraft potential changes
- ✅ Thruster ON/OFF protection effect
- ✅ Battery impact (SoC, discharge)
- ✅ Solar panel performance
- ✅ Propellant consumption
- ✅ Attitude performance

---

## The 5 Operating Modes

### 1. Power Emergency Mode
**When:** Battery < 30%  
**Action:** Point solar panels directly at Sun  
**Priority:** HIGHEST (survival)

### 2. Charging Mitigation Mode (NEW!)
**When:** Spacecraft potential ≤ -10V  
**Action:** Point to Sun + Turn ON EP thruster  
**Priority:** Critical (protection)  
**Power:** 723 W  
**Effect:** Protects spacecraft (+26V improvement)

### 3. Point towards Sun Mode
**When:** Cruise phase, battery OK  
**Action:** Point solar panels to Sun  
**Priority:** Normal cruise

### 4. Maximize Solar Power Mode
**When:** Battery < 50%  
**Action:** Optimize for maximum power generation  
**Priority:** Battery recharge

### 5. Science/Comm/Maneuver Modes
**When:** Specific operations needed  
**Action:** Point camera, antenna, or thruster  
**Priority:** Mission dependent

---

## How It Works

### Decision Tree

```
START
  ↓
Is battery < 30%?
  YES → Maximize Solar Power (Emergency!)
  NO  ↓
Is potential ≤ -10V?
  YES → Charging Mitigation Mode (Turn ON thruster)
  NO  ↓
Are we in charging mode already?
  YES → Stay ON until potential ≥ -6V (hysteresis)
  NO  ↓
Is battery < 50%?
  YES → Maximize Solar Power
  NO  ↓
Default → Point towards Sun (cruise)
```

### Hysteresis Protection

**Prevents rapid ON/OFF switching:**
- Turn ON at: -10V
- Turn OFF at: -6V
- Gap: 4V (prevents chatter)
- Min dwell time: 100 seconds

---

## Your EP Thruster Specs

| Parameter | Value |
|-----------|-------|
| Mass Flow | 1.99e-6 kg/s |
| Current | 1.44 A |
| Thrust | 35 mN |
| **Power** | **723 W** (Important!) |
| ISP | 1840 seconds |

**Implications:**
- High power consumption (723 W!)
- Battery drains quickly during activation
- Need to track propellant carefully

---

## What Gets Tracked

### 1. Spacecraft Potential
- Current value [V]
- Evolution over time
- Distance dependency
- Threshold crossings

### 2. Thruster Events
- ON/OFF state
- Activation times
- Duty cycle
- Protection effectiveness

### 3. Battery Performance
- State of Charge [%]
- Charge/discharge rate [A]
- Power balance [W]
- Impact of thruster (723 W drain)

### 4. Solar Panel
- Power generation [W]
- Distance dependency (1/r²)
- Attitude impact
- Efficiency

### 5. Propellant
- Mass remaining [kg]
- Consumption rate [kg/s]
- Total used [kg]
- Projected depletion

### 6. Attitude
- Pointing error [deg]
- Control effort [N-m]
- EP thruster disturbance
- Mode transitions

---

## Expected Results

### At Earth (1.0 AU)

```
Distance:    1.0 AU
Potential:   +9V (SAFE)
Mode:        Point towards Sun
Thruster:    OFF
Battery:     Charging
Solar:       ~4 kW
Propellant:  No consumption
```

### At Venus (0.72 AU)

```
Distance:    0.72 AU
Potential:   +5V to 0V (borderline)
Mode:        Point towards Sun
Thruster:    Occasional ON
Battery:     Stable
Solar:       ~7.7 kW
Propellant:  Minimal consumption
```

### Near Sun (0.044 AU)

```
Distance:    0.044 AU
Potential:   -28V → -2V (with thruster)
Mode:        CHARGING MITIGATION MODE!
Thruster:    ON continuously
Battery:     Draining (723 W load)
Solar:       ~2 MW (plenty!)
Propellant:  ~0.007 kg/hr

Protection Effectiveness:
  Without thruster: -28V (CRITICAL!)
  With thruster:    -2V (SAFE)
  Improvement:      +26V (92.9%)
```

---

## Resource Budget

### Power Budget

**Near Sun (0.044 AU):**
- Solar generation: ~2 MW
- EP thruster: 723 W
- Net surplus: ~1,999 kW (plenty!)

**At Venus (0.72 AU):**
- Solar generation: ~7.7 kW
- EP thruster: 723 W
- Net surplus: ~7 kW (comfortable)

**At Earth (1.0 AU):**
- Solar generation: ~4 kW
- EP thruster: 723 W
- Net surplus: ~3.3 kW (OK)

**Conclusion:** Power is NOT a problem!

### Propellant Budget

**Consumption Rate:**
- 1.99e-6 kg/s = 0.0072 kg/hr
- 1 day continuous: 0.17 kg
- 30 days continuous: 5.1 kg

**If we start with 5 kg:**
- Max continuous operation: ~30 days
- Near Sun phase: Critical budget
- Need smart mode switching

**Recommendation:** Start with 10-15 kg for margin

---

## Visualizations You'll Get

### 1. Mode Timeline
- Shows which mode is active over time
- Color-coded regions
- Transition markers
- Charging events highlighted

### 2. Spacecraft Potential Evolution
- Potential vs time and distance
- Threshold lines
- Thruster activation overlay
- Protection effect visible

### 3. Power System Analysis
- Solar power generation
- Total consumption
- EP thruster contribution
- Battery SoC evolution

### 4. Propellant Budget
- Mass remaining
- Consumption rate
- Cumulative used
- Projected depletion

### 5. Attitude Performance
- Pointing error
- Control torque
- EP thruster impact
- Mode-dependent accuracy

### 6. Integrated System View
All of the above in one comprehensive figure!

---

## Implementation Plan

### Week 1: Core System
- Autonomous mode selector
- Charging Mitigation Mode
- Updated EP thruster specs
- Basic tracking

### Week 2: Enhanced Tracking
- Propellant consumption
- Attitude metrics
- Expanded telemetry
- Current/mass flow

### Week 3: Visualization
- Mode timeline plot
- Propellant plots
- Attitude plots
- Integrated view

### Week 4: Testing & Integration
- Validate with DART mission
- Test with EVS mission (if approved)
- Performance analysis
- Documentation

---

## Questions for You

To finalize the design, please answer:

### 1. Propellant Budget
**Question:** How much propellant should we start with?
- Minimum: 5 kg (30 days continuous)
- Recommended: 10 kg (60 days)
- Conservative: 15 kg (90 days)

**Your answer:** _____________

### 2. Mode Priorities
**Question:** Is this priority order OK?
1. Power Emergency
2. Charging Critical
3. Normal Operations

**Your answer:** Yes / No / Modify: _____________

### 3. Charging Thresholds
**Question:** Keep current thresholds?
- V_ON = -10V (turn thruster ON)
- V_OFF = -6V (turn thruster OFF)

**Your answer:** Keep / Change to: _____________

### 4. Battery Limits
**Question:** Min battery for charging mode?
- Current: 30% (same as power emergency)
- Or different threshold?

**Your answer:** 30% / Other: _____________

### 5. Additional Features
**Question:** What else should we add?
- Temperature tracking?
- Radiation dose?
- Communication distance?
- Component degradation?

**Your answer:** _____________

---

## Next Steps

### Option A: Implement Now (Recommended)
**Timeline:** 3-4 weeks  
**Deliverables:**
- Working autonomous mode manager
- Complete tracking
- Comprehensive visualization
- Integration with existing missions

### Option B: Implement Later
**Approach:** Focus on EVS mission first, add later  
**Risk:** More work to integrate after

### Option C: Hybrid
**Approach:** Basic mode manager now, enhancements later  
**Benefit:** Get core working, iterate

---

## Decision Needed

**Your choice:**
- [ ] Option A: Full implementation now ← Recommended
- [ ] Option B: EVS mission first, this later
- [ ] Option C: Basic now, enhancements later

**Additional requests:** _____________

---

## Status

📋 **READY TO IMPLEMENT**

**Design:** ✅ Complete  
**Plan:** ✅ Ready  
**Resources:** ✅ Available  
**Timeline:** ✅ 3-4 weeks  

**Awaiting:** Your approval and answers to 5 questions

**Contact:** Just reply with your decisions and we'll start coding! 🚀

---

## References

**Detailed Design:** See `AUTONOMOUS_MODE_MANAGER_DESIGN.md` (16KB)  
**EVS Mission:** See `MISSION_EVS_DESIGN_PROPOSAL.md` (15KB)  
**Current Charging:** See `COMPREHENSIVE_CHANGELOG_AND_LOGIC.md` (26KB)

**Everything documented and ready to go!**
