# Luau-Native MVC Reference Template (`--!strict`)

Compact blueprint adapting the architecture into idiomatic Roblox Luau modules.

## 1. Frozen Enum & Contract Types (`ReplicatedStorage/Shared/ShopTypes.luau`)

```luau
--!strict
--[[
	Shared immutable enums, commands, events, and snapshot contracts for the Shop feature.
]]

local ShopTypes = {}

ShopTypes.PurchaseErrorEnum = table.freeze({
	InsufficientFunds = "InsufficientFunds",
	InvalidItem = "InvalidItem",
})

export type BuyItemCommand = {
	PlayerId: number,
	ItemId: string,
	Quantity: number,
}

export type ItemBoughtEvent = {
	PlayerId: number,
	ItemId: string,
	RemainingCurrency: number,
}

export type IUpdatable = {
	UpdateLogic: (self: IUpdatable, deltaTime: number) -> (),
}

return ShopTypes
```

## 2. Pure Model (`ReplicatedStorage/Logic/ShopModel.luau`)

```luau
--!strict
--[[
	Holds player shop currency state and enforces non-negative balance invariants.
]]

local ShopModel = {}
ShopModel.__index = ShopModel

export type ShopModel = typeof(setmetatable(
	{} :: {
		_currencyByPlayer: { [number]: number },
	},
	ShopModel
))

function ShopModel.new(): ShopModel
	return setmetatable({
		_currencyByPlayer = {},
	}, ShopModel)
end

function ShopModel.GetCurrency(self: ShopModel, playerId: number): number
	return self._currencyByPlayer[playerId] or 0
end

function ShopModel.TryDeductCurrency(self: ShopModel, playerId: number, amount: number): boolean
	if amount < 0 then
		return false
	end
	local current = self:GetCurrency(playerId)
	if current < amount then
		return false
	end
	self._currencyByPlayer[playerId] = current - amount
	return true
end

return ShopModel
```

## 3. Controller with Constructor DI + Init/Destroy (`ServerScriptService/Logic/ShopController.luau`)

```luau
--!strict
--[[
	Owns Shop business rules. Consumes BuyItemCommand, updates ShopModel, and raises events.
]]

local ShopController = {}
ShopController.__index = ShopController

export type Deps = {
	Model: any,
	CatalogPrices: { [string]: number },
	EventBus: any,
}

export type ShopController = typeof(setmetatable(
	{} :: {
		_model: any,
		_catalogPrices: { [string]: number },
		_eventBus: any,
		_connections: { any },
		_threads: { thread },
		_isInitialized: boolean,
	},
	ShopController
))

function ShopController.new(deps: Deps): ShopController
	return setmetatable({
		_model = deps.Model,
		_catalogPrices = deps.CatalogPrices,
		_eventBus = deps.EventBus,
		_connections = {},
		_threads = {},
		_isInitialized = false,
	}, ShopController)
end

function ShopController.Init(self: ShopController)
	self._isInitialized = true
	-- Subscribe to CommandQueue or Bus here; store handles in self._connections
end

function ShopController.HandleBuyItem(self: ShopController, command: { PlayerId: number, ItemId: string, Quantity: number })
	if not self._isInitialized then
		return
	end
	local unitPrice = self._catalogPrices[command.ItemId]
	if not unitPrice or command.Quantity <= 0 or command.Quantity > 99 then
		return
	end
	local totalCost = unitPrice * command.Quantity
	if self._model:TryDeductCurrency(command.PlayerId, totalCost) then
		self._eventBus:Publish("ItemBought", {
			PlayerId = command.PlayerId,
			ItemId = command.ItemId,
			RemainingCurrency = self._model:GetCurrency(command.PlayerId),
		})
	end
end

function ShopController.Destroy(self: ShopController)
	for _, conn in self._connections do
		if conn and conn.Disconnect then
			conn:Disconnect()
		end
	end
	table.clear(self._connections)

	for _, th in self._threads do
		pcall(task.cancel, th)
	end
	table.clear(self._threads)

	self._isInitialized = false
	self._model = nil
	self._eventBus = nil
end

return ShopController
```

## 4. Client View Using Hand-Authored Studio UI (`StarterPlayerScripts/Visualizer/ShopView.luau`)

```luau
--!strict
--[[
	Renders Shop currency updates onto the pre-built Studio ScreenGui without deciding rules.
]]

local ShopView = {}
ShopView.__index = ShopView

function ShopView.new(playerGui: PlayerGui, buyRemote: RemoteEvent)
	return setmetatable({
		_playerGui = playerGui,
		_buyRemote = buyRemote,
		_currencyLabel = nil :: TextLabel?,
		_lastCurrencyText = "",
		_connections = {} :: { RBXScriptConnection },
	}, ShopView)
end

function ShopView.Init(self: any)
	local shopGui = self._playerGui:WaitForChild("ShopGui", 10)
	if not shopGui then
		warn("[ShopView] Missing Studio ScreenGui 'ShopGui'")
		return
	end
	local panel = shopGui:WaitForChild("MainPanel")
	local buyButton = panel:WaitForChild("BuyPotionButton") :: TextButton
	self._currencyLabel = panel:WaitForChild("CurrencyLabel") :: TextLabel

	table.insert(
		self._connections,
		buyButton.Activated:Connect(function()
			self._buyRemote:FireServer("HealthPotion", 1)
		end)
	)
end

function ShopView.RefreshCurrency(self: any, amount: number)
	if not self._currencyLabel then
		return
	end
	local nextText = tostring(amount)
	if nextText ~= self._lastCurrencyText then
		self._lastCurrencyText = nextText
		self._currencyLabel.Text = nextText
	end
end

function ShopView.Destroy(self: any)
	for _, conn in self._connections do
		conn:Disconnect()
	end
	table.clear(self._connections)
	self._currencyLabel = nil
end

return ShopView
```
