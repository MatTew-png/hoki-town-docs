--!strict
--[[
    RaycastChassisServer.server.luau
    HOKI TOWN - Vehicle Engineering
    Hybrid Raycast Chassis Server Authority: upgrade stat sheet, assembly calibration,
    entry/exit, HUD lifecycle, repair, crash damage, and per-wheel tire puncture hooks.
]]

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VehicleStats = require(ReplicatedStorage:WaitForChild("VehicleStats"))

local car = script.Parent :: Model
VehicleStats.EnsureDefaultAttributes(car)
pcall(function()
	car.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
end)

local seat = car:FindFirstChild("DriveSeat") or car:FindFirstChild("DriveSeat", true)
assert(seat ~= nil and seat:IsA("VehicleSeat"), "[RaycastChassisServer] Missing DriveSeat under " .. car:GetFullName())
local driveSeat = seat :: VehicleSeat

local chassisCollider = car:FindFirstChild("Chassis_Collider", true) :: BasePart?

local function clamp(value: number, minimum: number, maximum: number): number
	return math.clamp(value, minimum, maximum)
end

-- ---------------------------------------------------------------------------
-- 1. Root Part & Hierarchy Calibration
--    DriveSeat is the assembly root. Every cosmetic body part is massless,
--    collisionless, and welded to it so the whole vehicle moves as one assembly.
-- ---------------------------------------------------------------------------
driveSeat.Disabled = false
driveSeat.CanCollide = false
driveSeat.CanTouch = true
driveSeat.Transparency = 1
driveSeat.Anchored = true

local function isWeldedToSeat(part: BasePart): boolean
	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("WeldConstraint") and (child.Part0 == driveSeat or child.Part1 == driveSeat) then
			return true
		end
	end
	return false
end

local function weldToSeat(part: BasePart)
	part.Anchored = false
	part.CanCollide = false
	part.Massless = true
	if not isWeldedToSeat(part) then
		local weld = Instance.new("WeldConstraint")
		weld.Name = "ChassisWeld"
		weld.Part0 = driveSeat
		weld.Part1 = part
		weld.Parent = part
	end
end

local function calibrateBody(container: Instance)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("BasePart") then
			if child ~= driveSeat and child ~= chassisCollider then
				weldToSeat(child :: BasePart)
			end
		elseif child:IsA("Model") or child:IsA("Folder") then
			if child.Name ~= "Wheels" then
				calibrateBody(child)
			end
		end
	end
end

calibrateBody(car)

-- Chassis_Collider (when present) provides physical bounds and collision for crashes/walls.
if chassisCollider and chassisCollider ~= driveSeat then
	chassisCollider.Anchored = false
	chassisCollider.CanCollide = true
	chassisCollider.Massless = false
	if PhysicsService:IsCollisionGroupRegistered("Vehicles") then
		chassisCollider.CollisionGroup = "Vehicles"
	end
	if not isWeldedToSeat(chassisCollider) then
		local weld = Instance.new("WeldConstraint")
		weld.Name = "ChassisWeld"
		weld.Part0 = driveSeat
		weld.Part1 = chassisCollider
		weld.Parent = chassisCollider
	end
end

-- ---------------------------------------------------------------------------
-- 2. Cosmetic Wheels Un-welding
--    Wheels stay physically separate (Anchored) so the client can CFrame them for
--    steer/spin/suspension without being driven by chassis physics. All welds
--    connecting wheel/tire/rotor parts to calipers or the chassis are destroyed.
-- ---------------------------------------------------------------------------
local function unweldBasePart(part: BasePart)
	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("Weld") or child:IsA("WeldConstraint") then
			child:Destroy()
		end
	end
	part.Anchored = true
	part.CanCollide = false
	part.Massless = true
end

local wheelsFolder = car:FindFirstChild("Wheels")
if wheelsFolder then
	for _, part in ipairs(wheelsFolder:GetDescendants()) do
		if part:IsA("BasePart") then
			unweldBasePart(part :: BasePart)
		end
	end
end

-- Handle car-level calipers (direct BasePart wheel layouts where Caliper_XX sits
-- at the model root rather than inside a Wheels.XX model).
for _, caliperName in ipairs({ "Caliper_FL", "Caliper_FR", "Caliper_RL", "Caliper_RR" }) do
	local caliper = car:FindFirstChild(caliperName, true)
	if caliper and caliper:IsA("BasePart") then
		unweldBasePart(caliper :: BasePart)
	end
end

-- ---------------------------------------------------------------------------
-- 3. Remotes, Attributes & GodMode
-- ---------------------------------------------------------------------------
local function ensureRemoteEvent(name: string): RemoteEvent
	local existing = car:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = car
	return remote
end

local function ensureBindableEvent(name: string): BindableEvent
	local existing = car:FindFirstChild(name)
	if existing and existing:IsA("BindableEvent") then
		return existing
	end
	local bindable = Instance.new("BindableEvent")
	bindable.Name = name
	bindable.Parent = car
	return bindable
