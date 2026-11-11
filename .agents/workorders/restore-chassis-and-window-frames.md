# Work Order: Restore Chassis Underbody, Window Frames, and Polish Door Seams

## 1. Objective
Restore the missing window frames, pillars, roof seals, and underbody floor from `Tesla_Roadster_Unified_Flawless.blend` (Plane0015Mtl / Chassis_Underbody) into `Tesla_Roadster_Raycast_Master_2026.blend`, seal all panel/glass/roof gaps, eliminate the B-pillar shutline step marked by the user in `media_1794176227432_e501b896.jpg`, ensure Universal Origin (0,0,0), and export the updated production `.blend` and `.fbx`.

## 2. Target Files
- `scripts/restore_chassis_and_frames.py`

## 3. Implementation Contract
- **Root Cause Resolution:**
  - The raw model's `Plane0015Mtl` (3,112 vertices, 2,494 faces, named `Chassis_Underbody` in `Tesla_Roadster_Unified_Flawless.blend`) was inadvertently omitted in earlier passes.
  - It contains both the complete lower chassis undertray / wheel tubs and the upper window frames (A-pillar, B-pillar, quarter window border, roof rail seals).
  - OpenCode MUST extract `Chassis_Underbody` from `Tesla_Roadster_Unified_Flawless.blend` and append/link it into `Tesla_Roadster_Raycast_Master_2026.blend` under collection `Body_Assembly`.
- **Material Assignment:**
  - Assign `Mat_Chassis_Underbody_Trim` to `Chassis_Underbody`:
    - Base Color: `(0.02, 0.02, 0.02, 1.0)` (Satin Obsidian / Carbon Matte)
    - Roughness: `0.75`
    - Metallic: `0.1`
- **Door Shut-Line Polish at B-Pillar (User Circled Zone):**
  - Adjust `Door_ShutLines` so the rear seam meets the B-pillar window pillar flush and seamlessly, without the floating step/gap highlighted in `media_1794176227432_e501b896.jpg`.
  - Ensure the top beltline seam hugs the window sill perfectly.
- **Production Export & Integrity:**
  - All body mesh objects in `Body_Assembly` MUST have Origin at `(0, 0, 0)`, Rotation `(0, 0, 0)`, Scale `(1, 1, 1)`.
  - Overwrite `C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend`.
  - Re-export `C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.fbx` with face smoothing and scale applied.
- **Verification Renders:**
  - Render 1: Angle matching `media_1794176227432_e501b896.jpg` showing the resolved B-pillar junction, solid window frame, filled roof gaps, and sealed underbody. Saved to `C:\Users\_newgen\.gemini\antigravity\brain\a634876d-c794-428d-a197-2a958c3d6bb3\proof_restored_chassis_and_frames_side.png`.
  - Render 2: Side elevation ortho profile saved to `C:\Users\_newgen\.gemini\antigravity\brain\a634876d-c794-428d-a197-2a958c3d6bb3\proof_restored_chassis_and_frames_ortho.png`.
  - Render 3: Front 3/4 hero view saved to `C:\Users\_newgen\.gemini\antigravity\brain\a634876d-c794-428d-a197-2a958c3d6bb3\proof_restored_chassis_and_frames_hero.png`.

## 4. Verification Command
`& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b "C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend" -P scripts/restore_chassis_and_frames.py`
