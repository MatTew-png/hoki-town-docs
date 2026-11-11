---
name: luau-syntax-guardian
description: Zero-Syntax-Error Protocol, 3-Tool Pre-Flight Validation Gate (StyLua + Selene + Luau-LSP), and Modern Roblox API Standards for Luau scripts.
---

# 🛡️ Luau Syntax Guardian & Pre-Flight Gate

This skill enforces a mandatory 3-Tool Pre-Flight Verification Gate and modern architectural coding rules before ANY `.luau` script or Roblox Studio script `.Source` can be modified or committed.

---

## 🔒 1. Mandatory 3-Tool Pre-Flight Verification Gate

Before committing any `.luau` file or assigning to `script.Source`, the script MUST pass all 3 tools without errors:

```bash
# 1. Format & AST Syntax Integrity Check
stylua --check <filePath>

# 2. Strict Roblox Linter (Scope, undefined variables, multiple statements)
selene <filePath>

# 3. Static Type Analysis & API Verification (using official definitions)
luau-lsp analyze --definitions=globalTypes.d.luau <filePath>
```

### In-Memory `.Source` Gate (when applying in Roblox Studio)
Before writing to `script.Source` in Studio:
```lua
local fn, compileErr = loadstring(newSource, chunkName)
if not fn then
    error("[PRE-FLIGHT GATE BLOCKED] Syntax error detected before saving: " .. tostring(compileErr))
end
```
> [!IMPORTANT]
> If ANY of the 3 checks or `loadstring` fails, the edit is **BLOCKED**. Fix the root cause and re-verify before proceeding.

---

## 📜 2. Luau Coding & Refactoring Commandments

### A. Entire Function Replacement (No Fragment Splicing)
* **NEVER** use regex or string substitution on partial sub-blocks containing nested `if`, `for`, `while`, or `function`.
* **ALWAYS** replace the **entire function** from its signature down to its closing `end`.
* Replacing the complete function boundary ensures that keyword pairs (`then...end`, `do...end`) are always mathematically balanced.

### B. Guard Clauses First (Early Returns)
* Prevent deep nesting (Pyramid of Doom) by inverting conditions into Guard Clauses:
  ```lua
  -- ❌ AVOID: Deep nested blocks
  local function onTouch(hit)
      if hit then
          local char = hit.Parent
          if char then
              local hum = char:FindFirstChildOfClass("Humanoid")
              if hum then
                  -- logic buried 4 tabs deep
              end
          end
      end
  end

  -- ✅ PREFERRED: Guard Clauses
  local function onTouch(hit: BasePart)
      if not hit then return end
      local char = hit.Parent
      if not char then return end
      local hum = char:FindFirstChildOfClass("Humanoid")
      if not hum then return end

      -- logic remains at root indentation
  end
  ```

### C. Strictly Modern Roblox APIs (Zero Deprecation)
* Use `task.wait(...)` — **NEVER** legacy `wait()`
* Use `task.spawn(...)` or `task.defer(...)` — **NEVER** legacy `spawn()` or `delay()`
* Use `workspace:Raycast(...)` — **NEVER** `Ray.new()` or `FindPartOnRay()`
* Use `model:PivotTo(...)` and `model:GetPivot()` — **NEVER** `SetPrimaryPartCFrame()`
* Use **Physics Constraints** (`VectorForce`, `AngularVelocity`, `AlignOrientation`, `SpringConstraint`, `HingeConstraint`, `WeldConstraint`) — **NEVER** deprecated BodyMovers (`BodyVelocity`, `BodyGyro`, `BodyPosition`, `BodyThrust`)

---

## ⚙️ 3. Project Configuration Reference

* **Definitions:** `globalTypes.d.luau` (Official Roblox definitions from `luau-lsp`)
* **Linter Config:** `selene.toml` with `std = "roblox"`
* **Formatter Config:** `.stylua.toml` or default StyLua rules
