--!strict
-- /// <summary>Composition root owning server feature recipes and application lifetime.</summary>
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ReplicatedStorage:WaitForChild("InventoryMVC"):WaitForChild("Core")
local Scope = require(Core:WaitForChild("Scope"))
local CommandQueue = require(Core:WaitForChild("CommandQueue"))
local UpdateLoop = require(Core:WaitForChild("UpdateLoop"))
local EventBus = require(Core:WaitForChild("EventBus"))

local function reportError(message)
	warn("[ServerMain] " .. tostring(message))
end

local commands = CommandQueue.new(reportError)
local updates = UpdateLoop.new(reportError)
local eventBus = EventBus.new(reportError)
local application = Scope.new({
	Kind = 0,
	Context = { Players = Players, ReplicatedStorage = ReplicatedStorage, ServerScriptService = ServerScriptService },
	ReportError = reportError,
	Updates = updates,
})
local disposed = false
local frameConnection

local function registerFeatureRecipes()
	local systems = ServerScriptService:WaitForChild("Systems")

	application:Register("DeathSystemServerSystem", 0, function()
		local System = require(systems:WaitForChild("DeathSystemServerSystem"))
		return System.new({
			Players = Players,
			DataStoreService = game:GetService("DataStoreService"),
			ReplicatedStorage = ReplicatedStorage,
			RunService = RunService,
			Workspace = workspace,
			TextChatService = game:GetService("TextChatService"),
			JobId = game.JobId,
		})
	end)

	application:Register("MainMenuServerSystem", 0, function()
		local System = require(systems:WaitForChild("MainMenuServerSystem"))
		return System.new({
			Players = Players,
			ReplicatedStorage = ReplicatedStorage,
			ServerScriptService = ServerScriptService,
		})
	end)

	application:Register("InventoryServerSystem", 0, function()
		local HttpService = game:GetService("HttpService")
		local System = require(systems:WaitForChild("InventoryServerSystem"))
		return System.new({
			Players = Players,
			ReplicatedStorage = ReplicatedStorage,
			RunService = RunService,
			HttpService = HttpService,
			ServerScriptService = ServerScriptService,
			Workspace = workspace,
		})
	end)

	application:Register("PlayerVitalsServerSystem", 0, function()
		local System = require(systems:WaitForChild("PlayerVitalsServerSystem"))
		return System.new({ Players = Players, ReplicatedStorage = ReplicatedStorage })
	end)

	application:Register("FallImpactServerSystem", 0, function()
		local logic = ReplicatedStorage:WaitForChild("CharacterMovementMVC"):WaitForChild("Logic")
		local System = require(systems:WaitForChild("FallImpactServerSystem"))
		return System.new({
			Players = Players,
			RunService = RunService,
			Config = require(logic:WaitForChild("MovementConfig")),
			Rules = require(logic:WaitForChild("MovementRules")),
		})
	end)

	application:Register("PlayerCollisionServerSystem", 0, function()
		local System = require(systems:WaitForChild("PlayerCollisionServerSystem"))
		local config =
			require(ReplicatedStorage:WaitForChild("CharacterMovementMVC").Logic:WaitForChild("PlayerCollisionConfig"))
		return System.new({ Players = Players, PhysicsService = game:GetService("PhysicsService"), Config = config })
	end)

	application:Register("StreakKillSystem", 0, function()
		local root = ReplicatedStorage:WaitForChild("StreakKillMVC")
		local Model = require(root.Logic:WaitForChild("StreakKillModel"))
		local Controller = require(root.Logic:WaitForChild("StreakKillController"))
		local event = root.Gateway:WaitForChild("StreakKillUpdated")
		local model = Model.new()
		local controller = Controller.new(model, function(player, count)
			if player and player.Parent == Players then
				event:FireClient(player, count)
			end
		end)
		local System = require(systems:WaitForChild("StreakKillSystem"))
		return System.new({
			Players = Players,
			Workspace = workspace,
			Event = event,
			Model = model,
			Controller = controller,
		})
	end)

	application:Register("MeleeWeaponSystem", 0, function()
		local root = ReplicatedStorage:WaitForChild("MeleeWeaponMVC")
		local logic = root:WaitForChild("Logic")
		local gatewayFolder = root:WaitForChild("Gateway")
		local config = require(logic:WaitForChild("MeleeWeaponConfig"))
		local Model = require(logic:WaitForChild("MeleeWeaponModel"))
		local Controller = require(logic:WaitForChild("MeleeWeaponController"))
		local Gateway = require(gatewayFolder:WaitForChild("MeleeWeaponCombatGateway"))
		local attribution =
			require(ReplicatedStorage:WaitForChild("StreakKillMVC").Gateway:WaitForChild("DamageAttributionGateway"))
		local model = Model.new()
		local controller = Controller.new(config)
		local gateway = Gateway.new({
			Remote = gatewayFolder:WaitForChild("MeleeWeaponCommand"),
			Config = config,
			Model = model,
			Controller = controller,
			Attribution = attribution,
		})
		local System = require(systems:WaitForChild("MeleeWeaponSystem"))
		return System.new({ Gateway = gateway, Controller = controller, Model = model })
	end)

	application:Register("TrainningDummySystem", 0, function()
		local root = ReplicatedStorage:WaitForChild("TrainningDummyMVC")
		local config = require(root.Logic:WaitForChild("TrainningDummyConfig"))
		local Gateway = require(root.Gateway:WaitForChild("TrainningDummyRespawnGateway"))
		local System = require(systems:WaitForChild("TrainningDummySystem"))
		return System.new(Gateway.new(config))
	end)

	application:Register("CarStatusServerSystem", 0, function()
		local root = ReplicatedStorage:WaitForChild("CarStatusMVC")
		local logic = root:WaitForChild("Logic")
		local config = require(logic:WaitForChild("CarStatusConfig"))
		local Model = require(logic:WaitForChild("CarStatusModel"))
		local Controller = require(logic:WaitForChild("CarStatusController"))
		local Gateway = require(root:WaitForChild("Gateway"):WaitForChild("CarStatusServerGateway"))
		local System = require(systems:WaitForChild("CarStatusServerSystem"))
		local controller = Controller.new(config, Model)
		local gateway = Gateway.new({
			Workspace = workspace,
			RunService = RunService,
			HttpService = game:GetService("HttpService"),
			Controller = controller,
			Config = config,
			CollisionSoundTemplate = root:WaitForChild("Gateway"):WaitForChild("CollisionSoundTemplate"),
		})
		return System.new(gateway)
	end)

	application:Register("AnnouncementServerSystem", 0, function()
		local root = ReplicatedStorage:WaitForChild("AnnouncementMVC")
		local logic = root:WaitForChild("Logic")
		local gatewayFolder = root:WaitForChild("Gateway")
		local config = require(logic:WaitForChild("AnnouncementConfig"))
		local Model = require(logic:WaitForChild("AnnouncementModel"))
		local Controller = require(logic:WaitForChild("AnnouncementController"))
		local CommandGateway = require(gatewayFolder:WaitForChild("AnnouncementCommandGateway"))
		local remote = gatewayFolder:WaitForChild("AnnouncementBroadcast")
		local controller = Controller.new(config, Model.new(config, os.time()), function(payload)
			remote:FireAllClients(payload)
		end)
		local commandGateway = CommandGateway.new({
			Command = game:GetService("TextChatService"):WaitForChild("AnnouncementCommand"),
			Players = Players,
			TextService = game:GetService("TextService"),
			Config = config.TestCommand,
			CreatorType = game.CreatorType,
			CreatorId = game.CreatorId,
			Publish = function(text)
				controller:PublishManual(text)
			end,
		})
		local System = require(systems:WaitForChild("AnnouncementServerSystem"))
		return System.new({ Controller = controller, CommandGateway = commandGateway })
	end)

	application:Register("FarmServerSystem", 0, function()
		local root = ReplicatedStorage:WaitForChild("FarmMVC")
		local config = require(root.Logic:WaitForChild("FarmConfig"))
		local System = require(systems:WaitForChild("FarmServerSystem"))
		return System.new({
			Players = Players,
			ReplicatedStorage = ReplicatedStorage,
			ServerScriptService = ServerScriptService,
			Workspace = workspace,
			Config = config,
			Channel = root.Gateway:WaitForChild("FarmChannel"),
		})
	end)

	application:Register("AirdropServerSystem", 0, function()
		local root = ReplicatedStorage:WaitForChild("AirdropMVC")
		local logic = root:WaitForChild("Logic")
		local Config = require(logic:WaitForChild("AirdropConfig"))
		local Model = require(logic:WaitForChild("AirdropModel"))
		local ControllerClass = require(logic:WaitForChild("AirdropController"))
		local Controller = ControllerClass.new(Config, Model)
		local System = require(systems:WaitForChild("AirdropServerSystem"))
		return System.new({
			Players = Players,
			Updates = updates,
			Workspace = workspace,
			ServerStorage = game:GetService("ServerStorage"),
			Effects = ReplicatedStorage:WaitForChild("Effect"):WaitForChild("Airdrop"),
			Channel = root.Gateway:WaitForChild("AirdropChannel"),
			Config = Config,
			Controller = Controller,
		})
	end)

	application:Register("WolfHuntServerSystem", 0, function()
		local root = ReplicatedStorage:WaitForChild("WolfHuntMVC")
		local logic = root:WaitForChild("Logic")
		local config = require(logic:WaitForChild("WolfHuntConfig"))
		local Model = require(logic:WaitForChild("WolfHuntModel"))
		local Controller = require(logic:WaitForChild("WolfHuntController"))
		local System = require(systems:WaitForChild("WolfHuntServerSystem"))
		return System.new({
			Players = Players,
			Workspace = workspace,
			ReplicatedStorage = ReplicatedStorage,
			ServerScriptService = ServerScriptService,
			Updates = updates,
			Config = config,
			Controller = Controller.new(config, Model.new(), Random.new()),
		})
	end)

	application:Register("ShopServerSystem", 0, function()
		local root = ReplicatedStorage:WaitForChild("ShopMVC")
		local logic = root:WaitForChild("Logic")
		local gatewayFolder = root:WaitForChild("Gateway")
		local config = require(logic:WaitForChild("ShopConfig"))
		local names = require(logic:WaitForChild("ShopMessageEnum"))
		local pricing = require(logic:WaitForChild("ShopPricingController"))
		local catalog = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
		local Model = require(logic:WaitForChild("ShopSessionModel"))
		local Controller = require(logic:WaitForChild("ShopServerController"))
		local Gateway = require(gatewayFolder:WaitForChild("ShopServerGateway"))
		local System = require(systems:WaitForChild("ShopServerSystem"))
		local shopCommands = CommandQueue.new(reportError)
		local shopEvents = EventBus.new(reportError)
		local model = Model.new()
		local inventory = application:Get("InventoryServerSystem")
		local controller = Controller.new({
			Model = model,
			Commands = shopCommands,
			Events = shopEvents,
			Names = names,
			Config = config,
			Catalog = catalog,
			Pricing = pricing,
			PurchaseInventory = function(userId, currencyItemId, totalCost, bundle)
				local player = Players:GetPlayerByUserId(userId)
				if not player then
					return false, "InventoryUnavailable"
				end
				return inventory:PurchaseBundle(player, currencyItemId, totalCost, bundle)
			end,
		})
		local gateway = Gateway.new({
			Workspace = workspace,
			Players = Players,
			Channel = gatewayFolder:WaitForChild("ShopChannel"),
			Commands = shopCommands,
			Events = shopEvents,
			Names = names,
			Config = config,
		})
		return System.new({
			Controller = controller,
			Gateway = gateway,
			Model = model,
			Commands = shopCommands,
			Events = shopEvents,
		})
	end)

	application:Register("VaultServerSystem", 0, function()
		local root = ReplicatedStorage:WaitForChild("VaultMVC")
		local logic = root:WaitForChild("Logic")
		local gatewayFolder = root:WaitForChild("Gateway")
		local config = require(logic:WaitForChild("VaultConfig"))
		local names = require(logic:WaitForChild("VaultMessageEnum"))
		local catalog = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
		local DataManager = require(ServerScriptService:WaitForChild("DataManager"))
		local Model = require(logic:WaitForChild("VaultModel"))
		local Controller = require(logic:WaitForChild("VaultServerController"))
		local Gateway = require(gatewayFolder:WaitForChild("VaultServerGateway"))
		local System = require(systems:WaitForChild("VaultServerSystem"))
		local vaultCommands = CommandQueue.new(reportError)
		local vaultEvents = EventBus.new(reportError)
		local model = Model.new()
		local inventory = application:Get("InventoryServerSystem")
		local controller = Controller.new({
			Model = model,
			Commands = vaultCommands,
			Events = vaultEvents,
			Names = names,
			Config = config,
			Catalog = catalog,
			GetBackpackItems = function(userId)
				local player = Players:GetPlayerByUserId(userId)
				local snapshot = player and inventory:GetSnapshot(player) or nil
				return snapshot and snapshot.Items or {}
			end,
			GetVaultItems = function(userId)
				local player = Players:GetPlayerByUserId(userId)
				if not player or not DataManager.CanMutate(player) then
					return nil
				end
				local vaultData = DataManager.GetSystemData(player, "Vault")
				return type(vaultData) == "table" and vaultData.Items or {}
			end,
			SaveVaultItems = function(userId, items)
				local player = Players:GetPlayerByUserId(userId)
				if player and DataManager.CanMutate(player) then
					DataManager.SetSystemData(player, "Vault", { Items = items })
				end
			end,
			ExchangeInventory = function(userId, removeList, addList)
				local player = Players:GetPlayerByUserId(userId)
				if not player then
					return false, "InventoryUnavailable"
				end
				return inventory:ExchangeItems(player, removeList, addList)
			end,
		})
		local gateway = Gateway.new({
			Workspace = workspace,
			Players = Players,
			Channel = gatewayFolder:WaitForChild("VaultChannel"),
			Commands = vaultCommands,
			Events = vaultEvents,
			Names = names,
			Config = config,
		})
		return System.new({
			Controller = controller,
			Gateway = gateway,
			Model = model,
			Commands = vaultCommands,
			Events = vaultEvents,
		})
	end)

	application:Register("CrafterServerSystem", 0, function()
		local root = ReplicatedStorage:WaitForChild("CrafterMVC")
		local logic = root:WaitForChild("Logic")
		local gatewayFolder = root:WaitForChild("Gateway")
		local config = require(logic:WaitForChild("CrafterConfig"))
		local names = require(logic:WaitForChild("CrafterMessageEnum"))
		local catalog = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
		local Model = require(logic:WaitForChild("CrafterModel"))
		local Controller = require(logic:WaitForChild("CrafterServerController"))
		local Gateway = require(gatewayFolder:WaitForChild("CrafterServerGateway"))
		local System = require(systems:WaitForChild("CrafterServerSystem"))
		local crafterCommands = CommandQueue.new(reportError)
		local crafterEvents = EventBus.new(reportError)
		local model = Model.new()
		local inventory = application:Get("InventoryServerSystem")
		local controller = Controller.new({
			Model = model,
			Commands = crafterCommands,
			Events = crafterEvents,
			Names = names,
			Config = config,
			Catalog = catalog,
			GetBackpackItems = function(userId)
				local player = Players:GetPlayerByUserId(userId)
				local snapshot = player and inventory:GetSnapshot(player) or nil
				return snapshot and snapshot.Items or {}
			end,
			ExchangeInventory = function(userId, removeList, addList)
				local player = Players:GetPlayerByUserId(userId)
				if not player then
					return false, "InventoryUnavailable"
				end
				return inventory:ExchangeItems(player, removeList, addList)
			end,
		})
		local gateway = Gateway.new({
			Workspace = workspace,
			Players = Players,
			Channel = gatewayFolder:WaitForChild("CrafterChannel"),
			Commands = crafterCommands,
			Events = crafterEvents,
			Names = names,
			Config = config,
		})
		return System.new({
			Controller = controller,
			Gateway = gateway,
			Model = model,
			Commands = crafterCommands,
			Events = crafterEvents,
		})
	end)

	application:Register("FlagGameServerSystem", 0, function()
		local root = ReplicatedStorage:WaitForChild("FlagGameMVC")
		local logic = root:WaitForChild("Logic")
		local config = require(logic:WaitForChild("FlagGameConfig"))
		local Model = require(logic:WaitForChild("FlagGameModel"))
		local Command = require(logic:WaitForChild("FlagGameCommand"))
		local ControllerClass = require(logic:WaitForChild("FlagGameController"))
		local controller = ControllerClass.new({
			Config = config,
			Model = Model.new(),
			Commands = commands,
			Events = eventBus,
		})
		local System = require(systems:WaitForChild("FlagGameServerSystem"))
		return System.new({
			Players = Players,
			RunService = RunService,
			Workspace = workspace,
			ReplicatedStorage = ReplicatedStorage,
			Commands = commands,
			Events = eventBus,
			Controller = controller,
			Command = Command,
			Config = config,
			Updates = updates,
		})
	end)
end

local function dispose()
	if disposed then
		return
	end
	disposed = true
	if frameConnection then
		frameConnection:Disconnect()
		frameConnection = nil
	end
	application:Dispose()
	commands:Dispose()
	eventBus:Dispose()
end

registerFeatureRecipes()
application:Get("DeathSystemServerSystem")
application:Get("CarStatusServerSystem")
application:Get("MainMenuServerSystem")
application:Get("InventoryServerSystem")
application:Get("ShopServerSystem")
application:Get("VaultServerSystem")
application:Get("CrafterServerSystem")
application:Get("PlayerVitalsServerSystem")
application:Get("FallImpactServerSystem")
application:Get("PlayerCollisionServerSystem")
application:Get("StreakKillSystem")
application:Get("MeleeWeaponSystem")
application:Get("TrainningDummySystem")
application:Get("AnnouncementServerSystem")
application:Get("AirdropServerSystem")
application:Get("FlagGameServerSystem")
application:Get("FarmServerSystem")
application:Get("WolfHuntServerSystem")

frameConnection = RunService.Heartbeat:Connect(function(deltaTime)
	commands:Pump()
	updates:Run(deltaTime)
end)

script.Destroying:Connect(dispose)
game:BindToClose(dispose)
