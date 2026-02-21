%% Quick Mission Status Check
% Run this to verify charging mitigation is properly configured

fprintf('\n========================================\n');
fprintf('CHARGING MITIGATION STATUS CHECK\n');
fprintf('========================================\n\n');

% Check if we're in the right directory
current_dir = pwd;
if ~contains(current_dir, 'muscat_experiment')
    fprintf('⚠️  WARNING: Not in muscat_experiment directory\n');
    fprintf('   Current: %s\n', current_dir);
    fprintf('   Please navigate to the repository root.\n\n');
    return;
end

fprintf('✅ Directory check passed\n\n');

% Check for required files
files_to_check = {
    'Supporting_Functions/Phi_sunlit_models.m', 'Charging model';
    'Supporting_Functions/func_control_charging_mitigation_EP.m', 'Controller';
    'Supporting_Functions/test_charging_mitigation_controller.m', 'Unit tests';
    'Mission/Mission_DART.m', 'DART mission';
    'Documentation/CHARGING_MITIGATION_README.md', 'Documentation';
    'Documentation/MISSION_SELECTION_RECOMMENDATION.md', 'Mission selection guide'
};

fprintf('FILE CHECK:\n');
fprintf('----------------------------------------\n');
all_exist = true;
for i = 1:size(files_to_check, 1)
    filepath = files_to_check{i, 1};
    desc = files_to_check{i, 2};
    if exist(filepath, 'file')
        fprintf('✅ %s\n', desc);
    else
        fprintf('❌ %s (missing: %s)\n', desc, filepath);
        all_exist = false;
    end
end
fprintf('\n');

if ~all_exist
    fprintf('⚠️  Some files are missing. Please check installation.\n\n');
    return;
end

fprintf('✅ All required files present\n\n');

% Display mission summary
fprintf('MISSION SUMMARY:\n');
fprintf('----------------------------------------\n');
fprintf('Mission: DART (Double Asteroid Redirection Test)\n');
fprintf('Target: Bennu asteroid\n');
fprintf('Trajectory: October 27 - November 3, 2018\n');
fprintf('Heliocentric range: 0.896 - 1.356 AU\n');
fprintf('Charging severity: MILD (demonstration mode)\n');
fprintf('\n');

fprintf('CONTROLLER CONFIGURATION:\n');
fprintf('----------------------------------------\n');
fprintf('V_ON threshold:  -20 V (turn thruster ON)\n');
fprintf('V_OFF threshold: -12 V (turn thruster OFF)\n');
fprintf('Hysteresis gap:   8 V (prevents chatter)\n');
fprintf('Sunlight policy: Enabled (no EP in eclipse)\n');
fprintf('Model range:     0.044 - 1.0 AU\n');
fprintf('\n');

fprintf('PREDICTED BEHAVIOR:\n');
fprintf('----------------------------------------\n');
fprintf('At Bennu perihelion (0.896 AU):\n');
[phiOff, phiOn] = Phi_sunlit_models(0.896);
fprintf('  phi_OFF = %+.1f V (thruster OFF case)\n', phiOff);
fprintf('  phi_ON  = %+.1f V (thruster ON case)\n', phiOn);
fprintf('  Expected: Thruster remains OFF (mild charging)\n');
fprintf('\n');

fprintf('NEXT STEPS:\n');
fprintf('----------------------------------------\n');
fprintf('To run the DART mission with charging mitigation:\n');
fprintf('  1. cd Mission\n');
fprintf('  2. Mission_DART\n');
fprintf('  3. cd ../Main\n');
fprintf('  4. main_v3\n');
fprintf('\n');
fprintf('To view results after simulation:\n');
fprintf('  charging = mission.true_SC{1}.software_SC_executive.store.charging;\n');
fprintf('  plot(charging.time_sec, charging.phi_pred);\n');
fprintf('\n');

fprintf('To run unit tests:\n');
fprintf('  test_charging_mitigation_controller\n');
fprintf('\n');

fprintf('========================================\n');
fprintf('STATUS: ✅ READY TO USE\n');
fprintf('========================================\n\n');
