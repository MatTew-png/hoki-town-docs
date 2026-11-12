--!strict
-- ============================================================================
-- HOKI TOWN — Production Vehicle Server Controller (VehicleSystems)
-- Target Model: Workspace.TeslaRoadster
-- Features:
--   • Safe ProximityPrompt entry & side exit (No glitch / roof clipping)
--   • Live Multiplayer VFX Sync (Brake lights, Tire smoke, Skid trails)
--   • 5-Slot Customization & Live Tuning Remote (Body, Seats, Console, Rims, Calipers, Underglow)
--   • Pedestrian Ragdoll & Damage on high-speed impact (> 15 studs/s)
--   • Wall Crash Damage with 5 speed tiers & GodMode toggle
--   • Dynamic Engine Breakdown VFX (White smoke < 50%, Black smoke < 25%, Fire at 0%)
--   • Instant Vehicle Repair Remote ([R] key / Proximity repair)
--   • Automatic HUD Lifecycle (CarStatusGui)
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local car = script.Parent :: Model
local seat = car:WaitForChild("DriveSeat", 5) :: VehicleSeat?
if not seat then
	warn("[VehicleSystems] Aborting: No DriveSeat found in " .. car:GetFullName())
	return
end
local passengerSeat = car:FindFirstChild("PassengerSeat") :: Seat?
local bodyModel = (car:FindFirstChild("Body") or car) :: Instance
local wheelsModel = (car:FindFirstChild("Wheels") or car) :: Instance
local guiTemplate = car:WaitForChild("CarStatusGui", 5) :: ScreenGui?
if not guiTemplate then
	warn("[VehicleSystems] Aborting: No CarStatusGui found in " .. car:GetFullName())
	return
end

-- Ensure seats never auto-sit on touch; entry is strictly controlled
seat.CanTouch = false
if passengerSeat then
	passengerSeat.CanTouch = false
	passengerSeat.Anchored = false
end

-- Low-slung supercar cabin posture calibration (keeps driver head safely under glass roof)
-- Shift vertically in seat space so Roblox's sitting rotation on SeatWeld.C0 is preserved.
local function applyCabinSeatOffset(targetSeat: Seat | VehicleSeat)
	targetSeat.ChildAdded:Connect(function(child: Instance)
		if child:IsA("Weld") and child.Name == "SeatWeld" then
			local weld = child :: Weld
			task.defer(function()
				if weld.Parent ~= targetSeat or weld:GetAttribute("HokiOffsetApplied") then
					return
				end
				weld:SetAttribute("HokiOffsetApplied", true)
				weld.C0 = CFrame.new(0, -0.64, -0.10) * CFrame.Angles(math.rad(26), 0, 0) * weld.C0
			end)
		end
	end)
end

applyCabinSeatOffset(seat)
if passengerSeat then
	applyCabinSeatOffset(passengerSeat)
end

-- ============================================================================
-- 1. AUTO-CREATE REQUIRED REMOTES & ENGINE BAY VFX
-- ============================================================================
local repairRemote = car:FindFirstChild("VehicleRepairRequest") :: RemoteEvent?
if not repairRemote then
	repairRemote = Instance.new("RemoteEvent")
	repairRemote.Name = "VehicleRepairRequest"
	repairRemote.Parent = car
end

local exitRemote = car:FindFirstChild("VehicleExitRequest") :: RemoteEvent?
if not exitRemote then
	exitRemote = Instance.new("RemoteEvent")
	exitRemote.Name = "VehicleExitRequest"
	exitRemote.Parent = car
end

local tuningRemote = ReplicatedStorage:FindFirstChild("HokiVehicleTuningRemote") :: RemoteEvent?
if not tuningRemote then
	tuningRemote = Instance.new("RemoteEvent")
	tuningRemote.Name = "HokiVehicleTuningRemote"
	tuningRemote.Parent = ReplicatedStorage
end

-- Engine Bay Breakdown VFX Attachment & Particles
local engineBayAtt = seat:FindFirstChild("EngineBay_VFX") :: Attachment?
if not engineBayAtt then
	engineBayAtt = Instance.new("Attachment")
	engineBayAtt.Name = "EngineBay_VFX"
	engineBayAtt.Position = Vector3.new(0, 1.2, -4.8) -- Front hood / motor area
	engineBayAtt.Parent = seat
