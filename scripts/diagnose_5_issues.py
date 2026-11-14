import bpy
import bmesh
import os
import math

glb_path = os.path.abspath('assets/models/kairo_neko_ev/raw_download/es11_full.glb')
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb_path)

# Check door handle geometry
door = bpy.data.objects.get('_4_car_LF_door-mesh')
door_inner = bpy.data.objects.get('_4_car_LF_door-mesh_4')

print("=== CHECKING DOOR HANDLE POCKET ===")
if door and door_inner:
    # Find verts near the door handle
    # In door, handle is around X: 1.0, Y: -0.8 to -0.6, Z: -0.5
    print(f"Door outer verts: {len(door.data.vertices)}, Door inner verts: {len(door_inner.data.vertices)}")

print("\n=== CHECKING WHEEL HUB WITHOUT BRAKES ===")
# List all wheel parts without brakes
wheel_rim_parts = [o for o in bpy.context.scene.objects if o.type == 'MESH' and 'hub' in o.name.lower() and not any(k in o.name.lower() for k in ['001', '002', 'brake'])]
print("Clean Wheel Rim Parts (No Brakes, No Spares):")
for p in wheel_rim_parts:
    print(f"  {p.name:32s} | Polys: {len(p.data.polygons):5d}")

tires = [o for o in bpy.context.scene.objects if o.type == 'MESH' and 'tire' in o.name.lower()]
print("Tire Parts:")
for t in tires:
    print(f"  {t.name:32s} | Polys: {len(t.data.polygons):5d}")
