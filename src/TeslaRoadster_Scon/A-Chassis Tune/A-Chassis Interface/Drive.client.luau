--[[	
		             _____ _                   _     
	     /\         / ____| |                 (_)    
	    /  \ ______| |    | |__   __ _ ___ ___ _ ___ 
	   / /\ \______| |    | '_ \ / _` / __/ __| / __|
	  / ____ \     | |____| | | | (_| \__ \__ \ \__ \
	 /_/    \_\     \_____|_| |_|\__,_|___/___/_|___/
	 Version 1.7
--]]

-- Dependencies
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer :: Player
local mouse = player:GetMouse()

local carVal = script.Parent:WaitForChild("Car", 5) :: ObjectValue?
local car = carVal and carVal.Value
if not car then
	local startWait = os.clock()
	while not car and (os.clock() - startWait) < 3 do
		task.wait(0.05)
		car = carVal and carVal.Value
	end
end
if not car then
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
		car = hum.SeatPart:FindFirstAncestorOfClass("Model")
	end
	if not car then
		car = workspace:FindFirstChild("TeslaRoadster")
	end
end

local values = script.Parent:WaitForChild("Values", 5)
local tuneFolder = (car and (car:FindFirstChild("Hoki-Chassis Tune") or car:FindFirstChild("A-Chassis Tune")))
	or script.Parent.Parent
local _Tune = tuneFolder and require(tuneFolder)
local Units = tuneFolder and tuneFolder:FindFirstChild("README") and require(tuneFolder.README.Units)
local SpiderFlightEngine = require(script.Parent:WaitForChild("SpiderFlightEngine"))
local StuntCamera = require(script.Parent:WaitForChild("StuntCamera"))
print(">>> [DRIVE CLIENT ACTIVE] Drive.client.luau initialized for car: " .. tostring(car))

-- ============================================================================
-- DYNAMIC MULTI-VEHICLE TIRE SMOKE RIG (Universal across all vehicle models)
-- Automatically computes wheel ground contact offsets relative to DriveSeat
-- ============================================================================
local function ensureMultiVehicleSmokeRig()
	local wheelsModel = car:FindFirstChild("Wheels")
	local seat = car:FindFirstChild("DriveSeat")
	if not wheelsModel or not seat then
		return
	end

	for _, w in ipairs(wheelsModel:GetChildren()) do
		if w:IsA("BasePart") then
			local attName = w.Name .. "_SmokeAtt"
			local att = seat:FindFirstChild(attName)
			if not att then
				att = Instance.new("Attachment")
				att.Name = attName
				local rel = seat.CFrame:PointToObjectSpace(w.Position)
				local halfH = w.Size.Y * 0.5
				local trailZ = rel.Z > 0 and 0.4 or -0.4
				att.Position = Vector3.new(rel.X, rel.Y - halfH + 0.15, rel.Z + trailZ)
				att.Parent = seat
			end

			local pe = att:FindFirstChild("TireSmoke")
			if not pe then
				pe = Instance.new("ParticleEmitter")
				pe.Name = "TireSmoke"
				pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
				pe.Color = ColorSequence.new(Color3.fromRGB(240, 240, 245), Color3.fromRGB(200, 200, 210))
				pe.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.9),
					NumberSequenceKeypoint.new(0.35, 2.8),
					NumberSequenceKeypoint.new(1.0, 5.2),
				})
				pe.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.35),
					NumberSequenceKeypoint.new(0.6, 0.65),
					NumberSequenceKeypoint.new(1.0, 1.0),
				})
				pe.Lifetime = NumberRange.new(0.6, 1.2)
				pe.Speed = NumberRange.new(1.2, 2.5)
				pe.Drag = 3.5
				pe.Acceleration = Vector3.new(0, 1.2, 0)
				pe.SpreadAngle = Vector2.new(20, 20)
				pe.Orientation = Enum.ParticleOrientation.FacingCamera
				pe.EmissionDirection = Enum.NormalId.Top
				pe.Enabled = false
				pe.Parent = att
			end
		end
	end
end
task.spawn(ensureMultiVehicleSmokeRig)

local VirtualInput = script:FindFirstChild("VirtualInput") or Instance.new("BindableEvent")

local _IThrot = 0
local _GSteerT = 0
local _IBrake = 0

local RemoteThrottle = script.Parent:FindFirstChild("RemoteThrottle")
if not RemoteThrottle then
	RemoteThrottle = Instance.new("RemoteEvent")
	RemoteThrottle.Name = "RemoteThrottle"
	RemoteThrottle.Parent = script.Parent
end
RemoteThrottle.OnClientEvent:Connect(function(throt: number?, steer: number?, brake: number?)
	if throt ~= nil then
		_IThrot = throt
	end
	if steer ~= nil then
		_GSteerT = steer
	end
	if brake ~= nil then
		_IBrake = brake
	end
end)

local pgui = player:FindFirstChild("PlayerGui")
if _Tune.Mobile and pgui then
	pgui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
	GuiService.TouchControlsEnabled = false
end

local MobileMode = "Tap"
local MobileModes = { "Tap", "Tilt" }
local MobileUI = script.Parent.Mobile
local MobileUIChildren = MobileUI:GetChildren()
local LastInputWasMobile = UserInputService:GetLastInputType() == Enum.UserInputType.Touch

local LastInputWasGamepad = string.find(UserInputService:GetLastInputType().Name, "Gamepad") and true or false
local ChatInputBarConfiguration = TextChatService.ChatInputBarConfiguration

local GlobalTemperature = workspace:GetAttribute("GlobalTemperature") or 22

-- Value Instance Caching
local Value = {
	Clutch = values.Clutch,
	Gear = values.Gear,
	TransmissionMode = values.TransmissionMode,
	CurrentRatio = values.CurrentRatio,
	RPM = values.RPM,
	Boost = values.Boost,
	BoostTurbo = values.BoostTurbo,
	BoostSuper = values.BoostSuper,
	HpNatural = values.HpNatural,
	HpElectric = values.HpElectric,
	HpTurbo = values.HpTurbo,
	HpSuper = values.HpSuper,
	HpBoosted = values.HpBoosted,
	Horsepower = values.Horsepower,
	TqNatural = values.TqNatural,
	TqElectric = values.TqElectric,
	TqTurbo = values.TqTurbo,
	TqSuper = values.TqSuper,
	TqBoosted = values.TqBoosted,
	Torque = values.Torque,
	Throttle = values.Throttle,
	InputThrottle = values.InputThrottle,
	Brake = values.Brake,
	InputBrake = values.InputBrake,
	SteerC = values.SteerC,
	SteerT = values.SteerT,
	PBrake = values.PBrake,
	Velocity = values.Velocity,
	AverageRotSpeed = values.AverageRotSpeed,
	Acceleration = values.Acceleration,
	Center = values.Center,
	TCS = values.TCS,
	TCSActive = values.TCSActive,
	TCSAmt = values.TCSAmt,
	ABS = values.ABS,
	ABSActive = values.ABSActive,
	ABSAmt = values.ABSAmt,
	ESC = values.ESC,
	ESCActive = values.ESCActive,
	ESCAmt = values.ESCAmt,
	CS = values.CS,
	CSActive = values.CSActive,
	CSAmt = values.CSAmt,
}

local TCSTrackerFolder = values.TCSTracker
local ABSTrackerFolder = values.ABSTracker
local ESCTrackerFolder = values.ESCTracker
local WheelSpeedsFolder = values.WheelSpeeds

-- Status Vars
local _IsOn = _Tune.AutoStart and true or (_Tune.Engine or _Tune.Electric)
local IsOnValue = script.Parent.IsOn
IsOnValue.Value = _IsOn
IsOnValue.Changed:Connect(function(value)
	_IsOn = value
end)

local _Starting = false
local StartingValue = IsOnValue.Starting
StartingValue.Value = _Starting
StartingValue.Changed:Connect(function(value)
	_Starting = value
end)

local _InControls = false
local ControlsOpenValue = script.Parent.ControlsOpen
ControlsOpenValue.Value = _InControls
ControlsOpenValue.Changed:Connect(function(value)
	_InControls = value
end)

local _AutoClutch = true
local AutoClutchValue = values.AutoClutch
AutoClutchValue.Value = _AutoClutch
AutoClutchValue.Changed:Connect(function(value)
	_AutoClutch = value
end)

local _MSteer = false
local MouseSteerValue = values.MouseSteerOn
MouseSteerValue.Value = false
MouseSteerValue.Changed:Connect(function(value)
	_MSteer = false
	if value then
		MouseSteerValue.Value = false
	end
end)

-- Status Vars
local ParkingGearEnabled = _Tune.Ratios[1] == 0
local ParkingGearOffset = ParkingGearEnabled and 1 or 0

local _GSteerC = 0

local _GThrot = 0
local _InThrot = 0
local _GBrake = 0
local _InBrake = 0

local _GClutch = 0
local _ClPressing = false
local _PlayerClutch = false
local _Clutch = 0
local _ClutchKick = 0
local _ClutchModulate = 0

local _RPM = _Tune.AutoStart and _Tune.IgnitionRPM or 0
local _OutTorque = 0
local _CGear = ParkingGearOffset == 1 and -2 or (_Tune.AutoStart and 1 or 0)
local _ShiftUp = false
local _ShiftDn = false
local _Shifting = false
local _spLimit = 0

local engine = tuneFolder
		and tuneFolder:FindFirstChild("README")
		and tuneFolder.README:FindFirstChild("CustomEngine")
		and require(tuneFolder.README.CustomEngine)
	or nil

local _Boost = 0
local _TBoost = 0
local _SBoost = 0

local _HP = 0
local _TQ = 0
local _NH = 0
local _NT = 0
local _EH = 0
local _ET = 0
local _TH = 0
local _TT = 0
local _SH = 0
local _ST = 0
local _BH = 0
local _BT = 0

local _CurrentRatio = _Tune.Ratios[_CGear + 2 + ParkingGearOffset]
local _CVTRatio = 0
local _FlywheelEnergy = 0

local _TMode = "Auto"
local _RevLimiting = false

local _SteerL = false
local _SteerR = false
local _PBrake = not _Tune.AutoStart and values.PBrake.Value or false
local _SpaceHeld = false
local _TapDriftActive = false
local _PrevIBrake = 0
local _BrakePressTimestamp = 0
local _EligibleForTapDrift = false
local _DriftEndTime = 0
local _StraightenTimer = 0

local _TCSTracker = {}
local _TCS = _Tune.TCSEnabled
local _TCSActive = false
local _TCSAmt = 0

local _ABSTracker = {}
local _ABS = _Tune.ABSEnabled
local _ABSActive = false
local _ABSAmt = 0

local _ESCTracker = {}
local _ESC = _Tune.ESCEnabled and _Tune.TCSEnabled
local _ESCActive = false
local _ESCAmt = 0

local _CS = _Tune.CSEnabled
local _CSActive = false
local _CSAmt = 0
local _MidAirActive = false
local stunt: any = nil
local stuntCam: any = nil
local _FrontGroundedCount = 2
local _RearGroundedCount = 2
local _WheelGrounded = { FL = true, FR = true, RL = true, RR = true }

local _FlipWait = tick()
local _FlipDB = false

local _WheelSpeedsTable = {}
local _WheelSpeeds = {}

local _AvgWheelSpeed = 0
local _DriveWheelSpeed = 0
local _MaxWheelSpin = 0

local _OldVelocity = Vector3.new()
local _Acceleration = Vector3.new()
local _Velocity = Vector3.new()
local _Center = CFrame.new()

_Tune.AutoShiftVers = "Old"
local _InitialAutoShiftVers = "Old"

local weightBrick = (car.Body:FindFirstChild("#Weight") or car.DriveSeat) :: BasePart
local driveSeat = car.DriveSeat :: VehicleSeat

-- Initialize Client
local FWheelCount = 0
local RWheelCount = 0

local wDia = 0
local wDRatio = 0

local Wheels = {}
local Drive = {}

for _, v in car.Wheels:GetChildren() :: { BasePart } do
	local name = v.Name
	if
		not v:IsA("BasePart")
		or not (name == "FL" or name == "FR" or name == "F" or name == "RL" or name == "RR" or name == "R")
	then
		continue
	end

	local size = v.Size
	local base = v:FindFirstChild("Base")
	local arm = v:FindFirstChild("Arm")

	local steer = arm and arm:FindFirstChild("Steer") or nil
	local rotate = base and base:FindFirstChild("Rotate") or nil
	local straightLock = base and base:FindFirstChild("StraightLock") or nil
	local steerAttach0 = _Tune.PowerSteeringType == "New" and steer and steer.Attachment0 or nil

	local av = v:FindFirstChild("#AV")
	local bv = v:FindFirstChild("#BV")

	FWheelCount += string.find(name, "F") and 1 or 0
	RWheelCount += (not string.find(name, "F")) and 1 or 0

	local isFront = string.find(name, "F") ~= nil
	local driven = ((_Tune.Config == "FWD" or _Tune.Config == "AWD") and isFront)
		or ((_Tune.Config == "RWD" or _Tune.Config == "AWD") and not isFront)

	local canSteer = 0
	if arm and (steer or (rotate and _Tune.PowerSteeringType == "Servo")) then
		canSteer = v:GetAttribute("SteerDisabled") and 1 or 2
	end

	local WheelSpeedValue = Instance.new("NumberValue", WheelSpeedsFolder)
	WheelSpeedValue.Name = name
	local TCSTrackerValue = Instance.new("NumberValue", TCSTrackerFolder)
	TCSTrackerValue.Name = name
	local ABSTrackerValue = Instance.new("NumberValue", ABSTrackerFolder)
	ABSTrackerValue.Name = name
	local ESCTrackerValue = Instance.new("NumberValue", ESCTrackerFolder)
	ESCTrackerValue.Name = name

	local data = {}
	data.Name = name
	data.OppositeWheel = (name == "FL" and car.Wheels:FindFirstChild("FR"))
		or (name == "FR" and car.Wheels:FindFirstChild("FL"))
		or (name == "RL" and car.Wheels:FindFirstChild("RR"))
		or (name == "RR" and car.Wheels:FindFirstChild("RL"))
	data.Size = size
	data.Base = base
	data.Arm = arm
	data.Steer = steer
	data.SteerAttach0 = steerAttach0
	data.Rotate = rotate
	data.StraightLock = straightLock
	data.AV = av
	data.BV = bv
	data.isFront = isFront
	data.driven = driven
	data.WheelSpeedValue = WheelSpeedValue
	data.TCSTrackerValue = TCSTrackerValue
	data.ABSTrackerValue = ABSTrackerValue
	data.ESCTrackerValue = ESCTrackerValue
	data.RotVelocityMagnitude = 0
	data.WheelVelocityMagnitude = 0
	data.CanSteer = canSteer

	if driven then
		table.insert(Drive, v)
	end

	v:GetPropertyChangedSignal("Size"):Connect(function()
		Wheels[v].Size = v.Size

		local size = 0
		for name, data in Wheels do
			size = math.max(size, data.Size.Y)
			wDia = size
		end

		wDRatio = wDia * math.pi / 60
	end)

	v:GetAttributeChangedSignal("SteerDisabled"):Connect(function()
		data.CanSteer = v:GetAttribute("SteerDisabled") and 1 or 2
	end)

	Wheels[v] = data