end

local warningWhiteSmoke = engineBayAtt:FindFirstChild("WarningWhiteSmoke") :: ParticleEmitter?
if not warningWhiteSmoke then
	warningWhiteSmoke = Instance.new("ParticleEmitter")
	warningWhiteSmoke.Name = "WarningWhiteSmoke"
	warningWhiteSmoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	warningWhiteSmoke.Color = ColorSequence.new(Color3.fromRGB(235, 235, 240))
	warningWhiteSmoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.8),
		NumberSequenceKeypoint.new(1.0, 3.8),
	})
	warningWhiteSmoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.4),
		NumberSequenceKeypoint.new(1.0, 1.0),
	})
	warningWhiteSmoke.Lifetime = NumberRange.new(0.8, 1.6)
	warningWhiteSmoke.Rate = 22
	warningWhiteSmoke.Speed = NumberRange.new(3, 6)
	warningWhiteSmoke.EmissionDirection = Enum.NormalId.Top
	warningWhiteSmoke.Enabled = false
	warningWhiteSmoke.Parent = engineBayAtt
end

local heavyBlackSmoke = engineBayAtt:FindFirstChild("HeavyBlackSmoke") :: ParticleEmitter?
if not heavyBlackSmoke then
	heavyBlackSmoke = Instance.new("ParticleEmitter")
	heavyBlackSmoke.Name = "HeavyBlackSmoke"
	heavyBlackSmoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	heavyBlackSmoke.Color = ColorSequence.new(Color3.fromRGB(35, 35, 38))
	heavyBlackSmoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 1.2),
		NumberSequenceKeypoint.new(1.0, 5.5),
	})
	heavyBlackSmoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.15),
		NumberSequenceKeypoint.new(1.0, 1.0),
	})
	heavyBlackSmoke.Lifetime = NumberRange.new(1.0, 2.2)
	heavyBlackSmoke.Rate = 35
	heavyBlackSmoke.Speed = NumberRange.new(4, 8)
	heavyBlackSmoke.EmissionDirection = Enum.NormalId.Top
	heavyBlackSmoke.Enabled = false
	heavyBlackSmoke.Parent = engineBayAtt
end

local engineFire = engineBayAtt:FindFirstChild("EngineFire") :: ParticleEmitter?
if not engineFire then
	engineFire = Instance.new("ParticleEmitter")
	engineFire.Name = "EngineFire"
	engineFire.Texture = "rbxasset://textures/particles/fire_main.dds"
	engineFire.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 220, 50)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 90, 20)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(150, 20, 10)),
	})
	engineFire.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 1.2),
		NumberSequenceKeypoint.new(1.0, 3.2),
	})
	engineFire.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.1),
		NumberSequenceKeypoint.new(1.0, 1.0),
	})
	engineFire.Lifetime = NumberRange.new(0.4, 0.8)
	engineFire.Rate = 45
	engineFire.Speed = NumberRange.new(3, 7)
	engineFire.EmissionDirection = Enum.NormalId.Top
	engineFire.Enabled = false
	engineFire.Parent = engineBayAtt
end

-- ============================================================================
-- 2. ATTRIBUTES & DEFAULT VALUES
-- ============================================================================
local MAX_HEALTH = 100
local MAX_FUEL = 100

local DEFAULT_ATTRIBUTES: { [string]: any } = {
	MaxHealth = MAX_HEALTH,
	Health = MAX_HEALTH,
	MaxFuel = MAX_FUEL,
	Fuel = MAX_FUEL,
	GodMode = true,
	VehiclePowerDisabled = false,
	PerfStage = 2,
	TireMode = "Arcade",
	BrakeMultiplier = 1.25,
	RideHeightOffset = 0.0,
	CamberAngle = 0.0,
	WheelSpacer = 0.0,
	SuspensionStiffScale = 1.0,
	HeadlightsOn = false,
	UnderglowEnabled = false,
	UnderglowColor = Color3.fromRGB(0, 220, 255),
	BodyColor = Color3.fromRGB(215, 30, 45),
	RimColor = Color3.fromRGB(175, 175, 180),
	ImpactSpeed1 = 12,
	ImpactDamage1 = 2,
	ImpactSpeed2 = 25,
	ImpactDamage2 = 5,
	ImpactSpeed3 = 40,
	ImpactDamage3 = 12,
	ImpactSpeed4 = 60,
	ImpactDamage4 = 22,
	ImpactSpeed5 = 85,
	ImpactDamage5 = 35,
	FuelDrainStartSpeed = 4,
	FuelDrainBasePerSecond = 0.01,
	FuelDrainPerStudPerSecond = 0.0002,
}

