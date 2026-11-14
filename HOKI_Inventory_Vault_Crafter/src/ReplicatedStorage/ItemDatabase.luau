local ItemDatabase = {
	-- =============== weapon
	["Pool"] = {
		Name = "Pool",
		Image = "rbxassetid://14434989783",
		MaxStack = 1,
		Type = "Weapon",
		CanGive = false,
		CanLeave = false,
		WeaponName = "BaseballBat",
		ToolName = "Pool",
	},

	["BottleBasic"] = {
		Name = "Basic Bottle",
		Image = "",
		MaxStack = 1,
		Type = "Weapon",
		CanGive = false,
		CanLeave = false,
		ToolName = "BottleBasic",
		ToolPath = "Tier1.BottleBasic",
	},
	["DaggerBasic"] = {
		Name = "Basic Dagger",
		Image = "",
		MaxStack = 1,
		Type = "Weapon",
		CanGive = false,
		CanLeave = false,
		ToolName = "DaggerBasic",
		ToolPath = "Tier1.DaggerBasic",
	},
	["M9Basic"] = {
		Name = "M9 Knife",
		Image = "",
		MaxStack = 1,
		Type = "Weapon",
		CanGive = false,
		CanLeave = false,
		ToolName = "M9Basic",
		ToolPath = "Tier1.M9Basic",
	},

	-- Currency is stored and spent as inventory stacks.
	["cash"] = {
		Name = "เงินสด",
		Image = "",
		MaxStack = 9999999999,
		Type = "Currency",
		CanGive = true,
		CanLeave = true,
	},

	-- ================== labeltype ----------

	["wire"] = {
		Name = "สายไฟ",
		Image = "rbxassetid://136031651820136",
		MaxStack = 200,
		Type = "general",
		CanGive = true,
		CanLeave = true,
	},

	-- ================= From Farm ------

	["apple"] = {
		Name = "แอปเปิ้ล",
		Image = "rbxassetid://115782078",
		MaxStack = 50,
		Type = "Food",
		CanGive = true,
		CanLeave = true,
	},
	["Strawberry"] = {
		Name = "สตรอว์เบอร์รี",
		Image = "rbxassetid://114427030877504",
		MaxStack = 50,
		Type = "Food",
		CanGive = true,
		CanLeave = true,
	},
	["Banana"] = {
		Name = "กล้วย",
		Image = "rbxassetid://102158178476135",
		MaxStack = 50,
		Type = "Food",
		CanGive = true,
		CanLeave = true,
	},
	["Cherrie"] = {
		Name = "เชอร์รี",
		Image = "rbxassetid://125986617666654",
		MaxStack = 50,
		Type = "Food",
		CanGive = true,
		CanLeave = true,
	},
	["Grape"] = {
		Name = "องุ่น",
		Image = "rbxassetid://124978312578786",
		MaxStack = 50,
		Type = "Food",
		CanGive = true,
		CanLeave = true,
	},
	["Watermelon"] = {
		Name = "แตงโม",
		Image = "rbxassetid://74099984376799",
		MaxStack = 50,
		Type = "Food",
		CanGive = true,
		CanLeave = true,
	},

	-- ================= From Wolf Hunt ------
	["WolfMeat"] = {
		Name = "เนื้อหมาป่า",
		Image = "",
		MaxStack = 50,
		Type = "general",
		CanGive = true,
		CanLeave = true,
	},
	["WolfPelt"] = {
		Name = "หนังหมาป่า",
		Image = "",
		MaxStack = 50,
		Type = "general",
		CanGive = true,
		CanLeave = true,
	},
	["WolfFang"] = {
		Name = "เขี้ยวหมาป่า",
		Image = "",
		MaxStack = 50,
		Type = "general",
		CanGive = true,
		CanLeave = true,
	},

	-- =================== use -------
	["painkiller"] = {
		Name = "ยาแก้ปวด",
		Image = "rbxassetid://72476280115120",
		MaxStack = 50,
		Type = "use",
		UseAction = "Heal",
		CanGive = true,
		CanLeave = true,
	},
	["armor"] = {
		Name = "เกราะ",
		Image = "rbxassetid://138262468177042",
		MaxStack = 50,
		Type = "use",
		UseAction = "Armor",
		CanGive = true,
		CanLeave = true,
	},
}

return ItemDatabase
