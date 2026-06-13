# Hacker Quest — TODO & Suggestions

A running list of what's done, what's open, and ideas worth doing next. Pick
anything from here in a fresh session — each item notes where it lives in the
code so it's easy to resume.

Last updated: end of the district-content + display-fix session.

---

## How to run / test (quick reference)

- **Play in editor:** open the project in Godot 4.6, press **F5** (main scene is
  `scenes/ui/title_screen.tscn`).
- **Headless smoke test (run after any change):**
  ```
  Godot --headless --path . --import      # always import first
  Godot --headless --path . res://tests/smoke_test.tscn
  ```
  Expect `SMOKE TEST PASSED`. The test covers stats, hacking, heat/status,
  cosmetics, save/load, WiFi, districts, contracts, apartments, ambient NPCs.
- **Save file location (delete to reset):**
  `~/Library/Application Support/Godot/app_userdata/HackerQuest/save.json`
- **Gotcha:** if you add a `class_name` script, run `--import` before testing or
  the global class cache goes stale (`Could not resolve class X`). Better: avoid
  `class_name` for new classes and reference by path (see `district.gd`).
- **Gotcha:** the editor owns open `.tscn` files and overwrites external edits on
  run ("save before run"). Edit scene values through the editor (or close the
  scene) so they persist. project.godot edits are safe to make directly.

---

## ✅ Done so far (high level)

Core loop, mobile HUD, hacking terminal, save/load + title screen, XP/levels,
3-skill tree + War Driving, status ranks (9 tiers w/ rewards), heat/wanted
tiers w/ rank-scaled cooling, cosmetics (outfit+hat), consumables, NPC services
(Vex fence, Marlowe fixer), endgame hardware tiers, **district system**
(home/plaza/market + status-gated corp_row/darknet), **WiFi sniffing + known
networks**, **Darknet contracts**, **Corp Row gig board**, **apartments**,
**wandering ambient NPCs**, larger phone-shaped display.

---

## 🔧 Open / polish

- [ ] **Confirm the new display feels right on your screen.** `project.godot` now
      launches **maximized** with a **phone-shaped (9:16) letterboxed** view and
      hidpi on; camera zoom is **2.5** (`scenes/player.tscn`). If maximized is
      disruptive, set `window/size/mode=0` (windowed). If the world is too
      zoomed-in, lower the camera zoom; too small, raise it.
- [x] **HUD top bar runs off-screen at the right edge** — mitigated in the
      UI v2 pass (smaller mono fonts, slimmer XP bar, MAP moved to row 3).
      Verified: full bar + MAP fit at 720 wide even with long status titles.
- [x] **UI v2 — cyberpunk terminal restyle** (`ui_theme.gd` + `hud.gd` +
      `virtual_joystick.gd`): system monospace font everywhere, neon-on-black
      panels with 1px borders (green = actions, cyan = info), neon resource
      bars, "> " terminal dialogs, // ruled modal headers, cyan interact
      button, restyled joystick, subtle CRT scanline shader. Applies to both
      shells + title screen + terminal/shop via the shared theme.
- [x] **Juice pass v1**: dialog typewriter (tap completes line, tap again
      advances), CRT power-on stutter on modal open, heat bar pulses red
      whenever heat_penalty > 0, camera jolt on TRACED (3D shell). The 2D
      shell is no longer a design target — it inherits HUD juice for free
      but new feel work lands 3D-first.
- [x] **Neon sign flicker** (`scripts/iso/neon_flicker.gd` on
      prop_neon_sign): random 3–9s cadence, 2–4 stutters per burst, kills
      tube + glow light together. Every sign misfires on its own rhythm.
- [x] **Top bar v3** — info/action split: row 1 is status + cash only, one
      tiny meta line (DAY · LVL · REP · BOT), thin unlabeled XP strip,
      vitals bars at full-width equal thirds, quest line; SKILLS/BAG/MAP/
      WIFI moved to a vertical action rail on the right edge. Also fixed a
      latent anchor bug — the stats panel was shrink-wrapping instead of
      spanning the screen (masked before by wide content).
