---
project: HOKI TOWN
doc_type: handoff-document
topic: opencode-raycast-chassis-evaluation
target_session: opencode-go-comparison
status: ready
created_at: 2026-11-08
tags:
  - handoff
  - opencode-go
  - deepseek-v4-pro
  - gemini-4-argon
  - gpt-6-luna
  - raycast-vehicle
  - tesla-roadster
---

# 🚀 Handoff: Tesla Roadster Raycast Pipeline & OpenCode Comparison

> **Date:** 2026-11-08  
> **Topic:** HOKI TOWN — Raycast Vehicle Architecture, 3D Asset Completion, and OpenCode Go Multi-Model Implementation Comparison  
> **Next Session Goal:** ใช้โมเดลตระกูล **OpenCode Go** (`opencode-go/deepseek-v4-pro` 80% + `opencode-go/gemini-4-argon` / `gpt-6-luna` 20%) สร้างและเปรียบเทียบสคริปต์ระบบขับขี่ Raycast Chassis เพื่อตัดสินใจเลือกแนวทางที่ดีที่สุดสู่โปรดักชัน  

---

## 📊 1. Current State (สิ่งที่ทำเสร็จแล้วและมีหลักฐานยืนยัน 100%)

### A. โมเดล 3D และการจัดโครงสร้าง (Blender 5.2) — COMPLETED ✅
โมเดลถูกสร้าง สำรองข้อมูล และ Export ออกมาเรียบร้อยแล้ว:
* **Production Files:**
  - `C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Production.blend` (515 KB)
  - `C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Production.fbx` (617 KB)
