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

# Aim directly at front left hood crease (around X=-2.0, Y=6.3, Z=2.0)
cam.data.type = 'PERSP'
aim_cam((-3.8, 5.0, 3.2), (-1.8, 6.4, 1.9), lens=60)
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.render.filepath = RENDER_DIR + r"\check_hood_hole.png"
bpy.ops.render.render(write_still=True)
print("HOOD_HOLE_RENDERED")
