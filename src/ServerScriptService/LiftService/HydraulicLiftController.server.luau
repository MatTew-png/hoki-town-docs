--!strict
--[[
    HydraulicLiftController.server.luau
    HOKI TOWN / รถ HOKI - Tuning Garage Hub
    2-Post Hydraulic Lift Controller with Model Freeze, Seat Lockout & Smooth Tween Animation
]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local ELEVATION_HEIGHT_STUDS = 8.5
local TWEEN_DURATION_SECONDS = 3.0

type LiftState = {
	isElevated: boolean,
	isMoving: boolean,
	groundCFrame: CFrame,
	elevatedCFrame: CFrame,
	activeWeld: WeldConstraint?,
	lockedCar: Model?,
	lockedOccupant: Humanoid?,
}

local function setupLift(liftModel: Model)
	local platform = liftModel:FindFirstChild("Lift_Carriage_Platform") :: BasePart?
	local promptPart = liftModel:FindFirstChild("Lift_Control_Console") :: BasePart?
	local sensorZone = liftModel:FindFirstChild("Lift_Sensor_Zone") :: BasePart?

	if not platform or not promptPart or not sensorZone then
		warn("[HydraulicLiftController] Incomplete lift model components in:", liftModel:GetFullName())
		return
	end

	local prompt = promptPart:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "สำนักแต่ง HOKI"
		prompt.ActionText = "ยกลิฟต์ตรวจช่วงล่าง [E]"
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = promptPart
	end

	local state: LiftState = {
		isElevated = false,
		isMoving = false,
		groundCFrame = platform.CFrame,
		elevatedCFrame = platform.CFrame + Vector3.new(0, ELEVATION_HEIGHT_STUDS, 0),
		activeWeld = nil,
		lockedCar = nil,
		lockedOccupant = nil,
	}

	local tweenInfo = TweenInfo.new(
		TWEEN_DURATION_SECONDS,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut
	)

	local function findCarInZone(): Model?
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Include
		overlapParams.FilterDescendantsInstances = { workspace }

		local parts = workspace:GetPartsInPart(sensorZone, overlapParams)
		for _, part in ipairs(parts) do
			local model = part:FindFirstAncestorOfClass("Model")
			if model and (model:FindFirstChild("Chassis_Collider") or model:FindFirstChild("DriveSeat")) then
				return model
			end
		end
		return nil
	end

	local function lockVehicle(car: Model)
		local collider = car:FindFirstChild("Chassis_Collider") :: BasePart?
		local driveSeat = car:FindFirstChild("DriveSeat") :: VehicleSeat?

		if collider and platform then
			-- 1. Neutralize physics kinetic spikes
			collider.AssemblyLinearVelocity = Vector3.zero
			collider.AssemblyAngularVelocity = Vector3.zero

			-- 2. Anchor structural weld to lift carriage
			local weld = Instance.new("WeldConstraint")
			weld.Name = "Lift_Lock_Constraint"
			weld.Part0 = platform
			weld.Part1 = collider
			weld.Parent = platform
			state.activeWeld = weld
		end

		-- 3. Mute drive input
		car:SetAttribute("VehicleControlLocked", true)
		state.lockedCar = car

		-- 4. Lock driver into seat (prevent accidental ejection)
		if driveSeat and driveSeat.Occupant then
			local humanoid = driveSeat.Occupant
			state.lockedOccupant = humanoid
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			humanoid:SetAttribute("LiftSeatLocked", true)
		end
	end

	local function unlockVehicle()
		if state.activeWeld then
			state.activeWeld:Destroy()
			state.activeWeld = nil
		end

		if state.lockedCar then
			state.lockedCar:SetAttribute("VehicleControlLocked", false)
			state.lockedCar = nil
		end

		if state.lockedOccupant then
			state.lockedOccupant:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			state.lockedOccupant:SetAttribute("LiftSeatLocked", false)
			state.lockedOccupant = nil
		end
	end

	prompt.Triggered:Connect(function(playerWhoTriggered)
		if state.isMoving then return end

		if not state.isElevated then
			-- Raising lift
			local car = findCarInZone()
			if not car then
				prompt.ActionText = "กรุณาขับรถเข้าช่องจอดก่อนยกลิฟต์"
				task.delay(2, function()
					if not state.isElevated and not state.isMoving then
						prompt.ActionText = "ยกลิฟต์ตรวจช่วงล่าง [E]"
					end
				end)
				return
			end

			state.isMoving = true
			lockVehicle(car)
			prompt.ActionText = "กำลังยกลิฟต์..."

			local tween = TweenService:Create(platform, tweenInfo, {
				CFrame = state.elevatedCFrame
			})
			tween:Play()
			tween.Completed:Connect(function()
				state.isElevated = true
				state.isMoving = false
				prompt.ActionText = "ลดระดับลิฟต์ลง [E]"
			end)
		else
			-- Lowering lift
			state.isMoving = true
			prompt.ActionText = "กำลังลดระดับลิฟต์..."

			local tween = TweenService:Create(platform, tweenInfo, {
				CFrame = state.groundCFrame
			})
			tween:Play()
			tween.Completed:Connect(function()
				unlockVehicle()
				state.isElevated = false
				state.isMoving = false
				prompt.ActionText = "ยกลิฟต์ตรวจช่วงล่าง [E]"
			end)
		end
	end)

	print("[HydraulicLiftController] Configured lift for:", liftModel.Name)
end

-- Scan and bind all lifts in workspace
local function scanLifts()
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc:IsA("Model") and (desc.Name == "Hydraulic_Lift" or desc.Name:find("Lift_2Post")) then
			setupLift(desc)
		end
	end
end

task.defer(scanLifts)
workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("Model") and (desc.Name == "Hydraulic_Lift" or desc.Name:find("Lift_2Post")) then
		setupLift(desc)
	end
end)
