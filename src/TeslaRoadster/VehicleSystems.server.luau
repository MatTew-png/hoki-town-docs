--!strict
-- ============================================================================
-- HOKI TOWN — Unified Master Vehicle Server Controller (VehicleSystems)
-- Architecture: Single Source of Truth for TeslaRoadster_HokiChassis
-- Responsibilities:
--   1. Seating & Parking Handbrake Lock (Rock-solid parking, Zero fling)
--   2. Safe Raycast Side Exit System (Left -> Right fallback -> Roof fallback)
--   3. Security-Validated FX Sync (Brake light, Hub TireSmoke, SkidTrails, Horn)
--   4. Attribute-driven Health & Fuel Simulation (Impact damage & Fuel drain)
--   5. HUD Lifecycle Management (CarStatusGui & Destroying cleanup)
--   6. Visual Suspension Spring Hiding
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")

local car = script.Parent :: Model
local seat = car:WaitForChild("DriveSeat") :: VehicleSeat
local prompt = seat:WaitForChild("DrivePrompt") :: ProximityPrompt
local tuneFolder = car:FindFirstChild("Hoki-Chassis Tune") or car:FindFirstChild("A-Chassis Tune") or car:WaitForChild("Hoki-Chassis Tune", 5) or car:WaitForChild("A-Chassis Tune", 5)
local guiTemplate = car:WaitForChild("CarStatusGui") :: ScreenGui

-- Ensure seats never auto-sit on touch; entry is strictly controlled via ProximityPrompt
seat.CanTouch = false

-- ============================================================================
-- 0. ANTI-FLING & ZERO-PUSH COLLISION GROUP CONFIGURATION
-- ============================================================================
pcall(function()
	pcall(function() PhysicsService:RegisterCollisionGroup("Vehicles") end)
	pcall(function() PhysicsService:RegisterCollisionGroup("Characters") end)
	PhysicsService:CollisionGroupSetCollidable("Vehicles", "Characters", false)
end)

local function applyVehicleCollisionGroup(inst: Instance)
	if inst:IsA("BasePart") then
		pcall(function()
			inst.CollisionGroup = "Vehicles"
		end)
	end
end

for _, desc in ipairs(car:GetDescendants()) do
	applyVehicleCollisionGroup(desc)
end
car.DescendantAdded:Connect(applyVehicleCollisionGroup)

local function applyCharacterCollisionGroup(char: Model)
	for _, desc in ipairs(char:GetDescendants()) do
		if desc:IsA("BasePart") then
			pcall(function()
				desc.CollisionGroup = "Characters"
			end)
		end
	end
	char.DescendantAdded:Connect(function(desc)
		if desc:IsA("BasePart") then
			pcall(function()
				desc.CollisionGroup = "Characters"
			end)
		end
	end)
end

for _, p in ipairs(Players:GetPlayers()) do
	if p.Character then applyCharacterCollisionGroup(p.Character) end
	p.CharacterAdded:Connect(applyCharacterCollisionGroup)
end
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(applyCharacterCollisionGroup)
end)

-- ============================================================================
-- 1. REMOTE EVENTS (Single Source of Truth)
-- ============================================================================
local exitRemote = tuneFolder:FindFirstChild("VehicleExitRequest") :: RemoteEvent?
if not exitRemote then
	exitRemote = Instance.new("RemoteEvent")
	exitRemote.Name = "VehicleExitRequest"
	exitRemote.Parent = tuneFolder
end

local fxRemote = tuneFolder:FindFirstChild("VehicleFXEvent") :: RemoteEvent?
if not fxRemote then
	fxRemote = Instance.new("RemoteEvent")
	fxRemote.Name = "VehicleFXEvent"
	fxRemote.Parent = tuneFolder
end

