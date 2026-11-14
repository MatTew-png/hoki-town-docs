--!strict
-- /// <summary>Routes client crafting commands to the server channel and dispatches server events locally.</summary>
local CrafterClientGateway = {}
CrafterClientGateway.__index = CrafterClientGateway

function CrafterClientGateway.new(parameters)
	return setmetatable({
		Channel = parameters.Channel,
		Commands = parameters.Commands,
		Events = parameters.Events,
		Names = parameters.Names,
		Connection = nil,
		Subscriptions = {},
		Disposed = false,
	}, CrafterClientGateway)
end

function CrafterClientGateway:Init()
	local names = self.Names
	for _, cmdName in ipairs({ names.Close, names.Craft, names.Refresh }) do
		table.insert(
			self.Subscriptions,
			self.Commands:Register(cmdName, function(command)
				self.Channel:FireServer({
					Name = cmdName,
					RecipeId = command.RecipeId,
					Quantity = command.Quantity,
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
			or message.Name == names.CraftResult
		then
			self.Events:Publish(message.Name, message.Payload)
		end
	end)
end

function CrafterClientGateway:Dispose()
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

return CrafterClientGateway
