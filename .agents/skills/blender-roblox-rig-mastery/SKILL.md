---
name: blender-roblox-rig-mastery
description: Professional Blender 5.2 <-> Roblox Studio vehicle and character rigging, animation importer/exporter pipeline (powered by Cautioned rbx_anims v3.1.3), origin pivot alignment, FBX modular vehicle restructuring, and empirical mesh sanitization against HTTP -1 upload errors and visual shading defects.
---

# 🎨 Blender 5.2 <-> Roblox Studio Rigging, Vehicle & Asset Pipeline

This skill governs the production pipeline for importing, rigging, animating, sanitizing, and structuring 3D assets between **Blender 5.2.3 LTS** and **Roblox Studio**.

---

## 🛠️ 1. Installed Environment & Tooling

| Component | Path / ID | Status |
| :--- | :--- | :--- |
| **Blender Engine** | `C:\Program Files\Blender Foundation\Blender 5.2\blender.exe` | ✅ 5.2.3 LTS |
| **Blender Addon** | `rbx_anims` (Cautioned v3.1.3) in `%APPDATA%\Blender Foundation\Blender\5.2\scripts\addons\rbx_anims` | ✅ Installed & Enabled |
| **Roblox Companion Plugin** | `Blender Animations (Ultimate Edition)` (Asset `16708835782`) | Companion for Studio |
| **Automated Mesh Sanitizer** | `scripts/sanitize_roblox_mesh.py` | Built-in CLI tool |

---

## 🏎️ 2. Vehicle Architecture: Modular Rigid vs Skinned Bone Rig

When building or fixing vehicles in Roblox, choose between two primary architectures:

### A. Modular Rigid Setup (Standard for A-Chassis & Raycast Physics)
1. **Geometry & Pivots in Blender:**
   - **Chassis / Body:** Origin at `(0, 0, 0)` world center, exactly between the axles.
   - **Wheels (FL, FR, RL, RR):** 
     - Select wheel geometry (Rim + Tire + Rotor).
     - `Object > Set Origin > Origin to Geometry` or snap 3D cursor to center of cylinder and `Set Origin to 3D Cursor`.
     - Wheel spin axis MUST be centered along the local X or Y axis.
   - **Doors & Steering Wheel:** 
     - Set Origin to the physical hinge line (for doors) or steering column center (for steering wheel).
2. **Export to Roblox:**
   - FBX Export: Scale = `0.01` (or `1.0` with scene unit 0.01m).
   - Apply All Transforms (`Ctrl + A > All Transforms`).
   - In Roblox Studio: Import via **3D Importer** > Uncheck "Import as single mesh" > Check "แทรกโดยใช้ตำแหน่งฉาก" (Use Scene Position).
   - Result: Every wheel and body part snaps into its exact mathematical position with zero stud offset!

### B. Skinned Mesh / Bone Rig Setup (Advanced Modern Arcade & AAA Vehicle)
1. **Armature Hierarchy in Blender:**
   - `Root_Bone` (Chassis center)
     ├── `Wheel_FL` (Bone at FL wheel center)
     ├── `Wheel_FR` (Bone at FR wheel center)
     ├── `Wheel_RL` (Bone at RL wheel center)
     ├── `Wheel_RR` (Bone at RR wheel center)
     ├── `Steering_Bone` (Bone on steering column)
     ├── `Door_L` (Bone at driver door hinge)
     └── `Door_R` (Bone at passenger door hinge)
2. **Weight Painting & Parenting:**
   - Parent car mesh to Armature with `Empty Groups`.
   - Assign 100% vertex weights to corresponding bones (Rigid vertex groups).
3. **Studio Sync via Cautioned Plugin (`rbx_anims`):**
   - Export Rig Data from Roblox Studio via companion plugin.
   - Import Rig into Blender using `rbx_anims` panel.
   - Animate in Blender (suspension bounce, door opens, wheel turns).
   - Export Animation back to Roblox KeyframeSequence.

---

## 🚨 3. Roblox 3D Importer Error Forensics: HTTP StatusCode -1

When Roblox Studio's 3D Importer throws:
`PublishService AssetUpload failed. Info: Single part asset create call failed HTTP StatusCode: -1`
It is caused by one of three geometry violations rejected by Roblox's C++ asset packer:

### Failure Mode 1: Degenerate Faces (Area <= 1e-6)
* **Symptom**: Cloud upload rejects single parts like `Body_Glass` or `Body_Paint`.
* **Cause**: Polygons whose vertices have collapsed to a line or point (Area = 0.0).
* **Fix**:
```python
zero_faces = [f for f in bm.faces if f.calc_area() <= 1e-6]
bmesh.ops.delete(bm, geom=zero_faces, context='FACES_ONLY')
bmesh.ops.dissolve_degenerate(bm, dist=0.0001, edges=bm.edges)
```