-- ============================================================================
-- 2. SUSPENSION SHOCK VISUAL HIDER
-- ============================================================================
local wheels = car:WaitForChild("Wheels")
local function hideShockVisual(instance: Instance)
	if instance:IsA("SpringConstraint") then
		instance.Visible = false
		instance:GetPropertyChangedSignal("Visible"):Connect(function()
			if instance.Visible then instance.Visible = false end
		end)
	elseif instance:IsA("BasePart") then
		local name = string.lower(instance.Name)
		if string.find(name, "shock", 1, true)
			or string.find(name, "spring", 1, true)
			or string.find(name, "damper", 1, true)
			or string.find(name, "coil", 1, true) then
			instance.Transparency = 1
			instance.LocalTransparencyModifier = 1
			instance:GetPropertyChangedSignal("Transparency"):Connect(function()
				if instance.Transparency < 1 then instance.Transparency = 1 end
			end)
		end
	end
end

for _, instance in ipairs(wheels:GetDescendants()) do
	hideShockVisual(instance)
end
wheels.DescendantAdded:Connect(hideShockVisual)

-- ============================================================================
-- 3. VEHICLE ATTRIBUTES (Health, Fuel & FX States)
-- ============================================================================
local MAX_HEALTH = 100
local MAX_FUEL = 100

local defaults = {
	ImpactSpeed1 = 12, ImpactDamage1 = 2,
	ImpactSpeed2 = 25, ImpactDamage2 = 5,
	ImpactSpeed3 = 40, ImpactDamage3 = 12,
	ImpactSpeed4 = 60, ImpactDamage4 = 22,
	ImpactSpeed5 = 85, ImpactDamage5 = 35,
	FuelDrainStartSpeed = 4,
	FuelDrainBasePerSecond = 0.01,
	FuelDrainPerStudPerSecond = 0.0002,
}
for name, value in pairs(defaults) do
	if car:GetAttribute(name) == nil then car:SetAttribute(name, value) end
end

if car:GetAttribute("MaxHealth") == nil then car:SetAttribute("MaxHealth", MAX_HEALTH) end
if car:GetAttribute("Health") == nil then car:SetAttribute("Health", MAX_HEALTH) end
if car:GetAttribute("MaxFuel") == nil then car:SetAttribute("MaxFuel", MAX_FUEL) end
if car:GetAttribute("Fuel") == nil then car:SetAttribute("Fuel", MAX_FUEL) end
if car:GetAttribute("IsBraking") == nil then car:SetAttribute("IsBraking", false) end
if car:GetAttribute("IsHonking") == nil then car:SetAttribute("IsHonking", false) end
if car:GetAttribute("IsDrifting") == nil then car:SetAttribute("IsDrifting", false) end

local function updatePowerForFuel()
	local fuel = math.max(0, tonumber(car:GetAttribute("Fuel")) or 0)
	local maxFuel = math.max(0.001, tonumber(car:GetAttribute("MaxFuel")) or MAX_FUEL)
	local displayedPercent = math.floor((fuel / maxFuel) * 100 + 0.5)
	car:SetAttribute("VehiclePowerDisabled", displayedPercent <= 0)
end
car:GetAttributeChangedSignal("Fuel"):Connect(updatePowerForFuel)
updatePowerForFuel()

-- ============================================================================
-- 4. LIGHTING, SOUNDS & TIRE FX SYNC
-- ============================================================================
local horn = seat:WaitForChild("HornSound") :: Sound
local teera = car:WaitForChild("Body"):WaitForChild("Teera Roadster")
local lights = teera:WaitForChild("Lights")
local tailMesh = lights:FindFirstChild("TaillightBar")
	or lights:FindFirstChild("Plane.007")
	or lights:FindFirstChildWhichIsA("BasePart")

local brakeGlow: SpotLight? = nil
if tailMesh and tailMesh:IsA("BasePart") then
	tailMesh.TextureID = ""
	tailMesh.Material = Enum.Material.Neon
	tailMesh.Color = Color3.new(1, 0.34902, 0.34902)
	local center = tailMesh:FindFirstChild("TaillightCenter")
	brakeGlow = center and center:FindFirstChild("BrakeGlow") :: SpotLight?
	if brakeGlow then
		brakeGlow.Color = Color3.new(1, 0.34902, 0.34902)
		brakeGlow.Brightness = 0.4
		brakeGlow.Range = 8
	end
