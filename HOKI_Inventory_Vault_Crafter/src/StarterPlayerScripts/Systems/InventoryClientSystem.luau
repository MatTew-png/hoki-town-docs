--!strict
-- /// <summary>Owns inventory client messaging, scoped views, and UI respawn cleanup.</summary>
local InventoryClientSystem = {}
InventoryClientSystem.__index = InventoryClientSystem
local function start(self)
	local Players = self._context.Players
	local ReplicatedStorage = self._context.ReplicatedStorage
	local UserInputService = self._context.UserInputService
	local TweenService = self._context.TweenService
	local Lighting = self._context.Lighting

	local root = ReplicatedStorage:WaitForChild("InventoryMVC")
	local core = root:WaitForChild("Core")
	local Scope = require(core:WaitForChild("Scope"))
	local UpdateLoop = require(core:WaitForChild("UpdateLoop"))
	local CommandQueue = require(core:WaitForChild("CommandQueue"))
	local EventBus = require(core:WaitForChild("EventBus"))
	local names = require(root:WaitForChild("Logic"):WaitForChild("InventoryMessageEnum"))
	local InventorySnapshotController = require(root:WaitForChild("Logic"):WaitForChild("InventorySnapshotController"))
	local InventoryQuantityController = require(root:WaitForChild("Logic"):WaitForChild("InventoryQuantityController"))
	local gateway = root:WaitForChild("Gateway")
	local RobloxInventoryClientTransport = require(gateway:WaitForChild("RobloxInventoryClientTransport"))
	local InventoryDtoMapper = require(gateway:WaitForChild("InventoryDtoMapper"))
	local InventoryView = require(root:WaitForChild("Visualizer"):WaitForChild("InventoryView"))
	local ItemTransferView = require(root:WaitForChild("Visualizer"):WaitForChild("ItemTransferView"))
	local ItemTransferConfig = require(root:WaitForChild("Visualizer"):WaitForChild("ItemTransferConfig"))
	local InventoryUseLoadingView = require(root:WaitForChild("Visualizer"):WaitForChild("InventoryUseLoadingView"))
	local catalog = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
	local useConfig = require(root:WaitForChild("Logic"):WaitForChild("InventoryUseConfig"))
	local interactionConfig = require(root:WaitForChild("Logic"):WaitForChild("InventoryInteractionConfig"))
	local useAnimationAssets = root:WaitForChild("Assets")
	local useAnimations = {}
	for itemId, itemConfig in pairs(useConfig.Items) do
		local animationName = itemConfig.AnimationAsset
		if type(animationName) == "string" then
			local animation = useAnimationAssets:WaitForChild(animationName, 10)
			assert(animation and animation:IsA("Animation"), "Missing inventory use animation asset: " .. animationName)
			useAnimations[itemId] = animation
		end
	end
	local player = self._context.Player
	local playerGui = self._context.PlayerGui
	local remote = ReplicatedStorage:WaitForChild("InventoryEvents"):WaitForChild("InventoryChannel", 10)
	assert(remote and remote:IsA("RemoteEvent"), "Missing InventoryChannel")

	local function child(parent, name)
		local object = parent:WaitForChild(name, 10)
		assert(object, "Missing authored inventory asset: " .. parent:GetFullName() .. "." .. name)
		return object
	end

	local function optionalChild(parent, name)
		return parent:FindFirstChild(name)
	end

	local loadingScreen = child(playerGui, "Loading")
	local loadingBackground = child(loadingScreen, "BackGround")
	local loadingBar = child(loadingBackground, "Bar")
	local loadingAssets = {
		Screen = loadingScreen,
		Bar = loadingBar,
		Clip = child(loadingBar, "ProgressClip"),
		Percent = child(loadingBackground, "PercentLoad"),
		DesktopPrompt = child(child(loadingBackground, "CancelPrompt"), "DesktopPrompt"),
		MobilePrompt = child(child(loadingBackground, "CancelPrompt"), "MobilePrompt"),
	}
	loadingAssets.DesktopButton = child(loadingAssets.DesktopPrompt, "CancelButton")
	loadingAssets.MobileButton = child(loadingAssets.MobilePrompt, "CancelButton")
	assert(
		loadingScreen:IsA("ScreenGui")
			and loadingBar:IsA("ImageLabel")
			and loadingAssets.Clip:IsA("UIGradient")
			and loadingAssets.Percent:IsA("TextLabel")
			and loadingAssets.DesktopPrompt:IsA("Frame")
			and loadingAssets.MobilePrompt:IsA("Frame")
			and loadingAssets.DesktopButton:IsA("TextButton")
			and loadingAssets.MobileButton:IsA("TextButton"),
		"Loading GUI hierarchy has an unexpected class"
	)

	local transferScreen = child(playerGui, "ItemTransfer")
	local transferScroll = child(transferScreen, "ScrollingFrame")
	local transferAssets = {
		Screen = transferScreen,
		Scroll = transferScroll,
		Template = child(transferScroll, "Template"),
		ExitLayer = child(transferScreen, "ExitLayer"),
		GainSound = child(transferScreen, "GainSound"),
		LossSound = child(transferScreen, "LossSound"),
	}

	local function readAssets(inventory)
		local backdropScreen = child(playerGui, "InventoryBackdrop")
		local mobileUser = playerGui:FindFirstChild("MobileUser")
		local mobileMenu = mobileUser and mobileUser:FindFirstChild("Menu")
		local toggleButton = mobileMenu and mobileMenu:FindFirstChild("ImageButton")
		local storage = child(inventory, "Storage")
		local background = child(storage, "Background")
		local scroll = child(background, "ScrollingFrame")
		local hotbarFrame = child(storage, "Hotbars")
		local hotbarHud = child(inventory, "HotbarHUD")
		local characterAndStatus = child(inventory, "CharacterAndStatus")
		local characterPanel = child(characterAndStatus, "CharacterPanel")
		local viewport = child(characterPanel, "CharacterViewport")
		local status = child(characterAndStatus, "Status")
		local idLabel
		for _, object in ipairs(status:GetChildren()) do
			if object:IsA("TextLabel") and string.find(object.Text, "ID", 1, true) then
				idLabel = object
				break
			end
		end
		assert(idLabel, "Missing authored inventory asset: Inventory.CharacterAndStatus.Status ID TextLabel")
		assert(workspace.CurrentCamera, "Workspace.CurrentCamera is required for the inventory viewport preview")
		local assets = {
			Screen = inventory,
			Main = background,
			Storage = storage,
			CharacterAndStatus = characterAndStatus,
			BackdropScreen = backdropScreen,
			Dimmer = child(backdropScreen, "Dimmer"),
			CharacterPanel = characterPanel,
			Viewport = viewport,
			PreviewWorld = child(viewport, "PreviewWorld"),
			CameraTemplate = workspace.CurrentCamera,
			Status = status,
			PlayerName = child(status, "Playername"),
			PlayerId = idLabel,
			Money = child(status, "MoneyText"),
			Bank = child(status, "BankText"),
			Scroll = scroll,
			Template = child(scroll, "ItemTemplate"),
			Count = child(background, "ItemQuantify"),
			DragTemplate = child(inventory, "DragItemTemplate"),
			Chooser = child(inventory, "Chooser"),
			PlayerInrange = child(inventory, "PlayerInrange"),
			PlayerRangeScroll = child(child(inventory, "PlayerInrange"), "ScrollingFrame"),
			PlayerRangeTemplate = child(child(inventory, "PlayerInrange"), "ScrollingFrame"):WaitForChild("Template"),
			Accept = child(inventory, "Accept"),
			Search = child(child(background, "SearchBar"), "TextBox"),
			ToggleButton = toggleButton,
			Categories = {
				BtnAll = child(background, "BtnAll"),
				BtnWeapon = child(background, "BtnWeapon"),
				BtnFoods = child(background, "BtnFoods"),
				BtnFashion = child(background, "BtnFashion"),
			},
			OpenSound = child(storage, "OpenSound"),
			CloseSound = child(storage, "CloseSound"),
			HoverSound = child(storage, "HoverSound"),
			UseSound = child(storage, "UseSound"),
			HotbarUseSound = child(storage, "HotbarUseSound"),
			DropSound = child(storage, "DropSound"),
			Blur = optionalChild(Lighting, "InventoryBlur"),
			HotbarMain = hotbarFrame,
			HudMain = hotbarHud,
			Slots = {},
			HudHotbars = {},
		}
		for index = 1, 6 do
			local slot = child(hotbarFrame, "Slot" .. index)
			local icon = child(slot, "ItemIcon")
			assets.Slots[index] = { Frame = slot, Decal = icon, Amount = optionalChild(slot, "Amount") }
			local hudButton = child(hotbarHud, "Hotbar" .. index)
			assets.HudHotbars[index] = {
				Button = hudButton,
				Amount = optionalChild(hudButton, "Amount"),
				Scale = child(hudButton, "BounceScale"),
				Indicator = child(hudButton, "SelectionIndicator"),
				NumberLabel = child(hudButton, "TextLabel"),
				Icon = child(hudButton, "ItemIcon"),
			}
		end
		return assets
	end

	local updates = UpdateLoop.new(warn)
	local app = Scope.new({ Kind = 1, Updates = updates, ReportError = warn })
	app:Register("Commands", 1, function()
		return CommandQueue.new(warn)
	end)
	app:Register("Events", 1, function()
		return EventBus.new(warn)
	end)
	app:Register("RobloxInventoryClientTransport", 1, function(scope)
		return RobloxInventoryClientTransport.new({
			Remote = remote,
			Commands = scope:Get("Commands"),
			Events = scope:Get("Events"),
			Names = names,
			Mapper = InventoryDtoMapper,
			Catalog = catalog,
			ReportError = warn,
		})
	end)
	app:Register("InventorySnapshotController", 1, function(scope)
		return InventorySnapshotController.new({
			Commands = scope:Get("Commands"),
			Events = scope:Get("Events"),
			Names = names,
		})
	end)
	app:Register("InventoryQuantityController", 1, function(scope)
		return InventoryQuantityController.new({ Events = scope:Get("Events"), Names = names })
	end)
	app:Register("ItemTransferView", 1, function(scope)
		return ItemTransferView.new({
			Assets = transferAssets,
			Events = scope:Get("Events"),
			Names = names,
			Catalog = catalog,
			TweenService = TweenService,
			Config = ItemTransferConfig,
		})
	end)
	app:Register("InventoryUseLoadingView", 1, function(scope)
		return InventoryUseLoadingView.new({
			Assets = loadingAssets,
			Events = scope:Get("Events"),
			Commands = scope:Get("Commands"),
			Input = UserInputService,
			TweenService = TweenService,
			Names = names,
			Clock = function()
				return workspace:GetServerTimeNow()
			end,
		})
	end)
	app:Register("InventoryView", 4, function(scope)
		return InventoryView.new({
			Assets = scope.Context,
			Input = UserInputService,
			Player = player,
			TweenService = TweenService,
			Commands = scope:Get("Commands"),
			Events = scope:Get("Events"),
			Names = names,
			Catalog = catalog,
			UseConfig = useConfig,
			UseAnimations = useAnimations,
			Players = Players,
			InteractionConfig = interactionConfig,
		})
	end)
	local commands = app:Get("Commands")
	app:Get("InventorySnapshotController")
	app:Get("InventoryQuantityController")
	app:Get("ItemTransferView")
	app:Get("InventoryUseLoadingView")
	app:Get("RobloxInventoryClientTransport")
	local viewScope
	local currentInventory
	local generation = 0
	local pendingThread
	local disposed = false
	local connections = {}

	local function refreshViews()
		generation += 1
		local expectedGeneration = generation
		if pendingThread then
			local success, message = pcall(task.cancel, pendingThread)
			if not success then
				warn(message)
			end
			pendingThread = nil
		end
		if viewScope then
			viewScope:Dispose()
			viewScope = nil
		end
		pendingThread = task.defer(function()
			local success, message = pcall(function()
				local inventory = child(playerGui, "Inventory")
				local assets = readAssets(inventory)
				inventory.Enabled = true
				if disposed or generation ~= expectedGeneration or not inventory.Parent then
					return
				end
				currentInventory = inventory
				viewScope = app:CreateChild(4, assets)
				viewScope:Get("InventoryView")
				commands:Enqueue(table.freeze({ Name = names.Request }))
			end)
			if not success then
				warn("Inventory UI initialization failed: " .. tostring(message))
				if viewScope then
					viewScope:Dispose()
					viewScope = nil
				end
			end
			pendingThread = nil
		end)
	end

	table.insert(
		connections,
		playerGui.ChildAdded:Connect(function(object)
			if object.Name == "Inventory" then
				refreshViews()
			end
		end)
	)
	table.insert(
		connections,
		playerGui.ChildRemoved:Connect(function(object)
			if object == currentInventory then
				refreshViews()
			end
		end)
	)
	self._step = function(deltaTime)
		commands:Pump()
		updates:Run(deltaTime)
	end
	refreshViews()

	local function dispose()
		if disposed then
			return
		end
		disposed = true
		generation += 1
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		if pendingThread then
			local success, message = pcall(task.cancel, pendingThread)
			if not success then
				warn(message)
			end
		end
		app:Dispose()
	end
	self._dispose = dispose
end
function InventoryClientSystem.new(context)
	return setmetatable(
		{ _context = context, _started = false, _disposed = false, _step = nil, _dispose = nil },
		InventoryClientSystem
	)
end
function InventoryClientSystem:Init()
	if self._started or self._disposed then
		return
	end
	self._started = true
	local ok, message = pcall(start, self)
	if not ok then
		self:Dispose()
		error("InventoryClientSystem initialization failed: " .. tostring(message))
	end
end
function InventoryClientSystem:UpdateLogic(deltaTime)
	if not self._disposed and self._step then
		self._step(deltaTime)
	end
end
function InventoryClientSystem:Dispose()
	if self._disposed then
		return
	end
	self._disposed = true
	local cleanup = self._dispose
	self._dispose = nil
	self._step = nil
	if cleanup then
		local ok, message = pcall(cleanup)
		if not ok then
			warn("[InventoryClientSystem] Cleanup failed: " .. tostring(message))
		end
	end
	self._context = nil
end
return InventoryClientSystem
