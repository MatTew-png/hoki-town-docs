--[[ <summary>Defines the timing, capacity, and colors of inventory transfer notifications.</summary> ]]
return table.freeze({
	VisibleSeconds = 5,
	ExitSeconds = 0.35,
	MaxVisible = 8,
	EntrySeconds = 0.28,
	EntryBatchSeconds = 0.04,
	EntryStaggerSeconds = 0.18,
	EntryStartScale = 0.82,
	SoundBatchSeconds = 0.12,
	SoundVolume = 0.6,
	GainSoundId = "rbxassetid://71450094482101",
	LossSoundId = "rbxassetid://18209039561",
	GainColor = table.freeze({ R = 239, G = 195, B = 36 }),
	LossColor = table.freeze({ R = 239, G = 37, B = 40 }),
})
