--!strict
-- /// <summary>Renders elapsed progress for timed inventory actions using the authored Loading bar.</summary>
local InventoryUseLoadingView = {}
InventoryUseLoadingView.__index = InventoryUseLoadingView

local PERCENT_SCALE = 100
local CLIP_EDGE = 0.001
local SLIDE_PIXELS = 16
local ENTER_SECONDS = 0.2
local EXIT_SECONDS = 0.18
local SUCCESS_HOLD_SECONDS = 0.2

local function shiftedDown(position)
	return UDim2.new(position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset + SLIDE_PIXELS)
end

local function createClipTransparency(percent)
	local visibleFraction = percent / PERCENT_SCALE
	if visibleFraction <= 0 then
		return NumberSequence.new(1)
	end
	if visibleFraction >= 1 then
		return NumberSequence.new(0)
	end
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(visibleFraction, 0),
		NumberSequenceKeypoint.new(math.min(visibleFraction + CLIP_EDGE, 1), 1),
		NumberSequenceKeypoint.new(1, 1),
	})
end

function InventoryUseLoadingView.new(parameters)
	return setmetatable({
		_assets = parameters.Assets,
		_events = parameters.Events,
		_commands = parameters.Commands,
		_input = parameters.Input,
		_names = parameters.Names,
		_clock = parameters.Clock,
		_tweenService = parameters.TweenService,
		_visualTargets = {},
		_motionRoots = {},
		_tweens = {},
		_motionThread = nil,
		_motionToken = 0,
		_subscriptions = {},
		_connections = {},
		_activeKind = nil,
		_cancelRequested = false,
		_duration = 0,
		_endsAtServerTime = 0,
		_displayedPercent = nil,
		_disposed = false,
	}, InventoryUseLoadingView)
end

function InventoryUseLoadingView:_captureVisuals()
	local screen = self._assets.Screen
	for _, object in ipairs(screen:GetChildren()) do
		if object:IsA("GuiObject") then
			table.insert(self._motionRoots, { Object = object, Position = object.Position })
		end
	end
	for _, object in ipairs(screen:GetDescendants()) do
		local values = {}
		if object:IsA("GuiObject") then
			values.BackgroundTransparency = object.BackgroundTransparency
			if object:IsA("ImageLabel") or object:IsA("ImageButton") then
				values.ImageTransparency = object.ImageTransparency
			end
			if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
				values.TextTransparency = object.TextTransparency
				values.TextStrokeTransparency = object.TextStrokeTransparency
			end
		elseif object:IsA("UIStroke") then
			values.Transparency = object.Transparency
		end
		if next(values) then
			table.insert(self._visualTargets, { Object = object, Values = values })
		end
	end
end

function InventoryUseLoadingView:_stopMotion()
	self._motionToken += 1
	local motionThread = self._motionThread
	self._motionThread = nil
	if motionThread then
		pcall(task.cancel, motionThread)
	end
	for _, tween in ipairs(self._tweens) do
		tween:Cancel()
	end
	table.clear(self._tweens)
end

function InventoryUseLoadingView:_setVisuals(hidden)
	for _, target in ipairs(self._visualTargets) do
		for property, original in pairs(target.Values) do
			target.Object[property] = if hidden then 1 else original
		end
	end
	for _, root in ipairs(self._motionRoots) do
		root.Object.Position = if hidden then shiftedDown(root.Position) else root.Position
	end
end

function InventoryUseLoadingView:_tweenVisuals(hidden, seconds)
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, target in ipairs(self._visualTargets) do
		local goal = {}
		for property, original in pairs(target.Values) do
			goal[property] = if hidden then 1 else original
		end
		local tween = self._tweenService:Create(target.Object, info, goal)
		table.insert(self._tweens, tween)
		tween:Play()
	end
	for _, root in ipairs(self._motionRoots) do
		local tween = self._tweenService:Create(root.Object, info, {
			Position = if hidden then shiftedDown(root.Position) else root.Position,
		})
		table.insert(self._tweens, tween)
		tween:Play()
	end
end

function InventoryUseLoadingView:_beginExit()
	self:_stopMotion()
	self:_tweenVisuals(true, EXIT_SECONDS)
	local token = self._motionToken
	self._motionThread = task.delay(EXIT_SECONDS, function()
		self._motionThread = nil
		if self._disposed or self._motionToken ~= token then
			return
		end
		self._assets.Screen.Enabled = false
		self:_setVisuals(false)
	end)
end

function InventoryUseLoadingView:_setPercent(percent)
	local roundedPercent = math.clamp(math.floor(percent), 0, PERCENT_SCALE)
	if roundedPercent == self._displayedPercent then
		return
	end
	self._displayedPercent = roundedPercent
	self._assets.Percent.Text = tostring(roundedPercent) .. "%"
	self._assets.Clip.Transparency = createClipTransparency(roundedPercent)
