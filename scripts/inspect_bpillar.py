import bpy
import bmesh
from mathutils import Vector

BLEND_PATH = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"
bpy.ops.wm.open_mainfile(filepath=BLEND_PATH)

bp = bpy.data.objects.get("Body_Paint")
bg = bpy.data.objects.get("Body_Glass")

bm_bp = bmesh.new()
bm_bp.from_mesh(bp.data)
bm_bp.verts.ensure_lookup_table()
bm_bp.faces.ensure_lookup_table()

print("=== BODY_PAINT AROUND B-PILLAR (-2.2 < Y < -1.0, Z > 2.5) ===")
bp_near_bp = [v for v in bm_bp.verts if -2.2 < v.co.y < -1.0 and v.co.z > 2.5 and v.co.x < -1.5]
for v in bp_near_bp:
    print(f"  BP v{v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f}), linked faces={len(v.link_faces)}")

print("\n=== BODY_GLASS AROUND B-PILLAR (-2.2 < Y < -1.0, Z > 2.5) ===")
bm_bg = bmesh.new()
bm_bg.from_mesh(bg.data)
bm_bg.verts.ensure_lookup_table()
bg_near_bp = [v for v in bm_bg.verts if -2.2 < v.co.y < -1.0 and v.co.z > 2.5 and v.co.x < -1.5]
for v in bg_near_bp:
    print(f"  BG v{v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f}), linked faces={len(v.link_faces)}")

print("\n=== BODY_PAINT ROOF FACES (-2.5 < Y < -0.5, Z > 3.8, X < -1.5) ===")
roof_faces = [f for f in bm_bp.faces if any(-2.5 < v.co.y < -0.5 and v.co.z > 3.8 and v.co.x < -1.5 for v in f.verts)]
for f in roof_faces:
    v_indices = [v.index for v in f.verts]
    print(f"  Roof Face {f.index}: verts={v_indices}, normal=({f.normal.x:.2f}, {f.normal.y:.2f}, {f.normal.z:.2f})")
