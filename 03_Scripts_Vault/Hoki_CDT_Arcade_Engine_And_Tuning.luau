-- ============================================================================
-- HOKI TOWN - CDT-Style Clean Arcade Engine + Live Car Tuning & Customization
-- Empirically verified against TeslaRoadster ("Teera Roadster") in Place1
-- Replaces bloated 2,200-line A-Chassis Drive with a clean CDT Arcade Engine
-- ============================================================================

local car = workspace:FindFirstChild("TeslaRoadster")
assert(car, "TeslaRoadster not found in Workspace!")

local tuneModule = car:FindFirstChild("A-Chassis Tune")
local acInterface = tuneModule and tuneModule:FindFirstChild("A-Chassis Interface")
local driveScript = acInterface and acInterface:FindFirstChild("Drive")
assert(driveScript, "Drive LocalScript not found in A-Chassis Interface!")

-- 1. Set Default Tuning & Customization Attributes on TeslaRoadster
local defaultAttributes = {
	-- Performance Tuning
	PerfStage = 2,              -- 1: Stock (155 km/h), 2: Street (190 km/h), 3: Race (228 km/h), 4: Ludicrous (270 km/h)
	TireMode = "Arcade",        -- "Grip", "Arcade", "Drift"
	BrakeMultiplier = 1.25,     -- 1.0, 1.25, 1.5
	GodMode = false,
	-- Stance & Suspension Tuning
	RideHeightOffset = 0.0,     -- -0.55 (Slammed), -0.25 (Sport), 0.0 (Stock), +0.60 (Off-Road)
	CamberAngle = 0,            -- 0, -4, -8, -12 degrees
	WheelSpacer = 0.0,          -- 0.0, 0.25, 0.45, 0.70 studs outward
	SuspensionStiffScale = 1.0, -- 0.75 (Soft), 1.0 (Balanced), 1.5 (Track Stiff)
	-- Visual Customization
	BodyColor = Color3.fromRGB(210, 30, 45),
	BodyMaterialName = "SmoothPlastic", -- "Metal", "SmoothPlastic", "Neon", "Foil"
	RimColor = Color3.fromRGB(163, 162, 165),
	UnderglowColor = Color3.fromRGB(0, 220, 255),
	UnderglowEnabled = false,
	SmokeColor = Color3.fromRGB(245, 245, 245),
}

for k, v in pairs(defaultAttributes) do
	if car:GetAttribute(k) == nil then
		car:SetAttribute(k, v)
	end
end

-- 2. Install Server-Side Tuning & Visual Customization Controller (HokiCDT_Server)
local oldTuningServer = car:FindFirstChild("HokiCDT_Server")
if oldTuningServer then
	oldTuningServer:Destroy()
end

local cdtServer = Instance.new("Script")
cdtServer.Name = "HokiCDT_Server"
cdtServer.Source = [=====[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local car = script.Parent
local driveSeat = car:WaitForChild("DriveSeat", 10)
local bodyModel = car:WaitForChild("Body", 10)
local wheelsModel = car:WaitForChild("Wheels", 10)
if not driveSeat or not bodyModel or not wheelsModel then return end

-- RemoteEvent for Live Tuning & Customization
local tuningRemote = ReplicatedStorage:FindFirstChild("HokiVehicleTuningRemote")
if not tuningRemote then
	tuningRemote = Instance.new("RemoteEvent")
	tuningRemote.Name = "HokiVehicleTuningRemote"
	tuningRemote.Parent = ReplicatedStorage
end

-- Wait for A-Chassis Initialize to finish creating #AV, #BV, AxleP, and #Weight
local flWheel = wheelsModel:WaitForChild("FL", 10)
if flWheel then
	flWheel:WaitForChild("#AV", 10)
	flWheel:WaitForChild("AxleP", 10)
end
task.wait(0.2)

-- Cache Base Values for Suspension Springs & Axle Attachments
local baseSpringFree = {}
local baseSpringMax = {}
local baseSpringMin = {}
local baseSpringStiff = {}
local baseAxleAttPos = {}
local baseAxleAttOri = {}

for _, wName in ipairs({"FL", "FR", "RL", "RR"}) do
	local wheel = wheelsModel:FindFirstChild(wName)
	if wheel then
		local susGeo = wheel:FindFirstChild("SuspensionGeometry")
		local spring = (susGeo and susGeo:FindFirstChild("Spring")) or wheel:FindFirstChild("Spring") or wheel:FindFirstChildWhichIsA("SpringConstraint", true)
		if spring then
			baseSpringFree[wName] = spring.FreeLength
			baseSpringMax[wName] = spring.MaxLength
			baseSpringMin[wName] = spring.MinLength
			baseSpringStiff[wName] = spring.Stiffness
		end

		local axleP = wheel:FindFirstChild("AxleP")
		if axleP then
			for _, attName in ipairs({"AA", "BA"}) do
				local att = axleP:FindFirstChild(attName)
				if att and att:IsA("Attachment") then
					local key = wName .. "_" .. attName
					baseAxleAttPos[key] = att.Position
					baseAxleAttOri[key] = att.Orientation
				end
			end
		end

		-- Ensure TireSmoke exists on every wheel
		local tireSmoke = wheel:FindFirstChild("TireSmoke", true)
		if not tireSmoke then
			local att = wheel:FindFirstChild("SmokeAttachment") or Instance.new("Attachment")
			att.Name = "SmokeAttachment"
			att.Position = Vector3.new(0, -1.1, 0)
			att.Parent = wheel

			tireSmoke = Instance.new("ParticleEmitter")
			tireSmoke.Name = "TireSmoke"
			tireSmoke.Texture = "rbxassetid://243660364"
			tireSmoke.Color = ColorSequence.new(Color3.fromRGB(245, 245, 245))
			tireSmoke.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1.3),
				NumberSequenceKeypoint.new(0.4, 3.0),
				NumberSequenceKeypoint.new(1, 5.5),
			})
			tireSmoke.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.30),
				NumberSequenceKeypoint.new(0.6, 0.62),
				NumberSequenceKeypoint.new(1, 1),
			})
			tireSmoke.Lifetime = NumberRange.new(0.55, 1.10)
			tireSmoke.Rate = 65
			tireSmoke.Speed = NumberRange.new(3, 9)
			tireSmoke.SpreadAngle = Vector2.new(38, 38)
			tireSmoke.Enabled = false
			tireSmoke.Parent = att
		end

		-- Create Ground Skidmark Trail on non-spinning Arm/AxleP
		local fixedHost = wheel:FindFirstChild("AxleP") or wheel:FindFirstChild("Arm") or wheel:FindFirstChild("Base")
		if fixedHost and not fixedHost:FindFirstChild("SkidTrail") then
			local a0 = Instance.new("Attachment")
			a0.Name = "SkidAtt0"
			a0.Position = Vector3.new(0, -1.32, -0.42)
			a0.Parent = fixedHost

			local a1 = Instance.new("Attachment")
			a1.Name = "SkidAtt1"
			a1.Position = Vector3.new(0, -1.32, 0.42)
			a1.Parent = fixedHost

			local trail = Instance.new("Trail")
			trail.Name = "SkidTrail"
			trail.Attachment0 = a0
			trail.Attachment1 = a1
			trail.Color = ColorSequence.new(Color3.fromRGB(18, 18, 22))
			trail.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.22),
				NumberSequenceKeypoint.new(0.8, 0.65),
				NumberSequenceKeypoint.new(1, 1),
			})
			trail.Lifetime = 4.0
			trail.MinLength = 0.15
			trail.FaceCamera = false
			trail.Enabled = false
			trail.Parent = fixedHost
		end
	end
