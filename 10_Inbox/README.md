---
project: HOKI TOWN
category: intake
doc_type: inbox-protocol
tags:
  - inbox
  - staging
  - raw-intake
  - review-workflow
---

# 📥 10_Inbox — Raw Intake & AI Draft Staging

> **วัตถุประสงค์:** ใช้เป็นพื้นที่ปลอดภัย (Sandbox Staging) สำหรับบันทึกโน้ตดิบ ไอเดียใหม่ หรือเอกสารที่ AI Agent ร่างขึ้นมา ก่อนที่จะผ่านการตรวจสอบโดยมนุษย์และย้ายเข้าสู่โฟลเดอร์ถาวร

---

## 🛡️ Staging Workflow (กระบวนการคัดกรอง)

```mermaid
flowchart LR
    AI[🤖 AI Agent / ไอเดียดิบ] -->|บันทึกดราฟต์| Inbox[📥 10_Inbox/]
    Inbox -->|มนุษย์ตรวจสอบ & ปรับปรุง| Review{ผ่านการตรวจสอบ?}
    Review -->|ใช่: ย้ายสู่ถาวร| Vault[📂 01_Features / 02_Architecture]
    Review -->|ไม่: ยกเลิก/แก้ไข| Archive[🗑️ 90_Archive/]
```

---

## 📝 กฎการตั้งชื่อไฟล์ใน Inbox
- เอกสารที่ AI ร่าง: `DRAFT_YYYY-MM-DD_TopicName.md`
- โน้ตย่อหรือไอเดียดิบ: `INBOX_TopicName.md`