end

local repairRemote = ensureRemoteEvent("VehicleRepairRequest")

if car:GetAttribute("GodMode") == nil then
	car:SetAttribute("GodMode", true)
end
if car:GetAttribute("MaxFuel") == nil then
	car:SetAttribute("MaxFuel", 100)
end
if car:GetAttribute("Fuel") == nil then
	car:SetAttribute("Fuel", 100)
end

-- MaxHealth is derived from ArmourTier and kept in sync whenever the tier changes.
local function syncMaxHealth()
	local maxHealth = VehicleStats.Compute(car).MaxHealth
	car:SetAttribute("MaxHealth", maxHealth)
	local current = tonumber(car:GetAttribute("Health"))
	if current == nil or current > maxHealth then
		car:SetAttribute("Health", maxHealth)
	end
end
syncMaxHealth()
car:GetAttributeChangedSignal("ArmourTier"):Connect(syncMaxHealth)

-- ---------------------------------------------------------------------------
-- 4. ProximityPrompt Entry
-- ---------------------------------------------------------------------------
local function configurePrompt(prompt: ProximityPrompt)
	prompt.ObjectText = "Tesla Roadster"
	prompt.ActionText = "ขับรถ (Drive)"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
end

local existingPrompt = driveSeat:FindFirstChildOfClass("ProximityPrompt")
local prompt: ProximityPrompt
if existingPrompt then
	prompt = existingPrompt
else
	prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DrivePrompt"
	prompt.Parent = driveSeat
end
configurePrompt(prompt)

prompt.Triggered:Connect(function(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and not driveSeat.Occupant then
		driveSeat:Sit(humanoid)
	end
end)

-- ---------------------------------------------------------------------------
-- 5. Network Ownership & Seat Occupant
-- ---------------------------------------------------------------------------
local seatNoCollisions: { NoCollisionConstraint } = {}

local function clearSeatNoCollisions()
	for _, constraint in ipairs(seatNoCollisions) do
		constraint:Destroy()
	end
	table.clear(seatNoCollisions)
end

local function attachSeatNoCollisions(character: Model)
	if not chassisCollider then
		return
	end
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local constraint = Instance.new("NoCollisionConstraint")
			constraint.Part0 = chassisCollider
			constraint.Part1 = descendant
			constraint.Parent = chassisCollider
			table.insert(seatNoCollisions, constraint)
		end
	end
end

local function updateNetworkOwnership(occupant: Humanoid?)
	local root: BasePart = driveSeat.AssemblyRootPart
	if occupant then
		local character = occupant.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			clearSeatNoCollisions()
			local playerCharacter = player.Character
			if playerCharacter then
				attachSeatNoCollisions(playerCharacter)
			end
			driveSeat.Anchored = false
			root.Anchored = false
			pcall(function()
				root:SetNetworkOwner(player)
			end)
		end
	else
		clearSeatNoCollisions()
		task.wait(0.15)
		if not driveSeat.Occupant then
			pcall(function()
				root:SetNetworkOwner(nil)
			end)
			driveSeat.AssemblyLinearVelocity = Vector3.zero
			driveSeat.AssemblyAngularVelocity = Vector3.zero
			driveSeat.Anchored = true
		end
	end
end

driveSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
	updateNetworkOwnership(driveSeat.Occupant)
end)

car.Destroying:Connect(clearSeatNoCollisions)
car.AncestryChanged:Connect(function()
	if car.Parent == nil then
		clearSeatNoCollisions()
	end
end)

-- ---------------------------------------------------------------------------
-- 6. HUD Lifecycle (CarStatusGui)
-- ---------------------------------------------------------------------------
local guiTemplate = car:FindFirstChild("CarStatusGui") :: ScreenGui?
if guiTemplate then
	guiTemplate.Enabled = false
	guiTemplate.ResetOnSpawn = false

	local currentPlayer: Player? = nil
	local function updateOccupant()
		local humanoid = driveSeat.Occupant
		local newPlayer = humanoid and Players:GetPlayerFromCharacter(humanoid.Parent) or nil

		if not humanoid then
			prompt.Enabled = true
			if currentPlayer then
				local pg = currentPlayer:FindFirstChildOfClass("PlayerGui")
				if pg then
					local existing = pg:FindFirstChild(car.Name .. "StatusGui")
					if existing then
						existing:Destroy()
					end
				end
				currentPlayer = nil
			end
			return
		end

		prompt.Enabled = false
		if currentPlayer == newPlayer then
			return
		end

		if currentPlayer then
			local pg = currentPlayer:FindFirstChildOfClass("PlayerGui")
			if pg then
				local existing = pg:FindFirstChild(car.Name .. "StatusGui")
				if existing then
					existing:Destroy()
				end
			end
		end

		currentPlayer = newPlayer

		if newPlayer then
			task.spawn(function()
				local pg = newPlayer:WaitForChild("PlayerGui", 10)
				if not pg or currentPlayer ~= newPlayer or not car.Parent then
					return
				end

				local screen = guiTemplate:Clone()
				screen.Name = car.Name .. "StatusGui"
				screen.Enabled = true
				screen.ResetOnSpawn = false

				local ref = Instance.new("ObjectValue")
				ref.Name = "VehicleRef"
				ref.Value = car
				ref.Parent = screen

				screen.Parent = pg
			end)
		end
	end

	driveSeat:GetPropertyChangedSignal("Occupant"):Connect(updateOccupant)
	Players.PlayerRemoving:Connect(function(player)
		if player == currentPlayer then
			currentPlayer = nil
		end
	end)
	updateOccupant()
