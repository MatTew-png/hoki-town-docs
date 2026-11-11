import bpy
from mathutils import Vector

path = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Production.blend"
bpy.ops.wm.open_mainfile(filepath=path)

print("=== OBJECTS IN PRODUCTION ===")
for o in bpy.data.objects:
    if o.type == 'MESH':
        bb = [o.matrix_world @ Vector(b) for b in o.bound_box]
        min_x, max_x = min(b.x for b in bb), max(b.x for b in bb)
        min_y, max_y = min(b.y for b in bb), max(b.y for b in bb)
        min_z, max_z = min(b.z for b in bb), max(b.z for b in bb)
        print(f"{o.name:<22} | V:{len(o.data.vertices):>4} | F:{len(o.data.polygons):>4} | X:[{min_x:+.2f}, {max_x:+.2f}] | Y:[{min_y:+.2f}, {max_y:+.2f}] | Z:[{min_z:+.2f}, {max_z:+.2f}]")
