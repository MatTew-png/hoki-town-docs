# Handoff: Tesla Roadster Modular & Animation Pipeline

> **Date:** 2026-11-08  
> **Topic:** HOKI TOWN - Tesla Roadster Modular Overhaul, R15 Animation & Customization Architecture  
> **Status:** ✅ Authentic Door Open/Close Animation & Bisect Extraction Completed (Verified via GIF & FBX)

---

## 🎯 1. Goal
Complete the production implementation of the modular Tesla Roadster in Roblox Studio:
1. Import `Tesla_Roadster_Enter_Animation.fbx` / `Tesla_Roadster_Modular.fbx` into Roblox Studio.
2. Wire the R15 Enter/Exit Vehicle sequence with the $45^\circ$ fail-safe door swing and calibrated seated driving pose (hands on steering wheel at 9 and 3 o'clock).
3. Implement the 5-slot color customization module with grayscale PBR tinting (`Body`, `Seats`, `Console`, `Calipers`, `Rims`).
4. Wire the 7-parameter ECU Tuner Attributes and 3 approved features (Digital Dashboard on `Center_Screen`, RGB Underglow, Official License Plate sync).

---

## 📊 2. Current State (What Has Been Done & Verified)

### A. Wheel Alignment & Root Cause Solved
* Wheel drift was caused by manual edit mode displacement ($+0.80\text{ studs}$ in Y, $-0.70\text{ studs}$ in Z).
* Reset to canonical Day 1 coordinates in `TeslaRoadster`:
  - `FL`: `(-2.767, -0.851, -4.662)`
  - `FR`: `( 2.743, -0.851, -4.662)`
  - `RL`: `(-2.767, -0.792,  5.008)`
  - `RR`: `( 2.743, -0.851,  5.008)`

### B. Blender 5.2 Toolchain & Installed Skills
* **Installed Addon:** Cautioned's `rbx_anims` v3.1.3 (RBXMonkey) active in Blender 5.2.3 LTS.
* **Installed Agent Skills:**
  - `animate-roblox-characters` (`dillydog580`): Installed in `~/.gemini/config/skills/` and `.agents/skills/`.
  - `blender-modeling` (`MAX-786`, Grade A): Installed in `~/.gemini/config/skills/` and `.agents/skills/`.
  - `blender-skills` (`arjun988`, 95 skills): Stored in `~/.agent-sync/vault/blender-skills/` with core skills exposed.
  - *Audit Verdict:* `terminalskills-skills-blender-3d-modeling` was audited and rejected (shallow/redundant).

### C. 3D Model & Dual Door Animation (Production Solid Option A)
* **Doors:** `Door_FL` and `Door_FR` built as $100\%$ Solid / Watertight Closed Meshes (Outer Paint Skin + $0.12\text{m}$ Rubber Door Lip + Custom Ergonomic Inner Door Card with armrest bolster and aluminum release lever).
* **Windows:** `Window_FL` and `Window_FR` extracted as independent meshes, hinge-aligned and parented to doors.
* **Door Jambs:** Extruded $0.16\text{m}$ inward from body apertures and sealed to interior chassis tub ($0\%$ see-through holes).
* **Hinge Pivots:** Set to exact A-pillar axes (FL: `(2.75, 28.10, 3.30)`, FR: `(9.25, 28.10, 3.30)`).
* **Action:** `Tesla_Roadster_Dual_Doors_Open_Close` (90 frames, synchronized latch pop, $48^\circ$ swing, hold, and rubber compression lock).
* **Production Files:**
  - `C:\Users\_newgen\Downloads\Tesla_Roadster_Modular.blend` & `.fbx`
  - `C:\Users\_newgen\Downloads\Tesla_Roadster_Dual_Door_Animation.blend` & `.fbx`
  - `C:\Users\_newgen\.gemini\antigravity\brain\cad127cd-9b1b-4acb-ae26-9132b44d5e7f\tesla_dual_doors_open_close_preview.gif`

---

## ❓ 3. Key Decisions & Open Questions
1. **Interaction Prompt:** Trigger the enter sequence via `ProximityPrompt` on the driver door handle [E] or automatic seat detection. (ProximityPrompt recommended for GTA/FiveM realism).
2. **Chassis Selection:** Confirm whether to package into lightweight Raycast Arcade Chassis or continue with A-Chassis.

---

## 📁 4. Relevant Artifacts & Files
* **Master Specification Artifact:**  
  `C:\Users\_newgen\.gemini\antigravity\brain\b7f5baef-815b-47b5-b518-2fa4e83b4720\HOKI_TOWN_Vehicle_Architecture_And_Customization_Spec.md`
* **Blender Animation Blend:**  
  `C:\Users\_newgen\Downloads\Tesla_Roadster_Enter_Animation.blend`
* **Blender Animation FBX:**  
  `C:\Users\_newgen\Downloads\Tesla_Roadster_Enter_Animation.fbx`
* **Modular Car Model:**  
  `C:\Users\_newgen\Downloads\Tesla_Roadster_Modular.blend` & `.fbx`
* **Texture Maps:**  
  `C:\Users\_newgen\Downloads\Plane0015_*.png`, `Plane0031_*.png`, `Plane0041_*.png`
* **Studio Live Workspace:**  
  Connected via Rojo (PID 13324, port 34872) and `Roblox_Studio` MCP. Models: `TeslaRoadster`, `TeslaRoadster_Day1`, `TeeraRoadster_Original_Model`, `TestRig_R15`.

---

## ⏭️ 5. Suggested Next Skill & Starting Move
* **Skill:** `roblox-vault-router` / `gamedev-vault-router`
* **Starting Move:** Import `Tesla_Roadster_Enter_Animation.fbx` into Roblox Studio via 3D Importer, load the AnimationTrack on `Humanoid`, set `Priority = Enum.AnimationPriority.Action`, and wire `ProximityPrompt` on `Door_Driver`.
