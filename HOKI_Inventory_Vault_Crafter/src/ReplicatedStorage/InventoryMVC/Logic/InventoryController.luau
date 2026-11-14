--[[ <summary>Owns authoritative inventory rules using only injected plain data and messaging.</summary> ]]
local InventoryController = {}
InventoryController.__index = InventoryController

local MAX_AMOUNT = 10000
local MAX_STACKS = 2000
local SLOT_COUNT = 6

function InventoryController.new(parameters)
	return setmetatable({
		_model = parameters.Model,
		_commands = parameters.Commands,
		_events = parameters.Events,
		_catalog = parameters.Catalog,
		_names = parameters.Names,
		_createId = parameters.CreateId,
		_canMutate = parameters.CanMutate or function()
			return true
		end,
		_subscriptions = {},
		_disposed = false,
	}, InventoryController)
end

local function isPositiveInteger(amount)
	return type(amount) == "number" and amount == amount and amount > 0 and amount <= MAX_AMOUNT and amount % 1 == 0
end

local function isSlot(slot)
	if type(slot) ~= "string" then
		return false
	end
	for index = 1, SLOT_COUNT do
		if slot == "Slot" .. index then
			return true
		end
	end
	return false
end

function InventoryController:Init()
	local names = self._names
	for _, name in ipairs({
		names.Move,
		names.RemoveSlot,
		names.Use,
		names.Give,
		names.Leave,
		names.Add,
		names.Remove,
		names.Request,
		names.Load,
		names.Character,
	}) do
		table.insert(
			self._subscriptions,
			self._commands:Register(name, function(command)
				self:HandleInventoryCommand(command)
			end)
		)
	end
end

function InventoryController:findItem(id)
	for index, item in ipairs(self._model.Items) do
		if item.UUID == id then
			return item, index
		end
	end
	return nil
end

function InventoryController:PurchaseBundle(currencyItemId, totalCost, bundle)
	if self._disposed or not self._model.IsReady or not self._canMutate() then
		return false, "InventoryUnavailable"
	end
	local currency = self._catalog[currencyItemId]
	if
		not currency
		or currency.Type ~= "Currency"
		or type(totalCost) ~= "number"
		or totalCost ~= totalCost
		or totalCost % 1 ~= 0
		or totalCost < 1
		or totalCost > 2000000
		or type(bundle) ~= "table"
		or #bundle == 0
	then
		return false, "InvalidPurchase"
	end
	local purchased = {}
	local ownedLimits = {}
	for _, loot in ipairs(bundle) do
		local info = type(loot) == "table" and self._catalog[loot.ItemId]
		local maxOwned = type(loot) == "table" and loot.MaxOwned
		if
			not info
			or info.Type == "Weapon"
			or info.Permanent
			or type(loot.Amount) ~= "number"
			or loot.Amount % 1 ~= 0
			or loot.Amount < 1
			or type(maxOwned) ~= "number"
			or maxOwned % 1 ~= 0
			or maxOwned < 1
		then
			return false, "InvalidPurchase"
		end
		purchased[loot.ItemId] = (purchased[loot.ItemId] or 0) + loot.Amount
		ownedLimits[loot.ItemId] = maxOwned
	end
	for _, item in ipairs(self._model.Items) do
		if purchased[item.ItemID] then
			purchased[item.ItemID] += item.Amount
		end
	end
	for itemId, amount in pairs(purchased) do
		if amount > ownedLimits[itemId] then
			return false, "InventoryFull"
		end
	end
	if not self:CanReceiveBundle(bundle) then
		return false, "InventoryFull"
	end
	local balance = 0
	for _, item in ipairs(self._model.Items) do
		if item.ItemID == currencyItemId then
			balance += item.Amount
		end
	end
	if balance < totalCost then
		return false, "InsufficientCash"
	end

	local remainingCost = totalCost
	for index = #self._model.Items, 1, -1 do
		local item = self._model.Items[index]
		if item.ItemID == currencyItemId and remainingCost > 0 then
			local spent = math.min(item.Amount, remainingCost)
			item.Amount -= spent
			remainingCost -= spent
			if item.Amount == 0 then
				self:removeStack(index)
			end
		end
	end
	for _, loot in ipairs(bundle) do
		local remaining = loot.Amount
		local info = self._catalog[loot.ItemId]
		for _, item in ipairs(self._model.Items) do
			if item.ItemID == loot.ItemId and remaining > 0 then
				local added = math.min(remaining, info.MaxStack - item.Amount)
				item.Amount += added
				remaining -= added
			end
		end
		while remaining > 0 do
			local added = math.min(remaining, info.MaxStack)
			table.insert(self._model.Items, { UUID = self._createId(), ItemID = loot.ItemId, Amount = added })
			remaining -= added
		end
	end
	self._model.Revision += 1
	self:publishSnapshot()
	return true
