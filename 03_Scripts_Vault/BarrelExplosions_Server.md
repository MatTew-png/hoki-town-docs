# 📜 BarrelExplosions (Server Script)

> **ตำแหน่งเดิมใน DataModel:** `Workspace.ExplosiveBarrels.BarrelExplosions`  
> **ประเภทสคริปต์:** `BarrelExplosions_Server`  
> **คำอธิบาย:** สคริปต์เซิร์ฟเวอร์จัดการกับถังระเบิดในฉาก เมื่อตัวละครสัมผัสจะจุดชนวนระเบิด สร้างดาเมจระยะห่าง ระเบิดลูกโซ่ และรีสปอว์นใหม่ใน 25 วินาที  

---

## 📝 ซอร์สโค้ดต้นฉบับ (Original Source Code)

```luau
local container = script.Parent
local DEFAULT_RADIUS, DEFAULT_DAMAGE, RESPAWN = 14, 80, 25
local templates = {}

local setup

local function explode(model)
	if model:GetAttribute("Exploded") or not model.PrimaryPart then return end
	model:SetAttribute("Exploded", true)
	local template = templates[model]
	local radius = model:GetAttribute("BlastRadius") or DEFAULT_RADIUS
	local damage = model:GetAttribute("Damage") or DEFAULT_DAMAGE
	local pos = model.PrimaryPart.Position
	local hurt = {}
	local ex = Instance.new("Explosion")
	ex.Position = pos
	ex.BlastRadius = radius
	ex.BlastPressure = 120000 * (radius / DEFAULT_RADIUS)
	ex.DestroyJointRadiusPercent = 0
	ex.ExplosionType = Enum.ExplosionType.NoCraters
	ex.Hit:Connect(function(part, dist)
		local parent = part.Parent
		if not parent then return end
		local hum = parent:FindFirstChildOfClass("Humanoid")
		if hum and not hurt[hum] then
			hurt[hum] = true
			hum:TakeDamage(damage * (1 - math.clamp(dist / radius, 0, 1)))
		end
		if parent:IsA("Model") and parent.Name == "ExplosiveBarrel" and parent ~= model and not parent:GetAttribute("Exploded") then
			task.delay(0.2, explode, parent)
		end
	end)
	ex.Parent = workspace
	model:Destroy()
	templates[model] = nil
	if template then
		task.delay(RESPAWN, function()
			template.Parent = container
			setup(template)
		end)
	end
end

setup = function(model)
	templates[model] = model:Clone()
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.CanCollide then
			d.Touched:Connect(function(hit)
				local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then explode(model) end
			end)
		end
	end
end

for _, m in ipairs(container:GetChildren()) do
	if m:IsA("Model") and m.Name == "ExplosiveBarrel" then setup(m) end
end

```