for name, value in pairs(DEFAULT_ATTRIBUTES) do
	if car:GetAttribute(name) == nil then
		car:SetAttribute(name, value)
	end
end

-- ============================================================================
-- 3. ENTRY & SAFE SIDE-EXIT CONTROLLER (+ OCCUPANT NO-COLLISION SHIELD)
-- ============================================================================
type OccupantNoCollideEntry = {
	folder: Folder,
	descConn: RBXScriptConnection?,
	cleanupThread: thread?,
}

local occupantNoCollideByChar: { [Model]: OccupantNoCollideEntry } = {}
local recentOccupantExitAt: { [Model]: number } = {}

local function getVehicleCollidableParts(): { BasePart }
	local list = {} :: { BasePart }
	for _, desc in ipairs(car:GetDescendants()) do
		if
			desc:IsA("BasePart")
			and (desc.CanCollide or desc.Name == "SconHitbox" or (desc.Parent and desc.Parent.Name == "SconHitbox"))
		then
			table.insert(list, desc)
		end
	end
	return list
end

local function addNoCollideForPart(folder: Folder, charPart: BasePart, carParts: { BasePart })
	for _, carPart in ipairs(carParts) do
		local nc = Instance.new("NoCollisionConstraint")
		nc.Part0 = charPart
		nc.Part1 = carPart
		nc.Parent = folder
	end
end

local function attachOccupantNoCollision(char: Model)
	local existing = occupantNoCollideByChar[char]
	if existing then
		if existing.cleanupThread then
			pcall(task.cancel, existing.cleanupThread)
			existing.cleanupThread = nil
		end
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = "SconOccupantNoCollide_" .. char.Name
	folder.Parent = car

	local carParts = getVehicleCollidableParts()
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") then
			addNoCollideForPart(folder, d, carParts)
		end
	end

	local descConn = char.DescendantAdded:Connect(function(d: Instance)
		if d:IsA("BasePart") and folder.Parent then
			addNoCollideForPart(folder, d, getVehicleCollidableParts())
		end
	end)

	occupantNoCollideByChar[char] = {
		folder = folder,
		descConn = descConn,
		cleanupThread = nil,
	}
end

local function scheduleDetachOccupantNoCollision(char: Model)
	local entry = occupantNoCollideByChar[char]
	if not entry then
		return
	end
	if entry.descConn then
		entry.descConn:Disconnect()
		entry.descConn = nil
	end
	if entry.cleanupThread then
		pcall(task.cancel, entry.cleanupThread)
	end
	entry.cleanupThread = task.delay(0.45, function()
		if occupantNoCollideByChar[char] == entry then
			occupantNoCollideByChar[char] = nil
		end
		if entry.folder.Parent then
			entry.folder:Destroy()
		end
	end)
end

local existingPrompt = seat:FindFirstChild("DrivePrompt")
local drivePrompt: ProximityPrompt
if existingPrompt and existingPrompt:IsA("ProximityPrompt") then
	drivePrompt = existingPrompt
else
	drivePrompt = Instance.new("ProximityPrompt")
	drivePrompt.Name = "DrivePrompt"
	drivePrompt.ObjectText = "Tesla Roadster"
	drivePrompt.HoldDuration = 0
	drivePrompt.Parent = seat
end
drivePrompt.KeyboardKeyCode = Enum.KeyCode.F
drivePrompt.ActionText = "ขับรถ (Drive)"
drivePrompt.MaxActivationDistance = 15
drivePrompt.RequiresLineOfSight = false

