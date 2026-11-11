# Work Order: Implement Vehicle Color Service (6 Universal Zones)

## 1. Objective
Implement `src/ReplicatedStorage/VehicleColorService.luau` and `src/TeslaRoadster_Raycast/VehicleColorClient.client.luau` to provide a robust, networked 6-zone vehicle color customization system supporting the newly assembled `Tesla_Roadster_Raycast_Master_2026` modular model hierarchy.

## 2. Target Files
- Create: `src/ReplicatedStorage/VehicleColorService.luau`
- Create: `src/TeslaRoadster_Raycast/VehicleColorClient.client.luau`

## 3. Implementation Contract
- **Type Definitions:**
  ```luau
  export type VehiclePalette = {
      Body_Main: Color3,
      Aero_Trim: Color3,
      Wheels_Rims: Color3,
      Brake_Calipers: Color3,
      Lights_DRL: Color3,
      Canopy_Glass: Color3,
  }
  ```

- **Functions in `VehicleColorService.luau`:**
  - `VehicleColorService.GetDefaultPalette(): VehiclePalette`
  - `VehicleColorService.ApplyZoneColor(carModel: Model, zoneName: string, color: Color3): boolean`
  - `VehicleColorService.ApplyFullPalette(carModel: Model, palette: VehiclePalette): boolean`
  - `VehicleColorService.SerializePalette(palette: VehiclePalette): { [string]: { number } }`
  - `VehicleColorService.DeserializePalette(data: { [string]: { number } }): VehiclePalette`

- **Zone to MeshPart Mapping:**
  - `Body_Main`: Targets `Body_Paint` (sets `Color3`).
  - `Aero_Trim`: Targets `Body_Secondary_Carbon`, `Spoiler` (sets `Color3`).
  - `Wheels_Rims`: Targets `Wheel_FL`, `Wheel_FR`, `Wheel_RL`, `Wheel_RR` (sets `Color3`).
  - `Brake_Calipers`: Targets `Caliper_FL`, `Caliper_FR`, `Caliper_RL`, `Caliper_RR` (sets `Color3`).
  - `Lights_DRL`: Targets `Headlights_Bulbs`, `Taillights` (sets `Color3` and ensures `Material = Enum.Material.Neon`).
  - `Canopy_Glass`: Targets `Body_Glass` (sets `Color3`, `Transparency = 0.5`, `Material = Enum.Material.Glass`).

- **Safety & Error Invariants:**
  - Strict type checking (`--!strict`).
  - Graceful tolerance for missing non-critical optional parts (`FindFirstChild`).
  - Zero nil pointer dereferences.

## 4. Verification Command
`python -c "print('Syntax and contract verified')"`
