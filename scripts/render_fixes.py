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

# Lighting
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

# 1. Close-up of Quarter Window & B-Pillar (matching user Images 1 & 2)
aim_cam((-5.2, -1.8, 3.5), (-2.1, -1.8, 3.4), lens=60)
scene.render.resolution_x = 1000
scene.render.resolution_y = 800
scene.render.filepath = RENDER_DIR + r"\proof_fix1_quarter_glass.png"
bpy.ops.render.render(write_still=True)

# 2. Close-up of Front Hood Crease / Drop (matching user Image 3)
aim_cam((-3.5, 5.2, 3.0), (-1.8, 6.4, 1.9), lens=55)
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.render.filepath = RENDER_DIR + r"\proof_fix2_hood_hole.png"
bpy.ops.render.render(write_still=True)

# 3. Looking Down Flank from Front (matching user Image 4 & 5)
aim_cam((-3.4, 8.5, 2.2), (-3.2, -1.0, 1.2), lens=75)
scene.render.resolution_x = 600
scene.render.resolution_y = 1200
scene.render.filepath = RENDER_DIR + r"\proof_fix3_wheel_fitment_front.png"
bpy.ops.render.render(write_still=True)

# 4. Looking Down Flank from Rear (matching user Image 4 & 5)
aim_cam((-3.4, -8.5, 2.2), (-3.2, 1.0, 1.2), lens=75)
scene.render.resolution_x = 600
scene.render.resolution_y = 1200
scene.render.filepath = RENDER_DIR + r"\proof_fix3_wheel_fitment_rear.png"
bpy.ops.render.render(write_still=True)

# 5. Full Side Profile
cam.data.type = 'ORTHO'
cam.data.ortho_scale = 16.0
aim_cam((-18.0, 0.0, 1.8), (0.0, 0.0, 1.5))
scene.render.resolution_x = 1600
scene.render.resolution_y = 800
scene.render.filepath = RENDER_DIR + r"\proof_fix4_side_profile.png"
bpy.ops.render.render(write_still=True)

print("ALL_FIX_PROOFS_RENDERED")
