--[[ <summary>Turns authoritative inventory snapshots into quantity change facts for client presentation.</summary> ]]
local InventoryQuantityController = {}
InventoryQuantityController.__index = InventoryQuantityController

function InventoryQuantityController.new(parameters)
	return setmetatable({
		_events = parameters.Events,
		_names = parameters.Names,
		_previousTotals = nil,
		_lastRevision = nil,
		_unsubscribe = nil,
		_disposed = false,
	}, InventoryQuantityController)
end

local function countItems(snapshot)
	local totals = {}
	for _, item in ipairs(snapshot.Items) do
		if type(item.ItemID) == "string" and type(item.Amount) == "number" and item.Amount > 0 then
			totals[item.ItemID] = (totals[item.ItemID] or 0) + item.Amount
		end
	end
	return totals
end

function InventoryQuantityController:OnInventoryChanged(snapshot)
	if
		self._disposed
		or type(snapshot) ~= "table"
		or type(snapshot.Items) ~= "table"
		or type(snapshot.Revision) ~= "number"
	then
		return
	end
	if self._lastRevision and snapshot.Revision <= self._lastRevision then
		return
	end

	local currentTotals = countItems(snapshot)
	local previousTotals = self._previousTotals
	self._previousTotals = currentTotals
	self._lastRevision = snapshot.Revision
	if not previousTotals then
		return
	end

	local itemIds, seen = {}, {}
	for itemId in pairs(previousTotals) do
		seen[itemId] = true
		table.insert(itemIds, itemId)
	end
	for itemId in pairs(currentTotals) do
		if not seen[itemId] then
			table.insert(itemIds, itemId)
		end
	end
	table.sort(itemIds)
	for _, itemId in ipairs(itemIds) do
		local delta = (currentTotals[itemId] or 0) - (previousTotals[itemId] or 0)
		if delta ~= 0 then
			self._events:Publish(
				self._names.QuantityChanged,
				table.freeze({
					ItemId = itemId,
					Delta = delta,
					Revision = snapshot.Revision,
				})
			)
		end
	end
end

function InventoryQuantityController:Init()
	self._unsubscribe = self._events:Subscribe(self._names.Changed, function(snapshot)
		self:OnInventoryChanged(snapshot)
	end)
end

function InventoryQuantityController:Dispose()
	if self._disposed then
		return
	end
	self._disposed = true
	if self._unsubscribe then
		self._unsubscribe()
		self._unsubscribe = nil
	end
	self._previousTotals = nil
	self._events = nil
	self._names = nil
end

return InventoryQuantityController
