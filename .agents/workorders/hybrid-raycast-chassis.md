# Work Order: hybrid-raycast-chassis

## 1. Objective
Upgrade `src/TeslaRoadster_Raycast/` + `src/ReplicatedStorage/VehicleStats.luau` into a clean, zero-constraint Hybrid Raycast Chassis featuring effortless controls with speed-dependent controlled tail-whip oversteer and auto-straightening, lighter airborne gravity with delayed W/S/A/D air control, decoupled 6-tier upgrades + ECU tuning multipliers, per-wheel police-chase tire puncture physics, A-Chassis EQ/Turbo audio synthesis, and `CarStatusGui` telemetry integration.

## 2. Target Files
- Create: `src/ReplicatedStorage/VehicleStats.luau`
- Modify: `src/TeslaRoadster_Raycast/RaycastVehiclePhysics.luau`
- Modify: `src/TeslaRoadster_Raycast/RaycastChassisClient.client.luau`
- Modify: `src/TeslaRoadster_Raycast/RaycastChassisServer.server.luau`
- Create: `src/TeslaRoadster_Raycast/VehicleSoundClient.client.luau`
- Create: `src/TeslaRoadster_Raycast/VehicleSoundClient.meta.json`
- Create: `src/TeslaRoadster_Raycast/VehicleStatusClient.client.luau`
- Modify: `default.project.json`
- Modify: `sourcemap.json`

## 3. Implementation Contract

### A. `src/ReplicatedStorage/VehicleStats.luau` (`--!strict`)
Shared SSOT stat sheet module used by both client physics and server validation/damage. **Zero raw physics solver constants mutated directly by upgrades; all upgrades & ECU tuning map to clean bounded multipliers:**
- Export types:
  - `WheelKey = "FL" | "FR" | "RL" | "RR"`
  - `TireStates = { FL: boolean, FR: boolean, RL: boolean, RR: boolean }` (`true` = popped/punctured)
  - `ComputedVehicleStats = { TopSpeed: number, ReverseSpeed: number, DriveAcceleration: number, LaunchAccelMultiplier: number, HighSpeedPullMultiplier: number, BrakeAcceleration: number, LateralGrip: number, AntiRollStiffness: number, OversteerSensitivity: number, MaxHealth: number, ImpactDamageMultiplier: number, TurboBoostPower: number, AirGravityScale: number, AirPitchRate: number, AirYawRate: number, AirRollRate: number, AirControlDelay: number, CurbHeight: number, CurbAssistForce: number, PoppedTireCount: number, FrontSteerBias: number, EffectiveTopSpeed: number, TireStates: TireStates }`
- Default Attributes (applied by `VehicleStats.EnsureDefaultAttributes(car: Model)` only when nil):
  - Upgrades: `EngineTier = 1` (1..5), `BrakeTier = 1` (1..5), `TransmissionTier = 1` (1..5), `SuspensionTier = 1` (1..5), `ArmourTier = 1` (1..5), `TurboTier = 0` (0..5).
  - ECU Tuning Box sliders: `ECU_GripBias = 0` (-1..1), `ECU_PowerMap = 0` (-1..1), `ECU_AirWeight = 0.70` (0.50..1.00).
  - Tire Puncture Hooks (for future police shooting patch): `TirePopped_FL = false`, `TirePopped_FR = false`, `TirePopped_RL = false`, `TirePopped_RR = false`.
