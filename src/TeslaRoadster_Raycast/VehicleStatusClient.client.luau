--!strict
--[[
    VehicleStatusClient.client.luau
    HOKI TOWN - Vehicle Engineering
    Drives the CarStatusGui telemetry HUD for the Hybrid Raycast Roadster: speed,
    virtual gear, fuel/health, [R] quick-repair, breakdown alert, and tire-puncture
    alert banner. Reads client-local telemetry attributes published by the chassis.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local gui = script.Parent :: ScreenGui

local vehicleReference = gui:WaitForChild("VehicleRef", 10) :: ObjectValue?
local car = vehicleReference and vehicleReference.Value
if not car then
	return
end

local repairRemote = car:FindFirstChild("VehicleRepairRequest") :: RemoteEvent?

-- Breakdown alert banner (0% HP -> [R] to repair).
local alertBanner: TextLabel
local existingAlert = gui:FindFirstChild("BreakdownAlertBanner")
if existingAlert and existingAlert:IsA("TextLabel") then
	alertBanner = existingAlert
else
	local newBanner = Instance.new("TextLabel")
	newBanner.Name = "BreakdownAlertBanner"
	newBanner.Size = UDim2.fromOffset(480, 42)
	newBanner.Position = UDim2.new(0.5, -240, 0, 24)
	newBanner.BackgroundColor3 = Color3.fromRGB(220, 35, 35)
	newBanner.BackgroundTransparency = 0.15
	newBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
	newBanner.Font = Enum.Font.GothamBold
	newBanner.TextSize = 16
	newBanner.Text =
		"💥 รถพังเสียหายหนัก (0% HP) — กด [R] เพื่อซ่อมรถทันที"
	newBanner.Visible = false
	newBanner.Parent = gui

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 8)
	bCorner.Parent = newBanner

	local bStroke = Instance.new("UIStroke")
	bStroke.Color = Color3.fromRGB(255, 255, 255)
	bStroke.Thickness = 1.5
	bStroke.Transparency = 0.3
	bStroke.Parent = newBanner

	alertBanner = newBanner
end

-- Tire puncture alert banner (1+ popped tires -> reduced control).
local tireBanner: TextLabel
local existingTire = gui:FindFirstChild("TireAlertBanner")
if existingTire and existingTire:IsA("TextLabel") then
	tireBanner = existingTire
else
	local newTire = Instance.new("TextLabel")
	newTire.Name = "TireAlertBanner"
	newTire.Size = UDim2.fromOffset(480, 42)
	newTire.Position = UDim2.new(0.5, -240, 0, 72)
	newTire.BackgroundColor3 = Color3.fromRGB(230, 140, 20)
	newTire.BackgroundTransparency = 0.15
	newTire.TextColor3 = Color3.fromRGB(255, 255, 255)
	newTire.Font = Enum.Font.GothamBold
	newTire.TextSize = 16
	newTire.Text = "⚠️ ยางแตก x1 เส้น — การควบคุมลดลง!"
	newTire.Visible = false
	newTire.Parent = gui

	local tCorner = Instance.new("UICorner")
	tCorner.CornerRadius = UDim.new(0, 8)
	tCorner.Parent = newTire

	local tStroke = Instance.new("UIStroke")
	tStroke.Color = Color3.fromRGB(255, 255, 255)
	tStroke.Thickness = 1.5
	tStroke.Transparency = 0.3
	tStroke.Parent = newTire

	tireBanner = newTire
end

-- Keyboard shortcut [R] to Quick-Repair.
local inputConn = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed or UserInputService:GetFocusedTextBox() then
		return
	end
	if input.KeyCode == Enum.KeyCode.R and repairRemote then
		repairRemote:FireServer()
	end
end)

local frame = gui:WaitForChild("Frame") :: GuiObject
local background = frame:WaitForChild("Background") :: GuiObject
local fuelPercent = background:WaitForChild("FuelPercent") :: TextLabel
local healthPercent = background:WaitForChild("HealthPercent") :: TextLabel
local speedLabel = background:WaitForChild("SpeedNow") :: TextLabel
local gearNow = background:WaitForChild("GearNow") :: TextLabel
local gearNext = background:WaitForChild("GearNext") :: TextLabel
local gearBefore = background:WaitForChild("GearBefore") :: TextLabel
local seat = car:WaitForChild("DriveSeat") :: VehicleSeat

