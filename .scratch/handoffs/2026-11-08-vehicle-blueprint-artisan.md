# 🚗 Handoff: Vehicle Blueprint Artisan Pipeline & Tesla Roadster Asset Suite

**Date:** 2026-11-08  
**Topic:** Automotive 3-Prompt Blueprint Generation, Universal 6-Color Zones, and Roblox Modular Mesh Architecture  
**Author:** Antigravity (Lead Orchestrator)

---

## 🎯 1. Goal for Next Session

1. **Option A (New Vehicle Blueprinting):** When the user provides a reference photo of another vehicle (e.g., *Honda ADV350* or any car/bike), execute the **3-Prompt Handshake Protocol** from `vehicle-blueprint-artisan` to immediately output the 3 ready-to-copy Master Prompts (Exterior CAD 4-View, Wheel/Brake Assembly, Color ID Map).
2. **Option B (3D Modeling & Mesh Construction):** Use the 4 verified Tesla Roadster blueprint sheets to build or align the 3D model in Blender, partitioned into the 6 standardized MeshParts (`Body_Main`, `Aero_Trim`, `Wheels_Rims`, `Brake_Calipers`, `Lights_DRL`, `Canopy_Glass`).
3. **Option C (Roblox Scripting & Token Burning):** Offload the implementation of the Luau `VehicleColorService` (Paint Shop UI + 6-Zone RGB Color Picker + ProfileStore serialization) to headless **OpenCode** before tonight's token reset.

---

## 📊 2. Current State & What Was Accomplished

1. **Game-Ready Prompt Optimization Completed:**
   - Identified and eliminated high-poly bottlenecks (removed 3D tire tread cuts, removed drilled rotor boolean holes, removed interior cockpit line clutter).
   - Prompts refined and permanently installed in `SKILL.md` across workspace, user config, and global agent roots.
2. **Verified Game-Ready Tesla Roadster (2nd Gen) Blueprint Suite Ingested:**
   - Saved permanently in repository at `assets/blueprints/tesla_roadster_gen2/`:
     - `01_exterior_cad_4view.jpg`: Clean closed canopy, zero interior clutter, 4-view orthographic with datum guide lines.
     - `02_wheel_rim_assembly.jpg`: 10-spoke radial symmetry rim (Radial Array ready), concavity dish profile, solid flat rotor, low-poly caliper, smooth game tire profile.
     - `03_modular_color_id.jpg`: Solid flat 6-zone map explicitly matching Roblox MeshParts (`Body_Main`, `Aero_Trim`, `Wheels_Rims`, `Brake_Calipers`, `Lights_DRL`, `Canopy_Glass`).
3. **Master Blender 3D Model Repaired & Symmetrized (Exit Code 0):**
   - Dissected merged wheels and calipers from `Tesla_Roadster_Unified_Flawless.blend`.
   - Separated into 4 independent wheel objects (`Wheel_FL`, `Wheel_FR`, `Wheel_RL`, `Wheel_RR`) combining clean Rims (848 verts) + Tires (192 verts) at 840 tris each.
   - Symmetrized wheel centers to exact Raycast HalfTrack $\pm 2.755\text{ studs}$ ($X = \pm 2.755, Y = 4.765 / -4.941, Z = 1.166 / 1.224$).
   - Symmetrized calipers into 4 independent objects (`Caliper_FL`, `Caliper_FR`, `Caliper_RL`, `Caliper_RR`) at $X = \pm 2.670 / \pm 2.666$.
   - Created `Chassis_Collider` ski-chamfered RootPart with full raycast and lighting attachments.
   - Exported master production assets:
     - `C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend` & `.fbx`
     - `.scratch\Tesla_Roadster_Raycast_Master_2026.blend` & `.fbx`
4. **OpenCode Autonomous Luau Implementation Completed (Exit Code 0, $0.095):**
   - Offloaded Work Order `.agents/workorders/implement_vehicle_color_service.md` to `deepseek-v4-pro`.
   - Implemented `src/ReplicatedStorage/VehicleColorService.luau` (`--!strict`) with complete 6-zone mappings, material/transparency overrides, and palette serialization.
   - Implemented `src/TeslaRoadster_Raycast/VehicleColorClient.client.luau` wired to native `PaletteColor_<Zone>` attributes.
   - Updated `default.project.json` to expose `VehicleColorService` and client applicator under Rojo.

---

## 🤝 3. The Established 3-Prompt Handshake Protocol

When the user uploads a vehicle photo:
```text
Step 1: User sends reference vehicle photo.
Step 2: Agent immediately outputs the 3 tailored Master Prompts:
        - Prompt 1: Exterior CAD 4-View (Pure B&W Line Art)
        - Prompt 2: Wheel, Tire & Brake Dedicated Assembly Sheet (CAD B&W with Cross-Section)
        - Prompt 3: Modular Color ID & 6-Color Zone Specification Map (Color-Blocked)
Step 3: User generates the 3 images in external Image AI (Midjourney/Flux) and pastes them back.
Step 4: Agent ingests the 3 images -> Blender 3D modeling / OpenCode Luau scripting.
```

---

## 📁 4. Relevant Artifacts & Paths

- **Permanent Skill:** [SKILL.md](file:///c:/Users/_newgen/Documents/antigravity/HOKI%20TOWN/.agents/skills/vehicle-blueprint-artisan/SKILL.md)
- **Verified Generated Images:**
  - Showcase Presentation Board: `media_1794140084545_f9e8d843.jpg`
  - Exterior CAD 4-View: `media_1794140311661_635f31c7.jpg`
  - Wheel & Brake CAD Assembly: `media_1794140471647_e6f747b1.jpg`
  - Color ID 6-Zone Specification: `media_1794140687146_6e6f7609.jpg`
- **OpenCode Config:** `C:\Users\_newgen\.config\opencode\opencode.jsonc`
- **Subagent Script:** `.agents/skills/delegate-worker/scripts/run-subagent.sh`
- **Work Orders:** `.agents/workorders/implement_ngchassis_car3.md`, `fix_vehicle_drive_system.md`

---

## 🧭 5. Suggested Next Command / Action

- If processing a new vehicle photo: Apply `vehicle-blueprint-artisan` to immediately generate the 3 Master Prompts.
- If modeling in Blender: Apply `blender-roblox-rig-mastery` or `blender-modeler` to drop the B&W CAD sheets into viewports.
- If implementing Roblox customization code: Use `delegate-worker` with OpenCode to create `src/ReplicatedStorage/VehicleColorService.luau` and wire it up to the existing `TeslaRoadster` models on `Hoki_Proving_Grounds`.