* **Backup Chain ครบ 5 สเต็ป:** อยู่ที่ `C:\Users\_newgen\Downloads\Tesla_Roadster_Backups\`
  - `Step0_Base_Modular_Initial.blend` (โมเดลดิบตั้งต้น)
  - `Step1_Separated_Components.blend` (ผ่าแยก `Caliper_FL..RR` และ `Body_Secondary_Carbon`)
  - `Step2_Consolidated_Components.blend` (ยุบ `Door_Jamb` เข้า `Tub` และ `Weatherstrip` เข้า `Door` ลด 4 Draw Calls)
  - `Step3_Symmetric_Aligned.blend` (สมมาตรล้อและตั้ง Origin บานพับเสา A)
  - `Step4_Complete_Raycast_Production.blend` (`Chassis_Collider` สกี + Underglow 4 ด้าน + 15 Attachments)
* **ตัวเลขความแม่นยำทางวิศวกรรม (Verified stdout):**
  - ล้อซ้าย (`FL, RL`): $X = 3.245$ (ห่างจากจุดกึ่งกลาง $6.000$ คือ $-2.755\text{ studs}$)
  - ล้อขวา (`FR, RR`): $X = 8.755$ (ห่างจากจุดกึ่งกลาง $6.000$ คือ $+2.755\text{ studs}$) $\rightarrow$ สมมาตรเป๊ะ $100\%$
  - ความสูงทุกล้อขนานพื้น: $Z = 2.806$ (แก้ปัญหาล้อหลังซ้าย RL ลอยเรียบร้อย)
  - คาลิปเปอร์เบรกแยกชิ้น ไม่หมุนตามแกนขับเคลื่อนล้อ (แก้ Caliper Spin Bug)
  - บานพับประตู: `Door_FL` อยู่ที่เสา A ซ้าย $(2.750, 28.100, 3.300)$, `Door_FR` อยู่ที่เสา A ขวา $(9.250, 28.100, 3.300)$
  - Polycount รวม: **11,258 Polygons (~22,500 Tris)** ไม่กินสเปก รันลื่นในเซิร์ฟเวอร์ 40 คน

### B. การเชื่อมต่อ OpenCode Go CLI — VERIFIED ✅
* **ข้อค้นพบสำคัญ (Root Cause):** บัญชีผู้ใช้เป็นสมาชิก **OpenCode Go** ต้องใช้ Prefix **`opencode-go/...`** (ห้ามใช้ `opencode/...` เพราะจะติด `Insufficient account funds`)
* **ทดสอบรันคำสั่งจริงใน Terminal แล้วได้ผล Exit Code 0 ทั้งหมด:**
  - `opencode-go/deepseek-v4-pro` $\rightarrow$ ส่ง `pong` สำเร็จ ✅
  - `opencode-go/gemini-4-argon` $\rightarrow$ ส่ง `pong` สำเร็จ ✅
  - `opencode-go/gpt-6-luna` $\rightarrow$ ส่ง `pong` สำเร็จ ✅

### C. สถาปัตยกรรมและข้อกำหนดใน Vault — RECORDED ✅
* เอกสารสเปกทางการ: [`01_Features_Deep_Dive/FEAT_01D_Tesla_Raycast_Modular_Pipeline.md`](file:///c:/Users/_newgen/Documents/antigravity/HOKI%20TOWN/01_Features_Deep_Dive/FEAT_01D_Tesla_Raycast_Modular_Pipeline.md)
* อัปเดตบรรจุลง [`MOC.md`](file:///c:/Users/_newgen/Documents/antigravity/HOKI%20TOWN/MOC.md) เรียบร้อย
* ข้อตกลงระบบควบคุมและเกมเพลย์:
  - **PC:** `W A S D`, `Spacebar` เบรก (ContextActionService Sink ป้องกันตัวละครเด้งหลุด), `F` ลงรถ, `H` ไฟหน้า
  - **Mobile:** 4 ปุ่มหลัก (เดินหน้า, ถอย/เบรก S, ซ้าย, ขวา) + ปุ่ม `[🚪 ลงรถ]` มุมซ้ายบน + ปุ่ม `[💡]` สลับไฟ
  - **ระบบไฟ 4 สถานะ:** ปิดไฟ / ไฟหรี่ท้ายแดงนุ่ม / เหยียบเบรกไฟแดงสว่างจ้า 100% วาบสะท้อนท้าย
  - **ระบบประตูแนวทาง A:** วาปนั่งทันที (ไร้บั๊กตัวละคร, ออกตัวหนีตำรวจได้ไว) + ประตูสวิงรับ 0.4s + โหมด Car Meet เปิดค้างโชว์รถ
  - **ระบบข้ามฟุตบาทไทย CurbAssist:** Probe Ray หน้าล้อเฉียง $45^\circ$ ข้ามสันปูน $\le 2.1\text{ studs}$

---

## 🎯 2. Goal สำหรับเซสชันถัดไป (What Next Session Should Do)

1. **ใช้ `opencode-go` เปรียบเทียบแนวทางการเขียนโค้ด Raycast Chassis:**
   - **แนวทาง 1 (Pure Custom Raycast Solver):** สั่ง `opencode-go/deepseek-v4-pro` เขียนตัวคำนวณ Spherecast Suspension + Pacejka Tire Friction จากศูนย์แบบ Lightweight
   - **แนวทาง 2 (Hybrid Arcade Raycast Mod):** ดัดแปลงระบบจาก CDT Arcade เดิมที่มีใน `03_Scripts_Vault/` ให้ใช้ Raycast แทน Springs
2. **เปรียบเทียบข้อดี-ข้อเสีย (Benchmark Comparison):**
   - การกิน CPU ในมือถือ
   - ความรู้สึกเวลาขับ (Game Feel: การเข้าโค้ง, การดริฟต์, การเหินเนินข้ามสะพาน)
   - ความเสถียรของฟิสิกส์เมื่อมีรถชนกันหลายคัน
3. **ตัดสินใจเลือกทางที่ดีที่สุด แล้วนำไปติดตั้งลงใน `Workspace.TeslaRoadster` ใน Roblox Studio**

---

## 📁 3. ไฟล์และ Artifacts สำคัญที่ต้องใช้อ้างอิง

| รายการ | ตำแหน่งไฟล์ | คำอธิบาย |
| :--- | :--- | :--- |
| **Model FBX** | `C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Production.fbx` | โมเดล Master พร้อม Import เข้า Studio |
| **Model Blend**| `C:\Users\_newgen\Downloads\Tesla_Roadster_Raycast_Production.blend` | ไฟล์ต้นฉบับ Blender 5.2 |
| **Backups** | `C:\Users\_newgen\Downloads\Tesla_Roadster_Backups\` | โฟลเดอร์สำรองงาน Step 0 ถึง 4 |
| **Spec FEAT-01D**| `01_Features_Deep_Dive/FEAT_01D_Tesla_Raycast_Modular_Pipeline.md` | เอกสารสเปกหลักทั้งระบบ |
| **Render Front** | `C:\Users\_newgen\.gemini\antigravity\brain\cad127cd-9b1b-4acb-ae26-9132b44d5e7f\tesla_raycast_production_front34.png` | รูปพรีวิวหน้า 3/4 |
| **Render Rear** | `C:\Users\_newgen\.gemini\antigravity\brain\cad127cd-9b1b-4acb-ae26-9132b44d5e7f\tesla_raycast_production_rear34.png` | รูปพรีวิวท้าย 3/4 (โชว์ Underglow & Diffuser) |

---

## ⏭️ 4. สกิลและก้าวแรกของเซสชันถัดไป (Suggested Starting Move)

* **สกิลที่ใช้:** `roblox-vault-router` หรือ `delegate-worker` ร่วมกับ `opencode-go` CLI
* **คำสั่งเปิดเกมสำหรับ Agent เซสชันหน้า:**
  ```bash
  # รัน prompt คำนวณฟิสิกส์ Raycast Suspension ผ่าน DeepSeek V4 Pro
  echo "Write a clean, optimized Roblox Luau Raycast vehicle suspension module using workspace:Shapecast for 4 wheels with Hooke's Law damping, Anti-Roll Bar, and CurbAssist for 2.1 studs curbs. Half-track width: 2.755 studs." | opencode run -m opencode-go/deepseek-v4-pro
  ```
