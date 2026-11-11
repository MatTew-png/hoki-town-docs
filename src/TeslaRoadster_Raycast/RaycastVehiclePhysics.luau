--!strict
--[=[
	RaycastVehiclePhysics.luau
	Client-side custom raycast chassis solver for the Hybrid Raycast Roadster.

	Require this ModuleScript from a LocalScript after the vehicle is in Workspace:
		local controller = RaycastVehiclePhysics.Initialize(carModel)
		controller:Start()

	The driver must own the vehicle assembly's network ownership. Cosmetic wheel and
	caliper parts must be separate visual assemblies, not welded to the chassis or each other.
]=]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local VehicleStats = require(ReplicatedStorage:WaitForChild("VehicleStats"))

local LOCAL_PLAYER = Players.LocalPlayer :: Player
local WORLD_DOWN = -Vector3.yAxis
local SPHERECAST_RADIUS = 0.28
local MAX_FRAME_DT = 1 / 20

type TireStates = { [string]: boolean }

type Stats = {
	TopSpeed: number,
	ReverseSpeed: number,
	DriveAcceleration: number,
	LaunchAccelMultiplier: number,
	HighSpeedPullMultiplier: number,
	BrakeAcceleration: number,
	LateralGrip: number,
	AntiRollRatio: number,
	OversteerSensitivity: number,
	TurboBoostPower: number,
	AirGravityScale: number,
	AirPitchRate: number,
	AirYawRate: number,
	AirRollRate: number,
	AirControlDelay: number,
	CurbHeight: number,
	CurbAssistForce: number,
	FrontSteerBias: number,
	EffectiveTopSpeed: number,
	TireStates: TireStates,
}

-- Solver constants that upgrades deliberately never touch (zero overcontrol).
local DEFAULTS = {
	RestLength = 2.4,
	SpringTravel = 0.9,
	LandingDamperMultiplier = 2.5,
	LandingDamperDuration = 0.2,
	DriftGripMultiplier = 0.3,
	MaximumSteerAngle = math.rad(30),
}

type Config = {
	RestLength: number,
	SpringTravel: number,
	LandingDamperMultiplier: number,
	LandingDamperDuration: number,
	DriftGripMultiplier: number,
	MaximumSteerAngle: number,
}

type WheelVisualPart = {
	part: BasePart,
	relToHub: CFrame,
}

type WheelState = {
	key: string,
	front: boolean,
	probePosition: Vector3,
	forceAttachment: Attachment,
	forceConstraint: VectorForce,
	wheelRadius: number,
	spinners: { WheelVisualPart },
	calipers: { WheelVisualPart },
	compression: number,
	previousCompression: number,
	suspensionOffset: number,
	normalLoad: number,
	grounded: boolean,
}

export type TelemetrySnapshot = {
	SpeedKmh: number,
	SpeedStuds: number,
	Gear: number,
	RPM: number,
	Throttle: number,
	Boost: number,
	Steer: number,
}

export type Controller = {
	Start: (self: Controller) -> (),
	Stop: (self: Controller) -> (),
	Destroy: (self: Controller) -> (),
	GetTelemetry: (self: Controller) -> TelemetrySnapshot,
}

type ModuleApi = {
	Initialize: (car: Model) -> Controller,
}

type ControllerData = Controller & {
	car: Model,
	root: BasePart,
	seat: VehicleSeat,
	wheels: { WheelState },
	config: Config,
	stats: Stats,
	rayParams: RaycastParams,
	curbParams: RaycastParams,
	curbAttachment: Attachment,
	curbForce: VectorForce,
	airAttachment: Attachment,
	airControl: AngularVelocity,
	airGravityAttachment: Attachment,
	airGravityForce: VectorForce,
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
	airborneTime: number,
	jumpDisabledHumanoid: Humanoid?,
	telemetry: TelemetrySnapshot,
}

local Module: any = {}
Module.__index = Module

local WHEEL_NAMES: { string } = { "FL", "FR", "RL", "RR" }
local CALIPER_NAMES = { "Caliper_FL", "Caliper_FR", "Caliper_RL", "Caliper_RR" }

local function clamp(value: number, minimum: number, maximum: number): number
	return math.clamp(value, minimum, maximum)
end

local function lerp(from: number, to: number, t: number): number
	return from + (to - from) * t
end

