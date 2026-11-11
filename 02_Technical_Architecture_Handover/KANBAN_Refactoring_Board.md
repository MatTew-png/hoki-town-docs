---
kanban-plugin: basic
project: HOKI TOWN
category: management
doc_type: kanban-board
status: active
last_audit: 2026-11-04
tags:
  - kanban
  - tasks
  - roadmap
  - refactoring
  - project-management
---

# 📋 HOKI TOWN — Refactoring & Development Kanban Board

> **Plugin Compatibility:** รองรับการแสดงผลแบบบอร์ดลาก-วาง ผ่าน Obsidian Kanban Plugin  
> **แผนงานหลัก:** [[ARCH_02_Target_Refactoring_Roadmap|🚀 ARCH_02_Target_Refactoring_Roadmap]]

***

## 📋 Backlog (แผนงานรอเริ่ม)

- [ ] **3.1** ติดตั้ง ProximityPrompt เก็บเกี่ยวที่แท่นฟาร์ม (ลุงเอ / กล้วย / เมล่อน) #farming #phase3
- [ ] **3.2** สร้าง InventoryService จัดการกระเป๋าเก็บไอเทม #inventory #phase3
- [ ] **3.3** สร้างจุดขายผลไม้ที่โกดัง FiveM (Market NPC Buyer) #economy #phase3
- [ ] **3.4** เชื่อมโยงระบบเติมน้ำมันที่ GasTankSites #fuel #phase3
- [ ] **4.1** วางระบบ ProfileStore จัดเก็บ Cash, OwnedVehicles และ Inventory #datastore #phase4 #critical
- [ ] **4.2** ระบบ Server-Side Anti-Cheat ป้องกันการปั๊มความเร็ว/เงิน #security #phase4 #critical
- [ ] **4.3** ตรวจสอบความเข้ากันได้ของ Mobile HUD บนหน้าจอขนาดต่างๆ #mobile #phase4

## 🏗️ In Progress (กำลังดำเนินการ - เฟส 1 & 2)

- [ ] **1.4** สร้าง SpawnLocation ถาวรหน้าโชว์รูม (Transparency=1, Neutral=true) #phase1
- [ ] **1.5** ย้ายชิ้นส่วนใน Workspace เข้าหมวด Environment, Hazards, InteractivePoints #cleanup #phase1
- [ ] **1.6** ย้าย TotemAnimation จาก Workspace ไป StarterPlayerScripts (Client CFrame) #optimization #phase1
- [ ] **2.1** ย้ายโมเดล TeslaRoadster เข้าสู่ ServerStorage.VehicleTemplates #phase2
- [ ] **2.2** ออกแบบโครงร่าง VehicleService บน ServerScriptService #phase2 #critical
- [ ] **2.3** ย้าย CarStatusGui ไปติดตั้งใน StarterGui #ui #phase2

## 🧪 Testing & Sandbox (ทดสอบยืนยันแล้วบน Sandbox)

- [x] ทดสอบพฤติกรรมเบรกมือ Spacebar Sink ไม่ให้ตัวละครดีดหลุดจากเบาะ #cdt-arcade #passed
- [x] ทดสอบ Tap-to-Drift ล็อกล้อหลัง 18,000 N คืนการยึดเกาะภายใน 1.2 วินาที #cdt-arcade #passed
- [x] ทดสอบการปลดล็อกความเร็วสูงสุด 280 km/h ด้วยเกียร์ 6 อัตโนมัติ #cdt-arcade #passed
- [x] ตรวจสอบเอฟเฟกต์ควันยางแนบพื้นผิว (Raycast Ground Snap) #vfx #passed
- [x] ยืนยันการทำงานของ GodMode ป้องกันรถระเบิด/เครื่องพังถาวร #vehicle-system #passed

## ✅ Completed (เสร็จสมบูรณ์ 100%)

- [x] **1.1** ล้าง Ghost Welds ตกค้างที่ตรึงตัวรถกับพื้นถนน #fixed #phase1
- [x] **1.2** แก้ไขข้อผิดพลาด Crash บรรทัดที่ 2 ของ VehicleStatusClient #fixed #phase1
- [x] **1.3** พัฒนา CDT Arcade Engine พร้อมฟังก์ชัน Live Tuning ทดแทน A-Chassis ดั้งเดิม #cdt-arcade #phase1
- [x] **1.4** ติดตั้ง ProximityPrompt ประตูคนขับ/ผู้โดยสาร 2 ฝั่ง พร้อม Safe Teleport ตอนลงรถ #doors #phase1
- [x] **1.5** ติดตั้งรีโมตซ่อมรถด่วนกดปุ่ม [R] (VehicleRepairRequest) ฟื้นฟู 100% #repair #phase1
