--!strict
-- /// <summary>Renders the standalone Dark/Gold Vault window with dual UIGridLayout panels (Backpack & Vault).</summary>
local VaultView = {}
VaultView.__index = VaultView

function VaultView.new(parameters)
	return setmetatable({
		Gui = parameters.Gui,
		Commands = parameters.Commands,
		Events = parameters.Events,
		Names = parameters.Names,
		Config = parameters.Config,
		Catalog = parameters.Catalog,
		TweenService = parameters.TweenService,
		UserInputService = parameters.UserInputService,
		Connections = {},
		CardConnections = {},
		Subscriptions = {},
		BackpackCards = {},
		VaultCards = {},
		State = nil,
		SelectedSide = nil, -- "Backpack" | "Vault"
		SelectedItemId = nil,
		SelectedMaxAmount = 1,
		Category = "All",
		SearchText = "",
		IsOpen = false,
		Disposed = false,
	}, VaultView)
end

function VaultView:clearCards()
	for _, conn in ipairs(self.CardConnections) do
		conn:Disconnect()
	end
	table.clear(self.CardConnections)
	for _, card in ipairs(self.BackpackCards) do
		card:Destroy()
	end
	for _, card in ipairs(self.VaultCards) do
		card:Destroy()
	end
	table.clear(self.BackpackCards)
	table.clear(self.VaultCards)
end

function VaultView:updateSelectionBar()
	local main = self.Gui:FindFirstChild("MainFrame")
	if not main then
		return
	end
	local transferBar = main:FindFirstChild("TransferBar")
	if not transferBar then
		return
	end
	local selectedLabel = transferBar:FindFirstChild("SelectedLabel") :: TextLabel?
	local qtyBox = transferBar:FindFirstChild("QuantityBox") :: TextBox?
	local depositBtn = transferBar:FindFirstChild("DepositBtn") :: TextButton?
	local withdrawBtn = transferBar:FindFirstChild("WithdrawBtn") :: TextButton?

	local info = self.SelectedItemId and self.Catalog[self.SelectedItemId]
	if info and self.SelectedSide then
		local sideText = if self.SelectedSide == "Backpack" then "กระเป๋า" else "ตู้เซฟ"
		if selectedLabel then
			selectedLabel.Text = string.format(
				"%s (%s • สูงสุด %d)",
				info.Name or self.SelectedItemId,
				sideText,
				self.SelectedMaxAmount
			)
		end
		if depositBtn then
			depositBtn.AutoButtonColor = (self.SelectedSide == "Backpack")
			depositBtn.BackgroundTransparency = if self.SelectedSide == "Backpack" then 0 else 0.55
		end
		if withdrawBtn then
			withdrawBtn.AutoButtonColor = (self.SelectedSide == "Vault")
			withdrawBtn.BackgroundTransparency = if self.SelectedSide == "Vault" then 0 else 0.55
		end
		if qtyBox then
			local cur = tonumber(qtyBox.Text) or 1
			qtyBox.Text = tostring(math.clamp(math.floor(cur), 1, math.max(1, self.SelectedMaxAmount)))
		end
	else
		if selectedLabel then
			selectedLabel.Text =
				"เลือกไอเทมจากกระเป๋าหรือตู้เซฟเพื่อฝาก/ถอน"
		end
		if depositBtn then
			depositBtn.BackgroundTransparency = 0.55
		end
		if withdrawBtn then
			withdrawBtn.BackgroundTransparency = 0.55
		end
	end
end

