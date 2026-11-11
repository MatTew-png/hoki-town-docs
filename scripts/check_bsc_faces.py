import bpy
import bmesh
from mathutils import Vector

BLEND_PATH = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"
bpy.ops.wm.open_mainfile(filepath=BLEND_PATH)

bg = bpy.data.objects.get("Body_Glass")
cu = bpy.data.objects.get("Chassis_Underbody")
bp = bpy.data.objects.get("Body_Paint")

print("=== BODY_GLASS FACES (Z > 2.7, X < -1.8) ===")
for f in bg.data.polygons:
    f_verts = [bg.data.vertices[i].co for i in f.vertices]
    if any(v.z > 2.7 and v.x < -1.8 for v in f_verts):
        y_center = sum(v.y for v in f_verts)/len(f_verts)
        z_center = sum(v.z for v in f_verts)/len(f_verts)
        x_center = sum(v.x for v in f_verts)/len(f_verts)
        print(f"  BG Poly {f.index}: {len(f.vertices)} verts | center=({x_center:.2f}, {y_center:.2f}, {z_center:.2f}) | verts={[v for v in f.vertices]}")

print("\n=== CHASSIS_UNDERBODY FACES (Z > 2.7, -2.5 < Y < -1.0, X < -1.8) ===")
for f in cu.data.polygons:
    f_verts = [cu.data.vertices[i].co for i in f.vertices]
    if all(v.z > 2.7 and -2.5 < v.y < -1.0 and v.x < -1.8 for v in f_verts):
        y_center = sum(v.y for v in f_verts)/len(f_verts)
        z_center = sum(v.z for v in f_verts)/len(f_verts)
        x_center = sum(v.x for v in f_verts)/len(f_verts)
        print(f"  CU Poly {f.index}: {len(f.vertices)} verts | center=({x_center:.2f}, {y_center:.2f}, {z_center:.2f})")
