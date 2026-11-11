# Work Order: Implement NGChassis Engine for Car 3 (TeslaRoadster_NGChassis)

## 1. Objective
Create the modern **NGChassis (Next-Gen Chassis)** vehicle driving system for Car 3 (`Workspace.TeslaRoadster_NGChassis`) located on Lane 3 of `Hoki_Proving_Grounds`. The vehicle must respond immediately to W/A/S/D and arrow keys, feature smooth suspension ground conformity, deliver responsive arcade-drift handling, and animate visual wheel steering and rotation.

## 2. Target Files to Create
- `src/TeslaRoadster_NGChassis/NGChassisConfig.luau` (ModuleScript)
- `src/TeslaRoadster_NGChassis/NGChassisServer.server.luau` (Server Script)
- `src/TeslaRoadster_NGChassis/NGChassisClient.client.luau` (Client Script with RunContext = Client)

## 3. Specifications

### Module 1: `NGChassisConfig.luau`
Clean configuration table exporting:
- `TopSpeed = 190` (studs/second)
- `ReverseSpeed = 55`
- `Acceleration = 120`
- `BrakeRate = 170`
- `CoastDrag = 25`
- `TurnSpeed = 3.0`
- `DriftTurnSpeed = 4.2`
- `TargetHeight = 2.80` (ground clearance)
- `SpringStiffness = 15`
- `SpringDamping = 0.3`
- `MaxSteerAngle = math.rad(30)`

### Module 2: `NGChassisServer.server.luau`
Server authority script managing:
1. `DriveSeat` configuration: `Disabled = false`, `CanCollide = false`, `Transparency = 1`.
2. ProximityPrompt for entry: `ObjectText = "Tesla Roadster (NGChassis)"`, `ActionText = "ขับรถ (Drive)"`, `KeyCode = Enum.KeyCode.E`.
3. Network ownership: When `seat.Occupant` changes to a player character, set `(seat.AssemblyRootPart or seat):SetNetworkOwner(player)`. On exit, return ownership to `nil` and zero velocities.
4. Health & Fuel attributes: Initialize `Health = 100`, `MaxHealth = 100`, `Fuel = 100`, `MaxFuel = 100`.

### Module 3: `NGChassisClient.client.luau`
Client physics & input engine:
1. Detect driver seat occupancy (`seat.Occupant and seat.Occupant.Parent == localPlayer.Character`).
2. Read dual-input: keyboard (`W/S/A/D` + arrow keys) combined with `seat.ThrottleFloat` and `seat.SteerFloat`.
3. Ground raycast from `seat.Position + Vector3.new(0, 1, 0)` downward.
4. PD spring calculation for vertical velocity:
   `local heightDiff = (rayResult.Position.Y + Config.TargetHeight) - seat.Position.Y`
   `local targetVelY = math.clamp(heightDiff * Config.SpringStiffness - (root.AssemblyLinearVelocity.Y * Config.SpringDamping), -30, 30)`
5. Apply velocities to `root = seat.AssemblyRootPart or seat`:
   `root.AssemblyLinearVelocity = finalLinearVel`
   `root.AssemblyAngularVelocity = finalAngularVel`
6. Visual wheel transforms: cache relative wheel CFrames, apply steering rotation to front wheels (`FL`, `FR`) and spin rotation to all 4 wheels using `PivotTo`.

## 4. Verification Target
Run Rojo build check:
`rojo build --output scratch/test_build.rbxm`
Both build and syntax must pass cleanly with exit code 0.
