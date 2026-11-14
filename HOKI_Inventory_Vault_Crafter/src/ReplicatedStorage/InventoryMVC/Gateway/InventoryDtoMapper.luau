--[[ <summary>Maps persisted inventory DTOs to validated immutable domain snapshots.</summary> ]]
local InventoryDtoMapper = {}

function InventoryDtoMapper.MapToSnapshot(data, catalog)
	if data == nil then
		data = { Items = {}, Slots = {} }
	end
	assert(
		type(data) == "table" and type(data.Items) == "table" and type(data.Slots) == "table",
		"Invalid saved inventory"
	)
	local revision = data.Revision
	if revision == nil then
		revision = 0
	end
	assert(
		type(revision) == "number" and revision == revision and revision >= 0 and revision % 1 == 0,
		"Invalid inventory revision"
	)
	local items, slots, ids = {}, {}, {}
	local itemCount = 0
	for key in pairs(data.Items) do
		assert(type(key) == "number" and key % 1 == 0 and key >= 1, "Invalid saved item index")
		itemCount += 1
	end
	assert(itemCount == #data.Items, "Sparse saved items would lose data")
	for index, item in ipairs(data.Items) do
		assert(index <= 2000 and type(item) == "table", "Invalid inventory stack")
		local info = catalog[item.ItemID]
		assert(
			info and type(item.UUID) == "string" and #item.UUID > 0 and not ids[item.UUID],
			"Unknown or duplicate saved item"
		)
		assert(
			type(item.Amount) == "number" and item.Amount % 1 == 0 and item.Amount > 0 and item.Amount <= info.MaxStack,
			"Invalid saved amount"
		)
		ids[item.UUID] = true
		items[index] = table.freeze({ UUID = item.UUID, ItemID = item.ItemID, Amount = item.Amount })
	end
	local assigned = {}
	for slot in pairs(data.Slots) do
		assert(type(slot) == "string" and string.match(slot, "^Slot[1-6]$"), "Unknown saved slot")
	end
	for index = 1, 6 do
		local slot = "Slot" .. index
		local id = data.Slots[slot]
		if id ~= nil then
			assert(ids[id] and not assigned[id], "Invalid saved slot")
			slots[slot] = id
			assigned[id] = true
		end
	end
	return table.freeze({ Items = table.freeze(items), Slots = table.freeze(slots), Revision = revision })
end

function InventoryDtoMapper.MapToDto(snapshot)
	local items = {}
	for index, item in ipairs(snapshot.Items) do
		items[index] = { UUID = item.UUID, ItemID = item.ItemID, Amount = item.Amount }
	end
	return { Items = items, Slots = table.clone(snapshot.Slots) }
end

return InventoryDtoMapper
