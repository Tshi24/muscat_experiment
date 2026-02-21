function trajectory = func_compute_parker_trajectory(mission_duration_days)
% func_compute_parker_trajectory - Generate Parker Solar Probe-inspired trajectory
%
% Creates a simplified trajectory similar to Parker Solar Probe:
% - Earth departure (1.0 AU)
% - Venus gravity assist flybys (0.72 AU)
% - Perihelion approaches to Sun (0.044 AU)
%
% INPUTS:
%   mission_duration_days - Total mission duration [days]
%
% OUTPUTS:
%   trajectory - Structure with trajectory data:
%     .time_jd - Julian dates [JD]
%     .time_days - Time since start [days]
%     .position - Position vectors [km] (Nx3)
%     .velocity - Velocity vectors [km/s] (Nx3)
%     .r_sun - Distance from Sun [AU]
%     .phase - Mission phase ID (1-5)
%     .phase_name - Mission phase name
%
% Mission phases:
%   1: Earth departure (1.0 AU circular)
%   2: Transfer to Venus
%   3: Venus flyby (0.72 AU)
%   4: Transfer to perihelion
%   5: Near-Sun operations (0.044 AU)
%
% Reference: Parker Solar Probe uses Venus flybys to progressively
% lower perihelion from ~0.73 AU to ~0.046 AU (9.86 solar radii)
%
% Author: Charging Mitigation Team
% Date: 2026-02-09

%% Constants
AU_km = 149597870.7; % 1 AU in km
GM_sun = 1.32712440018e11; % Sun's gravitational parameter [km^3/s^2]
GM_venus = 3.24859e5; % Venus gravitational parameter [km^3/s^2]

% Orbital radii
r_earth = 1.0 * AU_km;
r_venus = 0.72 * AU_km;
r_perihelion = 0.044 * AU_km;

% Time parameters
num_steps = mission_duration_days * 24; % Hourly timesteps
dt_sec = 3600; % 1 hour timestep
time_days = linspace(0, mission_duration_days, num_steps)';
time_jd = 2451545.0 + time_days; % Arbitrary J2000 start

%% Mission Phase Durations (Parker-inspired)
% Phase 1: Earth departure orbit (30 days)
% Phase 2: Transfer to Venus (~146 days Hohmann-like)
% Phase 3: Venus flyby operations (30 days)
% Phase 4: Transfer to perihelion (~121 days)
% Phase 5: Near-Sun operations (remainder)

phase_durations = [30, 146, 30, 121]; % days
phase_end_days = cumsum(phase_durations);

%% Initialize arrays
position = zeros(num_steps, 3);
velocity = zeros(num_steps, 3);
r_sun = zeros(num_steps, 1);
phase = ones(num_steps, 1);
phase_name = cell(num_steps, 1);

%% Phase definitions
phase_names = {
    'Earth Departure'
    'Earth-Venus Transfer'
    'Venus Flyby'
    'Venus-Sun Transfer'
    'Near-Sun Operations'
};

