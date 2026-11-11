---
name: roblox-vehicle-scripting
description: Engineer, tune, and debug Roblox vehicle physics and driving scripts (A-Chassis constraints and custom Raycast/Spherecast chassis). Use when fixing steering collapse, wheel wobble/camber flex, suspension rebound explosions, SeatWeld posture, driver-chassis collision launch, Spacebar handbrake ejection, or dual-input and visual wheel pivoting.
---

# Roblox Vehicle Physics & Scripting

Field-tested engineering patterns for Roblox vehicle scripts across **Constraint/A-Chassis** rigs and **Raycast/Spherecast** chassis. Focuses on runtime Luau physics, seat/collision traps, and input/visual mechanics (see `roblox-3d-rigging-vehicles` for Blender/Studio 3D hierarchy assembly).

## 1. Choose & Partition the Driving Model

- **Constraint / A-Chassis (`Drive.client.luau` + `Initialize.server.luau`)**: Best for weighty physical suspension, mechanical springs, and authentic roll. Server creates joints/constraints and assigns network ownership; client drives actuators and inputs.
- **Raycast / Spherecast (`RaycastVehiclePhysics.luau`)**: Best for predictable arcade handling, crisp drift, and zero constraint-explosion risk. Server manages `Chassis_Collider` ownership, `DriveSeat`, and character collision guards; client runs the suspension/tire solver and updates visual wheel CFrames.

## 2. Constraint & A-Chassis PGS Stability

- **Anchor before `LoadDelay`**: At the top of `Initialize` (before `require` or `task.wait(Tune.LoadDelay)` and constraint teardown), anchor every `BasePart` descendant in the vehicle model so unwelded wheels or chassis snapshots never drop into the void before `Unanchor(car)` runs.
- **Upgrade Steering from `BodyGyro` to `HingeConstraint` Servo**: `BodyGyro` (`PowerSteeringType = "Old"`) collapses to ~1°–3° wheel angle under tire scrub at high speed. Configure `Base.Rotate` as `Enum.ActuatorType.Servo` (`SteerServoMaxTorque` ~`5_000_000`, `AngularSpeed` ~`24`), disable any residual `BodyGyro` (`MaxTorque = Vector3.zero`), and drive `TargetAngle` with Ackermann inner/outer scaling (`ackermannRatio = clamp(SteerOuter / SteerInner, 0.72, 1)`).
- **Lock Camber Flex with Vertical `PrismaticConstraint`**: Multi-hinge wishbones flex on the Z axis during hard cornering. Replace wishbone arms with a `PrismaticConstraint` (`VerticalSuspensionGuide`) between `DriveSeat` and the spindle `Base` (`WorldAxis = DriveSeat.CFrame.UpVector`, `WorldSecondaryAxis = DriveSeat.CFrame.RightVector`), keep `Spring` and `SwayBar` attached to `Hub`, set `FCamber = 0` / `RCamber = 0`, and raise `AxleDensity` (e.g. `0.25`) to prevent PGS wheel wobble.
- **Clean Up Duplicate Attachments**: Before rebuilding suspension constraints on init, explicitly purge previous `PrismaticConstraint` and custom attachment names (`PrismaticHubAtt`, `PrismaticBaseAtt`, `PrismaticChassisAtt_*`) so re-initializing never leaves conflicting joints.

## 3. Raycast / Spherecast Solver Stability

- **Explicit Euler `dt`-Cap & Contact-Blended Damper**: Cap suspension stiffness against frame timestep so slow frames (`dt = 0.05s`) never explode upward:
  - `wheelMass = math.max(root.AssemblyMass * 0.25, 1)`
  - `maxStableStiffness = (0.35 * wheelMass) / (safeDt * safeDt)`
  - `damper = math.min(0.65 * cCrit * springMultiplier, 0.50 * wheelMass / safeDt)`
  - Blend damping near zero compression (`contactBlend = clamp(activeCompression / 0.12, 0, 1)`) and zero out spring/damper when `activeCompression <= 0` so extended wheels never hit a negative-compression damper wall.
