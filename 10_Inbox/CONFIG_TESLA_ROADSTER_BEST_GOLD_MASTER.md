---
title: "Tesla Roadster Best Gold Master Tune Configuration"
type: "configuration"
status: "verified"
tags:
  - "vehicle"
  - "tuning"
  - "a-chassis"
  - "tesla-roadster"
created: "2026-11-09"
updated: "2026-11-09"
---

# 🏎️ Tesla Roadster Best Gold Master Configuration

> [!IMPORTANT]
> บันทึกค่าคอนฟิกและพารามิเตอร์ของ **Tesla Roadster** ที่ผู้ใช้ยืนยันว่าเป็นค่าที่ดีที่สุด (Best Master Tune) สำหรับการขับขี่ ทรงตัว การดริฟต์ และทดสอบความเร็วใน [[MOC|HOKI TOWN]]

## 1. Raw JSON Configuration
```json
{
    "ClassName": "Model",
    ".A-Chassis": true,
    "$ImpactSpeed3": 40,
    "ModelStreamingMode": "Nonatomic",
    "$HeadlightsOn": false,
    "$BrakeMultiplier": 1.25,
    "WorldPivot": "272.062683, 3.43122673, 205.393265, 1, 0, 0, 0, 1, 0, 0, 0, 1",
    "Name": "TeslaRoadster",
    "$CamberAngle": 0,
    "$Fuel": 100,
    "$FuelDrainBasePerSecond": 0.01,
    "$FuelDrainPerStudPerSecond": 0.0002,
    "$ImpactSpeed4": 60,
    "$FuelDrainStartSpeed": 4,
    "$ImpactDamage4": 22,
    "$GodMode": true,
    "$Health": 100,
    "$PiggyCarAirborneWeightReduced": true,
    "$ImpactDamage1": 2,
    "$SuspensionStiffScale": 1,
    "$ImpactDamage2": 5,
    "$ImpactDamage3": 12,
    "$ImpactDamage5": 35,
    "$ImpactSpeed1": 12,
    "$TireMode": "Arcade",
    "$ImpactSpeed2": 25,
    "$ImpactSpeed5": 85,
    "$MaxFuel": 100,
    "$MaxHealth": 100,
    "$VehiclePowerDisabled": false,
    "$PerfStage": 2,
    "$RideHeightOffset": 0,
    "$TapDriftEnabled": true,
    "$WheelSpacer": 0
}
```

## 2. Key Dynamic Behavior & Stance Specifications
- **Tire Mode**: `Arcade` (การยึดเกาะถนนสูง ควบคุมง่าย สไลด์เข้าโค้งเนียน)
- **Brake Multiplier**: `1.25` (ระยะเบรกฉุกเฉินสั้น หน่วงความเร็วคม)
- **Performance Stage**: `Stage 2` (กำลังขับและอัตราเร่งตอบสนองไว)
- **Suspension Springs**: `Tune.SpringsVisible = false` (ซ่อนคอยล์สปริงโช๊คทั้งหมด ไม่เกะกะสายตา)
- **Wheel Stance / Fitment**: ยุบระยะฐานล้อเข้าใน (Tucked/Flush Fitment) $\Delta x = 0.28\text{ studs}$ ต่อข้าง ให้ขอบล้อแม็กซ์และหน้ายางหลบเข้าในซุ้มบังโคลน (Fender Arches) อย่างสมบูรณ์ ไม่ล้นตัวถัง
- **Door Panel Cleaning**: ลบชิ้นส่วนแผ่นเหล็กประตูทดสอบ (`Door_Driver`) ออกจากตัวถังรถ
- **Body Clearance Lift**: ยกตัวถัง `Teera Roadster` (Paint, Glass, Interior, Wing) ขึ้น $+0.85\text{ studs}$ ทำให้ขอบซุ้มบังโคลนและฝากระโปรงอยู่สูงกว่าหน้ายางและโช๊ค $+0.537\text{ studs}$ ขจัดปัญหาล้อและสปริงโช๊คทิ่มทะลุฝากระโปรง 100%
- **Cabin Ergonomics**: ปรับระดับ `DriveSeat` ลง $-0.25\text{ studs}$ ให้คนขับนั่งจมลงในเบาะบักเก็ตซีทอย่างเป็นธรรมชาติ ศีรษะอยู่ใต้กระจกหลังคา ไม่โผล่ทะลุหลังคากระจก
- **Anti-Bottoming Compression Limit**: `Tune.FCompressLim = 0.5` ซึ่งน้อยกว่าระยะเคลียร์แลนซ์ตัวถัง ($0.537\text{ studs}$) การันตีว่าแม้จังหวะกระแทกเนินหรือคอสะพานแรงที่สุด ล้อก็จะไม่ชนทะลุฝากระโปรงอีกแน่นอน
- **Invisible Shocks & Hitboxes (โช้คล่องหน 100%)**: ปรับ `Transparency = 1` ให้กับกระบอกล้อฟิสิกส์ (`FL`, `FR`, `RL`, `RR`) และตั้ง `SpringConstraint.Visible = false` ทำให้ไม่เห็นชิ้นส่วนทรงกระบอกสีดำหรือขดสปริงสีแดงโผล่ทะลุตัวถังอีกต่อไป
- **Sleek Supercar Stance**: ปรับลดระดับตัวถัง `Teera Roadster` ลงมา $-0.50\text{ studs}$ จากเดิม (ระดับสุทธิ $+0.35\text{ studs}$ จากฐานเดิม) ให้รถเตี้ย แบน สปอร์ต ปลายซุ้มบังโคลนครอบพอดีขอบยาง (Flush Stance) สวยงามสมส่วน
