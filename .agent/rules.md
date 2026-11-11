---
project: HOKI TOWN
doc_type: agent-rules
version: 1.0.0
last_updated: 2026-11-07
tags:
  - agent-rules
  - governance
  - conventions
  - best-practices
---

# 🤖 Agent Rules & Vault Governance Guidelines

เอกสารนี้กำหนดกรอบการทำงาน ข้อห้าม และมาตรฐานการอ่าน/เขียนข้อมูลของ AI Agent (Antigravity, Claude Code, Cursor, MCP Agents) ใน Obsidian Vault ของโครงการ **HOKI TOWN**

---

## 🛡️ 1. Core Principles (หลักการสำคัญสูงสุด)

1. **Zero Destructive Overwrite (ห้ามเขียนทับข้อมูลโดยไม่ได้รับอนุญาต):**
   - ห้ามลบหรือเขียนทับเอกสารที่มีอยู่แล้วโดยเด็ดขาด ให้ใช้แนวทาง **Surgical Editing** (แก้ไขเฉพาะจุด) หรือนำเสนอแบบ Diff
   - หากต้องการร่างฟีเจอร์หรือสถาปัตยกรรมใหม่ ให้บันทึกลงใน `10_Inbox/` เพื่อให้มนุษย์รีวิวก่อนย้ายเข้าโฟลเดอร์ถาวร

2. **Empirical Grounding (ยึดหลักข้อเท็จจริงใน DataModel):**
   - ห้ามคาดเดาชื่อชิ้นส่วนหรือพฤติกรรมของสคริปต์ Roblox หากไม่แน่ใจ ให้ตรวจสอบจาก [[01_Project_Status_Audit]] หรือโครงสร้างใน `03_Scripts_Vault/` เสมอ
   - ห้ามประดิษฐ์ (Hallucinate) API หรือ RemoteEvent ที่ไม่มีอยู่จริง

3. **Context Window & Token Discipline:**
   - ใช้ [[MOC]] (Map of Content) หรือ Index Files ก่อนเริ่มสแกนลึก
   - ห้าม Bulk-read โฟลเดอร์ `03_Scripts_Vault` ทั้งหมดลง Context หากต้องการสืบค้น ให้ดูสรุปจาก [[00_Master_Index]] หรือ [[02_Feature_Matrix]] ก่อน

---

## 📝 2. File Naming & Path Conventions

| หมวดหมู่ | โครงสร้างชื่อไฟล์ | ตัวอย่าง |
| :--- | :--- | :--- |
| **ฟีเจอร์หลัก** | `FEAT_XX_PascalCase.md` | `FEAT_01B_CDT_Arcade_Vehicle_Overhaul.md` |
| **สถาปัตยกรรม** | `ARCH_XX_PascalCase.md` | `ARCH_02_Target_Refactoring_Roadmap.md` |
| **สคริปต์ต้นฉบับ** | `ScriptName_Type.md` | `AChassis_Drive_CDT_Arcade_Client.md` |
| **แม่แบบ (Template)** | `Template_Name.md` | `Template_New_Feature.md` |
| **ดราฟต์ใหม่ใน Inbox** | `DRAFT_YYYY-MM-DD_Topic.md` | `DRAFT_2026-11-07_Gas_Station_Economy.md` |
| **โน้ตย่อย (Atomic Note)**| `kebab-case-concept.md` | `tap-to-drift-physics.md` |

---

## 🏷️ 3. YAML Frontmatter Standards

ทุกไฟล์ Markdown ต้องขึ้นต้นด้วย YAML Frontmatter ตามข้อกำหนดใน [[.agent/schema.md]] ห้ามละเว้น:

```yaml
---
project: HOKI TOWN
category: feature-deep-dive # หรือ index, architecture, script, template
status: active # หรือ completed, in-progress, prototype, draft
priority: high # หรือ critical, medium, low
last_audit: YYYY-MM-DD
tags:
  - roblox
  - hoki-town
  - [contextual-tags]
---
```

---

## 🔗 4. Linking & Reference Guidelines

1. **ใช้ Obsidian Wikilinks เท่านั้น:**
   - ใช้ `[[ชื่อไฟล์]]` หรือ `[[ชื่อไฟล์|ข้อความแสดงผล]]`
   - ห้ามใช้ Relative Web Paths เช่น `../01_Features/file.md` ในเนื้อหา prose
2. **Anchor Links ภายในหน้า:**
   - เมื่ออ้างอิงถึงหัวข้อย่อยในไฟล์ ให้ใช้ `[[ชื่อไฟล์#หัวข้อ]]` หรือใช้ HTML Anchor `<a id="..."></a>`

---

## 💻 5. Roblox Luau Code Standards

1. **Strict Type Safety:** กำหนด Type Annotation ทุกฟังก์ชันและตัวแปรหลัก (`local seat: VehicleSeat`)
2. **Memory Leak Prevention:** สัญญาณทุกตัว (`Connect`) ต้องถูกตัดการเชื่อมต่อ (`Disconnect`) เมื่ออ็อบเจ็กต์ถูกทำลาย
3. **Client-Server Boundary:**
   - ตรวจสอบสิทธิ์และระยะห่าง (`Magnitude < 15`) ฝั่ง Server เสมอ
   - ห้ามเชื่อถือ Client Arguments จาก RemoteEvent

---

## 🔍 6. Autonomous Pre-Delivery Scrutinize Audit

