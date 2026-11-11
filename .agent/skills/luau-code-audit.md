---
skill_name: luau-code-audit
version: 1.0.0
author: HOKI TOWN Architecture Team
description: ตรวจสอบและประเมินคุณภาพของโค้ด Luau ในเกม Roblox เพื่อหาช่องโหว่ด้านความปลอดภัย การกิน CPU และ Memory Leaks
---

# 🛠️ Skill: Luau Code & Architecture Audit

## 🎯 Input Schema
- `script_path`: ตำแหน่งของไฟล์สคริปต์ใน `03_Scripts_Vault/` หรือใน DataModel
- `context`: วัตถุประสงค์และการทำงานของสคริปต์

## 📋 Evaluation Checklist
1. **Security & Anti-Exploit:** มีการตรวจสอบระยะทาง (`Magnitude`), สิทธิ์ของผู้เล่น และ Sanitize Arguments ใน RemoteEvents หรือไม่
2. **Physics & Performance:** มี Part ลอยที่ไม่ได้ Anchor หรือ Weld ที่ขัดแย้งกับล้อหรือไม่
3. **Signal Disconnection:** มีการล้าง `RBXScriptConnection` เมื่อตัวละครลงจากรถหรือตายหรือไม่
4. **DataModel Coupling:** โค้ดฝังอยู่ใน Workspace หรือถูกออกแบบแยกขึ้น `ServerScriptService`

## 📤 Output Format
- **Severity Rating:** 🟢 Pass | 🟡 Warning | 🔴 Critical Risk
- **Identified Issues:** จุดบกพร่องพร้อมหมายเลขบรรทัด
- **Recommended Luau Refactor:** โค้ดฉบับปรับปรุงที่ Type-safe และสะอาด
