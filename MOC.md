---
project: HOKI TOWN
category: index
doc_type: map-of-content
status: active
last_audit: 2026-11-07
tags:
  - moc
  - map-of-content
  - navigation
  - agent-index
---

# 🗺️ HOKI TOWN — Map of Content (MOC)

> **Agent Context Entrypoint:** เอกสารแผนผังความสัมพันธ์ระดับสูง ออกแบบเพื่อให้มนุษย์และ AI Agent ค้นหาเอกสารเป้าหมายได้โดยใช้ Token น้อยที่สุด  
> **Visual Boards:** [[HOKI_TOWN_Project_Dashboard.canvas|🗺️ Project Dashboard]] | [[HOKI_TOWN_Architecture.canvas|🏛️ Architecture Canvas]] | [[HOKI_TOWN_Full_System_Architecture.excalidraw|🎨 Complete 6-Tier Excalidraw]] | [[KANBAN_Refactoring_Board|📋 Kanban Board]]

---

## 🧭 High-Level Vault Hierarchy

```text
HOKI TOWN Vault/
├── .agent/                  # กฎ กฎบัตร Schema และ Skills ของ AI Agent
│   ├── rules.md             # กฎความปลอดภัยและข้อกำหนดการเขียนโค้ด
│   ├── schema.md            # ข้อกำหนด YAML Frontmatter
│   ├── mcp-setup.md         # คู่มือตั้งค่า Model Context Protocol
│   └── skills/              # Agent Automation Directives
├── 00_Index/                # สารบัญภาพรวม การประเมินสถานะ และ Git Workflow
├── 01_Features_Deep_Dive/   # เจาะลึกระบบรถ การชน ถังระเบิด แท่นฟาร์ม และแผนที่
├── 02_Technical_Architecture_Handover/ # แผนผัง Refactor, Remotes Spec, Kanban และ Dataview
├── 03_Scripts_Vault/        # คลังซอร์สโค้ด Luau ต้นฉบับที่ผ่านการทดสอบแล้ว
├── 10_Inbox/                # จุดพักข้อมูลดิบและงานดราฟต์ของ AI ก่อนรีวิว
├── Templates/               # แม่แบบเอกสาร Templater Plugin
└── 90_Archive/              # เอกสารและบันทึกเก่าที่ผ่านการปรับปรุงแล้ว
```

---

## 📌 Direct Map of Content Links

### 00. ภาพรวมและการประเมิน (Index & Assessment)
- [[00_Master_Index|🏙️ 00_Master_Index]]: ศูนย์รวมสารบัญหลักของโปรเจค
- [[01_Project_Status_Audit|📊 01_Project_Status_Audit]]: ผลสแกน DataModel ละเอียดกว่า 35,000 ชิ้น
- [[02_Feature_Matrix|📋 02_Feature_Matrix]]: ตารางสรุปสถานะฟีเจอร์ปัจจุบัน vs ฟีเจอร์ที่ต้องสร้างต่อ
- [[OBSIDIAN_GIT_GUIDE|🐙 OBSIDIAN_GIT_GUIDE]]: คู่มือซิงค์ Vault ขึ้น GitHub ด้วย Obsidian Git

