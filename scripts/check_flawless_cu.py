import bpy

bpy.ops.wm.open_mainfile(filepath=r"C:\Users\_newgen\Downloads\Tesla_Roadster_Unified_Flawless.blend")
cu = bpy.data.objects.get("Chassis_Underbody")
print("Flawless CU B-pillar verts:")
for v in cu.data.vertices:
    if v.co.x < -2.0 and -1.8 < v.co.y < -1.4 and v.co.z > 3.9:
        print(f"  v{v.index}: ({v.co.x:.4f}, {v.co.y:.4f}, {v.co.z:.4f})")