end

-- Create Underglow Neon Light under the chassis
local underglowPart = bodyModel:FindFirstChild("#Weight") or driveSeat
local underglowLight = underglowPart:FindFirstChild("HokiUnderglow")
if not underglowLight then
	underglowLight = Instance.new("SurfaceLight")
	underglowLight.Name = "HokiUnderglow"
	underglowLight.Face = Enum.NormalId.Bottom
	underglowLight.Range = 15
	underglowLight.Brightness = 5.0
	underglowLight.Angle = 130
	underglowLight.Shadows = false
	underglowLight.Color = car:GetAttribute("UnderglowColor") or Color3.fromRGB(0, 220, 255)
	underglowLight.Enabled = car:GetAttribute("UnderglowEnabled") == true
	underglowLight.Parent = underglowPart
end

-- Locate Built-In Rear Taillight Mesh ("Teera Roadster.Lights.Plane.007")
local teeraMeshModel = bodyModel:FindFirstChild("Teera Roadster")
local lightsFolder = teeraMeshModel and teeraMeshModel:FindFirstChild("Lights")
local rearLightMesh = lightsFolder and lightsFolder:FindFirstChild("Plane.007")
local brakePointLight = rearLightMesh and rearLightMesh:FindFirstChild("HokiBrakeGlow")
if rearLightMesh and not brakePointLight then
	brakePointLight = Instance.new("PointLight")
	brakePointLight.Name = "HokiBrakeGlow"
	brakePointLight.Color = Color3.fromRGB(255, 25, 25)
	brakePointLight.Range = 10
	brakePointLight.Brightness = 3.2
	brakePointLight.Enabled = false
	brakePointLight.Parent = rearLightMesh
end

-- Exact Classification of Body Paint Parts vs Rim Parts for Teera Roadster
local paintParts = {}
local rimParts = {}

if teeraMeshModel then
	local mainPaint = teeraMeshModel:FindFirstChild("Paint")
	if mainPaint and mainPaint:IsA("BasePart") then
		table.insert(paintParts, mainPaint)
	end
	local wingFolder = teeraMeshModel:FindFirstChild("Wing")
	if wingFolder then
		local wingPaint = wingFolder:FindFirstChild("Plane.008")
		if wingPaint and wingPaint:IsA("BasePart") then
			table.insert(paintParts, wingPaint)
		end
	end
end

for _, wName in ipairs({"FL", "FR", "RL", "RR"}) do
	local wheel = wheelsModel:FindFirstChild(wName)
	local partsFolder = wheel and wheel:FindFirstChild("Parts")
	if partsFolder then
		for _, p in ipairs(partsFolder:GetDescendants()) do
			if p:IsA("BasePart") and (p.Name == "Plane.008" or p.Name == "Plane.003" or p.Material == Enum.Material.Metal) then
				table.insert(rimParts, p)
			end
		end
	end
end

local materialMap = {
	Metal = Enum.Material.Metal,
	SmoothPlastic = Enum.Material.SmoothPlastic,
	Neon = Enum.Material.Neon,
	Foil = Enum.Material.Foil,
}

local function applyAllTuningAndVisuals()
	-- 1. Suspension Ride Height, Stiffness, Camber & Spacer
	local rideOffset = tonumber(car:GetAttribute("RideHeightOffset")) or 0
	local stiffScale = tonumber(car:GetAttribute("SuspensionStiffScale")) or 1
	local camberDeg = tonumber(car:GetAttribute("CamberAngle")) or 0
	local spacer = tonumber(car:GetAttribute("WheelSpacer")) or 0

	for _, wName in ipairs({"FL", "FR", "RL", "RR"}) do
		local wheel = wheelsModel:FindFirstChild(wName)
		if wheel then
			local susGeo = wheel:FindFirstChild("SuspensionGeometry")
			local spring = (susGeo and susGeo:FindFirstChild("Spring")) or wheel:FindFirstChild("Spring") or wheel:FindFirstChildWhichIsA("SpringConstraint", true)
			if spring and baseSpringFree[wName] then
				spring.FreeLength = math.clamp(baseSpringFree[wName] + rideOffset, 0.45, 4.5)
				spring.MaxLength = math.clamp(baseSpringMax[wName] + rideOffset, 0.65, 5.0)
				spring.MinLength = math.clamp(baseSpringMin[wName] + math.min(0, rideOffset), 0.20, 4.0)
				spring.Stiffness = baseSpringStiff[wName] * stiffScale
			end

			-- Apply Camber & Wide Track Spacer relative to cached original AxleP Hinge Attachments (AA & BA)
			-- Preserves original A-Chassis left/right hinge spin axis so FL/RL never spin backwards
			local axleP = wheel:FindFirstChild("AxleP")
			if axleP then
				local isLeft = (wName == "FL" or wName == "RL")
				local tiltZ = isLeft and -camberDeg or camberDeg
				for _, attName in ipairs({"AA", "BA"}) do
					local att = axleP:FindFirstChild(attName)
					if att and att:IsA("Attachment") then
						local key = wName .. "_" .. attName
						local origPos = baseAxleAttPos[key] or Vector3.zero
						local origOri = baseAxleAttOri[key] or Vector3.zero
						att.Position = origPos + Vector3.new(-spacer, 0, 0)
						att.Orientation = origOri + Vector3.new(0, 0, tiltZ)
					end
				end
			end
		end
	end

	-- 2. Body Paint & Material
	local bodyCol = car:GetAttribute("BodyColor")
	local matName = car:GetAttribute("BodyMaterialName") or "SmoothPlastic"
	local targetMat = materialMap[matName] or Enum.Material.SmoothPlastic
	if typeof(bodyCol) == "Color3" then
		for _, p in ipairs(paintParts) do
			if p and p.Parent then
				p.Color = bodyCol
				p.Material = targetMat
			end
		end
	end

	-- 3. Rim Color
	local rimCol = car:GetAttribute("RimColor")
	if typeof(rimCol) == "Color3" then
		for _, p in ipairs(rimParts) do
			if p and p.Parent then
				p.Color = rimCol
			end
		end
	end

	-- 4. Underglow Neon
	if underglowLight then
		local ugCol = car:GetAttribute("UnderglowColor")
		if typeof(ugCol) == "Color3" then
			underglowLight.Color = ugCol
		end
		underglowLight.Enabled = (car:GetAttribute("UnderglowEnabled") == true)
	end

	-- 5. Tire Smoke Color
	local smokeCol = car:GetAttribute("SmokeColor")
	if typeof(smokeCol) == "Color3" then
		for _, wName in ipairs({"FL", "FR", "RL", "RR"}) do
			local wheel = wheelsModel:FindFirstChild(wName)
			local ts = wheel and wheel:FindFirstChild("TireSmoke", true)
			if ts and ts:IsA("ParticleEmitter") then
				ts.Color = ColorSequence.new(smokeCol)
			end
		end
	end
end

applyAllTuningAndVisuals()

for k, _ in pairs({
	RideHeightOffset = true,
	SuspensionStiffScale = true,
	CamberAngle = true,
	WheelSpacer = true,
	BodyColor = true,
	BodyMaterialName = true,
	RimColor = true,
	UnderglowColor = true,
	UnderglowEnabled = true,
	SmokeColor = true,
}) do
	car:GetAttributeChangedSignal(k):Connect(applyAllTuningAndVisuals)
