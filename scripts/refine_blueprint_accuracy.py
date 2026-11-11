"""
Work Order: Refine Tesla Roadster to Match Official Blueprints
================================================================
Single Source of Truth script that brings the Door Shut-Lines, Rear
Diffuser & Aero, Greenhouse Glass & B-Pillars, and Materials into
alignment with the official 4-view blueprints.

Blueprint references (4-view):
  - Side   : media_1794178715901_2d041317.png
  - Rear   : media_1794178856480_b0e6a08e.png
  - Top    : media_1794178865934_bfd8d371.png
  - Front  : media_1794178860971_50a6e153.png

Coordinate convention (Blender, Y-forward):
  X = left/right (car width),  Y = fore/aft (nose = +Y, tail = -Y),
  Z = up. Car is symmetric about the X=0 plane.
"""

import bpy
import bmesh
import math
from mathutils import Vector

BLEND_SRC = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Unified_Flawless.blend"
BLEND_DST = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"
FBX_DST = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.fbx"
RENDER_DIR = r"C:\Users\_newgen\.gemini\antigravity\brain\a634876d-c794-428d-a197-2a958c3d6bb3"

# ----------------------------------------------------------------------------
# Tunable blueprint-matching constants (assumed from the 4-view blueprints)
# ----------------------------------------------------------------------------
B_PILLAR_RAKE = 0.10          # backward lean applied to the B-pillar top (units)
QUARTER_ELONGATE = 0.10       # backward elongation of the quarter-window rear edge


# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------
def get_principled(mat):
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:
        return bsdf
    bsdf = mat.node_tree.nodes.new("ShaderNodeBsdfPrincipled")
    out = mat.node_tree.nodes.get("Material Output")
    if out is None:
        out = mat.node_tree.nodes.new("ShaderNodeOutputMaterial")
        mat.node_tree.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return bsdf


def ensure_mat(name, base, rough, met, **extra):
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = get_principled(mat)
    bsdf.inputs["Base Color"].default_value = base
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = met
    for key, val in extra.items():
        if key in bsdf.inputs:
            bsdf.inputs[key].default_value = val
    return mat


def assign_single_mat(obj, mat):
    obj.data.materials.clear()
    obj.data.materials.append(mat)


