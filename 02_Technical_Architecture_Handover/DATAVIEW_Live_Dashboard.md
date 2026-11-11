---
project: HOKI TOWN
category: architecture
doc_type: dataview-dashboard
status: active
last_audit: 2026-11-04
tags:
  - dataview
  - dashboard
  - live-tracking
  - roadmap
  - task-management
---

# 📊 HOKI TOWN — Dataview Live Project Dashboard

> **ความต้องการ:** ติดตั้งและเปิดใช้งาน **Dataview Community Plugin** ใน Obsidian เพื่อแสดงผลแบบเรียลไทม์  
> **กระดานแบบภาพ:** [[HOKI_TOWN_Project_Dashboard.canvas|🗺️ Project Overview Canvas]] | [[KANBAN_Refactoring_Board|📋 Kanban Board]]

---

## 🚀 งานคงค้างใน Roadmap ที่ต้องเร่งทำ (Pending Roadmap Tasks) #tasks #critical

```dataview
TASK
FROM "02_Technical_Architecture_Handover"
WHERE !completed
GROUP BY file.name
```

---

## ✅ งานที่ผ่านการทดสอบและเสร็จสมบูรณ์แล้ว (Completed Milestones)

```dataview
TASK
FROM "02_Technical_Architecture_Handover"
WHERE completed
GROUP BY file.name
```

---

## 🚗 สรุปสถานะระบบยานพาหนะและการขับขี่ (Vehicle Systems Matrix) #vehicle-system

```dataview
TABLE WITHOUT ID
  file.link AS "เอกสาร / สเปก",
  system AS "ระบบงาน",
  status AS "สถานะ",
  priority AS "ลำดับความสำคัญ",
  top_speed_kmh AS "Max Speed (KM/H)"
FROM "01_Features_Deep_Dive"
WHERE contains(tags, "vehicle-system")
SORT priority ASC
```

---

## 📜 คลังสคริปต์ต้นฉบับทั้งหมด (Scripts Inventory) #scripts

```dataview
TABLE WITHOUT ID
  file.link AS "สคริปต์",
  script_type AS "ประเภท",
  lines_of_code AS "จำนวนบรรทัด",
  datamodel_location AS "ตำแหน่งใน DataModel"
FROM "03_Scripts_Vault"
SORT lines_of_code DESC
```
