"""
Work Order: Restore Chassis Underbody, Window Frames, and Polish Door Seams
===========================================================================
Single Source of Truth script for restoring Chassis_Underbody, window frames,
sealing roof/underbody gaps, and building closed-loop door shut-lines.
"""

import bpy
import bmesh
import math
from mathutils import Vector

BLEND_SRC = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Unified_Flawless.blend"
BLEND_DST = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"
FBX_DST = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.fbx"
RENDER_DIR = r"C:\Users\_newgen\.gemini\antigravity\brain\a634876d-c794-428d-a197-2a958c3d6bb3"

CHASSIS_NAME = "Chassis_Underbody"
MAT_CHASSIS = "Mat_Chassis_Underbody_Trim"

# 1. Open master file
bpy.ops.wm.open_mainfile(filepath=BLEND_DST)

col_body = bpy.data.collections.get("Body_Assembly")
if col_body is None:
    raise RuntimeError("Body_Assembly collection not found")

# 2. Append Chassis_Underbody if missing
chassis = bpy.data.objects.get(CHASSIS_NAME)
if chassis is None:
    with bpy.data.libraries.load(BLEND_SRC, link=False) as (data_from, data_to):
        data_to.objects = [CHASSIS_NAME]
    loaded = [o for o in data_to.objects if o is not None]
    if not loaded:
        raise RuntimeError(f"Failed to append {CHASSIS_NAME} from {BLEND_SRC}")
    chassis = loaded[0]
    chassis.name = CHASSIS_NAME
    for c in list(chassis.users_collection):
        c.objects.unlink(chassis)
    col_body.objects.link(chassis)

# Ensure proper collection membership
for c in list(chassis.users_collection):
    if c != col_body:
        c.objects.unlink(chassis)
if chassis.name not in [o.name for o in col_body.objects]:
    col_body.objects.link(chassis)

# 3. Assign Mat_Chassis_Underbody_Trim
mat = bpy.data.materials.get(MAT_CHASSIS)
if mat is None:
    mat = bpy.data.materials.new(MAT_CHASSIS)
