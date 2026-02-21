# Fix: True_Target_Simple Class for Mission_EVS

## Problem

Mission_EVS.m attempted to use `True_Target_Simple()` class on line 96, but this class did not exist in the repository, causing an error:

```
Error: Unrecognized function or variable 'True_Target_Simple'.

Error in Mission_EVS (line 96)
mission.true_target{1} = True_Target_Simple();
```

## Root Cause

When Mission_EVS was created for the Earth-Venus-Sun charging mitigation mission, it needed a simple target representation for the Sun (stationary at the origin). The existing target classes in MuSCAT were:

- **True_Target_SPICE** - For targets with SPICE ephemeris data
- **True_Target_Computed** - For targets requiring dynamic integration

Neither was appropriate for a simple stationary target, so `True_Target_Simple` was referenced but never implemented.

## Solution

Created a new lightweight target class: `True_Target_Simple`

### File Location
```
True_Environment/True_Target_Simple.m
```

### Class Purpose

Provides a minimal target representation for:
- Stationary bodies (e.g., Sun at origin in Sun-centered reference frame)
- Simple targets without complex dynamics
- Cases where SPICE data is unnecessary

### Key Features

1. **Basic Properties:**
   - `name` - Target name
   - `radius` - Target radius [km]
   - `position` - Target position [km] (1x3)
   - `velocity` - Target velocity [km/sec] (1x3)

2. **Optional Properties:**
   - `mass` - Target mass [kg]
   - `mu` - Gravitational parameter [km³/sec²]

3. **Methods:**
   - Constructor: `True_Target_Simple(init_data)` (init_data optional)
   - Update method: `update()` (for interface compatibility)

4. **Vector Format:**
   - Automatically handles row/column vector conversion
   - Ensures 1x3 row vector format (MuSCAT convention)

## Usage Example

### In Mission_EVS.m

```matlab
% Create Sun as simple target at origin
mission.true_target{1} = True_Target_Simple();
mission.true_target{1}.name = 'Sun';
mission.true_target{1}.radius = 696000; % km
mission.true_target{1}.position = [0, 0, 0]; % Sun at origin
mission.true_target{1}.velocity = [0, 0, 0];
```

### Alternative: With init_data

```matlab
% Create target with initialization data
init_data.name = 'Sun';
init_data.radius = 696000;
init_data.position = [0, 0, 0];
init_data.velocity = [0, 0, 0];

mission.true_target{1} = True_Target_Simple(init_data);
```

## Implementation Details

### Constructor Logic

```matlab
function obj = True_Target_Simple(init_data)
    % Handle optional init_data
    if nargin > 0 && ~isempty(init_data)
        % Copy fields from init_data
        if isfield(init_data, 'name'), obj.name = init_data.name; end
        if isfield(init_data, 'radius'), obj.radius = init_data.radius; end
        % ... etc
    else
        % Default initialization
        obj.name = 'Simple Target';
        obj.radius = 1;
        obj.position = [0, 0, 0];
        obj.velocity = [0, 0, 0];
    end
    
    % Ensure row vector format (1x3)
    if size(obj.position, 1) == 3
        obj.position = obj.position';
    end
    if size(obj.velocity, 1) == 3
        obj.velocity = obj.velocity';
    end
end
```

### Update Method (Compatibility)

```matlab
function update(obj, ~, ~)
    % Do nothing - simple target is stationary
    % Exists for interface compatibility with other target classes
end
```

## Benefits

1. **Simplicity:** Minimal overhead for simple targets
2. **No Dependencies:** No SPICE or external data required
3. **Flexibility:** Can be used for any stationary target
4. **Compatibility:** Follows MuSCAT class patterns
5. **Future-Proof:** Easy to extend if needed

## Testing

### Basic Functionality
- ✅ Constructor with no arguments
- ✅ Constructor with init_data
- ✅ Property assignment
- ✅ Vector format conversion
- ✅ Update method (no-op)

### Mission_EVS Integration
- ✅ Target creation successful
- ✅ Sun at origin [0, 0, 0]
- ✅ Radius 696,000 km
- ✅ Ready for simulation

## Impact

### Files Changed
- **Created:** `True_Environment/True_Target_Simple.m` (84 lines)

### Files Using This Class
- `Mission/Mission_EVS.m` (line 96)

### Future Use Cases
This class can be reused for:
- Any Sun-centered mission (Sun at origin)
- Fixed waypoints in space
- Simple gravitational sources
- Test scenarios with artificial targets

## Comparison with Other Target Classes

| Feature | True_Target_Simple | True_Target_SPICE | True_Target_Computed |
|---------|-------------------|-------------------|---------------------|
| SPICE Required | No | Yes | Optional |
| Dynamic Updates | No | Yes | Yes |
| Integration | No | No | Yes |
| Overhead | Minimal | Medium | High |
| Use Case | Fixed targets | Real bodies | Dynamic bodies |

## Resolution

**Status:** ✅ **FIXED**

Mission_EVS can now run without the `True_Target_Simple` error. The class is implemented, tested, and ready for use.

### To Run Mission_EVS:
```matlab
cd Mission
Mission_EVS
cd ../Main
main_v3
```

## Notes

- This is a minimal implementation focused on the immediate need
- Can be extended in the future if more features are needed
- Follows the handle class pattern used throughout MuSCAT
- Maintains consistency with existing True_Target classes

## Related Files

- `Mission/Mission_EVS.m` - Uses True_Target_Simple
- `True_Environment/True_Target_SPICE.m` - Complex target class
- `True_Environment/True_Target_Computed.m` - Dynamic target class

## Date

Fixed: February 21, 2026

## Author

GitHub Copilot Agent
