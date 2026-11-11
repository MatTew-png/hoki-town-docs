import bpy
import bmesh
from mathutils import Vector

path = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"
bpy.ops.wm.open_mainfile(filepath=path)

bg = bpy.data.objects.get("Body_Glass")
print(f"Body_Glass: {len(bg.data.vertices)} verts, {len(bg.data.polygons)} faces")

bm = bmesh.new()
bm.from_mesh(bg.data)

# Print connected components (islands) of Body_Glass
visited_faces = set()
islands = []
for f in bm.faces:
    if f in visited_faces:
        continue
    island = []
    stack = [f]
    visited_faces.add(f)
    while stack:
        curr = stack.pop()
        island.append(curr)
        for e in curr.edges:
            for n_f in e.link_faces:
                if n_f not in visited_faces:
                    visited_faces.add(n_f)
                    stack.append(n_f)
    islands.append(island)

print(f"Body_Glass has {len(islands)} separate mesh islands:")
for idx, isl in enumerate(islands):
    verts = list({v for f in isl for v in f.verts})
    min_x = min(v.co.x for v in verts)
    max_x = max(v.co.x for v in verts)
    min_y = min(v.co.y for v in verts)
    max_y = max(v.co.y for v in verts)
    min_z = min(v.co.z for v in verts)
    max_z = max(v.co.z for v in verts)
    print(f"  Island {idx+1}: {len(isl)} faces, {len(verts)} verts | X:[{min_x:.2f}, {max_x:.2f}] | Y:[{min_y:.2f}, {max_y:.2f}] | Z:[{min_z:.2f}, {max_z:.2f}]")
