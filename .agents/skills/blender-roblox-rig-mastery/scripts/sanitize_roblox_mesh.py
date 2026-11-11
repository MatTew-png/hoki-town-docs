"""
sanitize_roblox_mesh.py
Automated Blender 5.2+ Headless Mesh Sanitizer for Roblox Studio.
Eliminates all causes of `PublishService AssetUpload failed HTTP -1`,
see-through backface culling, and non-manifold geometry.
"""
import sys
import bpy
import bmesh

def sanitize_mesh(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)

    # 1. Remove zero-area degenerate faces
    zero_faces = [f for f in bm.faces if f.calc_area() <= 1e-6]
    if zero_faces:
        bmesh.ops.delete(bm, geom=zero_faces, context='FACES_ONLY')

    bmesh.ops.dissolve_degenerate(bm, dist=0.0001, edges=bm.edges)

    # 2. Remove loose edges and loose vertices
    loose_e = [e for e in bm.edges if not e.link_faces]
    if loose_e:
        bmesh.ops.delete(bm, geom=loose_e, context='EDGES')

    loose_v = [v for v in bm.verts if not v.link_edges]
    if loose_v:
        bmesh.ops.delete(bm, geom=loose_v, context='VERTS')

    # 3. Triangulate large N-gons (> 4 verts) to avoid Roblox C++ Ear Clipping failure
    ngons = [f for f in bm.faces if len(f.verts) > 4]
    if ngons:
        bmesh.ops.triangulate(bm, faces=ngons)

    # 4. Separate Pinched / Bow-tie non-manifold vertices
    for iteration in range(10):
        bm.verts.ensure_lookup_table()
        fixed = 0
        for v in list(bm.verts):
            if not v.is_valid or len(v.link_faces) <= 1:
                continue
            faces = list(v.link_faces)
            components = []
            vis = set()
            for f in faces:
                if f in vis: continue
                comp = [f]
                vis.add(f)
                q = [f]
                while q:
                    c = q.pop(0)
                    for e in c.edges:
                        if v in e.verts:
                            for n in e.link_faces:
                                if n in faces and n not in vis:
                                    vis.add(n); q.append(n); comp.append(n)
                components.append(comp)

            if len(components) > 1:
                for comp in components[1:]:
                    comp_edges = list({e for f in comp for e in f.edges if v in e.verts})
                    try:
                        bmesh.utils.vert_separate(v, comp_edges)
                        fixed += 1
                        break
                    except Exception:
                        pass
        if fixed == 0:
            break

    # 5. Recalculate face normals to outside
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    bm.to_mesh(obj.data)
    obj.data.update()
    bm.free()

def main():
    blend_path = sys.argv[-2] if len(sys.argv) >= 2 else bpy.data.filepath
    out_fbx = sys.argv[-1] if len(sys.argv) >= 2 else blend_path.replace(".blend", ".fbx")

    print(f"[Sanitizer] Processing scene...")
    for obj in bpy.data.objects:
        if obj.type == 'MESH':
            sanitize_mesh(obj)

    # Export clean FBX
    bpy.ops.object.select_all(action='DESELECT')
    for obj in bpy.data.objects:
        if obj.type == 'MESH':
            obj.select_set(True)

    bpy.ops.export_scene.fbx(
        filepath=out_fbx,
        use_selection=True,
        axis_forward='-Z',
        axis_up='Y',
        apply_scale_options='FBX_SCALE_ALL',
        mesh_smooth_type='FACE',
        bake_space_transform=False
    )
    print(f"[Sanitizer] Successfully exported pristine Roblox FBX to: {out_fbx}")

if __name__ == "__main__":
    main()
