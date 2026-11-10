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
	-- α╕äα╕ºα╕▓α╕íα╣Çα╕úα╣çα╕º (TopSpeed & Drive)
	TopSpeed         = 260,       -- α╕äα╕ºα╕▓α╕íα╣Çα╕úα╣çα╕ºα╕¬α╕╣α╕çα╕¬α╕╕α╕ö km/h (160 km/h: α╣Çα╕úα╣çα╕ºα╣Çα╕úα╣ëα╕▓α╣âα╕êα╣üα╕òα╣êα╕ºα╕┤α╣êα╕çα╣âα╕Öα╣Çα╕íα╕╖α╕¡α╕çα╕äα╕ºα╕Üα╕äα╕╕α╕íα╕çα╣êα╕▓α╕ó)
	FinalDrive       = 3.6,       -- α╕¡α╕▒α╕òα╕úα╕▓α╕ùα╕öα╣Çα╕ƒα╕╖α╕¡α╕çα╕ùα╣ëα╕▓α╕ó α╣üα╕úα╕çα╕Üα╕┤α╕öα╕öα╕╡α╣Çα╕óα╕╡α╣êα╕óα╕íα╕ùα╕▒α╣ëα╕çα╕ùα╕▓α╕çα╣Çα╕úα╕╡α╕óα╕Üα╣üα╕Ñα╕░α╣äα╕òα╣êα╣Çα╕Öα╕┤α╕Öα╕èα╕▒α╕Ö

	-- α╕¡α╕▒α╕òα╕úα╕▓α╣Çα╕úα╣êα╕çα╣üα╕Ñα╕░α╕üα╕▓α╕úα╕òα╕¡α╕Üα╕¬α╕Öα╕¡α╕çα╕äα╕▒α╕Öα╣Çα╕úα╣êα╕ç
	Acceleration     = 8.5,       -- α╕¡α╕▒α╕òα╕úα╕▓α╣Çα╕úα╣êα╕çα╕Ñα╕╖α╣êα╕Öα╣äα╕½α╕Ñ α╣äα╕íα╣êα╕¡α╕╖α╕öα╣üα╕Ñα╕░α╣äα╕íα╣êα╕üα╕úα╕░α╕òα╕╕α╕üα╣Çα╕üα╕┤α╕Öα╣äα╕¢
	ThrottleResponse = 0.45,      -- α╕äα╕▒α╕Öα╣Çα╕úα╣êα╕çα╕òα╕¡α╕Üα╕¬α╕Öα╕¡α╕çα╣Çα╕¢α╣çα╕Öα╕ÿα╕úα╕úα╕íα╕èα╕▓α╕òα╕┤ α╕üα╕öα╣üα╕Ñα╣ëα╕ºα╕₧α╕╕α╣êα╕çα╕Öα╕╕α╣êα╕íα╕Öα╕ºα╕Ñ

	-- α╕ºα╕çα╣Çα╕Ñα╕╡α╣ëα╕óα╕º / α╕₧α╕ºα╕çα╕íα╕▓α╕Ñα╕▒α╕ó (Steering)
	MaxSteerAngle    = 36,        -- α╕¡α╕çα╕¿α╕▓α╣Çα╕Ñα╕╡α╣ëα╕óα╕ºα╕½α╕Öα╣ëα╕▓ α╣Çα╕Ñα╕╡α╣ëα╕óα╕ºα╣Çα╕éα╣ëα╕▓α╕ïα╕¡α╕óα╣üα╕äα╕Üα╣âα╕Ö HOKI α╣äα╕öα╣ëα╕äα╕Ñα╣êα╕¡α╕çα╕òα╕▒α╕º
	SteerSpeed       = 1.35,       -- α╕äα╕ºα╕▓α╕íα╣äα╕ºα╕₧α╕ºα╕çα╕íα╕▓α╕Ñα╕▒α╕óα╕äα╕íα╕èα╕▒α╕ö
	ReturnSpeed      = 2.2,       -- α╕äα╕╖α╕Öα╕₧α╕ºα╕çα╕íα╕▓α╕Ñα╕▒α╕óα╕òα╕úα╕çα╣äα╕º α╕èα╣êα╕ºα╕óα╣âα╕½α╣ëα╣üα╕üα╣ëα╕¡α╕▓α╕üα╕▓α╕úα╕¢α╕▒α╕öα╕çα╣êα╕▓α╕ó
	SteerAtTopSpeed  = 45,        -- α╕Ñα╕öα╕íα╕╕α╕íα╣Çα╕Ñα╕╡α╣ëα╕óα╕ºα╕ùα╕╡α╣êα╕äα╕ºα╕▓α╕íα╣Çα╕úα╣çα╕ºα╕¬α╕╣α╕çα╣Çα╕₧α╕╖α╣êα╕¡α╕äα╕ºα╕▓α╕íα╕íα╕▒α╣êα╕Öα╕äα╕ç α╣äα╕íα╣êα╕½α╕íα╕╕α╕Öα╣Çα╕äα╕ºα╣ëα╕ç
	SteerDecaySpeed  = 140,       -- α╕êα╕╕α╕öα╣Çα╕úα╕┤α╣êα╕íα╕Ñα╕öα╕íα╕╕α╕íα╣Çα╕Ñα╕╡α╣ëα╕óα╕ºα╕òα╕▓α╕íα╕äα╕ºα╕▓α╕íα╣Çα╕úα╣çα╕º

	-- α╕ƒα╕┤α╕¬α╕┤α╕üα╕¬α╣îα╕Öα╣ëα╕│α╕½α╕Öα╕▒α╕üα╣üα╕Ñα╕░α╣üα╕úα╕çα╣éα╕Öα╣ëα╕íα╕ûα╣êα╕ºα╕ç (Weight & Gravity Balance)
	Weight           = 1350,      -- α╕Öα╣ëα╕│α╕½α╕Öα╕▒α╕üα╕òα╕▒α╕ºα╕úα╕û 1,450 kg (α╣üα╕Öα╣êα╕Ö α╕½α╕Öα╕▒α╕üα╣üα╕Öα╣êα╕Ö α╣äα╕íα╣êα╣Çα╕Üα╕▓α╣Çα╕¢α╣çα╕Öα╕üα╕úα╕░α╕öα╕▓α╕⌐)
	GroundGravity    = 210,       -- α╣üα╕úα╕çα╕öα╕╢α╕çα╕öα╕╣α╕öα╕Üα╕Öα╕₧α╕╖α╣ëα╕Ö α╕óα╕▓α╕çα╣Çα╕üα╕▓α╕░α╕ûα╕Öα╕Öα╕½α╕Öα╕╢α╕Ü α╣äα╕íα╣êα╕Ñα╕¡α╕ó
	AirGravity       = 196.2,       -- α╣üα╕úα╕çα╕öα╕╢α╕çα╕öα╕╣α╕öα╕üα╕Ñα╕▓α╕çα╕¡α╕▓α╕üα╕▓α╕¿ (α╣üα╕üα╣ëα╕êα╕▓α╕ü 12 α╣Çα╕öα╕┤α╕íα╕ùα╕╡α╣êα╣Çα╕¢α╣çα╕Öα╣üα╕úα╕çα╣éα╕Öα╣ëα╕íα╕ûα╣êα╕ºα╕çα╕öα╕ºα╕çα╕êα╕▒α╕Öα╕ùα╕úα╣î α╣âα╕½α╣ëα╕òα╕üα╕Ñα╕çα╕₧α╕╖α╣ëα╕Öα╕¡α╕óα╣êα╕▓α╕çα╕¬α╕íα╕êα╕úα╕┤α╕ç α╣äα╕íα╣êα╕Ñα╕¡α╕óα╣Çα╕äα╕ºα╣ëα╕ç)
	AirborneDensityScale = 1.3,   -- α╣Çα╕₧α╕┤α╣êα╕íα╣Çα╕¬α╕ûα╕╡α╕óα╕úα╕áα╕▓α╕₧α╕üα╕▓α╕úα╕½α╕íα╕╕α╕Öα╕üα╕Ñα╕▓α╕çα╕¡α╕▓α╕üα╕▓α╕¿ α╕¢α╣ëα╕¡α╕çα╕üα╕▒α╕Öα╕úα╕ûα╕òα╕╡α╕Ñα╕▒α╕çα╕üα╕▓

	-- α╕úα╕░α╕Üα╕Üα╕òα╕¡α╕Öα╕úα╕ûα╣Çα╕½α╕┤α╕Ö (Air Launch Tuning - α╣Çα╕¡α╕▓α╣üα╕úα╕çα╕öα╕╡α╕öα╕½α╕Ñα╕¡α╕üα╕¡α╕¡α╕ü α╣âα╕èα╣ëα╕ƒα╕┤α╕¬α╕┤α╕üα╕¬α╣îα╣éα╕íα╣Çα╕íα╕Öα╕òα╕▒α╕íα╕êα╕úα╕┤α╕ç)
	AirLaunchMinimumSpeed = 15,   -- α╕òα╣ëα╕¡α╕çα╕ºα╕┤α╣êα╕çα╣Çα╕úα╣çα╕ºα╕₧α╕¡α╕ûα╕╢α╕çα╕êα╕░α╣Çα╕½α╕┤α╕Öα╕òα╕▓α╕íα╣Çα╕Öα╕┤α╕Ö
	AirLaunchBaseBoost    = 0.0,  -- α╕¢α╕┤α╕öα╣üα╕úα╕çα╕öα╕╡α╕öα╕êα╕úα╕ºα╕öα╕½α╕Ñα╕¡α╕ü α╣âα╕½α╣ëα╕úα╕ûα╣Çα╕½α╕┤α╕Öα╕òα╕▓α╕íα╕¡α╕çα╕¿α╕▓α╣Çα╕Öα╕┤α╕Öα╕êα╕úα╕┤α╕çα╕¡α╕óα╣êα╕▓α╕çα╣Çα╕¢α╣çα╕Öα╕ÿα╕úα╕úα╕íα╕èα╕▓α╕òα╕┤
	AirLaunchSpeedScale   = 0.01,
	AirLaunchMaxVerticalSpeed = 3.5, -- α╕êα╕│α╕üα╕▒α╕öα╕äα╕ºα╕▓α╕íα╕¬α╕╣α╕çα╣äα╕íα╣êα╣âα╕½α╣ëα╕Ñα╕¡α╕óα╕ƒα╣ëα╕▓α╣Çα╕ºα╕¡α╕úα╣îα╣Çα╕üα╕┤α╕Öα╣äα╕¢

	-- α╕úα╕░α╕Üα╕Üα╕éα╣ëα╕▓α╕íα╕éα╕¡α╕Üα╕ƒα╕╕α╕òα╕Üα╕▓α╕ùα╣äα╕ùα╕ó (CurbAssist - α╕Öα╕╕α╣êα╕íα╕Öα╕ºα╕Ñ α╣äα╕íα╣êα╕¬α╕░α╕Üα╕▒α╕ö)
	CurbAssistEnabled              = true,
	CurbAssistMaxStep              = 2.1,   -- α╕úα╕¡α╕çα╕úα╕▒α╕Üα╕éα╕¡α╕Üα╕ƒα╕╕α╕òα╕Üα╕▓α╕ù HOKI TOWN (α╕¬α╕╣α╕ç ~1.8 studs)
	CurbAssistProbeDistance        = 1.8,
	CurbAssistAcceleration         = 130,   -- α╕¢α╕úα╕▒α╕Üα╕Ñα╕öα╕êα╕▓α╕ü 240 α╣âα╕½α╣ëα╕óα╕üα╕òα╕▒α╕ºα╕úα╕ûα╕Öα╕╕α╣êα╕íα╕Öα╕ºα╕Ñ α╣äα╕íα╣êα╣Çα╕öα╣ëα╕çα╕üα╕úα╕░α╕èα╕▓α╕ü
	CurbAssistLookAheadSeconds     = 0.22,
	CurbAssistMaxProbeDistance     = 12,
	CurbAssistHopLeadSeconds       = 0.12,
	CurbAssistHopMaxTriggerDistance = 5.0,
	CurbAssistHopDuration          = 0.2,
	CurbAssistMaxUpwardSpeed       = 14,
	CurbAssistAngularDampingRate   = 6.5,   -- α╕½α╕Öα╣êα╕ºα╕çα╕üα╕▓α╕úα╣Çα╕¡α╕╡α╕óα╕ç α╕¢α╣ëα╕¡α╕çα╕üα╕▒α╕Öα╕úα╕ûα╕₧α╕Ñα╕┤α╕üα╣Çα╕ºα╕Ñα╕▓α╕Ñα╣ëα╕¡α╕¢α╕╡α╕Öα╕ƒα╕╕α╕òα╕Üα╕▓α╕ù

	-- α╣üα╕úα╕çα╕üα╕öα╕¡α╕▓α╕üα╕▓α╕¿ (Aerodynamic Downforce)
	DownforceFrontKgf = 50,       -- α╣üα╕úα╕çα╕üα╕öα╕½α╕Öα╣ëα╕▓α╕úα╕ûα╕òα╕¡α╕Öα╕äα╕ºα╕▓α╕íα╣Çα╕úα╣çα╕ºα╕¬α╕╣α╕ç α╣Çα╕₧α╕┤α╣êα╕íα╕üα╕▓α╕úα╣Çα╕üα╕▓α╕░α╕ûα╕Öα╕Ö
	DownforceRearKgf  = 65,       -- α╣üα╕úα╕çα╕üα╕öα╕ùα╣ëα╕▓α╕óα╕úα╕û α╕¢α╣ëα╕¡α╕çα╕üα╕▒α╕Öα╕ùα╣ëα╕▓α╕óα╕¢α╕▒α╕ö

	-- α╕úα╕░α╕Üα╕Üα╣Çα╕Üα╕úα╕ü (Braking)
	BrakeForce       = 4800,      -- α╕₧α╕Ñα╕▒α╕çα╣Çα╕Üα╕úα╕ü α╕½α╕óα╕╕α╕öα╕úα╕ûα╣äα╕öα╣ëα╕íα╕▒α╣êα╕Öα╣âα╕êα╣âα╕Öα╕úα╕░α╕óα╕░α╕ùα╕╡α╣êα╣Çα╕½α╕íα╕▓α╕░α╕¬α╕í
	-- ระบบการขับขี่สไตล์ ARCADE & DRIFT (HOKI HYBRID ENGINE)
	-- รองรับการปรับแต่งบุคลิกรถได้อิสระสำหรับรถแต่ละรุ่น (Supercar, Sedan, SUV, Truck)
	TapDriftEnabled                = true,      -- ปิดใช้งานระบบแตะเบรกเพื่อดริฟต์ (Tap-to-Drift)
	TapDriftTapDuration            = 0.35,      -- ระยะเวลาแตะเบรกสั้นที่นับเป็นการดริฟต์ (วินาที)
	TapDriftMinSpeed               = 18,        -- ความเร็วขั้นต่ำที่จะเริ่มดริฟต์ได้ (studs/s ~ 16 km/h)
	TapDriftRearBrake              = 22000,     -- แรงดึงเบรกล้อหลังตอนสไลด์ (ยิ่งเยอะ ท้ายยิ่งสะบัดแรง)
	TapDriftPowerRatio             = 0.55,      -- อัตราส่งกำลังเครื่องยนต์ขณะสไลด์ (0.45 = เลี้ยงคันเร่ง 45%)
	TapDriftMaxDuration            = 1.35,      -- ระยะเวลาดริฟต์สูงสุดก่อนคืนแรงยึดเกาะ 100% (วินาที)
	TireSmokeEnabled               = true,      -- เปิด/ปิดควันยางเวลาดริฟต์หรือสไลด์
	TireSmokeDriftRate             = 75,        -- ปริมาณควันขณะดริฟต์
	TireSmokeBrakeRate             = 40,        -- ปริมาณควันขณะเบรกหนัก
}

