--!strict
--[[
	SpiderFlightEngine.luau
	Arcade 360-degree Wall-Climbing, Ceiling Adhesion, Crest-Wrapping,
	Stunt Jump / Wall-Jump, and Rocket Flight / Glide solver for TeslaRoadster_Scon.
]]

local RunService = game:GetService("RunService")

local SpiderFlightEngine = {}
SpiderFlightEngine.__index = SpiderFlightEngine

export type EngineContext = {
	car: Model,
	driveSeat: VehicleSeat,
	weightBrick: BasePart,
	tune: { [string]: any },
	units: { [string]: any },
	wheels: { [BasePart]: any },
	wheelGrounded: { [string]: boolean },
	frontLeftWheel: BasePart?,
	frontRightWheel: BasePart?,
	rearLeftWheel: BasePart?,
	rearRightWheel: BasePart?,
	player: Player,
	clearCurbAssist: () -> (),
	getThrottleInput: () -> number,
	getSteerInput: () -> number,
}

export type StepInput = {
	iThrot: number,
	gThrot: number,
	iBrake: number,
	gBrake: number,
	gSteerT: number,
	spaceHeld: boolean,
	isOn: boolean,
	stepClimbActive: boolean,
}

type SpiderFlightEngineData = {
	ctx: EngineContext,
	boostHeld: boolean,
	midAirActive: boolean,
	adhered: boolean,
	wallClimbActive: boolean,
	surfaceNormal: Vector3,
	targetSurfaceNormal: Vector3,
	lastAdheredAt: number,
	isWallSnapTransition: boolean,
	jumpDetachUntil: number,
	lastStuntJumpAt: number,
	airJumpsRemaining: number,
	prevTestJumpAttr: boolean,
	arcadeYawCommand: number,
	arcadeGroundedCount: number,
	frontGroundedCount: number,
	rearGroundedCount: number,
	takeoffAssistUsed: boolean,
	allWheelsGroundedSince: number,
	nextTakeoffAssistAt: number,
	rayParams: RaycastParams,
	totalMass: number,
	worldWeightForce: number,
	physicsAttachment: Attachment,
	physicsForce: VectorForce,
}

export type SpiderFlightEngine = typeof(setmetatable({} :: SpiderFlightEngineData, SpiderFlightEngine))

local function computeTotalVehicleMass(car: Model, weightBrick: BasePart): (number, number, number)
	local ballastMass = weightBrick.Mass
	local total = 0
	for _, desc in car:GetDescendants() do
		if desc:IsA("BasePart") and not desc.Massless then
			total += desc:GetMass()
		end
	end
	if total <= 0 then
		total = weightBrick.AssemblyMass
	end
	local nonBallastMass = math.max(total - ballastMass, 0)
	return ballastMass, nonBallastMass, ballastMass + nonBallastMass
end

local function rotateVectorMinimal(vec: Vector3, fromUp: Vector3, toUp: Vector3): Vector3
	local dot = math.clamp(fromUp:Dot(toUp), -1, 1)
	if dot > 0.999 then
		return vec
	end
	local axis = fromUp:Cross(toUp)
	if axis.Magnitude < 1e-4 then
		return vec
	end
	local angle = math.acos(dot)
	return CFrame.fromAxisAngle(axis.Unit, angle):VectorToWorldSpace(vec)
end

