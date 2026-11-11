---
project: HOKI TOWN
category: technical-handover
doc_type: agent-handoff
date: 2026-11-09
status: ready
target: vehicle-scripting
tags:
  - handoff
  - roblox
  - rojo
  - luau
  - raycast-vehicle
  - vehicle-physics
---

# 🏎️ Engineering Handoff: 3D Model Handoff & Vehicle Scripting Pivot

> **Topic:** Transition from 3D Asset Refinement to Core Vehicle Scripting (Driving, Steering, Braking, Reversing, Air Control/Jump, Curb Climbing)  
> **Status:** 3D Model Verified & Frozen; Scripting Phase Active  
> **Target Skill / Domain:** `roblox-game-development-lifecycle` / `roblox-vault-router` / Luau Scripting

---

## 🎯 1. Goal for Next Session

**Pivot 100% to Luau Vehicle Scripting:**
The user's immediate priority is scripting the vehicle mechanics to achieve a fully functional, tactile driving experience in Roblox Studio:
1. **Drive & Accelerate (วิ่ง):** Smooth forward throttle via VectorForce.
2. **Steer & Counter-Steer (เลี้ยว):** Dynamic lateral tire friction and drift counter-steering.
3. **Brake & Handbrake (เบรค / ดริฟต์):** Hard braking deceleration and Spacebar drift release.
4. **Reverse (ถอย):** Clean backward torque with reverse gear speed limit.
5. **Air Control / Mid-Air Attitude (เหิน):** Gyro / AngularVelocity attitude leveling during jumps + landing damper to eliminate rebound.
6. **Curb Climbing Assist (ไต่):** Forward raycast detection of curbs/steps up to 2.1 studs with automated nose-lift impulse.

*Note on 3D Model:* 3D modeling work is **paused** per user request ("ส่วนโมเดล เดะกลับมาทำต่อ ตอนนี้ต้องรีบทำ script ก่อน"). Do not modify the 3D meshes unless a hard blocker emerges during Studio assembly.

---

## 🏁 2. Current State: 3D Model Completed & Verified

The master asset pipeline is fully verified, saved, and exported:

- **Master Blend File:** `C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend`
- **Production FBX:** `C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.fbx` *(541,068 bytes)*
- **Total Polycount:** ~9,300 polygons across 27 modular objects (lightweight, highly optimized for 60+ FPS on mobile & desktop).

### Key Geometry Issues Resolved in Turn 7:
1. **Flank Scoop & Rear Quarter Seam (`Aero_Trim` vs `Body_Paint`):**
   - Deleted 4 duplicate clashing faces in `Aero_Trim` (`Face 4, 5` right, `Face 61, 62` left).
   - Bridged the 4-sided hole in `Body_Paint` with smooth quads. Zero see-through holes, zero Z-fighting.
2. **Headlights Sealed Housing Bucket & Fender Separation:**
   - Purged 28 legacy dashboard faces (`Y < 5.0`) from `Headlights_Housing`.
   - Built a deep 3D enclosed housing bucket chamber extending 0.22m inward with solid backplate in `Headlights_Housing`.
   - Assigned `Mat_Headlight_Housing_Dark` (Charcoal Metallic, Roughness 0.35) for crisp technical separation from the white fender (`Body_Paint`). Completely blocks any view into the engine bay or ground.
   - Positioned the cyan LED strip (`Headlights_Bulbs`) neatly along the upper housing shelf.
3. **Rear Diffuser Underside:**
   - Deleted the horizontal flat plate protruding beneath the diffuser fins. Diffuser fins are clean and aerodynamic.
4. **B-Pillar, Quarter Glass & Windows:**
   - `Body_Glass` sits flush against the B-pillar with zero cabin holes.
   - Quarter window diagonal wireframe edge dissolved into a single unified quad glass face.
5. **Front Hood Nose Slot:**
   - Front hood leading edge seamlessly sealed to bumper nose with continuous quads.
6. **Wheel Arch Geometry & Offset:**
   - Wheel track calibrated: all 4 wheels (`Tire`, `Wheel`, `Rotor`, `Caliper`) sit tucked cleanly inside the fender arches.

---

## 📐 3. Roblox Studio DataModel Assembly Contract (Crucial for Scripting)

To wire the FBX model to the vehicle physics script in Roblox Studio, enforce this exact hierarchy and property setup:

```
TeslaRoadster_Raycast (Model)
├── Chassis_Collider (BasePart) [RootPart: CanCollide=true, Massless=false, Transparency=1]
├── DriveSeat (VehicleSeat) [CanCollide=false, Welded to Chassis_Collider]
├── Wheels (Folder or Model)
│   ├── FL (BasePart / Assembly) [Anchored=true, CanCollide=false, Massless=true, UNWELDED]
│   ├── FR (BasePart / Assembly) [Anchored=true, CanCollide=false, Massless=true, UNWELDED]
│   ├── RL (BasePart / Assembly) [Anchored=true, CanCollide=false, Massless=true, UNWELDED]
│   └── RR (BasePart / Assembly) [Anchored=true, CanCollide=false, Massless=true, UNWELDED]
├── Calipers (Folder or Model)
│   ├── Caliper_FL (BasePart) [Anchored=true, CanCollide=false, Massless=true, UNWELDED]
│   ├── Caliper_FR (BasePart) [Anchored=true, CanCollide=false, Massless=true, UNWELDED]
│   ├── Caliper_RL (BasePart) [Anchored=true, CanCollide=false, Massless=true, UNWELDED]
│   └── Caliper_RR (BasePart) [Anchored=true, CanCollide=false, Massless=true, UNWELDED]
└── Body (Folder or Model)
    ├── Body_Paint, Body_Glass, Chassis_Underbody, Aero_Trim, etc.
    └── (All parts: CanCollide=false, Massless=true, WeldConstraint to Chassis_Collider)
```

