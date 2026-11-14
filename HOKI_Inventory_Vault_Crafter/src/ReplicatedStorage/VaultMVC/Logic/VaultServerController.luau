--!strict
-- /// <summary>Validates vault deposit/withdraw commands and coordinates atomic inventory exchanges.</summary>
local VaultServerController = {}
VaultServerController.__index = VaultServerController

local function isPositiveInteger(value: any, maxValue: number): boolean
	return type(value) == "number" and value == value and value > 0 and value <= maxValue and value % 1 == 0
end

function VaultServerController.new(parameters)
	return setmetatable({
		Model = parameters.Model,
		Commands = parameters.Commands,
		Events = parameters.Events,
		Names = parameters.Names,
		Config = parameters.Config,
		Catalog = parameters.Catalog,
		GetVaultItems = parameters.GetVaultItems,
		SaveVaultItems = parameters.SaveVaultItems,
		GetBackpackItems = parameters.GetBackpackItems,
		ExchangeInventory = parameters.ExchangeInventory,
		Subscriptions = {},
		Disposed = false,
	}, VaultServerController)
end

function VaultServerController:buildStatePayload(userId: number, session)
	local vaultStacks = self.GetVaultItems(userId) or {}
	local backpackStacks = self.GetBackpackItems(userId) or {}
	local vaultConfig = self.Config.Vaults[session.VaultId]
	return table.freeze({
		UserId = userId,
		VaultId = session.VaultId,
		SessionId = session.SessionId,
		DisplayName = vaultConfig and vaultConfig.DisplayName or "VAULT",
		MaxStacks = vaultConfig and vaultConfig.MaxStacks or self.Config.MaxVaultStacks,
		VaultItems = vaultStacks,
		BackpackItems = backpackStacks,
	})
end

function VaultServerController:publishResult(userId: number, sessionId: string?, succeeded: boolean, reason: string?)
	self.Events:Publish(
		self.Names.TransferResult,
		table.freeze({
			UserId = userId,
			SessionId = sessionId,
			Succeeded = succeeded == true,
			Reason = reason,
		})
	)
end

function VaultServerController:open(command)
	local vaultConfig = self.Config.Vaults[command.VaultId]
	if not vaultConfig then
		return
	end
	local session = {
		VaultId = command.VaultId,
		SessionId = command.SessionId,
	}
	self.Model.Sessions[command.UserId] = session
	local payload = self:buildStatePayload(command.UserId, session)
	self.Events:Publish(self.Names.Opened, payload)
	self.Events:Publish(self.Names.StateChanged, payload)
end

function VaultServerController:close(command)
	local session = self.Model.Sessions[command.UserId]
	if not session or (command.SessionId and session.SessionId ~= command.SessionId) then
		return
	end
	self.Model.Sessions[command.UserId] = nil
	self.Events:Publish(
		self.Names.Closed,
		table.freeze({
			UserId = command.UserId,
			SessionId = session.SessionId,
		})
	)
end

function VaultServerController:refresh(command)
	local session = self.Model.Sessions[command.UserId]
	if not session then
		return
	end
	self.Events:Publish(self.Names.StateChanged, self:buildStatePayload(command.UserId, session))
end

function VaultServerController:deposit(command)
	local session = self.Model.Sessions[command.UserId]
	if not session or (command.SessionId and session.SessionId ~= command.SessionId) then
		self:publishResult(command.UserId, command.SessionId, false, "VaultClosed")
		return
	end
	local itemId = command.ItemId
	local amount = command.Amount
	local info = type(itemId) == "string" and self.Catalog[itemId]
	local transferLimit = info
			and math.max(self.Config.MaxTransferAmount, info.MaxStack or self.Config.MaxTransferAmount)
		or self.Config.MaxTransferAmount
	if not info or info.Permanent or not isPositiveInteger(amount, transferLimit) then
		self:publishResult(command.UserId, session.SessionId, false, "InvalidItem")
		return
	end

	local vaultItems = self.GetVaultItems(command.UserId)
	if type(vaultItems) ~= "table" then
		self:publishResult(command.UserId, session.SessionId, false, "VaultUnavailable")
		return
	end

	local vaultConfig = self.Config.Vaults[session.VaultId]
	local maxStacks = (vaultConfig and vaultConfig.MaxStacks) or self.Config.MaxVaultStacks
	local partialSpace = 0
	for _, stack in ipairs(vaultItems) do
		if stack.ItemID == itemId then
			partialSpace += math.max(0, info.MaxStack - stack.Amount)
		end
	end
	local neededNewStacks = math.ceil(math.max(0, amount - partialSpace) / info.MaxStack)
	if #vaultItems + neededNewStacks > maxStacks then
		self:publishResult(command.UserId, session.SessionId, false, "VaultFull")
		return
	end

	local exchanged, reason = self.ExchangeInventory(command.UserId, { { ItemId = itemId, Amount = amount } }, {})
	if not exchanged then
		self:publishResult(command.UserId, session.SessionId, false, reason or "InsufficientItems")
		return
	end

	local updatedVault = {}
	for i, stack in ipairs(vaultItems) do
		updatedVault[i] = { ItemID = stack.ItemID, Amount = stack.Amount }
	end
	local remaining = amount
	for _, stack in ipairs(updatedVault) do
		if stack.ItemID == itemId and remaining > 0 then
			local add = math.min(remaining, info.MaxStack - stack.Amount)
			stack.Amount += add
			remaining -= add
		end
	end
	while remaining > 0 do
		local add = math.min(remaining, info.MaxStack)
		table.insert(updatedVault, { ItemID = itemId, Amount = add })
		remaining -= add
	end

	self.SaveVaultItems(command.UserId, updatedVault)
	self:publishResult(command.UserId, session.SessionId, true, "Deposited")
	self.Events:Publish(self.Names.StateChanged, self:buildStatePayload(command.UserId, session))
