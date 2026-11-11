import bpy
from mathutils import Vector

def inspect_underbody(blend_path, label):
    print(f"\n--- {label}: {blend_path} ---")
    bpy.ops.wm.open_mainfile(filepath=blend_path)
    cu = bpy.data.objects.get("Chassis_Underbody")
    if cu:
        print(f"Chassis_Underbody found: {len(cu.data.vertices)} verts, {len(cu.data.polygons)} faces")
        # Check normal directions and Z distribution
        bottom_faces = [f for f in cu.data.polygons if f.normal.z < -0.5]
        print(f"Faces with downward normal (Z < -0.5): {len(bottom_faces)}")
        # Check bounding box of bottom faces
        z_vals = [v.co.z for v in cu.data.vertices]
        print(f"Z range: min={min(z_vals):.3f}, max={max(z_vals):.3f}, median={(sorted(z_vals)[len(z_vals)//2]):.3f}")
        # Check visibility / collections
        print(f"Users collections: {[c.name for c in cu.users_collection]}")
        print(f"Hide viewport: {cu.hide_viewport}, Hide render: {cu.hide_render}")
        print(f"Materials: {[m.name for m in cu.data.materials if m]}")
    else:
        print("Chassis_Underbody NOT FOUND!")

    # Check all objects with Z < 1.0 (underbody level)
    print("Objects with parts below Z=1.0:")
    for o in bpy.data.objects:
        if o.type == 'MESH':
            z_min = min(v.co.z for v in o.data.vertices)
            if z_min < 1.0:
                print(f"  {o.name}: z_min={z_min:.3f}, total verts={len(o.data.vertices)}")

inspect_underbody(r"C:\Users\_newgen\Downloads\Tesla_Roadster_Unified_Flawless.blend", "ORIGINAL")
inspect_underbody(r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend", "CURRENT MASTER")
