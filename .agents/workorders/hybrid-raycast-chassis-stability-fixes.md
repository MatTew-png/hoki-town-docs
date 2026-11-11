# Work Order: Hybrid Raycast Chassis Stability & Collision Fixes

## 1. Objective
Eliminate the two empirically observed playtest stability bugs in `Tesla_Roadster_Base_2026` (`RaycastVehiclePhysics`):
1. Seat-entry launch impulse (`CollisionGroup` + `NoCollisionConstraint` between `Chassis_Collider` and the seated character) and `StreamingEnabled` startup safety.
2. Zero-speed lateral Euler chatter / popped-tire bang-bang oscillation at rest in `updateForces`.

## 2. Target Files
- `src/TeslaRoadster_Raycast/RaycastChassisServer.server.luau`
- `src/TeslaRoadster_Raycast/RaycastVehiclePhysics.luau`
- `src/TeslaRoadster_Raycast/RaycastChassisClient.server.luau`

## 3. Exact Specifications

### A. `src/TeslaRoadster_Raycast/RaycastChassisServer.server.luau`
1. Add `local PhysicsService = game:GetService("PhysicsService")`.
2. Immediately after `VehicleStats.EnsureDefaultAttributes(car)`, enforce persistent streaming so `Workspace.StreamingEnabled = true` keeps the vehicle replicated reliably:
   ```lua
   pcall(function()
       car.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
   end)
   ```
3. Under section 1 (`Chassis_Collider` setup, lines ~78-89):
   - When `"Vehicles"` is registered (`PhysicsService:IsCollisionGroupRegistered("Vehicles")`), set `chassisCollider.CollisionGroup = "Vehicles"`.
4. Add runtime `NoCollisionConstraint` management inside occupant handling (section 5):
   - Keep a module-local table `seatNoCollisions: { NoCollisionConstraint } = {}` and helper `clearSeatNoCollisions()` / `attachSeatNoCollisions(character: Model)`.
   - When a valid `player` driver sits in `driveSeat`, create a `NoCollisionConstraint` (`Part0 = chassisCollider`, `Part1 = desc`) for each `BasePart` descendant of `player.Character` (if `chassisCollider` exists), BEFORE or as `driveSeat.Anchored = false` runs so the character's torso/legs enclosed by `Chassis_Collider` never collide with `Chassis_Collider` even across collision groups or delayed `SeatWeld` replication.
   - Clear `seatNoCollisions` cleanly when occupant leaves (`not occupant`), changes, or on `car.Destroying` / `car.AncestryChanged` (`Parent == nil`).

### B. `src/TeslaRoadster_Raycast/RaycastVehiclePhysics.luau`
1. **Streaming-safe `findBasePart` & `resolveWheel` wait (`Initialize`)**:
   - Update `findBasePart(root: Instance, name: string, timeoutSeconds: number?): BasePart` to wait cleanly if not immediately present under `root`: if `root:FindFirstChild(name, true)` is nil, loop with `task.wait(0.1)` until `timeoutSeconds or 10` seconds elapse before asserting.
   - Wait similarly up to `10` seconds for `wheelsFolder` (`car:FindFirstChild("Wheels")` or direct child `"FL"`) and each wheel entry `"FL"`, `"FR"`, `"RL"`, `"RR"` inside `Initialize` before `resolveWheel`, so `Workspace.StreamingEnabled = true` can never race with client startup.
2. **Corner velocity for initial ground contact in `probeWheels`**:
   - On line ~479, replace `else root.AssemblyLinearVelocity.Y` with:
     `else root:GetVelocityAtPosition(wheel.forceAttachment.WorldPosition).Y`
     so pitch/roll velocity at each wheel corner is damped cleanly on touchdown.
3. **Impulse-bounded low-speed tire friction & smooth drag (`updateForces`)**:
   - Before the wheel force loop (around line 755), compute `totalNormalLoad`:
     ```lua
     local totalNormalLoad = 0
     for _, w in ipairs(self.wheels) do
         if w.grounded then
             totalNormalLoad += w.normalLoad
         end
     end
     ```
   - Inside `if wheel.grounded then` in the wheel force loop:
     - Compute `local safeDt = math.max(dt, 1 / 60)` and `local wheelMassShare = mass * (wheel.normalLoad / math.max(totalNormalLoad, 1e-3))`.
     - Smooth popped-tire drag & handbrake locking using `local smoothLongSign = clamp(wheelLongitudinalSpeed / 2.0, -1, 1)` instead of abrupt `math.sign(wheelLongitudinalSpeed)`:
       - For handbrake (`if handbraking and not wheel.front then`):
         `longitudinalForce = -smoothLongSign * maximumTireForce * 1.5`
       - For popped rolling resistance (`if popped then`):
         `local drag = -smoothLongSign * wheel.normalLoad * 0.38`
         and clamp `longitudinalForce` if not actively accelerating with throttle (`math.abs(throttle) < 0.05`) or braking (`handbraking`) by `[-maxStopLong, maxStopLong]` where `local maxStopLong = (math.abs(wheelLongitudinalSpeed) * wheelMassShare) / safeDt * 0.55`. (More simply: when applying pure drag/handbrake deceleration with `math.abs(throttle) < 0.05` or `handbraking`, cap `-sign` longitudinal braking force magnitude so `|dv_long| <= 0.55 * |wheelLongitudinalSpeed|`.)
     - Replace `local lateralForce = -lateralCurve * lateralCapacity * gripScale` with:
       ```lua
       local rawLateralForce = -lateralCurve * lateralCapacity * gripScale
       local maxStopLateral = (math.abs(lateralSpeed) * wheelMassShare) / safeDt * 0.55
       local lateralForce = clamp(rawLateralForce, -maxStopLateral, maxStopLateral)
       ```
       so resting and near-zero speed stability never triggers explicit Euler overshoot oscillation while high-speed cornering and drift curves remain identical.

### C. `src/TeslaRoadster_Raycast/RaycastChassisClient.server.luau`
1. Wait up to 15s for `DriveSeat` and `Chassis_Collider` (`car:WaitForChild("DriveSeat", 15)` / `car:WaitForChild("Chassis_Collider", 15)`) before calling `RaycastVehiclePhysics.Initialize(car)`, returning safely if `car` is removed before streaming completes.

## 4. Constraints & Standards
- Keep `--!strict` Luau clean (0 `luau-lsp` type errors, 0 `selene` warnings, passes `stylua`).
- Preserve all existing API signatures, attribute names, comments, and `VehicleStats.luau` contracts untouched.
- Do not touch any file outside Section 2 Target Files.

## 5. Verification Steps
1. `stylua --check src/ReplicatedStorage/VehicleStats.luau src/TeslaRoadster_Raycast/`
2. `selene src/ReplicatedStorage/VehicleStats.luau src/TeslaRoadster_Raycast/`
3. `rojo sourcemap default.project.json -o sourcemap.json && luau-lsp analyze --defs=globalTypes.d.luau --sourcemap=sourcemap.json src/ReplicatedStorage/VehicleStats.luau src/TeslaRoadster_Raycast/RaycastVehiclePhysics.luau src/TeslaRoadster_Raycast/RaycastChassisClient.server.luau src/TeslaRoadster_Raycast/RaycastChassisServer.server.luau src/TeslaRoadster_Raycast/VehicleSoundClient.server.luau src/TeslaRoadster_Raycast/VehicleColorClient.server.luau src/TeslaRoadster_Raycast/VehicleStatusClient.client.luau`
