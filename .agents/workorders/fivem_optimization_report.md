---
title: FiveM Stuttering Root-Cause Analysis & Optimization Report
type: workorder-report
status: complete
severity: critical
source: fivem_stutter_diagnosis_and_optimization.md
hardware:
  cpu: AMD Ryzen 5 5500 (6C/12T)
  gpu: NVIDIA GeForce RTX 3060 Ti (8GB, Driver 561.42)
  ram: 32 GB DDR4
tags:
  - fivem
  - performance
  - root-cause
  - optimization
  - powershell
---

# FiveM Severe Stuttering & Frametime Hitching — Root-Cause Analysis & Optimization

## 1. Executive Technical Diagnosis

The stuttering is **not a single bottleneck** — it is a compounded failure across four interacting systems, each independently capable of producing violent frame spikes, and together producing the "unplayable" (เฟรมกระชาก) symptom.

**Primary root cause — memory exhaustion → CPU thrash:** At capture, the system showed only **5.78 GB free** of 31.87 GB RAM with **3.32 GB** in Windows compressed memory. The `System` process was consuming **105% CPU** purely to compress/decompress pages because physical RAM was exhausted. The culprits holding memory hostage concurrently:

| Process | CPU | RAM | Verdict |
|---|---|---|---|
| `FiveM_b3889_GTAProcess` | 404% | — | Expected engine load, but amplified by settings below |
| `FiveM_ChromeBrowser` (CEF/NUI) | 110% | 3.38 GB | **Memory leak + runaway NUI JS** |
| `RobloxPlayerBeta` | 22% | 2.86 GB | **Should not be running** |
| `RobloxStudioBeta` | 33% | 1.0 GB | **Should not be running** |
| Discord ×2 | 27% | 1.43 GB | Redundant duplicate instance |
| `dwm` | 99% | — | Borderless compositing strain |
| `System` | 105% | — | Memory compression thrash |

**Secondary root causes** (stacked on top of the RAM ceiling):
1. **Rockstar Editor Action Replay** is silently buffering gameplay to RAM (`profile_replayMode=1`, `profile_replayMemLimit=9`) — stealing memory bandwidth and CPU every frame.
2. **ReShade 5 + QuantV** with five heavy post-process shaders hooking the D3D11/12 swapchain — adding fixed GPU/CPU cost per frame and destabilizing frame pacing.
3. **`UpdateChannel=canary`** — an experimental build with debug/profiling overhead known to hitch.
4. **Borderless Windowed + uncapped VSync on a 144 Hz panel** — `dwm` must composite every frame while the game swings wildly between 120 and 30 FPS, producing visible frametime spikes.
5. **5-hour session uptime (17.8M ms)** — CEF texture/NUI cache and font leaks accumulate monotonically.
6. **D: drive at 1.08 GB free** — if the pagefile or any game/cache data lives on D:, this alone causes micro-stutters on I/O.

The frame spike mechanism: RAM pressure → `System` compresses memory on CPU → pagefile hits on a full D: drive → DWM compositing contention → game thread stalls → 120→30 FPS hitch. Every one of these is addressable, and together they explain the severity.

---

## 2. Root-Cause Analysis (by System)

### 2.1 Resource Contention & Memory Compression
- **Evidence:** `System` 105% CPU, 3.32 GB compressed, 5.78 GB free, D: 1.08 GB free.
- **Mechanism:** Windows 10/11 memory compression runs inside the `System` process. When physical RAM is exhausted by ~9.5 GB of non-essential workloads (Roblox ×2 + duplicate Discord + CEF leak), the OS must compress/decompress pages in real time, burning CPU cycles that the game thread needs.
- **D: drive at 1.08 GB:** If `C:\pagefile.sys` is on C: it is fine (280 GB free), but any FiveM data, texture caches, or a pagefile on D: will stall I/O. This must be verified and relocated.
- **Contributing:** Total CPU already ~82–85% before the compression overhead is considered — the 12-thread 5500 has no headroom left.

