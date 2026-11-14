--[[ <summary>Owns atomic per-player DataStore sessions, ordered saves, autosave, and safe cleanup.</summary> ]]
local DataManager = {}

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Existing store names and top-level system keys remain unchanged.
local suffix = RunService:IsStudio() and "_Studio" or ""
local playerDataStore = DataStoreService:GetDataStore("PlayerData_v1" .. suffix)
local registeredSystems = {}
local sessions = {}
local loading = {}
local pendingClose = {}
local closeWorkers = {}
local shutdownDeadline = nil

local AUTO_SAVE_INTERVAL = 60
local MAX_RETRY = 3
local LOCK_TTL_SECONDS = 300
local CLOSE_RETRY_SECONDS = 3
local SHUTDOWN_WAIT_SECONDS = 25

local function playerKey(player)
	return "player_" .. player.UserId
end

local function retryDelay(attempt)
	return math.min(4, 2 ^ (attempt - 1)) + math.random() * 0.5
end

local function snapshotValue(value, visiting)
	if type(value) ~= "table" then
		return value
	end
	assert(not visiting[value], "Cyclic player data cannot be saved")
	visiting[value] = true
	local copy = {}
	for key, child in pairs(value) do
		copy[key] = snapshotValue(child, visiting)
	end
	visiting[value] = nil
	return copy
end

local function isStudioApiDisabled(message)
	if not RunService:IsStudio() then
		return false
	end
	local value = tostring(message)
	return string.find(value, "StudioAccessToApisNotAllowed", 1, true) ~= nil
		or string.find(value, "Cannot write to DataStore from studio if API access is not enabled", 1, true) ~= nil
end

function DataManager.RegisterSystem(systemName, config)
	assert(type(systemName) == "string" and type(config) == "table", "Invalid DataManager system")
	registeredSystems[systemName] = {
		Default = config.Default or {},
		Save = config.Save or function(_player, data)
			return data
		end,
		Load = config.Load or function(_player, savedData)
			return savedData
		end,
	}
end

function DataManager.GetSystemData(player, systemName)
	local session = sessions[player]
	return session and session.Data[systemName] or nil
end

function DataManager.CanMutate(player)
	local session = sessions[player]
	return session ~= nil and not session.Closing and not session.Closed and not session.PersistenceDegraded
end

function DataManager.SetSystemData(player, systemName, data)
	local session = sessions[player]
	if not session or session.Closing or not registeredSystems[systemName] then
		return false
	end
	session.Data[systemName] = data
	session.Revision += 1
	return true
end

local function loadMemoryDefaults(player, reason)
	local data = {}
	for systemName, systemConfig in pairs(registeredSystems) do
		data[systemName] = systemConfig.Load(player, systemConfig.Default)
	end
	sessions[player] = { Data = data, Revision = 0, MemoryOnly = true, Saving = false, Closing = false }
	warn(
		"[DataManager] Studio temporary data for user "
			.. player.UserId
			.. "; nothing will be saved: "
			.. tostring(reason)
	)
	return data
end

local function releaseSessionLock(player, token)
	local result = playerDataStore:UpdateAsync(playerKey(player), function(current)
		if type(current) ~= "table" then
			return nil
		end
		local lock = current._DataSession
		if type(lock) == "table" and lock.Token == token then
			local updated = table.clone(current)
			updated._DataSession = nil
			return updated
		end
		-- A retry after an uncertain response is safe if the prior release committed.
		if lock == nil and type(current._LastSave) == "table" and current._LastSave.Token == token then
			return current
		end
		return nil
	end)
	return type(result) == "table"
		and result._DataSession == nil
		and type(result._LastSave) == "table"
		and result._LastSave.Token == token
end

