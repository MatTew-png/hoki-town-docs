# 🏙️ HOKI TOWN — Master Knowledge Vault

> **Project Identity:** `HOKI TOWN` (Roblox Open-World Thai Roleplay / Driving & Farming Experience)  
> **Roblox Place ID:** `70639875551777`  
> **Universe / Game ID:** `10770440568`  
> **Project Scope:** โปรเจคอิสระใหม่ (New Independent Project) — *ไม่มีความเกี่ยวข้องใดๆ กับ HUNTER TOWN TYCOON*  
> **Vault Root:** `C:\Users\_newgen\Documents\antigravity\HOKI TOWN`  
> **Audit Timestamp:** 2026-11-04  

---

## 📌 สรุปภาพรวมการรับไม้ต่อ (Handover Executive Summary)
โปรเจค **HOKI TOWN** เป็นเกมแนว **Open-World Roleplay / Realistic Driving / Gathering Simulator** ที่ได้รับแรงบันดาลใจจากสไตล์ **FiveM GTA RP ผสมผสานความเป็นไทยร่วมสมัย** (Thai Shophouse, ทางเท้าไทย, พร็อพ FiveM, จุดฟาร์มผลไม้ลุงเอ) 

สภาพงานปัจจุบันจากการสแกนผ่าน Roblox Studio Engine โดยตรง:
- **World & Map (สร้างไว้แล้ว ~70%):** แผนที่ขนาดมหึมา $7,722 \times 8,248$ studs ครอบคลุมถนน 1,552 ท่อน, เนินเขา 1,886 ชิ้น, ตึกแถวพาณิชย์ไทย, โกดัง FiveM เต็มรูปแบบ, โชว์รูม และปั๊มน้ำมัน
- **Scripted Features (สร้างไว้แล้วระดับ Prototype):** ระบบขับรถสมจริง (A-Chassis + ระบบดาเมจชน 5 ระดับ + น้ำมันลด + หน้าปัดไมล์ HUD), ระบบถังน้ำมันระเบิดลูกโซ่, ระบบอนิเมชั่นแท่นฟาร์มผลไม้
- **หนี้ทางสถาปัตยกรรม (Technical Debt):** โค้ดทั้งหมดของทีมเดิมถูกเขียนฝังไว้ใน `Workspace` ตรงๆ (ยังไม่มีสคริปต์ใน `ServerScriptService` หรือ `ReplicatedStorage` เลย) และยังไม่มีระบบ RemoteEvents กลาง

---

## 🗺️ แผนผังเอกสารใน Vault (Vault Navigation)

### 📂 00. ภาพรวมและการประเมิน (Index & Audits)
- [[00_Master_Index|🏙️ 00_Master_Index]]: ศูนย์รวมสารบัญและข้อมูลระบุตัวตนของโปรเจค
- [[01_Project_Status_Audit|📊 01_Project_Status_Audit]]: ผลการประเมินสถานะทางเทคนิคจากการสแกนสดผ่าน Studio Engine
- [[02_Feature_Matrix|📋 02_Feature_Matrix]]: ตารางสรุปฟีเจอร์ที่มีอยู่แล้ว vs ฟีเจอร์ที่ต้องทำต่อ

