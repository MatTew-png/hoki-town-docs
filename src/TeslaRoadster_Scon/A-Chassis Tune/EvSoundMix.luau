--!strict
-- Shared Tesla EV sound profile & acoustic smoothing for TeslaRoadster_Scon.
-- Used identically by both A-Chassis Interface/Sounds (local 60Hz) and car.Sounds.Server (3D FE).

local EvSoundMix = {}

EvSoundMix.ASSETS = {
	PWS = "rbxassetid://134888998064928", -- Warm low-speed Tesla PWS / UFO hum (4.49s)
	Motor = "rbxassetid://6454137904", -- Smooth continuous EV inverter whir (8.48s)
	Chime = "rbxassetid://6107437073", -- Clean Tesla power-on chime (1.01s)
}

local LEGACY_PREFIXES = {
	"ENG_",
	"TUR_",
	"SUP_",
	"BOV_",
	"TRA_",
	"IGN_",
}

local LEGACY_EXACT = {
	WindSound = true,
	BodySound = true,
}

export type EvTargets = {
	pwsVol: number,
	pwsPitch: number,
	motorVol: number,
	motorPitch: number,
	motorMidGain: number,
	motorHighGain: number,
	revVol: number,
	revPitch: number,
}

export type EvChannel = {
	sound: Sound,
	eq: EqualizerSoundEffect,
}

export type EvRig = {
	pws: EvChannel,
	motor: EvChannel,
	reverse: EvChannel,
	chime: EvChannel,
}

