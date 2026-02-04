%% Phi_eclipse_models
% Eclipse charging model for spacecraft potential prediction
% Valid for x_AU in [0.044, 1.0] AU
%
% Inputs:
%   x_AU - heliocentric distance in AU (can be scalar or vector)
%
% Outputs:
%   phiOff_eclipse - predicted potential (V) with thruster OFF in eclipse
%   phiOn_eclipse  - predicted potential (V) with thruster ON in eclipse
%
% Model: Eclipse charging is typically more negative than sunlit charging
% At 1 AU: approximately -15 V (thruster OFF), -8 V (thruster ON)
% At 0.044 AU: approximately -35 V (thruster OFF), -10 V (thruster ON)
%
% This model complements Phi_sunlit_models.m for comprehensive charging coverage

function [phiOff_eclipse, phiOn_eclipse] = Phi_eclipse_models(x_AU)

    % Use xi as shorthand for x_AU (supports vectorized inputs)
    xi = x_AU;
    
    % Eclipse model for thruster OFF case
    % Designed to give approximately:
    % - At 1.0 AU: -15 V
    % - At 0.5 AU: -20 V
    % - At 0.044 AU: -35 V
    phiOff_eclipse = -10.0 ...
                   - 5.0 ./ xi ...
                   - 0.2 ./ (xi.^2) ...
                   - 0.01 ./ (xi.^3);
    
    % Eclipse model for thruster ON case
    % Thruster ON provides mitigation (less negative)
    % Designed to give approximately:
    % - At 1.0 AU: -8 V
    % - At 0.5 AU: -12 V  
    % - At 0.044 AU: -10 V
    phiOn_eclipse  = -5.0 ...
                   - 3.0 ./ xi ...
                   - 0.1 ./ (xi.^2) ...
                   - 0.005 ./ (xi.^3);

end
