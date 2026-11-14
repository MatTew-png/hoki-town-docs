--[[ <summary>Runs validated inventory use actions for one player session and restores character locks on every exit.</summary> ]]
local InventoryUseService = {}
InventoryUseService.__index = InventoryUseService

local function isPositiveInteger(value)
	return type(value) == "number" and value == value and value % 1 == 0 and value > 0 and value <= 10000
end

function InventoryUseService.new(parameters)
	return setmetatable({
		Player = parameters.Player,
		Controller = parameters.Controller,
		Events = parameters.Events,
		Names = parameters.Names,
		Config = parameters.Config,
		Handlers = parameters.Handlers,
		ReplicatedStorage = parameters.ReplicatedStorage,
		Catalog = parameters.Catalog,
		InteractionConfig = parameters.InteractionConfig,
		TransferItem = parameters.TransferItem,
		NotifyTarget = parameters.NotifyTarget,
		Active = nil,
		Connections = {},
		Disposed = false,
	}, InventoryUseService)
end

function InventoryUseService:reject(reason)
	self.Events:Publish(self.Names.Rejected, table.freeze({ Reason = reason }))
end

function InventoryUseService:releaseMovementLock(active)
	if not active.LocksMovement or active.MovementUnlocked then
		return
	end
	active.MovementUnlocked = true
	if active.Character and active.Character.Parent then
		active.Character:SetAttribute("IsUsingItem", false)
	end
	local humanoid = active.Humanoid
	if humanoid and humanoid.Parent then
		if humanoid.JumpPower == 0 then
			humanoid.JumpPower = active.JumpPower
		end
		if humanoid.JumpHeight == 0 then
			humanoid.JumpHeight = active.JumpHeight
		end
	end
end

function InventoryUseService:finish(active, succeeded)
	if self.Active ~= active then
		return
	end
	self.Active = nil
	local delayThread = active.DelayThread
	active.DelayThread = nil
	if delayThread then
		pcall(task.cancel, delayThread)
	end
	if active.DeathConnection then
		active.DeathConnection:Disconnect()
		active.DeathConnection = nil
	end
	self:releaseMovementLock(active)
	if
		active.HeadLookProfile
		and active.Character
		and active.Character.Parent
		and active.Character:GetAttribute("HeadLookProfile") == active.HeadLookProfile
	then
		active.Character:SetAttribute("HeadLookProfile", nil)
	end
	self.Events:Publish(
		self.Names.UseFinished,
		table.freeze({
			ItemId = active.ItemId,
			Action = active.Action,
			Succeeded = succeeded == true,
		})
	)
end

function InventoryUseService:beginUse(request)
	if self.Disposed or self.Active then
		self:reject("UseInProgress")
		return
	end
	if type(request) ~= "table" or type(request.ItemUUID) ~= "string" or type(request.ItemId) ~= "string" then
		return
	end
	local action = request.Action
	local itemConfig = self.Config.Items[request.ItemId]
	local handler = self.Handlers[action]
	if not itemConfig or not handler or type(handler.CanApply) ~= "function" or type(handler.Apply) ~= "function" then
		self:reject("UnsupportedUseAction")
		return
	end

	local ownedItem = self.Controller:findItem(request.ItemUUID)
	if not ownedItem or ownedItem.ItemID ~= request.ItemId then
		self:reject("ItemUnavailable")
		return
	end
	local player = self.Player
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		self:reject("CharacterUnavailable")
		return
	end
	if
		player:GetAttribute("IsDowned") == true
		or player:GetAttribute("AirdropCollecting") == true
		or character:GetAttribute("IsFarming") == true
		or character:GetAttribute("IsSliding") == true
		or character:GetAttribute("Crouching") == true
		or humanoid.SeatPart ~= nil
	then
		self:reject("CannotUseNow")
		return
	end

	local context = {
		Player = player,
		Character = character,
		Humanoid = humanoid,
		Item = ownedItem,
		Config = itemConfig,
		ReplicatedStorage = self.ReplicatedStorage,
	}
	local canApplyOk, canApply, reason = pcall(handler.CanApply, context)
	if not canApplyOk then
		warn("[InventoryUseService] CanApply failed: " .. tostring(canApply))
		self:reject("UseFailed")
		return
	end
	if canApply ~= true then
		self:reject(reason or "CannotUseNow")
		return
	end

	local duration = itemConfig.DurationSeconds
	if type(duration) ~= "number" or duration ~= duration or duration < 0 or duration > 120 then
		warn("[InventoryUseService] Invalid DurationSeconds for action " .. tostring(action))
		self:reject("UseFailed")
		return
	end

	local consumeOnStart = itemConfig.ConsumeOnStart == true
	if consumeOnStart and not self.Controller:CompleteUse(ownedItem.UUID) then
		self:reject("ItemUnavailable")
		return
	end

	local active = {
		Character = character,
		Humanoid = humanoid,
		ItemUUID = ownedItem.UUID,
		ItemId = ownedItem.ItemID,
		Action = action,
		ConsumedOnStart = consumeOnStart,
		Context = context,
		LocksMovement = itemConfig.LocksMovement == true,
		HeadLookProfile = itemConfig.HeadLookProfile,
		JumpPower = humanoid.JumpPower,
		JumpHeight = humanoid.JumpHeight,
	}
	self.Active = active
	if type(active.HeadLookProfile) == "string" then
		character:SetAttribute("HeadLookProfile", active.HeadLookProfile)
	end
	if itemConfig.LocksMovement == true then
		character:SetAttribute("IsUsingItem", true)
		humanoid.Jump = false
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	end
	active.DeathConnection = humanoid.Died:Connect(function()
		self:finish(active, false)
	end)
	self.Events:Publish(
		self.Names.UseStarted,
		table.freeze({
			ItemId = active.ItemId,
			Action = action,
			Duration = duration,
			EndsAtServerTime = workspace:GetServerTimeNow() + duration,
		})
	)
	active.DelayThread = task.delay(duration, function()
		active.DelayThread = nil
		if self.Disposed or self.Active ~= active then
			return
		end
		if player.Parent == nil or player.Character ~= character or humanoid.Health <= 0 then
			self:finish(active, false)
			return
		end
		local validOk, stillValid, invalidReason = pcall(handler.CanApply, context)
		if not validOk or stillValid ~= true then
			if not validOk then
				warn("[InventoryUseService] Final CanApply failed: " .. tostring(stillValid))
			end
			if invalidReason then
				self:reject(invalidReason)
			end
			self:finish(active, false)
			return
		end
		if not active.ConsumedOnStart and not self.Controller:CompleteUse(active.ItemUUID) then
			self:reject("ItemUnavailable")
			self:finish(active, false)
			return
		end
		local applyOk, applied = pcall(handler.Apply, context)
		if not applyOk then
			warn("[InventoryUseService] Apply failed: " .. tostring(applied))
		end
		self:finish(active, applyOk and applied == true)
	end)
