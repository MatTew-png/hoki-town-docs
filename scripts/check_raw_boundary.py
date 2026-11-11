import bpy
import bmesh

bpy.ops.wm.open_mainfile(filepath=r"C:\Users\_newgen\Downloads\Tesla_Roadster_Original_Raw.blend")
o = bpy.data.objects['TeslaRoadsterbaseModel']
bm = bmesh.new()
bm.from_mesh(o.data)

# In raw model, check boundary edges
b_edges = [e for e in bm.edges if e.is_boundary]
print(f"Total boundary edges in Raw Model: {len(b_edges)}")

# Check materials near the rear scoop (in Raw model coordinates)
# Remember raw model has rotation X=90
print("\nMaterials on Raw Model:")
for i, m in enumerate(o.data.materials):
    print(f"Slot {i}: {m.name}")

bm.free()
