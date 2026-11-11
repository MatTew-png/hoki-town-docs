---
project: HOKI TOWN
category: documentation
doc_type: setup-guide
tags:
  - templater
  - setup-guide
  - obsidian-configuration
---

# 🛠️ คู่มือการตั้งค่า Templater Plugin ใน Obsidian

เพื่อให้การสร้างเอกสารฟีเจอร์ สคริปต์ และสถาปัตยกรรมใหม่เป็นไปตามมาตรฐานเดียวกัน แนะนำให้ตั้งค่าปลั๊กอิน **Templater** ใน Obsidian ดังนี้:

### 1. การติดตั้ง Templater
1. เปิด Obsidian Settings (`Ctrl + ,` หรือไอคอนฟันเฟือง)
2. ไปที่หัวข้อ **Community plugins** -> ค้นหา `Templater`
3. คลิก **Install** และกด **Enable**

### 2. การตั้งค่าโฟลเดอร์เทมเพลต (Settings)
- **Template folder location:** กำหนดเป็น `Templates`
- **Enable User System Command:** เปิดเป็น `ON` (เพื่อให้รองรับการประมวลผลวันที่และ Prompt)
- **Trigger Templater on new file creation:** เปิดเป็น `ON` (ทางเลือกเสริม)

### 3. เทมเพลตมาตรฐานที่มีให้ใช้งาน
1. `Templates/Template_New_Feature.md` — สำหรับสร้างเอกสารฟีเจอร์ใหม่ใน `01_Features_Deep_Dive`
2. `Templates/Template_New_Script.md` — สำหรับบันทึกและจัดเก็บสคริปต์ใหม่ใน `03_Scripts_Vault`
3. `Templates/Template_New_Architecture_ADR.md` — สำหรับบันทึกการตัดสินใจทางสถาปัตยกรรม (ADR)
