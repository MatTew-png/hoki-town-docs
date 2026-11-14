--!strict
-- /// <summary>Stores active player crafting station sessions.</summary>
local CrafterModel = {}
CrafterModel.__index = CrafterModel

function CrafterModel.new()
	return setmetatable({
		Sessions = {},
	}, CrafterModel)
end

function CrafterModel:Dispose()
	table.clear(self.Sessions)
end

return CrafterModel