function SpiderFlightEngine.new(ctx: EngineContext): SpiderFlightEngine
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { ctx.car }
	rayParams.RespectCanCollide = true

	local ballastMass, nonBallastMass, totalMass = computeTotalVehicleMass(ctx.car, ctx.weightBrick)
	local wheelGrav: number = if ctx.tune.GravComp and ctx.tune.GravComp > 0
		then ctx.tune.GravComp
		else workspace.Gravity
	local worldWeightForce = ballastMass * workspace.Gravity + nonBallastMass * wheelGrav

	local foundAtt = ctx.weightBrick:FindFirstChild("SconPhysicsAttachment")
	local att: Attachment
	if foundAtt and foundAtt:IsA("Attachment") then
		att = foundAtt
	else
		att = Instance.new("Attachment")
		att.Name = "SconPhysicsAttachment"
		att.Parent = ctx.weightBrick
	end

	local foundVf = ctx.weightBrick:FindFirstChild("SconPhysicsForce")
	local vf: VectorForce
	if foundVf and foundVf:IsA("VectorForce") then
		vf = foundVf
	else
		vf = Instance.new("VectorForce")
		vf.Name = "SconPhysicsForce"
		vf.Parent = ctx.weightBrick
	end
	vf.ApplyAtCenterOfMass = true
	vf.RelativeTo = Enum.ActuatorRelativeTo.World
	vf.Attachment0 = att
	vf.Force = Vector3.zero
	vf.Enabled = true

	local legacyGravComp = ctx.weightBrick:FindFirstChild("#GRAVCOMP")
	if legacyGravComp and legacyGravComp:IsA("VectorForce") then
		legacyGravComp.Enabled = false
		legacyGravComp.Force = Vector3.zero
	end

	local data: SpiderFlightEngineData = {
		ctx = ctx,
		boostHeld = false,
		midAirActive = false,
		adhered = true,
		wallClimbActive = false,
		surfaceNormal = Vector3.yAxis,
		targetSurfaceNormal = Vector3.yAxis,
		lastAdheredAt = os.clock(),
		isWallSnapTransition = false,
		jumpDetachUntil = 0,
		lastStuntJumpAt = 0,
		airJumpsRemaining = ctx.tune.StuntJumpMaxAirJumps or 1,
		prevTestJumpAttr = false,
		arcadeYawCommand = 0,
		arcadeGroundedCount = 0,
		frontGroundedCount = 2,
		rearGroundedCount = 2,
		takeoffAssistUsed = false,
		allWheelsGroundedSince = 0,
		nextTakeoffAssistAt = 0,
		rayParams = rayParams,
		totalMass = totalMass,
		worldWeightForce = worldWeightForce,
		physicsAttachment = att,
		physicsForce = vf,
	}

	-- Ensure no legacy blue thruster flame/glow attachments remain on DriveSeat
	for _, child in ipairs(ctx.driveSeat:GetChildren()) do
		if child.Name == "SconThruster_1" or child.Name == "SconThruster_2" then
			child:Destroy()
		end
	end

	local self = setmetatable(data, SpiderFlightEngine) :: SpiderFlightEngine
	return self
end

function SpiderFlightEngine.SetBoostHeld(self: SpiderFlightEngine, held: boolean)
	self.boostHeld = held
end

function SpiderFlightEngine.IsBoostActive(self: SpiderFlightEngine, isOn: boolean): boolean
	local ctx = self.ctx
	if ctx.tune.BoostEnabled == false or not isOn or ctx.car:GetAttribute("VehiclePowerDisabled") == true then
		return false
	end
	if RunService:IsStudio() and ctx.car:GetAttribute("SconTestBoost") == true then
		return true
	end
	return self.boostHeld
end

function SpiderFlightEngine.ShouldAllowAutoFlip(self: SpiderFlightEngine): boolean
	local upY = self.ctx.driveSeat.CFrame.UpVector.Y
	return not self.adhered
		and upY < 0.25
		and self.ctx.driveSeat.AssemblyLinearVelocity.Magnitude < 14
		and (self.frontGroundedCount + self.rearGroundedCount == 0)
end

function SpiderFlightEngine._getAxlePositions(self: SpiderFlightEngine): (Vector3, Vector3)
	local ctx = self.ctx
	local frontPos = ctx.weightBrick.Position + ctx.driveSeat.CFrame.LookVector * 4.5
	local rearPos = ctx.weightBrick.Position - ctx.driveSeat.CFrame.LookVector * 4.5
	if ctx.frontLeftWheel and ctx.frontRightWheel then
		frontPos = (ctx.frontLeftWheel.Position + ctx.frontRightWheel.Position) * 0.5
	end
	if ctx.rearLeftWheel and ctx.rearRightWheel then
		rearPos = (ctx.rearLeftWheel.Position + ctx.rearRightWheel.Position) * 0.5
	end
	return frontPos, rearPos
end

function SpiderFlightEngine.TriggerStuntJump(self: SpiderFlightEngine, isOn: boolean)
	local ctx = self.ctx
	if ctx.tune.StuntJumpEnabled == false or ctx.driveSeat.Occupant == nil or not isOn then
		return
	end
	local now = os.clock()
	if now - self.lastStuntJumpAt < (ctx.tune.StuntJumpCooldown or 0.45) then
		return
	end
	if not self.adhered and self.airJumpsRemaining <= 0 then
		return
	end

	self.lastStuntJumpAt = now
	if not self.adhered then
		self.airJumpsRemaining = math.max(0, self.airJumpsRemaining - 1)
	end

	local jumpDir = (self.adhered and self.surfaceNormal.Magnitude > 0.1) and self.surfaceNormal.Unit or Vector3.yAxis
	local upImpulse = ctx.tune.StuntJumpUpImpulse or 48
	local fwdImpulse = ctx.tune.StuntJumpForwardImpulse or 14
	local currentVel = ctx.weightBrick.AssemblyLinearVelocity
	local alongJump = currentVel:Dot(jumpDir)
	local targetAlongJump = math.max(alongJump, 0) + upImpulse
	local fwdDir = ctx.driveSeat.CFrame.LookVector
	local deltaVel = jumpDir * (targetAlongJump - alongJump) + fwdDir * fwdImpulse

	ctx.weightBrick:ApplyImpulse(deltaVel * self.totalMass)
	self.jumpDetachUntil = now + 0.28
	self.adhered = false
	self.wallClimbActive = false
	self.midAirActive = true
	self.targetSurfaceNormal = Vector3.yAxis
	ctx.clearCurbAssist()
	ctx.car:SetAttribute("SconWallClimbActive", false)
	ctx.car:SetAttribute("PiggyCarAirborneWeightReduced", true)
