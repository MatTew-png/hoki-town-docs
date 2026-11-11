---
project: HOKI TOWN
place_id: "70639875551777"
universe_id: "10770440568"
category: index
doc_type: master-index
status: active
last_audit: 2026-11-04
tags:
  - roblox
  - hoki-town
  - handover
  - architecture
  - master-index
  - project-overview
  - dashboard
---

# 🏙️ HOKI TOWN — Master Knowledge Vault

> **Project Identity:** `HOKI TOWN` (Roblox Open-World Thai Roleplay / Driving & Farming Experience)  
> **Interactive Dashboards:** [[HOKI_TOWN_Project_Dashboard.canvas|🗺️ Project Dashboard Canvas]] | [[HOKI_TOWN_Architecture.canvas|🏛️ Architecture Canvas]] | [[HOKI_TOWN_Full_System_Architecture.excalidraw|🎨 Complete 6-Tier Excalidraw]] | [[KANBAN_Refactoring_Board|📋 Kanban Board]] | [[DATAVIEW_Live_Dashboard|📊 Dataview Live View]]

---

## 📌 สรุปภาพรวมการรับไม้ต่อ (Handover Executive Summary) #handover #project-overview
โปรเจค **HOKI TOWN** เป็นเกมแนว **Open-World Roleplay / Realistic Driving / Gathering Simulator** ที่ได้รับแรงบันดาลใจจากสไตล์ **FiveM GTA RP ผสมผสานความเป็นไทยร่วมสมัย** (Thai Shophouse, ทางเท้าไทย, พร็อพ FiveM, จุดฟาร์มผลไม้ลุงเอ) 

สภาพงานปัจจุบันจากการสแกนผ่าน Roblox Studio Engine โดยตรง:
- **World & Map (สร้างไว้แล้ว ~70%):** #world-map แผนที่ขนาดมหึมา $7,722 \times 8,248$ studs ครอบคลุมถนน 1,552 ท่อน, เนินเขา 1,886 ชิ้น, ตึกแถวพาณิชย์ไทย, โกดัง FiveM เต็มรูปแบบ, โชว์รูม และปั๊มน้ำมัน
- **Scripted Features (สร้างไว้แล้วระดับ Prototype):** #vehicle-system ระบบขับรถสมจริง (A-Chassis + ระบบดาเมจชน 5 ระดับ + น้ำมันลด + หน้าปัดไมล์ HUD), #explosive-hazards ระบบถังน้ำมันระเบิดลูกโซ่, #totem-farm ระบบอนิเมชั่นแท่นฟาร์มผลไม้
- **หนี้ทางสถาปัตยกรรม (Technical Debt):** #critical #technical-debt โค้ดทั้งหมดของทีมเดิมถูกเขียนฝังไว้ใน `Workspace` ตรงๆ (ยังไม่มีสคริปต์ใน `ServerScriptService` หรือ `ReplicatedStorage` เลย) และยังไม่มีระบบ RemoteEvents กลาง

---

## 🗺️ แผนผังเอกสารใน Vault (Vault Navigation)

### 📂 00. ภาพรวมและการประเมิน (Index & Audits) #index
- [[00_Master_Index|🏙️ 00_Master_Index]]: ศูนย์รวมสารบัญและข้อมูลระบุตัวตนของโปรเจค
- [[01_Project_Status_Audit|📊 01_Project_Status_Audit]]: ผลการประเมินสถานะทางเทคนิคจากการสแกนสดผ่าน Studio Engine #audit
- [[02_Feature_Matrix|📋 02_Feature_Matrix]]: ตารางสรุปฟีเจอร์ที่มีอยู่แล้ว vs ฟีเจอร์ที่ต้องทำต่อ พร้อม Dataview Queries #feature-matrix
- [[OBSIDIAN_GIT_GUIDE|🐙 OBSIDIAN_GIT_GUIDE]]: คู่มือการติดตั้งและซิงค์ Vault ขึ้น Git อัตโนมัติด้วย Obsidian Git #git

