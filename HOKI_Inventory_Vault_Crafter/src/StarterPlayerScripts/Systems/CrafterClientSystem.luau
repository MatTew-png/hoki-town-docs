--!strict
-- /// <summary>Client composition for the standalone CraftingTable UI system.</summary>
local CrafterClientSystem = {}
CrafterClientSystem.__index = CrafterClientSystem

function CrafterClientSystem.new(parameters)
	return setmetatable({
		Commands = parameters.Commands,
		Events = parameters.Events,
		View = parameters.View,
		Gateway = parameters.Gateway,
		Started = false,
		Disposed = false,
	}, CrafterClientSystem)
end

function CrafterClientSystem:Init()
	if self.Started or self.Disposed then
		return
	end
	self.Started = true
	self.Gateway:Init()
	self.View:Init()
end

function CrafterClientSystem:UpdateLogic(_deltaTime: number)
	if not self.Disposed then
		self.Commands:Pump()
	end
end

function CrafterClientSystem:Dispose()
	if self.Disposed then
		return
	end
	self.Disposed = true
	self.View:Dispose()
	self.Gateway:Dispose()
	self.Commands:Dispose()
	self.Events:Dispose()
end

return CrafterClientSystem
