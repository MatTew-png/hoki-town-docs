import bpy
from mathutils import Vector

def check_obj(path):
    bpy.ops.wm.open_mainfile(filepath=path)
    bp = bpy.data.objects.get("Body_Paint")
    print(f"\nFile: {path}")
    print(f"Location: {bp.location}, Rotation: {bp.rotation_euler}, Scale: {bp.scale}")
    bb = [bp.matrix_world @ Vector(b) for b in bp.bound_box]
    print(f"World BBox X: [{min(b.x for b in bb):.3f}, {max(b.x for b in bb):.3f}]")
    print(f"World BBox Y: [{min(b.y for b in bb):.3f}, {max(b.y for b in bb):.3f}]")
    print(f"World BBox Z: [{min(b.z for b in bb):.3f}, {max(b.z for b in bb):.3f}]")
    cen = sum((v.co for v in bp.data.vertices), Vector()) / len(bp.data.vertices)
    print(f"Local Vertex Center: {cen}")

check_obj(r"C:\Users\_newgen\Downloads\Tesla_Roadster_Unified_Flawless.blend")
check_obj(r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend")
