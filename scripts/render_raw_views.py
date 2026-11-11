import bpy
from mathutils import Vector

bpy.ops.wm.open_mainfile(filepath=r"C:\Users\_newgen\Downloads\Tesla_Roadster_Original_Raw.blend")

scene = bpy.context.scene
cam_data = bpy.data.cameras.new("Cam")
cam = bpy.data.objects.new("Cam", cam_data)
scene.collection.objects.link(cam)
scene.camera = cam

# Add a light
light_data = bpy.data.lights.new("Sun", type='SUN')
light_data.energy = 3.0
light = bpy.data.objects.new("Sun", light_data)
scene.collection.objects.link(light)

def aim_cam(pos, target, ortho=False, scale=16.0):
    cam.location = Vector(pos)
    cam.rotation_euler = (Vector(target) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    if ortho:
        cam.data.type = 'ORTHO'
        cam.data.ortho_scale = scale
    else:
        cam.data.type = 'PERSP'
        cam.data.lens = 45

# 1. Side view
aim_cam((-15.0, 0.0, 2.0), (0.0, 0.0, 2.0), ortho=True, scale=14.0)
scene.render.resolution_x = 1200
scene.render.resolution_y = 600
scene.render.filepath = r"c:\Users\_newgen\Documents\antigravity\HOKI TOWN\.scratch\raw_side.png"
bpy.ops.render.render(write_still=True)

# 2. Side window close-up
aim_cam((-8.0, -0.2, 3.2), (-2.5, -0.2, 3.2), ortho=False)
scene.render.resolution_x = 1200
scene.render.resolution_y = 600
scene.render.filepath = r"c:\Users\_newgen\Documents\antigravity\HOKI TOWN\.scratch\raw_window_close.png"
bpy.ops.render.render(write_still=True)

# 3. Bottom view (underbody)
aim_cam((0.0, -11.0, -1.8), (0.0, 0.0, 1.5), ortho=False)
scene.render.resolution_x = 1200
scene.render.resolution_y = 600
scene.render.filepath = r"c:\Users\_newgen\Documents\antigravity\HOKI TOWN\.scratch\raw_bottom.png"
bpy.ops.render.render(write_still=True)

print("RAW_RENDERS_DONE")
