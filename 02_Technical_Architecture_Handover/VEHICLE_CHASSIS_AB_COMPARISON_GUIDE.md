---
title: "Vehicle Chassis A/B Comparison Guide: A-Chassis vs Raycast Chassis"
date: 2026-11-07
tags:
  - roblox
  - vehicle
  - a-chassis
  - raycast-chassis
  - architecture
status: verified
summary: "Comprehensive side-by-side comparison guide between A-Chassis (Constraint Physics) and Raycast Chassis (CDT Laser Arcade) deployed in HOKI TOWN Proving Grounds."
---

# 🏎️ Vehicle Chassis A/B Comparison Guide: HOKI TOWN

## 1. Executive Summary & Proving Grounds Setup
Both vehicle architectures have been deployed side-by-side on the starting line of **`Hoki_Proving_Grounds`**, positioned directly in front of the primary spawn point:

| Lane | Vehicle Model | Engine / Architecture | Position | 3D Billboard Indicator |
| :--- | :--- | :--- | :--- | :--- |
| **Lane 1 (ซ้าย)** | `TeslaRoadster` | **A-Chassis v1.5+** (Constraint Physics) | `(-18, 2.80, -28)` | 🏎️ Sky Blue Badge (`[E] ขับรถ`) |
| **Lane 2 (ขวา)** | `TeslaRoadster_Raycast` | **Raycast Chassis** (CDT Laser Arcade) | `(-6, 2.80, -28)` | ⚡ Cyber Orange Badge (`[E] ขับรถ`) |

---

## 2. In-Depth Architecture Comparison

```
┌─────────────────────────────────┐       ┌─────────────────────────────────┐
│     คันที่ 1: A-Chassis         │       │   คันที่ 2: Raycast Chassis     │
├─────────────────────────────────┤       ├─────────────────────────────────┤
│ • 57 Physical Constraints       │       │ • 0 Physical Constraints        │
│ • Real Spring & Hinge Joints    │       │ • 4 Laser Raycasts to Ground    │
│ • High Wheel-Ground Friction    │       │ • Smooth Spring Equation Force  │
│ • 3,198 lb-ft Torque Tune       │       │ • Tap-to-Drift Momentum Boost   │
│ • Realistic Heavy Drift Feel    │       │ • 100% Anti-Glitch & Zero Lag   │
└─────────────────────────────────┘       └─────────────────────────────────┘
```

### Feature Matrix:
| มิติการเปรียบเทียบ | คันที่ 1: A-Chassis (Constraint) | คันที่ 2: Raycast Chassis (Arcade Laser) |
| :--- | :--- | :--- |
| **ระบบช่วงล่าง (Suspension)** | `SpringConstraint` + `HingeConstraint` จริง | ยิง Raycast 4 จุด คำนวณ \(F = kx - dv\) |
| **การชนของล้อ (Wheel Collision)** | ล้อชนฟิสิกส์จริง (`CanCollide = true`) | ล้อไร้การชน (`CanCollide = false`) หมดปัญหาติดขอบ |
| **ฟีลลิ่งการขับ (Driving Feel)** | หนักแน่น สมจริง น้ำหนักตัวรถชัดเจน | นุ่มนวล ตอบสนองไว สไตล์ Need for Speed / CDT |
| **การดริฟต์ (Drift Mechanics)** | กด Spacebar ล็อกเบรกมือ ดึงท้ายกวาด | Spacebar หรือสบัดเลี้ยว ลดแรงเสียดทานเป็น Arcade Slide |
| **ประสิทธิภาพเซิร์ฟเวอร์ (Server Load)**| ปานกลาง (คำนวณ Constraint 57 ชิ้นต่อคัน) | สูงมาก/ลื่นไหลสุด (Server รับแค่ตำแหน่ง ไม่มี Solver หน่วง) |
| **ความเสี่ยงบั๊ก (Glitches)** | มีโอกาสล้อปีนขอบ หรือเด้งเวลารถชนแรง | 0% ล้อไม่จมดิน ไม่บั๊กลอยข้ามแมพ |

---

## 3. How to Test Drive & Verify (คู่มือการทดสอบ)
1. เปิด **Roblox Studio** ในโปรเจกต์ `HOKI TOWN`
2. กดปุ่ม **Play Solo (F5)**
3. ตัวละครจะเกิดที่จุด `SpawnLocation (-18, 0.5, -10)` มองเห็นรถทั้ง 2 คันจอดคู่กัน
4. **เดินไปทดสอบคันที่ 1 (A-Chassis):**
   - กดปุ่ม `E` หรือกระโดดขึ้นนั่งที่ `DriveSeat`
   - ทดสอบกด `W/A/S/D` เพื่อดูแรงบิด และกด `Spacebar` เพื่อทดสอบการดึงเบรกมือดริฟต์
5. **เดินไปทดสอบคันที่ 2 (Raycast Chassis):**
   - กดปุ่ม `E` เพื่อขึ้นนั่ง
   - ทดสอบกด `W` เร่งความเร็ว และสังเกตความนุ่มนวลเวลาขึ้นเนิน/ลงหลุม
   - ทดสอบสะบัดเลี้ยวพร้อมกด `Spacebar` เพื่อดู Arcade Drift

---

## 4. Single Source of Truth (Rojo Structure)
- `src/TeslaRoadster/` ➡️ จัดการโค้ด A-Chassis คันที่ 1
- `src/TeslaRoadster_Raycast/` ➡️ จัดการโค้ด Raycast Chassis คันที่ 2
  - `RaycastChassisServer.server.luau`: จัดการ Network Ownership และ ProximityPrompt
  - `RaycastChassisClient.client.luau`: รัน PreSimulation คำนวณฟิสิกส์ Raycast และ Animation ล้อหมุน