### 📂 01. เจาะลึกฟีเจอร์ระบบงาน (Features Deep Dive) #features
- [[FEAT_01B_CDT_Arcade_Vehicle_Overhaul|🏎️ FEAT_01B_CDT_Arcade_Vehicle_Overhaul]]: **การยกเครื่องระบบรถสไตล์ Car Dealership Tycoon (CDT Clean Arcade)** — Tap-to-Drift, เบรกมือ Spacebar ไม่เด้งหลุด, ปลดล็อกความเร็ว 280 km/h, ควันยางนุ่มฟูแนบพื้น, ปลดล็อกรถไม่พังถาวร (GodMode) #cdt-arcade #fixed
- [[VEHICLE_MASTER_DEVELOPMENT_MANUAL|🏎️ VEHICLE_MASTER_DEVELOPMENT_MANUAL]]: **คู่มือพัฒนาเจาะลึกระบบรถยนต์ทั้งระบบ** (วิธี Sandbox แยกเทสต์, การจูน Config ภาษาไทย, ดาเมจชน, น้ำมัน, หน้าปัดไมล์, และขั้นตอนเพิ่มรถใหม่) #developer-guide
- [[FEAT_01_Vehicle_Systems_AChassis|🚗 FEAT_01_Vehicle_Systems_AChassis]]: ระบบยานพาหนะ Tesla Roadster, A-Chassis, กฎดาเมจการชน 5 สปีด, อัตราสิ้นเปลืองน้ำมัน และ CarStatusGui HUD #a-chassis
- [[FEAT_02_Explosive_Hazards|💥 FEAT_02_Explosive_Hazards]]: ระบบถังน้ำมันระเบิด (Explosive Barrels), ฟิสิกส์แรงอัด, ดาเมจระยะห่าง, การระเบิดลูกโซ่ และวงจรรีสปอว์น 25 วินาที #hazards
- [[FEAT_03_Totem_Farming_System|🌾 FEAT_03_Totem_Farming_System]]: ระบบแท่นฟาร์มอนิเมชั่น (ลุงเอ / กล้วย / เมล่อน), การหมุนแกน CFrame 3 มิติ และแนวทางการผูกระบบเก็บเกี่ยว #farming
- [[FEAT_04_FiveM_Roleplay_Points|📍 FEAT_04_FiveM_Roleplay_Points]]: จุดวงกลม Interactive สไตล์ FiveM (Summon_Car จุดเบิกรถ, Water_pump จุดเติมน้ำ) #fivem-rp
- [[FEAT_05_World_Map_Environment|🗺️ FEAT_05_World_Map_Environment]]: แผนที่โลก 7.7k x 8.2k studs, โครงข่ายถนน, อาคารไทย Shophouse, โกดาว FiveM, Lighting และ Custom Materials #world-map

### 📂 02. แผนงานสถาปัตยกรรมและโครงสร้าง (Architecture & Handover Roadmap) #architecture
- [[ARCH_01_Predecessor_Architecture_Audit|🔍 ARCH_01_Predecessor_Architecture_Audit]]: การผ่าตัดวิเคราะห์โค้ดของผู้พัฒนาคนก่อน จุดเสี่ยงบั๊ก และข้อจำกัด #anti-pattern
- [[ARCH_02_Target_Refactoring_Roadmap|🚀 ARCH_02_Target_Refactoring_Roadmap]]: แผนการ Refactor ย้ายระบบขึ้น `ServerScriptService` และ `ReplicatedStorage` พร้อม Tasks Plugin Syntax #refactor #tasks
- [[ARCH_03_Remotes_And_Data_Model_Spec|📡 ARCH_03_Remotes_And_Data_Model_Spec]]: ข้อกำหนดระบบเครือข่าย Client-Server Networking และฐานข้อมูล DataStore ที่ต้องพัฒนาเพิ่ม #networking #profilestore
- [[KANBAN_Refactoring_Board|📋 KANBAN_Refactoring_Board]]: กระดาน Kanban Board สำหรับติดตามงาน 4 เฟสตามมาตรฐาน Obsidian Kanban #kanban
- [[DATAVIEW_Live_Dashboard|📊 DATAVIEW_Live_Dashboard]]: หน้าแดชบอร์ดสรุปงานคงค้าง สถิติระบบรถ และคลังสคริปต์แบบเรียลไทม์ #dataview

