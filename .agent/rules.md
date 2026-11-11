---
project: HOKI TOWN
doc_type: agent-rules
version: 1.1.0
last_updated: 2026-11-11
tags:
  - agent-rules
  - governance
  - conventions
---

# 🤖 Agent Rules & Governance (HOKI TOWN)

Rules for AI agents working in the **HOKI TOWN** Roblox codebase and Obsidian vault.

## 1. Vault & Context Discipline
1. **Surgical Edits:** Preserve existing verified notes and scripts; stage new feature/architecture drafts in `10_Inbox/`.
2. **Empirical Grounding:** Verify Studio instances, remotes, and script paths before editing; never guess APIs or object hierarchies.
3. **Zero-Bloat Lookup:** Read `[[MOC]]` or `[[00_Master_Index]]` for vault discovery instead of bulk-reading `03_Scripts_Vault/`.
4. **Markdown Standards:** Include YAML frontmatter per `[[.agent/schema.md]]` and use Obsidian `[[Wikilinks]]` inside prose.
   - Naming: `FEAT_XX_PascalCase.md`, `ARCH_XX_PascalCase.md`, `ScriptName_Type.md`, `DRAFT_YYYY-MM-DD_Topic.md`, `kebab-case-concept.md`.

## 2. Hybrid Rojo + Studio MCP Boundary
*(Details in `.agents/skills/roblox-hybrid-rojo-studio/SKILL.md`)*
- **Rojo = Single Source of Truth for Code:** Edit `.luau` files exclusively under `src/` per `default.project.json`; never overwrite Rojo-managed `.Source` via Studio MCP.
- **Studio MCP = Eyes, 3D Assembly & Playtest:** Use MCP to inspect DataModel hierarchy/attributes, weld/arrange Studio 3D models, and run playtest telemetry checks (`Inspect -> Prepare -> Write -> Verify`).

## 3. Luau Code, Architecture & Pre-Flight Standards
*(Details in `.agents/skills/roblox-mvc-architecture/SKILL.md`, `luau-syntax-guardian/SKILL.md`, and `roblox-vehicle-scripting/SKILL.md`)*
- **Architecture & Assets:** Use MVC (`Controller`/`Model`/`View`/`Gateway`) + `Init()`/`Destroy()` lifecycle for new gameplay, UI, and backend systems; keep vehicle physics loops direct. Use hand-authored Studio assets via `WaitForChild("ExactName")` instead of procedural UI trees unless requested.
- **Security:** Validate player permissions, distance (`Magnitude < 15`), and payloads on the Server; never trust client `RemoteEvent` arguments.
- **Safety & Hygiene:** Use `--!strict` / type annotations on new modules, guard clauses, `Disconnect()` connections + `task.cancel()` owned threads on `Destroy()`, avoid per-frame allocations/redundant `.Text` updates, and use modern APIs (`task.wait`, `task.spawn`, `task.defer`, `workspace:Raycast`, `PivotTo`, physics constraints).
- **Pre-Delivery Audit & Handback:** Check YAGNI, sibling callers, cleanup, and type safety; for new features, report **Runtime Flow**, **Manual Studio Setup**, and **Follow-up Steps**.
- **Incremental Pre-Flight:** Run `scripts/preflight.ps1` (auto-checks changed `.luau` files via `stylua --check`, `selene`, and `luau-lsp analyze`) instead of scanning the entire `src/` tree.
