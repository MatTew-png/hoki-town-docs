---
project: HOKI TOWN
category: intake
doc_type: design-draft
system: vehicle-fleet-and-starter-ev
status: draft
priority: high
created: 2026-11-13
last_updated: 2026-11-13
tags:
  - inbox
  - draft
  - vehicle-fleet
  - starter-car
  - ora-good-cat
  - roadmap
  - specs
---

# 📝 DRAFT: แผนชุดรถเริ่มต้น (Starter EV) & การแบ่งเฟสรถ Roleplay HOKI TOWN

> **สถานะ:** บันทึกไว้เพื่อใช้พูดคุยสรุปสเปคและลำดับงานก่อนเริ่มลงมือจริง (Stage in `10_Inbox/`)
> **อ้างอิงระบบเดิม:** [[02_Feature_Matrix]] | [[ARCH_02_Target_Refactoring_Roadmap]] | [[FEAT_01D_Tesla_Raycast_Modular_Pipeline]] | [[SPEC_TUNING_GARAGE_SYSTEM_DESIGN]]

---

## 1. มติที่ล็อกไว้แล้ว (Confirmed Decisions)

### 1.1 รถเริ่มต้นแจกฟรีทุกคน (Starter Car)
* **รุ่นต้นแบบ:** GWM ORA Good Cat *(อ้างอิงทรงรุ่น Pro / Ultra; ต้องตั้งชื่อสมมติและถอดโลโก้แบรนด์จริงออกก่อนเข้าเกมเพื่อกันปัญหา IP/DMCA)*
* **สเปคจริงอ้างอิง:** กว้าง `1,825 มม.` × ยาว `4,235 มม.` × สูง `1,596 มม.` | ฐานล้อ `2,650 มม.` | EV 100% (143 แรงม้า)
* **เหตุผลทางเทคนิค:** เป็นรถยนต์ไฟฟ้า (EV) จึงใช้ระบบเสียง [[EvSoundMix]] ที่มีอยู่ในโปรเจกต์ได้ทันที ไม่ต้องสร้างระบบเสียงเครื่องสันดาปใหม่ในเฟสแรก
* **เป้าหมายการใช้งาน RP:**
  * **4 ที่นั่ง:** `DriveSeat` (1) + เบาะผู้โดยสาร `Seat` (3)
  * **สมรรถนะระดับเริ่มต้น:** TopSpeed ~`120–130 km/h`, ปิดโหมด Wall-Climb และ Flight, เปิด `CurbAssistEnabled = true`
  * **การแต่งสี:** รองรับสี Two-Tone (ตัวถัง + หลังคา/คิ้วตัดสี) ผ่านระบบสีใน `VehicleColorService`

### 1.2 ต้นแบบสเกล & อ้างอิงรถหลัก: `TeslaRoadster_Scon`
จากการวัดขนาดจริงใน Roblox Studio บน `Workspace.TeslaRoadster_Scon`:
* **ขนาดตัวถังที่มองเห็นจริง (Visible Body Span):** กว้าง `7.02` × สูง `3.89` × ยาว `15.46` studs *(หมายเหตุ: BoundingBox รวม `34.38` studs เกิดจาก Part/Collider โปร่งใสภายใน)*
* **ระยะฐานล้อ (Wheelbase):** `9.67` studs | **ความกว้างช่วงล้อ (Track):** `5.51` studs | **ขนาดล้อ:** หน้า `2.33` / หลัง `2.45` studs
* **สเกลเป้าหมายของ ORA Good Cat (เทียบ `TeslaRoadster_Scon` ที่ ~`3.55 studs/m`):**
  * กว้าง ~`6.5` studs × ยาว ~`15.0` studs × สูง ~`5.7` studs (ฐานล้อ ~`9.4` studs)
  * เทียบกับความกว้างถนนใน `Hoki_Metropolis.01_Ground_Roads.Roads` (`44–48` studs) จะเข้าช่องจราจรได้พอดี

---

