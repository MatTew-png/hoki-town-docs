---
project: HOKI TOWN
category: technical-handover
doc_type: agent-handoff
target_agent: OpenCode Go
date: 2026-11-07
status: ready
tags:
  - handoff
  - opencode-go
  - roblox
  - rojo
  - vehicle-chassis
---

# 🚀 Engineering Handoff: HOKI TOWN Vehicle Architecture for OpenCode Go

> **For OpenCode Go**: This document provides the complete technical context, exact file locations, active daemon states, and resolved pitfalls so you can immediately continue development without breaking existing systems or rereading past chat history.

---

## 📌 1. Mission & Goal
Continue developing the **Hybrid Vehicle System** for **HOKI TOWN** in Roblox Studio:
* **Driving Style**: Hybrid CDT-style Arcade Drift + FiveM-style Roleplay realism (Crash damage, fuel drain, repair/refuel).
* **Current Focus**: Polish Category 1 (Handling & Drift Physics), then integrate Category 2 (Gas Stations & Repair Economy).

---

## ⚡ 2. Core Operational Workflow: Rojo Hybrid Development
**CRITICAL**: All AI agents working on this project must follow the Hybrid Architecture in [[.agent/rules.md]] and `AGENTS.md`:

```
Local Files (`src/**/*.luau`)  ==[Rojo 7.7.1]==>  Roblox Studio DataModel (`Workspace.TeslaRoadster`)
```

* **Rojo = Single Source of Truth for Code**:
  * **DO NOT** edit script `.Source` directly via Studio command bar or MCP.
  * Always edit `.luau` files on disk inside `src/` and let Rojo sync into Studio.
* **Studio = 3D World & Diagnostics**:
  * 3D Meshes, Collision geometry, and Terrain stay in Roblox Studio.
  * Use Output Log (`LogService`) for runtime verification.

### Active Daemons:
* **Rojo Server**: Running in background on `localhost:34872`.
  * If stopped, restart via command: `rojo serve` in project root.
  * Project configuration: `default.project.json` (uses `$ignoreUnknownInstances: true` to prevent deleting 3D parts).

---

## 📂 3. Codebase Map (`src/TeslaRoadster/`)

| File Path | Role | Key Functions / Logic |
| :--- | :--- | :--- |
| `src/TeslaRoadster/A-Chassis Tune/A-Chassis Interface/Drive.client.luau` | **Client Drive & Input** | 2-pedal tap-to-drift (`_BrakePressTimestamp < 0.35s`), `HokiSpacebarHandbrakeSink` (ContextActionService Priority +3000 to prevent character jump ejection), mobile controls, HUD output. |
| `src/TeslaRoadster/A-Chassis Tune/Initialize.server.luau` | **Chassis Assembly** | `Zero-Duplicate Guard` (purges old welds/hinges before building), unanchors all parts dynamically, handles `handleDriverSit` (sets network ownership & clones GUI). |
| `src/TeslaRoadster/A-Chassis Tune/init.luau` | **Physics & Tuning Config** | Engine torque (`Tune.PeakTorque = 3198 lb-ft`), gear ratios, `Tune.LoadDelay = 0.5s`, drift power multipliers. |
| `src/TeslaRoadster/VehicleSystems.server.luau` | **Server Roleplay Engine** | 5-tier directional impact damage (12-85 studs/s), fuel consumption based on speed, health/fuel attributes on model. |
| `src/TeslaRoadster/CarStatusGui/VehicleStatusClient.client.luau` | **Player HUD** | Displays real-time Health and Fuel status bars. |

---

## ⚠️ 4. Solved Traps & Pitfalls (DO NOT RE-INTRODUCE)

1. **The 153 Ghost Part Lockup (Physics Binding)**:
   * *Problem*: In previous iterations, running assembly in Edit Mode created duplicate `Arm`, `Base`, `Axle`, and 4x `HingeConstraint` per wheel, locking wheels completely rigid.
   * *Fix*: `Initialize.server.luau` now contains the **Zero-Duplicate Guard** at the start of `for _, v in Drive do` that automatically destroys stale instances before assembling.
