# 🚀 Quick Reference: Download Modified NISAR Package

## Direct Download Links

### Git Clone (Recommended)
```bash
git clone -b copilot/enable-microthruster-functionality https://github.com/Tshi24/muscat_experiment.git
```

### ZIP Download
**Direct Link:** [Download ZIP](https://github.com/Tshi24/muscat_experiment/archive/refs/heads/copilot/enable-microthruster-functionality.zip)

### GitHub Web Interface
1. Visit: https://github.com/Tshi24/muscat_experiment
2. Click branch dropdown → Select `copilot/enable-microthruster-functionality`
3. Click "Code" → "Download ZIP"

## What You Get

✅ NISAR mission with **12 active microthrusters**  
✅ Asymptotically stable attitude control  
✅ KKT optimization for thruster allocation  
✅ Fuel consumption tracking  
✅ Full system integration (power, data, control)  

## Quick Start After Download

```bash
cd muscat_experiment/Mission
# Open MATLAB
matlab
```

```matlab
% In MATLAB:
Mission_NISAR  % Run the simulation
```

## Files Modified

- `Mission/Mission_NISAR.m` - Enabled 12 microthrusters, set control mode
- `Supporting_Functions/mission_specific/NISAR/func_update_software_SC_control_attitude_NISAR.m` - Added control modes

## Full Documentation

See [MICROTHRUSTER_SETUP.md](MICROTHRUSTER_SETUP.md) for complete setup guide

## Support

- Issues: https://github.com/Tshi24/muscat_experiment/issues
- Original MuSCAT: Saptarshi.Bandyopadhyay@jpl.nasa.gov