ทุกครั้งที่มีการแก้ไข/สร้างไฟล์ Luau หรืออัปเดตสถาปัตยกรรมใน Vault Agent ต้องรัน Scrutinize Checklist ก่อนส่งมอบเสมอ:
1. **YAGNI Check:** โค้ดที่เพิ่มจำเป็นจริงหรือไม่ ไม่เขียนโครงสร้างเกินจำเป็น
2. **Sibling Sweep:** ตรวจสอบทุกจุดที่เรียกใช้ (Callers) ใน `03_Scripts_Vault/` ว่าไม่เกิด Breaking Changes
3. **Event Disconnect:** ตรวจสอบการทำลาย Connection ทุกตัวเมื่อ Instance ถูกทำลาย
4. **Type Checking:** บังคับใส่ `--!strict` และ Type Annotations ทุกฟังก์ชันสำคัญ

---

## ⚡ 7. Roblox Hybrid Development Protocol (Rojo + Studio MCP)

เพื่อป้องกันปัญหาข้อมูลทับซ้อน (Sync Conflict) และความผิดพลาดจากการแก้โค้ดในหน่วยความจำ:

1. **Rojo = Single Source of Truth for Code:**
   - **ห้ามใช้ MCP แก้ไขสคริปต์โดยตรง:** ห้ามใช้ MCP (`run_code` หรือเขียนทับ `.Source`) กับสคริปต์ที่อยู่ในโฟลเดอร์ที่ Rojo ดูแลเด็ดขาด
   - **แก้ไขโค้ดผ่าน Local Files บนเครื่องเสมอ:** การสร้าง แก้ไข หรือลบไฟล์ `.luau` ทั้งหมด ต้องทำผ่านไฟล์ใน `src/` ตามโครงสร้าง `default.project.json` แล้วให้ Rojo ซิงค์เข้า Studio อัตโนมัติ

2. **Roblox Studio MCP = Eyes, World Builder & Tester:**
   - **Context Inspection:** ส่องดูโครงสร้างใน `Workspace`, `StarterGui`, `Lighting` ตรวจสอบ Part, Hierarchy, Properties, Attributes ก่อนเขียนโค้ด
   - **3D & UI Manipulation:** เสกโมเดล, ปรับ CFrame, สี, วัสดุ, Attributes, Tags ในฉากที่ไม่ได้แปลงเป็นไฟล์ Rojo
   - **Command Bar Execution:** รันสคริปต์ One-off จัดระเบียบฉากหรือตั้งค่าเริ่มต้น
   - **Testing & Debugging:** สั่งรัน Playtest, ดึง LogService/Console ตรวจสอบ Error แล้วนำกลับมาแก้ที่ไฟล์ `.luau` ในเครื่อง

3. **Standard Execution Loop (Inspect ➡️ Prepare ➡️ Write ➡️ Verify):**
   - **Step 1 (Inspect - MCP):** เช็คโครงสร้าง Object ใน Studio
   - **Step 2 (Prepare Assets - MCP):** เตรียม Part, Attribute, Tag ใน Studio ให้พร้อม
   - **Step 3 (Write Code - Local / Rojo):** แก้ไขไฟล์ `.luau` บนเครื่อง
   - **Step 4 (Verify - MCP):** ตรวจสอบ Output ใน Studio หลัง Rojo ซิงค์เสร็จสิ้น

---

## 🛡️ 8. Roblox Pre-Flight Gate & Modern Luau Standards

ก่อนบันทึกไฟล์ `.luau` หรือแก้ไขสคริปต์ใน DataModel ต้องผ่านข้อบังคับต่อไปนี้ 100%:

### 1. Mandatory 3-Tool Pre-Flight Check:
ก่อนบันทึกไฟล์ทุกครั้ง ต้องรันคำสั่งตรวจสอบ:
* `stylua --check <path>` — ตรวจสอบ AST Syntax และโครงสร้างโค้ด
* `selene <path>` — Linter ตรวจสอบตัวแปรและไวยากรณ์ด้วยมาตรฐาน `std = "roblox"` (`selene.toml`)
* `luau-lsp analyze --definitions=globalTypes.d.luau <path>` — Type check และวิเคราะห์ API Roblox ล่าสุด
* หากเป็นการแก้สคริปต์ใน Studio ต้องผ่าน `loadstring(code, chunkName)` ก่อนเซฟลง `.Source` เสมอ

### 2. Luau Coding Commandments:
* **Entire Function Replacement:** ห้ามใช้ String Replace ตัดต่อเฉพาะเศษบรรทัดที่มีบล็อกซ้อนกัน ให้แทนที่ทั้งฟังก์ชันเสมอเพื่อป้องกัน `end` เกินหรือขาด
* **Guard Clauses:** ใช้ Guard Clauses (`if not condition then return end`) เพื่อลดการซ้อนของบล็อก และป้องกัน Deep Nesting
* **Strictly Modern Roblox APIs:**
  * ใช้ `task.wait(...)` แทน `wait()`
  * ใช้ `task.spawn(...)` หรือ `task.defer(...)` แทน `spawn()` หรือ `delay()`
  * ใช้ `workspace:Raycast(...)` แทน `Ray.new()` หรือ `FindPartOnRay()`
  * ใช้ `Model:PivotTo(...)` และ `Model:GetPivot()` แทน `SetPrimaryPartCFrame()`
  * ใช้ Physics Constraints (`VectorForce`, `AngularVelocity`, `AlignOrientation`, `SpringConstraint`, `HingeConstraint`, `WeldConstraint`) แทน BodyMovers ที่ Deprecated


