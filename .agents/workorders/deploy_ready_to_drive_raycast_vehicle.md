# Work Order: Deploy Ready-to-Drive Raycast Vehicle (Server & Client Architecture)

## 1. Objective
Produce a complete, robust, production-grade Luau driving system for `TeslaRoadster_Raycast` in `HOKI TOWN`.
The system must allow a player to approach the vehicle, press [E] to sit in `DriveSeat`, and immediately drive with instant W/A/S/D responsiveness, smooth forward acceleration, high-grip steering, Spacebar tap-to-drift handbrake without player ejection, automated curb climbing over obstacles up to 2.1 studs, mid-air leveling, and visual wheel steering/spin animation.

## 2. Target Files
- Modify: `src/TeslaRoadster_Raycast/RaycastChassisServer.server.luau`
- Modify: `src/TeslaRoadster_Raycast/RaycastChassisClient.client.luau`

## 3. Implementation Contract

### A. Server Authority: `src/TeslaRoadster_Raycast/RaycastChassisServer.server.luau`
1. **Root Part & Hierarchy Calibration:**
   - Detect `DriveSeat` and/or `Chassis_Collider`.
   - Ensure `DriveSeat.Anchored = false`, `DriveSeat.CanCollide = false`, `DriveSeat.Disabled = false`.
   - For all parts inside `Body` and child models: ensure `CanCollide = false`, `Massless = true`, `Anchored = false`, and weld them to `DriveSeat` using `WeldConstraint` if not already welded.
2. **Cosmetic Wheels Un-welding:**
   - In `car:FindFirstChild("Wheels")`, find all wheels (`FL`, `FR`, `RL`, `RR`) and child parts.
   - Destroy or disable any `WeldConstraint` or `Weld` connecting wheels to `DriveSeat` or the chassis root so wheels are physically separate assemblies.
   - Set wheels to `Anchored = true`, `CanCollide = false`, `Massless = true`.
3. **ProximityPrompt Entry:**
   - Add/configure `DrivePrompt` on `DriveSeat`:
     - `ObjectText = "Tesla Roadster"`
     - `ActionText = "ขับรถ (Drive)"`
     - `KeyboardKeyCode = Enum.KeyCode.E`
     - `HoldDuration = 0`
     - `MaxActivationDistance = 12`
     - `RequiresLineOfSight = false`
4. **Network Ownership & Seat Occupant:**
   - On `seat:GetPropertyChangedSignal("Occupant")`:
     - If occupant exists, find `Player` from `occupant.Parent` and transfer network ownership of `seat.AssemblyRootPart or seat` via `pcall(root.SetNetworkOwner, root, player)`.
     - When occupant leaves, wait 0.1s, then if still unoccupied, reset network ownership to `nil` (`root:SetNetworkOwner(nil)`), reset linear/angular velocities to zero.
5. **Vehicle Attributes & GodMode:**
   - Set attributes `Health = 100`, `MaxHealth = 100`, `Fuel = 100`, `MaxFuel = 100`, `GodMode = true`.

### B. Client Driving Engine: `src/TeslaRoadster_Raycast/RaycastChassisClient.client.luau`
1. **Spacebar Sink & Jump Prevention:**
   - When local player enters `DriveSeat`, bind Spacebar via `ContextActionService:BindActionAtPriority("HokiRoadsterHandbrake", handleHandbrake, false, Enum.ContextActionPriority.High.Value + 3000, Enum.KeyCode.Space)`.
   - Return `Enum.ContextActionResult.Sink` so Spacebar is captured exclusively by the vehicle and never triggers `Humanoid.Jump`.
   - Temporarily disable `humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)` on entry; restore on exit.
2. **Dual-Input Responsive Controller:**
   - Read throttle from `seat.ThrottleFloat` + `UserInputService:IsKeyDown(Enum.KeyCode.W)` / `S` / `Up` / `Down`.
   - Read steer from `seat.SteerFloat` + `UserInputService:IsKeyDown(Enum.KeyCode.A)` / `D` / `Left` / `Right`.
   - Max speed: ~190 studs/s, Reverse speed: ~55 studs/s, Accel rate: ~110 studs/s², Brake rate: ~160 studs/s², Coast drag: ~25 studs/s².
3. **Raycast Ground Detection & Suspension:**
   - Target height: `TARGET_HEIGHT = 2.80` studs above ground.
   - Downward raycast from `seat.Position + Vector3.new(0, 1, 0)`.
   - Spring damping calculation for `targetVelY` when grounded.
   - Gravity acceleration `(196.2 * dt)` when airborne.
4. **Curb Climbing Assist:**
   - Forward raycast 3.5 studs in direction of travel at height +0.8 studs above ground.
   - If obstacle/curb detected with step height <= 2.1 studs and vehicle moving forward (`currentForwardSpeed > 2`), apply an automated upward boost `targetVelY = math.max(targetVelY, 16)` to climb over smoothly without sticking.
5. **Airborne Attitude Leveling:**
   - When airborne (`not isGrounded`), smoothly damp roll and pitch using `root.CFrame:VectorToObjectSpace(...)` so vehicle stays horizontally aligned with world space and lands safely.
6. **Steering, Drift & Lateral Grip:**
   - Normal steering: high grip, responsive turning rate.
   - Drift mode: active when Spacebar is held OR hard steer at high speed (`speed > 60` and `|steer| > 0.6`).
   - Lateral slip velocity applied in direction of drift.
7. **Cosmetic Wheels Animation:**
   - Animate all parts inside `car.Wheels` via `w:PivotTo(desired)`:
     - Front wheels (`FL`, `FR`): apply steer angle + wheel spin.
     - Rear wheels (`RL`, `RR`): apply wheel spin only.

## 4. Verification Target
- Verify with `rojo build --output scratch/test_build.rbxm` or Luau syntax test.
