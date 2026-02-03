# ANSWER: Eclipse Charging Mitigation at Bennu

## Question

**"Near Bennu, charging is minimal in sunlight but in eclipse (no sunlight) the spacecraft charges to -15V approximately. Should we switch ON the thruster to mitigate?"**

---

## Short Answer

**YES - Enable thruster operation in eclipse** by setting:
```matlab
policy_require_sunlight_for_ep = false
```

**But at current -15V:** Thruster will NOT activate (above -20V threshold)

**If worsens to ≤-20V:** Thruster WILL activate (protection available)

---

## Detailed Answer

### Current Situation at Bennu

| Condition | Potential | Threshold Check | Current Policy |
|-----------|-----------|----------------|----------------|
| **Sunlit** | +9V | ✓ Safe (far above -20V) | No action |
| **Eclipse** | **-15V** | ⚠️ Concerning (5V from -20V) | ❌ Blocked |

### Analysis

**Eclipse Potential: -15V**

```
Critical threshold:    V_ON  = -20V ─────┐
                                          │ 5V margin
Current eclipse:       phi   = -15V ──────┤
                                          │ 3V margin
Acceptable threshold:  V_OFF = -12V ─────┘
```

**Key Points:**
- -15V is **75% of critical threshold** (-20V)
- **Only 5V margin** before critical
- **Only 3V from acceptable level** (-12V)
- In the **hysteresis zone** (concerning but not yet critical)

---

## Recommendation: ALLOW EP IN ECLIPSE

### Why?

1. **Comprehensive Protection**
   - Protects against both sunlit AND eclipse charging
   - Ready if conditions worsen
   - Safety > battery conservation

2. **Smart Activation**
   - Threshold-based (only if φ ≤ -20V)
   - At current -15V: No activation (no power drain)
   - At severe -22V: Activates (protection kicks in)

3. **Minimal Power Impact**
   - Current -15V: 0 W-hr (no activation)
   - Severe case: ~75 W-hr per eclipse (worth it for safety)

### Configuration Change

**OLD Setting (blocks mitigation):**
```matlab
init_data_charging.policy_require_sunlight_for_ep = true;  % Blocks EP in eclipse
```

**NEW Setting (recommended):**
```matlab
init_data_charging.policy_require_sunlight_for_ep = false;  % Allows EP in eclipse
```

---

## Controller Behavior with New Setting

### Scenario 1: Current Eclipse (-15V)

```matlab
isSunlit = false
phi_eclipse = -15V
V_ON = -20V

Decision: -15V > -20V → Thruster stays OFF
Reason: Above threshold (acceptable risk)
Power: 0 W (no consumption)
```
✓ **No unnecessary power drain**

### Scenario 2: Severe Eclipse (-22V)

```matlab
isSunlit = false
phi_eclipse = -22V
V_ON = -20V

Decision: -22V ≤ -20V → Thruster turns ON
Reason: Critical charging detected
Power: ~75 W-hr per eclipse
```
✓ **Protection activated when needed**

### Scenario 3: Sunlit (+9V)

```matlab
isSunlit = true
phi_sunlit = +9V
V_ON = -20V

Decision: +9V > -20V → Thruster stays OFF
Reason: Positive potential (safe)
Power: 0 W
```
✓ **No change from before**

---

## Implementation

### 1. Update DART Mission Configuration

File: `/Mission/Mission_DART.m`

```matlab
%% Spacecraft Charging Mitigation Configuration
init_data_charging = [];
init_data_charging.V_ON = -20;   % [V] Turn thruster ON when phi <= -20 V
init_data_charging.V_OFF = -12;  % [V] Allow thruster OFF when phi >= -12 V

% UPDATED: Allow EP in eclipse for comprehensive protection
% Near Bennu: Eclipse charging ~-15V (concerning but above -20V threshold)
% Setting to false provides protection if eclipse charging worsens
init_data_charging.policy_require_sunlight_for_ep = false;

init_data_charging.clamp_range = [0.044, 1.0];
mission.true_SC{i_SC}.charging_mitigation_config = init_data_charging;
```

### 2. Test the Configuration

Run: `test_eclipse_charging_scenario.m`

```matlab
>> test_eclipse_charging_scenario

Test 1: Policy enabled → Eclipse charging blocked (BAD)
Test 2: Policy disabled → Smart threshold-based activation (GOOD)
Test 3: Severe case → Protection activated (GOOD)
Test 4: Power impact analysis
```

---

## Summary

### Answer to Your Question

**"Should we switch ON the thruster for -15V eclipse charging?"**

**With recommended setting (policy = false):**

✅ **Controller will intelligently decide:**
- **At -15V:** NO activation (above threshold, saves power)
- **At ≤-20V:** YES activation (critical, protection needed)
- **Flexibility:** Adapts to actual conditions

✅ **Benefits:**
- Comprehensive protection (sunlit + eclipse)
- Smart power management
- Safety prioritized
- No power waste at current -15V
- Protection available if worsens

✅ **Power Impact:**
- Current -15V: 0 W-hr (no activation)
- Severe -22V: ~75 W-hr (worth it for safety)

---

## Key Takeaway

**Enable thruster in eclipse** by setting `policy_require_sunlight_for_ep = false`.

The controller uses **threshold-based logic**, not blanket ON/OFF:
- At current -15V: No activation (no power waste)
- If worsens to ≤-20V: Protection kicks in (safety critical)

**Best of both worlds:** Safety when needed, efficiency otherwise.

---

## Files

- **Analysis:** `Documentation/ECLIPSE_CHARGING_ANALYSIS.md`
- **Configuration:** `Mission/Mission_DART.m`
- **Test:** `Supporting_Functions/test_eclipse_charging_scenario.m`
- **Answer:** `ANSWER_ECLIPSE_CHARGING.md` (this file)

**Last Updated:** 2024  
**Mission:** DART (Bennu)  
**Status:** ✅ RECOMMENDED SETTING IMPLEMENTED
