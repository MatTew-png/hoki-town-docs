---
project: HOKI TOWN
category: architecture
doc_type: architecture-decision-record
adr_id: "<% tp.user.prompt ? await tp.system.prompt('ระบุรหัส ADR (เช่น ADR-01, ADR-02):', 'ADR-XX') : 'ADR-XX' %>"
status: proposed
decision_date: "<% tp.date.now('YYYY-MM-DD') %>"
tags:
  - architecture
  - adr
  - technical-decision
  - refactor
---

# 🏛️ <% tp.frontmatter.adr_id %>: <% tp.file.title %>

> **สถานะ:** 🟡 อยู่ระหว่างพิจารณา (Proposed)  
> **วันที่บันทึกข้อตกลง:** `<% tp.frontmatter.decision_date %>`  
> **ผลกระทบต่อระบบ:** [[ARCH_01_Predecessor_Architecture_Audit|🔍 สถาปัตยกรรมเดิม]] -> [[ARCH_02_Target_Refactoring_Roadmap|🚀 แผนการปรับปรุง]]

---

## 1. บริบทและปัญหาที่ต้องตัดสินใจ (Context & Problem Statement) #context
- ปัญหาที่พบในระบบปัจจุบันคืออะไร?
- ทำไมสถาปัตยกรรมเดิมถึงไม่ตอบโจทย์การขยายตัว (Scalability) หรือความปลอดภัย?

---

## 2. ทางเลือกที่พิจารณา (Considered Options) #options
1. **ทางเลือก A:** ... (ข้อดี / ข้อเสีย)
2. **ทางเลือก B:** ... (ข้อดี / ข้อเสีย)

---

## 3. มติและข้อสรุปทางสถาปัตยกรรม (Decision Outcome) #decision
- **การตัดสินใจ:** เลือกทางเลือก ...
- **เหตุผลหลัก:** ...

---

## 4. ผลกระทบและการเปลี่ยนแปลงที่ต้องทำ (Consequences & Action Items) #tasks
- [ ] ย้ายสคริปต์ที่เกี่ยวข้องไปยัง `ServerScriptService` หรือ `ReplicatedStorage`
- [ ] สร้างหรือปรับเปลี่ยน RemoteEvents ที่เกี่ยวข้อง
- [ ] อัปเดตเอกสารใน [[00_Master_Index]]
