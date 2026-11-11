import bpy
from mathutils import Vector

def render_bottom_view(blend_path, out_png):
    bpy.ops.wm.open_mainfile(filepath=blend_path)
    scene = bpy.context.scene
    cam = scene.camera
    if not cam:
        cam_data = bpy.data.cameras.new("Cam")
        cam = bpy.data.objects.new("Cam", cam_data)
        scene.collection.objects.link(cam)
        scene.camera = cam
    
    cam.data.type = 'PERSP'
    cam.data.lens = 35
    cam.data.clip_end = 100.0
    # Camera at rear underneath: (0, -12, -2), looking up towards (0, 0, 1.5)
    cam.location = Vector((0.0, -11.0, -1.8))
    targ = Vector((0.0, 0.0, 1.5))
    cam.rotation_euler = (targ - cam.location).to_track_quat("-Z", "Y").to_euler()
    
    scene.render.resolution_x = 1000
    scene.render.resolution_y = 600
    scene.render.filepath = out_png
    bpy.ops.render.render(write_still=True)
    print(f"Rendered: {out_png}")

render_bottom_view(r"C:\Users\_newgen\Downloads\Tesla_Roadster_Unified_Flawless.blend", 
                   r"c:\Users\_newgen\Documents\antigravity\HOKI TOWN\.scratch\bottom_orig.png")
render_bottom_view(r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend", 
                   r"c:\Users\_newgen\Documents\antigravity\HOKI TOWN\.scratch\bottom_master.png")
