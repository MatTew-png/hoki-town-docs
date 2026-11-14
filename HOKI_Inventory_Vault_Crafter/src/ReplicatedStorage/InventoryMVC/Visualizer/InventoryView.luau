--[[ <summary>Renders authoritative inventory snapshots, handles authored inventory input, and previews the current character.</summary> ]]
local InventoryView = {}
InventoryView.__index = InventoryView

local HOTBAR_SWITCH_COOLDOWN = 0.35
local SEQUENCE_ITEM_GAP_SECONDS = 0.04
local SEQUENCE_MAX_CASCADE_SECONDS = 1.0
local SEQUENCE_CLOSE_ITEM_GAP_SECONDS = 0.032
local SEQUENCE_CLOSE_MAX_CASCADE_SECONDS = 0.8
local SEQUENCE_MAX_STARTS_PER_FRAME = 24
local SEQUENCE_OPEN_SECONDS = 0.11
local SEQUENCE_CLOSE_SECONDS = 0.08

local CATEGORY_TYPES = table.freeze({ BtnWeapon = "Weapon", BtnFoods = "Food", BtnFashion = "Fashion" })
local KEY_SLOTS = table.freeze({
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.KeypadOne] = 1,
	[Enum.KeyCode.KeypadTwo] = 2,
	[Enum.KeyCode.KeypadThree] = 3,
	[Enum.KeyCode.KeypadFour] = 4,
	[Enum.KeyCode.KeypadFive] = 5,
	[Enum.KeyCode.KeypadSix] = 6,
})

function InventoryView.new(parameters)
	return setmetatable({
		_assets = parameters.Assets,
		_input = parameters.Input,
		_player = parameters.Player,
		_tweenService = parameters.TweenService,
		_commands = parameters.Commands,
		_events = parameters.Events,
		_names = parameters.Names,
		_catalog = parameters.Catalog,
		_useConfig = parameters.UseConfig,
		_useAnimations = parameters.UseAnimations or {},
		_useTrack = nil,
		_connections = {},
		_rowConnections = {},
		_players = parameters.Players,
		_interactionConfig = parameters.InteractionConfig,
		_interactionConnections = {},
		_interactionRows = {},
		_interactionGeneration = 0,
		_actionItemId = nil,
		_actionMode = nil,
		_targetUserId = nil,
		_rows = {},
		_tweens = {},
		_snapshot = { Items = {}, Slots = {} },
		_category = "BtnAll",
		_dragGhost = nil,
		_isOpen = false,
		_isClosing = false,
		_openSequencesStarted = false,
		_hasReceivedSnapshot = false,
		_disposed = false,
		_transition = 0,
		_inVehicle = false,
		_canOpen = false,
		_canUseHotbar = false,
		_hotbarCooldownRemaining = 0,
		_backdropShown = false,
		_hasHotbarItems = false,
		_hideHotbarAfterInteraction = false,
		_indicatorSelected = {},
		_hudHovered = {},
		_hudPopping = {},
	}, InventoryView)
end

function InventoryView:connect(signal, callback, rows)
	local connection = signal:Connect(callback)
	table.insert(rows and self._rowConnections or self._connections, connection)
	return connection
end

function InventoryView:sendCommand(name, id, slot, extra)
	local command = { Name = name, ItemId = id, Slot = slot }
	if type(extra) == "table" then
		for key, value in pairs(extra) do
			command[key] = value
		end
	end
	self._commands:Enqueue(table.freeze(command))
end

function InventoryView:findItem(id)
	for _, item in ipairs(self._snapshot.Items) do
		if item.UUID == id then
			return item
		end
	end
	return nil
end

function InventoryView:playTween(instance, goals, duration, easingStyle, easingDirection, delayTime, onCompleted)
	local existing = self._tweens[instance]
	if existing then
		self._tweens[instance] = nil
		existing:Cancel()
		existing:Destroy()
	end

	local tween = self._tweenService:Create(
		instance,
		TweenInfo.new(
			duration,
			easingStyle or Enum.EasingStyle.Quad,
			easingDirection or Enum.EasingDirection.Out,
			0,
			false,
			delayTime or 0
		),
		goals
	)
	self._tweens[instance] = tween
	local completionConnection
	completionConnection = tween.Completed:Connect(function(playbackState)
		if self._tweens[instance] == tween then
			self._tweens[instance] = nil
		end
		if completionConnection then
			completionConnection:Disconnect()
		end
		tween:Destroy()
		if onCompleted and playbackState == Enum.PlaybackState.Completed then
			onCompleted()
		end
	end)
	tween:Play()
end

local function isInside(object, position)
	local origin, size = object.AbsolutePosition, object.AbsoluteSize
	return position.X >= origin.X
		and position.Y >= origin.Y
		and position.X <= origin.X + size.X
		and position.Y <= origin.Y + size.Y
end

local function scaleUDim2(value, factor)
	return UDim2.new(value.X.Scale * factor, value.X.Offset * factor, value.Y.Scale * factor, value.Y.Offset * factor)
end

local function centeredPosition(position, originalSize, targetSize, anchorPoint)
	local centerOffsetX, centerOffsetY = 0.5 - anchorPoint.X, 0.5 - anchorPoint.Y
	return UDim2.new(
		position.X.Scale + (originalSize.X.Scale - targetSize.X.Scale) * centerOffsetX,
		position.X.Offset + (originalSize.X.Offset - targetSize.X.Offset) * centerOffsetX,
		position.Y.Scale + (originalSize.Y.Scale - targetSize.Y.Scale) * centerOffsetY,
		position.Y.Offset + (originalSize.Y.Offset - targetSize.Y.Offset) * centerOffsetY
	)
end