end

function SpiderFlightEngine._probeForwardWall(
	self: SpiderFlightEngine,
	frontAxlePos: Vector3,
	carForward: Vector3,
	carUp: Vector3,
	carRight: Vector3,
	forwardSpeed: number
): Vector3?
	local tune = self.ctx.tune
	local baseDist = tune.SpiderForwardProbeDist or 7.5
	local speedScale = tune.SpiderForwardProbeSpeedScale or 0.105
	local maxDist = if forwardSpeed > 32 then 26.0 else baseDist
	local probeDist = math.clamp(baseDist + math.max(0, forwardSpeed) * speedScale, baseDist, maxDist)
	local minWallHeight = tune.SpiderMinWallHeight or 2.6

	local probeOffsets = {
		carUp * 0.60,
		carUp * 1.45,
		carUp * 0.70 + carRight * 1.6,
		carUp * 0.70 - carRight * 1.6,
	}
	for _, offset in ipairs(probeOffsets) do
		local hit = workspace:Raycast(frontAxlePos + offset, carForward * probeDist, self.rayParams)
		if hit then
			local normalDotUp = carUp:Dot(hit.Normal)
			local normalDotFwd = hit.Normal:Dot(carForward)
			if normalDotUp < 0.86 and normalDotFwd < -0.20 then
				if normalDotUp > 0.25 then
					return hit.Normal
				end
				local headroomHit = workspace:Raycast(
					frontAxlePos + carUp * minWallHeight,
					carForward * (hit.Distance + 1.5),
					self.rayParams
				)
				if headroomHit then
					return hit.Normal
				end
			end
		end
	end
	return nil
end

function SpiderFlightEngine._probeCrestWrap(
	self: SpiderFlightEngine,
	frontAxlePos: Vector3,
	carForward: Vector3,
	carUp: Vector3,
	carRight: Vector3
): Vector3?
	if self.ctx.tune.SpiderCrestWrapEnabled == false then
		return nil
	end
	for _, lat in ipairs({ 0, -1.5, 1.5 }) do
		local roofOrigin = frontAxlePos + carForward * 1.5 + carUp * 0.45 + carRight * lat
		local roofDir = (-carUp * 0.80 - carForward * 0.60).Unit
		local roofHit = workspace:Raycast(roofOrigin, roofDir * 5.8, self.rayParams)
		if roofHit and carUp:Dot(roofHit.Normal) > 0.15 then
			return roofHit.Normal
		end
	end
	local backOrigin = frontAxlePos + carForward * 1.6 - carUp * 2.2
	local backDir = (carUp * 0.85 - carForward * 0.50).Unit
	local backHit = workspace:Raycast(backOrigin, backDir * 5.0, self.rayParams)
	if backHit then
		return carForward
	end
	return nil
end

