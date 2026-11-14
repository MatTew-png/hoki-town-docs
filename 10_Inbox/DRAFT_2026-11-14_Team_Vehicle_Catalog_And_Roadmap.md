---
project: HOKI TOWN
category: intake
doc_type: vehicle-catalog-roadmap
system: vehicle-fleet
status: draft
priority: high
created: 2026-11-14
last_updated: 2026-11-14
tags:
  - vehicle-catalog
  - set-1
  - roadmap
  - team-handout
---

# 🚗 HOKI TOWN — รายชื่อรถทั้งหมด & แผนการเพิ่มรถในอนาคต (ฉบับส่งให้ทีม)

> สรุปรวมรถที่มีอยู่แล้ว, ชุดเปิดตัว Set 1 (10 คัน), แพตช์ถัดไป (ก๊อก 2), และคลังรถสำรองสำหรับพัฒนาต่อในอนาคต

---

## 1. รถที่มีอยู่แล้วในโปรเจกต์ตอนนี้ (Existing)

| รุ่นอ้างอิง | ชื่อสมมติแนะนำในเกม | สถานะปัจจุบัน | แผนการใช้งาน |
| :--- | :--- | :--- | :--- |
| **Tesla Roadster** *(Gen 2)* | **Hoki Volt-R** *(หรือ Volta Mach-R)* | มีโมเดล + ระบบขับขี่ในโปรเจกต์แล้ว (`TeslaRoadster_Scon` / `Refined_2026`) | ปรับลด Tris และจัดโซนสีใหม่ เพื่อใช้เป็นรถเติม **Super Sports (Stunt / Wall-Climb)** ใน Set 1 |

---

## 2. Set 1: ชุดเปิดตัว (Launch Roster — 10 คัน, 4 ล้อ/DRW ทั้งหมด)

| หมวด | รุ่นอ้างอิง (Reference) | ชื่อสมมติแนะนำ *(กัน IP/DMCA)* | ระดับสี & แต่ง | บทบาท & สเปคภาพรวม |
| :--- | :--- | :--- | :--- | :--- |
| **Starter (แจกฟรี)** | GWM ORA Good Cat *(Pro/Ultra)* | **Kairo Neko EV** | Standard 4 Zones | รถแจกทุกคนตั้งแต่เริ่ม, EV, 4 ที่นั่ง, ขับในเมืองง่าย |
| **Utility (Tier 1)** | Shelby Ford F-150 Raptor (2022) | **Atlas Claw 150** | Standard 4 Zones | กระบะเริ่มต้นสายงาน (`Body_Secondary` = แถบคู่กลาง), 4 ที่นั่ง |
| **Utility (Tier 2)** | 2026 Ford Super Duty F-450 Platinum | **Atlas Titan 450** | Standard 4 Zones | กระบะยักษ์ DRW ล้อหลังคู่, บรรทุกหนัก, 4 ที่นั่ง |
| **Utility (Tier 3)** | Mercedes-Benz Luxury Unimog *(U 4023)* | **Kronen Mog-40** | Standard 4 Zones *(หรือ VIP)* | รถบรรทุก 4×4 ลุยหนัก, 4 ที่นั่ง Double Cab + แร็คไฟหลังคา |
| **Sports (Tier 1)** | Honda Civic Type R *(FL5/FK8)* | **Kaze Type-X** | Standard 4 Zones | รถซิ่ง 4 ประตูเริ่มต้นของหมวด, ขับเกาะถนน |
| **Sports (Tier 2)** | Mazda RX-7 *(FD3S)* | **Kaze FD-7** | Standard 4 Zones | รถสปอร์ต 2 ประตู สาย **Drift** |
| **Sports (Top-Tier)** | Chevy Corvette C8 (2023) | **Striker Ray-8** | **VIP Package** *(ข้อยกเว้นตัวท็อป)* | ตัวจบเงินในเกมของหมวด Sports, 2 ที่นั่ง |
| **Super Sports (Paid)** | Audi R8 | **Kronen V10-R** | **VIP Package** เต็มระบบ | Supercar รถเติม Robux ขับนิ่งเกาะถนนสูง, 2 ที่นั่ง |
| **Super Sports (Paid)** | Tesla Roadster *(ปรับจากของเดิม)* | **Hoki Volt-R** | **VIP Package** + Stunt | รถเติม Robux เร็วสุด + เปิด Wall-Climb / Flight, 1–2 ที่นั่ง |
| **Gacha (ตัวแรก)** | BMW i8 | **Kronen Prism-8** | **VIP Package** เต็มระบบ | รถสุ่มกาชาตัวเปิด ประตูปีกนก, 2 ที่นั่ง |

