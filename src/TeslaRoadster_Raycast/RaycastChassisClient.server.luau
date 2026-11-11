--!strict
--[[
    RaycastChassisClient.client.luau
    HOKI TOWN - Vehicle Engineering
    Thin client entrypoint for the Hybrid Raycast Chassis. Initializes the physics
    solver, starts it, and publishes client-local telemetry attributes consumed by
    VehicleSoundClient and VehicleStatusClient (no server network spam).
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local car = script.Parent :: Model
local RaycastVehiclePhysics = require(script.Parent:WaitForChild("RaycastVehiclePhysics"))

if not car:WaitForChild("DriveSeat", 15) then
	return
end
if not car:WaitForChild("Chassis_Collider", 15) then
	return
end

local controller = RaycastVehiclePhysics.Initialize(car)
controller:Start()

local heartbeatConn: RBXScriptConnection
local destroyingConn: RBXScriptConnection
local ancestryConn: RBXScriptConnection

local function cleanup()
	heartbeatConn:Disconnect()
	destroyingConn:Disconnect()
	ancestryConn:Disconnect()
	controller:Destroy()
end

heartbeatConn = RunService.Heartbeat:Connect(function()
	if not car:IsDescendantOf(Workspace) then
		return
	end
	local telemetry = controller:GetTelemetry()
	car:SetAttribute("ClientRPM", telemetry.RPM)
	car:SetAttribute("ClientGear", telemetry.Gear)
	car:SetAttribute("ClientThrottle", telemetry.Throttle)
	car:SetAttribute("ClientBoost", telemetry.Boost)
	car:SetAttribute("ClientSpeedKmh", telemetry.SpeedKmh)
end)

destroyingConn = car.Destroying:Connect(function()
	cleanup()
end)

ancestryConn = car.AncestryChanged:Connect(function()
	if car.Parent == nil then
		cleanup()
	end
end)

print("[RaycastChassisClient] Hybrid Raycast Chassis ready for " .. car.Name)
