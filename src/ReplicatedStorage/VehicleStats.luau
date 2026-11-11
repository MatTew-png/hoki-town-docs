--!strict
--[=[
	VehicleStats.luau
	HOKI TOWN - Vehicle Engineering
	Shared Single Source of Truth (SSOT) stat sheet for the Hybrid Raycast Chassis.

	Used by both the client physics solver and the server validation / damage logic.
	Zero raw physics solver constants are mutated directly by upgrades. Every upgrade
	and ECU tuning slider maps to a clean, bounded multiplier. Vertical suspension
	stiffness, ride height, and vehicle Mass are never touched by this module.
]=]

export type WheelKey = "FL" | "FR" | "RL" | "RR"

export type TireStates = {
	FL: boolean,
	FR: boolean,
	RL: boolean,
	RR: boolean,
}

export type ComputedVehicleStats = {
	TopSpeed: number,
	ReverseSpeed: number,
	DriveAcceleration: number,
	LaunchAccelMultiplier: number,
	HighSpeedPullMultiplier: number,
	BrakeAcceleration: number,
	LateralGrip: number,
	AntiRollRatio: number,
	OversteerSensitivity: number,
	MaxHealth: number,
	ImpactDamageMultiplier: number,
	TurboBoostPower: number,
	AirGravityScale: number,
	AirPitchRate: number,
	AirYawRate: number,
	AirRollRate: number,
	AirControlDelay: number,
	CurbHeight: number,
	CurbAssistForce: number,
	PoppedTireCount: number,
	FrontSteerBias: number,
	EffectiveTopSpeed: number,
	TireStates: TireStates,
}

local VehicleStats = {}

local function clamp(value: number, minimum: number, maximum: number): number
	return math.clamp(value, minimum, maximum)
end

local function lerp(from: number, to: number, t: number): number
	return from + (to - from) * t
end

local function tier01(tier: number, minimum: number, maximum: number): number
	if maximum <= minimum then
		return 0
	end
	return clamp((tier - minimum) / (maximum - minimum), 0, 1)
end

local function getNumber(car: Model, name: string, default: number): number
	local value = car:GetAttribute(name)
	if typeof(value) == "number" then
		return value
	end
	return default
end

local function getBoolean(car: Model, name: string, default: boolean): boolean
	local value = car:GetAttribute(name)
	if typeof(value) == "boolean" then
		return value
	end
	return default
end

local LIMP_FACTORS = { 1.0, 0.82, 0.62, 0.42, 0.28 }

function VehicleStats.EnsureDefaultAttributes(car: Model): ()
	local defaults: { [string]: any } = {
		EngineTier = 1,
		BrakeTier = 1,
		TransmissionTier = 1,
		SuspensionTier = 1,
		ArmourTier = 1,
		TurboTier = 0,
		ECU_GripBias = 0,
		ECU_PowerMap = 0,
		ECU_AirWeight = 0.70,
		TirePopped_FL = false,
		TirePopped_FR = false,
		TirePopped_RL = false,
		TirePopped_RR = false,
	}
	for name, value in pairs(defaults) do
		if car:GetAttribute(name) == nil then
			car:SetAttribute(name, value)
		end
	end
end

function VehicleStats.GetTireStates(car: Model): TireStates
	return {
		FL = getBoolean(car, "TirePopped_FL", false),
		FR = getBoolean(car, "TirePopped_FR", false),
		RL = getBoolean(car, "TirePopped_RL", false),
		RR = getBoolean(car, "TirePopped_RR", false),
	}
end

