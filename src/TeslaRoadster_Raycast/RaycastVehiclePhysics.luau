--!strict
--[=[
	RaycastVehiclePhysics.luau
	Client-side custom raycast chassis solver for the Tesla Roadster.

	Require this ModuleScript from a LocalScript after the vehicle is in Workspace:
	local controller = RaycastVehiclePhysics.Initialize(carModel)
	controller:Start()
	
	The driver must own the vehicle assembly's network ownership. Cosmetic wheel and
	caliper parts must be separate visual assemblies, not welded to the chassis or each other.
]=]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LOCAL_PLAYER = Players.LocalPlayer :: Player
local WORLD_DOWN = -Vector3.yAxis
local WHEEL_RADIUS = 1.15
local SPHERECAST_RADIUS = 0.28
local MAX_FRAME_DT = 1 / 20

local DEFAULTS = {
	HalfTrack = 2.755,
	FrontZ = -4.662,
	RearZ = 5.008,
	WheelCenterY = -0.851,
	WheelRadius = WHEEL_RADIUS,
	RestLength = 2.4,
	SpringTravel = 0.9,
	SpringStiffness = 32000,
	Damper = 2800,
	AntiRollStiffness = 8000,
	LandingDamperMultiplier = 2.5,
	LandingDamperDuration = 0.2,
	TopSpeed = 175,
	ReverseSpeed = 42,
	DriveAcceleration = 85,
	BrakeAcceleration = 150,
	LateralGrip = 1.25,
	DriftGripMultiplier = 0.3,
	MaximumSteerAngle = math.rad(30),
	CurbHeight = 2.1,
	CurbAssistForce = 1.25,
	AirPitchRate = 1.4,
	AirRollRate = 1.2,
}

export type ConfigOverrides = {
	HalfTrack: number?,
	FrontZ: number?,
	RearZ: number?,
	WheelCenterY: number?,
	WheelRadius: number?,
	RestLength: number?,
	SpringTravel: number?,
	SpringStiffness: number?,
	Damper: number?,
	AntiRollStiffness: number?,
	LandingDamperMultiplier: number?,
	LandingDamperDuration: number?,
	TopSpeed: number?,
	ReverseSpeed: number?,
	DriveAcceleration: number?,
	BrakeAcceleration: number?,
	LateralGrip: number?,
	DriftGripMultiplier: number?,
	MaximumSteerAngle: number?,
	CurbHeight: number?,
	CurbAssistForce: number?,
	AirPitchRate: number?,
	AirRollRate: number?,
}

type Config = {
	HalfTrack: number,
	FrontZ: number,
	RearZ: number,
	WheelCenterY: number,
	WheelRadius: number,
	RestLength: number,
	SpringTravel: number,
	SpringStiffness: number,
	Damper: number,
	AntiRollStiffness: number,
	LandingDamperMultiplier: number,
	LandingDamperDuration: number,
	TopSpeed: number,
	ReverseSpeed: number,
	DriveAcceleration: number,
	BrakeAcceleration: number,
	LateralGrip: number,
	DriftGripMultiplier: number,
	MaximumSteerAngle: number,
	CurbHeight: number,
	CurbAssistForce: number,
	AirPitchRate: number,
	AirRollRate: number,
}

type WheelState = {
	front: boolean,
	probeOffset: Vector3,
	forceAttachment: Attachment,
	forceConstraint: VectorForce,
	wheel: BasePart,
	caliper: BasePart,
	wheelLocalCFrame: CFrame,
	caliperLocalCFrame: CFrame,
	compression: number,
	previousCompression: number,
	suspensionOffset: number,
	normalLoad: number,
	grounded: boolean,
}

export type Controller = {
	Start: (self: Controller) -> (),
	Stop: (self: Controller) -> (),
	Destroy: (self: Controller) -> (),
}

type ModuleApi = {
	Initialize: (car: Model, overrides: ConfigOverrides?) -> Controller,
}

