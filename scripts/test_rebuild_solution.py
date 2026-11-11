import bpy
import bmesh
from mathutils import Vector

BLEND_SRC = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Unified_Flawless.blend"
BLEND_CUR = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"
TEST_BLEND = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Test_Rebuilt.blend"
RENDER_DIR = r"c:\Users\_newgen\Documents\antigravity\HOKI TOWN\.scratch"

# 1. Open Current Master
bpy.ops.wm.open_mainfile(filepath=BLEND_CUR)

col_body = bpy.data.collections.get("Body_Assembly")
col_wheels = bpy.data.collections.get("Wheels")
col_interior = bpy.data.collections.get("Interior")

# Delete the bad floating Door_ShutLines object
dsl = bpy.data.objects.get("Door_ShutLines")
if dsl:
    bpy.data.objects.remove(dsl, do_unlink=True)
    print("REMOVED floating Door_ShutLines")

# Delete damaged Body_Glass and Body_Paint
bp_old = bpy.data.objects.get("Body_Paint")
bg_old = bpy.data.objects.get("Body_Glass")
if bp_old:
    bpy.data.objects.remove(bp_old, do_unlink=True)
if bg_old:
    bpy.data.objects.remove(bg_old, do_unlink=True)

# 2. Append pristine Body_Paint, Body_Glass, and Body_Secondary_Carbon from Unified_Flawless
with bpy.data.libraries.load(BLEND_SRC, link=False) as (data_from, data_to):
    data_to.objects = ["Body_Paint", "Body_Glass", "Body_Secondary_Carbon"]

appended = [o for o in data_to.objects if o is not None]
bp = bpy.data.objects.get("Body_Paint")
bg = bpy.data.objects.get("Body_Glass")
bsc = bpy.data.objects.get("Body_Secondary_Carbon")

for o in [bp, bg]:
    if o:
        for c in list(o.users_collection):
            c.objects.unlink(o)
        col_body.objects.link(o)

# 3. Fix Issue 4: Merge the entire Underbody Floor into Chassis_Underbody
cu = bpy.data.objects.get("Chassis_Underbody")
if bsc and cu:
    # Extract lower undertray / floor faces from bsc
    bm_bsc = bmesh.new()
    bm_bsc.from_mesh(bsc.data)
    
    # We want all underbody faces (Z < 1.0)
    floor_faces = [f for f in bm_bsc.faces if f.calc_center_median().z < 0.95]
    print(f"Extracted {len(floor_faces)} underbody floor faces from Body_Secondary_Carbon")
    
    # Convert floor faces to a new mesh and join into Chassis_Underbody
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
            
    me_floor = bpy.data.meshes.new("Underbody_Floor_Mesh")
    bm_floor.to_mesh(me_floor)
    bm_floor.free()
    bm_bsc.free()
    
    # Join into Chassis_Underbody
    floor_obj = bpy.data.objects.new("Underbody_Floor", me_floor)
    col_body.objects.link(floor_obj)
    
    # Select cu and floor_obj and join
    bpy.ops.object.select_all(action='DESELECT')
    floor_obj.select_set(True)
    cu.select_set(True)
    bpy.context.view_layer.objects.active = cu
    bpy.ops.object.join()
    print(f"Chassis_Underbody now has {len(cu.data.vertices)} verts, {len(cu.data.polygons)} faces")

# Remove temporary bsc
if bsc and bsc.name in bpy.data.objects:
    bpy.data.objects.remove(bsc, do_unlink=True)

# 4. Assign Materials
mat_white = bpy.data.materials.get("Mat_Zone1_Primary_White")
if not mat_white:
    mat_white = bpy.data.materials.new("Mat_Zone1_Primary_White")
    mat_white.use_nodes = True
    bsdf = mat_white.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (0.92, 0.92, 0.93, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.20
    bsdf.inputs["Metallic"].default_value = 0.10

bp.data.materials.clear()
bp.data.materials.append(mat_white)

mat_glass = bpy.data.materials.get("Mat_Glass_Tinted")
if not mat_glass:
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

mat_chassis = bpy.data.materials.get("Mat_Chassis_Underbody_Trim")
if cu and mat_chassis:
    cu.data.materials.clear()
    cu.data.materials.append(mat_chassis)

# Save test blend
bpy.ops.wm.save_as_mainfile(filepath=TEST_BLEND)
print("SAVED TEST BLEND")

# 5. Render 4 test views matching the user's 4 images!
scene = bpy.context.scene
cam = scene.camera
if not cam:
    cam_data = bpy.data.cameras.new("Cam")
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam

def aim_cam(pos, target, lens=35, ortho=False, ortho_scale=16.0):
    cam.location = Vector(pos)
    cam.rotation_euler = (Vector(target) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    if ortho:
        cam.data.type = 'ORTHO'
        cam.data.ortho_scale = ortho_scale
    else:
        cam.data.type = 'PERSP'
        cam.data.lens = lens

# Test 1: Matching Image 1 (side door)
aim_cam((-8.5, 0.6, 2.2), (-2.6, 0.4, 2.1), lens=32)
scene.render.resolution_x = 1200
scene.render.resolution_y = 600
scene.render.filepath = RENDER_DIR + r"\test_view1_door.png"
bpy.ops.render.render(write_still=True)

# Test 2: Matching Image 2 (door rear seam / B-pillar)
aim_cam((-6.5, -1.8, 2.8), (-2.9, -1.8, 2.6), lens=70)
scene.render.resolution_x = 800
scene.render.resolution_y = 1200
scene.render.filepath = RENDER_DIR + r"\test_view2_seam.png"
bpy.ops.render.render(write_still=True)

# Test 3: Matching Image 3 (glass side view)
aim_cam((-12.0, -0.2, 3.2), (-2.0, -0.2, 3.2), lens=40)
scene.render.resolution_x = 1200
scene.render.resolution_y = 600
scene.render.filepath = RENDER_DIR + r"\test_view3_glass.png"
bpy.ops.render.render(write_still=True)

# Test 4: Matching Image 4 (underbody bottom view)
aim_cam((0.0, -11.0, -1.8), (0.0, 0.0, 1.5), lens=35)
scene.render.resolution_x = 1200
scene.render.resolution_y = 600
scene.render.filepath = RENDER_DIR + r"\test_view4_bottom.png"
bpy.ops.render.render(write_still=True)

print("ALL_4_TEST_RENDERS_DONE")
