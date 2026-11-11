# Work Order: Remove Temp Diag Hook & Stabilize `probeWheels` Euler/ARB Solver

## 1. Objective
1. Remove the temporary `ReplicatedStorage:FindFirstChild("__Diag")` debug block from `updateForces` in `src/TeslaRoadster_Raycast/RaycastVehiclePhysics.luau`.
2. Fix the empirically observed `FRAME_01..FRAME_17` `probeWheels` launch instability (`dt = 0.050s` explicit Euler gain + negative-compression damper wall + non-conservative anti-roll bar when opposite wheel lifts).

## 2. Target Files
- `src/TeslaRoadster_Raycast/RaycastVehiclePhysics.luau`

## 3. Exact Specifications for `src/TeslaRoadster_Raycast/RaycastVehiclePhysics.luau`
1. In `updateForces` (right after `updateTelemetry(self, throttle, steer, longitudinalSpeed)`), delete the temporary `local diag = ReplicatedStorage:FindFirstChild("__Diag")` block cleanly so `if grounded == 0 then` immediately follows `updateTelemetry(...)`.
2. In `probeWheels(self: ControllerData, dt: number, now: number)`:
   - Keep `DEFAULTS.RestLength = 2.4` and `DEFAULTS.SpringTravel = 0.9` untouched, and compute `safeDt = math.max(dt, 1 / 60)`.
   - Compute mass-normalized spring & Euler-stable stiffness:
     - `local wheelMass = math.max(root.AssemblyMass * 0.25, 1)`
     - `local rawStiffness = (wheelMass * Workspace.Gravity) / 0.40`
     - `local maxStableStiffness = (0.35 * wheelMass) / (safeDt * safeDt)`
     - `local springStiffness = math.min(rawStiffness, maxStableStiffness)`
     - `local cCrit = 2 * math.sqrt(springStiffness * wheelMass)`
     - `local damper = math.min(0.65 * cCrit * springMultiplier, 0.50 * wheelMass / safeDt)`
     - `local maxWheelNormalLoad = wheelMass * Workspace.Gravity * 2.5`
   - Inside the per-wheel `if hit then` block:
     - Keep `wheel.suspensionOffset = compression` in `[-config.SpringTravel, config.SpringTravel]` for visual droop/compression, OR clamp active compression `local activeCompression = math.max(compression, 0)`.
     - Blend damper smoothly as the tire contacts (`local contactBlend = clamp(activeCompression / 0.12, 0, 1)`), so extended wheels (`compression <= 0`) do NOT hit a sudden damper wall (`19kN` at `c = -0.90`!):
       `local force = if activeCompression > 0 then springStiffness * activeCompression - (damper * contactBlend) * compressionVelocity else 0`
     - Cap individual wheel force before ARB:
       `wheel.normalLoad = clamp(force, 0, maxWheelNormalLoad)`
   - Replace the Anti-Roll Bar load transfer (lines ~516-521) with strictly force-conserving symmetric transfer that ONLY operates when BOTH wheels on that axle are grounded (`normalLoad > 0`):
     ```lua
     if frontLeft.grounded and frontRight.grounded then
         local rawFrontArb = (frontLeft.compression - frontRight.compression) * springStiffness * self.stats.AntiRollRatio
         local frontTransfer = clamp(rawFrontArb, -frontLeft.normalLoad, frontRight.normalLoad)
         frontLeft.normalLoad = clamp(frontLeft.normalLoad + frontTransfer, 0, maxWheelNormalLoad)
         frontRight.normalLoad = clamp(frontRight.normalLoad - frontTransfer, 0, maxWheelNormalLoad)
     end
     if rearLeft.grounded and rearRight.grounded then
         local rawRearArb = (rearLeft.compression - rearRight.compression) * springStiffness * self.stats.AntiRollRatio
         local rearTransfer = clamp(rawRearArb, -rearLeft.normalLoad, rearRight.normalLoad)
         rearLeft.normalLoad = clamp(rearLeft.normalLoad + rearTransfer, 0, maxWheelNormalLoad)
         rearRight.normalLoad = clamp(rearRight.normalLoad - rearTransfer, 0, maxWheelNormalLoad)
     end
     ```

## 4. Verification Steps
1. `stylua --check src/ReplicatedStorage/VehicleStats.luau src/TeslaRoadster_Raycast/`
2. `selene src/ReplicatedStorage/VehicleStats.luau src/TeslaRoadster_Raycast/`
3. `rojo sourcemap default.project.json -o sourcemap.json && luau-lsp analyze --defs=globalTypes.d.luau --sourcemap=sourcemap.json src/ReplicatedStorage/VehicleStats.luau src/TeslaRoadster_Raycast/RaycastVehiclePhysics.luau src/TeslaRoadster_Raycast/RaycastChassisClient.server.luau src/TeslaRoadster_Raycast/RaycastChassisServer.server.luau src/TeslaRoadster_Raycast/VehicleSoundClient.server.luau src/TeslaRoadster_Raycast/VehicleColorClient.server.luau src/TeslaRoadster_Raycast/VehicleStatusClient.client.luau`