type ControllerData = Controller & {
	car: Model,
	root: BasePart,
	seat: VehicleSeat,
	wheels: { WheelState },
	config: Config,
	rayParams: RaycastParams,
	curbParams: RaycastParams,
	curbAttachment: Attachment,
	curbForce: VectorForce,
	airAttachment: Attachment,
	airControl: AngularVelocity,
	connections: { RBXScriptConnection },
	actionName: string,
	isRunning: boolean,
	isDestroyed: boolean,
	isLocalDriver: boolean,
	isHandbraking: boolean,
	wasAirborne: boolean,
	landingDamperUntil: number,
	wheelSpinAngle: number,
	steerAngle: number,
}

local Module: any = {}
Module.__index = Module

local WHEEL_NAMES = { "FL", "FR", "RL", "RR" }
local CALIPER_NAMES = { "Caliper_FL", "Caliper_FR", "Caliper_RL", "Caliper_RR" }

local function findBasePart(root: Instance, name: string): BasePart
	local instance = root:FindFirstChild(name, true)
	assert(instance and instance:IsA("BasePart"), string.format("Missing BasePart '%s' under %s", name, root:GetFullName()))
	return instance
end

local function findWheelPart(root: Instance, shortName: string): BasePart
	local wheel = root:FindFirstChild(shortName, true)
	if not wheel then
		wheel = root:FindFirstChild("Wheel_" .. shortName, true)
	end
	assert(wheel and wheel:IsA("BasePart"), string.format("Missing wheel '%s' under %s", shortName, root:GetFullName()))
	return wheel
end

local function copyConfig(overrides: ConfigOverrides?): Config
	local config: Config = table.clone(DEFAULTS) :: Config
	if overrides then
		if overrides.HalfTrack ~= nil then config.HalfTrack = overrides.HalfTrack end
		if overrides.FrontZ ~= nil then config.FrontZ = overrides.FrontZ end
		if overrides.RearZ ~= nil then config.RearZ = overrides.RearZ end
		if overrides.WheelCenterY ~= nil then config.WheelCenterY = overrides.WheelCenterY end
		if overrides.WheelRadius ~= nil then config.WheelRadius = overrides.WheelRadius end
		if overrides.RestLength ~= nil then config.RestLength = overrides.RestLength end
		if overrides.SpringTravel ~= nil then config.SpringTravel = overrides.SpringTravel end
		if overrides.SpringStiffness ~= nil then config.SpringStiffness = overrides.SpringStiffness end
		if overrides.Damper ~= nil then config.Damper = overrides.Damper end
		if overrides.AntiRollStiffness ~= nil then config.AntiRollStiffness = overrides.AntiRollStiffness end
		if overrides.LandingDamperMultiplier ~= nil then config.LandingDamperMultiplier = overrides.LandingDamperMultiplier end
		if overrides.LandingDamperDuration ~= nil then config.LandingDamperDuration = overrides.LandingDamperDuration end
		if overrides.TopSpeed ~= nil then config.TopSpeed = overrides.TopSpeed end
		if overrides.ReverseSpeed ~= nil then config.ReverseSpeed = overrides.ReverseSpeed end
		if overrides.DriveAcceleration ~= nil then config.DriveAcceleration = overrides.DriveAcceleration end
		if overrides.BrakeAcceleration ~= nil then config.BrakeAcceleration = overrides.BrakeAcceleration end
		if overrides.LateralGrip ~= nil then config.LateralGrip = overrides.LateralGrip end
		if overrides.DriftGripMultiplier ~= nil then config.DriftGripMultiplier = overrides.DriftGripMultiplier end
		if overrides.MaximumSteerAngle ~= nil then config.MaximumSteerAngle = overrides.MaximumSteerAngle end
		if overrides.CurbHeight ~= nil then config.CurbHeight = overrides.CurbHeight end
		if overrides.CurbAssistForce ~= nil then config.CurbAssistForce = overrides.CurbAssistForce end
		if overrides.AirPitchRate ~= nil then config.AirPitchRate = overrides.AirPitchRate end
		if overrides.AirRollRate ~= nil then config.AirRollRate = overrides.AirRollRate end
	end
	assert(config.WheelRadius > 0, "WheelRadius must be positive")
	assert(config.RestLength > 0 and config.SpringTravel > 0, "Suspension lengths must be positive")
	assert(config.TopSpeed > 0 and config.CurbHeight > 0, "Vehicle limits must be positive")
	assert(config.SpringStiffness >= 0 and config.Damper >= 0 and config.AntiRollStiffness >= 0, "Suspension rates cannot be negative")
	assert(config.LateralGrip > 0 and config.DriftGripMultiplier >= 0, "Tire grip settings are invalid")
	assert(config.DriveAcceleration >= 0 and config.BrakeAcceleration >= 0, "Acceleration settings cannot be negative")
	assert(config.HalfTrack > 0 and config.LandingDamperMultiplier >= 1, "Vehicle geometry or landing damper settings are invalid")
	assert(config.DriftGripMultiplier <= 1 and config.LandingDamperDuration >= 0, "Drift grip or landing duration is invalid")
	return config
