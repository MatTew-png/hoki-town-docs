local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local car = script.Parent
local seat = car:WaitForChild("DriveSeat")
local guiTemplate = car:WaitForChild("CarStatusGui")
-- ProximityPrompt for driver entry: Press [E] to sit in DriveSeat
local drivePrompt = seat:WaitForChild("DrivePrompt", 5) :: ProximityPrompt?
if not drivePrompt then
	drivePrompt = Instance.new("ProximityPrompt")
	drivePrompt.Name = "DrivePrompt"
	drivePrompt.ObjectText = "Tesla Roadster"
	drivePrompt.ActionText = "ขับรถ (Drive)"
	drivePrompt.KeyboardKeyCode = Enum.KeyCode.E
	drivePrompt.HoldDuration = 0
	drivePrompt.MaxActivationDistance = 12
	drivePrompt.RequiresLineOfSight = false
	drivePrompt.Parent = seat
end

drivePrompt.Triggered:Connect(function(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and not seat.Occupant then
		seat:Sit(hum)
	end
end)

-- Hide the four suspension shock visuals without changing their physics.
local wheels = car:WaitForChild("Wheels")
local function hideShockVisual(instance: Instance)
	if instance:IsA("SpringConstraint") then
		instance.Visible = false
		instance:GetPropertyChangedSignal("Visible"):Connect(function()
			if instance.Visible then instance.Visible = false end
		end)
	elseif instance:IsA("BasePart") then
		local name = string.lower(instance.Name)
		if string.find(name, "shock", 1, true)
			or string.find(name, "spring", 1, true)
			or string.find(name, "damper", 1, true)
			or string.find(name, "coil", 1, true) then
			instance.Transparency = 1
			instance.LocalTransparencyModifier = 1
			instance:GetPropertyChangedSignal("Transparency"):Connect(function()
				if instance.Transparency < 1 then instance.Transparency = 1 end
			end)
			instance:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
				if instance.LocalTransparencyModifier < 1 then instance.LocalTransparencyModifier = 1 end
			end)
		end
	end
end

for _, instance in ipairs(wheels:GetDescendants()) do
	hideShockVisual(instance)
end
wheels.DescendantAdded:Connect(hideShockVisual)

local MAX_HEALTH = 100
local MAX_FUEL = 100

-- Editable on the TeslaRoadster model in Properties > Attributes.
local defaults = {
	ImpactSpeed1 = 12, ImpactDamage1 = 2,
	ImpactSpeed2 = 25, ImpactDamage2 = 5,
	ImpactSpeed3 = 40, ImpactDamage3 = 12,
	ImpactSpeed4 = 60, ImpactDamage4 = 22,
	ImpactSpeed5 = 85, ImpactDamage5 = 35,
	FuelDrainStartSpeed = 4,
	FuelDrainBasePerSecond = 0.01,
	FuelDrainPerStudPerSecond = 0.0002,
}
for name, value in pairs(defaults) do
	if car:GetAttribute(name) == nil then car:SetAttribute(name, value) end
end

if car:GetAttribute("MaxHealth") == nil then car:SetAttribute("MaxHealth", MAX_HEALTH) end
if car:GetAttribute("Health") == nil then car:SetAttribute("Health", MAX_HEALTH) end
if car:GetAttribute("MaxFuel") == nil then car:SetAttribute("MaxFuel", MAX_FUEL) end
if car:GetAttribute("Fuel") == nil then car:SetAttribute("Fuel", MAX_FUEL) end

-- Match the drive cutoff to the GUI's rounded fuel percentage. This disables
-- power as soon as the display would read 0%, and restores it after refueling.
local function updatePowerForFuel()
	local fuel = math.max(0, tonumber(car:GetAttribute("Fuel")) or 0)
	local maxFuel = math.max(0.001, tonumber(car:GetAttribute("MaxFuel")) or MAX_FUEL)
	local displayedPercent = math.floor((fuel / maxFuel) * 100 + 0.5)
	car:SetAttribute("VehiclePowerDisabled", displayedPercent <= 0)
end

car:GetAttributeChangedSignal("Fuel"):Connect(updatePowerForFuel)
updatePowerForFuel()