## 2. การแบ่งระดับความละเอียดรถ (ลดจาก 6 โซน เพื่อแยกเกรดรถ & ปั้นไวขึ้น)

### 2.1 มติเรื่องโซนตกแต่ง (`Aero_Trim` & `Chassis_Underbody`)
* **`Aero_Trim` และ `Chassis_Underbody` (รวมถึง Diffuser / Skirt / Housing / Spoiler):** **ไม่ต้องเปิดให้เปลี่ยนสี** — ล็อกเป็น **สีดำ / คาร์บอน (Fixed Carbon Black)** ตายตัวทุกคัน
* **ข้อดีทางเทคนิค:** สามารถ **ยุบรวมชิ้นส่วนสีดำ-คาร์บอนรอบคันให้เป็น Mesh เดียวกันใน Blender** ได้เลย ลดจำนวน `MeshPart` และ Draw Calls ลงได้เยอะโดยที่รถยังดูดุดันสมจริง

### 2.2 มาตรฐานโมเดล 3D & โซนลงสี (Locked Spec)

#### ก. ชิ้นส่วน Static สีตายตัว (เหมือนกันทุกเกรด — ไม่ต้องเปิดให้ผู้เล่นเปลี่ยนสี)
* **`Trim_Black`:** ยุบรวมคาร์บอน/พลาสติกดำรอบคัน (`Aero_Trim`, `Chassis_Underbody`, ซุ้มล้อ, กันชนล่าง, กรอบไฟ, *(และสปอยเลอร์ถ้าไม่เปลี่ยนสี)*) เป็น **1 MeshPart เดียว**
* **`Tire`:** ยาง 4 เส้น (ปั้น **1 เส้น** แชร์ `MeshId` 4 มุม)
* **`Interior_Simple` / `Interior_Console`:** คอนโซล+โครงห้องโดยสารแบบ Low-poly สีดำ/เทาเข้ม (~500–1,500 tris)
* **`Lights_Head` / `Lights_Tail`:** ไฟหน้าหลักและไฟท้าย (สีขาว/แดงมาตรฐาน)
* **`License_Plate`:** ป้ายทะเบียน (ชิ้นเดียวที่ติด `SurfaceAppearance`)

#### ข. ระดับที่ 1 — Standard 4 Zones (`Starter` + รถทั่วไปทุกหมวด `Utility` / `Sports` ยกเว้นตัวท็อป/กาชา)
* **โซนเปลี่ยนสี 4 ชิ้น:**
  1. `Body_Main` — ตัวถังหลัก (เนื้อสี Gloss มาตรฐาน)
  2. `Body_Secondary` — จุดตัดสีทูโทน *(เช่น หลังคา Good Cat, ตู้ทึบ Revo, แถบแต่ง — รุ่นไหนไม่มีทูโทนตัดออกได้)*
  3. `Wheel_Rim` — ล้อแม็ก (ปั้น **1 ล้อ** แชร์ `MeshId` 4 มุม)
  4. `Canopy_Glass` — กระจกเปลี่ยนสี/ความเข้มฟิล์มได้
* **งบ Polycount:** **12,000–22,000 Tris** (Starter/Utility ~12–18k, Sports ~18–22k)

#### ค. ระดับที่ 2 — VIP / Top-Tier Package (`Super Sports` รถเติม + ยกเว้นให้ตัวท็อปของแต่ละหมวด / รถกาชา)
* **ได้ชุด Standard 4 ชิ้นครบ + ปลดล็อกฟีเจอร์พิเศษทั้งหมดนี้:**
  5. `Brake_Caliper` *(+ `Brake_Rotor` คู่กัน; ปั้น **1 ชุด** แชร์ 4 มุม ไม่หมุนตามล้อ)*
  6. `Lights_DRL` *(ไฟเส้น LED หน้า / ตัดหมอก `Neon` เปลี่ยนสีได้ — เห็นชัดระยะไกล)*
  7. `Underglow` *(ไฟนีออนใต้ท้อง — วางใน Roblox Studio โดยตรง 0 Tris ใน Blender)*
  8. **Paint Finish บน `Body_Main`:** ปลดล็อกเนื้อสี **`Matte` / `Metallic` / `Chrome`** เพิ่มจาก `Gloss` ปกติ
  9. `Interior_Seats` *(ทางเลือกสำหรับรุ่นกระจกใส/เปิดประทุน — แยกสีเบาะออกจากคอนโซลดำ)*