- Role separation across the 6 upgrades (zero overcontrol, never touches vertical `SpringStiffness`, `RestLength`, or vehicle `Mass`):
  - `EngineTier` (1..5): scales base `TopSpeed` (175 -> ~245) and base `DriveAcceleration`.
  - `TransmissionTier` (1..5): scales `LaunchAccelMultiplier` (low-end response 1.0 -> 1.45) and `ReverseSpeed` (42 -> 62).
  - `TurboTier` (0..5): scales `HighSpeedPullMultiplier` (1.0 -> 1.40) and `TurboBoostPower` (0 -> 1.0) for high-RPM pull & BOV audio.
  - `BrakeTier` (1..5): scales `BrakeAcceleration` (150 -> 270).
  - `SuspensionTier` (1..5): **DOES NOT alter vertical spring stiffness or ride height**; scales `LateralGrip` (1.25 -> 1.65) and `AntiRollStiffness` (8000 -> 14000) for cornering stability.
  - `ArmourTier` (1..5): scales `MaxHealth` (100 -> 250) and `ImpactDamageMultiplier` (1.0 -> 0.40). **Never modifies physics `Mass`**.
- `ECU_GripBias` (-1..1) scales `LateralGrip` in `[0.75, 1.25]` and `OversteerSensitivity` inversely (negative = driftier tail, positive = planted).
- `ECU_PowerMap` (-1..1) trades `LaunchAccelMultiplier` vs `TopSpeed` by up to `±12%`.
- `ECU_AirWeight` clamped `[0.50, 1.00]` sets `AirGravityScale` (default `0.70` = 30% lighter airborne gravity).
- Tire puncture penalties in `Compute(car)`:
  - Count popped tires (`0..4`).
  - `EffectiveTopSpeed = TopSpeed * limpFactor` where `0 -> 1.0, 1 -> 0.82, 2 -> 0.62, 3 -> 0.42, 4 -> 0.28`.
  - `FrontSteerBias`: `(FL popped ? -0.18 : 0) + (FR popped ? 0.18 : 0)`.
- Export `VehicleStats.EnsureDefaultAttributes(car: Model): ()`, `VehicleStats.GetTireStates(car: Model): TireStates`, and `VehicleStats.Compute(car: Model): ComputedVehicleStats`.

### B. `src/TeslaRoadster_Raycast/RaycastVehiclePhysics.luau` (`--!strict`)
- Preserve clean 0-constraint raycast suspension solver (`Chassis_Collider` + `DriveSeat` root assembly, Spherecast wheel probes, Hooke spring + damper + anti-roll + landing damper + curb assist + Spacebar sink).
- **Fix existing type/lint issues cleanly:**
  - Remove invalid `AngularVelocity.MaxAngularVelocity` assignment (line 326).
  - Type `filterInstances: { Instance } = { self.car }`.
  - Fix `setmetatable` strict typing (`--!strict`, `luau-lsp analyze` 0 errors, `selene` 0 errors/warnings).
  - Do NOT `assert(not root.Anchored)` at `Initialize` (server anchors `DriveSeat` while parked and unanchors on sit; instead skip force simulation until `self.isLocalDriver and not self.root.Anchored`).
- **Auto-calibrate per-wheel geometry & multi-part wheel models (`Tesla_Roadster_Base_2026` compatibility):**
  - Support `Wheels.FL` (a `Model` containing `Wheel_FL`, `Tire_FL`, `Brake_Rotor_FL`, `Caliper_FL`) as well as direct `BasePart` wheels (`FL` or `Wheel_FL`).
  - Read each wheel's rest `localCenter` and `WheelRadius` directly from `Tire_XX` (or wheel part `Size.Y * 0.5`) relative to `Chassis_Collider` at `Initialize` time (so front `1.060` and rear `1.115` radii & exact offsets work out of the box!).
  - Collect all non-caliper visual parts inside `Wheels.XX` (`Wheel_XX`, `Tire_XX`, `Brake_Rotor_XX`) with their local CFrame offsets relative to wheel pivot; move them + `Caliper_XX` cleanly via CFrame in `PreRender`/step (all `Anchored = true, CanCollide = false, Massless = true`, calipers steer & follow vertical suspension offset without spinning!).
- **Live Stat Reactivity:**
  - Hold `self.stats = VehicleStats.Compute(car)` and refresh whenever any `AttributeChanged` fires on `car`.
