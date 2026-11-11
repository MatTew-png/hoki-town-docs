# Work Order: Rebuild Tesla Master Chassis and Authentic Blueprint Wheels

## 1. Objective
Procedurally rebuild and refine the Tesla Roadster (2nd Gen) 3D asset in Blender 5.2 to eliminate all mesh defects identified in user screenshots (pinched/crumpled doors, dented hood, cyan holes in rear diffuser, floating spoiler) and construct the authentic 7 twin-spoke turbine concave wheel and 370mm ventilated brake assembly directly matching Blueprint Image 10.

## 2. Defects to Eliminate (Root Causes & Solutions)
1. **Crumpled/Pinched Doors & Flanks (Image 7):**
   - Cause: `Subdivision Surface` modifier applied to an open-boundary, non-manifold triangulated low-poly game mesh.
   - Fix: Completely remove `Subdivision Surface` modifiers from all body meshes (`Body_Paint`, `Door_FL`, `Door_FR`). Use `WeightedNormal (keep_sharp=True, weight=100)` with marked sharp edges on character lines. Re-seal door perimeter with solid closed hem flanges and clean 0.015 stud shutlines.
2. **Dented / Wavy Front Hood & Nose (Image 3 vs Image 4):**
   - Cause: Non-planar pole vertices smoothed unevenly.
   - Fix: Re-smooth hood vertex elevation along the compound curve from cowl to nose, enforce bilateral symmetry across X=0, and restore crisp character crease ridges flowing into headlights.
3. **Rear Diffuser Cyan Holes & Floating Spoiler (Image 1 vs Image 2):**
   - Cause: Open holes cut in lower rear bumper showing untextured underbody; spoiler floating 0.16 studs above decklid.
   - Fix: Solidify rear diffuser with closed aero tunnel and 2 vertical center aero fins matching Image 2 (`REAR ELEVATION`). Lower ducktail spoiler flush into decklid pocket.
4. **Authentic Blueprint Wheel & Brake Assembly (Image 9 vs Image 10):**
   - Build 7 twin-spokes (14 branches in Y-pairs) with full 3D solid cross-section, beveled chamfers, and concave dish profile.
   - Recessed 5-lug bolt circle with central aero cap.
   - 370mm ventilated steel rotor with cross-drilled cooling holes, directional gas slots, internal radial cooling vanes, and aluminum mounting hat with 10 bobbin bolts.
   - Brembo 6-piston monobloc caliper at 3 o'clock position (with caliper body bridge, pad retention pins, and dual bleeders) in glossy Brembo red.
   - Secondary EPB parking caliper at 12 o'clock on rear wheels.
   - Maintain strict Roblox Raycast physics HalfTrack $\pm 2.755$ studs.

## 3. Execution Target
Produce a standalone Python script `scratch/execute_master_rebuild.py` that loads `Tesla_Roadster_Apex_GT_Master.blend` (or pristine base), executes the geometric reconstruction, applies luxury PBR materials, and exports both `.blend` and `.fbx` to `.scratch/` and `Downloads/`.