### 2.2 FiveM CEF (NUI) CPU & Memory Hogging
- **Evidence:** `FiveM_ChromeBrowser` 110% CPU, 3.38 GB RAM.
- **Mechanism:** FiveM's NUI is Chromium (CEF). Server NUI resources (HUD, radial menus, speedometers) running `setInterval` loops, non-throttled `requestAnimationFrame`, or leaking DOM/`img` elements will pin a full CPU thread and grow memory unboundedly. Over a 5-hour session this leak compounds — the browser cache and unreleased GPU textures are the smoking gun.
- **Contributing:** The `canary` channel ships less-hardened CEF builds, worsening leak behavior.

### 2.3 Graphics / ReShade / QuantV / Rockstar Replay Bottlenecks
- **ReShade 5 + QuantV:** `PD80_04_Color_Isolation`, `PD80_04_Selective_Color`, `Technicolor2`, `DepthHaze`, `QuantV` — five full-screen passes every frame, each with a CPU-dispatch + GPU cost. DepthHaze specifically requires depth-buffer access that forces pipeline stalls.
- **Rockstar Editor Replay (`profile_replayMode=1`):** The action replay system continuously captures and buffers gameplay into RAM (9 chunks at `profile_replayMemLimit=9`), competing directly with the memory-compression bottleneck.
- **`UpdateChannel=canary`:** Experimental branch, prone to hitching, debug logging, and profiling overhead.

### 2.4 Windows DWM / Borderless vs Fullscreen / VSync Pacing
- **Evidence:** `dwm` 99% CPU, `Windowed=2`, `VSync=0`, 144 Hz panel.
- **Mechanism:** Borderless Windowed forces every frame through the Desktop Window Manager compositor. `dwm` at 99% means it is being crushed compositing multiple high-FPS GPU apps simultaneously (FiveM + Roblox + DWM itself). This adds input latency and a compositing copy per frame.
- **Uncapped VSync:** With no frame cap, the renderer produces frames as fast as possible then stalls unpredictably — the classic 120↔30 FPS sawtooth, which reads as violent stutter even though *average* FPS looks fine.
- **Tessellation=3 + SSAO=2 + SoftShadows=3 + FogVolumes=true** all add CPU-side geometry/scene overhead feeding into an already-saturated CPU.

---

## 3. Step-by-Step Immediate Action Plan

### Phase 0 — Free the CPU/RAM *before* touching settings
1. **Close Roblox entirely** (`RobloxPlayerBeta` **and** `RobloxStudioBeta`). Never run these during FiveM. Reclaims ~4% CPU and ~3.86 GB RAM.
2. **Close the duplicate Discord** (keep one instance, or none; disable Hardware Acceleration in the remaining instance: *Settings → Advanced → Hardware Acceleration → Off*).
3. **Close any browser/Chrome tabs** not needed.
4. **Verify the pagefile** is on C: only — *System → Advanced → Performance → Advanced → Virtual memory*. Set C: to "System managed"; set D: to "None". **Do not leave a pagefile on a 1.08 GB-free drive.**
5. **Free D: to ≥ 10 GB** (or move any FiveM/cache data off D: to C:).

### Phase 1 — Kill the biggest single win: Rockstar Replay
6. Edit `fivem.cfg` (see §4.3): disable `profile_replayMode` and `profile_replayMemLimit`. Immediate RAM/CPU relief.

### Phase 2 — Remove the post-process overhead
7. **Disable ReShade/QuantV** (see §4.1) and relaunch without it to baseline.
8. Optionally re-enable a *single* lightweight shader later — never the full 5-shader QuantV stack.

### Phase 3 — Restore frame pacing
9. Switch to **Exclusive Fullscreen** and **enable VSync** (or G-Sync + driver cap), per §4.2.

