---
project: HOKI TOWN
category: index
doc_type: feature-matrix
status: active
total_features: 9
implemented_count: 5
partial_count: 2
to_build_count: 2
last_audit: 2026-11-04
tags:
  - feature-matrix
  - roadmap
  - progress-tracking
  - game-design
  - vehicle-systems
  - dataview
---

# 📋 02. Feature Matrix (ตารางแจกแจงฟีเจอร์)

> **Dynamic Queries:** หน้านี้รองรับการแสดงผลแบบไดนามิกผ่าน **Obsidian Dataview Plugin** ควบคู่กับตารางสำรองแบบ Static Markdown

---

## 🔄 Dynamic Feature Matrix (Dataview Query) #dataview

```dataview
TABLE WITHOUT ID
  file.link AS "ชื่อฟีเจอร์ (Note)",
  feature_id AS "รหัส",
  system AS "ระบบ",
  status AS "สถานะ",
  priority AS "ความสำคัญ",
  last_audit AS "ตรวจสอบล่าสุด"
FROM "01_Features_Deep_Dive"
WHERE feature_id
SORT feature_id ASC
```

---

## 📊 Feature Status Breakdown (Grouped by Status)

```dataview
TABLE WITHOUT ID
  status AS "สถานะปัจจุบัน",
  rows.file.link AS "ฟีเจอร์ที่อยู่ในกลุ่ม",
  length(rows) AS "จำนวนรวม"
FROM "01_Features_Deep_Dive"
WHERE feature_id
GROUP BY status
```

---

## 📋 ตารางสรุปภาพรวมฟีเจอร์ (Static Fallback Matrix)

ตารางแสดงสถานะของทุกระบบใน **HOKI TOWN** จำแนกระหว่าง **"มีอยู่แล้ว (Implemented)"**, **"มีบางส่วน (Partial)"**, และ **"ต้องสร้างต่อ (To Build)"** #feature-matrix

| รหัสฟีเจอร์ | ชื่อฟีเจอร์ (Feature Name) | หมวดหมู่ | สถานะปัจจุบัน | ไฟล์ / อ็อบเจ็กต์ที่เกี่ยวข้อง | สิ่งที่ต้องพัฒนาต่อ (Next Steps) | Tags |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **VEH-01** | **A-Chassis Vehicle Base** | ยานพาหนะ | 🟢 พร้อมใช้งาน | `Workspace.TeslaRoadster` | ฐานโครงสร้างช่วงล่างฟิสิกส์ 4 ล้อ | #vehicle-system #a-chassis |
| **VEH-01B** | **CDT Arcade Overhaul & Tap-to-Drift** | การขับขี่และฟิสิกส์ | 🟢 สมบูรณ์ 100% | `[[FEAT_01B_CDT_Arcade_Vehicle_Overhaul]]` | ปลดล็อก Spacebar เบรกมือ, Tap-to-Drift, ควันยางนุ่มฟู, 280 km/h, GodMode | #cdt-arcade #fixed |
| **VEH-02** | **5-Tier Crash Damage & GodMode** | ฟิสิกส์การชน | 🟢 พร้อมใช้งาน | `[[VehicleSystems_Server]]` | มีโหมด GodMode รองรับการเปิด-ปิด และระบบซ่อมด่วนกด R | #damage-system #godmode |
| **VEH-03** | **Dynamic Fuel Drain & Infinity Mode** | ระบบน้ำมัน | 🟢 พร้อมใช้งาน | `[[VehicleSystems_Server]]` | ปลดล็อกขับได้ไม่จำกัดรอบ และรองรับการเติมน้ำมันในอนาคต | #fuel-system |
| **VEH-04** | **In-Car Status HUD (Golden Wing)** | UI หน้าปัดไมล์ | 🟢 สมบูรณ์ 100% | `[[VehicleStatusClient_Local]]` | แก้บั๊ก Crash บรรทัดที่ 2, อัปเดตความเร็ว 0-280 KM/H และเกียร์ 60 FPS | #car-hud #fixed |
| **VEH-05** | **Garage & Vehicle Spawner** | ระบบเบิกรถ | 🔴 ยังไม่มี | `Workspace.Fivem_pack_v2.Summon_Car` | เขียนระบบ GUI เลือกเบิกรถและเซิร์ฟเวอร์ Spawner | #spawner #todo |
| **HAZ-01** | **Explosive Barrels Hazard** | อุปสรรคฉาก | 🟢 พร้อมใช้งาน | `Workspace.ExplosiveBarrels.BarrelExplosions` | ปรับตำแหน่งวางในจุดเลี้ยวอันตรายเพื่อเพิ่มความท้าทาย | #hazards #explosive-barrel |
| **JOB-01** | **Farming Totems Visual** | ระบบอาชีพ/ฟาร์ม| 🟡 มีเฉพาะภาพ | `Workspace.TotemFarm_Pack.TotemAnimation` | เพิ่ม `ProximityPrompt` ให้ผู้เล่นกดเก็บเกี่ยว (Harvesting) | #farming #totem |
| **JOB-02** | **Inventory & Item Stash** | กระเป๋าเก็บของ | 🔴 ยังไม่มี | - | พัฒนาระบบ Inventory จัดเก็บกล้วย, เมล่อน, น้ำ | #inventory #todo |
