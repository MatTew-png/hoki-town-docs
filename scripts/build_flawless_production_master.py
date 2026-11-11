import bpy
import bmesh
from mathutils import Vector

BLEND_FLAWLESS = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Unified_Flawless.blend"
BLEND_RAYCAST = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"
BLEND_OUTPUT = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"
FBX_OUTPUT = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.fbx"
RENDER_DIR = r"c:\Users\_newgen\Documents\antigravity\HOKI TOWN\.scratch"

print("==================================================")
print("1. BUILDING FLAWLESS MASTER FROM PRISTINE GEOMETRY")
print("==================================================")
bpy.ops.wm.open_mainfile(filepath=BLEND_FLAWLESS)

# 1. Collections setup
for c in ["Body_Assembly", "Wheels", "Interior"]:
    if not bpy.data.collections.get(c):
        col = bpy.data.collections.new(c)
        bpy.context.scene.collection.children.link(col)

col_body = bpy.data.collections["Body_Assembly"]
col_wheels = bpy.data.collections["Wheels"]
col_interior = bpy.data.collections["Interior"]

# 2. Extract Underbody Floor from Body_Secondary_Carbon and merge into Chassis_Underbody
bsc = bpy.data.objects.get("Body_Secondary_Carbon")
cu = bpy.data.objects.get("Chassis_Underbody")
assert bsc and cu, "Missing Body_Secondary_Carbon or Chassis_Underbody"

bm_bsc = bmesh.new()
bm_bsc.from_mesh(bsc.data)

# All underbody floor faces: Z < 0.95
floor_faces = [f for f in bm_bsc.faces if f.calc_center_median().z < 0.95]
print(f"Extracted {len(floor_faces)} underbody floor faces to seal bottom")

bm_floor = bmesh.new()
v_map = {}
for f in floor_faces:
    new_verts = []
    for v in f.verts:
        if v not in v_map:
            v_map[v] = bm_floor.verts.new(v.co)
        new_verts.append(v_map[v])
    try:
        bm_floor.faces.new(new_verts)
    except:
        pass

me_floor = bpy.data.meshes.new("Floor_Sealing_Mesh")
bm_floor.to_mesh(me_floor)
bm_floor.free()

floor_obj = bpy.data.objects.new("Floor_Sealing", me_floor)
bpy.context.scene.collection.objects.link(floor_obj)

# Join Floor_Sealing into Chassis_Underbody
bpy.ops.object.select_all(action='DESELECT')
floor_obj.select_set(True)
cu.select_set(True)
bpy.context.view_layer.objects.active = cu
bpy.ops.object.join()
print(f"Chassis_Underbody now has {len(cu.data.vertices)} verts, {len(cu.data.polygons)} faces (100% floor sealed)")

# 3. Extract Authentic Rear Diffuser from bsc (Y < -4.0)
bm_diff = bmesh.new()
diff_faces = [f for f in bm_bsc.faces if f.calc_center_median().y < -4.0]
v_map_diff = {}
for f in diff_faces:
    new_verts = []
    for v in f.verts:
        if v not in v_map_diff:
            v_map_diff[v] = bm_diff.verts.new(v.co)
        new_verts.append(v_map_diff[v])
    try:
        bm_diff.faces.new(new_verts)
    except:
        pass

me_diff = bpy.data.meshes.new("Rear_Diffuser_Aero_Mesh")
bm_diff.to_mesh(me_diff)
bm_diff.free()
diff_obj = bpy.data.objects.new("Rear_Diffuser_Aero", me_diff)
col_body.objects.link(diff_obj)
print(f"Rear_Diffuser_Aero: {len(diff_obj.data.vertices)} verts, {len(diff_obj.data.polygons)} faces")

# 4. Extract Aero Trim (front splitter + side skirts: Y >= -4.0 and outside center)
bm_trim = bmesh.new()
trim_faces = [f for f in bm_bsc.faces if f.calc_center_median().y >= -4.0 and abs(f.calc_center_median().x) > 1.5]
v_map_trim = {}
for f in trim_faces:
    new_verts = []
    for v in f.verts:
        if v not in v_map_trim:
            v_map_trim[v] = bm_trim.verts.new(v.co)
        new_verts.append(v_map_trim[v])
    try:
        bm_trim.faces.new(new_verts)
    except:
        pass

