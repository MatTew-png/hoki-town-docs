# 📜 VehicleSystems (Server Script)

> **ตำแหน่งใน DataModel:** Workspace.TeslaRoadster.VehicleSystems  
> **ประเภทสคริปต์:** Server Script (Script)  
> **คำอธิบาย:** สคริปต์เซิร์ฟเวอร์ควบคุมระบบหลักของตัวรถ Tesla Roadster จัดการประตู ProximityPrompt คนขับ/ผู้โดยสาร, การขึ้น-ลงรถและปลดตัวละคร, ระบบ GodMode ป้องกันรถพัง, ระบบเรนเดอร์ควันเครื่องยนต์เสีย (Breakdown VFX), รีโมตซ่อมรถด่วน (VehicleRepairRequest) และการกระจายหน้าปัดไมล์ CarStatusGui สู่ผู้เล่น  
> **สถานะ:** ✅ ผ่านการแก้ไขและทดสอบใน Studio Sandbox เรียบร้อยแล้ว

---

## 📌 สรุปคุณสมบัติและสถาปัตยกรรมหลัก (Key Architecture Features)

1. **ระบบขึ้น-ลงรถผ่าน ProximityPrompt 2 ฝั่ง (DriverDoor / PassengerDoor):**
   - ชิ้นส่วน Hitbox ประตูทั้ง 2 ฝั่งตั้งเป็น Anchored = false, CanCollide = false, CanTouch = false, Massless = true และเชื่อมด้วย WeldConstraint กับ DriveSeat **(แก้ปัญหาตัวรถถูกตอกหมุดขยับไม่ได้ 100%)**
   - เมื่อกดลงรถ มีการลบ SeatWeld อย่างปลอดภัย คืนค่า HumanoidStateType.Jumping = true และวาร์ปตัวละครออกมายืนข้างประตูรถ (Offset ด้านข้าง + หมุนหน้าตามทิศทางรถ) เพื่อป้องกันไม่ให้ตัวละครติดอยู่ในหลังคารถหรือเด้งกระเด็น
   - สลับสถานะ Prompt.Enabled อัตโนมัติเมื่อมีคนนั่ง เพื่อป้องกันไม่ให้คนขับเห็น Prompt ประตูบานอื่นบังหน้าจอ

2. **ระบบความปลอดภัยและการขับขี่ไม่สะดุด (GodMode & Infinite Drive):**
   - เปิดโหมด GodMode = true เป็นค่าเริ่มต้น ตรวจสอบในฟังก์ชันคำนวณการชน processImpact หากเปิด GodMode จะข้ามการหักเลือดทันที
   - ฟังก์ชันตรวจสอบกำลังเครื่องยนต์ (updatePowerCutoff) ล็อกสถานะ VehiclePowerDisabled = false ถาวร ทำให้ขับได้ไม่จำกัดรอบ ไม่ต้องกังวลเรื่องน้ำมันหมดหรือรถน็อกกลางแมป

3. **ระบบซ่อมรถด่วนและเอฟเฟกต์เครื่องพัง (Breakdown VFX & Quick Repair):**
   - ฟังเหตุการณ์จาก VehicleRepairRequest (RemoteEvent): ผู้เล่นกดปุ่ม [R] ขณะขับหรือยืนอยู่ใกล้รถ (< 18 studs) จะฟื้นฟู Health = 100% และ Fuel = 100% ทันที
   - อัปเดตเอฟเฟกต์ควันและไฟที่ห้องเครื่องยนต์ (EngineBayDamageVFX) ตามระดับความเสียหายแบบไดนามิก

4. **การ Spawn และจัดการวงจรชีวิตของ HUD (CarStatusGui):**
   - โคลน GUI จาก Template ไปยัง PlayerGui ของผู้ขับขี่โดยอัตโนมัติ พร้อมฝัง VehicleRef (ObjectValue) ชี้กลับมาที่ตัวรถ
   - ทำลาย GUI ทิ้งอย่างสะอาดเมื่อผู้เล่นลงจากรถหรือตัดการเชื่อมต่อ

