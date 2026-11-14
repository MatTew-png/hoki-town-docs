--!strict
-- /// <summary>Client composition root for shared feature lifetime and frame updates.</summary>
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local systems = script.Parent:WaitForChild("Systems")
local core = ReplicatedStorage:WaitForChild("InventoryMVC"):WaitForChild("Core")
local Scope = require(core:WaitForChild("Scope"))
local CommandQueue = require(core:WaitForChild("CommandQueue"))
local EventBus = require(core:WaitForChild("EventBus"))
local UpdateLoop = require(core:WaitForChild("UpdateLoop"))

local function reportError(message)
	warn("[ClientMain] " .. tostring(message))
end

local commands = CommandQueue.new(reportError)
local updates = UpdateLoop.new(reportError)
local application = Scope.new({
	Kind = 0,
	Context = { Player = player, PlayerGui = playerGui },
	ReportError = reportError,
	Updates = updates,
})
local disposed = false
local frameConnection

application:Register("DeathSystemClientSystem", 0, function()
	local System = require(systems:WaitForChild("DeathSystemClientSystem"))
	return System.new({
		Players = Players,
		ReplicatedStorage = ReplicatedStorage,
		UserInputService = UserInputService,
		Workspace = workspace,
		Player = player,
		PlayerGui = playerGui,
	})
end)

application:Register("CharacterMovementClientSystem", 0, function()
	local movementRoot = ReplicatedStorage:WaitForChild("CharacterMovementMVC")
	local ControllerClass = require(movementRoot:WaitForChild("Bootstrap"):WaitForChild("CharacterMovementController"))
	local System = require(systems:WaitForChild("CharacterMovementClientSystem"))
	return System.new({ Player = player, ControllerClass = ControllerClass })
end)

application:Register("StreakKillClientSystem", 0, function()
	local root = ReplicatedStorage:WaitForChild("StreakKillMVC")
	local event = root.Gateway:WaitForChild("StreakKillUpdated")
	local hud = playerGui:WaitForChild("StreakKillHUD", 15)
	assert(hud and hud:IsA("ScreenGui"), "PlayerGui.StreakKillHUD is required")
	local View = require(root.Visualizer:WaitForChild("StreakKillView"))
	local System = require(systems:WaitForChild("StreakKillClientSystem"))
	return System.new({ Event = event, View = View.new(hud) })
end)

application:Register("MobileUserSystem", 0, function()
	local gui = playerGui:WaitForChild("MobileUser", 15)
	assert(gui and gui:IsA("ScreenGui"), "PlayerGui.MobileUser is required")
	local System = require(systems:WaitForChild("MobileUserSystem"))
	return System.new({ Player = player, UserInputService = UserInputService, Gui = gui })
end)

application:Register("MeleeWeaponClientSystem", 0, function()
	local root = ReplicatedStorage:WaitForChild("MeleeWeaponMVC")
	local config = require(root.Logic:WaitForChild("MeleeWeaponConfig"))
	local adapterModule = require(root.Visualizer:WaitForChild("MeleeWeaponInputAdapter"))
	local System = require(systems:WaitForChild("MeleeWeaponClientSystem"))
	return System.new({
		Adapter = adapterModule.new({
			Player = player,
			Remote = root.Gateway:WaitForChild("MeleeWeaponCommand"),
			Config = config,
		}),
	})
end)

application:Register("InventoryClientSystem", 0, function()
	local System = require(systems:WaitForChild("InventoryClientSystem"))
	return System.new({
		Players = Players,
		ReplicatedStorage = ReplicatedStorage,
		RunService = RunService,
		UserInputService = UserInputService,
		TweenService = game:GetService("TweenService"),
		Lighting = game:GetService("Lighting"),
		Player = player,
		PlayerGui = playerGui,
	})
end)

application:Register("AnnouncementClientSystem", 0, function()
	local root = ReplicatedStorage:WaitForChild("AnnouncementMVC")
	local logic = root:WaitForChild("Logic")
	local config = require(logic:WaitForChild("AnnouncementConfig"))
	local View = require(root.Visualizer:WaitForChild("AnnouncementView"))
	local Controller = require(logic:WaitForChild("AnnouncementClientController"))
	local Gateway = require(root.Gateway:WaitForChild("AnnouncementClientGateway"))
	local hud = playerGui:WaitForChild("AnnouncementHUD", 15)
	assert(hud and hud:IsA("ScreenGui"), "PlayerGui.AnnouncementHUD is required")
	local view = View.new({ Hud = hud, TweenService = game:GetService("TweenService"), Config = config })
	local System = require(systems:WaitForChild("AnnouncementClientSystem"))
	return System.new({
		Gateway = Gateway.new(root.Gateway:WaitForChild("AnnouncementBroadcast")),
		Controller = Controller.new(view, config),
	})
end)

