---
project: HOKI TOWN
feature_id: VEH-01C
category: feature-deep-dive
system: universal-arcade-handling-engine
target_models: 
  - Workspace.TeslaRoadster
  - Future Multi-Vehicle Fleet
top_speed_kmh: 160-280
drift_mode: tap-to-drift-hybrid
status: implemented
priority: critical
last_audit: 2026-11-07
tags:
  - handling-physics
  - multi-vehicle-chassis
  - spacebar-sink
  - tap-to-drift
  - curb-assist
  - surface-smoke
  - verified-in-studio
---

# 🏎️ FEAT-01C: Universal Arcade Handling Chassis (ระบบฟิสิกส์และการขับขี่สากลรองรับรถหลายรุ่น)

> **สถานะ:** ✅ ติดตั้ง, ปลดล็อคชิ้นส่วนทั้งหมด (Anchored=0), ทดสอบ Play Mode ผ่านฉลุย 100% บน Roblox Studio  
> **ไฟล์สคริปต์หลัก:** 
> - กล่องฟิสิกส์: `Workspace.TeslaRoadster["A-Chassis Tune"]` (555 บรรทัด)
> - ตัวตั้งค่ารถสากล: `Workspace.TeslaRoadster["A-Chassis Tune"].Initialize` (1,052 บรรทัด)
> - คอร์คุมการขับขี่: `Workspace.TeslaRoadster["A-Chassis Tune"]["A-Chassis Interface"].Drive` (2,304 บรรทัด)

---

## 📌 1. ภาพรวมการพัฒนาหมวดที่ 1 (Handling & Physics Core)

ระบบการขับขี่หมวดที่ 1 ได้รับการยกเครื่องให้กลายเป็น **Universal Engine** ที่สมบูรณ์แบบทั้งในแง่ฟีลลิ่งการขับ (Arcade Drift สไตล์ CDT) ความเข้ากันได้กับระบบฟิสิกส์เดิม (CurbAssist ปีนฟุตบาทไทย) และที่สำคัญที่สุดคือ **การออกแบบให้พร้อมสเกลรองรับรถยนต์หลากหลายรุ่นในอนาคต (Multi-Vehicle Architecture)**

```mermaid
flowchart TD
    subgraph MultiVehicleFleet["🚗 รองรับรถทุกรุ่นในอนาคต"]
        CarA[Tesla Roadster\nSupercar 160-280 km/h]
        CarB[Pickup Truck / กระบะซิ่ง\nTorque 14,000 N]
        CarC[SUV / Offroad\nHigh Clearance & Grip]
        CarD[Sedan / รถบ้าน 4 ประตู\nBalanced Drift]
    end

    subgraph ArchitectureLayer["⚙️ สถาปัตยกรรม Universal Chassis"]
        TuneConfig[Config Block ภาษาไทยใน A-Chassis Tune\n(ปรับแค่จุดนี้จุดเดียวต่อรถ 1 รุ่น)]
        Initializer[Universal Initialize\n- สปริงและกันสะเทือน\n- Auto-Rig จุดปล่อยควันยางแนบพื้น 4 จุด]
        DriverCore[Universal Drive LocalScript\n- Spacebar Sink ไม่เด้งหลุดรถ\n- 2-Pedal Tap-to-Drift\n- CurbAssist ปีนฟุตบาทไทย\n- Mobile Ergonomic Touch UI]
    end

    MultiVehicleFleet --> TuneConfig
    TuneConfig --> Initializer
    TuneConfig --> DriverCore
```

---

## 🛠️ 2. ผลการตรวจสอบและแก้ปัญหา 6 ฟังก์ชันวิกฤต (Category 1 Achievements)

