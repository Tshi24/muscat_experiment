%% Class: True_Target_Simple
% Simple target body class for stationary targets (e.g., Sun at origin)
% Used when SPICE data is not needed and target has fixed position

classdef True_Target_Simple < handle
    
    %% Properties
    properties
        
        %% [ ] Properties: Basic Variables
        
        name            % [string] Name of Target
        radius          % [km] Radius of Target
        position        % [km] Position of Target (3x1 or 1x3 vector)
        velocity        % [km/sec] Velocity of Target (3x1 or 1x3 vector)
        mass            % [kg] Mass of Target (optional)
        mu              % [km^3/sec^2] Gravitational parameter (optional)
        
        %% [ ] Properties: Storage Variables
        
        store           % Storage structure for telemetry
        
    end
    
    %% Methods
    methods
        
        %% [ ] Methods: Constructor
        % Construct an instance of this class
        
        function obj = True_Target_Simple(init_data)
            % Initialize with default values
            % init_data is optional and can be empty
            
            if nargin > 0 && ~isempty(init_data)
                if isfield(init_data, 'name')
                    obj.name = init_data.name;
                end
                if isfield(init_data, 'radius')
                    obj.radius = init_data.radius;
                end
                if isfield(init_data, 'position')
                    obj.position = init_data.position;
                end
                if isfield(init_data, 'velocity')
                    obj.velocity = init_data.velocity;
                end
                if isfield(init_data, 'mass')
                    obj.mass = init_data.mass;
                end
                if isfield(init_data, 'mu')
                    obj.mu = init_data.mu;
                end
            else
                % Default initialization
                obj.name = 'Simple Target';
                obj.radius = 1;
                obj.position = [0, 0, 0];
                obj.velocity = [0, 0, 0];
            end
            
            % Ensure vectors are row vectors (1x3)
            if size(obj.position, 1) == 3 && size(obj.position, 2) == 1
                obj.position = obj.position';
            end
            if size(obj.velocity, 1) == 3 && size(obj.velocity, 2) == 1
                obj.velocity = obj.velocity';
            end
            
            % Initialize store structure
            obj.store = struct();
        end
        
        %% [ ] Methods: Update (optional, for compatibility)
        % Simple targets don't need updates, but this method exists for compatibility
        
        function update(obj, ~, ~)
            % Do nothing - simple target is stationary
            % This method exists for compatibility with True_Target_SPICE interface
        end
        
    end
    
end
