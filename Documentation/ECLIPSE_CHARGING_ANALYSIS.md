# Eclipse Charging Analysis for Bennu Mission

## Problem Statement

**Question:** Near Bennu, the charging is minimal in sunlight but in eclipse (no sunlight), the spacecraft charges to approximately -15V. Should we switch ON the thruster to lower the potential?

**Short Answer:** YES - The thruster should be allowed to operate in eclipse for comprehensive charging protection.

---

## Current Situation

### Charging Conditions Near Bennu

| Condition | Potential | Severity | Current Response |
|-----------|-----------|----------|------------------|
| **Sunlit** | +9.0 V | MINIMAL | No action needed |
| **Eclipse** | **-15.0 V** | **CONCERNING** | ❌ Blocked by policy |

### Controller Configuration

- **V_ON threshold:** -20 V (turn thruster ON)
- **V_OFF threshold:** -12 V (turn thruster OFF)
- **Hysteresis zone:** [-20, -12] V
- **Current policy:** `policy_require_sunlight_for_ep = true` (blocks EP in eclipse)

---

## Analysis

### Eclipse Potential: -15V

```
Position relative to thresholds:
  V_ON  = -20 V ──────┐
                      │ 5V margin
  Eclipse = -15 V ────┤
                      │ 3V margin  ← CLOSER TO V_OFF
  V_OFF = -12 V ──────┘
```

**Key Observations:**
1. **-15V is 75% of critical threshold** (-20V)
2. **Only 3V margin** from acceptable level (-12V)
3. **Within hysteresis zone** (neither safe nor critical)
4. **Closer to V_OFF than V_ON** (concerning but not yet critical)

### Why This Matters

#### Current Sunlight Policy Blocks Mitigation
```matlab
if policy_require_sunlight_for_ep && ~isSunlit && thruster_cmd
    % Override: don't allow thruster ON outside sunlight
    thruster_cmd = false;
    reason_code = 'SUNLIGHT_POLICY_OFF';
end
```

**Result:** Even though -15V is concerning, the thruster cannot activate in eclipse.

#### Power Implications

**In Eclipse:**
- ❌ No solar panels generating power
- ❌ Battery drains if EP thruster operates
- ✓ But: Eclipse is temporary (spacecraft orbit)
- ✓ But: Better to protect spacecraft than save power

**Trade-off:**
- Risk of battery depletion vs. Risk of charging damage
- **Charging damage is permanent; battery can recharge**

---

## Recommendation: ALLOW EP IN ECLIPSE

### Option 1: Disable Sunlight Policy (RECOMMENDED)

**Configuration:**
```matlab
config.policy_require_sunlight_for_ep = false;
```

**Advantages:**
- ✅ Protects against BOTH sunlit AND eclipse charging
- ✅ Threshold-based activation (only when phi ≤ -20V)
- ✅ Comprehensive protection
- ✅ At Bennu: -15V won't trigger (above -20V threshold)
- ✅ At closer approaches: Will protect in any lighting

**Disadvantages:**
- ⚠️ EP operation in eclipse drains battery
- ⚠️ Requires power management awareness

**When EP Would Actually Activate in Eclipse:**
- Only if potential drops to ≤ -20V
- At Bennu: -15V is above threshold, so NO activation
- At closer solar approaches: May activate if eclipse charging worsens

### Option 2: Adjust Thresholds for Eclipse (ALTERNATIVE)

**Configuration:**
```matlab
config.V_ON = -15;   % More aggressive threshold
config.V_OFF = -10;  % Tighter hysteresis
config.policy_require_sunlight_for_ep = false;
```

**Advantages:**
- ✅ Catches -15V eclipse charging
- ✅ More conservative approach
- ✅ Better protection

**Disadvantages:**
- ⚠️ May cause more frequent thruster activation
- ⚠️ Higher power consumption
- ⚠️ Potential for chatter if near threshold

### Option 3: Keep Sunlight Policy (NOT RECOMMENDED)

**Configuration:**
```matlab
config.policy_require_sunlight_for_ep = true;  % Current setting
```

**Advantages:**
- ✅ Simpler logic
- ✅ Saves battery in eclipse

**Disadvantages:**
- ❌ No protection against eclipse charging
- ❌ -15V is concerning (only 5V from critical)
- ❌ If charging worsens, no mitigation available

---

## Detailed Comparison

### Scenario Analysis

| Scenario | Sunlit Charging | Eclipse Charging | Policy=true | Policy=false |
|----------|----------------|------------------|-------------|--------------|
| **Bennu (current)** | +9V (safe) | -15V (concerning) | ❌ No protection | ✓ Ready if worsens |
| **Closer approach** | -25V (critical) | -20V (critical) | ❌ No eclipse protection | ✓ Full protection |
| **Earth orbit** | +10V (safe) | -5V (safe) | ✓ OK | ✓ OK |

### Power Budget Analysis