-- Keep the original custom GUI as a disabled template inside the car.
guiTemplate.Enabled = false
guiTemplate.ResetOnSpawn = false

local currentPlayer: Player? = nil
local currentGui: ScreenGui? = nil

local function removeGui(player: Player?)
	if player then
		local playerGui = player:FindFirstChildOfClass("PlayerGui")
		if playerGui then
			local existing = playerGui:FindFirstChild(car.Name .. "StatusGui")
			if existing then existing:Destroy() end
		end
	end
	currentGui = nil
end

local function updateOccupant()
	local humanoid = seat.Occupant
	local newPlayer = humanoid and Players:GetPlayerFromCharacter(humanoid.Parent) or nil
	if currentPlayer == newPlayer then return end

	removeGui(currentPlayer)
	currentPlayer = newPlayer
	if not newPlayer then return end

	task.spawn(function()
		local playerGui = newPlayer:WaitForChild("PlayerGui", 10)
		if not playerGui or currentPlayer ~= newPlayer or not car.Parent then return end

		local oldGui = playerGui:FindFirstChild(car.Name .. "StatusGui")
		if oldGui then oldGui:Destroy() end

		local screen = guiTemplate:Clone()
		screen.Name = car.Name .. "StatusGui"
		screen.Enabled = true
		screen.ResetOnSpawn = false

		local reference = Instance.new("ObjectValue")
		reference.Name = "VehicleRef"
		reference.Value = car
		reference.Parent = screen

		screen.Parent = playerGui
		currentGui = screen
	end)
end

seat:GetPropertyChangedSignal("Occupant"):Connect(updateOccupant)
Players.PlayerRemoving:Connect(function(player)
	if player == currentPlayer then
		removeGui(player)
		currentPlayer = nil
	end
end)
updateOccupant()

local impactFolder = car:WaitForChild("Body"):FindFirstChild("ImpactSensors")
local lastImpactTime = 0
local IMPACT_COOLDOWN = 0.65
local MIN_IMPACT_SPEED = 12 -- studs/second; filters slow rubbing while catching low-speed crashes
local lastVehicleVelocity = seat.AssemblyLinearVelocity

RunService.Heartbeat:Connect(function()
	if seat.Parent then
		lastVehicleVelocity = seat.AssemblyLinearVelocity
	end
end)

local supportRayParams = RaycastParams.new()
supportRayParams.FilterType = Enum.RaycastFilterType.Exclude
supportRayParams.FilterDescendantsInstances = { car }
supportRayParams.RespectCanCollide = true

local function isSupportedByRamp(): boolean
	local wheels = car:FindFirstChild("Wheels")
	if not wheels then return false end

	local inclinedWheelCount = 0
	for _, wheel in ipairs(wheels:GetChildren()) do
		if not wheel:IsA("BasePart") then continue end
		local radius = math.max(wheel.Size.Y, wheel.Size.Z) * 0.5
		local result = workspace:Raycast(
			wheel.Position + Vector3.yAxis * 0.2,
			-Vector3.yAxis * (radius + 1.25),
			supportRayParams
		)
		if result and result.Normal.Y > 0.05 and result.Normal.Y < 0.995 then
			inclinedWheelCount += 1
		end
	end
	return inclinedWheelCount >= 2
end

local function isRampGeometry(part: BasePart): boolean
	if part:IsA("WedgePart") then return true end
	local ancestor: Instance? = part
	while ancestor and ancestor ~= workspace do
		if string.find(string.lower(ancestor.Name), "ramp", 1, true) then
			return true
		end
		ancestor = ancestor.Parent
	end
	return false
end

