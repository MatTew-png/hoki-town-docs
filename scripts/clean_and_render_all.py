import bpy
import bmesh
from mathutils import Vector

BLEND_PATH = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"
RENDER_DIR = r"c:\Users\_newgen\Documents\antigravity\HOKI TOWN\.scratch"

bpy.ops.wm.open_mainfile(filepath=BLEND_PATH)

cu = bpy.data.objects.get("Chassis_Underbody")
bm = bmesh.new()
bm.from_mesh(cu.data)
bm.verts.ensure_lookup_table()
bm.faces.ensure_lookup_table()

# Find faces in cu that poke out near rear scoop (abs(x) > 2.9, -2.5 < y < -2.2, z > 2.4)
stray_faces = [f for f in bm.faces if any(abs(v.co.x) > 2.95 and -2.5 < v.co.y < -2.2 and v.co.z > 2.4 for v in f.verts)]
print(f"Stray scoop faces found: {len(stray_faces)}")
for f in stray_faces:
    print(f"  Removing stray face: {[v.co for v in f.verts]}")
    bm.faces.remove(f)

# Also ensure no vertices of scoop backing walls exceed the body contour
for v in bm.verts:
    # If near rear scoop and Z > 2.4, ensure abs(X) < 2.90
    if -3.8 < v.co.y < -2.2 and v.co.z > 2.4 and abs(v.co.x) > 2.90:
        old_x = v.co.x
        v.co.x = (2.85 if v.co.x > 0 else -2.85)
        print(f"Tucked vert X: {old_x:.3f} -> {v.co.x:.3f}")

bm.to_mesh(cu.data)
bm.free()
cu.data.update()

bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
print("SAVED_CLEAN_MASTER")

# -----------------------------------------------------------------------------
# RENDER ALL 6 VERIFIED CLOSE-UPS
# -----------------------------------------------------------------------------
scene = bpy.context.scene
cam = scene.camera

def aim_cam(pos, target, lens=50):
    cam.location = Vector(pos)
    cam.rotation_euler = (Vector(target) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = lens

# 1. B-Pillar & Greenhouse Side Profile
aim_cam((-5.2, -1.6, 3.5), (-2.0, -1.6, 3.4), lens=55)
scene.render.resolution_x = 1000
scene.render.resolution_y = 800
scene.render.filepath = RENDER_DIR + r"\final_v1_bpillar.png"
bpy.ops.render.render(write_still=True)

# 2. Roof Rail & B-Pillar Top Angle
aim_cam((-4.2, -1.5, 4.8), (-1.8, -1.5, 3.8), lens=60)
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.render.filepath = RENDER_DIR + r"\final_v2_roof_rail.png"
bpy.ops.render.render(write_still=True)

# 3. Underbody Rear Angle looking forward
aim_cam((0.0, -11.5, -0.4), (0.0, -1.5, 0.9), lens=32)
scene.render.resolution_x = 1000
scene.render.resolution_y = 650
scene.render.filepath = RENDER_DIR + r"\final_v3_underbody_rear.png"
bpy.ops.render.render(write_still=True)

# 4. Rear Side Scoop (isolated, cleanly tucked)
aim_cam((-6.5, -2.8, 1.8), (-3.1, -2.8, 1.8), lens=55)
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.render.filepath = RENDER_DIR + r"\final_v4_rear_scoop.png"
bpy.ops.render.render(write_still=True)

# 5. Front Fender Vents & Wheel Arch
aim_cam((-6.5, 4.0, 1.8), (-3.0, 4.0, 1.8), lens=55)
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.render.filepath = RENDER_DIR + r"\final_v5_front_fender_vents.png"
bpy.ops.render.render(write_still=True)

# 6. Front Bumper Cheeks (wide front view showing both cheeks matching user Image 5)
aim_cam((0.0, 14.5, 2.0), (0.0, 6.5, 1.1), lens=65)
scene.render.resolution_x = 1200
scene.render.resolution_y = 600
scene.render.filepath = RENDER_DIR + r"\final_v6_front_cheeks.png"
bpy.ops.render.render(write_still=True)

# 7. Side Profile Full Car
cam.data.type = 'ORTHO'
cam.data.ortho_scale = 16.0
aim_cam((-18.0, 0.0, 1.8), (0.0, 0.0, 1.5))
scene.render.resolution_x = 1600
scene.render.resolution_y = 800
scene.render.filepath = RENDER_DIR + r"\final_v7_side_profile.png"
bpy.ops.render.render(write_still=True)

print("ALL_FINAL_RENDERS_DONE")
