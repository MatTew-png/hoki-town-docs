"""
build_vault_chest.py
Generates an authentic, pixel-accurate Vanilla Minecraft Single Chest
in Blender 5.2 using a 14x14x14 voxel grid (1 voxel = 0.625 studs ->
8.75 x 8.75 x 9.375 studs including the 2x4x1 front latch),
separated cleanly by palette/role for crisp Roblox Materials without textures.
"""

import os
import bpy
import bmesh
from mathutils import Vector

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
BLEND_PATH = os.path.join(OUT_DIR, "Hoki_Vault_Chest.blend")
FBX_PATH = os.path.join(OUT_DIR, "Hoki_Vault_Chest.fbx")


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in list(bpy.data.meshes):
        if block.users == 0:
            bpy.data.meshes.remove(block)
    for mat in list(bpy.data.materials):
        if mat.users == 0:
            bpy.data.materials.remove(mat)


def get_or_create_material(name, rgba, roughness=0.75, metallic=0.0):
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name=name)
        mat.diffuse_color = rgba
        mat.roughness = roughness
        mat.metallic = metallic
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = rgba
            bsdf.inputs["Roughness"].default_value = roughness
            bsdf.inputs["Metallic"].default_value = metallic
    return mat


def add_box(bm, min_x, max_x, min_y, max_y, min_z, max_z):
    sx = max_x - min_x
    sy = max_y - min_y
    sz = max_z - min_z
    if sx <= 1e-5 or sy <= 1e-5 or sz <= 1e-5:
        return
    cx = (min_x + max_x) * 0.5
    cy = (min_y + max_y) * 0.5
    cz = (min_z + max_z) * 0.5

    ret = bmesh.ops.create_cube(bm, size=1.0)
    for v in ret["verts"]:
        v.co.x = v.co.x * sx + cx
        v.co.y = v.co.y * sy + cy
        v.co.z = v.co.z * sz + cz


def build_mesh_object(name, boxes, material, origin=(0.0, 0.0, 0.0), parent=None):
    mesh = bpy.data.meshes.new(name + "_Mesh")
    bm = bmesh.new()
    for b in boxes:
        add_box(bm, *b)

    zero_faces = [f for f in bm.faces if f.calc_area() <= 1e-6]
    if zero_faces:
        bmesh.ops.delete(bm, geom=zero_faces, context="FACES_ONLY")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    ox, oy, oz = origin
    if ox != 0.0 or oy != 0.0 or oz != 0.0:
        for v in bm.verts:
            v.co.x -= ox
            v.co.y -= oy
            v.co.z -= oz

    bm.to_mesh(mesh)
    bm.free()
    mesh.update()

    obj = bpy.data.objects.new(name, mesh)
    obj.location = Vector(origin)
    obj.data.materials.append(material)
    bpy.context.collection.objects.link(obj)
    if parent is not None:
        obj.parent = parent
    return obj


# Voxel grid helpers (14x14x14, U = 0.625 studs)
U = 0.625
HALF = 7.0 * U  # 4.375


def vx(i):
    """Grid index 0..14 -> X/Y coordinate in [-4.375, +4.375]."""
    return -HALF + i * U


def vz(k):
    """Grid index 0..14 -> Z coordinate in [0.0, 8.75]."""
    return k * U


def classify_mc_face_pixel(u_idx, v_idx, u_max, v_max):
    """
    Returns palette key for a pixel (u_idx in 0..u_max-1, v_idx in 0..v_max-1)
    matching Vanilla Minecraft Chest face layout:
      - Outer 1px rim: 'border' (#221509)
      - Inner 1px bevel ring: 'bevel' (#825422)
      - Inner wood field: 'oak_main', 'oak_light', 'oak_shade' pixel grain
    """
    if u_idx == 0 or u_idx == u_max - 1 or v_idx == 0 or v_idx == v_max - 1:
        return "border"
    if u_idx == 1 or u_idx == u_max - 2 or v_idx == 1 or v_idx == v_max - 2:
        return "bevel"

    # Deterministic pixel-art wood grain inside the chest panel
    if (u_idx == 2 or v_idx == 2) and (u_idx + v_idx) % 2 == 0:
        return "oak_light"
    if (u_idx == u_max - 3 or v_idx == v_max - 3) and (u_idx + v_idx) % 2 == 1:
        return "oak_shade"

    h = (u_idx * 7 + v_idx * 13) % 11
    if h in (1, 5):
        return "oak_light"
    if h in (3, 8):
        return "oak_shade"
    return "oak_main"