end

function VaultServerController:withdraw(command)
	local session = self.Model.Sessions[command.UserId]
	if not session or (command.SessionId and session.SessionId ~= command.SessionId) then
		self:publishResult(command.UserId, command.SessionId, false, "VaultClosed")
		return
	end
	local itemId = command.ItemId
	local amount = command.Amount
	local info = type(itemId) == "string" and self.Catalog[itemId]
	local transferLimit = info
			and math.max(self.Config.MaxTransferAmount, info.MaxStack or self.Config.MaxTransferAmount)
		or self.Config.MaxTransferAmount
	if not info or info.Permanent or not isPositiveInteger(amount, transferLimit) then
		self:publishResult(command.UserId, session.SessionId, false, "InvalidItem")
		return
	end

	local vaultItems = self.GetVaultItems(command.UserId)
	if type(vaultItems) ~= "table" then
		self:publishResult(command.UserId, session.SessionId, false, "VaultUnavailable")
		return
	end

	local totalInVault = 0
	for _, stack in ipairs(vaultItems) do
		if stack.ItemID == itemId then
			totalInVault += stack.Amount
		end
	end
	if totalInVault < amount then
		self:publishResult(command.UserId, session.SessionId, false, "InsufficientVaultItems")
		return
	end

	local exchanged, reason = self.ExchangeInventory(command.UserId, {}, { { ItemId = itemId, Amount = amount } })
	if not exchanged then
		self:publishResult(command.UserId, session.SessionId, false, reason or "InventoryFull")
		return
	end

	local updatedVault = {}
	for i, stack in ipairs(vaultItems) do
		updatedVault[i] = { ItemID = stack.ItemID, Amount = stack.Amount }
	end
	local remaining = amount
	for index = #updatedVault, 1, -1 do
		local stack = updatedVault[index]
		if stack.ItemID == itemId and remaining > 0 then
			local take = math.min(stack.Amount, remaining)
			stack.Amount -= take
			remaining -= take
			if stack.Amount <= 0 then
				table.remove(updatedVault, index)
			end
		end
	end

	self.SaveVaultItems(command.UserId, updatedVault)
	self:publishResult(command.UserId, session.SessionId, true, "Withdrawn")
	self.Events:Publish(self.Names.StateChanged, self:buildStatePayload(command.UserId, session))
end

function VaultServerController:Init()
	local names = self.Names
	for name, callback in pairs({
		[names.Open] = function(cmd)
			self:open(cmd)
		end,
		[names.Close] = function(cmd)
			self:close(cmd)
		end,
		[names.Refresh] = function(cmd)
			self:refresh(cmd)
		end,
		[names.Deposit] = function(cmd)
			self:deposit(cmd)
		end,
		[names.Withdraw] = function(cmd)
			self:withdraw(cmd)
		end,
	}) do
		table.insert(self.Subscriptions, self.Commands:Register(name, callback))
	end
end

function VaultServerController:Dispose()
	if self.Disposed then
		return
	end
	self.Disposed = true
	for _, unsubscribe in ipairs(self.Subscriptions) do
		unsubscribe()
	end
	table.clear(self.Subscriptions)
	self.Model = nil
	self.Commands = nil
	self.Events = nil
end

return VaultServerController
