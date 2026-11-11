# Work Order: hybrid-raycast-chassis-fixes

## 1. Objective
Apply 5 surgical physics, visual-pivot, and resource-cleanup fixes identified during code review of the Hybrid Raycast Chassis.

## 2. Target Files
- Modify: `src/ReplicatedStorage/VehicleStats.luau`
- Modify: `src/TeslaRoadster_Raycast/RaycastVehiclePhysics.luau`
- Modify: `src/TeslaRoadster_Raycast/RaycastChassisClient.client.luau`
- Modify: `src/TeslaRoadster_Raycast/VehicleSoundClient.client.luau`
- Modify: `src/TeslaRoadster_Raycast/VehicleStatusClient.client.luau`
- Modify: `sourcemap.json`

## 3. Implementation Contract
1. **`src/ReplicatedStorage/VehicleStats.luau`**:
   - Replace `AntiRollStiffness: number` in `ComputedVehicleStats` with `AntiRollRatio: number` (`lerp(0.25, 0.45, tier01(suspensionTier, 1, 5))`) so anti-roll scales proportionally with any chassis mass without causing wheel-lift instability on lightweight assemblies.
2. **`src/TeslaRoadster_Raycast/RaycastVehiclePhysics.luau`**:
   - Update `Stats` type (`AntiRollRatio: number` instead of `AntiRollStiffness: number`).
   - Fix mass-normalized suspension in `probeWheels(self, dt, now)`:
     - Keep `origin` fixed at the strut mount: `rootCFrame:PointToWorldSpace(Vector3.new(wheel.probePosition.X, wheel.probePosition.Y + config.RestLength, wheel.probePosition.Z))`.
     - Shrink `effectiveRadius = if popped then math.max(0.4, wheel.wheelRadius - 0.35) else wheel.wheelRadius` (so `restLength - suspensionDistance` genuinely drops the popped corner by 0.35 studs onto the rim instead of cancelling out!).
     - Compute `castLength = config.RestLength + config.SpringTravel + effectiveRadius + SPHERECAST_RADIUS` and `suspensionDistance = hit.Distance + SPHERECAST_RADIUS - effectiveRadius`, `compression = clamp(config.RestLength - suspensionDistance, -config.SpringTravel, config.SpringTravel)`.
     - Compute mass-normalized spring/damper: `wheelMass = math.max(root.AssemblyMass * 0.25, 1)`, `springStiffness = (wheelMass * Workspace.Gravity) / 0.30`, `cCrit = 2 * math.sqrt(springStiffness * wheelMass)`, `damper = math.min(0.75 * cCrit * springMultiplier, 0.70 * wheelMass / math.max(dt, 1 / 240))`.
     - Force: `force = springStiffness * math.max(compression, 0) - damper * compressionVelocity`.
     - Anti-roll: `frontArb = (frontLeft.compression - frontRight.compression) * springStiffness * self.stats.AntiRollRatio`, `rearArb = (rearLeft.compression - rearRight.compression) * springStiffness * self.stats.AntiRollRatio`.
     - Note: in `DEFAULTS`, remove unused `SpringStiffness` / `Damper` if no longer referenced (keep `selene` 0 warnings!).
   - Fix visual wheel & caliper hub pivoting in `captureVisualPart`, `resolveWheel`, and `updateVisuals`:
     - Store `relToHub: CFrame` (relative to the wheel's axle center `hubWorldCFrame = rootCFrame * CFrame.new(center)` aligned with chassis axes!): `captureVisualPart(hubWorldCFrame: CFrame, part: BasePart)` returns `{ part = part, relToHub = hubWorldCFrame:ToObjectSpace(part.CFrame) }`.
     - In `updateVisuals`: advance per-wheel or average spin angle using `wheel.wheelRadius` (or `self.wheelSpinAngle += forwardSpeed * dt`, and divide by `wheel.wheelRadius` per wheel!). Spin direction in Roblox (`-Z` forward, right-hand rule around `+X`) is `CFrame.Angles(-self.wheelSpinDistance / wheel.wheelRadius, 0, 0)`.
     - Position parts: `local hubPose = rootCFrame * CFrame.new(wheel.probePosition + offset) * steerPose`; for spinners: `spinner.part.CFrame = hubPose * spinRotation * spinner.relToHub`; for calipers: `caliper.part.CFrame = hubPose * caliper.relToHub` (fixes `(-180, 0, -180)` rotated meshes and prevents calipers from detaching during steering!).
3. **`src/TeslaRoadster_Raycast/RaycastChassisClient.client.luau`**:
   - Store all `RBXScriptConnection` handles (`heartbeatConn`, `destroyingConn`, `ancestryConn`) and disconnect them inside a `cleanup()` function when the vehicle is destroyed or removed from Workspace.
4. **`src/TeslaRoadster_Raycast/VehicleSoundClient.client.luau`**:
   - Store all connections (`renderConn`, `seatConn`, `ancestryConn`) and disconnect on `car.Destroying` / `car.AncestryChanged` (`car.Parent == nil`).
   - If `ClientRPM` attribute is `nil` (remote observer watching another driver), estimate fallback `rpm` & `throttle` cleanly from `seat.AssemblyLinearVelocity.Magnitude` so remote players hear realistic engine pitch too.
5. **`src/TeslaRoadster_Raycast/VehicleStatusClient.client.luau`**:
   - Store `inputConn`, `renderConn`, `destroyingConn`, `ancestryConn` and disconnect all on `gui.Destroying` or `car.Parent == nil` so re-entering the vehicle never leaks listeners or fires `repairRemote` multiple times.

## 4. Verification Command
`stylua src/ReplicatedStorage/VehicleStats.luau src/TeslaRoadster_Raycast/ && stylua --check src/ReplicatedStorage/VehicleStats.luau src/TeslaRoadster_Raycast/ && selene src/ReplicatedStorage/VehicleStats.luau src/TeslaRoadster_Raycast/ && rojo sourcemap default.project.json -o sourcemap.json && luau-lsp analyze --defs=globalTypes.d.luau --sourcemap=sourcemap.json src/ReplicatedStorage/VehicleStats.luau src/TeslaRoadster_Raycast/RaycastVehiclePhysics.luau src/TeslaRoadster_Raycast/RaycastChassisClient.client.luau src/TeslaRoadster_Raycast/RaycastChassisServer.server.luau src/TeslaRoadster_Raycast/VehicleSoundClient.client.luau src/TeslaRoadster_Raycast/VehicleStatusClient.client.luau`
