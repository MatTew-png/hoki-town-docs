# Work Order: A-Chassis Arcade Overhaul (Drive Like Raycast)

## 1. Objective
Transform the A-Chassis on `Workspace.TeslaRoadster` into an effortless, tactile, instantaneous "Arcade Supercar" driving engine that handles as easily and responsively as Raycast / Car Dealership Tycoon (CDT), eliminating clutch lag, gear delay, spinouts, and curb bounce.

## 2. Target Files
- Modify: `src/TeslaRoadster/A-Chassis Tune/init.luau`
- Modify: `src/TeslaRoadster/A-Chassis Tune/A-Chassis Interface/Drive.client.luau`

## 3. Implementation Contract

### A. Tuning Configuration: `src/TeslaRoadster/A-Chassis Tune/init.luau`
1. **Instant Throttle & Supercar Speed:**
   - Set `Config.TopSpeed = 260` (km/h)
   - Set `Config.Acceleration = 8.5` (high responsiveness)
   - Set `Config.ThrottleResponse = 0.45` (immediate pedal bite)
   - Set `Config.Weight = 1350`
   - Set `Config.GroundGravity = 210` (strong tire-ground contact, prevents floaty sensation)
   - Set `Config.AirGravity = 196.2`
2. **Instant Electric Torque (Zero Lag at 0 RPM):**
   - Enable `Tune.Electric = true`
   - Set `Tune.E_Torque = 3600` lb-ft (supercar instant pull)
   - Set `Tune.E_TransitionRPM = 7500`
   - Set `Tune.E_Redline = 22000`
   - Set `Tune.E_RedlineTorque = 1800`
   - Set `Tune.Clutch = false` (eliminates slow clutch slipping; power connects immediately)
   - Set `Tune.Stall = false`
3. **Smart 2-Pedal Auto Transmission:**
   - `Tune.AutoShiftVers = "Old"` (auto Reverse on S when stopped, auto Forward on W)
   - `Tune.TransModes = {"Auto"}`
   - `Tune.ShiftUpTime = 0.05` (ultra-fast DCT shifting)
   - `Tune.ShiftDnTime = 0.05`
4. **Steering Grip & Auto Counter-Steer (Anti-Spinout):**
   - Set `Config.MaxSteerAngle = 36`
   - Set `Config.SteerSpeed = 1.35`
   - Set `Config.ReturnSpeed = 2.2` (snappy center return)
   - Set `Config.SteerAtTopSpeed = 45` (tames twitchiness at high speed)
   - **ENABLE Counter-Steer:**
     - `Tune.CSEnabled = true`
     - `Tune.CSAmt = 75` (auto-countersteer into drift slides)
     - `Tune.CSSteerThresh = 8`
     - `Tune.CSSpeedThresh = 15`
5. **Arcade Drift & Tire Smoke:**
   - Set `Config.TapDriftEnabled = true`
   - Set `Config.TapDriftTapDuration = 0.35`
   - Set `Config.TapDriftMinSpeed = 18`
   - Set `Config.TapDriftRearBrake = 22000`
   - Set `Config.TapDriftPowerRatio = 0.55`
   - Set `Config.TapDriftMaxDuration = 1.35`
   - Set `Config.TireSmokeEnabled = true`
6. **Suspension & Curb Stability (Anti-Fling):**
   - Set `Tune.FSusStiffness = 22.0`, `Tune.RSusStiffness = 22.0`
   - Set `Tune.FSusDamping = 16.0`, `Tune.RSusDamping = 16.0` (fast rebound settling)
   - Set `Tune.FSwayBar = 8.0`, `Tune.RSwayBar = 8.0` (eliminates excessive body roll)
   - Set `Config.CurbAssistEnabled = true`, `Config.CurbAssistMaxStep = 2.1`

### B. Client Driving Script: `src/TeslaRoadster/A-Chassis Tune/A-Chassis Interface/Drive.client.luau`
1. **Spacebar Sink Priority & Ejection Immunity:**
   - Verify `ContextActionService:BindActionAtPriority` for Handbrake (`Enum.KeyCode.Space`) with priority `High + 3000` returning `Enum.ContextActionResult.Sink`.
   - Ensure `humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)` while seated in `DriveSeat`, restored upon exiting.
2. **Instant Throttle & Neutral Bypass:**
   - In the drive loop where `_CGear` and `_PBrake` are processed:
     - On any forward throttle (`_InThrot > 0.05`), immediately disengage parking brake (`_PBrake = false`).
     - If `_CGear == 0` (Neutral) and in Automatic mode, automatically engage `_CGear = 1` immediately without delay.

## 4. Verification Target
- Verify with `rojo build --output scratch/test_build.rbxm`.
