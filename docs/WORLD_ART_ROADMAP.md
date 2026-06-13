# Hacker Quest — World, Art & Engine Roadmap

A practical plan for growing the prototype: a bigger world, real art and
animation, and an honest take on 2D-vs-3D. Ordered by recommended sequence and
ROI. Nothing here is built yet — this is the plan.

The guiding principle: **the simulation is the product.** Stats, hacking, heat,
status, NPCs, and the economy are all data-driven and decoupled from how the
world is drawn (`WorldBuilder` builds placeholder rects; `Interactable` is a
generic Area2D + Callable). That means we can upgrade visuals in layers without
rewriting gameplay. Protect that separation as we scale.

---

## 1. Bigger map & game world

### Where we are
- One 1600×1600 scene, built entirely in code by `world_builder.gd` (ground
  rects, walls as `StaticBody2D`, signs, NPCs, trash).
- A single camera that follows the player with hard limits to the map bounds.
- Everything lives in one `Main` scene; no streaming, no rooms.

### Target: a districts model
Move from "one room" to a **hub-and-districts** city. Each district is its own
scene the player travels between, so we can add content without one giant scene
getting unwieldy.

Proposed districts:
| District | Purpose | Anchors |
|----------|---------|---------|
| **The Block** (home) | apartment, sleep, desk/terminal, stash | starting area |
| **The Market** | pawn shop, Vex's fence stall, cosmetics | buying/selling |
| **The Plaza** | job board, NPCs (Riot, Glitch, Marlowe), notice board | social/quests |
| **The Underpass** | e-waste/scavenging, sketchy deals | early econ |
| **Corp Row** (unlocks w/ status) | high-tier job givers, server farms | mid/late game |
| **The Darknet Café** (unlocks late) | elite NPCs, endgame contracts | endgame |

