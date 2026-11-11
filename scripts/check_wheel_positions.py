import bpy
from mathutils import Vector

def check_wheels(blend_path):
    print(f"\n=== WHEELS IN {blend_path} ===")
    bpy.ops.wm.open_mainfile(filepath=blend_path)
    for name in ["Wheel_FL", "Wheel_FR", "Wheel_RL", "Wheel_RR", "Wheels_Rims", "Calipers", "Caliper_FL"]:
        o = bpy.data.objects.get(name)
        if o:
            bb = [o.matrix_world @ Vector(b) for b in o.bound_box]
            cen = sum((v.co for v in o.data.vertices), Vector()) / len(o.data.vertices)
            print(f"  {name:<14} | Center: ({cen.x:.2f}, {cen.y:.2f}, {cen.z:.2f}) | Z range: [{min(b.z for b in bb):.2f}, {max(b.z for b in bb):.2f}]")

check_wheels(r"C:\Users\_newgen\Downloads\Tesla_Roadster_Unified_Flawless.blend")
check_wheels(r"C:\Users\_newgen\Downloads\Tesla_Roadster_Production.blend")
check_wheels(r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Production.blend")