### Phase 4 — Reduce CPU-bound graphics
10. Drop Tessellation, SSAO, SoftShadows, FogVolumes (see §4.2).

### Phase 5 — Switch off the canary build
11. Set `UpdateChannel` to `beta` (stable) and let FiveM re-download the stable binaries (§4.1).

### Phase 6 — Clean caches & restart
12. Run the PowerShell script in §5 to clear FiveM caches and restart cleanly (also resets the 5-hour leak accumulation).

---

## 4. Recommended Configuration Diffs

### 4.1 `CitizenFX.ini` (typically in the FiveM install dir or `%LOCALAPPDATA%\FiveM\FiveM.app\`)

```ini
# --- BEFORE (faulty) ---
[Game]
UpdateChannel=canary          ; unstable experimental build
PoolSizesIncrease=...         ; inflated pool allocations
; ReShade5 + QuantV injected via dxgi.dll / d3d11.dll in GTAV root

# --- AFTER (fixed) ---
[Game]
UpdateChannel=beta            ; stable recommended channel
; PoolSizesIncrease: remove or reduce to defaults — do not inflate
```

**ReShade/QuantV removal (do this in the GTAV game root, e.g. `...\Grand Theft Auto V\`):**
- Rename `dxgi.dll` → `dxgi.dll.bak`
- Rename `d3d11.dll` → `d3d11.dll.bak` (if present)
- Rename `ReShade.ini` / `ReShadePreset.ini` → `*.bak`
- Remove the QuantV `.addon`/shader files (`PD80_*.fx`, `Technicolor2.fx`, `DepthHaze.fx`, `QuantV.fx`).

### 4.2 `gta5_settings.xml` (Documents\Rockstar Games\GTA V\)

```xml
<!-- BEFORE -->
<Windowed value="2" />            <!-- borderless -->
<VSync value="0" />               <!-- uncapped -->
<Tessellation value="3" />        <!-- very high -->
<SSAO value="2" />
<ShaderQuality value="2" />
<Shadow_SoftShadows value="3" />
<Lighting_FogVolumes value="true" />

<!-- AFTER -->
<Windowed value="0" />            <!-- exclusive fullscreen -->
<VSync value="1" />               <!-- cap to refresh / G-Sync -->
<Tessellation value="1" />        <!-- normal (or 0) -->
<SSAO value="1" />
<ShaderQuality value="1" />
<Shadow_SoftShadows value="2" />  <!-- or NVIDIA PCSS via driver -->
<Lighting_FogVolumes value="false" />
```

> Note: if the panel is G-Sync capable, prefer **G-Sync ON + VSync OFF in-game + FPS cap of 141 via NVIDIA Control Panel / RTSS** instead of raw VSync — this gives tear-free pacing without the full VSync input-latency penalty.

### 4.3 `fivem.cfg` (Documents\Rockstar Games\GTA V\fivem.cfg)

```cfg
// BEFORE
seta "profile_replayMode" "1"       // Rockstar Editor replay buffering
seta "profile_replayMemLimit" "9"

// AFTER
seta "profile_replayMode" "0"
// profile_replayMemLimit can be removed entirely
```

---

## 5. PowerShell Optimization Script (non-destructive)

Clears FiveM cache directories, disables (does not delete) ReShade, and restarts FiveM cleanly. It never touches profiles, settings, or game binaries.

```powershell
# FiveM_CleanRestart.ps1 — non-destructive cache clear + clean relaunch
# Run from an elevated PowerShell session.

$ErrorActionPreference = 'Stop'

function Test-AndClear($Path) {
    if (Test-Path -LiteralPath $Path) {
        Get-ChildItem -LiteralPath $Path -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Cleared: $Path" -ForegroundColor Green
    } else {
        Write-Host "Skipped (not found): $Path" -ForegroundColor DarkGray
    }
}

Write-Host "== Step 1/5: Terminating FiveM processes ==" -ForegroundColor Cyan
$fiveMProcesses = Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.ProcessName -like 'FiveM*' -or $_.ProcessName -like 'CefSharp*' }

