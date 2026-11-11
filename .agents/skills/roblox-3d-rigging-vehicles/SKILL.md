---
name: roblox-3d-rigging-vehicles
description: Complete end-to-end 3D vehicle rigging pipeline for Roblox Studio and Blender. Covers Modular Physics Constraint Rigging (Springs, Hinges, Cylindrical), Skinned Bone/Armature Rigging (Bones, Motor6D, Vertex Groups), Wheel Origin/Pivot Calibration, Collision Matrix, and Center of Mass tuning.
---

# 🏎️ Roblox 3D Vehicle Rigging & Assembly Pipeline

This skill provides the definitive engineering standard for rigging, assembling, and calibrating 3D vehicles for Roblox Studio (from Blender 3D modeling down to physics simulation).

---

## 🛠️ 1. Two Primary Vehicle Rigging Architectures

Roblox vehicles operate under one of two core rigging paradigms:

```
                          Vehicle Rigging Paradigms
                                     │
           ┌─────────────────────────┴─────────────────────────┐
           ▼                                                   ▼
   [Type A: Modular Constraint Rig]                 [Type B: Skinned Bone Rig]
   • Physics-driven (A-Chassis / Spring)            • Animation/CFrame-driven (Raycast / Arcade)
   • Separate parts joined by Constraints          • Single mesh with Armature / Bones
   • Wheel spin via Hinge / Cylindrical             • Wheels animated via Bone rotation
   • Physical suspension rebound                    • Zero constraint flinging / 100% stable
```

---

## 📐 2. Architecture A: Modular Physics Constraint Rig (A-Chassis / Heavy Physics)

Used when vehicles require authentic physical spring suspension, double wishbone geometry, and mechanical collision.

### A. DataModel Hierarchy Contract
```
Vehicle_Model (Model)
├── Chassis_Collider (BasePart) [PrimaryPart: Massless=false, CanCollide=true, Density=1.5-3.0]
├── DriveSeat (VehicleSeat) [CanCollide=false, Massless=true, Welded to Chassis_Collider]
├── Body (Model / Folder)
│   ├── Body_Paint, Glass, Interior, Trim, etc.
│   └── (All parts: CanCollide=false, Massless=true, WeldConstraint to Chassis_Collider)
├── Wheels (Model / Folder)
│   ├── FL, FR, RL, RR (BasePart: CanCollide=true, CustomPhysicalProperties: Friction=1.5-2.0, Elasticity=0)
└── Suspension / Constraints
    ├── SpringConstraints (4x: FreeLength, Stiffness, Damping)
    └── HingeConstraints (Steering Servos + Wheel Rotations)
```

### B. Suspension & Ride Height Calibration
1. **FreeLength vs Stiff:**
   - Always set `SpringConstraint.FreeLength` equal to the resting distance between upper chassis mount and wheel hub.
   - Setting `FreeLength` too long causes the **Monster Truck Lift** bug.
2. **Center of Mass (CoM):**
   - Place a heavy ballast `#Weight` or set `Chassis_Collider` density so the center of mass sits **below the wheel axle center** (0.5 - 0.8 studs above asphalt).
   - This prevents rollover during high-G arcade cornering.

---

## 🦴 3. Architecture B: Skinned Bone / Armature Rig (Raycast & AAA Arcade)

Used when vehicles require 100% stable physics with zero constraint glitches, or custom cosmetic door/spoiler animations.

### A. Blender Armature Structure
```
Root_Bone (Origin at (0, 0, 0), world center between axles)
├── Chassis_Bone (Skin weights: Body_Paint, Interior, Glass)
├── Wheel_Bone_FL (At front-left wheel cylinder center)
├── Wheel_Bone_FR (At front-right wheel cylinder center)
├── Wheel_Bone_RL (At rear-left wheel cylinder center)
├── Wheel_Bone_RR (At rear-right wheel cylinder center)
├── Steering_Bone (Along steering column rotation axis)
├── Door_L_Bone (At driver door hinge line)
└── Spoiler_Bone (For active aerodynamics)
```

### B. Ingesting into Roblox Studio
1. Export FBX from Blender: `Apply Transform = true`, `Bake Animations = true`, `Armature Primary Bone Axis = -Y`, `Secondary = X`.
2. Import via **Roblox 3D Importer** > Enable **Skinning** and **Rigging**.
3. Result: In Studio, `Bone` instances appear under the MeshPart. Rotate bones directly via Luau `RunService.Heartbeat` without physical joint instability.

---

## ⚙️ 4. Wheel Origin & Pivot Alignment SOP (Blender ➡️ Studio)

The #1 cause of wobbly wheels or misaligned suspension is incorrect pivot origins.

### Blender Step-by-Step Calibration:
1. **Combine Wheel Components:** Join `Rim`, `Tire`, and `Brake_Rotor` into a single object (`FL`, `FR`, `RL`, `RR`).
2. **Find Geometric Center:**
   - Select the outer perimeter circular edge of the tire or rim in Edit Mode.
   - Press `Shift + S` ➡️ **Cursor to Selected**.
3. **Set Object Origin:**
   - Switch to Object Mode.
   - Right-click ➡️ **Set Origin ➡️ Origin to 3D Cursor**.
4. **Orientation Standard:**
   - Wheel spin axis MUST align cleanly with the local X or Y axis.
   - Run `Ctrl + A` ➡️ **Apply Rotation & Scale**.

---

## 🛡️ 5. Collision Matrix & Anti-Glitch Checklist

| Component | CanCollide | Massless | CanTouch | Role |
| :--- | :---: | :---: | :---: | :--- |
| `Chassis_Collider` | **true** | **false** | false | Main physics collider, bottom hull |
| `Wheels (FL/FR/RL/RR)` | **true** | **false** | true | Road contact and traction |
| `DriveSeat` | **false** | **true** | false | Player sitting; prevent road snagging |
| `Body_Paint` | **false** | **true** | false | Visual only; prevent wall snagging |
| `Glass & Trim` | **false** | **true** | false | Visual only |
| `Sensors (Front/Rear)` | **false** | **true** | true | Impact damage detection via spatial query |

### ⚠️ Common Pitfalls:
* **Avatar Hanging Upside-Down / Fling:** Occurs when `DriveSeat.CanCollide = true` and the seat penetrates the road collision layer. Always enforce `DriveSeat.CanCollide = false`.
* **Monster Truck Suspension:** Occurs when `SpringConstraint` FreeLength is uncalibrated or springs push unanchored cosmetic parts.
* **Ghost Occupant Lock:** Phantom `SeatWeld` leaves `DriveSeat.Occupant ~= nil`, blocking new players from sitting. Always clean stale `SeatWeld` on player exit.
