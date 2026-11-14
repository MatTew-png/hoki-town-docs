--!strict
-- /// <summary>Renders the standalone Dark/Gold CraftingTable UI with recipe cards and live material requirements.</summary>
local CrafterView = {}
CrafterView.__index = CrafterView

function CrafterView.new(parameters)
	return setmetatable({
		Gui = parameters.Gui,
		Commands = parameters.Commands,
		Events = parameters.Events,
		Names = parameters.Names,
		Config = parameters.Config,
		Catalog = parameters.Catalog,
		UserInputService = parameters.UserInputService,
		Connections = {},
		DynamicConnections = {},
		Subscriptions = {},
		RecipeCards = {},
		IngredientCards = {},
		State = nil,
		SelectedRecipeId = nil,
		Category = "All",
		CraftQuantity = 1,
		IsOpen = false,
		Disposed = false,
	}, CrafterView)
end

function CrafterView:clearDynamic()
	for _, conn in ipairs(self.DynamicConnections) do
		conn:Disconnect()
	end
	table.clear(self.DynamicConnections)
	for _, card in ipairs(self.RecipeCards) do
		card:Destroy()
	end
	for _, card in ipairs(self.IngredientCards) do
		card:Destroy()
	end
	table.clear(self.RecipeCards)
	table.clear(self.IngredientCards)
end

function CrafterView:getMaxCraftable(recipe): number
	local counts = (self.State and self.State.ItemCounts) or {}
	local maxPossible = self.Config.MaxCraftQuantity
	for _, ing in ipairs(recipe.Ingredients) do
		local owned = counts[ing.ItemId] or 0
		local possibleForIng = math.floor(owned / math.max(1, ing.Amount))
		maxPossible = math.min(maxPossible, possibleForIng)
	end
	return math.max(0, maxPossible)
end

