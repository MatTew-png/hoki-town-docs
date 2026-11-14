--!strict
-- /// <summary>Client composition for the standalone Vault UI system.</summary>
local VaultClientSystem = {}
VaultClientSystem.__index = VaultClientSystem

function VaultClientSystem.new(parameters)
	return setmetatable({
		Commands = parameters.Commands,
		Events = parameters.Events,
		View = parameters.View,
		Gateway = parameters.Gateway,
		Started = false,
		Disposed = false,
	}, VaultClientSystem)
end

function VaultClientSystem:Init()
	if self.Started or self.Disposed then
		return
	end
	self.Started = true
	self.Gateway:Init()
	self.View:Init()
end

function VaultClientSystem:UpdateLogic(_deltaTime: number)
	if not self.Disposed then
		self.Commands:Pump()
	end
end

function VaultClientSystem:Dispose()
	if self.Disposed then
		return
	end
	self.Disposed = true
	self.View:Dispose()
	self.Gateway:Dispose()
	self.Commands:Dispose()
	self.Events:Dispose()
end

return VaultClientSystem
