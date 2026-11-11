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

# Find boundary vertices of left rear scoop
scoop_b_edges = [e for e in bm_bp.edges if len(e.link_faces) == 1 and any(v.co.x < -2.8 and -3.8 < v.co.y < -2.2 and 1.1 < v.co.z < 2.8 for v in e.verts)]
scoop_verts = list({v for e in scoop_b_edges for v in e.verts})
print(f"Left scoop boundary verts: {len(scoop_verts)}")
for v in scoop_verts:
    print(f"  v{v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f})")

# Order the loop
loop_verts = []
curr = scoop_verts[0]
remaining = set(scoop_verts[1:])
loop_verts.append(curr)

while remaining:
    # Find next vert connected by a boundary edge
    found = False
    for other in remaining:
        # Check if connected
        if any(e in scoop_b_edges for e in curr.link_edges if other in e.verts):
            curr = other
            loop_verts.append(curr)
            remaining.remove(other)
            found = True
            break
    if not found:
        print("Loop broken, appending closest")
        curr = min(remaining, key=lambda v: (v.co - curr.co).length)
        loop_verts.append(curr)
        remaining.remove(curr)

print(f"Ordered loop of {len(loop_verts)} verts:")
for v in loop_verts:
    print(f"  Vector(({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f})),")
