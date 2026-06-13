# Hacker Quest — Gameplay & RPG Roadmap

The layer that turns the living city into a *game with stakes*: a tuned
economy, a real character you create and equip, threats that chase and fight
you, and far more to do. Companion to `ALIVE_ROADMAP.md` (which covered making
the city feel alive); this covers what you actually *do* in it.

3D shell only (`scenes/iso/`). Everything below is data + systems on top of the
existing `GameState` / `GameData` autoloads — no engine changes.

Ordering: quick/foundational first, threat systems in the middle (the meat),
**teaser districts and apartments deliberately LAST** per design call.

---

## G1 — Economy & balance pass (IN PROGRESS)

Make the numbers feel earned and the curve intentional.

- [x] **District-flavored trash + rare finds** (`GameData.TRASH_TABLES`,
  `district_3d._search_trash`): per-district scrap range, loot pool, XP, and
  a RARE bonus-find roll. Verified avg yields — Underpass ~10.7 scrap & 20%
  rare (motherlode), Market ~7.1 & 12%, Corp Row sparse-but-classy (5.5 but
  16% → rig cores/wallets), Plaza/default ~5.0 & 6%. New high-value items:
  Gold-Trace Board $70, Salvaged Rig Core $120 (a G4 gear seed), Forgotten
  Wallet $200. All auto-sell at the pawn shop.
- [x] **Trash gives no XP** — it's now a pure money loop (toast: "+$N scrap").
- [x] **Job boards are risk/reward bets, not free clicks** (`GameData.JOBS`
  gained `heat` + `risk`; `GameState.gig_risk` factors Stealth). Taking a
  gig can go **sideways** (~its risk %): a blown run pays ~25% + a heat
  spike instead of full pay. Board shows "[risk: +N heat · X% clean]".
  Verified: fixer gig ~82% clean / ~18% sideways.
- [x] **Randomized daily board** (`GameState.daily_gigs`): 3 gigs/board/day,
  deterministic per day (refresh on sleep), **always one status-gated
  advanced gig**. R10T may claim one. Verified across days.
- [ ] **Per-source roles** so each grind means something: trash = early cash,
  jobs = steady cash + XP, favors = REP, goods = arbitrage cash, fence =
  burst cash, contracts = endgame cash + REP, hacking = XP + botnet + heat.
- **Tune the whole curve** in one pass: `STATUS_RANKS`, `JOBS`, `TARGETS`,
  `GOODS`, `FENCE_PRICE` (55), `CONTRACTS`, `APARTMENTS`. Target shape:
  days 1–3 scrape to the $100 laptop; first week to a working botnet; mid
  game Corp Row; late game the AI datacenter.
- **Energy as the pace limiter** is already right — keep it the throttle so
  more income sources don't break the day.
- Effort: ~1 day. Mostly data + one richer trash function.

## G2 — Character creation & customization (SHIPPED)

A front door that makes the run *yours*. `scenes/ui/char_creation.tscn`
(title NEW GAME → creation → world). Pick a **handle**, **skin tone**,
**starting outfit + hat** (granted free), and a **background class**:
Scrapper (+50% scrap), Coder (+2 CPU, +1 skill point), Face (REP grows
faster), Runner (starts with the Hoverboard). Persisted via `handle`,
`skin_tone`, `background`. Skin tints the head/hands, outfit the body
(`player_3d._apply_cosmetics`); handle shows on the HUD and is woven into
wanderer recognition and R10T's texts. Verified end-to-end: "Wraith", Coder
→ 2 CPU + 1 skill point, neon jacket equipped, handle on the meta line.

### Original design notes

- **Creation screen** between title and world: enter a **handle** (used
  everywhere already wired for "the player" — CITY WIRE, recognition, R10T
  texts, NPC dialog), pick a **starting look** (outfit color + hat + skin
  tone — extends the existing cosmetic system), and a **background/class**
  that gives a small permanent bias:
  - *Scrapper* — +trash/scrap yield
  - *Coder* — +1 starting max CPU
  - *Face* — +REP gains
  - *Runner* — starts with the hoverboard
- Persist `handle`, `skin_tone`, `background` in `PERSISTED`. New-game flow:
  `title_screen` → `creation_screen` → `iso_main`.
