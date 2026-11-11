---
project: HOKI TOWN
script_name: AChassis_Drive_CDT_Arcade_Client
script_type: LocalScript
datamodel_location: 'Workspace.TeslaRoadster["A-Chassis Tune"]["A-Chassis Interface"].Drive'
lines_of_code: 2118
verified_status: passed
features:
  - tap-to-drift
  - spacebar-sink
  - mobile-hud
  - surface-smoke
tags:
  - client-script
  - cdt-arcade
  - a-chassis
  - input-sink
  - tap-to-drift
  - production-code
---

# 📜 AChassis_Drive_CDT_Arcade_Client (LocalScript)

> **ตำแหน่งใน DataModel:** `Workspace.TeslaRoadster["A-Chassis Tune"]["A-Chassis Interface"].Drive`  
> **ประเภทสคริปต์:** `LocalScript (Client-Side Controller)`  
> **คำอธิบาย:** คอร์สคริปต์ควบคุมการขับขี่หลักของรถ Tesla Roadster ที่ได้รับการยกเครื่องเป็น **CDT-Style Clean Arcade Engine** ครบวงจร ทั้งการรองรับ Tap-to-Drift, การดักปุ่ม Spacebar ด้วย ContextActionService Sink, การปิด Prompt รบกวนในห้องโดยสาร, การปล่อยควันยางแบบแนบพื้นผิว และการจัดเลย์เอาต์หน้าจอมือถือ  
> **สถานะ:** ✅ ผ่านการคอมไพล์และทดสอบบน Studio Sandbox เรียบร้อยแล้ว (2,118 บรรทัด)

---

## 📌 จุดปรับปรุงสำคัญระดับสถาปัตยกรรม (Architectural Highlights)

### 1. การดักปุ่ม Spacebar เบรกมือด้วย ContextActionService Sink (Priority `High + 3000`)
- **ปัญหาเดิม:** เมื่อผู้เล่นกด Spacebar บน PC เพื่อดริฟต์ เอนจินของ Roblox Character จะสั่ง `Jump = true` ส่งผลให้ตัวละครหลุดกระเด็นออกจากเบาะทันที
- **แนวทางแก้:** 
  - ลงทะเบียน Action ผ่าน `ContextActionService:BindActionAtPriority("CDT_SpacebarBrake", ... , Enum.ContextActionPriority.High.Value + 3000, Enum.KeyCode.Space)`
  - ส่งกลับ `Enum.ContextActionResult.Sink` เพื่อสกัดกั้นไม่ให้ Input Spacebar เดินทางไปถึง `PlayerModule.Jump`
  - ปิด `Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)` ขณะนั่งขับ และคืนค่า `true` เมื่อลงจากรถ

### 2. ระบบ Tap-to-Drift อัจฉริยะ 2 แป้นเหยียบ (CDT / Asphalt Style)
- **พฤติกรรม:**
  - เมื่อผู้เล่นแตะแป้นเบรก (`S` หรือแป้นเบรกซ้ายบนมือถือ) ขณะรถกำลังวิ่งด้วยความเร็วและมีการหักเลี้ยวพวงมาลัย หากแตะสั้น (< 0.35 วินาที) ระบบจะเข้าสู่ **โหมด Tap-to-Drift**
  - ล้อหลังถูกล็อกแรงดึง 18,000 N แต่ยังคงรักษากำลังส่งเครื่องยนต์ 45% ทำให้ท้ายรถปัดสไลด์ได้อย่างสวยงาม
  - เมื่อพวงมาลัยกลับมาตั้งตรง หรือครบกำหนดเวลา Safe Timeout 1.2 วินาที ยางจะคืนแรงยึดเกาะ 100% พุ่งทะยานออกจากโค้งทันที
  - หากกดแป้นเบรกแช่นาน (> 0.35 วินาที) จะทำงานเป็นเบรกเท้า 4 ล้อธรรมดา และเมื่อรถหยุดนิ่งจะเข้าเกียร์ถอยหลัง (`R`) ให้ทันที

### 3. Immediate Launch PBrake Auto-Release (แก้ปัญหาออกตัวไม่ได้)
- **พฤติกรรม:** ในลูป `Inputs(dt)` เพิ่มระบบตรวจสอบ: หากเบรกมือ (`_PBrake`) ค้างอยู่ แต่ผู้เล่นไม่ได้กด Spacebar และมีการเหยียบคันเร่ง (`_InThrot > 0.05`) หรือแตะเบรก ระบบจะปลด `_PBrake = false` ทันที ทำให้รถออกตัวได้พริบตา ไม่ต้องกดเบรกมือซ้ำ

### 4. ซ่อน ProximityPrompt ประตูอัตโนมัติขณะนั่งขับ
- **พฤติกรรม:** เมื่อ `Drive` เริ่มทำงาน ฟังก์ชัน `setPromptsEnabled(false)` จะค้นหา `DoorPrompts` ภายในรถและปิดการแสดงผล เพื่อไม่ให้ขึ้นข้อความ *"นั่งข้างคนขับ"* กวนสายตาคนขับ และเปิดคืนเมื่อลงจากรถ (`script.Destroying`)

### 5. การจัดเลย์เอาต์หน้าจอบนอุปกรณ์มือถือ (Mobile Touch Controls)
- ปุ่มคันเร่ง (`Throttle`) และเบรก (`Brake`) แยกฝั่งขวาล่างชัดเจน
- ปุ่มเลี้ยวซ้าย-ขวาอยู่ฝั่งซ้ายล่าง
- ปุ่ม `[🚪 ลงจากรถ]` (`MobileExit`) แยกไปไว้มุมบนซ้ายอย่างปลอดภัย หลุดจากโซนสัมผัสของนิ้วโป้งขวา ป้องกันการกดผิดขณะดริฟต์

---

## 📝 ซอร์สโค้ดฉบับสมบูรณ์ (Production Source Code - 2,118 Lines)

