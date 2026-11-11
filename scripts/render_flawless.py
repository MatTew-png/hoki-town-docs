import bpy
from mathutils import Vector

bpy.ops.wm.open_mainfile(filepath=r"C:\Users\_newgen\Downloads\Tesla_Roadster_Unified_Flawless.blend")
scene = bpy.context.scene
cam = scene.camera
if not cam:
    cam_data = bpy.data.cameras.new("Cam")
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam

def aim_cam(pos, target, lens=35):
    cam.location = Vector(pos)
    cam.rotation_euler = (Vector(target) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = lens

# View 1: Matching Image 1 (side door)
aim_cam((-8.5, 0.6, 2.2), (-2.6, 0.4, 2.1), lens=32)
scene.render.resolution_x = 1200
scene.render.resolution_y = 600
scene.render.filepath = r"c:\Users\_newgen\Documents\antigravity\HOKI TOWN\.scratch\flawless_door.png"
bpy.ops.render.render(write_still=True)

# View 2: Matching Image 2 (rear door seam / B-pillar close-up)
aim_cam((-6.5, -1.8, 2.7), (-2.8, -1.8, 2.6), lens=50)
scene.render.resolution_x = 1200
scene.render.resolution_y = 600
scene.render.filepath = r"c:\Users\_newgen\Documents\antigravity\HOKI TOWN\.scratch\flawless_seam_close.png"
bpy.ops.render.render(write_still=True)

# View 3: Matching Image 3 (glass side view)
aim_cam((-12.0, -0.2, 3.2), (-2.0, -0.2, 3.2), lens=40)
scene.render.resolution_x = 1200
scene.render.resolution_y = 600
scene.render.filepath = r"c:\Users\_newgen\Documents\antigravity\HOKI TOWN\.scratch\flawless_glass.png"
bpy.ops.render.render(write_still=True)

print("FLAWLESS_RENDERS_DONE")