local function waitForChild(root: Instance, name: string, timeoutSeconds: number): Instance?
	local instance = root:FindFirstChild(name, true)
	local deadline = os.clock() + timeoutSeconds
	while not instance and os.clock() < deadline do
		task.wait(0.1)
		instance = root:FindFirstChild(name, true)
	end
	return instance
end

local function findBasePart(root: Instance, name: string, timeoutSeconds: number?): BasePart
	local instance = waitForChild(root, name, timeoutSeconds or 10)
	assert(
		instance and instance:IsA("BasePart"),
		string.format("Missing BasePart '%s' under %s", name, root:GetFullName())
	)
	return instance
end

local function captureVisualPart(hubWorldCFrame: CFrame, part: BasePart): WheelVisualPart
	part.Anchored = true
	part.CanCollide = false
	part.Massless = true
	return {
		part = part,
		relToHub = hubWorldCFrame:ToObjectSpace(part.CFrame),
	}
end

-- Resolves a wheel's physical radius and visual parts from either a multi-part
-- Model (Wheels.FL -> Wheel_FL/Tire_FL/Brake_Rotor_FL/Caliper_FL) or a direct
-- BasePart wheel (FL / Wheel_FL). Returns radius, center offset (root-local), the
-- set of spinning parts, and the set of caliper parts (which follow the axle but
-- never spin).
local function resolveWheel(
	root: BasePart,
	car: Model,
	wheelsFolder: Instance,
	key: string,
	index: number
): (number, Vector3, { WheelVisualPart }, { WheelVisualPart })
	local rootCFrame = root.CFrame
	local entry = wheelsFolder:FindFirstChild(key)

	local spinners: { WheelVisualPart } = {}
	local calipers: { WheelVisualPart } = {}
	local radius = 0
	local center = Vector3.zero

	if entry and entry:IsA("Model") then
		local pivotPart = entry:FindFirstChild("Tire_" .. key)
			or entry:FindFirstChild("Tire")
			or entry:FindFirstChild("Wheel_" .. key)
			or entry:FindFirstChild("Wheel")
		if pivotPart and pivotPart:IsA("BasePart") then
			radius = pivotPart.Size.Y * 0.5
			center = rootCFrame:ToObjectSpace(pivotPart.CFrame).Position
		else
			for _, part in ipairs(entry:GetDescendants()) do
				if part:IsA("BasePart") and not part.Name:find("Caliper", 1, true) then
					radius = part.Size.Y * 0.5
					center = rootCFrame:ToObjectSpace(part.CFrame).Position
					break
				end
			end
		end

		local hubWorldCFrame = rootCFrame * CFrame.new(center)
		for _, part in ipairs(entry:GetDescendants()) do
			if part:IsA("BasePart") then
				local basePart = part :: BasePart
				if basePart.Name:find("Caliper", 1, true) then
					table.insert(calipers, captureVisualPart(hubWorldCFrame, basePart))
				else
					table.insert(spinners, captureVisualPart(hubWorldCFrame, basePart))
				end
			end
		end
	else
		local wheelPart = if entry and entry:IsA("BasePart")
			then entry :: BasePart
			else wheelsFolder:FindFirstChild("Wheel_" .. key) :: BasePart?
		assert(wheelPart, string.format("Missing wheel '%s' under %s", key, wheelsFolder:GetFullName()))
		radius = wheelPart.Size.Y * 0.5
		center = rootCFrame:ToObjectSpace(wheelPart.CFrame).Position

		local hubWorldCFrame = rootCFrame * CFrame.new(center)
		table.insert(spinners, captureVisualPart(hubWorldCFrame, wheelPart))

		local caliperPart = car:FindFirstChild(CALIPER_NAMES[index], true)
		if caliperPart and caliperPart:IsA("BasePart") then
			table.insert(calipers, captureVisualPart(hubWorldCFrame, caliperPart))
		end
	end

	assert(radius > 0, string.format("Invalid wheel radius for '%s'", key))
	return radius, center, spinners, calipers
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