end

for name, data in Wheels do
	wDia = math.max(wDia, data.Size.Y)
	wDRatio = wDia * math.pi / 60
end

-- /// <summary>Continuous, velocity-capped step-climb assist for uneven curbs and multi-level terrain.</summary>
local curbAssistForce = (
	car.Body:FindFirstChild("CurbAssistForce", true) or (weightBrick and weightBrick:FindFirstChild("CurbAssistForce"))
) :: VectorForce?
if curbAssistForce then
	curbAssistForce.RelativeTo = Enum.ActuatorRelativeTo.World
	curbAssistForce.ApplyAtCenterOfMass = true
end

local curbAssistRaycastParams = RaycastParams.new()
curbAssistRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
curbAssistRaycastParams.FilterDescendantsInstances = { car }
curbAssistRaycastParams.RespectCanCollide = true

local cachedTotalVehicleMass: number? = nil
local function getTotalVehicleMass(): number
	if cachedTotalVehicleMass and cachedTotalVehicleMass > 0 then
		return cachedTotalVehicleMass
	end
	local total = 0
	for _, desc in car:GetDescendants() do
		if desc:IsA("BasePart") and not desc.Massless then
			total += desc:GetMass()
		end
	end
	if total <= 0 and weightBrick then
		total = weightBrick.AssemblyMass
	end
	cachedTotalVehicleMass = total
	return total
end

local curbClimbLatch = {
	Active = false,
	TargetTopY = 0,
	StepHeight = 0,
	LastSeenAt = 0,
}

local function getEffectiveSeatThrottle(): number
	local testThrot = RunService:IsStudio() and car:GetAttribute("SconTestThrottle")
	if typeof(testThrot) == "number" then
		return math.clamp(testThrot, -1, 1)
	end
	return driveSeat and driveSeat.ThrottleFloat or 0
end

local function getEffectiveSeatSteer(): number
	local testSteer = RunService:IsStudio() and car:GetAttribute("SconTestSteer")
	if typeof(testSteer) == "number" then
		return math.clamp(testSteer, -1, 1)
	end
	return driveSeat and driveSeat.SteerFloat or 0
end

local function isBoostActive(): boolean
	return stunt ~= nil and stunt:IsBoostActive(_IsOn) or false
end

local function clearCurbAssistState()
	curbClimbLatch.Active = false
	curbClimbLatch.TargetTopY = 0
	curbClimbLatch.StepHeight = 0
	if curbAssistForce then
		curbAssistForce.Force = Vector3.zero
	end
	car:SetAttribute("SconStepClimbActive", false)
	car:SetAttribute("SconStepClimbHeight", 0)
end

local function UpdateCurbAssist(deltaTime: number)
	if
		not _Tune.CurbAssistEnabled
		or not curbAssistForce
		or not weightBrick
		or _MidAirActive
		or (stunt and (stunt.wallClimbActive or stunt.surfaceNormal.Y < 0.72 or os.clock() < stunt.jumpDetachUntil))
	then
		clearCurbAssistState()
		return
	end

	local throttle = getEffectiveSeatThrottle()
	local driveDirection = throttle > 0.05 and 1 or (throttle < -0.05 and -1 or 0)
	if driveDirection == 0 then
		clearCurbAssistState()
		return
	end

	local lookVector = driveSeat.CFrame.LookVector
	local forwardXZ = Vector3.new(lookVector.X, 0, lookVector.Z)
	if forwardXZ.Magnitude <= 1e-4 then
		clearCurbAssistState()
		return
	end
	local forward = forwardXZ.Unit * driveDirection

	local planarVelocity = Vector3.new(_Velocity.X, 0, _Velocity.Z)
	local approachSpeed = math.max(0, planarVelocity:Dot(forward))
	local maxStep = (_Tune.CurbAssistMaxStep and _Tune.CurbAssistMaxStep > 0) and _Tune.CurbAssistMaxStep or 2.0
	local baseProbe = (_Tune.CurbAssistProbeDistance and _Tune.CurbAssistProbeDistance > 0)
			and _Tune.CurbAssistProbeDistance
		or 0.95
	local maxProbe = (_Tune.CurbAssistMaxProbeDistance and _Tune.CurbAssistMaxProbeDistance > baseProbe)
			and _Tune.CurbAssistMaxProbeDistance
		or 2.6
	local lookAhead = _Tune.CurbAssistLookAheadSeconds or 0.04
	local probeDistance = math.clamp(baseProbe + approachSpeed * lookAhead, baseProbe, maxProbe)

	local bestStepHeight = 0
	local bestTargetTopY = -math.huge
	local groundedWheelsCount = 0

	for wheel in Wheels do
		local radius = math.max(wheel.Size.Y, wheel.Size.Z) * 0.5
		local floorHit = workspace:Raycast(
			wheel.Position + Vector3.yAxis * 0.35,
			-Vector3.yAxis * (radius + 1.25),
			curbAssistRaycastParams
		)
		local floorY = floorHit and floorHit.Position.Y or (wheel.Position.Y - radius)
		if floorHit and (wheel.Position.Y - radius - floorY) <= 0.65 then
			groundedWheelsCount += 1
		end

		-- Multi-height scan across tire face so both 0.4-stud low curbs and 2.0-stud steps register reliably
		local scanOffsetsY = { -radius + 0.22, -radius * 0.45, 0.12 }
		for _, offsetY in scanOffsetsY do
			local rayOrigin = wheel.Position + forward * math.max(0.2, radius - 0.15) + Vector3.yAxis * offsetY
			local obstacle = workspace:Raycast(rayOrigin, forward * probeDistance, curbAssistRaycastParams)
			if not obstacle or obstacle.Normal.Y >= 0.45 then
				continue
			end

			-- Reject tall walls (> maxStep + 0.35): headroom check directly across obstacle face
			local headroomOrigin = Vector3.new(wheel.Position.X, floorY + maxStep + 0.35, wheel.Position.Z)
			local headroomSpan = math.max(0.2, radius - 0.15) + obstacle.Distance + 0.35
			local headroomHit = workspace:Raycast(headroomOrigin, forward * headroomSpan, curbAssistRaycastParams)
			if headroomHit then
				continue
			end

			local topProbeOrigin = Vector3.new(obstacle.Position.X, floorY + maxStep + 0.35, obstacle.Position.Z)
				+ forward * 0.25
			local topHit = workspace:Raycast(topProbeOrigin, -Vector3.yAxis * (maxStep + 0.50), curbAssistRaycastParams)
			if not topHit or topHit.Normal.Y < 0.65 then
				continue
			end

			local stepHeight = topHit.Position.Y - floorY
			if stepHeight >= 0.22 and stepHeight <= (maxStep + 0.05) then
				if stepHeight > bestStepHeight then
					bestStepHeight = stepHeight
					bestTargetTopY = math.max(bestTargetTopY, topHit.Position.Y)
				end
				break
			end
		end
	end

	local now = os.clock()
	if bestStepHeight > 0 then
		curbClimbLatch.Active = true
		curbClimbLatch.TargetTopY = bestTargetTopY
		curbClimbLatch.StepHeight = bestStepHeight
		curbClimbLatch.LastSeenAt = now
	elseif curbClimbLatch.Active then
		local highestClearingGap = -math.huge
		for wheel in Wheels do
			local radius = math.max(wheel.Size.Y, wheel.Size.Z) * 0.5
			local wheelBottomY = wheel.Position.Y - radius
			local remainingRise = curbClimbLatch.TargetTopY - wheelBottomY
			if remainingRise > highestClearingGap then
				highestClearingGap = remainingRise
			end
		end
		-- Release latch cleanly once wheels clear the ledge or probe times out
		if (now - curbClimbLatch.LastSeenAt > 0.22) or groundedWheelsCount == 0 or highestClearingGap <= 0.06 then
			curbClimbLatch.Active = false
		end
	end

	if not curbClimbLatch.Active or groundedWheelsCount == 0 then
		clearCurbAssistState()
		return
	end

	local totalMass = getTotalVehicleMass()
	local weightMass = weightBrick.AssemblyMass
	local nonWeightMass = math.max(totalMass - weightMass, 0)
	local gravComp = (_Tune.GravComp and _Tune.GravComp > 0) and _Tune.GravComp or workspace.Gravity
	local totalWeightForce = weightMass * workspace.Gravity + nonWeightMass * gravComp

	local activeStep = math.clamp(bestStepHeight > 0 and bestStepHeight or curbClimbLatch.StepHeight, 0.25, maxStep)
	local maxUpSpeed = math.max(
		(_Tune.CurbAssistMaxUpwardSpeed and _Tune.CurbAssistMaxUpwardSpeed > 0) and _Tune.CurbAssistMaxUpwardSpeed
			or 6.5,
		1.0
	)
	local climbAccelMax = math.max(_Tune.CurbAssistAcceleration or 48, 12)

	-- Smooth velocity-regulated climb: scales gently with step size and caps strictly <= maxUpSpeed
	local targetVy = math.clamp(1.8 + activeStep * 2.1 + math.min(approachSpeed * 0.06, 1.2), 2.4, maxUpSpeed)
	local currentVy = weightBrick.AssemblyLinearVelocity.Y
	local speedError = targetVy - currentVy
	local commandedAccel = math.clamp(speedError / 0.08, -28, climbAccelMax)
	local liftForce =
		math.clamp(totalWeightForce + totalMass * commandedAccel, 0, totalWeightForce + totalMass * climbAccelMax)

	curbAssistForce.Force = Vector3.yAxis * liftForce
	car:SetAttribute("SconStepClimbActive", true)
	car:SetAttribute("SconStepClimbHeight", math.floor(activeStep * 100 + 0.5) / 100)

	-- Keep roll and pitch calm during uneven climbs without muting yaw steering
	local carCFrame = weightBrick.CFrame
	local localAngularVelocity = carCFrame:VectorToObjectSpace(weightBrick.AssemblyAngularVelocity)
	local angularBlend = math.exp(-(_Tune.CurbAssistAngularDampingRate or 8.0) * deltaTime)
	localAngularVelocity = Vector3.new(
		localAngularVelocity.X * angularBlend,
		localAngularVelocity.Y,
		localAngularVelocity.Z * angularBlend
	)
	weightBrick.AssemblyAngularVelocity = carCFrame:VectorToWorldSpace(localAngularVelocity)
end

-- Shutdown
local function unbindDriverControls()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end
	local CAS = game:GetService("ContextActionService")
	CAS:UnbindAction("HokiSpacebarHandbrakeSink")
	CAS:UnbindAction("HokiDriverCleanExit")
	CAS:UnbindAction("HokiTeslaHorn")
	CAS:UnbindAction("HokiBoostFlight")
	if stuntCam then
		stuntCam:Destroy()
		stuntCam = nil
	end
end

driveSeat.ChildRemoved:Connect(function(child: Instance)
	if child.Name == "SeatWeld" and child:IsA("Weld") then
		unbindDriverControls()
		clearCurbAssistState()
		if stunt then
			stunt:ResetOnExit()
		end
		if _Tune.Mobile and LastInputWasMobile then
			_Tune.AutoShiftVers = _InitialAutoShiftVers
		end

		-- Remove Flip Force
		if driveSeat:FindFirstChild("Flip") then
			if _Tune.FlipType == "New" then
				driveSeat.Flip.Enabled = false
			else
				driveSeat.Flip.MaxTorque = Vector3.new()
			end
		end

		-- Clear stale driver input and engage the parking brake before saving state.
		_IThrot = 0
		_IBrake = 0
		_GThrot = 0
		_GBrake = 0
		_GSteerT = 0
		_GSteerC = 0
		_SteerL = false
		_SteerR = false
		_PBrake = true
		if ParkingGearEnabled then
			_CGear = -2
		end

		local values = script.Parent.Values
		values.InputThrottle.Value = 0
		values.Throttle.Value = 0
		values.InputBrake.Value = 0
		values.Brake.Value = 0
		values.SteerT.Value = 0
		values.SteerC.Value = 0
		values.PBrake.Value = true

		-- Remove Wheel Force
		for _, data in Wheels do
			if data.AV then
				data.AV.MotorMaxTorque = 0
				data.AV.AngularVelocity = 0
			end
			if data.BV then
				if ParkingGearEnabled then
					_CGear = -2
				else
					_PBrake = true
				end

				-- Parking brake on exit locks every wheel; keep PBrakeBias for handbrake while driving.
				local exitBrakeTorque = _Tune.PBrakeForce * 9.80665 * Units.Force_N
				data.BV.MotorMaxTorque = _Tune.ExitBrake and exitBrakeTorque or 0
			end
		end

		-- Reintroduce touch controls
		if _Tune.Mobile then
			GuiService.TouchControlsEnabled = true
		end

		-- Tell server to remove
		if tuneFolder and tuneFolder:FindFirstChild("Shutdown") then
			tuneFolder.Shutdown:FireServer()
		end
	end
end)

-- Controls
local Controls = script.Parent:FindFirstChild("Controls") :: Folder
if not Controls then
	Controls = Instance.new("Folder")
	Controls.Name = "Controls"
	Controls.Parent = script.Parent
end

