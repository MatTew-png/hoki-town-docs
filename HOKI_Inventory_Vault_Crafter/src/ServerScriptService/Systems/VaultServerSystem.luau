--!strict
-- /// <summary>Server composition for VaultMVC, registering Vault persistence with DataManager.</summary>
local VaultServerSystem = {}
VaultServerSystem.__index = VaultServerSystem

function VaultServerSystem.new(parameters)
	return setmetatable({
		Controller = parameters.Controller,
		Gateway = parameters.Gateway,
		Model = parameters.Model,
		Commands = parameters.Commands,
		Events = parameters.Events,
		Started = false,
		Disposed = false,
	}, VaultServerSystem)
end

function VaultServerSystem:Init()
	if self.Started or self.Disposed then
		return
	end
	self.Started = true
	self.Controller:Init()
	self.Gateway:Init()
end

function VaultServerSystem:UpdateLogic(_deltaTime: number)
	if not self.Disposed then
		self.Commands:Pump()
	end
end

function VaultServerSystem:Dispose()
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

return VaultServerSystem
