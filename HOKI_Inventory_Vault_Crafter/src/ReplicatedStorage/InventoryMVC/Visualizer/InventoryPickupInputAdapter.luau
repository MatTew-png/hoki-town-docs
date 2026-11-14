--[[ <summary>Translates authored pickup prompt input to commands and renders pickup cooldown facts.</summary> ]]
local InventoryPickupInputAdapter = {}
InventoryPickupInputAdapter.__index = InventoryPickupInputAdapter

function InventoryPickupInputAdapter.new(parameters)
	return setmetatable({
		_commands = parameters.Commands,
		_events = parameters.Events,
		_pickups = parameters.Pickups,
		_connections = {},
		_subscriptions = {},
		_original = {},
	}, InventoryPickupInputAdapter)
end

function InventoryPickupInputAdapter:Init()
	for id, pickup in pairs(self._pickups) do
		self._original[id] = {
			Transparency = pickup.Part.Transparency,
			CanCollide = pickup.Part.CanCollide,
			Enabled = pickup.Prompt.Enabled,
		}
		table.insert(
			self._connections,
			pickup.Prompt.Triggered:Connect(function(player)
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root then
					self._commands:Enqueue(table.freeze({
						Name = "TriggerInventoryPickupCommand",
						PickupId = id,
						UserId = player.UserId,
						IsAlive = humanoid ~= nil and humanoid.Health > 0,
						Distance = (root.Position - pickup.Part.Position).Magnitude,
					}))
				end
			end)
		)
	end
	table.insert(
		self._subscriptions,
		self._events:Subscribe("InventoryPickupTriggered", function(event)
			local pickup = self._pickups[event.PickupId]
			if pickup.Part.Parent then
				pickup.Part.Transparency = 0.8
				pickup.Part.CanCollide = false
				pickup.Prompt.Enabled = false
			end
		end)
	)
	table.insert(
		self._subscriptions,
		self._events:Subscribe("InventoryPickupRestored", function(event)
			self:RefreshPickup(event.PickupId)
		end)
	)
end

function InventoryPickupInputAdapter:RefreshPickup(id)
	local pickup, original = self._pickups[id], self._original[id]
	if pickup.Part.Parent then
		pickup.Part.Transparency = original.Transparency
		pickup.Part.CanCollide = original.CanCollide
		pickup.Prompt.Enabled = original.Enabled
	end
end

function InventoryPickupInputAdapter:Dispose()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	for _, unsubscribe in ipairs(self._subscriptions) do
		unsubscribe()
	end
	for id in pairs(self._original) do
		self:RefreshPickup(id)
	end
	table.clear(self._connections)
	table.clear(self._subscriptions)
	table.clear(self._original)
	self._pickups = nil
	self._commands = nil
	self._events = nil
end

return InventoryPickupInputAdapter