end

-- Hub-mounted Smoke and Skid attachments
local rlHub = wheels:WaitForChild("RL"):WaitForChild("SuspensionGeometry"):WaitForChild("Hub")
local rrHub = wheels:WaitForChild("RR"):WaitForChild("SuspensionGeometry"):WaitForChild("Hub")
local smokeRL = rlHub:WaitForChild("RL_SmokeAtt"):WaitForChild("TireSmoke") :: ParticleEmitter
local smokeRR = rrHub:WaitForChild("RR_SmokeAtt"):WaitForChild("TireSmoke") :: ParticleEmitter
local trailRL = rlHub:WaitForChild("RL_SkidTrail") :: Trail
local trailRR = rrHub:WaitForChild("RR_SkidTrail") :: Trail

local function applyBrakeFX(isBraking: boolean)
	car:SetAttribute("IsBraking", isBraking)
	if tailMesh and tailMesh:IsA("BasePart") then
		if isBraking then
			tailMesh.Material = Enum.Material.Neon
			tailMesh.Color = Color3.fromRGB(255, 30, 30)
			if brakeGlow then
				brakeGlow.Brightness = 2.2
				brakeGlow.Range = 14
			end
		else
			tailMesh.Material = Enum.Material.Neon
			tailMesh.Color = Color3.new(1, 0.34902, 0.34902)
			if brakeGlow then
				brakeGlow.Brightness = 0.4
				brakeGlow.Range = 8
			end
		end
	end
end

local function applyDriftFX(isDrifting: boolean)
	car:SetAttribute("IsDrifting", isDrifting)
	smokeRL.Enabled = isDrifting
	smokeRR.Enabled = isDrifting
	trailRL.Enabled = isDrifting
	trailRR.Enabled = isDrifting
end

local function applyHornFX(isHonking: boolean)
	car:SetAttribute("IsHonking", isHonking)
	if isHonking then
		if not horn.IsPlaying then horn:Play() end
	else
		if horn.IsPlaying then horn:Stop() end
	end
end

applyBrakeFX(false)
applyDriftFX(false)
applyHornFX(false)

-- ============================================================================
-- 5. SECURITY VALIDATION
-- ============================================================================
local function isCurrentDriver(player: Player): boolean
	local occupant = seat.Occupant
	if not occupant or not occupant.Parent then return false end
	return Players:GetPlayerFromCharacter(occupant.Parent) == player
end

-- Handle Vehicle FX Remote
fxRemote.OnServerEvent:Connect(function(player, action: string, value: any)
	if not isCurrentDriver(player) then return end
	if action == "Brake" then
		applyBrakeFX(value == true)
	elseif action == "Drift" then
		applyDriftFX(value == true)
	elseif action == "Horn" then
		applyHornFX(value == true)
	end
end)

-- ============================================================================
-- 6. SAFE RAYCAST SIDE EXIT SYSTEM (Obstacle Detection)
-- ============================================================================
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = { car }
rayParams.RespectCanCollide = true

local function getSafeExitCFrame(): CFrame
	local seatCF = seat.CFrame
	local origin = seat.Position + Vector3.new(0, 0.5, 0)
	
	-- 1. Check Driver Door (Left: -seatCF.RightVector * 5.5)
	local leftDir = -seatCF.RightVector * 5.5
	local leftHit = Workspace:Raycast(origin, leftDir, rayParams)
	if not leftHit then
		local targetCF = seatCF * CFrame.new(-5.5, 0.5, 0)
		return CFrame.new(targetCF.Position, targetCF.Position + seatCF.LookVector)
	end
	
	-- 2. Fallback: Check Passenger Door (Right: seatCF.RightVector * 5.5)
	local rightDir = seatCF.RightVector * 5.5
	local rightHit = Workspace:Raycast(origin, rightDir, rayParams)
	if not rightHit then
		local targetCF = seatCF * CFrame.new(5.5, 0.5, 0)
		return CFrame.new(targetCF.Position, targetCF.Position + seatCF.LookVector)
	end
	
	-- 3. Fallback: Roof (Up: 0, 4.5, 0)
	local roofCF = seatCF * CFrame.new(0, 4.5, 0)
	return CFrame.new(roofCF.Position, roofCF.Position + seatCF.LookVector)