end

local function createAttachment(parent: BasePart, name: string, position: Vector3): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.Position = position
	attachment.Parent = parent
	return attachment
end

local function createVectorForce(parent: BasePart, attachment: Attachment, name: string): VectorForce
	local force = Instance.new("VectorForce")
	force.Name = name
	force.Attachment0 = attachment
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.ApplyAtCenterOfMass = false
	force.Parent = parent
	return force
end

function Module.Initialize(car: Model, overrides: ConfigOverrides?): Controller
	assert(RunService:IsClient(), "RaycastVehiclePhysics must be initialized by a LocalScript")
	assert(car:IsA("Model"), "Initialize expects a vehicle Model")

	local root = findBasePart(car, "Chassis_Collider")
	local seatPart = findBasePart(car, "DriveSeat")
	assert(seatPart:IsA("VehicleSeat"), "DriveSeat must be a VehicleSeat")
	local seat = seatPart :: VehicleSeat
	assert(not root.Anchored, "Chassis_Collider must be unanchored")
	local config = copyConfig(overrides)
	local wheelsFolder = car:FindFirstChild("Wheels") or car
	local rootCFrame = root.CFrame

	root.CanCollide = true
	root.Massless = false
	seat.CanCollide = false

	local controller = setmetatable({
		car = car,
		root = root,
		seat = seat,
		config = config,
		wheels = {},
		connections = {},
		rayParams = RaycastParams.new(),
		curbParams = RaycastParams.new(),
		isRunning = false,
		isDestroyed = false,
		isLocalDriver = false,
		isHandbraking = false,
		wasAirborne = false,
		landingDamperUntil = 0,
		wheelSpinAngle = 0,
		steerAngle = 0,
		actionName = "HokiRoadsterHandbrake_" .. car.Name .. "_" .. tostring(car),
	}, Module) :: ControllerData

	controller.rayParams.FilterType = Enum.RaycastFilterType.Exclude
	controller.rayParams.FilterDescendantsInstances = { car }
	controller.rayParams.IgnoreWater = true
	controller.rayParams.RespectCanCollide = true
	controller.curbParams.FilterType = Enum.RaycastFilterType.Exclude
	controller.curbParams.FilterDescendantsInstances = { car }
	controller.curbParams.IgnoreWater = true
	controller.curbParams.RespectCanCollide = true

	for index, name in ipairs(WHEEL_NAMES) do
		local front = index <= 2
		local left = index == 1 or index == 3
		local localOffset = Vector3.new(
			left and -config.HalfTrack or config.HalfTrack,
			0,
			front and config.FrontZ or config.RearZ
		)
		local wheel = findWheelPart(wheelsFolder, name)
		local caliper = findBasePart(car, CALIPER_NAMES[index])
		local chassisAssemblyRoot = root.AssemblyRootPart
		assert(wheel.AssemblyRootPart ~= chassisAssemblyRoot, wheel.Name .. " must not be welded to the chassis")
		assert(caliper.AssemblyRootPart ~= chassisAssemblyRoot, caliper.Name .. " must not be welded to the chassis")
		assert(wheel.AssemblyRootPart ~= caliper.AssemblyRootPart, name .. " wheel and caliper must be separate assemblies")
		wheel.Anchored = true
		wheel.CanCollide = false
		wheel.Massless = true
		caliper.Anchored = true
		caliper.CanCollide = false
		caliper.Massless = true

		local wheelCenter = Vector3.new(localOffset.X, config.WheelCenterY, localOffset.Z)
		local probeOffset = Vector3.new(localOffset.X, config.WheelCenterY + config.RestLength, localOffset.Z)
		local attachment = createAttachment(root, "RaycastSuspension_" .. name, wheelCenter)
		local force = createVectorForce(root, attachment, "RaycastTireForce_" .. name)
		table.insert(controller.wheels, {
			front = front,
			probeOffset = probeOffset,
			forceAttachment = attachment,
			forceConstraint = force,
			wheel = wheel,
			caliper = caliper,
			wheelLocalCFrame = CFrame.new(wheelCenter) * rootCFrame:ToObjectSpace(wheel.CFrame).Rotation,
			caliperLocalCFrame = rootCFrame:ToObjectSpace(caliper.CFrame),
			compression = 0,
			previousCompression = 0,
			suspensionOffset = 0,
			normalLoad = 0,
			grounded = false,
		})
	end

	controller.curbAttachment = createAttachment(root, "CurbAssist_ForceAttachment", Vector3.new(0, -0.15, config.FrontZ - 0.65))
	controller.curbForce = createVectorForce(root, controller.curbAttachment, "CurbAssist_Force")
	controller.airAttachment = createAttachment(root, "AirControl_Attachment", Vector3.zero)
	controller.airControl = Instance.new("AngularVelocity")
	controller.airControl.Name = "AirControl_AngularVelocity"
	controller.airControl.Attachment0 = controller.airAttachment
	controller.airControl.RelativeTo = Enum.ActuatorRelativeTo.World
	controller.airControl.MaxTorque = root.AssemblyMass * 1800
	controller.airControl.MaxAngularVelocity = 3
	controller.airControl.AngularVelocity = Vector3.zero
	controller.airControl.Enabled = false
	controller.airControl.Parent = root

	return controller
