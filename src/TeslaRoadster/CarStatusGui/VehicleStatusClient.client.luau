local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local gui = script.Parent
local vehicleReference = gui:WaitForChild("VehicleRef", 10)
local car = vehicleReference and vehicleReference.Value
while not car do
	if not vehicleReference then break end
	vehicleReference:GetPropertyChangedSignal("Value"):Wait()
	car = vehicleReference.Value
end
if not car then return end

local repairRemote = car:WaitForChild("VehicleRepairRequest", 5) :: RemoteEvent?

-- Create Alert Banner on HUD
local alertBanner = gui:FindFirstChild("BreakdownAlertBanner")
if not alertBanner then
	alertBanner = Instance.new("TextLabel")
	alertBanner.Name = "BreakdownAlertBanner"
	alertBanner.Size = UDim2.new(0, 480, 0, 42)
	alertBanner.Position = UDim2.new(0.5, -240, 0, 24)
	alertBanner.BackgroundColor3 = Color3.fromRGB(220, 35, 35)
	alertBanner.BackgroundTransparency = 0.15
	alertBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
	alertBanner.Font = Enum.Font.GothamBold
	alertBanner.TextSize = 16
	alertBanner.Text = "💥 รถพังเสียหายหนัก (0% HP) — กด [R] เพื่อซ่อมรถทันที"
	alertBanner.Visible = false
	alertBanner.Parent = gui

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 8)
	bCorner.Parent = alertBanner

	local bStroke = Instance.new("UIStroke")
	bStroke.Color = Color3.fromRGB(255, 255, 255)
	bStroke.Thickness = 1.5
	bStroke.Transparency = 0.3
	bStroke.Parent = alertBanner
end

-- Keyboard Shortcut [R] to Quick-Repair
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.R then
		if repairRemote then
			repairRemote:FireServer()
		end
	end
end)

local frame = gui:WaitForChild("Frame")
local background = frame:WaitForChild("Background")
local fuelPercent = background:WaitForChild("FuelPercent")
local healthPercent = background:WaitForChild("HealthPercent")
local speedLabel = background:WaitForChild("SpeedNow")
local gearNow = background:WaitForChild("GearNow")
local gearNext = background:WaitForChild("GearNext")
local gearBefore = background:WaitForChild("GearBefore")
local seat = car:WaitForChild("DriveSeat")

local function readGear()
	local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
	local interface = playerGui and playerGui:FindFirstChild("A-Chassis Interface")
	local values = interface and interface:FindFirstChild("Values")
	local gearValue = values and values:FindFirstChild("Gear")
	if gearValue and (gearValue:IsA("NumberValue") or gearValue:IsA("IntValue")) then
		return math.floor(gearValue.Value + 0.5)
	end

	local tune = car:FindFirstChild("A-Chassis Tune")
	local vehicleInterface = tune and tune:FindFirstChild("A-Chassis Interface")
	local vehicleValues = vehicleInterface and vehicleInterface:FindFirstChild("Values")
	gearValue = vehicleValues and vehicleValues:FindFirstChild("Gear")
	if gearValue and (gearValue:IsA("NumberValue") or gearValue:IsA("IntValue")) then
		return math.floor(gearValue.Value + 0.5)
	end
	return nil
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

	local fuel = car:GetAttribute("Fuel") or 100
	local maxFuel = car:GetAttribute("MaxFuel") or 100
	local health = car:GetAttribute("Health") or 100
	local maxHealth = car:GetAttribute("MaxHealth") or 100
	setPercent(fuelPercent, fuel, maxFuel)
	setPercent(healthPercent, health, maxHealth)

	-- Live Speed in KM/H (1 stud/s = 1.008 km/h)
	local speedKmh = seat.AssemblyLinearVelocity.Magnitude * 1.008
	speedLabel.Text = string.format("%03d", math.floor(speedKmh + 0.5))

	-- Live Gear display
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
			gearNext.Text = gear < 6 and tostring(gear + 1) or "—"
			gearBefore.Text = gear > 1 and tostring(gear - 1) or "N"
		end
	end
end

RunService.RenderStepped:Connect(render)
render()

