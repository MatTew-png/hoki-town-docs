--[[ <summary>Queues immutable requests for delivery by the Bootstrap frame.</summary> ]]
local CommandQueue = {}
CommandQueue.__index = CommandQueue

function CommandQueue.new(reportError)
	return setmetatable({ _handlers = {}, _pending = {}, _reportError = reportError, _disposed = false }, CommandQueue)
end

function CommandQueue:Init() end

function CommandQueue:Register(commandName, callback)
	assert(not self._handlers[commandName], "Duplicate command handler: " .. commandName)
	self._handlers[commandName] = callback
	return function()
		if self._handlers[commandName] == callback then
			self._handlers[commandName] = nil
		end
	end
end

function CommandQueue:Enqueue(command)
	if self._disposed or #self._pending >= 256 then
		return false
	end
	table.insert(self._pending, command)
	return true
end

function CommandQueue:Pump()
	local pending = self._pending
	self._pending = {}
	for _, command in ipairs(pending) do
		if self._disposed then
			break
		end
		local handler = self._handlers[command.Name]
		if handler then
			local success, message = pcall(handler, command)
			if not success then
				self._reportError(tostring(message))
			end
		end
	end
end

function CommandQueue:Dispose()
	self._disposed = true
	table.clear(self._pending)
	table.clear(self._handlers)
end

return CommandQueue
