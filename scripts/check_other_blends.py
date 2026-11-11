import bpy

for path in [
    r"C:\Users\_newgen\Downloads\Tesla_Roadster_Original_Raw.blend",
    r"C:\Users\_newgen\Downloads\Tesla_Roadster_Base_Pristine.blend",
    r"C:\Users\_newgen\Downloads\Tesla_Roadster_Unified_Flawless.blend",
]:
    print(f"\n=== INSPECTING: {path} ===")
    bpy.ops.wm.open_mainfile(filepath=path)
    for o in bpy.data.objects:
        if "Glass" in o.name or "Window" in o.name or "Body" in o.name or "Chassis" in o.name:
            if o.type == 'MESH':
                print(f"  {o.name}: verts={len(o.data.vertices)}, faces={len(o.data.polygons)}, mats={[m.name for m in o.data.materials if m]}")
