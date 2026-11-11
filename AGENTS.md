# 🤖 Agent Operational Instructions for HOKI TOWN

Roblox codebase (`src/`, `default.project.json`) + Obsidian Knowledge Vault for **HOKI TOWN**.

## Context Pointers (Read On Demand)
- **Vault Governance & Conventions:** `[[.agent/rules.md]]` (read when editing Obsidian notes/frontmatter)
- **Frontmatter Schema:** `[[.agent/schema.md]]` (read when creating/updating Vault Markdown)
- **Vault Map & Legacy Audit:** `[[MOC.md]]` / `[[01_Project_Status_Audit]]` (consult only for vault navigation or DataModel audit; for active scripts inspect `src/` and `default.project.json` directly)
- **Project Skills:** `.agents/skills/` (`roblox-vehicle-scripting`, `roblox-hybrid-rojo-studio`, `luau-syntax-guardian`, `roblox-3d-rigging-vehicles`, `roblox-toolchain`)

## Key Commandments
1. **Surgical Edits Only:** Never overwrite verified notes/scripts without confirmation; stage new vault drafts in `10_Inbox/`.
2. **Obsidian Hygiene:** Maintain YAML frontmatter and `[[Wikilinks]]` on Vault `.md` files.
3. **Strict Hybrid Workflow (Rojo + MCP):** Rojo (`src/`) is the Single Source of Truth for all `.luau` scripts. Never mutate Rojo-managed script `.Source` via MCP; use MCP strictly for inspection, 3D assembly, and playtest verification.
4. **Fast Targeted Checks:** Run `powershell -File scripts/preflight.ps1` (checks only modified `.luau` files) instead of full-tree lint sweeps.