### How to get there
1. **Promote `Main` into a district loader.** Add a lightweight `WorldRouter`
   autoload (or a node in a persistent root) that does
   `change_scene_to_file()` between district scenes and remembers spawn points.
   `GameState` already survives scene changes (it's an autoload), so travel is
   safe today — the title→world transition already proves this.
2. **Travel points.** Add an `Interactable` type "exit" that calls
   `WorldRouter.go_to("market", "from_block")`. Districts declare named spawn
   markers; the router places the player at the matching one.
3. **Gate districts by progression.** Reuse the existing `status_index()` /
   level checks (same pattern as status-gated cosmetics and jobs) so new areas
   unlock as the player climbs — built-in retention.
4. **Migrate rendering to `TileMapLayer`.** Replace the `_rect`/`_wall` helpers
   with a tileset. Keep `WorldBuilder` as the *spawner* of interactables/NPCs
   but let tiles handle floors/walls/collision. This is the single biggest
   readability + performance upgrade and it doesn't touch gameplay code.
5. **Data-drive placement.** Today NPCs already come from `GameData.NPCS`
   (`{name, pos, color}`). Extend that pattern: add a `district` field, and add
   `GameData.DISTRICTS` describing each scene's exits, spawn markers, and
   unlock requirement. New content becomes data, not code.

### Effort
- Router + travel points + 2 hand-built districts: **~2–3 days.**
- TileMap migration with a placeholder tileset: **~1–2 days.**
- Full 6-district city with art: gated on the art pipeline (section 2).

---

## 2. Real sprite assets

### Recommended style
**16×16 or 24×24 top-down pixel art, dark "synthwave/cyberpunk" palette.**
Reasons: cheap to produce/commission, reads great on phone screens, matches the
terminal/neon aesthetic we already lean on (`#7ee787` green, `#7adfff` cyan,
`#b277e0` purple), and animates with few frames. Avoid hi-res vector or
hand-painted — it balloons cost and file size for a mobile prototype.

### Asset list (minimum viable art pass)
- **Player:** 4-direction walk (down/up/side, flip for left+right) + idle.
  4–6 frames per direction. The cosmetic system already separates **outfit**
  (body tint) and **hat** (overlay) — preserve that: draw the base body, tint
  or swap the torso, and render the hat as a separate sprite layer above the
  head. This keeps the wardrobe working with real art.
- **NPCs:** one idle sprite each (Pix, Riot, Glitch, Marlowe, Vex) + a 2-frame
  idle bob. Distinct silhouettes/colors so they read at a glance.
- **Tileset:** asphalt, plaza tile, alley grime, apartment floor, walls,
  doors/exits, neon signage. ~1 sheet.
- **Props:** bed, desk + monitors (lit state when terminal unlocked), shop
  counter, job board, trash piles (full/empty states — we already toggle a
  "searched" dim), server racks for Corp Row.
- **UI/icons:** small icons for stats (cash/CPU/energy/heat/rep/botnet),
  consumables, loot, and cosmetics to replace text-only rows.

### Pipeline
1. **Lock a 1-screen style frame first** (player + 3 tiles + 1 NPC) before
   commissioning a full set — cheap way to validate direction.
2. **Sourcing options, cheapest→best:**
   - Free/CC0 packs (Kenney, itch.io top-down cyberpunk packs) for an immediate
     non-placeholder pass.
   - A single pixel artist on commission for a cohesive custom set once the
     style frame is locked.
3. **Integration is mechanical and low-risk:** swap `ColorRect`/`_draw()` for
   `Sprite2D`/`AnimatedSprite2D`. The `Interactable.configure()` call already
   takes size/color/label — add an optional `texture` param and prefer it when
   present. The player's `_draw()` cosmetic logic maps 1:1 onto a layered
   sprite (body + hat).
4. **Import discipline:** set textures to **Nearest** filtering (crisp pixels),
   pack into atlases to cut draw calls, keep a consistent pixels-per-unit.

### Effort
- Drop-in CC0 pass (player + tiles + NPCs): **~1–2 days** integration.
- Custom commissioned set: **art lead time (1–3 wks)** + ~2 days integration.

---

## 3. Animation

Layer animation on *after* sprites exist. Priorities by player impact:

1. **Player locomotion** — `AnimatedSprite2D` with `walk_*`/`idle` clips, driven
   by the existing movement vector in `player.gd` (we already track `_face`).
   Biggest "game feels alive" win.
2. **NPC idle bobs** — 2-frame loops; trivial, high charm-per-effort.
3. **Feedback juice** — we already use `Tween` for floating text and toasts.
   Extend with: hit-stop/flash on bust, a screen-shake on "TRACED", a heat-bar
   pulse at Hunted tier, coin-pop on payouts, a CRT flicker when the terminal
   opens.
4. **Terminal** — typewriter reveal for command output (cosmetic, satisfying),
   blinking cursor, a subtle scanline shader.
5. **Environment** — flickering neon signs, monitor glow, a day/night tint
   driven by `GameState.day`.

**Tooling:** `AnimationPlayer` for one-off sequences (bust, level-up, status-up
flourish), `AnimatedSprite2D` for looping character anim, shaders
(`CanvasItemMaterial`/`.gdshader`) for CRT/neon/scanlines. All additive — no
gameplay changes required.

### Effort
- Player + NPC anim once sprites exist: **~2 days.**
- Juice/feedback pass: **~2–3 days, incremental.**

---

## 4. 2D vs 3D — recommendation

**Recommendation: stay 2D top-down. Do not migrate to 3D for this game.**

### Why 2D is the right call
- The core loop is **menus, terminal, economy, and short traversal** — none of
  it benefits from 3D. The fantasy is "elite hacker," sold through the terminal
  and systems, not spatial gameplay.
- **Mobile-first**: 2D is lighter (battery, thermals, load times), and our UI is
  already tuned for portrait phone resolutions.
- **Iteration speed**: 2D art/anim is dramatically cheaper and faster — critical
  for a solo/small effort chasing "more to do."
- **Sunk value**: the whole UI, camera, movement, and world system is 2D and
  working. A 3D port is a near-total rewrite of presentation for no design win.

### If you still want more depth/"wow" without going full 3D
- **2.5D / faux-perspective:** layered parallax backgrounds, drop shadows,
  height-offset sprites, lighting via `Light2D` + normal maps. Gets ~80% of the
  "modern" feel at a fraction of 3D's cost.
- **3D set-pieces in a 2D game:** a `SubViewport` rendering a rotating 3D server
  rack or city skyline embedded in the 2D UI — flavor without committing the
  game to 3D.

### What a real 3D migration would cost (for the record)
A genuine move to 3D means: new camera rig, 3D character controller +
navmesh, 3D models + rigging + animation (far pricier than sprites), relit
environments, and reworking every UI/world interaction for 3D space. Estimate
**weeks-to-months** and it would freeze feature work. Only revisit if the design
pivots to something spatial (e.g., physically infiltrating buildings).

---

## Suggested sequence

1. **District router + 2 hand-built districts** (unblocks "bigger world" now,
   pure code, no art dependency).
2. **CC0 sprite + tile pass** (kills the "placeholder rectangles" look fast).
3. **Player + NPC animation.**
4. **Juice/feedback + terminal polish.**
5. **Commissioned custom art** once the style is proven and the city layout is
   final.
6. **(Optional) 2.5D lighting/parallax pass** for production sheen.

Throughout: keep gameplay in `GameState`/`GameData` and keep presentation
swappable. Every system added so far (status, heat, cosmetics, NPCs, hardware)
already follows that rule — that's what makes this roadmap cheap to execute.
