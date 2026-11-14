--!strict
-- /// <summary>Stores active vault sessions and per-player vault stack state.</summary>
local VaultModel = {}
VaultModel.__index = VaultModel

function VaultModel.new()
	return setmetatable({
		Sessions = {},
		VaultData = {},
	}, VaultModel)
end

function VaultModel:Dispose()
	table.clear(self.Sessions)
	table.clear(self.VaultData)
end

return VaultModel
