import bpy
import bmesh

bpy.ops.wm.open_mainfile(filepath=r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend")
bp = bpy.data.objects.get("Body_Paint")

bm = bmesh.new()
bm.from_mesh(bp.data)
bm.edges.ensure_lookup_table()
bm.verts.ensure_lookup_table()

# Helper to find connected boundary loops
def get_boundary_loops(edges):
    visited = set()
    loops = []
    edge_set = set(edges)
    
    for start_edge in edges:
        if start_edge in visited:
            continue
        loop = [start_edge]
        visited.add(start_edge)
        
        # Traverse forward
        curr_vert = start_edge.verts[1]
        while True:
            next_edge = None
            for e in curr_vert.link_edges:
                if e in edge_set and e not in visited:
                    next_edge = e
                    break
            if next_edge:
                visited.add(next_edge)
                loop.append(next_edge)
                curr_vert = next_edge.other_vert(curr_vert)
            else:
                break
        loops.append(loop)
    return loops

# 1. Rear Scoops
print("=== 1. REAR SCOOPS ===")
for side, sgn in [("Left", -1), ("Right", 1)]:
    edges = [e for e in bm.edges if e.is_boundary and (sgn * e.verts[0].co.x > 2.5) and -3.6 < e.verts[0].co.y < -2.0 and 1.1 < e.verts[0].co.z < 2.3]
    print(f"\n{side} Rear Scoop: {len(edges)} boundary edges")
    verts = list({v for e in edges for v in e.verts})
    print(f"Verts ({len(verts)}): {[v.index for v in verts]}")
    for v in verts:
        print(f"  v{v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f})")

# 2. Front Fender Vents
print("\n=== 2. FRONT FENDER VENTS ===")
for side, sgn in [("Left", -1), ("Right", 1)]:
    edges = [e for e in bm.edges if e.is_boundary and (sgn * e.verts[0].co.x > 2.5) and 2.4 < e.verts[0].co.y < 3.8 and 1.1 < e.verts[0].co.z < 2.3]
    print(f"\n{side} Front Fender Vent: {len(edges)} boundary edges")
    verts = list({v for e in edges for v in e.verts})
    print(f"Verts ({len(verts)}): {[v.index for v in verts]}")
    for v in verts:
        print(f"  v{v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f})")

# 3. Front Bumper Cheek Vents
print("\n=== 3. FRONT BUMPER CHEEKS ===")
for side, sgn in [("Left", -1), ("Right", 1)]:
    edges = [e for e in bm.edges if e.is_boundary and (sgn * e.verts[0].co.x > 1.2) and e.verts[0].co.y > 6.0 and 0.8 < e.verts[0].co.z < 1.7]
    print(f"\n{side} Front Cheek: {len(edges)} boundary edges")
    verts = list({v for e in edges for v in e.verts})
    print(f"Verts ({len(verts)}): {[v.index for v in verts]}")

bm.free()