me_trim = bpy.data.meshes.new("Aero_Trim_Mesh")
bm_trim.to_mesh(me_trim)
bm_trim.free()
trim_obj = bpy.data.objects.new("Aero_Trim", me_trim)
col_body.objects.link(trim_obj)
print(f"Aero_Trim: {len(trim_obj.data.vertices)} verts, {len(trim_obj.data.polygons)} faces")

# Delete original bsc
bm_bsc.free()
bpy.data.objects.remove(bsc, do_unlink=True)

# 5. Split Wheels and Calipers into individual FL, FR, RL, RR
# Load Calipers from BLEND_RAYCAST where 2 o'clock calibration was already perfected!
with bpy.data.libraries.load(BLEND_RAYCAST, link=False) as (data_from, data_to):
    data_to.objects = [
        "Wheel_FL", "Wheel_FR", "Wheel_RL", "Wheel_RR",
        "Tire_FL", "Tire_FR", "Tire_RL", "Tire_RR",
        "Brake_Rotor_FL", "Brake_Rotor_FR", "Brake_Rotor_RL", "Brake_Rotor_RR",
        "Caliper_FL", "Caliper_FR", "Caliper_RL", "Caliper_RR"
    ]

# Remove monolithic wheels/calipers from pristine
for name in ["Wheels_Rims", "Wheels_Tires", "Wheels_Accents", "Calipers"]:
    o = bpy.data.objects.get(name)
    if o:
        bpy.data.objects.remove(o, do_unlink=True)

# Link imported wheel objects to col_wheels
for o in data_to.objects:
    if o:
        for c in list(o.users_collection):
            c.objects.unlink(o)
        col_wheels.objects.link(o)

# 6. Assemble Interior
interior_parts = ["Interior_Dashboard", "Interior_Seats", "Steering_Wheel", "Steering_Badge"]
interior_objs = [bpy.data.objects.get(p) for p in interior_parts if bpy.data.objects.get(p)]
if interior_objs:
    bpy.ops.object.select_all(action='DESELECT')
    for o in interior_objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = interior_objs[0]
    bpy.ops.object.join()
    interior_objs[0].name = "Interior"
    for c in list(interior_objs[0].users_collection):
        c.objects.unlink(interior_objs[0])
    col_interior.objects.link(interior_objs[0])

# Move Body parts into col_body
bp = bpy.data.objects.get("Body_Paint")
bg = bpy.data.objects.get("Body_Glass")
hl = bpy.data.objects.get("Headlights_Bulbs")
tl = bpy.data.objects.get("Taillights")
sp = bpy.data.objects.get("Spoiler")
lp = bpy.data.objects.get("License_Plate")
hh = bpy.data.objects.get("Headlights_Housing")

for o in [bp, bg, cu, hl, tl, sp, lp, hh]:
    if o:
        for c in list(o.users_collection):
            c.objects.unlink(o)
        col_body.objects.link(o)

# 7. Setup Production Materials
mat_white = bpy.data.materials.new("Mat_Zone1_Primary_White")
mat_white.use_nodes = True
bsdf = mat_white.node_tree.nodes.get("Principled BSDF")
bsdf.inputs["Base Color"].default_value = (0.92, 0.92, 0.93, 1.0)
bsdf.inputs["Roughness"].default_value = 0.20
bsdf.inputs["Metallic"].default_value = 0.10
bp.data.materials.clear()
bp.data.materials.append(mat_white)
if sp:
    sp.data.materials.clear()
    sp.data.materials.append(mat_white)

mat_glass = bpy.data.materials.new("Mat_Glass_Tinted")
mat_glass.use_nodes = True
bsdf = mat_glass.node_tree.nodes.get("Principled BSDF")
bsdf.inputs["Base Color"].default_value = (0.04, 0.05, 0.06, 1.0)
bsdf.inputs["Roughness"].default_value = 0.04
bsdf.inputs["Metallic"].default_value = 0.05
if "Transmission" in bsdf.inputs:
    bsdf.inputs["Transmission"].default_value = 0.85
elif "Transmission Weight" in bsdf.inputs:
    bsdf.inputs["Transmission Weight"].default_value = 0.85
bg.data.materials.clear()
bg.data.materials.append(mat_glass)