end

-- Listen for Client Tuning / Brake Light / Drift VFX updates
tuningRemote.OnServerEvent:Connect(function(player, targetCar, action, payload)
	if targetCar ~= car then return end
	if driveSeat.Occupant and driveSeat.Occupant.Parent ~= player.Character then
		return
	end

	if action == "SetAttribute" and type(payload) == "table" then
		for attrName, attrVal in pairs(payload) do
			car:SetAttribute(attrName, attrVal)
		end
	elseif action == "VFXState" and type(payload) == "table" then
		local smoking = payload.Smoking == true
		local skidding = payload.Skidding == true
		local braking = payload.Braking == true

		for _, wName in ipairs({"RL", "RR", "FL", "FR"}) do
			local wheel = wheelsModel:FindFirstChild(wName)
			if wheel then
				local isRear = (wName == "RL" or wName == "RR")
				local ts = wheel:FindFirstChild("TireSmoke", true)
				if ts and ts:IsA("ParticleEmitter") then
					ts.Enabled = smoking and (isRear or payload.AllWheels)
				end
				local st = wheel:FindFirstChild("SkidTrail", true)
				if st and st:IsA("Trail") then
					st.Enabled = skidding and (isRear or payload.AllWheels)
				end
			end
		end

		if rearLightMesh then
			rearLightMesh.Color = braking and Color3.fromRGB(255, 30, 30) or Color3.fromRGB(165, 55, 55)
			if brakePointLight then
				brakePointLight.Enabled = braking
			end
		end
	end
end)
]=====]
cdtServer.Parent = car

