# G6 — Turn-based Hacker Combat (Scope / Spec)

The headline new system: infrequent, special RPG/Pokémon-style fights that pay
off the gear (G4) and skill investment. Companion to `GAMEPLAY_ROADMAP.md` G6;
this is the build-ready spec. Effort: ~1–2 weeks.

**Design decisions locked** (2026-06-13):
- **PROGRAM action reuses inventory items** — combat consumables come from the
  existing bag, tying combat into the economy loop (no parallel item system).
- **Encounters stay rare & special** — low chance, status/heat-gated. Fights
  are memorable, not a grind.
- 3D shell only. Data + systems on the existing `GameState`/`GameData`
  autoloads + one new UI Panel; no engine changes.

---

## 1. Foundation (already shipped in G4)

Combat reads the existing derived stats (`game_state.gd:660-683`) — no new
stat system:

| Stat | Formula | Range (early → late) |
|------|---------|----------------------|
| `total_cyber_attack()` | rig cyber + `hardware` skill | 0 → 3 → 7 → 14 (+skill) |
| `total_defense()` | firewall defense + `stealth` skill | 0 → 3 → 7 → 13 (+skill) |
| `total_integrity()` | `20 + level*2` + implant | ~22 → ~90+ (combat HP) |
| `total_crit()` | implant crit | 0 → 5% → 10% → 15% |

Enemies carry the **same four stats** so the math is symmetric.

Reward/penalty APIs already exist: `add_cash`, `add_xp`, `add_rep`, `add_item`,
`use_consumable`.

---

## 2. Combat math

- **EXPLOIT** (attack): `dmg = max(1, atk - def/2) * randf(0.85, 1.15)`, rounded.
  Crit (`total_crit()` roll) doubles it. Using `def/2` (not full subtraction)
  stops a high-defense enemy from being unkillable.
- **FIREWALL** (defend): a one-turn stance — halves the next incoming hit and
  regens ~10% of max integrity.
- **PROGRAM** (item): use an inventory item flagged with a `combat` effect
  (see §4). Consumes the item.
- **JACK OUT** (flee): success `= clampf(0.4 + stealth*0.1, 0, 0.85)`. Fail
  wastes the turn and you take a hit. Bosses can set `flee: false`.

Turn order: player acts, then enemy acts (simple alternation). Enemy "AI" picks
from its `moveset` array (random/weighted) — deliberately dumb; texture comes
from movesets, not smarts.

---

## 3. Data model — `GameData.ENEMIES` (new table)

Mirrors the `GEAR`/`JOBS` table style:

```gdscript
const ENEMIES := {
    "script_kid": {
        "name": "Script Kiddie", "integrity": 18, "attack": 3, "defense": 1,
        "crit": 0.0, "moveset": ["exploit", "exploit", "firewall"],
        "loot": {"cash": [20, 50], "xp": 15, "rep": 1},
        "flee": true, "tier": 0,
        "intro": "some kid in a hoodie squares up...",
        "taunts": ["u even got a 0day bro?", "skid."]},
    "tracker_cop": {  # the G5 trace unit, fought instead of fled
        "name": "Trace Unit", "integrity": 40, "attack": 7, "defense": 6,
        "crit": 0.05, "moveset": ["exploit", "trace_lock", "firewall"],
        "loot": {"cash": [0, 0], "xp": 40, "heat_clear": true},
        "flee": false, "tier": 2, ...},
    "r10t": {  # recurring boss, scripted via the quest chain
        "name": "R10T", "integrity": 70, "attack": 10, "defense": 6,
        "crit": 0.12, "moveset": ["exploit", "exploit", "ddos", "firewall"],
        "loot": {"cash": [300, 500], "xp": 120, "gear": "rig_breaker", "rep": 8},
        "flee": false, "boss": true, "tier": 3, ...},
}
```

Enemy-only moves add flavor without new player verbs:
- **ddos** — heavier hit but the enemy skips defending next turn.
- **trace_lock** — chip damage + lowers your flee chance for a turn.

