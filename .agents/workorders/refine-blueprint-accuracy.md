# Work Order: Refine Tesla Roadster to Match Official Blueprints

## 1. Objective
Execute a comprehensive blueprint-matching overhaul of the Tesla Roadster 3D model in Blender. Bring the Door Shut-Lines, Rear Diffuser & Aero, Greenhouse Glass & B-Pillars, and Materials into 100% alignment with the official 4-view blueprints (Side Profile `media_1794178715901_2d041317.png`, Rear Elevation `media_1794178856480_b0e6a08e.png`, Top Plan `media_1794178865934_bfd8d371.png`, and Front Elevation `media_1794178860971_50a6e153.png`).

## 2. Target Files
- Modify/Create: `scripts/refine_blueprint_accuracy.py`
- Output Blend: `C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend`
- Output FBX: `C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.fbx`
- Renders:
  - `C:\Users\_newgen\.gemini\antigravity\brain\a634876d-c794-428d-a197-2a958c3d6bb3\blueprint_side_comparison.png`
  - `C:\Users\_newgen\.gemini\antigravity\brain\a634876d-c794-428d-a197-2a958c3d6bb3\blueprint_rear_comparison.png`
  - `C:\Users\_newgen\.gemini\antigravity\brain\a634876d-c794-428d-a197-2a958c3d6bb3\blueprint_top_comparison.png`
  - `C:\Users\_newgen\.gemini\antigravity\brain\a634876d-c794-428d-a197-2a958c3d6bb3\blueprint_hero_34.png`

## 3. Implementation Contract
1. **Rear Diffuser (`Rear_Diffuser_Aero`):**
   - Extract the authentic 98-polygon aerodynamic rear diffuser from `C:\Users\_newgen\Downloads\Tesla_Roadster_Unified_Flawless.blend`'s `Body_Secondary_Carbon` (all polygons with $Y < -4.0$).
   - This geometry features the authentic arched center tunnel dome and the two vertical aerodynamic strakes/fins matching the rear blueprint (`media_1794178856480_b0e6a08e.png`).
   - Replace the 54-vertex flat box in `Tesla_Roadster_Raycast_Master_2026.blend`.
   - Ensure the diffuser tucks snugly under the rear bumper and meets `Chassis_Underbody` with zero see-through hollow gap into the car.
   - Assign `Mat_Aero_Forged_Carbon` (base color (0.03, 0.03, 0.03, 1.0), roughness 0.40, metallic 0.1).

2. **Door Shut-Lines (`Door_ShutLines`):**
   - REMOVE any horizontal beltline seam (`belt_samples`) across the painted door panel. Frameless supercar doors have continuous sheet metal from rocker sill to the window sill.
   - Reconstruct the authentic 3-sided frameless door shut-line system:
     - **Front Seam:** A-pillar base ($Y \approx 2.45, Z \approx 2.50$) dropping behind the fender badge down to the rocker sill ($Y \approx 2.61, Z \approx 0.50$).
     - **Bottom Rocker Seam:** Along the rocker sill ($Z \approx 0.50 - 0.54$) connecting front ($Y = 2.61$) to rear ($Y = -1.90$).
     - **Rear Haunch Seam:** From the B-pillar beltline sill ($Y \approx -1.38, Z \approx 2.47$) sweeping back along the muscular rear haunch curve `)` ($Y \approx -2.15, Z \approx 1.70$) down to the rocker sill ($Y = -1.90, Z \approx 0.54$).
   - Snap all spline samples strictly to `Body_Paint` using `bp.closest_point_on_mesh`.
   - Extrude into ribbon channels with `Mat_Door_ShutLine_Cavity` for both Left and Right sides.

3. **Greenhouse, Window Frames & Glass (`Body_Glass`, `Chassis_Underbody`):**
   - Assign `Mat_Glass_Tinted` to `Body_Glass`:
     - Base Color: `(0.04, 0.05, 0.06, 1.0)` (subtle dark tint).
     - Transmission: `0.85`, Roughness: `0.04`, IOR: `1.52`, Metallic: `0.05`.
   - Ensure `Chassis_Underbody` provides dark trim (`Mat_Chassis_Underbody_Trim`) for A-pillar seals, B-pillar structure, roof rail gaskets, and wheel wells with zero hollow pass-through.
   - In `Chassis_Underbody`, ensure the B-pillar vertices slope backwards at the correct rake angle matching the side blueprint (`media_1794178715901_2d041317.png`).
   - Elongate the quarter window opening backwards along $Y$ to match the aerodynamic fastback taper of the blueprint.

4. **Aero Trim & Active Rear Spoiler:**
   - Assign `Mat_Aero_Forged_Carbon` to `Aero_Trim`.
   - Verify the active rear spoiler sits aligned with the rear deck as shown in the rear and side blueprints.

5. **Universal Origin & Scale:**
   - All objects in `Body_Assembly` must have location `(0, 0, 0)`, rotation `(0, 0, 0)`, scale `(1, 1, 1)`.

6. **Render Verification Orthos:**
   - Side elevation orthographic render matching blueprint view.
   - Rear elevation orthographic render matching rear blueprint view.
   - Top plan orthographic render matching top blueprint view.
   - Front 3/4 perspective hero view.

## 4. Verification Command
`& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b "C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend" -P "scripts/refine_blueprint_accuracy.py"`
