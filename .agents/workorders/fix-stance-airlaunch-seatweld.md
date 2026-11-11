# Work Order: Fix Stance, AirLaunch Bug, and SeatWeld Posture

## 1. Objective
Calibrate suspension tune values (`init.luau`), eliminate the zero-treated-as-6.0 upward launch bug (`Drive.client.luau`), and fix `SeatWeld.C0` vertical offset without stripping Roblox sitting rotation (`VehicleSystems.server.luau`).

## 2. Target Files
- Modify: `src/TeslaRoadster/A-Chassis Tune/init.luau`
- Modify: `src/TeslaRoadster/A-Chassis Tune/A-Chassis Interface/Drive.client.luau`
- Modify: `src/TeslaRoadster/VehicleSystems.server.luau`

## 3. Implementation Contract
1. **`src/TeslaRoadster/A-Chassis Tune/init.luau`**:
   - Under `--Front Strut` (around lines 144-152):
     - `Tune.FSusStiffness = 22.0`
     - `Tune.FSusDamping = 6.0`
     - `Tune.FSwayBar = 10.0`
     - `Tune.FSusLength = 1.35`
     - `Tune.FPreCompress = 0.08`
     - `Tune.FExtensionLim = 0.25`
     - `Tune.FCompressLim = 0.25`
   - Under `--Rear Strut` (around lines 153-162):
     - `Tune.RSusStiffness = 24.0`
     - `Tune.RSusDamping = 6.5`
     - `Tune.RSwayBar = 10.0`
     - `Tune.RSusLength = 1.40`
     - `Tune.RPreCompress = 0.08`
     - `Tune.RExtensionLim = 0.25`
     - `Tune.RCompressLim = 0.25`

2. **`src/TeslaRoadster/A-Chassis Tune/A-Chassis Interface/Drive.client.luau`**:
   - Around lines 2730-2745 (inside the ramp/airborne takeoff block):
   - Currently `_Tune.AirLaunchBaseBoost > 0` falls back to `6.0` when `AirLaunchBaseBoost == 0.0`.
   - Fix `baseBoost` and `speedScale` so `0` is respected when `_Tune.AirLaunchBaseBoost ~= nil` (do NOT coerce `0` to `6.0`). If `baseBoost <= 0 and (_Tune.AirLaunchBaseBoost == nil or _Tune.AirLaunchBaseBoost <= 0)`, only apply launch if `speedScale > 0` or skip impulse when `requestedBoost <= 0`. Preserve existing behavior when `_Tune.AirLaunchBaseBoost > 0`.

3. **`src/TeslaRoadster/VehicleSystems.server.luau`**:
   - Replace the `SeatWeld` `ChildAdded` handlers on `seat` and `passengerSeat` (around lines 43-58):
   - Do NOT overwrite `weld.C0 = CFrame.new(...)` (which strips Roblox's sitting rotation).
   - Instead, create a helper `applyCabinSeatOffset(targetSeat: Seat | VehicleSeat)` connected to `targetSeat.ChildAdded`:
     - When `child:IsA("Weld") and child.Name == "SeatWeld"`, schedule on `task.defer` (checking `child.Parent == targetSeat` and `not child:GetAttribute("HokiOffsetApplied")`), mark `child:SetAttribute("HokiOffsetApplied", true)`, and preserve rotation by shifting vertically in seat space: `child.C0 = CFrame.new(0, -0.75, -0.05) * child.C0`.

## 4. Verification Command
`stylua --check "src/TeslaRoadster/A-Chassis Tune/init.luau" "src/TeslaRoadster/A-Chassis Tune/A-Chassis Interface/Drive.client.luau" "src/TeslaRoadster/VehicleSystems.server.luau"`
(Note: if formatting fails, run `stylua` on the three target files first; `selene` is optional and may exit non-zero only on pre-existing `Enum.KeyCode.Unknown` deprecation warnings — confirm `0 errors` if you run `selene`.)