### สรุปมาตรฐานแต่งสี 2 ระดับ (ใช้คุมการปั้น 3D)
* **Static สีตายตัว (ทุกคัน):** `Trim_Black` *(ใต้ท้อง/กันชนล่าง/ซุ้มล้อรวมเป็นชิ้นเดียว)*, `Tire`, `Interior_Simple`, `Lights_Head/Tail`, `License_Plate`
* **Standard 4 Zones:** `Body_Main`, `Body_Secondary`, `Wheel_Rim`, `Canopy_Glass`
* **VIP Package** *(Super Sports, Gacha, ตัวท็อปหมวด)*: ได้ Standard 4 Zones + `Brake_Caliper` *(+ Rotor)*, `Lights_DRL`, `Underglow`, `Interior_Seats`, และปลดล็อกเนื้อสี `Matte / Metallic / Chrome`

---

## 3. Patch 2 / ก๊อกถัดไป (Near-Term Updates)

* **หมวด `Utility` ก๊อก 2 (สายหัวลากหนัก):**
  * **Tier 4 (`Truck Tractor`):** Scania R-Series *(หัวลากยุโรป — Standard 4 Zones)*
  * **Paid (`รถโลเติม`):** 2019 Peterbilt 389 Sleeper Semi Truck *(หัวลากหน้ายาว + ตู้นอน — VIP Package เต็มระบบ + แยกชิ้น Chrome)*
* **หมวดใหม่ `Multi-Passenger` (รถนั่งหลายคน / แก๊ง):**
  * **Toyota Alphard** *(6–7 ที่นั่ง — Standard 4 Zones)*

---

## 4. คลังรถสำหรับทีมคัดเลือกในอนาคต (Future Expansion Pool)

### 4.1 `Sports` (เงินในเกมเพิ่มเติม)
* Toyota GR Supra (A90)
* Toyota Supra MK4 (A80)
* Nissan Skyline GT-R (R34)
* Aston Martin Vantage V12
* Nissan GT-R50 *(เหมาะเป็นตัวท็อปหมวด / กาชา)*

### 4.2 `Super Sports` & `Hyper / Gacha / Limited` (รถเติม & ตัวแรร์)
* **Super Sports:** Porsche 911 GT3 RS, Lamborghini Huracán / Aventador, McLaren 720S, Ferrari 488 GTB
* **Hypercar / Gacha Limited:** McLaren P1, Ferrari LaFerrari, Koenigsegg Agera RS, Zenvo TS1 GT, Apollo EVO

### 4.3 `Utility` / Commercial สำรองเพิ่มเติม
* Suzuki Carry, Toyota Hilux Revo, Isuzu D-Max
* Isuzu ELF (NLR / NMR), Hino 500 Victor (10 ล้อ), Volvo FH16

### 4.4 `Civilian & Luxury` (ถ้าเปิดหมวดรถบ้าน/ผู้บริหารภายหลัง)
* Honda Jazz (GK) / Toyota Yaris, Honda Civic (FE), Toyota Corolla Altis
* Toyota Fortuner, BMW Series 3 (G20), Mercedes-Benz C-Class

### 4.5 `Motorcycles` (หมวด 2 ล้อ — ทำหลังสุดหลังทำฟิสิกส์ 2 ล้อแยก)
* **สกู๊ตเตอร์ / รถเล็ก:** Honda Wave 110i, Honda PCX 160, Yamaha XMAX 300
* **บิ๊กไบค์:** Kawasaki Ninja ZX-10R, Yamaha YZF-R1, Ducati Panigale V4

### 4.6 `Emergency & Public Transport` (หน่วยงาน & รถบริการเมือง — อนาคต)
* **ตำรวจ (Police):** Toyota Camry
* **หมอ / พยาบาล (EMS):** Toyota Commuter
* **ช่าง / กู้ภัย (Tow Truck):** Toyota Hilux Vigo / Revo ดัดแปลงรถยก
* **ขนส่งสาธารณะ & บริการ:** Taxi *(Toyota Corolla Altis)*, รถโดยสารประจำทาง *(Hino / Isuzu)*, รถบรรทุกขยะ *(Isuzu NPR)*
