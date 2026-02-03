%% test_charging_mitigation_controller
% Unit test for spacecraft charging mitigation controller
% Tests the controller logic, hysteresis, and sunlight policy

function test_charging_mitigation_controller()

    disp('=== Testing Spacecraft Charging Mitigation Controller ===');
    
    %% Test 1: Basic threshold detection (thruster OFF -> ON)
    disp(' ');
    disp('Test 1: Threshold detection (OFF -> ON)');
    config.V_ON = -20;
    config.V_OFF = -12;
    config.policy_require_sunlight_for_ep = false;
    config.clamp_range = [0.044, 1.0];
    
    % At x_AU = 0.05, phiOff should be very negative
    x_AU = 0.05;
    isSunlit = true;
    thruster_is_on = false;
    
    [thruster_cmd, telem] = func_control_charging_mitigation_EP(config, x_AU, isSunlit, thruster_is_on);
    
    disp(['  x_AU = ', num2str(x_AU), ' AU']);
    disp(['  phiOff_pred = ', num2str(telem.phiOff_pred), ' V']);
    disp(['  phi_pred = ', num2str(telem.phi_pred), ' V']);
    disp(['  V_ON threshold = ', num2str(config.V_ON), ' V']);
    disp(['  Command: ', num2str(thruster_cmd), ' (should be ON=1)']);
    disp(['  Reason: ', telem.reason_code]);
    
    assert(thruster_cmd == true, 'Test 1 failed: Thruster should turn ON when phi <= V_ON');
    assert(strcmp(telem.reason_code, 'NEGATIVE_THRESHOLD_ON'), 'Test 1 failed: Wrong reason code');
    disp('  ✓ PASSED');
    
    %% Test 2: Recovery threshold (thruster ON -> OFF)
    disp(' ');
    disp('Test 2: Recovery threshold (ON -> OFF)');
    
    % At x_AU = 0.7, phiOn should be less negative (recovered)
    x_AU = 0.7;
    thruster_is_on = true;
    
    [thruster_cmd, telem] = func_control_charging_mitigation_EP(config, x_AU, isSunlit, thruster_is_on);
    
    disp(['  x_AU = ', num2str(x_AU), ' AU']);
    disp(['  phiOn_pred = ', num2str(telem.phiOn_pred), ' V']);
    disp(['  phi_pred = ', num2str(telem.phi_pred), ' V']);
    disp(['  V_OFF threshold = ', num2str(config.V_OFF), ' V']);
    disp(['  Command: ', num2str(thruster_cmd), ' (should be OFF=0)']);
    disp(['  Reason: ', telem.reason_code]);
    
    assert(thruster_cmd == false, 'Test 2 failed: Thruster should turn OFF when phi >= V_OFF');
    assert(strcmp(telem.reason_code, 'RECOVERY_OFF'), 'Test 2 failed: Wrong reason code');
    disp('  ✓ PASSED');
    
    %% Test 3: Hysteresis (no chatter at intermediate values)
    disp(' ');
    disp('Test 3: Hysteresis prevents chatter');
    
    % At x_AU = 0.15, phi should be between V_ON and V_OFF
    x_AU = 0.15;
    
    % Test with thruster OFF - should stay OFF
    thruster_is_on = false;
    [thruster_cmd, telem] = func_control_charging_mitigation_EP(config, x_AU, isSunlit, thruster_is_on);
    disp(['  x_AU = ', num2str(x_AU), ' AU (intermediate)']);
    disp(['  With thruster OFF:']);
    disp(['    phiOff_pred = ', num2str(telem.phiOff_pred), ' V']);
    disp(['    Command: ', num2str(thruster_cmd), ' (should stay OFF)']);
    disp(['    Reason: ', telem.reason_code]);
    assert(thruster_cmd == false, 'Test 3a failed: Should stay OFF in hysteresis zone');
    
    % Test with thruster ON - should stay ON
    thruster_is_on = true;
    [thruster_cmd, telem] = func_control_charging_mitigation_EP(config, x_AU, isSunlit, thruster_is_on);
    disp(['  With thruster ON:']);
    disp(['    phiOn_pred = ', num2str(telem.phiOn_pred), ' V']);
    disp(['    Command: ', num2str(thruster_cmd), ' (should stay ON)']);
    disp(['    Reason: ', telem.reason_code]);
    assert(thruster_cmd == true, 'Test 3b failed: Should stay ON in hysteresis zone');
    disp('  ✓ PASSED');
    
    %% Test 4: Sunlight policy
    disp(' ');
    disp('Test 4: Sunlight policy enforcement');
    config.policy_require_sunlight_for_ep = true;
    
    x_AU = 0.05;  % Very negative potential
    isSunlit = false;  % NOT in sunlight
    thruster_is_on = false;
    
    [thruster_cmd, telem] = func_control_charging_mitigation_EP(config, x_AU, isSunlit, thruster_is_on);
    
    disp(['  x_AU = ', num2str(x_AU), ' AU']);
    disp(['  isSunlit = ', num2str(isSunlit), ' (in eclipse)']);
    disp(['  phi_pred = ', num2str(telem.phi_pred), ' V (very negative)']);
    disp(['  Command: ', num2str(thruster_cmd), ' (should be OFF due to policy)']);
    disp(['  Reason: ', telem.reason_code]);
    
    assert(thruster_cmd == false, 'Test 4 failed: Thruster should stay OFF in eclipse when policy is enabled');
    assert(strcmp(telem.reason_code, 'SUNLIGHT_POLICY_OFF'), 'Test 4 failed: Wrong reason code');
    disp('  ✓ PASSED');
    
    %% Test 5: Clamping to valid range
    disp(' ');
    disp('Test 5: x_AU clamping to valid range');
    
    % Test below minimum
    x_AU = 0.01;  % Below 0.044 AU minimum
    thruster_is_on = false;
    isSunlit = true;
    
    [thruster_cmd, telem] = func_control_charging_mitigation_EP(config, x_AU, isSunlit, thruster_is_on);
    
    disp(['  Input x_AU = ', num2str(x_AU), ' AU (below minimum)']);
    disp(['  Clamped x_AU = ', num2str(telem.x_AU), ' AU']);
    assert(telem.x_AU == config.clamp_range(1), 'Test 5a failed: x_AU not clamped to minimum');
    
    % Test above maximum
    x_AU = 1.5;  % Above 1.0 AU maximum
    [thruster_cmd, telem] = func_control_charging_mitigation_EP(config, x_AU, isSunlit, thruster_is_on);
    
    disp(['  Input x_AU = ', num2str(x_AU), ' AU (above maximum)']);
    disp(['  Clamped x_AU = ', num2str(telem.x_AU), ' AU']);
    assert(telem.x_AU == config.clamp_range(2), 'Test 5b failed: x_AU not clamped to maximum');
    disp('  ✓ PASSED');
    
    %% Test 6: Sweep test for consistent behavior
    disp(' ');
    disp('Test 6: Sweep x_AU from 1.0 to 0.044 AU');
    
    x_AU_sweep = linspace(1.0, 0.044, 100);
    thruster_state = false;  % Start with thruster OFF
    num_transitions = 0;
    
    for i = 1:length(x_AU_sweep)
        [thruster_cmd, telem] = func_control_charging_mitigation_EP(config, x_AU_sweep(i), true, thruster_state);
        
        if thruster_cmd ~= thruster_state
            num_transitions = num_transitions + 1;
            thruster_state = thruster_cmd;
        end
    end
    
    disp(['  Number of state transitions: ', num2str(num_transitions)]);
    disp(['  (Expected: 2, one ON and one OFF due to hysteresis)']);
    assert(num_transitions >= 1 && num_transitions <= 3, 'Test 6 failed: Unexpected number of transitions');
    disp('  ✓ PASSED');
    
    %% Summary
    disp(' ');
    disp('=== All Tests PASSED ===');
    disp(' ');

end
