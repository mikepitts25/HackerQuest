# Hacker Quest — "Alive City" Roadmap

The plan for making the city feel inhabited, reactive, and worth grinding.
Guiding principle: **the simulation already knows everything — make the world
show it.** Heat, botnet, status, day cycle, and money all exist in GameState;
aliveness is mostly presentation wired to state we already track.

3D shell only (`scenes/iso/`). The 2D shell is legacy.

---

## Phase 1 — The world reacts to you (SHIPPED)

Pure presentation over existing sim state. Highest aliveness per effort.

- **Heat empties the streets.** Above Clean (heat_penalty > 0), districts
  spawn ~half their wanderers and the rest hurry (1.8x walk speed), and a
  police drone orbits the district with red/blue strobes. Rebuilt on every
  district entry, so lying low visibly calms the city.
- **The botnet glows.** Buildings sprout small winking green LEDs, one per
  bot (capped per district). The city literally becomes yours as you climb.
- **CITY WIRE news feed.** `news` in the terminal prints procedural
  headlines generated from live state — your unattributed crimes, police
  sweep notices at high heat, whispers about your status title — padded
  with city flavor. Every morning (day change) one headline drops as a
  toast: the city talking about what you did yesterday.

## Phase 2 — Grind identity per district (IN PROGRESS)

- [x] **Daily district modifiers** — one per day, deterministic from the
  day number (no save data): Gig Surge (plaza +50% jobs), Corp Crunch
  (corp gigs +50%), Scrap Rush / E-Waste Drop (double scrap), Fence Demand
  (Vex +50%). Announced as an amber toast at boot + each morning, starred
  on the city map, applied at payout time via `GameState.daily_mult()`.
- [x] **District mastery tracks** — activity earns per-district points
  (jobs → plaza/corp_row, trash → that district, fencing → market,
  contracts → darknet ×2, sleeping → home). Tiers at 5/15/30 points grant
  permanent payout perks by kind (GameData.MASTERY; +5% jobs, +10% fence,
  +25% scrap, +10% sleep cooling, +5% contracts per tier; Drowned Quarter
  reserved for the taps mechanic). Tier-ups toast; the city map shows
  amber mastery pips under each open station. Persisted via `mastery` in
  PERSISTED (old saves load clean). Verified live: 5 plaza jobs → tier 1 →
  next job paid $21 vs $20 base.
- [x] **Per-district activity loops** — Plaza **Community Board** (FAVORS:
  four REP-paying tasks, one of each per day, feed plaza mastery) and the
  Market **Goods Exchange** (buy-low/sell-high commodities with daily
  prices deterministic per day+good, feed market mastery). Both persisted
  (favors_done, goods). Verified: favor +1 REP & re-run blocked; goods
  price day-stable, buy/sell + mastery tick. Phase 2 COMPLETE.

- Plaza = REP (favors, notice-board side-quests). Market = MONEY (fence,
  goods market with daily prices). Underpass = early XP/scrap. Corp Row =
  high-tier money+XP. Darknet = endgame contracts. Drowned Quarter =
  unique loot via physical taps.
- **District mastery track:** activity fills a per-district meter →
  permanent perk (+10% fence prices, −heat decay in hideouts, etc.).
  Grinding becomes claiming territory.

## Phase 3 — 10x scale (IN PROGRESS)

- [x] **Movement upgrade:** Hoverboard ($250, +60% speed) and Maglev Deck
  ($1200, +120%) upgrades; a glowing board mesh materializes under the
  player and banks into turns, legs still (gliding). Verified 4.48 vs 2.8
  base. Sold in the pawn shop (auto-listed).
- [x] **Chunk kit:** `_skyline_row()` / `_back_street()` helpers stamp
  building clusters + pavement in one call. Plaza enlarged ~2.6x (22x15)
  with a ringed skyline + south promenade as the proof case.
