--[[ <summary>Renders prioritized, queued item gain and loss notifications from inventory quantity facts.</summary> ]]
local ItemTransferView = {}
ItemTransferView.__index = ItemTransferView

local function formatAmount(delta)
	return if delta > 0 then "+" .. tostring(delta) else tostring(delta)
end

local function sameDirection(first, second)
	return (first > 0 and second > 0) or (first < 0 and second < 0)
end

function ItemTransferView.new(parameters)
	return setmetatable({
		_assets = parameters.Assets,
		_events = parameters.Events,
		_names = parameters.Names,
		_catalog = parameters.Catalog,
		_tweenService = parameters.TweenService,
		_config = parameters.Config,
		_active = {},
		_queue = {},
		_exiting = {},
		_entryTimer = nil,
		_lastEntryTime = nil,
		_soundTimer = nil,
		_pendingSound = 0,
		_unsubscribe = nil,
		_disposed = false,
	}, ItemTransferView)
end

function ItemTransferView:_hasExitingRows()
	for _ in pairs(self._exiting) do
		return true
	end
	return false
end

function ItemTransferView:_refreshVisibility()
	self._assets.Screen.Enabled = #self._active > 0 or self:_hasExitingRows()
end

function ItemTransferView:_refreshLayoutOrder()
	local order = 0
	for _, entry in ipairs(self._active) do
		if entry.Delta > 0 then
			order += 1
			entry.Row.LayoutOrder = order
		end
	end
	for _, entry in ipairs(self._active) do
		if entry.Delta < 0 then
			order += 1
			entry.Row.LayoutOrder = order
		end
	end
end

function ItemTransferView:_scheduleDismissal(entry)
	if entry.Timer then
		pcall(task.cancel, entry.Timer)
	end
	entry.Timer = task.delay(self._config.VisibleSeconds, function()
		entry.Timer = nil
		if not self._disposed then
			self:_dismissEntry(entry)
		end
	end)
end

function ItemTransferView:_hideEntryRow(row)
	local objects = { row }
	for _, descendant in ipairs(row:GetDescendants()) do
		table.insert(objects, descendant)
	end
	for _, object in ipairs(objects) do
		if object:IsA("GuiObject") then
			object.BackgroundTransparency = 1
		end
		if object:IsA("ImageLabel") or object:IsA("ImageButton") then
			object.ImageTransparency = 1
		elseif object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
			object.TextTransparency = 1
			object.TextStrokeTransparency = 1
		elseif object:IsA("UIStroke") then
			object.Transparency = 1
		end
	end
end

function ItemTransferView:_stopEntryTween(entry)
	if entry.EntryTween then
		entry.EntryTween:Cancel()
		entry.EntryTween:Destroy()
		entry.EntryTween = nil
	end
end

function ItemTransferView:_queueSound(delta)
	if delta > 0 then
		self._pendingSound = 1
	elseif self._pendingSound ~= 1 then
		self._pendingSound = -1
	end
	if self._soundTimer then
		return
	end
	self._soundTimer = task.delay(self._config.SoundBatchSeconds, function()
		self._soundTimer = nil
		if self._disposed then
			return
		end
		local sound = if self._pendingSound > 0 then self._assets.GainSound else self._assets.LossSound
		self._pendingSound = 0
		sound:Stop()
		sound:Play()
	end)
end