function VaultView:populateCard(
	template: GuiObject,
	parentScroll: ScrollingFrame,
	stack,
	index: number,
	side: string,
	targetList
)
	local info = self.Catalog[stack.ItemID]
	if not info then
		return
	end
	if self.Category ~= "All" then
		if self.Category == "Weapon" and info.Type ~= "Weapon" then
			return
		end
		if self.Category == "Food" and info.Type ~= "Food" then
			return
		end
		if self.Category == "General" and (info.Type == "Weapon" or info.Type == "Food") then
			return
		end
	end
	if self.SearchText ~= "" then
		local lowerName = string.lower(info.Name or "")
		local lowerId = string.lower(stack.ItemID)
		if
			not string.find(lowerName, self.SearchText, 1, true) and not string.find(lowerId, self.SearchText, 1, true)
		then
			return
		end
	end

	local card = template:Clone()
	card.Name = side .. "Item_" .. tostring(index)
	card.Visible = true
	card.LayoutOrder = index

	local icon = card:FindFirstChild("ItemIcon") :: ImageLabel?
	local fallback = card:FindFirstChild("FallbackIcon") :: TextLabel?
	local nameLabel = card:FindFirstChild("ItemName") :: TextLabel?
	local amountLabel = card:FindFirstChild("ItemAmount") :: TextLabel?
	local stroke = card:FindFirstChildOfClass("UIStroke")
	local selectBtn = card:FindFirstChild("SelectBtn") :: TextButton?

	local hasImage = type(info.Image) == "string" and info.Image ~= ""
	if icon then
		icon.Image = hasImage and info.Image or ""
		icon.Visible = hasImage
	end
	if fallback then
		fallback.Visible = not hasImage
		fallback.Text = string.upper(string.sub(stack.ItemID, 1, 2))
	end
	if nameLabel then
		nameLabel.Text = info.Name or stack.ItemID
	end
	if amountLabel then
		amountLabel.Text = "x" .. tostring(stack.Amount)
	end

	local isSelected = (self.SelectedSide == side and self.SelectedItemId == stack.ItemID)
	if stroke then
		stroke.Color = if isSelected then Color3.fromRGB(220, 162, 3) else Color3.fromRGB(58, 58, 70)
		stroke.Thickness = if isSelected then 2 else 1
	end

	card.Parent = parentScroll
	table.insert(targetList, card)

	local clickTarget = selectBtn or (card :: any)
	if clickTarget and clickTarget.Activated then
		table.insert(
			self.CardConnections,
			clickTarget.Activated:Connect(function()
				self.SelectedSide = side
				self.SelectedItemId = stack.ItemID
				self.SelectedMaxAmount = stack.Amount
				self:render()
			end)
		)
	end
end

