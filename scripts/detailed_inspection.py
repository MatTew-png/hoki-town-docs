import bpy
import os
import math

glb_path = os.path.abspath('assets/models/kairo_neko_ev/raw_download/es11_full.glb')
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb_path)

delete_names = [
    'Mesh_180-mesh', 'Mesh_231-mesh', 'Plane_026-mesh',
    '_9_trunk_glass-mesh_3', '_9_trunk_glass-mesh_7', '_9_trunk_glass-mesh_8', # GT wing / spoiler parts
    '_1_car_body_004-mesh_3', # GT wing brackets
    '_5_hub_black_metal_001-mesh', '_5_hub_black_metal_001-mesh_1', # floating spare wheel at origin
    '_5_hub_black_metal_001-mesh_2', '_5_hub_black_metal_001-mesh_3',
    '_5_hub_black_metal_002-mesh'
]

for o in list(bpy.context.scene.objects):
    if o.name.startswith('Untitled') or o.name in delete_names:
        bpy.data.objects.remove(o, do_unlink=True)

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.ops.transform.rotate(value=math.radians(-90), orient_axis='X')
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.ops.transform.rotate(value=math.pi, orient_axis='Z')
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

remaining = [o for o in bpy.context.scene.objects if o.type == 'MESH']
print(f"Total remaining mesh objects: {len(remaining)}")

# Print detailed categorization candidate list
for o in sorted(remaining, key=lambda x: x.name):
    zs = [v.co.z for v in o.data.vertices]
    ys = [v.co.y for v in o.data.vertices]
    xs = [v.co.x for v in o.data.vertices]
    print(f"{o.name:36s} | Polys: {len(o.data.polygons):5d} | X:[{min(xs):.2f}, {max(xs):.2f}] | Y:[{min(ys):.2f}, {max(ys):.2f}] | Z:[{min(zs):.2f}, {max(zs):.2f}]")
