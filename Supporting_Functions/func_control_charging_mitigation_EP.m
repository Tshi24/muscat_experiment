%% func_control_charging_mitigation_EP
% Spacecraft charging mitigation controller for electric propulsion thruster
%
% This function predicts spacecraft potential (sunlit charging) and toggles 
% the electric thruster ON/OFF to mitigate strong negative charging.
%
% Inputs:
%   config - struct with controller parameters:
%       .V_ON  - threshold to turn thruster ON (default: -20 V)
%       .V_OFF - threshold to turn thruster OFF (default: -12 V)
%       .policy_require_sunlight_for_ep - only allow EP ON in sunlight (default: true)
%       .clamp_range - [min max] for x_AU clamping (default: [0.044, 1.0])
%   x_AU - heliocentric distance in AU
%   isSunlit - boolean (true if spacecraft is in sunlight)
%   thruster_is_on - current EP thruster state (true/false)
%
% Outputs:
%   thruster_cmd - commanded thruster state (true=ON, false=OFF)
%   telemetry - struct with:
%       .x_AU - clamped heliocentric distance used
%       .isSunlit - sunlight status
%       .phiOff_pred - predicted potential with thruster OFF (V)
%       .phiOn_pred - predicted potential with thruster ON (V)
%       .phi_pred - predicted potential based on current state (V)
%       .thruster_is_on - input thruster state
%       .thruster_cmd - commanded thruster state
%       .reason_code - string describing decision ('NEGATIVE_THRESHOLD_ON', 'RECOVERY_OFF', 'HOLD', 'SUNLIGHT_POLICY_OFF')

function [thruster_cmd, telemetry] = func_control_charging_mitigation_EP(config, x_AU, isSunlit, thruster_is_on)

    %% Set default configuration values if not provided
    if ~isfield(config, 'V_ON')
        config.V_ON = -20; % [V] Turn thruster ON when phi <= -20 V
    end
    
    if ~isfield(config, 'V_OFF')
        config.V_OFF = -12; % [V] Allow thruster OFF when phi >= -12 V
    end
    
    if ~isfield(config, 'policy_require_sunlight_for_ep')
        config.policy_require_sunlight_for_ep = true;
    end
    
    if ~isfield(config, 'clamp_range')
        config.clamp_range = [0.044, 1.0]; % [AU] Valid model range
    end
    
    %% Safety: Clamp x_AU to valid model range to avoid blow-ups
    x_AU_clamped = min(max(x_AU, config.clamp_range(1)), config.clamp_range(2));
    
    %% Compute predicted potentials using SPIS-based models
    [phiOff_pred, phiOn_pred] = Phi_sunlit_models(x_AU_clamped);
    
    %% Choose phi_pred according to current thruster state
    if thruster_is_on
        phi_pred = phiOn_pred;
    else
        phi_pred = phiOff_pred;
    end
    
    %% Decision logic with hysteresis
    reason_code = 'HOLD';  % Default: maintain current state
    thruster_cmd = thruster_is_on;  % Default: keep current state
    
    % Check if thruster should turn ON (negative threshold)
    if ~thruster_is_on && phi_pred <= config.V_ON
        thruster_cmd = true;
        reason_code = 'NEGATIVE_THRESHOLD_ON';
    end
    
    % Check if thruster should turn OFF (recovery threshold)
    if thruster_is_on && phi_pred >= config.V_OFF
        thruster_cmd = false;
        reason_code = 'RECOVERY_OFF';
    end
    
    %% Apply sunlight policy if enabled
    if config.policy_require_sunlight_for_ep && ~isSunlit && thruster_cmd
        % Override: don't allow thruster ON outside sunlight
        thruster_cmd = false;
        reason_code = 'SUNLIGHT_POLICY_OFF';
    end
    
    %% Package telemetry
    telemetry.x_AU = x_AU_clamped;
    telemetry.isSunlit = isSunlit;
    telemetry.phiOff_pred = phiOff_pred;
    telemetry.phiOn_pred = phiOn_pred;
    telemetry.phi_pred = phi_pred;
    telemetry.thruster_is_on = thruster_is_on;
    telemetry.thruster_cmd = thruster_cmd;
    telemetry.reason_code = reason_code;

end
