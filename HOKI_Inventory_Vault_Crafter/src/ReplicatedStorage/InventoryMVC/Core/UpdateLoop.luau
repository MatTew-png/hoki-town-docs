--[[ <summary>Updates ready systems in creation order under Bootstrap ownership.</summary> ]]
local UpdateLoop = {}
UpdateLoop.__index = UpdateLoop

function UpdateLoop.new(reportError)
	return setmetatable({ _entries = {}, _reportError = reportError }, UpdateLoop)
end

function UpdateLoop:Add(instance)
	local entry = { Instance = instance }
	table.insert(self._entries, entry)
	return function()
		entry.Instance = nil
	end
end

function UpdateLoop:Run(deltaTime)
	local count = #self._entries
	for index = 1, count do
		local instance = self._entries[index].Instance
		if instance then
			local success, message = pcall(instance.UpdateLogic, instance, deltaTime)
			if not success then
				self._reportError(tostring(message))
			end
		end
	end
	for index = #self._entries, 1, -1 do
		if not self._entries[index].Instance then
			table.remove(self._entries, index)
		end
	end
end

return UpdateLoop