local _CTRL = _Tune.Controls
for i, v in _CTRL do
	local a = Instance.new("StringValue")
	a.Name = i
	a.Value = v.Name
	a.Changed:Connect(function(value: string)
		if i == "MouseThrottle" or i == "MouseBrake" then
			if value == "MouseButton1" or value == "MouseButton2" then
				_CTRL[i] = Enum.UserInputType[value]
			else
				_CTRL[i] = Enum.KeyCode[value]
			end
		else
			_CTRL[i] = Enum.KeyCode[value]
		end
	end)
	a.Parent = Controls
end

-- Deadzone Adjust
local _PPH = _Tune.Peripherals
for i, v in _PPH do
	local a = Instance.new("IntValue")
	a.Name = i
	a.Value = v
	a.Changed:Connect(function(value: number)
		a.Value = math.min(100, math.max(0, value))
		_PPH[i] = value
	end)
	a.Parent = Controls
end

-- Input Handler
local function DealWithInput(input: InputObject, gameProcessed: boolean)
	if
		input.KeyCode == Enum.KeyCode.None
		and not (input.UserInputType and string.find(input.UserInputType.Name, "Gamepad"))
	then
		return
	end
	if not ChatInputBarConfiguration.IsFocused and not UserInputService:GetFocusedTextBox() and not _InControls then
		-- Shift Down [Manual Transmission]
		if
			(
				input.KeyCode == _CTRL["ContlrShiftDown"]
				or (_MSteer and input.KeyCode == _CTRL["MouseShiftDown"])
				or ((not _MSteer) and input.KeyCode == _CTRL["ShiftDown"])
			)
			and ((_IsOn and ((_TMode == "Auto" and _CGear <= 1) and _Tune.AutoShiftVers == "New") or _TMode == "Semi") or _TMode == "Manual")
			and input.UserInputState == Enum.UserInputState.Begin
		then
			-- Shift removed

			-- Shift Up [Manual Transmission]
		elseif
			(
				input.KeyCode == _CTRL["ContlrShiftUp"]
				or (_MSteer and input.KeyCode == _CTRL["MouseShiftUp"])
				or ((not _MSteer) and input.KeyCode == _CTRL["ShiftUp"])
			)
			and ((_IsOn and ((_TMode == "Auto" and _CGear < 1) and _Tune.AutoShiftVers == "New") or _TMode == "Semi") or _TMode == "Manual")
			and input.UserInputState == Enum.UserInputState.Begin
		then
			-- Shift removed

			-- Toggle Clutch
		elseif
			(
				input.KeyCode == _CTRL["ContlrClutch"]
				or (_MSteer and input.KeyCode == _CTRL["MouseClutch"])
				or ((not _MSteer) and input.KeyCode == _CTRL["Clutch"])
			) and _TMode == "Manual"
		then
			if input.UserInputState == Enum.UserInputState.Begin then
				_ClPressing = true
				_PlayerClutch = true
			elseif input.UserInputState == Enum.UserInputState.End then
				_ClPressing = false
				_PlayerClutch = false
			end

			-- Toggle PBrake
		elseif
			input.KeyCode == _CTRL["ContlrPBrake"]
			or (_MSteer and input.KeyCode == _CTRL["MousePBrake"])
			or ((not _MSteer) and input.KeyCode == _CTRL["PBrake"])
			or ((not _MSteer) and input.KeyCode == _CTRL["PBrake2"])
		then
			if input.UserInputState == Enum.UserInputState.Begin then
				_PBrake = not _PBrake
			elseif input.UserInputState == Enum.UserInputState.End then
				if _Velocity.Magnitude > 5 then
					_PBrake = false
				end
			end

			-- Keep the transmission automatic; legacy toggle inputs must not enable manual mode.
		elseif
			(input.KeyCode == _CTRL["ContlrToggleTMode"] or input.KeyCode == _CTRL["ToggleTransMode"])
			and input.UserInputState == Enum.UserInputState.Begin
		then
			_TMode = "Auto"

			-- Throttle
		elseif
			((not _MSteer) and (input.KeyCode == _CTRL["Throttle"] or input.KeyCode == _CTRL["Throttle2"]))
			or (
				(
					(
						(
							_CTRL["MouseThrottle"] == Enum.UserInputType.MouseButton1
							or _CTRL["MouseThrottle"] == Enum.UserInputType.MouseButton2
						) and input.UserInputType == _CTRL["MouseThrottle"]
					) or input.KeyCode == _CTRL["MouseThrottle"]
				) and _MSteer
			)
		then
			if input.UserInputState == Enum.UserInputState.Begin then
				_IThrot = 1
			else
				_IThrot = 0
			end

			-- Brake
		elseif
			((not _MSteer) and (input.KeyCode == _CTRL["Brake"] or input.KeyCode == _CTRL["Brake2"]))
			or (
				(
					(
						(
							_CTRL["MouseBrake"] == Enum.UserInputType.MouseButton1
							or _CTRL["MouseBrake"] == Enum.UserInputType.MouseButton2
						) and input.UserInputType == _CTRL["MouseBrake"]
					) or input.KeyCode == _CTRL["MouseBrake"]
				) and _MSteer
			)
		then
			if input.UserInputState == Enum.UserInputState.Begin then
				_IBrake = 1
			else
				_IBrake = 0
			end

			-- Steer Left
		elseif (not _MSteer) and (input.KeyCode == _CTRL["SteerLeft"] or input.KeyCode == _CTRL["SteerLeft2"]) then
			if input.UserInputState == Enum.UserInputState.Begin then
				_GSteerT = -1
				_SteerL = true
			else
				if _SteerR then
					_GSteerT = 1
				else
					_GSteerT = 0
				end
				_SteerL = false
			end

			-- Steer Right
		elseif (not _MSteer) and (input.KeyCode == _CTRL["SteerRight"] or input.KeyCode == _CTRL["SteerRight2"]) then
			if input.UserInputState == Enum.UserInputState.Begin then
				_GSteerT = 1
				_SteerR = true
			else
				if _SteerL then
					_GSteerT = -1
				else
					_GSteerT = 0
				end
				_SteerR = false
			end

			-- Toggle Mouse Controls (Disabled so mouse clicks never disable W/A/S/D)
		elseif false and input.KeyCode == _CTRL["ToggleMouseDrive"] then
			if input.UserInputState == Enum.UserInputState.End then
				MouseSteerValue.Value = false
				_IThrot = 0
				_IBrake = 0
				_GSteerT = 0
			end

			-- Toggle TCS and ESC
		elseif
			_Tune.TCSEnabled
			and _IsOn
			and (input.KeyCode == _CTRL["ToggleTCS"] or input.KeyCode == _CTRL["ContlrToggleTCS"])
		then
			if input.UserInputState == Enum.UserInputState.End then
				if _Tune.ESCEnabled then
					if _TCS and _ESC then
						_ESC = false
					elseif _TCS and not _ESC then
						_TCS = false
					elseif not _TCS and not _ESC then
						_TCS = true
						_ESC = true
					end
				else
					_TCS = not _TCS
				end
			end

			-- Toggle ABS
		elseif
			_Tune.ABSEnabled
			and _IsOn
			and (input.KeyCode == _CTRL["ToggleABS"] or input.KeyCode == _CTRL["ContlrToggleABS"])
		then
			if input.UserInputState == Enum.UserInputState.End then
				_ABS = not _ABS
			end

			-- Toggle CS
		elseif
			_Tune.CSEnabled
			and _IsOn
			and (input.KeyCode == _CTRL["ToggleCS"] or input.KeyCode == _CTRL["ContlrToggleCS"])
		then
			if input.UserInputState == Enum.UserInputState.End then
				_CS = not _CS
			end
		end

		-- Variable Controls
		if input.UserInputType and input.UserInputType.Name:find("Gamepad") then
			-- Gamepad Steering
			if input.KeyCode == _CTRL["ContlrSteer"] then
				if input.Position.X >= 0 then
					local cDZone = math.min(0.99, _Tune.Peripherals.ControlRDZone / 100)
					if math.abs(input.Position.X) > cDZone then
						_GSteerT = (input.Position.X - cDZone) / (1 - cDZone)
					else
						_GSteerT = 0
					end
				else
					local cDZone = math.min(0.99, _Tune.Peripherals.ControlLDZone / 100)
					if math.abs(input.Position.X) > cDZone then
						_GSteerT = (input.Position.X + cDZone) / (1 - cDZone)
					else
						_GSteerT = 0
					end
				end

				-- Gamepad Throttle
			elseif input.KeyCode == _CTRL["ContlrThrottle"] then
				_IThrot = math.max(0, input.Position.Z)

				-- Gamepad Brake
			elseif input.KeyCode == _CTRL["ContlrBrake"] then
				_IBrake = input.Position.Z
			end
		end
	else
		_IThrot = 0
		_GSteerT = 0
		_IBrake = 0
	end
end

UserInputService.InputBegan:Connect(DealWithInput)
-- ArcadeJump on Spacebar removed
UserInputService.InputChanged:Connect(DealWithInput)
UserInputService.InputEnded:Connect(DealWithInput)
VirtualInput.Event:Connect(DealWithInput)

local function DealWithMobileInput()
	local mobile = script.Parent.Mobile

	mobile.Jump.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
	end)

	mobile.ModeSwitch.MouseButton1Click:Connect(function()
		MobileMode = MobileModes[(table.find(MobileModes, MobileMode) or 0) + 1]
		if not MobileMode then
			MobileMode = MobileModes[1]
		end
	end)

	-- Tap
	for _, button in mobile.Tap:GetChildren() do
		if not button:IsA("ImageButton") then
			continue
		end
		button.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			button.ImageColor3 = Color3.fromRGB(178, 178, 178)
			button.ImageLabel.ImageColor3 = Color3.new(0, 0, 0)
			button.ImageLabel.ImageTransparency = 0.5
			if button.Name == "Throttle" then
				_IThrot = 1
			elseif button.Name == "Brake" then
				_IBrake = 1
			elseif button.Name == "Left" then
				_GSteerT = -1
				_SteerL = true
			elseif button.Name == "Right" then
				_GSteerT = 1
				_SteerR = true
			end
		end)
		button.InputEnded:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			button.ImageColor3 = Color3.new(0, 0, 0)
			button.ImageLabel.ImageColor3 = Color3.new(1, 1, 1)
			button.ImageLabel.ImageTransparency = 0.8
			if button.Name == "Throttle" then
				_IThrot = 0
			elseif button.Name == "Brake" then
				_IBrake = 0
			elseif button.Name == "Left" then
				if _SteerR then
					_GSteerT = 1
				else
					_GSteerT = 0
				end
				_SteerL = false
			elseif button.Name == "Right" then
				if _SteerL then
					_GSteerT = -1
				else
					_GSteerT = 0
				end
				_SteerR = false
			end
		end)
	end

	-- Tilt
	for _, button in mobile.Tilt:GetChildren() do
		if not button:IsA("TextButton") then
			continue
		end
		button.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			if button.Name == "Throttle" then
				_IThrot = 1
			elseif button.Name == "Brake" then
				_IBrake = 1
			end
		end)
		button.InputEnded:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			if button.Name == "Throttle" then
				_IThrot = 0
			elseif button.Name == "Brake" then
				_IBrake = 0
			end
		end)
	end
	if UserInputService.GyroscopeEnabled then
		UserInputService.DeviceRotationChanged:Connect(function(rotation, cframe)
			if MobileMode == "Tilt" then
				_GSteerT = -math.clamp(rotation.Position.Z * 2, -1, 1)
			end
		end)
	end
end

if _Tune.Mobile then
	DealWithMobileInput()
end

local _SeatSteerActive = false

-- Throttle and Brake Input Smoothing + CDT Tap-to-Drift Engine
local function Inputs(dt: number)
	local deltaTime = dt * 60
	local seatThrot = getEffectiveSeatThrottle()
	local seatSteer = getEffectiveSeatSteer()
	local boostNow = isBoostActive()

	-- Direct native sync: Ensure Roblox seat ThrottleFloat & SteerFloat feed into A-Chassis
	if seatThrot > 0.05 then
		_IThrot = math.clamp(seatThrot, 0, 1)
		_IBrake = 0
	elseif seatThrot < -0.05 then
		_IBrake = math.clamp(-seatThrot, 0, 1)
		_IThrot = 0
	elseif math.abs(seatThrot) <= 0.05 and not _InControls then
		-- When player releases seat controls without custom keys held, reset
		if
			_IThrot > 0
			and not UserInputService:IsKeyDown(Enum.KeyCode.W)
			and not UserInputService:IsKeyDown(Enum.KeyCode.Up)
		then
			_IThrot = 0
		end
		if
			_IBrake > 0
			and not UserInputService:IsKeyDown(Enum.KeyCode.S)
			and not UserInputService:IsKeyDown(Enum.KeyCode.Down)
		then
			_IBrake = 0
		end
	end

	local desiredBrake = math.max(_IBrake, math.clamp(-seatThrot, 0, 1))
	local desiredThrottle = math.max(_IThrot, math.clamp(seatThrot, 0, 1))
	if boostNow and desiredBrake < 0.05 then
		desiredThrottle = 1
	end

	if not _SteerL and not _SteerR and not _MSteer then
		if math.abs(seatSteer) > 0.05 then
			_SeatSteerActive = true
			_GSteerT = math.clamp(seatSteer, -1, 1)
		elseif _SeatSteerActive then
			_SeatSteerActive = false
			_GSteerT = 0
		end
	else
		_SeatSteerActive = false
	end
	if _InThrot <= desiredThrottle then
		_InThrot = math.min(desiredThrottle, _InThrot + (_Tune.ThrotAccel * deltaTime))
	else
		_InThrot = math.max(desiredThrottle, _InThrot - (_Tune.ThrotDecel * deltaTime))
	end
	if _InBrake <= desiredBrake then
		_InBrake = math.min(desiredBrake, _InBrake + (_Tune.BrakeAccel * deltaTime))
	else
		_InBrake = math.max(desiredBrake, _InBrake - (_Tune.BrakeDecel * deltaTime))
	end

	-- Immediate launch: release parking brake on throttle or brake
	if
		_PBrake
		and not _SpaceHeld
		and not _TapDriftActive
		and (_InThrot > 0.05 or _IBrake > 0.05 or desiredThrottle > 0.05 or desiredBrake > 0.05)
	then
		_PBrake = false
	end

	-- CDT Tap-to-Drift Architecture (Fixed _GSteerC & Non-Blocking Service Brake):
	local currentBrake = _IBrake
	local now = os.clock()
	local forwardSpeed = _Velocity:Dot(car.DriveSeat.CFrame.LookVector)
	local isSteering = (math.abs(_GSteerT) > 0.15 or _SteerL or _SteerR or math.abs(_GSteerC) > 0.10)

	-- Edge 1: Brake Pressed (0 -> >=0.1)
	if _PrevIBrake < 0.1 and currentBrake >= 0.1 then
		_BrakePressTimestamp = now
		local _tapAllowed = (_Tune.TapDriftEnabled ~= false)
		if car:GetAttribute("TapDriftEnabled") ~= nil then
			_tapAllowed = (car:GetAttribute("TapDriftEnabled") == true)
		end
		local _minSpeed = _Tune.TapDriftMinSpeed or 16
		if _tapAllowed and forwardSpeed > _minSpeed and isSteering then
			_EligibleForTapDrift = true
		else
			_EligibleForTapDrift = false
		end
	-- Edge 2: Brake Released (>=0.1 -> <0.1)
	elseif _PrevIBrake >= 0.1 and currentBrake < 0.1 then
		local holdDuration = now - _BrakePressTimestamp
		local _tapMaxHold = _Tune.TapDriftTapDuration or 0.35
		local _minSpeedCheck = (_Tune.TapDriftMinSpeed or 16) - 3
		if _EligibleForTapDrift and holdDuration <= _tapMaxHold and forwardSpeed > _minSpeedCheck and isSteering then
			-- Quick Tap confirmed! Sustain drift powerslide through the apex
			_TapDriftActive = true
			_DriftEndTime = now + (_Tune.TapDriftMaxDuration or 1.25)
			_StraightenTimer = 0
		else
			-- Held longer than tap (normal stopping brake), terminate drift
			_TapDriftActive = false
		end
		_EligibleForTapDrift = false
	end
	_PrevIBrake = currentBrake

	-- Active Drift Lifecycle Management
	if _TapDriftActive then
		-- If player presses brake again to slow down/stop, vehicle speed dropped, or drift expired
		if currentBrake >= 0.1 or forwardSpeed < 12 or now > _DriftEndTime then
			_TapDriftActive = false
		-- If player straightened out steering after the corner
		elseif not isSteering then
			_StraightenTimer = _StraightenTimer + dt
			if _StraightenTimer > 0.22 then
				_TapDriftActive = false
			end
		else
			_StraightenTimer = 0
		end
	end
