--!strict
--[[
	DriverPoseController.luau
	Client-side procedural driver posture & steering hand controller for TeslaRoadster_Scon.
	Supports 4 switchable driving poses across R15 (AnimationConstraint & Motor6D) and R6 rigs.
]]

local RunService = game:GetService("RunService")

local DriverPoseController = {}
DriverPoseController.__index = DriverPoseController

export type PosePreset = {
	id: number,
	name: string,
	labelTh: string,
	waistPitchDeg: number,
	neckPitchDeg: number,
	lShoulder: { pitch: number, yaw: number, roll: number },
	lElbow: { pitch: number, yaw: number, roll: number },
	rShoulder: { pitch: number, yaw: number, roll: number },
	rElbow: { pitch: number, yaw: number, roll: number },
	hipPitchDeg: number,
	hipSpreadDeg: number,
	kneePitchDeg: number,
	anklePitchDeg: number,
	steerHandScale: number,
	steerLeftFactor: number,
	steerRightFactor: number,
}

export type DriverPoseControllerData = {
	car: Model,
	driveSeat: VehicleSeat,
	character: Model?,
	poseIndex: number,
	steerRatio: number,
	steerValueObj: NumberValue?,
	stepConn: RBXScriptConnection?,
	attrConn: RBXScriptConnection?,
	destroyed: boolean,
}

export type DriverPoseController = typeof(setmetatable({} :: DriverPoseControllerData, DriverPoseController))

DriverPoseController.Presets = {
	{
		id = 1,
		name = "Sport",
		labelTh = "Sport (จับพวงมาลัย)",
		waistPitchDeg = 6,
		neckPitchDeg = -6,
		lShoulder = { pitch = 30, yaw = -8, roll = 8 },
		lElbow = { pitch = 68, yaw = 0, roll = 0 },
		rShoulder = { pitch = 30, yaw = 8, roll = -8 },
		rElbow = { pitch = 68, yaw = 0, roll = 0 },
		hipPitchDeg = 80,
		hipSpreadDeg = 2,
		kneePitchDeg = -18,
		anklePitchDeg = 18,
		steerHandScale = 12,
		steerLeftFactor = 1,
		steerRightFactor = 1,
	},
	{
		id = 2,
		name = "Chill",
		labelTh = "Chill (ขับมือเดียว)",
		waistPitchDeg = 2,
		neckPitchDeg = -4,
		lShoulder = { pitch = 36, yaw = -8, roll = 8 },
		lElbow = { pitch = 64, yaw = 0, roll = 0 },
		rShoulder = { pitch = 12, yaw = 14, roll = -12 },
		rElbow = { pitch = 52, yaw = -8, roll = 14 },
		hipPitchDeg = 80,
		hipSpreadDeg = 3,
		kneePitchDeg = -12,
		anklePitchDeg = 18,
		steerHandScale = 14,
		steerLeftFactor = 1,
		steerRightFactor = 0,
	},
	{
		id = 3,
		name = "Lowrider",
		labelTh = "Lowrider (เอนซิ่ง)",
		waistPitchDeg = -6,
		neckPitchDeg = 4,
		lShoulder = { pitch = 44, yaw = -7, roll = 8 },
		lElbow = { pitch = 56, yaw = 0, roll = 0 },
		rShoulder = { pitch = 44, yaw = 7, roll = -8 },
		rElbow = { pitch = 56, yaw = 0, roll = 0 },
		hipPitchDeg = 82,
		hipSpreadDeg = 2,
		kneePitchDeg = -6,
		anklePitchDeg = 18,
		steerHandScale = 11,
		steerLeftFactor = 1,
		steerRightFactor = 1,
	},
	{
		id = 4,
		name = "Upright",
		labelTh = "Upright (นั่งตรงสตั๊นท์)",
		waistPitchDeg = 12,
		neckPitchDeg = -10,
		lShoulder = { pitch = 20, yaw = -7, roll = 8 },
		lElbow = { pitch = 76, yaw = 0, roll = 0 },
		rShoulder = { pitch = 20, yaw = 7, roll = -8 },
		rElbow = { pitch = 76, yaw = 0, roll = 0 },
		hipPitchDeg = 80,
		hipSpreadDeg = 2,
		kneePitchDeg = -22,
		anklePitchDeg = 18,
		steerHandScale = 12,
		steerLeftFactor = 1,
		steerRightFactor = 1,
	},
} :: { PosePreset }

