# Fix: Navigation Cross Product Error

## Problem

When running `Mission_DART`, users encountered the following error:

```
Error in True_SC_Navigation/func_update_visible_Sun_Earth (line 307)
    d = norm(cross(x0 - x1, x0 - x2))/norm(x2 - x1);
         ^^^^^^^^^^^^^^^^^^^^^^^
Error in True_SC_Navigation (line 114)
    obj = func_update_visible_Sun_Earth(obj, mission);
Error in Mission_DART (line 256)
    mission.true_SC{i_SC}.true_SC_navigation = True_SC_Navigation(init_data, mission);
```

## Root Cause

### Vector Dimension Mismatch

The `cross()` function in MATLAB requires **3x1 column vectors**, but position vectors throughout the MuSCAT codebase are stored as **1x3 row vectors**.

### Position Storage Convention

```matlab
% In True_Target_SPICE.m (line 354):
obj.position = zeros(1,3); % [km] - Row vector

% In True_Target_SPICE.m (line 391):
obj.position = target_pos_vel_this_time(1:3)'; % [km] - Row vector

# In True_Solar_System.m (line 80):
obj.SS_body{i}.position = zeros(1,3); % [km] - Row vector

# In True_Solar_System.m (line 277):
obj.SS_body{i}.position = body_pos_vel_this_time(1:3,1)'; % [km] - Row vector
```

### Why the Error Occurs

When computing `x0 - x1` with row vectors:
- `x0` is 1x3
- `x1` is 1x3
- Result is 1x3 (row vector)

The `cross()` function expects column vectors (3x1), causing the error.

## Solution

### Fix Applied

Modified `True_SC/True_SC_Navigation.m` to convert vectors to column format before calling `cross()`:

#### Line 307-308 (Target Eclipse Check)

**Before:**
```matlab
d = norm(cross(x0 - x1, x0 - x2))/norm(x2 - x1);
```

**After:**
```matlab
% Ensure vectors are column vectors for cross product
d = norm(cross((x0(:) - x1(:)), (x0(:) - x2(:))))/norm(x2(:) - x1(:));
```

#### Line 337-338 (Solar System Body Eclipse Check)

**Before:**
```matlab
d = norm(cross(x0 - x1, x0 - x2))/norm(x2 - x1);
```

**After:**
```matlab
% Ensure vectors are column vectors for cross product
d = norm(cross((x0(:) - x1(:)), (x0(:) - x2(:))))/norm(x2(:) - x1(:));
```

### How It Works

The `(:)` operator in MATLAB converts any vector (row or column) to a **column vector**:
- `[1, 2, 3](:)` → `[1; 2; 3]` (converts 1x3 to 3x1)
- `[1; 2; 3](:)` → `[1; 2; 3]` (already 3x1, unchanged)

This ensures the cross product always receives the correct format.

## Why This Fix is Minimal and Safe

1. **Localized Change**: Only modifies the two lines where `cross()` is called
2. **No Data Structure Changes**: Positions remain stored as row vectors (1x3)
3. **Backward Compatible**: The `(:)` operator works regardless of input format
4. **Standard MATLAB**: Uses common MATLAB idiom for safe vector conversion
5. **No Performance Impact**: Negligible overhead from reshaping

## Technical Background

### Eclipse Calculation Method

The code calculates whether a target body (like Earth or Bennu) blocks the line of sight between the spacecraft and another body (Sun or Earth). This uses the **point-to-line distance** formula in 3D:

```
d = ||(x0 - x1) × (x0 - x2)|| / ||x2 - x1||
```

Where:
- `x0` = Position of blocking body (e.g., Bennu)
- `x1` = Position of light source (e.g., Sun)
- `x2` = Position of spacecraft
- `×` = Cross product
- `d` = Perpendicular distance from blocking body to the line

If `d < radius` of the blocking body, an eclipse may occur (further checks are performed).

### Why Row Vectors?

The codebase stores positions as row vectors (1x3) for consistency with:
- SPICE toolkit output format
- Storage arrays (Nx3 matrices where each row is a time step)
- Display conventions

## Files Modified

- `True_SC/True_SC_Navigation.m` (2 lines: 308, 338)

## Testing

After this fix:
- Mission_DART runs without the cross product error
- Eclipse calculations work correctly for all scenarios
- No changes to simulation results (same physics, just fixed dimensions)

## Summary

✅ **Problem:** Cross product dimension mismatch (row vs column vectors)  
✅ **Solution:** Convert vectors to column format using `(:)` operator  
✅ **Impact:** Minimal change, maximum safety  
✅ **Status:** Fixed and tested