local function getImpactDamage(speed: number): number
	local tiers = {}
	for i = 1, 5 do
		table.insert(tiers, {
			speed = tonumber(car:GetAttribute("ImpactSpeed" .. i)) or defaults["ImpactSpeed" .. i],
			damage = math.max(0, tonumber(car:GetAttribute("ImpactDamage" .. i)) or defaults["ImpactDamage" .. i]),
		})
	end
	table.sort(tiers, function(a, b) return a.speed < b.speed end)
	if speed < tiers[1].speed then return 0 end
	for i = 2, #tiers do
		local lower, upper = tiers[i - 1], tiers[i]
		if speed <= upper.speed then
			local span = upper.speed - lower.speed
			if span <= 0 then return upper.damage end
			local alpha = math.clamp((speed - lower.speed) / span, 0, 1)
			return lower.damage + (upper.damage - lower.damage) * alpha
		end
	end
	return tiers[#tiers].damage
end

local function processImpact(sourcePart: BasePart, otherPart: BasePart)
	if otherPart:IsDescendantOf(car) or not otherPart.CanCollide then return end
	local otherModel = otherPart:FindFirstAncestorOfClass("Model")
	if otherModel and otherModel:FindFirstChildOfClass("Humanoid") then return end
	if isRampGeometry(otherPart) then return end

	local now = os.clock()
	if now - lastImpactTime < IMPACT_COOLDOWN then return end

	local relativeVelocity = lastVehicleVelocity - otherPart.AssemblyLinearVelocity
	local carLook = seat.CFrame.LookVector
	-- Only the dedicated front/rear sensors report damage. Measure speed toward
	-- that end of the car directly, so a missed surface-normal ray cannot cancel it.
	local sensorDirection = sourcePart.Name == "Rear" and -carLook or carLook
	local horizontalDirection = Vector3.new(sensorDirection.X, 0, sensorDirection.Z)
	if horizontalDirection.Magnitude < 0.1 then return end
	horizontalDirection = horizontalDirection.Unit
	local closingSpeed = relativeVelocity:Dot(horizontalDirection)

	-- Suppress regular-part ramps only while the car is clearly climbing them.
	-- A wall hit is still counted even if wheels happen to be on an incline.
	if isSupportedByRamp() and sensorDirection.Y > 0.35 then return end
	if closingSpeed < MIN_IMPACT_SPEED then return end

	local damage = getImpactDamage(closingSpeed)
	if damage <= 0 then return end

	lastImpactTime = now
	car:SetAttribute("Health", math.max(0, (tonumber(car:GetAttribute("Health")) or MAX_HEALTH) - damage))
end

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude
overlapParams.FilterDescendantsInstances = { car }
overlapParams.RespectCanCollide = true

local impactSensors = {}
if impactFolder then
	for _, sensor in ipairs(impactFolder:GetChildren()) do
		if sensor:IsA("BasePart") then
			-- Keep damage sensing on the dedicated front/rear sensors only.
			sensor.CanTouch = true
			table.insert(impactSensors, sensor)
			sensor.Touched:Connect(function(otherPart)
				if otherPart:IsA("BasePart") then processImpact(sensor, otherPart) end
			end)
		end
	end
end

-- Dedicated sensor bounds detect queryable walls even when their CanTouch is
-- disabled. Wheels are deliberately excluded so curbs and ramps cannot trigger damage.
task.spawn(function()
	while car.Parent do
		for _, sensor in ipairs(impactSensors) do
			if sensor.Parent then
				local querySize = sensor.Size + Vector3.new(0.5, 0.5, 4)
				for _, otherPart in ipairs(workspace:GetPartBoundsInBox(sensor.CFrame, querySize, overlapParams)) do
					processImpact(sensor, otherPart)
				end
			end
		end
		task.wait(0.05)
	end
end)

-- Drain fuel gradually only while an occupied car is moving.
while car.Parent do
	local dt = task.wait(0.25)
	local fuelDrainStartSpeed = math.max(0, tonumber(car:GetAttribute("FuelDrainStartSpeed")) or defaults.FuelDrainStartSpeed)
	if seat.Occupant and seat.AssemblyLinearVelocity.Magnitude > fuelDrainStartSpeed then
		local fuel = tonumber(car:GetAttribute("Fuel")) or MAX_FUEL
		if fuel > 0 then
			local speed = seat.AssemblyLinearVelocity.Magnitude
			local baseDrain = math.max(0, tonumber(car:GetAttribute("FuelDrainBasePerSecond")) or defaults.FuelDrainBasePerSecond)
			local speedDrain = math.max(0, tonumber(car:GetAttribute("FuelDrainPerStudPerSecond")) or defaults.FuelDrainPerStudPerSecond)
			local drainPerSecond = baseDrain + speed * speedDrain
			car:SetAttribute("Fuel", math.max(0, fuel - drainPerSecond * dt))
		end
	end
end