end

local function isCurrentLocalDriver(self: ControllerData): boolean
	local occupant = self.seat.Occupant
	return occupant ~= nil and occupant.Parent == LOCAL_PLAYER.Character
end

local function bindHandbrake(self: ControllerData)
	ContextActionService:BindAction(self.actionName, function(_actionName: string, inputState: Enum.UserInputState): Enum.ContextActionResult
		if inputState == Enum.UserInputState.Begin then
			self.isHandbraking = true
		elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			self.isHandbraking = false
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.Space, Enum.KeyCode.ButtonB)
	ContextActionService:SetTitle(self.actionName, "Drift")
	ContextActionService:SetPosition(self.actionName, UDim2.new(0.83, 0, 0.72, 0))
end

local function updateDriver(self: ControllerData)
	local isDriver = isCurrentLocalDriver(self)
	if isDriver == self.isLocalDriver then
		return
	end

	self.isLocalDriver = isDriver
	self.isHandbraking = false
	if isDriver then
		local character = LOCAL_PLAYER.Character
		local filterInstances = { self.car }
		if character then
			table.insert(filterInstances, character)
		end
		self.rayParams.FilterDescendantsInstances = filterInstances
		self.curbParams.FilterDescendantsInstances = filterInstances
		bindHandbrake(self)
	else
		self.rayParams.FilterDescendantsInstances = { self.car }
		self.curbParams.FilterDescendantsInstances = { self.car }
		ContextActionService:UnbindAction(self.actionName)
	end
end