local Tune = {}

--[[Misc]]
	Tune.LoadDelay		= 0.1			    -- Delay before initializing chassis (in seconds)
	Tune.AutoStart		= true		    -- Set to false if using manual ignition plugin
	Tune.AutoFlip		= true		    -- A-Chassis flips the occupied car after it stays upside down
	Tune.Mobile			= true			-- Set to false if using a 3rd party mobile support method.
	Tune.FlipType		= "New"			-- "New" uses AlignOrientation, "Old" uses BodyGyro. This really only needs to be changed for plugin compatibility.

--[[Wheel Alignment]]
	--[Values are in degrees]
	Tune.FCamber		= -0.5
	Tune.RCamber		= -0.5
	Tune.FCaster		= 0
	Tune.RCaster		= 0
	Tune.FToe			= 0
	Tune.RToe			= 0

--[[Weight and CG]]
	Tune.Weight			= Config.Weight		-- Total weight (in kilograms, under Earth's gravity, including wheel and suspension weight)
	Tune.WeightBSize	= {			-- Size of weight brick in milimeters. You can find how to convert studs to milimeters inside the Units module.
		--[[Width]]			1900	,
		--[[Height]]		1303	,
		--[[Length]]		4545	}
	Tune.WeightDist		= 44		-- Weight distribution (0 - on rear wheels, 100 - on front wheels, can be <0 or >100)
	Tune.CGHeight		= 0.0		-- Lower CG reduces rollover on curb impacts
	Tune.WBVisible		= false		-- Makes the weight brick visible
	
	Tune.GravComp		= Config.GroundGravity	-- Keep grounded tire load and grip

	--Unsprung Weight
	Tune.FWheelWeight	= 22		-- Front Wheel Weight in kg
	Tune.RWheelWeight	= 23		-- Rear Wheel Weight in kg
 
	Tune.AxleSize		= 1.5		-- Size of structural members (larger = MORE STABLE / carry more weight)
	Tune.AxleDensity	= 0.1		-- Density of structural members
	Tune.CustomSuspensionDensity	= 1	-- Density of suspension joints, only applies to custom suspension. (0 makes them massless)

--[[Suspension]]
	Tune.SuspensionEnabled	= true	-- Enables suspension, true or false
	
	--Front Strut
	Tune.FSusStiffness	= 22.0		-- Proper spring rate supports car mass without bottoming out
	Tune.FSusDamping	= 16.0		-- Firm damping controls oscillations
	Tune.FSwayBar		= 8.0		-- Limits body roll and stabilizes wishbone geometry

	Tune.FSusLength		= 1.7		-- Restores proper ride height above ground
	Tune.FPreCompress	= 0.15
	Tune.FExtensionLim	= 0.6
	Tune.FCompressLim	= 0.5		-- Prevents suspension from over-compressing into extreme camber

	--Rear Strut
	Tune.RSusStiffness	= 22.0		-- Firm rear springs keep rear body lifted and level
	Tune.RSusDamping	= 16.0		-- Fast settling on landing/acceleration squat
	Tune.RSwayBar		= 8.0		-- Balances front/rear roll resistance
	
	Tune.RSusLength		= 1.7		-- Matches front ride height
	Tune.RPreCompress	= 0.15
	Tune.RExtensionLim	= 0.6
	Tune.RCompressLim	= 0.5

	--Old Suspension Settings, applies if there is no SuspensionGeometry for the respective wheel
	Tune.FSusAngle		= 80		-- Spring Angle (degrees from horizontal)
	Tune.FWsBoneLen		= 4			-- Wishbone Length
	Tune.FWsBoneAngle	= 0			-- Wishbone angle (degrees from horizontal)
	Tune.FAnchorOffset	= {			-- Suspension anchor point offset (relative to center of wheel)
		--[[Lateral]]		-0.4		,	-- positive = outward
		--[[Vertical]]		-0.5		,	-- positive = upward
		--[[Forward]]		0		}	-- positive = forward
	Tune.FSpringOffset	= {			-- Suspension anchor point offset (relative to ABOVE anchor offset) (Avxnturador)
		--[[Lateral]]		-0.4		,	-- positive = outward 
		--[[Vertical]]		0		,	-- positive = upward
		--[[Forward]]		0		}	-- positive = forward

	Tune.RSusAngle		= 80		-- Spring Angle (degrees from horizontal)
	Tune.RWsBoneLen		= 4			-- Wishbone Length
	Tune.RWsBoneAngle	= 0			-- Wishbone angle (degrees from horizontal)
	Tune.RAnchorOffset	= {			-- Suspension anchor point offset (relative to center of wheel)
		--[[Lateral]]		-0.4		,	-- positive = outward
		--[[Vertical]]		-0.5		,	-- positive = upward
		--[[Forward]]		0		}	-- positive = forward
	Tune.RSpringOffset	= {			-- Suspension anchor point offset (relative to ABOVE anchor offset) (Avxnturador)
		--[[Lateral]]		-0.4		,	-- positive = outward 
		--[[Vertical]]		0		,	-- positive = upward
		--[[Forward]]		0		}	-- positive = forward

	--Aesthetics	
	Tune.SusVisible		= false			-- Suspension Visible
	Tune.SpringsVisible	= false			-- Springs Visible
	Tune.SusRadius		= 0.2			-- Spring Coil Radius
	Tune.SusThickness	= 0.1			-- Spring Coil Thickness
	Tune.SusColor		= "Bright red"	-- Spring Color [BrickColor]
	Tune.SusCoilCount	= 6				-- Spring Coil Count
	
--[[Steering]]
	-- Front wheel steering
	Tune.SteeringType		= "Manual"		-- This can be "Auto" or "Manual".
	
	-- "Auto" Steering type somewhat realistically calculates steering angle for you
	Tune.SteerRatio			= 18/1		-- Steering ratio of your steering rack, google it for your car
	Tune.LockToLock			= 4.3		-- Number of turns of the steering wheel lock to lock, google it for your car
	Tune.Ackerman			= 1.1		-- If you don't know what it is don't touch it, ranges from .7 to 1.2
	
	-- "Manual" steering type allows you to manually set the angle of the wheels
	Tune.SteerInner			= Config.MaxSteerAngle		-- Inner wheel steering (in degrees)
	Tune.SteerOuter			= Config.MaxSteerAngle * 0.92		-- Outer wheel steering (in degrees)

	-- Steer speed tuning
	Tune.SteerSpeed			= Config.SteerSpeed		-- Steering increment per tick (in degrees)
	Tune.ReturnSpeed		= Config.ReturnSpeed		-- Steering increment per tick (in degrees)
	Tune.ContlrSteerSpeed	= 0			-- Controller version of steer speed (0 or less to be the same as SteerSpeed)
	Tune.ContlrReturnSpeed	= 0			-- Controller version of return speed (0 or less to be the same as ReturnSpeed)
	Tune.MSteerUsesContlr	= true		-- Set to true if you want mouse steering to use controller settings.
	
	-- Steer Decay
	Tune.SteerDecay			= Config.SteerDecaySpeed		-- Speed of gradient cutoff (in km/h)
	Tune.SteerSpeedDecay	= Config.SteerDecaySpeed		-- Speed of gradient cutoff of steering speed (in km/h)
	Tune.MinSteer			= Config.SteerAtTopSpeed		-- Minimum steering angle at max steer decay (in percent)
	Tune.MinSteerSpeed		= 75		-- Minimum steering speed at max decay (in percent)
	Tune.MSteerExp			= 1			-- Mouse steering exponential degree
	
	-- Counter-steer
	Tune.CSEnabled			= true		-- Enables or disables countersteering
	Tune.CSAmt				= 75		-- Amount of countersteering at a full perpendicular slide (in percent)
	Tune.CSSteerThresh		= 8		-- Threshold before countersteering activates (in percent)
	Tune.CSSpeedThresh		= 15		-- Speed threshold before countersteering can activate (in km/h)

	-- Four Wheel Steering
	Tune.FWSteer			= "None"	-- Static, Speed, Both, or None
	Tune.RSteerOuter		= 2.2		-- Outer rear wheel steering angle (in degrees)
	Tune.RSteerInner		= 1.6		-- Inner rear wheel steering angle (in degrees)
	Tune.RSteerSpeed		= 80		-- Speed at which 4WS fully activates (Speed), deactivates (Static), or transition begins (Both) (km/h)
	Tune.RSteerDecay		= 150		-- Speed of gradient cutoff (in km/h)
	
	Tune.RSteerD				= 1000		-- Rear Steering Damping (old only)
	Tune.RSteerP				= 50000		-- Rear Steering Aggressiveness (old only)
	Tune.RSteerMaxTorque		= 20000		-- Rear Steering Force (old only)

	-- Steering aggressiveness
	Tune.SteerSmoothing		= 1			-- The lower, the smoother the steering will arrive at max angle.
	Tune.PowerSteeringType	= "Old"		-- "New" uses AlignOrientation. This may cause problems.
										-- "Old" uses BodyGyro.
	Tune.SteerD				= 1000		-- Steering Damping (old only)
	Tune.SteerP				= 50000		-- Steering Aggressiveness (old only)
	Tune.SteerMaxTorque		= 20000		-- Steering Force (old only)
	
--[[Engine (Detomiks)]]

	-- *USE THE GRAPH BELOW TO PROPERLY TUNE THE ENGINE.*
	-- https://www.desmos.com/calculator/cqhgbm0vlt
	
	-- To import engines prior to 1.7, consult the README.
	
	Tune.CustomEngineCalculations	= false		-- Enables the use of the CustomEngine module. Even if enabled, please do not remove the default engine values.
	
	-- Naturally Aspirated Engine
	Tune.Engine 		= true		

		Tune.PeakTorque				= 390 * Config.Acceleration		-- The maximum amount of torque the engine makes in lb-ft.
		Tune.PeakTorqueRPM			= 2500		-- When the engine reaches PeakTorque in RPM.

		Tune.IdleRPM				= 1000		-- The engine's desired idle RPM. IdleDamping may change this.
		Tune.IdleTorque				= 315 * Config.Acceleration		-- How much torque the engine makes at idle.
		Tune.IdleTorqueCurve		= 0.275		-- The shape of the torque curve between idle and PeakRPM.

		Tune.Redline				= 7500		-- The maximum RPM.
		Tune.RedlineTorque			= 160 * Config.Acceleration		-- How much torque the engine makes at redline.
		Tune.RedlineTorqueCurve		= 0.31		-- The shape of the torque curve between PeakRPM and redline.
		
		Tune.ShiftRPM				= 7000		-- This is when the engine shifts.
		Tune.PeakRPM				= Tune.ShiftRPM		-- This is deprecated, only used for plugin compatibility.

		Tune.VVLTorque				= 0			-- Variable Valve Lift (VVL, aka VTEC)'s amount of torque. Set this to 0 to turn off.
		Tune.VVLRPM					= 3000		-- When VVL activates in RPM.
		Tune.VVLTime				= 1000		-- How long it takes for VVL to activate in RPM.
		Tune.VVLCurve				= 0.1		-- The shape of the curve during VVL activation.

		Tune.HPLimit				= 0			-- The horsepower limit of the engine (set to 0 to turn off).

	-- Electric Engine
	Tune.Electric		= true

		Tune.E_Torque				= 3600		-- The amount of electric torque in lb-ft.
		Tune.E_TransitionRPM		= 7500		-- When the torque begins decaying.

		Tune.E_Redline				= 22000		-- The maximum RPM of the electric motor.
		Tune.E_RedlineTorque		= 1800		-- How much torque is made at the maximum RPM.

		Tune.E_Curve				= 0.84		-- The shape of the curve between TransitionRPM and the redline.

	-- Turbocharger
	Tune.Turbochargers	= 0				-- Number of turbochargers in the engine, set to 0 for no turbochargers

		Tune.T_Boost			= 10		-- The maximum amount of boost of one turbocharger in PSI.
		Tune.T_PeakRPM			= 2500		-- When the turbo reaches maximum boost.

		Tune.T_IdleBoost		= 0			-- How much boost is made at idle.
		Tune.T_Curve			= 0.91		-- The shape of the boost curve between idle and PeakRPM.
		
		Tune.T_Efficiency		= 10		-- How much torque is made with 1 PSI.
		
		Tune.T_Size				= 11		-- Turbo size, larger = less boost from horsepower
		Tune.T_SpoolIncrease	= 0.3		-- Throttle response of the turbo. (Higher = more responsive, ranges from 0 to 1)
		Tune.T_SpoolDecrease	= 0.06		-- Throttle response of the turbo. (Higher = more responsive, ranges from 0 to 1)

	-- Supercharger
	Tune.Superchargers	= 0			-- Number of superchargers in the engine, Set to 0 for no superchargers

		Tune.S_Boost			= 8			-- The maximum amount of boost of one supercharger in PSI.
		Tune.S_PeakRPM			= 5500		-- When the supercharger reaches its maximum boost.
		
		Tune.S_IdleBoost		= 6.1		-- The amount of boost at idle.
		Tune.S_IdleCurve		= 0.31		-- The shape of the boost curve between idle and PeakRPM.

		Tune.S_RedlineBoost		= 5.6		-- The amount of boost at redline.
		Tune.S_RedlineCurve		= 0.187		-- The shape of the boost curve between PeakRPM and redline.

		Tune.S_Efficiency		= 4.34		-- How much torque is made with 1 PSI.

		Tune.S_Response			= 0.1		-- Throttle response of the supercharger. (Higher = more responsive, ranges from 0 to 1)


	-- Ignition
	Tune.IgnitionRPM	= 1200		-- This is how high the engine revs for the ignition.
	Tune.IgnitionAccel	= 30		-- The acceleration of the RPM while starting the car.
	Tune.IgnitionMinRPM	= 800		-- The minimum RPM required to start the car.
	
	-- Throttle and brake input
	Tune.ThrotAccel		= Config.ThrottleResponse		-- Throttle acceleration, applied per tick (recommended values between 0.1 to 0.3)
	Tune.ThrotDecel		= .3		-- Throttle deceleration, applied per tick (recommended values between 0.05 to 0.1)
	Tune.BrakeAccel		= .1		-- Brake acceleration, applied per tick
	Tune.BrakeDecel		= .2		-- Brake deceleration, applied per tick

	-- Engine speed 
	Tune.RevBounce	= 0		-- RPM kickback from redline
	Tune.OverRev		= false		-- Set to true to allow the RPM to go above redline
	
	Tune.RevAccel		= 300		-- RPM acceleration when clutch is on (this should be higher than RevDecay and RevDecayRPM)
	Tune.RevDecay		= 30		-- RPM decay when clutch is on
	Tune.RevDecayRPM	= 60		-- RPM decay from engine speed

	Tune.Flywheel		= 500		-- Flywheel weight (higher = faster response, lower = more stable RPM)
	Tune.DumpMult		= 1.0		-- Flywheel energy multiplier when dumping the clutch (keep at 1.0 for the best result).
	
	Tune.IdleThrottle	= 5			-- Percent throttle with no input. (in percent)
	Tune.IdleDamping	= 4800		-- Damping of idle in RPM. This will change that actual idle RPM at higher values.
	Tune.IdlePadding	= 800		-- Added on top of IdleRPM to account for IdleDamping
	Tune.RemoveCreep	= true		-- Tries to remove the natural creep of the chassis by applying clutch if there is no input throttle and if the RPM is below idle.
	
	Tune.InclineComp	= 2.2	    -- Torque compensation multiplier for inclines (applies gradient from 0-90 degrees)
	
--[[Drivetrain]]	
	Tune.Config			= "AWD"		-- "FWD" , "RWD" , "AWD"
	Tune.TorqueVector	= -0.25			-- AWD ONLY, "-1" has a 100% front bias, "0" has a 50:50 bias, and "1" has a 100% rear bias. Can be any number between that range.

	-- Options for a limited slip differential (LuaInt)
	-- *You can set all of these values to 0 to achieve an open differential.
	Tune.FDiffPower		= 20		-- 0 - 100				Higher values yield more wheel lock-up under throttle, more stability (Front wheels, only if driven)
	Tune.FDiffCoast		= 20		-- 0 - 100				Higher values yield more wheel lock-up when off throttle, more stability (Front wheels, only if driven)
	Tune.FDiffPreload	= 15		-- 0 - 100				Higher values will make the wheels generally lock up faster in any environment (Front wheels, only if driven)
	Tune.RDiffPower		= 20		-- 0 - 100				(Rear wheels, only if driven)
	Tune.RDiffCoast		= 20		-- 0 - 100				(Rear wheels, only if driven)
	Tune.RDiffPreload	= 15		-- 0 - 100				(Rear wheels, only if driven)

	-- Traction Control Settings
	Tune.TCSEnabled		= true		-- Implements TCS
	Tune.TCSThreshold	= 10		-- Slip speed allowed before TCS starts working (in km/h)
	Tune.TCSGradient	= 10		-- Slip speed gradient between 0 to max reduction (in km/h)
	Tune.TCSLimit		= 4			-- Minimum amount of torque at max reduction (in percent)
	
	-- Electronic Stability Control Settings
	Tune.ESCEnabled		= true		-- Implements ESC. TCS MUST ALSO BE ENABLED. This uses the same keybind as TCS.
	Tune.ESCVector		= -0.2		-- Force from the front to the rear for ESC. "-1" has a 100% front bias, "0" has a 50:50 bias, and "1" has a 100% rear bias. Can be any number between that range.
	Tune.ESCThreshold	= 0.85		-- Force difference in Gs before ESC starts working.
	Tune.ESCSpeed		= 30		-- Minimum speed before ESC can work in km/h.
	Tune.ESCThrottle	= 60		-- Maximum amount of throttle allowed to ESC in percent. (0 to allow no throttle)
	Tune.ESCBrake		= 60		-- Maximum amount of brakes allowed to ESC in percent. (0 to allow no brakes)

--[[Transmission]]
	Tune.Clutch			= false		-- Implements a realistic clutch, change to "false" for the chassis to act like AC6.81T.

	Tune.TransModes		= {"Auto"}												--[[
	[Modes]
		"Auto"		: Automatic shifting
		"Semi"		: Clutchless manual shifting, dual clutch transmission
		"Manual"	: Manual shifting with clutch
		
		>Include within brackets
			eg: {"Semi"} or {"Auto", "Manual"}								
	>First mode is default mode													]]

	Tune.ClutchMode		= "New"												--[[
	[Modes]
		"New"		: Speed controls clutch engagement			(AC6C V1.2)
		"Old"		: Speed and RPM control clutch engagement	(AC6C V1.1)		]]

	Tune.ClutchType 	= "Clutch"										--[[
	[Types]
		"Clutch"			: Standard clutch, recommended
		"TorqueConverter"	: Torque converter, keeps RPM up
		"CVT"				: Continously Variable Transmission
																		]] 
--[[Transmission]]
	--Transmission Settings
	Tune.Stall			= false		-- Stalling, enables the car to stall. An ignition plugin would be necessary. Disables if Tune.Clutch is false.
	Tune.ClutchRel		= false		-- If true, the driver must let off the gas before shifting to a higher gear. Recommended false for beginners.
	Tune.ClutchEngage	= 10		-- How fast engagement is (0 = instant, 99 = super slow)	
	Tune.SpeedEngage 	= 40		-- Speed the clutch fully engages at (Based on km/h)

	--Clutch: "Old" mode
	Tune.ClutchRPMMult	= 1			-- Clutch RPM multiplier, recommended to leave at 1.0

	--Torque Converter:
	Tune.TQLock 		= false		-- Torque converter starts locking at a certain RPM
	Tune.RPMEngage 		= 3500		-- Keeps RPMs to this level until passed

	--CVT:
	Tune.CVTRPM			= 7000		-- RPM that the CVT wants to keep at full throttle.
	Tune.CVTMaxRatio	= 6			-- The gear ratio that the CVT cannot go over.
	Tune.CVTMinRatio	= 1			-- The gear ratio that the CVT cannot go under.

	--Neutral Rev Limiter (Avxnturador)
	Tune.NeutralLimit	= false		-- Enables a different redline RPM for when the car is in neutral
	Tune.NeutralRevRPM	= 5000		-- The rev limiter when the car is in neutral
	Tune.LimitClutch	= false		-- Will also limit RPMs while the clutch is pressed down

	--Automatic Settings
	Tune.AutoShiftMode	= "Speed"												--[[
	[Modes]
		"Speed"		: Shifts based on wheel speed
		"RPM"		: Shifts based on RPM										]]	
	Tune.AutoShiftType	= "DCT"												--[[
	[Types]
		"Rev"		: Clutch engages fully once RPM reached			(AC6C V1)
		"DCT"		: Clutch engages after a set time has passed	(AC6.81T)	]]
	Tune.AutoShiftVers	= "Old"												--[[
	[Versions]
		"New"		: Shift from Reverse, Neutral, and Drive		(AC6.81T)
		"Old"		: Auto shifts into R or D when stopped.			(AC6.52S2)	]]
	Tune.AutoUpThresh	= -200		-- Automatic upshift point 	(relative to peak RPM, positive = Over-rev)
	Tune.AutoDownThresh = 1400		-- Automatic downshift point (relative to peak RPM, positive = Under-rev)

	--Automatic: Revmatching
	Tune.ShiftThrot		= 100		-- Throttle level when shifting down to revmatch, 0 - 100%

	--Automatic: DCT
	Tune.ShiftUpTime	= 0.05		-- Time required to shift into next gear, from a lower gear to a higher one.
	Tune.ShiftDnTime	= 0.05		-- Time required to shift into next gear, from a higher gear to a lower one.

	--Gear Ratios
	--You can tune the gears in the engine graphs by switching G_TunerType inside Desmos
	Tune.FinalDrive		= Config.FinalDrive
	Tune.Ratios			= {
		--[[Park]]		--0			, --"0" enables the parking gear, "--0" disables.
		--[[Reverse]]	3.18		,
		--[[Neutral]]	0			,
		--[[ 1 ]]		3.927		,
		--[[ 2 ]]		2.454		,
		--[[ 3 ]]		1.785		,
		--[[ 4 ]]		1.413		,
		--[[ 5 ]]		1.101		,
		--[[ 6 ]]		0.893		,
	}

	Tune.FDMult			= 1			-- Ratio multiplier (keep this at 1 if car is not struggling with torque)

	-- Speed Limiter
	Tune.SpeedLimit 	= Config.TopSpeed	 		-- Maximum speed limit in km/h (0 or less for no limiter)
	Tune.AirborneGravity = Config.AirGravity
	Tune.AirborneDensityScale = Config.AirborneDensityScale
	Tune.AirLaunchMinimumSpeed = Config.AirLaunchMinimumSpeed
	Tune.AirLaunchBaseBoost = Config.AirLaunchBaseBoost
	Tune.AirLaunchSpeedScale = Config.AirLaunchSpeedScale
	Tune.AirLaunchMaxVerticalSpeed = Config.AirLaunchMaxVerticalSpeed
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
	-- Hoki Arcade Drift Multi-Vehicle Mappings
	Tune.TapDriftEnabled           = Config.TapDriftEnabled
	Tune.TapDriftTapDuration       = Config.TapDriftTapDuration
	Tune.TapDriftMinSpeed          = Config.TapDriftMinSpeed
	Tune.TapDriftRearBrake         = Config.TapDriftRearBrake
	Tune.TapDriftPowerRatio        = Config.TapDriftPowerRatio
	Tune.TapDriftMaxDuration       = Config.TapDriftMaxDuration
	Tune.TireSmokeEnabled          = Config.TireSmokeEnabled
	Tune.TireSmokeDriftRate        = Config.TireSmokeDriftRate
	Tune.TireSmokeBrakeRate        = Config.TireSmokeBrakeRate
	Tune.DownforceFrontKgf = Config.DownforceFrontKgf
	Tune.DownforceRearKgf = Config.DownforceRearKgf
	Tune.ReverseSpeed	= 40		-- Maximum reverse speed limit
	Tune.SLimitGradient	= 2			-- Throttle and brake interpolation
	Tune.SLimitBrake	= true		-- If true, this will apply the brake if the car is moving too quickly.

	--[[Brakes]]
	Tune.ExitBrake		= true		-- Set to false if you don't want the car to apply the parking brake when exiting

	-- ABS
	Tune.ABSEnabled		= true		-- Implements the Antilock Braking System
	Tune.ABSThreshold	= 3			-- Slip speed allowed before ABS starts working (in km/h) 
	Tune.ABSGradient	= 8			-- Slip speed gradient between 0 to max reduction (in km/h)
	Tune.ABSLimit		= 0			-- Minimum amount of torque at max reduction (in percent)
	
	-- Forces
	Tune.BrakeForce		= Config.BrakeForce		-- Total brake force in kgf
	Tune.BrakeBias		= 0.65		-- Brake bias towards the front, percentage (1 = Front, 0 = Rear, .5 = 50/50)
	Tune.PBrakeForce	= 5000		-- Handbrake force in kgf (strong parking lock)
	Tune.PBrakeBias		= 0.5			-- Handbrake bias towards the front, percentage (1 = Front, 0 = Rear, .5 = 50/50)
	Tune.EBrakeForce	= 1600		-- Engine braking force at redline in kgf (2x stronger coast slowdown)

--[[[Default Controls]]
	--Peripheral Deadzones
	Tune.Peripherals = {
		MSteerWidth				= 67		,	-- Mouse steering control width	(0 - 100% of screen width)
		MSteerDZone				= 10		,	-- Mouse steering deadzone (0 - 100%)

		ControlLDZone			= 5			,	-- Controller steering L-deadzone (0 - 100%)
		ControlRDZone			= 5			,	-- Controller steering R-deadzone (0 - 100%)
	}

	--Control Mapping
	Tune.Controls = {

		--Keyboard Controls (W/A/S/D & Arrow Keys only per user request)
		ToggleTCS				= Enum.KeyCode.Unknown				,
		ToggleABS				= Enum.KeyCode.Unknown				,
		ToggleCS				= Enum.KeyCode.Unknown				,
		ToggleTransMode			= Enum.KeyCode.Unknown				,
		ToggleMouseDrive		= Enum.KeyCode.Unknown				,

		--Primary Controls
		Throttle				= Enum.KeyCode.Up					,
		Brake					= Enum.KeyCode.Down					,
		SteerLeft				= Enum.KeyCode.Left					,
		SteerRight				= Enum.KeyCode.Right				,

		--Secondary Controls
		Throttle2				= Enum.KeyCode.W					,
		Brake2					= Enum.KeyCode.S					,
		SteerLeft2				= Enum.KeyCode.A					,
		SteerRight2				= Enum.KeyCode.D					,

		--Manual Transmission (Disabled)
		ShiftUp					= Enum.KeyCode.Unknown				,
		ShiftDown				= Enum.KeyCode.Unknown				,
		Clutch					= Enum.KeyCode.Unknown				,

		--Handbrake (Disabled)
		PBrake					= Enum.KeyCode.Unknown				,

		--Mouse Controls (Disabled)
		MouseThrottle			= Enum.KeyCode.Unknown				,
		MouseBrake				= Enum.KeyCode.Unknown				,
		MouseClutch				= Enum.KeyCode.Unknown				,
		MouseShiftUp			= Enum.KeyCode.Unknown				,
		MouseShiftDown			= Enum.KeyCode.Unknown				,
		MousePBrake				= Enum.KeyCode.Unknown				,

		--Controller Mapping (Clean driving only)
		ContlrThrottle			= Enum.KeyCode.ButtonR2				,
		ContlrBrake				= Enum.KeyCode.ButtonL2				,
		ContlrSteer				= Enum.KeyCode.Thumbstick1			,
		ContlrShiftUp			= Enum.KeyCode.Unknown				,
		ContlrShiftDown			= Enum.KeyCode.Unknown				,
		ContlrClutch			= Enum.KeyCode.Unknown				,
		ContlrPBrake			= Enum.KeyCode.Unknown				,
		ContlrToggleTMode		= Enum.KeyCode.Unknown				,
		ContlrToggleTCS			= Enum.KeyCode.Unknown				,
		ContlrToggleABS			= Enum.KeyCode.Unknown				,
		ContlrToggleCS			= Enum.KeyCode.Unknown				,
	}

return Tune

