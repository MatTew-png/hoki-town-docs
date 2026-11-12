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
	-- ความเร็วและอัตราเร่ง (Arcade Stunt & Wall-Climb Edition)
	TopSpeed = 215, -- ความเร็วปกติ km/h (ขับมันในเมือง คุมอยู่ไม่หลุดแมพ)
	FinalDrive = 3.85, -- อัตราทดเฟืองท้าย แรงบิดสูงสำหรับไต่กำแพง 90 องศาและพุ่งขึ้นแรมป์
	Acceleration = 10.5, -- อัตราเร่งทันใจ ไม่หน่วงเวลาขึ้นเนินชัน/กำแพง
	ThrottleResponse = 0.65, -- คันเร่งตอบสนองฉับไว

	-- วงเลี้ยว / พวงมาลัย (Steering)
	MaxSteerAngle = 38,
	SteerSpeed = 1.6,
	ReturnSpeed = 2.4,
	SteerAtTopSpeed = 52,
	SteerDecaySpeed = 160,
	-- เลี้ยวแบบอาร์เคด (Arcade Steering & Slip Control - รองรับ 3D บนกำแพงและเพดาน)
	ArcadeSteering = true,
	ArcadeSteerLowSpeedDegPerSec = 175, -- เลี้ยวคล่องความเร็วต่ำ (องศา/วินาที)
	ArcadeSteerHighSpeedDegPerSec = 135, -- ยังเลี้ยวคมตอนความเร็วสูง (องศา/วินาที)
	ArcadeSteerFullSpeedKmh = 150, -- ความเร็วที่ใช้ความไวแบบ HighSpeed เต็มที่
	ArcadeSteerMinMoveStudsPerSec = 1.5, -- ต่ำกว่านี้รถจะไม่หมุนเมื่อกดเลี้ยว
	ArcadeSteerFullMoveStudsPerSec = 10, -- ความเร็วที่ได้แรงเลี้ยวเต็ม
	ArcadeSteerResponse = 22, -- เริ่มเลี้ยวทันที
	ArcadeSteerReleaseDamping = 16, -- ความเร็วที่หยุดหมุนหลังปล่อยปุ่ม
	ArcadeVelocityFollow = 0.92, -- หมุนทิศความเร็วตามตัวรถบนพื้นผิวทุกมุม (0-1)
	ArcadeLateralGrip = 14, -- เกาะพื้นผิวแน่น ลดการไถลข้างบนกำแพงและโค้ง
	ArcadeRollStability = 12, -- แรงประคองตัวรถให้ตั้งฉากกับพื้นผิว
	ArcadeRollDamping = 10, -- ลดการแกว่งตัวถัง
	ArcadeVisualWheelAngleLow = 38, -- มุมล้อหน้าเมื่อเลี้ยวช้า
	ArcadeVisualWheelAngleHigh = 20, -- มุมล้อหน้าเมื่อเลี้ยวเร็ว
	CurbRecoveryEnabled = true,
	CurbRecoveryGroundProbe = 3.5,
	CurbRecoveryDuration = 0.45,
	CurbRecoveryMinimumSpeed = 12,
	CurbRecoveryRollStrength = 10,
	CurbRecoveryPitchStrength = 6,
	CurbRecoveryDamping = 16,
	CurbRecoveryMaxAngularSpeed = 3.5,

	-- ฟิสิกส์น้ำหนักและแรงโน้มถ่วง (Weight & Balanced Stunt Gravity)
	Weight = 1350,
	GroundGravity = 210, -- แรงกดบนพื้นราบปกติ
	AirGravity = 132, -- เบากว่าแรงโน้มถ่วงปกติเพื่อให้เหินสนุก แต่ลงพื้นสวยไม่ลอยหลุดแมพ
	AirborneDensityScale = 1.0,

	-- ระบบไต่กำแพงและเกาะเพดาน 360° (Spider Wall-Climb & Ceiling Adhesion)
	SpiderClimbEnabled = true,
	SpiderAdhesionGravity = 240, -- แรงดูดกดตัวรถเข้ากับพื้นผิวปกติ
	SpiderSteepAdhesionGravity = 280, -- แรงดูดพิเศษบนกำแพง 90° และเพดาน 180°
	SpiderForwardProbeDist = 7.5, -- ระยะตรวจจับกำแพงข้างหน้าเพื่อพลิกหน้ารถขึ้นไต่
	SpiderForwardProbeSpeedScale = 0.105, -- ขยายระยะตรวจจับตามความเร็ว (ไม่ชนกำแพงก่อนพลิก)
	SpiderMinWallHeight = 2.6, -- ขอบเตี้ยกว่า 2.6 studs ปล่อยให้ล้อ/CurbAssist ข้ามแทนการพลิก 90°
	SpiderAlignRate = 22.0, -- ความไวในการปรับระนาบตัวรถให้แนบไปกับกำแพง/ลูป
	SpiderSnapRate = 34.0, -- ความไวในการพลิกขึ้นมุมหักศอก 90° และมุมพับขอบ
	SpiderCrestWrapEnabled = true, -- พลิกตัวข้ามขอบบนของกำแพง/ตึก หรือใบมีด Flip 0.7 stud ได้อัตโนมัติ
	SpiderTangentDriveAssist = 64, -- แรงขับเสริมบนกำแพงชัน/เพดาน (ไต่ลื่นไม่พุ่งหลุดยอดตึกเกินไป)
	SpiderMaxClimbSpeed = 135, -- เพดานความเร็วไต่กำแพงแนวตั้ง (studs/s) เพื่อให้อยู่ในระยะเล่นของพาร์ค
	SpiderStickDetachAirTime = 0.14, -- ช่วงกันหลุดเมื่อวิ่งข้ามรอยต่อลูป/สไปรอล

	-- ระบบตอนรถเหินและบิน (Air Launch, Glide & Controlled Jet Flight)
	AirLaunchMinimumSpeed = 24,
	AirLaunchBaseBoost = 10.0, -- พุ่งขึ้นกำลังดีเมื่อพ้นขอบแรมป์หรือยอดเนิน
	AirLaunchSpeedScale = 0.12,
	AirLaunchMaxVerticalSpeed = 44.0, -- เพดานแรงเหินแนวตั้งจากแรมป์ (ลงจอดได้ในเมือง)
	AirLaunchForwardBoostMax = 14.0, -- แรงส่งพุ่งไปข้างหน้าตอนพ้นแรมป์
	AirGlideLiftFactor = 0.22, -- แรงประคองร่อนกลางอากาศเบาๆ เฉพาะช่วงกำลังเหิน
	AirPitchRate = 2.5, -- ความไวคุมก้ม/เงยหัวกลางอากาศ (W/S)
	AirYawRate = 2.6, -- ความไวเลี้ยวกลางอากาศ (A/D)
	AirRollRate = 5.5, -- ความไวควงสว่าน Barrel Roll (Space + A/D)
	AirMaxVerticalSpeed = 48, -- เพดานความเร็วพุ่งขึ้นกลางอากาศ
	AirMaxAltitude = 390, -- เพดานความสูงเหนือยอดตึกสูงสุดกันลอยหลุดแมพ
	StuntCameraTiltBlend = 0.28, -- สัดส่วนการเอียงกล้องตามมุมตัวรถตอนไต่กำแพง/ลอยตัว (28%)
	StuntCameraMaxRollDeg = 28, -- มุมเอียงกล้องสูงสุด (องศา) เพื่อไม่ให้เวียนหัวตอนกลับหัว 180°

	-- ระบบดีดตัวหลังบ้าน (Auto/Internal StuntJump — ไม่ผูกปุ่ม Q เพื่อให้ระบบทำงานอัตโนมัติ)
	StuntJumpEnabled = true,
	StuntJumpUpImpulse = 48, -- ความเร็วดีดตัวตั้งฉากกับพื้นหรือกำแพง
	StuntJumpForwardImpulse = 14, -- แรงพุ่งไปข้างหน้าเล็กน้อยตอนดีดตัว
	StuntJumpCooldown = 0.45,
	StuntJumpMaxAirJumps = 1, -- กระโดดซ้ำกลางอากาศ (Double Jump) ได้ 1 ครั้ง!

	-- ระบบเทอร์โบไอพ่น & บินกลางอากาศ (LeftShift / RightShift)
	BoostEnabled = true,
	BoostGroundAccel = 120, -- แรงเร่งเทอร์โบบนพื้นและกำแพง
	BoostMaxSpeedKmh = 275, -- ความเร็วสูงสุดขณะกดบูสต์เทอร์โบ
	BoostAirForwardAccel = 62, -- แรงดันเจ็ทไปข้างหน้ากลางอากาศ
	BoostAirLiftAccel = 80, -- แรงประคองลอยกลางอากาศ (ชะลอตกเพื่อร่อนข้ามตึก กด S เพื่อไต่ขึ้น)
	BoostAirMaxSpeed = 195, -- เพดานความเร็วรวมขณะบินกลางอากาศ (studs/s)

	-- ระบบลดความเร็วเมื่อปล่อยคันเร่ง (ปล่อย W แล้วค่อยๆ หยุดสนิท ไม่ไหลค้าง)
	CoastDecelForce = 1600,
	AutoStopSpeedStuds = 3.5,

	-- ระบบไต่พื้นต่างระดับต่อเนื่องแบบคุมความเร็ว (Zero-Cooldown Step Climb - Scon)
	CurbAssistEnabled = true,
	CurbAssistMaxStep = 2.2, -- รองรับขอบต่างระดับและฟุตบาทสูงสุด 2.2 studs
	CurbAssistProbeDistance = 0.95, -- สแกนระยะชิดหน้ายาง ป้องกันการยกตัวล่วงหน้าผิดจังหวะ
	CurbAssistAcceleration = 48, -- แรงประคองเสริมขณะล้อติดขอบ
	CurbAssistLookAheadSeconds = 0.04,
	CurbAssistMaxProbeDistance = 2.6,
	CurbAssistHopLeadSeconds = 0.04,
	CurbAssistHopMaxTriggerDistance = 1.6,
	CurbAssistHopDuration = 0.2,
	CurbAssistMaxUpwardSpeed = 6.5,
	CurbAssistAngularDampingRate = 8.0,
	ClimbTCSBypassSpeedKmh = 22,

	-- แรงกดอากาศ (Aerodynamic Downforce)
	DownforceFrontKgf = 50,
	DownforceRearKgf = 65,

	-- ระบบเบรก (Braking)
	BrakeForce = 5200,
	-- ระบบการขับขี่สไตล์ ARCADE & DRIFT (HOKI HYBRID ENGINE)
	TapDriftEnabled = true,
	TapDriftTapDuration = 0.35,
	TapDriftMinSpeed = 18,
	TapDriftRearBrake = 22000,
	TapDriftPowerRatio = 0.55,
	TapDriftMaxDuration = 1.35,
	TireSmokeEnabled = true,
	TireSmokeDriftRate = 75,
	TireSmokeBrakeRate = 40,
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
Tune.FCamber = 0
Tune.RCamber = 0
Tune.FCaster = 0
Tune.RCaster = 0
Tune.FToe = 0
Tune.RToe = 0