function Module.Initialize(car: Model): Controller
	assert(RunService:IsClient(), "RaycastVehiclePhysics must be initialized by a LocalScript")
	assert(car:IsA("Model"), "Initialize expects a vehicle Model")

	local root = findBasePart(car, "Chassis_Collider")
	local seatPart = findBasePart(car, "DriveSeat")
	assert(seatPart:IsA("VehicleSeat"), "DriveSeat must be a VehicleSeat")
	local seat = seatPart :: VehicleSeat
	local config: Config = table.clone(DEFAULTS)
	if not car:FindFirstChild("Wheels") then
		waitForChild(car, "FL", 10)
	end
	local wheelsFolder: Instance = car:FindFirstChild("Wheels") or car
	for _, name in ipairs(WHEEL_NAMES) do
		waitForChild(wheelsFolder, name, 10)
	end

	root.CanCollide = true
	root.Massless = false
	seat.CanCollide = false

	local controller: ControllerData = setmetatable({}, Module) :: any
	controller.car = car
	controller.root = root
	controller.seat = seat
	controller.config = config
	controller.wheels = {}
	controller.stats = VehicleStats.Compute(car)
	controller.connections = {}
	controller.rayParams = RaycastParams.new()
	controller.curbParams = RaycastParams.new()
	controller.isRunning = false
	controller.isDestroyed = false
	controller.isLocalDriver = false
	controller.isHandbraking = false
	controller.wasAirborne = false
	controller.landingDamperUntil = 0
	controller.wheelSpinAngle = 0
	controller.steerAngle = 0
	controller.airborneTime = 0
	controller.jumpDisabledHumanoid = nil
	controller.telemetry = {
		SpeedKmh = 0,
		SpeedStuds = 0,
		Gear = 0,
		RPM = 850,
		Throttle = 0,
		Boost = 0,
		Steer = 0,
	}
	controller.actionName = "HokiRoadsterHandbrake_" .. car.Name .. "_" .. tostring(car)

	controller.rayParams.FilterType = Enum.RaycastFilterType.Exclude
	controller.rayParams.FilterDescendantsInstances = { car }
	controller.rayParams.IgnoreWater = true
	controller.rayParams.RespectCanCollide = true
	controller.curbParams.FilterType = Enum.RaycastFilterType.Exclude
	controller.curbParams.FilterDescendantsInstances = { car }
	controller.curbParams.IgnoreWater = true
	controller.curbParams.RespectCanCollide = true

	local frontZ = 0
	local rearZ = 0
	for index, name in ipairs(WHEEL_NAMES) do
		local front = index <= 2
		local radius, center, spinners, calipers = resolveWheel(root, car, wheelsFolder, name, index)
		if front then
			frontZ += center.Z
		else
			rearZ += center.Z
		end

		local attachment = createAttachment(root, "RaycastSuspension_" .. name, center)
		local force = createVectorForce(root, attachment, "RaycastTireForce_" .. name)
		table.insert(controller.wheels, {
			key = name,
			front = front,
			probePosition = center,
			forceAttachment = attachment,
			forceConstraint = force,
			wheelRadius = radius,
			spinners = spinners,
			calipers = calipers,
			compression = 0,
			previousCompression = 0,
			suspensionOffset = 0,
			normalLoad = 0,
			grounded = false,
		})
	end
	frontZ = frontZ / 2
	rearZ = rearZ / 2

	controller.curbAttachment =
		createAttachment(root, "CurbAssist_ForceAttachment", Vector3.new(0, -0.15, frontZ - 0.65))
	controller.curbForce = createVectorForce(root, controller.curbAttachment, "CurbAssist_Force")

	controller.airAttachment = createAttachment(root, "AirControl_Attachment", Vector3.zero)
	controller.airControl = Instance.new("AngularVelocity")
	controller.airControl.Name = "AirControl_AngularVelocity"
	controller.airControl.Attachment0 = controller.airAttachment
	controller.airControl.RelativeTo = Enum.ActuatorRelativeTo.World
	controller.airControl.MaxTorque = root.AssemblyMass * 1800
	controller.airControl.AngularVelocity = Vector3.zero
	controller.airControl.Enabled = false
	controller.airControl.Parent = root

	controller.airGravityAttachment = createAttachment(root, "AirGravity_Attachment", Vector3.zero)
	controller.airGravityForce = createVectorForce(root, controller.airGravityAttachment, "AirGravity_Force")
	controller.airGravityForce.ApplyAtCenterOfMass = true
	controller.airGravityForce.Force = Vector3.zero

	table.insert(
		controller.connections,
		car.AttributeChanged:Connect(function()
			controller.stats = VehicleStats.Compute(car)
		end)
	)

	return controller
end

