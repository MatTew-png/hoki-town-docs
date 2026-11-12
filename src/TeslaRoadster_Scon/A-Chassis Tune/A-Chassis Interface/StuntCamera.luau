--!strict
--[[
	StuntCamera.luau
	Lightweight client camera enhancer for TeslaRoadster_Scon:
	- Smooth speed & boost FOV expansion
	- Gentle roll tilt (default ~28%, clamped <= 28 deg) during wall-climb / ceiling / airborne stunts
	- Preserves default Roblox CameraScript mouse orbit/zoom and restores FOV cleanly on exit
]]

local RunService = game:GetService("RunService")

local RENDER_BIND_NAME = "SconStuntCamera"

local StuntCamera = {}
StuntCamera.__index = StuntCamera

type StuntCameraData = {
	car: Model,
	driveSeat: VehicleSeat,
	tune: { [string]: any },
	units: { [string]: any },
	baseFov: number,
	currentFov: number,
	currentRoll: number,
	currentOffset: Vector3,
	destroyed: boolean,
}

export type StuntCamera = typeof(setmetatable({} :: StuntCameraData, StuntCamera))

function StuntCamera.new(
	car: Model,
	driveSeat: VehicleSeat,
	tune: { [string]: any },
	units: { [string]: any }
): StuntCamera
	local cam = workspace.CurrentCamera
	local initialFov = if cam and cam.FieldOfView >= 50 and cam.FieldOfView <= 85 then cam.FieldOfView else 70

	local data: StuntCameraData = {
		car = car,
		driveSeat = driveSeat,
		tune = tune,
		units = units,
		baseFov = initialFov,
		currentFov = cam and cam.FieldOfView or initialFov,
		currentRoll = 0,
		currentOffset = Vector3.zero,
		destroyed = false,
	}

	local self = setmetatable(data, StuntCamera) :: StuntCamera

	pcall(function()
		RunService:UnbindFromRenderStep(RENDER_BIND_NAME)
	end)

	RunService:BindToRenderStep(RENDER_BIND_NAME, Enum.RenderPriority.Camera.Value + 1, function(dt: number)
		self:_step(dt)
	end)

	return self
end

function StuntCamera._step(self: StuntCamera, dt: number)
	if self.destroyed or not self.car.Parent or not self.driveSeat.Parent then
		return
	end
	if self.driveSeat.Occupant == nil then
		return
	end

	local cam = workspace.CurrentCamera
	if not cam or cam.CameraType == Enum.CameraType.Scriptable then
		return
	end

	local clampedDt = math.clamp(dt, 1 / 240, 0.1)
	local mdivs = (self.units and self.units.Velocity_mdivs) or 3.5714
	local speedKmh = self.driveSeat.AssemblyLinearVelocity.Magnitude / (mdivs / 3.6)
	local speedRatio = math.clamp((speedKmh - 20) / 200, 0, 1)
	local isBoost = self.car:GetAttribute("SconFlightBoostActive") == true

	local targetFov = math.clamp(self.baseFov + speedRatio * 13 + (isBoost and 5 or 0), 50, 92)
	local fovBlend = 1 - math.exp(-6.5 * clampedDt)
	self.currentFov += (targetFov - self.currentFov) * fovBlend
	cam.FieldOfView = self.currentFov

	local wallClimb = self.car:GetAttribute("SconWallClimbActive") == true
	local airborne = self.car:GetAttribute("PiggyCarAirborneWeightReduced") == true
	local carUp = self.driveSeat.CFrame.UpVector
	local camCF = cam.CFrame
	local camLook = camCF.LookVector

	local targetRoll = 0
	if wallClimb or airborne or carUp.Y < 0.85 then
		local projUp = carUp - camLook * carUp:Dot(camLook)
		if projUp.Magnitude > 0.08 then
			local unitCarUp = projUp.Unit
			local rawRoll = math.atan2(camCF.RightVector:Dot(unitCarUp), camCF.UpVector:Dot(unitCarUp))
			local tiltBlend = math.clamp(self.tune.StuntCameraTiltBlend or 0.28, 0, 0.40)
			local maxRoll = math.rad(self.tune.StuntCameraMaxRollDeg or 28)
			targetRoll = math.clamp(rawRoll * tiltBlend, -maxRoll, maxRoll)
		end
	end

	local rollBlend = 1 - math.exp(-6.0 * clampedDt)
	self.currentRoll += (targetRoll - self.currentRoll) * rollBlend

	local targetOffset = if wallClimb then (carUp * 0.75) else Vector3.zero
	self.currentOffset = self.currentOffset:Lerp(targetOffset, rollBlend)

	if math.abs(self.currentRoll) > 0.0015 or self.currentOffset.Magnitude > 0.01 then
		cam.CFrame = (camCF + self.currentOffset) * CFrame.Angles(0, 0, -self.currentRoll)
	end
end

function StuntCamera.Destroy(self: StuntCamera)
	if self.destroyed then
		return
	end
	self.destroyed = true
	pcall(function()
		RunService:UnbindFromRenderStep(RENDER_BIND_NAME)
	end)
	local cam = workspace.CurrentCamera
	if cam and cam.CameraType ~= Enum.CameraType.Scriptable then
		cam.FieldOfView = self.baseFov
	end
end

return StuntCamera