end

local function safeUnseat(humanoid: Humanoid, hrp: BasePart)
	local targetCF = getSafeExitCFrame()
	
	local weld = seat:FindFirstChild("SeatWeld")
	if weld and weld:IsA("Weld") then
		weld:Destroy()
	end
	
	humanoid.Sit = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	
	hrp.CFrame = targetCF
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	
	task.defer(function()
		if seat.Occupant == nil then
			seat.AssemblyLinearVelocity = Vector3.zero
			seat.AssemblyAngularVelocity = Vector3.zero
			seat.Anchored = false
			if not seat.Disabled then
				prompt.Enabled = true
			end
			pcall(function()
				local root = seat.AssemblyRootPart or seat
				root:SetNetworkOwner(nil)
			end)
		end
	end)
end

exitRemote.OnServerEvent:Connect(function(player)
	if not isCurrentDriver(player) then return end
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if humanoid and hrp then
		safeUnseat(humanoid, hrp)
	end
end)

-- Fallback unseat (e.g. humanoid died or broken externally)
seat.ChildRemoved:Connect(function(child)
	if child.Name == "SeatWeld" and child:IsA("Weld") then
		task.defer(function()
			if seat.Occupant == nil then
				seat.AssemblyLinearVelocity = Vector3.zero
				seat.AssemblyAngularVelocity = Vector3.zero
				seat.Anchored = false
				if not seat.Disabled then
					prompt.Enabled = true
				end
				pcall(function()
					local root = seat.AssemblyRootPart or seat
					root:SetNetworkOwner(nil)
				end)
			end
		end)
	end
end)

-- ============================================================================
-- 7. SEATING & PARKING HANDBRAKE LOCK (Zero-Fling / Zero-Push)
-- ============================================================================
prompt.Triggered:Connect(function(player)
	if seat.Occupant ~= nil or seat.Disabled then return end
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	prompt.Enabled = false
	seat.Anchored = false
	seat:Sit(humanoid)
end)

seat:GetPropertyChangedSignal("Occupant"):Connect(function()
	local hum = seat.Occupant
	if hum == nil then
		task.wait(0.1)
		if seat.Occupant == nil and not seat.Disabled then
			seat.AssemblyLinearVelocity = Vector3.zero
			seat.AssemblyAngularVelocity = Vector3.zero
			seat.Anchored = false
			prompt.Enabled = true
		end
		applyHornFX(false)
		applyDriftFX(false)
		applyBrakeFX(false)
		pcall(function()
			local root = seat.AssemblyRootPart or seat
			root:SetNetworkOwner(nil)
		end)
	else
		seat.Anchored = false
		prompt.Enabled = false
		local driverPlayer = Players:GetPlayerFromCharacter(hum.Parent)
		if driverPlayer then
			pcall(function()
				local root = seat.AssemblyRootPart or seat
				root:SetNetworkOwner(driverPlayer)
			end)
		end
	end
end)

seat.Anchored = false
if seat.Disabled then
	prompt.Enabled = false
	seat:GetPropertyChangedSignal("Disabled"):Connect(function()
		if not seat.Disabled and seat.Occupant == nil then
			prompt.Enabled = true
		end
	end)
else
	prompt.Enabled = (seat.Occupant == nil)
end

-- ============================================================================
-- 8. HUD LIFECYCLE (CarStatusGui)
-- ============================================================================
guiTemplate.Enabled = false
guiTemplate.ResetOnSpawn = false

local currentPlayer: Player? = nil

local function removeGui(player: Player?)
	if player then
		local playerGui = player:FindFirstChildOfClass("PlayerGui")
		if playerGui then
			local existing = playerGui:FindFirstChild(car.Name .. "StatusGui")
			if existing then existing:Destroy() end
		end
	end
