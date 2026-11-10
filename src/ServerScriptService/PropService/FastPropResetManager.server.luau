--!strict
--[[
    FastPropResetManager.server.luau
    HOKI TOWN / รถ HOKI - Proving Grounds
    Zero-Lag Prop Tumble & 3-Second Automatic CFrame Restoration Engine
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local TAG_NAME = "TumbleProp"
local RESET_DELAY_SECONDS = 3.0
local DISPLACEMENT_THRESHOLD_STUDS = 1.5
local TILT_THRESHOLD_DEGREES = 15.0

type PropRecord = {
	originalCFrame: CFrame,
	isPendingReset: boolean,
	lastCheckedTime: number,
}

local registeredProps: { [BasePart]: PropRecord } = {}

local function registerProp(prop: BasePart)
	if not prop:IsA("BasePart") then return end
	if registeredProps[prop] then return end

	registeredProps[prop] = {
		originalCFrame = prop.CFrame,
		isPendingReset = false,
		lastCheckedTime = os.clock(),
	}

	-- Ensure prop is physically active and unanchored for satisfying knockdowns
	prop.Anchored = false
	prop.CanCollide = true
end

local function unregisterProp(prop: BasePart)
	registeredProps[prop] = nil
end

local function isTilted(currentCF: CFrame, originalCF: CFrame): boolean
	local currentUp = currentCF.UpVector
	local originalUp = originalCF.UpVector
	local dot = math.clamp(currentUp:Dot(originalUp), -1, 1)
	local angleDeg = math.deg(math.acos(dot))
	return angleDeg > TILT_THRESHOLD_DEGREES
end

local function executeReset(prop: BasePart, record: PropRecord)
	if not prop:IsDescendantOf(workspace) then
		unregisterProp(prop)
		return
	end

	-- Overlap check: ensure no vehicle collider is pinning the prop down before snapping
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { prop }

	local nearbyParts = workspace:GetPartBoundsInBox(record.originalCFrame, prop.Size + Vector3.new(1, 1, 1), overlapParams)
	local isObstructed = false

	for _, part in ipairs(nearbyParts) do
		if part.Name == "Chassis_Collider" or part.Name == "DriveSeat" or part.Parent:FindFirstChild("Humanoid") then
			isObstructed = true
			break
		end
	end

	if isObstructed then
		-- Re-try in 1.5 seconds if vehicle is still on top of the reset coordinate
		task.delay(1.5, function()
			executeReset(prop, record)
		end)
		return
	end

	-- Zero velocity before resetting position to prevent kinetic energy spikes
	prop.AssemblyLinearVelocity = Vector3.zero
	prop.AssemblyAngularVelocity = Vector3.zero
	prop.CFrame = record.originalCFrame
	prop.AssemblyLinearVelocity = Vector3.zero
	prop.AssemblyAngularVelocity = Vector3.zero

	record.isPendingReset = false
end

-- Initialize tagged props
for _, inst in ipairs(CollectionService:GetTagged(TAG_NAME)) do
	if inst:IsA("BasePart") then
		registerProp(inst)
	end
end

CollectionService:GetInstanceAddedSignal(TAG_NAME):Connect(function(inst)
	if inst:IsA("BasePart") then
		registerProp(inst)
	end
end)

CollectionService:GetInstanceRemovedSignal(TAG_NAME):Connect(function(inst)
	if inst:IsA("BasePart") then
		unregisterProp(inst)
	end
end)

-- Heartbeat scan loop (throttled to every 0.3s for negligible CPU overhead)
local accumulatedTime = 0
RunService.Heartbeat:Connect(function(dt)
	accumulatedTime += dt
	if accumulatedTime < 0.3 then return end
	accumulatedTime = 0

	for prop, record in pairs(registeredProps) do
		if not record.isPendingReset and prop:IsDescendantOf(workspace) then
			local dist = (prop.Position - record.originalCFrame.Position).Magnitude
			local tilted = isTilted(prop.CFrame, record.originalCFrame)

			if dist > DISPLACEMENT_THRESHOLD_STUDS or tilted then
				record.isPendingReset = true
				task.delay(RESET_DELAY_SECONDS, function()
					executeReset(prop, record)
				end)
			end
		end
	end
end)

print("[FastPropResetManager] Initialized with 3.0s zero-lag CFrame restoration.")