| ฟังก์ชัน | ปัญหาเดิม | แนวทางแก้ไขใหม่ (Production Grade) | สถานะใน Studio |
| :--- | :--- | :--- | :---: |
| **1. ปลดล็อกชิ้นส่วนรถ (Zero Anchored)** | ชิ้นส่วนตัวถังและประตูถูก Anchored ติดพื้น 74 ชิ้น ทำให้รถขยับไม่ได้ | ปลดล็อก `Anchored = false` ครบ 100% ทั้ง 74 ชิ้น ตัวรถขยับตามระบบฟิสิกส์อิสระ | ✅ Verified |
| **2. ดักปุ่ม Spacebar เบรกมือ (Spacebar Sink)** | กด Spacebar แล้วตัวละครส่งสัญญาณ Jump เด้งหลุดออกจากเบาะทันที | ใช้ `ContextActionService:BindActionAtPriority("HokiSpacebarHandbrakeSink", ..., High + 3000, Space)` พร้อมสั่ง `SetStateEnabled(Jumping, false)` ขณะนั่งขับ | ✅ Verified |
| **3. ระบบ Tap-to-Drift 2 แป้นเหยียบ** | ไม่มีโหมดดริฟต์ การเลี้ยวทำได้แค่ชะลอความเร็ว | แตะเบรกสั้น ๆ ($< 0.35$s) ขณะเข้าโค้ง จะล็อกเบรกล้อหลังตามค่า `TapDriftRearBrake` พร้อมเลี้ยงคันเร่ง 45% ให้สไลด์โค้งเนียนตา | ✅ Verified |
| **4. ควันยางแนบพื้นผิวสากล (Universal Smoke Rig)** | ควันยางเดิมหมุนเหวี่ยงตามล้อ หรือไม่มีจุดปล่อยควัน | สคริปต์คำนวณพิกัด Local Offset ของล้อทั้ง 4 ข้างเทียบกับ `DriveSeat` อัตโนมัติ ปล่อยควันหนานุ่มเรี่ยพื้นถนน | ✅ Verified |
| **5. ระบบข้ามฟุตบาทไทย (CurbAssist)** | รถสะดุดสันปูนทางเท้าความสูง 1.8–2.0 studs | ติดตั้ง `VectorForce` + Raycast วัดระยะขอบปูนล่วงหน้า ยกรถข้ามอย่างนุ่มนวล ไม่สะบัดคว่ำ | ✅ Verified |
| **6. คอนโทรลหน้าจอมือถือ (Mobile Touch UI)** | ปุ่มบังคับซ้อนทับ หรือกดปุ่มลงรถผิด | แยกแป้นคันเร่ง-เบรก-เลี้ยวชัดเจน และย้ายปุ่ม `[🚪 ลงจากรถ]` ไปไว้มุมบนซ้ายอย่างปลอดภัย | ✅ Verified |

---

## 🏎️ 3. มาตรฐานการเพิ่มรถรุ่นใหม่ (Multi-Vehicle Tuning Guide)

เมื่อทีมพัฒนาต้องการเพิ่มรถรุ่นใหม่ (เช่น รถกระบะ, มอเตอร์ไซค์, รถพยาบาล หรือ SUV):
**ไม่ต้องแตะต้องหรือแก้ไขโค้ด 2,300 บรรทัดใน `Drive` เลยแม้แต่บรรทัดเดียว!**  
เพียงแค่คัดลอกโฟลเดอร์ `A-Chassis Tune` มาใส่ในรถคันใหม่ แล้วปรับตัวเลขในตาราง `Config` ด้านบนสุด:

```luau
local Config = {
	-- ความเร็วและอัตราเร่ง
	TopSpeed         = 160,       -- ความเร็วสูงสุด (km/h)
	FinalDrive       = 3.6,       -- อัตราทดเฟืองท้าย
	Acceleration     = 5.2,       -- ความจัดของอัตราเร่ง
	ThrottleResponse = 0.25,

	-- พวงมาลัย
	MaxSteerAngle    = 35,        -- องศาเลี้ยว
	SteerSpeed       = 1.1,
	ReturnSpeed      = 1.6,

	-- ฟิสิกส์ข้ามขอบฟุตบาทไทย (CurbAssist)
	CurbAssistEnabled              = true,
	CurbAssistMaxStep              = 2.0,   -- studs
	CurbAssistAcceleration         = 130,

	-- 🏎️ ระบบการขับขี่สไตล์ ARCADE & DRIFT (ปรับแต่งเฉพาะแต่ละรุ่น)
	TapDriftEnabled                = true,      -- เปิด/ปิดดริฟต์
	TapDriftTapDuration            = 0.35,      -- เวลาแตะเบรกที่นับเป็นการดริฟต์
	TapDriftMinSpeed               = 16,        -- ความเร็วขั้นต่ำที่จะเริ่มดริฟต์ (studs/s)
	TapDriftRearBrake              = 18000,     -- แรงดึงเบรกล้อหลัง (Supercar: 22000, กระบะ: 14000)
	TapDriftPowerRatio             = 0.45,      -- กำลังส่งเลี้ยงรอบเครื่องขณะสไลด์ (45%)
	TapDriftMaxDuration            = 1.25,      -- เวลาดริฟต์สูงสุดก่อนคืนกริป 100%
	TireSmokeEnabled               = true,
	TireSmokeDriftRate             = 75,
	TireSmokeBrakeRate             = 40,
}
```

---

## 🔗 เอกสารที่เกี่ยวข้องใน Vault
- [[FEAT_01_Vehicle_Systems_AChassis|🚗 FEAT_01: สถาปัตยกรรมระบบรถดั้งเดิม]]
- [[FEAT_01B_CDT_Arcade_Vehicle_Overhaul|🏎️ FEAT_01B: การยกเครื่องสไตล์ Car Dealership Tycoon]]
- [[VEHICLE_MASTER_DEVELOPMENT_MANUAL|📘 คู่มือการสร้างและจูนรถคันใหม่]]
- [[ARCH_02_Target_Refactoring_Roadmap|🚀 แผนงาน Roadmap 4 เฟสสู่โปรดักชัน]]
