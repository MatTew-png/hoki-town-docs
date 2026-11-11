# Work Order: vertical-suspension-and-feet

## 1. Objective
Eliminate wheel Z-axis camber tilt/flex during cornering by replacing the 4-hinge wishbone arms with a vertical `PrismaticConstraint` guide on `SuspensionGeometry.Hub` (preserving `Spring` and `SwayBar` body suspension physics and X/Y wheel rotation only), zero static camber (`FCamber`/`RCamber`), and raise/recline the driver `SeatWeld.C0` offset so the driver's shoes stay above the front bumper while head stays under the glass roof.

## 2. Target Files
- Modify: `src/TeslaRoadster/A-Chassis Tune/init.luau`
- Modify: `src/TeslaRoadster/A-Chassis Tune/Initialize.server.luau`
- Modify: `src/TeslaRoadster/VehicleSystems.server.luau`

## 3. Implementation Contract
1. In `src/TeslaRoadster/A-Chassis Tune/init.luau` (lines 108-109):
   - Set `Tune.FCamber = 0` and `Tune.RCamber = 0`.
2. In `src/TeslaRoadster/A-Chassis Tune/Initialize.server.luau`:
   - In the Zero-Duplicate Guard loop (lines 196-204), also remove any `PrismaticConstraint` or `Attachment` named `PrismaticHubAtt` inside `sg`, and remove `car.DriveSeat:FindFirstChild("PrismaticChassisAtt_" .. v.Name)` if present.
   - Inside `if SuspensionGeometry then` (around line 315, right after `MakeWeld(SuspensionGeometry.Hub, base)` and `SpringTop` weld):
     - Destroy `"UpperArm"` and `"LowerArm"` inside `SuspensionGeometry` (so double-wishbone hinges cannot flex/tilt wheels around Z during cornering; `Spring` attaches to `Hub.LowerAttachment` and `Weld.SpringTopWeld.Attachment`, and `SwayBar` attaches to `Hub.SwayBarAttachment`, both remain intact).
     - Create `"PrismaticChassisAtt_" .. v.Name` on `car.DriveSeat` and `"PrismaticHubAtt"` on `hub` (`SuspensionGeometry:FindFirstChild("Hub")`), both positioned at `hub.Position` with `WorldAxis = car.DriveSeat.CFrame.UpVector` and `WorldSecondaryAxis = car.DriveSeat.CFrame.RightVector`.
     - Create `PrismaticConstraint` named `"VerticalSuspensionGuide"` parented to `SuspensionGeometry` connecting `chassisAtt` (`Attachment0`) and `hubAtt` (`Attachment1`), with `LimitsEnabled = true`, `LowerLimit = -(isFront and Tune.FExtensionLim or Tune.RExtensionLim) - 0.35`, `UpperLimit = (isFront and Tune.FCompressLim or Tune.RCompressLim) + 0.45`, and `Visible = Tune.SusVisible`.
3. In `src/TeslaRoadster/VehicleSystems.server.luau` (line 54):
   - Update `weld.C0 = CFrame.new(0, -0.88, -0.12) * CFrame.Angles(math.rad(20), 0, 0) * weld.C0` to:
     `weld.C0 = CFrame.new(0, -0.64, -0.10) * CFrame.Angles(math.rad(26), 0, 0) * weld.C0`

## 4. Verification Command
`stylua --check "src/TeslaRoadster/A-Chassis Tune/init.luau" "src/TeslaRoadster/A-Chassis Tune/Initialize.server.luau" src/TeslaRoadster/VehicleSystems.server.luau && selene "src/TeslaRoadster/A-Chassis Tune/init.luau" "src/TeslaRoadster/A-Chassis Tune/Initialize.server.luau" src/TeslaRoadster/VehicleSystems.server.luau`
