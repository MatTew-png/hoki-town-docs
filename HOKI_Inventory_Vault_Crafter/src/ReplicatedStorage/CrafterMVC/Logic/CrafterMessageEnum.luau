--!strict
-- /// <summary>Names immutable crafting commands and events shared between server and client.</summary>
return table.freeze({
	Open = "OpenCrafterCommand",
	Close = "CloseCrafterCommand",
	Craft = "CraftRecipeItemCommand",
	Refresh = "RefreshCrafterStateCommand",
	Opened = "CrafterOpened",
	Closed = "CrafterClosed",
	StateChanged = "CrafterStateChanged",
	CraftResult = "CrafterCraftResult",
})
