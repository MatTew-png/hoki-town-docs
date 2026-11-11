---
title: Tesla Roadster Raycast Base Model 2026
type: 3d_asset_specification
status: verified_base
created: 2026-11-09
tags:
  - vehicle
  - 3d_model
  - raycast_chassis
  - blender
  - roblox
---

# 🏎️ Tesla Roadster Raycast — Official Base Model 2026

## 📌 สถานะโมเดลหลัก (Official Base Milestone)
โมเดลนี้ได้รับการรับรอง (Consecrated) เป็น **Official Base Model** ใหม่สำหรับระบบ Raycast Vehicle ของโปรเจกต์ HOKI TOWN โดยรวมการแก้ไขและจัดโครงสร้างสมบูรณ์แบบทั้ง 26 ชิ้นส่วนแยก (Modular Objects) พร้อมรองรับ Roblox Studio 100%

### 📁 ที่อยู่ไฟล์หลัก (File Registry):
* **Master Base Blend:** `C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Base_New.blend`
* **Master Base FBX:** `C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Base_New.fbx`
* **Vault Archive Blend:** `assets/models/tesla_roadster/Tesla_Roadster_Raycast_Base_2026.blend`
* **Vault Archive FBX:** `assets/models/tesla_roadster/Tesla_Roadster_Raycast_Base_2026.fbx`

---

## 🛠️ จุดแก้ไขสมบูรณ์ที่บันทึกใน Base Model นี้:
1. **ช่องดักลมข้างประตู (Side Air Scoops & Aero Trim):**
   - กู้คืนสันเหลี่ยมคมคู่และขอบคิ้วสีดำ (`Aero_Trim` Faces 4, 5, 61, 62) สวยงามรับลม 1:1 กับต้นฉบับ
2. **ดิฟฟิวเซอร์ท้าย (Rear Diffuser Underside):**
   - ลบแผ่นครีบส่วนเกินใต้ท้องรถ (Face 2620) ท้องรถเรียบเนียน ไร้ชิ้นส่วนแลบ
3. **ระบบไฟหน้า (Headlights Unblocked & Dual Neon Blades):**
   - ลบ 4 โพลีกอนส่วนเกินใน `Body_Paint` (Faces 1410-1413) ที่เคยขึงบังหน้าไฟออก 100%
   - กู้คืนเส้นไฟ DRL 2 ขีดคู่แท้ 132 Polygons เข้าสู่ `Headlights_Bulbs` เรืองแสง Neon สีขาวบริสุทธิ์
   - แยกเบ้าโคมดำ 68 Polygons สู่ `Headlights_Housing` ให้มิติตัดกับเส้นไฟ
   - ส่งคืนคอนโซลห้องโดยสาร 28 Polygons เข้าสู่ `Interior`
4. **Roblox Studio 100% Native Compatibility:**
   - Baked sRGB Vertex Colors (`Color` layer) ครบทั้ง 26 ชิ้นส่วน
   - ระบบ PBR Diffuse Color Palette พร้อมเชื่อมต่อกับ Raycast Physics Engine

---

## 🧩 รายการ 26 ชิ้นส่วนโมดูลาร์ (26 Modular Objects List):
| Object Name | Faces | Material | Vertex Color |
| :--- | :--- | :--- | :--- |
| `Body_Paint` | 1,410 | `Mat_Zone1_Primary_White` | sRGB Baked |
| `Headlights_Bulbs` | 132 | `Mat_DRL_Neon_Cyber_White` | Pure White (1, 1, 1) |
| `Headlights_Housing` | 68 | `Mat_Headlight_Housing_Dark` | Dark Grey (0.02, 0.02, 0.02) |
| `Taillights` | 156 | `Plane0071Mtl` | Red Neon (1, 0.35, 0.35) |
| `Body_Glass` | 122 | `Mat_Glass_Tinted` | Tinted Glass |
| `Aero_Trim` | 164 | `Mat_Aero_Forged_Carbon` | Forged Carbon |
| `Rear_Diffuser_Aero` | 124 | `Mat_Aero_Forged_Carbon` | Forged Carbon |
| `Spoiler` | 252 | `Mat_Zone1_Primary_White` | Primary Paint |
| `Chassis_Underbody` | 2,552 | `Mat_Chassis_Underbody_Trim` | Dark Trim |
| `Interior` | 1,564 | `Mat_Interior_Dark_Cabin` | Cabin Leather / Plastic |
| `License_Plate` | 12 | `Plate1Mtl` | Dark Metal |
| `Wheel_FL / FR / RL / RR` | 696 each | `Mat_Rims_Satin_Titanium` | Satin Titanium |
| `Tire_FL / FR / RL / RR` | 144 each | `Mat_Tires_Track_Rubber` | Track Rubber |
| `Brake_Rotor_FL / FR / RL / RR`| 96 each | `Mat_Brake_Rotor_Steel` | Steel / Hat Dark |
| `Caliper_FL / FR / RL / RR` | 26 each | `Mat_Calipers_Brembo_Red` | Brembo Red |