- [ ] **Modal CLOSE buttons** — automated taps sometimes hit a hidden modal's
      button; real play is fine, but consider hiding off-screen instead of just
      `visible=false`, or disabling buttons of inactive modals.
- [ ] **Walking onto exits/NPCs** needs precise positioning at high zoom. Consider
      auto-travel when standing in a doorway for a beat, or bigger exit hitboxes.
- [ ] **Balance pass** on the full curve (early scavenging → endgame ai_datacenter).
      Numbers are centralized: `STATUS_RANKS`, `HEAT_TIERS`, `TARGETS`, `JOBS`,
      `WIFI_ENCRYPTION`, `APARTMENTS`, `CONTRACTS` in `scripts/game_data.gd`.

---

## 🌃 Alive City (see docs/ALIVE_ROADMAP.md for the full plan)

- [x] **Phase 1 — world reacts to you**: heat above Clean thins wanderers
      ~55% + survivors hurry + a strobing police drone orbits each district;
      botnet size scatters winking green LEDs across district buildings;
      `news` terminal command + morning CITY WIRE headline toast generated
      from live state (`scripts/news_feed.gd`, `patrol_drone.gd`,
      district_3d hooks).
- [x] **Phase 2 — district grind identities** COMPLETE: daily modifiers +
      mastery tracks + per-district loops (Plaza FAVORS → REP, Market GOODS
      exchange → buy-low/sell-high arbitrage). All verified.
- [x] **Phase 3 — 10x scale** COMPLETE: hoverboard/maglev speed upgrades,
      chunk-kit helpers, and all main districts enlarged ~2x (Plaza, Market,
      Corp Row, Darknet, Underpass) with denser content — more trash piles,
      a 12-rack datacenter hall, skylines, vendor/loading back-streets. Only
      optional tail: map sub-stops (the hoverboard makes traversal fine).
- [x] **Phase 4 — inhabitants** COMPLETE: chatter, recognition, street
      thinning, R10T, apartment privacy, pet (Byte), burner-phone inbox,
      night stall shutters, AND NPC schedules — regulars relocate by day
      and the CITY GRID map shows a live "who's where today" tag per NPC.
      Only further-out idea left: deeper branching dialog.

## 🎮 Gameplay & RPG layer (see docs/GAMEPLAY_ROADMAP.md for the full plan)

The "game with stakes" pass: tuned economy, character creation, threats that
chase and fight you, gear with stats, way more to do. Build order:

- [~] **G1 — economy & balance pass**: SHIPPED — district-flavored trash +
      rare finds; trash gives NO xp now (pure money loop); job boards are
      randomized risk/reward bets (3 daily gigs, one status-gated advanced,
      heat + sideways-failure chance) instead of free money clicks. Open:
      per-source role tuning + whole-curve pass.
- [x] **G2 — character creation** SHIPPED: creation screen (handle, skin
      tone, outfit, hat, background class — Scrapper/Coder/Face/Runner) wired
      into title→creation→world; handle on HUD + in recognition/R10T texts;
      skin tints head/hands. Verified end-to-end.
- [~] **G3 — quests v2 + more NPCs**: SHIPPED — crowd of anonymous regular
      people per district (scaled to size, varied looks/names, chatter,
      greetable); 3 service NPCs (Sparks bulk-buy, Tess trainer, Ozark scrap
      bounty); quest-log modal (story chain + bounties). Open: deeper
      branching side-quests.
- [x] **G4 — equipment & gear stats** SHIPPED: RIG/FIREWALL/IMPLANT gear
      (3 tiers each) in the pawn shop; derived ATK/DEF/INTEGRITY/CRIT; a
      sharper rig lifts hack odds; LOADOUT modal (GEAR rail button).
      Verified. Prereq for G6 combat is ready.
