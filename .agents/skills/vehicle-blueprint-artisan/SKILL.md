---
name: vehicle-blueprint-artisan
description: >-
  Standardized 3-Prompt automotive & motorcycle blueprint generation pipeline for 3D modeling
  (Blender) and game engine implementation (Roblox Studio). Transforms any reference vehicle photo
  into the 3 core production prompts, then ingests the generated sheets for downstream engineering.
---

# 🚗 Vehicle Blueprint Artisan: 3-Prompt Handshake Protocol

This skill governs the end-to-end workflow between the User, an external Image Generation AI, and Antigravity/OpenCode for vehicle modeling and Roblox game integration.

---

## 🤝 The Handshake Protocol (ขั้นตอนการทำงาน)

```text
[Step 1: User]       ➡️ อัปโหลดภาพถ่ายรถจริง (Car / Motorcycle / Scooter / Supercar)
[Step 2: Agent]      ➡️ วิเคราะห์สเปก แล้วส่งมอบ "3 Master Prompts" ทันที (พร้อมก๊อปปี้ไปเจนรูป)
[Step 3: User]       ➡️ นำ Prompt ไปเจนรูปใน Image AI (Midjourney/Flux/etc.) แล้วแนบ 3 ภาพกลับมา
[Step 4: Agent/Code] ➡️ รับภาพทั้ง 3 ใบเข้าคลัง แล้วนำไปขึ้นโครง 3D / สั่ง OpenCode เขียนระบบรถใน Roblox
```

---

## 📋 The 3 Core Master Prompts (ชุด 3 ใบมาตรฐาน สำหรับ Roblox Game Assets)

เมื่อผู้ใช้ส่งภาพรถเข้ามา Agent ต้องส่งมอบ Master Prompts ทั้ง 3 ชุดนี้ โดยกรอกตัวแปรจากรูปถ่ายให้ครบ 100% (ปรับแต่งให้ตรงกับข้อจำกัด Game Engine / Roblox 6,000–12,000 Tris Budget):

### 1️⃣ Prompt 1: Exterior CAD 4-View (Clean Outer Shell Blueprint)
> สำหรับดราฟต์เส้นขึ้นโครงตัวถังรถใน Blender (ตัดเส้นรกภายในห้องโดยสาร เน้นเส้นสันและสัดส่วนภายนอกที่ชัดเจน)

```text
Pure black and white technical vector line art blueprint reference sheet of the [Vehicle Category and Model], game asset production CAD database style, based on the reference photo.

STRICT TECHNICAL DRAWING CONSTRAINTS:
- Pure black line art on pure clean white background (#FFFFFF).
- ABSOLUTELY NO COLORS, NO GRADIENTS, NO SHADING, NO TINT, NO 3D RENDER.
- Razor-sharp 1px black technical drafting contour lines showing all exterior body seams, door shut lines, glass boundaries, and aerodynamic edges.
- CLEAN EXTERIOR SHELL FOCUS: Absolutely NO interior seats, steering wheels, or pedal clutter showing through the glass (clean closed canopy silhouette).
- True orthographic projection only (parallel projection, zero perspective distortion, zero vanishing point).
- Perfectly aligned 4-view elevation layout:
  1. Top view (centered top-to-bottom)
  2. Side profile view (horizontal 90-degree elevation)
  3. Front elevation view
  4. Rear elevation view
- All 4 views must share identical scale, wheelbase, and wheel proportions with horizontal dotted datum alignment guide lines.
- Clean engineering dimension lines with millimeters (mm) indicators.

NEGATIVE PROMPT:
interior seats, steering wheel, interior clutter, color, red paint, shading, shadows, 3d render, photorealistic, ambient occlusion, reflections, gradients, greyscale fill, cartoon, perspective view, 3/4 angle, low resolution, blurry lines, sketched pencil.
```

---

### 2️⃣ Prompt 2: Game-Ready Wheel, Rim & Caliper Dedicated Sheet
> สำหรับปั้นล้อแม็กด้วย Radial Array, ดัดความเว้าก้านล้อ (Dish Depth) และก้อนปั๊มเบรก Low-poly (ตัดดอกยาง 3D และรูจานเบรกออกเพื่อประหยัด Polycount ใน Roblox)