function InventoryView:Init()
	local assets = self._assets
	assets.Main.Visible = false
	assets.CharacterAndStatus.Visible = false
	assets.HotbarMain.Visible = false
	assets.HudMain.Visible = false
	assets.Chooser.Visible = false
	assets.PlayerInrange.Visible = false
	assets.Accept.Visible = false
	assets.PlayerRangeTemplate.Visible = false
	assets.DragTemplate.Visible = false
	assert(
		assets.DragTemplate:IsA("Frame") and assets.DragTemplate:WaitForChild("ItemIcon"):IsA("ImageLabel"),
		"Missing authored Inventory.DragItemTemplate.ItemIcon"
	)
	assets.BackdropScreen.Enabled = false
	assets.Dimmer.Visible = false
	assets.Dimmer.BackgroundTransparency = 1
	self._originalSize = assets.Main.Size
	self._originalPosition = assets.Main.Position
	self._originalRotation = assets.Main.Rotation
	self._mainAnchorPoint = assets.Main.AnchorPoint
	self._characterOriginalSize = assets.CharacterAndStatus.Size
	self._characterOriginalPosition = assets.CharacterAndStatus.Position
	self._characterOriginalRotation = assets.CharacterAndStatus.Rotation
	self._characterAnchorPoint = assets.CharacterAndStatus.AnchorPoint
	self._slotOriginals = {}
	for index, slot in ipairs(assets.Slots) do
		local openScale = slot.Frame:FindFirstChild("OpenScale")
		assert(openScale and openScale:IsA("UIScale"), "Missing authored OpenScale on hotbar Slot" .. index)
		self._slotOriginals[index] = {
			Position = slot.Frame.Position,
			Rotation = slot.Frame.Rotation,
			Scale = openScale,
			Visible = slot.Frame.Visible,
		}
	end
	self._hudOriginals = {}
	for index, hud in ipairs(assets.HudHotbars) do
		local indicator = hud.Indicator
		assert(indicator and indicator:IsA("Frame"), "Missing authored SelectionIndicator on Hotbar" .. index)
		assert(
			hud.Scale and hud.Scale:IsA("UIScale") and hud.NumberLabel:IsA("TextLabel"),
			"Missing authored hotbar scale or number label on Hotbar" .. index
		)
		self._hudOriginals[index] = {
			Position = hud.Button.Position,
			Scale = hud.Scale,
			IndicatorSize = indicator.Size,
			ButtonColor = hud.Button.BackgroundColor3,
			NumberColor = hud.NumberLabel.BackgroundColor3,
			IndicatorColor = indicator.BackgroundColor3,
		}
		indicator.Visible = false
	end
	self:connect(assets.HudMain:GetPropertyChangedSignal("AbsoluteSize"), function()
		self:RefreshHotbar()
	end)
	assets.Main.Visible = false
	assets.CharacterAndStatus.Visible = false
	assets.HotbarMain.Visible = false
	assets.Template.Visible = false
	assets.PlayerRangeTemplate.Visible = false
	self:connect(assets.Chooser.UseBtn.Activated, function()
		local id = self._actionItemId
		if id then
			self:CloseActionPanels(true)
			self:UseItem(id)
		end
	end)
	self:connect(assets.Chooser.GiveBtn.Activated, function()
		self:ShowGiveTargets()
	end)
	self:connect(assets.Chooser.LeaveBtn.Activated, function()
		self:ShowAccept("Leave")
	end)
	self:connect(assets.Accept:WaitForChild("cancelBtn").Activated, function()
		self:CloseActionPanels(true)
	end)
	self:connect(assets.Accept:WaitForChild("acceptBtn").Activated, function()
		self:AcceptInteraction()
	end)
	local minusBtn = assets.Accept:FindFirstChild("minusBtn")
	local plusBtn = assets.Accept:FindFirstChild("plusBtn")
	local maxBtn = assets.Accept:FindFirstChild("maxBtn")
	local qtyBox = assets.Accept:WaitForChild("quantity")
	if minusBtn and minusBtn:IsA("GuiButton") then
		self:connect(minusBtn.Activated, function()
			local item = self:findItem(self._actionItemId)
			local current = tonumber(qtyBox.Text) or 1
			local maxVal = item and item.Amount or 1
			qtyBox.Text = tostring(math.clamp(current - 1, 1, maxVal))
		end)
	end
	if plusBtn and plusBtn:IsA("GuiButton") then
		self:connect(plusBtn.Activated, function()
			local item = self:findItem(self._actionItemId)
			local current = tonumber(qtyBox.Text) or 1
			local maxVal = item and item.Amount or 1
			qtyBox.Text = tostring(math.clamp(current + 1, 1, maxVal))
		end)
	end
	if maxBtn and maxBtn:IsA("GuiButton") then
		self:connect(maxBtn.Activated, function()
			local item = self:findItem(self._actionItemId)
			if item then
				qtyBox.Text = tostring(item.Amount)
			end
		end)
	end
	self._interactionStartedSubscription = self._events:Subscribe(self._names.InteractionStarted, function(event)
		self:PlayInteractionAnimation(event)
	end)
	self._interactionFinishedSubscription = self._events:Subscribe(self._names.InteractionFinished, function()
		self:StopInteractionAnimation()
	end)
	self._previewCamera = assets.CameraTemplate:Clone()
	self._previewCamera.Name = "InventoryPreviewCamera"
	self._previewCamera.Parent = assets.Viewport
	assets.Viewport.CurrentCamera = self._previewCamera
	assets.PreviewCamera = self._previewCamera
	self._previewDirty = true
	self._unsubscribe = self._events:Subscribe(self._names.Changed, function(snapshot)
		self._snapshot = snapshot
		local shouldAnimateInitialLoad = self._isOpen
			and (not self._hasReceivedSnapshot or not self._openSequencesStarted)
		self._hasReceivedSnapshot = true
		self:RefreshInventory(shouldAnimateInitialLoad)
		self:RefreshIdentityStatus()
	end)
	self._rejectSubscription = self._events:Subscribe(self._names.Rejected, function()
		self:RefreshInventory()
	end)
	self._weaponSubscription = self._events:Subscribe(self._names.WeaponChanged, function(event)
		self._equippedId = event.UniqueId
		self:RefreshHotbar()
	end)
	self._useStartedSubscription = self._events:Subscribe(self._names.UseStarted, function(event)
		self:PlayUseAnimation(event.ItemId)
	end)
	self._useFinishedSubscription = self._events:Subscribe(self._names.UseFinished, function()
		self:StopUseAnimation()
	end)
	self:connect(self._player.CharacterRemoving, function()
		self:StopUseAnimation()
	end)
	local function bindSlidePresentation(character)
		self:connect(character:GetAttributeChangedSignal("IsSliding"), function()
			if character:GetAttribute("IsSliding") ~= true or character:GetAttribute("IsUsingItem") ~= true then
				return
			end
			self:StopUseAnimation()
			self:sendCommand(self._names.SlideDuringUse)
		end)
	end
	if self._player.Character then
		bindSlidePresentation(self._player.Character)
	end
	self:connect(self._player.CharacterAdded, bindSlidePresentation)
	if assets.ToggleButton and assets.ToggleButton:IsA("GuiButton") then
		self:connect(assets.ToggleButton.Activated, function()
			self:ToggleOpen()
		end)
	end
	for name, button in pairs(assets.Categories) do
		self:connect(button.Activated, function()
			self._category = name
			self:RefreshInventory()
		end)
	end
	self:connect(self._input.InputBegan, function(input, processed)
		if
			self._isOpen
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local chooser = assets.Chooser
			local targets = assets.PlayerInrange
			local accept = assets.Accept
			if chooser.Visible or targets.Visible or accept.Visible then
				local position = Vector2.new(input.Position.X, input.Position.Y)
				local insidePanel = (chooser.Visible and isInside(chooser, position))
					or (targets.Visible and isInside(targets, position))
					or (accept.Visible and isInside(accept, position))
				if not insidePanel then
					self:CloseActionPanels(true)
				end
			end
		end
		if input.KeyCode == Enum.KeyCode.Escape and self._isOpen then
			if not self:IsTransitioning() then
				self:SetOpen(false)
			end
			return
		end
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.T then
			self:ToggleOpen()
		elseif KEY_SLOTS[input.KeyCode] then
			self:UseHotbar(KEY_SLOTS[input.KeyCode])
		end
	end)
	self:connect(assets.Search:GetPropertyChangedSignal("Text"), function()
		self:RefreshInventory()
	end)
	self:connect(self._input.InputChanged, function(input)
		if self._dragId and (input.UserInputType == Enum.UserInputType.MouseMovement or input == self._dragInput) then
			self:RefreshDragPosition(input.Position)
		end
	end)
	self:connect(self._input.InputEnded, function(input)
		if self._dragId and (input == self._dragInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
			self:OnDragEnded(input.Position)
		end
	end)
	self:connect(self._input.WindowFocusReleased, function()
		self:clearDrag()
	end)
	for index = 1, 6 do
		local slot = assets.Slots[index]
		slot.Frame.Active = true
		self:connect(slot.Frame.MouseEnter, function()
			if self._isOpen and self._snapshot.Slots["Slot" .. index] then
				assets.HoverSound:Play()
			end
		end)
		self:connect(slot.Frame.InputBegan, function(input)
			local id = self._snapshot.Slots["Slot" .. index]
			if self._isOpen and id then
				self:OnItemInput(id, "Slot" .. index, input, slot.Frame)
			elseif
				not self._isOpen
				and (
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				)
			then
				self:UseHotbar(index)
			end
		end)
		local hud = assets.HudHotbars[index]
		self:connect(hud.Button.Activated, function()
			self:UseHotbar(index)
		end)
		self:connect(hud.Button.MouseEnter, function()
			self._hudHovered[index] = true
			if hud.Button.Visible then
				assets.HoverSound:Play()
			end
			if not self._hudPopping[index] then
				self:playTween(
					hud.Scale,
					{ Scale = self:GetHotbarBaseScale(index) },
					0.12,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out
				)
			end
		end)
		self:connect(hud.Button.MouseLeave, function()
			self._hudHovered[index] = false
			if not self._hudPopping[index] then
				self:playTween(
					hud.Scale,
					{ Scale = self:GetHotbarBaseScale(index) },
					0.10,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out
				)
			end
		end)
	end
	for _, attributeName in ipairs({ "PlayerId", "Money", "Cash", "Bank" }) do
		self:connect(self._player:GetAttributeChangedSignal(attributeName), function()
			self:RefreshIdentityStatus()
		end)
	end
	self:connect(self._player.CharacterAdded, function(character)
		self:WatchPreviewCharacter(character)
		self._previewDirty = true
		self:RefreshCharacterPreview()
	end)
	self:connect(self._player.CharacterAppearanceLoaded, function(character)
		if character == self._player.Character then
			self._previewDirty = true
			self:RefreshCharacterPreview()
		end
	end)
	if self._player.Character then
		self:WatchPreviewCharacter(self._player.Character)
	end
	self:RefreshIdentityStatus()
	self:RefreshInventory()
	self:RefreshCharacterPreview()
end

--[[ <summary>Pop-animates an authored hotbar slot around its center with a small tilt.</summary> ]]
function InventoryView:animateSlot(index, delayTime, closing)
	local slot = self._assets.Slots[index]
	local original = self._slotOriginals and self._slotOriginals[index]
	if not slot or not original then
		return
	end
	local scale = original.Scale
	local angle = original.Rotation + 9
	if closing then
		self:playTween(scale, { Scale = 0.68 }, 0.16, Enum.EasingStyle.Back, Enum.EasingDirection.In, delayTime)
		self:playTween(
			slot.Frame,
			{ Rotation = angle },
			0.16,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.In,
			delayTime
		)
	else
		scale.Scale = 0.68
		slot.Frame.Rotation = angle
		self:playTween(scale, { Scale = 1 }, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out, delayTime)
		self:playTween(
			slot.Frame,
			{ Rotation = original.Rotation },
			0.28,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out,
			delayTime
		)
	end
end

function InventoryView:PlayUseAnimation(itemId)
	self:StopUseAnimation()
	local itemConfig = self._useConfig and self._useConfig.Items[itemId]
	local animation = self._useAnimations[itemId]
	local character = self._player and self._player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not itemConfig or not animation or not animator then
		return
	end
	if type(itemConfig.AnimationId) == "string" then
		animation.AnimationId = itemConfig.AnimationId
	end
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok or not track then
		warn("[InventoryView] Could not load inventory use animation: " .. tostring(track))
		return
	end
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = itemConfig.AnimationLooped == true
	self._useTrack = track
	track:Play(0.12)
end

function InventoryView:StopUseAnimation()
	local track = self._useTrack
	self._useTrack = nil
	if not track then
		return
	end
	if track.IsPlaying then
		track:Stop(0.12)
	end
	track:Destroy()
end

--[[ <summary>Keeps the equipped bottom HUD slot slightly larger between presses.</summary> ]]
function InventoryView:GetHotbarBaseScale(index)
	if self._indicatorSelected[index] then
		return if self._hudHovered[index] then 1.13 else 1.10
	end
	return if self._hudHovered[index] then 1.08 else 1
end

--[[ <summary>Pulses the pressed bottom HUD slot around its center, then restores its equipped size.</summary> ]]
function InventoryView:PopHotbar(index)
	local hud = self._assets.HudHotbars[index]
	local scale = hud.Scale
	self._hudPopping[index] = true
	self:playTween(scale, { Scale = 1.20 }, 0.10, Enum.EasingStyle.Back, Enum.EasingDirection.Out, nil, function()
		if self._disposed then
			return
		end
		self._hudPopping[index] = false
		self:playTween(
			scale,
			{ Scale = self:GetHotbarBaseScale(index) },
			0.14,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		)
	end)
end

function InventoryView:UseHotbar(index)
	if
		not self._canUseHotbar
		or self._inVehicle
		or self._isOpen
		or self._hotbarCooldownRemaining > 0
		or type(index) ~= "number"
		or index < 1
		or index > 6
		or index % 1 ~= 0
	then
		return
	end
	local id = self._snapshot.Slots["Slot" .. index]
	if id then
		self._hotbarCooldownRemaining = HOTBAR_SWITCH_COOLDOWN
		self:PopHotbar(index)
		local button = self._assets.HudHotbars[index].Button
		button.Rotation = 2
		self:playTween(button, { Rotation = 0 }, 0.22, Enum.EasingStyle.Back)
		self._assets.HotbarUseSound:Play()
		self:sendCommand(self._names.Use, id)
	end
end

--[[ <summary>Blocks player toggles until the current inventory opening or closing sequence has finished.</summary> ]]
function InventoryView:IsTransitioning()
	return self._isClosing
		or (
			self._isOpen
			and (
				self._transition > 0
				or not self._openSequencesStarted
				or self._loadingRows ~= nil
				or self._loadingSlots ~= nil
			)
		)
end

function InventoryView:ToggleOpen()
	if self:IsTransitioning() then
		return
	end
	self:SetOpen(not self._isOpen)
end

function InventoryView:SetOpen(isOpen)
	if isOpen and not self._canOpen then
		return
	end
	if self._isOpen == isOpen then
		return
	end
	local assets = self._assets
	self:CloseActionPanels(false)
	if isOpen then
		self._hideHotbarAfterInteraction = false
		self:CancelLoadingAnimation(false)
		self._isClosing = false
		self._openSequencesStarted = false
		self._storageClosing = false
	else
		self:CancelLoadingAnimation(false)
		self._isClosing = true
		self._openSequencesStarted = false
		self._storageClosing = false
	end
	self._isOpen = isOpen
	self:clearDrag()
	assets.Main.Visible = true
	assets.CharacterAndStatus.Visible = true
	assets.HotbarMain.Visible = self._canUseHotbar and not self._inVehicle
	if isOpen then
		self._transition = 0.34
		self:RefreshInventory(true)
		self:PrepareSlotReveal()
		if assets.OpenSound then
			assets.OpenSound:Play()
		end
		local compactSize = scaleUDim2(self._originalSize, 0.82)
		local compactPosition =
			centeredPosition(self._originalPosition, self._originalSize, compactSize, self._mainAnchorPoint)
		local compactCharacterSize = scaleUDim2(self._characterOriginalSize, 0.82)
		local compactCharacterPosition = centeredPosition(
			self._characterOriginalPosition,
			self._characterOriginalSize,
			compactCharacterSize,
			self._characterAnchorPoint
		)
		assets.Main.Size = compactSize
		assets.Main.Position = compactPosition
		assets.Main.Rotation = self._originalRotation + 3
		assets.CharacterAndStatus.Size = compactCharacterSize
		assets.CharacterAndStatus.Position = compactCharacterPosition
		assets.CharacterAndStatus.Rotation = self._characterOriginalRotation - 3
		self:playTween(
			assets.Main,
			{ Size = self._originalSize, Position = self._originalPosition, Rotation = self._originalRotation },
			0.20,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out,
			nil,
			function()
				if self._isOpen and not self._disposed then
					assets.BackdropScreen.Enabled = true
					assets.Dimmer.Visible = true
					assets.Dimmer.BackgroundTransparency = 1
					self:playTween(
						assets.Dimmer,
						{ BackgroundTransparency = 0.46 },
						0.18,
						Enum.EasingStyle.Quad,
						Enum.EasingDirection.Out
					)
					if assets.Blur then
						self:playTween(assets.Blur, { Size = 10 }, 0.18)
					end
					self._backdropShown = true
					self:StartOpenSequences()
				end
			end
		)
		self:playTween(assets.CharacterAndStatus, {
			Size = self._characterOriginalSize,
			Position = self._characterOriginalPosition,
			Rotation = self._characterOriginalRotation,
		}, 0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	else
		self._transition = 0
		self:PrepareCloseSequences()
		self:CheckCloseSequences()
	end
end

--[[ <summary>Begins hotbar slot and inventory item reveals after the Storage panel finishes opening.</summary> ]]
function InventoryView:StartOpenSequences()
	if not self._isOpen or self._disposed then
		return
	end
	self._openSequencesStarted = true
	self._loadingSlotsNextIndex = 1
	self._loadingRowsNextIndex = 1
	self._loadingSlotsAnimating = 0
	self._loadingRowsAnimating = 0
end

function InventoryView:clearDrag()
	if self._dragGhost then
		self._dragGhost:Destroy()
		self._dragGhost = nil
	end
	self._dragId = nil
	self._dragSource = nil
	self._dragInput = nil
	self._dragStartPosition = nil
	self._dragTarget = nil
end

--[[ <summary>Shows the authored item preview only after a click becomes a drag.</summary> ]]
function InventoryView:RefreshDragPosition(position)
	if not self._dragId or not self._dragStartPosition or not self._isOpen then
		return
	end
	if (position - self._dragStartPosition).Magnitude < 10 then
		return
	end
	local ghost = self._dragGhost
	if not ghost then
		local item = self:findItem(self._dragId)
		local info = item and self._catalog[item.ItemID]
		if not info then
			return
		end
		ghost = self._assets.DragTemplate:Clone()
		ghost.Name = "InventoryDragPreview"
		local icon = ghost:WaitForChild("ItemIcon")
		if type(info.Image) == "string" and info.Image ~= "" then
			icon.Image = info.Image
		end
		ghost.Visible = false
		ghost.Parent = self._assets.Screen
		self._dragGhost = ghost
	end
	local touchOffset = if self._dragInput and self._dragInput.UserInputType == Enum.UserInputType.Touch then 58 else 0
	ghost.Position = UDim2.fromOffset(position.X, position.Y - touchOffset)
	ghost.Visible = true
end

function InventoryView:clearInteractionRows()
	for _, connection in ipairs(self._interactionConnections) do
		connection:Disconnect()
	end
	table.clear(self._interactionConnections)
	for _, row in ipairs(self._interactionRows) do
		row:Destroy()
	end
	table.clear(self._interactionRows)
end

function InventoryView:CloseActionPanels(restoreStatus)
	self._interactionGeneration += 1
	self:clearInteractionRows()
	local assets = self._assets
	assets.Chooser.Visible = false
	assets.PlayerInrange.Visible = false
	assets.Accept.Visible = false
	if restoreStatus and self._isOpen then
		assets.CharacterAndStatus.Visible = true
	end
	self._actionItemId = nil
	self._actionMode = nil
	self._targetUserId = nil
end

function InventoryView:ShowChooser(id, itemGui)
	local item = self:findItem(id)
	local info = item and self._catalog[item.ItemID]
	if not item or not info then
		return
	end
	self:CloseActionPanels(true)
	local assets = self._assets
	self._actionItemId = id
	assets.CharacterAndStatus.Visible = true
	assets.Chooser.Visible = true
	assets.Chooser.UseBtn.Visible = info.UseAction ~= nil or info.Type == "Food" or info.Type == "Weapon"
	assets.Chooser.GiveBtn.Visible = info.CanGive == true
	assets.Chooser.LeaveBtn.Visible = info.CanLeave == true and not info.Permanent
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local menuSize = assets.Chooser.AbsoluteSize
	if menuSize.X <= 0 then
		menuSize = Vector2.new(viewport.X * assets.Chooser.Size.X.Scale, viewport.Y * assets.Chooser.Size.Y.Scale)
	end
	local anchor = itemGui or assets.Scroll
	local anchorPos, anchorSize = anchor.AbsolutePosition, anchor.AbsoluteSize
	local x = anchorPos.X + anchorSize.X + 8
	if x + menuSize.X > viewport.X then
		x = anchorPos.X - menuSize.X - 8
	end
	x = math.clamp(x, 8, math.max(8, viewport.X - menuSize.X - 8))
	local y = math.clamp(anchorPos.Y, 8, math.max(8, viewport.Y - menuSize.Y - 8))
	assets.Chooser.Position = UDim2.fromOffset(x, y)
end

function InventoryView:ShowGiveTargets()
	local item = self:findItem(self._actionItemId)
	local info = item and self._catalog[item.ItemID]
	if not item or not info or info.CanGive ~= true then
		self:CloseActionPanels(true)
		return
	end
	self._interactionGeneration += 1
	local interactionGeneration = self._interactionGeneration
	self:clearInteractionRows()
	self._actionMode = "Give"
	self._assets.Chooser.Visible = false
	self._assets.Accept.Visible = false
	local character = self._player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		self:CloseActionPanels(true)
		return
	end
	local nearby = {}
	for _, candidate in ipairs(self._players:GetPlayers()) do
		if candidate ~= self._player then
			local targetCharacter = candidate.Character
			local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
			local humanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
			if targetRoot and humanoid and humanoid.Health > 0 then
				local distance = (root.Position - targetRoot.Position).Magnitude
				if distance <= self._interactionConfig.TargetRangeStuds then
					table.insert(nearby, { Player = candidate, Distance = distance })
				end
			end
		end
	end
	table.sort(nearby, function(a, b)
		return a.Distance < b.Distance
	end)
	local maxTargets = self._interactionConfig.MaxVisibleTargets
	local count = math.min(#nearby, maxTargets)
	if count == 0 then
		self:CloseActionPanels(true)
		return
	end
	self._assets.CharacterAndStatus.Visible = true
	self._assets.PlayerInrange.Visible = true
	for index = 1, count do
		local target = nearby[index].Player
		local row = self._assets.PlayerRangeTemplate:Clone()
		row.Name = "NearbyPlayer_" .. tostring(target.UserId)
		row.Visible = true
		row.LayoutOrder = index
		row:SetAttribute("TargetUserId", target.UserId)
		row:SetAttribute("TargetDisplayName", target.DisplayName)
		local fallback = row:FindFirstChild("FallbackName")
		if fallback and fallback:IsA("TextLabel") then
			fallback.Text = string.upper(string.sub(target.Name, 1, 1))
			fallback.Visible = true
		end
		row.Image = ""
		row.Parent = self._assets.PlayerRangeScroll
		table.insert(self._interactionRows, row)
		local connection = row.Activated:Connect(function()
			self:ShowAccept("Give", target.UserId)
		end)
		table.insert(self._interactionConnections, connection)
		local avatarUserId = if target.UserId > 0 then target.UserId else target.CharacterAppearanceId
		if type(avatarUserId) == "number" and avatarUserId > 0 then
			task.spawn(function()
				for _ = 1, 6 do
					local ok, thumbnail, ready = pcall(function()
						return self._players:GetUserThumbnailAsync(
							avatarUserId,
							Enum.ThumbnailType.HeadShot,
							Enum.ThumbnailSize.Size100x100
						)
					end)
					if
						self._disposed
						or self._interactionGeneration ~= interactionGeneration
						or self._actionMode ~= "Give"
						or not row.Parent
					then
						return
					end
					if ok and type(thumbnail) == "string" and thumbnail ~= "" then
						row.Image = thumbnail
					end
					if ok and ready then
						if fallback then
							fallback.Visible = false
						end
						return
					end
					task.wait(0.5)
				end
			end)
		end
	end
end

function InventoryView:ShowAccept(action, targetUserId)
	self._interactionGeneration += 1
	local item = self:findItem(self._actionItemId)
	local info = item and self._catalog[item.ItemID]
	if not item or not info then
		self:CloseActionPanels(true)
		return
	end
	if action == "Give" and info.CanGive ~= true then
		self:CloseActionPanels(true)
		return
	end
	if action == "Leave" and (info.CanLeave ~= true or info.Permanent) then
		self:CloseActionPanels(true)
		return
	end
	self:clearInteractionRows()
	self._actionMode = action
	self._targetUserId = targetUserId
	self._assets.Chooser.Visible = false
	self._assets.PlayerInrange.Visible = false
	self._assets.CharacterAndStatus.Visible = true
	self._assets.Accept.Visible = true
	self._assets.Accept:WaitForChild("itemName").Text = info.Name
	self._assets.Accept:WaitForChild("quantity").Text = "1"
end

function InventoryView:AcceptInteraction()
	local item = self:findItem(self._actionItemId)
	local action = self._actionMode
	local amount = tonumber(self._assets.Accept:WaitForChild("quantity").Text)
	if
		not item
		or (action ~= "Give" and action ~= "Leave")
		or type(amount) ~= "number"
		or amount % 1 ~= 0
		or amount < 1
		or amount > item.Amount
	then
		return
	end
	if action == "Give" then
		if not self._targetUserId then
			return
		end
		self:sendCommand(self._names.Give, item.UUID, nil, { TargetUserId = self._targetUserId, Amount = amount })
	else
		self:sendCommand(self._names.Leave, item.UUID, nil, { Amount = amount })
	end
	self._hideHotbarAfterInteraction = true
	self:CloseActionPanels(true)
	if self._isOpen then
		self:SetOpen(false)
	end
	local assets = self._assets
	assets.Main.Visible = false
	assets.CharacterAndStatus.Visible = false
	assets.HotbarMain.Visible = false
	assets.Dimmer.Visible = false
	assets.BackdropScreen.Enabled = false
	if assets.Blur then
		assets.Blur.Size = 0
	end
end

function InventoryView:PlayInteractionAnimation(event)
	local config = self._interactionConfig
	if not config or type(event) ~= "table" then
		return
	end
	local key = if event.Action == "Leave"
		then "LeaveAnimationId"
		elseif event.Role == "Receiver" then "ReceiveAnimationId"
		else "GiveAnimationId"
	local animationId = config[key]
	if type(animationId) ~= "string" or animationId == "" then
		return
	end
	self:StopInteractionAnimation()
	local character = self._player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	animation:Destroy()
	if ok and track then
		track.Priority = Enum.AnimationPriority.Action
		track:Play(0.12)
		self._interactionTrack = track
	end
end

function InventoryView:StopInteractionAnimation()
	local track = self._interactionTrack
	self._interactionTrack = nil
	if track then
		if track.IsPlaying then
			track:Stop(0.12)
		end
		track:Destroy()
	end
end

function InventoryView:UseItem(id)
	local item = self:findItem(id)
	local info = item and self._catalog[item.ItemID]
	if not item or not info then
		return
	end
	if info.Type == "Weapon" then
		local assigned = false
		local emptySlot
		for index = 1, 6 do
			local slotName = "Slot" .. index
			if self._snapshot.Slots[slotName] == id then
				assigned = true
			end
			if not self._snapshot.Slots[slotName] and not emptySlot then
				emptySlot = slotName
			end
		end
		if not assigned then
			if not emptySlot then
				return
			end
			self:sendCommand(self._names.Move, id, emptySlot)
			self:animateSlot(tonumber(string.match(emptySlot, "%d+")))
			self._assets.DropSound:Play()
		end
	end
	self._assets.UseSound:Play()
	self:sendCommand(self._names.Use, id)
end

function InventoryView:OnItemInput(id, source, input, itemGui)
	if not self._isOpen then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		self:ShowChooser(id, itemGui)
	elseif
		not self._dragId
		and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
	then
		if not self:findItem(id) then
			return
		end
		self._dragId, self._dragSource, self._dragInput = id, source, input
		self._dragTarget = itemGui
		self._dragStartPosition = input.Position
	end
end

function InventoryView:OnDragEnded(position)
	local id, source, startPosition = self._dragId, self._dragSource, self._dragStartPosition
	if not id or not startPosition then
		self:clearDrag()
		return
	end
	local wasDragged = (position - startPosition).Magnitude >= 10
	if not wasDragged then
		self:ShowChooser(id, self._dragTarget)
		self:clearDrag()
		return
	end
	local destination
	for index, slot in ipairs(self._assets.Slots) do
		if isInside(slot.Frame, position) then
			destination = "Slot" .. index
			break
		end
	end
	if destination then
		self:sendCommand(self._names.Move, id, destination)
		self:animateSlot(tonumber(string.match(destination, "%d+")))
		if self._assets.DropSound then
			self._assets.DropSound:Play()
		end
	elseif source ~= "Scroll" then
		self:sendCommand(self._names.RemoveSlot, nil, source)
	end
	self:clearDrag()
end

--[[ <summary>Cancels queued reveal and hide sequences, optionally restoring each authored element.</summary> ]]
function InventoryView:CancelLoadingAnimation(restore, preserveSlots)
	for _, queueName in ipairs({ "_loadingRows", "_loadingSlots", "_closingRows", "_closingSlots" }) do
		local isSlotQueue = string.find(queueName, "Slots", 1, true) ~= nil
		if not (preserveSlots and isSlotQueue) then
			local entries = self[queueName]
			if entries then
				for _, entry in ipairs(entries) do
					for _, object in ipairs({ entry.Frame, entry.Scale }) do
						local tween = object and self._tweens[object]
						if tween then
							self._tweens[object] = nil
							tween:Cancel()
							tween:Destroy()
						end
					end
					if restore and entry.Frame.Parent then
						entry.Scale.Scale = 1
						entry.Frame.Rotation = entry.Rotation
						entry.Frame.Visible = entry.Visible
					end
				end
			end
			self[queueName] = nil
			self[queueName .. "Elapsed"] = nil
		end
	end
	for _, name in ipairs({ "_loadingRows", "_loadingSlots", "_closingRows", "_closingSlots" }) do
		local isSlotQueue = string.find(name, "Slots", 1, true) ~= nil
		if not (preserveSlots and isSlotQueue) then
			self[name .. "NextIndex"] = 1
			self[name .. "Animating"] = 0
		end
	end
end

--[[ <summary>Prepares authored hotbar slots as hidden entries for the ordered opening reveal.</summary> ]]
function InventoryView:PrepareSlotReveal()
	local entries = {}
	for index, slot in ipairs(self._assets.Slots) do
		local original = self._slotOriginals[index]
		local frame, scale = slot.Frame, original.Scale
		table.insert(
			entries,
			{ Frame = frame, Scale = scale, Rotation = original.Rotation, Visible = original.Visible }
		)
		scale.Scale = 0.68
		frame.Rotation = original.Rotation + 9
		frame.Visible = false
	end
	self._loadingSlots = if #entries > 0 then entries else nil
	self._loadingSlotsNextIndex = 1
	self._loadingSlotsAnimating = 0
end

--[[ <summary>Builds reverse-order close queues for visible inventory rows and authored slots.</summary> ]]
function InventoryView:PrepareCloseSequences()
	local rows, slots = {}, {}
	for index = #self._rows, 1, -1 do
		local frame = self._rows[index]
		local scale = frame:FindFirstChild("OpenScale")
		if frame.Visible and scale and scale:IsA("UIScale") then
			table.insert(rows, { Frame = frame, Scale = scale, Rotation = frame.Rotation, Visible = true })
		end
	end
	for index = #self._assets.Slots, 1, -1 do
		local frame = self._assets.Slots[index].Frame
		local original = self._slotOriginals[index]
		if frame.Visible then
			table.insert(slots, { Frame = frame, Scale = original.Scale, Rotation = frame.Rotation, Visible = true })
		end
	end
	self._closingRows = if #rows > 0 then rows else nil
	self._closingSlots = if #slots > 0 then slots else nil
	self._closingRowsNextIndex = 1
	self._closingSlotsNextIndex = 1
	self._closingRowsAnimating = 0
	self._closingSlotsAnimating = 0
end

--[[ <summary>Starts each authored row in order using a visible time gap while capping long lists.</summary> ]]
function InventoryView:UpdateSequence(queueName, indexName, animatingName, closing, deltaTime)
	local entries = self[queueName]
	local canRun = if closing
		then self._isClosing
		else self._isOpen and not self._isClosing and self._openSequencesStarted
	if not canRun or not entries then
		return
	end
	local elapsedName = queueName .. "Elapsed"
	local elapsed = (self[elapsedName] or 0) + math.max(0, deltaTime)
	self[elapsedName] = elapsed
	local itemGap = if closing then SEQUENCE_CLOSE_ITEM_GAP_SECONDS else SEQUENCE_ITEM_GAP_SECONDS
	local maxCascade = if closing then SEQUENCE_CLOSE_MAX_CASCADE_SECONDS else SEQUENCE_MAX_CASCADE_SECONDS
	local gap = math.min(itemGap, maxCascade / #entries)
	local lastDueIndex = math.min(#entries, 1 + math.floor(elapsed / gap))
	local index = self[indexName] or 1
	local started = 0
	while started < SEQUENCE_MAX_STARTS_PER_FRAME and index <= lastDueIndex do
		local entry = entries[index]
		index += 1
		started += 1
		self[animatingName] = (self[animatingName] or 0) + 1
		if not closing then
			entry.Frame.Visible = true
		end
		local targetScale = if closing then 0.68 else 1
		local targetRotation = if closing then entry.Rotation + 9 else entry.Rotation
		local easingDirection = if closing then Enum.EasingDirection.In else Enum.EasingDirection.Out
		local duration = if closing then SEQUENCE_CLOSE_SECONDS else SEQUENCE_OPEN_SECONDS
		self:playTween(
			entry.Scale,
			{ Scale = targetScale },
			duration,
			Enum.EasingStyle.Back,
			easingDirection,
			nil,
			function()
				if self[queueName] ~= entries then
					return
				end
				if closing then
					entry.Frame.Visible = false
				end
				self[animatingName] -= 1
				if self[indexName] > #entries and self[animatingName] == 0 then
					self[queueName] = nil
					self[elapsedName] = nil
					if closing then
						self:CheckCloseSequences()
					end
				end
			end
		)
		self:playTween(entry.Frame, { Rotation = targetRotation }, duration, Enum.EasingStyle.Back, easingDirection)
	end
	self[indexName] = index
end

--[[ <summary>Starts storage close only after both reverse-order child sequences have finished.</summary> ]]
function InventoryView:CheckCloseSequences()
	if self._isClosing and not self._storageClosing and self._closingRows == nil and self._closingSlots == nil then
		self:BeginStorageClose()
	end
end

--[[ <summary>Animates Storage out after all item templates and hotbar slots have closed.</summary> ]]
function InventoryView:BeginStorageClose()
	if not self._isClosing or self._storageClosing then
		return
	end
	self._storageClosing = true
	self._transition = 0.10
	local assets = self._assets
	local compactSize = scaleUDim2(self._originalSize, 0.82)
	local compactPosition =
		centeredPosition(self._originalPosition, self._originalSize, compactSize, self._mainAnchorPoint)
	local compactCharacterSize = scaleUDim2(self._characterOriginalSize, 0.82)
	local compactCharacterPosition = centeredPosition(
		self._characterOriginalPosition,
		self._characterOriginalSize,
		compactCharacterSize,
		self._characterAnchorPoint
	)
	if assets.CloseSound then
		assets.CloseSound:Play()
	end
	self:playTween(
		assets.Main,
		{ Size = compactSize, Position = compactPosition, Rotation = self._originalRotation - 3 },
		0.10,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.In
	)
	self:playTween(assets.CharacterAndStatus, {
		Size = compactCharacterSize,
		Position = compactCharacterPosition,
		Rotation = self._characterOriginalRotation + 3,
	}, 0.10, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	self:playTween(
		assets.Dimmer,
		{ BackgroundTransparency = 1 },
		0.10,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.In,
		nil,
		function()
			if not self._isOpen and not self._disposed then
				assets.Dimmer.Visible = false
				assets.BackdropScreen.Enabled = false
				self._backdropShown = false
			end
		end
	)
	if assets.Blur then
		self:playTween(assets.Blur, { Size = 0 }, 0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
end

--[[ <summary>Runs row and slot cascades concurrently with a timed stagger.</summary> ]]
function InventoryView:UpdateLoadingAnimation(deltaTime)
	self:UpdateSequence("_loadingRows", "_loadingRowsNextIndex", "_loadingRowsAnimating", false, deltaTime)
	self:UpdateSequence("_loadingSlots", "_loadingSlotsNextIndex", "_loadingSlotsAnimating", false, deltaTime)
	self:UpdateSequence("_closingRows", "_closingRowsNextIndex", "_closingRowsAnimating", true, deltaTime)
	self:UpdateSequence("_closingSlots", "_closingSlotsNextIndex", "_closingSlotsAnimating", true, deltaTime)
end

function InventoryView:RefreshInventory(animateLoading)
	-- A snapshot, search change, or rejection can arrive mid-close. Rebuilding rows here
	-- cancels the close tweens and leaves _isClosing true with no sequence to finish it.
	-- Keep the latest snapshot; SetOpen(true) rebuilds the rows on the next opening.
	if self._isClosing then
		self:RefreshHotbar()
		return
	end
	local assets = self._assets
	self:CancelLoadingAnimation(true, true)
	self:clearDrag()
	for _, connection in ipairs(self._rowConnections) do
		connection:Disconnect()
	end
	table.clear(self._rowConnections)
	for _, row in ipairs(self._rows) do
		local rowObjects = row:GetDescendants()
		table.insert(rowObjects, row)
		for _, object in ipairs(rowObjects) do
			local tween = self._tweens[object]
			if tween then
				tween:Cancel()
				tween:Destroy()
				self._tweens[object] = nil
			end
		end
		row:Destroy()
	end
	table.clear(self._rows)
	local filter = CATEGORY_TYPES[self._category]
	local search = string.lower(assets.Search.Text)
	local loadingRows = {}
	for index, item in ipairs(self._snapshot.Items) do
		local info = self._catalog[item.ItemID]
		local matchesSearch = search == ""
			or string.find(string.lower(info and info.Name or ""), search, 1, true)
			or string.find(string.lower(item.ItemID), search, 1, true)
		local matchesCategory = not filter or (info and info.Type == filter)
		if info and matchesSearch and matchesCategory then
			local row = assets.Template:Clone()
			row.Name = "InventoryItem_" .. tostring(index)
			row.LayoutOrder = index
			row.Active = true
			local visual = row:WaitForChild("Visual")
			local itemName = visual:WaitForChild("ItemName")
			local itemAmount = visual:WaitForChild("ItemAmount")
			local itemDecal = visual:WaitForChild("ItemDecal")
			itemName.Text = info.Name
			itemAmount.Text = item.Amount > 1 and ("x" .. tostring(item.Amount)) or ""
			local hasImage = type(info.Image) == "string" and info.Image ~= ""
			itemDecal.Image = hasImage and info.Image or ""
			itemDecal.Visible = hasImage
			local fallbackIcon = visual:FindFirstChild("FallbackIcon")
			if fallbackIcon and fallbackIcon:IsA("TextLabel") then
				fallbackIcon.Visible = not hasImage
				fallbackIcon.Text = string.upper(string.sub(item.ItemID, 1, 2))
			end
			local cardStroke = visual:FindFirstChildOfClass("UIStroke")
			local slotBadge = visual:FindFirstChild("SlotBadge")
			local assignedSlotNum = nil
			for slotKey, equippedId in pairs(self._snapshot.Slots) do
				if equippedId == item.UUID then
					itemName.TextColor3 = Color3.fromRGB(255, 204, 42)
					assignedSlotNum = string.match(slotKey, "%d+")
					break
				end
			end
			if cardStroke then
				cardStroke.Color = if assignedSlotNum then Color3.fromRGB(220, 162, 3) else Color3.fromRGB(58, 58, 68)
				cardStroke.Thickness = if assignedSlotNum then 2 else 1
			end
			if slotBadge and slotBadge:IsA("TextLabel") then
				slotBadge.Visible = assignedSlotNum ~= nil
				slotBadge.Text = assignedSlotNum and ("#" .. assignedSlotNum) or ""
			end
			local loadingEntry
			if animateLoading then
				local openScale = row:FindFirstChild("OpenScale")
				assert(openScale and openScale:IsA("UIScale"), "Missing authored OpenScale on ItemTemplate")
				loadingEntry = { Frame = row, Scale = openScale, Rotation = row.Rotation, Visible = true }
				openScale.Scale = 0.68
				row.Rotation = row.Rotation + 9
				row.Visible = false
			else
				row.Visible = true
			end
			row.Parent = assets.Scroll
			table.insert(self._rows, row)
			if loadingEntry then
				table.insert(loadingRows, loadingEntry)
			end
			self:connect(row.InputBegan, function(input)
				self:OnItemInput(item.UUID, "Scroll", input, row)
			end, true)
			local hoverScale = visual:WaitForChild("HoverScale")
			assert(hoverScale:IsA("UIScale"), "Missing authored HoverScale on ItemTemplate.Visual")
			local normalZIndex = row.ZIndex
			self:connect(row.MouseEnter, function()
				if assets.HoverSound then
					assets.HoverSound:Play()
				end
				row.ZIndex = normalZIndex + 10
				self:playTween(hoverScale, { Scale = 1.08 }, 0.13, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			end, true)
			self:connect(row.MouseLeave, function()
				row.ZIndex = normalZIndex
				self:playTween(hoverScale, { Scale = 1 }, 0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			end, true)
		end
	end
	if animateLoading and #loadingRows > 0 then
		self._loadingRows = loadingRows
		self._loadingRowsNextIndex = 1
		self._loadingRowsAnimating = 0
	end
	assets.Count.Text = string.format("ITEMS: %d / 2000", #self._snapshot.Items)
	for name, button in pairs(assets.Categories) do
		local isSelected = (name == self._category)
		button.BackgroundColor3 = if isSelected then Color3.fromRGB(220, 162, 3) else Color3.fromRGB(32, 32, 40)
		button.BackgroundTransparency = if isSelected then 0.1 else 0.35
		local stroke = button:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = if isSelected then Color3.fromRGB(255, 215, 64) else Color3.fromRGB(64, 64, 78)
			stroke.Thickness = if isSelected then 1.5 else 1
		end
	end
	self:RefreshHotbar()
end

--[[ <summary>Shows only assigned hotbar items, centers the group, and animates selection and layout changes.</summary> ]]
function InventoryView:RefreshHotbar()
	local assets = self._assets
	local visibleEntries = {}
	local canShow = self._canUseHotbar and not self._inVehicle
	for index, slot in ipairs(assets.Slots) do
		local slotId = self._snapshot.Slots["Slot" .. index]
		local item = self:findItem(slotId)
		local info = item and self._catalog[item.ItemID]
		slot.Decal.Image = if info then info.Image or "" else ""
		slot.Decal.Visible = info ~= nil
		slot.Decal.ImageTransparency = if info then 0 else 1
		if slot.Amount then
			slot.Amount.Text = item and item.Amount > 1 and tostring(item.Amount) or ""
		end

		local hud = assets.HudHotbars[index]
		local button = hud.Button
		local hadBeenVisible = button.Visible
		local hasItem = item ~= nil and info ~= nil
		local shouldShow = canShow and hasItem
		button.LayoutOrder = index
		hud.Icon.Image = if info then info.Image or "" else ""
		hud.Icon.ImageTransparency = if info and info.Image and info.Image ~= "" then 0 else 1
		if hud.Amount then
			hud.Amount.Text = item and item.Amount > 1 and tostring(item.Amount) or ""
		end
		local selected = shouldShow and slotId == self._equippedId
		local indicator = hud.Indicator
		local original = self._hudOriginals[index]
		if self._indicatorSelected[index] ~= selected then
			self._indicatorSelected[index] = selected
			button.BackgroundColor3 = original.ButtonColor
			if shouldShow and not self._hudPopping[index] then
				self:playTween(
					hud.Scale,
					{ Scale = self:GetHotbarBaseScale(index) },
					0.14,
					Enum.EasingStyle.Back,
					Enum.EasingDirection.Out
				)
			end
			hud.NumberLabel.BackgroundColor3 = original.NumberColor
			indicator.BackgroundColor3 = original.IndicatorColor
			local collapsedSize = UDim2.new(0, 0, original.IndicatorSize.Y.Scale, original.IndicatorSize.Y.Offset)
			if selected then
				indicator.Visible = true
				self:playTween(
					indicator,
					{ Size = original.IndicatorSize },
					0.18,
					Enum.EasingStyle.Back,
					Enum.EasingDirection.Out
				)
			elseif indicator.Visible then
				self:playTween(
					indicator,
					{ Size = collapsedSize },
					0.13,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.In,
					nil,
					function()
						if not self._indicatorSelected[index] then
							indicator.Visible = false
							indicator.Size = original.IndicatorSize
						end
					end
				)
			end
		end
		if shouldShow then
			table.insert(visibleEntries, { Button = button, Index = index, WasVisible = hadBeenVisible })
		else
			button.Visible = false
			if hud.Scale then
				hud.Scale.Scale = 1
			end
		end
	end

	self._hasHotbarItems = #visibleEntries > 0
	local frameWidth = assets.HudMain.AbsoluteSize.X
	if frameWidth <= 0 then
		local camera = workspace.CurrentCamera
		frameWidth = camera and camera.ViewportSize.X * assets.HudMain.Size.X.Scale or 400
	end
	local firstButton = visibleEntries[1] and visibleEntries[1].Button
	-- Use the authored width so a selected button's UIScale never shifts the whole HUD group.
	local buttonWidth = firstButton and (firstButton.Size.X.Offset + firstButton.Size.X.Scale * frameWidth) or 0
	local gap = if #visibleEntries > 1
		then math.min(8, math.max(2, (frameWidth - buttonWidth * #visibleEntries) / (#visibleEntries - 1)))
		else 0
	local groupWidth = buttonWidth * #visibleEntries + gap * math.max(0, #visibleEntries - 1)
	local startX = math.max(0, (frameWidth - groupWidth) * 0.5)
	for order, entry in ipairs(visibleEntries) do
		local button = entry.Button
		local original = self._hudOriginals[entry.Index]
		local targetPosition = UDim2.new(
			0,
			startX + buttonWidth * button.AnchorPoint.X + (order - 1) * (buttonWidth + gap),
			original.Position.Y.Scale,
			original.Position.Y.Offset
		)
		if not entry.WasVisible then
			button.Position = targetPosition
			if original.Scale then
				original.Scale.Scale = 0.82
			end
			button.Visible = true
			if original.Scale then
				self:playTween(
					original.Scale,
					{ Scale = self:GetHotbarBaseScale(entry.Index) },
					0.18,
					Enum.EasingStyle.Back,
					Enum.EasingDirection.Out
				)
			end
		else
			button.Visible = true
			if button.Position ~= targetPosition then
				self:playTween(
					button,
					{ Position = targetPosition },
					0.18,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out
				)
			end
		end
	end
	assets.HudMain.Visible = canShow and self._hasHotbarItems and not (self._isOpen or self._isClosing)
end

function InventoryView:RefreshIdentityStatus()
	local player = self._player
	if not player then
		return
	end
	self._assets.PlayerName.Text = player.DisplayName ~= "" and player.DisplayName or player.Name
	self._assets.PlayerId.Text = "ID: " .. tostring(player:GetAttribute("PlayerId") or "0000")
	local money = 0
	for _, item in ipairs(self._snapshot.Items) do
		if item.ItemID == "cash" then
			money += item.Amount
		end
	end
	local bank = player:GetAttribute("Bank")
	self._assets.Money.Text = string.format("Money: %06d", money)
	if type(bank) == "number" then
		self._assets.Bank.Text = string.format("Bank: %06d", math.max(0, math.floor(bank)))
	end
end

function InventoryView:WatchPreviewCharacter(character)
	for _, connection in ipairs(self._previewConnections or {}) do
		connection:Disconnect()
	end
	self._previewConnections = {}
	if character then
		table.insert(
			self._previewConnections,
			character.ChildAdded:Connect(function()
				self._previewDirty = true
			end)
		)
		table.insert(
			self._previewConnections,
			character.ChildRemoved:Connect(function()
				self._previewDirty = true
			end)
		)
	end
	self._previewCharacterSource = character
end

--[[ <summary>Builds a stable descendant path for matching live character parts to their viewport copies.</summary> ]]
local function getRelativeInstancePath(root, instance)
	local segments = {}
	local current = instance
	while current and current ~= root do
		table.insert(segments, 1, current.Name)
		current = current.Parent
	end
	return table.concat(segments, "/")
end

function InventoryView:RefreshCharacterPreview()
	if self._disposed or not self._previewDirty then
		return
	end
	self._previewDirty = false
	local assets = self._assets
	if self._previewModel then
		self._previewModel:Destroy()
		self._previewModel = nil
	end
	self._previewPartPairs = nil
	self._previewSourceRoot = nil
	self._previewTargetRoot = nil
	self._previewTargetRootCFrame = nil
	for _, object in ipairs(assets.PreviewWorld:GetChildren()) do
		object:Destroy()
	end
	local character = self._player.Character
	if not character then
		return
	end
	local oldArchivable = character.Archivable
	character.Archivable = true
	local cloneSucceeded, clone = pcall(function()
		return character:Clone()
	end)
	character.Archivable = oldArchivable
	if not cloneSucceeded or not clone then
		warn("[InventoryView] Could not clone the current character for the viewport.")
		return
	end
	clone.Name = "InventoryCharacterPreview"
	for _, object in ipairs(clone:GetDescendants()) do
		if object:IsA("BaseScript") then
			object:Destroy()
		elseif object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = false
			if object.Name == "HumanoidRootPart" then
				object.Transparency = 1
			end
		end
	end
	local humanoid = clone:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	local sourcePivot = character:GetPivot()
	clone:PivotTo(CFrame.new(0, 0, 0) * (sourcePivot - sourcePivot.Position))
	clone.Parent = assets.PreviewWorld
	self._previewModel = clone
	local sourceRoot = character:FindFirstChild("HumanoidRootPart")
	local previewRoot = clone:FindFirstChild("HumanoidRootPart")
	self._previewPartPairs = {}
	if sourceRoot and previewRoot then
		local previewParts = {}
		for _, object in ipairs(clone:GetDescendants()) do
			if object:IsA("BasePart") then
				previewParts[getRelativeInstancePath(clone, object)] = object
			end
		end
		for _, sourcePart in ipairs(character:GetDescendants()) do
			if sourcePart:IsA("BasePart") then
				local previewPart = previewParts[getRelativeInstancePath(character, sourcePart)]
				if previewPart then
					table.insert(self._previewPartPairs, { Source = sourcePart, Preview = previewPart })
				end
			end
		end
		self._previewSourceRoot = sourceRoot
		self._previewTargetRoot = previewRoot
		self._previewTargetRootCFrame = previewRoot.CFrame
	end
	local bounds, size = clone:GetBoundingBox()
	local center = bounds.Position + Vector3.new(0, size.Y * 0.04, 0)
	local distance = math.max(size.X * 1.5, size.Y * 2.05, size.Z * 2.6, 6)
	assets.PreviewCamera.FieldOfView = 35
	local facingDirection = clone:GetPivot().LookVector
	local cameraPosition = center + facingDirection * distance + Vector3.new(0, size.Y * 0.04, 0)
	local cameraRight = CFrame.lookAt(cameraPosition, center).RightVector
	local focus = center + cameraRight * size.X * 0.33
	assets.PreviewCamera.CFrame = CFrame.lookAt(cameraPosition, focus)
	assets.Viewport.CurrentCamera = assets.PreviewCamera
	self:SynchronizeCharacterPreview()
end

--[[ <summary>Copies the live character pose to the anchored viewport model while preserving its preview position.</summary> ]]
function InventoryView:SynchronizeCharacterPreview()
	local sourceRoot = self._previewSourceRoot
	local targetRoot = self._previewTargetRoot
	local pairsList = self._previewPartPairs
	if not sourceRoot or not targetRoot or not sourceRoot.Parent or not targetRoot.Parent or not pairsList then
		return
	end
	local sourceRootCFrame = sourceRoot.CFrame
	local targetRootCFrame = self._previewTargetRootCFrame
	for _, pair in ipairs(pairsList) do
		if pair.Source.Parent and pair.Preview.Parent then
			pair.Preview.CFrame = targetRootCFrame * sourceRootCFrame:ToObjectSpace(pair.Source.CFrame)
		end
	end
end

function InventoryView:UpdateLogic(deltaTime)
	self._hotbarCooldownRemaining = math.max(0, self._hotbarCooldownRemaining - deltaTime)
	self:UpdateLoadingAnimation(deltaTime)
	if self._transition > 0 then
		self._transition = math.max(0, self._transition - deltaTime)
		if self._transition == 0 and not self._isOpen then
			self._assets.Main.Visible = false
			self._assets.CharacterAndStatus.Visible = false
			self._assets.HotbarMain.Visible = false
			self._assets.HudMain.Visible = false
			self._assets.Dimmer.Visible = false
			self._assets.BackdropScreen.Enabled = false
			self._backdropShown = false
			self._assets.Main.Size = self._originalSize
			self._assets.Main.Position = self._originalPosition
			self._assets.Main.Rotation = self._originalRotation
			self._assets.CharacterAndStatus.Size = self._characterOriginalSize
			self._assets.CharacterAndStatus.Position = self._characterOriginalPosition
			self._assets.CharacterAndStatus.Rotation = self._characterOriginalRotation
			self._isClosing = false
			self._storageClosing = false
		end
	end
	if self._previewCharacterSource ~= self._player.Character then
		self:WatchPreviewCharacter(self._player.Character)
		self._previewDirty = true
	end
	self:RefreshCharacterPreview()
	self:SynchronizeCharacterPreview()
	local character = self._player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local canUseHotbar = humanoid ~= nil and humanoid.Health > 0 and self._player:GetAttribute("IsDowned") ~= true
	local seat = humanoid and humanoid.SeatPart
	local inVehicle = seat ~= nil and seat:IsA("VehicleSeat")
	local stateChanged = canUseHotbar ~= self._canUseHotbar or inVehicle ~= self._inVehicle
	self._canOpen = canUseHotbar
	self._canUseHotbar = canUseHotbar
	self._inVehicle = inVehicle
	self._assets.HotbarMain.Visible = (self._isOpen or self._isClosing)
		and canUseHotbar
		and not inVehicle
		and not self._hideHotbarAfterInteraction
	self._assets.HudMain.Visible = canUseHotbar
		and not inVehicle
		and self._hasHotbarItems
		and not (self._isOpen or self._isClosing)
	if not canUseHotbar and self._isOpen then
		self:SetOpen(false)
	end
	if stateChanged then
		self:RefreshHotbar()
	end
end

function InventoryView:Dispose()
	if self._disposed then
		return
	end
	self._disposed = true
	self:CancelLoadingAnimation(false)
	self:clearDrag()
	for _, list in ipairs({ self._connections, self._rowConnections, self._previewConnections or {} }) do
		for _, connection in ipairs(list) do
			connection:Disconnect()
		end
		table.clear(list)
	end
	if self._unsubscribe then
		self._unsubscribe()
	end
	if self._rejectSubscription then
		self._rejectSubscription()
	end
	if self._weaponSubscription then
		self._weaponSubscription()
	end
	if self._useStartedSubscription then
		self._useStartedSubscription()
	end
	if self._useFinishedSubscription then
		self._useFinishedSubscription()
	end
	if self._interactionStartedSubscription then
		self._interactionStartedSubscription()
	end
	if self._interactionFinishedSubscription then
		self._interactionFinishedSubscription()
	end
	self:CloseActionPanels(false)
	self:StopUseAnimation()
	self:StopInteractionAnimation()
	for _, tween in pairs(self._tweens) do
		tween:Cancel()
		tween:Destroy()
	end
	table.clear(self._tweens)
	for _, row in ipairs(self._rows) do
		row:Destroy()
	end
	table.clear(self._rows)
	if self._previewModel then
		self._previewModel:Destroy()
		self._previewModel = nil
	end
	if self._assets then
		for _, object in ipairs(self._assets.PreviewWorld:GetChildren()) do
			object:Destroy()
		end
		self._assets.Viewport.CurrentCamera = nil
		if self._previewCamera then
			self._previewCamera:Destroy()
			self._previewCamera = nil
		end
		if self._assets.Blur then
			self._assets.Blur.Size = 0
		end
		self._assets.Dimmer.BackgroundTransparency = 1
		self._assets.Dimmer.Visible = false
		self._assets.BackdropScreen.Enabled = false
		self._assets.HudMain.Visible = false
		for index, hud in ipairs(self._assets.HudHotbars) do
			local original = self._hudOriginals and self._hudOriginals[index]
			if original then
				hud.Button.Position = original.Position
				if original.Scale then
					original.Scale.Scale = 1
				end
				hud.Button.BackgroundColor3 = original.ButtonColor
				hud.NumberLabel.BackgroundColor3 = original.NumberColor
				hud.Indicator.BackgroundColor3 = original.IndicatorColor
				hud.Indicator.Visible = false
				hud.Indicator.Size = original.IndicatorSize
			end
		end
		self._assets.Main.Visible = false
		self._assets.CharacterAndStatus.Visible = false
	end
	self._assets = nil
	self._snapshot = nil
	self._events = nil
	self._commands = nil
	self._player = nil
end

return InventoryView
