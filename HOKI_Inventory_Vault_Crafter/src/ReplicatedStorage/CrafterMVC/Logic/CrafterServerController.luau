--!strict
-- /// <summary>Validates crafting recipes and executes atomic ingredient-to-output inventory exchanges.</summary>
local CrafterServerController = {}
CrafterServerController.__index = CrafterServerController

function CrafterServerController.new(parameters)
	return setmetatable({
		Model = parameters.Model,
		Commands = parameters.Commands,
		Events = parameters.Events,
		Names = parameters.Names,
		Config = parameters.Config,
		Catalog = parameters.Catalog,
		GetBackpackItems = parameters.GetBackpackItems,
		ExchangeInventory = parameters.ExchangeInventory,
		Subscriptions = {},
		Disposed = false,
	}, CrafterServerController)
end

function CrafterServerController:buildStatePayload(userId: number, session)
	local station = self.Config.Stations[session.StationId]
	local backpackItems = self.GetBackpackItems(userId) or {}
	local counts = {}
	for _, stack in ipairs(backpackItems) do
		if type(stack.ItemID) == "string" and type(stack.Amount) == "number" then
			counts[stack.ItemID] = (counts[stack.ItemID] or 0) + stack.Amount
		end
	end
	return table.freeze({
		UserId = userId,
		StationId = session.StationId,
		SessionId = session.SessionId,
		DisplayName = station and station.DisplayName or "CRAFTING TABLE",
		ItemCounts = counts,
	})
end

function CrafterServerController:publishResult(
	userId: number,
	sessionId: string?,
	succeeded: boolean,
	reason: string?,
	recipeId: string?
)
	self.Events:Publish(
		self.Names.CraftResult,
		table.freeze({
			UserId = userId,
			SessionId = sessionId,
			Succeeded = succeeded == true,
			Reason = reason,
			RecipeId = recipeId,
		})
	)
end

function CrafterServerController:findRecipe(stationId: string, recipeId: string)
	local station = self.Config.Stations[stationId]
	if not station then
		return nil
	end
	for _, recipe in ipairs(station.Recipes) do
		if recipe.RecipeId == recipeId then
			return recipe
		end
	end
	return nil
end

function CrafterServerController:open(command)
	if not self.Config.Stations[command.StationId] then
		return
	end
	local session = {
		StationId = command.StationId,
		SessionId = command.SessionId,
	}
	self.Model.Sessions[command.UserId] = session
	local payload = self:buildStatePayload(command.UserId, session)
	self.Events:Publish(self.Names.Opened, payload)
	self.Events:Publish(self.Names.StateChanged, payload)
end

function CrafterServerController:close(command)
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

function CrafterServerController:refresh(command)
	local session = self.Model.Sessions[command.UserId]
	if not session then
		return
	end
	self.Events:Publish(self.Names.StateChanged, self:buildStatePayload(command.UserId, session))
end

function CrafterServerController:craft(command)
	local session = self.Model.Sessions[command.UserId]
	if not session or (command.SessionId and session.SessionId ~= command.SessionId) then
		self:publishResult(command.UserId, command.SessionId, false, "CrafterClosed", command.RecipeId)
		return
	end
	if type(command.RecipeId) ~= "string" then
		self:publishResult(command.UserId, session.SessionId, false, "InvalidRecipe", nil)
		return
	end
	local recipe = self:findRecipe(session.StationId, command.RecipeId)
	if not recipe or not self.Catalog[recipe.OutputItemId] then
		self:publishResult(command.UserId, session.SessionId, false, "InvalidRecipe", command.RecipeId)
		return
	end

	local quantity = command.Quantity
	if
		type(quantity) ~= "number"
		or quantity ~= quantity
		or quantity % 1 ~= 0
		or quantity < 1
		or quantity > self.Config.MaxCraftQuantity
	then
		self:publishResult(command.UserId, session.SessionId, false, "InvalidQuantity", recipe.RecipeId)
		return
	end

	local removeList = {}
	for _, ing in ipairs(recipe.Ingredients) do
		table.insert(removeList, {
			ItemId = ing.ItemId,
			Amount = ing.Amount * quantity,
		})
	end
	local addList = {
		{
			ItemId = recipe.OutputItemId,
			Amount = recipe.OutputAmount * quantity,
		},
	}

	local succeeded, reason = self.ExchangeInventory(command.UserId, removeList, addList)
	self:publishResult(
		command.UserId,
		session.SessionId,
		succeeded,
		reason or (succeeded and "Crafted" or "CraftFailed"),
		recipe.RecipeId
	)
	if succeeded then
		self.Events:Publish(self.Names.StateChanged, self:buildStatePayload(command.UserId, session))
	end
end

function CrafterServerController:Init()
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
		[names.Craft] = function(cmd)
			self:craft(cmd)
		end,
	}) do
		table.insert(self.Subscriptions, self.Commands:Register(name, callback))
	end
end

function CrafterServerController:Dispose()
	if self.Disposed then
		return
	end
	self.Disposed = true
	for _, unsub in ipairs(self.Subscriptions) do
		unsub()
	end
	table.clear(self.Subscriptions)
	self.Model = nil
	self.Commands = nil
	self.Events = nil
end

return CrafterServerController
