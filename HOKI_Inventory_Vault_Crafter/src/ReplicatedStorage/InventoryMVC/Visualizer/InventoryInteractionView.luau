--[[ <summary>Shows an authored, camera-facing item icon on the giver's or receiver's hand during inventory interactions.</summary> ]]
local InventoryInteractionView = {}
InventoryInteractionView.__index = InventoryInteractionView

local function findRightHand(character)
	if not character then
		return nil
	end
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if hand and hand:IsA("BasePart") then
		return hand
	end
	return nil
end

function InventoryInteractionView.new(parameters)
	return setmetatable({
		_player = parameters.Player,
		_players = parameters.Players,
		_events = parameters.Events,
		_names = parameters.Names,
		_catalog = parameters.Catalog,
		_config = parameters.Config,
		_template = parameters.Template,
		_icon = nil,
		_switchThread = nil,
		_unsubscribeStarted = nil,
		_unsubscribeFinished = nil,
		_characterRemovingConnection = nil,
		_disposed = false,
	}, InventoryInteractionView)
end

function InventoryInteractionView:clearIcon()
	if self._switchThread then
		pcall(task.cancel, self._switchThread)
		self._switchThread = nil
	end
	if self._icon then
		self._icon:Destroy()
		self._icon = nil
	end
end

function InventoryInteractionView:findTarget(userId)
	for _, player in ipairs(self._players:GetPlayers()) do
		if player.UserId == userId then
			return player
		end
	end
	return nil
end

function InventoryInteractionView:showIcon(event)
	self:clearIcon()
	if self._disposed or event.Role ~= "Sender" then
		return
	end
	if event.Action ~= "Give" and event.Action ~= "Leave" then
		return
	end
	local hand = findRightHand(self._player.Character)
	if not hand then
		return
	end
	local icon = self._template:Clone()
	local image = icon:WaitForChild("ItemIcon")
	local info = self._catalog[event.ItemId]
	if info and type(info.Image) == "string" and info.Image ~= "" then
		image.Image = info.Image
	end
	icon.Name = "InventoryHandItemIcon"
	icon.Enabled = true
	icon.Parent = hand
	self._icon = icon

	if event.Action ~= "Give" then
		return
	end
	local targetUserId = event.TargetUserId
	local switchAfter = math.min(self._config.GiveIconHandSwitchSeconds, math.max(0, event.Duration - 0.05))
	self._switchThread = task.delay(switchAfter, function()
		self._switchThread = nil
		if self._disposed or self._icon ~= icon or not icon.Parent then
			return
		end
		local target = self:findTarget(targetUserId)
		local targetCharacter = target and target.Character
		local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
		local targetHand = findRightHand(targetCharacter)
		if not targetHand or not targetHumanoid or targetHumanoid.Health <= 0 then
			return
		end
		icon.Parent = targetHand
	end)
end

function InventoryInteractionView:Init()
	self._unsubscribeStarted = self._events:Subscribe(self._names.InteractionStarted, function(event)
		self:showIcon(event)
	end)
	self._unsubscribeFinished = self._events:Subscribe(self._names.InteractionFinished, function(event)
		if event.Role == "Sender" then
			self:clearIcon()
		end
	end)
	self._characterRemovingConnection = self._player.CharacterRemoving:Connect(function()
		self:clearIcon()
	end)
end

function InventoryInteractionView:Dispose()
	if self._disposed then
		return
	end
	self._disposed = true
	if self._unsubscribeStarted then
		self._unsubscribeStarted()
		self._unsubscribeStarted = nil
	end
	if self._unsubscribeFinished then
		self._unsubscribeFinished()
		self._unsubscribeFinished = nil
	end
	if self._characterRemovingConnection then
		self._characterRemovingConnection:Disconnect()
		self._characterRemovingConnection = nil
	end
	self:clearIcon()
	self._player = nil
	self._players = nil
	self._events = nil
	self._catalog = nil
	self._template = nil
end

return InventoryInteractionView