local function probeWheels(self: ControllerData, dt: number, now: number): (number, number, number)
	local root = self.root
	local config = self.config
	local rootCFrame = root.CFrame
	local castLength = config.RestLength + config.SpringTravel + config.WheelRadius + SPHERECAST_RADIUS
	local groundCount = 0
	local rearGroundY = 0
	local rearCount = 0
	local springMultiplier = now < self.landingDamperUntil and config.LandingDamperMultiplier or 1
	local damper = config.Damper * springMultiplier

	for _, wheel in ipairs(self.wheels) do
		local origin = rootCFrame:PointToWorldSpace(wheel.probeOffset)
		local hit = Workspace:Spherecast(origin, SPHERECAST_RADIUS, WORLD_DOWN * castLength, self.rayParams)
		local wasGrounded = wheel.grounded
		wheel.grounded = hit ~= nil
		wheel.normalLoad = 0
		if hit then
			groundCount += 1
			if not wheel.front then
				rearGroundY += hit.Position.Y
				rearCount += 1
			end

			local suspensionDistance = hit.Distance + SPHERECAST_RADIUS - config.WheelRadius
			local compression = math.clamp(
				config.RestLength - suspensionDistance,
				-config.SpringTravel,
				config.SpringTravel
			)
			-- Positive compression velocity means the suspension is extending; this
			-- sign convention makes F = k*x - c*v resist both compression and rebound.
			local compressionVelocity = if wasGrounded
				then (wheel.previousCompression - compression) / math.max(dt, 1 / 240)
				else root.AssemblyLinearVelocity.Y
			compressionVelocity = math.clamp(compressionVelocity, -20, 20)
			local force = config.SpringStiffness * math.max(compression, 0) - damper * compressionVelocity
			wheel.compression = compression
			wheel.previousCompression = compression
			wheel.suspensionOffset = compression
			wheel.normalLoad = math.max(0, force)
		else
			wheel.compression = -config.SpringTravel
			wheel.previousCompression = -config.SpringTravel
			wheel.suspensionOffset = -config.SpringTravel
			wheel.forceConstraint.Force = Vector3.zero
		end
	end

	-- Anti-roll force transfers load between wheels on each axle without pulling
	-- either tire below zero normal force.
	local frontLeft = self.wheels[1]
	local frontRight = self.wheels[2]
	local rearLeft = self.wheels[3]
	local rearRight = self.wheels[4]
	local frontArb = (frontLeft.compression - frontRight.compression) * config.AntiRollStiffness
	local rearArb = (rearLeft.compression - rearRight.compression) * config.AntiRollStiffness
	frontLeft.normalLoad = if frontLeft.grounded then math.max(0, frontLeft.normalLoad + frontArb) else 0
	frontRight.normalLoad = if frontRight.grounded then math.max(0, frontRight.normalLoad - frontArb) else 0
	rearLeft.normalLoad = if rearLeft.grounded then math.max(0, rearLeft.normalLoad + rearArb) else 0
	rearRight.normalLoad = if rearRight.grounded then math.max(0, rearRight.normalLoad - rearArb) else 0

	local airborne = groundCount == 0
	if airborne then
		self.curbForce.Force = Vector3.zero
		self.airControl.Enabled = self.isLocalDriver
	else
		if self.wasAirborne then
			self.landingDamperUntil = now + config.LandingDamperDuration
		end
		self.airControl.Enabled = false
	end
	self.wasAirborne = airborne

	return groundCount, rearGroundY, rearCount
end

local function curbAssist(self: ControllerData, rearGroundY: number, rearCount: number): ()
	if rearCount == 0 or not self.isLocalDriver then
		self.curbForce.Force = Vector3.zero
		return
	end

	local root = self.root
	local forward = root.CFrame.LookVector
	local direction = (forward + WORLD_DOWN).Unit * 4.3
	local origin = root.CFrame:PointToWorldSpace(Vector3.new(0, -0.15, self.config.FrontZ - 0.65))
	local hit = Workspace:Spherecast(origin, SPHERECAST_RADIUS, direction, self.curbParams)
	if not hit or hit.Normal.Y > 0.65 then
		self.curbForce.Force = Vector3.zero
		return
	end

	local roadY = rearGroundY / rearCount
	local obstacleHeight = hit.Position.Y - roadY
	if obstacleHeight <= 0.04 or obstacleHeight > self.config.CurbHeight or hit.Distance > 3.8 then
		self.curbForce.Force = Vector3.zero
		return
	end

	local heightRatio = math.clamp(1 - obstacleHeight / self.config.CurbHeight, 0.25, 1)
	local lift = root.AssemblyMass * Workspace.Gravity * self.config.CurbAssistForce * heightRatio
	self.curbForce.Force = Vector3.yAxis * lift
