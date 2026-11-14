# Handoff: HOKI TOWN Set 1 Vehicle Fleet, 3D Modeling/Coloring Standard & Next Execution

- **Date:** 2026-11-13
- **Target:** Next session continuing **3D Vehicle Blueprints/Modeling (`vehicle-blueprint-artisan` -> Blender)** and later **Unified Vehicle Chassis / `VehicleService` Refactoring (`roblox-vehicle-scripting` + `roblox-mvc-architecture`)**
- **Canonical Design Draft (Single Source of Truth for this Plan):** [10_Inbox/DRAFT_2026-11-13_Starter_EV_And_Vehicle_Rollout_Plan.md](../../10_Inbox/DRAFT_2026-11-13_Starter_EV_And_Vehicle_Rollout_Plan.md)

---

## 1. Goal for the Next Session
1. Confirm fictional in-game brand/model names (IP/DMCA safe) for all 10 Set 1 vehicles from Section 6 of the draft.
2. Execute the **first 3D modeling pipeline** starting with the Starter EV (**GWM ORA Good Cat** / proposed `Kairo Neko EV`) using `vehicle-blueprint-artisan` (3 Master Blueprint Prompts/sheets) scaled to `Workspace.TeslaRoadster_Scon`, following the locked 4-zone + static `Trim_Black` spec.
3. *(Once 3D models & coloring rules are cleared — user explicitly deferred scripting until models/coloring are settled)* Lock one canonical 4-wheel chassis (`Hoki-Chassis` vs `RaycastVehiclePhysics`) and centralize into `VehicleService` + `ServerStorage` before cloning scripts across 10 cars.

---

## 2. Current State (Decisions & Empirical Findings)
* **Scale & Baseline Reference:** `Workspace.TeslaRoadster_Scon`
  * Measured visible body span in Studio: `7.02 W x 3.89 H x 15.46 L` studs (wheelbase `9.67` studs, track `5.51` studs; `Hoki_Metropolis.01_Ground_Roads.Roads` lanes are `44–48` studs wide).
  * `ORA Good Cat` (Pro/Ultra `4,235 x 1,825 x 1,596 mm`, WB `2,650 mm`) target scale: `~6.5 W x ~5.7 H x ~15.0 L` studs, WB `~9.4` studs, **4 seats**, EV audio compatible with `EvSoundMix.luau`.
* **Locked 3D Modeling & Coloring Architecture (No Scripts Touched):**
  * **Static Parts (Non-colorable):** `Trim_Black` (merged `Aero_Trim` + `Chassis_Underbody` + wheel arches/bumpers), `Tire` (1 shared mesh), `Interior_Simple`/`Interior_Console`, `Lights_Head`/`Lights_Tail`, `License_Plate` (only part using `SurfaceAppearance`).
  * **Standard 4 Zones** *(Starter, Utility, regular Sports; budget `12k–22k Tris`)*: `Body_Main`, `Body_Secondary` (two-tone roof/stripes/trim), `Wheel_Rim` (1 shared mesh), `Canopy_Glass`.
  * **VIP / Top-Tier Package** *(Super Sports paid, Gacha, and category top-tier exceptions; budget `22k–35k Tris`)*: adds `Brake_Caliper` (+ `Brake_Rotor`, 1 shared set), `Lights_DRL`, `Underglow` (Studio-only, 0 Blender tris), `Body_Main` Paint Finish (`Matte`/`Metallic`/`Chrome`), and `Interior_Seats`.
  * **Blender Export Fixes Learned from `Tesla_Roadster_Refined_2026`:** That `.glb` measured `51,428 Tris` across `27` unique meshes (over budget) and Studio instances had rotated axes (`Y=15.45, Z=4.25`) + extra `CanCollide=true` parts. New models must export `+Y Up / -Z Forward`, white `#FFFFFF` base material on colorable meshes, single `Chassis_Collider`, and shared wheel `MeshId`.