function EvSoundMix.isLegacySoundName(name: string): boolean
	if LEGACY_EXACT[name] then
		return true
	end
	for _, prefix in ipairs(LEGACY_PREFIXES) do
		if string.sub(name, 1, #prefix) == prefix then
			return true
		end
	end
	return false
end

function EvSoundMix.cleanupLegacySounds(root: Instance?, localOnly: boolean?)
	if not root then
		return
	end
	for _, desc in ipairs(root:GetDescendants()) do
		if desc:IsA("Sound") and EvSoundMix.isLegacySoundName(desc.Name) then
			local isClientOwned = (string.sub(desc.Name, -6) == "_Local") or LEGACY_EXACT[desc.Name] == true
			if not localOnly or isClientOwned then
				desc:Stop()
				desc:Destroy()
			end
		end
	end
end

local function makeOrResetChannel(
	parent: Instance,
	name: string,
	soundId: string,
	looped: boolean,
	minDist: number,
	maxDist: number,
	lowGain: number,
	midGain: number,
	highGain: number
): EvChannel
	local existing = parent:FindFirstChild(name)
	local s: Sound
	if existing and existing:IsA("Sound") then
		s = existing
	else
		s = Instance.new("Sound")
		s.Name = name
		s.Parent = parent
	end

	s.SoundId = soundId
	s.Looped = looped
	s.Volume = 0
	s.PlaybackSpeed = 1
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = minDist
	s.RollOffMaxDistance = maxDist
	s.Playing = false

	-- Strip any leftover distortion or old filters
	for _, ch in ipairs(s:GetChildren()) do
		if ch:IsA("SoundEffect") and ch.Name ~= "#EV_EQ" then
			ch:Destroy()
		end
	end

	local existingEq = s:FindFirstChild("#EV_EQ")
	local eq: EqualizerSoundEffect
	if existingEq and existingEq:IsA("EqualizerSoundEffect") then
		eq = existingEq
	else
		eq = Instance.new("EqualizerSoundEffect")
		eq.Name = "#EV_EQ"
		eq.Parent = s
	end

	eq.LowGain = lowGain
	eq.MidGain = midGain
	eq.HighGain = highGain
	eq.Enabled = true

	return {
		sound = s,
		eq = eq,
	}
end

function EvSoundMix.ensureRig(parent: Instance, suffix: string): EvRig
	return {
		pws = makeOrResetChannel(parent, "EV_PWS" .. suffix, EvSoundMix.ASSETS.PWS, true, 8, 95, 2.5, -2.0, -10.0),
		motor = makeOrResetChannel(
			parent,
			"EV_Motor" .. suffix,
			EvSoundMix.ASSETS.Motor,
			true,
			8,
			110,
			1.5,
			-2.5,
			-11.0
		),
		reverse = makeOrResetChannel(
			parent,
			"EV_Reverse" .. suffix,
			EvSoundMix.ASSETS.PWS,
			true,
			8,
			85,
			0.5,
			-2.0,
			-8.0
		),
		chime = makeOrResetChannel(parent, "EV_Chime" .. suffix, EvSoundMix.ASSETS.Chime, false, 6, 42, 1.0, 0.0, -3.0),
	}
end

function EvSoundMix.destroyRig(rig: EvRig?)
	if not rig then
		return
	end
	for _, ch in ipairs({ rig.pws, rig.motor, rig.reverse, rig.chime }) do
		if ch.sound.Parent then
			ch.sound:Stop()
			ch.sound.Volume = 0
			ch.sound:Destroy()
		end
	end
end

function EvSoundMix.stopAll(rig: EvRig?)
	if not rig then
		return
	end
	for _, ch in ipairs({ rig.pws, rig.motor, rig.reverse, rig.chime }) do
		ch.sound.Volume = 0
		ch.sound:Stop()
	end
end

function EvSoundMix.computeTargets(
	speedKmh: number,
	throttle: number,
	brake: number,
	gear: number,
	isOn: boolean,
	volumeScale: number?
): EvTargets
	local scale = volumeScale or 1
	if not isOn then
		return {
			pwsVol = 0,
			pwsPitch = 0.86,
			motorVol = 0,
			motorPitch = 0.56,
			motorMidGain = -2.5,
			motorHighGain = -11.0,
			revVol = 0,
			revPitch = 1.16,
		}
	end

	local spd = math.max(0, speedKmh)
	local throt = math.clamp(throttle, 0, 1)
	local brk = math.clamp(brake, 0, 1)
	local speedNorm = math.clamp(spd / 220, 0, 1.15)
	local isCoasting = (throt < 0.05) and (spd > 12)

	-- 1. Low-speed Tesla Pedestrian Warning halo (silent at standstill, hands off by ~60 km/h)
	local pwsIn = math.clamp((spd - 1.5) / 6.5, 0, 1)
	local pwsOut = 1 - math.clamp((spd - 35) / 25, 0, 1)
	local pwsVol = 0.11 * pwsIn * pwsOut * (0.78 + 0.22 * throt) * scale
	local pwsPitch = 0.86 + 0.32 * math.clamp(spd / 45, 0, 1)

	-- 2. Fatigue-free EV inverter motor: continuous single-speed pitch, gentle during steady cruise
	local moveFactor = math.clamp((spd - 6) / 28, 0, 1)
	local launchFactor = throt * math.clamp(spd / 8, 0, 1)
	local baseDrivePresence = math.max(moveFactor, launchFactor)
	local regenBoost = (isCoasting or (brk > 0.1 and spd > 10)) and (0.015 + 0.025 * brk) or 0
	local motorVol = baseDrivePresence
		* (0.045 + 0.125 * throt + regenBoost)
		* (0.55 + 0.45 * math.min(speedNorm, 1))
		* scale
	local motorPitch = math.max(0.48, 0.56 + 0.88 * speedNorm - brk * 0.03)
	local motorMidGain = -2.5 + 1.5 * throt
	local motorHighGain = -11.0 + 4.5 * throt

	-- 3. Soft EV reverse tone (never high-pitched screech)
	local revFactor = (gear < 0 and spd > 1.2) and math.clamp((spd - 1.2) / 5, 0, 1) or 0
	local revVol = 0.095 * revFactor * scale
	local revPitch = 1.16

	return {
		pwsVol = pwsVol,
		pwsPitch = pwsPitch,
		motorVol = motorVol,
		motorPitch = motorPitch,
		motorMidGain = motorMidGain,
		motorHighGain = motorHighGain,
		revVol = revVol,
		revPitch = revPitch,
	}
end

local function stepLoopChannel(
	channel: EvChannel,
	targetVol: number,
	targetPitch: number,
	volBlend: number,
	pitchBlend: number
)
	local s = channel.sound
	s.Volume += (targetVol - s.Volume) * volBlend
	s.PlaybackSpeed += (targetPitch - s.PlaybackSpeed) * pitchBlend
	if targetVol > 0.002 then
		if not s.Playing then
			s:Play()
		end
	elseif s.Volume <= 0.002 and s.Playing then
		s.Volume = 0
		s:Stop()
	end
end

function EvSoundMix.applyTargets(rig: EvRig, targets: EvTargets, dt: number)
	local clampedDt = math.clamp(dt, 1 / 240, 0.25)
	local volBlend = 1 - math.exp(-clampedDt * 8)
	local pitchBlend = 1 - math.exp(-clampedDt * 12)

	stepLoopChannel(rig.pws, targets.pwsVol, targets.pwsPitch, volBlend, pitchBlend)
	stepLoopChannel(rig.motor, targets.motorVol, targets.motorPitch, volBlend, pitchBlend)
	stepLoopChannel(rig.reverse, targets.revVol, targets.revPitch, volBlend, pitchBlend)

	rig.motor.eq.MidGain += (targets.motorMidGain - rig.motor.eq.MidGain) * volBlend
	rig.motor.eq.HighGain += (targets.motorHighGain - rig.motor.eq.HighGain) * volBlend
end

return EvSoundMix
