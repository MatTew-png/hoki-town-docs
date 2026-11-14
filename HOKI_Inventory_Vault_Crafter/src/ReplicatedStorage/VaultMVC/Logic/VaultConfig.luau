--!strict
-- /// <summary>Defines vault locations, storage stack limits, interaction distances, and UI timing.</summary>
local VaultConfig = table.freeze({
	OpenDistanceStuds = 12,
	CloseDistanceStuds = 15,
	MaxVaultStacks = 60,
	MaxTransferAmount = 10000,
	EnterSeconds = 0.2,
	ExitSeconds = 0.16,
	Vaults = table.freeze({
		MainVault = table.freeze({
			DisplayName = "HOKI VAULT — ตู้เซฟเก็บของ",
			MaxStacks = 60,
		}),
	}),
})

return VaultConfig