function SpiderFlightEngine.Step(self: SpiderFlightEngine, dt: number, inp: StepInput): (boolean, number, number)
	local ctx = self.ctx
	local tune = ctx.tune
	local now = os.clock()
	local filterList: { Instance } = { ctx.car }
	if ctx.player.Character then
		table.insert(filterList, ctx.player.Character)
	end
	self.rayParams.FilterDescendantsInstances = filterList

	if RunService:IsStudio() then
		local testJump = ctx.car:GetAttribute("SconTestJump") == true
		if testJump and not self.prevTestJumpAttr then
			self:TriggerStuntJump(inp.isOn)
		end
		self.prevTestJumpAttr = testJump
	end

	local groundedCount = 0
	local frontGroundedCount = 0
	local rearGroundedCount = 0
	local frontWheelCount = 0
	local rearWheelCount = 0
	local frontGroundHeight = 0
	local rearGroundHeight = 0
	local frontRampContact = false
	local groundNormalSum = Vector3.zero
	local groundNormalCount = 0

	local carCF = ctx.driveSeat.CFrame
	local carUp = carCF.UpVector
	local carForward = carCF.LookVector
	local carRight = carCF.RightVector
	local stickyRayBonus = self.adhered and 1.35 or 0.52

	for wheel, wheelData in pairs(ctx.wheels) do
		if wheelData.isFront then
			frontWheelCount += 1
		else
			rearWheelCount += 1
		end
		local wheelRadius = math.max(wheel.Size.Y, wheel.Size.Z) * 0.5
		local result = workspace:Raycast(wheel.Position, -carUp * (wheelRadius + stickyRayBonus), self.rayParams)
		ctx.wheelGrounded[wheelData.Name] = (result ~= nil and result.Distance <= wheelRadius + 0.48)
		if result then
			groundedCount += 1
			groundNormalSum += result.Normal
			groundNormalCount += 1
			if wheelData.isFront then
				frontGroundedCount += 1
				frontGroundHeight += result.Position.Y
				if result.Normal.Y >= 0.25 and result.Normal.Y < 0.985 then
					frontRampContact = true
				end
			else
				rearGroundedCount += 1
				rearGroundHeight += result.Position.Y
			end
		end
	end

	self.frontGroundedCount = frontGroundedCount
	self.rearGroundedCount = rearGroundedCount
	self.arcadeGroundedCount = groundNormalCount

	local wheelNormal: Vector3? = if groundNormalCount > 0 and groundNormalSum.Magnitude > 0.01
		then groundNormalSum.Unit
		else nil

	local vel = ctx.weightBrick.AssemblyLinearVelocity
	local forwardSpeed = vel:Dot(carForward)
	local seatThrot = ctx.getThrottleInput()
	local boostActive = self:IsBoostActive(inp.isOn)
	local driveCmd = math.max(inp.iThrot, inp.gThrot, math.clamp(seatThrot, 0, 1), boostActive and 1 or 0)
	local frontAxlePos, _ = self:_getAxlePositions()

	local snapWallNormal: Vector3? = nil
	local crestNormal: Vector3? = nil
	if tune.SpiderClimbEnabled ~= false and now >= self.jumpDetachUntil and ctx.driveSeat.Occupant ~= nil then
		if driveCmd > 0.05 or forwardSpeed > 10 then
			snapWallNormal = self:_probeForwardWall(frontAxlePos, carForward, carUp, carRight, forwardSpeed)
		end
		if
			not snapWallNormal
			and self.adhered
			and self.surfaceNormal.Y < 0.60
			and frontGroundedCount == 0
			and rearGroundedCount > 0
			and driveCmd > 0.05
		then
			crestNormal = self:_probeCrestWrap(frontAxlePos, carForward, carUp, carRight)
		end
	end

	local stickGrace = tune.SpiderStickDetachAirTime or 0.14
	if now >= self.jumpDetachUntil and snapWallNormal then
		self.adhered = true
		self.targetSurfaceNormal = snapWallNormal
		self.isWallSnapTransition = true
		self.lastAdheredAt = now
	elseif now >= self.jumpDetachUntil and crestNormal then
		self.adhered = true
		self.targetSurfaceNormal = crestNormal
		self.isWallSnapTransition = true
		self.lastAdheredAt = now
	elseif now >= self.jumpDetachUntil and groundedCount >= 1 and wheelNormal then
		self.adhered = true
		self.targetSurfaceNormal = wheelNormal
		self.isWallSnapTransition = false
		self.lastAdheredAt = now
	elseif
		now >= self.jumpDetachUntil
		and self.adhered
		and (now - self.lastAdheredAt <= stickGrace)
		and self.surfaceNormal.Y < 0.78
	then
		self.adhered = true
		self.isWallSnapTransition = false
	else
		self.adhered = false
		self.isWallSnapTransition = false
	end

	if self.adhered then
		local alignBlend = 1 - math.exp(-(self.isWallSnapTransition and 22 or 16) * dt)
		local blended = self.surfaceNormal:Lerp(self.targetSurfaceNormal, alignBlend)
		if blended.Magnitude > 0.01 then
			self.surfaceNormal = blended.Unit
		end
	else
		self.surfaceNormal = Vector3.yAxis
		self.targetSurfaceNormal = Vector3.yAxis
	end

	local wasAirborne = self.midAirActive
	self.midAirActive = not self.adhered
	self.wallClimbActive = self.adhered and (self.surfaceNormal.Y < 0.72)

	ctx.car:SetAttribute("SconWallClimbActive", self.wallClimbActive)
	ctx.car:SetAttribute("SconFlightBoostActive", boostActive)
	ctx.car:SetAttribute("PiggyCarAirborneWeightReduced", self.midAirActive)

	if self.midAirActive and not wasAirborne and tune.ArcadeSteering then
		local spin = ctx.driveSeat.AssemblyAngularVelocity
		ctx.driveSeat.AssemblyAngularVelocity = Vector3.new(spin.X, 0, spin.Z)
	end

	local totalWheelCount = frontWheelCount + rearWheelCount
	local frontAverageGroundY = frontGroundedCount > 0 and frontGroundHeight / frontGroundedCount or 0
	local rearAverageGroundY = rearGroundedCount > 0 and rearGroundHeight / rearGroundedCount or 0
	if self.adhered then
		self.airJumpsRemaining = tune.StuntJumpMaxAirJumps or 1
	end
	if totalWheelCount > 0 and groundedCount == totalWheelCount then
		if not self.takeoffAssistUsed or self.allWheelsGroundedSince == 0 then
			self.allWheelsGroundedSince = now
		elseif now - self.allWheelsGroundedSince >= 0.25 then
			self.takeoffAssistUsed = false
		end
	else
		self.allWheelsGroundedSince = 0
	end

	local rampTakeoff = frontRampContact
		and frontGroundedCount > 0
		and rearGroundedCount > 0
		and frontAverageGroundY - rearAverageGroundY >= 0.25
		and now >= self.nextTakeoffAssistAt
	local nosePitchedUpOnRamp = carForward.Y >= 0.08
	local frontLipClearOnRamp = frontWheelCount > 0
		and frontGroundedCount == 0
		and rearGroundedCount > 0
		and nosePitchedUpOnRamp
		and self.surfaceNormal.Y >= 0.55
	local steepRampCrest = rampTakeoff
		and nosePitchedUpOnRamp
		and (frontAverageGroundY - rearAverageGroundY >= 0.35)
		and vel.Y >= 3.5
		and self.surfaceNormal.Y >= 0.55

	if
		(frontLipClearOnRamp or steepRampCrest)
		and not inp.stepClimbActive
		and not self.takeoffAssistUsed
		and now >= self.nextTakeoffAssistAt
		and now >= self.jumpDetachUntil
	then
		self.takeoffAssistUsed = true
		self.allWheelsGroundedSince = 0
		self.nextTakeoffAssistAt = now + 0.8
		local horizontalSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
		local currentVerticalSpeed = vel.Y
		local minLaunchSpeed = tune.AirLaunchMinimumSpeed or 24
		local baseBoost = tune.AirLaunchBaseBoost ~= nil and tune.AirLaunchBaseBoost or 10.0
		local speedScale = tune.AirLaunchSpeedScale ~= nil and tune.AirLaunchSpeedScale or 0.12
		local maxVertSpeed = tune.AirLaunchMaxVerticalSpeed or 44.0
		local requestedBoost = math.min(baseBoost + horizontalSpeed * speedScale, maxVertSpeed)
		if requestedBoost > 0 and horizontalSpeed >= minLaunchSpeed and currentVerticalSpeed > -2 then
			local targetVerticalSpeed = math.min(maxVertSpeed, math.max(0, currentVerticalSpeed) + requestedBoost)
			local verticalBoost = math.max(0, targetVerticalSpeed - currentVerticalSpeed)
			if verticalBoost > 0 then
				local fwdDir = Vector3.new(carForward.X, 0, carForward.Z)
				fwdDir = fwdDir.Magnitude > 0.01 and fwdDir.Unit or carForward
				local maxFwdBoost = tune.AirLaunchForwardBoostMax or 14.0
				local fwdBoost = math.clamp(horizontalSpeed * 0.10, 0, maxFwdBoost)
				ctx.weightBrick:ApplyImpulse((Vector3.yAxis * verticalBoost + fwdDir * fwdBoost) * self.totalMass)
				self.jumpDetachUntil = now + 0.20
				self.adhered = false
				self.midAirActive = true
			end
		end
	end

	local worldCancelForce = Vector3.yAxis * self.worldWeightForce

	if self.adhered then
		local n = self.surfaceNormal
		local adhesionAccel = (n.Y < 0.72) and (tune.SpiderSteepAdhesionGravity or 280)
			or (tune.SpiderAdhesionGravity or 250)
		if self.isWallSnapTransition then
			adhesionAccel = math.max(adhesionAccel, 320)
		end
		local totalForce = worldCancelForce - n * (self.totalMass * adhesionAccel)

		local tangentFwd = carForward - n * carForward:Dot(n)
		if tangentFwd.Magnitude > 0.01 then
			tangentFwd = tangentFwd.Unit
			local climbSpeedCap = tune.SpiderMaxClimbSpeed or 135
			if boostActive then
				climbSpeedCap = math.max(climbSpeedCap, 195)
			end
			if n.Y < 0.78 and driveCmd > 0.05 and inp.iBrake < 0.05 and forwardSpeed < climbSpeedCap then
				local maxClimbStuds =
					math.min((tune.SpeedLimit or 215) * (ctx.units.Velocity_mdivs / 3.6), climbSpeedCap)
				local climbHeadroom = math.clamp(1 - (forwardSpeed / math.max(maxClimbStuds, 1)), 0, 1)
				local assistAccel = (tune.SpiderTangentDriveAssist or 64) * driveCmd * math.max(0.20, climbHeadroom)
				totalForce += tangentFwd * (self.totalMass * assistAccel)
			elseif n.Y < 0.55 and forwardSpeed > climbSpeedCap then
				local excess = forwardSpeed - climbSpeedCap
				totalForce -= tangentFwd * (self.totalMass * math.min(excess * 18, 420))
			end
			if boostActive and inp.iBrake < 0.05 then
				local boostMaxStuds = ((tune.BoostMaxSpeedKmh or 275) * (ctx.units.Velocity_mdivs / 3.6))
				if n.Y < 0.55 then
					boostMaxStuds = math.min(boostMaxStuds, climbSpeedCap)
				end
				if forwardSpeed < boostMaxStuds then
					local boostScale = math.clamp((boostMaxStuds - forwardSpeed) / 60, 0.2, 1)
					totalForce += tangentFwd * (self.totalMass * (tune.BoostGroundAccel or 120) * boostScale)
				end
			end
		end
		self.physicsForce.Force = totalForce
		return false, frontGroundedCount, rearGroundedCount
	end

	-- Airborne / Flight / Soar physics (map-bounded hangtime with crisp landing descent)
	ctx.clearCurbAssist()
	local airGrav = tune.AirborneGravity or 132
	local glideFactor = tune.AirGlideLiftFactor or 0.22
	local glideRatio = math.clamp(math.max(0, forwardSpeed) / 110, 0, 1)
	local ascentGlide = (vel.Y > -8) and (airGrav * glideFactor * glideRatio * (driveCmd > 0.05 and 1 or 0.5)) or 0
	local descentPull = (not boostActive and vel.Y < -8) and (airGrav * 1.20) or airGrav
	local effectiveAirGrav = math.max(0, descentPull - ascentGlide)
	local airForce = worldCancelForce - Vector3.yAxis * (self.totalMass * effectiveAirGrav)

	if boostActive then
		local curSpeed = vel.Magnitude
		local maxAirSpeed = tune.BoostAirMaxSpeed or 195
		local maxVertSpeed = tune.AirMaxVerticalSpeed or 48
		local maxAlt = tune.AirMaxAltitude or 390
		local posY = ctx.weightBrick.Position.Y
		local altFade = math.clamp((maxAlt - posY) / 70, 0, 1)
		local thrustScale = curSpeed < maxAirSpeed and math.clamp((maxAirSpeed - curSpeed) / 50, 0.15, 1) or 0
		local thrustDir = carForward
		if altFade <= 0.15 and thrustDir.Y > 0 then
			thrustDir = Vector3.new(thrustDir.X, thrustDir.Y * altFade, thrustDir.Z)
			if thrustDir.Magnitude > 0.01 then
				thrustDir = thrustDir.Unit
			end
		end
		airForce += thrustDir * (self.totalMass * (tune.BoostAirForwardAccel or 62) * thrustScale)
		if curSpeed > maxAirSpeed then
			airForce -= vel.Unit * (self.totalMass * math.min((curSpeed - maxAirSpeed) * 1.4, 90))
		end

		if posY < maxAlt and vel.Y < maxVertSpeed then
			local liftScale = math.clamp((maxVertSpeed - vel.Y) / 28, 0, 1) * altFade
			airForce += Vector3.yAxis * (self.totalMass * (tune.BoostAirLiftAccel or 80) * liftScale)
		end
	elseif vel.Magnitude > 175 then
		airForce -= vel.Unit * (self.totalMass * math.min((vel.Magnitude - 175) * 1.8, 120))
	end
	self.physicsForce.Force = airForce

	local pitchRate = tune.AirPitchRate or 2.5
	local yawRate = tune.AirYawRate or 2.6
	local rollRate = tune.AirRollRate or 5.5

	local pitchCmd = 0
	if inp.iBrake > 0.1 or inp.gBrake > 0.1 then
		pitchCmd = pitchRate
	elseif inp.iThrot > 0.1 or inp.gThrot > 0.1 then
		local currentPitch = math.asin(math.clamp(carForward.Y, -1, 1))
		local targetGlidePitch = boostActive and math.rad(8) or math.rad(1.5)
		pitchCmd = math.clamp((targetGlidePitch - currentPitch) * 3.2, -1.6, 1.6)
	else
		local downHit = workspace:Raycast(ctx.weightBrick.Position, -Vector3.yAxis * 16, self.rayParams)
		if downHit then
			local levelAxis = carUp:Cross(downHit.Normal)
			pitchCmd = math.clamp(levelAxis:Dot(carRight) * 3.0, -1.5, 1.5)
		else
			local currentPitch = math.asin(math.clamp(carForward.Y, -1, 1))
			pitchCmd = math.clamp(-currentPitch * 1.5, -1.0, 1.0)
		end
	end

	local steerIn = inp.gSteerT
	if math.abs(steerIn) < 0.05 then
		steerIn = ctx.getSteerInput()
	end
	local currentRoll = math.asin(math.clamp(carRight.Y, -1, 1))
	local rollCmd = inp.spaceHeld and (-steerIn * rollRate)
		or math.clamp((math.rad(steerIn * 24) - currentRoll) * 4.0, -2.5, 2.5)
	local yawCmd = (not inp.spaceHeld) and (-steerIn * yawRate) or 0

	local localAngVel = Vector3.new(pitchCmd, yawCmd, rollCmd)
	local worldAngVel = carCF:VectorToWorldSpace(localAngVel)
	local lerpFactor = math.min(dt * 7.5, 1)
	ctx.driveSeat.AssemblyAngularVelocity = ctx.driveSeat.AssemblyAngularVelocity:Lerp(worldAngVel, lerpFactor)

	return true, frontGroundedCount, rearGroundedCount
