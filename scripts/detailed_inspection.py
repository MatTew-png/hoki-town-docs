import bpy
import bmesh
from mathutils import Vector

BLEND_PATH = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"
bpy.ops.wm.open_mainfile(filepath=BLEND_PATH)

bp = bpy.data.objects.get("Body_Paint")
bg = bpy.data.objects.get("Body_Glass")
cu = bpy.data.objects.get("Chassis_Underbody")

print("=== 1. QUARTER WINDOW FACES IN BODY_GLASS ===")
bm_bg = bmesh.new()
bm_bg.from_mesh(bg.data)
bm_bg.faces.ensure_lookup_table()
bm_bg.edges.ensure_lookup_table()

# Look at left quarter window: X < -1.8, -3.8 < Y < -1.6
qw_faces = [f for f in bm_bg.faces if any(v.co.x < -1.8 and -3.8 < v.co.y < -1.6 for v in f.verts)]
for f in qw_faces:
    print(f"  Face {f.index}: {[v.index for v in f.verts]} | coords={[f'({v.co.x:.2f},{v.co.y:.2f},{v.co.z:.2f})' for v in f.verts]}")

print("\n=== 2. B-PILLAR INTERSECTIONS IN CHASSIS_UNDERBODY ===")
bm_cu = bmesh.new()
bm_cu.from_mesh(cu.data)
bp_faces = [f for f in bm_cu.faces if any(-1.9 < v.co.y < -1.3 and v.co.z > 2.9 and abs(v.co.x) > 1.9 for v in f.verts)]
print(f"Total CU faces in B-pillar zone: {len(bp_faces)}")
for f in bp_faces[:10]:
    print(f"  CU Face {f.index}: {[f'({v.co.x:.2f},{v.co.y:.2f},{v.co.z:.2f})' for v in f.verts]}")

print("\n=== 3. FRONT HOOD HOLE (IMAGE 3) ===")
# Find boundary loops in Body_Paint on hood: 5.5 < Y < 7.2, 1.5 < Z < 2.5
bm_bp = bmesh.new()
bm_bp.from_mesh(bp.data)
hood_b_edges = [e for e in bm_bp.edges if len(e.link_faces) == 1 and any(5.5 < v.co.y < 7.2 and 1.5 < v.co.z < 2.5 and v.co.x < -1.0 for v in e.verts)]
print(f"Left hood hole boundary edges: {len(hood_b_edges)}")
for e in hood_b_edges:
    print(f"  e({e.verts[0].index}, {e.verts[1].index}): ({e.verts[0].co.x:.3f}, {e.verts[0].co.y:.3f}, {e.verts[0].co.z:.3f}) -> ({e.verts[1].co.x:.3f}, {e.verts[1].co.y:.3f}, {e.verts[1].co.z:.3f})")

print("\n=== 4. FENDER CONTOUR AND WHEEL FITMENT ===")
# Let's inspect the fender flare X coordinates at front wheel (Y=4.64) and rear wheel (Y=-4.90)
fw_arch = [v.co.x for v in bm_bp.verts if 4.2 < v.co.y < 5.0 and 1.0 < v.co.z < 2.3 and v.co.x < -2.0]
rw_arch = [v.co.x for v in bm_bp.verts if -5.3 < v.co.y < -4.5 and 1.0 < v.co.z < 2.3 and v.co.x < -2.0]
print(f"Front Wheel Arch X range: [{min(fw_arch):.3f}, {max(fw_arch):.3f}]")
print(f"Rear Wheel Arch X range: [{min(rw_arch):.3f}, {max(rw_arch):.3f}]")