function ItemTransferView:_showEntry(itemId, delta)
	local info = self._catalog[itemId]
	if not info then
		return
	end
	local row = self._assets.Template:Clone()
	row.Name = "ItemTransferEntry"
	row.Visible = true
	local entryScale = row:WaitForChild("EntryScale")
	entryScale.Scale = self._config.EntryStartScale
	local icon = row:WaitForChild("ItemIcon")
	local nameLabel = row:WaitForChild("ItemName")
	local amountLabel = row:WaitForChild("Amount")
	local colorImage = row:WaitForChild("Color")
	icon.Image = type(info.Image) == "string" and info.Image or ""
	nameLabel.Text = type(info.Name) == "string" and info.Name or itemId
	amountLabel.Text = formatAmount(delta)
	local rgb = if delta > 0 then self._config.GainColor else self._config.LossColor
	colorImage.ImageColor3 = Color3.fromRGB(rgb.R, rgb.G, rgb.B)
	row.Parent = self._assets.Scroll
	local entry = { ItemId = itemId, Delta = delta, Row = row, Timer = nil, EntryTween = nil }
	table.insert(self._active, entry)
	self:_refreshLayoutOrder()
	self:_scheduleDismissal(entry)
	self:_refreshVisibility()
	local tween = self._tweenService:Create(
		entryScale,
		TweenInfo.new(self._config.EntrySeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	)
	entry.EntryTween = tween
	tween:Play()
end

function ItemTransferView:_drainQueue()
	if self._entryTimer or self:_hasExitingRows() or #self._active >= self._config.MaxVisible or #self._queue == 0 then
		return
	end
	local waitSeconds = self._config.EntryBatchSeconds
	if self._lastEntryTime then
		waitSeconds = math.max(waitSeconds, self._config.EntryStaggerSeconds - (os.clock() - self._lastEntryTime))
	end
	self._entryTimer = task.delay(waitSeconds, function()
		self._entryTimer = nil
		if
			self._disposed
			or self:_hasExitingRows()
			or #self._active >= self._config.MaxVisible
			or #self._queue == 0
		then
			return
		end
		local nextIndex = 1
		for index, entry in ipairs(self._queue) do
			if entry.Delta > 0 then
				nextIndex = index
				break
			end
		end
		local nextEntry = table.remove(self._queue, nextIndex)
		self._lastEntryTime = os.clock()
		self:_showEntry(nextEntry.ItemId, nextEntry.Delta)
		self:_drainQueue()
	end)
end

function ItemTransferView:_finishExit(ghost)
	local effect = self._exiting[ghost]
	if not effect then
		return
	end
	self._exiting[ghost] = nil
	if effect.Connection then
		effect.Connection:Disconnect()
	end
	if effect.Tween then
		effect.Tween:Destroy()
	end
	if ghost.Parent then
		ghost:Destroy()
	end
	local entry = effect.Entry
	if entry and entry.Row and entry.Row.Parent then
		entry.Row:Destroy()
	end
	local index = entry and table.find(self._active, entry)
	if index then
		table.remove(self._active, index)
		self:_refreshLayoutOrder()
	end
	self:_drainQueue()
	self:_refreshVisibility()
end

function ItemTransferView:_dismissEntry(entry)
	local index = table.find(self._active, entry)
	if not index or entry.Exiting then
		return
	end
	entry.Exiting = true
	if entry.Timer then
		pcall(task.cancel, entry.Timer)
		entry.Timer = nil
	end
	self:_stopEntryTween(entry)
	local row = entry.Row
	if row and row.Parent then
		local layer = self._assets.ExitLayer
		local absolutePosition = row.AbsolutePosition
		local absoluteSize = row.AbsoluteSize
		local layerPosition = layer.AbsolutePosition
		local ghost = row:Clone()
		ghost.Name = "ItemTransferExit"
		ghost.AnchorPoint = Vector2.zero
		ghost.Position = UDim2.fromOffset(absolutePosition.X - layerPosition.X, absolutePosition.Y - layerPosition.Y)
		ghost.Size = UDim2.fromOffset(absoluteSize.X, absoluteSize.Y)
		ghost.Parent = layer
		self:_hideEntryRow(row)
		local target = UDim2.fromOffset(-absoluteSize.X - 24, ghost.Position.Y.Offset)
		local tween = self._tweenService:Create(
			ghost,
			TweenInfo.new(self._config.ExitSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = target }
		)
		local connection
		connection = tween.Completed:Connect(function()
			self:_finishExit(ghost)
		end)
		self._exiting[ghost] = { Tween = tween, Connection = connection, Entry = entry }
		tween:Play()
	else
		table.remove(self._active, index)
		self:_refreshLayoutOrder()
		self:_drainQueue()
	end
	self:_refreshVisibility()
end

function ItemTransferView:OnInventoryQuantityChanged(event)
	if
		self._disposed
		or type(event) ~= "table"
		or type(event.ItemId) ~= "string"
		or type(event.Delta) ~= "number"
		or event.Delta == 0
		or not self._catalog[event.ItemId]
	then
		return
	end
	self:_queueSound(event.Delta)
	for _, entry in ipairs(self._active) do
		if not entry.Exiting and entry.ItemId == event.ItemId and sameDirection(entry.Delta, event.Delta) then
			entry.Delta += event.Delta
			entry.Row:WaitForChild("Amount").Text = formatAmount(entry.Delta)
			self:_scheduleDismissal(entry)
			return
		end
	end
	for _, entry in ipairs(self._queue) do
		if entry.ItemId == event.ItemId and sameDirection(entry.Delta, event.Delta) then
			entry.Delta += event.Delta
			return
		end
	end
	table.insert(self._queue, { ItemId = event.ItemId, Delta = event.Delta })
	self:_drainQueue()
end

function ItemTransferView:Init()
	local assets = self._assets
	assert(
		assets.Screen:IsA("ScreenGui")
			and assets.Scroll:IsA("ScrollingFrame")
			and assets.Template:IsA("ImageLabel")
			and assets.ExitLayer:IsA("Frame")
			and assets.GainSound:IsA("Sound")
			and assets.LossSound:IsA("Sound")
			and assets.Template:WaitForChild("EntryScale"):IsA("UIScale"),
		"ItemTransfer UI hierarchy is incomplete"
	)
	assets.Screen.Enabled = false
	assets.Template.Visible = false
	assets.GainSound.SoundId = self._config.GainSoundId
	assets.LossSound.SoundId = self._config.LossSoundId
	assets.GainSound.Volume = self._config.SoundVolume
	assets.LossSound.Volume = self._config.SoundVolume
	assets.Scroll:WaitForChild("UIListLayout").SortOrder = Enum.SortOrder.LayoutOrder
	assets.Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	assets.Scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	assets.Scroll.ScrollingEnabled = false
	assets.Scroll.Active = false
	self._unsubscribe = self._events:Subscribe(self._names.QuantityChanged, function(event)
		self:OnInventoryQuantityChanged(event)
	end)
end

function ItemTransferView:Dispose()
	if self._disposed then
		return
	end
	self._disposed = true
	if self._entryTimer then
		pcall(task.cancel, self._entryTimer)
		self._entryTimer = nil
	end
	if self._soundTimer then
		pcall(task.cancel, self._soundTimer)
		self._soundTimer = nil
	end
	self._pendingSound = 0
	if self._unsubscribe then
		self._unsubscribe()
		self._unsubscribe = nil
	end
	for _, entry in ipairs(self._active) do
		self:_stopEntryTween(entry)
		if entry.Timer then
			pcall(task.cancel, entry.Timer)
		end
		if entry.Row and entry.Row.Parent then
			entry.Row:Destroy()
		end
	end
	table.clear(self._active)
	table.clear(self._queue)
	for ghost, effect in pairs(self._exiting) do
		if effect.Connection then
			effect.Connection:Disconnect()
		end
		if effect.Tween then
			effect.Tween:Cancel()
			effect.Tween:Destroy()
		end
		if ghost.Parent then
			ghost:Destroy()
		end
	end
	table.clear(self._exiting)
	if self._assets then
		self._assets.GainSound:Stop()
		self._assets.LossSound:Stop()
	end
	if self._assets and self._assets.Screen then
		self._assets.Screen.Enabled = false
	end
	self._assets = nil
	self._events = nil
	self._catalog = nil
end

return ItemTransferView
