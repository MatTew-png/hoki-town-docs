import bpy
from mathutils import Vector

BLEND_PATH = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"
RENDER_DIR = r"c:\Users\_newgen\Documents\antigravity\HOKI TOWN\.scratch"

bpy.ops.wm.open_mainfile(filepath=BLEND_PATH)

scene = bpy.context.scene
cam = scene.camera

def aim_cam(pos, target, lens=50):
    cam.location = Vector(pos)
    cam.rotation_euler = (Vector(target) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = lens

# Set lighting to clay / solid shading style
for light in [o for o in bpy.data.objects if o.type == 'LIGHT']:
    light.data.energy = 5.0

# 1. Close up of B-pillar and roof hole from outside
cam.data.type = 'PERSP'
aim_cam((-5.0, -1.6, 3.7), (-2.0, -1.6, 3.5), lens=60)
scene.render.resolution_x = 1000
scene.render.resolution_y = 800
scene.render.filepath = RENDER_DIR + r"\check_bpillar_roof.png"
bpy.ops.render.render(write_still=True)

# 2. Underbody from rear (matching user Image 4)
aim_cam((0.0, -12.0, -0.5), (0.0, -2.0, 1.0), lens=35)
scene.render.resolution_x = 1000
scene.render.resolution_y = 600
scene.render.filepath = RENDER_DIR + r"\check_underbody_rear.png"
bpy.ops.render.render(write_still=True)

# 3. Front bumper cheek intakes (matching user Image 5)
aim_cam((0.0, 9.5, 0.8), (0.0, 6.0, 1.2), lens=40)
scene.render.resolution_x = 1000
scene.render.resolution_y = 500
scene.render.filepath = RENDER_DIR + r"\check_front_cheeks.png"
bpy.ops.render.render(write_still=True)

# 4. Front fender vents (matching user Image 4 in first list)
aim_cam((-6.5, 4.0, 1.8), (-3.0, 4.0, 1.8), lens=55)
scene.render.resolution_x = 800
scene.render.resolution_y = 800
scene.render.filepath = RENDER_DIR + r"\check_front_fender_vents.png"
bpy.ops.render.render(write_still=True)

print("CHECKS_RENDERED")
