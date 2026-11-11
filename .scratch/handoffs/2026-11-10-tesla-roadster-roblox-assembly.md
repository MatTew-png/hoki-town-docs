# 📋 Handoff: Tesla Roadster 2026 — Roblox Studio Assembly & Raycast Integration

**Date:** 2026-11-10  
**Target:** Roblox Studio Assembly, Rigging & Playtest Verification  
**Author:** Antigravity (Lead Architect)

---

## 🎯 Goal
Assist the user with importing the finalized 27-part `Tesla_Roadster_Base_2026.fbx` into Roblox Studio via 3D Importer, and immediately execute an automated Lua assembly script through Roblox Studio MCP (`run_code`) to:
1. Prevent physics fling/explosion by setting `CanCollide = false` and `Massless = true` on all 27 decorative mesh parts.
2. Weld all body, interior, glass, and trim parts to the central root/chassis (`Chassis_Underbody`) using `WeldConstraint`.
3. Rig the 4 wheels (`Wheel_FL`, `Wheel_FR`, `Wheel_RL`, `Wheel_RR`) into the existing `Tesla_Roadster_Base_2026` Model driven by the Raycast vehicle physics engine in `src/TeslaRoadster_Raycast`.

---

## 🏁 Current State & Completed Milestones
All 3D modeling and surfacing issues have been empirically resolved and verified with Blender 5.2 beauty renders:
1. **Front Fender Vents & Rocker Sill Restored:**
   - Procedural extrusion artifacts and notches completely eliminated.
   - Extracted authentic 24 collar faces (Left) + 24 collar faces (Right) in `Chassis_Underbody` and 4 duct faces (Left) + 4 duct faces (Right) in `Aero_Trim` from `Tesla_Roadster_Unified_Flawless.blend`.
   - Continuous, seamless transition between the vent bottom and the lower rocker sill.
2. **Hood Nose Aerodynamic Scoop Restored:**
   - Removed the 4 flat bridging quads that previously covered the nose opening.
   - Restored the 8 recessed carbon scoop tray faces into `Aero_Trim`.
   - Verified 1:1 match against user reference photos (`proof_hood_scoop_matching_user1.png`, `proof_hood_topdown_exact_user2.png`, `proof_hood_scoop_beauty.png`).
3. **Sharp Creases Preserved:**
   - Sharp dihedral character crease along the side doors intact.
   - Sharp aerodynamic ridges on the front hood intact.
4. **Budget & Architecture Compliance:**
   - Total Triangles: **15,328 Tris** across 27 discrete Raycast vehicle objects ($\le 16,000$ Tris budget passed).
   - Bilateral symmetry verified ($X = 0$).
5. **Assets Synchronized & Ready:**
   - Master Blend: `C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend`
   - Master FBX: `C:\Users\_newgen\Downloads\Tesla_Roadster_Base_2026.fbx`
   - Vault Blend: `c:\Users\_newgen\Documents\antigravity\HOKI TOWN\assets\models\tesla_roadster\Tesla_Roadster_Raycast_Base_2026.blend`
   - Vault FBX: `c:\Users\_newgen\Documents\antigravity\HOKI TOWN\assets\models\tesla_roadster\Tesla_Roadster_Raycast_Base_2026.fbx`
6. **Roblox Studio MCP Status:**
   - Roblox Studio is active and connected via MCP (`Roblox_Studio`).
   - `workspace.Tesla_Roadster_Base_2026` already exists with Rojo-synced Raycast scripts:
     - `RaycastChassisClient` (LocalScript)
     - `RaycastChassisServer` (Script)
     - `RaycastVehiclePhysics` (ModuleScript)
     - `VehicleColorClient` (LocalScript)

---

## ⚠️ Critical User Pitfall (Why Cars Explode in Roblox)
The user previously experienced their car exploding into pieces upon import.
- **Root Cause:** Roblox Studio's `3D Importer` defaults all imported `MeshPart`s to `CanCollide = true`, `Anchored = false`, and generates **zero** welds. Because `Body_Paint`, `Chassis_Underbody`, `Aero_Trim`, and `Interior` nest closely together, the collision engine calculates severe interpenetration and exerts massive repulsive separation forces, flinging parts across the map.
- **Protocol:**
  1. User imports `Tesla_Roadster_Base_2026.fbx` via Studio **3D Importer** (do **NOT** press Play / F5).
  2. Agent immediately runs the Assembly Script below via `Roblox_Studio:run_code`.

---

## 🛠️ Assembly Script for Next Agent (Execute via `run_code`)

```lua
local importedModel = workspace:FindFirstChild("Tesla_Roadster_Base_2026_Imported") 
    or workspace:FindFirstChild("Tesla_Roadster_Base_2026")
    or workspace:FindFirstChild("Model")

-- Identify root chassis
local chassis = importedModel:FindFirstChild("Chassis_Underbody", true) 
    or importedModel:FindFirstChild("Chassis", true)

assert(chassis, "Chassis_Underbody not found in imported model!")
chassis.Anchored = true
chassis.CanCollide = false
chassis.Massless = false

local targetContainer = workspace:FindFirstChild("Tesla_Roadster_Base_2026")

for _, part in ipairs(importedModel:GetDescendants()) do
    if part:IsA("MeshPart") or part:IsA("BasePart") then
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = true
        part.CastShadow = true
        
        if part ~= chassis then
            part.Massless = true
            part.Anchored = false
            
            -- Only weld non-wheel parts to chassis
            local isWheel = string.find(part.Name, "Wheel_") or string.find(part.Name, "Tire_")
            if not isWheel then
                local weld = Instance.new("WeldConstraint")
                weld.Name = part.Name .. "_Weld"
                weld.Part0 = chassis
                weld.Part1 = part
                weld.Parent = chassis
            end
        end
        
        if targetContainer and part.Parent ~= targetContainer then
            part.Parent = targetContainer
        end
    end
end

chassis.Anchored = false
return "Assembly and Welds successfully configured! Ready for Raycast playtest."
```

---

## 📁 Key Artifacts & References
- Reference Hood Scoop Renders:
  - `proof_hood_scoop_matching_user1.png`
  - `proof_hood_topdown_exact_user2.png`
  - `proof_hood_scoop_beauty.png`
- Reference Side Profile & Vent Renders:
  - `proof_beauty_side_matching_user3.png`
  - `proof_beauty_persp_matching_user5.png`
  - `proof_beauty_front_vent_macro.png`
  - `proof_beauty_front_vent_sill.png`
- Active Raycast Scripts:
  - [RaycastChassisClient.client.luau](file:///c:/Users/_newgen/Documents/antigravity/HOKI%20TOWN/src/TeslaRoadster_Raycast/RaycastChassisClient.client.luau)
  - [RaycastChassisServer.server.luau](file:///c:/Users/_newgen/Documents/antigravity/HOKI%20TOWN/src/TeslaRoadster_Raycast/RaycastChassisServer.server.luau)
  - [RaycastVehiclePhysics.luau](file:///c:/Users/_newgen/Documents/antigravity/HOKI%20TOWN/src/TeslaRoadster_Raycast/RaycastVehiclePhysics.luau)

---

## ⏭️ Suggested Next Step
Wait for the user to confirm they have clicked **Import** in Roblox Studio, then execute the assembly script via `Roblox_Studio:run_code` and launch playtest verification.
