---
project: HOKI TOWN
doc_type: schema-definition
version: 1.0.0
last_updated: 2026-11-07
tags:
  - schema
  - frontmatter
  - validation
---

# 📋 Frontmatter Metadata Schema

ข้อกำหนด Schema สำหรับข้อมูลหัวเรื่อง (Properties / YAML Frontmatter) ของเอกสารแต่ละประเภทใน HOKI TOWN Vault

---

## 1. Feature Deep Dive Schema (`01_Features_Deep_Dive/`)

```yaml
---
project: HOKI TOWN             # string (Required)
feature_id: VEH-01B           # string (Required, format: [AREA]-[NUM])
category: feature-deep-dive    # string (Required)
system: cdt-arcade-overhaul    # string (Required)
datamodel_location: "Workspace.TeslaRoadster" # string (Roblox Instance Path)
status: completed              # enum: [completed, in-progress, prototype, planned]
priority: critical            # enum: [critical, high, medium, low]
last_audit: 2026-11-04         # date (YYYY-MM-DD)
tags:                          # array of strings
  - vehicle-system
  - cdt-arcade
---
```

---

## 2. Technical Architecture Schema (`02_Technical_Architecture_Handover/`)

```yaml
---
project: HOKI TOWN             # string (Required)
category: architecture         # string (Required)
doc_type: refactoring-roadmap  # string: [architecture-audit, refactoring-roadmap, network-spec]
status: in-progress            # enum: [active, in-progress, documented, planned]
priority: critical            # enum: [critical, high, medium, low]
last_audit: 2026-11-04         # date (YYYY-MM-DD)
tags:
  - architecture
  - refactor
---
```

---

## 3. Scripts Vault Schema (`03_Scripts_Vault/`)

```yaml
---
project: HOKI TOWN             # string (Required)
script_name: VehicleSystems_Server # string (Required)
script_type: Script (Server)   # enum: [LocalScript, Script (Server), ModuleScript]
datamodel_location: "Workspace.TeslaRoadster.VehicleSystems" # string
lines_of_code: 511             # integer
verified_status: passed        # enum: [passed, tested, draft, obsolete]
tags:
  - server-script
  - production-code
---
```