-- 3. Replace the 2,200-Line A-Chassis Drive Script with the Clean CDT Arcade Engine + Garage UI
driveScript.Source = [=====[
-- ============================================================================
-- HOKI CDT-STYLE CLEAN ARCADE ENGINE & IN-GAME GARAGE TUNING
-- Replaces 2,200-line A-Chassis Drive with crisp Car Dealership Tycoon physics
-- ============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gui = script.Parent
local car = gui:WaitForChild("Car").Value
local driveSeat = car:WaitForChild("DriveSeat")
local wheels = car:WaitForChild("Wheels")
local body = car:WaitForChild("Body")
local soundsFolder = body:FindFirstChild("Sounds")
local tuningRemote = ReplicatedStorage:WaitForChild("HokiVehicleTuningRemote", 5)

-- Disable legacy A-Chassis sub-plugins (AC6_Stock_Sound, Aerodynamics, etc.)
for _, child in ipairs(gui:GetChildren()) do
	if child:IsA("GuiObject") and child.Name ~= "CDT_GaragePanel" and child.Name ~= "CDT_TopBar" then
		child.Visible = false
	end
	if child:IsA("LocalScript") and child ~= script then
		child.Disabled = true
	end
end

-- ============================================================================
-- 1. PERFORMANCE & TIRE PRESET TABLES
-- ============================================================================
local STAGE_PRESETS = {
	[1] = { Name = "Stage 1 (เดิมโรงงาน)", TopSpeedKmh = 155, AccelTorque = 9500,  AccelForce = 18500, GearCount = 6 },
	[2] = { Name = "Stage 2 (สตรีทจูน)",   TopSpeedKmh = 190, AccelTorque = 13500, AccelForce = 26500, GearCount = 6 },
	[3] = { Name = "Stage 3 (สนามแข่ง)",  TopSpeedKmh = 228, AccelTorque = 18000, AccelForce = 35500, GearCount = 6 },
	[4] = { Name = "Stage 4 (Ludicrous)", TopSpeedKmh = 270, AccelTorque = 24000, AccelForce = 48000, GearCount = 6 },
}

local TIRE_PRESETS = {
	Grip   = { Name = "เกาะถนนหนึบ (Grip)",  SteerMax = 35, HighSpeedSteer = 16, LateralGrip = 0.94, DriftYawRate = 1.40 },
	Arcade = { Name = "สมดุลสนุก (Arcade)", SteerMax = 39, HighSpeedSteer = 19, LateralGrip = 0.80, DriftYawRate = 2.10 },
	Drift  = { Name = "สายดริฟต์ (Drift)",  SteerMax = 45, HighSpeedSteer = 26, LateralGrip = 0.48, DriftYawRate = 2.75 },
}

-- ============================================================================
-- 2. CLEAN 6-SPEED AUDIO SYNTHESIZER (Uses Clean ENG_Idle + Guaranteed Cornering/Drift Tires)
-- ============================================================================
local engSound = soundsFolder and soundsFolder:FindFirstChild("ENG_Idle", true)
local tireSound = soundsFolder and soundsFolder:FindFirstChild("Tires", true)
if soundsFolder then
	for _, s in ipairs(soundsFolder:GetDescendants()) do
		if s:IsA("Sound") and s ~= engSound and s ~= tireSound then
			s:Stop()
			s.Volume = 0
		end
	end
end
if engSound then
	engSound.Looped = true
	engSound.Volume = 0.35
	if not engSound.IsPlaying then engSound:Play() end
end

-- Ensure a working Warm Tire Scrub Sound always exists on DriveSeat even if body.Sounds.Tires is missing
if not tireSound or not tireSound:IsA("Sound") or tireSound.SoundId == "" then
	tireSound = driveSeat:FindFirstChild("HokiTireScrub")
	if not tireSound then
		tireSound = Instance.new("Sound")
		tireSound.Name = "HokiTireScrub"
		tireSound.SoundId = "rbxassetid://112851268328371"
		tireSound.RollOffMaxDistance = 140
		tireSound.RollOffMinDistance = 10
		tireSound.RollOffMode = Enum.RollOffMode.InverseTapered
		tireSound.Parent = driveSeat
	end
end
tireSound.Looped = true
tireSound.Volume = 0
if not tireSound.IsPlaying then tireSound:Play() end

-- ============================================================================
-- 3. WHEEL MOTORS (#AV / #BV HingeConstraints) & STEERING GYRO CACHE
-- ============================================================================
local wheelList = {}
for _, wName in ipairs({"FL", "FR", "RL", "RR"}) do
	local w = wheels:WaitForChild(wName, 5)
	if w then
		local arm = w:WaitForChild("Arm", 5)
		local base = w:WaitForChild("Base", 5)
		local av = w:WaitForChild("#AV", 5)
		local bv = w:WaitForChild("#BV", 5)
		local steerGyro = arm and arm:FindFirstChild("Steer")
		local steerAttach0 = (steerGyro and steerGyro:IsA("AlignOrientation")) and steerGyro.Attachment0 or nil
		table.insert(wheelList, {
			Name = wName,
			Part = w,
			Base = base,
			Arm = arm,
			IsFront = (wName == "FL" or wName == "FR"),
			IsRear = (wName == "RL" or wName == "RR"),
			AV = av,
			BV = bv,
			SteerGyro = steerGyro,
			SteerAttach0 = steerAttach0,
			Smoke = w:FindFirstChild("TireSmoke", true),
			Trail = w:FindFirstChild("SkidTrail", true),
		})
	end
end

-- Master CDT Arcade Linear & Angular Assist on DriveSeat
local cdtAtt = driveSeat:FindFirstChild("CDT_CenterAttachment") or Instance.new("Attachment")
cdtAtt.Name = "CDT_CenterAttachment"
cdtAtt.Parent = driveSeat

local cdtVectorForce = driveSeat:FindFirstChild("CDT_ArcadeForce") or Instance.new("VectorForce")
cdtVectorForce.Name = "CDT_ArcadeForce"
cdtVectorForce.Attachment0 = cdtAtt
cdtVectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
cdtVectorForce.Force = Vector3.zero
cdtVectorForce.Parent = driveSeat

local cdtYawTorque = driveSeat:FindFirstChild("CDT_YawAssist") or Instance.new("Torque")
cdtYawTorque.Name = "CDT_YawAssist"
cdtYawTorque.Attachment0 = cdtAtt
cdtYawTorque.RelativeTo = Enum.ActuatorRelativeTo.World
cdtYawTorque.Torque = Vector3.zero
cdtYawTorque.Parent = driveSeat

-- ============================================================================
-- 4. CLEAN [E] / [F] EXIT VEHICLE HANDLER
-- ============================================================================
local exitCooldown = os.clock() + 0.65
local function doCleanExit()
	if os.clock() < exitCooldown then return end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	cdtVectorForce.Force = Vector3.zero
	cdtYawTorque.Torque = Vector3.zero
	hum.Sit = false
	hum.Jump = true
	task.delay(0.05, function()
		if char and char.PrimaryPart and driveSeat then
			char:PivotTo(driveSeat.CFrame * CFrame.new(5.6, 2.2, 0))
		end
	end)
end

ContextActionService:BindActionAtPriority("CDT_ExitCar", function(_, state)
	if state == Enum.UserInputState.Begin then
		doCleanExit()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value + 1200, Enum.KeyCode.E, Enum.KeyCode.F)

-- ============================================================================
-- 5. IN-GAME [G] GARAGE TUNING & CUSTOMIZATION UI
-- ============================================================================
local topBar = Instance.new("Frame")
topBar.Name = "CDT_TopBar"
topBar.Size = UDim2.new(0, 480, 0, 42)
topBar.Position = UDim2.new(0.5, -240, 0, 10)
topBar.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
topBar.BackgroundTransparency = 0.12
topBar.Parent = gui

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 10)
tbCorner.Parent = topBar

local tbStroke = Instance.new("UIStroke")
tbStroke.Color = Color3.fromRGB(0, 210, 255)
tbStroke.Thickness = 1.5
tbStroke.Parent = topBar

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(0.66, -12, 1, 0)
statusText.Position = UDim2.new(0, 12, 0, 0)
statusText.BackgroundTransparency = 1
statusText.Font = Enum.Font.GothamBold
statusText.TextSize = 13
statusText.TextColor3 = Color3.fromRGB(240, 245, 255)
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Text = "🏎️ CDT Engine | Stage 2 | โหมด: Arcade"
statusText.Parent = topBar

local garageToggleBtn = Instance.new("TextButton")
garageToggleBtn.Size = UDim2.new(0.32, 0, 0, 30)
garageToggleBtn.Position = UDim2.new(0.67, 0, 0.5, -15)
garageToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 175, 230)
garageToggleBtn.Font = Enum.Font.GothamBold
garageToggleBtn.TextSize = 13
garageToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
garageToggleBtn.Text = "🔧 [G] แต่งรถ / จูนรถ"
garageToggleBtn.Parent = topBar

local gtCorner = Instance.new("UICorner")
gtCorner.CornerRadius = UDim.new(0, 8)
gtCorner.Parent = garageToggleBtn

local garagePanel = Instance.new("Frame")
garagePanel.Name = "CDT_GaragePanel"
garagePanel.Size = UDim2.new(0, 530, 0, 400)
garagePanel.Position = UDim2.new(0.5, -265, 0, 58)
garagePanel.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
garagePanel.BackgroundTransparency = 0.05
garagePanel.Visible = false
garagePanel.Parent = gui

local gpCorner = Instance.new("UICorner")
gpCorner.CornerRadius = UDim.new(0, 12)
gpCorner.Parent = garagePanel

local gpStroke = Instance.new("UIStroke")
gpStroke.Color = Color3.fromRGB(0, 200, 255)
gpStroke.Thickness = 2
gpStroke.Parent = garagePanel

local gpTitle = Instance.new("TextLabel")
gpTitle.Size = UDim2.new(1, -24, 0, 34)
gpTitle.Position = UDim2.new(0, 14, 0, 6)
gpTitle.BackgroundTransparency = 1
gpTitle.Font = Enum.Font.GothamBlack
gpTitle.TextSize = 15
gpTitle.TextColor3 = Color3.fromRGB(0, 220, 255)
gpTitle.TextXAlignment = Enum.TextXAlignment.Left
gpTitle.Text = "⚡ HOKI GARAGE — ระบบจูนรถ & แต่งรถสด (กด [G] เปิด/ปิด)"
gpTitle.Parent = garagePanel

local contentScroll = Instance.new("ScrollingFrame")
contentScroll.Size = UDim2.new(1, -24, 1, -50)
contentScroll.Position = UDim2.new(0, 12, 0, 42)
contentScroll.BackgroundTransparency = 1
contentScroll.ScrollBarThickness = 6
contentScroll.CanvasSize = UDim2.new(0, 0, 0, 560)
contentScroll.Parent = garagePanel

local uiList = Instance.new("UIListLayout")
uiList.Padding = UDim.new(0, 8)
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Parent = contentScroll

local function setCarAttr(attrTable)
	for k, v in pairs(attrTable) do
		car:SetAttribute(k, v)
	end
	if tuningRemote then
		tuningRemote:FireServer(car, "SetAttribute", attrTable)
	end
end

local rowOrder = 0
local function addSectionRow(titleText, options)
	rowOrder += 1
	local row = Instance.new("Frame")
	row.LayoutOrder = rowOrder
	row.Size = UDim2.new(1, -10, 0, 58)
	row.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
	row.Parent = contentScroll

	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 8)
	rc.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -16, 0, 22)
	lbl.Position = UDim2.new(0, 10, 0, 3)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 13
	lbl.TextColor3 = Color3.fromRGB(220, 230, 245)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = titleText
	lbl.Parent = row

	local btnHolder = Instance.new("Frame")
	btnHolder.Size = UDim2.new(1, -16, 0, 28)
	btnHolder.Position = UDim2.new(0, 8, 0, 26)
	btnHolder.BackgroundTransparency = 1
	btnHolder.Parent = row

	local hLayout = Instance.new("UIListLayout")
	hLayout.FillDirection = Enum.FillDirection.Horizontal
	hLayout.Padding = UDim.new(0, 6)
	hLayout.Parent = btnHolder

	local btnWidth = math.floor((480 - (#options - 1) * 6) / #options)
	for _, opt in ipairs(options) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, btnWidth, 1, 0)
		b.BackgroundColor3 = opt.Color or Color3.fromRGB(42, 50, 68)
		b.Font = Enum.Font.GothamBold
		b.TextSize = 12
		b.TextColor3 = opt.TextColor or Color3.fromRGB(255, 255, 255)
		b.Text = opt.Label
		b.Parent = btnHolder

		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0, 6)
		bc.Parent = b

		b.MouseButton1Click:Connect(function()
			opt.Callback()
		end)
	end
end

-- Build All 8 Real-Time Tuning & Customization Rows
addSectionRow("1. ⚡ จูนเครื่องยนต์ (Engine Stage — ความเร็วสูงสุด & แรงม้า)", {
	{ Label = "Stage 1 (155)", Callback = function() setCarAttr({ PerfStage = 1 }) end },
	{ Label = "Stage 2 (190)", Callback = function() setCarAttr({ PerfStage = 2 }) end },
	{ Label = "Stage 3 (228)", Callback = function() setCarAttr({ PerfStage = 3 }) end },
	{ Label = "🔥 Stage 4 (270)", Color = Color3.fromRGB(200, 45, 65), Callback = function() setCarAttr({ PerfStage = 4 }) end },
})

addSectionRow("2. 🛞 โหมดยางและการเข้าโค้ง (Tire & Drift Spec)", {
	{ Label = "เกาะถนนหนึบ (Grip)", Callback = function() setCarAttr({ TireMode = "Grip" }) end },
	{ Label = "สมดุล (Arcade)", Color = Color3.fromRGB(0, 140, 195), Callback = function() setCarAttr({ TireMode = "Arcade" }) end },
	{ Label = "💨 สายดริฟต์ (Drift)", Color = Color3.fromRGB(165, 60, 210), Callback = function() setCarAttr({ TireMode = "Drift" }) end },
})

addSectionRow("3. 📐 ความสูงช่วงล่าง (Ride Height / Stance)", {
	{ Label = "โหลดเตี้ยสุด (-0.55)", Callback = function() setCarAttr({ RideHeightOffset = -0.55 }) end },
	{ Label = "สปอร์ต (-0.25)", Callback = function() setCarAttr({ RideHeightOffset = -0.25 }) end },
	{ Label = "มาตรฐาน (0.0)", Callback = function() setCarAttr({ RideHeightOffset = 0.0 }) end },
	{ Label = "ยกสูงลุย (+0.60)", Callback = function() setCarAttr({ RideHeightOffset = 0.60 }) end },
})

addSectionRow("4. 📐 มุมล้อแบะ & ฐานล้อยื่น (Camber & Wide Track Spacer)", {
	{ Label = "ล้อตรง (0°)", Callback = function() setCarAttr({ CamberAngle = 0, WheelSpacer = 0 }) end },
	{ Label = "Camber -4°", Callback = function() setCarAttr({ CamberAngle = -4, WheelSpacer = 0.25 }) end },
	{ Label = "Stance -8°", Callback = function() setCarAttr({ CamberAngle = -8, WheelSpacer = 0.45 }) end },
	{ Label = "VIP Demon -12°", Color = Color3.fromRGB(180, 50, 120), Callback = function() setCarAttr({ CamberAngle = -12, WheelSpacer = 0.70 }) end },
})

addSectionRow("5. 🎨 สีตัวถังรถ (Body Paint Color)", {
	{ Label = "แดง Roadster", Color = Color3.fromRGB(210, 30, 45), Callback = function() setCarAttr({ BodyColor = Color3.fromRGB(210, 30, 45) }) end },
	{ Label = "ดำ Stealth", Color = Color3.fromRGB(25, 27, 32), Callback = function() setCarAttr({ BodyColor = Color3.fromRGB(25, 27, 32) }) end },
	{ Label = "ขาวมุก Pearl", Color = Color3.fromRGB(235, 240, 248), TextColor = Color3.fromRGB(20, 20, 25), Callback = function() setCarAttr({ BodyColor = Color3.fromRGB(240, 244, 250) }) end },
	{ Label = "ฟ้านีออน Cyber", Color = Color3.fromRGB(0, 185, 255), Callback = function() setCarAttr({ BodyColor = Color3.fromRGB(0, 185, 255) }) end },
	{ Label = "ทองคำ Gold", Color = Color3.fromRGB(215, 165, 35), Callback = function() setCarAttr({ BodyColor = Color3.fromRGB(215, 165, 35) }) end },
})

addSectionRow("6. ✨ ผิววัสดุตัวถัง & สีล้อแม็ก (Material & Rims)", {
	{ Label = "สีเมทัลลิก", Callback = function() setCarAttr({ BodyMaterialName = "Metal" }) end },
	{ Label = "สีเงาคลีน", Callback = function() setCarAttr({ BodyMaterialName = "SmoothPlastic" }) end },
	{ Label = "แม็กดำดุ", Color = Color3.fromRGB(28, 30, 35), Callback = function() setCarAttr({ RimColor = Color3.fromRGB(28, 30, 35) }) end },
	{ Label = "แม็กทอง Bronze", Color = Color3.fromRGB(185, 140, 55), Callback = function() setCarAttr({ RimColor = Color3.fromRGB(185, 140, 55) }) end },
	{ Label = "แม็กเงิน Silver", Color = Color3.fromRGB(210, 218, 228), TextColor = Color3.fromRGB(20, 20, 25), Callback = function() setCarAttr({ RimColor = Color3.fromRGB(210, 218, 228) }) end },
})

addSectionRow("7. 💡 ไฟนีออนใต้ท้องรถ (Underglow Neon RGB)", {
	{ Label = "ปิดไฟ", Callback = function() setCarAttr({ UnderglowEnabled = false }) end },
	{ Label = "ฟ้า Cyan", Color = Color3.fromRGB(0, 200, 255), Callback = function() setCarAttr({ UnderglowEnabled = true, UnderglowColor = Color3.fromRGB(0, 220, 255) }) end },
	{ Label = "ม่วง Neon", Color = Color3.fromRGB(170, 40, 255), Callback = function() setCarAttr({ UnderglowEnabled = true, UnderglowColor = Color3.fromRGB(170, 40, 255) }) end },
	{ Label = "แดง Crimson", Color = Color3.fromRGB(255, 35, 55), Callback = function() setCarAttr({ UnderglowEnabled = true, UnderglowColor = Color3.fromRGB(255, 35, 55) }) end },
	{ Label = "เขียว Matrix", Color = Color3.fromRGB(30, 235, 100), Callback = function() setCarAttr({ UnderglowEnabled = true, UnderglowColor = Color3.fromRGB(30, 235, 100) }) end },
})

addSectionRow("8. 💨 สีควันยางดริฟต์ (Drift Tire Smoke Color)", {
	{ Label = "ควันขาว", Color = Color3.fromRGB(230, 230, 235), TextColor = Color3.fromRGB(20, 20, 25), Callback = function() setCarAttr({ SmokeColor = Color3.fromRGB(245, 245, 245) }) end },
	{ Label = "ควันฟ้า", Color = Color3.fromRGB(0, 195, 255), Callback = function() setCarAttr({ SmokeColor = Color3.fromRGB(0, 195, 255) }) end },
	{ Label = "ควันม่วง", Color = Color3.fromRGB(185, 55, 255), Callback = function() setCarAttr({ SmokeColor = Color3.fromRGB(185, 55, 255) }) end },
	{ Label = "ควันแดง", Color = Color3.fromRGB(255, 50, 60), Callback = function() setCarAttr({ SmokeColor = Color3.fromRGB(255, 50, 60) }) end },
})

local function toggleGarage()
	garagePanel.Visible = not garagePanel.Visible
end
garageToggleBtn.MouseButton1Click:Connect(toggleGarage)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.G then
		toggleGarage()
	end
end)