end

function InventoryController:CompleteUse(itemUUID)
	if self._disposed or not self._canMutate() then
		return false
	end
	local item, index = self:findItem(itemUUID)
	local info = item and self._catalog[item.ItemID]
	if not item or not info or not info.UseAction then
		return false
	end
	item.Amount -= 1
	if item.Amount <= 0 then
		self:removeStack(index)
	end
	self._model.Revision += 1
	self:publishSnapshot()
	return true
end

function InventoryController:publishSnapshot()
	self._events:Publish(self._names.Changed, self._model:CreateSnapshot())
end

function InventoryController:rejectRequest(reason)
	self._events:Publish(self._names.Rejected, table.freeze({ Reason = reason }))
end

function InventoryController:clearWeapon()
	if self._model.EquippedId then
		self._model.EquippedId = nil
		self._events:Publish(self._names.WeaponChanged, table.freeze({}))
	end
end

function InventoryController:removeStack(index)
	local item = self._model.Items[index]
	for slot, id in pairs(self._model.Slots) do
		if id == item.UUID then
			self._model.Slots[slot] = nil
		end
	end
	if self._model.EquippedId == item.UUID then
		self:clearWeapon()
	end
	table.remove(self._model.Items, index)
end

function InventoryController:CanReceiveTransferred(itemId, amount)
	local info = self._catalog[itemId]
	if
		not self._canMutate()
		or not info
		or info.Permanent
		or info.Type == "Weapon"
		or not isPositiveInteger(amount)
	then
		return false
	end
	local capacity = (MAX_STACKS - #self._model.Items) * info.MaxStack
	for _, item in ipairs(self._model.Items) do
		if item.ItemID == itemId then
			capacity += info.MaxStack - item.Amount
		end
	end
	return capacity >= amount
end

function InventoryController:CanReceiveBundle(bundle)
	if self._disposed or not self._model.IsReady or type(bundle) ~= "table" or #bundle == 0 then
		return false
	end
	local totals = {}
	for _, loot in ipairs(bundle) do
		if type(loot) ~= "table" or not self:CanReceiveTransferred(loot.ItemId, loot.Amount) then
			return false
		end
		totals[loot.ItemId] = (totals[loot.ItemId] or 0) + loot.Amount
	end
	local newStacks = 0
	for itemId, amount in pairs(totals) do
		local info = self._catalog[itemId]
		local partialSpace = 0
		for _, item in ipairs(self._model.Items) do
			if item.ItemID == itemId then
				partialSpace += info.MaxStack - item.Amount
			end
		end
		newStacks += math.ceil(math.max(0, amount - partialSpace) / info.MaxStack)
	end
	return #self._model.Items + newStacks <= MAX_STACKS
end

function InventoryController:AddBundle(bundle)
	if not self:CanReceiveBundle(bundle) then
		return false
	end
	for _, loot in ipairs(bundle) do
		if not self:AddTransferred(loot.ItemId, loot.Amount) then
			return false
		end
	end
	return true
end

function InventoryController:AddTransferred(itemId, amount)
	if self._disposed or not self:CanReceiveTransferred(itemId, amount) then
		return false
	end
	local info = self._catalog[itemId]
	local remaining = amount
	for _, item in ipairs(self._model.Items) do
		if item.ItemID == itemId and remaining > 0 then
			local moved = math.min(remaining, info.MaxStack - item.Amount)
			item.Amount += moved
			remaining -= moved
		end
	end
	while remaining > 0 do
		local moved = math.min(remaining, info.MaxStack)
		table.insert(self._model.Items, { UUID = self._createId(), ItemID = itemId, Amount = moved })
		remaining -= moved
	end
	self._model.Revision += 1
	self:publishSnapshot()
	return true
end

function InventoryController:RemoveForGive(itemUUID, amount)
	if self._disposed or not isPositiveInteger(amount) then
		return false
	end
	local item, index = self:findItem(itemUUID)
	local info = item and self._catalog[item.ItemID]
	if not item or not info or info.Type == "Weapon" or info.CanGive ~= true or item.Amount < amount then
		return false
	end
	item.Amount -= amount
	if item.Amount <= 0 then
		self:removeStack(index)
	end
	self._model.Revision += 1
	self:publishSnapshot()
	return true
end

function InventoryController:CompleteLeave(itemUUID, amount)
	if self._disposed or not isPositiveInteger(amount) then
		return false
	end
	local item, index = self:findItem(itemUUID)
	local info = item and self._catalog[item.ItemID]
	if
		not item
		or not info
		or info.Type == "Weapon"
		or info.CanLeave ~= true
		or info.Permanent
		or item.Amount < amount
	then
		return false
	end
	item.Amount -= amount
	if item.Amount <= 0 then
		self:removeStack(index)
	end
	self._model.Revision += 1
	self:publishSnapshot()
	return true
end

function InventoryController:GetSnapshot()
	if self._disposed or not self._model.IsReady then
		return nil
	end
	return self._model:CreateSnapshot()
end

function InventoryController:GetItemCount(itemId)
	if self._disposed or not self._model.IsReady or type(itemId) ~= "string" then
		return 0
	end
	local total = 0
	for _, item in ipairs(self._model.Items) do
		if item.ItemID == itemId then
			total += item.Amount
		end
	end
	return total
end

function InventoryController:ExchangeItems(removeList, addList)
	if self._disposed or not self._model.IsReady or not self._canMutate() then
		return false, "InventoryUnavailable"
	end
	if type(removeList) ~= "table" or type(addList) ~= "table" or (#removeList == 0 and #addList == 0) then
		return false, "InvalidExchange"
	end

	local toRemove = {}
	for _, entry in ipairs(removeList) do
		local info = type(entry) == "table" and self._catalog[entry.ItemId]
		local limit = info and math.max(MAX_AMOUNT, info.MaxStack or MAX_AMOUNT) or MAX_AMOUNT
		if
			not info
			or info.Permanent
			or type(entry.Amount) ~= "number"
			or entry.Amount ~= entry.Amount
			or entry.Amount % 1 ~= 0
			or entry.Amount < 1
			or entry.Amount > limit
		then
			return false, "InvalidRemoveItem"
		end
		local nextAmount = (toRemove[entry.ItemId] or 0) + entry.Amount
		if nextAmount > limit * 100 then
			return false, "InvalidRemoveItem"
		end
		toRemove[entry.ItemId] = nextAmount
	end

	local toAdd = {}
	local addOrder = {}
	for _, entry in ipairs(addList) do
		local info = type(entry) == "table" and self._catalog[entry.ItemId]
		local limit = info and math.max(MAX_AMOUNT, info.MaxStack or MAX_AMOUNT) or MAX_AMOUNT
		if
			not info
			or info.Permanent
			or type(entry.Amount) ~= "number"
			or entry.Amount ~= entry.Amount
			or entry.Amount % 1 ~= 0
			or entry.Amount < 1
			or entry.Amount > limit
		then
			return false, "InvalidAddItem"
		end
		if not toAdd[entry.ItemId] then
			table.insert(addOrder, entry.ItemId)
		end
		local nextAmount = (toAdd[entry.ItemId] or 0) + entry.Amount
		if nextAmount > limit * 100 then
			return false, "InvalidAddItem"
		end
		toAdd[entry.ItemId] = nextAmount
	end

	local owned = {}
	for _, item in ipairs(self._model.Items) do
		owned[item.ItemID] = (owned[item.ItemID] or 0) + item.Amount
	end
	for itemId, required in pairs(toRemove) do
		if (owned[itemId] or 0) < required then
			return false, "InsufficientItems"
		end
	end

	local simRemove = table.clone(toRemove)
	local simStacks = {}
	for index = #self._model.Items, 1, -1 do
		local item = self._model.Items[index]
		local rem = simRemove[item.ItemID] or 0
		local take = math.min(item.Amount, rem)
		simRemove[item.ItemID] = rem - take
		local left = item.Amount - take
		if left > 0 then
			table.insert(simStacks, { ItemID = item.ItemID, Amount = left })
		end
	end

	local projectedCount = #simStacks
	for _, itemId in ipairs(addOrder) do
		local info = self._catalog[itemId]
		local remaining = toAdd[itemId]
		for _, stack in ipairs(simStacks) do
			if stack.ItemID == itemId and remaining > 0 then
				local space = info.MaxStack - stack.Amount
				local add = math.min(remaining, space)
				stack.Amount += add
				remaining -= add
			end
		end
		if remaining > 0 then
			projectedCount += math.ceil(remaining / info.MaxStack)
		end
	end
	if projectedCount > MAX_STACKS then
		return false, "InventoryFull"
	end

	for index = #self._model.Items, 1, -1 do
		local item = self._model.Items[index]
		local rem = toRemove[item.ItemID] or 0
		if rem > 0 then
			local take = math.min(item.Amount, rem)
			item.Amount -= take
			toRemove[item.ItemID] = rem - take
			if item.Amount <= 0 then
				self:removeStack(index)
			end
		end
	end

	for _, itemId in ipairs(addOrder) do
		local info = self._catalog[itemId]
		local remaining = toAdd[itemId]
		for _, item in ipairs(self._model.Items) do
			if item.ItemID == itemId and remaining > 0 then
				local moved = math.min(remaining, info.MaxStack - item.Amount)
				item.Amount += moved
				remaining -= moved
			end
		end
		while remaining > 0 do
			local moved = math.min(remaining, info.MaxStack)
			table.insert(self._model.Items, { UUID = self._createId(), ItemID = itemId, Amount = moved })
			remaining -= moved
		end
	end

	self._model.Revision += 1
	self:publishSnapshot()
	return true, nil
end

function InventoryController:HandleInventoryCommand(command)
	if self._disposed then
		return
	end
	local model, names = self._model, self._names
	if command.Name == names.Load then
		if model.IsReady then
			return
		end
		model.Items = {}
		for index, item in ipairs(command.Snapshot.Items) do
			model.Items[index] = table.clone(item)
		end
		model.Slots = table.clone(command.Snapshot.Slots)
		model.IsReady = true
		self._events:Publish(names.Loaded, model:CreateSnapshot())
		self:publishSnapshot()
		return
	end
	if not model.IsReady then
		self:rejectRequest("NotReady")
		return
	end
	if command.Name == names.Request then
		self:publishSnapshot()
		return
	end
	if command.Name == names.Character then
		self:clearWeapon()
		return
	end
	if not self._canMutate() then
		self:rejectRequest("DataUnavailable")
		return
	end
	if command.Name == names.Add or command.Name == names.Remove then
		local info = self._catalog[command.ItemId]
		local amount = command.Amount
		if not info or not isPositiveInteger(amount) then
			self:rejectRequest("InvalidAmount")
			return
		end
		local total, space = 0, 0
		for _, item in ipairs(model.Items) do
			if item.ItemID == command.ItemId then
				total += item.Amount
				space += info.MaxStack - item.Amount
			end
		end
		if command.Name == names.Add then
			if info.Permanent then
				if total > 0 then
					return
				end
				amount = 1
			end
			if #model.Items + math.ceil(math.max(0, amount - space) / info.MaxStack) > MAX_STACKS then
				self:rejectRequest("InventoryFull")
				return
			end
			for _, item in ipairs(model.Items) do
				if item.ItemID == command.ItemId then
					local count = math.min(amount, info.MaxStack - item.Amount)
					item.Amount += count
					amount -= count
				end
			end
			while amount > 0 do
				local count = math.min(amount, info.MaxStack)
				table.insert(model.Items, { UUID = self._createId(), ItemID = command.ItemId, Amount = count })
				amount -= count
			end
		else
			if info.Permanent or total < amount then
				self:rejectRequest("InsufficientItems")
				return
			end
			for index = #model.Items, 1, -1 do
				local item = model.Items[index]
				if item.ItemID == command.ItemId then
					local count = math.min(amount, item.Amount)
					item.Amount -= count
					amount -= count
					if item.Amount == 0 then
						self:removeStack(index)
					end
				end
			end
		end
	elseif command.Name == names.Move then
		if not isSlot(command.Slot) or not self:findItem(command.ItemId) then
			self:rejectRequest("InvalidSlot")
			return
		end
		local previousSlot
		for slot, id in pairs(model.Slots) do
			if id == command.ItemId then
				previousSlot = slot
			end
		end
		if previousSlot then
			model.Slots[previousSlot] = model.Slots[command.Slot]
		end
		model.Slots[command.Slot] = command.ItemId
		local equippedHasSlot = false
		for _, id in pairs(model.Slots) do
			if id == model.EquippedId then
				equippedHasSlot = true
			end
		end
		if not equippedHasSlot then
			self:clearWeapon()
		end
	elseif command.Name == names.RemoveSlot then
		if not isSlot(command.Slot) then
			return
		end
		if model.Slots[command.Slot] == model.EquippedId then
			self:clearWeapon()
		end
		model.Slots[command.Slot] = nil
	elseif command.Name == names.Give or command.Name == names.Leave then
		local item = self:findItem(command.ItemId)
		local info = item and self._catalog[item.ItemID]
		local amount = command.Amount
		local allowed = info
			and info.Type ~= "Weapon"
			and (
				(command.Name == names.Give and info.CanGive == true)
				or (command.Name == names.Leave and info.CanLeave == true and not info.Permanent)
			)
		if not item or not allowed or not isPositiveInteger(amount) or amount > item.Amount then
			self:rejectRequest("InteractionNotAllowed")
			return
		end
		if
			command.Name == names.Give
			and (type(command.TargetUserId) ~= "number" or command.TargetUserId % 1 ~= 0 or command.TargetUserId == 0)
		then
			self:rejectRequest("InvalidTarget")
			return
		end
		local eventName = if command.Name == names.Give then names.GiveRequested else names.LeaveRequested
		self._events:Publish(
			eventName,
			table.freeze({
				ItemUUID = item.UUID,
				ItemId = item.ItemID,
				Amount = amount,
				TargetUserId = command.TargetUserId,
			})
		)
		return
	elseif command.Name == names.Use then
		local item, index = self:findItem(command.ItemId)
		local info = item and self._catalog[item.ItemID]
		if not info then
			return
		end
		if info.UseAction then
			self._events:Publish(
				names.UseRequested,
				table.freeze({
					ItemId = item.ItemID,
					ItemUUID = item.UUID,
					Action = info.UseAction,
				})
			)
			return
		elseif info.Type == "Food" then
			item.Amount -= 1
			if item.Amount == 0 then
				self:removeStack(index)
			end
		elseif info.Type == "Weapon" then
			local hasSlot = false
			for _, id in pairs(model.Slots) do
				if id == item.UUID then
					hasSlot = true
				end
			end
			if not hasSlot then
				self:rejectRequest("WeaponRequiresSlot")
				return
			end
			if model.EquippedId == item.UUID then
				self:clearWeapon()
			else
				model.EquippedId = item.UUID
				self._events:Publish(names.WeaponChanged, table.freeze({ ItemId = item.ItemID, UniqueId = item.UUID }))
			end
		else
			self:rejectRequest("UnsupportedItem")
			return
		end
	else
		return
	end
	model.Revision += 1
	self:publishSnapshot()
end

function InventoryController:Dispose()
	if self._disposed then
		return
	end
	self._disposed = true
	for _, unsubscribe in ipairs(self._subscriptions) do
		unsubscribe()
	end
	table.clear(self._subscriptions)
	self._model = nil
	self._commands = nil
	self._events = nil
	self._catalog = nil
	self._createId = nil
	self._canMutate = nil
end

return InventoryController
