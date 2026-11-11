--!strict
--[[
    VehicleSoundClient.client.luau
    HOKI TOWN - Vehicle Engineering
    A-Chassis 1.7 EQ / Turbo audio synthesis for the Hybrid Raycast Roadster.

    Builds the full engine sound stack on DriveSeat and drives pitch, EQ, distortion,
    turbo, blow-off valve, reverse beep, and starter from client-local telemetry
    attributes (ClientRPM / ClientGear / ClientThrottle / ClientBoost) plus TurboTier.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local car = script.Parent :: Model
local seat = car:WaitForChild("DriveSeat") :: VehicleSeat

local ROLLOFF = 120

type EngineSound = {
	sound: Sound,
	eq: EqualizerSoundEffect?,
	distortion: DistortionSoundEffect?,
}

local function createSound(
	name: string,
	id: string,
	looped: boolean,
	volume: number,
	withEq: boolean,
	withDistortion: boolean
): EngineSound
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Looped = looped
	sound.Volume = volume
	sound.RollOffMaxDistance = ROLLOFF
	sound.Parent = seat

	local eq: EqualizerSoundEffect? = nil
	local distortion: DistortionSoundEffect? = nil
	if withEq then
		local newEq = Instance.new("EqualizerSoundEffect")
		newEq.Name = "EQ"
		newEq.Parent = sound
		eq = newEq
	end
	if withDistortion then
		local newDistortion = Instance.new("DistortionSoundEffect")
		newDistortion.Name = "Distortion"
		newDistortion.Parent = sound
		distortion = newDistortion
	end

	return { sound = sound, eq = eq, distortion = distortion }
end

local engIdle = createSound("ENG_Idle", "rbxassetid://5226685480", true, 0.45, false, false)
local engEngine = createSound("ENG_Engine", "rbxassetid://6002661882", true, 0.8, true, true)
local engExhaust = createSound("ENG_Exhaust", "rbxassetid://1489232045", true, 0.7, true, true)
local engExhaust2 = createSound("ENG_Exhaust2", "rbxassetid://1235897119", true, 0.55, true, true)
local turTurbo = createSound("TUR_Turbo", "rbxassetid://240323039", true, 0, false, false)
local turTurbo2 = createSound("TUR_Turbo2", "rbxassetid://1033010834", true, 0, false, false)
local bovBov = createSound("BOV_BOV", "rbxassetid://3568930062", false, 0.9, false, false)
local traReverse = createSound("TRA_Reverse", "rbxassetid://404779487", true, 0, false, false)
local ignStarter = createSound("IGN_Starter", "rbxassetid://169394147", false, 0.8, false, false)

local OFF_EQ = { Low = -6, Mid = -4, High = -6 }
local THROTTLE_EQ = { Low = 6, Mid = 2, High = 4 }

local RPM_MIN = 850
local RPM_MAX = 7500

local currentPitch = 0.75
local lastBoost = 0

local function setEq(effect: EqualizerSoundEffect?, throttle: number)
	if not effect then
		return
	end
	local t = math.clamp(throttle, 0, 1)
	effect.LowGain = OFF_EQ.Low + (THROTTLE_EQ.Low - OFF_EQ.Low) * t
	effect.MidGain = OFF_EQ.Mid + (THROTTLE_EQ.Mid - OFF_EQ.Mid) * t
	effect.HighGain = OFF_EQ.High + (THROTTLE_EQ.High - OFF_EQ.High) * t
end

local function rpmToPitch(rpm: number): number
	local t = math.clamp((rpm - RPM_MIN) / (RPM_MAX - RPM_MIN), 0, 1)
	return 0.75 + t * 1.2
end

local function stopAll()
	for _, engineSound in ipairs({ engIdle, engEngine, engExhaust, engExhaust2, turTurbo, turTurbo2, traReverse }) do
		engineSound.sound:Stop()
	end
end

local function playEngineLoop()
	engIdle.sound:Play()
	engEngine.sound:Play()
	engExhaust.sound:Play()
	engExhaust2.sound:Play()
end

-- Remote observers do not run the physics solver, so ClientRPM is nil for them.
-- Estimate a plausible pitch & throttle from the chassis speed so they still hear
-- the engine rather than a dead silent car.
local function estimateRemoteTelemetry(): (number, number)
	local speed = seat.AssemblyLinearVelocity.Magnitude
	local speedRatio = math.clamp(speed / 70, 0, 1)
	local rpm = RPM_MIN + (RPM_MAX - RPM_MIN) * (0.15 + speedRatio * 0.85)
	local throttle = math.clamp(speed / 45, 0, 1)
	return rpm, throttle
end

local function onRender()
	if not car:IsDescendantOf(workspace) then
		stopAll()
		return
	end

	local occupied = seat.Occupant ~= nil
	if not occupied then
		stopAll()
		currentPitch = 0.75
		lastBoost = 0
		return
	end

	if not engIdle.sound.IsPlaying then
		playEngineLoop()
	end

	local clientRpm = tonumber(car:GetAttribute("ClientRPM"))
	local clientThrottle = tonumber(car:GetAttribute("ClientThrottle"))
	local rpm: number
	local throttle: number
	if clientRpm == nil then
		rpm, throttle = estimateRemoteTelemetry()
	else
		rpm = clientRpm
		throttle = clientThrottle or 0
	end
	local gear = tonumber(car:GetAttribute("ClientGear")) or 0
	local boost = tonumber(car:GetAttribute("ClientBoost")) or 0
	local turboTier = tonumber(car:GetAttribute("TurboTier")) or 0

	local targetPitch = rpmToPitch(rpm)
	currentPitch += (targetPitch - currentPitch) * 0.15

	engIdle.sound.PlaybackSpeed = 0.75
	engEngine.sound.PlaybackSpeed = currentPitch
	engExhaust.sound.PlaybackSpeed = currentPitch * 0.98
	engExhaust2.sound.PlaybackSpeed = currentPitch * 1.02

	engEngine.sound.Volume = 0.8 + throttle * 0.2
	engExhaust.sound.Volume = 0.7 + throttle * 0.25
	engExhaust2.sound.Volume = 0.55 + throttle * 0.2

	setEq(engEngine.eq, throttle)
	setEq(engExhaust.eq, throttle)
	setEq(engExhaust2.eq, throttle)

	if engEngine.distortion then
		engEngine.distortion.Level = throttle * 0.5
	end
	if engExhaust.distortion then
		engExhaust.distortion.Level = throttle * 0.4
	end
	if engExhaust2.distortion then
		engExhaust2.distortion.Level = throttle * 0.35
	end

	-- Turbo spool volume scales with TurboTier and boost.
	local turboEnabled = turboTier > 0
	if turboEnabled then
		if not turTurbo.sound.IsPlaying then
			turTurbo.sound:Play()
			turTurbo2.sound:Play()
		end
		local turboVolume = (0.25 + boost * 0.75) * (turboTier / 5)
		turTurbo.sound.Volume = turboVolume
		turTurbo2.sound.Volume = turboVolume * 0.7
		turTurbo.sound.PlaybackSpeed = 0.9 + boost * 0.5
		turTurbo2.sound.PlaybackSpeed = 0.9 + boost * 0.45
	else
		turTurbo.sound.Volume = 0
		turTurbo2.sound.Volume = 0
		if turTurbo.sound.IsPlaying then
			turTurbo.sound:Stop()
			turTurbo2.sound:Stop()
		end
	end

	-- Blow-off valve: one-shot when releasing throttle after boost builds up.
	if turboEnabled and lastBoost > 0.28 and boost < lastBoost and throttle < 0.2 then
		bovBov.sound:Play()
	end
	lastBoost = boost

	-- Reverse beep fades in when in reverse and moving.
	if gear == -1 then
		if not traReverse.sound.IsPlaying then
			traReverse.sound:Play()
		end
		traReverse.sound.Volume = math.clamp(rpm / RPM_MAX, 0, 1) * 0.6
	else
		traReverse.sound.Volume = 0
		if traReverse.sound.IsPlaying then
			traReverse.sound:Stop()
		end
	end
end

local renderConn: RBXScriptConnection
local seatConn: RBXScriptConnection
local ancestryConn: RBXScriptConnection
local destroyingConn: RBXScriptConnection

local function cleanup()
	renderConn:Disconnect()
	seatConn:Disconnect()
	ancestryConn:Disconnect()
	destroyingConn:Disconnect()
	stopAll()
	ignStarter.sound:Stop()
	bovBov.sound:Stop()
end

local wasDriver = false
seatConn = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
	local isDriver = seat.Occupant ~= nil and seat.Occupant.Parent == Players.LocalPlayer.Character
	if isDriver and not wasDriver then
		ignStarter.sound:Play()
	end
	if not isDriver then
		stopAll()
	end
	wasDriver = isDriver
end)

ancestryConn = car.AncestryChanged:Connect(function()
	if car.Parent == nil then
		cleanup()
	end
end)

destroyingConn = car.Destroying:Connect(function()
	cleanup()
end)

renderConn = RunService.RenderStepped:Connect(onRender)
