# Fix: Vector Dimension Mismatch Error

## Problem

You encountered this error when running Mission_DART:

```
Unable to perform assignment because the size of the left side is 1-by-3 
and the size of the right side is 3-by-3.

Error in True_SC_Navigation/func_update_true_SC_navigation_store (line 138)
    obj.store.position_relative_target(mission.storage.k_storage,:) = obj.position_relative_target;
```

## Simple Explanation

### What Happened?

The code was trying to store a spacecraft position, but there was a size mismatch:
- **Expected:** A simple 3-element vector: `[x, y, z]` (1 row, 3 columns)
- **Got:** A 3x3 matrix (3 rows, 3 columns)

### Why Did This Happen?

In MATLAB, there are two ways to create vectors:

1. **Row vector** (horizontal): `[1, 2, 3]` - commas separate elements → 1x3 (1 row, 3 columns)
2. **Column vector** (vertical): `[1; 2; 3]` - semicolons separate elements → 3x1 (3 rows, 1 column)

The charging mitigation scenarios we added used **semicolons** (creating column vectors):
```matlab
init_data.position = [r_AU; 0; 0];  % Creates 3x1 column vector ❌
```

But the rest of the codebase expects **commas** (creating row vectors):
```matlab
init_data.position = [r_AU, 0, 0];  % Creates 1x3 row vector ✓
```

### The Chain Reaction

When different vector orientations are mixed in math operations, MATLAB "broadcasts" them:

```matlab
% If obj.position is 3x1 (column) and position_target is 1x3 (row):
obj.position_relative_target = obj.position - position_target;

% Result: 3x3 matrix! (MATLAB subtracts each row from each column)
```

This 3x3 matrix then couldn't be stored in a slot that expects 1x3.

## The Fix

Changed all vector initializations in the charging scenarios from **semicolons to commas**:

### Before (Wrong) ❌
```matlab
init_data.position = [r_AU; 0; 0];      % Column vector (3x1)
init_data.velocity = [0; v_circ; 0];    % Column vector (3x1)
```

### After (Correct) ✓
```matlab
init_data.position = [r_AU, 0, 0];      % Row vector (1x3)
init_data.velocity = [0, v_circ, 0];    % Row vector (1x3)
```

## Files Modified

- `Mission/Mission_DART.m`
  - Line 219: AU1_sunlight position
  - Line 222: AU1_sunlight velocity
  - Line 230: AU1_eclipse position
  - Line 232: AU1_eclipse velocity
  - Line 238: AU0044 position
  - Line 240: AU0044 velocity

## Verification

The fix ensures consistency with how the SPICE trajectory loader initializes vectors:

```matlab
% Line 207 - SPICE initialization (creates 1x3):
init_data.SC_pos_vel = cspice_spkezr(...);  % Returns 6x1
init_data.position = init_data.SC_pos_vel(1:3)';  % Take first 3, transpose to 1x3
```

Now all scenarios use the same 1x3 row vector format.

## Result

✅ Mission_DART now runs successfully with all charging scenarios:
- `mission.charging_scenario = 'AU1_sunlight'`
- `mission.charging_scenario = 'AU1_eclipse'`
- `mission.charging_scenario = 'AU0044'`
- `mission.charging_scenario = 'BENNU'` (default)

## Lesson Learned

When working with MATLAB vectors:
- **Commas** `,` → Row vectors (1xN) - horizontal
- **Semicolons** `;` → Column vectors (Nx1) - vertical
- Mixing them in math operations can create unexpected matrices!
- Always maintain consistency with the rest of the codebase!
