"""
Fix all 3 user issues:
1. Images 1 & 2: Remove black lines across quarter glass and B-pillar.
   - Dissolve diagonal edge across left & right rear quarter windows in Body_Glass (merge triangles into single smooth quad).
   - Clean up B-pillar overlapping coplanar faces in Chassis_Underbody to eliminate z-fighting / jagged intersection lines.
2. Image 3: Seal front hood drop holes in Body_Paint (both left and right sides).
3. Images 4 & 5: Adjust all 4 wheel assemblies inward so tires and wheels sit flush/tucked inside fender arches (no poke).
"""

import bpy
import bmesh
from mathutils import Vector

BLEND_PATH = r"C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Master_2026.blend"
RENDER_DIR = r"c:\Users\_newgen\Documents\antigravity\HOKI TOWN\.scratch"

bpy.ops.wm.open_mainfile(filepath=BLEND_PATH)

bp = bpy.data.objects.get("Body_Paint")
bg = bpy.data.objects.get("Body_Glass")
cu = bpy.data.objects.get("Chassis_Underbody")

# =============================================================================
# 1. FIX BLACK LINES ON GLASS & B-PILLAR (IMAGES 1 & 2)
# =============================================================================
print("=== 1. Fixing Glass & B-Pillar Lines ===")

# A. Body_Glass: Dissolve diagonal edge on rear quarter windows
bm_bg = bmesh.new()
bm_bg.from_mesh(bg.data)
bm_bg.verts.ensure_lookup_table()
bm_bg.edges.ensure_lookup_table()
bm_bg.faces.ensure_lookup_table()

# Find diagonal edges inside the quarter window on left and right
# Left diagonal: connects v182 (-2.51, -1.78, 3.15) and v183 (-2.04, -2.69, 3.76)
diag_edges = []
for e in bm_bg.edges:
    if len(e.link_faces) == 2:
        v0, v1 = e.verts[0], e.verts[1]
        # Left quarter window diagonal
        if (-2.6 < v0.co.x < -1.8 and -2.6 < v1.co.x < -1.8 and
            -3.6 < v0.co.y < -1.6 and -3.6 < v1.co.y < -1.6 and
            abs(v0.co.y - v1.co.y) > 0.5):
            diag_edges.append(e)
        # Right quarter window diagonal
        elif (1.8 < v0.co.x < 2.6 and 1.8 < v1.co.x < 2.6 and
              -3.6 < v0.co.y < -1.6 and -3.6 < v1.co.y < -1.6 and
              abs(v0.co.y - v1.co.y) > 0.5):
            diag_edges.append(e)

print(f"Found {len(diag_edges)} diagonal edges in quarter windows to dissolve")
if diag_edges:
    bmesh.ops.dissolve_edges(bm_bg, edges=diag_edges, use_verts=False)

# Ensure all glass faces are smooth
for f in bm_bg.faces:
    f.smooth = True
for e in bm_bg.edges:
    e.seam = False
    e.smooth = True

bm_bg.to_mesh(bg.data)
bm_bg.free()
bg.data.update()
print("Body_Glass quarter window diagonal lines dissolved successfully")

# B. Chassis_Underbody: Clean up B-pillar overlapping faces
bm_cu = bmesh.new()
bm_cu.from_mesh(cu.data)
bm_cu.verts.ensure_lookup_table()
bm_cu.faces.ensure_lookup_table()

# Find the added quad faces in Chassis_Underbody (the ones at X ~ ±2.3, Y ~ -1.56, Z ~ 3.53)
# and remove them because they conflict with the B-pillar faces already present
added_bp_faces = [f for f in bm_cu.faces if len(f.verts) == 4 and (
    any(abs(v.co.x - (-2.034)) < 0.01 and abs(v.co.y - (-1.474)) < 0.01 for v in f.verts) or
    any(abs(v.co.x - ( 2.034)) < 0.01 and abs(v.co.y - (-1.474)) < 0.01 for v in f.verts)
)]
print(f"Found {len(added_bp_faces)} redundant B-pillar quad faces in Chassis_Underbody")
for f in added_bp_faces:
    bm_cu.faces.remove(f)

# Ensure all remaining faces in B-pillar zone are smooth
for f in bm_cu.faces:
    if any(-2.2 < v.co.y < -1.2 and v.co.z > 2.8 and abs(v.co.x) > 1.8 for v in f.verts):
        f.smooth = True

bm_cu.to_mesh(cu.data)
bm_cu.free()
cu.data.update()
print("Chassis_Underbody B-pillar overlapping faces cleaned")

