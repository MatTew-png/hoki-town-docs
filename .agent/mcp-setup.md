---
project: HOKI TOWN
doc_type: mcp-setup-guide
version: 1.0.0
last_updated: 2026-11-07
tags:
  - mcp
  - model-context-protocol
  - ai-tools
  - integrations
---

# 🔌 Obsidian Model Context Protocol (MCP) Integration Guide

การเชื่อมต่อ Obsidian Vault ของ **HOKI TOWN** เข้ากับ AI Agents ผ่านโปรโตคอล **MCP (Model Context Protocol)** ช่วยให้ Agent สามารถสืบค้น ค้นหา Backlinks และอ่านโน้ตแบบ Atomic ได้โดยตรงโดยไม่สิ้นเปลือง Token

---

## 1. เซิร์ฟเวอร์ MCP ที่รองรับ (Supported Obsidian MCP Servers)

1. **`calclavia/mcp-obsidian`** (Official Community Adapter):
   - รองรับการเข้าถึง Vault ผ่าน Local REST API หรือ Filesystem
   - มีคำสั่งหลัก: `read_note`, `search_notes`, `get_backlinks`, `patch_note`, `list_tags`

2. **`obsidian-context-server`**:
   - ปรับแต่งสำหรับการสร้าง Knowledge Graph และค้นหาความสัมพันธ์ของไฟล์ใน Vault

---

## 2. วิธีการติดตั้งและตั้งค่า (Setup Configuration)

### ตัวเลือกที่ 1: ผ่าน npx (Filesystem Direct Access)
เพิ่มในไฟล์คอนฟิก MCP ของ Client (เช่น Claude Desktop หรือ Cursor `claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "hoki-town-vault": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-obsidian",
        "C:\\Users\\_newgen\\Documents\\antigravity\\HOKI TOWN"
      ]
    }
  }
}
```

### ตัวเลือกที่ 2: ผ่าน Obsidian Local REST API Plugin
1. ติดตั้งปลั๊กอิน **Local REST API** ใน Obsidian
2. ดึง API Key จากหน้า Settings
3. กำหนดค่า MCP ให้เชื่อมต่อผ่านพอร์ต HTTPS `https://127.0.0.1:27124`

---

## 3. Best Practices ในการสั่งงานผ่าน MCP
- **Targeted Lookups:** สั่งให้ Agent ใช้ `search_notes` ค้นหาผ่าน Tags เช่น `#vehicle-system` แทนการอ่านไฟล์ทั้งหมด
- **Backlink Traversal:** ใช้ `get_backlinks` เพื่อตรวจสอบว่าฟีเจอร์หนึ่งส่งผลกระทบต่อสคริปต์ใดบ้าง ก่อนทำการแก้ไขโค้ด