2. **Cannot Sit in Car (CanCollide & Disabled)**:
   * *Problem*: `DriveSeat` was saved with `Disabled = true` and `CanCollide = false`.
   * *Fix*: `DriveSeat` is set to `Disabled = false`, `CanCollide = true`, `CanTouch = true`, and has a `ProximityPrompt` (`[E] ขับรถ (Drive)`) with fallback `seat:Sit(humanoid)`.
3. **Spacebar Avatar Ejection**:
   * *Problem*: Pressing Spacebar while driving ejected the avatar from the seat because Roblox default Jump is bound to Space.
   * *Fix*: `HokiSpacebarHandbrakeSink` sinks Spacebar at priority `High + 3000`, clamping the handbrake without jumping.
4. **Plugins nil Crash**:
   * *Problem*: `Initialize` crashed on `script.Parent.Plugins` because plugins were moved to `A-Chassis Interface`.
   * *Fix*: Handled with safe `FindFirstChild("Plugins")` check.

---

## 🎯 5. Completed Implementation by DeepSeek V4 Pro (Session `ses_1794070192_b4b0d5374ca4`)

- **Subagent Model**: `opencode-go/deepseek-v4-pro`
- **Tokens Consumed**: In: 210,189 | Cache Read: 1,940,480 | Out: 6,724 | Tool Calls: 35 ($0.236568)
- **Delivered Patches**:
  1. `Drive.client.luau`:
     - Initialized `_TMode = "Auto"` before `_CGear`; defaulted `_CGear = 1` (Drive) instead of 0/neutral.
     - `_PBrake = false` initialized and forced clear via `driveSeat.ChildAdded`.
     - Drive loop releases parking brake immediately on `driveCommand > 0.05 or _InThrot > 0.05`.
     - Full motor torque `tqOUT` delivered to wheel AngularVelocity on launch.
  2. `RaycastChassisClient.client.luau`:
     - Dual-input engine combining `UserInputService:IsKeyDown` (W/S/A/D) with `VehicleSeat` floats for 100% immediate responsiveness.
     - Damped PD spring hovering at `TARGET_HEIGHT = 2.80` studs without bottoming out.
     - Applied linear and angular velocities to `root = seat.AssemblyRootPart or seat`.
     - Added relative CFrame wheel steering (front) and wheel spin (all 4) via `PivotTo`.
- **Rojo Build Verification**: `rojo build --output scratch/test_build.rbxm` exited 0.
- **Studio Place Synced**: Live code injected into `Workspace.TeslaRoadster` and `Workspace.TeslaRoadster_Raycast`.

---

## 🎯 6. Recommended Next Steps for OpenCode Go

1. **Verify Driving in Studio**:
   - Press **Play Solo** in Studio (spawns at `-18, 0.5, -10` right in front of both cars).
   - Test Drive **Car 1 (Lane 1 - Sky Blue)**: `TeslaRoadster` (A-Chassis physics tune).
   - Test Drive **Car 2 (Lane 2 - Cyber Orange)**: `TeslaRoadster_Raycast` (Raycast arcade tune).
2. **Category 2: Gas Station & Mechanic Interaction**:
   - Create ProximityPrompt interactions at gas station pumps that trigger `VehicleSystems` refuel (raising `car:SetAttribute("Fuel", 100)`).
   - Create repair kits/mechanic shop prompts to restore `car:SetAttribute("Health", 100)` and extinguish smoke/fire.
3. **Multi-Vehicle Templating**:
   - Abstract `src/TeslaRoadster` so that future cars in `Workspace` (e.g. `Workspace.ToyotaAE86`, `Workspace.Porsche911`) can inherit the same modular structure via `default.project.json`.

---
*Updated by Antigravity after DeepSeek V4 Pro implementation on 2026-11-08.*