* **งบ Polycount:** **22,000–35,000 Tris**

---

## 3. โครงสร้างร้านรถ (Dealership) & แผนแบ่งเฟสรถ

### 3.1 🎯 Set 1 Launch Roster (เคาะครบแล้ว — รวม 10 คัน, 4 ล้อ/DRW ทั้งหมด)
| หมวด | รุ่นรถ (Reference Model) | ระดับสี & แต่ง | บทบาท / หมายเหตุ |
| :--- | :--- | :--- | :--- |
| **Starter (ฟรี)** | **GWM ORA Good Cat** *(Pro/Ultra)* | Standard 4 Zones | แจกทุกคนตั้งแต่เริ่ม, 4 ที่นั่ง, EV |
| **Utility (Tier 1)** | **Shelby Ford F-150 Raptor (2022)** | Standard 4 Zones | กระบะเริ่มต้นสายงาน (`Body_Secondary` = แถบคู่กลาง/คิ้ว) |
| **Utility (Tier 2)** | **2026 Ford Super Duty F-450 Platinum** | Standard 4 Zones | กระบะยักษ์ DRW (ล้อหลังคู่รวมเป็น `RL/RR` ต่อข้าง) |
| **Utility (Tier 3)** | **Mercedes-Benz Luxury Unimog** *(U 4023)* | Standard 4 Zones *(หรือ VIP)* | รถบรรทุก 4×4 หรู 4 ที่นั่ง Double Cab + แร็คไฟหลังคา |
| **Sports (Tier 1)** | **Honda Civic Type R** *(FL5/FK8)* | Standard 4 Zones | รถซิ่ง 4 ประตูเริ่มต้นของหมวด |
| **Sports (Tier 2)** | **Mazda RX-7** *(FD3S)* | Standard 4 Zones | รถสปอร์ต 2 ประตูสาย Drift |
| **Sports (Top-Tier)** | **Chevy Corvette C8 (2023)** | **VIP Package** *(ข้อยกเว้นตัวท็อป)* | ตัวจบเงินในเกมของหมวด Sports |
| **Super Sports (Paid)** | **Tesla Roadster** *(มีอยู่แล้ว)* | **VIP Package** + Stunt | ปรับลด Tris จากตัวเดิม + Wall-Climb/Flight |
| **Super Sports (Paid)** | **Audi R8** | **VIP Package** เต็มระบบ | Supercar รถเติมคู่กับ Tesla |
| **Gacha (ตัวแรก)** | **BMW i8** | **VIP Package** เต็มระบบ | รถตู้กาชาตัวเปิดตัว ดีไซน์ประตูปีกนกล้ำอนาคต |

*(หมายเหตุ: `Scania R-Series`, `2019 Peterbilt 389 Sleeper` [Paid Utility] และ `Toyota Alphard` [Multi-Passenger] เลื่อนไปปล่อยใน **Patch ถัดไป** หลัง Set 1)*

### 3.2 📚 คลังรายชื่อรถทั้งหมดสำหรับทีมคัดเลือก (Full Team Pool)
* **หมวด 1 — `Utility` (4+1 คัน — เคาะรุ่นแล้ว):**
  * Tier 1: **Shelby Ford F-150 Raptor (2022)** *(Standard 4 Zones — `Body_Secondary` = แถบคู่กลาง/คิ้วแต่ง)*
  * Tier 2: **2026 Ford Super Duty F-450 Platinum** *(Standard 4 Zones — ล้อหลังคู่ DRW รวมเป็น `RL/RR` ต่อข้างได้)*
  * Tier 3: **Mercedes-Benz Luxury Unimog (80th Anniversary Concept / U 4023)** *(4 ประตู Double Cab + LED Bar — ใช้ VIP Package ได้)*
  * Tier 4: **Scania R-Series (Tractor Unit)** *(หัวลากยุโรป — Standard 4 Zones)*
  * Paid (`รถโลเติม` — *VIP Package เต็มระบบ*): **2019 Peterbilt 389 Sleeper Semi Truck** *(หัวลากหน้ายาว + ตู้นอน, แยกชิ้น `Chrome` คงที่สำหรับท่อตั้ง/กันชนหน้า)*