application:Register("AirdropClientSystem", 0, function()
	local root = ReplicatedStorage:WaitForChild("AirdropMVC")
	local gui = playerGui:WaitForChild("AirdropNotify", 15)
	assert(gui and gui:IsA("ScreenGui"), "PlayerGui.AirdropNotify is required")
	local mainFrame = gui:WaitForChild("MainFrame")
	local cards = {}
	for _, cardName in ipairs({ "GangFrame", "FamilyFrame", "CitizenFrame" }) do
		local card = mainFrame:WaitForChild(cardName)
		card:WaitForChild("Background"):WaitForChild("TimeCount")
		cards[cardName] = card
	end
	local View = require(root.Visualizer:WaitForChild("AirdropView"))
	local config = require(root.Logic:WaitForChild("AirdropConfig"))
	local view = View.new({
		Gui = gui,
		Workspace = workspace,
		Cards = cards,
		Config = config,
		TweenService = game:GetService("TweenService"),
		SoundService = game:GetService("SoundService"),
	})
	local System = require(systems:WaitForChild("AirdropClientSystem"))
	return System.new({ Channel = root.Gateway:WaitForChild("AirdropChannel"), View = view, Updates = updates })
end)

application:Register("FarmClientSystem", 0, function()
	local root = ReplicatedStorage:WaitForChild("FarmMVC")
	local logic = root:WaitForChild("Logic")
	local config = require(logic:WaitForChild("FarmConfig"))
	local catalog = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
	local gui = playerGui:WaitForChild(config.FarmGuiName, 15)
	assert(gui and gui:IsA("ScreenGui"), "PlayerGui.FarmGUI is required")
	local View = require(root.Visualizer:WaitForChild("FarmView"))
	local System = require(systems:WaitForChild("FarmClientSystem"))
	local view = View.new({
		Gui = gui,
		Player = player,
		Config = config,
		ItemInfo = catalog,
		Workspace = workspace,
		ReplicatedStorage = ReplicatedStorage,
		TweenService = game:GetService("TweenService"),
	})
	return System.new({
		Channel = root.Gateway:WaitForChild("FarmChannel"),
		View = view,
		Gui = gui,
		Player = player,
		Config = config,
		Workspace = workspace,
		ItemInfo = catalog,
	})
end)

application:Register("FlagGameClientSystem", 0, function()
	local root = ReplicatedStorage:WaitForChild("FlagGameMVC")
	local config = require(root.Logic:WaitForChild("FlagGameConfig"))
	local gui = playerGui:WaitForChild("FlagNotify", 15)
	assert(gui and gui:IsA("ScreenGui"), "PlayerGui.FlagNotify is required")
	local View = require(root.Visualizer:WaitForChild("FlagGameView"))
	local System = require(systems:WaitForChild("FlagGameClientSystem"))
	local view = View.new({
		Gui = gui,
		Player = player,
		Players = Players,
		Workspace = workspace,
		TweenService = game:GetService("TweenService"),
		Config = config,
	})
	return System.new({ View = view, Config = config })
end)

application:Register("MainMenuClientSystem", 0, function()
	local root = ReplicatedStorage:WaitForChild("MainMenuMVC")
	local logic = root:WaitForChild("Logic")
	local config = require(logic:WaitForChild("MainMenuConfig"))
	local gui = playerGui:WaitForChild("MainMenu", 15)
	assert(gui and gui:IsA("ScreenGui"), "PlayerGui.MainMenu is required")
	local Model = require(logic:WaitForChild("MainMenuModel"))
	local Controller = require(logic:WaitForChild("MainMenuController"))
	local visualizer = root:WaitForChild("Visualizer")
	local dailyConfig = require(logic:WaitForChild("DailyLoginConfig"))
	local catalog = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
	local Gateway = require(root:WaitForChild("Gateway"):WaitForChild("MainMenuClientGateway"))
	local View = require(visualizer:WaitForChild("MainMenuView"))
	local ContentView = require(visualizer:WaitForChild("MainMenuContentView"))
	local System = require(systems:WaitForChild("MainMenuClientSystem"))
	local model = Model.new(config.DefaultPage)
	local controller = Controller.new(model, config)
	local view = View.new(gui, config)
	local contentView = ContentView.new(gui, dailyConfig, dailyConfig.Rewards, catalog, player)
	return System.new({
		View = view,
		ContentView = contentView,
		Controller = controller,
		Gateway = Gateway.new(root.Gateway:WaitForChild("MainMenuChannel")),
		DailyConfig = dailyConfig,
		Player = player,
		Config = config,
		UserInputService = UserInputService,
	})
end)