- **Easy Driving + High-Speed Controlled Tail-Whip + Auto-Straightening:**
  - Read `VehicleSeat` + direct `W/S/A/D` & Arrow keys dual-input (`Throttle` and `Steer`), plus Spacebar `ContextActionService` Sink + `Humanoid:SetStateEnabled(Jumping, false)`.
  - Acceleration curve blends `LaunchAccelMultiplier` (low speed) and `HighSpeedPullMultiplier` (high speed) using `EffectiveTopSpeed`.
  - High-speed steering oversteer ("ความเร็วเยอะแล้วเลี้ยวกระทันหันท้ายจะสะบัด"):
    - When `speedRatio > 0.38` and `abs(steerInput) > 0.35`, compute rear-only `oversteerGripFactor` dropping down to `~0.58 * OversteerSensitivity` at peak speed + full lock, letting the tail whip smoothly.
    - **Auto-Straightening & Anti-Spin Safety Cap ("เลี้ยวรถคืนตัวตรงให้เอง ขับง่ายมาก"):**
      - Compute chassis slip angle (`atan2(lateralVel, max(abs(forwardVel), 5))`). If `abs(slipAngle) > math.rad(38)`, apply progressive stabilizing yaw damping so the car never spins 360° uncontrollably.
      - When `abs(steerInput) < 0.08` and grounded, apply smooth yaw-rate damping (`root.AssemblyAngularVelocity` Y damping) and slightly elevated rear lateral recovery so releasing `A/D` cleanly straightens the car onto its travel path.
- **Per-Wheel Tire Puncture Handling (Police Chase Ready):**
  - Inside the per-wheel loop, inspect `self.stats.TireStates[wheel.key]`.
  - If that tire is popped (`true`):
    - Lower its effective `RestLength` by `0.35` studs (physical & visual dip onto rim).
    - Drop that wheel's `LateralGrip` to `0.22x` (rear popped = heavy oversteer; front popped = understeer + steering pull).
    - Add rolling resistance drag (`-math.sign(wheelLongitudinalSpeed) * wheel.normalLoad * 0.38`).
  - Apply `self.stats.FrontSteerBias` onto steering input when grounded and moving (`> 6` studs/s) so a blown front tire pulls left/right realistically.
- **Lighter Airborne Gravity + Delayed W/S/A/D Stunt Control:**
  - Add an upward `VectorForce` (`AirGravityForce`, `ApplyAtCenterOfMass = true`, `RelativeTo = World`) enabled only when `grounded == 0`: `Force = Vector3.yAxis * (mass * Workspace.Gravity * (1 - self.stats.AirGravityScale))`.
  - Track `self.airborneTime` (`+= dt` while `grounded == 0`, reset to `0` on ground).
  - In `updateAirControl(throttle, steer)`:
    - While `self.airborneTime < self.stats.AirControlDelay` (`0.15s`), do NOT apply pitch/yaw from held `W/S/A/D` (prevents immediate nose-dive off ramps).
    - After `0.15s`, apply `W/S` pitch (`frame.RightVector * -throttle * AirPitchRate`) and `A/D` yaw (`Vector3.yAxis * -steer * AirYawRate`) + subtle roll bank (`frame.LookVector * steer * AirRollRate * 0.45`).
    - When airborne and both `throttle` and `steer` are near 0 (`abs < 0.08`), gently damp angular velocity and assist leveling slightly toward upright so jumps feel smooth and playable.