end

-- ---------------------------------------------------------------------------
-- 7. Repair System ([R] / RemoteEvent)
-- ---------------------------------------------------------------------------
local function performFullRepair()
	local maxHealth = VehicleStats.Compute(car).MaxHealth
	car:SetAttribute("Health", maxHealth)
	car:SetAttribute("Fuel", 100)
	car:SetAttribute("TirePopped_FL", false)
	car:SetAttribute("TirePopped_FR", false)
	car:SetAttribute("TirePopped_RL", false)
	car:SetAttribute("TirePopped_RR", false)
end

repairRemote.OnServerEvent:Connect(function(player: Player)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	local dist = (hrp.Position - driveSeat.Position).Magnitude
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if dist <= 24 or driveSeat.Occupant == humanoid then
		performFullRepair()
	end
end)

-- ---------------------------------------------------------------------------
-- 8. Per-Wheel Tire Puncture Hook (police chase ready)
--    Future gunfire scripts can either fire car.DamageTire with a wheel key, or
--    set car:SetAttribute("TirePopped_RL", true) directly. The client physics
--    reacts to the attribute change instantly.
-- ---------------------------------------------------------------------------
local damageTireEvent = ensureBindableEvent("DamageTire")

damageTireEvent.Event:Connect(function(key: unknown)
	if typeof(key) == "string" and (key == "FL" or key == "FR" or key == "RL" or key == "RR") then
		car:SetAttribute("TirePopped_" .. key, true)
	end
end)

-- ---------------------------------------------------------------------------
-- 9. Crash Impact Damage
--    Scaled by ArmourTier via VehicleStats.Compute(car).ImpactDamageMultiplier.
-- ---------------------------------------------------------------------------
local IMPACT_SPEEDS = { 12, 25, 40, 60, 85 }
local IMPACT_DAMAGES = { 2, 5, 12, 22, 35 }

local lastVehicleVelocity = Vector3.zero
RunService.Heartbeat:Connect(function()
	if driveSeat.Parent then
		lastVehicleVelocity = driveSeat.AssemblyLinearVelocity
	end
end)

local function getImpactDamage(speed: number, multiplier: number): number
	if speed < IMPACT_SPEEDS[1] then
		return 0
	end
	for i = 2, #IMPACT_SPEEDS do
		if speed <= IMPACT_SPEEDS[i] then
			local span = IMPACT_SPEEDS[i] - IMPACT_SPEEDS[i - 1]
			if span <= 0 then
				return IMPACT_DAMAGES[i] * multiplier
			end
			local alpha = clamp((speed - IMPACT_SPEEDS[i - 1]) / span, 0, 1)
			return (IMPACT_DAMAGES[i - 1] + (IMPACT_DAMAGES[i] - IMPACT_DAMAGES[i - 1]) * alpha) * multiplier
		end
	end
	return IMPACT_DAMAGES[#IMPACT_DAMAGES] * multiplier
end

if chassisCollider then
	local lastImpactTime = 0
	chassisCollider.Touched:Connect(function(otherPart: BasePart)
		if not otherPart:IsA("BasePart") or otherPart:IsDescendantOf(car) or not otherPart.CanCollide then
			return
		end

		local now = os.clock()
		if now - lastImpactTime < 0.65 then
			return
		end
		if car:GetAttribute("GodMode") == true then
			return
		end

		local closingSpeed = (lastVehicleVelocity - otherPart.AssemblyLinearVelocity).Magnitude
		if closingSpeed < 12 then
			return
		end

		local multiplier = VehicleStats.Compute(car).ImpactDamageMultiplier
		local damage = getImpactDamage(closingSpeed, multiplier)
		if damage <= 0 then
			return
		end

		lastImpactTime = now
		local maxHealth = VehicleStats.Compute(car).MaxHealth
		local currentHealth = tonumber(car:GetAttribute("Health")) or maxHealth
		car:SetAttribute("Health", math.max(0, currentHealth - damage))
	end)
end

print("[RaycastChassisServer] Initialized for " .. car.Name .. " - Server Authority Ready!")
