# Work Order: Upgrade Front Steering Actuator to HingeConstraint Servo

## Why
Play Mode telemetry showed that `PowerSteeringType = "Old"` (`BodyGyro` in `Arm`, even at `SteerMaxTorque = 350000`) collapsed to ~`1°–2.8°` wheel angle when driving at `100–130 studs/s`, whereas switching `Base.Rotate` (`HingeConstraint`) to `Enum.ActuatorType.Servo` held exact target angles (`18°–22°` at 125 studs/s and `31°–35°` at low speed) with `maxBaseZ = 0.14°` and smooth body roll (`1.13°`).

## Files to Modify (Strictly Only These 3 Files)
1. `src/TeslaRoadster/A-Chassis Tune/init.luau`
2. `src/TeslaRoadster/A-Chassis Tune/Initialize.server.luau`
3. `src/TeslaRoadster/A-Chassis Tune/A-Chassis Interface/Drive.client.luau`

Do NOT touch `VehicleSystems.server.luau`, `VerticalSuspensionGuide` (`PrismaticConstraint`), `FCamber`/`RCamber`, or `ArcadeVisualWheelAngleLow`/`High` (`36`/`18`).

## Exact Edits

### 1. `src/TeslaRoadster/A-Chassis Tune/init.luau`
Around lines 278-285:
- Set `Tune.PowerSteeringType = "Servo" -- "Servo" uses Rotate HingeConstraint, "New" uses AlignOrientation, "Old" uses BodyGyro`
- Add right below `Tune.SteerMaxTorque`:
  ```lua
  Tune.SteerServoMaxTorque = 5000000 -- Rotate hinge servo torque for crisp steering under load
  Tune.SteerServoAngularSpeed = 24 -- Rotate hinge servo angular speed (rad/s)
  ```

### 2. `src/TeslaRoadster/A-Chassis Tune/Initialize.server.luau`
1. Around lines 560-592 (`if Tune.PowerSteeringType == "New" then ... else ...`):
   - Keep `"New"` branch unchanged.
   - In the `else` (`BodyGyro`) branch:
     When `Tune.PowerSteeringType == "Servo" and string.find(v.Name, "F")`, still create `steer = Instance.new("BodyGyro")` on `v.Arm` so `canSteer` / external checks never break, EXCEPT disable its torque (`steer.P = 0`, `steer.D = 0`, `steer.MaxTorque = Vector3.zero`) so it never fights the `Rotate` Servo! Otherwise keep existing `SteerP`/`SteerD`/`SteerMaxTorque` and `RSteer*`.
2. Around lines 607-615 (`rotationHinge`):
   - When `Tune.PowerSteeringType == "Servo" and string.find(v.Name, "F")`:
     ```lua
     rotationHinge.ActuatorType = Enum.ActuatorType.Servo
     rotationHinge.ServoMaxTorque = Tune.SteerServoMaxTorque or 5000000
     rotationHinge.AngularSpeed = Tune.SteerServoAngularSpeed or 24
     rotationHinge.TargetAngle = 0
     ```
3. Around lines 1193-1202 (driver exit readjust steering):
   - Handle `Tune.PowerSteeringType == "Servo"` cleanly:
     ```lua
     if Tune.PowerSteeringType == "Servo" then
         if wheel.Base:FindFirstChild("Rotate") and string.find(wheel.Name, "F") then
             wheel.Base.Rotate.TargetAngle = wheel.Base.Rotate.CurrentAngle
         end
     elseif wheel.Arm:FindFirstChild("Steer") then
         ...
     ```
     (Make sure if `wheel.Base:FindFirstChild("Rotate")` isn't used for rear wheels, it safely skips.)

### 3. `src/TeslaRoadster/A-Chassis Tune/A-Chassis Interface/Drive.client.luau`
1. In the `Wheels` setup loop (around lines 368-420):
   - Add `local rotate = base and base:FindFirstChild("Rotate") or nil`
   - Update `canSteer`:
     ```lua
     if arm and (steer or (rotate and _Tune.PowerSteeringType == "Servo")) then
         canSteer = v:GetAttribute("SteerDisabled") and 1 or 2
     end
     ```
   - Store `data.Rotate = rotate`.
2. In `Steering(dt)` `ArcadeSteering` branch (around lines 1268-1275):
   - Support `"Servo"` first:
     ```lua
     if _Tune.PowerSteeringType == "Servo" and data.Rotate then
         data.Rotate.TargetAngle = -angle
     elseif _Tune.PowerSteeringType == "New" then
         data.SteerAttach0.Orientation = Vector3.new(0, angle, 0)
     else
         data.Steer.CFrame = data.Base.CFrame * CFrame.Angles(0, -math.rad(angle), 0)
     end
     ```
3. In `Steering(dt)` non-Arcade branch (around lines 1375-1385):
   - Support `"Servo"` consistently (sibling sweep):
     ```lua
     if _Tune.PowerSteeringType == "Servo" and data.Rotate then
         data.Rotate.TargetAngle = data.CanSteer == 1 and 0 or -(_GSteerC * angle * rsteerVariableAngle)
     elseif _Tune.PowerSteeringType == "New" then
         ...
     ```

## Validation Commands
Run and ensure 0 errors:
1. `stylua --check "src/TeslaRoadster/A-Chassis Tune/init.luau" "src/TeslaRoadster/A-Chassis Tune/Initialize.server.luau" "src/TeslaRoadster/A-Chassis Tune/A-Chassis Interface/Drive.client.luau"` (format only those files if needed, then re-run `--check`).
2. `selene "src/TeslaRoadster/A-Chassis Tune/init.luau" "src/TeslaRoadster/A-Chassis Tune/Initialize.server.luau" "src/TeslaRoadster/A-Chassis Tune/A-Chassis Interface/Drive.client.luau"` (must show `0 errors` and `0 parse errors`).
