--[[ <summary>Describes immutable inventory intent carried through the command queue; identifiers contain no Instances.</summary> ]]
export type InventoryCommand = {
	Name: string,
	ItemId: string?,
	Amount: number?,
	Slot: string?,
	Snapshot: { Items: { { UUID: string, ItemID: string, Amount: number } }, Slots: { [string]: string } }?,
}
return table.freeze({})
