import bpy
from mathutils import Vector

bpy.ops.wm.open_mainfile(filepath=r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend")

wheel_centers = {
    "FL": Vector((-2.93, 4.64, 1.17)),
    "FR": Vector((2.93, 4.64, 1.17)),
    "RL": Vector((-2.95, -4.90, 1.19)),
    "RR": Vector((2.95, -4.90, 1.19)),
}

for side, cen in wheel_centers.items():
    for prefix in ["Wheel_", "Tire_"]:
        name = prefix + side
        o = bpy.data.objects.get(name)
        if o:
            # Shift mesh vertices by cen so they sit in wheel wells with origin at (0, 0, 0)
            for v in o.data.vertices:
                v.co += cen
            o.data.update()
            o.location = (0, 0, 0)

bpy.ops.wm.save_as_mainfile(filepath=r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend")

# Re-render side ortho
scene = bpy.context.scene
cam = scene.camera
cam.data.type = 'ORTHO'
cam.data.ortho_scale = 16.0
cam.location = Vector((-18.0, 0.0, 1.7))
targ = Vector((0.0, 0.0, 1.3))
cam.rotation_euler = (targ - cam.location).to_track_quat("-Z", "Y").to_euler()

scene.render.resolution_x = 1600
scene.render.resolution_y = 800
scene.render.filepath = r"c:\Users\_newgen\Documents\antigravity\HOKI TOWN\.scratch\verified_side_ortho.png"
bpy.ops.render.render(write_still=True)
print("VERIFIED_SIDE_ORTHO_DONE")
