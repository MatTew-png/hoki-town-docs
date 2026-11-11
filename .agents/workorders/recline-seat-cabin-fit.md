# Work Order: recline-seat-cabin-fit

## 1. Objective
Calibrate `applyCabinSeatOffset` in `src/TeslaRoadster/VehicleSystems.server.luau` so an R15 driver fits cleanly inside the low-slung Tesla Roadster cabin (head completely beneath the glass roof `Plane.005`, hips above the cabin floor, sporty reclined posture preserving sitting rotation).

## 2. Target Files
- Modify: `src/TeslaRoadster/VehicleSystems.server.luau`

## 3. Implementation Contract
- **Function:** `applyCabinSeatOffset(targetSeat: Seat | VehicleSeat)` (around line 45)
- **Exact Change:** Replace line 54 (`weld.C0 = CFrame.new(0, -0.75, -0.05) * weld.C0`) with:
  ```luau
  weld.C0 = CFrame.new(0, -0.88, -0.12) * CFrame.Angles(math.rad(20), 0, 0) * weld.C0
  ```
- **Behavioral Invariants:**
  - Keep `task.defer`, `HokiOffsetApplied` attribute guard, and left-multiplication order (`offset * angles * weld.C0`) intact so Roblox's sitting rotation on `SeatWeld.C0` is preserved and `Seat.LookVector` (`-Z`) gets a `+20 deg` backward recline (`UpVector.Z > 0`).
  - Do NOT modify any other function, variable, comment structure, or file.

## 4. Verification Command
`stylua --check src/TeslaRoadster/VehicleSystems.server.luau && selene src/TeslaRoadster/VehicleSystems.server.luau`
