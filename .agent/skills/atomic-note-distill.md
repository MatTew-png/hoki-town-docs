---
skill_name: atomic-note-distill
version: 1.0.0
author: HOKI TOWN Architecture Team
description: สกัดเนื้อหาทางเทคนิคที่ซับซ้อนให้กลายเป็นโน้ตย่อยแบบอะตอม (Atomic Note) เพื่อให้ Agent ประหยัด Token ในการอ่าน
---

# 🛠️ Skill: Atomic Note Distillation

## 🎯 Input Schema
- `source_doc`: เอกสารต้นฉบับขนาดยาว (เช่น VEHICLE_MASTER_DEVELOPMENT_MANUAL หรือ ARCH_01)
- `topic`: หัวข้อเฉพาะที่ต้องการสกัด (เช่น "Tap-to-Drift Physics Formula" หรือ "Session Locking")

## 📋 Rules
1. **Single Responsibility:** โน้ตย่อย 1 ไฟล์ต้องอธิบายเพียงคอนเซปต์เดียวเท่านั้น
2. **Concise Length:** ความยาวไม่ควรเกิน 50 บรรทัด
3. **Strong Wikilinks:** ต้องมีลิงก์ย้อนกลับไปยังเอกสารแม่และ MOC เสมอ
4. บันทึกลงใน `10_Inbox/` ก่อนเสมอ
