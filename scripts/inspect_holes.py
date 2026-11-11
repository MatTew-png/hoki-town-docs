import bpy
import bmesh
from mathutils import Vector

BLEND_PATH = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"
bpy.ops.wm.open_mainfile(filepath=BLEND_PATH)

bp = bpy.data.objects.get("Body_Paint")
bm = bmesh.new()
bm.from_mesh(bp.data)
bm.verts.ensure_lookup_table()
bm.edges.ensure_lookup_table()

# Find boundary loops in this region: -2.5 < X < -0.8, 5.0 < Y < 7.2, 1.8 < Z < 2.8
hood_b_edges = [e for e in bm.edges if len(e.link_faces) == 1 and any(-2.5 < v.co.x < -0.8 and 5.0 < v.co.y < 7.2 and 1.8 < v.co.z < 2.8 for v in e.verts)]
print(f"Boundary edges in hood crease: {len(hood_b_edges)}")

# Group edges into loops
loops = []
visited = set()
for e in hood_b_edges:
    if e in visited:
        continue
    loop = [e]
    visited.add(e)
    # expand forward
    while True:
        last_v = loop[-1].verts[1]
        next_edges = [ne for ne in last_v.link_edges if ne in hood_b_edges and ne not in visited]
        if not next_edges:
            # try with verts[0]
            last_v = loop[-1].verts[0]
            next_edges = [ne for ne in last_v.link_edges if ne in hood_b_edges and ne not in visited]
        if next_edges:
            loop.append(next_edges[0])
            visited.add(next_edges[0])
        else:
            break
    loops.append(loop)

print(f"Found {len(loops)} connected boundary edge loops:")
for idx, loop in enumerate(loops):
    verts = list({v for e in loop for v in e.verts})
    min_x = min(v.co.x for v in verts)
    max_x = max(v.co.x for v in verts)
    min_y = min(v.co.y for v in verts)
    max_y = max(v.co.y for v in verts)
    min_z = min(v.co.z for v in verts)
    max_z = max(v.co.z for v in verts)
    print(f"  Loop {idx+1}: {len(loop)} edges, {len(verts)} verts | X:[{min_x:.3f}, {max_x:.3f}], Y:[{min_y:.3f}, {max_y:.3f}], Z:[{min_z:.3f}, {max_z:.3f}]")
    for v in verts:
        print(f"    v{v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f})")