- [x] **G5 — police escalation** SHIPPED: beat cops + a 30-second TRACE
      countdown. Heat 100 and failed high-risk hacks start TRACE; leaving the
      district shakes it, while timeout applies the existing bust penalty.
- [x] **G6 — combat** SHIPPED: turn-based hacker battles (EXPLOIT/FIREWALL/
      PROGRAM/JACK OUT) on the G4 stat layer. Headless CombatSession core +
      ENEMIES table (skid → cracker → trace unit → R10T) + combat programs
      (logic bomb/patch kit/proxy smoke) + combat screen (color log, hit
      flash) + rare street encounters and a once-per-game R10T boss. Plus
      fight-the-tracker: during a trace you can tap a converging trace unit and
      fight it — win clears the trace (heat zeroed), lose busts you. Verified
      live + balance-checked.
- [x] **G7 — street life** SHIPPED: cars ring the big districts on lane paths
      (`vehicle_3d.gd` + `district_3d._ring_road`), citizens zip by on glowing
      hoverboards (`wanderer_3d.rider`), and crowds are denser. Verified live
      in the plaza. Sweeps/night still thin the streets.
- [ ] **(LATER) teaser districts** — Old Exchange, Neon Strip, Signal Yards,
      Rooftops, The Stacks (already on the map as "???").
- [x] **(LAST) apartments v2** SHIPPED — FURNISH board sells functional +
      cosmetic furniture (rendered in home_3d), Style score pays a daily REP
      trickle, trophy shelf shows milestone tokens. Verified live + smoke.
      Deferred: classes-per-district / multi-property (housing refactor).

## 🎮 Gameplay ideas (older notes — some folded into GAMEPLAY_ROADMAP above)

- [ ] **Rotating contract pool** — when a Darknet contract completes, a new one
      appears so there's always fresh endgame work. (`game_data.CONTRACTS` +
      GameState pool logic; board UI already exists in `hud.gd`.)
- [ ] **Claimed WiFi networks pay a trickle** — cracked known-networks add a tiny
      daily income (like a mini-botnet) so the war-driving map keeps paying.
- [ ] **District-specific content** — Corp Row server racks you can hack in the
      world; Darknet contact who sells exclusive gear; plaza events.
- [ ] **More status tiers / prestige** — a "new game+" or reputation-decay
      mechanic for replay.
- [ ] **Random world events** — police sweeps when Heat is high, a fence sale, a
      rival hacker stealing some botnet.
- [ ] **Achievements / milestones** with small rewards (drives "keep coming back").
- [ ] **Daily login-style bonus** at the apartment (already have day cycle + sleep).
- [ ] **Tutorial polish** — the first 5 minutes lean on Pix dialog; consider
      objective arrows/highlights for first laptop, first hack.

## 🗺️ World / content

- [x] **District maps** — DONE (both shells). The HUD now has a **MAP**
      button (row 3, next to the objective) opening the **CITY GRID** modal:
      a subway-style network diagram drawn by `scripts/ui/city_map.gd` from
      `GameData.DISTRICT_MAP`. Live stations show lock state + unlock rank
      and a pulsing YOU ARE HERE; planned districts appear as dashed "???"
      teaser stops. Renders: `docs/city_map_ingame.png` (player view) and
      `docs/city_map_expansion.png` (`reveal_future = true`, names + hooks).
      Follow-ups:
      - [x] Fast travel: tapping an unlocked station closes the map and
            `go_to()`s there (free, arrives at district center; tapping a
            locked one toasts the status requirement). Works in both shells.
      - [ ] Expansion candidates below are now data in
            `GameData.DISTRICT_MAP.future` — promote one to a real district
            when ready:
         - ~~**The Underpass**~~ **SHIPPED** (both shells): 4 e-waste piles,
           expressway deck + graffiti pillars (3D), locked stash teaser, door
           to the Plaza. `scripts/districts/underpass_district.gd` +
           `scripts/iso/districts/underpass_3d.gd`. The stash crate is a
           hook for a future "sketchy deals" vendor.
         - **Signal Yards** — an antenna farm on the city's edge; war-driving
           paradise where rare encrypted networks cluster (feeds the WiFi map).
         - **The Stacks** — container-home maze; parkour-ish shortcuts between
           districts, hideout apartment tier with heat-decay bonus.
         - **Old Exchange** — abandoned stock exchange; time-window heist
           contracts (only open certain in-game days), big REP.
         - **Neon Strip** — arcade/casino row; minigame gambling sink for cash,
           a rival crew hangout, cosmetic vendor exclusives.
         - ~~**The Drowned Quarter**~~ **SHIPPED** (both shells, Architect-
           gated): glowing black water pools, tunnel ribs, half-sunken racks,
           fiber conduits, and THE TRUNK monolith with a floating core
           (`docs/drowned_quarter.png`). The "Jack into the trunk"
           interactable is the hook for physical-intrusion jobs / wired
           targets when that mechanic lands.
           `scripts/districts/drowned_quarter_district.gd` +
           `scripts/iso/districts/drowned_quarter_3d.gd`.
         - **Rooftops** (vertical district) — relay network endgame: place
           repeaters to link every district, passive botnet range boost.
      Map both onto a subway-style city diagram so players see locked
      districts as grayed-out stations — built-in aspiration/retention.
