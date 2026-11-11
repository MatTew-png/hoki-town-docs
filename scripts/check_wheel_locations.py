import bpy

BLEND_PATH = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"
bpy.ops.wm.open_mainfile(filepath=BLEND_PATH)

bp = bpy.data.objects.get("Body_Paint")

# Find vertices of Body_Paint near front wheel (Y around 4.64)
fw_verts = [v for v in bp.data.vertices if 4.0 < v.co.y < 5.2 and v.co.x < -2.0]
print(f"Front wheel body verts: {len(fw_verts)}")
for v in fw_verts:
    print(f"  v{v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f})")

# Find vertices of Body_Paint near rear wheel (Y around -4.90)
rw_verts = [v for v in bp.data.vertices if -5.5 < v.co.y < -4.3 and v.co.x < -2.0]
print(f"\nRear wheel body verts: {len(rw_verts)}")
for v in rw_verts:
    print(f"  v{v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f})")