application:Register("ProximityPromptClientSystem", 0, function()
	local promptRoot = ReplicatedStorage:WaitForChild("ProximityPromptMVC")
	local templateFolder = ReplicatedStorage:WaitForChild("BillboardGui")
	local template = templateFolder:WaitForChild("BillboardGui")
	local config = require(promptRoot:WaitForChild("Logic"):WaitForChild("ProximityPromptConfig"))
	local View = require(promptRoot:WaitForChild("Visualizer"):WaitForChild("ProximityPromptView"))
	local view = View.new({
		PlayerGui = playerGui,
		Player = player,
		Template = template,
		TweenService = game:GetService("TweenService"),
		Config = config,
	})
	local System = require(systems:WaitForChild("ProximityPromptClientSystem"))
	return System.new({
		View = view,
		Player = player,
		ProximityPromptService = game:GetService("ProximityPromptService"),
		UserInputService = UserInputService,
	})
end)

application:Register("ShopClientSystem", 0, function()
	local root = ReplicatedStorage:WaitForChild("ShopMVC")
	local logic = root:WaitForChild("Logic")
	local gatewayFolder = root:WaitForChild("Gateway")
	local config = require(logic:WaitForChild("ShopConfig"))
	local names = require(logic:WaitForChild("ShopMessageEnum"))
	local pricing = require(logic:WaitForChild("ShopPricingController"))
	local catalog = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
	local Model = require(logic:WaitForChild("ShopCartModel"))
	local Controller = require(logic:WaitForChild("ShopCartController"))
	local View = require(root.Visualizer:WaitForChild("ShopView"))
	local Gateway = require(gatewayFolder:WaitForChild("ShopClientGateway"))
	local System = require(systems:WaitForChild("ShopClientSystem"))
	local gui = playerGui:WaitForChild("Shop", 15)
	assert(gui and gui:IsA("ScreenGui"), "PlayerGui.Shop is required")
	local shopCommands = CommandQueue.new(reportError)
	local shopEvents = EventBus.new(reportError)
	local model = Model.new()
	return System.new({
		Model = model,
		Commands = shopCommands,
		Events = shopEvents,
		Controller = Controller.new({
			Model = model,
			Commands = shopCommands,
			Events = shopEvents,
			Names = names,
			Config = config,
			Catalog = catalog,
			Pricing = pricing,
		}),
		View = View.new({
			Gui = gui,
			Commands = shopCommands,
			Events = shopEvents,
			Names = names,
			Config = config,
			Catalog = catalog,
			Pricing = pricing,
			TweenService = game:GetService("TweenService"),
		}),
		Gateway = Gateway.new({
			Channel = gatewayFolder:WaitForChild("ShopChannel"),
			Player = player,
			Commands = shopCommands,
			Events = shopEvents,
			Names = names,
			Config = config,
		}),
	})
end)

application:Register("VaultClientSystem", 0, function()
	local root = ReplicatedStorage:WaitForChild("VaultMVC")
	local logic = root:WaitForChild("Logic")
	local gatewayFolder = root:WaitForChild("Gateway")
	local config = require(logic:WaitForChild("VaultConfig"))
	local names = require(logic:WaitForChild("VaultMessageEnum"))
	local catalog = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
	local View = require(root.Visualizer:WaitForChild("VaultView"))
	local Gateway = require(gatewayFolder:WaitForChild("VaultClientGateway"))
	local System = require(systems:WaitForChild("VaultClientSystem"))
	local gui = playerGui:WaitForChild("Vault", 15)
	assert(gui and gui:IsA("ScreenGui"), "PlayerGui.Vault is required")
	local vaultCommands = CommandQueue.new(reportError)
	local vaultEvents = EventBus.new(reportError)
	return System.new({
		Commands = vaultCommands,
		Events = vaultEvents,
		View = View.new({
			Gui = gui,
			Commands = vaultCommands,
			Events = vaultEvents,
			Names = names,
			Config = config,
			Catalog = catalog,
			TweenService = game:GetService("TweenService"),
			UserInputService = UserInputService,
		}),
		Gateway = Gateway.new({
			Channel = gatewayFolder:WaitForChild("VaultChannel"),
			Player = player,
			Commands = vaultCommands,
			Events = vaultEvents,
			Names = names,
			Config = config,
		}),
	})
end)