local function isAnchored(self: ControllerData): boolean
	return self.seat.Anchored or self.root.Anchored
end

local function isCurrentLocalDriver(self: ControllerData): boolean
	local occupant = self.seat.Occupant
	return occupant ~= nil and occupant.Parent == LOCAL_PLAYER.Character
end

local function bindHandbrake(self: ControllerData)
	ContextActionService:BindAction(
		self.actionName,
		function(_actionName: string, inputState: Enum.UserInputState): Enum.ContextActionResult
			if inputState == Enum.UserInputState.Begin then
				self.isHandbraking = true
			elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
				self.isHandbraking = false
			end
			return Enum.ContextActionResult.Sink
		end,
		true,
		Enum.KeyCode.Space,
		Enum.KeyCode.ButtonB
	)
	ContextActionService:SetTitle(self.actionName, "Drift")
	ContextActionService:SetPosition(self.actionName, UDim2.fromScale(0.83, 0.72))
end

local function updateDriver(self: ControllerData)
	local isDriver = isCurrentLocalDriver(self)
	if isDriver == self.isLocalDriver then
		return
	end

	self.isLocalDriver = isDriver
	self.isHandbraking = false
	if isDriver then
		local occupant = self.seat.Occupant
		if occupant then
			occupant:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			self.jumpDisabledHumanoid = occupant
		end
		local character = LOCAL_PLAYER.Character
		local filterInstances: { Instance } = { self.car }
		if character then
			table.insert(filterInstances, character)
		end
		self.rayParams.FilterDescendantsInstances = filterInstances
		self.curbParams.FilterDescendantsInstances = filterInstances
		bindHandbrake(self)
	else
		if self.jumpDisabledHumanoid then
			self.jumpDisabledHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			self.jumpDisabledHumanoid = nil
		end
		self.rayParams.FilterDescendantsInstances = { self.car }
		self.curbParams.FilterDescendantsInstances = { self.car }
		ContextActionService:UnbindAction(self.actionName)
	end
end

