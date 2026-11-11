import bpy
import bmesh
from mathutils import Vector

def inspect_door_lines():
    bpy.ops.wm.open_mainfile(filepath=r"C:\Users\_newgen\Downloads\Tesla_Roadster_Original_Raw.blend")
    o = bpy.data.objects['TeslaRoadsterbaseModel']
    bm = bmesh.new()
    bm.from_mesh(o.data)
    
    # Check edges along the door boundary:
    # Front door seam: around Y in [2.4, 2.7], X < -2.6
    # Rear door seam: around Y in [-2.2, -1.5], X < -2.6
    # Bottom rocker: Z ~ 0.5, X < -2.6
    print("=== Raw Model Edges near Rear Seam (Y in [-2.0, -1.6], X < -2.6) ===")
    rear_e = [e for e in bm.edges if any(v.co.x < -2.6 and -2.0 < v.co.y < -1.6 for v in e.verts)]
    print(f"Edges: {len(rear_e)}")
    for e in rear_e[:10]:
        v0, v1 = e.verts[0].co, e.verts[1].co
        print(f"  Edge: ({v0.x:.3f}, {v0.y:.3f}, {v0.z:.3f}) -> ({v1.x:.3f}, {v1.y:.3f}, {v1.z:.3f}), mats: {[f.material_index for f in e.link_faces]}")

    print("\n=== Materials in Raw Model linked to door ===")
    for m in o.data.materials:
        print(f"  {m.name}")

    bm.free()

inspect_door_lines()