function CrafterView:render()
	local main = self.Gui:FindFirstChild("Frame") :: Frame?
	if not main or not self.State then
		return
	end
	self:clearDynamic()

	local station = self.Config.Stations[self.State.StationId or "General"] or self.Config.Stations.General
	if not station then
		return
	end

	local header = main:FindFirstChild("Header")
	local titleLabel = header and header:FindFirstChild("Title") :: TextLabel?
	if titleLabel then
		titleLabel.Text = self.State.DisplayName or station.DisplayName
	end

	local recipePanel = main:FindFirstChild("RecipePanel")
	local recipeScroll = recipePanel and recipePanel:FindFirstChild("RecipeScroll") :: ScrollingFrame?
	local recipeTemplate = main:FindFirstChild("RecipeCardTemplate") :: GuiObject?

	local detailPanel = main:FindFirstChild("DetailPanel")
	local ingScroll = detailPanel and detailPanel:FindFirstChild("IngredientScroll") :: ScrollingFrame?
	local ingTemplate = main:FindFirstChild("IngredientRowTemplate") :: GuiObject?

	local selectedRecipe = nil
	local visibleRecipes = {}
	for _, recipe in ipairs(station.Recipes) do
		if self.Category == "All" or recipe.Category == self.Category then
			table.insert(visibleRecipes, recipe)
			if recipe.RecipeId == self.SelectedRecipeId then
				selectedRecipe = recipe
			end
		end
	end
	if not selectedRecipe and #visibleRecipes > 0 then
		selectedRecipe = visibleRecipes[1]
		self.SelectedRecipeId = selectedRecipe.RecipeId
	end

	if recipeTemplate and recipeScroll then
		for idx, recipe in ipairs(visibleRecipes) do
			local outInfo = self.Catalog[recipe.OutputItemId]
			if outInfo then
				local card = recipeTemplate:Clone()
				card.Name = "Recipe_" .. recipe.RecipeId
				card.Visible = true
				card.LayoutOrder = idx

				local icon = card:FindFirstChild("ItemIcon") :: ImageLabel?
				local fallback = card:FindFirstChild("FallbackIcon") :: TextLabel?
				local nameLabel = card:FindFirstChild("ItemName") :: TextLabel?
				local statusBadge = card:FindFirstChild("StatusBadge") :: TextLabel?
				local stroke = card:FindFirstChildOfClass("UIStroke")
				local selectBtn = card:FindFirstChild("SelectBtn") :: TextButton?

				local hasImage = type(outInfo.Image) == "string" and outInfo.Image ~= ""
				if icon then
					icon.Image = hasImage and outInfo.Image or ""
					icon.Visible = hasImage
				end
				if fallback then
					fallback.Visible = not hasImage
					fallback.Text = string.upper(string.sub(recipe.OutputItemId, 1, 2))
				end
				if nameLabel then
					nameLabel.Text = outInfo.Name or recipe.OutputItemId
				end

				local maxCraft = self:getMaxCraftable(recipe)
				if statusBadge then
					if maxCraft > 0 then
						statusBadge.Text = "พร้อมสร้าง (x" .. tostring(maxCraft) .. ")"
						statusBadge.TextColor3 = Color3.fromRGB(110, 235, 130)
					else
						statusBadge.Text = "วัตถุดิบไม่พอ"
						statusBadge.TextColor3 = Color3.fromRGB(255, 110, 110)
					end
				end

				local isSelected = (selectedRecipe and selectedRecipe.RecipeId == recipe.RecipeId)
				if stroke then
					stroke.Color = if isSelected then Color3.fromRGB(220, 162, 3) else Color3.fromRGB(58, 58, 70)
					stroke.Thickness = if isSelected then 2 else 1
				end

				card.Parent = recipeScroll
				table.insert(self.RecipeCards, card)

				local clickTarget = selectBtn or (card :: any)
				if clickTarget and clickTarget.Activated then
					table.insert(
						self.DynamicConnections,
						clickTarget.Activated:Connect(function()
							self.SelectedRecipeId = recipe.RecipeId
							self.CraftQuantity = 1
							self:render()
						end)
					)
				end
			end
		end
	end

	if detailPanel then
		local previewName = detailPanel:FindFirstChild("OutputName") :: TextLabel?
		local previewDesc = detailPanel:FindFirstChild("OutputDesc") :: TextLabel?
		local previewIcon = detailPanel:FindFirstChild("OutputIcon") :: ImageLabel?
		local previewFallback = detailPanel:FindFirstChild("OutputFallback") :: TextLabel?
		local qtyBox = detailPanel:FindFirstChild("QuantityBox") :: TextBox?
		local craftBtn = detailPanel:FindFirstChild("CraftBtn") :: TextButton?

		if selectedRecipe then
			local outInfo = self.Catalog[selectedRecipe.OutputItemId]
			local maxCraft = self:getMaxCraftable(selectedRecipe)
			self.CraftQuantity = math.clamp(
				self.CraftQuantity,
				1,
				math.max(1, maxCraft > 0 and maxCraft or self.Config.MaxCraftQuantity)
			)

			if previewName then
				previewName.Text = string.format(
					"%s (x%d)",
					(outInfo and outInfo.Name) or selectedRecipe.OutputItemId,
					selectedRecipe.OutputAmount * self.CraftQuantity
				)
			end
			if previewDesc then
				previewDesc.Text = selectedRecipe.Description or ""
			end
			local hasImage = outInfo and type(outInfo.Image) == "string" and outInfo.Image ~= ""
			if previewIcon then
				previewIcon.Image = (hasImage and outInfo.Image) or ""
				previewIcon.Visible = hasImage == true
			end
			if previewFallback then
				previewFallback.Visible = not hasImage
				previewFallback.Text = string.upper(string.sub(selectedRecipe.OutputItemId, 1, 2))
			end
			if qtyBox then
				qtyBox.Text = tostring(self.CraftQuantity)
			end

			local counts = (self.State and self.State.ItemCounts) or {}
			local canAffordSelectedQty = true

			if ingTemplate and ingScroll then
				for idx, ing in ipairs(selectedRecipe.Ingredients) do
					local ingInfo = self.Catalog[ing.ItemId]
					local row = ingTemplate:Clone()
					row.Name = "Ingredient_" .. tostring(idx)
					row.Visible = true
					row.LayoutOrder = idx

					local ingName = row:FindFirstChild("IngName") :: TextLabel?
					local ingCount = row:FindFirstChild("IngCount") :: TextLabel?
					local owned = counts[ing.ItemId] or 0
					local required = ing.Amount * self.CraftQuantity
					if owned < required then
						canAffordSelectedQty = false
					end
					if ingName then
						ingName.Text = (ingInfo and ingInfo.Name) or ing.ItemId
					end
					if ingCount then
						ingCount.Text = string.format("%d / %d", owned, required)
						ingCount.TextColor3 = if owned >= required
							then Color3.fromRGB(110, 235, 130)
							else Color3.fromRGB(255, 105, 105)
					end

					row.Parent = ingScroll
					table.insert(self.IngredientCards, row)
				end
			end

			if craftBtn then
				craftBtn.AutoButtonColor = canAffordSelectedQty
				craftBtn.BackgroundTransparency = if canAffordSelectedQty then 0 else 0.5
				craftBtn.Text = if canAffordSelectedQty
					then "สร้างไอเทม (CRAFT)"
					else "วัตถุดิบไม่เพียงพอ"
			end
		end
	end
end

function CrafterView:setOpen(open: boolean)
	self.IsOpen = open
	local main = self.Gui:FindFirstChild("Frame") :: Frame?
	self.Gui.Enabled = open
	if main then
		main.Visible = open
	end
	if not open then
		self:clearDynamic()
	end
end

