# 📋 02. Feature Matrix (ตารางแจกแจงฟีเจอร์)

ตารางแสดงสถานะของทุกระบบใน **HOKI TOWN** จำแนกระหว่าง **"มีอยู่แล้ว (Implemented)"**, **"มีบางส่วน (Partial)"**, และ **"ต้องสร้างต่อ (To Build)"**

| รหัสฟีเจอร์ | ชื่อฟีเจอร์ (Feature Name) | หมวดหมู่ | สถานะปัจจุบัน | ไฟล์ / อ็อบเจ็กต์ที่เกี่ยวข้อง | สิ่งที่ต้องพัฒนาต่อ (Next Steps) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **VEH-01** | **A-Chassis Vehicle Base** | ยานพาหนะ | 🟢 พร้อมใช้งาน | `Workspace.TeslaRoadster` (A-Chassis Tune) | ฐานโครงสร้างช่วงล่างฟิสิกส์ 4 ล้อ |
| **VEH-01B** | **CDT Arcade Overhaul & Tap-to-Drift** | การขับขี่และฟิสิกส์ | 🟢 สมบูรณ์ 100% | `[[FEAT_01B_CDT_Arcade_Vehicle_Overhaul]]`, `[[AChassis_Drive_CDT_Arcade_Client]]` | ปลดล็อก Spacebar เบรกมือไม่เด้งหลุด, Tap-to-Drift สไตล์ CDT, ควันยางนุ่มฟูแนบพื้น, ปลดล็อกความเร็ว 280 km/h, ระบบไม่พังถาวร (GodMode) |
| **VEH-02** | **5-Tier Crash Damage & GodMode** | ฟิสิกส์การชน | 🟢 พร้อมใช้งาน | `[[VehicleSystems_Server]]` | มีโหมด GodMode รองรับการเปิด-ปิด และระบบซ่อมด่วนกด R |
| **VEH-03** | **Dynamic Fuel Drain & Infinity Mode** | ระบบน้ำมัน | 🟢 พร้อมใช้งาน | `[[VehicleSystems_Server]]` | ปลดล็อกขับได้ไม่จำกัดรอบ และรองรับการเติมน้ำมันในอนาคต |
| **VEH-04** | **In-Car Status HUD (Golden Wing)** | UI หน้าปัดไมล์ | 🟢 สมบูรณ์ 100% | `[[VehicleStatusClient_Local]]` | แก้บั๊ก Crash บรรทัดที่ 2, อัปเดตความเร็ว 0-280 KM/H และเกียร์ 60 FPS เรียลไทม์ |
| **VEH-05** | **Garage & Vehicle Spawner** | ระบบเบิกรถ | 🔴 ยังไม่มี | `Workspace.Fivem_pack_v2.Summon_Car` | เขียนระบบ GUI เลือกเบิกรถและเซิร์ฟเวอร์ Spawner |
| **HAZ-01** | **Explosive Barrels Hazard** | อุปสรรคฉาก | 🟢 พร้อมใช้งาน | `Workspace.ExplosiveBarrels.BarrelExplosions` | ปรับตำแหน่งวางในจุดเลี้ยวอันตรายเพื่อเพิ่มความท้าทาย |
| **JOB-01** | **Farming Totems Visual** | ระบบอาชีพ/ฟาร์ม| 🟡 มีเฉพาะภาพ | `Workspace.TotemFarm_Pack.TotemAnimation` | เพิ่ม `ProximityPrompt` ให้ผู้เล่นกดเก็บเกี่ยว (Harvesting) |
| **JOB-02** | **Inventory & Item Stash** | กระเป๋าเก็บของ | 🔴 ยังไม่มี | - | พัฒนาระบบ Inventory จัดเก็บกล้วย, เมล่อน, น้ำ |
| **JOB-03** | **Water Pumping Station**| อาชีพ/ฟาร์ม | 🟡 มีเฉพาะภาพ | `Workspace.Fivem_pack_v2.Water_pump` | เพิ่มระบบดูดน้ำ / ปั๊มน้ำเพื่อนำไปแปรรูป |
| **MAP-01** | **Road & Sidewalk Network**| แผนที่ | 🟢 พร้อมใช้งาน | `Workspace.Road` (1,552 ชิ้น), `Workspace.ฟุตบาท` | จัดหมวดหมู่ Folder ให้เป็นระเบียบ และ Anchor ชิ้นส่วน |
| **MAP-02** | **Town Buildings & Props** | แผนที่ | 🟢 พร้อมใช้งาน | `ThaiShophouse`, `OldWarehouse_FiveM`, `บ้าน #1` | วางประตูปิดเปิด / แสงไฟส่องสว่างตอนกลางคืน |
| **MAP-03** | **Spawn Location & Hub** | แผนที่ | 🔴 ยังไม่มี | - | สร้าง SpawnLocation บริเวณหน้าโชว์รูมหรือใจกลางเมือง |
| **SYS-01** | **Player DataStore** | ข้อมูลผู้เล่น | 🔴 ยังไม่มี | - | ระบบบันทึกเงิน, ยานพาหนะที่ครอบครอง, เลเวล |
| **SYS-02** | **Clean Architecture** | โครงสร้างโค้ด | 🔴 ยังไม่มี | - | ย้ายสคริปต์ขึ้น `ServerScriptService` และใช้ Knit/OOP Service |
