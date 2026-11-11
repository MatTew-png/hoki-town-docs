import bpy
import bmesh
from mathutils import Vector

BLEND_PATH = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"
bpy.ops.wm.open_mainfile(filepath=BLEND_PATH)

bp = bpy.data.objects.get("Body_Paint")
bg = bpy.data.objects.get("Body_Glass")
cu = bpy.data.objects.get("Chassis_Underbody")

print("==================================================")
print("1. INSPECTING GLASS & B-PILLAR EDGES (IMAGES 1 & 2)")
print("==================================================")
# Check Body_Glass faces and edges at quarter window (-3.6 < Y < -1.4, X < -1.8)
bm_bg = bmesh.new()
bm_bg.from_mesh(bg.data)
bm_bg.verts.ensure_lookup_table()
bm_bg.edges.ensure_lookup_table()
bm_bg.faces.ensure_lookup_table()

qw_faces = [f for f in bm_bg.faces if any(-3.6 < v.co.y < -1.4 and v.co.x < -1.8 for v in f.verts)]
print(f"Quarter window faces in Body_Glass: {len(qw_faces)}")
for f in qw_faces:
    print(f"  Face {f.index}: smooth={f.smooth}, verts={[v.index for v in f.verts]}")
    for v in f.verts:
        print(f"    v{v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f})")

qw_edges = [e for e in bm_bg.edges if any(-3.6 < v.co.y < -1.4 and v.co.x < -1.8 for v in e.verts)]
print(f"Quarter window edges in Body_Glass: {len(qw_edges)}")
for e in qw_edges:
    print(f"  Edge {e.index} ({e.verts[0].index}, {e.verts[1].index}): smooth={e.smooth}, seam={e.seam}, sharp={not e.smooth}, faces={len(e.link_faces)}")

# Check B-pillar in Chassis_Underbody
bm_cu = bmesh.new()
bm_cu.from_mesh(cu.data)
bm_cu.verts.ensure_lookup_table()
bm_cu.edges.ensure_lookup_table()
bm_cu.faces.ensure_lookup_table()
bp_cu_faces = [f for f in bm_cu.faces if any(-2.0 < v.co.y < -1.2 and v.co.z > 2.8 and abs(v.co.x) > 1.8 for v in f.verts)]
print(f"\nB-pillar faces in Chassis_Underbody: {len(bp_cu_faces)}")
for f in bp_cu_faces:
    print(f"  CU Face {f.index}: smooth={f.smooth}, verts={[v.index for v in f.verts]}")
    for v in f.verts:
        print(f"    v{v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f})")

print("\n==================================================")
print("2. INSPECTING FRONT HOOD HOLES (IMAGE 3)")
print("==================================================")
# Find all boundary edges on Body_Paint on the front hood (Y > 4.0, Z > 1.8, abs(X) < 2.5)
bm_bp = bmesh.new()
bm_bp.from_mesh(bp.data)
bm_bp.verts.ensure_lookup_table()
bm_bp.edges.ensure_lookup_table()

hood_b_edges = [e for e in bm_bp.edges if len(e.link_faces) == 1 and any(v.co.y > 4.0 and v.co.z > 1.8 and abs(v.co.x) < 2.5 for v in e.verts)]
print(f"Boundary edges on front hood: {len(hood_b_edges)}")
for e in hood_b_edges:
    v0, v1 = e.verts[0], e.verts[1]
    print(f"  Hood boundary e({v0.index}, {v1.index}): ({v0.co.x:.3f}, {v0.co.y:.3f}, {v0.co.z:.3f}) -> ({v1.co.x:.3f}, {v1.co.y:.3f}, {v1.co.z:.3f})")

print("\n==================================================")
print("3. INSPECTING WHEEL & TIRE FITMENT (IMAGES 4 & 5)")
print("==================================================")
# Check fender arch outer edge X coordinates vs Tire / Wheel outer edge X coordinates
# Front Left fender arch: 3.5 < Y < 5.8, 1.0 < Z < 2.4
fl_fender_verts = [v for v in bm_bp.verts if v.co.x < -2.0 and 3.5 < v.co.y < 5.8 and 1.0 < v.co.z < 2.4]
fl_fender_outer_x = min(v.co.x for v in fl_fender_verts) if fl_fender_verts else 0
print(f"Front Left Fender arch outer X: {fl_fender_outer_x:.3f}")

# Rear Left fender arch: -6.0 < Y < -3.8, 1.0 < Z < 2.4
rl_fender_verts = [v for v in bm_bp.verts if v.co.x < -2.0 and -6.0 < v.co.y < -3.8 and 1.0 < v.co.z < 2.4]
rl_fender_outer_x = min(v.co.x for v in rl_fender_verts) if rl_fender_verts else 0
print(f"Rear Left Fender arch outer X: {rl_fender_outer_x:.3f}")

# Check Wheel and Tire bounds:
for name in ["Tire_FL", "Wheel_FL", "Brake_Rotor_FL", "Caliper_FL", "Tire_RL", "Wheel_RL", "Brake_Rotor_RL", "Caliper_RL"]:
    obj = bpy.data.objects.get(name)
    if obj:
        xs = [v.co.x for v in obj.data.vertices]
        print(f"  {name:<15}: X min={min(xs):.3f}, max={max(xs):.3f}, center={(min(xs)+max(xs))/2:.3f}")
