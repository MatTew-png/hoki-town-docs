import bpy
from mathutils import Vector

bpy.ops.wm.open_mainfile(filepath=r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend")
print("=== CHECKING ALL OBJECTS WITH Z < 0.5 ===")
for o in bpy.data.objects:
    if o.type == 'MESH':
        bb = [o.matrix_world @ Vector(b) for b in o.bound_box]
        min_z = min(b.z for b in bb)
        max_z = max(b.z for b in bb)
        cen_y = sum(b.y for b in bb)/8.0
        cen_z = sum(b.z for b in bb)/8.0
        if min_z < 0.0 or (cen_y < 1.0 and cen_y > -1.0 and cen_z < 1.0):
            print(f"  {o.name}: Z range [{min_z:.2f}, {max_z:.2f}], center=({(sum(b.x for b in bb)/8.0):.2f}, {cen_y:.2f}, {cen_z:.2f})")