drivePrompt.Triggered:Connect(function(player: Player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and not seat.Occupant and char then
		attachOccupantNoCollision(char)
		seat:Sit(hum)
	end
end)

local function findSafeExitCFrame(char: Model, targetSeat: Seat | VehicleSeat, isDriver: boolean): CFrame
	local weightPart = bodyModel:FindFirstChild("#Weight") :: BasePart?
	local centerPos = weightPart and weightPart.Position or targetSeat.Position
	local flatFwd = Vector3.new(targetSeat.CFrame.LookVector.X, 0, targetSeat.CFrame.LookVector.Z)
	if flatFwd.Magnitude < 0.05 then
		flatFwd = Vector3.new(targetSeat.CFrame.UpVector.X, 0, targetSeat.CFrame.UpVector.Z)
	end
	flatFwd = flatFwd.Magnitude > 0.05 and flatFwd.Unit or Vector3.new(0, 0, -1)
	local flatRight = flatFwd:Cross(Vector3.yAxis).Unit

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { car, char }

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { car, char }
	rayParams.RespectCanCollide = true

	local sideOrder = if isDriver then { -6.2, 6.2 } else { 6.2, -6.2 }
	local candidates = {
		centerPos + flatRight * sideOrder[1] + Vector3.new(0, 1.5, 0),
		centerPos + flatRight * sideOrder[2] + Vector3.new(0, 1.5, 0),
		centerPos + Vector3.new(0, 5.8, 0),
		centerPos - flatFwd * 9.6 + Vector3.new(0, 1.5, 0),
		centerPos + flatFwd * 9.8 + Vector3.new(0, 1.5, 0),
	}

	local chosenPos = candidates[1]
	for _, pos in ipairs(candidates) do
		local blocking = workspace:GetPartBoundsInBox(CFrame.new(pos), Vector3.new(2.2, 4.4, 2.2), overlapParams)
		local hasSolid = false
		for _, part in ipairs(blocking) do
			if part.CanCollide then
				hasSolid = true
				break
			end
		end
		if not hasSolid then
			chosenPos = pos
			break
		end
	end

	local floorHit = workspace:Raycast(chosenPos + Vector3.new(0, 1.0, 0), Vector3.new(0, -8.0, 0), rayParams)
	if floorHit then
		chosenPos = Vector3.new(chosenPos.X, math.max(floorHit.Position.Y + 3.0, chosenPos.Y), chosenPos.Z)
	end
	return CFrame.lookAt(chosenPos, chosenPos + flatFwd)
end

local function ejectOccupantToSide(player: Player, targetSeat: Seat | VehicleSeat, isDriver: boolean)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or not hrp or not char then
		return
	end

	attachOccupantNoCollision(char)
	recentOccupantExitAt[char] = os.clock()

	-- Unseat safely
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	hum.Sit = false

	local seatWeld = targetSeat:FindFirstChild("SeatWeld")
	if seatWeld then
		seatWeld:Destroy()
	end

	local exitCF = findSafeExitCFrame(char, targetSeat, isDriver)
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end
	char:PivotTo(exitCF)
	scheduleDetachOccupantNoCollision(char)
end

exitRemote.OnServerEvent:Connect(function(player: Player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end

	if seat.Occupant == hum then
		ejectOccupantToSide(player, seat, true)
	elseif passengerSeat and passengerSeat.Occupant == hum then
		ejectOccupantToSide(player, passengerSeat, false)
	end
end)

-- ============================================================================
-- 4. LIVE MULTIPLAYER TUNING & VFX SYNC (HokiVehicleTuningRemote)
-- ============================================================================
local teeraMesh = bodyModel:FindFirstChild("Teera Roadster")
local lightsFolder = (teeraMesh and teeraMesh:FindFirstChild("Lights")) or bodyModel:FindFirstChild("Lights", true)
local rearLightMesh = (lightsFolder and lightsFolder:FindFirstChild("Plane.007")) :: BasePart?
local brakePointLight = rearLightMesh and rearLightMesh:FindFirstChild("HokiBrakeGlow") :: PointLight?

local function ensureSeatAudio(
	name: string,
	soundId: string,
	minDist: number,
	maxDist: number,
	lowGain: number,
	midGain: number,
	highGain: number
): Sound
	local existing = seat:FindFirstChild(name)
	local s: Sound
	if existing and existing:IsA("Sound") then
		s = existing
	else
		s = Instance.new("Sound")
		s.Name = name
		s.Parent = seat
	end
	s.SoundId = soundId
	s.Looped = false
	s.Volume = 0
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = minDist
	s.RollOffMaxDistance = maxDist

	local eqExisting = s:FindFirstChild("#EQ")
	local eq: EqualizerSoundEffect
	if eqExisting and eqExisting:IsA("EqualizerSoundEffect") then
		eq = eqExisting
	else
		eq = Instance.new("EqualizerSoundEffect")
		eq.Name = "#EQ"
		eq.Parent = s
	end
	eq.LowGain = lowGain
	eq.MidGain = midGain
	eq.HighGain = highGain
	eq.Enabled = true
	return s
end

local hornSound = ensureSeatAudio("HokiTeslaHorn", "rbxassetid://9120385543", 12, 160, 1.0, 0.0, -2.5)
hornSound.Volume = 0.50
local impactLightSound = ensureSeatAudio("HokiImpactLight", "rbxassetid://8113081527", 10, 110, 4.5, -6.0, -18.0)
local impactHeavySound = ensureSeatAudio("HokiImpactHeavy", "rbxassetid://8113081527", 12, 150, 2.0, -1.0, -5.0)

local hornStartClock = 0
local lastHornToggleClock = 0
local hornReleaseToken = 0

tuningRemote.OnServerEvent:Connect(function(player: Player, targetCar: Instance?, action: string, payload: any)
	if targetCar ~= car or not payload then
		return
	end

	if action == "VFXState" then
		-- Sync brake lights across all observing clients
		local braking = payload.Braking == true
		local smoking = payload.Smoking == true
		local skidding = payload.Skidding == true

		if rearLightMesh then
			local headlightsOn = car:GetAttribute("HeadlightsOn") == true
			if braking then
				rearLightMesh.Material = Enum.Material.Neon
				rearLightMesh.Color = Color3.fromRGB(255, 30, 30)
			elseif headlightsOn then
				rearLightMesh.Material = Enum.Material.Neon
				rearLightMesh.Color = Color3.fromRGB(165, 45, 45)
			else
				rearLightMesh.Material = Enum.Material.SmoothPlastic
				rearLightMesh.Color = Color3.fromRGB(75, 25, 28)
			end
		end
		if brakePointLight then
			brakePointLight.Enabled = braking
		end

		-- Sync tire smoke across wheels
		for _, wName in ipairs({ "FL", "FR", "RL", "RR" }) do
			local wheel = wheelsModel:FindFirstChild(wName)
			if wheel then
				local isRear = (wName == "RL" or wName == "RR")
				local pe = wheel:FindFirstChildWhichIsA("ParticleEmitter", true)
				if pe then
					pe.Enabled = smoking and (isRear or payload.AllWheels)
				end
				local tr = wheel:FindFirstChildWhichIsA("Trail", true)
				if tr then
					tr.Enabled = skidding and (isRear or payload.AllWheels)
				end
			end
		end
	elseif action == "SetAttribute" and typeof(payload) == "table" then
		for k, v in pairs(payload) do
			car:SetAttribute(k, v)
		end
	elseif action == "Horn" and typeof(payload) == "table" then
		local occupantHum = seat.Occupant
		local occupantChar = occupantHum and occupantHum.Parent
		local occupantPlayer = if occupantChar and occupantChar:IsA("Model")
			then Players:GetPlayerFromCharacter(occupantChar)
			else nil
		if occupantPlayer ~= player then
			return
		end

		local now = os.clock()
		local active = payload.Active == true
		if active then
			if now - lastHornToggleClock < 0.08 then
				return
			end
			lastHornToggleClock = now
			hornReleaseToken += 1
			hornStartClock = now
			hornSound.Volume = 0.50
			hornSound.PlaybackSpeed = 1.0
			hornSound.TimePosition = 0
			hornSound:Play()
		else
			hornReleaseToken += 1
			local token = hornReleaseToken
			local minBeepRemain = 0.22 - (now - hornStartClock)
			if minBeepRemain > 0.02 then
				task.delay(minBeepRemain, function()
					if hornReleaseToken == token and hornSound.Playing then
						hornSound:Stop()
					end
				end)
			else
				hornSound:Stop()
			end
		end
	elseif action == "Customization" and typeof(payload) == "table" then
		-- Slot 1: Body Paint
		if typeof(payload.BodyColor) == "Color3" then
			car:SetAttribute("BodyColor", payload.BodyColor)
			local paintPart = (teeraMesh and teeraMesh:FindFirstChild("Paint"))
				or bodyModel:FindFirstChild("Body_Primary_Paint", true)
			if paintPart and paintPart:IsA("BasePart") then
				paintPart.Color = payload.BodyColor
			end
		end
		-- Slot 4: Rims
		if typeof(payload.RimColor) == "Color3" then
			car:SetAttribute("RimColor", payload.RimColor)
			for _, desc in ipairs(wheelsModel:GetDescendants()) do
				if
					desc:IsA("BasePart")
					and (desc.Name == "Plane.006" or desc.Name == "Rim" or desc.Material == Enum.Material.Metal)
				then
					desc.Color = payload.RimColor
				end
			end
		end
		-- Underglow
		if typeof(payload.UnderglowColor) == "Color3" then
			car:SetAttribute("UnderglowColor", payload.UnderglowColor)
		end
		if payload.UnderglowEnabled ~= nil then
			car:SetAttribute("UnderglowEnabled", payload.UnderglowEnabled == true)
		end
	end
end)

-- ============================================================================
-- 5. REPAIR SYSTEM ([R] / RemoteEvent)
-- ============================================================================
local function performFullRepair()
	car:SetAttribute("Health", MAX_HEALTH)
	car:SetAttribute("Fuel", MAX_FUEL)
	car:SetAttribute("VehiclePowerDisabled", false)

	warningWhiteSmoke.Enabled = false
	heavyBlackSmoke.Enabled = false
	engineFire.Enabled = false
end

repairRemote.OnServerEvent:Connect(function(player: Player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	-- Allow repair if player is seated or standing within 18 studs of car
	local dist = (hrp.Position - seat.Position).Magnitude
	if dist <= 24 or seat.Occupant == (char and char:FindFirstChildOfClass("Humanoid")) then
		performFullRepair()
	end
end)

-- ============================================================================
-- 6. PEDESTRIAN RAGDOLL & WALL COLLISION DAMAGE
-- ============================================================================
local lastVehicleVelocity = Vector3.zero
RunService.Heartbeat:Connect(function()
	if seat.Parent then
		lastVehicleVelocity = seat.AssemblyLinearVelocity
	end
end)

local lastPedImpact = 0
local function handlePedestrianHit(humanoid: Humanoid, hitPart: BasePart)
	local char = humanoid.Parent
	if not char or char == (seat.Occupant and seat.Occupant.Parent) then
		return
	end
	if char:IsA("Model") then
		local exitedAt = recentOccupantExitAt[char]
		if exitedAt and (os.clock() - exitedAt) < 1.5 then
			return
		end
	end

	local now = os.clock()
	if now - lastPedImpact < 0.35 then
		return
	end

	local speed = lastVehicleVelocity.Magnitude
	if speed < 15 then
		return
	end -- Filter gentle parking bumps

	lastPedImpact = now
	local damage = math.clamp(speed * 1.45, 10, 100)
	humanoid:TakeDamage(damage)

	-- Apply Ragdoll State
	humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
	local victimRoot = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if victimRoot then
		local knockbackDir = (lastVehicleVelocity.Unit + Vector3.new(0, 0.45, 0)).Unit
		victimRoot:ApplyImpulse(knockbackDir * (victimRoot.AssemblyMass * speed * 0.85))
	end
end

-- Wall impact sensor detection (5 speed tiers)
local impactFolder = bodyModel:FindFirstChild("ImpactSensors")
local lastImpactTime = 0

local function getImpactDamage(speed: number): number
	local tiers = {}
	for i = 1, 5 do
		table.insert(tiers, {
			speed = tonumber(car:GetAttribute("ImpactSpeed" .. i)) or DEFAULT_ATTRIBUTES["ImpactSpeed" .. i],
			damage = math.max(
				0,
				tonumber(car:GetAttribute("ImpactDamage" .. i)) or DEFAULT_ATTRIBUTES["ImpactDamage" .. i]
			),
		})
	end
	table.sort(tiers, function(a, b)
		return a.speed < b.speed
	end)
	if speed < tiers[1].speed then
		return 0
	end
	for i = 2, #tiers do
		local lower, upper = tiers[i - 1], tiers[i]
		if speed <= upper.speed then
			local span = upper.speed - lower.speed
			if span <= 0 then
				return upper.damage
			end
			local alpha = math.clamp((speed - lower.speed) / span, 0, 1)
			return lower.damage + (upper.damage - lower.damage) * alpha
		end
	end
	return tiers[#tiers].damage
end

local function processImpact(sourcePart: BasePart, otherPart: BasePart)
	if otherPart:IsDescendantOf(car) or not otherPart.CanCollide then
		return
	end

	-- Check for Pedestrian Hit
	local otherModel = otherPart:FindFirstAncestorOfClass("Model")
	local hum = otherModel and otherModel:FindFirstChildOfClass("Humanoid")
	if hum then
		handlePedestrianHit(hum, otherPart)
		return
	end

	if car:GetAttribute("SconWallClimbActive") == true or car:GetAttribute("SconFlightBoostActive") == true then
		return
	end

	local now = os.clock()
	if now - lastImpactTime < 0.65 then
		return
	end

	local relVel = lastVehicleVelocity - otherPart.AssemblyLinearVelocity
	local carLook = seat.CFrame.LookVector
	local sensorDir = sourcePart.Name == "Rear" and -carLook or carLook
	local horizDir = Vector3.new(sensorDir.X, 0, sensorDir.Z)
	if horizDir.Magnitude < 0.1 then
		return
	end
	local closingSpeed = relVel:Dot(horizDir.Unit)

	if closingSpeed < 12 then
		return
	end

	lastImpactTime = now
	if closingSpeed >= 55 then
		impactHeavySound.Volume = math.clamp(0.45 + (closingSpeed - 55) * 0.004, 0.45, 0.65)
		impactHeavySound.PlaybackSpeed = 0.96
		impactHeavySound.TimePosition = 0
		impactHeavySound:Play()
	else
		impactLightSound.Volume = math.clamp(0.24 + (closingSpeed - 12) * 0.007, 0.24, 0.54)
		impactLightSound.PlaybackSpeed = math.clamp(0.78 - (closingSpeed - 12) * 0.002, 0.68, 0.80)
		impactLightSound.TimePosition = 0
		impactLightSound:Play()
	end

	if car:GetAttribute("GodMode") == true then
		return
	end

	local damage = getImpactDamage(closingSpeed)
	if damage <= 0 then
		return
	end

	local currentHealth = tonumber(car:GetAttribute("Health")) or MAX_HEALTH
	car:SetAttribute("Health", math.max(0, currentHealth - damage))
end

if impactFolder then
	for _, sensor in ipairs(impactFolder:GetChildren()) do
		if sensor:IsA("BasePart") then
			sensor.CanCollide = false
			sensor.CanQuery = false
			sensor.CanTouch = true
			sensor.Touched:Connect(function(otherPart: BasePart)
				if otherPart:IsA("BasePart") then
					processImpact(sensor, otherPart)
				end
			end)
		end
	end
end

-- ============================================================================
-- 7. HEALTH, FUEL DRAIN & ENGINE BREAKDOWN LOOP
-- ============================================================================
local function updateBreakdownVFX(health: number)
	if health <= 0 then
		warningWhiteSmoke.Enabled = false
		heavyBlackSmoke.Enabled = true
		engineFire.Enabled = true
		car:SetAttribute("VehiclePowerDisabled", true)
	elseif health <= 25 then
		warningWhiteSmoke.Enabled = false
		heavyBlackSmoke.Enabled = true
		engineFire.Enabled = false
		car:SetAttribute("VehiclePowerDisabled", false)
	elseif health <= 50 then
		warningWhiteSmoke.Enabled = true
		heavyBlackSmoke.Enabled = false
		engineFire.Enabled = false
		car:SetAttribute("VehiclePowerDisabled", false)
	else
		warningWhiteSmoke.Enabled = false
		heavyBlackSmoke.Enabled = false
		engineFire.Enabled = false
		car:SetAttribute("VehiclePowerDisabled", false)
	end
end

car:GetAttributeChangedSignal("Health"):Connect(function()
	local h = tonumber(car:GetAttribute("Health")) or MAX_HEALTH
	updateBreakdownVFX(h)
end)

-- Gradual Fuel Drain Loop
task.spawn(function()
	while car.Parent do
		local dt = task.wait(0.25)
		if seat.Occupant and seat.AssemblyLinearVelocity.Magnitude > 4 then
			local fuel = tonumber(car:GetAttribute("Fuel")) or MAX_FUEL
			if fuel > 0 and car:GetAttribute("GodMode") ~= true then
				local speed = seat.AssemblyLinearVelocity.Magnitude
				local drainPerSec = 0.01 + speed * 0.0002
				car:SetAttribute("Fuel", math.max(0, fuel - drainPerSec * dt))
			end
		end
	end
end)

-- ============================================================================
-- 8. HUD LIFECYCLE (CarStatusGui)
-- ============================================================================
guiTemplate.Enabled = false
guiTemplate.ResetOnSpawn = false

local currentPlayer: Player? = nil
local currentDriverChar: Model? = nil
local function updateOccupant()
	local hum = seat.Occupant
	local newChar = (hum and hum.Parent and hum.Parent:IsA("Model")) and hum.Parent or nil
	local newPlayer = hum and Players:GetPlayerFromCharacter(hum.Parent) or nil

	if not hum then
		hornReleaseToken += 1
		hornSound:Stop()
		seat.Anchored = false
		drivePrompt.Enabled = true
		if currentDriverChar then
			recentOccupantExitAt[currentDriverChar] = os.clock()
			scheduleDetachOccupantNoCollision(currentDriverChar)
			currentDriverChar = nil
		end
		if currentPlayer then
			local pg = currentPlayer:FindFirstChildOfClass("PlayerGui")
			if pg then
				local existing = pg:FindFirstChild(car.Name .. "StatusGui")
				if existing then
					existing:Destroy()
				end
			end
			currentPlayer = nil
		end
		return
	end

	seat.Anchored = false
	drivePrompt.Enabled = false
	if newChar then
		if currentDriverChar and currentDriverChar ~= newChar then
			scheduleDetachOccupantNoCollision(currentDriverChar)
		end
		currentDriverChar = newChar
		attachOccupantNoCollision(newChar)
	end

	if currentPlayer == newPlayer then
		return
	end

	if currentPlayer then
		local pg = currentPlayer:FindFirstChildOfClass("PlayerGui")
		if pg then
			local existing = pg:FindFirstChild(car.Name .. "StatusGui")
			if existing then
				existing:Destroy()
			end
		end
	end

	currentPlayer = newPlayer

	if newPlayer then
		task.spawn(function()
			local pg = newPlayer:WaitForChild("PlayerGui", 10)
			if not pg or currentPlayer ~= newPlayer or not car.Parent then
				return
			end

			local screen = guiTemplate:Clone()
			screen.Name = car.Name .. "StatusGui"
			screen.Enabled = true
			screen.ResetOnSpawn = false

			local ref = Instance.new("ObjectValue")
			ref.Name = "VehicleRef"
			ref.Value = car
			ref.Parent = screen

			screen.Parent = pg
		end)
	end
end

seat:GetPropertyChangedSignal("Occupant"):Connect(updateOccupant)
Players.PlayerRemoving:Connect(function(player)
	if player == currentPlayer then
		currentPlayer = nil
	end
end)
updateOccupant()

-- Ensure seat remains unanchored for physics simulation
seat.Anchored = false
