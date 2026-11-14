--[[ <summary>Describes the existing PlayerData_v1 Inventory persistence payload at the Gateway boundary.</summary> ]]
export type InventoryDto = {
	Items: { { UUID: string, ItemID: string, Amount: number } },
	Slots: { [string]: string },
}
return table.freeze({})