- **Force-Conserving Anti-Roll Bar (ARB)**: Apply ARB load transfer on an axle *only* when both wheels (`FL/FR` or `RL/RR`) are grounded, clamping transfer within `[-left.normalLoad, right.normalLoad]` so a lifted wheel never pulls the chassis sideways.
- **Impulse-Bounded Low-Speed Friction**: At rest or near-zero speed, raw lateral tire curves and `math.sign(vLong)` drag oscillate via Euler overshoot. Clamp lateral force by `maxStopLateral = (math.abs(lateralSpeed) * wheelMassShare / safeDt) * 0.55` and smooth longitudinal sign with `clamp(vLong / 2.0, -1, 1)`.
- **Corner Velocity on Touchdown**: Measure vertical contact velocity at each wheel corner via `root:GetVelocityAtPosition(wheel.forceAttachment.WorldPosition).Y` instead of center-of-mass velocity so pitch/roll angular velocity damps cleanly on landing.

## 4. Seat, Collision, Input & Visual Contracts

- **Prevent Seat-Entry Launch & Void Floor Bugs**:
  - Size `DriveSeat` as a slim cabin pad (`CanCollide = false`, `Transparency = 1`) at seat height—never leave a thick, collidable mesh at axle level.
  - When a player sits, attach `NoCollisionConstraint` between `Chassis_Collider` and every `BasePart` in `player.Character` *before* unanchoring `DriveSeat`, and clear those constraints on exit or `Destroying`.
- **Preserve Sitting Rotation on `SeatWeld.C0`**: Never assign `weld.C0 = CFrame.new(...)` directly (strips Roblox's built-in sitting orientation). Defer one step with `task.defer`, guard idempotency with an attribute (`HokiOffsetApplied`), and left-multiply `CFrame.new(offset) * CFrame.Angles(reclineRad, 0, 0) * weld.C0`.
- **Dual-Input Without Sticky Steering**: Read both `UserInputService` keys and `seat.ThrottleFloat` / `seat.SteerFloat`, tracking a `_SeatSteerActive` boolean so steering resets cleanly to `0` when `seatSteer` returns to neutral.
- **Sink Spacebar for Handbrake**: While seated, bind `Space` at `Enum.ContextActionPriority.High.Value + 3000` returning `Enum.ContextActionResult.Sink` and disable `HumanoidStateType.Jumping` (restoring it on exit) so drifting never ejects the driver.
- **Respect Explicit `0` Tuning Values**: Check `val ~= nil` rather than `val > 0` or `val or fallback` when `0` is a valid disable setting (e.g. `AirLaunchBaseBoost = 0`).
- **Hub-Relative Visual Pivots (`relToHub`)**: Keep visual wheels, brake rotors, and calipers `Anchored = true`, `CanCollide = false`, unwelded from the chassis. Capture `relToHub = hubWorldCFrame:ToObjectSpace(part.CFrame)` at init:
  - Calipers steer in yaw only: `hubPose * caliper.relToHub`
  - Wheels/rotors steer and spin: `hubPose * CFrame.Angles(-spinDist / wheelRadius, 0, 0) * spinner.relToHub`
- **Auto-Create Missing Interface Events**: Guard optional `BindableEvent`/`RemoteEvent` references (e.g. `VirtualInput`, `Sounds`) with `FindFirstChild` + safe creation/noop listener so missing Studio sub-instances never halt the drive loop or spam discarded remote warnings.

## 5. Verification Gate

1. **Static**: Run `stylua --check`, `selene`, and `luau-lsp analyze` on modified vehicle scripts (target `0` errors).
2. **Runtime (Studio Play Mode)**: Confirm `4/4` wheels grounded at spawn, driver sits with zero upward launch impulse, steering reaches target `Rotate.CurrentAngle` under speed, and Spacebar engages handbrake without unseating.
