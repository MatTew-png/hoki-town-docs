---
project: HOKI TOWN
category: index
doc_type: git-setup-guide
last_audit: 2026-11-04
tags:
  - git
  - obsidian-git
  - backup-strategy
  - version-control
  - collaboration
---

# 🐙 คู่มือการใช้งาน Git กับ Obsidian Vault (HOKI TOWN)

> **เป้าหมาย:** ซิงค์ข้อมูลเอกสาร คลังสคริปต์ แผนผัง Canvas และ Excalidraw ขึ้น GitHub / Git Remote อัตโนมัติ ป้องกันข้อมูลสูญหาย และรองรับการทำงานร่วมกันในทีม

---

## 1. การติดตั้งและตั้งค่า Obsidian Git Plugin #obsidian-git

### ขั้นตอนที่ 1: ติดตั้งปลั๊กอิน
1. เปิด Obsidian -> ไปที่ **Settings** (`Ctrl + ,`)
2. คลิกหัวข้อ **Community plugins** -> กด **Turn on community plugins** (ถ้ายังไม่ได้เปิด)
3. ค้นหา `Obsidian Git` (โดย Vinzent03) -> คลิก **Install** แล้วกด **Enable**

### ขั้นตอนที่ 2: ตั้งค่าการแบ็กอัปอัตโนมัติ (Recommended Settings)
- **Vault backup interval (minutes):** ตั้งเป็น `10` หรือ `30` นาที (ระบบจะ Git Commit & Push อัตโนมัติเมื่อถึงเวลา)
- **Auto backup after file change:** ปิด `OFF` (เพื่อไม่ให้ Commit ถี่เกินไป)
- **Commit message format:** `vault backup: {{date}} ({{hostname}})`
- **Auto pull interval (minutes):** ตั้งเป็น `10` หรือ `30` นาที
- **Auto Pull on startup:** เปิด `ON` (ดึงโค้ดและเอกสารล่าสุดทันทีที่เปิด Obsidian)
- **Disable push:** ปิด `OFF` (อนุญาตให้ Push ขึ้น GitHub อัตโนมัติ)

---

## 2. สิ่งที่ `.gitignore` ควบคุมและกรองออก #gitignore

เพื่อป้องกันการขัดแย้ง (Merge Conflict) ของเลย์เอาต์หน้าจอแต่ละเครื่อง `.gitignore` ได้รับการกำหนดค่าให้:
- **ละเว้นไฟล์เฉพาะเครื่อง:** `.obsidian/workspace.json`, `.obsidian/workspace-mobile.json`, `.obsidian/cache/`, `.trash/`
- **บันทึกการตั้งค่าส่วนกลาง:** `.obsidian/core-plugins.json`, `.obsidian/appearance.json`, `.obsidian/community-plugins.json`, ธีม และ Hotkeys

---

## 3. สคริปต์ซิงค์แบบ 1-Click (Manual Backup Scripts) #scripts

หากไม่ต้องการรอรอบอัตโนมัติของปลั๊กอิน สามารถกดรันสคริปต์ซิงค์ได้ทันที:

### สำหรับ Windows (PowerShell):
```powershell
powershell -ExecutionPolicy Bypass -File .\sync_vault.ps1
```

### สำหรับทุกระบบปฏิบัติการ (Python):
```bash
python sync_vault.py
```

---

## 4. แนะนำขั้นตอนการแก้ไขเมื่อเกิด Merge Conflict #troubleshooting
1. หากเปิดโน้ตขึ้นมาแล้วพบเครื่องหมาย `<<<<<<< HEAD` ให้เลือกเนื้อหาส่วนที่ถูกต้อง
2. บันทึกไฟล์ และใช้คำสั่ง `git add <filename>`
3. ทำการ Commit ด้วยข้อความ `git commit -m "fix: resolve merge conflict"`
4. กด `git push` เพื่อนำขึ้น Remote
"""}
