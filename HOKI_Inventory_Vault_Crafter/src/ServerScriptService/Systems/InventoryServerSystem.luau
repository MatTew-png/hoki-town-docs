--!strict
-- /// <summary>Server inventory composition owned by ServerMain and the application scope.</summary>
local InventoryServerSystem = {}
InventoryServerSystem.__index = InventoryServerSystem

local function start(self)
	local Players = self._context.Players
	local ReplicatedStorage = self._context.ReplicatedStorage
	local HttpService = self._context.HttpService
	local ServerScriptService = self._context.ServerScriptService

	local root = ReplicatedStorage:WaitForChild("InventoryMVC")
	local core = root:WaitForChild("Core")
	local logic = root:WaitForChild("Logic")
	local gateway = root:WaitForChild("Gateway")
	local visualizer = root:WaitForChild("Visualizer")
	local Scope = require(core:WaitForChild("Scope"))
	local UpdateLoop = require(core:WaitForChild("UpdateLoop"))
	local EventBus = require(core:WaitForChild("EventBus"))
	local CommandQueue = require(core:WaitForChild("CommandQueue"))
	local InventoryModel = require(logic:WaitForChild("InventoryModel"))
	local InventoryController = require(logic:WaitForChild("InventoryController"))
	local InventoryPickupController = require(logic:WaitForChild("InventoryPickupController"))
	local names = require(logic:WaitForChild("InventoryMessageEnum"))
	local InventoryDtoMapper = require(gateway:WaitForChild("InventoryDtoMapper"))
	local RobloxInventoryTransport = require(gateway:WaitForChild("RobloxInventoryTransport"))
	local InventoryWeaponView = require(visualizer:WaitForChild("InventoryWeaponView"))
	local InventoryInteractionView = require(visualizer:WaitForChild("InventoryInteractionView"))
	local handIconTemplate = visualizer:WaitForChild("InventoryHandItemBillboard")
	assert(
		handIconTemplate:IsA("BillboardGui")
			and handIconTemplate:FindFirstChild("ItemIcon")
			and handIconTemplate.ItemIcon:IsA("ImageLabel"),
		"Missing authored inventory hand item billboard"
	)
	local InventoryPickupInputAdapter = require(visualizer:WaitForChild("InventoryPickupInputAdapter"))
	local InventoryUseService = require(ServerScriptService:WaitForChild("Systems"):WaitForChild("InventoryUseService"))
	local InventoryUseActionHandlers = require(ServerScriptService.Systems:WaitForChild("InventoryUseActionHandlers"))
	local InventoryUseConfig = require(logic:WaitForChild("InventoryUseConfig"))
	local InventoryInteractionConfig = require(logic:WaitForChild("InventoryInteractionConfig"))
	local catalog = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
	local remote = ReplicatedStorage:WaitForChild("InventoryEvents"):WaitForChild("InventoryChannel", 10)
	assert(
		remote and remote:IsA("RemoteEvent"),
		"Create ReplicatedStorage.InventoryEvents.InventoryChannel before activation"
	)
	local request = ServerScriptService:WaitForChild("InventoryRequest", 10)
	assert(request and request:IsA("BindableEvent"), "Create ServerScriptService.InventoryRequest before activation")
	local wolfLootRequest = ServerScriptService:WaitForChild("WolfLootRequest", 10)
	assert(
		wolfLootRequest and wolfLootRequest:IsA("BindableFunction"),
		"Create ServerScriptService.WolfLootRequest before activation"
	)
	local criticalGrantRequest = ServerScriptService:WaitForChild("InventoryCriticalGrantRequest", 10)
	assert(
		criticalGrantRequest and criticalGrantRequest:IsA("BindableFunction"),
		"Create ServerScriptService.InventoryCriticalGrantRequest before activation"
	)
	local DataManager = require(ServerScriptService:WaitForChild("DataManager"))
	local function safeStat(value, fallback, minimum, maximum)
		if type(value) ~= "number" or value ~= value then
			return fallback
		end
		return math.clamp(value, minimum, maximum)
	end
	DataManager.RegisterSystem("Vitals", {
		Default = { Health = 100, MaxHealth = 100, Armor = 0, MaxArmor = 100 },
		Load = function(_player, saved)
			saved = type(saved) == "table" and saved or {}
			local maxHealth = safeStat(saved.MaxHealth, 100, 1, 1000)
			local health = safeStat(saved.Health, maxHealth, 0, maxHealth)
			local maxArmor = safeStat(saved.MaxArmor, 100, 1, 1000)
			local armor = safeStat(saved.Armor, 0, 0, maxArmor)
			return { Health = health, MaxHealth = maxHealth, Armor = armor, MaxArmor = maxArmor }
		end,
	})
	local function sanitizeSavedInventory(data)
		local items, slots, recovery, ids = {}, {}, {}, {}
		local rawItems = type(data) == "table" and type(data.Items) == "table" and data.Items or {}
		for index, item in pairs(rawItems) do
			local reason
			if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > 2000 then
				reason = "invalid-index"
			elseif type(item) ~= "table" then
				reason = "invalid-stack"
			elseif type(item.ItemID) ~= "string" or not catalog[item.ItemID] then
				reason = "unknown-item"
			elseif
				type(item.Amount) ~= "number"
				or item.Amount % 1 ~= 0
				or item.Amount < 1
				or item.Amount > catalog[item.ItemID].MaxStack
			then
				reason = "invalid-amount"
			elseif type(item.UUID) ~= "string" or #item.UUID == 0 then
				reason = "invalid-uuid"
			end
			if reason then
				table.insert(recovery, { Index = tostring(index), Reason = reason, Item = item })
			else
				local uuid = item.UUID
				if ids[uuid] then
					uuid = HttpService:GenerateGUID(false)
				end
				ids[uuid] = true
				table.insert(items, { UUID = uuid, ItemID = item.ItemID, Amount = item.Amount })
			end
		end
		local rawSlots = type(data) == "table" and type(data.Slots) == "table" and data.Slots or {}
		local assigned = {}
		for index = 1, 6 do
			local slot = "Slot" .. index
			local uuid = rawSlots[slot]
			if ids[uuid] and not assigned[uuid] then
				slots[slot] = uuid
				assigned[uuid] = true
			end
		end
		return { Items = items, Slots = slots, RecoveryItems = recovery }
	end

	DataManager.RegisterSystem("Inventory", {
		Default = { Items = {}, Slots = {} },
		Save = function(_player, data)
			return InventoryDtoMapper.MapToDto(InventoryDtoMapper.MapToSnapshot(data, catalog))
		end,
		Load = function(_player, data)
			local sanitized = sanitizeSavedInventory(data)
			local dto = InventoryDtoMapper.MapToDto(InventoryDtoMapper.MapToSnapshot(sanitized, catalog))
			dto.RecoveryItems = sanitized.RecoveryItems
			return dto
		end,
	})
	DataManager.RegisterSystem("InventoryRecovery", {
		Default = { Items = {} },
		Save = function(_player, data)
			return data
		end,
		Load = function(_player, data)
			return type(data) == "table" and type(data.Items) == "table" and data or { Items = {} }
		end,
	})
	DataManager.RegisterSystem("Vault", {
		Default = { Items = {} },
		Save = function(_player, data)
			if type(data) ~= "table" or type(data.Items) ~= "table" then
				return { Items = {} }
			end
			local saved = {}
			for _, item in ipairs(data.Items) do
				if type(item) == "table" and type(item.ItemID) == "string" and type(item.Amount) == "number" then
					local info = catalog[item.ItemID]
					if info and not info.Permanent and item.Amount >= 1 then
						table.insert(saved, {
							UUID = type(item.UUID) == "string" and item.UUID ~= "" and item.UUID
								or HttpService:GenerateGUID(false),
							ItemID = item.ItemID,
							Amount = math.min(math.floor(item.Amount), info.MaxStack or 99),
						})
					end
				end
			end
			return { Items = saved }
		end,
		Load = function(_player, data)
			if type(data) ~= "table" or type(data.Items) ~= "table" then
				return { Items = {} }
			end
			local loaded = {}
			local ids = {}
			for _, item in ipairs(data.Items) do
				if type(item) == "table" and type(item.ItemID) == "string" and type(item.Amount) == "number" then
					local info = catalog[item.ItemID]
					if info and not info.Permanent and item.Amount >= 1 and #loaded < 60 then
						local uuid = type(item.UUID) == "string" and item.UUID ~= "" and item.UUID
							or HttpService:GenerateGUID(false)
						if ids[uuid] then
							uuid = HttpService:GenerateGUID(false)
						end
						ids[uuid] = true
						table.insert(loaded, {
							UUID = uuid,
							ItemID = item.ItemID,
							Amount = math.min(math.floor(item.Amount), info.MaxStack or 99),
						})
					end
				end
			end
			return { Items = loaded }
		end,
	})
	local templates = {}
	local templateFolder = ReplicatedStorage:WaitForChild("WeaponClone")
	for id, info in pairs(catalog) do
		assert(
			type(info.MaxStack) == "number" and info.MaxStack >= 1 and info.MaxStack % 1 == 0,
			"Invalid MaxStack: " .. id
		)
		if info.Type == "Weapon" then
			local name = info.ToolName or id
			local template = templateFolder
			local path = info.ToolPath or name
			for segment in string.gmatch(path, "[^%.]+") do
				template = template and template:WaitForChild(segment, 10)
			end
			templates[name] = template
			assert(templates[name] and templates[name]:IsA("Tool"), "Missing authored Tool: " .. path)
		end
	end

	local updates = UpdateLoop.new(warn)
	local app = Scope.new({ Kind = 1, Updates = updates, ReportError = warn })
	local sessions = {}
	local sessionsById = {}
	local closing = false
	self._purchaseBundle = function(player, currencyItemId, totalCost, bundle)
		local session = sessions[player]
		if
			closing
			or not session
			or not session.Ready
			or player.Parent ~= Players
			or not DataManager.CanMutate(player)
		then
			return false, "InventoryUnavailable"
		end
		return session.Controller:PurchaseBundle(currencyItemId, totalCost, bundle)
	end
	self._exchangeItems = function(player, removeList, addList)
		local session = sessions[player]
		if
			closing
			or not session
			or not session.Ready
			or player.Parent ~= Players
			or not DataManager.CanMutate(player)
		then
			return false, "InventoryUnavailable"
		end
		return session.Controller:ExchangeItems(removeList, addList)
	end
	self._getSnapshot = function(player)
		local session = sessions[player]
		if closing or not session or not session.Ready or player.Parent ~= Players then
			return nil
		end
		return session.Controller:GetSnapshot()
	end
	local pickupAssets, pickupRules = {}, {}
	for _, object in ipairs(self._context.Workspace:GetDescendants()) do
		local id = object:GetAttribute("InventoryPickupId")
		if object:IsA("BasePart") and type(id) == "string" then
			assert(not pickupAssets[id], "Duplicate InventoryPickupId: " .. id)
			local prompt = object:WaitForChild("ProximityPrompt", 10)
			assert(prompt and prompt:IsA("ProximityPrompt"), "Missing pickup prompt: " .. id)
			local action = object:GetAttribute("InventoryAction")
			assert(action == names.Add or action == names.Remove, "Invalid InventoryAction: " .. id)
			pickupAssets[id] = { Part = object, Prompt = prompt }
			pickupRules[id] = table.freeze({
				Action = action,
				MaximumDistance = prompt.MaxActivationDistance,
				Items = table.freeze({ "apple", "Pool", "armor", "wire" }),
			})
		end
	end
	app:Register("Commands", 2, function()
		return CommandQueue.new(warn)
	end)
	app:Register("PickupCommands", 1, function()
		return CommandQueue.new(warn)
	end)
	app:Register("PickupEvents", 1, function()
		return EventBus.new(warn)
	end)
	app:Register("InventoryPickupController", 1, function(scope)
		return InventoryPickupController.new({
			Commands = scope:Get("PickupCommands"),
			Events = scope:Get("PickupEvents"),
			Pickups = pickupRules,
		})
	end)
	app:Register("InventoryPickupInputAdapter", 1, function(scope)
		return InventoryPickupInputAdapter.new({
			Commands = scope:Get("PickupCommands"),
			Events = scope:Get("PickupEvents"),
			Pickups = pickupAssets,
		})
	end)
	app:Register("Events", 2, function()
		return EventBus.new(warn)
	end)
	app:Register("InventoryModel", 2, function()
		return InventoryModel.new()
	end)
	app:Register("InventoryController", 2, function(scope)
		return InventoryController.new({
			Model = scope:Get("InventoryModel"),
			Commands = scope:Get("Commands"),
			Events = scope:Get("Events"),
			Catalog = catalog,
			Names = names,
			CanMutate = function()
				return DataManager.CanMutate(scope.Context)
			end,
			CreateId = function()
				return HttpService:GenerateGUID(false)
			end,
		})
	end)
	app:Register("InventoryUseService", 2, function(scope)
		return InventoryUseService.new({
			Player = scope.Context,
			Controller = scope:Get("InventoryController"),
			Events = scope:Get("Events"),
			Names = names,
			Config = InventoryUseConfig,
			Handlers = InventoryUseActionHandlers,
			ReplicatedStorage = ReplicatedStorage,
			Catalog = catalog,
			InteractionConfig = InventoryInteractionConfig,
			TransferItem = function(sourcePlayer, itemUUID, targetUserId, amount, commit)
				local sourceSession = sessions[sourcePlayer]
				local targetSession = sessionsById[targetUserId]
				if
					not sourceSession
					or not sourceSession.Ready
					or not targetSession
					or not targetSession.Ready
					or not targetSession.Player
					or targetSession.Player.Parent ~= Players
					or not DataManager.CanMutate(sourcePlayer)
					or not DataManager.CanMutate(targetSession.Player)
				then
					return false
				end
				local sourceItem = sourceSession.Controller:findItem(itemUUID)
				local info = sourceItem and catalog[sourceItem.ItemID]
				if
					not sourceItem
					or not info
					or info.Type == "Weapon"
					or info.CanGive ~= true
					or sourceItem.Amount < amount
				then
					return false
				end
				local sourceCharacter, targetCharacter = sourcePlayer.Character, targetSession.Player.Character
				local sourceHumanoid = sourceCharacter and sourceCharacter:FindFirstChildOfClass("Humanoid")
				local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
				local sourceRoot = sourceCharacter and sourceCharacter:FindFirstChild("HumanoidRootPart")
				local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
				if
					not sourceHumanoid
					or sourceHumanoid.Health <= 0
					or not targetHumanoid
					or targetHumanoid.Health <= 0
					or not sourceRoot
					or not targetRoot
					or (sourceRoot.Position - targetRoot.Position).Magnitude > InventoryInteractionConfig.TargetRangeStuds
					or not targetSession.Controller:CanReceiveTransferred(sourceItem.ItemID, amount)
				then
					return false
				end
				if not commit then
					return true
				end
				if not sourceSession.Controller:RemoveForGive(itemUUID, amount) then
					return false
				end
				if not targetSession.Controller:AddTransferred(sourceItem.ItemID, amount) then
					sourceSession.Controller:AddTransferred(sourceItem.ItemID, amount)
					return false
				end
				return true
			end,
			NotifyTarget = function(targetUserId, eventName, payload)
				local targetSession = sessionsById[targetUserId]
				if targetSession and targetSession.Ready then
					targetSession.Events:Publish(eventName, payload)
				end
			end,
		})
	end)
	app:Register("InventoryWeaponView", 2, function(scope)
		return InventoryWeaponView.new({
			Player = scope.Context,
			Events = scope:Get("Events"),
			Names = names,
			Catalog = catalog,
			Templates = templates,
		})
	end)
	app:Register("InventoryInteractionView", 2, function(scope)
		return InventoryInteractionView.new({
			Player = scope.Context,
			Players = Players,
			Events = scope:Get("Events"),
			Names = names,
			Catalog = catalog,
			Config = InventoryInteractionConfig,
			Template = handIconTemplate,
		})
	end)
	app:Register("RobloxInventoryTransport", 1, function()
		return RobloxInventoryTransport.new({ Remote = remote, Names = names })
	end)
	-- Inventory is an explicitly prewarmed feature because input and login depend on it.
	local transport = app:Get("RobloxInventoryTransport")
	local pickupCommands = app:Get("PickupCommands")
	local pickupEvents = app:Get("PickupEvents")
	app:Get("InventoryPickupController")
	app:Get("InventoryPickupInputAdapter")
	local unsubscribePickup = pickupEvents:Subscribe("InventoryPickupTriggered", function(event)
		local session = sessionsById[event.UserId]
		if session then
			for _, itemId in ipairs(event.Items) do
				session.Commands:Enqueue(table.freeze({ Name = event.Action, ItemId = itemId, Amount = 1 }))
			end
		end
	end)

	local function onPlayerAdded(player)
		if closing or sessions[player] then
			return
		end
		local scope = app:CreateChild(2, player)
		local commands = scope:Get("Commands")
		local events = scope:Get("Events")
		local controller = scope:Get("InventoryController")
		scope:Get("InventoryUseService")
		scope:Get("InventoryWeaponView")
		scope:Get("InventoryInteractionView")
		local session = {
			Scope = scope,
			Commands = commands,
			Events = events,
			Controller = controller,
			Player = player,
			Ready = false,
			PendingCommands = {},
		}
		sessions[player] = session
		sessionsById[player.UserId] = session
		session.Unsubscribe = events:Subscribe(names.Changed, function(snapshot)
			DataManager.SetSystemData(player, "Inventory", InventoryDtoMapper.MapToDto(snapshot))
		end)
		session.CharacterConnection = player.CharacterAdded:Connect(function()
			if session.Ready then
				commands:Enqueue(table.freeze({ Name = names.Character }))
			end
		end)
		local loaded, loadError = pcall(DataManager.LoadPlayerData, player)
		if not loaded then
			warn("Inventory data load failed: " .. tostring(loadError))
			player:Kick("Inventory could not be loaded safely. Please reconnect.")
			return
		end
		if not player.Parent or sessions[player] ~= session then
			DataManager.ClosePlayerSession(player)
			return
		end
		local valid, snapshot =
			pcall(InventoryDtoMapper.MapToSnapshot, DataManager.GetSystemData(player, "Inventory"), catalog)
		if not valid then
			warn("Inventory data validation failed: " .. tostring(snapshot))
			local repaired = sanitizeSavedInventory(DataManager.GetSystemData(player, "Inventory"))
			snapshot = InventoryDtoMapper.MapToSnapshot(repaired, catalog)
			DataManager.SetSystemData(player, "Inventory", InventoryDtoMapper.MapToDto(snapshot))
			DataManager.SetSystemData(player, "InventoryRecovery", { Items = repaired.RecoveryItems })
		end
		local inventoryData = DataManager.GetSystemData(player, "Inventory")
		if type(inventoryData.RecoveryItems) == "table" and #inventoryData.RecoveryItems > 0 then
			local previous = DataManager.GetSystemData(player, "InventoryRecovery")
			local combined = table.clone(previous.Items)
			for _, item in ipairs(inventoryData.RecoveryItems) do
				table.insert(combined, item)
			end
			DataManager.SetSystemData(player, "InventoryRecovery", { Items = combined })
			DataManager.SetSystemData(player, "Inventory", InventoryDtoMapper.MapToDto(snapshot))
			warn(
				"Inventory migration preserved "
					.. tostring(#inventoryData.RecoveryItems)
					.. " legacy item record(s) for user "
					.. tostring(player.UserId)
			)
		end
		transport:AttachSession(player, commands, events)
		commands:Enqueue(table.freeze({ Name = names.Load, Snapshot = snapshot }))
		session.Ready = true
		for _, pendingCommand in ipairs(session.PendingCommands) do
			commands:Enqueue(pendingCommand)
		end
		table.clear(session.PendingCommands)
		task.defer(function()
			if not player.Parent or not sessions[player] then
				return
			end
			for id, info in pairs(catalog) do
				if info.Permanent then
					commands:Enqueue(table.freeze({ Name = names.Add, ItemId = id, Amount = 1 }))
				end
			end
		end)
	end

	local function onPlayerRemoving(player)
		local session = sessions[player]
		if not session then
			return
		end
		transport:DetachSession(player.UserId)
		session.CharacterConnection:Disconnect()
		session.Unsubscribe()
		session.Scope:Dispose()
		sessions[player] = nil
		sessionsById[player.UserId] = nil
	end

	local connections = {}
	table.insert(connections, Players.PlayerAdded:Connect(onPlayerAdded))
	table.insert(connections, Players.PlayerRemoving:Connect(onPlayerRemoving))
	table.insert(
		connections,
		request.Event:Connect(function(player, action, itemId, amount)
			local session = sessions[player]
			if session and (action == names.Add or action == names.Remove) then
				local command = table.freeze({ Name = action, ItemId = itemId, Amount = amount })
				if session.Ready then
					session.Commands:Enqueue(command)
				elseif #session.PendingCommands < 50 then
					table.insert(session.PendingCommands, command)
				end
			end
		end)
	)
	wolfLootRequest.OnInvoke = function(player, loot)
		local session = sessions[player]
		if closing or not session or not session.Ready then
			return false
		end
		return session.Controller:AddBundle(loot)
	end
	criticalGrantRequest.OnInvoke = function(player, itemId, amount, dailyData)
		local session = sessions[player]
		local info = type(itemId) == "string" and catalog[itemId]
		if
			closing
			or not session
			or not session.Ready
			or player.Parent ~= Players
			or not DataManager.CanMutate(player)
			or not info
			or info.Type == "Weapon"
			or info.Permanent
			or type(dailyData) ~= "table"
			or not DataManager.GetSystemData(player, "Inventory")
			or not DataManager.GetSystemData(player, "DailyLogin")
		then
			return false
		end
		if not session.Controller:AddTransferred(itemId, amount) then
			return false
		end
		return DataManager.SetSystemData(player, "DailyLogin", dailyData)
	end
	self._step = function(deltaTime)
		pickupCommands:Pump()
		for _, session in pairs(sessions) do
			session.Commands:Pump()
		end
		updates:Run(deltaTime)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	local function dispose()
		if closing then
			return
		end
		closing = true
		wolfLootRequest.OnInvoke = nil
		criticalGrantRequest.OnInvoke = nil
		unsubscribePickup()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		for player in pairs(sessions) do
			onPlayerRemoving(player)
		end
		app:Dispose()
	end
	self._dispose = dispose
end

function InventoryServerSystem.new(context)
	return setmetatable({
		_context = context,
		_started = false,
		_disposed = false,
		_step = nil,
		_dispose = nil,
		_purchaseBundle = nil,
		_exchangeItems = nil,
		_getSnapshot = nil,
	}, InventoryServerSystem)
end

function InventoryServerSystem:Init()
	if self._started or self._disposed then
		return
	end
	self._started = true
	local ok, message = pcall(start, self)
	if not ok then
		self:Dispose()
		error("InventoryServerSystem initialization failed: " .. tostring(message))
	end
end

function InventoryServerSystem:UpdateLogic(deltaTime)
	if not self._disposed and self._step then
		self._step(deltaTime)
	end
end

function InventoryServerSystem:PurchaseBundle(player, currencyItemId, totalCost, bundle)
	if self._disposed or not self._purchaseBundle then
		return false, "InventoryUnavailable"
	end
	return self._purchaseBundle(player, currencyItemId, totalCost, bundle)
end

function InventoryServerSystem:ExchangeItems(player, removeList, addList)
	if self._disposed or not self._exchangeItems then
		return false, "InventoryUnavailable"
	end
	return self._exchangeItems(player, removeList, addList)
end

function InventoryServerSystem:GetSnapshot(player)
	if self._disposed or not self._getSnapshot then
		return nil
	end
	return self._getSnapshot(player)
end

function InventoryServerSystem:Dispose()
	if self._disposed then
		return
	end
	self._disposed = true
	local cleanup = self._dispose
	self._dispose = nil
	self._step = nil
	self._purchaseBundle = nil
	self._exchangeItems = nil
	self._getSnapshot = nil
	if cleanup then
		local ok, message = pcall(cleanup)
		if not ok then
			warn("[InventoryServerSystem] Cleanup failed: " .. tostring(message))
		end
	end
end

return InventoryServerSystem