function VaultView:render()
	local main = self.Gui:FindFirstChild("MainFrame")
	if not main or not self.State then
		return
	end
	self:clearCards()

	local header = main:FindFirstChild("Header")
	local titleLabel = header and header:FindFirstChild("Title") :: TextLabel?
	if titleLabel and self.State.DisplayName then
		titleLabel.Text = self.State.DisplayName
	end

	local backpackPanel = main:FindFirstChild("BackpackPanel")
	local vaultPanel = main:FindFirstChild("VaultPanel")
	local backpackScroll = backpackPanel and backpackPanel:FindFirstChild("ItemScroll") :: ScrollingFrame?
	local vaultScroll = vaultPanel and vaultPanel:FindFirstChild("ItemScroll") :: ScrollingFrame?
	local template = main:FindFirstChild("ItemCardTemplate") :: GuiObject?
	local capacityLabel = vaultPanel and vaultPanel:FindFirstChild("CapacityLabel") :: TextLabel?
	local backpackCountLabel = backpackPanel and backpackPanel:FindFirstChild("CountLabel") :: TextLabel?

	if capacityLabel then
		capacityLabel.Text = string.format("SLOTS: %d / %d", #(self.State.VaultItems or {}), self.State.MaxStacks or 60)
	end
	if backpackCountLabel then
		backpackCountLabel.Text = string.format("ITEMS: %d", #(self.State.BackpackItems or {}))
	end

	if template and backpackScroll and vaultScroll then
		-- Aggregate backpack stacks by ItemID for clean display (excluding permanent items)
		local aggregatedBackpack = {}
		local orderList = {}
		for _, item in ipairs(self.State.BackpackItems or {}) do
			local info = self.Catalog[item.ItemID]
			if info and not info.Permanent then
				if not aggregatedBackpack[item.ItemID] then
					aggregatedBackpack[item.ItemID] = 0
					table.insert(orderList, item.ItemID)
				end
				aggregatedBackpack[item.ItemID] += item.Amount
			end
		end
		for idx, itemId in ipairs(orderList) do
			self:populateCard(
				template,
				backpackScroll,
				{ ItemID = itemId, Amount = aggregatedBackpack[itemId] },
				idx,
				"Backpack",
				self.BackpackCards
			)
		end
		for idx, stack in ipairs(self.State.VaultItems or {}) do
			self:populateCard(template, vaultScroll, stack, idx, "Vault", self.VaultCards)
		end
	end

	self:updateSelectionBar()
end

function VaultView:setOpen(open: boolean)
	self.IsOpen = open
	local main = self.Gui:FindFirstChild("MainFrame") :: Frame?
	self.Gui.Enabled = open
	if main then
		main.Visible = open
	end
	if not open then
		self.SelectedSide = nil
		self.SelectedItemId = nil
		self:clearCards()
	end
end

function VaultView:Init()
	local names = self.Names
	local main = self.Gui:WaitForChild("MainFrame") :: Frame
	local header = main:WaitForChild("Header")
	local closeBtn = header:WaitForChild("CloseBtn") :: TextButton
	local searchBox = header:FindFirstChild("SearchBox") :: TextBox?
	local transferBar = main:WaitForChild("TransferBar")
	local qtyBox = transferBar:WaitForChild("QuantityBox") :: TextBox
	local minusBtn = transferBar:WaitForChild("MinusBtn") :: TextButton
	local plusBtn = transferBar:WaitForChild("PlusBtn") :: TextButton
	local maxBtn = transferBar:WaitForChild("MaxBtn") :: TextButton
	local depositBtn = transferBar:WaitForChild("DepositBtn") :: TextButton
	local withdrawBtn = transferBar:WaitForChild("WithdrawBtn") :: TextButton
	local statusLabel = transferBar:FindFirstChild("StatusLabel") :: TextLabel?

	self:setOpen(false)

	table.insert(
		self.Connections,
		closeBtn.Activated:Connect(function()
			self.Commands:Enqueue(table.freeze({ Name = names.Close }))
			self:setOpen(false)
		end)
	)

	if searchBox then
		table.insert(
			self.Connections,
			searchBox:GetPropertyChangedSignal("Text"):Connect(function()
				self.SearchText = string.lower(searchBox.Text)
				if self.IsOpen then
					self:render()
				end
			end)
		)
	end

	local filterBar = main:FindFirstChild("FilterBar")
	if filterBar then
		for _, catName in ipairs({ "All", "Weapon", "Food", "General" }) do
			local btn = filterBar:FindFirstChild("Btn" .. catName) :: TextButton?
			if btn then
				table.insert(
					self.Connections,
					btn.Activated:Connect(function()
						self.Category = catName
						for _, otherName in ipairs({ "All", "Weapon", "Food", "General" }) do
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
			local cur = tonumber(qtyBox.Text) or 1
			qtyBox.Text = tostring(math.clamp(cur - 1, 1, math.max(1, self.SelectedMaxAmount)))
		end)
	)

	table.insert(
		self.Connections,
		plusBtn.Activated:Connect(function()
			local cur = tonumber(qtyBox.Text) or 1
			qtyBox.Text = tostring(math.clamp(cur + 1, 1, math.max(1, self.SelectedMaxAmount)))
		end)
	)

	table.insert(
		self.Connections,
		maxBtn.Activated:Connect(function()
			qtyBox.Text = tostring(math.max(1, self.SelectedMaxAmount))
		end)
	)

	table.insert(
		self.Connections,
		depositBtn.Activated:Connect(function()
			if self.SelectedSide ~= "Backpack" or not self.SelectedItemId then
				return
			end
			local amount = math.clamp(math.floor(tonumber(qtyBox.Text) or 1), 1, math.max(1, self.SelectedMaxAmount))
			self.Commands:Enqueue(table.freeze({
				Name = names.Deposit,
				ItemId = self.SelectedItemId,
				Amount = amount,
			}))
		end)
	)

	table.insert(
		self.Connections,
		withdrawBtn.Activated:Connect(function()
			if self.SelectedSide ~= "Vault" or not self.SelectedItemId then
				return
			end
			local amount = math.clamp(math.floor(tonumber(qtyBox.Text) or 1), 1, math.max(1, self.SelectedMaxAmount))
			self.Commands:Enqueue(table.freeze({
				Name = names.Withdraw,
				ItemId = self.SelectedItemId,
				Amount = amount,
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
			if self.SelectedItemId and self.SelectedSide then
				local newMax = 0
				if self.SelectedSide == "Backpack" then
					for _, stack in ipairs(payload.BackpackItems or {}) do
						if stack.ItemID == self.SelectedItemId then
							newMax += stack.Amount
						end
					end
				else
					for _, stack in ipairs(payload.VaultItems or {}) do
						if stack.ItemID == self.SelectedItemId then
							newMax += stack.Amount
						end
					end
				end
				if newMax <= 0 then
					self.SelectedItemId = nil
					self.SelectedSide = nil
					self.SelectedMaxAmount = 1
				else
					self.SelectedMaxAmount = newMax
				end
			end
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
		self.Events:Subscribe(names.TransferResult, function(result)
			if statusLabel then
				if result.Succeeded then
					statusLabel.TextColor3 = Color3.fromRGB(110, 235, 130)
					statusLabel.Text = if result.Reason == "Deposited"
						then "✓ ฝากไอเทมเข้าตู้เซฟสำเร็จ"
						else "✓ ถอนไอเทมเข้ากระเป๋าสำเร็จ"
				else
					statusLabel.TextColor3 = Color3.fromRGB(255, 105, 105)
					statusLabel.Text = "✕ ไม่สามารถทำรายการได้: "
						.. tostring(result.Reason or "Error")
				end
			end
		end)
	)
end

function VaultView:Dispose()
	if self.Disposed then
		return
	end
	self.Disposed = true
	self:clearCards()
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	for _, unsub in ipairs(self.Subscriptions) do
		unsub()
	end
	table.clear(self.Connections)
	table.clear(self.Subscriptions)
end

return VaultView
