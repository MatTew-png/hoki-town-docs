# 🏎️ Engineering Handoff: Vehicle Proving Grounds Trio Architecture

> **Date:** 2026-11-08  
> **Topic:** 3-Lane Chassis Comparison (`TeslaRoadster` A-Chassis vs `TeslaRoadster_Raycast` vs `TeslaRoadster_NGChassis`)  
> **Status:** Ready for User Playtest & Decision  
> **Next Recommended Skill:** `roblox-game-development-lifecycle` or `roblox-debugging-bugfix`

---

## 🎯 1. Goal for Next Session
1. **User Test Drive & Chassis Selection:**
   - The user will test-drive all three cars on `Workspace.Hoki_Proving_Grounds` in Roblox Studio Play Solo:
     - **Lane 1 (Sky Blue `#00D2FF`):** Car 1 (`TeslaRoadster` - A-Chassis v1.5+ Physical Drift Tune).
     - **Lane 2 (Cyber Orange `#FF8C00`):** Car 2 (`TeslaRoadster_Raycast` - Raycast Arcade 2.0).
     - **Lane 3 (Neon Green `#00FF66`):** Car 3 (`TeslaRoadster_NGChassis` - NGChassis Constraint / Arcade Hybrid).
   - Gather feedback on which handling style fits **HOKI TOWN** (Roleplay realism vs snappy arcade drift).
2. **Next Feature Pipeline:**
   - Once chassis preference is chosen, wire up Category 2 (Gas Stations & Fuel Drain) and Category 3 (Crash Damage & Repair Points).

---

## 🏁 2. Current State & Resolved Blockers

### A. Resolved: Giant Cyan Bounding Box Bug
- **Symptom:** Selecting Car 1 in Studio showed a blue selection box stretching 45 studs high.
- **Root Cause:** Detached `Wheels` at `Z = 2964` and misplaced `ImpactSensors` in `TeslaRoadster.Body` (`Front` at `Z = -35.2`, `Rear` at `Y = 6.26`).
- **Fix:** Repositioned `ImpactSensors` flush inside the bumpers at `Y = 2.30` and re-aligned wheels. All 3 cars now have a tight `(7.5 - 9.1, 6.0, 16.6)` bounding box fitting the body.

### B. Resolved: Car 1 Falling Through Map on Play
- **Symptom:** Pressing Play caused Car 1 to fall through the road into the void (-500 Studs).
- **Root Cause (Empirical Proof):**
  1. Wheel parts (`Wheels.FL/FR/RL/RR`) were set to `Anchored = false` with NO welds to the chassis during Edit Mode.
  2. `Initialize.server.luau` had `task.wait(Tune.LoadDelay)` (0.1s) before building suspension.
  3. Wheels had `CanCollide = false`, and all body parts + `#Weight` had `CanCollide = false`.
  4. In that 0.1s window, the unwelded, non-collidable wheels fell through the map due to gravity. When `Initialize` resumed and called `Unanchor(car)`, the entire chassis collapsed into the abyss.
- **Fix:**
  - Enforced `Anchored = true` on wheels in Edit Mode (standard A-Chassis resting state).
  - Enforced `CanCollide = true` on the 4 wheel cylinders.
  - Patched `Initialize.server.luau` to explicitly enforce `v.CanCollide = true` dynamically.
  - Added `UnderbellySkidPlate` inside `TeslaRoadster.Body` (`Size: 5.8, 0.3, 11.0`, `Massless = true`, `CanCollide = true`, `Friction = 0.01`) as an emergency collision guard preventing chassis clipping on harsh landings.
  - Verified in Play Solo: Car 1 stays solidly poised at `Y = 3.60` with zero fall-through.

### C. Completed: Car 3 NGChassis Implementation
- Built by OpenCode Go (`opencode-go/deepseek-v4-pro`):
  - `src/TeslaRoadster_NGChassis/NGChassisConfig.luau` (TopSpeed 190, Reverse 55, Accel 120, Brake 170, Steer 30°).
  - `src/TeslaRoadster_NGChassis/NGChassisServer.server.luau` (Driver seat lock, Network Ownership handoff, Attributes).
  - `src/TeslaRoadster_NGChassis/NGChassisClient.client.luau` (RunContext = Client, Dual WASD + VehicleSeat input, PD Spring suspension, visual wheel steer/spin).
  - Deployed to `Workspace.TeslaRoadster_NGChassis` on Lane 3 at `(6.0, 2.8, -28.0)`.

---

## 🔌 3. Active Daemons & Infrastructure State

| Service | Endpoint / Task | Status | Operational Notes |
| :--- | :--- | :--- | :--- |
| **Rojo Server** | `localhost:34872` (Task `task-2283`) | **RUNNING** (HTTP 200) | Single Source of Truth for `src/`. If user sees WebSocket 400 in Studio, click **"Okay"** then **"Connect"**. |
| **Studio Bridge** | `scratch/rbx.py` via `rbx-studio-mcp.exe` | **READY** | Instant Luau execution in Studio DataModel via stdio MCP. |
| **OpenCode Go** | `.agents/skills/delegate-worker/scripts/run-subagent.sh` | **READY** | Used for heavy Luau scripting tasks via DeepSeek V4 Pro. |

---

## 🗺️ 4. Vehicle Comparison Matrix on Proving Grounds

```
           [SpawnLocation: X=-18, Y=0.5, Z=-10]
                             |
    +------------------------+------------------------+
    |                        |                        |
[Lane 1: X = -18]        [Lane 2: X = -6]         [Lane 3: X = +6]
Car 1: A-Chassis         Car 2: Raycast Arcade    Car 3: NGChassis
- Sky Blue (#00D2FF)     - Cyber Orange (#FF8C00) - Neon Green (#00FF66)
- Physical Springs       - Laser Raycast Springs  - PD Constraint Springs
- Auto Gearbox           - Direct Arcade Torque   - AssemblyLinearVelocity
- Weighty Inertia        - Crisp Counter-Steering - Lightweight & Responsive
```

---

## ❓ 5. Key Unresolved Decisions for Next Agent
1. **Chassis Selection:**
   - Did the user prefer Car 1 (A-Chassis), Car 2 (Raycast Arcade), or Car 3 (NGChassis)?
   - If user wants a blend (e.g. NGChassis responsiveness with A-Chassis weight transfer), adapt the winning script accordingly.
2. **Next Feature:**
   - Connect Fuel Station Pad (`Workspace.Hoki_Proving_Grounds.Hoki_GasPad`) to the winning car's `Fuel` attribute.
   - Connect Repair Pad (`Workspace.Hoki_Proving_Grounds.Pad_LowHealth`) to restore `Health` to 100%.

---

## ↩️ 6. Return Instructions
- Pick up from this document.
- If user has tested the cars: ask for their ranking/preference (Car 1, Car 2, or Car 3).
- If user hasn't tested yet: instruct them to click **Connect** in Rojo 7.7.1 and hit **Play Solo** in Studio.