local function findJoint(char: Model, jointNames: { string }): Instance?
	for _, name in ipairs(jointNames) do
		local found = char:FindFirstChild(name, true)
		if found and (found:IsA("AnimationConstraint") or found:IsA("Motor6D")) then
			return found
		end
	end
	return nil
end

local function setJointTransform(joint: Instance?, cf: CFrame)
	if not joint then
		return
	end
	if joint:IsA("AnimationConstraint") or joint:IsA("Motor6D") then
		(joint :: AnimationConstraint).Transform = cf
	end
end

local function degAngles(pitch: number, yaw: number, roll: number): CFrame
	return CFrame.Angles(math.rad(pitch), math.rad(yaw), math.rad(roll))
end

local function degAnglesYXZ(pitch: number, yaw: number, roll: number): CFrame
	return CFrame.fromEulerAnglesYXZ(math.rad(pitch), math.rad(yaw), math.rad(roll))
end

local function readSteerValue(seat: VehicleSeat, cachedVal: NumberValue?): (number, NumberValue?)
	local valObj = cachedVal
	if not valObj or not valObj.Parent then
		local lp = game:GetService("Players").LocalPlayer
		local playerGui = lp and lp:FindFirstChildOfClass("PlayerGui")
		local iface = playerGui and playerGui:FindFirstChild("A-Chassis Interface")
		local values = iface and iface:FindFirstChild("Values")
		local s = values and values:FindFirstChild("SteerC")
		if s and s:IsA("NumberValue") then
			valObj = s
		end
	end
	if valObj and valObj.Parent then
		return math.clamp(valObj.Value, -1, 1), valObj
	end
	return math.clamp(seat.SteerFloat, -1, 1), valObj
end

