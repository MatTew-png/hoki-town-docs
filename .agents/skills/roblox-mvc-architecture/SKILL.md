---
name: roblox-mvc-architecture
description: Design and implement Roblox Luau gameplay, UI, and backend systems using strict MVC layering, constructor dependency injection, scoped Init/Destroy lifecycle management, domain naming conventions, hand-authored Studio asset wiring, and mandatory setup handback reports. Use when creating or refactoring ServerScriptService backends, ReplicatedStorage shared models, StarterPlayerScripts UI/input systems, Garage/Shop/Economy features, or Remote gateways (keep direct real-time vehicle physics loops in roblox-vehicle-scripting).
---

# Roblox MVC Architecture, Lifecycle & Coding Standard

Distilled Luau-native architecture for **game systems, UI, economy, and server backends**. Do **not** force real-time vehicle physics stepping (`Heartbeat`/`PreSimulation` forces) through a `CommandQueue`—use `roblox-vehicle-scripting` for physics loops and apply this skill's lifecycle, naming, and asset hygiene everywhere.

For a complete `--!strict` Luau module skeleton (Model, Command/Event, Controller, View, Bootstrap), read [`references/luau-mvc-template.md`](references/luau-mvc-template.md).

## 1. Layering & Dependency Matrix (Hard Rules)

```text
InputAdapter / GatewayInbound ──▶ CommandQueue ──▶ Controller (mutates Model)
                                                        │
                                                        ▼ EventBus
View / GatewayOutbound ◀────────────────────────────────┘
(Bootstrap is the composition root wiring all layers via constructor DI)
```

| Layer | Owns | May Reference | Must Never Reference |
| :--- | :--- | :--- | :--- |
| **Core** | `Scope`, `EventBus`, `CommandQueue`, `Signal` | Nothing | Game concepts, `Instance`, Logic, View, Gateway |
| **Logic.Model** | State + invariants (`hp >= 0`) | Core, self | Engine `Instance`s, Controller, View, Remotes |
| **Logic.Controller** | Business rules, consumes Commands, raises Events | Core, Model, Commands, Events | `Workspace`/`ScreenGui`/`Sound`, View, DTOs |
| **Visualizer** (`View`, `InputAdapter`) | UI, VFX, audio, raw input -> Commands | Core, Commands (out), Events (in), `Snapshot`, Engine | Controller methods, Model mutation, Gateway |
| **Gateway** (`Inbound`, `Outbound`, `Mapper`) | `RemoteEvent`s, `DataStore`, HTTP, DTO mapping | Core, Commands/Events, network/SDK | Model, Controller (inbound only enqueues Commands) |
| **Bootstrap** | Composition root, single `RunService` frame entry | All layers (creates recipes & scopes) | Business rules |

- **Separate VMs:** Server and Client run independent Luau VMs; state crosses VM boundaries only via `RemoteEvent`/`RemoteFunction` (one `RemoteEvent` per ordered channel).
- **Authoritative Server:** Validate player permissions, distance, and numeric bounds inside Server Controllers—never trust client payloads or put gameplay rules in a `View`.

## 2. Scoped Lifecycle (`Construct -> Init -> UpdateLogic -> Destroy`)

Scopes nest **outside-in** and tear down **inside-out**: `Application` > `Session` (player login) > `Level` (match/zone) > `Feature` (optional modal). Outer scopes never hold inner-scope objects.

| Phase | Allowed | Forbidden |
| :--- | :--- | :--- |
| `.new(deps)` | Store injected dependencies and plain fields (`>3` args -> `Params` type) | Subscribing events, `task.spawn`, touching Studio `Instance`s, gameplay |
| `:Init()` | Cache `Instance`s (`WaitForChild`), connect events, store handles/threads | Gameplay actions, spawning, audio/VFX, calling global locators |
| `:UpdateLogic(dt)` | Per-frame math driven by Bootstrap using passed `dt` | Calling `RunService`, `tick()`, allocating tables/closures per frame, redundant `.Text` sets |
| `:Destroy()` | Idempotent, nil-safe reverse cleanup: `Disconnect()`, `task.cancel(thread)`, destroy **owned** instances, nil fields last | Throwing on partial init, destroying borrowed dependencies, gameplay events |