def aim_cam(cam, pos, target):
    cam.location = Vector(pos)
    cam.rotation_euler = (Vector(target) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()


# ----------------------------------------------------------------------------
# 1. Open master project
# ----------------------------------------------------------------------------
bpy.ops.wm.open_mainfile(filepath=BLEND_DST)

col_body = bpy.data.collections.get("Body_Assembly")
if col_body is None:
    raise RuntimeError("Body_Assembly collection not found")

# ----------------------------------------------------------------------------
# 2. Materials (exact blueprint / contract values)
# ----------------------------------------------------------------------------
mat_aero = ensure_mat(
    "Mat_Aero_Forged_Carbon", (0.03, 0.03, 0.03, 1.0), 0.40, 0.10,
)
mat_glass = ensure_mat(
    "Mat_Glass_Tinted", (0.04, 0.05, 0.06, 1.0), 0.04, 0.05,
    Transmission=0.85, IOR=1.52,
)
mat_chassis = ensure_mat(
    "Mat_Chassis_Underbody_Trim", (0.02, 0.02, 0.02, 1.0), 0.75, 0.10,
)
mat_cavity = ensure_mat(
    "Mat_Door_ShutLine_Cavity", (0.01, 0.01, 0.01, 1.0), 0.95, 0.0,
)

# ----------------------------------------------------------------------------
# 3. Rear Diffuser - extract authentic geometry from Body_Secondary_Carbon
# ----------------------------------------------------------------------------
diffuser_src_name = "Body_Secondary_Carbon"

with bpy.data.libraries.load(BLEND_SRC, link=False) as (data_from, data_to):
    data_to.objects = [diffuser_src_name]
src_carbon = [o for o in data_to.objects if o is not None]
if not src_carbon:
    raise RuntimeError(f"Failed to append {diffuser_src_name} from {BLEND_SRC}")
src_carbon = src_carbon[0]

bm = bmesh.new()
bm.from_mesh(src_carbon.data)
bm.faces.ensure_lookup_table()

keep_faces = [f for f in bm.faces if f.calc_center_median().y < -4.0]
drop_faces = [f for f in bm.faces if f not in keep_faces]
if drop_faces:
    bmesh.ops.delete(bm, geom=drop_faces, context="FACES_ONLY")
loose_verts = [v for v in bm.verts if not v.link_faces]
if loose_verts:
    bmesh.ops.delete(bm, geom=loose_verts, context="VERTS")

diffuser_mesh = bpy.data.meshes.new("Rear_Diffuser_Aero_Mesh")
bm.to_mesh(diffuser_mesh)
bm.free()
diffuser_mesh.validate()

# Remove the temporary appended source object + its data
src_carbon_data = src_carbon.data
bpy.data.objects.remove(src_carbon, do_unlink=True)
if src_carbon_data.users == 0:
    bpy.data.meshes.remove(src_carbon_data)

# Replace the old 54-vertex flat box with the authentic diffuser
old_diffuser = bpy.data.objects.get("Rear_Diffuser_Aero")
if old_diffuser is None:
    old_diffuser = bpy.data.objects.new("Rear_Diffuser_Aero", diffuser_mesh)
    bpy.context.collection.objects.link(old_diffuser)
else:
    old_mesh = old_diffuser.data
    old_diffuser.data = diffuser_mesh
    if old_mesh.users == 0:
        bpy.data.meshes.remove(old_mesh)

old_diffuser.location = (0, 0, 0)
old_diffuser.rotation_euler = (0, 0, 0)
old_diffuser.scale = (1, 1, 1)
assign_single_mat(old_diffuser, mat_aero)
if col_body.name not in [c.name for c in old_diffuser.users_collection]:
    col_body.objects.link(old_diffuser)

print(f"DIFFUSER_EXTRACTED polygons={len(diffuser_mesh.polygons)} verts={len(diffuser_mesh.vertices)}")

# ----------------------------------------------------------------------------
# 4. Greenhouse glass, aero trim, chassis trim materials
# ----------------------------------------------------------------------------
for obj_name, mat in (
    ("Body_Glass", mat_glass),
    ("Aero_Trim", mat_aero),
    ("Chassis_Underbody", mat_chassis),
):
    o = bpy.data.objects.get(obj_name)
    if o is not None:
        assign_single_mat(o, mat)

# ----------------------------------------------------------------------------
# 5. Door shut-lines - rebuild authentic 3-sided frameless system (no beltline)
# ----------------------------------------------------------------------------
for o in list(bpy.data.objects):
    if "ShutLine" in o.name or "Door_Seam" in o.name:
        bpy.data.objects.remove(o, do_unlink=True)

bp = bpy.data.objects.get("Body_Paint")
if bp is None:
    raise RuntimeError("Body_Paint not found")

# Three sides of a frameless supercar door (open at the top where glass meets).
front_raw = [
    Vector((-3.07, 2.45, 2.56)),  # A-pillar cowl base flush with fender seam
    Vector((-3.12, 2.57, 2.17)),
    Vector((-3.18, 2.60, 1.65)),
    Vector((-3.22, 2.61, 1.15)),
    Vector((-3.25, 2.62, 0.75)),
    Vector((-3.12, 2.61, 0.50)),  # rocker sill front
]

bottom_raw = [
    Vector((-3.12, 2.61, 0.50)),  # rocker sill front
    Vector((-3.20, 1.50, 0.50)),
    Vector((-3.24, 0.00, 0.51)),
    Vector((-3.20, -1.20, 0.52)),
    Vector((-3.15, -1.90, 0.54)),  # rocker sill rear
]

rear_raw = [
    Vector((-3.15, -1.90, 0.54)),  # rocker sill rear
    Vector((-3.18, -1.98, 0.85)),
    Vector((-3.21, -2.05, 1.25)),
    Vector((-3.12, -2.15, 1.70)),  # muscular rear haunch curve
    Vector((-3.06, -2.00, 2.15)),
    Vector((-3.02, -1.75, 2.45)),
    Vector((-2.90, -1.55, 2.70)),
    Vector((-2.73, -1.38, 2.95)),  # B-pillar beltline junction meeting window sill seamlessly!
]


def sample_spline_on_bp(raw_pts, n_samples):
    samples = []
    for i in range(n_samples):
        t = i / float(n_samples - 1)
        seg = t * (len(raw_pts) - 1)
        idx0 = int(seg)
        idx1 = min(idx0 + 1, len(raw_pts) - 1)
        frac = seg - idx0
        pt = raw_pts[idx0].lerp(raw_pts[idx1], frac)
        succ, loc, norm, _ = bp.closest_point_on_mesh(pt)
        if succ:
            samples.append((loc, norm.normalized()))
        else:
            samples.append((pt, Vector((-1, 0, 0))))
    return samples


front_samples = sample_spline_on_bp(front_raw, 30)
bottom_samples = sample_spline_on_bp(bottom_raw, 30)
rear_samples = sample_spline_on_bp(rear_raw, 40)


def create_channel_ribbon(bm, samples, is_left=True, width=0.030, depth=0.015, lift=0.011):
    n = len(samples)
    if n < 2:
        return
    out_l, out_r, in_l, in_r = [], [], [], []
    for i in range(n):
        loc, norm = samples[i]
        P = Vector((loc.x * (1 if is_left else -1), loc.y, loc.z))
        N = Vector((norm.x * (1 if is_left else -1), norm.y, norm.z)).normalized()
        if i == 0:
            pn = samples[1][0]
            T = Vector(((pn.x - loc.x) * (1 if is_left else -1), pn.y - loc.y, pn.z - loc.z)).normalized()
        elif i == n - 1:
            pp = samples[n - 2][0]
            T = Vector(((loc.x - pp.x) * (1 if is_left else -1), loc.y - pp.y, loc.z - pp.z)).normalized()
        else:
            pp = samples[i - 1][0]
            pn = samples[i + 1][0]
            T = Vector(((pn.x - pp.x) * (1 if is_left else -1), pn.y - pp.y, pn.z - pp.z)).normalized()
        W = N.cross(T).normalized()
        p_lift = P + N * lift
        vol = bm.verts.new(p_lift - W * (width * 0.5))
        vor = bm.verts.new(p_lift + W * (width * 0.5))
        p_floor = P - N * depth
        vil = bm.verts.new(p_floor - W * (width * 0.35))
        vir = bm.verts.new(p_floor + W * (width * 0.35))
        out_l.append(vol)
        out_r.append(vor)
        in_l.append(vil)
        in_r.append(vir)

    bm.verts.ensure_lookup_table()
    for i in range(n - 1):
        for quad in (
            (out_l[i], out_r[i], out_r[i + 1], out_l[i + 1]),
            (in_l[i], in_r[i], in_r[i + 1], in_l[i + 1]),
            (out_l[i], in_l[i], in_l[i + 1], out_l[i + 1]),
            (out_r[i], in_r[i], in_r[i + 1], out_r[i + 1]),
        ):
            try:
                f = bm.faces.new(quad)
                f.smooth = True
            except Exception:
                pass


me = bpy.data.meshes.new("Door_ShutLines_Mesh")
bm = bmesh.new()
for is_left in (True, False):
    create_channel_ribbon(bm, front_samples, is_left=is_left, width=0.030)
    create_channel_ribbon(bm, bottom_samples, is_left=is_left, width=0.026)
    create_channel_ribbon(bm, rear_samples, is_left=is_left, width=0.030)
bm.to_mesh(me)
bm.free()
me.validate()

door_obj = bpy.data.objects.new("Door_ShutLines", me)
bpy.context.collection.objects.link(door_obj)
assign_single_mat(door_obj, mat_cavity)
door_obj.location = (0, 0, 0)
if col_body:
    col_body.objects.link(door_obj)
    if door_obj.name in bpy.context.scene.collection.objects:
        bpy.context.scene.collection.objects.unlink(door_obj)

print(f"DOOR_SHUTLINES_REBUILT verts={len(me.vertices)} (frameless 3-sided, no beltline)")

# ----------------------------------------------------------------------------
# 6. B-pillar rake + quarter-window elongation (greenhouse refinement)
# ----------------------------------------------------------------------------
def rake_b_pillar(obj, rake=B_PILLAR_RAKE, z_bottom=2.20):
    me = obj.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.verts.ensure_lookup_table()
    moved = 0
    for v in bm.verts:
        c = v.co
        if 1.05 <= abs(c.x) <= 2.65 and -1.85 <= c.y <= -1.08 and c.z >= z_bottom:
            v.co.y -= rake * (c.z - z_bottom)
            moved += 1
    bm.to_mesh(me)
    bm.free()
    me.update()
    return moved


def elongate_quarter_window(obj, amount=QUARTER_ELONGATE):
    me = obj.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.verts.ensure_lookup_table()
    moved = 0
    for v in bm.verts:
        c = v.co
        if abs(c.x) > 2.0 and c.y < -3.20 and c.z < 4.0:
            v.co.y -= amount
            moved += 1
    bm.to_mesh(me)
    bm.free()
    me.update()
    return moved


chassis = bpy.data.objects.get("Chassis_Underbody")
if chassis is not None:
    n = rake_b_pillar(chassis)
    print(f"B_PILLAR_RAKED verts_moved={n}")

glass = bpy.data.objects.get("Body_Glass")
if glass is not None:
    n = elongate_quarter_window(glass)
    print(f"QUARTER_WINDOW_ELONGATED verts_moved={n}")

# ----------------------------------------------------------------------------
# 7. Universal origin & scale for every Body_Assembly mesh
# ----------------------------------------------------------------------------
for obj in col_body.objects:
    if obj.type == "MESH":
        obj.location = (0, 0, 0)
        obj.rotation_euler = (0, 0, 0)
        obj.scale = (1, 1, 1)

# ----------------------------------------------------------------------------
# 8. Save master .blend
# ----------------------------------------------------------------------------
bpy.ops.wm.save_as_mainfile(filepath=BLEND_DST)
print("FINAL_MASTER_BLEND_SAVED")

# ----------------------------------------------------------------------------
# 9. Export production .fbx
# ----------------------------------------------------------------------------
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

# ----------------------------------------------------------------------------
# 10. Verification renders (orthographic blueprint views + hero)
# ----------------------------------------------------------------------------
scene = bpy.context.scene
cam = scene.camera
if cam is None:
    cam_data = bpy.data.cameras.new("Cam")
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam

cam.data.type = "ORTHO"
cam.data.ortho_scale = 16.0
scene.render.resolution_x = 1600
scene.render.resolution_y = 900

# (a) Side elevation ortho
aim_cam(cam, (-18.0, 0.0, 1.7), (0.0, 0.0, 1.3))
scene.render.filepath = RENDER_DIR + r"\blueprint_side_comparison.png"
bpy.ops.render.render(write_still=True)

# (b) Rear elevation ortho
aim_cam(cam, (0.0, -11.0, 1.5), (0.0, 0.0, 1.2))
scene.render.filepath = RENDER_DIR + r"\blueprint_rear_comparison.png"
bpy.ops.render.render(write_still=True)

# (c) Top plan ortho
cam.data.ortho_scale = 18.0
cam.location = (0.0, 0.0, 14.0)
cam.rotation_euler = (0.0, 0.0, math.radians(90))
scene.render.filepath = RENDER_DIR + r"\blueprint_top_comparison.png"
bpy.ops.render.render(write_still=True)

# (d) Front 3/4 perspective hero
cam.data.type = "PERSP"
cam.data.lens = 42
aim_cam(cam, (-9.5, 7.5, 3.2), (0.0, 0.5, 1.2))
scene.render.filepath = RENDER_DIR + r"\blueprint_hero_34.png"
bpy.ops.render.render(write_still=True)

print("ALL_FINAL_RENDERS_SUCCESS")
