# Work Order: stabilize-init-and-prismatic-base

## 1. Objective
Ensure `Initialize.server.luau` anchors all vehicle parts before `LoadDelay` / constraint teardown (preventing unanchored chassis/Body void drops), move the `PrismaticConstraint` hub attachment from the tiny `Hub` part onto the larger `base` spindle part, and raise `Tune.AxleDensity` slightly to eliminate PGS solver wheel-Z flex during high-speed turns.

## 2. Target Files
- Modify: `src/TeslaRoadster/A-Chassis Tune/init.luau`
- Modify: `src/TeslaRoadster/A-Chassis Tune/Initialize.server.luau`

## 3. Implementation Contract
1. In `src/TeslaRoadster/A-Chassis Tune/init.luau` (line 137):
   - Change `Tune.AxleDensity = 0.1` to `Tune.AxleDensity = 0.25`.
2. In `src/TeslaRoadster/A-Chassis Tune/Initialize.server.luau`:
   - Right after `seat.Disabled = false` (line 19, before `require` / `LoadDelay`), anchor all `BasePart` descendants in `car` (`desc.Anchored = true`) so unanchored workspace snapshots cannot fall before `Unanchor(car)` at line 844.
   - In the Zero-Duplicate Guard (around line 198-212), also destroy any `"PrismaticBaseAtt"` found on `v` or its descendants (in addition to `PrismaticHubAtt` and `PrismaticChassisAtt_`).
   - In `if SuspensionGeometry then` (lines 335-359): attach the `PrismaticConstraint` (`VerticalSuspensionGuide`) between `car.DriveSeat` (`chassisAtt` at `base.Position`) and `base` (`baseAtt` named `"PrismaticBaseAtt"` at `base.Position`, with `WorldAxis = car.DriveSeat.CFrame.UpVector` and `WorldSecondaryAxis = car.DriveSeat.CFrame.RightVector`) instead of the small `hub` part (keeping `MakeWeld(SuspensionGeometry.Hub, base)` intact).

## 4. Verification Command
`stylua --check "src/TeslaRoadster/A-Chassis Tune/init.luau" "src/TeslaRoadster/A-Chassis Tune/Initialize.server.luau" && selene "src/TeslaRoadster/A-Chassis Tune/init.luau" "src/TeslaRoadster/A-Chassis Tune/Initialize.server.luau"`
