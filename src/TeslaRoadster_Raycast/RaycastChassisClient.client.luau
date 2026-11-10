--!strict
--[[
    RaycastChassisClient.client.luau
    HOKI TOWN - Vehicle Engineering
    Laser / Raycast Arcade Vehicle Driving Engine (CDT Arcade + Tap-to-Drift)
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local car = script.Parent :: Model
local seat = car:WaitForChild("DriveSeat") :: VehicleSeat
local wheelsFolder = car:FindFirstChild("Wheels") :: Folder?

local MAX_SPEED = car:GetAttribute("MaxSpeed") or 190 -- studs/s (~130 mph)
local REVERSE_SPEED = car:GetAttribute("ReverseSpeed") or 55
local ACCEL_RATE = car:GetAttribute("Acceleration") or 110
local BRAKE_RATE = car:GetAttribute("Braking") or 160
local COAST_DRAG = 25
local TURN_SPEED = car:GetAttribute("TurnSpeed") or 2.8
local DRIFT_TURN_SPEED = car:GetAttribute("DriftTurnSpeed") or 4.0
local TARGET_HEIGHT = car:GetAttribute("TargetHoverHeight") or 1.85 -- height above ground (studs)
local CURB_STEP = 2.1 -- max curb/obstacle height the vehicle can climb
local CURB_BOOST = 16 -- upward velocity applied when climbing a curb

local HANDLEBRAKE_ACTION = "HokiRoadsterHandbrake"

local currentForwardSpeed = 0
local currentSteerAngle = 0
local wheelSpinAngle = 0
local isDriving = false
local handbrakeHeld = false
local jumpDisabledHumanoid: Humanoid? = nil

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

-- Spacebar sink: capture Space exclusively for drift/handbrake; never let it jump.
local function handleHandbrake(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject)
	if inputState == Enum.UserInputState.Begin then
		handbrakeHeld = true
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		handbrakeHeld = false
	end
	return Enum.ContextActionResult.Sink
end

local function onOccupantChanged()
	local occupant = seat.Occupant
	if occupant and occupant.Parent == localPlayer.Character then
		isDriving = true
		currentForwardSpeed = seat.AssemblyLinearVelocity:Dot(seat.CFrame.LookVector)
		rayParams.FilterDescendantsInstances = { car, localPlayer.Character }

		ContextActionService:BindActionAtPriority(
			HANDLEBRAKE_ACTION,
			handleHandbrake,
			false,
			Enum.ContextActionPriority.High.Value + 3000,
			Enum.KeyCode.Space
		)

		-- Prevent the seated humanoid from jumping while Space is used to drift.
		local humanoid = occupant
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		jumpDisabledHumanoid = humanoid
	else
		isDriving = false
		currentForwardSpeed = 0
		handbrakeHeld = false
		ContextActionService:UnbindAction(HANDLEBRAKE_ACTION)
		if jumpDisabledHumanoid then
			jumpDisabledHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			jumpDisabledHumanoid = nil
		end
	end
end

seat:GetPropertyChangedSignal("Occupant"):Connect(onOccupantChanged)
onOccupantChanged()

-- Cache visual wheel transforms relative to the chassis root so wheels can
-- spin and steer in place while following the vehicle.
type WheelVisual = { isFront: boolean, rel: CFrame }
local wheelVisuals: { [Instance]: WheelVisual } = {}

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
		if (w:IsA("BasePart") or w:IsA("Model")) and not wheelVisuals[w] then
			local wCFrame = w:IsA("Model") and w:GetPivot() or (w :: BasePart).CFrame
			wheelVisuals[w] = {
				isFront = (string.find(w.Name, "FL") ~= nil or string.find(w.Name, "FR") ~= nil),
				rel = rootCFrame:ToObjectSpace(wCFrame),
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

	-- 1. Direct Keyboard + VehicleSeat dual-input (100% immediate regardless of
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

	-- 2. Acceleration / Braking logic
	if throttle > 0.05 then
		currentForwardSpeed = math.min(MAX_SPEED, currentForwardSpeed + (ACCEL_RATE * throttle * dt))
	elseif throttle < -0.05 then
		if currentForwardSpeed > 3 then
			currentForwardSpeed = math.max(0, currentForwardSpeed - (BRAKE_RATE * math.abs(throttle) * dt))
		else
			currentForwardSpeed = math.max(-REVERSE_SPEED, currentForwardSpeed + (ACCEL_RATE * throttle * dt))
		end
	else
		-- Coasting friction
		if currentForwardSpeed > 0 then
			currentForwardSpeed = math.max(0, currentForwardSpeed - (COAST_DRAG * dt))
		elseif currentForwardSpeed < 0 then
			currentForwardSpeed = math.min(0, currentForwardSpeed + (COAST_DRAG * dt))
		end
	end

	-- 3. Raycast Ground Detection + damped PD spring for hover height conformity
	local rayOrigin = seat.Position + Vector3.new(0, 1, 0)
	local rayDir = -Vector3.yAxis * 8
	local rayResult = workspace:Raycast(rayOrigin, rayDir, rayParams)

	local targetVelY = 0
	local isGrounded = false

	if rayResult then
		isGrounded = true
		local heightDiff = (rayResult.Position.Y + TARGET_HEIGHT) - seat.Position.Y
		targetVelY = math.clamp(heightDiff * 14 - (root.AssemblyLinearVelocity.Y * 0.3), -30, 30)
	else
		-- Airborne gravity
		targetVelY = root.AssemblyLinearVelocity.Y - (196.2 * dt)
	end

	-- 4. Curb Climbing Assist
	--    Probe forward 3.5 studs at +0.8 studs above ground; lift over short curbs.
	if isGrounded and currentForwardSpeed > 2 and rayResult then
		local groundY = rayResult.Position.Y
		local curbOrigin = Vector3.new(seat.Position.X, groundY + 0.8, seat.Position.Z)
		local curbDir = forwardVector * math.sign(currentForwardSpeed) * 3.5
		local curbHit = workspace:Raycast(curbOrigin, curbDir, rayParams)
		if curbHit then
			local stepHeight = curbHit.Position.Y - groundY
			if stepHeight > 0 and stepHeight <= CURB_STEP then
				targetVelY = math.max(targetVelY, CURB_BOOST)
			end
		end
	end

	-- 5. Steering & Drift Dynamics
	local isDrifting = handbrakeHeld or (math.abs(steer) > 0.6 and math.abs(currentForwardSpeed) > 60)
	local activeTurnRate = isDrifting and DRIFT_TURN_SPEED or TURN_SPEED
	local speedRatio = math.clamp(math.abs(currentForwardSpeed) / 40, 0, 1)

	local yawVelocity = 0
	if isGrounded and math.abs(currentForwardSpeed) > 0.5 then
		local dirSign = currentForwardSpeed >= 0 and 1 or -1
		yawVelocity = -steer * activeTurnRate * speedRatio * dirSign
	end

	-- Lateral slip
	local lateralFactor = isDrifting and 0.45 or 0.05
	local lateralVelocity = isDrifting and (-rightVector * steer * currentForwardSpeed * lateralFactor) or Vector3.zero

	-- 6. Apply Assembly Velocities to the AssemblyRootPart
	local finalLinearVel = (forwardVector * currentForwardSpeed) + Vector3.new(0, targetVelY, 0) + lateralVelocity

	local angularVelocity = Vector3.new(0, yawVelocity, 0)
	if not isGrounded then
		-- Airborne attitude leveling: damp roll & pitch so the chassis lands flat.
		local localUp = root.CFrame:VectorToObjectSpace(Vector3.yAxis)
		local rollError = -localUp.X
		local pitchError = -localUp.Z
		angularVelocity += rightVector * (-pitchError * 5) + forwardVector * (rollError * 5)
	end

	root.AssemblyLinearVelocity = finalLinearVel
	root.AssemblyAngularVelocity = angularVelocity

	-- 7. Animate Visual Wheels (spin + front steering)
	if next(wheelVisuals) then
		wheelSpinAngle += (currentForwardSpeed / 1.35) * dt
		currentSteerAngle += ((-steer * math.rad(28)) - currentSteerAngle) * math.min(1, dt * 15)

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

print("[RaycastChassisClient] Arcade Engine 2.0 Ready!")