-- ============================================================================
-- 6. MAIN 60HZ CDT ARCADE PHYSICS & DRIFT ENGINE LOOP
-- ============================================================================
local cam = workspace.CurrentCamera
local currentGear = 1
local currentRPM = 1000
local smoothedSteer = 0
local reverseHoldTimer = 0
local isReversing = false
local nitroFuel = 100
local lastVFXSync = 0
local lastSmokeState = false
local lastBrakeState = false
local wasOnRampAt = 0
local nextJumpBoostAt = 0

local renderConn = RunService.RenderStepped:Connect(function(dt)
	dt = math.min(dt, 0.05)

	-- Check if vehicle is broken or out of fuel
	local isBroken = car:GetAttribute("IsBroken") == true and car:GetAttribute("GodMode") ~= true
	local fuel = tonumber(car:GetAttribute("Fuel")) or 100
	local canDrive = (not isBroken) and (fuel > 0)

	-- Read Live Controls (Keyboard + Seat fallback)
	local wDown = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up)
	local sDown = UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down)
	local aDown = UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left)
	local dDown = UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right)
	local spaceDown = UserInputService:IsKeyDown(Enum.KeyCode.Space)
	local shiftDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)

	local rawSteer = (aDown and -1 or 0) + (dDown and 1 or 0)
	if rawSteer == 0 and math.abs(driveSeat.SteerFloat) > 0.05 then
		rawSteer = driveSeat.SteerFloat
	end

	-- Read Live Tuning Config
	local stageIdx = math.clamp(tonumber(car:GetAttribute("PerfStage")) or 2, 1, 4)
	local stage = STAGE_PRESETS[stageIdx]
	local tireModeName = car:GetAttribute("TireMode") or "Arcade"
	local tire = TIRE_PRESETS[tireModeName] or TIRE_PRESETS.Arcade
	local brakeMult = tonumber(car:GetAttribute("BrakeMultiplier")) or 1.25

	-- Measure Vehicle Velocity & Forward Speed
	local vel = driveSeat.AssemblyLinearVelocity
	local cf = driveSeat.CFrame
	local forwardDir = cf.LookVector
	local rightDir = cf.RightVector

	local forwardSpeed = vel:Dot(forwardDir)
	local lateralSpeed = vel:Dot(rightDir)
	local speedStuds = vel.Magnitude
	local speedKmh = speedStuds * 1.09728

	-- Nitro Boost ([LeftShift])
	local isNitroActive = false
	if shiftDown and wDown and canDrive and forwardSpeed > 5 and nitroFuel > 5 then
		isNitroActive = true
		nitroFuel = math.max(0, nitroFuel - dt * 28)
	else
		nitroFuel = math.min(100, nitroFuel + dt * 14)
	end
	local nitroBoostMult = isNitroActive and 1.35 or 1.0

	-- Update Top Status Bar
	statusText.Text = string.format(
		"🏎️ %s | ยาง: %s | ⚡ Nitro: %d%%",
		stage.Name,
		tireModeName,
		math.floor(nitroFuel)
	)

	-- Speed-Sensitive Arcade Steering
	local speedRatio = math.clamp(speedKmh / stage.TopSpeedKmh, 0, 1)
	local maxSteerDeg = tire.SteerMax - (tire.SteerMax - tire.HighSpeedSteer) * (speedRatio ^ 0.75)
	if spaceDown then
		maxSteerDeg = maxSteerDeg * 1.22 -- Extra steering angle while drifting
	end
	smoothedSteer = smoothedSteer + (rawSteer - smoothedSteer) * math.min(1, dt * 11)

	-- Apply Steering to Front Wheels (supports both New AlignOrientation Attachment0 and Legacy BodyGyro)
	for _, w in ipairs(wheelList) do
		if w.IsFront and w.SteerGyro and w.Base then
			local steerDeg = smoothedSteer * maxSteerDeg
			if w.SteerAttach0 then
				w.SteerAttach0.Orientation = Vector3.new(0, -steerDeg, 0)
			elseif w.SteerGyro:IsA("BodyGyro") then
				w.SteerGyro.CFrame = w.Base.CFrame * CFrame.Angles(0, -math.rad(steerDeg), 0)
			end
		end
	end

	-- Ground Contact & Ramp Check (uses car-local -UpVector + upright check so upside-down cars NEVER detect ground!)
	local groundedWheelCount = 0
	local carUpVector = cf.UpVector
	local isCarUpright = carUpVector.Y > 0.35
	local wheelDownDir = -carUpVector
	local onSlopeOrRamp = isCarUpright and (forwardDir.Y > 0.075 and vel.Y > 1.8)
	local groundRayParams = RaycastParams.new()
	groundRayParams.FilterType = Enum.RaycastFilterType.Exclude
	groundRayParams.FilterDescendantsInstances = { car, player.Character }
	for _, w in ipairs(wheelList) do
		w.IsGrounded = false
		if isCarUpright and w.Part then
			local radius = math.max(w.Part.Size.Y, w.Part.Size.Z) * 0.5
			local hit = workspace:Raycast(w.Part.Position, wheelDownDir * (radius + 0.25), groundRayParams)
			if hit then
				w.IsGrounded = true
				groundedWheelCount += 1
				if hit.Normal.Y >= 0.25 and hit.Normal.Y < 0.985 then
					onSlopeOrRamp = true
				end
			end
		end
	end
	local isGrounded = isCarUpright and (groundedWheelCount >= 2)
	local nowClock = os.clock()
	if isGrounded and onSlopeOrRamp then
		wasOnRampAt = nowClock
	end

	-- Smart Forward / Brake / Reverse State Machine
	local REVERSE_MAX_SPEED_KMH = 45
	local throttleCmd = 0
	local brakeCmd = 0

	if not canDrive then
		throttleCmd = 0
		brakeCmd = 1
		isReversing = false
	elseif spaceDown then
		-- True Handbrake: overrides rear drive and triggers drift slide even if holding W!
		throttleCmd = wDown and 0.35 or 0
		brakeCmd = 1
	elseif sDown then
		if forwardSpeed > 3.5 then
			-- Crisp Service Brake while moving forward
			isReversing = false
			throttleCmd = 0
			brakeCmd = 1
			reverseHoldTimer = 0
		else
			-- Brief 0.22s stop hold before smoothly engaging Reverse
			reverseHoldTimer += dt
			if reverseHoldTimer >= 0.22 then
				isReversing = true
				throttleCmd = -0.65
				brakeCmd = 0
			else
				throttleCmd = 0
				brakeCmd = 1
			end
		end
	elseif wDown then
		isReversing = false
		reverseHoldTimer = 0
		if forwardSpeed < -3.5 then
			-- Braking from reverse
			throttleCmd = 0
			brakeCmd = 1
		else
			throttleCmd = 1
			brakeCmd = 0
		end
	else
		reverseHoldTimer = 0
		if math.abs(forwardSpeed) < 2 then
			isReversing = false
		end
	end

	-- Apply Wheel HingeConstraint Motors (#AV.MotorMaxTorque & #BV.MotorMaxTorque)
	local activeTopSpeedKmh = (throttleCmd < 0) and REVERSE_MAX_SPEED_KMH or (stage.TopSpeedKmh * nitroBoostMult)
	local maxWheelSpin = activeTopSpeedKmh / 1.09728 / 1.35
	for _, w in ipairs(wheelList) do
		if w.AV and w.BV then
			if spaceDown and w.IsRear then
				-- Lock rear wheels on Spacebar Handbrake
				w.AV.MotorMaxTorque = 0
				w.AV.AngularVelocity = 0
				w.BV.MotorMaxTorque = 28000 * brakeMult
			elseif brakeCmd > 0 and not spaceDown then
				w.AV.MotorMaxTorque = 0
				w.AV.AngularVelocity = 0
				w.BV.MotorMaxTorque = (w.IsFront and 24000 or 20000) * brakeCmd * brakeMult
			elseif math.abs(throttleCmd) > 0.01 then
				w.BV.MotorMaxTorque = 0
				w.AV.MotorMaxTorque = stage.AccelTorque * nitroBoostMult
				w.AV.AngularVelocity = maxWheelSpin * math.sign(throttleCmd)
			else
				-- Natural engine coasting drag
				w.AV.MotorMaxTorque = 0
				w.BV.MotorMaxTorque = 450
			end
		end
	end

	-- Apply CDT Linear Arcade Acceleration, Braking & Lateral Drift Physics (Only when Grounded)
	local horizontalForward = Vector3.new(forwardDir.X, 0, forwardDir.Z)
	if horizontalForward.Magnitude > 0.01 then
		horizontalForward = horizontalForward.Unit
	else
		horizontalForward = forwardDir
	end
	local horizontalRight = Vector3.new(rightDir.X, 0, rightDir.Z)
	if horizontalRight.Magnitude > 0.01 then
		horizontalRight = horizontalRight.Unit
	else
		horizontalRight = rightDir
	end

	local totalForce = Vector3.zero
	local totalYawTorque = Vector3.zero
	local isDrifting = false
	local slipAngleDeg = 0
	if speedStuds > 10 then
		local horizVel = Vector3.new(vel.X, 0, vel.Z)
		if horizVel.Magnitude > 1 then
			local dotF = math.clamp(horizVel.Unit:Dot(horizontalForward), -1, 1)
			slipAngleDeg = math.deg(math.acos(math.abs(dotF)))
		end
	end

	-- Long-Distance Ramp Launch Boost on Takeoff Transition
	if not isGrounded and (nowClock - wasOnRampAt <= 0.35) and speedKmh > 28 and nowClock >= nextJumpBoostAt then
		nextJumpBoostAt = nowClock + 0.85
		local upBoost = math.clamp(speedStuds * 0.42, 20, 52)
		local fwdBoost = math.clamp(speedStuds * 0.25, 14, 36)
		driveSeat.AssemblyLinearVelocity = vel + Vector3.new(0, upBoost, 0) + horizontalForward * fwdBoost
	end

	if isGrounded then
		-- 1. Arcade Forward / Reverse Thrust (capped at REVERSE_MAX_SPEED_KMH in reverse)
		if math.abs(throttleCmd) > 0.01 and speedKmh < activeTopSpeedKmh then
			local speedFactor = 1 - math.clamp(speedKmh / activeTopSpeedKmh, 0, 0.92) * 0.45
			totalForce += horizontalForward * (throttleCmd * stage.AccelForce * nitroBoostMult * speedFactor)
		end

		-- 2. Direct Linear Braking Assist (stops from 100 km/h in < 1.1s cleanly without nose-diving)
		if brakeCmd > 0 and speedStuds > 1.5 and not spaceDown then
			local brakeDir = -Vector3.new(vel.X, 0, vel.Z)
			if brakeDir.Magnitude > 0.01 then
				totalForce += brakeDir.Unit * (38000 * brakeCmd * brakeMult)
			end
		elseif spaceDown and speedStuds > 2 then
			-- Handbrake linear drag (allows sliding sideways while scrubbing forward speed)
			local dragDir = -Vector3.new(vel.X, 0, vel.Z)
			if dragDir.Magnitude > 0.01 then
				totalForce += dragDir.Unit * (16500 * brakeMult)
			end
		end

		-- 3. CDT Lateral Grip & Controlled Drift Assist
		local turnSign = (forwardSpeed >= -1) and 1 or -1
		if (spaceDown or tireModeName == "Drift") and forwardSpeed > 22 and math.abs(smoothedSteer) > 0.1 then
			isDrifting = true
			-- Controlled Drift Yaw Assist + Lateral Slide Stabilization
			local desiredYawRate = -smoothedSteer * turnSign * tire.DriftYawRate * (spaceDown and 1.25 or 0.95)
			local currentYawRate = driveSeat.AssemblyAngularVelocity.Y
			local yawError = desiredYawRate - currentYawRate
			totalYawTorque += Vector3.new(0, yawError * 45000, 0)

			-- Keep lateral slide controlled so car glides around the corner instead of spinning out
			totalForce += -horizontalRight * (lateralSpeed * 320 * tire.LateralGrip)
		else
			-- High-Grip Cornering Stabilization (plants the car into corners cleanly in both Forward & Reverse)
			totalForce += -horizontalRight * (lateralSpeed * 720 * tire.LateralGrip)
			if math.abs(smoothedSteer) > 0.05 and speedKmh > 6 then
				local targetYaw = -smoothedSteer * turnSign * math.clamp(speedKmh / 45, 0.3, 1.45) * 1.60
				local yawDiff = targetYaw - driveSeat.AssemblyAngularVelocity.Y
				totalYawTorque += Vector3.new(0, yawDiff * 30000, 0)
			end
		end

		-- 4. Active Anti-Roll Stabilizer (prevents flipping while allowing natural slopes)
		local currentRoll = math.asin(math.clamp(rightDir.Y, -1, 1))
		if math.abs(currentRoll) > math.rad(6) then
			totalYawTorque += forwardDir * (-currentRoll * 68000)
		end
	else
		-- ========================================================================
		-- MID-AIR CAR CONTROL & LONG GLIDE ASSIST (Air Steer Yaw/Strafe, Pitch & Barrel Roll)
		-- ========================================================================
		local mass = driveSeat.AssemblyMass
		local airTime = nowClock - wasOnRampAt

		if speedKmh > 18 then
			-- 1. Counteract 55% of Roblox gravity so the car glides far across ramps
			totalForce += Vector3.yAxis * (mass * workspace.Gravity * 0.55)
			-- 2. Forward Air Carry when holding W
			if wDown and speedKmh < (stage.TopSpeedKmh * 1.15) then
				totalForce += horizontalForward * (stage.AccelForce * 0.38)
			end
			-- 3. Mid-Air Lateral Strafe Control (A/D nudges flight path left/right to aim landing)
			if math.abs(rawSteer) > 0.05 then
				totalForce += horizontalRight * (rawSteer * stage.AccelForce * 0.24)
			end
		end

		-- 4. Mid-Air Pitch (W/S), Air Steer Yaw (A/D), and Barrel Roll (Space + A/D)
		local currentRoll = math.asin(math.clamp(rightDir.Y, -1, 1))
		local currentPitch = math.asin(math.clamp(forwardDir.Y, -1, 1))

		-- Safe Clamped Pitch Control:
		-- First 0.25s off ramp: hold +6 deg launch posture; after 0.25s, W tilts nose down (-10 deg max), S pulls nose up (+22 deg max)
		local targetPitch = math.rad(5)
		if sDown then
			targetPitch = math.rad(22)
		elseif wDown and airTime > 0.25 then
			targetPitch = math.rad(-10)
		end
		local pitchError = targetPitch - currentPitch
		totalYawTorque += rightDir * (pitchError * 45000)

		if spaceDown and math.abs(rawSteer) > 0.05 then
			-- Barrel Roll Mode (Hold Spacebar + A/D in mid-air)
			local desiredRollRate = -rawSteer * 3.2
			local currentRollRate = driveSeat.AssemblyAngularVelocity:Dot(forwardDir)
			totalYawTorque += forwardDir * ((desiredRollRate - currentRollRate) * 42000)
		else
			-- Normal Air Steering Mode: A/D turns the car's heading (Yaw) + banks gently (+/-14 deg) while preventing flips
			local targetBankRoll = math.rad(rawSteer * 14)
			local rollError = targetBankRoll - currentRoll
			totalYawTorque += forwardDir * (rollError * 54000)

			local desiredAirYawRate = -smoothedSteer * 1.45
			local currentYawRate = driveSeat.AssemblyAngularVelocity.Y
			totalYawTorque += Vector3.new(0, (desiredAirYawRate - currentYawRate) * 34000, 0)
		end
	end

	cdtVectorForce.Force = totalForce
	cdtYawTorque.Torque = totalYawTorque

	-- ============================================================================
	-- 7. 6-SPEED VIRTUAL TRANSMISSION, AUDIO & TELEMETRY ATTRIBUTES
	-- ============================================================================
	local gearTopSpeeds = {
		stage.TopSpeedKmh * 0.20,
		stage.TopSpeedKmh * 0.36,
		stage.TopSpeedKmh * 0.52,
		stage.TopSpeedKmh * 0.68,
		stage.TopSpeedKmh * 0.84,
		stage.TopSpeedKmh * 1.00,
	}

	if isReversing then
		currentGear = -1
	elseif speedKmh < 3 and math.abs(throttleCmd) < 0.05 then
		currentGear = 0
	else
		local newGear = 1
		for g = 1, 6 do
			if speedKmh > gearTopSpeeds[g] * 0.92 and g < 6 then
				newGear = g + 1
			end
		end
		currentGear = newGear
	end

	local gearMinSpd = (currentGear > 1) and (gearTopSpeeds[currentGear - 1] * 0.72) or 0
	local gearMaxSpd = (currentGear >= 1) and gearTopSpeeds[currentGear] or 45
	local inGearRatio = math.clamp((speedKmh - gearMinSpd) / math.max(15, gearMaxSpd - gearMinSpd), 0, 1)
	local targetRPM = 1000 + inGearRatio * 5600 + math.abs(throttleCmd) * 650
	if math.abs(throttleCmd) < 0.05 then
		-- Cruise relaxation so RPM never hangs when lifting off W
		targetRPM = 1000 + inGearRatio * 3400
	end
	currentRPM = currentRPM + (targetRPM - currentRPM) * math.min(1, dt * 10)

	-- Update attributes & A-Chassis Interface Values for CarStatusGui & Proving Grounds Telemetry
	car:SetAttribute("CurrentSpeedKmh", math.floor(speedKmh + 0.5))
	car:SetAttribute("CurrentRPM", math.floor(currentRPM + 0.5))
	car:SetAttribute("CurrentGear", currentGear == -1 and "R" or (currentGear == 0 and "N" or tostring(currentGear)))

	local interfaceValues = gui:FindFirstChild("Values")
	if interfaceValues then
		local gearVal = interfaceValues:FindFirstChild("Gear")
		if gearVal then gearVal.Value = currentGear end
		local rpmVal = interfaceValues:FindFirstChild("RPM")
		if rpmVal then rpmVal.Value = currentRPM end
	end

	-- Modulate Clean Engine Sound & Tire Screech
	if engSound then
		local rpmNorm = math.clamp((currentRPM - 1000) / 6500, 0, 1)
		local gearSaw = (math.max(1, currentGear) - 1) * 0.03
		engSound.PlaybackSpeed = 0.72 + rpmNorm * 0.92 - gearSaw + (isNitroActive and 0.18 or 0)
		engSound.Volume = canDrive and (0.30 + math.abs(throttleCmd) * 0.24 + rpmNorm * 0.14) or 0.05
	end

	-- STRICT GROUND-ONLY TIRE SMOKE (Zero smoke while jumping/airborne!)
	local shouldSmoke = isGrounded and (
		isDrifting
		or (spaceDown and speedKmh > 18)
		or (brakeCmd > 0.5 and speedKmh > 42)
		or (slipAngleDeg > 16 and speedKmh > 30)
	)
	local shouldBrakeLight = (brakeCmd > 0.2 or spaceDown)

	-- Cornering + Drift Tire Screech Audio (Plays when turning hard on ground OR drifting/braking)
	local cornerSteerLoad = isGrounded and (math.abs(smoothedSteer) * math.clamp((speedKmh - 20) / 50, 0, 1)) or 0
	local isCornerScreeching = isGrounded and (cornerSteerLoad > 0.22 or math.abs(lateralSpeed) > 6)
	if tireSound then
		local targetScreechVol = 0
		if shouldSmoke then
			targetScreechVol = math.clamp(speedKmh / 85, 0.28, 0.65)
		elseif isCornerScreeching then
			targetScreechVol = math.clamp(cornerSteerLoad * 0.48, 0.16, 0.45)
		end
		tireSound.Volume = tireSound.Volume + (targetScreechVol - tireSound.Volume) * math.min(1, dt * 14)
		tireSound.PlaybackSpeed = 0.94 + math.clamp((slipAngleDeg + cornerSteerLoad * 25) / 65, 0, 0.26)
	end

	-- Trigger Local Wheel Smoke + Skidmark Trails ONLY on wheels touching the ground & sync to Server
	for _, w in ipairs(wheelList) do
		if not w.Smoke then w.Smoke = w.Part:FindFirstChild("TireSmoke", true) end
		if not w.Trail then w.Trail = w.Part:FindFirstChild("SkidTrail", true) end
		local activeOnWheel = shouldSmoke and (w.IsGrounded == true) and (w.IsRear or brakeCmd > 0.5)
		if w.Smoke then w.Smoke.Enabled = activeOnWheel end
		if w.Trail then w.Trail.Enabled = activeOnWheel end
	end

	if os.clock() - lastVFXSync > 0.12 or shouldSmoke ~= lastSmokeState or shouldBrakeLight ~= lastBrakeState then
		lastVFXSync = os.clock()
		lastSmokeState = shouldSmoke
		lastBrakeState = shouldBrakeLight
		if tuningRemote then
			tuningRemote:FireServer(car, "VFXState", {
				Smoking = shouldSmoke,
				Skidding = shouldSmoke,
				Braking = shouldBrakeLight,
				AllWheels = (brakeCmd > 0.5 and not spaceDown),
			})
		end
	end

	-- ============================================================================
	-- 8. CDT HORIZON-LOCKED VELOCITY-VECTOR DRIFT CAMERA
	-- ============================================================================
	if cam and cam.CameraType ~= Enum.CameraType.Scriptable then
		local targetFov = 70 + math.clamp(speedKmh / 18, 0, 10) + (isNitroActive and 8 or 0)
		cam.FieldOfView = cam.FieldOfView + (targetFov - cam.FieldOfView) * math.min(1, dt * 8)

		local cPos = cam.CFrame.Position
		local cLook = cam.CFrame.LookVector
		local flatLook = Vector3.new(cLook.X, cLook.Y * 0.88, cLook.Z)
		if flatLook.Magnitude > 0.01 then
			cam.CFrame = CFrame.lookAt(cPos, cPos + flatLook.Unit, Vector3.yAxis)
		end
	end
end)

gui.AncestryChanged:Connect(function(_, parent)
	if not parent then
		renderConn:Disconnect()
		ContextActionService:UnbindAction("CDT_ExitCar")
		cdtVectorForce.Force = Vector3.zero
		cdtYawTorque.Torque = Vector3.zero
	end
end)
]=====]

print("[HOKI_CDT_ENGINE] Verified & installed Clean CDT Arcade Engine + Garage Tuning on TeslaRoadster!")