local function probeWheels(self: ControllerData, dt: number, now: number): (number, number, number)
	local root = self.root
	local config = self.config
	local rootCFrame = root.CFrame
	local groundCount = 0
	local rearGroundY = 0
	local rearCount = 0
	local springMultiplier = if now < self.landingDamperUntil then config.LandingDamperMultiplier else 1
	local safeDt = math.max(dt, 1 / 60)
	local wheelMass = math.max(root.AssemblyMass * 0.25, 1)
	local springStiffness = (wheelMass * Workspace.Gravity) / 0.70
	local cCrit = 2 * math.sqrt(springStiffness * wheelMass)
	local damper = math.min(0.75 * cCrit * springMultiplier, 0.70 * wheelMass / safeDt)
	local maxWheelNormalLoad = wheelMass * Workspace.Gravity * 2.5
	local effectiveRestLength = config.RestLength + 0.40
	local maxTravel = config.SpringTravel + 0.40

	for _, wheel in ipairs(self.wheels) do
		local popped = self.stats.TireStates[wheel.key]
		local effectiveRadius = if popped then math.max(0.4, wheel.wheelRadius - 0.35) else wheel.wheelRadius
		local castLength = config.RestLength + config.SpringTravel + effectiveRadius + SPHERECAST_RADIUS
		local origin = rootCFrame:PointToWorldSpace(
			Vector3.new(wheel.probePosition.X, wheel.probePosition.Y + config.RestLength, wheel.probePosition.Z)
		)
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

			local suspensionDistance = hit.Distance + SPHERECAST_RADIUS - effectiveRadius
			local compression = clamp(effectiveRestLength - suspensionDistance, -config.SpringTravel, maxTravel)
			-- Positive compression velocity means the suspension is extending; this
			-- sign convention makes F = k*x - c*v resist both compression and rebound.
			local compressionVelocity = if wasGrounded
				then (wheel.previousCompression - compression) / math.max(dt, 1 / 240)
				else root:GetVelocityAtPosition(wheel.forceAttachment.WorldPosition).Y
			compressionVelocity = clamp(compressionVelocity, -20, 20)
			local activeCompression = math.max(compression, 0)
			local contactBlend = clamp(activeCompression / 0.12, 0, 1)
			local force = if activeCompression > 0
				then springStiffness * activeCompression - (damper * contactBlend) * compressionVelocity
				else 0
			wheel.compression = compression
			wheel.previousCompression = compression
			wheel.suspensionOffset = clamp(compression - 0.40, -0.35, config.SpringTravel)
			wheel.normalLoad = clamp(force, 0, maxWheelNormalLoad)
		else
			wheel.compression = -config.SpringTravel
			wheel.previousCompression = -config.SpringTravel
			wheel.suspensionOffset = -0.35
			wheel.forceConstraint.Force = Vector3.zero
		end
	end

	-- Anti-roll force transfers load between wheels on each axle without pulling
	-- either tire below zero normal force.
	local frontLeft = self.wheels[1]
	local frontRight = self.wheels[2]
	local rearLeft = self.wheels[3]
	local rearRight = self.wheels[4]
	if frontLeft.grounded and frontRight.grounded then
		local rawFrontArb = (frontLeft.compression - frontRight.compression)
			* springStiffness
			* self.stats.AntiRollRatio
		local frontTransfer = clamp(rawFrontArb, -frontLeft.normalLoad, frontRight.normalLoad)
		frontLeft.normalLoad = clamp(frontLeft.normalLoad + frontTransfer, 0, maxWheelNormalLoad)
		frontRight.normalLoad = clamp(frontRight.normalLoad - frontTransfer, 0, maxWheelNormalLoad)
	end
	if rearLeft.grounded and rearRight.grounded then
		local rawRearArb = (rearLeft.compression - rearRight.compression) * springStiffness * self.stats.AntiRollRatio
		local rearTransfer = clamp(rawRearArb, -rearLeft.normalLoad, rearRight.normalLoad)
		rearLeft.normalLoad = clamp(rearLeft.normalLoad + rearTransfer, 0, maxWheelNormalLoad)
		rearRight.normalLoad = clamp(rearRight.normalLoad - rearTransfer, 0, maxWheelNormalLoad)
	end

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
	local origin = root.CFrame:PointToWorldSpace(self.curbAttachment.Position)
	local hit = Workspace:Spherecast(origin, SPHERECAST_RADIUS, direction, self.curbParams)
	if not hit or hit.Normal.Y > 0.65 then
		self.curbForce.Force = Vector3.zero
		return
	end

	local roadY = rearGroundY / rearCount
	local obstacleHeight = hit.Position.Y - roadY
	if obstacleHeight <= 0.04 or obstacleHeight > self.stats.CurbHeight or hit.Distance > 3.8 then
		self.curbForce.Force = Vector3.zero
		return
	end

	local heightRatio = clamp(1 - obstacleHeight / self.stats.CurbHeight, 0.25, 1)
	local lift = root.AssemblyMass * Workspace.Gravity * self.stats.CurbAssistForce * heightRatio
	self.curbForce.Force = Vector3.yAxis * lift
end

local function updateAirControl(self: ControllerData, throttle: number, steer: number): ()
	if not self.airControl.Enabled then
		self.airControl.AngularVelocity = Vector3.zero
		return
	end

	local frame = self.root.CFrame

	-- Delayed air control: hold W/S/A/D during the first frames off a ramp so the
	-- nose doesn't instantly dive; after the delay, stunt inputs unlock.
	if self.airborneTime < self.stats.AirControlDelay then
		self.airControl.AngularVelocity = Vector3.zero
		return
	end

	if math.abs(throttle) < 0.08 and math.abs(steer) < 0.08 then
		-- No input while airborne: gently damp spin and level slightly toward upright.
		local localUp = frame:VectorToObjectSpace(Vector3.yAxis)
		local pitchCorrection = -localUp.Z * 2.0
		local rollCorrection = localUp.X * 2.0
		self.airControl.MaxTorque = self.root.AssemblyMass * 1800
		self.airControl.AngularVelocity = frame.RightVector * pitchCorrection + frame.LookVector * rollCorrection
		return
	end

	local pitch = frame.RightVector * (-throttle * self.stats.AirPitchRate)
	local yaw = Vector3.yAxis * (-steer * self.stats.AirYawRate)
	local roll = frame.LookVector * (steer * self.stats.AirRollRate * 0.45)
	self.airControl.MaxTorque = self.root.AssemblyMass * 1800
	self.airControl.AngularVelocity = pitch + yaw + roll
end

