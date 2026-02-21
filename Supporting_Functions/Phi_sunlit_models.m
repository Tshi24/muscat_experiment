%% Phi_sunlit_models
% SPIS-based curve-fit models for spacecraft potential prediction
% Valid only for x_AU in [0.044, 1.0] AU
%
% Inputs:
%   x_AU - heliocentric distance in AU (can be scalar or vector)
%
% Outputs:
%   phiOff - predicted potential (V) with thruster OFF
%   phiOn  - predicted potential (V) with thruster ON
%
% Model based on SPIS simulations for sunlit spacecraft charging

function [phiOff, phiOn] = Phi_sunlit_models(x_AU)

    % Use xi as shorthand for x_AU (supports vectorized inputs)
    xi = x_AU;
    
    % Model for thruster OFF case
    phiOff = 8.39628 ...
           - 0.000770893 ./ (xi.^4) ...
           + 0.029318    ./ (xi.^3) ...
           - 0.362418    ./ (xi.^2) ...
           + 0.541516    ./ (xi) ...
           + 0.623116    .* (xi.^2);
    
    % Model for thruster ON case
    phiOn  = -5.6241689717 ...
           - 0.0001905435754 ./ (xi.^4) ...
           + 0.0060468979089 ./ (xi.^3) ...
           - 0.0319720512141 ./ (xi.^2) ...
           - 1.0811794594    .* (xi.^2);

end