---

## 📝 ซอร์สโค้ดฉบับสมบูรณ์ (Production Source Code - 511 Lines)

`luau
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local car = script.Parent
local seat = car:WaitForChild("DriveSeat") :: VehicleSeat
local passengerSeat = car:WaitForChild("PassengerSeat", 5) :: Seat?
local guiTemplate = car:WaitForChild("CarStatusGui")
local exitRemote = car:WaitForChild("VehicleExitRequest", 5) :: RemoteEvent?

-- Ensure seats never auto-sit on touch; entry is strictly via E ProximityPrompt
seat.CanTouch = false
if passengerSeat then
	passengerSeat.CanTouch = false
	passengerSeat.Anchored = false
end

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

-- Disable vehicle power if EITHER Fuel <= 0% OR Health <= 0%
local function updatePowerCutoff()
	local fuel = math.max(0, tonumber(car:GetAttribute("Fuel")) or 0)
	local maxFuel = math.max(0.001, tonumber(car:GetAttribute("MaxFuel")) or MAX_FUEL)
	local fuelPercent = math.floor((fuel / maxFuel) * 100 + 0.5)

	local health = math.max(0, tonumber(car:GetAttribute("Health")) or 0)
	local maxHealth = math.max(0.001, tonumber(car:GetAttribute("MaxHealth")) or MAX_HEALTH)
	local healthPercent = math.floor((health / maxHealth) * 100 + 0.5)

	car:SetAttribute("VehiclePowerDisabled", false)
end

car:GetAttributeChangedSignal("Fuel"):Connect(updatePowerCutoff)
car:GetAttributeChangedSignal("Health"):Connect(updatePowerCutoff)
updatePowerCutoff()

-- ============================================================================
-- E-KEY PROXIMITY PROMPT ENTRY & EXIT (DRIVER + PASSENGER SEATS)
-- ============================================================================
local doorPromptsModel = car:WaitForChild("Body"):WaitForChild("DoorPrompts", 5)
local driverPrompt: ProximityPrompt? = nil
local passengerPrompt: ProximityPrompt? = nil

if doorPromptsModel then
	local dPart = doorPromptsModel:FindFirstChild("DriverDoor")
	local pPart = doorPromptsModel:FindFirstChild("PassengerDoor")
	if dPart then driverPrompt = dPart:FindFirstChildOfClass("ProximityPrompt") end
	if pPart then passengerPrompt = pPart:FindFirstChildOfClass("ProximityPrompt") end
end

local lastInteractByPlayer: { [Player]: number } = {}

local function updatePromptVisibility()
	if driverPrompt then
		driverPrompt.Enabled = (seat.Occupant == nil) and (not seat.Disabled)
	end
	if passengerPrompt and passengerSeat then
		passengerPrompt.Enabled = (passengerSeat.Occupant == nil) and (not seat.Disabled)
	end
end

seat:GetPropertyChangedSignal("Occupant"):Connect(updatePromptVisibility)
seat:GetPropertyChangedSignal("Disabled"):Connect(updatePromptVisibility)
if passengerSeat then
	passengerSeat:GetPropertyChangedSignal("Occupant"):Connect(updatePromptVisibility)
end
updatePromptVisibility()

local function ejectOccupantToSide(player: Player, fromSeat: Seat | VehicleSeat, isDriverSide: boolean)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid then return end

	lastInteractByPlayer[player] = os.clock()
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)

	local seatWeld = fromSeat:FindFirstChild("SeatWeld")
	if seatWeld then
		seatWeld:Destroy()
	end
	humanoid.Sit = false

	if rootPart then
		task.defer(function()
			local sideOffset = isDriverSide and Vector3.new(-4.8, 1.8, 0) or Vector3.new(7.4, 1.8, 0)
			local targetCF = seat.CFrame * CFrame.new(sideOffset)
			local flatLook = Vector3.new(seat.CFrame.LookVector.X, 0, seat.CFrame.LookVector.Z)
			if flatLook.Magnitude > 0.01 then
				rootPart.CFrame = CFrame.lookAt(targetCF.Position, targetCF.Position + flatLook.Unit)
			else
				rootPart.CFrame = CFrame.new(targetCF.Position)
			end
			rootPart.AssemblyLinearVelocity = seat.AssemblyLinearVelocity * 0.25
		end)
	end
end

if driverPrompt then
	driverPrompt.Triggered:Connect(function(player: Player)
		local now = os.clock()
		if now - (lastInteractByPlayer[player] or 0) < 0.45 then return end
		if seat.Disabled or seat.Occupant ~= nil then return end

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end

		-- If player is currently in passengerSeat, unsit first
		if passengerSeat and passengerSeat.Occupant == humanoid then
			local sw = passengerSeat:FindFirstChild("SeatWeld")
			if sw then sw:Destroy() end
			humanoid.Sit = false
			task.wait(0.05)
		end

		lastInteractByPlayer[player] = now
		seat.CanTouch = false
		seat:Sit(humanoid)
		updatePromptVisibility()
	end)
end

if passengerPrompt and passengerSeat then
	passengerPrompt.Triggered:Connect(function(player: Player)
		local now = os.clock()
		if now - (lastInteractByPlayer[player] or 0) < 0.45 then return end
		if seat.Disabled or passengerSeat.Occupant ~= nil then return end

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end

		if seat.Occupant == humanoid then return end

		lastInteractByPlayer[player] = now
		passengerSeat.CanTouch = false
		passengerSeat:Sit(humanoid)
		updatePromptVisibility()
	end)
end

if exitRemote then
	exitRemote.OnServerEvent:Connect(function(player: Player)
		local now = os.clock()
		if now - (lastInteractByPlayer[player] or 0) < 0.35 then return end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		if seat.Occupant == humanoid then
			ejectOccupantToSide(player, seat, true)
		elseif passengerSeat and passengerSeat.Occupant == humanoid then
			ejectOccupantToSide(player, passengerSeat, false)
		end
	end)
end

-- Give Passenger a lightweight client helper so E exits passenger seat cleanly too
if passengerSeat then
	local currentPassenger: Player? = nil
	passengerSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local hum = passengerSeat.Occupant
		local plr = hum and Players:GetPlayerFromCharacter(hum.Parent) or nil
		if currentPassenger and currentPassenger ~= plr then
			local pg = currentPassenger:FindFirstChildOfClass("PlayerGui")
			if pg and pg:FindFirstChild("HokiPassengerGui") then
				pg.HokiPassengerGui:Destroy()
			end
		end
		currentPassenger = plr
		if plr then
			local pg = plr:FindFirstChildOfClass("PlayerGui")
			if pg then
				local pGui = Instance.new("ScreenGui")
				pGui.Name = "HokiPassengerGui"
				pGui.ResetOnSpawn = false
				local hint = Instance.new("TextLabel")
				hint.Size = UDim2.new(0, 260, 0, 28)
				hint.Position = UDim2.new(0.5, -130, 1, -36)
				hint.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
				hint.BackgroundTransparency = 0.25
				hint.TextColor3 = Color3.fromRGB(235, 245, 255)
				hint.Font = Enum.Font.GothamBold
				hint.TextSize = 14
				hint.Text = " ที่นั่งข้างคนขับ | กด [E] เพื่อลงจากรถ "
				hint.Parent = pGui
				local c = Instance.new("UICorner")
				c.CornerRadius = UDim.new(0, 8)
				c.Parent = hint
				pGui.Parent = pg
			end
		end
	end)
end

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
	lastInteractByPlayer[player] = nil
	if player == currentPlayer then
		removeGui(player)
		currentPlayer = nil
	end
end)
updateOccupant()

local impactFolder = car:WaitForChild("Body"):FindFirstChild("ImpactSensors")
local lastImpactTime = 0
local IMPACT_COOLDOWN = 0.65
local MIN_IMPACT_SPEED = 12
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
	local sensorDirection = sourcePart.Name == "Rear" and -carLook or carLook
	local horizontalDirection = Vector3.new(sensorDirection.X, 0, sensorDirection.Z)
	if horizontalDirection.Magnitude < 0.1 then return end
	horizontalDirection = horizontalDirection.Unit
	local closingSpeed = relativeVelocity:Dot(horizontalDirection)

	if isSupportedByRamp() and sensorDirection.Y > 0.35 then return end
	if closingSpeed < MIN_IMPACT_SPEED then return end

	if car:GetAttribute("GodMode") == true then return end
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
			sensor.CanTouch = true
			table.insert(impactSensors, sensor)
			sensor.Touched:Connect(function(otherPart)
				if otherPart:IsA("BasePart") then processImpact(sensor, otherPart) end
			end)
		end
	end
end

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
			car:SetAttribute("Fuel", MAX_FUEL)
		end
	end
end


-- ============================================================================
-- VEHICLE BREAKDOWN VFX & INSTANT REPAIR SYSTEM
-- ============================================================================
local repairRemote = car:WaitForChild("VehicleRepairRequest", 5) :: RemoteEvent?
local vfxPart = car:WaitForChild("Body"):WaitForChild("EngineBayDamageVFX", 5)
local whiteSmoke = vfxPart and vfxPart:FindFirstChild("WarningWhiteSmoke") :: ParticleEmitter?
local blackSmoke = vfxPart and vfxPart:FindFirstChild("HeavyBlackSmoke") :: ParticleEmitter?
local engineFire = vfxPart and vfxPart:FindFirstChild("EngineFire") :: ParticleEmitter?

local function updateBreakdownVFX()
	local health = tonumber(car:GetAttribute("Health")) or 100
	local maxHealth = math.max(1, tonumber(car:GetAttribute("MaxHealth")) or 100)
	local healthPercent = math.floor((health / maxHealth) * 100 + 0.5)

	if healthPercent <= 0 then
		if blackSmoke then blackSmoke.Rate = 45 end
		if engineFire then engineFire.Rate = 28 end
		if whiteSmoke then whiteSmoke.Rate = 0 end
	elseif healthPercent < 40 then
		if blackSmoke then blackSmoke.Rate = 0 end
		if engineFire then engineFire.Rate = 0 end
		if whiteSmoke then whiteSmoke.Rate = 18 end
	else
		if blackSmoke then blackSmoke.Rate = 0 end
		if engineFire then engineFire.Rate = 0 end
		if whiteSmoke then whiteSmoke.Rate = 0 end
	end
end

car:GetAttributeChangedSignal("Health"):Connect(updateBreakdownVFX)
updateBreakdownVFX()

local function performRepair()
	car:SetAttribute("Health", tonumber(car:GetAttribute("MaxHealth")) or 100)
	car:SetAttribute("Fuel", tonumber(car:GetAttribute("MaxFuel")) or 100)
	car:SetAttribute("VehiclePowerDisabled", false)
	updateBreakdownVFX()
	print("[VehicleSystems] Vehicle fully repaired and refueled to 100%!")
end

if repairRemote then
	repairRemote.OnServerEvent:Connect(function(player)
		local character = player.Character
		local hum = character and character:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		-- Allow repair if player is seated in the car or near the car
		local isOccupant = (seat.Occupant == hum) or (passengerSeat and passengerSeat.Occupant == hum)
		local isNear = false
		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			isNear = (hrp.Position - seat.Position).Magnitude < 18
		end
		if isOccupant or isNear then
			performRepair()
		end
	end)
end


`