function VehicleStats.Compute(car: Model): ComputedVehicleStats
	local engineTier = clamp(getNumber(car, "EngineTier", 1), 1, 5)
	local brakeTier = clamp(getNumber(car, "BrakeTier", 1), 1, 5)
	local transmissionTier = clamp(getNumber(car, "TransmissionTier", 1), 1, 5)
	local suspensionTier = clamp(getNumber(car, "SuspensionTier", 1), 1, 5)
	local armourTier = clamp(getNumber(car, "ArmourTier", 1), 1, 5)
	local turboTier = clamp(getNumber(car, "TurboTier", 0), 0, 5)

	local ecuGripBias = clamp(getNumber(car, "ECU_GripBias", 0), -1, 1)
	local ecuPowerMap = clamp(getNumber(car, "ECU_PowerMap", 0), -1, 1)
	local ecuAirWeight = clamp(getNumber(car, "ECU_AirWeight", 0.70), 0.50, 1.00)

	-- EngineTier: base top speed and drive acceleration.
	local topSpeed = lerp(175, 245, tier01(engineTier, 1, 5))
	local driveAcceleration = lerp(85, 130, tier01(engineTier, 1, 5))

	-- TransmissionTier: low-end launch response and reverse speed.
	local launchAccelMultiplier = lerp(1.0, 1.45, tier01(transmissionTier, 1, 5))
	local reverseSpeed = lerp(42, 62, tier01(transmissionTier, 1, 5))

	-- TurboTier: high-RPM pull and blow-off valve / turbo audio power.
	local highSpeedPullMultiplier = lerp(1.0, 1.40, tier01(turboTier, 0, 5))
	local turboBoostPower = lerp(0, 1.0, tier01(turboTier, 0, 5))

	-- BrakeTier: braking force only.
	local brakeAcceleration = lerp(150, 270, tier01(brakeTier, 1, 5))

	-- SuspensionTier: cornering grip + anti-roll only (never vertical spring stiffness / ride height).
	local lateralGrip = lerp(1.25, 1.65, tier01(suspensionTier, 1, 5))
	local antiRollRatio = lerp(0.25, 0.45, tier01(suspensionTier, 1, 5))

	-- ArmourTier: health and impact resistance only (never physics Mass).
	local maxHealth = lerp(100, 250, tier01(armourTier, 1, 5))
	local impactDamageMultiplier = lerp(1.0, 0.40, tier01(armourTier, 1, 5))

	-- ECU Grip Bias: lateral grip range [0.75x, 1.25x] and inverse oversteer sensitivity.
	local gripBiasT = (ecuGripBias + 1) / 2
	lateralGrip *= lerp(0.75, 1.25, gripBiasT)
	local oversteerSensitivity = lerp(1.6, 0.4, gripBiasT)

	-- ECU Power Map: trade launch acceleration against top speed by up to ±12%.
	launchAccelMultiplier *= 1 - ecuPowerMap * 0.12
	topSpeed *= 1 + ecuPowerMap * 0.12

	-- ECU Air Weight: airborne gravity scale (default 0.70 = 30% lighter).
	local airGravityScale = ecuAirWeight

	-- Tire puncture penalties.
	local tireStates = VehicleStats.GetTireStates(car)
	local poppedCount = 0
	for _, popped in pairs(tireStates) do
		if popped then
			poppedCount += 1
		end
	end
	poppedCount = clamp(poppedCount, 0, 4)
	local effectiveTopSpeed = topSpeed * (LIMP_FACTORS[poppedCount + 1] or 0.28)

	local frontSteerBias = (if tireStates.FL then -0.18 else 0) + (if tireStates.FR then 0.18 else 0)

	return {
		TopSpeed = topSpeed,
		ReverseSpeed = reverseSpeed,
		DriveAcceleration = driveAcceleration,
		LaunchAccelMultiplier = launchAccelMultiplier,
		HighSpeedPullMultiplier = highSpeedPullMultiplier,
		BrakeAcceleration = brakeAcceleration,
		LateralGrip = lateralGrip,
		AntiRollRatio = antiRollRatio,
		OversteerSensitivity = oversteerSensitivity,
		MaxHealth = maxHealth,
		ImpactDamageMultiplier = impactDamageMultiplier,
		TurboBoostPower = turboBoostPower,
		AirGravityScale = airGravityScale,
		AirPitchRate = 1.4,
		AirYawRate = 1.5,
		AirRollRate = 1.2,
		AirControlDelay = 0.15,
		CurbHeight = 2.1,
		CurbAssistForce = 1.25,
		PoppedTireCount = poppedCount,
		FrontSteerBias = frontSteerBias,
		EffectiveTopSpeed = effectiveTopSpeed,
		TireStates = tireStates,
	}
end

return VehicleStats
