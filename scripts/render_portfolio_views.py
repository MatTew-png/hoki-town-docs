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

# Lighting: balanced three-point studio lighting
for o in list(bpy.data.objects):
    if o.type == 'LIGHT':
        bpy.data.objects.remove(o, do_unlink=True)

def make_light(name, pos, energy, color=(1,1,1)):
    light_data = bpy.data.lights.new(name=name, type='POINT')
    light_data.energy = energy
    light_data.color = color
    light_obj = bpy.data.objects.new(name=name, object_data=light_data)
    bpy.context.collection.objects.link(light_obj)
    light_obj.location = Vector(pos)

make_light("Key", (-8, 6, 6), 800)
make_light("Fill", (8, -6, 5), 500)
make_light("Under", (0, -2, -2), 300)
make_light("Top", (0, 0, 8), 600)
make_light("Back", (0, -8, 2), 600)

cam.data.type = 'PERSP'

# 1. B-Pillar & Greenhouse Side Profile (matching user attachments 3 & 5)
aim_cam((-5.2, -1.6, 3.5), (-2.0, -1.6, 3.4), lens=55)
scene.render.resolution_x = 1000
scene.render.resolution_y = 800
scene.render.filepath = RENDER_DIR + r"\verified_v1_bpillar.png"
bpy.ops.render.render(write_still=True)

# 2. Roof Rail & B-Pillar Top Angle (matching user attachments 5 & 6)
aim_cam((-4.2, -1.5, 4.8), (-1.8, -1.5, 3.8), lens=60)
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.render.filepath = RENDER_DIR + r"\verified_v2_roof_rail.png"
bpy.ops.render.render(write_still=True)

# 3. Underbody Rear Angle looking forward (matching user attachment 4)
aim_cam((0.0, -11.5, -0.4), (0.0, -1.5, 0.9), lens=32)
scene.render.resolution_x = 1000
scene.render.resolution_y = 650
scene.render.filepath = RENDER_DIR + r"\verified_v3_underbody_rear.png"
bpy.ops.render.render(write_still=True)

# 4. Rear Side Scoop (matching user attachment 7)
aim_cam((-6.5, -2.8, 1.8), (-3.1, -2.8, 1.8), lens=55)
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.render.filepath = RENDER_DIR + r"\verified_v4_rear_scoop.png"
bpy.ops.render.render(write_still=True)

# 5. Front Fender Vents & Wheel Arch (matching user attachment 8)
aim_cam((-6.5, 4.0, 1.8), (-3.0, 4.0, 1.8), lens=55)
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.render.filepath = RENDER_DIR + r"\verified_v5_front_fender_vents.png"
bpy.ops.render.render(write_still=True)

# 6. Front Bumper Lower Cheeks (matching user attachment 9)
aim_cam((0.0, 8.8, 1.0), (0.0, 6.2, 1.1), lens=42)
scene.render.resolution_x = 1100
scene.render.resolution_y = 550
scene.render.filepath = RENDER_DIR + r"\verified_v6_front_cheeks.png"
bpy.ops.render.render(write_still=True)

# 7. Side Profile Full Car (matching user attachment 1 & 3)
cam.data.type = 'ORTHO'
cam.data.ortho_scale = 16.0
aim_cam((-18.0, 0.0, 1.8), (0.0, 0.0, 1.5))
scene.render.resolution_x = 1600
scene.render.resolution_y = 800
scene.render.filepath = RENDER_DIR + r"\verified_v7_side_profile.png"
bpy.ops.render.render(write_still=True)

print("ALL_7_VERIFICATION_VIEWS_RENDERED")
