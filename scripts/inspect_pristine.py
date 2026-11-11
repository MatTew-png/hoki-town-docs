import bpy
import bmesh
from mathutils import Vector

BLEND_PATH = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"
bpy.ops.wm.open_mainfile(filepath=BLEND_PATH)

bp = bpy.data.objects.get("Body_Paint")
bm = bmesh.new()
bm.from_mesh(bp.data)
bm.verts.ensure_lookup_table()
bm.faces.ensure_lookup_table()

# Find faces near (-1.338, 7.113, 1.695) and (-2.319, 6.583, 1.951)
target_verts = [v for v in bm.verts if -2.6 < v.co.x < -1.1 and 6.0 < v.co.y < 7.3 and 1.6 < v.co.z < 2.2]
print(f"Target verts count: {len(target_verts)}")
for v in target_verts:
    print(f"  v{v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f}), faces={len(v.link_faces)}, boundary={v.is_boundary}")

# Look at boundary edges among these verts
b_edges = [e for e in bm.edges if len(e.link_faces) == 1 and any(v in target_verts for v in e.verts)]
print(f"Boundary edges among target verts: {len(b_edges)}")
for e in b_edges:
    print(f"  e({e.verts[0].index}, {e.verts[1].index}): {e.verts[0].co} -> {e.verts[1].co}")
