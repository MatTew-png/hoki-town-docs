--[[ <summary>Delivers engine-free facts to scoped subscribers.</summary> ]]
local EventBus = {}
EventBus.__index = EventBus

function EventBus.new(reportError)
	return setmetatable({ _listeners = {}, _reportError = reportError, _disposed = false }, EventBus)
end

function EventBus:Init() end

function EventBus:Subscribe(eventName, callback)
	assert(not self._disposed, "EventBus disposed")
	local listeners = self._listeners[eventName]
	if not listeners then
		listeners = {}
		self._listeners[eventName] = listeners
	end
	local entry = { Callback = callback }
	table.insert(listeners, entry)
	return function()
		entry.Callback = nil
		local index = table.find(listeners, entry)
		if index then
			table.remove(listeners, index)
		end
	end
end

function EventBus:Publish(eventName, event)
	if self._disposed then
		return
	end
	local listeners = self._listeners[eventName]
	if not listeners then
		return
	end
	for _, entry in ipairs(table.clone(listeners)) do
		if entry.Callback then
			local success, message = pcall(entry.Callback, event)
			if not success then
				self._reportError(tostring(message))
			end
		end
	end
end

function EventBus:Dispose()
	self._disposed = true
	for _, listeners in pairs(self._listeners) do
		for _, entry in ipairs(listeners) do
			entry.Callback = nil
		end
	end
	table.clear(self._listeners)
end

return EventBus
