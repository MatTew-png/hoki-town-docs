--!strict
--[[
    NGChassisClient.client.luau
    HOKI TOWN - Vehicle Engineering
    Next-Gen Chassis (NGChassis) Client Physics & Input Engine
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local car = script.Parent :: Model
local seat = car:WaitForChild("DriveSeat") :: VehicleSeat
local Config = require(script.Parent.NGChassisConfig)

local wheelsFolder = car:FindFirstChild("Wheels") :: Folder?

local currentForwardSpeed = 0
local currentSteerAngle = 0
local wheelSpinAngle = 0
local isDriving = false

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

-- 1. Detect driver seat occupancy
local function onOccupantChanged()
	local occupant = seat.Occupant
	if occupant and occupant.Parent == localPlayer.Character then
		isDriving = true
		currentForwardSpeed = seat.AssemblyLinearVelocity:Dot(seat.CFrame.LookVector)
		rayParams.FilterDescendantsInstances = { car, localPlayer.Character }
	else
		isDriving = false
		currentForwardSpeed = 0
	end
end

seat:GetPropertyChangedSignal("Occupant"):Connect(onOccupantChanged)
onOccupantChanged()

-- Cache visual wheel transforms relative to the chassis root so wheels can
-- spin and steer in place while following the vehicle.
type WheelVisual = { isFront: boolean, rel: CFrame }
local wheelVisuals: { [BasePart]: WheelVisual } = {}

local function captureWheelVisuals()
	if not wheelsFolder then
		wheelsFolder = car:FindFirstChild("Wheels") :: Folder?
	end
	if not wheelsFolder then
		return
	end

	local root = seat.AssemblyRootPart or seat
	local rootCFrame = root.CFrame
	for _, w in ipairs(wheelsFolder:GetChildren()) do
		if w:IsA("BasePart") and not wheelVisuals[w] then
			wheelVisuals[w] = {
				isFront = (w.Name == "FL" or w.Name == "FR"),
				rel = rootCFrame:ToObjectSpace(w.CFrame),
			}
		end
	end
end
captureWheelVisuals()

RunService.PreSimulation:Connect(function(dt: number)
	if not isDriving or not seat:IsDescendantOf(workspace) then return end

	local root = seat.AssemblyRootPart or seat

	local seatCFrame = seat.CFrame
	local forwardVector = seatCFrame.LookVector
	local rightVector = seatCFrame.RightVector

	-- 2. Direct keyboard + VehicleSeat dual-input (immediate regardless of
	--    Roblox Gui/Seat focus state).
	local seatThrottle = seat.ThrottleFloat
	local seatSteer = seat.SteerFloat

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

	local throttle = math.clamp(seatThrottle + kbThrottle, -1, 1)
	local steer = math.clamp(seatSteer + kbSteer, -1, 1)
	local spaceHeld = UserInputService:IsKeyDown(Enum.KeyCode.Space)

	-- Acceleration / Braking logic
	if throttle > 0.05 then
		currentForwardSpeed = math.min(Config.TopSpeed, currentForwardSpeed + (Config.Acceleration * throttle * dt))
	elseif throttle < -0.05 then
		if currentForwardSpeed > 3 then
			currentForwardSpeed = math.max(0, currentForwardSpeed - (Config.BrakeRate * math.abs(throttle) * dt))
		else
			currentForwardSpeed = math.max(-Config.ReverseSpeed, currentForwardSpeed + (Config.Acceleration * throttle * dt))
		end
	else
		-- Coasting friction
		if currentForwardSpeed > 0 then
			currentForwardSpeed = math.max(0, currentForwardSpeed - (Config.CoastDrag * dt))
		elseif currentForwardSpeed < 0 then
			currentForwardSpeed = math.min(0, currentForwardSpeed + (Config.CoastDrag * dt))
		end
	end

	-- 3. Raycast Ground Detection + PD spring for hover height conformity
	local rayOrigin = seat.Position + Vector3.new(0, 1, 0)
	local rayDir = -Vector3.yAxis * 8
	local rayResult = workspace:Raycast(rayOrigin, rayDir, rayParams)

	local targetVelY = 0
	local isGrounded = false

	if rayResult then
		isGrounded = true
		local heightDiff = (rayResult.Position.Y + Config.TargetHeight) - seat.Position.Y
		targetVelY = math.clamp(heightDiff * Config.SpringStiffness - (root.AssemblyLinearVelocity.Y * Config.SpringDamping), -30, 30)
	else
		-- Airborne gravity
		targetVelY = root.AssemblyLinearVelocity.Y - (196.2 * dt)
	end

	-- Steering & Drift Dynamics
	local isDrifting = spaceHeld or (math.abs(steer) > 0.6 and math.abs(currentForwardSpeed) > 60)
	local activeTurnRate = isDrifting and Config.DriftTurnSpeed or Config.TurnSpeed
	local speedRatio = math.clamp(math.abs(currentForwardSpeed) / 40, 0, 1)

	local yawVelocity = 0
	if isGrounded and math.abs(currentForwardSpeed) > 0.5 then
		local dirSign = currentForwardSpeed >= 0 and 1 or -1
		yawVelocity = -steer * activeTurnRate * speedRatio * dirSign
	end

	-- Lateral slip
	local lateralFactor = isDrifting and 0.45 or 0.05
	local lateralVelocity = isDrifting and (-rightVector * steer * currentForwardSpeed * lateralFactor) or Vector3.zero

	-- 4/5. Apply Assembly Velocities to the AssemblyRootPart
	local finalLinearVel = (forwardVector * currentForwardSpeed) + Vector3.new(0, targetVelY, 0) + lateralVelocity
	root.AssemblyLinearVelocity = finalLinearVel
	root.AssemblyAngularVelocity = Vector3.new(0, yawVelocity, 0)

	-- 6. Animate Visual Wheels (spin + front steering)
	if next(wheelVisuals) then
		wheelSpinAngle += (currentForwardSpeed / 1.35) * dt
		currentSteerAngle += ((-steer * Config.MaxSteerAngle) - currentSteerAngle) * math.min(1, dt * 15)

		local rootCFrame = root.CFrame
		for w, state in wheelVisuals do
			local steerRot = state.isFront and CFrame.Angles(0, currentSteerAngle, 0) or CFrame.identity
			local spinRot = CFrame.Angles(wheelSpinAngle, 0, 0)
			local desired = rootCFrame * state.rel * steerRot * spinRot
			pcall(function()
				w:PivotTo(desired)
			end)
		end
	end
end)

print("[NGChassisClient] NGChassis Engine Ready!")