end

function InventoryUseService:finishInteraction(active, succeeded, reason)
	if self.Active ~= active then
		return
	end
	self.Active = nil
	local delayThread = active.DelayThread
	active.DelayThread = nil
	if delayThread then
		pcall(task.cancel, delayThread)
	end
	if active.DeathConnection then
		active.DeathConnection:Disconnect()
		active.DeathConnection = nil
	end
	local payload = table.freeze({
		Action = active.Action,
		ItemId = active.ItemId,
		Succeeded = succeeded == true,
		Role = "Sender",
		TargetUserId = active.TargetUserId,
	})
	self.Events:Publish(self.Names.InteractionFinished, payload)
	if active.TargetUserId and self.NotifyTarget then
		self.NotifyTarget(
			active.TargetUserId,
			self.Names.InteractionFinished,
			table.freeze({
				Action = active.Action,
				ItemId = active.ItemId,
				Succeeded = succeeded == true,
				Role = "Receiver",
				TargetUserId = self.Player.UserId,
			})
		)
	end
	if not succeeded and reason then
		self:reject(reason)
	end
end

function InventoryUseService:beginInteraction(request, action)
	if self.Disposed or self.Active then
		self:reject("UseInProgress")
		return
	end
	if
		type(request) ~= "table"
		or type(request.ItemUUID) ~= "string"
		or type(request.ItemId) ~= "string"
		or not isPositiveInteger(request.Amount)
	then
		self:reject("InvalidInteraction")
		return
	end
	local item = self.Controller:findItem(request.ItemUUID)
	local info = item and self.Catalog[item.ItemID]
	local isGive = action == "Give"
	local allowed = info
		and info.Type ~= "Weapon"
		and ((isGive and info.CanGive == true) or (not isGive and info.CanLeave == true and not info.Permanent))
	if not item or item.ItemID ~= request.ItemId or not allowed or request.Amount > item.Amount then
		self:reject("InteractionNotAllowed")
		return
	end
	local targetUserId = request.TargetUserId
	if isGive then
		if
			type(targetUserId) ~= "number"
			or targetUserId % 1 ~= 0
			or targetUserId == 0
			or targetUserId == self.Player.UserId
			or not self.TransferItem
		then
			self:reject("InvalidTarget")
			return
		end
		local valid = self.TransferItem(self.Player, request.ItemUUID, targetUserId, request.Amount, false)
		if not valid then
			self:reject("TargetUnavailable")
			return
		end
	end
	local character = self.Player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		self:reject("CharacterUnavailable")
		return
	end
	local config = self.InteractionConfig
	local duration = if isGive then config.GiveDurationSeconds else config.LeaveDurationSeconds
	if type(duration) ~= "number" or duration < 0 or duration > 30 then
		self:reject("InvalidInteractionDuration")
		return
	end
	local active = {
		Kind = "Interaction",
		Action = action,
		ItemUUID = request.ItemUUID,
		ItemId = request.ItemId,
		Amount = request.Amount,
		TargetUserId = targetUserId,
		Character = character,
		Humanoid = humanoid,
	}
	self.Active = active
	local endsAtServerTime = workspace:GetServerTimeNow() + duration
	local payload = table.freeze({
		Action = action,
		ItemId = active.ItemId,
		Duration = duration,
		EndsAtServerTime = endsAtServerTime,
		Role = "Sender",
		TargetUserId = targetUserId,
	})
	self.Events:Publish(self.Names.InteractionStarted, payload)
	if targetUserId and self.NotifyTarget then
		self.NotifyTarget(
			targetUserId,
			self.Names.InteractionStarted,
			table.freeze({
				Action = action,
				ItemId = active.ItemId,
				Duration = duration,
				EndsAtServerTime = endsAtServerTime,
				Role = "Receiver",
				TargetUserId = self.Player.UserId,
			})
		)
	end
	active.DeathConnection = humanoid.Died:Connect(function()
		self:finishInteraction(active, false, "CharacterUnavailable")
	end)
	active.DelayThread = task.delay(duration, function()
		active.DelayThread = nil
		if self.Disposed or self.Active ~= active then
			return
		end
		if self.Player.Parent == nil or self.Player.Character ~= character or humanoid.Health <= 0 then
			self:finishInteraction(active, false, "CharacterUnavailable")
			return
		end
		local succeeded, reason
		if isGive then
			succeeded, reason = self.TransferItem(self.Player, active.ItemUUID, targetUserId, active.Amount, true)
		else
			succeeded = self.Controller:CompleteLeave(active.ItemUUID, active.Amount)
			reason = if succeeded then nil else "InteractionNotAllowed"
		end
		self:finishInteraction(active, succeeded == true, reason)
	end)