- **No Zombie State:** Store every `RBXScriptConnection` and `task.spawn`/`task.delay` thread handle so `:Destroy()` releases everything cleanly even if `:Init()` failed midway.
- **Character Guard:** Never assume `player.Character` exists during `:Init()`; check `player.Character` and fall back to `player.CharacterAdded:Once(...)`.

## 3. Luau Conventions & Domain Naming

- **Module Role Suffixes:** `<Feature>Controller`, `<Feature>Model`, `<Feature>Snapshot`, `<Verb><Object>Command`, `<Subject><PastVerb>` (Event), `<Feature>View`, `<Device><Action>InputAdapter`, `<Source>InboundAdapter`, `<Target>OutboundAdapter`, `<Domain>Mapper`, `<Domain>Dto`, `<Feature>Module`.
- **Avoid Dumping-Ground Names:** Do not create new classes/modules named `Manager`, `Helper`, `Utils`, `Misc`, `Common`, `Data`, `Info`, `Handler`, or generic methods named `Process`, `DoStuff`, `Check`, `Execute`, `Run` without a domain target.
- **Verb Precision:** `Get` (guaranteed cheap read), `Find` (nullable search), `TryGet`/`Try...` (failable op), `Calculate` (pure), `Validate` (rule check), `Is`/`Has`/`Can` (non-mutating boolean), `Apply` (mutate Model), `Raise` (emit Event), `Enqueue` (push Command), `Show`/`Hide`/`Refresh` (View only).
- **Casing & Luau Idioms:**
  - `PascalCase` modules, public methods/fields, `I`-prefixed contract types (`export type IInventory`), and `*Enum` frozen tables (`table.freeze({ ... })`).
  - `_camelCase` private fields/helpers; `camelCase` locals/params (include units when unclear: `timeoutSeconds`); `UPPER_CASE` module constants.
  - Events/Callbacks: `self.EventItemBought = Signal.new()` paired with `OnItemBought`.
  - Expose designer-tunable values as Studio `Attributes` (`instance:GetAttribute(...)`), not public module fields.
  - Write a concise `--[[ Purpose / @param / @return ]]` doc block on every ModuleScript and public method.
  - Prefer full multi-line `if ... then ... end` blocks and guard clauses over single-line shorthand or deep nesting.

## 4. Hand-Authored Studio Assets & Wiring

- **Never Generate UI Trees in Code:** Assume `ScreenGui`, `Frame`, `TextButton`, `RemoteEvent`, and template `Model`s are authored in Studio. Clone templates (`template:Clone()`) rather than calling `Instance.new("ScreenGui")` / `Instance.new("Frame")` from scratch unless explicitly asked.
- **`WaitForChild` vs `FindFirstChild`:** Use `WaitForChild("ExactName")` for expected Studio children (`UI`, `Remotes`, templates). Use `FindFirstChild` only when absence is valid logic, always followed by a `nil` guard (and log/handle timeouts on `WaitForChild(name, timeout)`).

## 5. Mandatory Feature Handback Report

After implementing any feature or system, always report in plain language:
1. **Runtime Flow** — end-to-end path (`Trigger -> Input/Gateway -> Command -> Controller -> Event -> View`) and init/cleanup triggers.
2. **Manual Setup Required** — exact Studio paths/names (`StarterGui`, `ReplicatedStorage.Remotes`, template `Model`s, `Attribute`s/`Tag`s, and expected `Model`/`Dto` field shapes).
3. **Follow-up Steps** — exact Explorer items or wiring the developer must verify before pressing Play.