local function readInputs(self: ControllerData): (number, number)
	local seatThrottle = self.seat.ThrottleFloat
	local seatSteer = self.seat.SteerFloat

	local kbThrottle = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
		kbThrottle = 1
	elseif UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
		kbThrottle = -1
	end

	local kbSteer = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		kbSteer = -1
	elseif UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		kbSteer = 1
	end

	local throttle = clamp(seatThrottle + kbThrottle, -1, 1)
	local steer = clamp(seatSteer + kbSteer, -1, 1)
	return throttle, steer
end

local function updateTelemetry(self: ControllerData, throttle: number, steer: number, longitudinalSpeed: number)
	local speedStuds = math.abs(longitudinalSpeed)
	local speedKmh = speedStuds * 1.008
	local effectiveTopSpeed = math.max(self.stats.EffectiveTopSpeed, 1)
	local speedRatio = clamp(speedStuds / effectiveTopSpeed, 0, 1)

	local gear = 0
	if longitudinalSpeed < -1 then
		gear = -1
	elseif speedStuds > 0.5 or math.abs(throttle) > 0.05 then
		gear = clamp(1 + math.floor(speedRatio * 6), 1, 6)
	end

	local rpm = 850 + (7500 - 850) * clamp(0.12 + speedRatio * 0.72 + math.abs(throttle) * 0.25, 0, 1)
	local boost = clamp((rpm - 4500) / 3000, 0, 1) * math.max(throttle, 0) * self.stats.TurboBoostPower

	self.telemetry = {
		SpeedKmh = speedKmh,
		SpeedStuds = speedStuds,
		Gear = gear,
		RPM = rpm,
		Throttle = throttle,
		Boost = boost,
		Steer = steer,
	}
end

