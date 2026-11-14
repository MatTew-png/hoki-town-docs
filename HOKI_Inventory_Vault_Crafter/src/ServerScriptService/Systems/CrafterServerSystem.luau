--!strict
-- /// <summary>Server composition for CrafterMVC.</summary>
local CrafterServerSystem = {}
CrafterServerSystem.__index = CrafterServerSystem

function CrafterServerSystem.new(parameters)
	return setmetatable({
		Controller = parameters.Controller,
		Gateway = parameters.Gateway,
		Model = parameters.Model,
		Commands = parameters.Commands,
		Events = parameters.Events,
		Started = false,
		Disposed = false,
	}, CrafterServerSystem)
end

function CrafterServerSystem:Init()
	if self.Started or self.Disposed then
		return
	end
	self.Started = true
	self.Controller:Init()
	self.Gateway:Init()
end

function CrafterServerSystem:UpdateLogic(_deltaTime: number)
	if not self.Disposed then
		self.Commands:Pump()
	end
end

function CrafterServerSystem:Dispose()
	if self.Disposed then
		return
	end
	self.Disposed = true
	self.Gateway:Dispose()
	self.Controller:Dispose()
	self.Model:Dispose()
	self.Commands:Dispose()
	self.Events:Dispose()
end

return CrafterServerSystem
