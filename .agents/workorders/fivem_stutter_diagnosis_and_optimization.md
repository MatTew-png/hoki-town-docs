# Work Order: FiveM Severe Stuttering & Frametime Hitching Root-Cause Analysis and Optimization

## 1. Context & Telemetry Findings
The user is experiencing severe frame drops / violent stuttering ("เฟรมกระชากมาก เล่นไม่ได้เลย") while playing FiveM.
Antigravity performed live system telemetry and log inspections. Here are the exact empirical findings:

### A. Hardware Profile
- CPU: AMD Ryzen 5 5500 (6 Cores / 12 Threads)
- GPU: NVIDIA GeForce RTX 3060 Ti (8 GB VRAM, Driver 561.42)
- RAM: 32 GB DDR4 (Visible: 31.87 GB, Free: 5.78 GB, Compressed: 3.32 GB)
- Storage: C: (280 GB free), D: (1.08 GB free)

### B. Live Telemetry & Bottleneck Evidence
1. **Severe CPU Saturation (Total CPU ~82-85% pinned)**:
   - `FiveM_b3889_GTAProcess`: 404% CPU (over 4 CPU threads)
   - `FiveM_ChromeBrowser` (NUI / CEF UI): 110% CPU, 3.38 GB RAM (Memory leak & high CPU cycle waste from server NUI scripts)
   - `RobloxPlayerBeta`: 22% CPU, 2.86 GB RAM (Running concurrently in background)
   - `RobloxStudioBeta`: 33% CPU, 1.0 GB RAM (Running concurrently in background)
   - Two separate Discord instances (`DiscordPTB` + `Discord`): 27% CPU, 1.43 GB RAM
   - `dwm` (Desktop Window Manager): 99% CPU (Straining due to borderless windowed mode and multiple high-FPS GPU applications)
   - `System` (Memory Compression & Paging): 105% CPU (Windows is thrashing CPU cycles compressing memory)

2. **FiveM Engine & Graphics Configurations**:
   - `CitizenFX.ini`:
     - `UpdateChannel=canary` (Unstable experimental build prone to hitching and debug profiling overhead)
     - `ReShade5` is active with `QuantV.addon` and multiple heavy shaders (`PD80_04_Color_Isolation.fx`, `PD80_04_Selective_Color.fx`, `Technicolor2.fx`, `DepthHaze.fx`, `QuantV.fx`) hooking D3D11/D3D12 swapchains.
     - Redundant / inflated `PoolSizesIncrease` config.
   - `fivem.cfg`:
     - `seta "profile_replayMode" "1"` (Rockstar Editor Action Replay constantly buffering into RAM!)
     - `seta "profile_replayMemLimit" "9"`
   - `gta5_settings.xml`:
     - `Windowed value="2"` (Borderless Windowed instead of Exclusive Fullscreen)
     - `VSync value="0"` with 144Hz monitor -> Uncapped framerate causing wild swings from ~120 FPS down to 30 FPS.
     - `Tessellation value="3"` (Very High - heavy CPU geometry overhead)
     - `SSAO value="2"`, `ShaderQuality value="2"`, `Shadow_SoftShadows value="3"`, `Lighting_FogVolumes value="true"`.
   - **Session Uptime**: FiveM has been running continuously for ~5 hours (`17,815,031 ms`), accumulating NUI / texture cache leaks.

## 2. Objective
Analyze the root causes of the stuttering across:
1. Resource contention & memory compression.
2. FiveM CEF (NUI) CPU & memory hogging.
3. Graphics / ReShade / QuantV / Rockstar Replay bottlenecks.
4. Windows DWM / Borderless Windowed vs Fullscreen vs G-Sync/VSync pacing.

Generate:
1. Executive Technical Diagnosis explaining exactly why the frame spikes occur.
2. Step-by-step Immediate Action Plan (what to close, what settings to toggle).
3. Recommended configuration diffs for `CitizenFX.ini`, `gta5_settings.xml`, and `fivem.cfg`.
4. A clean, non-destructive PowerShell optimization script to clear FiveM cache and restart cleanly.