end

local function updateOccupant()
	local humanoid = seat.Occupant
	local newPlayer = humanoid and Players:GetPlayerFromCharacter(humanoid.Parent) or nil
	if currentPlayer == newPlayer then return end

	removeGui(currentPlayer)
	currentPlayer = newPlayer
	if not newPlayer then return end

	task.spawn(function()
		local playerGui = newPlayer:WaitForChild("PlayerGui", 10)
		if not playerGui or currentPlayer ~= newPlayer or not car.Parent then return end

		local oldGui = playerGui:FindFirstChild(car.Name .. "StatusGui")
		if oldGui then oldGui:Destroy() end

		local screen = guiTemplate:Clone()
		screen.Name = car.Name .. "StatusGui"
		screen.Enabled = true
		screen.ResetOnSpawn = false

		local reference = Instance.new("ObjectValue")
		reference.Name = "VehicleRef"
		reference.Value = car
		reference.Parent = screen

		screen.Parent = playerGui
	end)
end

seat:GetPropertyChangedSignal("Occupant"):Connect(updateOccupant)
Players.PlayerRemoving:Connect(function(player)
	if player == currentPlayer then
		removeGui(player)
		currentPlayer = nil
	end
end)
updateOccupant()

car.Destroying:Connect(function()
	local occupant = seat.Occupant
	if occupant and occupant.Parent then
		local player = Players:GetPlayerFromCharacter(occupant.Parent)
		if player then removeGui(player) end
		occupant.Sit = false
	end
end)

-- ============================================================================
-- 9. CRASH DAMAGE & IMPACT SENSORS
-- ============================================================================
local impactFolder = car:WaitForChild("Body"):FindFirstChild("ImpactSensors")
local lastImpactTime = 0
local IMPACT_COOLDOWN = 0.65
local MIN_IMPACT_SPEED = 12
local lastVehicleVelocity = seat.AssemblyLinearVelocity

RunService.Heartbeat:Connect(function()
	if seat.Parent then
		lastVehicleVelocity = seat.AssemblyLinearVelocity
	end
end)

local supportRayParams = RaycastParams.new()
supportRayParams.FilterType = Enum.RaycastFilterType.Exclude
supportRayParams.FilterDescendantsInstances = { car }
supportRayParams.RespectCanCollide = true

local function isSupportedByRamp(): boolean
	local wheelsInst = car:FindFirstChild("Wheels")
	if not wheelsInst then return false end
	local inclinedWheelCount = 0
	for _, wheel in ipairs(wheelsInst:GetChildren()) do
		if not wheel:IsA("BasePart") then continue end
		local radius = math.max(wheel.Size.Y, wheel.Size.Z) * 0.5
		local result = Workspace:Raycast(
			wheel.Position + Vector3.yAxis * 0.2,
			-Vector3.yAxis * (radius + 1.25),
			supportRayParams
		)
		if result and result.Normal.Y > 0.05 and result.Normal.Y < 0.995 then
			inclinedWheelCount += 1
		end
	end
	return inclinedWheelCount >= 2
end

local function isRampGeometry(part: BasePart): boolean
	if part:IsA("WedgePart") then return true end
	local ancestor: Instance? = part
	while ancestor and ancestor ~= Workspace do
		if string.find(string.lower(ancestor.Name), "ramp", 1, true) then
			return true
		end
		ancestor = ancestor.Parent
	end
	return false
end