local function updateForces(self: ControllerData, dt: number)
	if not self.isLocalDriver or isAnchored(self) then
		for _, wheel in ipairs(self.wheels) do
			wheel.forceConstraint.Force = Vector3.zero
		end
		self.curbForce.Force = Vector3.zero
		self.airGravityForce.Force = Vector3.zero
		self.airControl.Enabled = false
		self.airControl.AngularVelocity = Vector3.zero
		return
	end

	local root = self.root
	local config = self.config
	local stats = self.stats
	local throttle, steer = readInputs(self)
	local velocity = root.AssemblyLinearVelocity
	local forward = root.CFrame.LookVector
	local longitudinalSpeed = velocity:Dot(forward)
	local handbraking = self.isHandbraking

	local groundCount, rearGroundY, rearCount = probeWheels(self, dt, os.clock())
	local grounded = groundCount
	curbAssist(self, rearGroundY, rearCount)

	if grounded == 0 then
		self.airborneTime += dt
	else
		self.airborneTime = 0
	end

	-- Lighter airborne gravity (counteract a fraction of gravity while airborne).
	if grounded == 0 then
		self.airGravityForce.Force = Vector3.yAxis
			* (root.AssemblyMass * Workspace.Gravity * (1 - stats.AirGravityScale))
	else
		self.airGravityForce.Force = Vector3.zero
	end

	-- Blown front tire pulls steering toward the flat side when grounded & moving.
	if grounded > 0 and math.abs(longitudinalSpeed) > 6 then
		steer = clamp(steer + stats.FrontSteerBias, -1, 1)
	end

	self.steerAngle += ((-steer * config.MaximumSteerAngle) - self.steerAngle) * math.min(1, dt * 12)
	updateAirControl(self, throttle, steer)

	updateTelemetry(self, throttle, steer, longitudinalSpeed)

	if grounded == 0 then
		for _, wheel in ipairs(self.wheels) do
			wheel.forceConstraint.Force = Vector3.zero
		end
		return
	end

	local mass = root.AssemblyMass
	local speedRatio = clamp(math.abs(longitudinalSpeed) / math.max(stats.EffectiveTopSpeed, 1), 0, 1)
	local accelMultiplier = lerp(stats.LaunchAccelMultiplier, stats.HighSpeedPullMultiplier, speedRatio)
	local motorForce = throttle * mass * stats.DriveAcceleration * accelMultiplier
	if throttle < 0 and longitudinalSpeed > 2 then
		motorForce = -mass * stats.BrakeAcceleration * -throttle
	elseif throttle > 0 and longitudinalSpeed < -2 then
		motorForce = mass * stats.BrakeAcceleration * throttle
	end

	if longitudinalSpeed > stats.EffectiveTopSpeed then
		motorForce = -mass * math.min(stats.BrakeAcceleration, (longitudinalSpeed - stats.EffectiveTopSpeed) * 8)
	elseif longitudinalSpeed < -stats.ReverseSpeed then
		motorForce = mass * math.min(stats.BrakeAcceleration, (-stats.ReverseSpeed - longitudinalSpeed) * 8)
	end
	local speedFade = clamp(
		(stats.EffectiveTopSpeed - math.max(longitudinalSpeed, 0)) / math.max(stats.EffectiveTopSpeed * 0.08, 1),
		0,
		1
	)
	if motorForce > 0 then
		motorForce *= speedFade
	end

	-- High-speed controlled tail-whip: at speed + heavy steering the rear grip drops
	-- smoothly, letting the tail swing without ever losing control entirely.
	local oversteerActive = speedRatio > 0.38 and math.abs(steer) > 0.35
	local peakFactor = 0.58 * stats.OversteerSensitivity
	local speedBlend = clamp((speedRatio - 0.38) / 0.62, 0, 1)
	local steerBlend = clamp((math.abs(steer) - 0.35) / 0.65, 0, 1)
	local oversteerGrip = 1 - (1 - peakFactor) * speedBlend * steerBlend

	local rearGripFactor = if handbraking then config.DriftGripMultiplier else 1
	if oversteerActive then
		rearGripFactor = math.min(rearGripFactor, oversteerGrip)
	end

	-- Auto-straightening: when the driver releases A/D, damp yaw and slightly elevate
	-- rear lateral recovery so the chassis settles onto its travel path.
	local autoStraighten = grounded > 0 and math.abs(steer) < 0.08
	if autoStraighten then
		rearGripFactor = math.min(1, rearGripFactor + 0.15)
	end

	-- Anti-spin safety cap: clamp chassis slip angle so the car never whips 360°.
	local lateralVel = velocity:Dot(root.CFrame.RightVector)
	local slipAngle = math.atan2(lateralVel, math.max(math.abs(longitudinalSpeed), 5))
	local yawDamping = 0
	if math.abs(slipAngle) > math.rad(38) then
		yawDamping = clamp((math.abs(slipAngle) - math.rad(38)) / math.rad(20), 0, 1) * 6
	end
	if autoStraighten then
		yawDamping += 2.0
	end
	if yawDamping > 0 then
		local angularVelocity = root.AssemblyAngularVelocity
		local localAngularVelocity = root.CFrame:VectorToObjectSpace(angularVelocity)
		local dampFactor = math.max(0, 1 - yawDamping * dt)
		localAngularVelocity =
			Vector3.new(localAngularVelocity.X, localAngularVelocity.Y * dampFactor, localAngularVelocity.Z)
		root.AssemblyAngularVelocity = root.CFrame:VectorToWorldSpace(localAngularVelocity)
	end

	local tireForward = forward
	local tireRight = root.CFrame.RightVector
	local steeringRotation = CFrame.fromAxisAngle(Vector3.yAxis, self.steerAngle)
	local enginePerWheel = motorForce * 0.25
	local totalNormalLoad = 0
	for _, w in ipairs(self.wheels) do
		if w.grounded then
			totalNormalLoad += w.normalLoad
		end
	end
	for _, wheel in ipairs(self.wheels) do
		local suspensionForce = Vector3.yAxis * wheel.normalLoad
		local tireForce = Vector3.zero
		if wheel.grounded then
			local safeDt = math.max(dt, 1 / 60)
			local wheelMassShare = mass * (wheel.normalLoad / math.max(totalNormalLoad, 1e-3))
			local steeredForward = if wheel.front then steeringRotation:VectorToWorldSpace(tireForward) else tireForward
			local steeredRight = if wheel.front then steeringRotation:VectorToWorldSpace(tireRight) else tireRight
			local pointVelocity = root:GetVelocityAtPosition(wheel.forceAttachment.WorldPosition)
			local lateralSpeed = pointVelocity:Dot(steeredRight)
			local wheelLongitudinalSpeed = pointVelocity:Dot(steeredForward)
			local smoothLongSign = clamp(wheelLongitudinalSpeed / 2.0, -1, 1)
			local wheelSlipAngle = math.atan2(lateralSpeed, math.max(math.abs(wheelLongitudinalSpeed), 3))
			local lateralCurve = math.sin(clamp(wheelSlipAngle / 0.72, -1, 1) * math.pi * 0.5)

			local popped = stats.TireStates[wheel.key]
			local wheelLateralGrip = if popped then stats.LateralGrip * 0.22 else stats.LateralGrip
			local gripScale = if not wheel.front then rearGripFactor else 1
			local maximumTireForce = wheel.normalLoad * wheelLateralGrip
			local longitudinalForce = clamp(enginePerWheel, -maximumTireForce, maximumTireForce)
			if handbraking and not wheel.front then
				longitudinalForce = -smoothLongSign * maximumTireForce * 1.5
			end
			if popped then
				-- Rolling resistance drag on a flat tire.
				longitudinalForce += -smoothLongSign * wheel.normalLoad * 0.38
			end
			if math.abs(throttle) < 0.05 or handbraking then
				local maxStopLong = (math.abs(wheelLongitudinalSpeed) * wheelMassShare) / safeDt * 0.55
				longitudinalForce = clamp(longitudinalForce, -maxStopLong, maxStopLong)
			end
			local lateralCapacity = math.sqrt(
				math.max(
					0,
					maximumTireForce * maximumTireForce - math.min(math.abs(longitudinalForce), maximumTireForce) ^ 2
				)
			)
			local rawLateralForce = -lateralCurve * lateralCapacity * gripScale
			local maxStopLateral = (math.abs(lateralSpeed) * wheelMassShare) / safeDt * 0.55
			local lateralForce = clamp(rawLateralForce, -maxStopLateral, maxStopLateral)
			tireForce = steeredRight * lateralForce + steeredForward * longitudinalForce
		end
		wheel.forceConstraint.Force = suspensionForce + tireForce
	end
