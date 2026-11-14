--[[ <summary>Maps queued client requests to one ordered remote channel and validates returned snapshots.</summary> ]]
local RobloxInventoryClientTransport = {}
RobloxInventoryClientTransport.__index = RobloxInventoryClientTransport

function RobloxInventoryClientTransport.new(parameters)
	return setmetatable({
		_remote = parameters.Remote,
		_commands = parameters.Commands,
		_events = parameters.Events,
		_names = parameters.Names,
		_mapper = parameters.Mapper,
		_catalog = parameters.Catalog,
		_subscriptions = {},
		_sequence = 0,
		_revision = -1,
		_reportError = parameters.ReportError,
		_disposed = false,
	}, RobloxInventoryClientTransport)
end

function RobloxInventoryClientTransport:Init()
	for _, name in ipairs({
		self._names.Request,
		self._names.Move,
		self._names.RemoveSlot,
		self._names.Use,
		self._names.SlideDuringUse,
		self._names.CancelUse,
		self._names.Give,
		self._names.Leave,
	}) do
		table.insert(
			self._subscriptions,
			self._commands:Register(name, function(command)
				self._sequence += 1
				self._remote:FireServer({
					Version = 1,
					Sequence = self._sequence,
					Name = name,
					ItemId = command.ItemId,
					Slot = command.Slot,
					TargetUserId = command.TargetUserId,
					Amount = command.Amount,
				})
			end)
		)
	end
	self._connection = self._remote.OnClientEvent:Connect(function(message)
		if type(message) ~= "table" or message.Version ~= 1 then
			return
		end
		if message.Name == self._names.Changed then
			local payload = message.Payload
			if type(payload) ~= "table" or type(payload.Revision) ~= "number" or payload.Revision < self._revision then
				return
			end
			local success, snapshot = pcall(self._mapper.MapToSnapshot, payload, self._catalog)
			if success then
				self._revision = payload.Revision
				self._commands:Enqueue(table.freeze({ Name = self._names.ReceiveSnapshot, Snapshot = snapshot }))
			else
				self._reportError(tostring(snapshot))
			end
		elseif message.Name == self._names.Rejected and type(message.Payload) == "table" then
			self._commands:Enqueue(
				table.freeze({ Name = self._names.ReceiveRejection, Reason = message.Payload.Reason })
			)
		elseif
			(
				message.Name == self._names.WeaponChanged
				or message.Name == self._names.UseStarted
				or message.Name == self._names.UseFinished
				or message.Name == self._names.InteractionStarted
				or message.Name == self._names.InteractionFinished
			) and type(message.Payload) == "table"
		then
			self._events:Publish(message.Name, message.Payload)
		end
	end)
end

function RobloxInventoryClientTransport:Dispose()
	if self._disposed then
		return
	end
	self._disposed = true
	if self._connection then
		self._connection:Disconnect()
	end
	for _, unsubscribe in ipairs(self._subscriptions) do
		unsubscribe()
	end
	table.clear(self._subscriptions)
	self._remote = nil
	self._events = nil
	self._commands = nil
end

return RobloxInventoryClientTransport