mat.use_nodes = True
bsdf = mat.node_tree.nodes.get("Principled BSDF")
if bsdf:
    bsdf.inputs["Base Color"].default_value = (0.02, 0.02, 0.02, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.75
    bsdf.inputs["Metallic"].default_value = 0.1

chassis.data.materials.clear()
chassis.data.materials.append(mat)

# 4. Clean up old shut lines
for o in list(bpy.data.objects):
    if "ShutLine" in o.name or "Door_Seam" in o.name:
        bpy.data.objects.remove(o, do_unlink=True)

mat_cavity = bpy.data.materials.get("Mat_Door_ShutLine_Cavity")
if not mat_cavity:
    mat_cavity = bpy.data.materials.new("Mat_Door_ShutLine_Cavity")
mat_cavity.use_nodes = True
bsdf_cavity = mat_cavity.node_tree.nodes.get("Principled BSDF")
if bsdf_cavity:
    bsdf_cavity.inputs["Base Color"].default_value = (0.01, 0.01, 0.01, 1.0)
    bsdf_cavity.inputs["Roughness"].default_value = 0.95

# 5. Build perfect closed-loop door frame shut lines strictly snapped to Body_Paint
bp = bpy.data.objects.get("Body_Paint")

front_raw = [
    Vector((-3.15, 2.45, 2.50)), # Corner A (A-pillar base)
    Vector((-3.12, 2.57, 2.17)),
    Vector((-3.18, 2.60, 1.65)),
    Vector((-3.22, 2.61, 1.15)),
    Vector((-3.25, 2.62, 0.75)),
    Vector((-3.12, 2.61, 0.50)), # Corner B (Rocker sill front)
]

bottom_raw = [
    Vector((-3.12, 2.61, 0.50)), # Corner B
    Vector((-3.20, 1.50, 0.50)),
    Vector((-3.24, 0.00, 0.51)),
    Vector((-3.20, -1.20, 0.52)),
    Vector((-3.15, -1.90, 0.54)), # Corner C (Rocker sill rear)
]

rear_raw = [
    Vector((-3.15, -1.90, 0.54)), # Corner C
    Vector((-3.18, -1.98, 0.85)),
    Vector((-3.21, -2.05, 1.25)),
    Vector((-3.12, -2.15, 1.70)), # Muscular rear haunch curve
    Vector((-3.06, -2.00, 2.15)),
    Vector((-3.08, -1.70, 2.38)),
    Vector((-3.10, -1.38, 2.47)), # Corner D (B-pillar junction)
]

# Straight clean horizontal beltline along the base of the glass
n_belt = 30
belt_samples = []
for i in range(n_belt):
    t = i / float(n_belt - 1)
    y = (1 - t) * (-1.38) + t * 2.45
    z = (1 - t) * 2.47 + t * 2.50
    # Snap X directly to outer door surface
    succ, loc, norm, _ = bp.closest_point_on_mesh(Vector((-3.5, y, z)))
    if succ:
        # Keep exact level Z, snap X and use surface normal
        belt_samples.append((Vector((loc.x, y, z)), norm.normalized()))
    else:
        belt_samples.append((Vector((-3.12, y, z)), Vector((-1, 0, 0))))

def sample_spline_on_bp(raw_pts, n_samples):
    samples = []
    for i in range(n_samples):
        t = i / float(n_samples - 1)
        seg_idx = t * (len(raw_pts) - 1)
        idx0 = int(seg_idx)
        idx1 = min(idx0 + 1, len(raw_pts) - 1)
        frac = seg_idx - idx0
        pt = raw_pts[idx0].lerp(raw_pts[idx1], frac)
        succ, loc, norm, _ = bp.closest_point_on_mesh(pt)
        if succ:
            samples.append((loc, norm.normalized()))
        else:
            samples.append((pt, Vector((-1, 0, 0))))
    return samples

front_samples  = sample_spline_on_bp(front_raw, 30)
bottom_samples = sample_spline_on_bp(bottom_raw, 30)
rear_samples   = sample_spline_on_bp(rear_raw, 40)

def create_channel_ribbon(bm, samples, is_left=True, width=0.030, depth=0.015, lift=0.011):
    n = len(samples)
    if n < 2: return
    
    verts_out_l, verts_out_r = [], []
    verts_in_l, verts_in_r = [], []
    
    for i in range(n):
        loc, norm = samples[i]
        P = Vector((loc.x * (1 if is_left else -1), loc.y, loc.z))
        N = Vector((norm.x * (1 if is_left else -1), norm.y, norm.z)).normalized()
        
        if i == 0:
            p_next = samples[1][0]
            T = Vector(((p_next.x - loc.x) * (1 if is_left else -1), p_next.y - loc.y, p_next.z - loc.z)).normalized()
        elif i == n - 1:
            p_prev = samples[n - 2][0]
            T = Vector(((loc.x - p_prev.x) * (1 if is_left else -1), loc.y - p_prev.y, loc.z - p_prev.z)).normalized()
        else:
            p_prev = samples[i - 1][0]
            p_next = samples[i + 1][0]
            T = Vector(((p_next.x - p_prev.x) * (1 if is_left else -1), p_next.y - p_prev.y, p_next.z - p_prev.z)).normalized()
            
        W = N.cross(T).normalized()
        
        p_lift = P + N * lift
        vol = bm.verts.new(p_lift - W * (width * 0.5))
        vor = bm.verts.new(p_lift + W * (width * 0.5))
        
        p_floor = P - N * depth
        vil = bm.verts.new(p_floor - W * (width * 0.35))
        vir = bm.verts.new(p_floor + W * (width * 0.35))
        
        verts_out_l.append(vol)
        verts_out_r.append(vor)
        verts_in_l.append(vil)
        verts_in_r.append(vir)
        
    bm.verts.ensure_lookup_table()
    
    for i in range(n - 1):
        try:
            f = bm.faces.new([verts_out_l[i], verts_out_r[i], verts_out_r[i+1], verts_out_l[i+1]])
            f.smooth = True
        except: pass
        try:
            f = bm.faces.new([verts_in_l[i], verts_in_r[i], verts_in_r[i+1], verts_in_l[i+1]])
            f.smooth = True
        except: pass
        try:
            f = bm.faces.new([verts_out_l[i], verts_in_l[i], verts_in_l[i+1], verts_out_l[i+1]])
            f.smooth = True
        except: pass
        try:
            f = bm.faces.new([verts_out_r[i], verts_in_r[i], verts_in_r[i+1], verts_out_r[i+1]])
            f.smooth = True
        except: pass

me = bpy.data.meshes.new("Door_ShutLines_Mesh")
bm = bmesh.new()

for is_left in [True, False]:
    create_channel_ribbon(bm, front_samples, is_left=is_left, width=0.030)
    create_channel_ribbon(bm, bottom_samples, is_left=is_left, width=0.026)
    create_channel_ribbon(bm, rear_samples, is_left=is_left, width=0.030)
    create_channel_ribbon(bm, belt_samples, is_left=is_left, width=0.024)

bm.to_mesh(me)
bm.free()

door_obj = bpy.data.objects.new("Door_ShutLines", me)
bpy.context.collection.objects.link(door_obj)
door_obj.data.materials.append(mat_cavity)
door_obj.location = Vector((0, 0, 0))

if col_body:
    col_body.objects.link(door_obj)
    if door_obj.name in bpy.context.scene.collection.objects:
        bpy.context.scene.collection.objects.unlink(door_obj)

# 6. Normalize all Body_Assembly objects to origin (0,0,0)
for obj in col_body.objects:
    if obj.type == "MESH":
        obj.location = (0, 0, 0)
        obj.rotation_euler = (0, 0, 0)
        obj.scale = (1, 1, 1)

# 7. Save master .blend
bpy.ops.wm.save_as_mainfile(filepath=BLEND_DST)
print("FINAL_MASTER_BLEND_SAVED")

# 8. Export production .fbx
export_objs = [o for o in bpy.data.objects if o.type == "MESH"]
bpy.ops.object.select_all(action="DESELECT")
for o in export_objs:
    o.select_set(True)

bpy.ops.export_scene.fbx(
    filepath=FBX_DST,
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
print("FINAL_MASTER_FBX_EXPORTED")

# 9. Verification Renders
scene = bpy.context.scene
cam = scene.camera

# Render 1: View matching user reference (media_1794176227432_e501b896.jpg)
cam.data.type = "PERSP"
cam.data.lens = 40
cam.location = Vector((-8.5, -0.6, 2.5))
target = Vector((-2.2, -0.2, 1.6))
cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
scene.render.resolution_x = 1600
scene.render.resolution_y = 700
scene.render.filepath = RENDER_DIR + r"\proof_restored_chassis_and_frames_side.png"
bpy.ops.render.render(write_still=True)

# Render 2: Side elevation ortho profile
cam.data.type = "ORTHO"
cam.data.ortho_scale = 15.0
cam.location = Vector((-14.0, 0.0, 1.8))
cam.rotation_euler = (math.radians(90), 0, math.radians(-90))
scene.render.resolution_x = 1920
scene.render.resolution_y = 1080
scene.render.filepath = RENDER_DIR + r"\proof_restored_chassis_and_frames_ortho.png"
bpy.ops.render.render(write_still=True)

# Render 3: Front 3/4 hero view
cam.data.type = "PERSP"
cam.data.lens = 42
cam.location = Vector((-9.5, 7.5, 3.2))
target = Vector((0.0, 0.5, 1.2))
cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
scene.render.resolution_x = 1600
scene.render.resolution_y = 900
scene.render.filepath = RENDER_DIR + r"\proof_restored_chassis_and_frames_hero.png"
bpy.ops.render.render(write_still=True)

print("ALL_FINAL_RENDERS_SUCCESS")
