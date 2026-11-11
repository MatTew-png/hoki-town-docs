import bpy
from mathutils import Vector

path = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Base_Pristine.blend"
bpy.ops.wm.open_mainfile(filepath=path)

print("=== OBJECTS IN PRISTINE ===")
for o in bpy.data.objects:
    if o.type == 'MESH':
        bb = [o.matrix_world @ Vector(b) for b in o.bound_box]
        min_x, max_x = min(b.x for b in bb), max(b.x for b in bb)
        min_y, max_y = min(b.y for b in bb), max(b.y for b in bb)
        min_z, max_z = min(b.z for b in bb), max(b.z for b in bb)
        print(f"{o.name:<22} | V:{len(o.data.vertices):>4} | F:{len(o.data.polygons):>4} | X:[{min_x:+.2f}, {max_x:+.2f}] | Y:[{min_y:+.2f}, {max_y:+.2f}] | Z:[{min_z:+.2f}, {max_z:+.2f}]")

w_fl = bpy.data.objects.get("Window_FL")
if w_fl:
    print("\nWindow_FL vertices:")
    for v in w_fl.data.vertices:
        co = w_fl.matrix_world @ v.co
        print(f"  v: ({co.x:.3f}, {co.y:.3f}, {co.z:.3f})")

bg = bpy.data.objects.get("Body_Glass")
if bg:
    print("\nBody_Glass vertices (X < -1.5):")
    for i, v in enumerate(bg.data.vertices):
        co = bg.matrix_world @ v.co
        if co.x < -1.5:
            print(f"  v{i}: ({co.x:.3f}, {co.y:.3f}, {co.z:.3f})")
