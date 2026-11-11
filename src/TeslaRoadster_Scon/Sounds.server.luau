--!strict
--[[
	TeslaRoadster_Scon Electric Vehicle Server Spatial Audio Relay
	Receives compact EV state telemetry over car.Sounds (UnreliableRemoteEvent)
	and plays smooth 3D spatial EV audio on Body.Sounds.Engine for nearby players.
]]

local Players = game:GetService("Players")

local event = script.Parent
if not event or not event:IsA("UnreliableRemoteEvent") then
	return
end

local car = event.Parent
if not car or not car:IsA("Model") then
	return
end

local tuneFolder = car:WaitForChild("Hoki-Chassis Tune", 10)
if not tuneFolder then
	return
end
local EvSoundMix = require(tuneFolder:WaitForChild("EvSoundMix", 10))

local body = car:WaitForChild("Body", 10)
local driveSeat = car:WaitForChild("DriveSeat", 10) :: VehicleSeat?
if not body or not driveSeat then
	return
end

local soundsDir = body:FindFirstChild("Sounds")
local mountPart = (soundsDir and soundsDir:FindFirstChild("Engine")) or body:FindFirstChild("#Weight")
if not mountPart then
	return
end

-- Purge any legacy combustion or wind sounds so only clean EV channels remain
EvSoundMix.cleanupLegacySounds(soundsDir, false)
EvSoundMix.cleanupLegacySounds(body:FindFirstChild("#Weight"), false)

local rig = EvSoundMix.ensureRig(mountPart, "")
local canUpdate = false
local lastUpdateClock = os.clock()
local lastChimeClock = 0

local function playServerChime()
	local now = os.clock()
	if now - lastChimeClock < 1.2 then
		return
	end
	lastChimeClock = now
	rig.chime.sound.Volume = 0.20
	rig.chime.sound.PlaybackSpeed = 1.0
	rig.chime.sound.TimePosition = 0
	rig.chime.sound:Play()
end

event.OnServerEvent:Connect(function(player: Player, packet: any)
	if not canUpdate or typeof(packet) ~= "buffer" or buffer.len(packet) < 8 then
		return
	end

	-- Validate sender is actually seated in DriveSeat
	local occupantHum = driveSeat.Occupant
	if not occupantHum then
		return
	end
	local driverPlayer = Players:GetPlayerFromCharacter(occupantHum.Parent)
	if driverPlayer ~= player then
		return
	end

	local now = os.clock()
	local dt = now - lastUpdateClock
	lastUpdateClock = now

	local speedKmh = buffer.readf32(packet, 0)
	local throttle = buffer.readu8(packet, 4) / 255
	local brake = buffer.readu8(packet, 5) / 255
	local gear = buffer.readi8(packet, 6)
	local flags = buffer.readu8(packet, 7)

	local isOn = bit32.band(flags, 1) ~= 0
	local chimeReq = bit32.band(flags, 2) ~= 0

	if chimeReq then
		playServerChime()
	end

	local targets = EvSoundMix.computeTargets(speedKmh, throttle, brake, gear, isOn, 0.78)
	EvSoundMix.applyTargets(rig, targets, dt)
end)

driveSeat.ChildAdded:Connect(function(child: Instance)
	if child:IsA("Weld") and child.Name == "SeatWeld" then
		canUpdate = true
		lastUpdateClock = os.clock()
	end
end)

driveSeat.ChildRemoved:Connect(function(child: Instance)
	if child:IsA("Weld") and child.Name == "SeatWeld" then
		canUpdate = false
		EvSoundMix.stopAll(rig)
	end
end)