function DriverPoseController.new(car: Model, driveSeat: VehicleSeat): DriverPoseController
	local initialPose = tonumber(car:GetAttribute("SconDriverPose")) or 3
	initialPose = math.clamp(math.floor(initialPose + 0.5), 1, #DriverPoseController.Presets)

	local hum = driveSeat.Occupant
	local char = if hum and hum.Parent and hum.Parent:IsA("Model") then hum.Parent else nil

	local data: DriverPoseControllerData = {
		car = car,
		driveSeat = driveSeat,
		character = char,
		poseIndex = initialPose,
		steerRatio = 0,
		steerValueObj = nil,
		stepConn = nil,
		attrConn = nil,
		destroyed = false,
	}

	local self = setmetatable(data, DriverPoseController) :: DriverPoseController

	self.attrConn = car:GetAttributeChangedSignal("SconDriverPose"):Connect(function()
		local idx = tonumber(car:GetAttribute("SconDriverPose")) or 1
		self.poseIndex = math.clamp(math.floor(idx + 0.5), 1, #DriverPoseController.Presets)
	end)

	self.stepConn = RunService.Stepped:Connect(function(_, dt: number)
		self:_step(dt)
	end)

	return self
end

function DriverPoseController.GetPreset(self: DriverPoseController): PosePreset
	return DriverPoseController.Presets[self.poseIndex] or DriverPoseController.Presets[1]
end

function DriverPoseController._step(self: DriverPoseController, dt: number)
	if self.destroyed or not self.car.Parent or not self.driveSeat.Parent then
		return
	end

	local hum = self.driveSeat.Occupant
	local char = if hum and hum.Parent and hum.Parent:IsA("Model") then hum.Parent else nil
	self.character = char
	if not char then
		return
	end

	local rawSteer, foundVal = readSteerValue(self.driveSeat, self.steerValueObj)
	self.steerValueObj = foundVal
	local blend = 1 - math.exp(-12 * math.clamp(dt, 1 / 240, 0.1))
	self.steerRatio += (rawSteer - self.steerRatio) * blend

	local preset = self:GetPreset()
	local isR6 = char:FindFirstChild("Torso") ~= nil and char:FindFirstChild("UpperTorso") == nil

	if isR6 then
		local lSh = findJoint(char, { "Left Shoulder" })
		local rSh = findJoint(char, { "Right Shoulder" })
		local lHip = findJoint(char, { "Left Hip" })
		local rHip = findJoint(char, { "Right Hip" })
		local neck = findJoint(char, { "Neck" })
		if lSh then
			local lExtra = self.steerRatio * preset.steerHandScale * preset.steerLeftFactor
			setJointTransform(lSh, degAngles(0, 0, -24 + lExtra))
		end
		if rSh then
			local rExtra = -self.steerRatio * preset.steerHandScale * preset.steerRightFactor
			setJointTransform(rSh, degAngles(0, 0, (preset.id == 2 and -20 or 24) + rExtra))
		end
		if lHip then
			setJointTransform(lHip, degAngles(0, 0, -preset.hipPitchDeg))
		end
		if rHip then
			setJointTransform(rHip, degAngles(0, 0, preset.hipPitchDeg))
		end
		if neck then
			setJointTransform(neck, degAngles(preset.neckPitchDeg, -self.steerRatio * 8, 0))
		end
		return
	end

	-- R15 (supports both AnimationConstraint and Motor6D)
	local waist = findJoint(char, { "Waist" })
	local neck = findJoint(char, { "Neck" })
	local lShoulder = findJoint(char, { "LeftShoulder" })
	local lElbow = findJoint(char, { "LeftElbow" })
	local rShoulder = findJoint(char, { "RightShoulder" })
	local rElbow = findJoint(char, { "RightElbow" })
	local lHip = findJoint(char, { "LeftHip" })
	local lKnee = findJoint(char, { "LeftKnee" })
	local lAnkle = findJoint(char, { "LeftAnkle" })
	local rHip = findJoint(char, { "RightHip" })
	local rKnee = findJoint(char, { "RightKnee" })
	local rAnkle = findJoint(char, { "RightAnkle" })

	local lPitchDelta = -self.steerRatio * preset.steerHandScale * preset.steerLeftFactor
	local rPitchDelta = self.steerRatio * preset.steerHandScale * preset.steerRightFactor

	setJointTransform(waist, degAngles(preset.waistPitchDeg, -self.steerRatio * 5, -self.steerRatio * 4))
	setJointTransform(neck, degAngles(preset.neckPitchDeg, -self.steerRatio * 10, 0))
	setJointTransform(
		lShoulder,
		degAnglesYXZ(preset.lShoulder.pitch + lPitchDelta, preset.lShoulder.yaw, preset.lShoulder.roll)
	)
	setJointTransform(lElbow, degAngles(preset.lElbow.pitch, preset.lElbow.yaw, preset.lElbow.roll))
	setJointTransform(
		rShoulder,
		degAnglesYXZ(preset.rShoulder.pitch + rPitchDelta, preset.rShoulder.yaw, preset.rShoulder.roll)
	)
	setJointTransform(rElbow, degAngles(preset.rElbow.pitch, preset.rElbow.yaw, preset.rElbow.roll))
	setJointTransform(lHip, degAnglesYXZ(preset.hipPitchDeg, preset.hipSpreadDeg, -preset.hipSpreadDeg))
	setJointTransform(lKnee, degAngles(preset.kneePitchDeg, 0, 0))
	setJointTransform(lAnkle, degAngles(preset.anklePitchDeg, 0, 0))
	setJointTransform(rHip, degAnglesYXZ(preset.hipPitchDeg, -preset.hipSpreadDeg, preset.hipSpreadDeg))
	setJointTransform(rKnee, degAngles(preset.kneePitchDeg, 0, 0))
	setJointTransform(rAnkle, degAngles(preset.anklePitchDeg, 0, 0))
end

function DriverPoseController.Destroy(self: DriverPoseController)
	if self.destroyed then
		return
	end
	self.destroyed = true
	if self.stepConn then
		self.stepConn:Disconnect()
		self.stepConn = nil
	end
	if self.attrConn then
		self.attrConn:Disconnect()
		self.attrConn = nil
	end
	local char = self.character
	if char and char.Parent then
		for _, jName in ipairs({
			"Waist",
			"Neck",
			"LeftShoulder",
			"LeftElbow",
			"RightShoulder",
			"RightElbow",
			"LeftHip",
			"LeftKnee",
			"LeftAnkle",
			"RightHip",
			"RightKnee",
			"RightAnkle",
			"Left Shoulder",
			"Right Shoulder",
			"Left Hip",
			"Right Hip",
		}) do
			setJointTransform(findJoint(char, { jName }), CFrame.identity)
		end
	end
end

return DriverPoseController
