--!strict
--[[
	TeslaRoadster_Scon Aerodynamics (No Wind / Body Audio)
	Preserves chassis drag, ground-effect downforce, and jump-glide aero reduction.
	WindSound and BodySound are intentionally removed for long-duration driving comfort.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local car = script.Parent:WaitForChild("Car").Value :: Model?
if not car then
	return
end

local tuneFolder = car:WaitForChild("Hoki-Chassis Tune", 5)
if not tuneFolder then
	return
end
local Tune = require(tuneFolder)
local Units = require(tuneFolder.README.Units)

-- [[Aerodynamic Physics Config]]
local UseWeight = false
local UseSlipstream = false

local Drag = 0.2
local DragMult = 1.0
local Slipstream = 70
local SlipstreamTime = 0.7
local DownforceF = Tune.DownforceFrontKgf or 90
local DownforceR = Tune.DownforceRearKgf or 110

local body = car:WaitForChild("Body", 5)
if not body then
	return
end
local weight = body:WaitForChild("#Weight", 5) :: BasePart?
if not weight then
	return
end
local Directory = body:FindFirstChild("Aerodynamics")
local SimulationRate = 1 / 30

local values = script.Parent:WaitForChild("Values", 5)
if not values then
	return
end
local player = Players.LocalPlayer
local CenterValue = values:WaitForChild("Center") :: CFrameValue
local VelocityValue = values:WaitForChild("Velocity") :: Vector3Value

local toKMH = (Units.Length_mm / 1000) * 3.6
local fromKGF = 9.81 * Units.Force_N

-- Remove any legacy wind/body noise instances left on #Weight
for _, legacyName in ipairs({ "WindSound", "BodySound" }) do
	local legacy = weight:FindFirstChild(legacyName)
	if legacy and legacy:IsA("Sound") then
		legacy:Stop()
		legacy:Destroy()
	end
end

local dragPart: BasePart = (if UseWeight or not Directory then weight else Directory:FindFirstChild("Drag") or weight) :: BasePart
local dfPart: BasePart = (if UseWeight or not Directory then weight else Directory:FindFirstChild("DownforceF") or weight) :: BasePart
local drPart: BasePart = (if UseWeight or not Directory then weight else Directory:FindFirstChild("DownforceR") or weight) :: BasePart

local function ensureAttachment(part: BasePart, name: string, offset: Vector3): Attachment
	local targetOffset = offset
	if part ~= weight then
		local localCenter = part.CFrame:PointToObjectSpace(weight.Position)
		targetOffset = Vector3.new(localCenter.X, offset.Y, offset.Z)
	end
	local existing = part:FindFirstChild(name)
	if existing and existing:IsA("Attachment") then
		existing.Position = targetOffset
		return existing
	end
	local att = Instance.new("Attachment")
	att.Name = name
	att.Position = targetOffset
	att.Parent = part
	return att
end

local function ensureVectorForce(part: BasePart, name: string, att: Attachment): VectorForce
	local existing = part:FindFirstChild(name)
	if existing and existing:IsA("VectorForce") then
		existing.Attachment0 = att
		existing.RelativeTo = Enum.ActuatorRelativeTo.World
		return existing
	end
	local vf = Instance.new("VectorForce")
	vf.Name = name
	vf.Attachment0 = att
	vf.RelativeTo = Enum.ActuatorRelativeTo.World
	vf.Parent = part
	return vf
end

local dragAttach = ensureAttachment(dragPart, "DragAttachment", Vector3.zero)
local dfAttach = ensureAttachment(dfPart, "DownforceFAttachment", Vector3.new(0, 0, UseWeight and -weight.Size.Z / 2 or 0))
local drAttach = ensureAttachment(drPart, "DownforceRAttachment", Vector3.new(0, 0, UseWeight and weight.Size.Z / 2 or 0))

local dragForce = ensureVectorForce(dragPart, "DragForce", dragAttach)
local dfForce = ensureVectorForce(dfPart, "DownforceFForce", dfAttach)
local drForce = ensureVectorForce(drPart, "DownforceRForce", drAttach)

local aeroParams = RaycastParams.new()
aeroParams.FilterType = Enum.RaycastFilterType.Exclude
aeroParams.FilterDescendantsInstances = { car, player.Character :: Instance }

local aeroParamsFrom = RaycastParams.new()
aeroParamsFrom.FilterType = Enum.RaycastFilterType.Exclude
aeroParamsFrom.FilterDescendantsInstances = {}

local groundRaycastParams = RaycastParams.new()
groundRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
groundRaycastParams.FilterDescendantsInstances = { car }
groundRaycastParams.RespectCanCollide = true

local groundContactScale = 0

task.wait()
for _, v in ipairs(car:GetDescendants()) do
	if v:IsA("BasePart") then
		v.EnableFluidForces = false
	end
end

local active = true
local driveSeat = car:FindFirstChild("DriveSeat")
local seatRemovedConn: RBXScriptConnection? = nil

local function shutdownAero()
	if not active then
		return
	end
	active = false
	dragForce.Force = Vector3.zero
	dfForce.Force = Vector3.zero
	drForce.Force = Vector3.zero
	if seatRemovedConn then
		seatRemovedConn:Disconnect()
		seatRemovedConn = nil
	end
	if script.Parent then
		script:Destroy()
	end
end

if driveSeat then
	seatRemovedConn = driveSeat.ChildRemoved:Connect(function(child)
		if child.Name == "SeatWeld" and child:IsA("Weld") then
			shutdownAero()
		end
	end)
end

script.Destroying:Connect(function()
	active = false
	dragForce.Force = Vector3.zero
	dfForce.Force = Vector3.zero
	drForce.Force = Vector3.zero
	if seatRemovedConn then
		seatRemovedConn:Disconnect()
		seatRemovedConn = nil
	end
end)

local wheelsFolder = car:FindFirstChild("Wheels")
while active and car.Parent do
	local dt = task.wait(SimulationRate)
	if not active then
		break
	end

	local groundedWheelCount = 0
	local totalWheelCount = 0
	if player.Character then
		groundRaycastParams.FilterDescendantsInstances = { car, player.Character :: Instance }
	end
	if wheelsFolder then
		for _, wheel in ipairs(wheelsFolder:GetChildren()) do
			if
				wheel:IsA("BasePart")
				and (
					wheel.Name == "FL"
					or wheel.Name == "FR"
					or wheel.Name == "RL"
					or wheel.Name == "RR"
					or wheel.Name == "F"
					or wheel.Name == "R"
				)
			then
				totalWheelCount += 1
				local wheelRadius = math.max(wheel.Size.Y, wheel.Size.Z) * 0.5
				if Workspace:Raycast(wheel.Position, -Vector3.yAxis * (wheelRadius + 0.08), groundRaycastParams) then
					groundedWheelCount += 1
				end
			end
		end
	end

	local targetGroundContactScale = 0
	if totalWheelCount > 0 and groundedWheelCount >= math.ceil(totalWheelCount * 0.75) then
		targetGroundContactScale = groundedWheelCount / totalWheelCount
	end
	local contactBlend = 1 - math.exp(-dt / 0.14)
	groundContactScale += (targetGroundContactScale - groundContactScale) * contactBlend

	if (VelocityValue.Value - Workspace.GlobalWind).Magnitude < 1 then
		dragForce.Force = Vector3.zero
		dfForce.Force = Vector3.zero
		drForce.Force = Vector3.zero
		continue
	end

	local airTemp = (tonumber(Workspace:GetAttribute("GlobalTemperature")) or 22) + 273.15
	local airPressurePercent = math.exp(
		(-9.80665 * 0.0289644 * (CenterValue.Value.Position.Y * Units.Length_mm / 1000)) / (8.3142 * airTemp)
	) * (Workspace.AirDensity / 0.001)

	local dragFactor = 1
	if UseSlipstream then
		local toRay = Workspace:Raycast(weight.Position, weight.CFrame.LookVector * 1000, aeroParams)
		if toRay and toRay.Instance:IsA("BasePart") then
			local targetPart = toRay.Instance
			aeroParamsFrom.FilterDescendantsInstances = targetPart:GetConnectedParts()
			local fromRay = Workspace:Raycast(toRay.Position, -targetPart.AssemblyLinearVelocity * SlipstreamTime, aeroParamsFrom)
			if fromRay and fromRay.Instance:IsDescendantOf(car) then
				local slipLen = (targetPart.AssemblyLinearVelocity * SlipstreamTime).Magnitude
				if slipLen > 0.01 then
					dragFactor = (1 - (Slipstream / 100)) + (fromRay.Distance / slipLen * (Slipstream / 100))
				end
			end
		end
	end

	local isAirborne = car:GetAttribute("PiggyCarAirborneWeightReduced") == true
	local dragScale = isAirborne and 0.25 or 1
	local downforceScale = isAirborne and 0 or groundContactScale

	local carVel = VelocityValue.Value * toKMH
	local windVel = Workspace.GlobalWind * toKMH
	local diff = carVel - windVel
	local objectVel = weight.CFrame:VectorToObjectSpace(diff)

	local df = math.sign(objectVel.Z) * (objectVel.Z ^ 2 / (200 ^ 2)) * DownforceF * dragFactor * downforceScale
	local dr = math.sign(objectVel.Z) * (objectVel.Z ^ 2 / (200 ^ 2)) * DownforceR * dragFactor * downforceScale
	local combinedForce = if diff.Magnitude > 0.01
		then -diff.Unit * (diff.Magnitude ^ 2) * ((Drag * DragMult) / 100) * airPressurePercent * dragScale
		else Vector3.zero

	dfForce.Force = weight.CFrame.UpVector * df * fromKGF
	drForce.Force = weight.CFrame.UpVector * dr * fromKGF
	dragForce.Force = combinedForce * fromKGF
end
