--[[ <summary>Applies inventory equipment facts to authored Tool templates and owns their cleanup.</summary> ]]
local InventoryWeaponView = {}
InventoryWeaponView.__index = InventoryWeaponView

function InventoryWeaponView.new(parameters)
	return setmetatable({
		_player = parameters.Player,
		_events = parameters.Events,
		_names = parameters.Names,
		_catalog = parameters.Catalog,
		_templates = parameters.Templates,
		_connections = {},
		_tool = nil,
		_pending = nil,
		_disposed = false,
	}, InventoryWeaponView)
end

function InventoryWeaponView:Init()
	self._unsubscribe = self._events:Subscribe(self._names.WeaponChanged, function(event)
		self:clearTool()
		self._pending = event.ItemId and event or nil
		self:RefreshWeapon()
	end)
	table.insert(
		self._connections,
		self._player.CharacterAdded:Connect(function()
			self:RefreshWeapon()
		end)
	)
	table.insert(
		self._connections,
		self._player.CharacterRemoving:Connect(function()
			self._pending = nil
			self:clearTool()
		end)
	)
end

function InventoryWeaponView:clearTool()
	if self._tool then
		self._tool:Destroy()
		self._tool = nil
	end
end

function InventoryWeaponView:RefreshWeapon()
	local event = self._pending
	local character = self._player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not event or not humanoid or humanoid.Health <= 0 or self._tool then
		return
	end
	local info = self._catalog[event.ItemId]
	local template = self._templates[info.ToolName or event.ItemId]
	if template then
		self._tool = template:Clone()
		self._tool:SetAttribute("ItemUUID", event.UniqueId)
		self._tool.Parent = character
	end
end

function InventoryWeaponView:UpdateLogic(_deltaTime)
	self:RefreshWeapon()
end

function InventoryWeaponView:Dispose()
	if self._disposed then
		return
	end
	self._disposed = true
	if self._unsubscribe then
		self._unsubscribe()
	end
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	self:clearTool()
	self._pending = nil
	self._player = nil
	self._events = nil
	self._templates = nil
end

return InventoryWeaponView
