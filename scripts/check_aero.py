import bpy
import bmesh
from mathutils import Vector

BLEND_PATH = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"
bpy.ops.wm.open_mainfile(filepath=BLEND_PATH)

cu = bpy.data.objects.get("Chassis_Underbody")
inter = bpy.data.objects.get("Interior")
bp = bpy.data.objects.get("Body_Paint")

# Check all faces in Chassis_Underbody around rear wheels: -6.0 < Y < -3.5, 0.5 < Z < 2.5
bm_cu = bmesh.new()
bm_cu.from_mesh(cu.data)
bm_cu.verts.ensure_lookup_table()

rw_faces = [f for f in bm_cu.faces if any(-6.5 < v.co.y < -3.5 and 0.5 < v.co.z < 2.5 and abs(v.co.x) > 1.5 for v in f.verts)]
print(f"Rear wheel well faces in Chassis_Underbody: {len(rw_faces)}")

fw_faces = [f for f in bm_cu.faces if any(3.5 < v.co.y < 6.0 and 0.5 < v.co.z < 2.5 and abs(v.co.x) > 1.5 for v in f.verts)]
print(f"Front wheel well faces in Chassis_Underbody: {len(fw_faces)}")

# Check Interior boundary:
if inter:
    bm_int = bmesh.new()
    bm_int.from_mesh(inter.data)
    min_z = min(v.co.z for v in bm_int.verts)
    max_z = max(v.co.z for v in bm_int.verts)
    min_y = min(v.co.y for v in bm_int.verts)
    max_y = max(v.co.y for v in bm_int.verts)
    min_x = min(v.co.x for v in bm_int.verts)
    max_x = max(v.co.x for v in bm_int.verts)
    print(f"Interior bounds: X:[{min_x:.2f}, {max_x:.2f}], Y:[{min_y:.2f}, {max_y:.2f}], Z:[{min_z:.2f}, {max_z:.2f}]")
