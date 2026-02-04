%% [ ] Methods: Constructor for DART Executive

function obj = func_software_SC_executive_Dart_constructor(obj, mission,i_SC)
% Add mode transition management
if ~isfield(obj.data, 'last_mode_change_time')
    obj.data.last_mode_change_time = 0;
    obj.data.previous_mode = obj.this_sc_mode;
end

% Initialize charging mitigation storage
if ~isfield(obj.store, 'charging')
    obj.store.charging = [];
    obj.store.charging.time_sec = zeros(mission.storage.num_storage_steps, 1);
    obj.store.charging.x_AU = zeros(mission.storage.num_storage_steps, 1);
    obj.store.charging.isSunlit = zeros(mission.storage.num_storage_steps, 1);
    obj.store.charging.phiOff_pred = zeros(mission.storage.num_storage_steps, 1);
    obj.store.charging.phiOn_pred = zeros(mission.storage.num_storage_steps, 1);
    obj.store.charging.phi_pred = zeros(mission.storage.num_storage_steps, 1);
    obj.store.charging.thruster_is_on = zeros(mission.storage.num_storage_steps, 1);
    obj.store.charging.thruster_cmd = zeros(mission.storage.num_storage_steps, 1);
    obj.store.charging.reason_code = cell(mission.storage.num_storage_steps, 1);
    obj.store.charging.power_consumption = zeros(mission.storage.num_storage_steps, 1);  % [W] Power used for mitigation
    obj.store.charging.cumulative_energy = zeros(mission.storage.num_storage_steps, 1);  % [W-hr] Cumulative energy used
    obj.store.charging.V_ON = zeros(mission.storage.num_storage_steps, 1);   % [V] Threshold values
    obj.store.charging.V_OFF = zeros(mission.storage.num_storage_steps, 1);  % [V] Threshold values
end

% Initialize cumulative energy tracker
if ~isfield(obj.data, 'cumulative_mitigation_energy')
    obj.data.cumulative_mitigation_energy = 0;  % [W-hr]
    obj.data.last_energy_update_time = 0;  % [sec]
end

end