function DataManager.LoadPlayerData(player)
	local existing = sessions[player]
	if existing then
		return existing.Data
	end
	if loading[player] then
		repeat
			task.wait(0.1)
		until not loading[player]
		existing = sessions[player]
		if existing then
			return existing.Data
		end
		error("[DataManager] Concurrent load failed for user " .. player.UserId, 0)
	end
	loading[player] = true

	-- Temporary Studio data must be an explicit choice. Live servers always fail closed.
	if RunService:IsStudio() and game:GetAttribute("EnableStudioDataStores") == false then
		loading[player] = nil
		return loadMemoryDefaults(player, "EnableStudioDataStores is false")
	end

	local token = HttpService:GenerateGUID(false)
	local record
	local lastError
	for attempt = 1, MAX_RETRY do
		local now = os.time()
		local ok, result = pcall(function()
			return playerDataStore:UpdateAsync(playerKey(player), function(current)
				assert(current == nil or type(current) == "table", "Saved player record is not a table")
				local updated = type(current) == "table" and table.clone(current) or {}
				local lock = updated._DataSession
				if
					type(lock) == "table"
					and type(lock.ExpiresAt) == "number"
					and lock.ExpiresAt > now
					and lock.Token ~= token
				then
					return nil
				end
				updated._DataSession = { Token = token, JobId = game.JobId, ExpiresAt = now + LOCK_TTL_SECONDS }
				return updated
			end)
		end)
		if ok then
			if
				type(result) == "table"
				and type(result._DataSession) == "table"
				and result._DataSession.Token == token
			then
				record = result
				break
			end
			lastError = "Player data is locked by another server"
			break
		end
		lastError = result
		if attempt < MAX_RETRY then
			task.wait(retryDelay(attempt))
		end
	end

	if not record then
		loading[player] = nil
		if isStudioApiDisabled(lastError) then
			error(
				"[DataManager] Enable Studio API Services or set EnableStudioDataStores=false for an explicit temporary session: "
					.. tostring(lastError),
				0
			)
		end
		error("[DataManager] Cannot load user " .. player.UserId .. ": " .. tostring(lastError), 0)
	end

	local transformed, data = pcall(function()
		local loaded = {}
		for systemName, systemConfig in pairs(registeredSystems) do
			local saved = record[systemName]
			if saved == nil then
				saved = systemConfig.Default
			end
			loaded[systemName] = systemConfig.Load(player, saved)
		end
		return loaded
	end)
	if not transformed then
		-- Do not overwrite or default a corrupt record. Release only our own lock.
		pcall(function()
			playerDataStore:UpdateAsync(playerKey(player), function(current)
				if
					type(current) ~= "table"
					or type(current._DataSession) ~= "table"
					or current._DataSession.Token ~= token
				then
					return nil
				end
				local updated = table.clone(current)
				updated._DataSession = nil
				return updated
			end)
		end)
		loading[player] = nil
		error("[DataManager] Invalid saved data for user " .. player.UserId .. ": " .. tostring(data), 0)
	end

	sessions[player] = {
		Token = token,
		Data = data,
		Revision = 0,
		Saving = false,
		Closing = false,
		MemoryOnly = false,
		Closed = false,
	}
	loading[player] = nil
	if pendingClose[player] then
		task.defer(DataManager.ClosePlayerSession, player)
	end
	return data
end

function DataManager.SavePlayerData(player)
	local session = sessions[player]
	if not session or session.MemoryOnly or session.Closed then
		return false
	end
	while session.Saving do
		task.wait(0.05)
		if sessions[player] ~= session or session.Closed then
			return false
		end
	end
	session.Saving = true

	local serialized, payload = pcall(function()
		local data = {}
		for systemName, systemConfig in pairs(registeredSystems) do
			local value = session.Data[systemName]
			if value ~= nil then
				data[systemName] = snapshotValue(systemConfig.Save(player, value), {})
			end
		end
		return data
	end)
	if not serialized then
		session.Saving = false
		session.PersistenceDegraded = true
		if player.Parent then
			player:SetAttribute("DataSaveDegraded", true)
		end
		warn("[DataManager] Serialization failed for user " .. player.UserId .. ": " .. tostring(payload))
		return false
	end

	local revision = session.Revision
	local token = session.Token
	local lastError
	local saved = false
	for attempt = 1, MAX_RETRY do
		local now = os.time()
		local ok, result = pcall(function()
			return playerDataStore:UpdateAsync(playerKey(player), function(current)
				if
					type(current) ~= "table"
					or type(current._DataSession) ~= "table"
					or current._DataSession.Token ~= token
				then
					return nil
				end
				local updated = table.clone(current)
				for systemName, systemData in pairs(payload) do
					updated[systemName] = systemData
				end
				updated._DataSession = { Token = token, JobId = game.JobId, ExpiresAt = now + LOCK_TTL_SECONDS }
				updated._LastSave = { Token = token, Revision = revision, At = now }
				return updated
			end)
		end)
		if
			ok
			and type(result) == "table"
			and type(result._LastSave) == "table"
			and result._LastSave.Token == token
			and result._LastSave.Revision == revision
		then
			saved = true
			break
		end
		lastError = ok and "Session lock was lost" or result
		if attempt < MAX_RETRY then
			task.wait(retryDelay(attempt))
		end
	end
	session.Saving = false
	if saved then
		session.LastSavedRevision = revision
		session.LastSavedAt = os.time()
		session.PersistenceDegraded = false
		if player.Parent then
			player:SetAttribute("DataSaveDegraded", false)
		end
	else
		session.PersistenceDegraded = true
		if player.Parent then
			player:SetAttribute("DataSaveDegraded", true)
		end
		warn(
			"[DataManager] SAVE FAILED user "
				.. player.UserId
				.. " revision "
				.. revision
				.. ": "
				.. tostring(lastError)
		)
	end
	return saved