### Failure Mode 2: Giant N-gons (> 16-32 Vertices)
* **Symptom**: Upload fails on capped cylinders like `Brake_Rotor_FL` or wheel hub discs.
* **Cause**: Blender's `holes_fill(sides=0)` creates 48- or 96-vertex N-gons. Roblox's Ear Clipping / Delaunay triangulation algorithm crashes on non-planar float vertices.
* **Fix**: Pre-triangulate all N-gons before FBX export:
```python
ngons = [f for f in bm.faces if len(f.verts) > 4]
if ngons:
    bmesh.ops.triangulate(bm, faces=ngons)
```

### Failure Mode 3: Pinched / Bow-tie Non-Manifold Vertices
* **Symptom**: Upload fails on complex underbody shells or merged panels (`Chassis_Underbody`).
* **Cause**: Two disjoint face clusters meet ONLY at a single vertex (hourglass / bow-tie junction) without sharing an edge. Roblox cannot compute tangent space and aborts asset creation.
* **Fix**: Separate pinched vertices per connected face component:
```python
for comp in components[1:]:
    comp_edges = list({e for f in comp for e in f.edges if v in e.verts})
    bmesh.utils.vert_separate(v, comp_edges)
```

---

## 👁️ 4. The "See-Through Mesh" (มองทะลุ) Trap & Anti-Marshmallow Rule

### Trap A: Inverted Face Normals
* **Blender Illusion**: Blender has "Backface Culling" turned OFF by default in Solid / Material Preview mode. Inside-out faces look solid in Blender.
* **Roblox Reality**: Roblox Studio enforces Backface Culling by default. Any face pointing inward is 100% INVISIBLE from outside! (e.g. Brake rotors invisible, wheel spokes look floating/broken).
* **Fix**: Always recalculate normals outside:
```python
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
```

### Trap B: The "Solidify" Blunder (Anti-Marshmallow Rule)
* ⚠️ **NEVER apply the `Solidify` modifier to complex car body panels to solve see-through issues!**
* **Why it fails**: Pushing thickness inward on thin, curved sheet metal creates overlapping inner-outer shells. Smooth shading averages normals between the two shells across thin edges, turning sleek sports cars into wrinkled, lumpy marshmallow pillows!
* **The Professional Roblox Solution**: 
  1. Keep body panels pristine, single-layered, and sharp.
  2. In Roblox Studio, set **`MeshPart.DoubleSided = true`**! Roblox's shader renders both sides natively with zero vertex overhead and zero geometry distortion.
  3. Include dark matte **Inner Wheel Well Tubs** (Fender Liners) behind wheels so looking through the spokes does not reveal the sky or opposite wheel well.

---

## 🎨 5. Master Automotive Material & Color Specification (สูตรสีและวัสดุระดับสตูดิโอ)

Roblox 3D Importer **ไม่สามารถนำเข้า Procedural Material จาก Blender ได้** (หากไม่มีการ Bake Texture) ทุก MeshPart จะกลายเป็นสีเทา `Plastic` (`RGB: 163, 162, 165`) ทั้งคัน

### 🌟 Official Automotive Surface Shading Matrix:

| หมวดหมู่ชิ้นส่วน | ชื่อ MeshPart ใน Blender | Material ใน Roblox | Color (RGB & Hex) | คุณลักษณะทางฟิสิกส์ & แสง |
| :--- | :--- | :--- | :--- | :--- |
| **ตัวถังหลัก (Body Paint)** | `Body_Paint` | `Enum.Material.SmoothPlastic` | `#9FA1AC`<br/>`(159, 161, 172)` *(Nardo Grey)*<br/>หรือ `#F8F8F8` *(Pearl White)* | ผิวเงาสะท้อนแสงชัดเจน (Specular Reflection) ดึงเงาแสงตกกระทบเสมือนแล็กเกอร์เคลือบเงา |
| **พาร์ตแอโร่/คาร์บอน** | `Aero_Trim`, `Spoiler`, `Rear_Diffuser_Aero`, `Chassis_Underbody`, `Headlights_Housing` | `Enum.Material.SmoothPlastic` | `#111111`<br/>`(17, 17, 17)` *(Carbon Black)* | ดำเข้มสนิท ดูดกลืนแสง ตัดกับสีตัวถังหลัก |
| **เบาะ & ภายใน** | `Interior` | `Enum.Material.Leather` | `#F8F8F8`<br/>`(248, 248, 248)` *(Tesla White)* | เนื้อลายหนังแท้พรีเมียม สไตล์ Cockpit รถหรู |
| **ยางรถยนต์ (Tires)** | `Tire_FL`, `Tire_FR`, `Tire_RL`, `Tire_RR` | `Enum.Material.Rubber` | `#232325`<br/>`(35, 35, 37)` *(Dark Charcoal)* | ผิวด้าน ไม่สะท้อนแสง มี Texture รอยยางธรรมชาติ |
| **ล้อแม็กซ์ (Rims)** | `Wheel_FL`, `Wheel_FR`, `Wheel_RL`, `Wheel_RR` | `Enum.Material.Metal` | `#A3A2A5`<br/>`(163, 162, 165)` *(Silver Chrome)*<br/>หรือ `#30343A` *(Gunmetal)* | ผิวโลหะสะท้อนแสง Anisotropic แบบอัลลอยด์แท้ |
| **จานเบรก (Rotors)** | `Brake_Rotor_FL`, `FR`, `RL`, `RR` | `Enum.Material.Metal` | `#B4B9BE`<br/>`(180, 185, 190)` *(Stainless Steel)* | ผิวโลหะขัดเงา สะท้อนเงาจานเบรกทะลุผ่านแม็กซ์ |
| **คาลิปเปอร์เบรก** | `Caliper_FL`, `FR`, `RL`, `RR` | `Enum.Material.SmoothPlastic` | `#DC1E1E`<br/>`(220, 30, 30)` *(Brembo Red)* | สีแดงสปอร์ตเงา สะดุดตาหลังก้านล้อแม็กซ์ |
| **กระจกห้องโดยสาร** | `Body_Glass` | `Enum.Material.Glass` | `#191C23`<br/>`(25, 28, 35)` *(Smoke Tint)* | `Transparency = 0.55` กรองแสงสปอร์ต มองเห็นภายใน |
| **ไฟหน้า (DRL Laser)** | `Headlights_Bulbs` | `Enum.Material.Neon` | `#B4D2E4`<br/>`(180, 210, 228)` *(Ice Blue)* | หลอด LED เปล่งแสงนีออนสะท้อนพื้นถนน |
| **ไฟท้าย (Taillight)** | `Taillights` | `Enum.Material.Neon` | `#FF3C3C`<br/>`(255, 60, 60)` *(Vibrant Red)* | แถบแสงนีออนสีแดงสด สว่างเด่นชัดยามค่ำคืน |

### 📜 Automated Lua Styling Script (ใช้ยิงผ่าน MCP หรือ Command Bar):
```lua
local function styleVehicle(carModel: Model)
    local palette = {
        Body_Paint = { Color = Color3.fromRGB(159, 161, 172), Material = Enum.Material.SmoothPlastic },
        Aero_Trim = { Color = Color3.fromRGB(17, 17, 17), Material = Enum.Material.SmoothPlastic },
        Rear_Diffuser_Aero = { Color = Color3.fromRGB(17, 17, 17), Material = Enum.Material.SmoothPlastic },
        Spoiler = { Color = Color3.fromRGB(17, 17, 17), Material = Enum.Material.SmoothPlastic },
        Chassis_Underbody = { Color = Color3.fromRGB(17, 17, 17), Material = Enum.Material.SmoothPlastic },
        Headlights_Housing = { Color = Color3.fromRGB(17, 17, 17), Material = Enum.Material.SmoothPlastic },
        Interior = { Color = Color3.fromRGB(248, 248, 248), Material = Enum.Material.Leather },
        Body_Glass = { Color = Color3.fromRGB(25, 28, 35), Material = Enum.Material.Glass, Transparency = 0.55 },
        Headlights_Bulbs = { Color = Color3.fromRGB(180, 210, 228), Material = Enum.Material.Neon },
        Taillights = { Color = Color3.fromRGB(255, 60, 60), Material = Enum.Material.Neon },
        License_Plate = { Color = Color3.fromRGB(240, 240, 240), Material = Enum.Material.SmoothPlastic },
    }
    for _, suffix in ipairs({"FL", "FR", "RL", "RR"}) do
        palette["Tire_" .. suffix] = { Color = Color3.fromRGB(35, 35, 37), Material = Enum.Material.Rubber }
        palette["Wheel_" .. suffix] = { Color = Color3.fromRGB(163, 162, 165), Material = Enum.Material.Metal }
        palette["Brake_Rotor_" .. suffix] = { Color = Color3.fromRGB(180, 185, 190), Material = Enum.Material.Metal }
        palette["Caliper_" .. suffix] = { Color = Color3.fromRGB(220, 30, 30), Material = Enum.Material.SmoothPlastic }
    end

    for _, part in ipairs(carModel:GetDescendants()) do
        if part:IsA("MeshPart") then
            part.DoubleSided = true
            local rule = palette[part.Name]
            if rule then
                part.Color = rule.Color
                part.Material = rule.Material
                if rule.Transparency ~= nil then
                    part.Transparency = rule.Transparency
                end
            end
        end
    end
end
```

---

## ⚡ 6. One-Command Headless Sanitizer

To sanitize any vehicle `.blend` and produce a guaranteed 100% Roblox-compliant `.fbx`:
```powershell
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b "<path_to_model.blend>" -P "<skill_path>\scripts\sanitize_roblox_mesh.py" -- "<path_to_model.blend>" "<output_clean.fbx>"
```