local function getImpactDamage(speed: number): number
	local tiers = {}
	for i = 1, 5 do
		table.insert(tiers, {
			speed = tonumber(car:GetAttribute("ImpactSpeed" .. i)) or defaults["ImpactSpeed" .. i],
			damage = math.max(0, tonumber(car:GetAttribute("ImpactDamage" .. i)) or defaults["ImpactDamage" .. i]),
		})
	end
	table.sort(tiers, function(a, b) return a.speed < b.speed end)
	if speed < tiers[1].speed then return 0 end
	for i = 2, #tiers do
		local lower, upper = tiers[i - 1], tiers[i]
		if speed <= upper.speed then
			local span = upper.speed - lower.speed
			if span <= 0 then return upper.damage end
			local alpha = math.clamp((speed - lower.speed) / span, 0, 1)
			return lower.damage + (upper.damage - lower.damage) * alpha
		end
	end
	return tiers[#tiers].damage
end

local function processImpact(sourcePart: BasePart, otherPart: BasePart)
	if otherPart:IsDescendantOf(car) or not otherPart.CanCollide then return end
	local otherModel = otherPart:FindFirstAncestorOfClass("Model")
	if otherModel and otherModel:FindFirstChildOfClass("Humanoid") then return end
	if isRampGeometry(otherPart) then return end

	local now = os.clock()
	if now - lastImpactTime < IMPACT_COOLDOWN then return end

	local relativeVelocity = lastVehicleVelocity - otherPart.AssemblyLinearVelocity
	local carLook = seat.CFrame.LookVector
	local sensorDirection = sourcePart.Name == "Rear" and -carLook or carLook
	local horizontalDirection = Vector3.new(sensorDirection.X, 0, sensorDirection.Z)
	if horizontalDirection.Magnitude < 0.1 then return end
	horizontalDirection = horizontalDirection.Unit
	local closingSpeed = relativeVelocity:Dot(horizontalDirection)

	if isSupportedByRamp() and sensorDirection.Y > 0.35 then return end
	if closingSpeed < MIN_IMPACT_SPEED then return end

	local damage = getImpactDamage(closingSpeed)
	if damage <= 0 then return end

	lastImpactTime = now
	car:SetAttribute("Health", math.max(0, (tonumber(car:GetAttribute("Health")) or MAX_HEALTH) - damage))
end

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude
overlapParams.FilterDescendantsInstances = { car }
overlapParams.RespectCanCollide = true

local impactSensors = {}
if impactFolder then
	for _, sensor in ipairs(impactFolder:GetChildren()) do
		if sensor:IsA("BasePart") then
			sensor.CanTouch = true
			table.insert(impactSensors, sensor)
			sensor.Touched:Connect(function(otherPart)
				if otherPart:IsA("BasePart") then processImpact(sensor, otherPart) end
			end)
		end
	end
end

task.spawn(function()
	while car.Parent do
		for _, sensor in ipairs(impactSensors) do
			if sensor.Parent then
				local querySize = sensor.Size + Vector3.new(0.5, 0.5, 4)
				for _, otherPart in ipairs(Workspace:GetPartBoundsInBox(sensor.CFrame, querySize, overlapParams)) do
					processImpact(sensor, otherPart)
				end
			end
		end
		task.wait(0.05)
	end
end)

-- ============================================================================
-- 10. GRADUAL FUEL DRAIN WHILE DRIVING
-- ============================================================================
task.spawn(function()
	while car.Parent do
		local dt = task.wait(0.25)
		local fuelDrainStartSpeed = math.max(0, tonumber(car:GetAttribute("FuelDrainStartSpeed")) or defaults.FuelDrainStartSpeed)
		if seat.Occupant and seat.AssemblyLinearVelocity.Magnitude > fuelDrainStartSpeed then
			local fuel = tonumber(car:GetAttribute("Fuel")) or MAX_FUEL
			if fuel > 0 then
				local speed = seat.AssemblyLinearVelocity.Magnitude
				local baseDrain = math.max(0, tonumber(car:GetAttribute("FuelDrainBasePerSecond")) or defaults.FuelDrainBasePerSecond)
				local speedDrain = math.max(0, tonumber(car:GetAttribute("FuelDrainPerStudPerSecond")) or defaults.FuelDrainPerStudPerSecond)
				local drainPerSecond = baseDrain + speed * speedDrain
				car:SetAttribute("Fuel", math.max(0, fuel - drainPerSecond * dt))
			end
		end
	end
end)
