import bpy

FBX_OUTPUT = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.fbx"
BLEND_PATH = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"

bpy.ops.wm.open_mainfile(filepath=BLEND_PATH)

export_objs = [o for o in bpy.data.objects if o.type == 'MESH']
bpy.ops.object.select_all(action="DESELECT")
for o in export_objs:
    o.select_set(True)

bpy.ops.export_scene.fbx(
    filepath=FBX_OUTPUT,
    use_selection=True,
    global_scale=1.0,
    apply_unit_scale=True,
    apply_scale_options="FBX_SCALE_ALL",
    bake_space_transform=False,
    object_types={"MESH"},
    use_mesh_modifiers=True,
    mesh_smooth_type="FACE",
    add_leaf_bones=False,
    primary_bone_axis="Y",
    secondary_bone_axis="X",
    axis_forward="-Z",
    axis_up="Y",
)
print("FBX_EXPORT_SUCCESSFUL")
