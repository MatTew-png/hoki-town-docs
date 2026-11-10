--!strict
--[[
    RaycastChassisServer.server.luau
    HOKI TOWN - Vehicle Engineering
    Laser / Raycast Arcade Chassis Server Authority
]]

local Players = game:GetService("Players")
local car = script.Parent :: Model

local seat = car:FindFirstChild("DriveSeat") or car:FindFirstChild("DriveSeat", true)
assert(seat ~= nil and seat:IsA("VehicleSeat"), "[RaycastChassisServer] Missing DriveSeat under " .. car:GetFullName())
local driveSeat = seat :: VehicleSeat

local chassisCollider = car:FindFirstChild("Chassis_Collider", true) :: BasePart?

-- ---------------------------------------------------------------------------
-- 1. Root Part & Hierarchy Calibration
--    DriveSeat is the assembly root. Every cosmetic body part is massless,
--    collisionless, and welded to it so the whole vehicle moves as one assembly.
-- ---------------------------------------------------------------------------
driveSeat.Disabled = false
driveSeat.CanCollide = false -- body rides on the raycast hover plane, not seat belly
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
--    Wheels stay physically separate (Anchored) so the client can PivotTo them
--    for steer/spin without being driven by chassis physics.
-- ---------------------------------------------------------------------------
local wheelsFolder = car:FindFirstChild("Wheels")
if wheelsFolder then
	local function unWeldFromChassis(part: BasePart)
		for _, child in ipairs(part:GetChildren()) do
			if child:IsA("Weld") or child:IsA("WeldConstraint") then
				local p0 = child.Part0
				local p1 = child.Part1
				if p0 == driveSeat or p1 == driveSeat or p0 == chassisCollider or p1 == chassisCollider then
					child:Destroy()
				end
			end
		end
	end

	for _, wheel in ipairs(wheelsFolder:GetDescendants()) do
		if wheel:IsA("BasePart") then
			local w = wheel :: BasePart
			unWeldFromChassis(w)
			w.Anchored = true
			w.CanCollide = false
			w.Massless = true
		end
	end
end

-- ---------------------------------------------------------------------------
-- 3. ProximityPrompt Entry
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
-- 4. Network Ownership & Seat Occupant
-- ---------------------------------------------------------------------------
local function updateNetworkOwnership(occupant: Humanoid?)
	local root = driveSeat.AssemblyRootPart or driveSeat
	if occupant then
		local character = occupant.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			driveSeat.Anchored = false
			root.Anchored = false
			pcall(function()
				root:SetNetworkOwner(player)
			end)
		end
	else
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

-- ---------------------------------------------------------------------------
-- 5. Vehicle Attributes & GodMode
-- ---------------------------------------------------------------------------
car:SetAttribute("Health", 100)
car:SetAttribute("MaxHealth", 100)
car:SetAttribute("Fuel", 100)
car:SetAttribute("MaxFuel", 100)
car:SetAttribute("GodMode", true)

print("[RaycastChassisServer] Initialized for " .. car.Name .. " - Server Authority Ready!")