end

function SpiderFlightEngine.StepSurfaceSteering(self: SpiderFlightEngine, dt: number, gSteerC: number)
	local ctx = self.ctx
	local tune = ctx.tune
	if not tune.ArcadeSteering or ctx.driveSeat.Occupant == nil then
		return
	end
	if self.midAirActive then
		self.arcadeYawCommand = 0
		return
	end

	local n = self.surfaceNormal.Magnitude > 0.01 and self.surfaceNormal.Unit or Vector3.yAxis
	local velocity = ctx.driveSeat.AssemblyLinearVelocity
	local normalVelMag = velocity:Dot(n)
	local planarVelocity = velocity - n * normalVelMag
	local planarSpeed = planarVelocity.Magnitude

	local speedKmh = planarSpeed / (ctx.units.Velocity_mdivs / 3.6)
	local speedRatio = math.clamp(speedKmh / math.max(tune.ArcadeSteerFullSpeedKmh, 1), 0, 1)
	local turnRate = tune.ArcadeSteerLowSpeedDegPerSec
		+ (tune.ArcadeSteerHighSpeedDegPerSec - tune.ArcadeSteerLowSpeedDegPerSec) * speedRatio

	local minMove = math.max(tune.ArcadeSteerMinMoveStudsPerSec, 0)
	local fullMove = math.max(tune.ArcadeSteerFullMoveStudsPerSec, minMove + 0.01)
	local moveRatio = math.clamp((planarSpeed - minMove) / (fullMove - minMove), 0, 1)
	local moveBlend = moveRatio * moveRatio * (3 - 2 * moveRatio)

	local currentAng = ctx.driveSeat.AssemblyAngularVelocity
	local yawRate
	if math.abs(gSteerC) > 0.01 and moveBlend > 0 then
		local reverse = velocity:Dot(ctx.driveSeat.CFrame.LookVector) < -3 and -1 or 1
		local targetYaw = -gSteerC * reverse * math.rad(turnRate) * moveBlend
		local response = 1 - math.exp(-math.max(tune.ArcadeSteerResponse, 0) * dt)
		self.arcadeYawCommand += (targetYaw - self.arcadeYawCommand) * response
		yawRate = self.arcadeYawCommand
	else
		local currentYaw = currentAng:Dot(n)
		local yawDamping = (self.isWallSnapTransition or self.wallClimbActive) and 32
			or math.max(tune.ArcadeSteerReleaseDamping, 0)
		yawRate = currentYaw * math.exp(-yawDamping * dt)
		self.arcadeYawCommand = yawRate
	end

	local carCF = ctx.driveSeat.CFrame
	local carUp = carCF.UpVector
	local carRight = carCF.RightVector
	local carForward = carCF.LookVector

	local alignAxis = carUp:Cross(n)
	local alignRate = self.isWallSnapTransition and (tune.SpiderSnapRate or 34.0) or (tune.SpiderAlignRate or 22.0)
	local maxAlignSpeed = self.isWallSnapTransition and 18.0 or 9.0
	local pitchError = alignAxis:Dot(carRight)
	local rollError = alignAxis:Dot(carForward)
	local desiredPitchRate = math.clamp(pitchError * alignRate, -maxAlignSpeed, maxAlignSpeed)
	local desiredRollRate = math.clamp(rollError * alignRate, -maxAlignSpeed, maxAlignSpeed)

	local curPitchRate = currentAng:Dot(carRight)
	local curRollRate = currentAng:Dot(carForward)
	local angBlend = 1 - math.exp(-math.max(tune.ArcadeRollDamping or 10, 6) * dt)
	local nextPitchRate = curPitchRate + (desiredPitchRate - curPitchRate) * angBlend
	local nextRollRate = curRollRate + (desiredRollRate - curRollRate) * angBlend

	ctx.driveSeat.AssemblyAngularVelocity = carRight * nextPitchRate + carForward * nextRollRate + n * yawRate

	if self.isWallSnapTransition and carUp:Dot(self.targetSurfaceNormal) < 0.88 and velocity.Magnitude > 6 then
		local desiredClimbDir = rotateVectorMinimal(carForward, carUp, self.targetSurfaceNormal)
		if desiredClimbDir.Magnitude > 0.01 then
			desiredClimbDir = desiredClimbDir.Unit
			local redirectBlend = math.min(1, dt * 18)
			local preservedSpeed = math.max(velocity.Magnitude * 0.94, planarSpeed, 34)
			local targetVel = desiredClimbDir * preservedSpeed - self.targetSurfaceNormal * 16
			ctx.driveSeat.AssemblyLinearVelocity = velocity:Lerp(targetVel, redirectBlend)
		end
	elseif self.arcadeGroundedCount >= 1 and planarSpeed > minMove then
		local follow = math.clamp(tune.ArcadeVelocityFollow, 0, 1)
		if math.abs(gSteerC) > 0.01 then
			planarVelocity = CFrame.fromAxisAngle(n, yawRate * dt * follow):VectorToWorldSpace(planarVelocity)
		end
		local tangentForward = carForward - n * carForward:Dot(n)
		local tangentRight = carRight - n * carRight:Dot(n)
		if tangentRight.Magnitude > 0.01 and tangentForward.Magnitude > 0.01 then
			tangentForward = tangentForward.Unit
			tangentRight = tangentRight.Unit
			local rearAxle: Vector3? = if ctx.rearLeftWheel and ctx.rearRightWheel
				then (ctx.rearLeftWheel.Position + ctx.rearRightWheel.Position) * 0.5
				else nil
			local pivotDistance = if rearAxle
				then math.clamp((ctx.driveSeat.Position - rearAxle):Dot(tangentForward), 0, 20)
				else 0
			local pivotVelocity = n:Cross(tangentForward * pivotDistance) * yawRate
			local targetSidewaysSpeed = pivotVelocity:Dot(tangentRight)
			local sideError = planarVelocity:Dot(tangentRight) - targetSidewaysSpeed
			local grip = 1 - math.exp(-math.max(tune.ArcadeLateralGrip, 0) * dt)
			planarVelocity -= tangentRight * sideError * grip
		end
		ctx.driveSeat.AssemblyLinearVelocity = planarVelocity + n * normalVelMag
	end
end

function SpiderFlightEngine.ResetOnExit(self: SpiderFlightEngine)
	self.boostHeld = false
	self.adhered = false
	self.wallClimbActive = false
	if self.physicsForce and self.physicsForce.Parent then
		self.physicsForce.Force = Vector3.zero
	end
	if self.ctx.car and self.ctx.car.Parent then
		self.ctx.car:SetAttribute("SconWallClimbActive", false)
		self.ctx.car:SetAttribute("SconFlightBoostActive", false)
	end
end

function SpiderFlightEngine.Destroy(self: SpiderFlightEngine)
	self:ResetOnExit()
	if self.physicsForce and self.physicsForce.Parent then
		self.physicsForce.Enabled = false
	end
end

return SpiderFlightEngine
