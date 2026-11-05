# 📡 ARCH-03: Remotes & Data Model Specification (ข้อกำหนดระบบเน็ตเวิร์กและฐานข้อมูล)

> **เอกสารออกแบบระบบ (Technical Architecture Spec):** จัดเตรียมไว้ล่วงหน้าเพื่อให้การพัฒนาในก้าวต่อไปสามารถเขียนโค้ดต่อได้ทันทีโดยไม่ต้องเริ่มต้นคิดโครงสร้างใหม่

---

## 1. ผังการสื่อสารเครือข่าย (RemoteEvents & RemoteFunctions Contract)
จะถูกจัดวางไว้ใน `ReplicatedStorage.Network.Remotes`:

| ชื่อ Remote | ประเภท (Type) | ทิศทาง (Direction) | อาร์กิวเมนต์ (Arguments) | หน้าที่การทำงาน (Purpose) |
| :--- | :--- | :--- | :--- | :--- |
| `RequestSpawnVehicle` | `RemoteFunction` | Client $\rightarrow$ Server | `vehicleId: string` | ส่งคำขอเบิกรถจากจุด Summon_Car เซิร์ฟเวอร์จะตรวจสอบความเป็นเจ้าของ และคืนค่า `success: boolean, msg: string` |
| `RequestDespawnVehicle`| `RemoteEvent` | Client $\rightarrow$ Server | `nil` | สั่งเก็บรถของตัวเองเข้าโรงจอด |
| `HarvestResource` | `RemoteFunction` | Client $\rightarrow$ Server | `nodeId: string` | ส่งคำขอเก็บเกี่ยวพืชผลจากแท่นฟาร์ม เซิร์ฟเวอร์ตรวจสอบระยะห่างและคูลดาวน์ |
| `RefuelVehicle` | `RemoteFunction` | Client $\rightarrow$ Server | `fuelAmount: number` | ส่งคำขอเติมน้ำมันที่จุด GasTankSites หักเงินผู้เล่นและเพิ่มน้ำมันให้รถ |
| `SyncCarStatus` | `RemoteEvent` | Server $\rightarrow$ Client | `health: number, fuel: number` | ซิงค์ค่าเลือดและน้ำมันส่งไปยัง HUD ของคนขับ |

---

## 2. โครงสร้างฐานข้อมูลผู้เล่น (DataStore Schema)
แนะนำให้ใช้ `ProfileService` หรือ `DataStore2` เพื่อป้องกันปัญหาข้อมูลสูญหาย (Data Loss):

```luau
-- โครงสร้างข้อมูลเริ่มต้น (Default Player Profile Data)
local DefaultProfile = {
    Cash = 1500, -- เงินเริ่มต้นสำหรับผู้เล่นใหม่
    Bank = 5000,
    
    Inventory = {
        ["Banana"] = 0,
        ["Melon"] = 0,
        ["WaterBottle"] = 2,
    },
    
    OwnedVehicles = {
        ["TeslaRoadster"] = {
            Plate = "HOKI-001",
            CustomColor = "Bright red",
            Fuel = 100,
            Health = 100,
        }
    },
    
    Stats = {
        DistanceDriven = 0, -- กิโลเมตรที่เคยขับ
        HarvestCount = 0,   -- จำนวนครั้งที่เก็บเกี่ยวผลไม้
    }
}
```

---

## 3. กฎความปลอดภัยของเซิร์ฟเวอร์ (Anti-Exploit Guardrails)
1. **การตรวจสอบพิกัด (Proximity Check):**
   ทุกครั้งที่มีการเรียก `HarvestResource` หรือ `RequestSpawnVehicle` เซิร์ฟเวอร์ต้องคำนวณระยะห่างระหว่างตัวละครผู้เล่นกับจุด Interactive เสมอ:
   ```luau
   local distance = (player.Character.PrimaryPart.Position - node.Position).Magnitude
   if distance > 15 then
       return false, "Too far away"
   end
   ```
2. **การป้องกันการสแปมคำสั่ง (Rate Limiting):**
   กำหนดคูลดาวน์การกดเบิกรถอย่างน้อย 5 วินาทีต่อครั้ง เพื่อป้องกันเซิร์ฟเวอร์ค้างจากการสแปมโมเดล
3. **สิทธิ์ความเป็นเจ้าของรถ (Network Ownership):**
   เมื่อผู้เล่นขึ้นขับรถ ให้เซิร์ฟเวอร์มอบสิทธิ์ `SetNetworkOwner(player)` ให้กับชิ้นส่วนหลักของรถ เพื่อให้การบังคับเลี้ยวลื่นไหลไม่มีดีเลย์ และดึงสิทธิ์กลับคืนเมื่อผู้เล่นลงจากรถ
