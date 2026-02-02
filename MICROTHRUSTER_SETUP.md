# MuSCAT NISAR Mission with Microthrusters - Download & Setup Guide

This guide explains how to download and run the modified MuSCAT package with **microthrusters enabled** for the NISAR mission.

## 🎯 What's New

The NISAR mission now includes:
- ✅ **12 Active Microthrusters** (was disabled before)
- ✅ **Asymptotically Stable Attitude Control** using microthrusters
- ✅ **KKT Optimization** for thruster torque allocation
- ✅ **Full Integration** with fuel management, power, and data handling systems

## 📥 Download Options

### Option 1: Clone the Branch Directly (Recommended)

```bash
# Clone the repository with the microthruster branch
git clone -b copilot/enable-microthruster-functionality https://github.com/Tshi24/muscat_experiment.git
cd muscat_experiment
```

### Option 2: Clone and Switch to the Branch

```bash
# Clone the entire repository
git clone https://github.com/Tshi24/muscat_experiment.git
cd muscat_experiment

# Switch to the microthruster branch
git checkout copilot/enable-microthruster-functionality
```

### Option 3: Download as ZIP

1. Go to: https://github.com/Tshi24/muscat_experiment
2. Click on the branch dropdown (should show "main" or current branch)
3. Select `copilot/enable-microthruster-functionality`
4. Click the green "Code" button
5. Select "Download ZIP"
6. Extract the ZIP file to your desired location

## 🔧 Prerequisites

Before running the mission, ensure you have:

1. **MATLAB** (tested with recent versions)
2. **MuSCAT_Supporting_Files** folder in the parent directory
   - Download from: https://www.dropbox.com/s/qokkcj6sn802n7p/MuSCAT_Supporting_Files.zip?dl=0
   - Extract so you have: `parent_folder/MuSCAT_Supporting_Files/` and `parent_folder/muscat_experiment/`
3. **SPICE Toolkit** (MICE for MATLAB)
   - Download from: https://naif.jpl.nasa.gov/naif/toolkit_MATLAB.html
   - Place in `MuSCAT_Supporting_Files/SPICE/`

## 🚀 Running the NISAR Mission with Microthrusters

### Quick Start

1. **Navigate to the Mission folder:**
   ```matlab
   cd /path/to/muscat_experiment/Mission
   ```

2. **Open MATLAB and run:**
   ```matlab
   Mission_NISAR
   ```

3. **The simulation will:**
   - Initialize 12 microthrusters
   - Use asymptotically stable control with microthrusters
   - Generate attitude control visualizations
   - Show thruster firing patterns
   - Track fuel consumption

## 📊 What to Expect

### Microthuster Configuration

The NISAR spacecraft now has **12 microthrusters**:

| Thrusters | Max Thrust | Min Thrust | Purpose |
|-----------|------------|------------|---------|
| 1-11      | 11 N       | 0.1 N      | High-thrust attitude control |
| 12        | 1 N        | 0.01 N     | Fine attitude control |

**Specifications:**
- ISP: 220 seconds
- Noise level: 100 μN
- Command wait time: 0.5 seconds
- Control mode: Asymptotically stable with KKT optimization

### Control Mode

The mission uses: **`NISAR Control Asymptotically Stable send to thrusters`**

This means:
- Real attitude control using microthrusters (not Oracle mode)
- Torque is decomposed optimally across all 12 thrusters
- Fuel consumption is tracked and integrated with fuel tanks
- Power consumption is monitored
- Data generation is logged

## 📁 Modified Files

The following files were modified to enable microthrusters:

1. **`Mission/Mission_NISAR.m`**
   - Line 468: `num_micro_thruster = 12` (was 0)
   - Line 1190: Control mode set to `'NISAR Control Asymptotically Stable send to thrusters'`

2. **`Supporting_Functions/mission_specific/NISAR/func_update_software_SC_control_attitude_NISAR.m`**
   - Added two new control modes for microthruster operation
   - Integrated with existing DART control algorithms

## 🔍 Verification

To verify microthrusters are working:

1. **Check initialization output** - Should show 12 microthrusters being initialized
2. **Monitor simulation** - Look for thruster firing events
3. **Review output plots** - Attitude control plots will show thruster activity
4. **Check fuel consumption** - Fuel tank mass should decrease over time

## 💡 Tips

### Faster Simulation
To speed up the simulation, you can:
- Reduce simulation time in Mission_NISAR.m (line 47)
- Increase time step (line 37)
- Disable real-time plotting (line 63): `init_data.flag_realtime_plotting = 0;`

### Switching Back to Oracle Mode
If you want to compare with Oracle mode:
```matlab
% In Mission_NISAR.m, line 1190, change to:
init_data.mode_software_SC_control_attitude_selector = 'NISAR Oracle';

% And optionally disable microthrusters:
% Line 468:
init_data.num_hardware_exists.num_micro_thruster = 0;
```

## 📧 Support

For issues or questions:
- GitHub Issues: https://github.com/Tshi24/muscat_experiment/issues
- Original MuSCAT: Contact Saptarshi.Bandyopadhyay@jpl.nasa.gov

## 🎓 Learn More

- See `README.md` in the repository root for general MuSCAT documentation
- See `Documentation/` folder for detailed technical documentation
- Review DART mission example (`Mission_DART.m`) for another microthruster implementation

---

**Happy Simulating! 🚀**

*Last Updated: 2026-02-02*