end

local function updateVisuals(self: ControllerData, dt: number)
	local rootCFrame = self.root.CFrame
	local forwardSpeed = self.root.AssemblyLinearVelocity:Dot(rootCFrame.LookVector)
	self.wheelSpinAngle += forwardSpeed * dt
	local steerRotation = CFrame.Angles(0, self.steerAngle, 0)

	for _, wheel in ipairs(self.wheels) do
		local offset = Vector3.new(0, wheel.suspensionOffset, 0)
		local steerPose = if wheel.front then steerRotation else CFrame.identity
		local spinRotation = CFrame.Angles(-self.wheelSpinAngle / wheel.wheelRadius, 0, 0)
		local hubPose = rootCFrame * CFrame.new(wheel.probePosition + offset) * steerPose

		for _, spinner in ipairs(wheel.spinners) do
			spinner.part.CFrame = hubPose * spinRotation * spinner.relToHub
		end

		for _, caliper in ipairs(wheel.calipers) do
			caliper.part.CFrame = hubPose * caliper.relToHub
		end
	end
end

function Module.GetTelemetry(self: ControllerData): TelemetrySnapshot
	return self.telemetry
end

function Module.Start(self: ControllerData)
	assert(not self.isDestroyed, "Cannot start a destroyed vehicle controller")
	if self.isRunning then
		return
	end
	self.isRunning = true
	self.isLocalDriver = false
	updateDriver(self)
	table.insert(
		self.connections,
		self.seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			updateDriver(self)
		end)
	)
	table.insert(
		self.connections,
		self.car.Destroying:Connect(function()
			self:Destroy()
		end)
	)
	table.insert(
		self.connections,
		RunService.PreSimulation:Connect(function(dt: number)
			if self.isDestroyed or not self.car:IsDescendantOf(Workspace) then
				return
			end
			updateDriver(self)
			updateForces(self, clamp(dt, 1 / 240, MAX_FRAME_DT))
		end)
	)
	table.insert(
		self.connections,
		RunService.PreRender:Connect(function(dt: number)
			if self.isDestroyed or not self.car:IsDescendantOf(Workspace) then
				return
			end
			updateVisuals(self, math.min(dt, MAX_FRAME_DT))
		end)
	)
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
	if self.jumpDisabledHumanoid then
		self.jumpDisabledHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		self.jumpDisabledHumanoid = nil
	end
	self.curbForce.Force = Vector3.zero
	self.airGravityForce.Force = Vector3.zero
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
	self.airGravityForce:Destroy()
	self.airGravityAttachment:Destroy()
end

return Module :: ModuleApi
