--[[ <summary>Validates pickup distance and cooldown before emitting trusted inventory grant requests.</summary> ]]
local InventoryPickupController = {}
InventoryPickupController.__index = InventoryPickupController
local COOLDOWN_SECONDS = 5

function InventoryPickupController.new(parameters)
	local remaining = {}
	for id in pairs(parameters.Pickups) do
		remaining[id] = 0
	end
	return setmetatable({
		_commands = parameters.Commands,
		_events = parameters.Events,
		_pickups = parameters.Pickups,
		_remaining = remaining,
	}, InventoryPickupController)
end

function InventoryPickupController:Init()
	self._unsubscribe = self._commands:Register("TriggerInventoryPickupCommand", function(command)
		local pickup = self._pickups[command.PickupId]
		if
			not pickup
			or self._remaining[command.PickupId] > 0
			or not command.IsAlive
			or command.Distance > pickup.MaximumDistance
		then
			return
		end
		self._remaining[command.PickupId] = COOLDOWN_SECONDS
		self._events:Publish(
			"InventoryPickupTriggered",
			table.freeze({
				PickupId = command.PickupId,
				UserId = command.UserId,
				Action = pickup.Action,
				Items = pickup.Items,
			})
		)
	end)
end

function InventoryPickupController:UpdateLogic(deltaTime)
	for id, remaining in pairs(self._remaining) do
		if remaining > 0 then
			self._remaining[id] = math.max(0, remaining - deltaTime)
			if self._remaining[id] == 0 then
				self._events:Publish("InventoryPickupRestored", table.freeze({ PickupId = id }))
			end
		end
	end
end

function InventoryPickupController:Dispose()
	if self._unsubscribe then
		self._unsubscribe()
		self._unsubscribe = nil
	end
	table.clear(self._remaining)
	self._commands = nil
	self._events = nil
	self._pickups = nil
end

return InventoryPickupController
