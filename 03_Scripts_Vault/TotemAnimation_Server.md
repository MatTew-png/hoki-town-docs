# 📜 TotemAnimation (Server Script)

> **ตำแหน่งเดิมใน DataModel:** `Workspace.TotemFarm_Pack.TotemAnimation`  
> **ประเภทสคริปต์:** `TotemAnimation_Server`  
> **คำอธิบาย:** สคริปต์เซิร์ฟเวอร์จัดการแอนิเมชั่นคิเนมาติกของแท่นฟาร์มโทเทม (ลุงเอ, กล้วย, เมล่อน) ทำการหมุนหัวโทเทม, ลอยวงแหวน 3 ชั้นสลับจังหวะ และหมุนผลไม้รอบเสา  

---

## 📝 ซอร์สโค้ดต้นฉบับ (Original Source Code)

```luau
-- Totem animation script
-- - "animation" part spins clockwise
-- - Ring1-3 bob up/down slightly, each spinning in a different direction
-- - Fruit folder children spin counterclockwise

local RunService = game:GetService("RunService")

local totem = script.Parent
local animationPart = totem:FindFirstChild("animation")
local pillar = totem:FindFirstChild("Base")
local fruitFolder = totem:FindFirstChild("Fruit")

-- Each entry: part, spin direction (+1 = counterclockwise, -1 = clockwise),
-- spin speed (degrees/sec), bob amplitude (studs), bob speed, phase offset
local spinners = {}

if animationPart then
	table.insert(spinners, {
		part = animationPart,
		dir = -1, -- clockwise
		speed = 30,
		bobAmp = 0,
		bobSpeed = 0,
		phase = 0,
	})
end

if pillar then
	local ringSettings = {
		["Ring1"] = {dir = 1, speed = 45, bobAmp = 0.15, bobSpeed = 1.5, phase = 0},
		["Ring2"] = {dir = -1, speed = 60, bobAmp = 0.15, bobSpeed = 1.5, phase = math.pi * 2 / 3},
		["Ring3"] = {dir = 1, speed = 75, bobAmp = 0.15, bobSpeed = 1.5, phase = math.pi * 4 / 3},
	}
	for ringName, settings in ringSettings do
		local ring = pillar:FindFirstChild(ringName)
		if ring then
			table.insert(spinners, {
				part = ring,
				dir = settings.dir,
				speed = settings.speed,
				bobAmp = settings.bobAmp,
				bobSpeed = settings.bobSpeed,
				phase = settings.phase,
			})
		end
	end
end

-- Base model spins counterclockwise around its own pivot
local baseModel = totem:FindFirstChild("Base")
local basePivot = nil
if baseModel and baseModel:IsA("Model") then
	basePivot = baseModel:GetPivot()
end

if fruitFolder then
	for _, child in fruitFolder:GetChildren() do
		if child:IsA("BasePart") then
			table.insert(spinners, {
				part = child,
				dir = 1, -- counterclockwise
				speed = 40,
				bobAmp = 0,
				bobSpeed = 0,
				phase = 0,
			})
		end
	end
end

-- Capture base CFrames so each part rotates/bobs around its own original position
for _, spinner in spinners do
	spinner.baseCFrame = spinner.part.CFrame
end

local elapsedTime = 0

RunService.Heartbeat:Connect(function(dt)
	elapsedTime += dt
	if baseModel and basePivot then
		local baseAngle = math.rad(30 * elapsedTime) -- counterclockwise
		baseModel:PivotTo(basePivot * CFrame.Angles(0, baseAngle, 0))
	end
	for _, spinner in spinners do
		local part = spinner.part
		if part and part.Parent then
			local bobOffset = 0
			if spinner.bobAmp > 0 then
				bobOffset = math.sin(elapsedTime * spinner.bobSpeed + spinner.phase) * spinner.bobAmp
			end
			local angle = math.rad(spinner.dir * spinner.speed * elapsedTime)
			part.CFrame = spinner.baseCFrame
				* CFrame.new(0, bobOffset, 0)
				* CFrame.Angles(0, angle, 0)
		end
	end
end)
```