end

-- Steering
local function applyServoSteerTarget(data, targetAngle: number, steerActive: boolean, maxLimit: number)
	local rotate = data.Rotate
	if not rotate then
		return
	end
	local straightLock = data.StraightLock
	local curAngle = rotate.CurrentAngle
	if steerActive or math.abs(targetAngle) > 0.05 then
		if straightLock then
			straightLock.Enabled = false
		end
		rotate.LowerAngle = math.clamp(math.min(curAngle, targetAngle) - 0.15, -maxLimit, maxLimit)
		rotate.UpperAngle = math.clamp(math.max(curAngle, targetAngle) + 0.15, -maxLimit, maxLimit)
		rotate.TargetAngle = targetAngle
		return
	end

	rotate.TargetAngle = 0
	if math.abs(curAngle) <= 0.45 then
		rotate.LowerAngle = 0
		rotate.UpperAngle = 0
		if straightLock then
			straightLock.Enabled = true
		end
	else
		if straightLock then
			straightLock.Enabled = false
		end
		rotate.LowerAngle = math.clamp(math.min(curAngle, 0), -maxLimit, maxLimit)
		rotate.UpperAngle = math.clamp(math.max(curAngle, 0), -maxLimit, maxLimit)
	end
end

local arcadeWheelSteer = 0
local function Steering(dt: number)
	if _Tune.ArcadeSteering then
		-- Chassis yaw remains the steering source; a small front-wheel angle adds visual feedback.
		_GSteerC = _MidAirActive and 0 or math.clamp(_GSteerT, -1, 1)
		_CSAmt = 0
		_CSActive = false
		local visualResponse = 1 - math.exp(-14 * dt)
		arcadeWheelSteer = _MidAirActive and 0 or arcadeWheelSteer + (_GSteerC - arcadeWheelSteer) * visualResponse
		local speedKmh = _Velocity.Magnitude / (Units.Velocity_mdivs / 3.6)
		local speedRatio = math.clamp(speedKmh / math.max(_Tune.ArcadeSteerFullSpeedKmh, 1), 0, 1)
		local visualAngle = _Tune.ArcadeVisualWheelAngleLow
			+ (_Tune.ArcadeVisualWheelAngleHigh - _Tune.ArcadeVisualWheelAngleLow) * speedRatio
		local wheelMag = math.clamp(visualAngle, 0, _Tune.SteerInner or visualAngle)
		local ackermannRatio = (_Tune.SteerInner and _Tune.SteerInner > 0 and _Tune.SteerOuter)
				and math.clamp(_Tune.SteerOuter / _Tune.SteerInner, 0.72, 1)
			or 0.86
		local maxLimit = math.max(_Tune.SteerOuter or 0, _Tune.SteerInner or 0, wheelMag, 1)
		local steerActive = (
			math.abs(_GSteerT) > 0.01
			or math.abs(_GSteerC) > 0.01
			or math.abs(arcadeWheelSteer) > 0.01
		)
		for _, data in Wheels do
			if data.CanSteer ~= 0 then
				local sideRatio = 1
				if data.isFront then
					if data.Name == "FL" then
						sideRatio = arcadeWheelSteer < 0 and 1 or ackermannRatio
					elseif data.Name == "FR" then
						sideRatio = arcadeWheelSteer > 0 and 1 or ackermannRatio
					end
				end
				local angle = data.isFront and arcadeWheelSteer * wheelMag * sideRatio or 0
				if _Tune.PowerSteeringType == "Servo" and data.Rotate then
					applyServoSteerTarget(data, -angle, steerActive, maxLimit)
				elseif _Tune.PowerSteeringType == "New" then
					data.SteerAttach0.Orientation = Vector3.new(0, angle, 0)
				else
					data.Steer.CFrame = data.Base.CFrame * CFrame.Angles(0, -math.rad(angle), 0)
				end
			end
		end
		return
	end
	local deltaTime = dt * 60

	local SteerOuter = _Tune.SteerOuter
	local SteerInner = _Tune.SteerInner
	if _Tune.SteeringType == "Auto" or _Tune.SteeringType == nil then
		SteerOuter = (_Tune.LockToLock * 180) / _Tune.SteerRatio
		SteerInner = math.min(SteerOuter - (SteerOuter * (1 - _Tune.Ackerman)), SteerOuter * 1.2)
	end

	local controller = LastInputWasGamepad or (_Tune.MSteerUsesContlr and _MSteer or false)
	local SteerSpeed = controller and (_Tune.ContlrSteerSpeed > 0 and _Tune.ContlrSteerSpeed or _Tune.Steerspeed)
		or _Tune.SteerSpeed
			* (1 - math.min(
				_Velocity.Magnitude / (Units.Velocity_mdivs / 3.6) / _Tune.SteerSpeedDecay,
				1 - (_Tune.MinSteerSpeed / 100)
			))
	local ReturnSpeed = controller and (_Tune.ContlrReturnSpeed > 0 and _Tune.ContlrReturnSpeed or _Tune.ReturnSpeed)
		or _Tune.ReturnSpeed
			* (1 - math.min(
				_Velocity.Magnitude / (Units.Velocity_mdivs / 3.6) / _Tune.SteerSpeedDecay,
				1 - (_Tune.MinSteerSpeed / 100)
			))

	if _MSteer then
		local msWidth = math.max(1, mouse.ViewSizeX * _Tune.Peripherals.MSteerWidth / 200)
		local mdZone = _Tune.Peripherals.MSteerDZone / 100
		local mST = ((mouse.X - mouse.ViewSizeX / 2) / msWidth)
		if math.abs(mST) <= mdZone then
			_GSteerT = 0
		else
			_GSteerT = (math.max(math.min((math.abs(mST) - mdZone), (1 - mdZone)), 0) / (1 - mdZone)) ^ _Tune.MSteerExp
				* (mST / math.abs(mST))
		end
	end

	-- Interpolate Steering (ignore tiny lateral micro-slip when driving straight so CounterSteer doesn't pull)
	local localSideSpeed = _Center:VectorToObjectSpace(_Velocity):Dot(Vector3.new(1, 0, 0))
	if
		math.abs(_GSteerT) < _Tune.CSSteerThresh / 100
		and _CS
		and _Velocity.Magnitude * (Units.Length_mm / 1000) * 3.6 > _Tune.CSSpeedThresh
		and (_TapDriftActive or math.abs(localSideSpeed) >= 8)
	then
		_CSAmt = (localSideSpeed / math.max(_Velocity.Magnitude * (Units.Length_mm / 1000) * 3.6, _Tune.CSSpeedThresh))
			* (_Tune.CSAmt / 100)
	else
		_CSAmt = 0
	end
	if math.abs(_CSAmt) > (_Tune.CSAmt / 100) * 0.01 then
		_CSActive = true
	else
		_CSActive = false
	end
	local SteerWithCounter = math.clamp(_GSteerT + _CSAmt, -1, 1)
	local SteerSmoothing =
		math.clamp(math.abs(SteerWithCounter - _GSteerC) ^ (1 / math.max(_Tune.SteerSmoothing, 0.001)), 0, 1)
	if _GSteerC < SteerWithCounter then
		if _GSteerC < 0 then
			_GSteerC = math.min(SteerWithCounter, _GSteerC + (ReturnSpeed * SteerSmoothing * deltaTime))
		else
			_GSteerC = math.min(SteerWithCounter, _GSteerC + (SteerSpeed * SteerSmoothing * deltaTime))
		end
	else
		if _GSteerC > 0 then
			_GSteerC = math.max(SteerWithCounter, _GSteerC - (ReturnSpeed * SteerSmoothing * deltaTime))
		else
			_GSteerC = math.max(SteerWithCounter, _GSteerC - (SteerSpeed * SteerSmoothing * deltaTime))
		end
	end

	-- Steer Decay Multiplier
	local sDecay = (
		1
		- math.min(
			_Velocity.Magnitude / (Units.Velocity_mdivs / 3.6) / (_Tune.SteerDecay / (Units.Velocity_mdivs / 3.6)),
			1 - (_Tune.MinSteer / 100)
		)
	)
	local rsDecay = (
		1
		- math.min(
			_Velocity.Magnitude / (Units.Velocity_mdivs / 3.6) / (_Tune.RSteerDecay / (Units.Velocity_mdivs / 3.6)),
			1 - (_Tune.MinSteer / 100)
		)
	)

	-- Apply Steering
	for _, data in Wheels do
		if data.CanSteer == 0 then
			continue
		end

		local angle = 0
		local rsteerVariableAngle = 1
		if data.CanSteer == 2 then
			if data.Name == "FL" then
				angle = (_GSteerC < 0 and SteerInner or SteerOuter) * sDecay
			elseif data.Name == "FR" then
				angle = (_GSteerC < 0 and SteerOuter or SteerInner) * sDecay
			elseif data.Name == "F" then
				angle = SteerInner * sDecay
			elseif data.Name == "RL" then
				angle = (_GSteerC < 0 and _Tune.RSteerInner or _Tune.RSteerOuter) * rsDecay
			elseif data.Name == "RR" then
				angle = (_GSteerC < 0 and _Tune.RSteerOuter or _Tune.RSteerInner) * rsDecay
			elseif data.Name == "R" then
				angle = _Tune.RSteerInner * rsDecay
			end
			if not data.isFront then
				if _Tune.FWSteer == "Static" then
					rsteerVariableAngle = -math.max(0, 1 - (_Velocity.Magnitude / _Tune.RSteerSpeed))
				elseif _Tune.FWSteer == "Speed" then
					rsteerVariableAngle = math.min(1, (_Velocity.Magnitude / _Tune.RSteerSpeed))
				elseif _Tune.FWSteer == "Both" then
					rsteerVariableAngle = -math.max(-1, 1 - (_Velocity.Magnitude / _Tune.RSteerSpeed))
				end
			end
		end

		if _Tune.PowerSteeringType == "Servo" and data.Rotate then
			local targetAngle = data.CanSteer == 1 and 0 or -(_GSteerC * angle * rsteerVariableAngle)
			local maxLimit = math.max(SteerOuter, SteerInner, 1)
			local steerActive = (math.abs(_GSteerT) > 0.01 or math.abs(_GSteerC) > 0.01)
			applyServoSteerTarget(data, targetAngle, steerActive, maxLimit)
		elseif _Tune.PowerSteeringType == "New" then
			data.SteerAttach0.Orientation =
				Vector3.new(0, data.CanSteer == 1 and 0 or _GSteerC * angle * rsteerVariableAngle, 0)
		else
			data.Steer.CFrame = data.Base.CFrame
				* (
					data.CanSteer == 1 and CFrame.new(0, 0, 0)
					or (CFrame.Angles(0, -math.rad(_GSteerC * angle * rsteerVariableAngle), 0))
				)
		end
	end
end

-- Engine
-- Electric Only Setup
if not _Tune.Engine and _Tune.Electric then
	_Tune.Redline = _Tune.E_Redline
	_Tune.ShiftRPM = _Tune.E_Redline
	_Tune.Turbochargers = 0
	_Tune.Superchargers = 0
	_Tune.Clutch = false
	_Tune.IdleRPM = 0
	_Tune.IdleThrottle = 0
	_Tune.ClutchType = "Clutch"
	_Tune.AutoShiftType = "DCT"
end

-- Automatic Transmission
local function Auto()
	if not _IsOn then
		return
	end

	local fFD = _Tune.FinalDrive * _Tune.FDMult
	local fFDr = fFD * 30 / math.pi

	local forwardSpeed = _Velocity:Dot(car.DriveSeat.CFrame.LookVector)
	local seatThrot = getEffectiveSeatThrottle()
	local activeThrot = math.max(_IThrot, _InThrot, math.clamp(seatThrot, 0, 1))
	local activeBrake = math.max(_IBrake, _InBrake, math.clamp(-seatThrot, 0, 1))

	if _Tune.AutoShiftVers == "Old" and (_CGear == 0 or (ParkingGearEnabled and _CGear == -2)) then
		if activeBrake > 0.1 and activeThrot < 0.1 then
			_CGear = -1
		else
			_CGear = 1
		end
		_ClPressing = false
	end

	-- Return to 1st gear when slowed down so reverse or launch is always ready immediately
	if
		_Tune.AutoShiftVers == "Old"
		and _CGear > 1
		and _Velocity.Magnitude < 10
		and not _Shifting
		and not _ShiftUp
		and not _ShiftDn
	then
		_CGear = 1
		_ClPressing = false
	end

	if _CGear >= 1 then
		-- Engage Reverse smoothly as soon as forward speed drops low and player holds S (Brake) without W
		if (activeBrake > 0.1 and activeThrot < 0.1 and forwardSpeed < 8) and _Tune.AutoShiftVers == "Old" then
			_CGear = -1
			_ClPressing = false
			_Shifting = false
			_ShiftUp = false
			_ShiftDn = false
		elseif _Velocity.Magnitude > 5 and _Tune.ClutchType ~= "CVT" then
			if _Tune.AutoShiftMode == "RPM" then
				if _RPM > (_Tune.ShiftRPM + _Tune.AutoUpThresh) then
					if not _ShiftUp and not _Shifting then
						_ShiftUp = true
					end
				elseif
					math.max(
							math.min(
								_MaxWheelSpin * _Tune.Ratios[_CGear + 1 + ParkingGearOffset] * fFDr,
								_Tune.Redline + 100
							),
							0
						)
						< (_Tune.ShiftRPM - _Tune.AutoDownThresh)
					and _CGear > 1
				then
					if not _ShiftDn and not _Shifting then
						_ShiftDn = true
					end
				end
			else
				if
					_Velocity.Magnitude
					> math.ceil(wDRatio * (_Tune.ShiftRPM + _Tune.AutoUpThresh) / _CurrentRatio / fFD)
				then
					if not _ShiftUp and not _Shifting then
						_ShiftUp = true
					end
				elseif
					_Velocity.Magnitude
						< math.ceil(
							wDRatio
								* (_Tune.ShiftRPM - _Tune.AutoDownThresh)
								/ _Tune.Ratios[_CGear + 1 + ParkingGearOffset]
								/ fFD
						)
					and _CGear > 1
				then
					if not _ShiftDn and not _Shifting then
						_ShiftDn = true
					end
				end
			end
		end
	else
		-- Engage Forward 1st gear immediately when player presses W (Throttle) from Reverse or Neutral
		if (activeThrot > 0.1 and forwardSpeed > -14) and _Tune.AutoShiftVers == "Old" then
			_CGear = 1
			_ClPressing = false
			_Shifting = false
			_ShiftUp = false
			_ShiftDn = false
		end
	end
end

local function Gear()
	local _fFDr = (_Tune.FinalDrive * _Tune.FDMult) * 30 / math.pi

	if _ShiftUp and not _Shifting then
		if
			(_TMode == "Manual" and not _ClPressing)
			or (_TMode == "Manual" and _Tune.ClutchRel and (_InThrot > 0))
			or _CGear == #_Tune.Ratios - 2 - ParkingGearOffset
			or (_TMode ~= "Manual" and not _IsOn)
		then
			_ShiftUp = false
			return
		end
		local NextGear = math.min(_CGear + 3 + ParkingGearOffset, #_Tune.Ratios)
		-- Arcade Auto shifts immediately; do not disengage the clutch or wait on RPM.
		-- This keeps drive torque continuous through the gear change.
		_ShiftUp = false
		_Shifting = false
		if _TMode ~= "Manual" and not _IsOn then
			return
		end
		if NextGear > 3 + ParkingGearOffset and _Tune.ClutchType == "CVT" then
			return
		end
		_CGear = math.min(_CGear + 1, #_Tune.Ratios - 2 - ParkingGearOffset)
		if _TMode ~= "Manual" or (_CGear == 1 and _IsOn) then
			_ClPressing = (_TMode == "Manual" and _PlayerClutch) or false
		end
	end

	if _ShiftDn and not _Shifting then
		if
			(_TMode == "Manual" and not _ClPressing)
			or _CGear == -1 - ParkingGearOffset
			or (_TMode ~= "Manual" and not _IsOn)
		then
			_ShiftDn = false
			return
		end
		local _PrevGear = math.min(_CGear + 1 + ParkingGearOffset, #_Tune.Ratios)
		-- Arcade Auto downshifts immediately without clutch-cut or RPM delay.
		_ShiftDn = false
		_Shifting = false
		if _TMode ~= "Manual" and not _IsOn then
			return
		end
		_CGear = math.max(_CGear - 1, _Velocity.Magnitude > 5 and -1 or -2)
		if _TMode ~= "Manual" or (_CGear == -1 and _IsOn) then
			_ClPressing = (_TMode == "Manual" and _PlayerClutch) or false
		end
	end
end

local goalRPM = 0
local tqTCS = 1
local stallOk = false
local ticc = tick()

-- Power calculation prerequesites
local function f(m: number, n: number, p: number, q: number, M: number, b: number, x: number): number
	return math.clamp(M - ((q - n) / (b ^ p - b ^ m) * (b ^ x - b ^ m) + n), 0, M)
end

-- Apply Power
local function Engine(dt: number)
	local deltaTime = dt * 60

	local fFD = _Tune.FinalDrive * _Tune.FDMult
	local fFDr = fFD * 30 / math.pi
	local cGrav = (_Tune.GravComp > 0 and _Tune.GravComp or workspace.Gravity) * _Tune.InclineComp / 35

	local _WheelRPM = _DriveWheelSpeed * _CurrentRatio * fFDr

	-- CVT
	if _Tune.ClutchType == "CVT" then
		local denom = _DriveWheelSpeed * fFDr
		local targetRPM = _Tune.IdleRPM + (_Tune.CVTRPM - _Tune.IdleRPM) * _GThrot
		if math.abs(denom) > 1e-6 then
			_CVTRatio = math.clamp(targetRPM / denom, _Tune.CVTMinRatio, _Tune.CVTMaxRatio)
		else
			_CVTRatio = _Tune.CVTMaxRatio
		end
	end

	-- Update ratio
	_CurrentRatio = _Tune.ClutchType == "CVT" and _CVTRatio or _Tune.Ratios[_CGear + 2 + ParkingGearOffset]
	_spLimit = _Tune.Redline / (fFDr * _CurrentRatio)
	if _CurrentRatio * fFDr == 0 then
		_spLimit = 0
	end -- Prevents [nan] from dividing by 0

	-- Flywheel/clutch-dumping
	_FlywheelEnergy = math.max((_RPM - _WheelRPM) * _Tune.DumpMult, 0) * (1 - _Clutch) * 1.356 * Units.Torque_nm

	-- Determine RPM
	local revMin = 0
	local goalMin = 0
	local goalMax = _Tune.Redline

	if _Shifting and _ShiftUp then
		_GThrot = _Tune.IdleThrottle / 100
	elseif _Shifting and _ShiftDn then
		_GThrot = _Tune.ShiftThrot / 100
	else
		if _Tune.AutoShiftVers == "Old" and _CGear == -1 and _TMode == "Auto" then
			_GThrot = _InBrake
		else
			_GThrot = math.max(_InThrot, _Tune.IdleThrottle / 100)
		end
	end

	if _Tune.AutoShiftVers == "Old" and _CGear == -1 and _TMode == "Auto" then
		_GBrake = _InThrot
	else
		_GBrake = _InBrake
	end

	-- Release the exit parking brake when the driver commands the current drive direction.
	-- Old Auto uses S/IBrake as throttle while reversing and W/IThrot while moving forward.
	local reversing = _Tune.AutoShiftVers == "Old" and _CGear == -1 and _TMode == "Auto"
	local driveCommand = reversing and _IBrake or _IThrot
	if
		_PBrake
		and not _SpaceHeld
		and not _TapDriftActive
		and (driveCommand > 0.05 or _InThrot > 0.05 or _InBrake > 0.05 or _IThrot > 0.05 or _IBrake > 0.05)
	then
		_PBrake = false
	end

	if not _IsOn then
		ticc = tick()
		if _AutoClutch then
			_Clutch = 1
		end
		_GThrot = 0
	end
	if car:GetAttribute("VehiclePowerDisabled") == true then
		_GThrot = 0
	end

	if
		((_ClPressing and (_CGear == 0 or (ParkingGearEnabled and _CGear == -2))) or (_PlayerClutch and _CGear ~= 0))
		and _Tune.NeutralLimit
	then
		if ((_CGear == 0 or (ParkingGearEnabled and _CGear == -2)) and not _Tune.LimitClutch) or _Tune.LimitClutch then
			goalMax = _Tune.NeutralRevRPM
		end
	end

	-- Rev limiter/speed limiter
	if _RPM >= _Tune.Redline then
		_RevLimiting = true
	elseif _RPM < goalMax - _Tune.RevBounce then
		_RevLimiting = false
	end
	if _RevLimiting then
		_GThrot = _Tune.IdleThrottle / 100
	end

	local boostNow = isBoostActive()
	local forwardLimit = (boostNow and _Tune.BoostMaxSpeedKmh) and math.max(_Tune.SpeedLimit, _Tune.BoostMaxSpeedKmh)
		or _Tune.SpeedLimit
	if stunt and stunt.wallClimbActive and _Tune.SpiderMaxClimbSpeed then
		forwardLimit = math.min(
			forwardLimit > 0 and forwardLimit or 9999,
			(_Tune.SpiderMaxClimbSpeed / (Units.Velocity_mdivs / 3.6)) * (boostNow and 1.45 or 1)
		)
	end
	local limit = (_CGear < 0 and _Tune.ReverseSpeed or forwardLimit)
	if limit > 0 then
		_GThrot = math.min(
			_GThrot,
			math.max(
				1
					- math.clamp(
						((_Velocity.Magnitude / (Units.Velocity_mdivs / 3.6)) - (limit - _Tune.SLimitGradient))
							/ _Tune.SLimitGradient,
						0,
						1
					),
				_Tune.IdleThrottle / 100
			)
		)
		if _Tune.SLimitBrake then
			_GBrake = math.max(
				_GBrake,
				math.clamp((_Velocity.Magnitude / (Units.Velocity_mdivs / 3.6) - limit) / _Tune.SLimitGradient, 0, 1)
			)
		end
	end

	-- Idle
	if _RPM < _Tune.IdleRPM + (_Tune.IdlePadding or 0) and _IsOn then
		_GThrot = math.max(
			_GThrot,
			math.clamp((_Tune.IdleRPM + (_Tune.IdlePadding or 0) - _RPM) / (_Tune.IdleDamping or 400), 0, 1)
		)
	end

	if (_Tune.Engine or _Tune.Electric) and not _Starting then
		goalRPM = math.clamp(
			_RPM
				- (_Tune.RevDecay * deltaTime)
				+ (_Tune.RevAccel * _GThrot * deltaTime)
				- (
					math.clamp(math.max(_RPM - _Tune.IdleRPM, 0) / math.max(_Tune.Redline - _Tune.IdleRPM, 1), 0, 1)
					* _Tune.RevDecayRPM
					* deltaTime
				),
			goalMin,
			goalMax
		)
	end

	-- Starting
	if _Starting then
		goalRPM = math.clamp(goalRPM + _Tune.IgnitionAccel * deltaTime, 0, math.max(_Tune.IgnitionRPM, _WheelRPM))
		IsOnValue.Value = goalRPM > _Tune.IgnitionMinRPM
	end

	-- Set RPM
	local aRPM =
		math.max((goalRPM * (1 - deltaTime) + _WheelRPM * deltaTime) * (1 - _Clutch) + goalRPM * _Clutch, revMin)
	local clutchP = math.min(math.abs(aRPM - _RPM) / (_Tune.Flywheel * deltaTime), 0.9)
	if _ClPressing then
		clutchP = 0
	end
	_RPM = aRPM * (1 - clutchP) + _RPM * clutchP

	if _Tune.OverRev == false and _RPM > _Tune.Redline then
		_RPM = _Tune.Redline
	end

	if _RPM <= (_Tune.IdleRPM / 4) and stallOk and (tick() - ticc >= 0.2) and _Tune.Stall then
		IsOnValue.Value = false
	end

	-- Clutch
	if _Shifting or (_AutoClutch and (_CGear == 0 or (ParkingGearEnabled and _CGear == -2))) then
		_ClPressing = true
		_Clutch = 1
		stallOk = false
	end

	if _Tune.Clutch then
		if _AutoClutch then
			if _Tune.ClutchType == "Clutch" or _Tune.ClutchType == "CVT" then
				if _ClPressing then
					_ClutchKick = 1
				end
				_ClutchKick = _ClutchKick * (_Tune.ClutchEngage / 100)
				local ClRPMInfluence = math.max(_RPM * _Tune.ClutchRPMMult / _Tune.Redline, 0)
				if _Tune.ClutchMode == "New" then
					ClRPMInfluence = 0
				end
				_ClutchModulate = math.min(
					(
						(
							(
								(
									math.max(_Velocity.Magnitude, 0.001)
									/ (Units.Velocity_mdivs / 3.6)
									/ _Tune.SpeedEngage
								) / math.max(math.abs(_CGear), 1)
							) + ClRPMInfluence
						) - _ClutchKick
					),
					1
				)
			elseif _Tune.ClutchType == "TorqueConverter" and _Tune.TQLock then
				if
					(
						_GThrot <= _Tune.IdleThrottle / 100
						and _Velocity.Magnitude / (Units.Velocity_mdivs / 3.6) < _Tune.SpeedEngage
					)
					or (_GThrot > _Tune.IdleThrottle / 100 and (_RPM < _Tune.RPMEngage and _WheelRPM < _Tune.RPMEngage))
				then
					_ClutchModulate = math.min(_ClutchModulate * (_Tune.ClutchEngage / 100), 1)
				else
					_ClutchModulate =
						math.min(_ClutchModulate * (_Tune.ClutchEngage / 100) + (1 - (_Tune.ClutchEngage / 100)), 1)
				end
			elseif _Tune.ClutchType == "TorqueConverter" and not _Tune.TQLock then
				_ClutchModulate = math.min((_RPM / _Tune.Redline) * 0.7, 1)
			end
			if not _ClPressing then
				_Clutch = math.min(1 - _ClutchModulate, 1)
			else
				_Clutch = 1
			end
		else
			if _ClPressing then
				_Clutch = 1
			else
				_Clutch = 0
			end
		end
		stallOk = (_Clutch <= 0.01) or stallOk
	else
		stallOk = false
		if not _ClPressing and not _Shifting then
			_Clutch = 0
		else
			_Clutch = 1
		end
	end

	-- Things that apply the clutch (uses driveCommand so Reverse S is never cut!)
	if
		_AutoClutch
		and (
			_Starting
			or (_Tune.RemoveCreep and _RPM < _Tune.IdleRPM + (_Tune.IdlePadding or 0) and driveCommand < 0.05)
			or (_RevLimiting and _Tune.OverRev == false)
		)
	then
		_Clutch = 1
	end

	-- Torque calculations (Detomiks)
	-- What you see here is mostly just ported over from Desmos.
	if not engine or _Tune.CustomEngineCalculations == false then
		local x = _RPM / 1000
		local NTorque = 0
		local ETorque = 0
		local TTorque = 0
		local STorque = 0
		if _Tune.Engine then
			local NIdleTorque = f(
				_Tune.IdleRPM / 1000,
				_Tune.IdleTorque,
				_Tune.PeakTorqueRPM / 1000,
				_Tune.PeakTorque,
				_Tune.PeakTorque,
				_Tune.IdleTorqueCurve,
				x
			)
			local NRedlineTorque = f(
				_Tune.PeakTorqueRPM / 1000,
				_Tune.PeakTorque,
				_Tune.Redline / 1000,
				_Tune.RedlineTorque,
				_Tune.PeakTorque,
				1 / _Tune.RedlineTorqueCurve,
				x
			)
			local VVL = _Tune.VVLTorque > 0
					and _Tune.VVLTorque - f(
						_Tune.VVLRPM / 1000,
						0,
						(_Tune.VVLRPM + _Tune.VVLTime) / 1000,
						_Tune.VVLTorque,
						_Tune.VVLTorque,
						_Tune.VVLCurve,
						x
					)
				or 0
			local AirPressurePercent = math.exp(
				(-9.80665 * 0.0289644 * (_Center.Y * Units.Length_mm / 1000)) / (8.3142 * (GlobalTemperature + 273.15))
			) -- look up the barometric formula
			NTorque = 1 * (_Tune.PeakTorque - NIdleTorque - NRedlineTorque + VVL) * AirPressurePercent
			_NH, _NT = (NTorque * x) / 5.252, NTorque

			if _Tune.Turbochargers > 0 then
				local _TBoostGoal = _Tune.Turbochargers
					* (
						(_GThrot ^ 3) * (100 / _Tune.T_Size) * ((NTorque * x) / 5.252)
						- f(
							_Tune.IdleRPM / 1000,
							_Tune.T_IdleBoost,
							_Tune.T_PeakRPM / 1000,
							_Tune.T_Boost,
							(_GThrot ^ 3) * (100 / _Tune.T_Size) * ((NTorque * x) / 5.252),
							1 / _Tune.T_Curve,
							x
						)
					)
				if _TBoostGoal > _TBoost then
					_TBoost = _TBoost
						+ math.min(
								_Tune.T_SpoolIncrease * (_TBoostGoal - _TBoost),
								_Tune.T_SpoolIncrease * (10 / _Tune.T_Size) * _Tune.Turbochargers
							)
							* deltaTime -- i should probably base this off of the maximum horsepower instead of the RPM, but it's the same thing anyway
				elseif _TBoost > _TBoostGoal then
					_TBoost = _TBoost + _Tune.T_SpoolDecrease * (_TBoostGoal - _TBoost) * deltaTime
				end
				_TBoost = math.clamp(_TBoost, 0, _Tune.Turbochargers * _Tune.T_Boost)
				TTorque = _TBoost * _Tune.T_Efficiency
				_TH, _TT = (TTorque * x) / 5.252, TTorque
			end
			if _Tune.Superchargers > 0 then
				local SIdleBoost = f(
					_Tune.IdleRPM / 1000,
					_Tune.S_IdleBoost,
					_Tune.S_PeakRPM / 1000,
					_Tune.S_Boost,
					_Tune.S_Boost,
					_Tune.S_IdleCurve,
					x
				)
				local SRedlineBoost = f(
					_Tune.S_PeakRPM / 1000,
					_Tune.S_Boost,
					_Tune.Redline / 1000,
					_Tune.S_RedlineBoost,
					_Tune.S_Boost,
					1 / _Tune.S_RedlineCurve,
					x
				)
				local _SBoostGoal = _Tune.Superchargers * _GThrot * (_Tune.S_Boost - SIdleBoost - SRedlineBoost)
				if _SBoostGoal > _SBoost then
					_SBoost = math.min(_SBoost + _Tune.S_Boost * _Tune.S_Response * deltaTime, _SBoostGoal)
				elseif _SBoost > _SBoostGoal then
					_SBoost = math.max(_SBoost - _Tune.S_Boost * _Tune.S_Response * deltaTime, _SBoostGoal)
				end
				STorque = _SBoost * _Tune.S_Efficiency
				_SH, _ST = (STorque * x) / 5.252, STorque
			end
			if _Tune.Turbochargers > 0 or _Tune.Superchargers > 0 then
				_BH, _BT = ((TTorque + STorque) * x) / 5.252, TTorque + STorque
			end
		end
		if _Tune.Electric then
			ETorque = 1
				* (
					_Tune.E_Torque
					- f(
						_Tune.E_TransitionRPM / 1000,
						_Tune.E_Torque,
						_Tune.E_Redline / 1000,
						_Tune.E_RedlineTorque,
						_Tune.E_Torque,
						_Tune.E_Curve,
						x
					)
				)
			_EH, _ET = (ETorque * x) / 5.252, ETorque
		end
		local TotalTorque = math.clamp(
			NTorque + ETorque + TTorque + STorque,
			_Tune.Stall and 0 or _Tune.IdleTorque,
			(_Tune.HPLimit > 0 and _Tune.HPLimit or math.huge) * (5.252 / x)
		)
		_HP, _TQ = (TotalTorque * x) / 5.252, TotalTorque
	else
		engine.run({
			-- Manually add environment variables here
			_RPM = _RPM,
			_GThrot = _GThrot,
			_IsOn = _IsOn,
			_CGear = _CGear,
		}, dt)

		_Boost = engine._Boost
		_TBoost = engine._TBoost
		_SBoost = engine._SBoost

		_HP = engine._HP
		_TQ = engine._TQ
		_NH = engine._NH
		_NT = engine._NT
		_EH = engine._EH
		_ET = engine._ET
		_TH = engine._TH
		_TT = engine._TT
		_SH = engine._SH
		_ST = engine._ST
		_BH = engine._BH
		_BT = engine._BT
	end

	-- Exit engine
	_OutTorque = _TQ * _CurrentRatio * fFD
	local iComp = _Center.LookVector.Y * cGrav * math.sign(_CGear)
	_OutTorque = _OutTorque * math.max(1, (1 + iComp))

	-- Brakes
	local FBrakeForce = _Tune.BrakeForce * 9.80665 * Units.Force_N * _Tune.BrakeBias -- luaint edit, conversion to SI unit Detomiks
	local RBrakeForce = _Tune.BrakeForce * 9.80665 * Units.Force_N * (1 - _Tune.BrakeBias) -- luaint edit
	local PBrakeForceF = _Tune.PBrakeForce * 9.80665 * Units.Force_N * _Tune.PBrakeBias
	local PBrakeForceR = _Tune.PBrakeForce * 9.80665 * Units.Force_N * (1 - _Tune.PBrakeBias)

	-- Precompute symmetric straight-line TCS so left/right wheels never create uneven torque steer
	local straightAhead = math.abs(_GSteerT) <= 0.03 and math.abs(_GSteerC) <= 0.03 and not _TapDriftActive
	local straightAxleTcs: { [boolean]: number }? = nil
	if straightAhead and _TCS then
		local planarVel = weightBrick and weightBrick.AssemblyLinearVelocity or Vector3.zero
		local planarSpeedKmh = Vector3.new(planarVel.X, 0, planarVel.Z).Magnitude / (Units.Velocity_mdivs / 3.6)
		local tcsBypassSpeedKmh = _Tune.ClimbTCSBypassSpeedKmh or 0
		if _GThrot > _Tune.IdleThrottle / 100 and planarSpeedKmh >= tcsBypassSpeedKmh then
			local frontTcs, rearTcs = 1, 1
			for _, wData in Wheels do
				if wData.driven then
					local slipKmh = math.abs(
						wData.RotVelocityMagnitude * (wData.Size.Y / 2) / (Units.Velocity_mdivs / 3.6)
							- wData.WheelVelocityMagnitude / (Units.Velocity_mdivs / 3.6)
					)
					local wTcs = 1
						- (
							math.min(math.max(0, slipKmh - _Tune.TCSThreshold) / _Tune.TCSGradient, 1)
							* (1 - (_Tune.TCSLimit / 100))
						)
					if wData.isFront then
						frontTcs = math.min(frontTcs, wTcs)
					else
						rearTcs = math.min(rearTcs, wTcs)
					end
				end
			end
			straightAxleTcs = { [true] = frontTcs, [false] = rearTcs }
		end
	end

	-- Update Wheels
	for _, data in Wheels do
		-- Apply Power
		local PBrakeV = (_PBrake == true or _CGear == -2) and 1 or 0
		local on = _IsOn and 1 or 0

		local throt = _GThrot
		local brake = _GBrake

		local clutch = 1
		if
			_ClPressing
			or (
				_AutoClutch
				and (
					_Starting
					or (_Tune.RemoveCreep and _RPM < _Tune.IdleRPM + (_Tune.IdlePadding or 0) and driveCommand < 0.05)
				)
			)
		then
			clutch = 0
		end

		-- Apply ESC
		local tqESC = 0
		if
			not (data.Name == "F" or data.Name == "R")
			and _ESC
			and (_Velocity.Magnitude / (Units.Velocity_mdivs / 3.6)) > _Tune.ESCSpeed
		then
			local g = weightBrick.CFrame:VectorToObjectSpace(
				_Acceleration
					/ Units.Velocity_mdivs
					/ ((_Tune.GravComp > 0 and _Tune.GravComp or workspace.Gravity) * (Units.Length_mm / 1000))
			)
			if math.sign(_GSteerC) ~= math.sign(g.X) then
				local diff = _GSteerC - (g.X * -math.sign(_Center:VectorToObjectSpace(_Velocity).Z))
				if math.abs(diff) > _Tune.ESCThreshold then
					local escVector, escBias = 1, (_Tune.ESCVector + 1)
					if data.isFront then
						escVector = escVector * (2 - escBias)
					else
						escVector = escVector * escBias
					end

					tqESC = ((data.Name == "FL" or data.Name == "RL") and 1 or -1) * math.sign(diff) * escVector
					throt = throt + (math.max(tqESC, 0) - throt) * (_Tune.ESCThrottle / 100)
					brake = brake + (-math.min(tqESC, 0) - brake) * (_Tune.ESCBrake / 100)
				end
			end
		end

		_ESCActive = tqESC ~= 0 or _ESCActive
		_ESCTracker[data.Name] = tqESC

		-- Apply ABS
		local tqABS = 1
		if _ABS and brake > 0 then
			tqABS = 1
				- (
					math.min(
						math.max(
							0,
							math.abs(
								data.RotVelocityMagnitude * (data.Size.Y / 2) / (Units.Velocity_mdivs / 3.6)
									- data.WheelVelocityMagnitude / (Units.Velocity_mdivs / 3.6)
							) - _Tune.ABSThreshold
						) / _Tune.ABSGradient,
						1
					) * (1 - (_Tune.ABSLimit / 100))
				)
		end
		_ABSActive = tqABS < 1 or _ABSActive
		_ABSTracker[data.Name] = 1 - tqABS

		-- Apply Power
		if data.driven then
			-- Differential/Torque-Vectoring (symmetric when driving straight; guarded against zero wheel speed)
			local function computeDiffMultiplier(powerPct: number, coastPct: number, preload: number): number
				if straightAhead or not data.OppositeWheel then
					return 1
				end
				local oppSpeed = math.max(data.OppositeWheel.AssemblyAngularVelocity.Magnitude, 0.5)
				local avg = ((data.RotVelocityMagnitude / oppSpeed) - 1) * (preload / 10)
				local raw = 1 - (((powerPct / 100) * avg * _GThrot) + ((coastPct / 100) * avg * (1 - _GThrot)))
				return math.clamp(raw, 0, 2)
			end

			local diffMult = 1
			if data.Name == "FR" or data.Name == "FL" then
				diffMult = computeDiffMultiplier(_Tune.FDiffPower, _Tune.FDiffCoast, _Tune.FDiffPreload)
			elseif data.Name == "RR" or data.Name == "RL" then
				diffMult = computeDiffMultiplier(_Tune.RDiffPower, _Tune.RDiffCoast, _Tune.RDiffPreload)
			end

			-- Apply torque split
			-- This takes the total amount of torque alotted to the front or rear wheels, then divides it by how many wheels there are
			local bias = (_Tune.Config == "AWD" and (_Tune.TorqueVector + 1) / 2) or (_Tune.Config == "FWD" and 0) or 1
			local tq = data.isFront and (_OutTorque * (1 - bias)) / FWheelCount or (_OutTorque * bias) / RWheelCount

			-- Apply TCS (bypass at creeping speeds so curb climbing keeps full torque; synchronized per-axle when straight)
			tqTCS = 1
			if straightAxleTcs then
				tqTCS = straightAxleTcs[data.isFront]
			else
				local planarVel = weightBrick and weightBrick.AssemblyLinearVelocity or Vector3.zero
				local planarSpeedKmh = Vector3.new(planarVel.X, 0, planarVel.Z).Magnitude / (Units.Velocity_mdivs / 3.6)
				local tcsBypassSpeedKmh = _Tune.ClimbTCSBypassSpeedKmh or 0
				if _TCS and throt > _Tune.IdleThrottle / 100 and planarSpeedKmh >= tcsBypassSpeedKmh then
					tqTCS = 1
						- (
							math.min(
								math.max(
									0,
									math.abs(
										data.RotVelocityMagnitude * (data.Size.Y / 2) / (Units.Velocity_mdivs / 3.6)
											- data.WheelVelocityMagnitude / (Units.Velocity_mdivs / 3.6)
									) - _Tune.TCSThreshold
								) / _Tune.TCSGradient,
								1
							) * (1 - (_Tune.TCSLimit / 100))
						)
				end
			end
			_TCSActive = tqTCS < 1 or _TCSActive
			_TCSTracker[data.Name] = 1 - tqTCS

			-- Update Forces (only add flywheel energy when actively throttling and not braking)
			local seatThrottleFloat = getEffectiveSeatThrottle()
			local noPedalInput = (
				_InThrot <= 0.02
				and _InBrake <= 0.02
				and _IThrot <= 0.02
				and _IBrake <= 0.02
				and math.abs(seatThrottleFloat) <= 0.05
			)
			local flywheelAdd = (not noPedalInput and throt > 0.05 and brake < 0.05) and (_FlywheelEnergy / #Drive) or 0
			local tqOUT = (tq * 1.356 * Units.Torque_nm * throt * tqTCS * on * clutch) + flywheelAdd
			if noPedalInput or (brake > 0.05 and throt <= 0.05) or car:GetAttribute("VehiclePowerDisabled") == true then
				tqOUT = 0
			end
			-- convert lb-ft to nm to roblox stuff
			-- if it reaches an absurdly high number, set it to 0 to try and prevent physics death

			-- CDT Tap-to-Drift & Spacebar Handbrake:
			local isRear = (data.Name == "RR" or data.Name == "RL")
			local handbrakeEngaged = _SpaceHeld or _TapDriftActive

			local effectiveSpLimit = _spLimit
			if
				boostNow
				and _CGear >= 1
				and _Tune.SpeedLimit > 0
				and _Tune.BoostMaxSpeedKmh
				and _Tune.BoostMaxSpeedKmh > _Tune.SpeedLimit
			then
				effectiveSpLimit = _spLimit * (_Tune.BoostMaxSpeedKmh / _Tune.SpeedLimit)
			end
			if
				stunt
				and stunt.wallClimbActive
				and _CGear >= 1
				and _Tune.SpeedLimit > 0
				and _Tune.SpiderMaxClimbSpeed
			then
				effectiveSpLimit = math.min(
					effectiveSpLimit,
					_spLimit
						* (
							((_Tune.SpiderMaxClimbSpeed / (Units.Velocity_mdivs / 3.6)) * (boostNow and 1.45 or 1))
							/ _Tune.SpeedLimit
						)
				)
			end
			if noPedalInput and not _TapDriftActive then
				data.AV.MotorMaxTorque = 0
				data.AV.AngularVelocity = 0
			elseif handbrakeEngaged and isRear then
				if _SpaceHeld then
					-- Spacebar on PC: Complete rear torque cut for sharp handbrake lock
					data.AV.MotorMaxTorque = 0
				else
					-- Tap-to-Drift (CDT Arcade): Deliver 45% throttle torque to powerslide through the corner!
					data.AV.MotorMaxTorque = (tqOUT * (_InThrot > 0.1 and (_Tune.TapDriftPowerRatio or 0.45) or 0))
				end
				data.AV.AngularVelocity = effectiveSpLimit * math.sign(_CGear)
			else
				data.AV.MotorMaxTorque = tqOUT * diffMult
				data.AV.AngularVelocity = effectiveSpLimit * math.sign(_CGear)
			end

			-- Smooth grounded coast slowdown & auto-stop when W/S are released (keeps rolling smoothly to 0 instead of coasting forever)
			local coastTorque = 0
			if
				noPedalInput
				and not boostNow
				and not _MidAirActive
				and not _SpaceHeld
				and not _TapDriftActive
				and not _ClPressing
				and _IsOn
			then
				local coastForceBase = (_Tune.CoastDecelForce or 1600) * 9.80665 * Units.Force_N
				local speedStuds = _Velocity.Magnitude
				local autoStopSpeed = _Tune.AutoStopSpeedStuds or 3.5
				local axleSplit = data.isFront and 0.55 or 0.45
				if speedStuds <= autoStopSpeed then
					coastTorque = coastForceBase * 0.90 * axleSplit
				else
					local coastScale = math.clamp(speedStuds / 55, 0.50, 1.15)
					coastTorque = coastForceBase * coastScale * axleSplit
				end
			end

			-- Apply Brake Torques:
			if data.isFront then
				local fEmergency = _SpaceHeld and 10000 or (_TapDriftActive and 3000 or 0)
				data.BV.MotorMaxTorque = math.max(
					(FBrakeForce * brake * tqABS)
						+ (_Tune.EBrakeForce * clutch * ((1 - throt) * (_RPM / _Tune.Redline)))
						+ (PBrakeForceF * PBrakeV),
					fEmergency,
					coastTorque
				)
			else
				local rBrake = _SpaceHeld and 28000
					or (_TapDriftActive and (_Tune.TapDriftRearBrake or 18000) or (PBrakeForceR * PBrakeV))
				data.BV.MotorMaxTorque = math.max(
					(RBrakeForce * brake * tqABS)
						+ (_Tune.EBrakeForce * clutch * ((1 - throt) * (_RPM / _Tune.Redline)))
						+ rBrake,
					coastTorque
				)
			end
		else -- luaint edit
			data.AV.MotorMaxTorque = 0
			data.AV.AngularVelocity = 0
			if data.isFront then
				data.BV.MotorMaxTorque = (FBrakeForce * brake * tqABS) + (PBrakeForceF * PBrakeV)
			else
				data.BV.MotorMaxTorque = (RBrakeForce * brake * tqABS) + (PBrakeForceR * PBrakeV)
			end
		end

		-- Active Grounded Tire Smoke (DriveSeat Anchored) on Drift, Hard Cornering or Burnout
		local seat = car.DriveSeat
		local lateralSpeed = math.abs(_Velocity:Dot(seat.CFrame.RightVector))
		local isDrifting = (_SpaceHeld or _TapDriftActive) and _Velocity.Magnitude > 10
		local isHardSlide = lateralSpeed > 10 and _Velocity.Magnitude > 15
		local isBurnoutOrLock = brake > 0.65 and _Velocity.Magnitude > 20

		local isCarUpright = not _MidAirActive and ((_FrontGroundedCount or 0) + (_RearGroundedCount or 0) >= 1)
		local rearSmokeActive = isCarUpright
			and not _MidAirActive
			and (_RearGroundedCount and _RearGroundedCount >= 1)
			and (isDrifting or isHardSlide or isBurnoutOrLock)
		local frontSmokeActive = isCarUpright
			and not _MidAirActive
			and (_FrontGroundedCount and _FrontGroundedCount >= 1)
			and (isHardSlide or (brake > 0.75 and _Velocity.Magnitude > 25))

		-- Warm, Smooth Asphalt Tire Scrub (Fatigue-Free, Non-Piercing)
		local tireScrub = seat:FindFirstChild("HokiTireScrub")
			or (function()
				local s = Instance.new("Sound")
				s.Name = "HokiTireScrub"
				s.SoundId = "rbxassetid://112851268328371" -- Real organic asphalt friction by Detocoyote
				s.Looped = true
				s.Volume = 0
				s.RollOffMaxDistance = 140
				s.RollOffMinDistance = 10
				s.RollOffMode = Enum.RollOffMode.InverseTapered

				-- Acoustic EQ: Cut piercing highs (-14dB), warm up low-end rubber body
				local eq = Instance.new("EqualizerSoundEffect")
				eq.Name = "WarmthEQ"
				eq.LowGain = 2.5
				eq.MidGain = -3.0
				eq.HighGain = -14.0
				eq.Parent = s

				s.Parent = seat
				s:Play()
				return s
			end)()

		-- Clean up legacy harsh sounds if present
		local legacy1 = seat:FindFirstChild("HokiTireScreech")
		if legacy1 then
			legacy1:Stop()
			legacy1:Destroy()
		end
		local legacy2 = seat:FindFirstChild("HokiTireSkid")
		if legacy2 then
			legacy2:Stop()
			legacy2:Destroy()
		end

		local speedStuds = _Velocity.Magnitude
		local groundedTires = (_FrontGroundedCount or 0) + (_RearGroundedCount or 0)
		local canMakeTireSound = isCarUpright and not _MidAirActive and (groundedTires >= 1) and (speedStuds > 18)

		-- Only trigger when there is actual hard lateral slip (drifting or aggressive turn-in at high speed)
		local cornerSlip = canMakeTireSound and (math.abs(_GSteerC) * math.clamp((speedStuds - 22) / 45, 0, 1)) or 0
		local isHardTurning = cornerSlip > 0.28
		local isLateralSliding = lateralSpeed > 9.0 and speedStuds > 20

		local targetVol = 0
		if canMakeTireSound then
			if rearSmokeActive or frontSmokeActive or isDrifting or isHardSlide or isLateralSliding then
				-- Controlled, non-fatiguing drift volume (max 0.26 instead of 0.75)
				targetVol = math.clamp(0.18 + (lateralSpeed / 45) * 0.08, 0.16, 0.26)
			elseif isHardTurning then
				-- Subtle textured cornering cue (0.06 - 0.16)
				targetVol = math.clamp((cornerSlip - 0.28) * 0.35, 0.06, 0.16)
			elseif isBurnoutOrLock then
				targetVol = 0.22
			end
		end

		-- Gentle, smooth volume transitions (no abrupt jumps)
		local fadeRate = (targetVol > tireScrub.Volume) and 9 or 7
		tireScrub.Volume = tireScrub.Volume + (targetVol - tireScrub.Volume) * math.min(1, dt * fadeRate)

		-- Keep pitch warm and deep (0.92 - 1.02, never shrill)
		local targetPitch = 0.94 + math.clamp(speedStuds / 240, 0, 0.06) + math.clamp(lateralSpeed / 70, 0, 0.04)
		tireScrub.PlaybackSpeed = tireScrub.PlaybackSpeed
			+ (targetPitch - tireScrub.PlaybackSpeed) * math.min(1, dt * 6)

		local rrAtt = seat:FindFirstChild("RR_SmokeAtt")
		local rlAtt = seat:FindFirstChild("RL_SmokeAtt")
		local frAtt = seat:FindFirstChild("FR_SmokeAtt")
		local flAtt = seat:FindFirstChild("FL_SmokeAtt")

		if rrAtt and rrAtt:FindFirstChild("TireSmoke") then
			rrAtt.TireSmoke.Enabled = rearSmokeActive and (_WheelGrounded["RR"] == true)
			rrAtt.TireSmoke.Rate = (isDrifting or isHardSlide) and 75 or 40
		end
		if rlAtt and rlAtt:FindFirstChild("TireSmoke") then
			rlAtt.TireSmoke.Enabled = rearSmokeActive and (_WheelGrounded["RL"] == true)
			rlAtt.TireSmoke.Rate = (isDrifting or isHardSlide) and 75 or 40
		end
		if frAtt and frAtt:FindFirstChild("TireSmoke") then
			frAtt.TireSmoke.Enabled = frontSmokeActive and (_WheelGrounded["FR"] == true)
			frAtt.TireSmoke.Rate = 45
		end
		if flAtt and flAtt:FindFirstChild("TireSmoke") then
			flAtt.TireSmoke.Enabled = frontSmokeActive and (_WheelGrounded["FL"] == true)
			flAtt.TireSmoke.Rate = 45
		end
	end
end

-- Wheel output values
local function GetCenter()
	local centerF = Vector3.new()
	local centerR = Vector3.new()
	local countF = 0
	local countR = 0
	for wheel, data in Wheels do
		if data.isFront then
			centerF = centerF + wheel.Position
			countF = countF + 1
		else
			centerR = centerR + wheel.Position
			countR = countR + 1
		end
	end
	centerF = centerF / countF
	centerR = centerR / countR
	local center = CFrame.lookAt(centerR:Lerp(centerF, 0.5), centerF)
	return center
end

local function WheelOutput(dt: number)
	local tcsCount = 0
	local absCount = 0
	local escCount = 0
	local rot = 0
	local count = 0
	local driveCount = 0

	_TCSAmt = 0
	_ABSAmt = 0
	_ESCAmt = 0

	_MaxWheelSpin = 0
	_DriveWheelSpeed = 0

	for wheel, data in Wheels do
		count += 1

		-- Wheel speeds
		if not _WheelSpeedsTable[data.Name] then
			_WheelSpeedsTable[data.Name] = {}
		end

		data.RotVelocityMagnitude = wheel.RotVelocity.Magnitude
		data.WheelVelocityMagnitude = wheel.Velocity.Magnitude

		table.insert(_WheelSpeedsTable[data.Name], data.RotVelocityMagnitude)
		if #_WheelSpeedsTable[data.Name] > 8 then
			table.remove(_WheelSpeedsTable[data.Name], 1)
		end

		local avg = 0
		local avgCount = 0

		for _, a in _WheelSpeedsTable[data.Name] do
			avg += a
			avgCount += 1
		end

		avg = avg / avgCount
		_WheelSpeeds[data.Name] = avg

		if data.driven then
			_DriveWheelSpeed = _DriveWheelSpeed + avg
			driveCount = driveCount + 1
			if avg > _MaxWheelSpin then
				_MaxWheelSpin = avg
			end
		end

		-- Output wheel speeds
		data.WheelSpeedValue.Value = _WheelSpeeds[data.Name] -- I'm not using the avg variable here for future-proofing if we change the calculation later and stuff
		rot += _WheelSpeeds[data.Name] * (data.Size.Y / 2)

		-- TCS
		if _TCSTracker[data.Name] then
			data.TCSTrackerValue.Value = _TCSTracker[data.Name]
			_TCSAmt += _TCSTracker[data.Name]
			tcsCount += 1
		end

		-- ABS
		if _ABSTracker[data.Name] then
			data.ABSTrackerValue.Value = _ABSTracker[data.Name]
			_ABSAmt += _ABSTracker[data.Name]
			absCount += 1
		end

		-- ESC
		if _ESCTracker[data.Name] then
			data.ESCTrackerValue.Value = _ESCTracker[data.Name]
			_ESCAmt += math.abs(_ESCTracker[data.Name])
			escCount += 1
		end
	end

	_DriveWheelSpeed = _DriveWheelSpeed / driveCount

	-- Wheel speeds
	_AvgWheelSpeed = rot / count
	-- TCS
	_TCSAmt = _TCSAmt / tcsCount
	_TCSActive = false
	-- ABS
	_ABSAmt = _ABSAmt / absCount
	_ABSActive = false
	-- ESC
	_ESCAmt = _ESCAmt / escCount
	_ESCActive = false
end

-- Mobile
local function Mobile()
	MobileUI.ModeSwitch.Visible = _Velocity.Magnitude < 5
	MobileUI.ModeSwitch.Text = MobileMode
	MobileUI.Jump.Visible = false
	for _, v in MobileUIChildren do
		if v:IsA("Frame") then
			v.Visible = MobileMode == v.Name
		end
	end
end

-- Flip (only rescues when genuinely stuck upside-down on a surface with 0 wheel adhesion)
local function Flip()
	local stuckUpsideDown = stunt ~= nil and stunt:ShouldAllowAutoFlip() or false
	if _FlipDB or not stuckUpsideDown then
		_FlipWait = tick()
	else
		if tick() - _FlipWait >= 1.2 then
			_FlipDB = true
			if _Tune.FlipType == "New" then
				local gyro = driveSeat.Flip
				gyro.Enabled = true
				task.wait(1)
				gyro.Enabled = false
			else
				local gyro = driveSeat.Flip
				gyro.maxTorque = Vector3.new(10000, 0, 10000)
				gyro.P = 3000
				gyro.D = 500
				task.wait(1)
				gyro.maxTorque = Vector3.new(0, 0, 0)
				gyro.P = 0
				gyro.D = 0
			end
			_FlipDB = false
		end
	end
end

-- ============================================================================
-- SPIDER WALL-CLIMB, CEILING ADHESION & SKY-SOAR FLIGHT ENGINE (HOKI STUNT)
-- ============================================================================
stunt = SpiderFlightEngine.new({
	car = car,
	driveSeat = driveSeat,
	weightBrick = weightBrick,
	tune = _Tune,
	units = Units,
	wheels = Wheels,
	wheelGrounded = _WheelGrounded,
	frontLeftWheel = car.Wheels:FindFirstChild("FL") :: BasePart?,
	frontRightWheel = car.Wheels:FindFirstChild("FR") :: BasePart?,
	rearLeftWheel = car.Wheels:FindFirstChild("RL") :: BasePart?,
	rearRightWheel = car.Wheels:FindFirstChild("RR") :: BasePart?,
	player = player,
	clearCurbAssist = clearCurbAssistState,
	getThrottleInput = getEffectiveSeatThrottle,
	getSteerInput = getEffectiveSeatSteer,
})
stuntCam = StuntCamera.new(car, driveSeat, _Tune, Units)

local function ArcadeSteeringYaw(dt: number)
	stunt:StepSurfaceSteering(dt, _GSteerC)
end

local function UpdateCurbRecovery(_dt: number)
	-- Surface-normal alignment in SpiderFlightEngine keeps the chassis stable across flat ground, slopes, and walls.
end

local function MidAirControl(dt: number)
	local midAir, fCount, rCount = stunt:Step(dt, {
		iThrot = _IThrot,
		gThrot = _GThrot,
		iBrake = _IBrake,
		gBrake = _GBrake,
		gSteerT = _GSteerT,
		spaceHeld = _SpaceHeld,
		isOn = _IsOn,
		stepClimbActive = car:GetAttribute("SconStepClimbActive") == true,
	})
	_MidAirActive = midAir
	_FrontGroundedCount = fCount
	_RearGroundedCount = rCount
	if _MidAirActive and _Tune.ArcadeSteering then
		Steering(dt)
	end
end

-- Last Input Type
local function onLastInputTypeChanged(inputType: Enum.UserInputType)
	LastInputWasGamepad = string.find(inputType.Name, "Gamepad") and true or false

	-- Mobile
	LastInputWasMobile = inputType == Enum.UserInputType.Touch
	MobileUI.Visible = LastInputWasMobile
	if LastInputWasMobile then
		_Tune.AutoShiftVers = "Old"
		_TMode = "Auto"
	else
		_Tune.AutoShiftVers = _InitialAutoShiftVers
	end
end

-- Run
-- In case of car death
driveSeat.AncestryChanged:Connect(function()
	if driveSeat.Parent then
		return
	end
	task.wait(10)
	script.Parent:Destroy()
end)

-- Changes
onLastInputTypeChanged(UserInputService:GetLastInputType())
UserInputService.LastInputTypeChanged:Connect(onLastInputTypeChanged)

-- Runtime Loops
local function RuntimeLoop(dt: number)
	-- Update Internal Values
	-- Velocity
	_Velocity = weightBrick.AssemblyLinearVelocity
	_Acceleration = (_Velocity - _OldVelocity) / dt
	_OldVelocity = _Velocity
	_Center = GetCenter()
	UpdateCurbAssist(dt)

	-- Update External Values
	-- Transmission
	Value.Clutch.Value = _Clutch
	Value.Gear.Value = _CGear
	Value.TransmissionMode.Value = _TMode
	Value.CurrentRatio.Value = _CurrentRatio
	Value.RPM.Value = _RPM

	-- Boost
	Value.Boost.Value = _TBoost + _SBoost
	Value.BoostTurbo.Value = _TBoost
	Value.BoostSuper.Value = _SBoost

	-- Horsepower
	Value.HpNatural.Value = _NH
	Value.HpElectric.Value = _EH
	Value.HpTurbo.Value = _TH
	Value.HpSuper.Value = _SH
	Value.HpBoosted.Value = _BH
	Value.Horsepower.Value = _HP

	-- Torque
	Value.TqNatural.Value = _NT
	Value.TqElectric.Value = _ET
	Value.TqTurbo.Value = _TT
	Value.TqSuper.Value = _ST
	Value.TqBoosted.Value = _BT
	Value.Torque.Value = _TQ

	-- Inputs
	Value.Throttle.Value = _GThrot
	Value.InputThrottle.Value = _IThrot
	Value.Brake.Value = _GBrake
	Value.InputBrake.Value = _IBrake
	Value.SteerC.Value = _GSteerC
	Value.SteerT.Value = _GSteerT
	Value.PBrake.Value = _PBrake
	car:SetAttribute("DriveTicks", ((car:GetAttribute("DriveTicks") or 0) + 1) % 100000)
	car:SetAttribute("DriveLiveThrottle", _GThrot)
	car:SetAttribute("DriveLiveGear", _CGear)
	car:SetAttribute("DriveLivePBrake", _PBrake)

	-- Velocity
	Value.Velocity.Value = _Velocity
	Value.AverageRotSpeed.Value = _AvgWheelSpeed
	Value.Acceleration.Value = _Acceleration

	-- Misc
	Value.Center.Value = _Center
	Value.TCS.Value = _TCS
	Value.TCSActive.Value = _TCSActive
	Value.TCSAmt.Value = _TCSAmt

	Value.ABS.Value = _ABS
	Value.ABSActive.Value = _ABSActive
	Value.ABSAmt.Value = _ABSAmt

	Value.ESC.Value = _ESC
	Value.ESCActive.Value = _ESCActive
	Value.ESCAmt.Value = _ESCAmt

	Value.CS.Value = _CS
	Value.CSActive.Value = _CSActive
	Value.CSAmt.Value = _CSAmt

	-- Wheel Output
	WheelOutput(dt)

	-- Inputs
	Inputs(dt)

	-- Steering
	Steering(dt)

	-- Automatic Transmission (60Hz Zero-Delay)
	if _TMode == "Auto" then
		Auto()
	end

	-- Gear
	Gear()

	-- Mid-Air Control (runs before Engine so wheel ground flags are fresh)
	MidAirControl(dt)

	-- Power
	Engine(dt)

	-- Apply direct chassis steering after air control so it cannot overwrite yaw.
	ArcadeSteeringYaw(dt)

	-- Catch a dangerous curb impact without changing normal ramp flight.
	UpdateCurbRecovery(dt)
end

local fixedDeltaTime = 1 / 60 -- Fixed to avoid rewriting old code causing different behaviours at different FPS
local accumulatedSimTime = 0

local preSimConn = RunService.PreSimulation:Connect(function(deltaTimeSim: number)
	accumulatedSimTime += deltaTimeSim
	while accumulatedSimTime >= fixedDeltaTime do
		accumulatedSimTime -= fixedDeltaTime
		RuntimeLoop(fixedDeltaTime)
	end
end)

local function SlowRuntimeLoop()
	while script.Parent and car.Parent do
		local _deltaTime = task.wait(1 / 8)
		if not script.Parent or not car.Parent then
			break
		end

		-- Mobile UI
		if _Tune.Mobile and LastInputWasMobile then
			Mobile()
		end

		-- Automatic Transmission
		if _TMode == "Auto" then
			Auto()
		end

		-- Flip
		if _Tune.AutoFlip then
			Flip()
		end

		-- Set GlobalTemperature
		GlobalTemperature = workspace:GetAttribute("GlobalTemperature") or 22
	end
end

local slowLoopThread = task.spawn(SlowRuntimeLoop)

-- ============================================================================
-- SINK SPACEBAR HANDBRAKE & PREVENT EJECT JUMPING BUG
-- ============================================================================
local ContextActionService = game:GetService("ContextActionService")
local character = player.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")

-- 1. Disable Jumping while seated so pressing Spacebar NEVER bounces the player out of the seat!
if humanoid then
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
end

-- 1b. Locally suppress ALL door prompts for the driver so "นั่งข้างคนขับ" NEVER pops up while driving!
local doorPromptsFolder = car:FindFirstChild("Body") and car.Body:FindFirstChild("DoorPrompts")
local function setPromptsEnabled(enabled: boolean)
	if doorPromptsFolder then
		for _, desc in ipairs(doorPromptsFolder:GetDescendants()) do
			if desc:IsA("ProximityPrompt") then
				desc.Enabled = enabled
			end
		end
	end
end
setPromptsEnabled(false)

-- 2. Bind Spacebar to Handbrake / Brake with SINK at maximum priority (overrides Roblox core jump!)
local function handleSpacebarHandbrake(_actionName, inputState, _inputObject)
	if inputState == Enum.UserInputState.Begin then
		_SpaceHeld = true
		_PBrake = true
		_IBrake = 1
		return Enum.ContextActionResult.Sink
	elseif inputState == Enum.UserInputState.End then
		_SpaceHeld = false
		_PBrake = false
		_IBrake = 0
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindActionAtPriority(
	"HokiSpacebarHandbrakeSink",
	handleSpacebarHandbrake,
	false,
	Enum.ContextActionPriority.High.Value + 3000,
	Enum.KeyCode.Space
)

-- 3. Clean [E] / [F] Exit Vehicle Handler
local exitRemote = car:FindFirstChild("VehicleExitRequest")
local function triggerCleanExit()
	if exitRemote then
		exitRemote:FireServer()
	else
		if humanoid then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			humanoid.Sit = false
			humanoid.Jump = true
		end
	end
end

ContextActionService:BindActionAtPriority("HokiDriverCleanExit", function(_, state)
	if state == Enum.UserInputState.Begin then
		triggerCleanExit()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value + 1500, Enum.KeyCode.E, Enum.KeyCode.F)

-- 3b. [H] Key Tesla Horn Handler
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local hornHeld = false
local function sendHornState(active: boolean)
	local tuningRemote = ReplicatedStorage:FindFirstChild("HokiVehicleTuningRemote")
	if tuningRemote and tuningRemote:IsA("RemoteEvent") and car then
		tuningRemote:FireServer(car, "Horn", { Active = active })
	end
end

ContextActionService:BindActionAtPriority("HokiTeslaHorn", function(_, state)
	if state == Enum.UserInputState.Begin then
		if UserInputService:GetFocusedTextBox() then
			return Enum.ContextActionResult.Pass
		end
		if not hornHeld then
			hornHeld = true
			sendHornState(true)
		end
		return Enum.ContextActionResult.Sink
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		if hornHeld then
			hornHeld = false
			sendHornState(false)
		end
		return Enum.ContextActionResult.Pass
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value + 1400, Enum.KeyCode.H)

-- 3c. [LeftShift / RightShift] Rocket Boost & Sky-Soar Flight + [Q] Stunt Jump / Wall-Jump
ContextActionService:BindActionAtPriority(
	"HokiBoostFlight",
	function(_, state)
		if state == Enum.UserInputState.Begin then
			if UserInputService:GetFocusedTextBox() then
				return Enum.ContextActionResult.Pass
			end
			stunt:SetBoostHeld(true)
			return Enum.ContextActionResult.Pass
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			stunt:SetBoostHeld(false)
			return Enum.ContextActionResult.Pass
		end
		return Enum.ContextActionResult.Pass
	end,
	false,
	Enum.ContextActionPriority.High.Value + 1450,
	Enum.KeyCode.LeftShift,
	Enum.KeyCode.RightShift,
	Enum.KeyCode.ButtonX
)

-- 4. Mobile Exit Button Binding
local mobile = script.Parent:FindFirstChild("Mobile")
if mobile then
	local mobileExit = mobile:FindFirstChild("MobileExit", true)
	if mobileExit then
		mobileExit.MouseButton1Click:Connect(function()
			triggerCleanExit()
		end)
	end
end

-- 5. Restore Jumping, stop transient vehicle audio, and unbind actions on exit
script.Destroying:Connect(function()
	preSimConn:Disconnect()
	pcall(task.cancel, slowLoopThread)
	if stunt then
		stunt:Destroy()
	end

	setPromptsEnabled(true)
	if hornHeld then
		hornHeld = false
		sendHornState(false)
	end
	local seatForAudio = car and car:FindFirstChild("DriveSeat")
	local tireScrub = seatForAudio and seatForAudio:FindFirstChild("HokiTireScrub")
	if tireScrub and tireScrub:IsA("Sound") then
		tireScrub.Volume = 0
		tireScrub:Stop()
	end
	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end
	unbindDriverControls()
end)