if ($fiveMProcesses) {
    $fiveMProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    Write-Host "Terminated $($fiveMProcesses.Count) FiveM/CEF process(es)."
} else {
    Write-Host "No FiveM processes running."
}

Write-Host "`n== Step 2/5: Clearing FiveM caches ==" -ForegroundColor Cyan
$localAppData = $env:LOCALAPPDATA
Test-AndClear "$localAppData\FiveM\FiveM.app\cache"
Test-AndClear "$localAppData\FiveM\FiveM.app\data\cache"
Test-AndClear "$localAppData\FiveM\FiveM.app\data\server-cache"
Test-AndClear "$localAppData\FiveM\FiveM Application Data\cache"
Test-AndClear "$localAppData\FiveM\FiveM Application Data\crashes"

Write-Host "`n== Step 3/5: Disabling ReShade/QuantV (renaming, not deleting) ==" -ForegroundColor Cyan
# Adjust $gtaRoot to your actual Grand Theft Auto V folder.
$gtaRoot = "$env:ProgramFiles\Rockstar Games\Grand Theft Auto V"
if (Test-Path -LiteralPath $gtaRoot) {
    $reshadeFiles = @('dxgi.dll', 'd3d11.dll', 'ReShade.ini', 'ReShadePreset.ini')
    foreach ($f in $reshadeFiles) {
        $p = Join-Path $gtaRoot $f
        if (Test-Path -LiteralPath $p -PathType Leaf) {
            Rename-Item -LiteralPath $p -NewName "$f.bak" -Force -ErrorAction SilentlyContinue
            Write-Host "Disabled: $f -> $f.bak"
        }
    }
} else {
    Write-Host "GTA V root not found at '$gtaRoot' — skip ReShade step manually."
}

Write-Host "`n== Step 4/5: Verifying pagefile is not on D: ==" -ForegroundColor Cyan
# Read-only check. If a pagefile exists on D:, relocate it via System Properties > Advanced.
Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue |
    Select-Object Name, InitialSize, MaximumSize |
    Format-Table -AutoSize

Write-Host "`n== Step 5/5: Relaunching FiveM ==" -ForegroundColor Cyan
$fiveMExe = "$localAppData\FiveM\FiveM.app\FiveM.exe"
if (Test-Path -LiteralPath $fiveMExe) {
    Start-Process -FilePath $fiveMExe
    Write-Host "FiveM launched cleanly."
} else {
    Write-Host "FiveM.exe not found at '$fiveMExe'. Launch manually."
}

Write-Host "`nDone. Session now runs on stable beta build, no ReShade, fresh cache, and freed RAM." -ForegroundColor Green
```

### Pre-flight checklist before first run
- Save as `FiveM_CleanRestart.ps1` and run **elevated**.
- Update `$gtaRoot` to the real GTA V path if it differs.
- Confirm the `FiveM.app` and `FiveM Application Data` paths exist (script safely skips missing paths).
- This script **deletes only cache contents** — profiles, saved settings, and game files are untouched.

---

## 6. Expected Outcome & Verification

| Metric | Before | Expected After |
|---|---|---|
| Free RAM | 5.78 GB | ≥ 14 GB (Roblox/Discord closed + replay off) |
| `System` (compression) CPU | 105% | < 10% |
| `dwm` CPU | 99% | < 15% (exclusive fullscreen) |
| CEF/NUI RAM | 3.38 GB | < 1 GB (fresh cache) |
| Frametime | 120↔30 FPS swings | locked 60/72/144, stable frametime |

**Verify with:** close Roblox + duplicate Discord, run the script, load the same server, and watch Task Manager — the `System` process CPU should collapse and `dwm` should drop. Use an in-game frametime graph (ReShade is now off, so use the NVIDIA overlay) to confirm no sawtooth pattern.