local TIRE_KEYS = { "FL", "FR", "RL", "RR" }

local function readGear(): number?
	local clientGear = car:GetAttribute("ClientGear")
	if typeof(clientGear) == "number" then
		return math.floor(clientGear + 0.5)
	end

	local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
	local interface = playerGui and playerGui:FindFirstChild("A-Chassis Interface")
	local values = interface and interface:FindFirstChild("Values")
	local gearValue = values and values:FindFirstChild("Gear")
	if gearValue and (gearValue:IsA("NumberValue") or gearValue:IsA("IntValue")) then
		return math.floor(gearValue.Value + 0.5)
	end

	local tune = car:FindFirstChild("Hoki-Chassis Tune") or car:FindFirstChild("A-Chassis Tune")
	local vehicleInterface = tune and tune:FindFirstChild("A-Chassis Interface")
	local vehicleValues = vehicleInterface and vehicleInterface:FindFirstChild("Values")
	gearValue = vehicleValues and vehicleValues:FindFirstChild("Gear")
	if gearValue and (gearValue:IsA("NumberValue") or gearValue:IsA("IntValue")) then
		return math.floor(gearValue.Value + 0.5)
	end
	return nil
end

local function readSpeedKmh(): number
	local clientSpeed = car:GetAttribute("ClientSpeedKmh")
	if typeof(clientSpeed) == "number" then
		return clientSpeed
	end
	return seat.AssemblyLinearVelocity.Magnitude * 1.008
end

local function countPoppedTires(): number
	local count = 0
	for _, key in TIRE_KEYS do
		if car:GetAttribute("TirePopped_" .. key) == true then
			count += 1
		end
	end
	return count
end

local function setPercent(label: TextLabel, current: number, maximum: number)
	local percent = math.clamp(math.floor((current / math.max(maximum, 0.001)) * 100 + 0.5), 0, 100)
	label.Text = tostring(percent) .. "%"
end

local function render()
	if not car.Parent then
		gui.Enabled = false
		return
	end

	local fuel = tonumber(car:GetAttribute("Fuel")) or 100
	local maxFuel = tonumber(car:GetAttribute("MaxFuel")) or 100
	local health = tonumber(car:GetAttribute("Health")) or 100
	local maxHealth = tonumber(car:GetAttribute("MaxHealth")) or 100
	setPercent(fuelPercent, fuel, maxFuel)
	setPercent(healthPercent, health, maxHealth)

	local speedKmh = readSpeedKmh()
	speedLabel.Text = string.format("%03d", math.floor(speedKmh + 0.5))

	local gear = readGear()
	if gear ~= nil then
		if gear <= -2 then
			gearNow.Text = "P"
			gearNext.Text = "R"
			gearBefore.Text = "—"
		elseif gear == -1 then
			gearNow.Text = "R"
			gearNext.Text = "N"
			gearBefore.Text = "P"
		elseif gear == 0 then
			gearNow.Text = "N"
			gearNext.Text = "1"
			gearBefore.Text = "R"
		else
			gearNow.Text = tostring(gear)
			gearNext.Text = if gear < 6 then tostring(gear + 1) else "—"
			gearBefore.Text = if gear > 1 then tostring(gear - 1) else "N"
		end
	end

	-- Breakdown banner when the vehicle is wrecked (0% HP).
	alertBanner.Visible = health <= 0

	-- Tire puncture banner when one or more tires are popped.
	local popped = countPoppedTires()
	if popped > 0 then
		tireBanner.Text = "⚠️ ยางแตก x"
			.. tostring(popped)
			.. " เส้น — การควบคุมลดลง!"
		tireBanner.Visible = true
	else
		tireBanner.Visible = false
	end
end

local renderConn: RBXScriptConnection
local destroyingConn: RBXScriptConnection
local ancestryConn: RBXScriptConnection

local function cleanup()
	inputConn:Disconnect()
	renderConn:Disconnect()
	destroyingConn:Disconnect()
	ancestryConn:Disconnect()
end

renderConn = RunService.RenderStepped:Connect(render)
destroyingConn = gui.Destroying:Connect(cleanup)
ancestryConn = car.AncestryChanged:Connect(function()
	if car.Parent == nil then
		cleanup()
	end
end)

render()