def main():
    clear_scene()

    # Exact Vanilla Minecraft Chest Palette (linear approximations for Blender preview)
    mat_border = get_or_create_material("MC_Chest_Border", (0.04, 0.02, 0.008, 1.0), roughness=0.90)
    mat_bevel  = get_or_create_material("MC_Chest_Bevel",  (0.24, 0.11, 0.025, 1.0), roughness=0.82)
    mat_oak    = get_or_create_material("MC_Chest_Oak",    (0.41, 0.21, 0.045, 1.0), roughness=0.78)
    mat_light  = get_or_create_material("MC_Chest_Light",  (0.50, 0.27, 0.065, 1.0), roughness=0.75)
    mat_shade  = get_or_create_material("MC_Chest_Shade",  (0.31, 0.15, 0.030, 1.0), roughness=0.82)
    mat_latch_hi = get_or_create_material("MC_Latch_Bright", (0.72, 0.72, 0.74, 1.0), roughness=0.35, metallic=0.8)
    mat_latch_md = get_or_create_material("MC_Latch_Mid",    (0.42, 0.42, 0.45, 1.0), roughness=0.40, metallic=0.8)
    mat_latch_dk = get_or_create_material("MC_Latch_Dark",   (0.22, 0.22, 0.24, 1.0), roughness=0.45, metallic=0.8)

    root = bpy.data.objects.new("Hoki_Vault", None)
    bpy.context.collection.objects.link(root)

    # Relief depths (gives subtle, razor-sharp 3D pixel edges on every face)
    RELIEF = {
        "border":    0.000,   # Flush at 4.375
        "bevel":    -0.025,   # Slightly recessed 1px inner bevel
        "oak_light": -0.040,
        "oak_main":  -0.048,
        "oak_shade": -0.056,
    }
    BACK_INSET = 0.28  # Seat pixel tiles firmly into the solid dark inner core

    # =========================================================================
    # 1. BODY (Lower Chest: Z = 0..9 voxels -> 0.0 to 5.625 studs)
    # =========================================================================
    body_buckets = {k: [] for k in RELIEF}
    # Solid dark inner core (prevents any light leak between pixels & forms bottom)
    body_buckets["border"].append((-HALF + 0.12, HALF - 0.12, -HALF + 0.12, HALF - 0.12, 0.02, vz(9) - 0.04))

    # Bottom face (Z = 0)
    body_buckets["border"].append((-HALF, HALF, -HALF, HALF, 0.0, 0.18))

    # 4 vertical faces of Body: u in 0..13 (width 14), v in 0..8 (height 9)
    # Small inset 0.002 on tile edges prevents adjacent-box vertex pinching
    pad = 0.002
    for v_idx in range(9):
        z0 = vz(v_idx) + pad
        z1 = vz(v_idx + 1) - pad
        for u_idx in range(14):
            key = classify_mc_face_pixel(u_idx, v_idx, 14, 9)
            r = RELIEF[key]
            c0 = vx(u_idx) + pad
            c1 = vx(u_idx + 1) - pad
            # Front (-Y)
            body_buckets[key].append((c0, c1, -HALF - r, -HALF + BACK_INSET, z0, z1))
            # Back (+Y)
            body_buckets[key].append((c0, c1, HALF - BACK_INSET, HALF + r, z0, z1))
            # Left (-X)
            body_buckets[key].append((-HALF - r, -HALF + BACK_INSET, c0, c1, z0, z1))
            # Right (+X)
            body_buckets[key].append((HALF - BACK_INSET, HALF + r, c0, c1, z0, z1))

    build_mesh_object("Body_Border_Dark", body_buckets["border"], mat_border, parent=root)
    build_mesh_object("Body_Bevel_Wood",  body_buckets["bevel"],  mat_bevel,  parent=root)
    build_mesh_object("Body_Oak_Main",    body_buckets["oak_main"], mat_oak, parent=root)
    build_mesh_object("Body_Oak_Light",   body_buckets["oak_light"], mat_light, parent=root)
    build_mesh_object("Body_Oak_Shade",   body_buckets["oak_shade"], mat_shade, parent=root)

    # =========================================================================
    # 2. LID (Upper Chest: Z = 9..14 voxels -> 5.625 to 8.75 studs, Pivot at back seam)
    # =========================================================================
    lid_origin = (0.0, HALF, vz(9))
    lid_buckets = {k: [] for k in RELIEF}
    # Solid dark inner core for lid (starts 0.02 above seam for crisp lid line)
    lid_buckets["border"].append((-HALF + 0.12, HALF - 0.12, -HALF + 0.12, HALF - 0.12, vz(9) + 0.04, vz(14) - 0.12))

    # 4 vertical faces of Lid: u in 0..13 (width 14), v in 0..4 (height 5 -> Z = 9..13)
    for v_idx in range(5):
        z0 = vz(9 + v_idx) + (0.02 if v_idx == 0 else pad)
        z1 = vz(10 + v_idx) - pad
        for u_idx in range(14):
            key = classify_mc_face_pixel(u_idx, v_idx, 14, 5)
            r = RELIEF[key]
            c0 = vx(u_idx) + pad
            c1 = vx(u_idx + 1) - pad
            # Front (-Y)
            lid_buckets[key].append((c0, c1, -HALF - r, -HALF + BACK_INSET, z0, z1))
            # Back (+Y)
            lid_buckets[key].append((c0, c1, HALF - BACK_INSET, HALF + r, z0, z1))
            # Left (-X)
            lid_buckets[key].append((-HALF - r, -HALF + BACK_INSET, c0, c1, z0, z1))
            # Right (+X)
            lid_buckets[key].append((HALF - BACK_INSET, HALF + r, c0, c1, z0, z1))

    # Top Roof Face of Lid: 14 x 14 pixels at Z = 14 (8.75 studs)
    for iy in range(14):
        y0 = vx(iy) + pad
        y1 = vx(iy + 1) - pad
        for ix in range(14):
            key = classify_mc_face_pixel(ix, iy, 14, 14)
            r = RELIEF[key]
            x0 = vx(ix) + pad
            x1 = vx(ix + 1) - pad
            lid_buckets[key].append((x0, x1, y0, y1, vz(14) - BACK_INSET, vz(14) + r))

    build_mesh_object("Lid_Border_Dark", lid_buckets["border"], mat_border, origin=lid_origin, parent=root)
    build_mesh_object("Lid_Bevel_Wood",  lid_buckets["bevel"],  mat_bevel,  origin=lid_origin, parent=root)
    build_mesh_object("Lid_Oak_Main",    lid_buckets["oak_main"], mat_oak, origin=lid_origin, parent=root)
    build_mesh_object("Lid_Oak_Light",   lid_buckets["oak_light"], mat_light, origin=lid_origin, parent=root)
    build_mesh_object("Lid_Oak_Shade",   lid_buckets["oak_shade"], mat_shade, origin=lid_origin, parent=root)

    # =========================================================================
    # 3. VANILLA FRONT LATCH (2 x 4 x 1 pixels at X=6..8, Z=7..11, protruding 1px)
    # =========================================================================
    # In Minecraft: latch is 2px wide (X=6,7), 4px tall (Z=7,8,9,10), 1px deep (-Y: 4.375 to 5.000)
    # Top 2 rows (Z=9,10) bright silver, lower 1.5 rows medium gray, bottom edge dark iron
    latch_hi_boxes = [
        (vx(6), vx(8), -HALF - U, -HALF + 0.05, vz(9.2), vz(11)),
    ]
    latch_md_boxes = [
        (vx(6), vx(8), -HALF - U, -HALF + 0.05, vz(7.6), vz(9.18)),
    ]
    latch_dk_boxes = [
        (vx(6), vx(8), -HALF - U, -HALF + 0.05, vz(7.0), vz(7.58)),
    ]
    build_mesh_object("Latch_Silver_Top", latch_hi_boxes, mat_latch_hi, origin=lid_origin, parent=root)
    build_mesh_object("Latch_Iron_Mid",   latch_md_boxes, mat_latch_md, origin=lid_origin, parent=root)
    build_mesh_object("Latch_Iron_Dark",  latch_dk_boxes, mat_latch_dk, origin=lid_origin, parent=root)

    bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
    print(f"[BuildMinecraftChest] Saved .blend -> {BLEND_PATH}")

    bpy.ops.object.select_all(action="DESELECT")
    mesh_count = 0
    tri_count = 0
    for obj in bpy.data.objects:
        if obj.type == "MESH":
            obj.select_set(True)
            mesh_count += 1
            tri_count += sum(len(p.vertices) - 2 for p in obj.data.polygons)

    bpy.ops.export_scene.fbx(
        filepath=FBX_PATH,
        use_selection=True,
        axis_forward="-Z",
        axis_up="Y",
        apply_scale_options="FBX_SCALE_ALL",
        mesh_smooth_type="FACE",
        bake_space_transform=False,
    )
    print(f"[BuildMinecraftChest] Exported .fbx -> {FBX_PATH} (Objects={mesh_count}, Tris={tri_count})")


if __name__ == "__main__":
    main()
