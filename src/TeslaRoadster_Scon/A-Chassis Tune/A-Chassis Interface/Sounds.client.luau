--!strict
--[[
	TeslaRoadster_Scon Electric Vehicle Client Audio Controller
	Features:
	- Smooth speed+throttle EV Motor + low-speed PWS halo (silent at park, gentle during cruise)
	- Single soft Tesla power-on chime on seat/ignition engage
	- Cleans up legacy combustion/wind audio; syncs telemetry cleanly to car.Sounds
]]

local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local interface = script.Parent
local car = interface:WaitForChild("Car").Value :: Model?
if not car then
	return
end

local tuneFolder = car:WaitForChild("Hoki-Chassis Tune", 5)
if not tuneFolder then
	return
end
local EvSoundMix = require(tuneFolder:WaitForChild("EvSoundMix"))
local Units = require(tuneFolder.README.Units)

local values = interface:WaitForChild("Values", 5)
if not values then
	return
end

local FE = true
local FE_RATE = 1 / 15

local body = car:WaitForChild("Body", 5)
if not body then
	return
end
local soundsDir = body:WaitForChild("Sounds", 5)
local mountPart = (soundsDir and soundsDir:FindFirstChild("Engine")) or body:FindFirstChild("#Weight")
if not mountPart then
	return
end

local weightPart = body:FindFirstChild("#Weight")
local remoteEvent = car:FindFirstChild("Sounds")
if not remoteEvent then
	remoteEvent = car:WaitForChild("Sounds", 5)
end

-- Purge any leftover local/wind sounds left on Body.Sounds or #Weight
EvSoundMix.cleanupLegacySounds(soundsDir, true)
EvSoundMix.cleanupLegacySounds(weightPart, true)

-- Mute server-replicated EV channels locally on driver client via SoundGroup so only silky 60Hz audio plays
local muteGroup = Instance.new("SoundGroup")
muteGroup.Name = "HokiEvServerMute_" .. car.Name
muteGroup.Volume = 0
muteGroup.Parent = SoundService

local mutedServerSounds: { Sound } = {}
local function suppressServerSound(inst: Instance)
	if inst:IsA("Sound") and string.sub(inst.Name, 1, 3) == "EV_" and string.sub(inst.Name, -6) ~= "_Local" then
		inst.SoundGroup = muteGroup
		table.insert(mutedServerSounds, inst)
	end
end

for _, child in ipairs(mountPart:GetChildren()) do
	suppressServerSound(child)
end
local serverChildConn = mountPart.ChildAdded:Connect(suppressServerSound)

-- Create local EV rig
local rig = EvSoundMix.ensureRig(mountPart, "_Local")
task.spawn(function()
	pcall(function()
		ContentProvider:PreloadAsync({ rig.pws.sound, rig.motor.sound, rig.reverse.sound, rig.chime.sound })
	end)
end)

local VelocityValue = values:WaitForChild("Velocity") :: Vector3Value
local ThrottleValue = values:WaitForChild("Throttle") :: NumberValue
local BrakeValue = values:WaitForChild("Brake") :: NumberValue
local GearValue = values:WaitForChild("Gear") :: IntValue
local IsOnValue = interface:WaitForChild("IsOn") :: BoolValue

local toKMH = (Units.Length_mm / 1000) * 3.6
local pendingChimeForServer = false
local wasOn = false

local function triggerChimeOnce()
	local chimeSound = rig.chime.sound
	chimeSound.Volume = 0.28
	chimeSound.PlaybackSpeed = 1.0
	chimeSound.TimePosition = 0
	chimeSound:Play()
	pendingChimeForServer = true
end

if IsOnValue.Value then
	wasOn = true
	task.spawn(function()
		local deadline = os.clock() + 0.6
		while not rig.chime.sound.IsLoaded and os.clock() < deadline do
			task.wait(0.05)
		end
		if script.Parent and IsOnValue.Value then
			triggerChimeOnce()
		end
	end)
end

local isOnChangedConn = IsOnValue.Changed:Connect(function(newOn: boolean)
	if newOn and not wasOn then
		triggerChimeOnce()
	elseif not newOn then
		rig.chime.sound:Stop()
	end
	wasOn = newOn
end)

local smoothedSpeed = 0
local lastStep = os.clock()
local heartbeatConn: RBXScriptConnection? = nil
heartbeatConn = RunService.Heartbeat:Connect(function()
	local now = os.clock()
	local dt = now - lastStep
	if dt < 1 / 60 then
		return
	end
	lastStep = now

	local rawSpeedKmh = VelocityValue.Value.Magnitude * toKMH
	smoothedSpeed += (rawSpeedKmh - smoothedSpeed) * math.min(1, dt * 14)

	local targets = EvSoundMix.computeTargets(
		smoothedSpeed,
		ThrottleValue.Value,
		BrakeValue.Value,
		GearValue.Value,
		IsOnValue.Value,
		1.0
	)
	EvSoundMix.applyTargets(rig, targets, dt)
end)

local feActive = true
if FE and remoteEvent and remoteEvent:IsA("UnreliableRemoteEvent") then
	task.spawn(function()
		while feActive and script.Parent and car.Parent do
			local packet = buffer.create(8)
			buffer.writef32(packet, 0, math.clamp(smoothedSpeed, 0, 1000))
			buffer.writeu8(packet, 4, math.clamp(math.round(ThrottleValue.Value * 255), 0, 255))
			buffer.writeu8(packet, 5, math.clamp(math.round(BrakeValue.Value * 255), 0, 255))
			buffer.writei8(packet, 6, math.clamp(GearValue.Value, -128, 127))
			local flags = (IsOnValue.Value and 1 or 0) + (pendingChimeForServer and 2 or 0)
			buffer.writeu8(packet, 7, flags)
			pendingChimeForServer = false

			remoteEvent:FireServer(packet)
			task.wait(FE_RATE)
		end
	end)
end

local cleanedUp = false
local seatRemovedConn: RBXScriptConnection? = nil
local function cleanup()
	if cleanedUp then
		return
	end
	cleanedUp = true
	feActive = false

	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end
	if isOnChangedConn then
		isOnChangedConn:Disconnect()
		isOnChangedConn = nil
	end
	if serverChildConn then
		serverChildConn:Disconnect()
		serverChildConn = nil
	end
	if seatRemovedConn then
		seatRemovedConn:Disconnect()
		seatRemovedConn = nil
	end

	EvSoundMix.destroyRig(rig)

	for _, s in ipairs(mutedServerSounds) do
		if s.Parent then
			s.SoundGroup = nil
		end
	end
	table.clear(mutedServerSounds)
	if muteGroup.Parent then
		muteGroup:Destroy()
	end
end

local driveSeat = car:FindFirstChild("DriveSeat")
if driveSeat then
	seatRemovedConn = driveSeat.ChildRemoved:Connect(function(child)
		if child:IsA("Weld") and child.Name == "SeatWeld" then
			cleanup()
			if script.Parent then
				script:Destroy()
			end
		end
	end)
end

script.Destroying:Connect(cleanup)
