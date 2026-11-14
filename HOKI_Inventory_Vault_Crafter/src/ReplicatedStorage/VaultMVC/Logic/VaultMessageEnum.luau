--!strict
-- /// <summary>Names immutable vault commands and events shared across server and client.</summary>
return table.freeze({
	Open = "OpenVaultCommand",
	Close = "CloseVaultCommand",
	Deposit = "DepositVaultItemCommand",
	Withdraw = "WithdrawVaultItemCommand",
	Refresh = "RefreshVaultStateCommand",
	ReceiveState = "ReceiveVaultStateCommand",
	ReceiveResult = "ReceiveVaultResultCommand",
	Opened = "VaultOpened",
	Closed = "VaultClosed",
	StateChanged = "VaultStateChanged",
	TransferResult = "VaultTransferResult",
})