end

local function updateAirControl(self: ControllerData, throttle: number, steer: number): ()
	if not self.airControl.Enabled then
		self.airControl.AngularVelocity = Vector3.zero
		return
	end

	local frame = self.root.CFrame
	local pitch = -throttle * self.config.AirPitchRate
	local roll = steer * self.config.AirRollRate
	self.airControl.MaxTorque = self.root.AssemblyMass * 1800
	self.airControl.AngularVelocity = frame.RightVector * pitch + frame.LookVector * roll
end

local function updateForces(self: ControllerData, dt: number)
	if not self.isLocalDriver then
		for _, wheel in ipairs(self.wheels) do
			wheel.forceConstraint.Force = Vector3.zero
		end
		self.curbForce.Force = Vector3.zero
		self.airControl.Enabled = false
		return
	end

	local seat = self.seat
	local config = self.config
	local throttle = math.clamp(seat.ThrottleFloat, -1, 1)
	local steer = math.clamp(seat.SteerFloat, -1, 1)
	local velocity = self.root.AssemblyLinearVelocity
	local forward = self.root.CFrame.LookVector
	local longitudinalSpeed = velocity:Dot(forward)
	local handbraking = self.isHandbraking
	local grounded = 0
	local _, rearGroundY, rearCount = probeWheels(self, dt, os.clock())
	for _, wheel in ipairs(self.wheels) do
		if wheel.grounded then
			grounded += 1
		end
	end
	curbAssist(self, rearGroundY, rearCount)

	self.steerAngle += ((-steer * config.MaximumSteerAngle) - self.steerAngle) * math.min(1, dt * 12)
	updateAirControl(self, throttle, steer)
	if grounded == 0 then
		for _, wheel in ipairs(self.wheels) do
			wheel.forceConstraint.Force = Vector3.zero
		end
		return
	end

	local mass = self.root.AssemblyMass
	local motorForce = throttle * mass * config.DriveAcceleration
	if throttle < 0 and longitudinalSpeed > 2 then
		motorForce = -mass * config.BrakeAcceleration * -throttle
	elseif throttle > 0 and longitudinalSpeed < -2 then
		motorForce = mass * config.BrakeAcceleration * throttle
	end

	if longitudinalSpeed > config.TopSpeed then
		motorForce = -mass * math.min(config.BrakeAcceleration, (longitudinalSpeed - config.TopSpeed) * 8)
	elseif longitudinalSpeed < -config.ReverseSpeed then
		motorForce = mass * math.min(config.BrakeAcceleration, (-config.ReverseSpeed - longitudinalSpeed) * 8)
	end
	local speedFade = math.clamp((config.TopSpeed - math.max(longitudinalSpeed, 0)) / math.max(config.TopSpeed * 0.08, 1), 0, 1)
	if motorForce > 0 then
		motorForce *= speedFade
	end

	local tireForward = forward
	local tireRight = self.root.CFrame.RightVector
	local steeringRotation = CFrame.fromAxisAngle(Vector3.yAxis, self.steerAngle)
	local rearGripMultiplier = handbraking and config.DriftGripMultiplier or 1
	local enginePerWheel = motorForce * 0.25
	for _, wheel in ipairs(self.wheels) do
		local suspensionForce = Vector3.yAxis * wheel.normalLoad
		local tireForce = Vector3.zero
		if wheel.grounded then
			local steeredForward = if wheel.front then steeringRotation:VectorToWorldSpace(tireForward) else tireForward
			local steeredRight = if wheel.front then steeringRotation:VectorToWorldSpace(tireRight) else tireRight
			local pointVelocity = self.root:GetVelocityAtPosition(wheel.forceAttachment.WorldPosition)
			local lateralSpeed = pointVelocity:Dot(steeredRight)
			local wheelLongitudinalSpeed = pointVelocity:Dot(steeredForward)
			local slipAngle = math.atan2(lateralSpeed, math.max(math.abs(wheelLongitudinalSpeed), 3))
			local lateralCurve = math.sin(math.clamp(slipAngle / 0.72, -1, 1) * math.pi * 0.5)
			local gripScale = if handbraking and not wheel.front then rearGripMultiplier else 1
			local maximumTireForce = wheel.normalLoad * config.LateralGrip
			local longitudinalForce = math.clamp(enginePerWheel, -maximumTireForce, maximumTireForce)
			if handbraking and not wheel.front then
				longitudinalForce = -math.sign(wheelLongitudinalSpeed) * maximumTireForce * 1.5
			end
			local lateralCapacity = math.sqrt(math.max(0, maximumTireForce * maximumTireForce - math.min(math.abs(longitudinalForce), maximumTireForce) ^ 2))
			local lateralForce = -lateralCurve * lateralCapacity * gripScale
			tireForce = steeredRight * lateralForce + steeredForward * longitudinalForce
		end
		wheel.forceConstraint.Force = suspensionForce + tireForce
	end
