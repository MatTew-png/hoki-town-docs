---
project: HOKI TOWN
script_name: "<% tp.file.title %>"
script_type: "<% tp.user.prompt ? await tp.system.prompt('ระบุประเภทสคริปต์ (LocalScript / Script / ModuleScript):', 'LocalScript') : 'LocalScript' %>"
datamodel_location: "<% tp.user.prompt ? await tp.system.prompt('ตำแหน่งใน DataModel:', 'Workspace.Object.Script') : 'Workspace.Object.Script' %>"
lines_of_code: 0
verified_status: draft
tags:
  - script-vault
  - production-code
  - roblox
  - hoki-town
---

# 📜 <% tp.file.title %> (<% tp.frontmatter.script_type %>)

> **ตำแหน่งใน DataModel:** `<% tp.frontmatter.datamodel_location %>`  
> **ประเภทสคริปต์:** `<% tp.frontmatter.script_type %>`  
> **คำอธิบาย:** สรุปหน้าที่และฟังก์ชันการทำงานหลักของสคริปต์นี้  
> **สถานะ:** 🟡 กำลังพัฒนาและปรับแต่ง (Draft)

---

## 📌 จุดปรับปรุงสำคัญระดับสถาปัตยกรรม (Architectural Highlights) #architecture

### 1. การทำงานหลัก
- จุดเด่นที่ 1...
- จุดเด่นที่ 2...

---

## 📝 ซอร์สโค้ดฉบับสมบูรณ์ (Production Source Code) #code

```luau
-- ============================================================================
-- HOKI TOWN - <% tp.file.title %>
-- Created: <% tp.date.now('YYYY-MM-DD') %>
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

print("[<% tp.file.title %>] Initialized successfully.")
```