- **Telemetry API & Attributes for Sound/HUD:**
  - Compute virtual 6-speed gear (`-1` Reverse, `0` Neutral/Park, `1..6` Forward) and virtual RPM (`850..7500`) from `abs(longitudinalSpeed) / EffectiveTopSpeed` + throttle load.
  - Export `controller:GetTelemetry(): TelemetrySnapshot` and throttle-update `car:SetAttribute("CurrentGear", gear)`, `car:SetAttribute("CurrentRPM", rpm)`, `car:SetAttribute("SpeedKmh", speedKmh)` for `CarStatusGui` & `VehicleSoundClient` (or provide direct read via shared `car` attributes/Bindable/telemetry). Using `local telemetry` in `RaycastChassisClient` (setting `CurrentGear`, `CurrentRPM`, `CurrentBoost`, `CurrentThrottle`, `SpeedKmh` attributes only locally or via client attributes/State) — wait: setting attributes on `car` from a LocalScript only affects the client (`VehicleSoundClient` and `CarStatusGui` are both client scripts, so zero server network spam!). Even cleaner: keep `CurrentGear`, `SpeedKmh`, `CurrentRPM`, `CurrentBoost`, `CurrentThrottle` updated locally in client `RaycastChassisClient` via `car:SetAttribute` (client-local!) or `RaycastVehiclePhysics` telemetry table! Let's write `car:SetAttribute` cleanly on client OR export a `GetTelemetry` + client-local attributes (`ClientRPM`, `ClientGear`, `ClientBoost`, `ClientThrottle`, `ClientSpeedKmh`) so `VehicleSoundClient` and `VehicleStatusClient` stay 100% decoupled!

### C. `src/TeslaRoadster_Raycast/VehicleSoundClient.client.luau` + `VehicleSoundClient.meta.json` (`--!strict`)
- `VehicleSoundClient.meta.json`: `{"className": "Script", "properties": {"RunContext": "Client"}}` (same pattern as `RaycastChassisClient.meta.json` so it runs inside `Workspace`).
- Builds & manages the A-Chassis 1.7 EQ/Turbo audio stack cleanly on `DriveSeat` (only actively loud/playing when `car` has an occupant or local driver, with graceful `RollOffMaxDistance = 120`):
  - `ENG_Idle` (`rbxassetid://5226685480`)
  - `ENG_Engine` (`rbxassetid://6002661882`) + `EqualizerSoundEffect` + `DistortionSoundEffect`
  - `ENG_Exhaust` (`rbxassetid://1489232045`) + `EqualizerSoundEffect` + `DistortionSoundEffect`
  - `ENG_Exhaust2` (`rbxassetid://1235897119`) + `EqualizerSoundEffect` + `DistortionSoundEffect`
  - `TUR_Turbo` (`rbxassetid://240323039`) & `TUR_Turbo2` (`rbxassetid://1033010834`) (volume scales with `TurboTier > 0` and `ClientBoost`)
  - `BOV_BOV` (`rbxassetid://3568930062`) (one-shot blow-off sound when releasing throttle after boost builds above `0.28` and `TurboTier > 0`)
  - `TRA_Reverse` (`rbxassetid://404779487`) (fades in when `ClientGear == -1` and moving)
  - `IGN_Starter` (`rbxassetid://169394147`) (plays once when local player enters `DriveSeat`)
- Reads `ClientRPM`, `ClientGear`, `ClientThrottle`, `ClientBoost`, `TurboTier` from `car:GetAttribute(...)` on `RenderStepped` (with smooth pitch/EQ interpolation matching `OffEQ` -> `ThrottleEQ` from `TeslaSSSS (1).rbxm`). Cleanly stops all sounds on driver exit or `car.AncestryChanged`.

### D. `src/TeslaRoadster_Raycast/VehicleStatusClient.client.luau` (`--!strict`)
- Drives `CarStatusGui` (`Frame/Background/{SpeedNow, GearNow, GearNext, GearBefore, FuelPercent, HealthPercent}`) + `[R]` Quick-Repair + Breakdown Alert Banner.
- Reads `SpeedKmh` (from `ClientSpeedKmh` or `seat.AssemblyLinearVelocity.Magnitude * 1.008`), `ClientGear` (fallback to `A-Chassis Interface/Values/Gear` if present), `Health`, `MaxHealth`, `Fuel`, `MaxFuel`.
- Also shows a clean non-intrusive `TireAlertBanner` (created dynamically if absent, just like `BreakdownAlertBanner`) whenever 1+ tires are popped (`TirePopped_FL/FR/RL/RR`): e.g. `"⚠️ ยางแตก x%d เส้น — การควบคุมลดลง!"`.

