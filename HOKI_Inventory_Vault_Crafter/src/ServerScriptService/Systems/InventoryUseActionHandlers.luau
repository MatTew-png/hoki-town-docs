--[[ <summary>Registers reusable server-authoritative handlers for inventory use actions.</summary> ]]
local InventoryUseActionHandlers = {}

local armorStates = setmetatable({}, { __mode = "k" })

local function clearArmorState(character)
	local state = armorStates[character]
	if not state then
		return
	end
	armorStates[character] = nil
	for _, connection in ipairs(state.Connections) do
		connection:Disconnect()
	end
end

local function removeArmorVisual(character, visualName)
	local visual = character and character:FindFirstChild(visualName)
	if visual then
		visual:Destroy()
	end
end

local function findArmorAssets(context)
	local config = context.Config
	local replicatedStorage = context.ReplicatedStorage
	if not replicatedStorage then
		return nil, nil, nil, "ArmorAssetsUnavailable"
	end
	local folder = replicatedStorage:FindFirstChild(config.ModelFolder)
	local template = folder and folder:FindFirstChild(config.ModelName)
	if not template or not template:IsA("Model") then
		return nil, nil, nil, "ArmorModelUnavailable"
	end
	local primaryPart = template.PrimaryPart or template:FindFirstChildWhichIsA("BasePart", true)
	local weld = template:FindFirstChild("UpperTorsoWeld", true)
	if not primaryPart or not weld or not weld:IsA("WeldConstraint") then
		return nil, nil, nil, "ArmorModelNotConfigured"
	end
	return template, primaryPart, weld
end

InventoryUseActionHandlers.Heal = table.freeze({
	CanApply = function(context)
		local humanoid = context.Humanoid
		if not humanoid or not humanoid.Parent or humanoid.Health <= 0 then
			return false, "CharacterUnavailable"
		end
		if humanoid.Health >= humanoid.MaxHealth then
			return false, "HealthFull"
		end
		return true
	end,
	Apply = function(context)
		local humanoid = context.Humanoid
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + context.Config.HealAmount)
		return true
	end,
})

InventoryUseActionHandlers.Armor = table.freeze({
	CanApply = function(context)
		local character = context.Character
		local humanoid = context.Humanoid
		if not character or not character.Parent or not humanoid or humanoid.Health <= 0 then
			return false, "CharacterUnavailable"
		end
		local attachmentPart = character:FindFirstChild(context.Config.AttachmentPart)
		if not attachmentPart or not attachmentPart:IsA("BasePart") then
			return false, "ArmorAttachmentUnavailable"
		end
		local template, _, _, assetError = findArmorAssets(context)
		if not template then
			return false, assetError
		end
		local player = context.Player
		local currentArmor = player:GetAttribute("Armor")
		if typeof(currentArmor) ~= "number" then
			currentArmor = character:GetAttribute("Armor")
		end
		local maximum = context.Config.MaxArmor
		if typeof(currentArmor) == "number" and currentArmor >= maximum then
			return false, "ArmorFull"
		end
		return true
	end,
	Apply = function(context)
		local character = context.Character
		local player = context.Player
		local config = context.Config
		local template = findArmorAssets(context)
		if not template then
			return false
		end
		local attachmentPart = character:FindFirstChild(config.AttachmentPart)
		local visual = template:Clone()
		visual.Name = config.VisualName
		local armorPart = visual.PrimaryPart or visual:FindFirstChildWhichIsA("BasePart", true)
		local weld = visual:FindFirstChild("UpperTorsoWeld", true)
		if
			not attachmentPart
			or not attachmentPart:IsA("BasePart")
			or not armorPart
			or not weld
			or not weld:IsA("WeldConstraint")
		then
			visual:Destroy()
			return false
		end
		for _, object in ipairs(visual:GetDescendants()) do
			if object:IsA("BasePart") then
				object.Anchored = false
				object.CanCollide = false
				object.CanTouch = false
				object.CanQuery = false
				object.Massless = true
			end
		end
		local offset = typeof(config.AttachmentOffset) == "CFrame" and config.AttachmentOffset or CFrame.new()
		visual:PivotTo(attachmentPart.CFrame * offset)
		weld.Part0 = attachmentPart
		weld.Part1 = armorPart
		local previousVisual = character:FindFirstChild(config.VisualName)
		if previousVisual then
			previousVisual:Destroy()
		end
		clearArmorState(character)
		visual.Parent = character

		local maximum = math.max(1, config.MaxArmor)
		local amount = math.clamp(config.ArmorAmount, 0, maximum)
		player:SetAttribute("MaxArmor", maximum)
		character:SetAttribute("MaxArmor", maximum)
		player:SetAttribute("Armor", amount)
		character:SetAttribute("Armor", amount)

		local function removeWhenDepleted()
			removeArmorVisual(character, config.VisualName)
			clearArmorState(character)
		end
		local function syncArmor(source, target)
			local value = source:GetAttribute("Armor")
			if typeof(value) ~= "number" then
				return
			end
			value = math.clamp(value, 0, maximum)
			if source:GetAttribute("Armor") ~= value then
				source:SetAttribute("Armor", value)
			end
			if target:GetAttribute("Armor") ~= value then
				target:SetAttribute("Armor", value)
			end
			if value <= 0 then
				removeWhenDepleted()
			end
		end

		local state = { Connections = {} }
		armorStates[character] = state
		table.insert(
			state.Connections,
			player:GetAttributeChangedSignal("Armor"):Connect(function()
				syncArmor(player, character)
			end)
		)
		table.insert(
			state.Connections,
			character:GetAttributeChangedSignal("Armor"):Connect(function()
				syncArmor(character, player)
			end)
		)
		table.insert(
			state.Connections,
			player.CharacterRemoving:Connect(function(removingCharacter)
				if removingCharacter == character then
					clearArmorState(character)
				end
			end)
		)
		return true
	end,
})

return table.freeze(InventoryUseActionHandlers)
