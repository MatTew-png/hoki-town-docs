--[[ <summary>Stores session inventory state and produces detached immutable snapshots.</summary> ]]
local InventoryModel = {}
InventoryModel.__index = InventoryModel

function InventoryModel.new()
	return setmetatable({ Items = {}, Slots = {}, EquippedId = nil, IsReady = false, Revision = 0 }, InventoryModel)
end

function InventoryModel:CreateSnapshot()
	local items = {}
	for index, item in ipairs(self.Items) do
		items[index] = table.freeze(table.clone(item))
	end
	return table.freeze({
		Items = table.freeze(items),
		Slots = table.freeze(table.clone(self.Slots)),
		Revision = self.Revision,
	})
end

function InventoryModel:Dispose()
	table.clear(self.Items)
	table.clear(self.Slots)
	self.EquippedId = nil
	self.IsReady = false
end

return InventoryModel