* **หมวด 2 — `Multi-Passenger` (รถนั่งหลายคน / ครอบครัว / แก๊ง):**
  * **Toyota Alphard** *(6–7 ที่นั่ง — Standard 4 Zones; ปั้นทรงกล่องเหลี่ยมง่าย, ฟิล์มดำ, จุดเด่นรับเพื่อนทีเดียวทั้งแก๊ง)*
* **หมวด 3 — `Sports` (รถซิ่ง / JDM / Sport GT — เงินในเกม | Standard 4 Zones, ตัวท็อปใช้ VIP ได้):**
  * *ระดับต้น–กลาง:* `Honda Civic Type R`, `Mazda RX-7`, `Toyota GR Supra (A90)`, `Toyota Supra MK4 (A80)`, `Nissan Skyline GT-R (R34)`
  * *ระดับสูง/ตัวท็อปหมวด (เชื่อมสู่ Supercar / หรือลงกาชา):* `Aston Martin Vantage V12`, `Chevy Corvette C8 (2023)`, `BMW i8`, `Nissan GT-R50`
* **หมวด 4 — `Super Sports` (รถเติม Robux) & `Hyper / Gacha` (VIP Package เต็มระบบ):**
  * *Super Sports (ร้านรถเติม):* `Tesla Roadster` *(ที่มีอยู่แล้ว — Stunt/Wall-Climb)*, `Audi R8`, `Porsche 911 GT3 RS`, `Lamborghini Huracán`, `McLaren 720S`
  * *Hypercar / Gacha / Limited (ตัวท็อปสุดของเกม — ทยอยปล่อยเป็นตู้สุ่ม/ลิมิเต็ด):* `McLaren P1`, `Ferrari LaFerrari`, `Koenigsegg Agera RS`, `Zenvo TS1 GT`, `Apollo EVO`

### 3.3 เลื่อนไปทำหลังสุด (Post-Launch Backlog)
* **`Motorcycles` (2 ล้อ — ไว้หลังสุด):** `Wave 110i`, `PCX 160 / XMAX 300`, `ZX-10R`, `Ducati V4` *(รอกลับมาเขียน Chassis 2 ล้อทีหลัง)*
* **รถใหญ่พ่วง/พิเศษ & หน่วยงาน/สาธารณะ:** `Hino 10 ล้อ`, `Scania หัวลากพ่วง`, `Tow Truck`, `Police / EMS`, `Taxi`, `รถเมล์`, `รถขยะ`

---

## 4. หัวข้อที่ต้องคุยตกลงกันต่อ (Next Steps — โมเดล & รายชื่อรถ)

1. **กฎการลงสีใน Blender (ก่อนปั้น `ORA Good Cat`):**
   * ชิ้นที่เปลี่ยนสีได้ (`Body_Main`, `Body_Secondary`, `Wheel_Rim`, `Brake_Caliper`, `Lights_DRL`, `Interior_Seats`) ต้องใช้ Material สีขาว `#FFFFFF` ล้วน ไม่ Bake สีทับ (ใช้ `MeshPart.Color` + `Material`/`MaterialVariant` ของ Roblox)
   * แกน Export FBX: **Up = `+Y`, Forward = `-Z`** (Apply Rotation/Scale) + ตั้ง Origin ของ `Wheel_Rim`/`Tire`/`Brake_Caliper` ไว้ที่ `(0,0,0)`