- [x] **Chunk-kit rollout** — all main districts enlarged ~2x via the kit:
  Market 13.75x10 → 20x14 (5-pile e-waste yard, vendor alley, tenement
  skyline), Corp Row → 20x14 (12-rack datacenter hall, loading dock, glass
  towers), Darknet → 18x13 (6-rack rig hall, back alley), Underpass → 15x11
  (6-pile motherlode, longer pillar run). Drowned Quarter already large.
  All exits/spawn marks kept consistent; verified all four build + the
  12-rack farm renders.
- [ ] Map sub-stops if traversal demands it (the hoverboard covers it for
  now).

## Phase 4 — Inhabitants (IN PROGRESS)

- [x] **Wanderer chatter:** idle wanderers pop a Label3D speech bubble —
  generic muttering, sweep-nerves when heat is up, panic at heat ≥ 80.
- [x] **Recognition:** at Shadow Broker+ (status idx ≥ 4) a wanderer you
  pass within 2m turns to face you and gasps your status title. Once each.
- [x] **Quieter streets:** wanderers thin under sweeps (was phase 1) AND
  late at night (energy ≤ 30% of max) — combined skip up to 80%.
- [x] **Rival presence:** R10T claims ~1 board gig/day (deterministic per
  day, never the starter job) — shows "CLAIMED — R10T" / TAKEN.
- [x] **Apartment privacy:** districts can set `wander_zone` to confine
  ambient NPCs; home_3d limits it to the street strip so nobody spawns in
  APT 4B. (Verified: 0 intruders inside.)
- [x] **NPC schedules:** named regulars relocate by day
  (GameData.NPC_SCHEDULE + GameState.npc_district). Riot makes rounds
  (plaza→market→corp_row), Glitch keeps moving (plaza→underpass→market);
  mentors/endgame contacts stay put. Visitors loiter near the entrance
  with a "(visiting)" sign instead of their home coords. The CITY GRID map
  shows a colored name tag per NPC at their current station — a live
  "who's where today" board. (Verified: Day 1 Riot in Market, Glitch in
  Underpass, both shown on the map.)
- [x] Stalls shutter at night (was logged under phase 4 shutters).
- [ ] **A pet:** SHIPPED (Byte). [see above]
- [ ] **Phone/inbox:** SHIPPED. [see above]

## Phase 5 (LAST) — Apartments v2: the cosmetic money sink (SHIPPED)

The sink shipped as a furniture system on top of the existing apartment tiers
(`GameData.FURNITURE`, bought from a **FURNISH board** in the apartment):

- [x] **Functional furniture:** Memory-Foam Bed + Espresso Machine (+max
  Energy, applied at purchase), VPN Rack (+heat cooldown/day), Server Closet
  (+$/day). Effects stack on the apartment-tier perks.
- [x] **Cosmetic furniture + Style score:** palm, posters, shag rug, neon
  sign, jellyfish tank, arcade cabinet — each adds Style; Style pays a small
  daily REP trickle (`style_rep_per_day`, applied on sleep). All pieces render
  in `home_3d` (emissive for neon/tank/arcade).
- [x] **Trophy shelf:** a back-wall shelf with a glowing token per milestone
  earned (first pwn, first bot, Black Hat, botnet swarm, R10T down, Legend) —
  derived live from state, not bought.
- Status-gated like gear; persisted via `owned_furniture`. Smoke-covered.

Deferred (was in the original spec, not built): **classes per district /
owning multiple apartments / sleep-anywhere** — a housing-model refactor that's
less aligned with the "cosmetic sink" goal. The single-apartment furniture
system delivers the sink; multi-property can be a later milestone.

### Original design notes

- **Classes per district:** Squat (Underpass, free) → Studio (Block) →
  Loft (Market) → High-rise (Corp Row) → Penthouse (Drowned Quarter).
  Every owned apartment = spawn point + "sleep anywhere you own".

## Always-on candidates (slot anywhere)

- SFX + per-district ambience (waiting on the sfx folder).
- Weather: rain shader nights, fog.
- Trains/drone traffic as background motion.
- Old Exchange / Neon Strip / Signal Yards / Rooftops / The Stacks
  district builds (map teasers already placed).