```text
Pure black and white technical CAD blueprint drafting sheet dedicated exclusively to the game-ready wheel, rim, and brake assembly of the [Vehicle Model], clean low-poly automotive asset drafting style, based on the reference photo.

STRICT TECHNICAL SPECIFICATIONS:
- Pure black 1px technical vector line art on pure clean white background (#FFFFFF).
- ABSOLUTELY NO COLOR, NO SHADING, NO GRADIENTS, NO GREYSCALE, NO 3D RENDER.
- True orthographic mechanical drafting layout containing 3 clean game-asset views:
  1. Direct Face View (Front-Facing Orthographic, 90-degree straight-on): Symmetrical wheel rim spoke pattern (designed for 360-degree Blender Radial Array), clean center hub cap with lug nuts, solid flat circular brake rotor silhouette, and clean monobloc brake caliper profile mounted at the 3 o'clock position.
  2. Spoke Concavity & Dish Profile View: Clean side profile showing spoke concavity depth from outer rim lip down to center hub drop, rim lip width, and clean smooth tire sidewall profile.
  3. Low-Poly Brake Caliper & Solid Rotor Isolated View: Clean geometric caliper block with mounting tab silhouette, paired with solid flat disc rotor (NO cross-drilled holes, optimized for texture mapping).
- SMOOTH GAME TIRE PROFILE: Clean outer tire boundary without physical 3D tread cuts or grooves (texture-ready game mesh).
- Millimeter dimension lines indicating wheel diameter and rim width.
- Border technical rulers and CAD title block in the corner.

NEGATIVE PROMPT:
tire tread grooves, tire sipes, cross-drilled rotor holes, cutaway cross-section hatching, inner barrel bead seat, internal mechanical complexity, color, shading, shadows, 3d render, glossy reflections, grey fill, realistic lighting, perspective, 3/4 angle, low resolution, blurry lines, sketch, car body.
```

---

### 3️⃣ Prompt 3: Modular Color ID & 6-Color Zone Specification Map
> แผนผังพิกัด 6 โซนสีแบบ Flat Solid Color-Block จัดจ้าน คมกริบ สำหรับแยก 6 MeshParts อิสระใน Roblox Studio

```text
Professional automotive Material ID and Color Zone Mapping technical diagram sheet of the [Vehicle Model], game development asset production style, based on the reference photo.

STRICT TECHNICAL LAYOUT:
- Studio orthographic 3-view display (Top view, Side profile view, Front-Rear elevation).
- Flat clean vector CAD linework with razor-sharp solid color fills on a neutral light grey drafting background (#EBEBEB).
- 6 DISCRETE MODULAR MESH ZONES (Solid flat color blocks representing separate Roblox MeshParts):
  1. Zone 1 (Main Body Panels - MeshPart 'Body_Main'): Solid Flat White (#FFFFFF).
  2. Zone 2 (Aero Splitter, Diffuser, Skirts - MeshPart 'Aero_Trim'): High-vis Safety Orange (#FF6600).
  3. Zone 3 (Alloy Wheel Rims - MeshPart 'Wheels_Rims'): Bright Lime Green (#00FF66).
  4. Zone 4 (Brake Calipers - MeshPart 'Brake_Calipers'): Hot Magenta Pink (#FF007F).
  5. Zone 5 (DRL Headlight Optics - MeshPart 'Lights_DRL'): Glowing Electric Cyan Blue (#00E5FF).
  6. Zone 6 (Canopy & Windshield Glass - MeshPart 'Canopy_Glass'): Solid Dark Slate Navy (#1C2833).

GRAPHICAL ANNOTATIONS & LEGEND:
- Clean color swatch legend boxes at the bottom-right corner clearly labeled:
  "ZONE 1: BODY_MAIN", "ZONE 2: AERO_TRIM", "ZONE 3: WHEELS_RIMS", "ZONE 4: BRAKE_CALIPERS", "ZONE 5: LIGHTS_DRL", "ZONE 6: CANOPY_GLASS".
- Razor-sharp division borders between colors (zero color bleeding, zero gradients, zero feathered edges).
- Clean leader lines with pointer dots indicating material separation boundaries.
- Technical typography, title block "[VEHICLE MODEL] - MODULAR COLOR ID SPECIFICATION", and millimeter border grid.

NEGATIVE PROMPT:
realistic paint, metallic flakes, complex reflections, dark shadows, ambient occlusion, photographic lighting, dirty colors, color bleeding, gradients, blurry borders, perspective angle, sketch, cartoon.
```

---

## 🏗️ Downstream Execution (เมื่อได้รับ 3 ภาพกลับมา)

เมื่อผู้ใช้อัปโหลด 3 ภาพผลลัพธ์กลับเข้ามาในแชท:
1. **ตรวจสอบความสมบูรณ์ (Pre-flight Audit):** เช็คว่าทั้ง 3 ใบสเกลล้อ/ฐานล้อตรงกัน และโซนสีตัดขอบชัดเจน
2. **สร้าง Work Order สำหรับ 3D / Roblox:** กำหนดชื่อ 6 MeshParts ตามมาตรฐาน:
   * `Body_Main`
   * `Aero_Trim`
   * `Wheels_Rims`
   * `Brake_Calipers`
   * `Lights_DRL`
   * `Canopy_Glass`
3. **ส่งต่อให้ OpenCode / สคริปต์เอนจิน:** ดำเนินการเขียนระบบขับเคลื่อน (DriveSeat) และระบบ Paint Shop UI ทันที