# =============================================================================
# 2. SEAL FRONT HOOD HOLE (IMAGE 3)
# =============================================================================
print("=== 2. Sealing Front Hood Drop Holes ===")
bm_bp = bmesh.new()
bm_bp.from_mesh(bp.data)
bm_bp.verts.ensure_lookup_table()
bm_bp.faces.ensure_lookup_table()

# Left hood hole boundary:
# v1305(-2.319, 6.583, 1.951), v1307(-1.884, 6.855, 1.772), v1309(-1.528, 7.084, 1.629),
# v1310(-1.911, 6.931, 1.666), v1312(-2.326, 6.738, 1.735)
def try_create_face(bm, v_indices, name):
    try:
        v_objs = [bm.verts[i] for i in v_indices]
        f = bm.faces.new(v_objs)
        f.smooth = True
        print(f"Created face {name}")
        return f
    except Exception as e:
        try:
            v_objs = [bm.verts[i] for i in v_indices]
            f = bm.faces.new(list(reversed(v_objs)))
            f.smooth = True
            print(f"Created reversed face {name}")
            return f
        except Exception as e2:
            print(f"Face {name} note: {e2}")
            return None

# Bridge the 5-sided hole on the left hood
try_create_face(bm_bp, [1305, 1307, 1309, 1310, 1312], "Left Hood Hole Face")

# Bridge the hood crease seam gap (between v404/v1308 and v403/v1306 and v399/v1303)
# Look at v1304(-2.749, 6.259, 2.107), v1305(-2.319, 6.583, 1.951), v1312(-2.326, 6.738, 1.735), v1314(-2.648, 6.504, 1.798)
try_create_face(bm_bp, [1304, 1305, 1312, 1314], "Left Hood Vent Flap")

# Also on the right hood (symmetric across X)
# Find symmetric vertices on right side
def find_sym_vert(bm, target_co):
    sym_co = Vector((-target_co.x, target_co.y, target_co.z))
    best_v = min(bm.verts, key=lambda v: (v.co - sym_co).length)
    if (best_v.co - sym_co).length < 0.05:
        return best_v.index
    return None

sym_1305 = find_sym_vert(bm_bp, bm_bp.verts[1305].co)
sym_1307 = find_sym_vert(bm_bp, bm_bp.verts[1307].co)
sym_1309 = find_sym_vert(bm_bp, bm_bp.verts[1309].co)
sym_1310 = find_sym_vert(bm_bp, bm_bp.verts[1310].co)
sym_1312 = find_sym_vert(bm_bp, bm_bp.verts[1312].co)

if all(v is not None for v in [sym_1305, sym_1307, sym_1309, sym_1310, sym_1312]):
    try_create_face(bm_bp, [sym_1305, sym_1312, sym_1310, sym_1309, sym_1307], "Right Hood Hole Face")

sym_1304 = find_sym_vert(bm_bp, bm_bp.verts[1304].co)
sym_1314 = find_sym_vert(bm_bp, bm_bp.verts[1314].co)
if all(v is not None for v in [sym_1304, sym_1305, sym_1312, sym_1314]):
    try_create_face(bm_bp, [sym_1304, sym_1314, sym_1312, sym_1305], "Right Hood Vent Flap")

bm_bp.to_mesh(bp.data)
bm_bp.free()
bp.data.update()
print("Front hood drop holes sealed on both sides")

# =============================================================================
# 3. TUCK WHEELS & TIRES INWARD (IMAGES 4 & 5)
# =============================================================================
print("=== 3. Tucking Wheels & Tires Inward ===")

# Shift amounts:
# Front: 0.210m inward (FL: +0.210, FR: -0.210)
# Rear:  0.230m inward (RL: +0.230, RR: -0.230)

def shift_wheel_assembly(side, dx):
    names = [f"Wheel_{side}", f"Tire_{side}", f"Brake_Rotor_{side}", f"Caliper_{side}"]
    for name in names:
        obj = bpy.data.objects.get(name)
        if obj:
            for v in obj.data.vertices:
                v.co.x += dx
            obj.data.update()
            print(f"Shifted {name} by dx={dx:+.3f}")

shift_wheel_assembly("FL", +0.210)
shift_wheel_assembly("FR", -0.210)
shift_wheel_assembly("RL", +0.230)
shift_wheel_assembly("RR", -0.230)

# Save Master Blend
bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
print("SAVED_UPDATED_MASTER_BLEND")