### 01. ฟีเจอร์หลัก (Features Deep Dive)
- [[10_Inbox/CONFIG_TESLA_ROADSTER_BEST_GOLD_MASTER|🏎️ CONFIG_TESLA_ROADSTER_GOLD_MASTER]]: ค่าคอนฟิกจูนที่ดีที่สุด (Best Master Tune JSON, Flush Stance, ซ่อนโช๊ค)
- [[FEAT_01D_Tesla_Raycast_Modular_Pipeline|🏎️ FEAT_01D]]: สถาปัตยกรรม Raycast Arcade Vehicle, โมเดลโมดูลาร์ 5 ช่องสี, ระบบไฟซิงค์ 4 สถานะ, และ CurbAssist
- [[FEAT_01B_CDT_Arcade_Vehicle_Overhaul|🏎️ FEAT_01B]]: ยกเครื่องระบบขับขี่ CDT Arcade (Tap-to-Drift, 280 km/h, Spacebar Sink)
- [[VEHICLE_CHASSIS_AB_COMPARISON_GUIDE|🏎️ VEHICLE_CHASSIS_AB_COMPARISON_GUIDE]]: เปรียบเทียบ A-Chassis (Constraint) vs Raycast Chassis (Laser Arcade)
- [[VEHICLE_MASTER_DEVELOPMENT_MANUAL|🏎️ VEHICLE_MANUAL]]: คู่มือพัฒนาและจูนระบบรถยนต์ทั้งระบบ
- [[FEAT_01_Vehicle_Systems_AChassis|🚗 FEAT_01]]: ระบบช่วงล่าง A-Chassis, กฎดาเมจชน 5 สปีด และน้ำมัน
- [[FEAT_02_Explosive_Hazards|💥 FEAT_02]]: ระบบถังน้ำมันระเบิดลูกโซ่และวงจรรีสปอว์น 25 วินาที
- [[FEAT_03_Totem_Farming_System|🌾 FEAT_03]]: ระบบแท่นฟาร์มผลไม้คิเนมาติก (ลุงเอ/กล้วย/เมล่อน)
- [[FEAT_04_FiveM_Roleplay_Points|📍 FEAT_04]]: จุดอินเตอร์แอ็กชัน Summon_Car และ Water_pump สไตล์ FiveM
- [[FEAT_05_World_Map_Environment|🗺️ FEAT_05]]: โครงสร้างแผนที่ 7.7k x 8.2k studs, ถนน 1,552 ท่อน และแสง Future

### 02. สถาปัตยกรรมและแผนงาน (Technical Architecture)
- [[HANDOFF_OPENCODE_GO_2026-11-07|🚀 HANDOFF_OPENCODE_GO]]: เอกสารส่งมอบงานสำหรับ OpenCode Go (Rojo Hybrid Architecture & Chassis Guide)
- [[ARCH_01_Predecessor_Architecture_Audit|🔍 ARCH_01]]: การผ่าตัดวิเคราะห์โค้ดเดิมและหนี้ทางเทคนิค
- [[ARCH_02_Target_Refactoring_Roadmap|🚀 ARCH_02]]: แผนงาน 4 เฟส ย้ายระบบขึ้น ServerScriptService
- [[ARCH_03_Remotes_And_Data_Model_Spec|📡 ARCH_03]]: ข้อกำหนด RemoteEvents และฐานข้อมูล ProfileStore
- [[KANBAN_Refactoring_Board|📋 KANBAN_Refactoring_Board]]: กระดาน Kanban สำหรับติดตามงาน
- [[DATAVIEW_Live_Dashboard|📊 DATAVIEW_Live_Dashboard]]: แดชบอร์ดคิวรีข้อมูลสดผ่าน Dataview

### 03. คลังสคริปต์ต้นฉบับ (Scripts Vault)
- [[AChassis_Drive_CDT_Arcade_Client|📜 AChassis_Drive]]: สคริปต์ไคลเอนต์ขับขี่ CDT Arcade (2,118 บรรทัด)
- [[Hybrid_Arcade_Raycast_Client|🚗 Hybrid_Arcade_Raycast_Client]]: สคริปต์ขับขี่ Hybrid Raycast Arcade ตัวจริง (1,419 บรรทัด - Spherecast + CurbAssist)
- [[VehicleSystems_Server|📜 VehicleSystems]]: สคริปต์เซิร์ฟเวอร์ควบคุมรถ, ประตู ProximityPrompt และ GodMode
- [[VehicleStatusClient_Local|📜 VehicleStatusClient]]: สคริปต์ไคลเอนต์เรนเดอร์หน้าปัดไมล์ HUD ความเร็ว 0-280 KM/H
- [[BarrelExplosions_Server|📜 BarrelExplosions]]: สคริปต์เซิร์ฟเวอร์ควบคุมถังระเบิดลูกโซ่
- [[TotemAnimation_Server|📜 TotemAnimation]]: สคริปต์คำนวณการหมุนและ Bobbing ของแท่นฟาร์ม
- `03_Scripts_Vault/Hoki_CDT_Arcade_Engine_And_Tuning.luau`: ซอร์สโค้ด CDT Clean Arcade Engine & Live Stance Tuning
