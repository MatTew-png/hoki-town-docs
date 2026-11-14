--!strict
-- /// <summary>Defines crafting stations, recipes, material requirements, and interaction distances.</summary>
local CrafterConfig = table.freeze({
	OpenDistanceStuds = 16,
	CloseDistanceStuds = 19,
	MaxCraftQuantity = 20,
	Stations = table.freeze({
		General = table.freeze({
			DisplayName = "HOKI CRAFTER — โต๊ะคราฟต์อุปกรณ์",
			Recipes = table.freeze({
				table.freeze({
					RecipeId = "craft_armor",
					OutputItemId = "armor",
					OutputAmount = 1,
					Category = "Consumable",
					Description = "เกราะป้องกันตัว เสริมเกราะ +100 หน่วย",
					Ingredients = table.freeze({
						table.freeze({ ItemId = "wire", Amount = 2 }),
						table.freeze({ ItemId = "WolfPelt", Amount = 2 }),
					}),
				}),
				table.freeze({
					RecipeId = "craft_painkiller",
					OutputItemId = "painkiller",
					OutputAmount = 1,
					Category = "Consumable",
					Description = "ยาแก้ปวดฉุกเฉิน ฟื้นฟูพลังชีวิต +35 HP",
					Ingredients = table.freeze({
						table.freeze({ ItemId = "apple", Amount = 2 }),
						table.freeze({ ItemId = "Strawberry", Amount = 1 }),
					}),
				}),
				table.freeze({
					RecipeId = "craft_bottle",
					OutputItemId = "BottleBasic",
					OutputAmount = 1,
					Category = "Weapon",
					Description = "ขวดปากฉลาม อาวุธประชิดพื้นฐานน้ำหนักเบา",
					Ingredients = table.freeze({
						table.freeze({ ItemId = "wire", Amount = 2 }),
						table.freeze({ ItemId = "cash", Amount = 100 }),
					}),
				}),
				table.freeze({
					RecipeId = "craft_dagger",
					OutputItemId = "DaggerBasic",
					OutputAmount = 1,
					Category = "Weapon",
					Description = "มีดสั้นความเร็วสูง ตีขึ้นจากเขี้ยวหมาป่า",
					Ingredients = table.freeze({
						table.freeze({ ItemId = "WolfFang", Amount = 2 }),
						table.freeze({ ItemId = "wire", Amount = 2 }),
						table.freeze({ ItemId = "cash", Amount = 250 }),
					}),
				}),
				table.freeze({
					RecipeId = "craft_pool",
					OutputItemId = "Pool",
					OutputAmount = 1,
					Category = "Weapon",
					Description = "ไม้คิวพูล อาวุธระยะประชิดแรงปะทะสูง",
					Ingredients = table.freeze({
						table.freeze({ ItemId = "wire", Amount = 3 }),
						table.freeze({ ItemId = "WolfPelt", Amount = 1 }),
						table.freeze({ ItemId = "cash", Amount = 350 }),
					}),
				}),
				table.freeze({
					RecipeId = "craft_m9",
					OutputItemId = "M9Basic",
					OutputAmount = 1,
					Category = "Weapon",
					Description = "มีดแทคติคอล M9 ระดับสูงสำหรับสายต่อสู้",
					Ingredients = table.freeze({
						table.freeze({ ItemId = "WolfFang", Amount = 4 }),
						table.freeze({ ItemId = "WolfPelt", Amount = 2 }),
						table.freeze({ ItemId = "wire", Amount = 4 }),
						table.freeze({ ItemId = "cash", Amount = 500 }),
					}),
				}),
			}),
		}),
	}),
})

return CrafterConfig
