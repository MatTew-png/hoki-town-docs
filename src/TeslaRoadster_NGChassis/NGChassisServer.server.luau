--!strict
--[[
    NGChassisServer.server.luau
    HOKI TOWN - Vehicle Engineering
    Next-Gen Chassis (NGChassis) Server Authority
]]

local Players = game:GetService("Players")
local car = script.Parent :: Model
local seat = car:WaitForChild("DriveSeat") :: VehicleSeat

-- 1. Configure DriveSeat
seat.Disabled = false
seat.CanCollide = false
seat.Transparency = 1

-- 4. Health & Fuel attributes
if car:GetAttribute("Health") == nil then car:SetAttribute("Health", 100) end
if car:GetAttribute("MaxHealth") == nil then car:SetAttribute("MaxHealth", 100) end
if car:GetAttribute("Fuel") == nil then car:SetAttribute("Fuel", 100) end
if car:GetAttribute("MaxFuel") == nil then car:SetAttribute("MaxFuel", 100) end

-- 2. ProximityPrompt for entry
local existingPrompt = seat:FindFirstChildOfClass("ProximityPrompt")
if not existingPrompt then
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DrivePrompt"
	prompt.ObjectText = "Tesla Roadster (NGChassis)"
	prompt.ActionText = "ขับรถ (Drive)"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = seat

	prompt.Triggered:Connect(function(player: Player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and not seat.Occupant then
			seat:Sit(humanoid)
		end
	end)
end

-- 3. Network Ownership Management
local function updateNetworkOwnership(occupant: Humanoid?)
	local root = seat.AssemblyRootPart or seat
	if occupant then
		local character = occupant.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			pcall(function()
				root:SetNetworkOwner(player)
			end)
		end
	else
		task.wait(0.1)
		if not seat.Occupant then
			pcall(function()
				root:SetNetworkOwner(nil)
			end)
			seat.AssemblyLinearVelocity = Vector3.zero
			seat.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

seat:GetPropertyChangedSignal("Occupant"):Connect(function()
	updateNetworkOwnership(seat.Occupant)
end)

print("[NGChassisServer] Initialized for " .. car.Name .. " - Server Authority Ready!")