2. ~~**เลือกรุ่นที่จะเข้าปั้นใน Set แรก (`Utility` และ `Sports`):**~~ ✅ **ล็อกครบ 10 คันแล้วในข้อ 3.1**
3. **ชื่อแบรนด์สมมติในเกม (IP / DMCA Safety):** กำหนดชื่อแบรนด์สมมติของทั้ง 10 คันแทนชื่อจริงก่อนทำป้ายทะเบียน/UI (และถอดโลโก้แบรนด์จริงออกใน Blender)
4. **ออก Blueprint / เริ่มปั้น 3D คันแรก (`ORA Good Cat`):** เริ่มผลิตโมเดลตามสเปค 4 โซน + งบ 12k–18k Tris + สเกลเทียบ `TeslaRoadster_Scon` *(เรื่อง Script ไว้คุยหลังจากเคลียร์ฝั่งโมเดลเสร็จ)*

---

## 5. ตารางลำดับชั้น Handling เปรียบเทียบสำหรับ Set 1 (Relative Design Tiers)

> **หมายเหตุ:** ใช้ระดับ `1–5` เชิงเปรียบเทียบ (ยังไม่ลงตัวเลขจูนฟิสิกส์จริงจนกว่าจะล็อก Chassis ตัวเดียว) เพื่อให้ทีมร้านรถ/ตั้งราคา/UI ใช้ทำงานต่อได้ทันที

| หมวด | รุ่นรถ | ความเร็วปลาย | อัตราเร่ง | การควบคุม / บุคลิก | ความอึด / น้ำหนัก | ที่นั่ง / ขนของ | จุดขายหลัก (Why Buy) |
| :--- | :--- | :---: | :---: | :--- | :---: | :--- | :--- |
| **Starter** | **GWM ORA Good Cat** | `2.0 / 5` | `2.5 / 5` | `3.5 / 5` *(Grip นิ่ง ขับง่าย)* | `2.5 / 5` | **4 ที่นั่ง** / ของเล็ก | รถแจกฟรี รับเพื่อนได้ทั้งกลุ่ม ขับในเมืองคล่อง |
| **Utility T1** | **Shelby F-150 Raptor** | `3.0 / 5` | `3.5 / 5` | `3.5 / 5` *(Sport Off-Road)* | `3.5 / 5` | **4 ที่นั่ง** / ของกลาง-เล็ก | กระบะซิ่งคล่องตัว วิ่งงานเร็ว เข้าซอยง่าย |
| **Utility T2** | **Ford F-450 Platinum** | `2.5 / 5` | `2.5 / 5` | `3.0 / 5` *(Heavy Stable)* | `4.5 / 5` | **4 ที่นั่ง** / ของกลาง-ใหญ่ | กระบะยักษ์ DRW บรรทุกหนักขึ้น วิ่งทางไกลนิ่ง |
| **Utility T3** | **MB Luxury Unimog** | `2.0 / 5` | `3.0 / 5` | `4.0 / 5` *(All-Terrain Torque)* | `5.0 / 5` | **4 ที่นั่ง** / ของใหญ่สุด | ไต่เนิน/ทางชัน/ลุยทุกพื้นผิว แรงบิดสูง อึดสุดใน Set 1 |
| **Sports T1** | **Honda Civic Type R** | `3.5 / 5` | `3.5 / 5` | `4.0 / 5` *(Sharp FWD Grip)* | `2.5 / 5` | **4 ที่นั่ง** / ไม่เน้นขน | รถซิ่งสาย 4 ประตู เร็วขึ้นและพาเพื่อน 4 คนไปด้วยได้ |
| **Sports T2** | **Mazda RX-7** | `4.0 / 5` | `4.0 / 5` | `4.0 / 5` *(Tail-Happy Drift)* | `2.0 / 5` | **2 ที่นั่ง** / ไม่เน้นขน | รถสาย **Drift** เข้าโค้งกวาดท้ายสนุกบนลาน `Drift_Skidpad` |
| **Sports Top** | **Chevy Corvette C8** | `4.5 / 5` | `4.5 / 5` | `4.5 / 5` *(Mid-Engine Grip)* | `2.5 / 5` | **2 ที่นั่ง** / ไม่เน้นขน | ตัวจบเงินในเกม + ได้สิทธิ์แต่งสี **VIP Package** |
| **Gacha** | **BMW i8** | `4.5 / 5` | `4.5 / 5` | `4.5 / 5` *(Balanced Hybrid)* | `2.5 / 5` | **2 ที่นั่ง** / ไม่เน้นขน | รถสุ่มกาชาตัวเปิด ประตูปีกนก + **VIP Package** |
| **Super Sports** | **Audi R8** | `4.5 / 5` | `4.5 / 5` | `5.0 / 5` *(AWD Track Rail)* | `3.0 / 5` | **2 ที่นั่ง** / ไม่เน้นขน | รถเติมขับนิ่งเกาะถนนคมที่สุด ควบคุมง่ายที่ความเร็วสูง |
| **Super Sports** | **Tesla Roadster** | `5.0 / 5` | `5.0 / 5` | `4.5 / 5` *(EV Launch + Stunt)* | `2.5 / 5` | **1–2 ที่นั่ง** / ไม่เน้นขน | เร็ว/ออกตัวจัดสุด + **Wall-Climb & Flight** (เล่นโซน Stunt) |

