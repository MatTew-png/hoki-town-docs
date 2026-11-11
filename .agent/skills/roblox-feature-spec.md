---
skill_name: roblox-feature-spec
version: 1.0.0
author: HOKI TOWN Architecture Team
description: ร่างข้อกำหนดและโครงสร้างฟีเจอร์ใหม่ของ HOKI TOWN ให้พร้อมสำหรับการพัฒนาและทดสอบบน Studio Sandbox
---

# 🛠️ Skill: Roblox Feature Specification Drafter

## 🎯 Input Schema
- `feature_name`: ชื่อฟีเจอร์ (ภาษาไทยและอังกฤษ)
- `category`: ยานพาหนะ (Vehicles) / อาชีพและฟาร์ม (Jobs) / สภาพแวดล้อม (World)
- `core_loop`: รูปแบบการเล่นและผลตอบแทนที่ผู้เล่นได้รับ

## 📋 Execution Steps
1. ดึงโครงสร้างมาตรฐานจาก `Templates/Template_New_Feature.md`
2. กำหนดรหัสฟีเจอร์ (`FEAT_XX` / `JOB_XX`)
3. วางผังอ็อบเจ็กต์ใน DataModel และข้อกำหนด RemoteEvents
4. ระบุขั้นตอนการทดสอบบน Studio Sandbox แบบแยกส่วน (Isolated Testing)
5. บันทึกไฟล์ดราฟต์ลงใน `10_Inbox/DRAFT_[Date]_[FeatureName].md` เพื่อรอการรีวิว

## 📤 Output Format
- ไฟล์ Markdown ใน `10_Inbox/` พร้อม Frontmatter ที่สมบูรณ์