### 📂 03. คลังสำรองโค้ดต้นฉบับ (Scripts Vault) #scripts
- [[AChassis_Drive_CDT_Arcade_Client|📜 AChassis_Drive_CDT_Arcade_Client.luau]]: สคริปต์ไคลเอนต์หลักควบคุมการขับขี่สไตล์ CDT (Tap-to-Drift, Spacebar Sink, Mobile HUD, Auto-Release PBrake, 2,118 บรรทัด) #client-script
- [[VehicleSystems_Server|📜 VehicleSystems_Server.luau]]: สคริปต์เซิร์ฟเวอร์ควบคุมตัวรถ, ประตู ProximityPrompt 2 ฝั่ง, GodMode ป้องกันรถพัง, ระบบซ่อมรถด่วน, และการ Spawn HUD #server-script
- [[VehicleStatusClient_Local|📜 VehicleStatusClient_Local.luau]]: สคริปต์ไคลเอนต์เรนเดอร์หน้าปัดไมล์ (ความเร็ว 0-280 KM/H สด 60 FPS, เกียร์ P/R/N/1-6, เลือด, น้ำมัน, ปุ่ม R ซ่อมด่วน) #client-script
- [[BarrelExplosions_Server|📜 BarrelExplosions_Server.luau]]: สคริปต์เซิร์ฟเวอร์ควบคุมการระเบิดของถังและระเบิดลูกโซ่ #server-script
- [[TotemAnimation_Server|📜 TotemAnimation_Server.luau]]: สคริปต์คำนวณการหมุนและ Bobbing ของแท่นฟาร์ม #server-script

### 📂 04. แม่แบบเอกสารและเทมเพลต (Templates & Tooling) #templates
- [[Templates/Template_New_Feature|📄 Template_New_Feature]]: แม่แบบมาตรฐานสำหรับสร้างฟีเจอร์ใหม่
- [[Templates/Template_New_Script|📄 Template_New_Script]]: แม่แบบสำหรับบันทึกและจัดเก็บสคริปต์
- [[Templates/Template_New_Architecture_ADR|📄 Template_New_Architecture_ADR]]: แม่แบบบันทึกข้อตกลงสถาปัตยกรรม (ADR)
- [[Templates/README_Templater_Setup|🛠️ README_Templater_Setup]]: คู่มือการติดตั้งและตั้งค่า Templater Plugin ใน Obsidian

---

## 🎨 Interactive Visual Boards
- 🗺️ **Executive Project Dashboard Canvas:** `[[HOKI_TOWN_Project_Dashboard.canvas]]` — กระดานภาพรวมโครงการ สถิติประเมินความพร้อม ลิงก์ด่วน และ Roadmap
- 🏛️ **System Architecture Canvas:** `[[HOKI_TOWN_Architecture.canvas]]` — แผนผังภาพรวมระบบ DataModel, Server Services, Replicated Storage และ Client Layer
- 🎨 **Complete 6-Tier Excalidraw:** `[[HOKI_TOWN_Full_System_Architecture.excalidraw]]` — ผังทอพอโลยีสถาปัตยกรรมครบทั้ง 6 ลำดับชั้น
- 🎨 **Client-Server DataFlow Excalidraw:** `[[HOKI_TOWN_DataFlow_Architecture.excalidraw]]` — ผังการไหลของข้อมูลการกดปุ่มและวงจรคำนวณฟิสิกส์