> [!IMPORTANT]
> **Wheel & Caliper Assembly Rules:**
> 1. In FBX, each wheel is 3 meshes: `Wheel_*` (rim) + `Tire_*` (tire) + `Brake_Rotor_*` (rotor). In Studio, weld these 3 together into a single wheel assembly named `FL`, `FR`, `RL`, `RR`.
> 2. Wheels and Calipers **MUST NOT be welded to the chassis**. They are anchored and driven via CFrame in `RunService.RenderStepped` / `Heartbeat` by the client raycast solver.
> 3. Calipers **MUST NOT be welded to wheels** (they steer with the wheel in yaw, but do not tumble/spin in pitch).

---

## 💻 4. Codebase & Scripting Assets Ready to Deploy

All core logic already exists in the workspace under `src/`:

1. **Core Physics Engine:** [`src/TeslaRoadster_Raycast/RaycastVehiclePhysics.luau`](file:///c:/Users/_newgen/Documents/antigravity/HOKI%20TOWN/src/TeslaRoadster_Raycast/RaycastVehiclePhysics.luau)
   - 666 lines of pure client-side Raycast / Spherecast chassis physics.
   - Built-in `AirControl_Attachment` + `AngularVelocity` for mid-air attitude leveling.
   - Built-in `CurbAssist_ForceAttachment` + `VectorForce` for obstacle/curb climbing.
   - Built-in `LandingDamperMultiplier = 2.5` for smooth landings.
2. **Server Vehicle Lifecycle & Ownership:** [`src/TeslaRoadster/VehicleSystems.server.luau`](file:///c:/Users/_newgen/Documents/antigravity/HOKI%20TOWN/src/TeslaRoadster/VehicleSystems.server.luau)
   - Manages Network Ownership transfer to the driver upon sitting in `DriveSeat`.
   - Handles player entry/exit events and cleanup.
3. **Client GUI & HUD:** [`src/TeslaRoadster/CarStatusGui/VehicleStatusClient.client.luau`](file:///c:/Users/_newgen/Documents/antigravity/HOKI%20TOWN/src/TeslaRoadster/CarStatusGui/VehicleStatusClient.client.luau)
   - Tactile speedometer, gear indicator, battery/fuel meter.

---

## ❓ 5. Immediate Next Moves for Scripting

1. **Verify / Update Driver Bootstrap Script:**
   - Create or verify a dedicated client bootstrap script (e.g. `VehicleRaycastDriver.client.luau`) inside the car or `StarterPlayerScripts` that detects when `LocalPlayer` sits in `TeslaRoadster.DriveSeat`:
     ```luau
     local RaycastVehiclePhysics = require(ReplicatedStorage.TeslaRoadster_Raycast.RaycastVehiclePhysics)
     local controller = RaycastVehiclePhysics.Initialize(carModel)
     controller:Start()
     ```
2. **Tune Driving Parameters in `DEFAULTS`:**
   - Check wheel track (`HalfTrack = 2.755`), wheelbase (`FrontZ = -4.662`, `RearZ = 5.008`), and suspension stiffness to match the new FBX scale.
3. **Play Solo Verification:**
   - Connect Rojo, run Play Solo on `Workspace.Hoki_Proving_Grounds`, test drive, and verify steering responsiveness, drift grip, jump recovery, and curb climb assist.

---

## 🔗 6. Relevant File Links

- **Blender Master:** [Tesla_Roadster_Raycast_Master_2026.blend](file:///C:/Users/_newgen/Downloads/Tesla_Roadster_Raycast_Master_2026.blend)
- **Production FBX:** [Tesla_Roadster_Raycast_Master_2026.fbx](file:///C:/Users/_newgen/Downloads/Tesla_Roadster_Raycast_Master_2026.fbx)
- **Raycast Physics Solver:** [RaycastVehiclePhysics.luau](file:///c:/Users/_newgen/Documents/antigravity/HOKI%20TOWN/src/TeslaRoadster_Raycast/RaycastVehiclePhysics.luau)
- **Vehicle Systems Server:** [VehicleSystems.server.luau](file:///c:/Users/_newgen/Documents/antigravity/HOKI%20TOWN/src/TeslaRoadster/VehicleSystems.server.luau)
- **Technical Architecture Manual:** [FEAT_01B_CDT_Arcade_Vehicle_Overhaul.md](file:///c:/Users/_newgen/Documents/antigravity/HOKI%20TOWN/01_Features_Deep_Dive/FEAT_01B_CDT_Arcade_Vehicle_Overhaul.md)