### 📂 01. เจาะลึกฟีเจอร์ระบบงาน (Features Deep Dive)
- [[FEAT_01B_CDT_Arcade_Vehicle_Overhaul|🏎️ FEAT_01B_CDT_Arcade_Vehicle_Overhaul]]: **การยกเครื่องระบบรถสไตล์ Car Dealership Tycoon (CDT Clean Arcade)** — Tap-to-Drift, เบรกมือ Spacebar ไม่เด้งหลุด, ปลดล็อกความเร็ว 280 km/h, ควันยางนุ่มฟูแนบพื้น, ปลดล็อกรถไม่พังถาวร (GodMode)
- [[VEHICLE_MASTER_DEVELOPMENT_MANUAL|🏎️ VEHICLE_MASTER_DEVELOPMENT_MANUAL]]: **คู่มือพัฒนาเจาะลึกระบบรถยนต์ทั้งระบบ** (วิธี Sandbox แยกเทสต์, การจูน Config ภาษาไทย, ดาเมจชน, น้ำมัน, หน้าปัดไมล์, และขั้นตอนเพิ่มรถใหม่)
- [[FEAT_01_Vehicle_Systems_AChassis|🚗 FEAT_01_Vehicle_Systems_AChassis]]: ระบบยานพาหนะ Tesla Roadster, A-Chassis, กฎดาเมจการชน 5 สปีด, อัตราสิ้นเปลืองน้ำมัน และ CarStatusGui HUD
- [[FEAT_02_Explosive_Hazards|💥 FEAT_02_Explosive_Hazards]]: ระบบถังน้ำมันระเบิด (Explosive Barrels), ฟิสิกส์แรงอัด, ดาเมจระยะห่าง, การระเบิดลูกโซ่ และวงจรรีสปอว์น 25 วินาที
- [[FEAT_03_Totem_Farming_System|🌾 FEAT_03_Totem_Farming_System]]: ระบบแท่นฟาร์มอนิเมชั่น (ลุงเอ / กล้วย / เมล่อน), การหมุนแกน CFrame 3 มิติ และแนวทางการผูกระบบเก็บเกี่ยว
- [[FEAT_04_FiveM_Roleplay_Points|📍 FEAT_04_FiveM_Roleplay_Points]]: จุดวงกลม Interactive สไตล์ FiveM (Summon_Car จุดเบิกรถ, Water_pump จุดเติมน้ำ)
- [[FEAT_05_World_Map_Environment|🗺️ FEAT_05_World_Map_Environment]]: แผนที่โลก 7.7k x 8.2k studs, โครงข่ายถนน, อาคารไทย Shophouse, โกดาว FiveM, Lighting และ Custom Materials

### 📂 02. แผนงานสถาปัตยกรรมและโครงสร้าง (Architecture & Handover Roadmap)
- [[ARCH_01_Predecessor_Architecture_Audit|🔍 ARCH_01_Predecessor_Architecture_Audit]]: การผ่าตัดวิเคราะห์โค้ดของผู้พัฒนาคนก่อน จุดเสี่ยงบั๊ก และข้อจำกัด
- [[ARCH_02_Target_Refactoring_Roadmap|🚀 ARCH_02_Target_Refactoring_Roadmap]]: แผนการ Refactor ย้ายระบบขึ้น `ServerScriptService` และ `ReplicatedStorage`
- [[ARCH_03_Remotes_And_Data_Model_Spec|📡 ARCH_03_Remotes_And_Data_Model_Spec]]: ข้อกำหนดระบบเครือข่าย Client-Server Networking และฐานข้อมูล DataStore ที่ต้องพัฒนาเพิ่ม

### 📂 03. คลังสำรองโค้ดต้นฉบับ (Scripts Vault)
- [[AChassis_Drive_CDT_Arcade_Client|📜 AChassis_Drive_CDT_Arcade_Client.luau]]: สคริปต์ไคลเอนต์หลักควบคุมการขับขี่สไตล์ CDT (Tap-to-Drift, Spacebar Sink, Mobile HUD, Auto-Release PBrake, 2,118 บรรทัด)
- [[VehicleSystems_Server|📜 VehicleSystems_Server.luau]]: สคริปต์เซิร์ฟเวอร์ควบคุมตัวรถ, ประตู ProximityPrompt 2 ฝั่ง, GodMode ป้องกันรถพัง, ระบบซ่อมรถด่วน, และการ Spawn HUD
- [[VehicleStatusClient_Local|📜 VehicleStatusClient_Local.luau]]: สคริปต์ไคลเอนต์เรนเดอร์หน้าปัดไมล์ (ความเร็ว 0-280 KM/H สด 60 FPS, เกียร์ P/R/N/1-6, เลือด, น้ำมัน, ปุ่ม R ซ่อมด่วน)
- [[BarrelExplosions_Server|📜 BarrelExplosions_Server.luau]]: สคริปต์เซิร์ฟเวอร์ควบคุมการระเบิดของถังและระเบิดลูกโซ่
- [[TotemAnimation_Server|📜 TotemAnimation_Server.luau]]: สคริปต์คำนวณการหมุนและ Bobbing ของแท่นฟาร์ม

---

## 🏷️ Tags
#HOKI_TOWN #Roblox #Handover #Architecture #Roleplay #AChassis #Documentation