- Skin tone needs a tintable head on `char_player.tscn` (mirror the
  cosmetics `material_override` approach already in `player_3d`).
- Effort: ~1–2 days.

## G3 — Quests v2 + more NPCs (SHIPPED)

Much more to do, more faces to do it with, and a city full of regular people.

- [x] **Crowd of regular people** — `district_3d._spawn_crowd` fills each
  district with anonymous pedestrians scaled to its size (~6 in the Market,
  varied tints + names from `GameData.CITIZEN_NAMES`/`CITIZEN_TINTS`), who
  roam, mutter, and can be greeted. Respects `wander_zone` (none in APT 4B),
  thins under sweeps/night. The city reads as busy now.
- [x] **3 new service NPCs** (spawned as tinted citizens via the
  `CHAR_SCENES` fallback): **Sparks** (Market, bulk-sells your whole loot
  bag at +10%), **Tess** (Plaza, sells a skill point at a climbing price),
  **Ozark** (Underpass, daily scrap bounty → $120 + 2 REP). Wired through
  `NpcDialogs` side-effects like Vex/Marlowe. All verified live.
- [x] **Quest log** modal (QUESTS rail button): active objective, the full
  story chain with done/active/upcoming markers, and district bounties.
- [ ] Deeper branching side-quests (multi-step, choices) — a follow-up; the
  bounty + log + service NPCs deliver the core G3 value now.

### Original design notes

- **Quests**: `GameData.QUESTS` is a linear list today. Add (a) more main
  beats, (b) **side quests** from NPCs (the favor system is the seed), and
  new cond types: `befriend` an NPC, `win_fight`, `explore` a district,
  `own_gear`. A **QUEST LOG** modal (rail button) listing active/done.
- **More NPCs**, now that districts are 2x bigger and feel empty:
  - Market: a **parts dealer** (sells gear scrap / crafting bits)
  - Underpass: a **scrap boss** (bulk-sells your scrap, gives Underpass
    quests)
  - Corp Row: a **corp insider** (leaks high-tier targets for REP)
  - Darknet: a **gear fence** (rare combat equipment)
  - Plaza: a **trainer** (pay to respec skills / buy XP)
  Each = a `GameData.NPCS` entry (+ schedule), a `NpcDialogs` block, and a
  service hook. The map's "who's where" board already scales to them.
- Effort: ~2–3 days (incremental — one NPC/quest at a time).

## G4 — Equipment & gear with stats (SHIPPED)

The stat backbone everything else leans on. `GameData.GEAR` (3 tiers each
of RIG/FIREWALL/IMPLANT), bought/swapped in the pawn shop GEAR section;
derived totals in GameState (`total_cyber_attack/defense/integrity/crit`,
`gear_hack_bonus`). LOADOUT modal (GEAR rail button) shows stats + equipped
slots. A sharper RIG lifts exploit odds (terminal `_chance`). Persisted via
`owned_gear`/`gear`. Verified: Breaker Rig + Reflex Booster + Foam Firewall
→ ATK 7 · DEF 3 · INTEGRITY 32 · CRIT 5% · +7% hack. Ready for G6 combat.

### Original design notes

- New **functional gear slots** alongside the cosmetic outfit/hat:
  **RIG** (cyber_attack), **FIREWALL** (defense), **IMPLANT** (utility:
  +HP/integrity, crit, heat-resist), **DECK** (the hoverboard tier).
- Gear items carry stats: `cyber_attack`, `defense`, `integrity` (combat
  HP), `crit`, plus flavor. Cosmetics stay purely visual; gear is the
  number layer.
- Sources: buy (pawn shop / Darknet gear fence), loot (rare trash finds,
  fight rewards), craft (parts dealer).
- **LOADOUT** modal (rail) showing equipped gear + total derived stats.
- Derived stats also nudge hacking odds (a better RIG = better exploit
  chance), tying gear into the existing terminal loop, not just combat.
- Persist `gear` (slot→item id) + `owned_gear`. Effort: ~2 days.
- *Prerequisite for G6 combat.*

## G5 — Police escalation: beat cops & the trace countdown (SHIPPED)