end

function InventoryUseService:cancelActiveUse(request)
	if self.Disposed or type(request) ~= "table" or request.UserId ~= self.Player.UserId then
		return
	end
	local active = self.Active
	if not active then
		return
	end
	if active.Kind == "Interaction" then
		self:finishInteraction(active, false)
	else
		self:finish(active, false)
	end
end

function InventoryUseService:Init()
	if self.Disposed then
		return
	end
	table.insert(
		self.Connections,
		self.Events:Subscribe(self.Names.UseRequested, function(request)
			self:beginUse(request)
		end)
	)
	table.insert(
		self.Connections,
		self.Events:Subscribe(self.Names.GiveRequested, function(request)
			self:beginInteraction(request, "Give")
		end)
	)
	table.insert(
		self.Connections,
		self.Events:Subscribe(self.Names.LeaveRequested, function(request)
			self:beginInteraction(request, "Leave")
		end)
	)
	table.insert(
		self.Connections,
		self.Events:Subscribe(self.Names.CancelUseRequested, function(request)
			self:cancelActiveUse(request)
		end)
	)
	table.insert(
		self.Connections,
		self.Events:Subscribe(self.Names.SlideDuringUseRequested, function(request)
			if type(request) ~= "table" or request.UserId ~= self.Player.UserId then
				return
			end
			local active = self.Active
			if not active then
				return
			end
			if active.LocksMovement then
				self:releaseMovementLock(active)
			end
			local character = active.Character
			if
				active.HeadLookProfile
				and character
				and character.Parent
				and character:GetAttribute("HeadLookProfile") == active.HeadLookProfile
			then
				character:SetAttribute("HeadLookProfile", nil)
			end
		end)
	)
	table.insert(
		self.Connections,
		self.Player.CharacterRemoving:Connect(function(character)
			local active = self.Active
			if active and active.Character == character then
				if active.Kind == "Interaction" then
					self:finishInteraction(active, false, "CharacterUnavailable")
				else
					self:finish(active, false)
				end
			end
		end)
	)
end

function InventoryUseService:Dispose()
	if self.Disposed then
		return
	end
	self.Disposed = true
	for _, cleanup in ipairs(self.Connections) do
		local cleanupType = typeof(cleanup)
		if cleanupType == "function" then
			pcall(cleanup)
		elseif cleanupType == "RBXScriptConnection" then
			pcall(function()
				cleanup:Disconnect()
			end)
		end
	end
	table.clear(self.Connections)
	local active = self.Active
	if active then
		if active.Kind == "Interaction" then
			self:finishInteraction(active, false)
		else
			self:finish(active, false)
		end
	end
	self.Player = nil
	self.Controller = nil
	self.Events = nil
	self.Config = nil
	self.Handlers = nil
	self.ReplicatedStorage = nil
	self.Catalog = nil
	self.InteractionConfig = nil
	self.TransferItem = nil
	self.NotifyTarget = nil
end

return InventoryUseService
