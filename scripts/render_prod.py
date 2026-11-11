import bpy
from mathutils import Vector

bpy.ops.wm.open_mainfile(filepath=r"C:\Users\_newgen\Downloads\Tesla_Roadster_Production.blend")
scene = bpy.context.scene
cam = scene.camera
if not cam:
    cam_data = bpy.data.cameras.new("Cam")
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam

# Let's frame the door area in Production.blend
cam.data.type = 'PERSP'
cam.data.lens = 32
cam.location = Vector((-8.5, 0.6, 2.2))
targ = Vector((-2.6, 0.4, 2.1))
cam.rotation_euler = (targ - cam.location).to_track_quat("-Z", "Y").to_euler()

scene.render.resolution_x = 1200
scene.render.resolution_y = 600
scene.render.filepath = r"c:\Users\_newgen\Documents\antigravity\HOKI TOWN\.scratch\prod_door.png"
bpy.ops.render.render(write_still=True)

# Also close-up like Image 2
cam.data.lens = 70
cam.location = Vector((-6.5, -1.8, 2.8))
targ = Vector((-2.9, -1.8, 2.6))
cam.rotation_euler = (targ - cam.location).to_track_quat("-Z", "Y").to_euler()
scene.render.filepath = r"c:\Users\_newgen\Documents\antigravity\HOKI TOWN\.scratch\prod_door_close.png"
bpy.ops.render.render(write_still=True)

print("PROD_RENDERS_DONE")
