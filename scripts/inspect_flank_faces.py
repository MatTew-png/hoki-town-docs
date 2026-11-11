import bpy
import bmesh
from mathutils import Vector

BLEND_PATH = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"
bpy.ops.wm.open_mainfile(filepath=BLEND_PATH)

bp = bpy.data.objects.get("Body_Paint")
cu = bpy.data.objects.get("Chassis_Underbody")

bm_bp = bmesh.new()
bm_bp.from_mesh(bp.data)
bm_bp.verts.ensure_lookup_table()
bm_bp.edges.ensure_lookup_table()

# 1. Inspect upper front fender vent (around X < -2.5, 3.0 < Y < 4.5, 2.0 < Z < 2.8)
print("=== UPPER FRONT FENDER VENT (LEFT) ===")
fender_verts = [v for v in bm_bp.verts if v.co.x < -2.6 and 3.2 < v.co.y < 4.5 and 2.1 < v.co.z < 2.7]
for v in fender_verts:
    print(f"  v{v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f}), boundary={v.is_boundary}")

# Find boundary loop of this upper vent
upper_b_edges = [e for e in bm_bp.edges if len(e.link_faces) == 1 and any(v.co.x < -2.6 and 3.2 < v.co.y < 4.5 and 2.1 < v.co.z < 2.7 for v in e.verts)]
print(f"Upper fender vent boundary edges: {len(upper_b_edges)}")
for e in upper_b_edges:
    print(f"  e({e.verts[0].index}, {e.verts[1].index}): {e.verts[0].co} -> {e.verts[1].co}")

# 2. Inspect front bumper cheek vents (Y > 5.8, Z < 1.8)
print("\n=== FRONT CHEEK DUCT EDGES (LEFT: X < -1.0) ===")
cheek_b_edges = [e for e in bm_bp.edges if len(e.link_faces) == 1 and any(v.co.x < -1.0 and v.co.y > 5.8 and v.co.z < 1.8 for v in e.verts)]
print(f"Cheek boundary edges: {len(cheek_b_edges)}")
for e in cheek_b_edges:
    print(f"  e({e.verts[0].index}, {e.verts[1].index}): ({e.verts[0].co.x:.3f}, {e.verts[0].co.y:.3f}, {e.verts[0].co.z:.3f}) -> ({e.verts[1].co.x:.3f}, {e.verts[1].co.y:.3f}, {e.verts[1].co.z:.3f})")

# 3. Inspect rear underbody gaps (Chassis_Underbody vs Body_Paint rear bumper)
print("\n=== REAR UNDERBODY / DIFFUSER EDGES ===")
bm_cu = bmesh.new()
bm_cu.from_mesh(cu.data)
bm_cu.verts.ensure_lookup_table()
bm_cu.edges.ensure_lookup_table()
rear_cu_floor = [v for v in bm_cu.verts if v.co.y < -3.5 and v.co.z < 0.7]
print(f"Rear underbody floor verts with z < 0.7, y < -3.5: {len(rear_cu_floor)}")
y_min = min(v.co.y for v in rear_cu_floor) if rear_cu_floor else 0
print(f"Min Y of floor: {y_min:.3f}")
diffuser = bpy.data.objects.get("Rear_Diffuser_Aero")
if diffuser:
    diff_verts = [v.co for v in diffuser.data.vertices]
    print(f"Diffuser Y range: [{min(v.y for v in diff_verts):.3f}, {max(v.y for v in diff_verts):.3f}], Z range: [{min(v.z for v in diff_verts):.3f}, {max(v.z for v in diff_verts):.3f}]")
