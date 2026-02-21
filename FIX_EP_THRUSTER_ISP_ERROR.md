# Fix for "Unrecognized field name 'thruster_ISP'" Error

## Problem

When running `Mission_DART.m`, you encountered this error:

```
Unrecognized field name "thruster_ISP".

Error in True_SC_EP_Thruster (line 130)
    obj.isp = init_data.thruster_ISP; % sec
              ^^^^^^^^^^^^^^^^^^^^^^
Error in Mission_DART (line 716)
    mission.true_SC{i_SC}.true_SC_EP_thruster{i_HW} = True_SC_EP_Thruster(init_data, mission, i_SC, i_HW);
```

## Root Cause

There was a **field name mismatch** between Mission_DART.m and the True_SC_EP_Thruster class:

| File | Line | Field Name | Status |
|------|------|------------|--------|
| Mission_DART.m | 701 | `init_data.isp` | ❌ Incorrect |
| True_SC_EP_Thruster.m | 130 | `init_data.thruster_ISP` | ✅ Expected |

The Mission_DART.m file was setting `init_data.isp`, but the EP thruster class was looking for `init_data.thruster_ISP`.

## Solution Applied ✅

**Updated Mission_DART.m line 701:**

```matlab
% BEFORE (incorrect):
init_data.isp = 3000;  % [s] High specific impulse for EP

% AFTER (correct):
init_data.thruster_ISP = 3000;  % [s] High specific impulse for EP
```

## Why This Naming Convention?

All thruster types in MuSCAT follow the pattern `<type>_ISP`:

```matlab
% Micro Thrusters (line 547)
init_data.micro_thruster_ISP = 700;  % [sec]

% Chemical Thrusters (line 678)
init_data.chemical_thruster_ISP = 200;  % [s]

% EP Thrusters (line 701)
init_data.thruster_ISP = 3000;  % [s]  ← Fixed!
```

## Verification

The fix has been verified:
- ✅ Field name matches what True_SC_EP_Thruster expects
- ✅ Consistent with other thruster type naming conventions
- ✅ No other references to incorrect field name found

## Status

**FIXED** - Pull the latest changes from the branch and the error should be resolved.

```bash
git pull origin copilot/add-charging-mitigation-controller
```

Then run Mission_DART normally:
```matlab
cd Mission
Mission_DART
```

---

**Fixed:** 2024-02-04  
**Commit:** dc0e732  
**File Modified:** Mission/Mission_DART.m (1 line change)
