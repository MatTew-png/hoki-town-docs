--[[ <summary>Describes detached authoritative inventory state that presentation may read but never mutate.</summary> ]]
export type InventorySnapshot = {
	Items: { { UUID: string, ItemID: string, Amount: number } },
	Slots: { [string]: string },
	Revision: number,
}
return table.freeze({})