end

function InventoryUseLoadingView:_requestCancel()
	if self._disposed or not self._activeKind or self._cancelRequested or not self._assets.Screen.Enabled then
		return
	end
	self._cancelRequested = true
	self._commands:Enqueue(table.freeze({ Name = self._names.CancelUse }))
end

function InventoryUseLoadingView:Show(kind, event)
	if self._disposed or type(event) ~= "table" then
		return
	end
	local duration = event.Duration
	if type(duration) ~= "number" or duration ~= duration or duration <= 0 or duration > 120 then
		return
	end
	local endsAtServerTime = event.EndsAtServerTime
	if type(endsAtServerTime) ~= "number" or endsAtServerTime ~= endsAtServerTime then
		endsAtServerTime = self._clock() + duration
	end
	self._activeKind = kind
	self._cancelRequested = false
	self._duration = duration
	self._endsAtServerTime = endsAtServerTime
	self._displayedPercent = nil
	self:_setPercent(0)
	self:_stopMotion()
	self:_setVisuals(true)
	self._assets.Screen.Enabled = true
	self:_tweenVisuals(false, ENTER_SECONDS)
end

function InventoryUseLoadingView:Hide(kind, succeeded)
	if kind and self._activeKind ~= kind then
		return
	end
	self._activeKind = nil
	self._cancelRequested = false
	self._duration = 0
	self._endsAtServerTime = 0
	if succeeded then
		self:_setPercent(PERCENT_SCALE)
		self:_stopMotion()
		self:_setVisuals(false)
		local token = self._motionToken
		self._motionThread = task.delay(SUCCESS_HOLD_SECONDS, function()
			self._motionThread = nil
			if self._disposed or self._motionToken ~= token then
				return
			end
			self:_beginExit()
		end)
	else
		self:_beginExit()
	end
end

function InventoryUseLoadingView:Init()
	self:_captureVisuals()
	self._assets.Screen.Enabled = false
	local isTouch = self._input.TouchEnabled
	self._assets.DesktopPrompt.Visible = not isTouch
	self._assets.MobilePrompt.Visible = isTouch
	self:_setPercent(0)
	table.insert(
		self._connections,
		self._assets.DesktopButton.Activated:Connect(function()
			self:_requestCancel()
		end)
	)
	table.insert(
		self._connections,
		self._assets.MobileButton.Activated:Connect(function()
			self:_requestCancel()
		end)
	)
	table.insert(
		self._connections,
		self._input.InputBegan:Connect(function(input, processed)
			if processed or isTouch or input.KeyCode ~= Enum.KeyCode.X or self._input:GetFocusedTextBox() then
				return
			end
			self:_requestCancel()
		end)
	)
	table.insert(
		self._subscriptions,
		self._events:Subscribe(self._names.UseStarted, function(event)
			self:Show("Use", event)
		end)
	)
	table.insert(
		self._subscriptions,
		self._events:Subscribe(self._names.UseFinished, function(event)
			self:Hide("Use", event.Succeeded == true)
		end)
	)
	table.insert(
		self._subscriptions,
		self._events:Subscribe(self._names.InteractionStarted, function(event)
			if event.Role == "Sender" then
				self:Show("Interaction", event)
			end
		end)
	)
	table.insert(
		self._subscriptions,
		self._events:Subscribe(self._names.InteractionFinished, function(event)
			if event.Role == "Sender" then
				self:Hide("Interaction", event.Succeeded == true)
			end
		end)
	)
end

function InventoryUseLoadingView:UpdateLogic(_deltaTime)
	if self._disposed or not self._activeKind then
		return
	end
	local remaining = math.max(self._endsAtServerTime - self._clock(), 0)
	self:_setPercent(math.clamp(1 - remaining / self._duration, 0, 1) * PERCENT_SCALE)
end

function InventoryUseLoadingView:Dispose()
	if self._disposed then
		return
	end
	self._disposed = true
	self:_stopMotion()
	self:_setVisuals(false)
	for _, unsubscribe in ipairs(self._subscriptions) do
		unsubscribe()
	end
	table.clear(self._subscriptions)
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	if self._assets.Screen.Parent then
		self._assets.Screen.Enabled = false
	end
	self._activeKind = nil
	self._assets = nil
	self._events = nil
	self._commands = nil
	self._input = nil
	self._clock = nil
	self._tweenService = nil
	table.clear(self._visualTargets)
	table.clear(self._motionRoots)
end

return InventoryUseLoadingView