%% Generate trajectory for each phase
for i = 1:num_steps
    t = time_days(i);
    
    % Determine current phase
    if t <= phase_end_days(1)
        current_phase = 1;
        t_phase = t;
    elseif t <= phase_end_days(2)
        current_phase = 2;
        t_phase = t - phase_end_days(1);
    elseif t <= phase_end_days(3)
        current_phase = 3;
        t_phase = t - phase_end_days(2);
    elseif t <= phase_end_days(4)
        current_phase = 4;
        t_phase = t - phase_end_days(3);
    else
        current_phase = 5;
        t_phase = t - phase_end_days(4);
    end
    
    phase(i) = current_phase;
    phase_name{i} = phase_names{current_phase};
    
    % Compute position and velocity based on phase
    switch current_phase
        case 1 % Earth departure - circular orbit at 1 AU
            % Simple circular orbit
            omega = sqrt(GM_sun / r_earth^3); % Angular velocity
            theta = omega * t_phase * 86400; % Angle in radians
            
            position(i, :) = r_earth * [cos(theta), sin(theta), 0];
            velocity(i, :) = r_earth * omega * [-sin(theta), cos(theta), 0];
            r_sun(i) = r_earth;
            
        case 2 % Earth-Venus transfer - elliptical orbit
            % Hohmann transfer orbit from 1.0 AU to 0.72 AU
            a_transfer = (r_earth + r_venus) / 2; % Semi-major axis
            e_transfer = (r_earth - r_venus) / (r_earth + r_venus); % Eccentricity
            
            % Mean motion
            n = sqrt(GM_sun / a_transfer^3);
            M = n * t_phase * 86400; % Mean anomaly
            
            % Solve Kepler's equation (simplified)
            E = M; % Eccentric anomaly (first guess)
            for iter = 1:10
                E = M + e_transfer * sin(E);
            end
            
            % True anomaly
            nu = 2 * atan2(sqrt(1 + e_transfer) * sin(E/2), sqrt(1 - e_transfer) * cos(E/2));
            
            % Distance
            r = a_transfer * (1 - e_transfer * cos(E));
            
            % Position in orbital plane
            position(i, :) = r * [cos(nu), sin(nu), 0];
            
            % Velocity (simplified)
            v = sqrt(GM_sun * (2/r - 1/a_transfer));
            gamma = atan2(e_transfer * sin(nu), 1 + e_transfer * cos(nu)); % Flight path angle
            velocity(i, :) = v * [-sin(nu + gamma), cos(nu + gamma), 0];
            
            r_sun(i) = r;
            
        case 3 % Venus flyby - circular orbit at Venus
            % Circular orbit at Venus distance
            omega = sqrt(GM_sun / r_venus^3);
            theta = omega * t_phase * 86400;
            
            position(i, :) = r_venus * [cos(theta), sin(theta), 0];
            velocity(i, :) = r_venus * omega * [-sin(theta), cos(theta), 0];
            r_sun(i) = r_venus;
            
        case 4 % Venus-perihelion transfer - highly elliptical
            % Transfer orbit from 0.72 AU to 0.044 AU
            a_transfer = (r_venus + r_perihelion) / 2;
            e_transfer = (r_venus - r_perihelion) / (r_venus + r_perihelion);
            
            % Mean motion
            n = sqrt(GM_sun / a_transfer^3);
            M = n * t_phase * 86400;
            
            % Solve Kepler's equation
            E = M;
            for iter = 1:10
                E = M + e_transfer * sin(E);
            end
            
            % True anomaly
            nu = 2 * atan2(sqrt(1 + e_transfer) * sin(E/2), sqrt(1 - e_transfer) * cos(E/2));
            
            % Distance
            r = a_transfer * (1 - e_transfer * cos(E));
            
            % Position
            position(i, :) = r * [cos(nu), sin(nu), 0];
            
            % Velocity
            v = sqrt(GM_sun * (2/r - 1/a_transfer));
            gamma = atan2(e_transfer * sin(nu), 1 + e_transfer * cos(nu));
            velocity(i, :) = v * [-sin(nu + gamma), cos(nu + gamma), 0];
            
            r_sun(i) = r;
            
        case 5 % Near-Sun operations - circular at perihelion
            % Circular orbit at 0.044 AU (like Parker at perihelion)
            omega = sqrt(GM_sun / r_perihelion^3);
            theta = omega * t_phase * 86400;
            
            position(i, :) = r_perihelion * [cos(theta), sin(theta), 0];
            velocity(i, :) = r_perihelion * omega * [-sin(theta), cos(theta), 0];
            r_sun(i) = r_perihelion;
    end
end

% Convert r_sun to AU
r_sun_AU = r_sun / AU_km;

%% Package output
trajectory.time_jd = time_jd;
trajectory.time_days = time_days;
trajectory.position = position; % [km]
trajectory.velocity = velocity; % [km/s]
trajectory.r_sun = r_sun_AU; % [AU]
trajectory.phase = phase;
trajectory.phase_name = phase_name;
trajectory.phase_names = phase_names;
trajectory.phase_durations = phase_durations;
trajectory.phase_end_days = phase_end_days;

% Additional info
trajectory.AU_km = AU_km;
trajectory.mission_duration_days = mission_duration_days;
trajectory.num_steps = num_steps;
trajectory.dt_sec = dt_sec;

fprintf('\n=== Parker-Inspired Trajectory Generated ===\n');
fprintf('Mission Duration: %.0f days (%.1f months)\n', mission_duration_days, mission_duration_days/30);
fprintf('Timesteps: %d (%.1f hour intervals)\n', num_steps, dt_sec/3600);
fprintf('\nPhase Summary:\n');
for p = 1:length(phase_names)
    fprintf('  Phase %d: %s\n', p, phase_names{p});
end
fprintf('\nDistance range: %.3f - %.3f AU\n', min(r_sun_AU), max(r_sun_AU));
fprintf('=============================================\n\n');

end
