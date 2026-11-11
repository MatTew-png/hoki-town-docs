# Work Order: Fix Roadster 3D Hard-Surface Architecture

## 1. Objective
Fix the 4 critical visual defects identified in user review:
1. Front Bumper Over-Blacking: Restore front nose & bumper fascia to Body Paint (Red). Keep ONLY lower splitter lip and intake opening in Matte Carbon.
2. Wheel Unification: Unify all 4 wheels (`Wheel_FL`, `Wheel_FR`, `Wheel_RL`, `Wheel_RR`) to share the exact same high-end split-spoke turbine rim design at HalfTrack +/- 2.755 studs.
3. Brake Disc Rotors: Construct 4 ventilated brake rotor discs (`Brake_Rotor_FL`, `FR`, `RL`, `RR`) positioned behind each wheel rim with metallic steel shader, clamped by 6-piston Brembo red calipers.
4. Door Panel Planarization: Smooth out the crumpled triangular facets and dents on both side doors (`Door_FL`, `Door_FR` / side body panels) for clean automotive reflections.

## 2. Target Files
- `scratch/build_apex_roadster_gt.py`
- `scratch/polish_and_render_apex_gt.py`
- Target Model: `Tesla_Roadster_Apex_GT_Master.blend` & `Tesla_Roadster_Raycast_Master_2026.blend / .fbx`

## 3. Implementation Contract
- Preserve exact Wheelbase & Track: HalfTrack +/- 2.755 studs.
- Keep Chassis_Collider, DriveSeat, Raycast attachments intact.
- Zero clown diagnostics: Professional PBR material palette.
