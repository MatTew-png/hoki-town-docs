# Work Order: master-2026-wire-and-color

## 1. Objective
Wire `Workspace.Tesla_Roadster_Raycast_Master_2026` in Rojo alongside `Workspace.Tesla_Roadster_Base_2026`, and extend `VehicleColorService.ApplyFullPalette` so all vehicle trim/detail zones (rotors, tires, interior, taillights, and license plate) receive factory colors and materials cleanly at runtime as well as customizable palette zones.

## 2. Target Files
- Modify: `default.project.json`
- Modify: `src/ReplicatedStorage/VehicleColorService.luau`

## 3. Implementation Contract
- **`default.project.json`**:
  - Keep `"Tesla_Roadster_Base_2026"` inside `tree.Workspace` completely intact.
  - Add `"Tesla_Roadster_Raycast_Master_2026"` inside `tree.Workspace` directly after `"Tesla_Roadster_Base_2026"` with the exact same structure:
    - `"$className": "Model"`, `"$ignoreUnknownInstances": true`
    - `"RaycastChassisServer": { "$path": "src/TeslaRoadster_Raycast/RaycastChassisServer.server.luau" }`
    - `"RaycastChassisClient": { "$path": "src/TeslaRoadster_Raycast/RaycastChassisClient.server.luau" }`
    - `"RaycastVehiclePhysics": { "$path": "src/TeslaRoadster_Raycast/RaycastVehiclePhysics.luau" }`
    - `"VehicleColorClient": { "$path": "src/TeslaRoadster_Raycast/VehicleColorClient.server.luau" }`
    - `"VehicleSoundClient": { "$path": "src/TeslaRoadster_Raycast/VehicleSoundClient.server.luau" }`
    - `"CarStatusGui": { "$className": "ScreenGui", "$ignoreUnknownInstances": true, "VehicleStatusClient": { "$path": "src/TeslaRoadster_Raycast/VehicleStatusClient.client.luau" } }`
- **`src/ReplicatedStorage/VehicleColorService.luau`**:
  - Preserve existing public API (`ZONE_RULES`, `GetDefaultPalette`, `ApplyZoneColor`, `ApplyFullPalette`) and keep `GetDefaultPalette()` returning the existing 6-field `VehiclePalette` untouched (`Body_Main`, `Aero_Trim`, `Wheels_Rims`, `Brake_Calipers`, `Lights_DRL`, `Canopy_Glass`) so no existing callers break.
  - Add a `"License_Plate"` entry to `ZONE_RULES` targeting `parts = { "License_Plate" }` with `material = Enum.Material.SmoothPlastic` and `transparency = 0`.
  - Add a private `STATIC_ZONE_DEFAULTS: { [string]: Color3 }` table defining factory colors matching `Tesla_Roadster_Base_2026`:
    - `Brake_Rotors = Color3.fromRGB(180, 185, 190)`
    - `Tires = Color3.fromRGB(35, 35, 37)`
    - `Interior = Color3.fromRGB(245, 245, 245)`
    - `Lights_Tail = Color3.fromRGB(255, 60, 60)`
    - `License_Plate = Color3.fromRGB(240, 240, 240)`
  - Update `ApplyFullPalette(car: Model, palette: VehiclePalette)` to apply every zone in `STATIC_ZONE_DEFAULTS` (using `palette[zoneName]` if a caller explicitly passes an override, otherwise the static default) in addition to every zone/color pair present in `palette`, without mutating the caller's `palette` table. Also ensure strict `--!strict` Luau-LSP typing passes cleanly and `ApplyZoneColor` handles recursive `BasePart` lookup inside `car`.
- **Behavioral Invariants**:
  - Do not remove or alter `Tesla_Roadster_Base_2026` in `default.project.json`.
  - Match existing file formatting (tabs / StyLua rules in `.stylua.toml` if present, clean Selene lint, valid JSON).

## 4. Verification Command
`stylua --check src/ReplicatedStorage/VehicleColorService.luau && selene src/ReplicatedStorage/VehicleColorService.luau`