end

local function updateVisuals(self: ControllerData, dt: number)
	local rootCFrame = self.root.CFrame
	local forwardSpeed = self.root.AssemblyLinearVelocity:Dot(rootCFrame.LookVector)
	self.wheelSpinAngle += forwardSpeed * dt / self.config.WheelRadius
	local steerRotation = CFrame.Angles(0, self.steerAngle, 0)
	local spinRotation = CFrame.Angles(self.wheelSpinAngle, 0, 0)

	for _, wheel in ipairs(self.wheels) do
		local offset = Vector3.new(0, wheel.suspensionOffset, 0)
		local wheelPose = rootCFrame
			* CFrame.new(wheel.wheelLocalCFrame.Position + offset)
			* (wheel.front and steerRotation or CFrame.identity)
			* wheel.wheelLocalCFrame.Rotation
			* spinRotation
		local caliperPose = rootCFrame
			* CFrame.new(wheel.caliperLocalCFrame.Position + offset)
			* (wheel.front and steerRotation or CFrame.identity)
			* wheel.caliperLocalCFrame.Rotation
		wheel.wheel.CFrame = wheelPose
		wheel.caliper.CFrame = caliperPose
	end
end

function Module.Start(self: ControllerData)
	assert(not self.isDestroyed, "Cannot start a destroyed vehicle controller")
	if self.isRunning then
		return
	end
	self.isRunning = true
	self.isLocalDriver = false
	updateDriver(self)
	table.insert(self.connections, self.seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		updateDriver(self)
	end))
	table.insert(self.connections, self.car.Destroying:Connect(function()
		self:Destroy()
	end))
	table.insert(self.connections, RunService.PreSimulation:Connect(function(dt: number)
		if self.isDestroyed or not self.car:IsDescendantOf(Workspace) then
			return
		end
		updateDriver(self)
		updateForces(self, math.clamp(dt, 1 / 240, MAX_FRAME_DT))
	end))
	table.insert(self.connections, RunService.PreRender:Connect(function(dt: number)
		if self.isDestroyed or not self.car:IsDescendantOf(Workspace) then
			return
		end
		updateVisuals(self, math.min(dt, MAX_FRAME_DT))
	end))
end

function Module.Stop(self: ControllerData)
	if not self.isRunning then
		return
	end
	self.isRunning = false
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end
	table.clear(self.connections)
	ContextActionService:UnbindAction(self.actionName)
	self.isLocalDriver = false
	self.isHandbraking = false
	self.curbForce.Force = Vector3.zero
	self.airControl.Enabled = false
	self.airControl.AngularVelocity = Vector3.zero
	for _, wheel in ipairs(self.wheels) do
		wheel.forceConstraint.Force = Vector3.zero
	end
end

function Module.Destroy(self: ControllerData)
	if self.isDestroyed then
		return
	end
	self:Stop()
	self.isDestroyed = true
	for _, wheel in ipairs(self.wheels) do
		wheel.forceConstraint:Destroy()
		wheel.forceAttachment:Destroy()
	end
	self.curbForce:Destroy()
	self.curbAttachment:Destroy()
	self.airControl:Destroy()
	self.airAttachment:Destroy()
end

return Module :: ModuleApi
