--[[ <summary>Defines per-item use timing, presentation, and effect values; action handlers remain reusable.</summary> ]]
return table.freeze({
	Items = table.freeze({
		painkiller = table.freeze({
			DurationSeconds = 4.5,
			ConsumeOnStart = true,
			HealAmount = 35,
			AnimationAsset = "PainkillerUseAnimation",
			AnimationId = "rbxassetid://132471704145422",
			AnimationLooped = true,
			LocksMovement = true,
			HeadLookProfile = "HeadAndTorsoYaw",
		}),
		armor = table.freeze({
			DurationSeconds = 6,
			ConsumeOnStart = true,
			ArmorAmount = 100,
			MaxArmor = 100,
			ModelFolder = "AllModel",
			ModelName = "Armor",
			VisualName = "EquippedArmor",
			AttachmentPart = "UpperTorso",
			AttachmentOffset = CFrame.new(),
			AnimationAsset = "ArmorUseAnimation",
			AnimationId = "rbxassetid://93510612810908",
			AnimationLooped = true,
			LocksMovement = false,
		}),
	}),
})