Shipped: Heat 100 now starts a 30-second TRACE countdown instead of an instant
bust. Failed high-risk terminal hacks force Heat to 100 and start TRACE
immediately. Leaving the district through an exit or city-map travel shakes the
trace and leaves Heat at 75; waiting out the timer applies the existing bust
penalty. Districts now show beat cops under elevated Heat and faster tracker
units during active TRACE.

- **Beat cops**: ambient patrol NPCs (reuse the wanderer brain) that stroll
  every district; at higher heat there are more of them and they move with
  purpose. Flavor + presence (the drone from Phase 1 was the seed).
- **Tracker cops + TRACE**: when you get **caught hacking** (a failed/high-
  heat exploit at the terminal, or lingering at max heat), a **TRACE
  sequence** fires: a full-screen countdown (e.g. 30s) + a HUD banner
  "TRACE ACTIVE — LEAVE THE DISTRICT". Tracker units converge (drones +
  cops). **Reach a district exit before the timer hits zero** to shake them;
  fail and you're **busted** (escalated version of the current
  `GameState._bust()` — lose cash/botnet, but now it's earned through a
  chase you could have won).
- Hooks: `terminal` exploit outcomes raise a `trace_started` signal;
  `main_3d` runs the countdown UI + spawns trackers; `go_to` (district
  change) clears the trace = "you escaped."
- Optional: high Stealth skill / a FIREWALL implant lengthens the timer.
- Effort: ~2–3 days. The countdown UI + trace state machine is the work.

## G6 — Combat: turn-based hacker battles

The headline new system — RPG/Pokémon-style fights.

- **Encounters** (infrequent, so they stay special):
  - A **rival hacker** ambushes you in the world (R10T as a recurring
    boss; lesser enemies as random street encounters at higher status/heat).
  - Optionally, a **tracker cop** can be *fought* instead of fled.
- **Battle screen** (a `SubViewport` or full-screen modal): you vs opponent,
  each with **integrity** (HP) and a turn-based action menu:
  - **EXPLOIT** — attack, damage = cyber_attack vs their defense (+crit)
  - **FIREWALL** — defend / reduce next hit, regen a little integrity
  - **PROGRAM** — consumable/utility (use an item, debuff, DOM stall)
  - **JACK OUT** — flee (chance scales with Stealth; fails cost a turn)
- Stats come from **G4 gear** + skills + CPU. Win → cash / data / gear /
  REP / XP; lose → lose some cash or stolen_data (a real setback, *not* a
  full bust — losing a fight ≠ getting traced).
- Enemies are data (`GameData.ENEMIES`: integrity, attack, defense, moveset,
  loot). Reuses the blocky character art for the opponent portrait.
- This is the biggest lift: a battle state machine + UI + balancing.
  Effort: ~1–2 weeks. Build after G4 (needs the stat layer).

## G7 — Street life: traffic & crowds (slot anywhere)

Ambient motion that makes the bigger districts feel inhabited.

- **Cars**: blocky vehicles that drive lane paths through a district and loop
  at the edges. Lanes are data per district (a few points); a simple
  path-follower mover. Pure flavor, no collision with gameplay.
- **Hoverboarders**: citizen variants that zip by faster than walkers (reuse
  the board mesh + wanderer brain at high speed).
- **Denser crowds**: bump ambient wanderer counts in the enlarged districts;
  thin them under sweeps/night (already wired).
- Effort: ~2–3 days. Can land opportunistically alongside other phases.

---

## LATER — Teaser districts

The five "???" stops already on the city map, promoted to real districts via
the chunk kit (each ~a day now): **Old Exchange** (timed heists), **Neon
Strip** (casino/cash sink + rival crews), **Signal Yards** (war-driving),
**Rooftops** (relay endgame), **The Stacks** (container maze). Hooks live in
`GameData.DISTRICT_MAP.future`.

## LAST — Apartments v2 (the cosmetic money sink)

Per the standing design call. Classes per district, functional + cosmetic
furniture, Style score, trophy shelf. Full spec in `ALIVE_ROADMAP.md` Phase 5.

---

## Suggested build order

G1 (economy) → G2 (creation) → G3 (NPCs/quests) → G4 (gear) → G5 (police
trace) → G6 (combat) → G7 (street life, or slot earlier) → teaser districts →
apartments. G7 and individual G3 NPCs can be pulled forward as palette
cleansers between the heavier systems.