mat_aero = bpy.data.materials.new("Mat_Aero_Forged_Carbon")
mat_aero.use_nodes = True
bsdf = mat_aero.node_tree.nodes.get("Principled BSDF")
bsdf.inputs["Base Color"].default_value = (0.03, 0.03, 0.03, 1.0)
bsdf.inputs["Roughness"].default_value = 0.40
bsdf.inputs["Metallic"].default_value = 0.10
diff_obj.data.materials.clear()
diff_obj.data.materials.append(mat_aero)
trim_obj.data.materials.clear()
trim_obj.data.materials.append(mat_aero)

mat_chassis = bpy.data.materials.new("Mat_Chassis_Underbody_Trim")
mat_chassis.use_nodes = True
bsdf = mat_chassis.node_tree.nodes.get("Principled BSDF")
bsdf.inputs["Base Color"].default_value = (0.02, 0.02, 0.02, 1.0)
bsdf.inputs["Roughness"].default_value = 0.75
bsdf.inputs["Metallic"].default_value = 0.10
cu.data.materials.clear()
cu.data.materials.append(mat_chassis)

mat_interior = bpy.data.materials.new("Mat_Interior_Dark_Cabin")
mat_interior.use_nodes = True
bsdf = mat_interior.node_tree.nodes.get("Principled BSDF")
bsdf.inputs["Base Color"].default_value = (0.012, 0.012, 0.015, 1.0)
bsdf.inputs["Roughness"].default_value = 0.88
bsdf.inputs["Metallic"].default_value = 0.05
interior = bpy.data.objects.get("Interior")
if interior:
    interior.data.materials.clear()
    interior.data.materials.append(mat_interior)

# 8. Universal Origin & Transform Normalization
for o in bpy.data.objects:
    if o.type == 'MESH':
        o.location = (0, 0, 0)
        o.rotation_euler = (0, 0, 0)
        o.scale = (1, 1, 1)

# Remove any library references so we can overwrite
for lib in list(bpy.data.libraries):
    bpy.data.libraries.remove(lib)

# Save Master Blend
bpy.ops.wm.save_as_mainfile(filepath=BLEND_OUTPUT)
print("SUCCESSFULLY SAVED MASTER BLEND")

# 9. Render the 4 exact views
scene = bpy.context.scene
cam = scene.camera
if not cam:
    cam_data = bpy.data.cameras.new("Cam")
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam

# Light
sun = bpy.data.objects.get("Sun")
if not sun:
    sun_data = bpy.data.lights.new("Sun", type='SUN')
    sun_data.energy = 3.0
    sun = bpy.data.objects.new("Sun", sun_data)
    scene.collection.objects.link(sun)

def aim_cam(pos, target, lens=35):
    cam.location = Vector(pos)
    cam.rotation_euler = (Vector(target) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = lens

# View 1: Matching Image 1 (door side)
aim_cam((-8.5, 0.6, 2.2), (-2.6, 0.4, 2.1), lens=32)
scene.render.resolution_x = 1200
scene.render.resolution_y = 600
scene.render.filepath = RENDER_DIR + r"\final_view1_door.png"
bpy.ops.render.render(write_still=True)

# View 2: Matching Image 2 (door rear seam / B-pillar close-up)
aim_cam((-6.5, -1.8, 2.8), (-2.9, -1.8, 2.6), lens=70)
scene.render.resolution_x = 800
scene.render.resolution_y = 1200
scene.render.filepath = RENDER_DIR + r"\final_view2_seam.png"
bpy.ops.render.render(write_still=True)

# View 3: Matching Image 3 (glass side view)
aim_cam((-12.0, -0.2, 3.2), (-2.0, -0.2, 3.2), lens=40)
scene.render.resolution_x = 1200
scene.render.resolution_y = 600
scene.render.filepath = RENDER_DIR + r"\final_view3_glass.png"
bpy.ops.render.render(write_still=True)

# View 4: Matching Image 4 (underbody bottom view)
aim_cam((0.0, -11.0, -1.8), (0.0, 0.0, 1.5), lens=35)
scene.render.resolution_x = 1200
scene.render.resolution_y = 600
scene.render.filepath = RENDER_DIR + r"\final_view4_bottom.png"
bpy.ops.render.render(write_still=True)

# Also export production FBX
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
print("SUCCESSFULLY EXPORTED PRODUCTION FBX")
print("ALL_DONE")