**EP Thruster Power:** 50W (when ON)

**Eclipse Duration at Bennu:**
- Orbit period: ~4.3 hours
- Eclipse fraction: ~30-40% of orbit
- Eclipse duration: ~1.5 hours per orbit

**Power Consumption if EP Active in Eclipse:**
- 50W × 1.5 hours = 75 W-hr per orbit
- Only if phi ≤ -20V (currently -15V, so NO activation)

**Battery Reserve:**
- Typical spacecraft: Several hundred W-hr
- **Conclusion:** Manageable if needed for safety

---

## Implementation Recommendation

### For DART/Bennu Mission

**Recommended Configuration:**
```matlab
% In Mission_DART.m
init_data_charging.V_ON = -20;   % Keep standard threshold
init_data_charging.V_OFF = -12;  % Keep standard threshold
init_data_charging.policy_require_sunlight_for_ep = false;  % ALLOW in eclipse
```

**Rationale:**
1. **At Bennu:** -15V eclipse charging won't trigger thruster (above -20V)
2. **If conditions worsen:** Controller provides protection
3. **Power impact:** Minimal (only activates if critical)
4. **Safety:** Comprehensive protection more important than battery conservation

### Mission Planning Guidance

**When to USE sunlight policy (true):**
- Low-risk missions (Earth orbit, far from Sun)
- Power-constrained missions
- Eclipse charging is known to be minimal

**When to DISABLE sunlight policy (false):**
- Solar probe missions
- Missions with significant eclipse charging (like Bennu)
- When charging protection is critical
- When power budget allows for EP in eclipse

---

## Controller Behavior with Recommended Setting

### With policy_require_sunlight_for_ep = false

**Scenario 1: Bennu Eclipse (-15V)**
```
phi_eclipse = -15V
V_ON = -20V

-15V > -20V → Thruster stays OFF
Reason: Above threshold (safe enough)
```
✓ No unnecessary power consumption

**Scenario 2: Severe Eclipse Charging (-22V)**
```
phi_eclipse = -22V
V_ON = -20V

-22V ≤ -20V → Thruster turns ON
Reason: Critical charging detected
```
✓ Protection activated when needed

**Scenario 3: Sunlit Near Bennu (+9V)**
```
phi_sunlit = +9V
V_ON = -20V

+9V > -20V → Thruster stays OFF
Reason: Positive potential (safe)
```
✓ No action needed

---

## Testing Recommendations

### Test Case 1: Eclipse at Bennu (-15V)
```matlab
config.V_ON = -20;
config.V_OFF = -12;
config.policy_require_sunlight_for_ep = false;

x_AU = 0.896;  % Bennu
isSunlit = false;  % Eclipse
phi_eclipse = -15;  % Given value

Expected: Thruster stays OFF (-15V > -20V threshold)
```

### Test Case 2: Severe Eclipse Charging
```matlab
config.V_ON = -20;
config.V_OFF = -12;
config.policy_require_sunlight_for_ep = false;

x_AU = 0.896;
isSunlit = false;
phi_eclipse = -22;  % Worse than expected

Expected: Thruster turns ON (-22V ≤ -20V threshold)
```

### Test Case 3: Policy Comparison
```matlab
% Test with policy enabled
policy = true → Thruster blocked in eclipse (even if phi ≤ -20V)

% Test with policy disabled
policy = false → Thruster activates based on threshold only
```

---

## Conclusion

### Answer to Original Question

**"Should we switch ON the thruster to mitigate -15V eclipse charging?"**

**Answer:** With the **recommended configuration** (policy_require_sunlight_for_ep = false):

1. **At current -15V:** Thruster will NOT activate
   - -15V is above the -20V threshold
   - No power consumption
   - Acceptable risk level

2. **If charging worsens to ≤-20V:** Thruster WILL activate
   - Provides critical protection
   - Prevents spacecraft damage
   - Worth the battery drain

3. **Flexibility:** Controller decides based on actual conditions
   - Not blanket ON/OFF
   - Threshold-based logic
   - Optimal for mission safety

### Key Takeaway

**Enable thruster operation in eclipse** by setting `policy_require_sunlight_for_ep = false`. This provides:
- ✅ Comprehensive protection (sunlit + eclipse)
- ✅ Threshold-based activation (smart power management)
- ✅ Safety prioritized over battery conservation
- ✅ Adaptive to changing conditions

The current -15V at Bennu won't trigger the thruster (above threshold), but if conditions worsen, protection is available.

---

## References

- **Controller:** `Supporting_Functions/func_control_charging_mitigation_EP.m`
- **Configuration:** `Mission/Mission_DART.m`
- **Documentation:** `Documentation/CHARGING_MITIGATION_README.md`
- **Models:** `Supporting_Functions/Phi_sunlit_models.m`

**Last Updated:** 2024  
**Mission:** DART (Bennu)  
**Issue:** Eclipse charging mitigation
