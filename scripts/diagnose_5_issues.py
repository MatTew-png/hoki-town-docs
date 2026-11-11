import bpy
import bmesh
from mathutils import Vector

BLEND_PATH = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"
bpy.ops.wm.open_mainfile(filepath=BLEND_PATH)

print("=== CHECKING ALL OBJECTS ===")
for o in bpy.data.objects:
    if o.type == 'MESH':
        print(f"Object: {o.name}, Verts: {len(o.data.vertices)}, Polys: {len(o.data.polygons)}")

bp = bpy.data.objects.get("Body_Paint")
bg = bpy.data.objects.get("Body_Glass")
cu = bpy.data.objects.get("Chassis_Underbody")
inter = bpy.data.objects.get("Interior")

# Let's inspect B-pillar and roof in bp and bg
bm_bp = bmesh.new()
bm_bp.from_mesh(bp.data)
bm_bp.verts.ensure_lookup_table()
bm_bp.edges.ensure_lookup_table()

# Find boundary edges on Body_Paint around the roof and B pillar
b_edges_bp = [e for e in bm_bp.edges if len(e.link_faces) == 1]
print(f"Total boundary edges on Body_Paint: {len(b_edges_bp)}")

# Boundary edges around roof / B pillar: -2.0 < y < -1.0, z > 2.8
roof_bp_edges = [e for e in b_edges_bp if -2.2 < (e.verts[0].co.y + e.verts[1].co.y)/2 < -1.0 and (e.verts[0].co.z + e.verts[1].co.z)/2 > 2.8]
print(f"Boundary edges around roof/B-pillar on Body_Paint: {len(roof_bp_edges)}")
for e in roof_bp_edges:
    v0, v1 = e.verts[0], e.verts[1]
    print(f"  BP e({v0.index}, {v1.index}): ({v0.co.x:.3f}, {v0.co.y:.3f}, {v0.co.z:.3f}) -> ({v1.co.x:.3f}, {v1.co.y:.3f}, {v1.co.z:.3f})")

# Let's check Body_Glass around B pillar: -2.2 < y < -1.0
bm_bg = bmesh.new()
bm_bg.from_mesh(bg.data)
bm_bg.verts.ensure_lookup_table()
bm_bg.edges.ensure_lookup_table()
b_edges_bg = [e for e in bm_bg.edges if len(e.link_faces) == 1]
print(f"Total boundary edges on Body_Glass: {len(b_edges_bg)}")
bg_bp_edges = [e for e in b_edges_bg if -2.2 < (e.verts[0].co.y + e.verts[1].co.y)/2 < -1.0]
print(f"Boundary edges around B-pillar on Body_Glass: {len(bg_bp_edges)}")
for e in bg_bp_edges:
    v0, v1 = e.verts[0], e.verts[1]
    print(f"  BG e({v0.index}, {v1.index}): ({v0.co.x:.3f}, {v0.co.y:.3f}, {v0.co.z:.3f}) -> ({v1.co.x:.3f}, {v1.co.y:.3f}, {v1.co.z:.3f})")

# Check underbody rear boundary
bm_cu = bmesh.new()
bm_cu.from_mesh(cu.data)
bm_cu.verts.ensure_lookup_table()
bm_cu.edges.ensure_lookup_table()
b_edges_cu = [e for e in bm_cu.edges if len(e.link_faces) == 1]
print(f"Total boundary edges on Chassis_Underbody: {len(b_edges_cu)}")

# CU boundary edges around the rear floor (y < -3.5, z < 1.5)
rear_floor_edges = [e for e in b_edges_cu if (e.verts[0].co.y + e.verts[1].co.y)/2 < -3.5 and (e.verts[0].co.z + e.verts[1].co.z)/2 < 1.5]
print(f"Boundary edges on rear underbody floor: {len(rear_floor_edges)}")
for e in rear_floor_edges[:20]:
    v0, v1 = e.verts[0], e.verts[1]
    print(f"  CU rear e({v0.index}, {v1.index}): ({v0.co.x:.3f}, {v0.co.y:.3f}, {v0.co.z:.3f}) -> ({v1.co.x:.3f}, {v1.co.y:.3f}, {v1.co.z:.3f})")
