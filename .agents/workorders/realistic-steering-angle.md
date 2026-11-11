# Work Order: Realistic Front Wheel Steering Angle & Torque Authority

## Goal
Make `TeslaRoadster`'s front wheels (`FL`, `FR`) steer clearly, smoothly, and realistically at both low and driving speeds in Arcade mode (matching turn direction with Ackermann inside/outside wheel geometry and full steering torque authority so tire friction doesn't collapse the steering angle down to ~8-9°), while keeping the existing vertical `PrismaticConstraint` (`VerticalSuspensionGuide`), `0°` wheel Z-camber, cabin seating posture, and chassis roll/spring behavior completely untouched.

## Files to Modify (Strictly Only These 2 Files)
1. `src/TeslaRoadster/A-Chassis Tune/init.luau`
2. `src/TeslaRoadster/A-Chassis Tune/A-Chassis Interface/Drive.client.luau`

Do NOT modify `Initialize.server.luau` or `VehicleSystems.server.luau` or any other files.

## Exact Changes

### 1. `src/TeslaRoadster/A-Chassis Tune/init.luau`
Inspect around lines 24-50 and lines 270-290 first, then make minimal surgical edits preserving all unrelated Thai comments and settings:
- Under `Config` (`ArcadeVisualWheelAngleLow` / `ArcadeVisualWheelAngleHigh`):
  - Change `ArcadeVisualWheelAngleLow = 18` -> `ArcadeVisualWheelAngleLow = 36` (matches `MaxSteerAngle = 36` and `Rotate` hinge limits `±36°` at slow/parking speed).
  - Change `ArcadeVisualWheelAngleHigh = 8` -> `ArcadeVisualWheelAngleHigh = 18` (clearly visible front wheel turn even at `140+ km/h`, and ~`26-28°` at mid-speed cruising).
- Keep `FCamber = 0`, `RCamber = 0`, `AxleDensity = 0.25`, and all suspension/seat settings untouched.
- Under `Steering aggressiveness`:
  - Update `Tune.SteerOuter` (around line 270? inspect exact line first; currently `Config.MaxSteerAngle * 0.92`) -> `Config.MaxSteerAngle * 0.86` (realistic Ackermann ~`31°` outer vs `36°` inner). Wait: inspect line where `SteerOuter` is defined; keep `MaxSteerAngle = 36` and `SteerInner = Config.MaxSteerAngle`.
  - Update `Tune.SteerD = 1000` -> `Tune.SteerD = 3500`
  - Update `Tune.SteerP = 50000` -> `Tune.SteerP = 150000`
  - Update `Tune.SteerMaxTorque = 20000` -> `Tune.SteerMaxTorque = 350000` (strong enough that moving tire scrub cannot push the front wheels back from `25-36°` to `8°`).

### 2. `src/TeslaRoadster/A-Chassis Tune/A-Chassis Interface/Drive.client.luau`
Inspect around lines 1118-1160 and lines 1230-1256 first, then apply two surgical improvements:

#### A. Fix `seatSteer` sticky latch in `Inputs(dt)` (around lines 1152-1154)
Currently:
```lua
	if _GSteerT == 0 and math.abs(seatSteer) > 0.05 then
		_GSteerT = seatSteer
	end
```
Once `seatSteer` sets `_GSteerT`, `_GSteerT` never resets to `0` or flips sign if `seatSteer` changes unless keyboard keys are pressed/released.
Track a module/upvalue `local _SeatSteerActive = false` just above `Inputs(dt)`:
```lua
	if not _SteerL and not _SteerR and not _MSteer then
		if math.abs(seatSteer) > 0.05 then
			_SeatSteerActive = true
			_GSteerT = math.clamp(seatSteer, -1, 1)
		elseif _SeatSteerActive then
			_SeatSteerActive = false
			_GSteerT = 0
		end
	else
		_SeatSteerActive = false
	end
```
Notice this never interferes with keyboard (`_SteerL`/`_SteerR`), mobile tap buttons (`_SteerL`/`_SteerR`), mouse steer (`_MSteer`), or gamepad (`InputChanged` while `seatSteer == 0`).

#### B. Snappier response + Ackermann inner/outer ratio in `Steering(dt)` (`if _Tune.ArcadeSteering then ...`, around lines 1233-1255)
1. Change `local visualResponse = 1 - math.exp(-12 * dt)` to `local visualResponse = 1 - math.exp(-14 * dt)`.
2. Compute Ackermann ratio from `_Tune`:
```lua
		local maxVisAngle = math.min(visualAngle, _Tune.SteerInner or visualAngle)
		local ackermannRatio = (_Tune.SteerInner and _Tune.SteerInner > 0 and _Tune.SteerOuter)
			and math.clamp(_Tune.SteerOuter / _Tune.SteerInner, 0.72, 1)
			or 0.86
```
And inside `for _, data in Wheels do` (`if data.CanSteer ~= 0 then`):
- When turning right (`arcadeWheelSteer > 0`), `FR` is the inner wheel (`1.0`), `FL` is the outer wheel (`ackermannRatio`).
- When turning left (`arcadeWheelSteer < 0`), `FL` is the inner wheel (`1.0`), `FR` is the outer wheel (`ackermannRatio`).
```lua
			if data.CanSteer ~= 0 then
				local sideRatio = 1
				if data.isFront then
					if data.Name == "FL" then
						sideRatio = arcadeWheelSteer < 0 and 1 or ackermannRatio
					elseif data.Name == "FR" then
						sideRatio = arcadeWheelSteer > 0 and 1 or ackermannRatio
					end
				end
				local angle = data.isFront and arcadeWheelSteer * maxVisAngle * sideRatio or 0
```
Wait: double-check `local steerTarget = arcadeWheelSteer * visualAngle * sideRatio` (clamped safely within `±(_Tune.SteerInner or 36)` so `Rotate.LowerAngle`/`UpperAngle` (`±36°`) aren't exceeded). Using:
`local wheelMag = math.clamp(visualAngle, 0, _Tune.SteerInner or visualAngle)`
`local angle = data.isFront and arcadeWheelSteer * wheelMag * sideRatio or 0`
keeps `angle` clean even if `ArcadeVisualWheelAngleLow` is tuned later.

## Validation Commands
After editing, run BOTH checks from workspace root and require 0 errors:
1. `stylua --check "src/TeslaRoadster/A-Chassis Tune/init.luau" "src/TeslaRoadster/A-Chassis Tune/A-Chassis Interface/Drive.client.luau"` (if formatting check fails, run `stylua` on ONLY those two files, then re-verify `--check`).
2. `selene "src/TeslaRoadster/A-Chassis Tune/init.luau" "src/TeslaRoadster/A-Chassis Tune/A-Chassis Interface/Drive.client.luau"` (check 0 parse errors / no newly introduced errors).

Report exact file paths, line numbers, diffs, and validation outputs.
