--[[ <summary>Delivers authoritative inventory snapshots and rejection facts on the client command tick.</summary> ]]
local InventorySnapshotController = {}
InventorySnapshotController.__index = InventorySnapshotController

function InventorySnapshotController.new(parameters)
	return setmetatable(
		{ _commands = parameters.Commands, _events = parameters.Events, _names = parameters.Names, _subscriptions = {} },
		InventorySnapshotController
	)
end

function InventorySnapshotController:Init()
	table.insert(
		self._subscriptions,
		self._commands:Register(self._names.ReceiveSnapshot, function(command)
			self._events:Publish(self._names.Changed, command.Snapshot)
		end)
	)
	table.insert(
		self._subscriptions,
		self._commands:Register(self._names.ReceiveRejection, function(command)
			self._events:Publish(self._names.Rejected, table.freeze({ Reason = command.Reason }))
		end)
	)
end

function InventorySnapshotController:Dispose()
	for _, unsubscribe in ipairs(self._subscriptions) do
		unsubscribe()
	end
	table.clear(self._subscriptions)
	self._commands = nil
	self._events = nil
end

return InventorySnapshotController