- [ ] **More districts** — the roadmap in `docs/WORLD_ART_ROADMAP.md` sketches a
      6-district city. Adding one is now: a `_build()` script + 4-line `.tscn` +
      an `_exit`, plus a `GameData.DISTRICTS` entry (with `status_req`). (3D:
      same recipe with `scripts/iso/district_3d.gd` — see
      `docs/ISO_ART_DIRECTION.md`.)
- [ ] **More apartments / furniture perks** beyond the current 4 tiers.
- [ ] **More NPCs + branching dialog** (current NPCs are state-aware one-shots).
- [ ] **Bigger maps per district** + a minimap.

## 🎨 Art / presentation (see docs/WORLD_ART_ROADMAP.md)

- [ ] **CC0 sprite + tile pass** to replace placeholder ColorRects — biggest
      visual upgrade for the effort. Swap `_floor`/`_draw` for Sprite2D /
      TileMapLayer; cosmetic body+hat maps to layered sprites.
- [ ] **Player + NPC walk/idle animations** (`AnimatedSprite2D`).
- [ ] **Juice**: screen shake on bust, coin-pop on payout, terminal typewriter +
      CRT shader, neon sign flicker, day/night tint by `GameState.day`.
- [ ] **Stat icons** in the HUD instead of text labels.

## 🧱 Tech / architecture

- [ ] **Multiple save slots** + an in-game settings menu (audio, window mode).
- [ ] **Audio** — there's currently no sound. Add SFX (keypresses, payouts,
      bust) and ambient music per district.
- [ ] **Android export** test (project is mobile-configured; touch works).
- [ ] **Save versioning/migration** — `SAVE_VERSION` exists in `game_state.gd`
      but no migration path yet.
- [ ] **Replace remaining `class_name` usages** (`Interactable`, `UITheme`,
      `VirtualJoystick`, `GameData`) with path refs if the cache ever bites again.

---

## 📁 Where things live

- `scripts/game_state.gd` — all state + rules (single source of truth, autoload).
- `scripts/game_data.gd` — all tunable data tables (targets, jobs, skills,
  status, heat, cosmetics, apartments, wifi, contracts, districts, NPCs).
- `scripts/main.gd` — persistent shell + district router + NPC dialogue.
- `scripts/district.gd` + `scripts/districts/*` — world areas (build by code).
- `scripts/ui/hud.gd` — HUD + every modal (jobs, skills, bag, wifi, vacancies,
  contracts).
- `scripts/ui/terminal.gd`, `shop.gd`, `title_screen.gd` — other screens.
- `tests/smoke_test.gd` — headless regression test (keep it passing).
- `docs/WORLD_ART_ROADMAP.md` — bigger-world / art / 2D-vs-3D plan.
