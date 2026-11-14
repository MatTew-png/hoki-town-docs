--!strict
-- /// <summary>Routes client vault commands to the server channel and dispatches server events locally.</summary>
local VaultClientGateway = {}
VaultClientGateway.__index = VaultClientGateway

function VaultClientGateway.new(parameters)
	return setmetatable({
		Channel = parameters.Channel,
		Commands = parameters.Commands,
		Events = parameters.Events,
		Names = parameters.Names,
		Connection = nil,
		Subscriptions = {},
		Disposed = false,
	}, VaultClientGateway)
end

function VaultClientGateway:Init()
	local names = self.Names
	for _, cmdName in ipairs({ names.Close, names.Deposit, names.Withdraw, names.Refresh }) do
		table.insert(
			self.Subscriptions,
			self.Commands:Register(cmdName, function(command)
				self.Channel:FireServer({
					Name = cmdName,
					ItemId = command.ItemId,
					Amount = command.Amount,
				})
			end)
		)
	end

	self.Connection = self.Channel.OnClientEvent:Connect(function(message)
		if self.Disposed or type(message) ~= "table" or type(message.Payload) ~= "table" then
			return
		end
		if
			message.Name == names.Opened
			or message.Name == names.Closed
			or message.Name == names.StateChanged
			or message.Name == names.TransferResult
		then
			self.Events:Publish(message.Name, message.Payload)
		end
	end)
end

function VaultClientGateway:Dispose()
	if self.Disposed then
		return
	end
	self.Disposed = true
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
	for _, unsub in ipairs(self.Subscriptions) do
		unsub()
	end
	table.clear(self.Subscriptions)
end

return VaultClientGateway