application:Register("CrafterClientSystem", 0, function()
	local root = ReplicatedStorage:WaitForChild("CrafterMVC")
	local logic = root:WaitForChild("Logic")
	local gatewayFolder = root:WaitForChild("Gateway")
	local config = require(logic:WaitForChild("CrafterConfig"))
	local names = require(logic:WaitForChild("CrafterMessageEnum"))
	local catalog = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
	local View = require(root.Visualizer:WaitForChild("CrafterView"))
	local Gateway = require(gatewayFolder:WaitForChild("CrafterClientGateway"))
	local System = require(systems:WaitForChild("CrafterClientSystem"))
	local gui = playerGui:WaitForChild("CraftingTable", 15)
	assert(gui and gui:IsA("ScreenGui"), "PlayerGui.CraftingTable is required")
	local crafterCommands = CommandQueue.new(reportError)
	local crafterEvents = EventBus.new(reportError)
	return System.new({
		Commands = crafterCommands,
		Events = crafterEvents,
		View = View.new({
			Gui = gui,
			Commands = crafterCommands,
			Events = crafterEvents,
			Names = names,
			Config = config,
			Catalog = catalog,
			TweenService = game:GetService("TweenService"),
			UserInputService = UserInputService,
		}),
		Gateway = Gateway.new({
			Channel = gatewayFolder:WaitForChild("CrafterChannel"),
			Player = player,
			Commands = crafterCommands,
			Events = crafterEvents,
			Names = names,
			Config = config,
		}),
	})
end)

application:Register("CarStatusClientSystem", 0, function()
	local root = ReplicatedStorage:WaitForChild("CarStatusMVC")
	local logic = root:WaitForChild("Logic")
	local config = require(logic:WaitForChild("CarStatusConfig"))
	local Gateway = require(root:WaitForChild("Gateway"):WaitForChild("CarStatusClientGateway"))
	local Controller = require(logic:WaitForChild("CarStatusClientController"))
	local View = require(root:WaitForChild("Visualizer"):WaitForChild("CarStatusView"))
	local System = require(systems:WaitForChild("CarStatusClientSystem"))
	return System.new({
		Gateway = Gateway.new({ Player = player, PlayerGui = playerGui, Config = config }),
		Controller = Controller.new(),
		ViewClass = View,
		PlayerGui = playerGui,
		Config = config,
		TweenService = game:GetService("TweenService"),
	})
end)

application:Register("StatusClientSystem", 0, function()
	local statusGui = playerGui:WaitForChild("Status", 15)
	local mainFrame = statusGui:WaitForChild("MainFrame", 8)
	local hotbarsGui = playerGui:WaitForChild("Hotbars", 15)
	local inventoryGui = playerGui:WaitForChild("Inventory", 15)
	local hotbarsMainFrame = inventoryGui:WaitForChild("HotbarHUD", 8)
	local statusRoot = ReplicatedStorage:WaitForChild("StatusMVC")
	local logic = statusRoot:WaitForChild("Logic")
	local config = require(logic:WaitForChild("SprintConfig"))
	local Model = require(logic:WaitForChild("SprintModel"))
	local Controller = require(logic:WaitForChild("SprintController"))
	local View = require(systems:WaitForChild("StatusHudView"))
	local InputAdapter = require(systems:WaitForChild("SprintInputAdapter"))
	local System = require(systems:WaitForChild("StatusClientSystem"))
	assert(mainFrame and hotbarsMainFrame, "Status.MainFrame and Inventory.HotbarHUD are required")
	local sprintModel = Model.new(config.MaxStamina)
	local sprintController = Controller.new(sprintModel, config)
	local view = View.new(mainFrame)
	local inputAdapter = InputAdapter.new({
		UserInputService = UserInputService,
		PlayerGui = playerGui,
		Enqueue = function(command)
			commands:Enqueue(command)
		end,
	})
	return System.new({
		Player = player,
		PlayerGui = playerGui,
		StarterGui = game:GetService("StarterGui"),
		StatusGui = statusGui,
		HotbarsGui = hotbarsGui,
		MainFrame = mainFrame,
		HotbarsMainFrame = hotbarsMainFrame,
		SprintController = sprintController,
		MaxStamina = config.MaxStamina,
		View = view,
		InputAdapter = inputAdapter,
		CommandQueue = commands,
	})
end)

local function dispose()
	if disposed then
		return
	end
	disposed = true
	if frameConnection then
		frameConnection:Disconnect()
		frameConnection = nil
	end
	commands:Dispose()
	application:Dispose()
end

application:Get("DeathSystemClientSystem")
application:Get("CharacterMovementClientSystem")
application:Get("StreakKillClientSystem")
application:Get("MobileUserSystem")
application:Get("StatusClientSystem")

application:Get("MeleeWeaponClientSystem")
application:Get("InventoryClientSystem")
application:Get("CarStatusClientSystem")
application:Get("AnnouncementClientSystem")
application:Get("AirdropClientSystem")
application:Get("FlagGameClientSystem")
application:Get("MainMenuClientSystem")
application:Get("ProximityPromptClientSystem")
application:Get("ShopClientSystem")
application:Get("VaultClientSystem")
application:Get("CrafterClientSystem")
application:Get("FarmClientSystem")
frameConnection = RunService.Heartbeat:Connect(function(deltaTime)
	commands:Pump()
	updates:Run(deltaTime)
end)
script.Destroying:Connect(dispose)
