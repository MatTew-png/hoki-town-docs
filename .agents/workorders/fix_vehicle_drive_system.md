# Work Order: Fix Vehicle Driving Systems (Car 1 A-Chassis & Car 2 Raycast Arcade)

## 1. Objective
Ensure both vehicles on `Hoki_Proving_Grounds` (`TeslaRoadster` and `TeslaRoadster_Raycast`) can be driven immediately by the player in Roblox Studio Play Solo mode upon sitting in `DriveSeat` with instant W/A/S/D response, forward acceleration, smooth steering, and reverse.

## 2. Target Files
- `src/TeslaRoadster/A-Chassis Tune/A-Chassis Interface/Drive.client.luau`
- `src/TeslaRoadster_Raycast/RaycastChassisClient.client.luau`

## 3. Implementation Requirements

### Module 1: Car 1 (A-Chassis v1.5+ Physical Drift Tune)
File: `src/TeslaRoadster/A-Chassis Tune/A-Chassis Interface/Drive.client.luau`
1. **Parking Brake & Neutral Lockout Fix:**
   - At initialization (around lines 214-250), ensure `_CGear` defaults to `1` (First Gear / Drive) when in Automatic mode (`_TMode == "Auto"`), and `_PBrake` is forced to `false` on driver entry.
   - In the drive loop (around lines 1300-1320), ensure any forward throttle (`_InThrot > 0.05` or `driveCommand > 0.05`) immediately releases the parking brake (`_PBrake = false`).
2. **Torque Delivery & Wheel AngularVelocity:**
   - In the wheel torque application block (lines 1610-1655), verify that `data.AV.MotorMaxTorque` receives full motor torque `tqOUT` when accelerating, and `data.AV.AngularVelocity = _spLimit * math.sign(_CGear)` is non-zero so all 4 driven wheels spin under physics simulation.

### Module 2: Car 2 (Raycast Arcade Chassis 2.0)
File: `src/TeslaRoadster_Raycast/RaycastChassisClient.client.luau`
1. **Direct Keyboard + VehicleSeat Dual-Input:**
   - In `RunService.PreSimulation`, read throttle from both `seat.ThrottleFloat` and `UserInputService:IsKeyDown(Enum.KeyCode.W)` / `S` / `Up` / `Down`.
   - Read steer from both `seat.SteerFloat` and `UserInputService:IsKeyDown(Enum.KeyCode.A)` / `D` / `Left` / `Right`.
   - This guarantees 100% immediate responsive input regardless of Roblox Gui/Seat focus state.
2. **Stable Arcade Hover / Ground Conformity:**
   - Target height for `DriveSeat`: `TARGET_HEIGHT = 2.80` studs above ground.
   - Use a damped PD spring for vertical velocity:
     `local heightDiff = (rayResult.Position.Y + TARGET_HEIGHT) - seat.Position.Y`
     `local targetVelY = math.clamp(heightDiff * 14 - (root.AssemblyLinearVelocity.Y * 0.3), -30, 30)`
3. **AssemblyRootPart Physics Application:**
   - Resolve `local root = seat.AssemblyRootPart or seat`.
   - Set `root.AssemblyLinearVelocity = finalLinearVel`
   - Set `root.AssemblyAngularVelocity = Vector3.new(0, yawVelocity, 0)`
4. **Visual Wheel Meshes Steering & Spin:**
   - Smoothly update `wheelSpinAngle` and `currentSteerAngle`.
   - For all wheels in `car.Wheels`, apply CFrame relative rotation to visual wheel attachments or parts so front wheels steer and all wheels spin in direction of motion.

## 4. Verification Target
Run Rojo build check:
`rojo build --output scratch/test_build.rbxm`