* **Locked Set 1 Roster (10 Vehicles — All 4-Wheel / DRW, Motorcycles Deferred Last):**
  * Roster, Relative Design Tiers (`1–5`), and Post-Launch Backlog (`Scania R-Series`, `2019 Peterbilt 389`, `Toyota Alphard`, `Motorcycles`, Team Pool) are fully recorded in `10_Inbox/DRAFT_2026-11-13_Starter_EV_And_Vehicle_Rollout_Plan.md`.
* **Studio / Codebase Baseline Discovered:**
  * Two competing physics systems still exist in `src/` (`TeslaRoadster_Scon` Hoki-Chassis: `25` Scripts, `133` joints, `WallClimbEnabled=true`, `AirGravity=24`, `TapDriftEnabled=false`, single `PassengerSeat` lookup; vs `TeslaRoadster_Raycast` + `VehicleStats.luau`).
  * **Do NOT assign raw physics numbers yet** until one chassis is selected and calibrated.

---

## 3. Key Unresolved Questions
1. **Fictional Naming Approval:** Approve or adjust the 5-brand / 10-model fictional names in Section 6 of the draft.
2. **Blueprint Generation Mode for `ORA Good Cat`:** Does the user want **3 Master Prompts** to generate externally (per `vehicle-blueprint-artisan`), or generate draft sheets directly via `image-generator`?
3. **Chassis Consolidation (Deferred to Scripting Phase):** Choose `Hoki-Chassis` (`TeslaRoadster_Scon`) vs `RaycastVehiclePhysics` (`TeslaRoadster_Raycast`) + generalize `VehicleSystems.server.luau` (`Seats` multi-seat support, upright driver pose for hatchback/trucks, ICE combustion audio alongside `EvSoundMix`, and central `VehicleService` + Garage/Dealership Spawner).
4. **Refined Roadster Cleanup:** Optimize `Tesla_Roadster_Refined_2026` (`51,428` -> `25k–35k Tris`) and align its Studio orientation & color zones when migrating `TeslaRoadster_Scon`.

---

## 4. Relevant Artifacts
* **Primary Plan & Catalog Draft:** `10_Inbox/DRAFT_2026-11-13_Starter_EV_And_Vehicle_Rollout_Plan.md`
* **Blueprint Pipeline Skill:** `.agents/skills/vehicle-blueprint-artisan/SKILL.md`
* **Color SSOT:** `src/ReplicatedStorage/VehicleColorService.luau`
* **Upgrade Stats SSOT:** `src/ReplicatedStorage/VehicleStats.luau`
* **Active Scon Chassis Config & Server:** `src/TeslaRoadster_Scon/A-Chassis Tune/init.luau`, `src/TeslaRoadster_Scon/VehicleSystems.server.luau`, `src/TeslaRoadster_Scon/A-Chassis Tune/EvSoundMix.luau`
* **Raycast Chassis Reference:** `src/TeslaRoadster_Raycast/RaycastVehiclePhysics.luau`, `src/TeslaRoadster_Raycast/RaycastChassisServer.server.luau`
* **Existing Car Assets:** `assets/models/tesla_roadster/Tesla_Roadster_Refined_2026.glb` (`51,428 Tris`), `assets/blueprints/tesla_roadster_gen2/`

---

## 5. Suggested Next Skill & Return Instructions
* **Next Skill to Load:** `.agents/skills/vehicle-blueprint-artisan/SKILL.md` (followed by `vehicle-artist` / `blender-director` for Blender, then `roblox-vehicle-scripting` + `roblox-mvc-architecture` when moving to scripting).
* **First Concrete Action:** Ask the user to confirm the fictional names in Section 6, then immediately generate the **3 Master Blueprint Prompts (or sheets)** for the Starter EV (`ORA Good Cat` / `Kairo Neko EV`) at `12k–18k Tris`, `6.5 W x 5.7 H x 15.0 L` studs, 4-zone + `Trim_Black` layout.
* **Return Instructions:** Once `ORA Good Cat` blueprints/FBX are approved, update `10_Inbox/DRAFT_2026-11-13_Starter_EV_And_Vehicle_Rollout_Plan.md` (or promote verified specs to `01_Features_Deep_Dive/`) and hand back for chassis standardization & `VehicleService` implementation.