### หลักการกันสมดุลเสีย (Design Rules ที่ผูกกับตารางนี้)
1. **Stunt & Wall-Climb:** เปิดเฉพาะ **`Tesla Roadster`** เท่านั้น (รถอื่นปิดทั้งหมด เพื่อให้เป็นเอกลักษณ์เฉพาะรถเติมสาย Stunt และไม่ทำให้ Utility ใช้ไต่ตึกลัดทางส่งของ)
2. **Cargo vs Speed Trade-off:** `Utility` ชนะเรื่อง **ความอึด + ความจุขนของ** แต่ความเร็วปลายแพ้ `Sports` / `Super Sports` ชัดเจน
3. **4-Seat Roleplay Niche:** `ORA Good Cat` กับ `Civic Type R` / `Utility` มีจุดแข็งเรื่อง **4 ที่นั่ง** ส่วน `RX-7` ขึ้นไปเน้น **2 ที่นั่ง** เพื่อให้รถบ้านและกระบะยังมีบทบาทในเซิร์ฟเวอร์ตลอดเวลา

---

## 6. ชื่อแบรนด์และรุ่นสมมติในเกม (อนุมัติแล้ว — Confirmed In-Game Roster)

| หมวด | รุ่นจริง (Reference) | ค่ายสมมติ | ชื่อรุ่นแนะนำในเกม |
| :--- | :--- | :--- | :--- |
| **Starter** | GWM ORA Good Cat | **KAIRO** | **Kairo Neko EV** *(หรือ Kairo Meow)* |
| **Utility T1** | Shelby F-150 Raptor | **ATLAS** | **Atlas Claw 150** *(หรือ Atlas Apex 150)* |
| **Utility T2** | Ford F-450 Platinum | **ATLAS** | **Atlas Titan 450** |
| **Utility T3** | MB Luxury Unimog | **KRONEN** | **Kronen Mog-40** *(หรือ Kronen Brute 4x4)* |
| **Sports T1** | Honda Civic Type R | **KAZE** | **Kaze Type-X** *(หรือ Kaze Velo-R)* |
| **Sports T2** | Mazda RX-7 | **KAZE** | **Kaze FD-7** *(หรือ Kaze Rotary-7)* |
| **Sports Top** | Chevy Corvette C8 | **STRIKER** | **Striker Ray-8** |
| **Gacha** | BMW i8 | **KRONEN** | **Kronen Prism-8** *(หรือ Kronen E-8)* |
| **Super Sports** | Audi R8 | **KRONEN** | **Kronen V10-R** |
| **Super Sports** | Tesla Roadster | **HOKI / VOLTA** | **Hoki Volt-R** *(หรือ Volta Mach-R)* |
