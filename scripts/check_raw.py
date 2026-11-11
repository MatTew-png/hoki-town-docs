import bpy
from mathutils import Vector

bpy.ops.wm.open_mainfile(filepath=r"C:\Users\_newgen\Downloads\Tesla_Roadster_Original_Raw.blend")
o = bpy.data.objects.get("TeslaRoadsterbaseModel")
print(f"TeslaRoadsterbaseModel: {len(o.data.vertices)} verts, {len(o.data.polygons)} faces")
print("Materials on TeslaRoadsterbaseModel:")
for i, m in enumerate(o.data.materials):
    faces = [f for f in o.data.polygons if f.material_index == i]
    print(f"  Slot {i}: {m.name} -> {len(faces)} faces")

# Check bottom of TeslaRoadsterbaseModel (Z < 1.0)
low_faces = [f for f in o.data.polygons if f.center.z < 0.6 and f.normal.z < -0.5]
print(f"Downward floor faces in Raw: {len(low_faces)}")