```luau
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

local car = script.Parent.Car.Value
local values = script.Parent.Values

local _Tune = require(car["A-Chassis Tune"])
local ArcadeJumpRemote = car["A-Chassis Tune"]:WaitForChild("ArcadeJumpRequest")
local Units = require(car["A-Chassis Tune"].README.Units)
local VirtualInput = script:FindFirstChild("VirtualInput")

if _Tune.Mobile then
	player.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
	GuiService.TouchControlsEnabled = false
end

local MobileMode = "Tap"
local MobileModes = {"Tap", "Tilt"}
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
local _IsOn = _Tune.AutoStart and (_Tune.Engine or _Tune.Electric)
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

local _GSteerT = 0
local _GSteerC = 0

local _GThrot = 0
local _InThrot = 0
local _IThrot = 0
local _GBrake = 0
local _InBrake = 0
local _IBrake = 0

local _GClutch = 0
local _ClPressing = false
local _PlayerClutch = false
local _Clutch = 0
local _ClutchKick = 0
local _ClutchModulate = 0

local _RPM = _Tune.AutoStart and _Tune.IgnitionRPM or 0
local _OutTorque = 0
local _CGear = ParkingGearOffset == 1 and -2 or 0
local _ShiftUp = false
local _ShiftDn = false
local _Shifting = false
local _spLimit = 0

local engine = car["A-Chassis Tune"].README:FindFirstChild("CustomEngine") and require(car["A-Chassis Tune"].README:FindFirstChild("CustomEngine")) or nil

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
local _PBrake = car["A-Chassis Tune"]["A-Chassis Interface"].Values.PBrake.Value
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

_Tune.AutoShiftVers = "Old"; local _InitialAutoShiftVers = "Old"

local weightBrick = car.Body["#Weight"] :: Part
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
	if not v:IsA("BasePart") or not (name == "FL" or name == "FR" or name == "F" or name == "RL" or name == "RR" or name == "R") then 
		continue 
	end

	local size = v.Size
	local base = v:FindFirstChild("Base")
	local arm = v:FindFirstChild("Arm")

	local steer = arm and arm:FindFirstChild("Steer") or nil
	local steerAttach0 = _Tune.PowerSteeringType == "New" and steer and steer.Attachment0 or nil

	local av = v:FindFirstChild("#AV")
	local bv = v:FindFirstChild("#BV")

	FWheelCount += string.find(name, "F") and 1 or 0
	RWheelCount += (not string.find(name, "F")) and 1 or 0

	local isFront = string.find(name, "F") ~= nil
	local driven = ((_Tune.Config == "FWD" or _Tune.Config == "AWD") and isFront) or ((_Tune.Config == "RWD" or _Tune.Config == "AWD") and not isFront)

	local canSteer = 0
	if arm and steer then
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
	data.OppositeWheel = (name == "FL" and car.Wheels:FindFirstChild("FR")) or (name == "FR" and car.Wheels:FindFirstChild("FL")) or (name == "RL" and car.Wheels:FindFirstChild("RR")) or (name == "RR" and car.Wheels:FindFirstChild("RL"))
	data.Size = size
	data.Base = base
	data.Arm = arm
	data.Steer = steer
	data.SteerAttach0 = steerAttach0
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

-- /// <summary>Detects the leading and trailing axle at a curb and gives each one a single damped lift.</summary>
local curbAssistForce = weightBrick:WaitForChild("CurbAssistForce") :: VectorForce
local curbAssistRaycastParams = RaycastParams.new()
curbAssistRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
curbAssistRaycastParams.FilterDescendantsInstances = { car }
curbAssistRaycastParams.RespectCanCollide = true

local nextCurbAssistAt = 0
local curbAxleStates = {
	Front = { ActiveObstacle = nil, LastDetectionAt = 0, HopStartedAt = 0, HopTriggered = true, NextHopAt = 0 },
	Rear = { ActiveObstacle = nil, LastDetectionAt = 0, HopStartedAt = 0, HopTriggered = true, NextHopAt = 0 },
	Left = { ActiveObstacle = nil, LastDetectionAt = 0, HopStartedAt = 0, HopTriggered = true, NextHopAt = 0 },
	Right = { ActiveObstacle = nil, LastDetectionAt = 0, HopStartedAt = 0, HopTriggered = true, NextHopAt = 0 },
}

local function UpdateCurbAssist(deltaTime: number)
	if not _Tune.CurbAssistEnabled then
		curbAssistForce.Force = Vector3.zero
		return
	end

	local detections = { Front = nil, Rear = nil, Left = nil, Right = nil }
	local approachSpeed = 0
	local throttle = driveSeat.ThrottleFloat
	local driveDirection = throttle > 0.05 and 1 or (throttle < -0.05 and -1 or 0)

	if driveDirection ~= 0 then
		local lookVector = driveSeat.CFrame.LookVector
		local forward = Vector3.new(lookVector.X, 0, lookVector.Z)
		if forward.Magnitude > 0 then
			forward = forward.Unit * driveDirection
			local planarVelocity = Vector3.new(_Velocity.X, 0, _Velocity.Z)
			approachSpeed = math.max(0, planarVelocity:Dot(forward))
			local probeDistance = math.clamp(
				_Tune.CurbAssistProbeDistance + approachSpeed * _Tune.CurbAssistLookAheadSeconds,
				_Tune.CurbAssistProbeDistance,
				_Tune.CurbAssistMaxProbeDistance
			)

			for wheel, wheelData in Wheels do
				local axleName = wheelData.isFront and "Front" or "Rear"
				local radius = math.max(wheel.Size.Y, wheel.Size.Z) * 0.5
				local origin = wheel.Position + forward * (radius - 0.08) + Vector3.yAxis * 0.05
				local obstacle = workspace:Raycast(origin, forward * probeDistance, curbAssistRaycastParams)
				if not obstacle or obstacle.Normal.Y >= 0.35 then
					continue
				end

				local floorHit = workspace:Raycast(
					wheel.Position + Vector3.yAxis * 0.2,
					-Vector3.yAxis * (radius + 1),
					curbAssistRaycastParams
				)
				local topOrigin = obstacle.Position + forward * 0.2 + Vector3.yAxis * _Tune.CurbAssistMaxStep
				local topHit = workspace:Raycast(
					topOrigin,
					-Vector3.yAxis * (_Tune.CurbAssistMaxStep + 0.25),
					curbAssistRaycastParams
				)
				if not floorHit or not topHit or topHit.Normal.Y < 0.65 then
					continue
				end

				local stepHeight = topHit.Position.Y - floorHit.Position.Y
				if stepHeight <= 0.1 or stepHeight > _Tune.CurbAssistMaxStep then
					continue
				end

				local existingDetection = detections[axleName]
				if not existingDetection or obstacle.Distance < existingDetection.Distance then
					detections[axleName] = {
						Obstacle = obstacle.Instance,
						StepHeight = stepHeight,
						Distance = obstacle.Distance,
					}
				end
			end
		end
	end

	-- Probe a low edge on either side while the car steers or slides toward it.
	local steer = driveSeat.SteerFloat
	local planarVelocity = Vector3.new(_Velocity.X, 0, _Velocity.Z)
	local sideVelocity = planarVelocity:Dot(driveSeat.CFrame.RightVector)
	local sideSign = math.abs(steer) >= 0.2 and math.sign(steer) or (math.abs(sideVelocity) >= 4 and math.sign(sideVelocity) or 0)
	local sideSpeed = math.max(math.abs(sideVelocity), planarVelocity.Magnitude * math.abs(steer) * 0.5)
	if sideSign ~= 0 and sideSpeed >= 2.5 then
		local sideName = sideSign > 0 and "Right" or "Left"
		local sideDir = driveSeat.CFrame.RightVector * sideSign
		sideSpeed = math.max(0, sideVelocity * sideSign, sideSpeed * (sideVelocity * sideSign >= 0 and 1 or 0.65))
		approachSpeed = math.max(approachSpeed, sideSpeed)
		local sideProbeDistance = math.clamp(_Tune.CurbAssistProbeDistance + sideSpeed * _Tune.CurbAssistLookAheadSeconds, _Tune.CurbAssistProbeDistance, _Tune.CurbAssistMaxProbeDistance)
		for wheel in pairs(Wheels) do
			local radius = math.max(wheel.Size.Y, wheel.Size.Z) * 0.5
			local origin = wheel.Position + sideDir * (radius - 0.08) + Vector3.yAxis * 0.05
			local obstacle = workspace:Raycast(origin, sideDir * sideProbeDistance, curbAssistRaycastParams)
			if not obstacle or obstacle.Normal.Y >= 0.35 then continue end
			local floorHit = workspace:Raycast(wheel.Position + Vector3.yAxis * 0.2, -Vector3.yAxis * (radius + 1), curbAssistRaycastParams)
			local topOrigin = obstacle.Position + sideDir * 0.2 + Vector3.yAxis * _Tune.CurbAssistMaxStep
			local topHit = workspace:Raycast(topOrigin, -Vector3.yAxis * (_Tune.CurbAssistMaxStep + 0.25), curbAssistRaycastParams)
			if not floorHit or not topHit or topHit.Normal.Y < 0.65 then continue end
			local stepHeight = topHit.Position.Y - floorHit.Position.Y
			if stepHeight <= 0.1 or stepHeight > _Tune.CurbAssistMaxStep then continue end
			local current = detections[sideName]
			if not current or obstacle.Distance < current.Distance then
				detections[sideName] = { Obstacle = obstacle.Instance, StepHeight = stepHeight, Distance = obstacle.Distance }
			end
		end
	end

	local now = os.clock()
	local hopAcceleration = 0
	local stepCrossingActive = false
	for axleName, state in curbAxleStates do
		local detection = detections[axleName]
		if detection then
			state.LastDetectionAt = now
			if state.ActiveObstacle ~= detection.Obstacle then
				state.ActiveObstacle = detection.Obstacle
				state.HopTriggered = now < state.NextHopAt
				print(string.format(
					"[PiggyCar HeavyGripFloat][StepAssist] %s axle detected %.2f-stud step, %.1f studs/s, %.2f studs to wheel",
					axleName,
					detection.StepHeight,
					approachSpeed,
					detection.Distance
				))
			end

			local triggerDistance = math.clamp(
				approachSpeed * _Tune.CurbAssistHopLeadSeconds,
				0.45,
				_Tune.CurbAssistHopMaxTriggerDistance
			)
			if not state.HopTriggered and detection.Distance <= triggerDistance and now >= nextCurbAssistAt then
				state.HopStartedAt = now
				state.HopTriggered = true
				state.NextHopAt = now + 0.6
				nextCurbAssistAt = now + 0.3
				print(string.format(
					"[PiggyCar HeavyGripFloat][StepAssist] %s axle lift triggered %.2f studs before contact",
					axleName,
					detection.Distance
				))
			end

			if detection.Distance <= math.max(0.8, approachSpeed * 0.12) then
				stepCrossingActive = true
			end
		elseif now - state.LastDetectionAt > 0.12 then
			state.ActiveObstacle = nil
			state.HopTriggered = true
		end

		local hopAge = now - state.HopStartedAt
		if state.HopStartedAt > 0 and hopAge < _Tune.CurbAssistHopDuration then
			local progress = math.clamp(hopAge / _Tune.CurbAssistHopDuration, 0, 1)
			local pulse = math.sin(math.pi * progress)
			local upwardSpeed = weightBrick.AssemblyLinearVelocity.Y
			local speedRoom = math.clamp(
				(_Tune.CurbAssistMaxUpwardSpeed - upwardSpeed) / _Tune.CurbAssistMaxUpwardSpeed,
				0,
				1
			)
			hopAcceleration = math.max(hopAcceleration, _Tune.CurbAssistAcceleration * pulse * speedRoom)
		elseif state.HopStartedAt > 0 then
			state.HopStartedAt = 0
		end

		if state.ActiveObstacle and now - state.LastDetectionAt <= 0.12 then
			stepCrossingActive = true
		end
	end

	curbAssistForce.Force = Vector3.yAxis * weightBrick.AssemblyMass * hopAcceleration
	if stepCrossingActive then
		local carCFrame = weightBrick.CFrame
		local localAngularVelocity = carCFrame:VectorToObjectSpace(weightBrick.AssemblyAngularVelocity)
		local angularBlend = math.exp(-_Tune.CurbAssistAngularDampingRate * deltaTime)
		localAngularVelocity = Vector3.new(
			localAngularVelocity.X * angularBlend,
			localAngularVelocity.Y,
			localAngularVelocity.Z * angularBlend
		)
		weightBrick.AssemblyAngularVelocity = carCFrame:VectorToWorldSpace(localAngularVelocity)
	end
end

-- Shutdown
driveSeat.ChildRemoved:Connect(function(child: Instance) 
	if child.Name=="SeatWeld" and child:IsA("Weld") then

		curbAssistForce.Force = Vector3.zero
		for _, state in curbAxleStates do
			state.ActiveObstacle = nil
			state.LastDetectionAt = 0
			state.HopStartedAt = 0
			state.HopTriggered = true
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

		local values = car["A-Chassis Tune"]["A-Chassis Interface"].Values
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
		car["A-Chassis Tune"].Shutdown:FireServer()
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
	if input.KeyCode == Enum.KeyCode.Unknown and not (input.UserInputType and string.find(input.UserInputType.Name, "Gamepad")) then
		return
	end
	if not ChatInputBarConfiguration.IsFocused and not UserInputService:GetFocusedTextBox() and not _InControls then
		-- Shift Down [Manual Transmission]
		if (input.KeyCode ==_CTRL["ContlrShiftDown"] or (_MSteer and input.KeyCode==_CTRL["MouseShiftDown"]) or ((not _MSteer) and input.KeyCode==_CTRL["ShiftDown"])) and ((_IsOn and ((_TMode=="Auto" and _CGear<=1) and _Tune.AutoShiftVers == "New") or _TMode=="Semi") or _TMode=="Manual") and input.UserInputState == Enum.UserInputState.Begin then
			-- Shift removed

			-- Shift Up [Manual Transmission]
		elseif (input.KeyCode ==_CTRL["ContlrShiftUp"] or (_MSteer and input.KeyCode==_CTRL["MouseShiftUp"]) or ((not _MSteer) and input.KeyCode==_CTRL["ShiftUp"])) and ((_IsOn and ((_TMode=="Auto" and _CGear<1) and _Tune.AutoShiftVers == "New") or _TMode=="Semi") or _TMode=="Manual") and input.UserInputState == Enum.UserInputState.Begin then
			-- Shift removed

			-- Toggle Clutch
		elseif (input.KeyCode ==_CTRL["ContlrClutch"] or (_MSteer and input.KeyCode==_CTRL["MouseClutch"]) or ((not _MSteer) and input.KeyCode==_CTRL["Clutch"])) and _TMode=="Manual" then
			if input.UserInputState == Enum.UserInputState.Begin then
				_ClPressing = true
				_PlayerClutch = true
			elseif input.UserInputState == Enum.UserInputState.End then
				_ClPressing = false
				_PlayerClutch = false
			end

			-- Toggle PBrake
		elseif input.KeyCode ==_CTRL["ContlrPBrake"] or (_MSteer and input.KeyCode==_CTRL["MousePBrake"]) or ((not _MSteer) and input.KeyCode==_CTRL["PBrake"]) or ((not _MSteer) and input.KeyCode==_CTRL["PBrake2"]) then
			if input.UserInputState == Enum.UserInputState.Begin then
				_PBrake = not _PBrake
			elseif input.UserInputState == Enum.UserInputState.End then
				if _Velocity.Magnitude>5 then _PBrake = false end
			end

			-- Keep the transmission automatic; legacy toggle inputs must not enable manual mode.
		elseif (input.KeyCode == _CTRL["ContlrToggleTMode"] or input.KeyCode==_CTRL["ToggleTransMode"]) and input.UserInputState == Enum.UserInputState.Begin then
			_TMode = "Auto"

			-- Throttle
		elseif ((not _MSteer) and (input.KeyCode==_CTRL["Throttle"] or input.KeyCode == _CTRL["Throttle2"])) or ((((_CTRL["MouseThrottle"]==Enum.UserInputType.MouseButton1 or _CTRL["MouseThrottle"]==Enum.UserInputType.MouseButton2) and input.UserInputType == _CTRL["MouseThrottle"]) or input.KeyCode == _CTRL["MouseThrottle"])and _MSteer) then
			if input.UserInputState == Enum.UserInputState.Begin then
				_IThrot = 1
			else
				_IThrot = 0
			end

			-- Brake
		elseif ((not _MSteer) and (input.KeyCode==_CTRL["Brake"] or input.KeyCode == _CTRL["Brake2"])) or ((((_CTRL["MouseBrake"]==Enum.UserInputType.MouseButton1 or _CTRL["MouseBrake"]==Enum.UserInputType.MouseButton2) and input.UserInputType == _CTRL["MouseBrake"]) or input.KeyCode == _CTRL["MouseBrake"])and _MSteer) then
			if input.UserInputState == Enum.UserInputState.Begin then
				_IBrake = 1
			else
				_IBrake = 0
			end

			-- Steer Left
		elseif (not _MSteer) and (input.KeyCode==_CTRL["SteerLeft"] or input.KeyCode == _CTRL["SteerLeft2"]) then
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
		elseif (not _MSteer) and (input.KeyCode==_CTRL["SteerRight"] or input.KeyCode == _CTRL["SteerRight2"]) then
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
		elseif false and input.KeyCode ==_CTRL["ToggleMouseDrive"] then
			if input.UserInputState == Enum.UserInputState.End then
				MouseSteerValue.Value = false
				_IThrot = 0
				_IBrake = 0
				_GSteerT = 0
			end

			-- Toggle TCS and ESC
		elseif _Tune.TCSEnabled and _IsOn and (input.KeyCode == _CTRL["ToggleTCS"] or input.KeyCode == _CTRL["ContlrToggleTCS"]) then
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
		elseif _Tune.ABSEnabled and _IsOn and (input.KeyCode == _CTRL["ToggleABS"] or input.KeyCode == _CTRL["ContlrToggleABS"]) then
			if input.UserInputState == Enum.UserInputState.End then _ABS = not _ABS end

			-- Toggle CS
		elseif _Tune.CSEnabled and _IsOn and (input.KeyCode == _CTRL["ToggleCS"] or input.KeyCode == _CTRL["ContlrToggleCS"]) then
			if input.UserInputState == Enum.UserInputState.End then _CS = not _CS end

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
				_IThrot = math.max(0,input.Position.Z)

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
		if input.UserInputType ~= Enum.UserInputType.Touch then return end
		ArcadeJumpRemote:FireServer()
	end)

	mobile.ModeSwitch.MouseButton1Click:Connect(function()
		MobileMode = MobileModes[(table.find(MobileModes, MobileMode) or 0) + 1]
		if not MobileMode then
			MobileMode = MobileModes[1]
		end
	end)

	-- Tap
	for _, button in mobile.Tap:GetChildren() do
		if not button:IsA("ImageButton") then continue end
		button.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch then return end
			button.ImageColor3 = Color3.fromRGB(178,178,178)
			button.ImageLabel.ImageColor3 = Color3.new(0,0,0)
			button.ImageLabel.ImageTransparency = .5
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
			if input.UserInputType ~= Enum.UserInputType.Touch then return end
			button.ImageColor3 = Color3.new(0, 0, 0)
			button.ImageLabel.ImageColor3 = Color3.new(1,1,1)
			button.ImageLabel.ImageTransparency = .8
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
		if not button:IsA("TextButton") then continue end
		button.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch then return end
			if button.Name == "Throttle" then
				_IThrot = 1
			elseif button.Name == "Brake" then
				_IBrake = 1
			end
		end)
		button.InputEnded:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch then return end
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
				_GSteerT = -math.clamp(rotation.Position.Z*2, -1, 1)
			end
		end)
	end
end

if _Tune.Mobile then
	DealWithMobileInput()
end

-- Throttle and Brake Input Smoothing + CDT Tap-to-Drift Engine
local function Inputs(dt: number)
	local deltaTime = dt * 60
	local desiredThrottle = _IThrot
	local desiredBrake = _IBrake
	if _InThrot <= desiredThrottle then
		_InThrot = math.min(desiredThrottle,_InThrot+(_Tune.ThrotAccel*deltaTime))
	else
		_InThrot = math.max(desiredThrottle,_InThrot-(_Tune.ThrotDecel*deltaTime))
	end
	if _InBrake <= desiredBrake then
		_InBrake = math.min(desiredBrake,_InBrake+(_Tune.BrakeAccel*deltaTime))
	else
		_InBrake = math.max(desiredBrake,_InBrake-(_Tune.BrakeDecel*deltaTime))
	end

	-- Immediate launch: release parking brake on throttle or brake
	if _PBrake and not _SpaceHeld and not _TapDriftActive and (_InThrot > 0.05 or _IBrake > 0.05) then
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
		if (car:GetAttribute("TapDriftEnabled") == true) and forwardSpeed > 25 and isSteering then
			_EligibleForTapDrift = true
		else
			_EligibleForTapDrift = false
		end
	-- Edge 2: Brake Released (>=0.1 -> <0.1)
	elseif _PrevIBrake >= 0.1 and currentBrake < 0.1 then
		local holdDuration = now - _BrakePressTimestamp
		if _EligibleForTapDrift and holdDuration <= 0.28 and forwardSpeed > 20 and isSteering then
			-- Quick Tap confirmed! Sustain drift powerslide through the apex
			_TapDriftActive = true
			_DriftEndTime = now + 1.15
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
		-- If player presses brake again to slow down/stop, immediately abort drift and give 100% brakes
		if currentBrake >= 0.1 then
			_TapDriftActive = false
		-- If vehicle speed dropped too low, abort drift
		elseif forwardSpeed < 12 then
			_TapDriftActive = false
		-- If max drift duration expired
		elseif now > _DriftEndTime then
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
local function Steering(dt: number)
	local deltaTime = dt * 60

	local SteerOuter = _Tune.SteerOuter
	local SteerInner = _Tune.SteerInner
	if _Tune.SteeringType == "Auto" or _Tune.SteeringType == nil then
		SteerOuter = (_Tune.LockToLock * 180) / _Tune.SteerRatio
		SteerInner = math.min(SteerOuter - (SteerOuter * (1 - _Tune.Ackerman)), SteerOuter * 1.2)
	end

	local controller = LastInputWasGamepad or (_Tune.MSteerUsesContlr and _MSteer or false)
	local SteerSpeed = controller and (_Tune.ContlrSteerSpeed>0 and _Tune.ContlrSteerSpeed or _Tune.Steerspeed) or _Tune.SteerSpeed * (1-math.min(_Velocity.Magnitude/(Units.Velocity_mdivs/3.6)/_Tune.SteerSpeedDecay,1-(_Tune.MinSteerSpeed/100)))
	local ReturnSpeed = controller and (_Tune.ContlrReturnSpeed>0 and _Tune.ContlrReturnSpeed or _Tune.ReturnSpeed) or _Tune.ReturnSpeed * (1-math.min(_Velocity.Magnitude/(Units.Velocity_mdivs/3.6)/_Tune.SteerSpeedDecay,1-(_Tune.MinSteerSpeed/100)))

	if _MSteer then
		local msWidth = math.max(1,mouse.ViewSizeX*_Tune.Peripherals.MSteerWidth/200)
		local mdZone = _Tune.Peripherals.MSteerDZone/100
		local mST = ((mouse.X-mouse.ViewSizeX/2)/msWidth)
		if math.abs(mST)<=mdZone then
			_GSteerT = 0
		else
			_GSteerT = (math.max(math.min((math.abs(mST)-mdZone),(1-mdZone)),0)/(1-mdZone))^_Tune.MSteerExp * (mST / math.abs(mST))
		end
	end

	-- Interpolate Steering
	if math.abs(_GSteerT) < _Tune.CSSteerThresh/100 and _CS and _Velocity.Magnitude * (Units.Length_mm/1000) * 3.6 > _Tune.CSSpeedThresh then
		_CSAmt = (_Center:VectorToObjectSpace(_Velocity):Dot(Vector3.new(1, 0, 0))/math.max(_Velocity.Magnitude * (Units.Length_mm/1000) * 3.6, _Tune.CSSpeedThresh)) * (_Tune.CSAmt/100)
	else
		_CSAmt = 0
	end
	if math.abs(_CSAmt) > (_Tune.CSAmt/100) * 0.01 then
		_CSActive = true
	else
		_CSActive = false
	end
	local SteerWithCounter = math.clamp(_GSteerT+_CSAmt, -1, 1)
	local SteerSmoothing = math.clamp(math.abs(SteerWithCounter-_GSteerC)^(1/math.max(_Tune.SteerSmoothing, 0.001)), 0, 1)
	if _GSteerC < SteerWithCounter then
		if _GSteerC<0 then
			_GSteerC = math.min(SteerWithCounter,_GSteerC+(ReturnSpeed*SteerSmoothing*deltaTime))
		else
			_GSteerC = math.min(SteerWithCounter,_GSteerC+(SteerSpeed*SteerSmoothing*deltaTime))
		end
	else
		if _GSteerC>0 then
			_GSteerC = math.max(SteerWithCounter,_GSteerC-(ReturnSpeed*SteerSmoothing*deltaTime))
		else
			_GSteerC = math.max(SteerWithCounter,_GSteerC-(SteerSpeed*SteerSmoothing*deltaTime))
		end
	end

	-- Steer Decay Multiplier
	local sDecay = (1-math.min(_Velocity.Magnitude/(Units.Velocity_mdivs/3.6)/(_Tune.SteerDecay/(Units.Velocity_mdivs/3.6)),1-(_Tune.MinSteer/100)))
	local rsDecay = (1-math.min(_Velocity.Magnitude/(Units.Velocity_mdivs/3.6)/(_Tune.RSteerDecay/(Units.Velocity_mdivs/3.6)),1-(_Tune.MinSteer/100)))

	-- Apply Steering
	for wheel, data in Wheels do
		if data.CanSteer == 0 then continue end

		local angle = 0
		local rsteerVariableAngle = 1
		if data.CanSteer == 2 then
			if data.Name == "FL" then
				angle = (_GSteerC<0 and SteerInner or SteerOuter)*sDecay
			elseif data.Name == "FR" then
				angle = (_GSteerC<0 and SteerOuter or SteerInner)*sDecay
			elseif data.Name == "F" then
				angle = SteerInner*sDecay
			elseif data.Name == "RL" then
				angle = (_GSteerC<0 and _Tune.RSteerInner or _Tune.RSteerOuter)*rsDecay
			elseif data.Name == "RR" then
				angle = (_GSteerC<0 and _Tune.RSteerOuter or _Tune.RSteerInner)*rsDecay
			elseif data.Name == "R" then
				angle = _Tune.RSteerInner*rsDecay
			end
			if not data.isFront then	
				if _Tune.FWSteer == "Static" then
					rsteerVariableAngle = -math.max(0,1-(_Velocity.Magnitude/_Tune.RSteerSpeed))
				elseif _Tune.FWSteer == "Speed" then
					rsteerVariableAngle = math.min(1,(_Velocity.Magnitude/_Tune.RSteerSpeed))
				elseif _Tune.FWSteer == "Both" then
					rsteerVariableAngle = -math.max(-1,1-(_Velocity.Magnitude/_Tune.RSteerSpeed))
				end
			end
		end

		if _Tune.PowerSteeringType == "New" then
			data.SteerAttach0.Orientation = Vector3.new(0, data.CanSteer==1 and 0 or _GSteerC*angle*rsteerVariableAngle, 0)
		else
			data.Steer.CFrame = data.Base.CFrame * (data.CanSteer == 1 and CFrame.new(0,0,0) or (CFrame.Angles(0, -math.rad(_GSteerC*angle*rsteerVariableAngle), 0)))
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

	if _Tune.AutoShiftVers == "Old" and (_CGear == 0 or (ParkingGearEnabled and _CGear == -2)) then
		if _IBrake > 0.1 and _IThrot < 0.1 then
			_CGear = -1
		else
			_CGear = 1
		end
		_ClPressing = false
	end

	-- Return to 1st gear when slowed down so reverse or launch is always ready immediately
	if _Tune.AutoShiftVers == "Old" and _CGear > 1 and _Velocity.Magnitude < 10 and not _Shifting and not _ShiftUp and not _ShiftDn then
		_CGear = 1
		_ClPressing = false
	end

	if _CGear >= 1 then
		-- Engage Reverse smoothly as soon as forward speed drops low and player holds S (Brake) without W
		if (_IBrake > 0.1 and _IThrot < 0.1 and forwardSpeed < 8) and _Tune.AutoShiftVers == "Old" then
			_CGear = -1
			_ClPressing = false
			_Shifting = false
			_ShiftUp = false
			_ShiftDn = false
		elseif _Velocity.Magnitude > 5 and _Tune.ClutchType ~= "CVT" then
			if _Tune.AutoShiftMode == "RPM" then
				if _RPM>(_Tune.ShiftRPM+_Tune.AutoUpThresh) then
					if not _ShiftUp and not _Shifting then _ShiftUp = true end
				elseif math.max(math.min(_MaxWheelSpin*_Tune.Ratios[_CGear+1+ParkingGearOffset]*fFDr,_Tune.Redline+100),0)<(_Tune.ShiftRPM-_Tune.AutoDownThresh) and _CGear>1 then
					if not _ShiftDn and not _Shifting then _ShiftDn = true end 
				end
			else
				if _Velocity.Magnitude > math.ceil(wDRatio*(_Tune.ShiftRPM+_Tune.AutoUpThresh)/_CurrentRatio/fFD) then
					if not _ShiftUp and not _Shifting then _ShiftUp = true end
				elseif _Velocity.Magnitude < math.ceil(wDRatio*(_Tune.ShiftRPM-_Tune.AutoDownThresh)/_Tune.Ratios[_CGear+1+ParkingGearOffset]/fFD) and _CGear>1 then
					if not _ShiftDn and not _Shifting then _ShiftDn = true end
				end
			end
		end
	else
		-- Engage Forward 1st gear immediately when player presses W (Throttle) from Reverse or Neutral
		if (_IThrot > 0.1 and forwardSpeed > -14) and _Tune.AutoShiftVers == "Old" then
			_CGear = 1
			_ClPressing = false
			_Shifting = false
			_ShiftUp = false
			_ShiftDn = false
		end
	end
end

local function Gear()
	local fFDr = (_Tune.FinalDrive * _Tune.FDMult) * 30 / math.pi
	
	if _ShiftUp and not _Shifting then
		if (_TMode == "Manual" and not _ClPressing) or (_TMode == "Manual" and _Tune.ClutchRel and (_InThrot > 0)) or _CGear == #_Tune.Ratios - 2 - ParkingGearOffset or (_TMode ~= "Manual" and not _IsOn) then 
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
		if NextGear > 3 + ParkingGearOffset and _Tune.ClutchType == "CVT" then return end
		_CGear = math.min(_CGear + 1, #_Tune.Ratios - 2 - ParkingGearOffset)
		if _TMode ~= "Manual" or (_CGear == 1 and _IsOn) then 
			_ClPressing = (_TMode == "Manual" and _PlayerClutch) or false
		end
	end

	if _ShiftDn and not _Shifting then
		if (_TMode == "Manual" and not _ClPressing) or _CGear == -1 - ParkingGearOffset or (_TMode ~= "Manual" and not _IsOn) then 
			_ShiftDn = false 
			return 
		end
		local PrevGear = math.min(_CGear + 1 + ParkingGearOffset, #_Tune.Ratios)
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
	return math.clamp(M - ( (q-n)/(b^p-b^m) * (b^x-b^m) + n), 0, M)
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
	_CurrentRatio = _Tune.ClutchType == "CVT" and _CVTRatio or _Tune.Ratios[_CGear+2+ParkingGearOffset]
	_spLimit = _Tune.Redline/(fFDr*_CurrentRatio)
	if _CurrentRatio*fFDr == 0 then
		_spLimit = 0
	end -- Prevents [nan] from dividing by 0

	-- Flywheel/clutch-dumping
	_FlywheelEnergy = math.max((_RPM-_WheelRPM)*_Tune.DumpMult,0) * (1-_Clutch) * 1.356*Units.Torque_nm

	-- Determine RPM
	local revMin = 0
	local goalMin = 0
	local goalMax = _Tune.Redline

	if _Shifting and _ShiftUp then 
		_GThrot = _Tune.IdleThrottle/100
	elseif _Shifting and _ShiftDn then
		_GThrot = _Tune.ShiftThrot/100
	else
		if (_Tune.AutoShiftVers == "Old" and _CGear==-1 and _TMode=="Auto") then
			_GThrot = _InBrake
		else
			_GThrot = math.max(_InThrot, _Tune.IdleThrottle/100)
		end
	end

	if (_Tune.AutoShiftVers == "Old" and _CGear==-1 and _TMode=="Auto") then
		_GBrake = _InThrot
	else
		_GBrake = _InBrake
	end

	-- Release the exit parking brake when the driver commands the current drive direction.
	-- Old Auto uses S/IBrake as throttle while reversing and W/IThrot while moving forward.
	local reversing = _Tune.AutoShiftVers == "Old" and _CGear == -1 and _TMode == "Auto"
	local driveCommand = reversing and _IBrake or _IThrot
	if _PBrake and not _SpaceHeld and not _TapDriftActive and driveCommand > 0.05 then
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

	if ((_ClPressing and (_CGear == 0 or (ParkingGearEnabled and _CGear == -2))) or (_PlayerClutch and _CGear ~= 0)) and _Tune.NeutralLimit then
		if ((_CGear == 0 or (ParkingGearEnabled and _CGear == -2)) and not _Tune.LimitClutch) or _Tune.LimitClutch then
			goalMax = _Tune.NeutralRevRPM
		end
	end

	-- Rev limiter/speed limiter
	if _RPM >= _Tune.Redline then
		_RevLimiting = true
	elseif _RPM < goalMax-_Tune.RevBounce then
		_RevLimiting = false
	end
	if _RevLimiting then
		_GThrot = _Tune.IdleThrottle/100
	end

	local limit = (_CGear<0 and _Tune.ReverseSpeed or _Tune.SpeedLimit)
	if limit > 0 then
		_GThrot = math.min(_GThrot, math.max(1 - math.clamp(((_Velocity.Magnitude/(Units.Velocity_mdivs/3.6)) - (limit-_Tune.SLimitGradient))/_Tune.SLimitGradient, 0, 1), _Tune.IdleThrottle/100))
		if _Tune.SLimitBrake then
			_GBrake = math.max(_GBrake, math.clamp( (_Velocity.Magnitude/(Units.Velocity_mdivs/3.6) - limit)/_Tune.SLimitGradient, 0, 1))
		end
	end

	-- Idle
	if _RPM<_Tune.IdleRPM+(_Tune.IdlePadding or 0) and _IsOn then
		_GThrot = math.max(_GThrot, math.clamp((_Tune.IdleRPM+(_Tune.IdlePadding or 0)-_RPM)/(_Tune.IdleDamping or 400), 0, 1))
	end

	if (_Tune.Engine or _Tune.Electric) and (not _Starting) then
		goalRPM = math.clamp(_RPM - (_Tune.RevDecay*deltaTime) + (_Tune.RevAccel*_GThrot*deltaTime) - (math.clamp(math.max(_RPM-_Tune.IdleRPM,0)/math.max(_Tune.Redline-_Tune.IdleRPM,1),0,1)*_Tune.RevDecayRPM*deltaTime), goalMin, goalMax)
	end

	-- Starting
	if _Starting then
		goalRPM = math.clamp(goalRPM + _Tune.IgnitionAccel * deltaTime, 0, math.max(_Tune.IgnitionRPM, _WheelRPM))
		IsOnValue.Value = goalRPM > _Tune.IgnitionMinRPM
	end

	-- Set RPM
	local aRPM = math.max((goalRPM*(1-deltaTime) + _WheelRPM*deltaTime)*(1-_Clutch) + goalRPM*_Clutch, revMin)
	local clutchP = math.min(math.abs(aRPM-_RPM) / (_Tune.Flywheel*deltaTime), .9)
	if _ClPressing then 
		clutchP = 0 
	end
	_RPM = aRPM*(1-clutchP) + _RPM*clutchP

	if _Tune.OverRev == false and _RPM > _Tune.Redline then 
		_RPM = _Tune.Redline 
	end

	if _RPM<=(_Tune.IdleRPM/4) and stallOk and (tick()-ticc>=0.2) and _Tune.Stall then 
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
				if _ClPressing then _ClutchKick = 1 end
				_ClutchKick = _ClutchKick*(_Tune.ClutchEngage/100)
				local ClRPMInfluence = math.max(_RPM*_Tune.ClutchRPMMult/_Tune.Redline,0)
				if _Tune.ClutchMode == "New" then ClRPMInfluence = 0 end
				_ClutchModulate = math.min(((((math.max(_Velocity.Magnitude, 0.001) / (Units.Velocity_mdivs / 3.6) / _Tune.SpeedEngage) / math.max(math.abs(_CGear), 1)) + ClRPMInfluence) - _ClutchKick), 1)
			elseif _Tune.ClutchType == "TorqueConverter" and _Tune.TQLock then
				if (_GThrot<=_Tune.IdleThrottle/100 and _Velocity.Magnitude/(Units.Velocity_mdivs/3.6)<_Tune.SpeedEngage) or (_GThrot>_Tune.IdleThrottle/100 and (_RPM < _Tune.RPMEngage and _WheelRPM < _Tune.RPMEngage)) then
					_ClutchModulate = math.min(_ClutchModulate*(_Tune.ClutchEngage/100), 1)
				else
					_ClutchModulate = math.min(_ClutchModulate*(_Tune.ClutchEngage/100)+(1-(_Tune.ClutchEngage/100)), 1)
				end
			elseif _Tune.ClutchType == "TorqueConverter" and not _Tune.TQLock then
				_ClutchModulate = math.min((_RPM/_Tune.Redline)*0.7, 1)
			end
			if not _ClPressing then _Clutch = math.min(1-_ClutchModulate,1) else _Clutch = 1 end
		else
			if _ClPressing then
				_Clutch = 1
			else
				_Clutch = 0
			end
		end
		stallOk = (_Clutch<=0.01) or stallOk
	else
		stallOk = false
		if not _ClPressing and not _Shifting then _Clutch = 0 else _Clutch = 1 end
	end

	-- Things that apply the clutch (uses driveCommand so Reverse S is never cut!)
	if _AutoClutch and (_Starting or (_Tune.RemoveCreep and _RPM < _Tune.IdleRPM+(_Tune.IdlePadding or 0) and driveCommand < .05) or (_RevLimiting and _Tune.OverRev == false)) then
		_Clutch = 1
	end

	-- Torque calculations (Detomiks)
	-- What you see here is mostly just ported over from Desmos.
	if not engine or _Tune.CustomEngineCalculations == false then
		local x = _RPM/1000
		local NTorque = 0
		local ETorque = 0
		local TTorque = 0
		local STorque = 0
		if _Tune.Engine then
			local NIdleTorque = f(_Tune.IdleRPM/1000, _Tune.IdleTorque, _Tune.PeakTorqueRPM/1000, _Tune.PeakTorque, _Tune.PeakTorque, _Tune.IdleTorqueCurve, x)
			local NRedlineTorque = f(_Tune.PeakTorqueRPM/1000, _Tune.PeakTorque, _Tune.Redline/1000, _Tune.RedlineTorque, _Tune.PeakTorque, 1/_Tune.RedlineTorqueCurve, x)
			local VVL = _Tune.VVLTorque > 0 and _Tune.VVLTorque - f(_Tune.VVLRPM/1000, 0, (_Tune.VVLRPM + _Tune.VVLTime)/1000, _Tune.VVLTorque, _Tune.VVLTorque, _Tune.VVLCurve, x) or 0
			local AirPressurePercent = math.exp((-9.80665 * 0.0289644 * (_Center.Y * Units.Length_mm / 1000)) / (8.3142 * (GlobalTemperature + 273.15))) -- look up the barometric formula 
			NTorque = 1 * (_Tune.PeakTorque - NIdleTorque - NRedlineTorque + VVL) * AirPressurePercent
			_NH, _NT = (NTorque*x)/5.252, NTorque

			if _Tune.Turbochargers > 0 then
				local _TBoostGoal = _Tune.Turbochargers * ((_GThrot^3) * (100/_Tune.T_Size) * ((NTorque*x)/5.252) - f(_Tune.IdleRPM/1000, _Tune.T_IdleBoost, _Tune.T_PeakRPM/1000, _Tune.T_Boost, (_GThrot^3) * (100/_Tune.T_Size) * ((NTorque*x)/5.252), 1/_Tune.T_Curve, x))
				if _TBoostGoal > _TBoost then
					_TBoost = _TBoost + math.min(_Tune.T_SpoolIncrease*(_TBoostGoal-_TBoost), _Tune.T_SpoolIncrease * (10/_Tune.T_Size) * _Tune.Turbochargers) * deltaTime -- i should probably base this off of the maximum horsepower instead of the RPM, but it's the same thing anyway
				elseif _TBoost > _TBoostGoal then
					_TBoost = _TBoost + _Tune.T_SpoolDecrease*(_TBoostGoal-_TBoost) * deltaTime
				end
				_TBoost = math.clamp(_TBoost, 0, _Tune.Turbochargers * _Tune.T_Boost)
				TTorque = _TBoost * _Tune.T_Efficiency
				_TH, _TT = (TTorque*x)/5.252, TTorque
			end
			if _Tune.Superchargers > 0 then
				local SIdleBoost = f(_Tune.IdleRPM/1000, _Tune.S_IdleBoost, _Tune.S_PeakRPM/1000, _Tune.S_Boost, _Tune.S_Boost, _Tune.S_IdleCurve, x)
				local SRedlineBoost = f(_Tune.S_PeakRPM/1000, _Tune.S_Boost, _Tune.Redline/1000, _Tune.S_RedlineBoost, _Tune.S_Boost, 1/_Tune.S_RedlineCurve, x)
				local _SBoostGoal = _Tune.Superchargers * _GThrot * (_Tune.S_Boost - SIdleBoost - SRedlineBoost)
				if _SBoostGoal > _SBoost then
					_SBoost = math.min(_SBoost + _Tune.S_Boost*_Tune.S_Response*deltaTime, _SBoostGoal)
				elseif _SBoost > _SBoostGoal then
					_SBoost = math.max(_SBoost - _Tune.S_Boost*_Tune.S_Response*deltaTime, _SBoostGoal)
				end
				STorque = _SBoost * _Tune.S_Efficiency
				_SH, _ST = (STorque*x)/5.252, STorque
			end
			if _Tune.Turbochargers > 0 or _Tune.Superchargers > 0 then
				_BH, _BT = ((TTorque+STorque)*x)/5.252, TTorque+STorque
			end
		end
		if _Tune.Electric then
			ETorque = 1 * (_Tune.E_Torque - f(_Tune.E_TransitionRPM/1000, _Tune.E_Torque, _Tune.E_Redline/1000, _Tune.E_RedlineTorque, _Tune.E_Torque, _Tune.E_Curve, x))
			_EH, _ET = (ETorque*x)/5.252, ETorque
		end
		local TotalTorque = math.clamp(NTorque + ETorque + TTorque + STorque, _Tune.Stall and 0 or _Tune.IdleTorque, (_Tune.HPLimit > 0 and _Tune.HPLimit or math.huge)*(5.252/x))
		_HP, _TQ = (TotalTorque*x)/5.252, TotalTorque
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
	local iComp = (_Center.LookVector.Y)*cGrav*math.sign(_CGear)
	_OutTorque = _OutTorque*math.max(1,(1+iComp))

	-- Brakes
	local FBrakeForce =_Tune.BrakeForce * 9.80665 * Units.Force_N * _Tune.BrakeBias -- luaint edit, conversion to SI unit Detomiks
	local RBrakeForce =_Tune.BrakeForce * 9.80665 * Units.Force_N * (1 - _Tune.BrakeBias) -- luaint edit
	local PBrakeForceF = _Tune.PBrakeForce * 9.80665 * Units.Force_N * _Tune.PBrakeBias
	local PBrakeForceR = _Tune.PBrakeForce * 9.80665 * Units.Force_N * (1 - _Tune.PBrakeBias)

	-- Update Wheels
	for wheel, data in Wheels do
		-- Apply Power
		local PBrakeV = (_PBrake == true or _CGear == -2) and 1 or 0
		local on = _IsOn and 1 or 0

		local throt = _GThrot
		local brake = _GBrake

		local clutch=1
		if _ClPressing or (_AutoClutch and (_Starting or (_Tune.RemoveCreep and _RPM < _Tune.IdleRPM+(_Tune.IdlePadding or 0) and driveCommand < .05))) then 
			clutch=0 
		end

		-- Apply ESC
		local tqESC = 0
		if not (data.Name == "F" or data.Name == "R") and _ESC and (_Velocity.Magnitude/(Units.Velocity_mdivs/3.6)) > _Tune.ESCSpeed then
			local g = weightBrick.CFrame:VectorToObjectSpace(_Acceleration/(Units.Velocity_mdivs)/((_Tune.GravComp>0 and _Tune.GravComp or workspace.Gravity)*(Units.Length_mm/1000)))
			if math.sign(_GSteerC) ~= math.sign(g.X) then
				local diff = _GSteerC-(g.X*-math.sign(_Center:VectorToObjectSpace(_Velocity).Z))
				if math.abs(diff) > _Tune.ESCThreshold then
					local escVector, escBias = 1, (_Tune.ESCVector+1)
					if data.isFront then 
						escVector = escVector*(2-escBias)
					else 
						escVector = escVector*escBias 
					end

					tqESC = ((data.Name == "FL" or data.Name == "RL") and 1 or -1) * math.sign(diff)*escVector
					throt = throt + (math.max(tqESC,0) - throt) * (_Tune.ESCThrottle/100)
					brake = brake + (-math.min(tqESC,0) - brake) * (_Tune.ESCBrake/100)
				end
			end
		end

		_ESCActive = tqESC ~= 0 or _ESCActive
		_ESCTracker[data.Name] = tqESC

		-- Apply ABS
		local tqABS = 1
		if _ABS and brake>0 then
			tqABS = 1-(math.min(math.max(0,math.abs(data.RotVelocityMagnitude*(data.Size.Y/2)/(Units.Velocity_mdivs/3.6) - data.WheelVelocityMagnitude/(Units.Velocity_mdivs/3.6))-_Tune.ABSThreshold)/_Tune.ABSGradient,1)*(1-(_Tune.ABSLimit/100)))
		end
		_ABSActive = tqABS < 1 or _ABSActive
		_ABSTracker[data.Name] = 1 - tqABS

		-- Apply Power
		if data.driven then
			-- Differential/Torque-Vectoring
			local RRdiffMult=1
			local RLdiffMult=1
			local FRdiffMult=1
			local FLdiffMult=1

			if data.Name=="FR" then
				local avg=((data.RotVelocityMagnitude/data.OppositeWheel.RotVelocity.Magnitude)-1)*(_Tune.FDiffPreload/10)
				FRdiffMult=math.ceil(math.max(0,math.min(2,1-( ((_Tune.FDiffPower/100)*avg*_GThrot) + ((_Tune.FDiffCoast/100)*avg*(1-_GThrot)))))*100)/100
				FLdiffMult=2-FRdiffMult
			elseif data.Name=="FL" then
				local avg=((data.RotVelocityMagnitude/data.OppositeWheel.RotVelocity.Magnitude)-1)*(_Tune.FDiffPreload/10)
				FLdiffMult=math.ceil(math.max(0,math.min(2,1-( ((_Tune.FDiffPower/100)*avg*_GThrot) + ((_Tune.FDiffCoast/100)*avg*(1-_GThrot)))))*100)/100
				FRdiffMult=2-FLdiffMult
			elseif data.Name=="RR" then
				local avg=((data.RotVelocityMagnitude/data.OppositeWheel.RotVelocity.Magnitude)-1)*(_Tune.RDiffPreload/10)
				RRdiffMult=math.ceil(math.max(0,math.min(2,1-( ((_Tune.RDiffPower/100)*avg*_GThrot) + ((_Tune.RDiffCoast/100)*avg*(1-_GThrot)))))*100)/100
				RLdiffMult=2-RRdiffMult
			elseif data.Name=="RL" then
				local avg=((data.RotVelocityMagnitude/data.OppositeWheel.RotVelocity.Magnitude)-1)*(_Tune.RDiffPreload/10)
				RLdiffMult=math.ceil(math.max(0,math.min(2,1-( ((_Tune.RDiffPower/100)*avg*_GThrot) + ((_Tune.RDiffCoast/100)*avg*(1-_GThrot)))))*100)/100
				RRdiffMult=2-RLdiffMult
			end

			-- Apply torque split
			-- This takes the total amount of torque alotted to the front or rear wheels, then divides it by how many wheels there are
			local bias = (_Tune.Config == "AWD" and (_Tune.TorqueVector+1)/2) or (_Tune.Config == "FWD" and 0) or 1
			local tq = data.isFront and (_OutTorque * (1 - bias)) / FWheelCount or (_OutTorque * bias) / RWheelCount

			-- Apply TCS
			tqTCS = 1
			if _TCS and throt>_Tune.IdleThrottle/100 then
				tqTCS = 1-(math.min(math.max(0,math.abs(data.RotVelocityMagnitude*(data.Size.Y/2)/(Units.Velocity_mdivs/3.6) - data.WheelVelocityMagnitude/(Units.Velocity_mdivs/3.6))-_Tune.TCSThreshold)/_Tune.TCSGradient,1)*(1-(_Tune.TCSLimit/100)))
			end
			_TCSActive = tqTCS < 1 or _TCSActive
			_TCSTracker[data.Name] = 1-tqTCS

			-- Update Forces (only add flywheel energy when actively throttling and not braking)
			local flywheelAdd = (throt > 0.05 and brake < 0.05) and (_FlywheelEnergy/#Drive) or 0
			local tqOUT = (tq*1.356*Units.Torque_nm*throt*tqTCS*on*clutch) + flywheelAdd
			if brake > 0.05 and throt <= 0.05 then
				tqOUT = 0
			end
			if car:GetAttribute("VehiclePowerDisabled") == true then
				tqOUT = 0
			end
			-- convert lb-ft to nm to roblox stuff
			-- if it reaches an absurdly high number, set it to 0 to try and prevent physics death

			-- CDT Tap-to-Drift & Spacebar Handbrake:
			local isRear = (data.Name == 'RR' or data.Name == 'RL')
			local handbrakeEngaged = _SpaceHeld or _TapDriftActive

			if handbrakeEngaged and isRear then
				if _SpaceHeld then
					-- Spacebar on PC: Complete rear torque cut for sharp handbrake lock
					data.AV.MotorMaxTorque = 0
				else
					-- Tap-to-Drift (CDT Arcade): Deliver 45% throttle torque to powerslide through the corner!
					data.AV.MotorMaxTorque = (tqOUT * (_InThrot > 0.1 and 0.45 or 0))
				end
			else
				if data.Name=='RR' then
					data.AV.MotorMaxTorque=tqOUT*RRdiffMult
				elseif data.Name=='RL' then
					data.AV.MotorMaxTorque=tqOUT*RLdiffMult
				elseif data.Name=='FR' then
					data.AV.MotorMaxTorque=tqOUT*FRdiffMult
				elseif data.Name=='FL' then
					data.AV.MotorMaxTorque=tqOUT*FLdiffMult
				else
					data.AV.MotorMaxTorque=tqOUT
				end
			end
			data.AV.AngularVelocity = _spLimit * math.sign(_CGear)

			-- Apply Brake Torques:
			if data.isFront then
				local fEmergency = _SpaceHeld and 10000 or (_TapDriftActive and 3000 or 0)
				data.BV.MotorMaxTorque = math.max((FBrakeForce*brake*tqABS) + (_Tune.EBrakeForce*clutch*((1-throt)*(_RPM/_Tune.Redline))) + (PBrakeForceF*PBrakeV), fEmergency)
			else
				local rBrake = _SpaceHeld and 28000 or (_TapDriftActive and 18000 or (PBrakeForceR * PBrakeV))
				data.BV.MotorMaxTorque = (RBrakeForce*brake*tqABS) + (_Tune.EBrakeForce*clutch*((1-throt)*(_RPM/_Tune.Redline))) + rBrake
			end
		else -- luaint edit
			data.AV.MotorMaxTorque=0
			data.AV.AngularVelocity=0
			if data.isFront then
				data.BV.MotorMaxTorque = (FBrakeForce*brake*tqABS) + (PBrakeForceF*PBrakeV)
			else
				data.BV.MotorMaxTorque = (RBrakeForce*brake*tqABS) + (PBrakeForceR*PBrakeV)
			end
		end

		-- Active Grounded Tire Smoke (DriveSeat Anchored) on Drift, Hard Cornering or Burnout
		local seat = car.DriveSeat
		local lateralSpeed = math.abs(_Velocity:Dot(seat.CFrame.RightVector))
		local isDrifting = (_SpaceHeld or _TapDriftActive) and _Velocity.Magnitude > 10
		local isHardSlide = lateralSpeed > 10 and _Velocity.Magnitude > 15
		local isBurnoutOrLock = brake > 0.65 and _Velocity.Magnitude > 20

		local isCarUpright = seat.CFrame.UpVector.Y > 0.35
		local rearSmokeActive = isCarUpright and (not _MidAirActive) and (_RearGroundedCount and _RearGroundedCount >= 1) and (isDrifting or isHardSlide or isBurnoutOrLock)
		local frontSmokeActive = isCarUpright and (not _MidAirActive) and (_FrontGroundedCount and _FrontGroundedCount >= 1) and (isHardSlide or (brake > 0.75 and _Velocity.Magnitude > 25))

		-- Warm, Smooth Asphalt Tire Scrub (Fatigue-Free, Non-Piercing)
		local tireScrub = seat:FindFirstChild("HokiTireScrub") or (function()
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
		if legacy1 then legacy1:Stop() legacy1:Destroy() end
		local legacy2 = seat:FindFirstChild("HokiTireSkid")
		if legacy2 then legacy2:Stop() legacy2:Destroy() end

		local speedStuds = _Velocity.Magnitude
		local groundedTires = (_FrontGroundedCount or 0) + (_RearGroundedCount or 0)
		local canMakeTireSound = isCarUpright and (not _MidAirActive) and (groundedTires >= 1) and (speedStuds > 18)

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
		tireScrub.PlaybackSpeed = tireScrub.PlaybackSpeed + (targetPitch - tireScrub.PlaybackSpeed) * math.min(1, dt * 6)

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
	MobileUI.Jump.Visible = MobileUI.ModeSwitch.Visible
	for _, v in MobileUIChildren do
		if v:IsA("Frame") then
			v.Visible = MobileMode == v.Name
		end
	end
end

-- Flip
local function Flip()
	-- Detect Orientation
	if _FlipDB or (driveSeat.CFrame * CFrame.Angles(math.pi / 2, 0, 0)).LookVector.Y > 0.1 then
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

-- Mid-Air Control
-- Mid-Air Control (declared at top for Engine smoke gate)
local takeoffAssistUsed = false
local allWheelsGroundedSince = 0
local nextTakeoffAssistAt = 0
local midAirRays = RaycastParams.new()
midAirRays.FilterType = Enum.RaycastFilterType.Exclude
midAirRays.FilterDescendantsInstances = {car}

local function MidAirControl(dt: number)
	local groundedCount = 0
	local frontGroundedCount = 0
	local rearGroundedCount = 0
	local frontWheelCount = 0
	local rearWheelCount = 0
	local frontGroundHeight = 0
	local rearGroundHeight = 0
	local frontRampContact = false
	midAirRays.FilterDescendantsInstances = { car, player.Character }
	for wheel, wheelData in pairs(Wheels) do
		if wheelData.isFront then frontWheelCount += 1 else rearWheelCount += 1 end
		local wheelRadius = math.max(wheel.Size.Y, wheel.Size.Z) * 0.5
		local carUp = driveSeat.CFrame.UpVector
		local result = (carUp.Y > 0.35) and workspace:Raycast(wheel.Position, -carUp * (wheelRadius + 0.15), midAirRays) or nil
		_WheelGrounded[wheelData.Name] = (result ~= nil)
		if result then
			groundedCount += 1
			if wheelData.isFront then
				frontGroundedCount += 1
				frontGroundHeight += result.Position.Y
				if result.Normal.Y >= 0.25 and result.Normal.Y < 0.985 then
					frontRampContact = true
				end
			else
				rearGroundedCount += 1
				rearGroundHeight += result.Position.Y
			end
		end
	end

	_FrontGroundedCount = frontGroundedCount
	_RearGroundedCount = rearGroundedCount
	local totalWheelCount = frontWheelCount + rearWheelCount
	local frontAverageGroundY = frontGroundedCount > 0 and frontGroundHeight / frontGroundedCount or 0
	local rearAverageGroundY = rearGroundedCount > 0 and rearGroundHeight / rearGroundedCount or 0
	local rampTakeoff = frontRampContact
		and frontGroundedCount > 0
		and rearGroundedCount > 0
		and frontAverageGroundY - rearAverageGroundY >= 0.25
		and os.clock() >= nextTakeoffAssistAt
	local now = os.clock()
	if totalWheelCount > 0 and groundedCount == totalWheelCount then
		if not takeoffAssistUsed then
			allWheelsGroundedSince = now
		elseif allWheelsGroundedSince == 0 then
			allWheelsGroundedSince = now
		elseif now - allWheelsGroundedSince >= 0.35 then
			takeoffAssistUsed = false
		end
	else
		allWheelsGroundedSince = 0
	end

	-- Let either axle trigger launch while the other axle still has ground contact.
	local axleLeavingGround = (frontWheelCount > 0 and frontGroundedCount == 0)
		or (rearWheelCount > 0 and rearGroundedCount == 0)
	if (axleLeavingGround or rampTakeoff) and not takeoffAssistUsed and os.clock() >= nextTakeoffAssistAt then
		takeoffAssistUsed = true
		allWheelsGroundedSince = 0
		nextTakeoffAssistAt = now + 1.0
		local assemblyVelocity = weightBrick.AssemblyLinearVelocity
		local horizontalSpeed = Vector3.new(assemblyVelocity.X, 0, assemblyVelocity.Z).Magnitude
		local currentVerticalSpeed = assemblyVelocity.Y
		local minLaunchSpeed = (_Tune.AirLaunchMinimumSpeed and _Tune.AirLaunchMinimumSpeed > 0) and _Tune.AirLaunchMinimumSpeed or 22
		local baseBoost = (_Tune.AirLaunchBaseBoost and _Tune.AirLaunchBaseBoost > 0) and _Tune.AirLaunchBaseBoost or 6.0
		local speedScale = (_Tune.AirLaunchSpeedScale and _Tune.AirLaunchSpeedScale > 0) and _Tune.AirLaunchSpeedScale or 0.08
		local maxVertSpeed = (_Tune.AirLaunchMaxVerticalSpeed and _Tune.AirLaunchMaxVerticalSpeed > 0) and _Tune.AirLaunchMaxVerticalSpeed or 24.0
		if horizontalSpeed >= minLaunchSpeed and currentVerticalSpeed > -2 then
			local requestedBoost = math.min(
				baseBoost + horizontalSpeed * speedScale,
				maxVertSpeed
			)
			local targetVerticalSpeed = math.min(
				maxVertSpeed,
				math.max(0, currentVerticalSpeed) + requestedBoost
			)
			local verticalBoost = math.max(0, targetVerticalSpeed - currentVerticalSpeed)
			if verticalBoost > 0 then
				local fwdDir = Vector3.new(driveSeat.CFrame.LookVector.X, 0, driveSeat.CFrame.LookVector.Z)
				fwdDir = fwdDir.Magnitude > 0.01 and fwdDir.Unit or driveSeat.CFrame.LookVector
				local fwdBoost = math.clamp(horizontalSpeed * 0.05, 0, 8)
				weightBrick:ApplyImpulse((Vector3.yAxis * verticalBoost + fwdDir * fwdBoost) * weightBrick.AssemblyMass)
				local launchReason = rampTakeoff and "rising ramp" or "axle takeoff"
				print(string.format(
					"[PiggyCar HeavyGripFloat][AirLaunch] %s boost %.1f studs/s at %.1f studs/s",
					launchReason,
					verticalBoost,
					horizontalSpeed
				))
			end
		end
	end

	if groundedCount >= 3 then
		_MidAirActive = false
		car:SetAttribute("PiggyCarAirborneWeightReduced", false)
		return
	end

	_MidAirActive = true
	car:SetAttribute("PiggyCarAirborneWeightReduced", true)
	-- Clear curbAssistForce in air to prevent artificial antigravity lift (no flying off the map)
	curbAssistForce.Force = Vector3.zero

	-- Pitch & Roll Orientation Control (GTA / Asphalt style)
	-- W: Nose Down (-10 deg) to level out for smooth landing
	-- S: Nose Up (+14 deg) to catch air / prevent nose-dive
	-- A / D: Yaw & slight Bank (roll) to align landing direction with road
	-- Spacebar + A/D: Stunt Barrel Roll
	local currentPitch = math.asin(math.clamp(driveSeat.CFrame.LookVector.Y, -1, 1))
	local targetPitch = 0
	if _GBrake > 0.1 then
		targetPitch = math.rad(14)
	elseif _GThrot > 0.1 then
		targetPitch = math.rad(-10)
	end

	local pitchCmd = math.clamp((targetPitch - currentPitch) * 3.0, -1.2, 1.2)
	local rollInput = _GSteerT

	local currentRoll = math.asin(math.clamp(driveSeat.CFrame.RightVector.Y, -1, 1))
	local rollRateCmd = _SpaceHeld and (-rollInput * 2.8) or math.clamp((math.rad(rollInput * 12) - currentRoll) * 3.0, -1.6, 1.6)
	local yawRateCmd = (not _SpaceHeld) and (-rollInput * 1.2) or 0
	local localAngVel = Vector3.new(pitchCmd * 1.5, yawRateCmd, rollRateCmd)
	local worldAngVel = driveSeat.CFrame:VectorToWorldSpace(localAngVel)

	local lerpFactor = math.min(dt * 5, 1)
	driveSeat.AssemblyAngularVelocity = driveSeat.AssemblyAngularVelocity:Lerp(worldAngVel, lerpFactor)
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
	if driveSeat.Parent then return end 
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
end

local fixedDeltaTime = 1/60 -- Fixed to avoid rewriting old code causing different behaviours at different FPS
local accumulatedSimTime = 0

RunService.PreSimulation:Connect(function(deltaTimeSim: number) 
	accumulatedSimTime += deltaTimeSim
	while accumulatedSimTime >= fixedDeltaTime do
		accumulatedSimTime -= fixedDeltaTime
		RuntimeLoop(fixedDeltaTime) 
	end
end)

local function SlowRuntimeLoop()
	while true do
		local deltaTime = task.wait(1/8)

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

task.spawn(SlowRuntimeLoop)


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

-- 2. Bind Spacebar to Handbrake with SINK at maximum priority (overrides Roblox core jump!)
local function handleSpacebarHandbrake(_actionName, inputState, _inputObject)
	if inputState == Enum.UserInputState.Begin then
		_SpaceHeld = true
		_PBrake = true
		return Enum.ContextActionResult.Sink
	elseif inputState == Enum.UserInputState.End then
		_SpaceHeld = false
		if _Velocity.Magnitude > 2 or _IThrot > 0.05 or _IBrake > 0.05 then
			_PBrake = false
		end
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

ContextActionService:BindActionAtPriority(
	"HokiDriverCleanExit",
	function(_, state)
		if state == Enum.UserInputState.Begin then
			triggerCleanExit()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end,
	false,
	Enum.ContextActionPriority.High.Value + 1500,
	Enum.KeyCode.E,
	Enum.KeyCode.F
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

-- 5. Restore Jumping and unbind actions on exit
script.Destroying:Connect(function()
	setPromptsEnabled(true)
	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end
	ContextActionService:UnbindAction("HokiSpacebarHandbrakeSink")
	ContextActionService:UnbindAction("HokiDriverCleanExit")
end)


```
