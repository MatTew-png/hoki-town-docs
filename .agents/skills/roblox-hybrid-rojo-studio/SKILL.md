---
name: roblox-hybrid-rojo-studio
description: Manage hybrid Roblox workflows where 3D models live in Studio while Luau scripts sync from disk via Rojo. Use when editing default.project.json around Studio MeshParts, pairing model-scoped Client RunContext scripts with .meta.json, hardening scripts for StreamingEnabled, verifying runtime state via Studio MCP, or preparing clean git commits.
---

# Roblox Hybrid Rojo + Studio Workflow

Patterns for projects where **Rojo owns Luau source on disk (`src/`)** while **3D assemblies, MeshParts, and UI layouts live in Roblox Studio** (complementary to `roblox-toolchain`).

## 1. Lock the 3D / Code Boundary in `default.project.json`

- **Protect Studio 3D Assets**: Set `"$ignoreUnknownInstances": true` on `Workspace`, every hybrid `Model` (e.g., vehicles, props), and any Studio-designed `ScreenGui` whose visual children are not on disk. Without it, Rojo deletes Studio `Body`, `Wheels`, `DriveSeat`, and `WeldConstraint` trees on sync.
- **Single Source of Truth for Scripts**: Edit all managed `.luau` scripts exclusively on disk under `src/` and let `rojo serve` sync them into Studio. Use Studio MCP (`run_code` / `run_script_in_play_mode`) strictly for inspection, 3D assembly/welding, and playtest telemetry—never overwrite Rojo-managed `.Source` inside Studio.
- **Verify Sync Integrity**: Run `rojo sourcemap default.project.json -o sourcemap.json` and `rojo build --output scratch/test_build.rbxm` after any `default.project.json` or file rename change.

## 2. Model-Scoped Client Scripts (`RunContext`)

- LocalScripts directly under `Workspace` models do not execute reliably across cloning/ownership flows. To keep a client script bundled inside a `Workspace` vehicle or prop model:
  1. Name the source `<ScriptName>.server.luau` (or map via `.meta.json`).
  2. Pair it with `<ScriptName>.meta.json`:
     ```json
     {
       "properties": {
         "RunContext": "Client"
       }
     }
     ```
  3. Remove the stale `.client.luau` file and regenerate `sourcemap.json` so `luau-lsp` resolves the new `RunContext`.
- **Multi-Client Guard**: Because `RunContext: Client` runs for every client in the server, gate vehicle control loops on `seat.Occupant == localCharacter.Humanoid` before claiming input or physics control.

## 3. StreamingEnabled & Connection Hygiene

- **Keep Active Physics Models Streamed**: On server initialization for controllable vehicles or large contraptions, set:
  ```luau
  pcall(function()
      model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
  end)
  ```
- **Streaming-Safe Lookup**: On client startup, wait with bounded timeouts (`car:WaitForChild("DriveSeat", 15)` or polling `FindFirstChild(name, true)` with `task.wait(0.1)` up to a deadline), returning cleanly if `car.Parent == nil` before streaming finishes.
- **Deterministic Cleanup**: Track every `RBXScriptConnection` (`RunService`, `UserInputService`, `Occupant`, UI buttons) in a per-instance connection list and disconnect all of them in a shared `cleanup()` bound to `model.Destroying` and `model.AncestryChanged` (`Parent == nil`).

## 4. MCP Playtest & Clean Git Preflight

- **Telemetry Over Guesswork**: Verify fixes in Play Mode (`run_script_in_play_mode`) by printing measurable state (grounded wheel count, assembly velocity, hinge `CurrentAngle`, attribute values) rather than guessing parameters.
- **Keep Temporary Artifacts Out of Git**: Keep debug dumps, `.rbxl`/`.rbxm` test builds, raw `.blend`/`.fbx` binaries, and one-off probe scripts inside `scratch/` or `.gitignore` before committing and pushing.