--[[Weight and CG]]
Tune.Weight = Config.Weight -- Total weight (in kilograms, under Earth's gravity, including wheel and suspension weight)
Tune.WeightBSize =
	{ -- Size of weight brick in milimeters. You can find how to convert studs to milimeters inside the Units module.
		--[[Width]]
		1760,
		--[[Height]]
		820,
		--[[Length]]
		4120,
	}
Tune.WeightDist = 44 -- Weight distribution (0 - on rear wheels, 100 - on front wheels, can be <0 or >100)
Tune.CGHeight = 0.0 -- Lower CG reduces rollover on curb impacts
Tune.WBVisible = false -- Makes the weight brick visible

Tune.GravComp = Config.GroundGravity -- Keep grounded tire load and grip

--Unsprung Weight
Tune.FWheelWeight = 22 -- Front Wheel Weight in kg
Tune.RWheelWeight = 23 -- Rear Wheel Weight in kg

Tune.AxleSize = 1.5 -- Size of structural members (larger = MORE STABLE / carry more weight)
Tune.AxleDensity = 0.50 -- Balanced knuckle mass reduces PGS solver flex and wheel shimmy
Tune.CustomSuspensionDensity = 1 -- Density of suspension joints, only applies to custom suspension. (0 makes them massless)

--[[Suspension]]
Tune.SuspensionEnabled = true -- Enables suspension, true or false

--Front Strut
Tune.FSusStiffness = 28.0 -- Calibrated to hold low stance with real upward travel
Tune.FSusDamping = 9.0 -- Controlled rebound over uneven curbs
Tune.FSwayBar = 3.0 -- Soft roll coupling so one wheel climbs cleanly without yanking opposite wheel

Tune.FSusLength = 1.44 -- Calibrated to resting wishbone geometry
Tune.FPreCompress = 0.16 -- Slight preload keeps spring seated
Tune.FExtensionLim = 0.45 -- Extra droop travel for uneven terrain
Tune.FCompressLim = 0.65 -- Ample bump travel to absorb curb impacts

--Rear Strut
Tune.RSusStiffness = 34.0 -- Calibrated for 56% rear load without bottoming out
Tune.RSusDamping = 10.0 -- Fast settling after step transitions
Tune.RSwayBar = 3.0 -- Independent articulation over staggered bumps

Tune.RSusLength = 1.50 -- Matches rear ride height
Tune.RPreCompress = 0.18 -- Slight preload keeps spring seated
Tune.RExtensionLim = 0.45 -- Extra droop travel for uneven terrain
Tune.RCompressLim = 0.65 -- Ample bump travel to absorb curb impacts

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
Tune.SteerOuter = Config.MaxSteerAngle * 0.86 -- Outer wheel steering (in degrees)

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
Tune.CurbRecoveryMaxAngularSpeed = Config.CurbRecoveryMaxAngularSpeed -- Speed of gradient cutoff of steering speed (in km/h)
Tune.MinSteer = Config.SteerAtTopSpeed -- Minimum steering angle at max steer decay (in percent)
Tune.MinSteerSpeed = 75 -- Minimum steering speed at max decay (in percent)
Tune.MSteerExp = 1 -- Mouse steering exponential degree

-- Counter-steer
Tune.CSEnabled = true -- Enables or disables countersteering
Tune.CSAmt = 75 -- Amount of countersteering at a full perpendicular slide (in percent)
Tune.CSSteerThresh = 8 -- Threshold before countersteering activates (in percent)
Tune.CSSpeedThresh = 15 -- Speed threshold before countersteering can activate (in km/h)

-- Four Wheel Steering
Tune.FWSteer = "None" -- Static, Speed, Both, or None
Tune.RSteerOuter = 2.2 -- Outer rear wheel steering angle (in degrees)
Tune.RSteerInner = 1.6 -- Inner rear wheel steering angle (in degrees)
Tune.RSteerSpeed = 80 -- Speed at which 4WS fully activates (Speed), deactivates (Static), or transition begins (Both) (km/h)
Tune.RSteerDecay = 150 -- Speed of gradient cutoff (in km/h)

Tune.RSteerD = 1000 -- Rear Steering Damping (old only)
Tune.RSteerP = 50000 -- Rear Steering Aggressiveness (old only)
Tune.RSteerMaxTorque = 20000 -- Rear Steering Force (old only)

-- Steering aggressiveness
Tune.SteerSmoothing = 1 -- The lower, the smoother the steering will arrive at max angle.
Tune.PowerSteeringType = "Servo" -- "Servo" uses Rotate HingeConstraint, "New" uses AlignOrientation, "Old" uses BodyGyro
Tune.SteerD = 3500 -- Steering Damping (old only)
Tune.SteerP = 150000 -- Steering Aggressiveness (old only)
Tune.SteerMaxTorque = 350000 -- Steering Force (old only)
Tune.SteerServoMaxTorque = 5000000 -- Rotate hinge servo torque for crisp steering under load
Tune.SteerServoAngularSpeed = 24 -- Rotate hinge servo angular speed (rad/s)

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
Tune.RevBounce = 0 -- RPM kickback from redline
Tune.OverRev = false -- Set to true to allow the RPM to go above redline

Tune.RevAccel = 300 -- RPM acceleration when clutch is on (this should be higher than RevDecay and RevDecayRPM)
Tune.RevDecay = 30 -- RPM decay when clutch is on
Tune.RevDecayRPM = 60 -- RPM decay from engine speed

Tune.Flywheel = 500 -- Flywheel weight (higher = faster response, lower = more stable RPM)
Tune.DumpMult = 1.0 -- Flywheel energy multiplier when dumping the clutch (keep at 1.0 for the best result).

Tune.IdleThrottle = 0 -- Zero phantom creep throttle when releasing W
Tune.IdleDamping = 4800 -- Damping of idle in RPM. This will change that actual idle RPM at higher values.
Tune.IdlePadding = 800 -- Added on top of IdleRPM to account for IdleDamping
Tune.RemoveCreep = true -- Tries to remove the natural creep of the chassis by applying clutch if there is no input throttle and if the RPM is below idle.

Tune.InclineComp = 3.0 -- Torque compensation multiplier for inclines (applies gradient from 0-90 degrees)

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

-- Traction Control Settings (Disabled in Arcade Stunt mode so full AWD power drives straight up walls)
Tune.TCSEnabled = false -- Implements TCS
Tune.TCSThreshold = 10 -- Slip speed allowed before TCS starts working (in km/h)
Tune.TCSGradient = 10 -- Slip speed gradient between 0 to max reduction (in km/h)
Tune.TCSLimit = 4 -- Minimum amount of torque at max reduction (in percent)

-- Electronic Stability Control Settings
Tune.ESCEnabled = false -- Implements ESC. TCS MUST ALSO BE ENABLED. This uses the same keybind as TCS.
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
Tune.ShiftUpTime = 0.05 -- Time required to shift into next gear, from a lower gear to a higher one.
Tune.ShiftDnTime = 0.05 -- Time required to shift into next gear, from a higher gear to a lower one.

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
Tune.AirLaunchForwardBoostMax = Config.AirLaunchForwardBoostMax
Tune.SpiderClimbEnabled = Config.SpiderClimbEnabled
Tune.SpiderAdhesionGravity = Config.SpiderAdhesionGravity
Tune.SpiderSteepAdhesionGravity = Config.SpiderSteepAdhesionGravity
Tune.SpiderForwardProbeDist = Config.SpiderForwardProbeDist
Tune.SpiderForwardProbeSpeedScale = Config.SpiderForwardProbeSpeedScale
Tune.SpiderMinWallHeight = Config.SpiderMinWallHeight
Tune.SpiderAlignRate = Config.SpiderAlignRate
Tune.SpiderSnapRate = Config.SpiderSnapRate
Tune.SpiderCrestWrapEnabled = Config.SpiderCrestWrapEnabled
Tune.SpiderTangentDriveAssist = Config.SpiderTangentDriveAssist
Tune.SpiderMaxClimbSpeed = Config.SpiderMaxClimbSpeed
Tune.SpiderStickDetachAirTime = Config.SpiderStickDetachAirTime
Tune.AirGlideLiftFactor = Config.AirGlideLiftFactor
Tune.AirPitchRate = Config.AirPitchRate
Tune.AirYawRate = Config.AirYawRate
Tune.AirRollRate = Config.AirRollRate
Tune.AirMaxVerticalSpeed = Config.AirMaxVerticalSpeed
Tune.AirMaxAltitude = Config.AirMaxAltitude
Tune.StuntCameraTiltBlend = Config.StuntCameraTiltBlend
Tune.StuntCameraMaxRollDeg = Config.StuntCameraMaxRollDeg
Tune.StuntJumpEnabled = Config.StuntJumpEnabled
Tune.StuntJumpUpImpulse = Config.StuntJumpUpImpulse
Tune.StuntJumpForwardImpulse = Config.StuntJumpForwardImpulse
Tune.StuntJumpCooldown = Config.StuntJumpCooldown
Tune.StuntJumpMaxAirJumps = Config.StuntJumpMaxAirJumps
Tune.BoostEnabled = Config.BoostEnabled
Tune.BoostGroundAccel = Config.BoostGroundAccel
Tune.BoostMaxSpeedKmh = Config.BoostMaxSpeedKmh
Tune.BoostAirForwardAccel = Config.BoostAirForwardAccel
Tune.BoostAirLiftAccel = Config.BoostAirLiftAccel
Tune.BoostAirMaxSpeed = Config.BoostAirMaxSpeed
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
Tune.ClimbTCSBypassSpeedKmh = Config.ClimbTCSBypassSpeedKmh
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
Tune.SLimitGradient = 6 -- Throttle taper near TopSpeed (smooth cruise without abrupt surging)
Tune.SLimitBrake = false -- Taper drive torque smoothly instead of slamming service brakes at TopSpeed

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
Tune.PBrakeForce = 5000 -- Handbrake force in kgf (strong parking lock)
Tune.PBrakeBias = 0.5 -- Handbrake bias towards the front, percentage (1 = Front, 0 = Rear, .5 = 50/50)
Tune.EBrakeForce = 2400 -- Engine braking force at redline in kgf

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

return Tune
