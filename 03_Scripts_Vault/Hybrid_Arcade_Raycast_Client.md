---
project: HOKI TOWN
script_name: Hybrid_Arcade_Raycast_Client
script_type: LocalScript
datamodel_location: 'Workspace.TeslaRoadster["A-Chassis Tune"]["A-Chassis Interface"].Drive'
lines_of_code: 1419
verified_status: passed
features:
  - 4-wheel-spherecast-suspension
  - thai-curbassist-45deg
  - caliper-spin-prevention
  - zero-alloc-renderstepped
  - tap-to-drift-asphalt
  - spacebar-handbrake-sink
  - 6-speed-audio-synthesizer
  - warmtheq-tire-scrub
  - mobile-touch-hud-6-buttons
  - headlights-brakelights-neon-sync
tags:
  - client-script
  - hybrid-raycast
  - cdt-arcade
  - curbassist
  - production-code
---

# 🚗 Hybrid_Arcade_Raycast_Client (Production LocalScript)

> **ตำแหน่งใน DataModel:** `Workspace.TeslaRoadster["A-Chassis Tune"]["A-Chassis Interface"].Drive`  
> **ไฟล์ต้นทาง (Rojo SSOT):** [`src/TeslaRoadster/A-Chassis Tune/A-Chassis Interface/Drive.client.luau`](file:///c:/Users/_newgen/Documents/antigravity/HOKI%20TOWN/src/TeslaRoadster/A-Chassis%20Tune/A-Chassis%20Interface/Drive.client.luau)  
> **โมเดลเป้าหมาย:** `Workspace.TeslaRoadster`  
> **สถานะ:** ✅ ติดตั้งผ่าน Rojo และผ่านการทดสอบ Play Mode Unit Test เรียบร้อย (Exit Code 0)  

---

## 🌟 ฟีเจอร์หลัก (Key Features)

1. **4-Wheel Spherecast / Raycast Suspension:**
   - ใช้ `workspace:Spherecast` สแกนพื้นผิวถนนแบบไดนามิก รองรับการเอียงตามระนาบพื้นผิว (Ground Normal Alignment)
   - ยกเลิกข้อจำกัดของ SpringConstraints และ CylindricalConstraints ป้องกันรถเหินปลิวหรือล้อหลุดออกนอกแมพ
2. **ระบบข้ามฟุตบาทไทย (Thai CurbAssist):**
   - Probe Ray หน้า $45^\circ$ ระยะ 4.2 studs ตรวจจับขอบปูนความสูง $\le 2.1\text{ studs}$
   - สั่งยกแรง `VectorForce` ที่เพลาหน้า $82.0\text{ studs/s}^2$ ยกรถข้ามฟุตบาทได้อย่างนุ่มนวล
3. **การแยก Caliper และ Wheel CFrame:**
   - Wheel Meshes รับ Steer + Suspension + Pitch Spin
   - Caliper Meshes รับ Steer + Suspension อย่างเดียว **ไม่หมุนตามแกนขับเคลื่อนล้อ** (แก้ปัญหา Caliper Spin Bug 100%)
4. **Zero-Allocation RenderStepped Loop:**
   - ทุกตัวแปรและตารางถูกแคชไว้ล่วงหน้า (Pre-allocated) ปราศจากการสร้าง Garbage Collection ในทุกเฟรม รันลื่น 60 FPS บนมือถือสเปกเริ่มต้น
5. **ระบบการควบคุม (Controls):**
   - **PC:** `W A S D` ขับเคลื่อน, `Spacebar` เบรกมือ/ดริฟต์ (ดักด้วย `ContextActionService` Sink ไม่ให้ตัวละครกระเด้งหลุด), `F` ลงจากรถ, `H` สลับไฟหน้ารถ
   - **Mobile Touch HUD:** 6 ปุ่มกดสัมผัส (เลี้ยวซ้าย, เลี้ยวขวา, คันเร่ง, เบรก/ดริฟต์, เบรกมือ, สลับไฟ, ลงรถ)
6. **ระบบแสงและเสียงสมจริง:**
   - สลับไฟหน้ารถ [H] และไฟหรี่ท้าย
   - เหยียบเบรกไฟท้ายสว่างจ้าสีแดงสด (Intense Red Neon) พร้อมแสงสะท้อนท้ายรถ
   - เสียงเครื่องยนต์สังเคราะห์ 6 สปีด + เสียงยางกรีดถนน WarmthEQ สไตล์ CDT
