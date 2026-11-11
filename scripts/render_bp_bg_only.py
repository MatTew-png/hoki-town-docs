import bpy
from mathutils import Vector

bpy.ops.wm.open_mainfile(filepath=r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend")
scene = bpy.context.scene

# Hide everything except Body_Paint and Body_Glass
for o in bpy.data.objects:
    if o.name not in ["Body_Paint", "Body_Glass"]:
        o.hide_render = True
    else:
        o.hide_render = False

cam = scene.camera
cam.data.type = 'PERSP'
cam.data.lens = 75

# 1. Matching user Image 1: looking at B-pillar from side-high angle
cam.location = Vector((-5.5, -1.8, 3.8))
targ = Vector((-1.9, -1.8, 3.6))
cam.rotation_euler = (targ - cam.location).to_track_quat("-Z", "Y").to_euler()

scene.render.resolution_x = 800
scene.render.resolution_y = 1000
scene.render.filepath = r"c:\Users\_newgen\Documents\antigravity\HOKI TOWN\.scratch\user_img1_bp_bg_only.png"
bpy.ops.render.render(write_still=True)

# 2. Matching user Image 2: looking down from roof top
cam.location = Vector((-4.0, -1.8, 5.0))
targ = Vector((-1.8, -1.8, 3.8))
cam.rotation_euler = (targ - cam.location).to_track_quat("-Z", "Y").to_euler()

scene.render.filepath = r"c:\Users\_newgen\Documents\antigravity\HOKI TOWN\.scratch\user_img2_bp_bg_only.png"
bpy.ops.render.render(write_still=True)

print("BP_BG_ONLY_RENDERED")