function CrafterView:Init()
	local names = self.Names
	local main = self.Gui:WaitForChild("Frame") :: Frame
	local header = main:WaitForChild("Header")
	local closeBtn = header:WaitForChild("CloseBtn") :: TextButton
	local detailPanel = main:WaitForChild("DetailPanel")
	local minusBtn = detailPanel:WaitForChild("MinusBtn") :: TextButton
	local plusBtn = detailPanel:WaitForChild("PlusBtn") :: TextButton
	local maxBtn = detailPanel:WaitForChild("MaxBtn") :: TextButton
	local qtyBox = detailPanel:WaitForChild("QuantityBox") :: TextBox
	local craftBtn = detailPanel:WaitForChild("CraftBtn") :: TextButton
	local statusLabel = detailPanel:FindFirstChild("StatusLabel") :: TextLabel?

	self:setOpen(false)

	table.insert(
		self.Connections,
		closeBtn.Activated:Connect(function()
			self.Commands:Enqueue(table.freeze({ Name = names.Close }))
			self:setOpen(false)
		end)
	)

	local filterBar = main:FindFirstChild("FilterBar")
	if filterBar then
		for _, catName in ipairs({ "All", "Weapon", "Consumable" }) do
			local btn = filterBar:FindFirstChild("Btn" .. catName) :: TextButton?
			if btn then
				table.insert(
					self.Connections,
					btn.Activated:Connect(function()
						self.Category = catName
						self.SelectedRecipeId = nil
						for _, otherName in ipairs({ "All", "Weapon", "Consumable" }) do
							local otherBtn = filterBar:FindFirstChild("Btn" .. otherName) :: TextButton?
							if otherBtn then
								local active = (otherName == catName)
								otherBtn.BackgroundColor3 = if active
									then Color3.fromRGB(220, 162, 3)
									else Color3.fromRGB(32, 32, 40)
								otherBtn.TextColor3 = if active
									then Color3.fromRGB(15, 15, 18)
									else Color3.fromRGB(225, 225, 235)
							end
						end
						self:render()
					end)
				)
			end
		end
	end

	table.insert(
		self.Connections,
		minusBtn.Activated:Connect(function()
			self.CraftQuantity = math.clamp(self.CraftQuantity - 1, 1, self.Config.MaxCraftQuantity)
			self:render()
		end)
	)

	table.insert(
		self.Connections,
		plusBtn.Activated:Connect(function()
			self.CraftQuantity = math.clamp(self.CraftQuantity + 1, 1, self.Config.MaxCraftQuantity)
			self:render()
		end)
	)

	table.insert(
		self.Connections,
		maxBtn.Activated:Connect(function()
			local station = self.Config.Stations[(self.State and self.State.StationId) or "General"]
				or self.Config.Stations.General
			if station and self.SelectedRecipeId then
				for _, r in ipairs(station.Recipes) do
					if r.RecipeId == self.SelectedRecipeId then
						local maxC = self:getMaxCraftable(r)
						self.CraftQuantity = math.clamp(maxC, 1, self.Config.MaxCraftQuantity)
						break
					end
				end
			end
			self:render()
		end)
	)

	table.insert(
		self.Connections,
		qtyBox.FocusLost:Connect(function()
			local val = tonumber(qtyBox.Text) or 1
			self.CraftQuantity = math.clamp(math.floor(val), 1, self.Config.MaxCraftQuantity)
			self:render()
		end)
	)

	table.insert(
		self.Connections,
		craftBtn.Activated:Connect(function()
			if not self.SelectedRecipeId then
				return
			end
			self.Commands:Enqueue(table.freeze({
				Name = names.Craft,
				RecipeId = self.SelectedRecipeId,
				Quantity = self.CraftQuantity,
			}))
		end)
	)

	if self.UserInputService then
		table.insert(
			self.Connections,
			self.UserInputService.InputBegan:Connect(function(input, processed)
				if not processed and self.IsOpen and input.KeyCode == Enum.KeyCode.Escape then
					self.Commands:Enqueue(table.freeze({ Name = names.Close }))
					self:setOpen(false)
				end
			end)
		)
	end

	table.insert(
		self.Subscriptions,
		self.Events:Subscribe(names.Opened, function(payload)
			self.State = payload
			if statusLabel then
				statusLabel.Text = ""
			end
			self:setOpen(true)
			self:render()
		end)
	)

	table.insert(
		self.Subscriptions,
		self.Events:Subscribe(names.StateChanged, function(payload)
			self.State = payload
			if self.IsOpen then
				self:render()
			end
		end)
	)

	table.insert(
		self.Subscriptions,
		self.Events:Subscribe(names.Closed, function()
			self:setOpen(false)
		end)
	)

	table.insert(
		self.Subscriptions,
		self.Events:Subscribe(names.CraftResult, function(result)
			if statusLabel then
				if result.Succeeded then
					statusLabel.TextColor3 = Color3.fromRGB(110, 235, 130)
					statusLabel.Text =
						"✓ สร้างไอเทมสำเร็จ! ไอเทมถูกส่งเข้ากระเป๋าแล้ว"
				else
					statusLabel.TextColor3 = Color3.fromRGB(255, 105, 105)
					statusLabel.Text = "✕ ไม่สามารถสร้างไอเทมได้: "
						.. tostring(result.Reason or "Error")
				end
			end
		end)
	)
end

function CrafterView:Dispose()
	if self.Disposed then
		return
	end
	self.Disposed = true
	self:clearDynamic()
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	for _, unsub in ipairs(self.Subscriptions) do
		unsub()
	end
	table.clear(self.Connections)
	table.clear(self.Subscriptions)
end

return CrafterView