### E. `src/TeslaRoadster_Raycast/RaycastChassisClient.client.luau` (`--!strict`)
- Thin client entrypoint: initializes `RaycastVehiclePhysics.Initialize(car)`, calls `controller:Start()`, updates client telemetry attributes (`ClientRPM`, `ClientGear`, `ClientThrottle`, `ClientBoost`, `ClientSpeedKmh`) on `Heartbeat` while driving, and calls `controller:Destroy()` on `car.Destroying` / ancestry loss.

### F. `src/TeslaRoadster_Raycast/RaycastChassisServer.server.luau` (`--!strict`)
- Calls `VehicleStats.EnsureDefaultAttributes(car)`.
- Separates wheel parts cleanly:
  - Leaves body parts massless/non-colliding welded to `driveSeat`, and `Chassis_Collider` colliding & non-massless welded to `driveSeat`.
  - Under `Wheels`: destroys any `Weld`/`WeldConstraint` connecting `Wheel_*` / `Tire_*` / `Brake_Rotor_*` to `Caliper_*` or chassis, and sets all wheel & caliper `BasePart`s `Anchored = true, CanCollide = false, Massless = true` so client physics & CFrame rendering are conflict-free.
- Handles `ProximityPrompt` (`[E]` / `[F]` drive), single-authority `DriveSeat.Anchored` + `SetNetworkOwner(player)` on occupant change, and `CarStatusGui` lifecycle (clones `CarStatusGui` template to driver's `PlayerGui` with `VehicleRef` ObjectValue, cleans up on exit).
- Handles `VehicleRepairRequest` (`[R]` key within 24 studs or seated): restores `Health = MaxHealth`, `Fuel = MaxFuel`, and resets `TirePopped_FL = false, TirePopped_FR = false, TirePopped_RL = false, TirePopped_RR = false`.
- Handles Crash Impact Damage scaled by `VehicleStats.Compute(car).ImpactDamageMultiplier` (from `ArmourTier`) & `GodMode` respect, plus dynamic `MaxHealth` scaling when `ArmourTier` changes.
- Exposes a clean `BindableEvent` / attribute listener hook (`DamageTire` or direct `car:SetAttribute("TirePopped_RL", true)`) ready for future police gunfire scripts.

### G. `default.project.json`
- Map `ReplicatedStorage.VehicleStats` -> `"src/ReplicatedStorage/VehicleStats.luau"`.
- Under both `Workspace.Tesla_Roadster_Base_2026` and `ServerStorage.DisabledVehicles.TeslaRoadster_Raycast`, add:
  - `"VehicleSoundClient": { "$path": "src/TeslaRoadster_Raycast/VehicleSoundClient.client.luau" }`
  - `"CarStatusGui": { "$className": "ScreenGui", "$ignoreUnknownInstances": true, "VehicleStatusClient": { "$path": "src/TeslaRoadster_Raycast/VehicleStatusClient.client.luau" } }`

## 4. Verification Command
`stylua src/ReplicatedStorage/VehicleStats.luau src/TeslaRoadster_Raycast/ && stylua --check src/ReplicatedStorage/VehicleStats.luau src/TeslaRoadster_Raycast/ && selene src/ReplicatedStorage/VehicleStats.luau src/TeslaRoadster_Raycast/ && rojo sourcemap default.project.json -o sourcemap.json && luau-lsp analyze --defs=globalTypes.d.luau --sourcemap=sourcemap.json src/ReplicatedStorage/VehicleStats.luau src/TeslaRoadster_Raycast/RaycastVehiclePhysics.luau src/TeslaRoadster_Raycast/RaycastChassisClient.client.luau src/TeslaRoadster_Raycast/RaycastChassisServer.server.luau src/TeslaRoadster_Raycast/VehicleSoundClient.client.luau src/TeslaRoadster_Raycast/VehicleStatusClient.client.luau`