end

-- Public cleanup refuses to discard an unsaved persistent session.
function DataManager.ClearPlayerData(player)
	local session = sessions[player]
	if session and not session.MemoryOnly and not session.Closed then
		warn("[DataManager] Refused unsafe ClearPlayerData for user " .. player.UserId)
		return false
	end
	sessions[player] = nil
	return true
end

local function closeAttempt(player)
	local session = sessions[player]
	if not session then
		return not loading[player]
	end
	if session.MemoryOnly then
		sessions[player] = nil
		return true
	end
	if session.Closed then
		return true
	end
	session.Closing = true
	if not DataManager.SavePlayerData(player) then
		return false
	end
	local ok, released = pcall(releaseSessionLock, player, session.Token)
	if not ok or not released then
		warn("[DataManager] Lock release failed for user " .. player.UserId .. ": " .. tostring(released))
		return false
	end
	session.Closed = true
	sessions[player] = nil
	return true
end

function DataManager.ClosePlayerSession(player)
	pendingClose[player] = true
	if closeWorkers[player] then
		return
	end
	closeWorkers[player] = true
	task.spawn(function()
		while pendingClose[player] do
			if closeAttempt(player) then
				pendingClose[player] = nil
				break
			end
			if shutdownDeadline and os.clock() >= shutdownDeadline then
				break
			end
			task.wait(CLOSE_RETRY_SECONDS)
		end
		closeWorkers[player] = nil
	end)
end

-- Defer until other PlayerRemoving handlers have detached gameplay sessions.
Players.PlayerRemoving:Connect(function(player)
	task.defer(DataManager.ClosePlayerSession, player)
end)

game:BindToClose(function()
	shutdownDeadline = os.clock() + SHUTDOWN_WAIT_SECONDS
	for player in pairs(sessions) do
		DataManager.ClosePlayerSession(player)
	end
	for player in pairs(loading) do
		DataManager.ClosePlayerSession(player)
	end
	while os.clock() < shutdownDeadline do
		if next(pendingClose) == nil then
			return
		end
		task.wait(0.1)
	end
	local count = 0
	for _ in pairs(pendingClose) do
		count += 1
	end
	warn("[DataManager] Shutdown deadline reached with " .. count .. " unsaved player session(s)")
end)

task.spawn(function()
	-- Give servers different autosave phases to spread DataStore traffic.
	task.wait(math.random() * AUTO_SAVE_INTERVAL)
	while not shutdownDeadline do
		local players = Players:GetPlayers()
		if #players == 0 then
			task.wait(AUTO_SAVE_INTERVAL)
		else
			local spacing = math.max(0.5, AUTO_SAVE_INTERVAL / #players)
			for _, player in ipairs(players) do
				if shutdownDeadline then
					break
				end
				local session = sessions[player]
				if session and not session.MemoryOnly and not session.Closing then
					task.spawn(DataManager.SavePlayerData, player)
				end
				task.wait(spacing)
			end
		end
	end
end)

return DataManager