---

## 4. PROGRAM items (reuse the bag)

Add an optional `combat` block to items in `CONSUMABLES` (and/or a few new
combat-oriented items) so they live in the same shop/bag/economy:

```gdscript
"logic_bomb": {"name": "Logic Bomb", ... "price": 60,
    "combat": {"damage": 12, "desc": "ignores defense, one-shot burst"}},
"patch_kit":  {"name": "Patch Kit", ... "price": 40,
    "combat": {"heal": 18}},
"smoke_proxy":{"name": "Proxy Smoke", ... "price": 35,
    "combat": {"flee_bonus": 0.4}},  # guarantees the next JACK OUT
```

The PROGRAM menu lists only owned items that have a `combat` block; selecting
one applies the effect and decrements the item via the existing inventory.
Bought at the pawn shop / Vex, same as other consumables.

---

## 5. UI + integration (follows the terminal/shop pattern exactly)

`Terminal` and `Shop` are `Panel`s under `IsoMain/UILayer`, opened via `main_3d`
methods. **Combat is a third such Panel**:

- New `scripts/ui/combat.gd` + a `Combat` Panel node added to `iso_main.tscn`.
- Launched by a new `main_3d.start_combat(enemy_id)`; closes back to the world
  on resolve.
- Layout: player vs enemy blocky portraits (reuse char art), two integrity
  bars, a 4-button action menu (EXPLOIT / FIREWALL / PROGRAM / JACK OUT), and a
  scrolling log using the terminal's typewriter feel ("> R10T deploys ICE...").
- Inherits the existing cyberpunk theme. Movement is already gated by
  `GameState.is_ui_locked()` (`player_3d.gd:47`), so opening the panel freezes
  the world like other modals.

**Headless-testable core**: put the rules in a plain `CombatSession` object
(not the UI node) — `init(player_stats, enemy)`, `player_move(kind, item)`,
`enemy_turn()`, `is_over()`, `result()`. The UI just renders it. This is what
the smoke test drives.

---

## 6. Encounter system (rare & special)

- **Street encounters**: a low roll on district entry, hooked in
  `main_3d.go_to()` (next to the existing `escape_trace` logic). Gated to
  status ≥ a mid tier and nudged up by heat. Cooldown so you can't chain them.
- **R10T boss**: a guaranteed fight at a `GameData.QUESTS` story beat (the chain
  already references R10T).
- **Fight-the-tracker (optional)**: during a G5 TRACE, offer FIGHT as an
  alternative to fleeing — wins clear heat. Ties G5 → G6.

---

## 7. Rewards / penalties

- **Win** → `cash` (range roll) + `xp` + `rep`, occasional `gear` drop; tracker
  wins may set `heat_clear`.
- **Lose** → lose some cash or `stolen_data` — a real setback but **milder than
  the G5 trace bust** (losing a fight ≠ getting busted). Never a full wipe.

---

## 8. Build breakdown

1. **Data + math core** (~2d): `ENEMIES` table, `combat` item blocks, the
   headless `CombatSession` state machine + formulas. Smoke-tested without UI.
2. **Combat screen UI** (~3d): Panel, integrity bars, action menu, log,
   portraits, wired to the session; `main_3d.start_combat`.
3. **Encounters + rewards** (~2d): street-encounter rolls + cooldown, R10T
   quest hook, optional tracker FIGHT, win/lose payouts.
4. **Balance + juice + polish** (~2–3d): tune enemy stats vs gear tiers, hit
   shake/flash, taunts, smoke coverage for win/lose/flee paths.

---

## 9. Open items to settle during build

- Exact street-encounter probability + status gate (tune in phase 3).
- Whether FIREWALL's regen should scale with the firewall stat.
- Enemy roster size for v1 (suggest ~3–4: a skid, a mid street enemy, the
  tracker, R10T).
- Portrait treatment for enemies (tinted citizen vs bespoke blocky art).
