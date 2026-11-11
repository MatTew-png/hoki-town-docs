import bpy
import bmesh
from mathutils import Vector

def compare_bp():
    bpy.ops.wm.open_mainfile(filepath=r"C:\Users\_newgen\Downloads\Tesla_Roadster_Unified_Flawless.blend")
    bp_orig = bpy.data.objects.get("Body_Paint")
    v_orig = [v.co.copy() for v in bp_orig.data.vertices]
    f_orig = [tuple(p.vertices) for p in bp_orig.data.polygons]
    print(f"ORIGINAL BP: {len(v_orig)} verts, {len(f_orig)} faces")

    bpy.ops.wm.open_mainfile(filepath=r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend")
    bp_mast = bpy.data.objects.get("Body_Paint")
    v_mast = [v.co.copy() for v in bp_mast.data.vertices]
    f_mast = [tuple(p.vertices) for p in bp_mast.data.polygons]
    print(f"MASTER BP: {len(v_mast)} verts, {len(f_mast)} faces")

    # Check which parts were removed from BP in Master
    # Let's find vertices in ORIG that have no close match in MASTER
    missing_in_master = []
    for vo in v_orig:
        closest_d = min((vo - vm).length for vm in v_mast)
        if closest_d > 0.05:
            missing_in_master.append((closest_d, vo))
    print(f"Vertices in ORIG missing in MASTER (dist > 0.05): {len(missing_in_master)}")
    if missing_in_master:
        print("Sample missing verts in ORIG:")
        for d, v in sorted(missing_in_master, key=lambda x: x[0], reverse=True)[:10]:
            print(f"  d={d:.3f}: ({v.x:.3f}, {v.y:.3f}, {v.z:.3f})")

compare_bp()
