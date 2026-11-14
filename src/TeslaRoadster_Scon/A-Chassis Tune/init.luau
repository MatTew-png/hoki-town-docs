--[[	
		             _____ _                   _     
	     /\         / ____| |                 (_)    
	    /  \ ______| |    | |__   __ _ ___ ___ _ ___ 
	   / /\ \______| |    | '_ \ / _` / __/ __| / __|
	  / ____ \     | |____| | | | (_| \__ \__ \ \__ \
	 /_/    \_\     \_____|_| |_|\__,_|___/___/_|___/
	 Version 1.7
--]]

--[[ ============================================================
	CONFIG α╕½α╕Ñα╕▒α╕ü - α╕¢α╕úα╕▒α╕Üα╕ùα╕╡α╣êα╕Öα╕╡α╣êα╕ùα╕╡α╣êα╣Çα╕öα╕╡α╕óα╕º
	(α╕äα╣êα╕▓α╕¡α╕╖α╣êα╕Öα╕öα╣ëα╕▓α╕Öα╕Ñα╣êα╕▓α╕çα╕¡α╕┤α╕çα╕êα╕▓α╕üα╕Üα╕Ñα╣çα╕¡α╕üα╕Öα╕╡α╣ë)
============================================================ ]]
local Config = {
	-- ความเร็วและอัตราเร่ง (Urban Arcade 170 km/h High-Torque Edition)
	TopSpeed = 170, -- ล็อกเพดานความเร็ว 170 km/h คุมง่ายในเมืองตามคลิปต้นแบบ
	FinalDrive = 4.15,
	Acceleration = 13.5, -- อัตราเร่งต้นจัด 0-170 km/h ทันใจหลังชนหรือเลี้ยว
	ThrottleResponse = 0.78,

	-- เลี้ยวแบบอาร์เคด (Arcade Steering)
	ArcadeSteering = true,
	ArcadeSteerMinTurnRadius = 11.5, -- จำกัดอัตราการหมุนที่ความเร็วต่ำ (1 km/h ไม่หมุนควงสว่าน)
	ArcadeSteerLowSpeedDegPerSec = 170,
	ArcadeSteerHighSpeedDegPerSec = 125,
	ArcadeSteerFullSpeedKmh = 140,
	ArcadeSteerMinMoveStudsPerSec = 1.5,
	ArcadeSteerFullMoveStudsPerSec = 10,
	ArcadeSteerResponse = 22,
	ArcadeSteerReleaseDamping = 16,
	ArcadeVelocityFollow = 0.92,
	ArcadeLateralGrip = 14,
	ArcadeRollStability = 16,
	ArcadeRollDamping = 12,
	ArcadeVisualWheelAngleLow = 28,
	ArcadeVisualWheelAngleHigh = 12,

	-- วงเลี้ยว / พวงมาลัย
	MaxSteerAngle = 36,
	SteerSpeed = 1.2,
	ReturnSpeed = 1.8,
	SteerAtTopSpeed = 52,
	SteerDecaySpeed = 135,

	-- น้ำหนัก / ตอนรถเหิน (Arcade Stunt Hang-time & Ramp Launch)
	Weight = 1180, -- ปรับน้ำหนักลงให้อารมณ์รถสปอร์ตเบาคล่องตัว เหินพุ่งง่ายขึ้น
	GroundGravity = 196.2,
	AirGravity = 88.0, -- แรงโน้มถ่วงกลางอากาศสไตล์อาร์เคด (ลอยตัวสวยงามแบบในคลิป ไม่ทิ้งดิ่งเป็นหินและไม่ลอยค้าง)
	AirborneDensityScale = 0.80,
	AirLaunchMinimumSpeed = 10,
	AirLaunchBaseBoost = 28.0, -- แรงดีดส่งเหินเวลาแตะขอบแรมป์/เนิน
	AirLaunchSpeedScale = 0.35, -- ยิ่งวิ่งเร็วมาเทคออฟ ยิ่งเหินได้ไกลและสูงขึ้น
	AirLaunchMaxVerticalSpeed = 75.0, -- เพดานความเร็วแนวตั้งตอนเทคออฟ
	AirPitchDownSpeed = 0.20, -- กด W กลางอากาศแล้วหัวก้มลงช้า/ยากขึ้น (ต้านทานการทิ่มหัว)
	AirPitchUpSpeed = 1.25, -- กด S เชิดหัวขึ้นยังตอบสนองดี
	AirRollSpeed = 1.40, -- กด A/D หมุนควงตัวรถ

	-- ปิดระบบดูดไต่กำแพงแนวตั้ง (ใช้การเชิดข้ามรั้ว/ขอบทางตามธรรมชาติเหมือนคลิป)
	WallClimbEnabled = false,
	WallClimbMinHeight = 4.2,
	WallClimbProbeDist = 6.0,
	WallClimbAdhesionForce = 0,
	WallClimbDriveSpeed = 0,
	WallClimbPitchRate = 0,
	WallClimbCrestUpBoost = 0,
	WallClimbCrestForwardBoost = 0,

	-- Curb Assist & Recovery (รองรับการเชิดข้ามฟุตบาทและรั้วเตี้ยถึง 4.2 studs ที่ความเร็ว 170 km/h)
	CurbAssistEnabled = true,
	CurbAssistMaxStep = 4.2,
	CurbAssistProbeDistance = 2.6,
	CurbAssistAcceleration = 290,
	CurbAssistLookAheadSeconds = 0.28,
	CurbAssistMaxProbeDistance = 16,
	CurbAssistHopLeadSeconds = 0.14,
	CurbAssistHopMaxTriggerDistance = 9.5,
	CurbAssistHopDuration = 0.18,
	CurbAssistMaxUpwardSpeed = 22,
	CurbAssistAngularDampingRate = 7,
	CurbAssistClimbRange = 3.8,
	CurbAssistClimbAcceleration = 185,
	CurbAssistClimbMaxUpwardSpeed = 16,
	CurbRecoveryEnabled = true,
	CurbRecoveryMinimumSpeed = 18,
	CurbRecoveryDuration = 0.65,
	CurbRecoveryGroundProbe = 5.5,
	CurbRecoveryRollStrength = 14,
	CurbRecoveryPitchStrength = 6,
	CurbRecoveryDamping = 18,
	CurbRecoveryMaxAngularSpeed = 5.5,

	-- Aerodynamic grip (kgf at 200 km/h) - ลดลงเพื่อไม่ให้กดรถจมเวลาเหินเนิน/แรมป์
	DownforceFrontKgf = 12,
	DownforceRearKgf = 16,

	-- เบรก
	BrakeForce = 6000,

	-- Keep Scon features compatible
	CoastDecelForce = 0,
	AutoStopSpeedStuds = 0,
	TapDriftEnabled = false,
	TapDriftTapDuration = 0.35,
	TapDriftMinSpeed = 18,
	TapDriftRearBrake = 22000,
	TapDriftPowerRatio = 0.55,
	TapDriftMaxDuration = 1.35,
	TireSmokeEnabled = true,
	TireSmokeDriftRate = 95,
	TireSmokeBrakeRate = 65,
}

local Tune = {}

--[[Misc]]
Tune.LoadDelay = 0.1 -- Delay before initializing chassis (in seconds)
Tune.AutoStart = true -- Set to false if using manual ignition plugin
Tune.AutoFlip = true -- A-Chassis flips the occupied car after it stays upside down
Tune.Mobile = true -- Set to false if using a 3rd party mobile support method.
Tune.FlipType = "New" -- "New" uses AlignOrientation, "Old" uses BodyGyro. This really only needs to be changed for plugin compatibility.

--[[Wheel Alignment]]
--[Values are in degrees]
Tune.FCamber = -0.5
Tune.RCamber = -0.5
Tune.FCaster = 0
Tune.RCaster = 0
Tune.FToe = 0
Tune.RToe = 0

--[[Weight and CG]]
Tune.Weight = Config.Weight -- Total weight (in kilograms, under Earth's gravity, including wheel and suspension weight)
Tune.WeightBSize = {
	--[[Width]]
	1900,
	--[[Height]]
	1303,
	--[[Length]]
	4545,
}
Tune.WeightDist = 44 -- Weight distribution (0 - on rear wheels, 100 - on front wheels, can be <0 or >100)
Tune.CGHeight = -0.35 -- Pendulum low CG pulls raised wheels back to ground like the reference clip
Tune.WBVisible = false -- Makes the weight brick visible

Tune.GravComp = Config.GroundGravity -- Keep grounded tire load and grip

--Unsprung Weight
Tune.FWheelWeight = 22 -- Front Wheel Weight in kg
Tune.RWheelWeight = 23 -- Rear Wheel Weight in kg

Tune.AxleSize = 1.5 -- Size of structural members (larger = MORE STABLE / carry more weight)
Tune.AxleDensity = 0.1 -- Density of structural members
Tune.CustomSuspensionDensity = 1 -- Density of suspension joints, only applies to custom suspension. (0 makes them massless)

--[[Suspension]]
Tune.SuspensionEnabled = true -- Enables suspension, true or false

--Front Strut
Tune.FSusStiffness = 22.0 -- สปริงตอบสนองดี มีแรงส่งตัวเวลาวิ่งขึ้นเนิน/แรมป์
Tune.FSusDamping = 4.2 -- แดมปิ้งพอดี คืนตัวไว ส่งแรงดีดตอนพ้นขอบแรมป์
Tune.FSwayBar = 3.4 -- Limits body roll while retaining suspension travel

Tune.FSusLength = 1.44 -- Matches original travel geometry
Tune.FPreCompress = 0.16 -- Compensates Scon's 1.44 resting spring mount so ride height matches original
Tune.FExtensionLim = 0.85 -- Droop travel ให้ล้อยืดดันพื้นส่งตัวพ้นขอบแรมป์ได้เต็มที่
Tune.FCompressLim = 0.60 -- Adds compression travel before the suspension bottoms out

--Rear Strut
Tune.RSusStiffness = 23.0 -- สปริงหลังช่วยหนุนส่งจังหวะท้ายพ้นขอบแรมป์
Tune.RSusDamping = 4.5 -- คืนตัวไว ส่งแรงเหินให้รถลอยตัวได้สวยงาม
Tune.RSwayBar = 2.4 -- Balance front/rear roll resistance

Tune.RSusLength = 1.44
Tune.RPreCompress = 0.16 -- Compensates Scon's 1.44 resting spring mount so ride height matches original
Tune.RExtensionLim = 0.85
Tune.RCompressLim = 0.60

--Old Suspension Settings, applies if there is no SuspensionGeometry for the respective wheel
Tune.FSusAngle = 80 -- Spring Angle (degrees from horizontal)
Tune.FWsBoneLen = 4 -- Wishbone Length
Tune.FWsBoneAngle = 0 -- Wishbone angle (degrees from horizontal)
Tune.FAnchorOffset = { -- Suspension anchor point offset (relative to center of wheel)
	--[[Lateral]]
	-0.4, -- positive = outward
	--[[Vertical]]
	-0.5, -- positive = upward
	--[[Forward]]
	0,
} -- positive = forward
Tune.FSpringOffset = { -- Suspension anchor point offset (relative to ABOVE anchor offset) (Avxnturador)
	--[[Lateral]]
	-0.4, -- positive = outward
	--[[Vertical]]
	0, -- positive = upward
	--[[Forward]]
	0,
} -- positive = forward

Tune.RSusAngle = 80 -- Spring Angle (degrees from horizontal)
Tune.RWsBoneLen = 4 -- Wishbone Length
Tune.RWsBoneAngle = 0 -- Wishbone angle (degrees from horizontal)
Tune.RAnchorOffset = { -- Suspension anchor point offset (relative to center of wheel)
	--[[Lateral]]
	-0.4, -- positive = outward
	--[[Vertical]]
	-0.5, -- positive = upward
	--[[Forward]]
	0,
} -- positive = forward
Tune.RSpringOffset = { -- Suspension anchor point offset (relative to ABOVE anchor offset) (Avxnturador)
	--[[Lateral]]
	-0.4, -- positive = outward
	--[[Vertical]]
	0, -- positive = upward
	--[[Forward]]
	0,
} -- positive = forward

--Aesthetics
Tune.SusVisible = false -- Suspension Visible
Tune.SpringsVisible = false -- Springs Visible (Disabled so red coils never clutter game)
Tune.SusRadius = 0.2 -- Spring Coil Radius
Tune.SusThickness = 0.1 -- Spring Coil Thickness
Tune.SusColor = "Bright red" -- Spring Color [BrickColor]
Tune.SusCoilCount = 6 -- Spring Coil Count

--[[Steering]]
-- Front wheel steering
Tune.SteeringType = "Manual" -- This can be "Auto" or "Manual".

-- "Auto" Steering type somewhat realistically calculates steering angle for you
Tune.SteerRatio = 18 / 1 -- Steering ratio of your steering rack, google it for your car
Tune.LockToLock = 4.3 -- Number of turns of the steering wheel lock to lock, google it for your car
Tune.Ackerman = 1.1 -- If you don't know what it is don't touch it, ranges from .7 to 1.2

-- "Manual" steering type allows you to manually set the angle of the wheels
Tune.SteerInner = Config.MaxSteerAngle -- Inner wheel steering (in degrees)
Tune.SteerOuter = Config.MaxSteerAngle * 0.92 -- Outer wheel steering (in degrees)

-- Steer speed tuning
Tune.SteerSpeed = Config.SteerSpeed -- Steering increment per tick (in degrees)
Tune.ReturnSpeed = Config.ReturnSpeed -- Steering increment per tick (in degrees)
Tune.ContlrSteerSpeed = 0 -- Controller version of steer speed (0 or less to be the same as SteerSpeed)
Tune.ContlrReturnSpeed = 0 -- Controller version of return speed (0 or less to be the same as ReturnSpeed)
Tune.MSteerUsesContlr = true -- Set to true if you want mouse steering to use controller settings.

-- Steer Decay
Tune.SteerDecay = Config.SteerDecaySpeed -- Speed of gradient cutoff (in km/h)
Tune.SteerSpeedDecay = Config.SteerDecaySpeed
Tune.ArcadeSteering = Config.ArcadeSteering
Tune.ArcadeSteerLowSpeedDegPerSec = Config.ArcadeSteerLowSpeedDegPerSec
Tune.ArcadeSteerHighSpeedDegPerSec = Config.ArcadeSteerHighSpeedDegPerSec
Tune.ArcadeSteerFullSpeedKmh = Config.ArcadeSteerFullSpeedKmh
Tune.ArcadeSteerMinMoveStudsPerSec = Config.ArcadeSteerMinMoveStudsPerSec
Tune.ArcadeSteerFullMoveStudsPerSec = Config.ArcadeSteerFullMoveStudsPerSec
Tune.ArcadeSteerResponse = Config.ArcadeSteerResponse
Tune.ArcadeSteerReleaseDamping = Config.ArcadeSteerReleaseDamping
Tune.ArcadeVelocityFollow = Config.ArcadeVelocityFollow
Tune.ArcadeLateralGrip = Config.ArcadeLateralGrip
Tune.ArcadeRollStability = Config.ArcadeRollStability
Tune.ArcadeRollDamping = Config.ArcadeRollDamping
Tune.ArcadeVisualWheelAngleLow = Config.ArcadeVisualWheelAngleLow
Tune.ArcadeVisualWheelAngleHigh = Config.ArcadeVisualWheelAngleHigh
Tune.CurbRecoveryEnabled = Config.CurbRecoveryEnabled
Tune.CurbRecoveryGroundProbe = Config.CurbRecoveryGroundProbe
Tune.CurbRecoveryDuration = Config.CurbRecoveryDuration
Tune.CurbRecoveryMinimumSpeed = Config.CurbRecoveryMinimumSpeed
Tune.CurbRecoveryRollStrength = Config.CurbRecoveryRollStrength
Tune.CurbRecoveryPitchStrength = Config.CurbRecoveryPitchStrength
Tune.CurbRecoveryDamping = Config.CurbRecoveryDamping
Tune.CurbRecoveryMaxAngularSpeed = Config.CurbRecoveryMaxAngularSpeed
Tune.MinSteer = Config.SteerAtTopSpeed
Tune.MinSteerSpeed = 75
Tune.MSteerExp = 1

-- Counter-steer
Tune.CSEnabled = false
Tune.CSAmt = 100
Tune.CSSteerThresh = 10
Tune.CSSpeedThresh = 10

-- Four Wheel Steering
Tune.FWSteer = "None"
Tune.RSteerOuter = 2.2
Tune.RSteerInner = 1.6
Tune.RSteerSpeed = 80
Tune.RSteerDecay = 150

Tune.RSteerD = 1000
Tune.RSteerP = 50000
Tune.RSteerMaxTorque = 20000

-- Steering aggressiveness
Tune.SteerSmoothing = 1
Tune.PowerSteeringType = "Old"
Tune.SteerD = 1000
Tune.SteerP = 50000
Tune.SteerMaxTorque = 20000

--[[Engine (Detomiks)]]

-- *USE THE GRAPH BELOW TO PROPERLY TUNE THE ENGINE.*
-- https://www.desmos.com/calculator/cqhgbm0vlt

-- To import engines prior to 1.7, consult the README.

Tune.CustomEngineCalculations = false -- Enables the use of the CustomEngine module. Even if enabled, please do not remove the default engine values.

-- Naturally Aspirated Engine
Tune.Engine = true

Tune.PeakTorque = 390 * Config.Acceleration -- The maximum amount of torque the engine makes in lb-ft.
Tune.PeakTorqueRPM = 2500 -- When the engine reaches PeakTorque in RPM.

Tune.IdleRPM = 1000 -- The engine's desired idle RPM. IdleDamping may change this.
Tune.IdleTorque = 315 * Config.Acceleration -- How much torque the engine makes at idle.
Tune.IdleTorqueCurve = 0.275 -- The shape of the torque curve between idle and PeakRPM.

Tune.Redline = 7500 -- The maximum RPM.
Tune.RedlineTorque = 160 * Config.Acceleration -- How much torque the engine makes at redline.
Tune.RedlineTorqueCurve = 0.31 -- The shape of the torque curve between PeakRPM and redline.

Tune.ShiftRPM = 7000 -- This is when the engine shifts.
Tune.PeakRPM = Tune.ShiftRPM -- This is deprecated, only used for plugin compatibility.

Tune.VVLTorque = 0 -- Variable Valve Lift (VVL, aka VTEC)'s amount of torque. Set this to 0 to turn off.
Tune.VVLRPM = 3000 -- When VVL activates in RPM.
Tune.VVLTime = 1000 -- How long it takes for VVL to activate in RPM.
Tune.VVLCurve = 0.1 -- The shape of the curve during VVL activation.

Tune.HPLimit = 0 -- The horsepower limit of the engine (set to 0 to turn off).

-- Electric Engine
Tune.Electric = true

Tune.E_Torque = 3600 -- The amount of electric torque in lb-ft.
Tune.E_TransitionRPM = 7500 -- When the torque begins decaying.

Tune.E_Redline = 22000 -- The maximum RPM of the electric motor.
Tune.E_RedlineTorque = 1800 -- How much torque is made at the maximum RPM.

Tune.E_Curve = 0.84 -- The shape of the curve between TransitionRPM and the redline.

-- Turbocharger
Tune.Turbochargers = 0 -- Number of turbochargers in the engine, set to 0 for no turbochargers

Tune.T_Boost = 10 -- The maximum amount of boost of one turbocharger in PSI.
Tune.T_PeakRPM = 2500 -- When the turbo reaches maximum boost.

Tune.T_IdleBoost = 0 -- How much boost is made at idle.
Tune.T_Curve = 0.91 -- The shape of the boost curve between idle and PeakRPM.

Tune.T_Efficiency = 10 -- How much torque is made with 1 PSI.

Tune.T_Size = 11 -- Turbo size, larger = less boost from horsepower
Tune.T_SpoolIncrease = 0.3 -- Throttle response of the turbo. (Higher = more responsive, ranges from 0 to 1)
Tune.T_SpoolDecrease = 0.06 -- Throttle response of the turbo. (Higher = more responsive, ranges from 0 to 1)

-- Supercharger
Tune.Superchargers = 0 -- Number of superchargers in the engine, Set to 0 for no superchargers

Tune.S_Boost = 8 -- The maximum amount of boost of one supercharger in PSI.
Tune.S_PeakRPM = 5500 -- When the supercharger reaches its maximum boost.

Tune.S_IdleBoost = 6.1 -- The amount of boost at idle.
Tune.S_IdleCurve = 0.31 -- The shape of the boost curve between idle and PeakRPM.

Tune.S_RedlineBoost = 5.6 -- The amount of boost at redline.
Tune.S_RedlineCurve = 0.187 -- The shape of the boost curve between PeakRPM and redline.

Tune.S_Efficiency = 4.34 -- How much torque is made with 1 PSI.

Tune.S_Response = 0.1 -- Throttle response of the supercharger. (Higher = more responsive, ranges from 0 to 1)

-- Ignition
Tune.IgnitionRPM = 1200 -- This is how high the engine revs for the ignition.
Tune.IgnitionAccel = 30 -- The acceleration of the RPM while starting the car.
Tune.IgnitionMinRPM = 800 -- The minimum RPM required to start the car.

-- Throttle and brake input
Tune.ThrotAccel = Config.ThrottleResponse -- Throttle acceleration, applied per tick (recommended values between 0.1 to 0.3)
Tune.ThrotDecel = 0.3 -- Throttle deceleration, applied per tick (recommended values between 0.05 to 0.1)
Tune.BrakeAccel = 0.1 -- Brake acceleration, applied per tick
Tune.BrakeDecel = 0.2 -- Brake deceleration, applied per tick

-- Engine speed
Tune.RevBounce = 200 -- RPM kickback from redline
Tune.OverRev = false -- Set to true to allow the RPM to go above redline

Tune.RevAccel = 300 -- RPM acceleration when clutch is on (this should be higher than RevDecay and RevDecayRPM)
Tune.RevDecay = 30 -- RPM decay when clutch is on
Tune.RevDecayRPM = 60 -- RPM decay from engine speed

Tune.Flywheel = 500 -- Flywheel weight (higher = faster response, lower = more stable RPM)
Tune.DumpMult = 1.0 -- Flywheel energy multiplier when dumping the clutch (keep at 1.0 for the best result).

Tune.IdleThrottle = 5 -- Percent throttle with no input. (in percent)
Tune.IdleDamping = 4800 -- Damping of idle in RPM. This will change that actual idle RPM at higher values.
Tune.IdlePadding = 800 -- Added on top of IdleRPM to account for IdleDamping
Tune.RemoveCreep = true -- Tries to remove the natural creep of the chassis by applying clutch if there is no input throttle and if the RPM is below idle.

Tune.InclineComp = 1.0 -- Torque compensation multiplier for inclines (applies gradient from 0-90 degrees)

--[[Drivetrain]]
Tune.Config = "AWD" -- "FWD" , "RWD" , "AWD"
Tune.TorqueVector = -0.25 -- AWD ONLY, "-1" has a 100% front bias, "0" has a 50:50 bias, and "1" has a 100% rear bias. Can be any number between that range.

-- Options for a limited slip differential (LuaInt)
-- *You can set all of these values to 0 to achieve an open differential.
Tune.FDiffPower = 20 -- 0 - 100				Higher values yield more wheel lock-up under throttle, more stability (Front wheels, only if driven)
Tune.FDiffCoast = 20 -- 0 - 100				Higher values yield more wheel lock-up when off throttle, more stability (Front wheels, only if driven)
Tune.FDiffPreload = 15 -- 0 - 100				Higher values will make the wheels generally lock up faster in any environment (Front wheels, only if driven)
Tune.RDiffPower = 20 -- 0 - 100				(Rear wheels, only if driven)
Tune.RDiffCoast = 20 -- 0 - 100				(Rear wheels, only if driven)
Tune.RDiffPreload = 15 -- 0 - 100				(Rear wheels, only if driven)

-- Traction Control Settings
Tune.TCSEnabled = true -- Implements TCS
Tune.TCSThreshold = 10 -- Slip speed allowed before TCS starts working (in km/h)
Tune.TCSGradient = 10 -- Slip speed gradient between 0 to max reduction (in km/h)
Tune.TCSLimit = 4 -- Minimum amount of torque at max reduction (in percent)

-- Electronic Stability Control Settings
Tune.ESCEnabled = true -- Implements ESC. TCS MUST ALSO BE ENABLED. This uses the same keybind as TCS.
Tune.ESCVector = -0.2 -- Force from the front to the rear for ESC. "-1" has a 100% front bias, "0" has a 50:50 bias, and "1" has a 100% rear bias. Can be any number between that range.
Tune.ESCThreshold = 0.85 -- Force difference in Gs before ESC starts working.
Tune.ESCSpeed = 30 -- Minimum speed before ESC can work in km/h.
Tune.ESCThrottle = 60 -- Maximum amount of throttle allowed to ESC in percent. (0 to allow no throttle)
Tune.ESCBrake = 60 -- Maximum amount of brakes allowed to ESC in percent. (0 to allow no brakes)

--[[Transmission]]
Tune.Clutch = false -- Implements a realistic clutch, change to "false" for the chassis to act like AC6.81T.

Tune.TransModes = { "Auto" } --[[
	[Modes]
		"Auto"		: Automatic shifting
		"Semi"		: Clutchless manual shifting, dual clutch transmission
		"Manual"	: Manual shifting with clutch
		
		>Include within brackets
			eg: {"Semi"} or {"Auto", "Manual"}								
	>First mode is default mode													]]

Tune.ClutchMode = "New" --[[
	[Modes]
		"New"		: Speed controls clutch engagement			(AC6C V1.2)
		"Old"		: Speed and RPM control clutch engagement	(AC6C V1.1)		]]

Tune.ClutchType = "Clutch" --[[
	[Types]
		"Clutch"			: Standard clutch, recommended
		"TorqueConverter"	: Torque converter, keeps RPM up
		"CVT"				: Continously Variable Transmission
																		]]
--[[Transmission]]
--Transmission Settings
Tune.Stall = false -- Stalling, enables the car to stall. An ignition plugin would be necessary. Disables if Tune.Clutch is false.
Tune.ClutchRel = false -- If true, the driver must let off the gas before shifting to a higher gear. Recommended false for beginners.
Tune.ClutchEngage = 10 -- How fast engagement is (0 = instant, 99 = super slow)
Tune.SpeedEngage = 40 -- Speed the clutch fully engages at (Based on km/h)

--Clutch: "Old" mode
Tune.ClutchRPMMult = 1 -- Clutch RPM multiplier, recommended to leave at 1.0

--Torque Converter:
Tune.TQLock = false -- Torque converter starts locking at a certain RPM
Tune.RPMEngage = 3500 -- Keeps RPMs to this level until passed

--CVT:
Tune.CVTRPM = 7000 -- RPM that the CVT wants to keep at full throttle.
Tune.CVTMaxRatio = 6 -- The gear ratio that the CVT cannot go over.
Tune.CVTMinRatio = 1 -- The gear ratio that the CVT cannot go under.

--Neutral Rev Limiter (Avxnturador)
Tune.NeutralLimit = false -- Enables a different redline RPM for when the car is in neutral
Tune.NeutralRevRPM = 5000 -- The rev limiter when the car is in neutral
Tune.LimitClutch = false -- Will also limit RPMs while the clutch is pressed down

--Automatic Settings
Tune.AutoShiftMode = "Speed" --[[
	[Modes]
		"Speed"		: Shifts based on wheel speed
		"RPM"		: Shifts based on RPM										]]
Tune.AutoShiftType = "DCT" --[[
	[Types]
		"Rev"		: Clutch engages fully once RPM reached			(AC6C V1)
		"DCT"		: Clutch engages after a set time has passed	(AC6.81T)	]]
Tune.AutoShiftVers = "Old" --[[
	[Versions]
		"New"		: Shift from Reverse, Neutral, and Drive		(AC6.81T)
		"Old"		: Auto shifts into R or D when stopped.			(AC6.52S2)	]]
Tune.AutoUpThresh = -200 -- Automatic upshift point 	(relative to peak RPM, positive = Over-rev)
Tune.AutoDownThresh = 1400 -- Automatic downshift point (relative to peak RPM, positive = Under-rev)

--Automatic: Revmatching
Tune.ShiftThrot = 100 -- Throttle level when shifting down to revmatch, 0 - 100%

--Automatic: DCT
Tune.ShiftUpTime = 0.2 -- Time required to shift into next gear, from a lower gear to a higher one.
Tune.ShiftDnTime = 0.1 -- Time required to shift into next gear, from a higher gear to a lower one.

--Gear Ratios
--You can tune the gears in the engine graphs by switching G_TunerType inside Desmos
Tune.FinalDrive = Config.FinalDrive
Tune.Ratios = {
	--[[Park]]
	--0			, --"0" enables the parking gear, "--0" disables.
	--[[Reverse]]
	3.18,
	--[[Neutral]]
	0,
	--[[ 1 ]]
	3.927,
	--[[ 2 ]]
	2.454,
	--[[ 3 ]]
	1.785,
	--[[ 4 ]]
	1.413,
	--[[ 5 ]]
	1.101,
	--[[ 6 ]]
	0.893,
}

Tune.FDMult = 1 -- Ratio multiplier (keep this at 1 if car is not struggling with torque)

-- Speed Limiter
Tune.SpeedLimit = Config.TopSpeed -- Maximum speed limit in km/h (0 or less for no limiter)
Tune.AirborneGravity = Config.AirGravity
Tune.AirborneDensityScale = Config.AirborneDensityScale
Tune.AirLaunchMinimumSpeed = Config.AirLaunchMinimumSpeed
Tune.AirLaunchBaseBoost = Config.AirLaunchBaseBoost
Tune.AirLaunchSpeedScale = Config.AirLaunchSpeedScale
Tune.AirLaunchMaxVerticalSpeed = Config.AirLaunchMaxVerticalSpeed
Tune.CoastDecelForce = Config.CoastDecelForce
Tune.AutoStopSpeedStuds = Config.AutoStopSpeedStuds
Tune.CurbAssistEnabled = Config.CurbAssistEnabled
Tune.CurbAssistMaxStep = Config.CurbAssistMaxStep
Tune.CurbAssistProbeDistance = Config.CurbAssistProbeDistance
Tune.CurbAssistAcceleration = Config.CurbAssistAcceleration
Tune.CurbAssistLookAheadSeconds = Config.CurbAssistLookAheadSeconds
Tune.CurbAssistMaxProbeDistance = Config.CurbAssistMaxProbeDistance
Tune.CurbAssistHopLeadSeconds = Config.CurbAssistHopLeadSeconds
Tune.CurbAssistHopMaxTriggerDistance = Config.CurbAssistHopMaxTriggerDistance
Tune.CurbAssistHopDuration = Config.CurbAssistHopDuration
Tune.CurbAssistMaxUpwardSpeed = Config.CurbAssistMaxUpwardSpeed
Tune.CurbAssistAngularDampingRate = Config.CurbAssistAngularDampingRate
Tune.CurbAssistClimbRange = Config.CurbAssistClimbRange
Tune.CurbAssistClimbAcceleration = Config.CurbAssistClimbAcceleration
Tune.CurbAssistClimbMaxUpwardSpeed = Config.CurbAssistClimbMaxUpwardSpeed
-- Hoki Arcade Drift Multi-Vehicle Mappings
Tune.TapDriftEnabled = Config.TapDriftEnabled
Tune.TapDriftTapDuration = Config.TapDriftTapDuration
Tune.TapDriftMinSpeed = Config.TapDriftMinSpeed
Tune.TapDriftRearBrake = Config.TapDriftRearBrake
Tune.TapDriftPowerRatio = Config.TapDriftPowerRatio
Tune.TapDriftMaxDuration = Config.TapDriftMaxDuration
Tune.TireSmokeEnabled = Config.TireSmokeEnabled
Tune.TireSmokeDriftRate = Config.TireSmokeDriftRate
Tune.TireSmokeBrakeRate = Config.TireSmokeBrakeRate
Tune.DownforceFrontKgf = Config.DownforceFrontKgf
Tune.DownforceRearKgf = Config.DownforceRearKgf
Tune.ReverseSpeed = 40 -- Maximum reverse speed limit
Tune.SLimitGradient = 6 -- Smoothly holds 170 km/h ceiling without brake-slam oscillation
Tune.SLimitBrake = false -- Taper drive torque smoothly at top speed instead of slamming brakes

--[[Brakes]]
Tune.ExitBrake = true -- Set to false if you don't want the car to apply the parking brake when exiting

-- ABS
Tune.ABSEnabled = true -- Implements the Antilock Braking System
Tune.ABSThreshold = 3 -- Slip speed allowed before ABS starts working (in km/h)
Tune.ABSGradient = 8 -- Slip speed gradient between 0 to max reduction (in km/h)
Tune.ABSLimit = 0 -- Minimum amount of torque at max reduction (in percent)

-- Forces
Tune.BrakeForce = Config.BrakeForce -- Total brake force in kgf
Tune.BrakeBias = 0.65 -- Brake bias towards the front, percentage (1 = Front, 0 = Rear, .5 = 50/50)
Tune.PBrakeForce = 1000 -- Handbrake force in kgf
Tune.PBrakeBias = 0 -- Handbrake bias towards the front, percentage (1 = Front, 0 = Rear, .5 = 50/50)
Tune.EBrakeForce = 1600 -- Engine braking force at redline in kgf

--[[[Default Controls]]
--Peripheral Deadzones
Tune.Peripherals = {
	MSteerWidth = 67, -- Mouse steering control width	(0 - 100% of screen width)
	MSteerDZone = 10, -- Mouse steering deadzone (0 - 100%)

	ControlLDZone = 5, -- Controller steering L-deadzone (0 - 100%)
	ControlRDZone = 5, -- Controller steering R-deadzone (0 - 100%)
}

--Control Mapping
Tune.Controls = {

	--Keyboard Controls (W/A/S/D & Arrow Keys only per user request)
	ToggleTCS = Enum.KeyCode.Unknown,
	ToggleABS = Enum.KeyCode.Unknown,
	ToggleCS = Enum.KeyCode.Unknown,
	ToggleTransMode = Enum.KeyCode.Unknown,
	ToggleMouseDrive = Enum.KeyCode.Unknown,

	--Primary Controls
	Throttle = Enum.KeyCode.Up,
	Brake = Enum.KeyCode.Down,
	SteerLeft = Enum.KeyCode.Left,
	SteerRight = Enum.KeyCode.Right,

	--Secondary Controls
	Throttle2 = Enum.KeyCode.W,
	Brake2 = Enum.KeyCode.S,
	SteerLeft2 = Enum.KeyCode.A,
	SteerRight2 = Enum.KeyCode.D,

	--Manual Transmission (Disabled)
	ShiftUp = Enum.KeyCode.Unknown,
	ShiftDown = Enum.KeyCode.Unknown,
	Clutch = Enum.KeyCode.Unknown,

	--Handbrake (Spacebar)
	PBrake = Enum.KeyCode.Space,

	--Mouse Controls (Disabled)
	MouseThrottle = Enum.KeyCode.Unknown,
	MouseBrake = Enum.KeyCode.Unknown,
	MouseClutch = Enum.KeyCode.Unknown,
	MouseShiftUp = Enum.KeyCode.Unknown,
	MouseShiftDown = Enum.KeyCode.Unknown,
	MousePBrake = Enum.KeyCode.Unknown,

	--Controller Mapping (Clean driving only)
	ContlrThrottle = Enum.KeyCode.ButtonR2,
	ContlrBrake = Enum.KeyCode.ButtonL2,
	ContlrSteer = Enum.KeyCode.Thumbstick1,
	ContlrShiftUp = Enum.KeyCode.Unknown,
	ContlrShiftDown = Enum.KeyCode.Unknown,
	ContlrClutch = Enum.KeyCode.Unknown,
	ContlrPBrake = Enum.KeyCode.Unknown,
	ContlrToggleTMode = Enum.KeyCode.Unknown,
	ContlrToggleTCS = Enum.KeyCode.Unknown,
	ContlrToggleABS = Enum.KeyCode.Unknown,
	ContlrToggleCS = Enum.KeyCode.Unknown,
}

--[[Wall-Climb & Stunt Settings]]
Tune.WallClimbEnabled = Config.WallClimbEnabled
Tune.WallClimbMinHeight = Config.WallClimbMinHeight
Tune.WallClimbProbeDist = Config.WallClimbProbeDist
Tune.WallClimbAdhesionForce = Config.WallClimbAdhesionForce
Tune.WallClimbDriveSpeed = Config.WallClimbDriveSpeed
Tune.WallClimbPitchRate = Config.WallClimbPitchRate
Tune.WallClimbCrestUpBoost = Config.WallClimbCrestUpBoost
Tune.WallClimbCrestForwardBoost = Config.WallClimbCrestForwardBoost

--[[Airborne Stunt Control]]
Tune.AirPitchDownSpeed = Config.AirPitchDownSpeed
Tune.AirPitchUpSpeed = Config.AirPitchUpSpeed
Tune.AirRollSpeed = Config.AirRollSpeed

return Tune
