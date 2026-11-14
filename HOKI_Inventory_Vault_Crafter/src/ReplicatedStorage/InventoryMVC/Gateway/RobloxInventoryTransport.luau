--[[ <summary>Validates Roblox inventory messages and maps them to queued domain requests.</summary> ]]
local RunService = game:GetService("RunService")
local RobloxInventoryTransport = {}
RobloxInventoryTransport.__index = RobloxInventoryTransport

function RobloxInventoryTransport.new(parameters)
	return setmetatable(
		{ _remote = parameters.Remote, _names = parameters.Names, _sessions = {}, _connection = nil, _disposed = false },
		RobloxInventoryTransport
	)
end

function RobloxInventoryTransport:Init()
	self._connection = self._remote.OnServerEvent:Connect(function(player, message)
		local session = self._sessions[player.UserId]
		if not session or session.Budget <= 0 or type(message) ~= "table" or message.Version ~= 1 then
			return
		end
		session.Budget -= 1
		local names = self._names
		local name = message.Name
		if
			name ~= names.Request
			and name ~= names.Move
			and name ~= names.RemoveSlot
			and name ~= names.Use
			and name ~= names.SlideDuringUse
			and name ~= names.CancelUse
			and name ~= names.Give
			and name ~= names.Leave
		then
			return
		end
		if
			(name == names.Move or name == names.Use or name == names.Give or name == names.Leave)
			and (type(message.ItemId) ~= "string" or #message.ItemId > 128)
		then
			return
		end
		if
			(name == names.Move or name == names.RemoveSlot)
			and (type(message.Slot) ~= "string" or not string.match(message.Slot, "^Slot[1-6]$"))
		then
			return
		end
		if
			type(message.Sequence) ~= "number"
			or message.Sequence % 1 ~= 0
			or message.Sequence <= session.Sequence
			or message.Sequence > 9007199254740991
		then
			return
		end
		if
			(name == names.Give or name == names.Leave)
			and (
				type(message.Amount) ~= "number"
				or message.Amount % 1 ~= 0
				or message.Amount < 1
				or message.Amount > 10000
			)
		then
			return
		end
		if
			name == names.Give
			and (
				type(message.TargetUserId) ~= "number"
				or message.TargetUserId % 1 ~= 0
				or message.TargetUserId == 0
				or (message.TargetUserId < 0 and not RunService:IsStudio())
			)
		then
			return
		end
		session.Sequence = message.Sequence
		if name == names.SlideDuringUse then
			session.Events:Publish(names.SlideDuringUseRequested, table.freeze({ UserId = player.UserId }))
			return
		end
		if name == names.CancelUse then
			session.Events:Publish(names.CancelUseRequested, table.freeze({ UserId = player.UserId }))
			return
		end
		session.Commands:Enqueue(table.freeze({
			Name = name,
			ItemId = message.ItemId,
			Slot = message.Slot,
			TargetUserId = message.TargetUserId,
			Amount = message.Amount,
		}))
	end)
end

function RobloxInventoryTransport:AttachSession(player, commands, events)
	local session = { Commands = commands, Events = events, Budget = 30, Sequence = 0, Subscriptions = {} }
	self._sessions[player.UserId] = session
	for _, name in ipairs({
		self._names.Changed,
		self._names.Rejected,
		self._names.WeaponChanged,
		self._names.UseStarted,
		self._names.UseFinished,
		self._names.InteractionStarted,
		self._names.InteractionFinished,
	}) do
		table.insert(
			session.Subscriptions,
			events:Subscribe(name, function(event)
				if player.Parent then
					self._remote:FireClient(player, { Version = 1, Name = name, Payload = event })
				end
			end)
		)
	end
end

function RobloxInventoryTransport:DetachSession(userId)
	local session = self._sessions[userId]
	if session then
		for _, unsubscribe in ipairs(session.Subscriptions) do
			unsubscribe()
		end
		self._sessions[userId] = nil
	end
end

function RobloxInventoryTransport:UpdateLogic(deltaTime)
	for _, session in pairs(self._sessions) do
		session.Budget = math.min(30, session.Budget + deltaTime * 15)
	end
end

function RobloxInventoryTransport:Dispose()
	if self._disposed then
		return
	end
	self._disposed = true
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
	for userId in pairs(self._sessions) do
		self:DetachSession(userId)
	end
	self._remote = nil
end

return RobloxInventoryTransport
