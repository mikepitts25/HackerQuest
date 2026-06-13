# Hacker Quest — Isometric 3D Art Direction (v0)

Supersedes the "stay 2D top-down pixel art" recommendation in
`WORLD_ART_ROADMAP.md` §2/§4. New direction: **blocky low-poly 3D characters
and sets, rendered with a fixed orthographic isometric camera** (Crossy Road /
Monument Valley proportions, synthwave palette). See
`docs/iso_styleframe_preview.png` for the first style frame.

## Why this works for us

- The roadmap's core warning about 3D (rigging, navmesh, relighting, weeks of
  cost) assumed *sculpted* 3D. Blocky primitive characters sidestep all of it:
  no rigging (animate by tweening/rotating box parts), no texture painting
  (flat `StandardMaterial3D` colors + emission), tiny file sizes, and the
  mobile renderer handles it with glow enabled.
- A fixed orthographic camera means gameplay stays effectively 2D: movement on
  a ground plane, same `Interactable` pattern, same camera-follow logic — only
  the presentation layer changes, which is exactly the separation the roadmap
  says to protect.
- The cosmetic system maps cleanly: outfit = body/arm material swap, hat =
  separate mesh on the head (the cap on `char_player.tscn` is already built as
  detachable nodes).

## Style rules (lock these)

- **Proportions:** ~1.25u tall, oversized head (≈0.45u cube), stubby limbs.
- **Geometry:** axis-aligned boxes only; detail comes from thin emissive
  strips (zippers, cap logos, LEDs), never from sculpting.
- **Palette:** near-black bases (#11141a–#232733), one saturated identity
  color per character, neon accents from the existing UI palette
  (#7ee787 green, #7adfff cyan, #b277e0 purple, #ff3ec8 magenta).
- **Lighting:** dim bluish sun + colored omni lights per neon source; WorldEnvironment
  with dark bg, low ambient, glow enabled, filmic tonemap.
- **Camera:** orthographic, yaw 45°, pitch −30°, `keep_aspect = Keep Width`
  for portrait phones.

## Assets (all procedural .tscn, no imports)

Characters use canonical `GameData.NPCS` identity colors and share a node
recipe: legs at the root, everything else parented under `Body` (or
`Coat`/`Cloak`), so each ships with a built-in `AnimationPlayer` holding
`idle` (autoplays) and `walk` clips — call
`$AnimationPlayer.play("walk")` from movement code, no rig needed.

| Character | Gimmick | Path |
|-----------|---------|------|
| Player | green hoodie, cap, backpack | `assets/iso/characters/char_player.tscn` |
| Pix (#b277e0) | tiny, antenna beanie with glowing tip | `assets/iso/characters/char_pix.tscn` |
| Riot (#3aa68a) | teal jacket, magenta mohawk | `assets/iso/characters/char_riot.tscn` |
| Glitch (#e0894a) | orange visor, glitch panel on chest | `assets/iso/characters/char_glitch.tscn` |
| Marlowe (#3b5dc9) | wide trench, fedora, glowing tie | `assets/iso/characters/char_marlowe.tscn` |
| Vex (#c060c0) | purple coat, hood up, glowing eyes | `assets/iso/characters/char_vex.tscn` |
| Cipher (#5ad1c0) | corp suit, teal visor, shoulder pads | `assets/iso/characters/char_cipher.tscn` |
| Oracle (#d06fff) | floor-length cloak, hidden face, floating orb | `assets/iso/characters/char_oracle.tscn` |

| Prop / building | Notes | Path |
|-----------------|-------|------|
| Bed | green blanket accent | `assets/iso/props/prop_bed.tscn` |
| Desk + terminal | `ScreensOn`/`ScreensOff` child nodes for the lit state | `assets/iso/props/prop_desk_terminal.tscn` |
| Shop counter | neon strip + canopy | `assets/iso/props/prop_shop_counter.tscn` |
| Job board | paper notes + one glowing "new job" note | `assets/iso/props/prop_job_board.tscn` |
| Trash pile | `Full`/`Searched` child nodes for the searched state | `assets/iso/props/prop_trash_pile.tscn` |
| Exit marker | neon arch + floor pad + omni light | `assets/iso/props/prop_exit_marker.tscn` |
| Server rack | alternating green/cyan LEDs | `assets/iso/props/prop_server_rack.tscn` |
| Neon sign | carries its own magenta omni light | `assets/iso/props/prop_neon_sign.tscn` |
| Tower block | window strips on two faces, roof edge neon | `assets/iso/buildings/bldg_tower.tscn` |
| Shop block | door, amber windows, mounted neon sign | `assets/iso/buildings/bldg_shop.tscn` |

Showcase scenes (open and Play Current Scene):
- `scenes/proto/iso_styleframe.tscn` — original 3-character style frame
  (`docs/iso_styleframe_preview.png`)
- `scenes/proto/iso_asset_sheet.tscn` — every asset on one contact sheet
  (`docs/iso_asset_sheet.png`)
- `scenes/proto/iso_district_mock.tscn` — composed market/plaza corner
  (`docs/iso_district_mock.png`)

## Playable slice (done)

`scenes/proto/iso_playground.tscn` — the district mock, alive. Play it and
walk with WASD/arrows (the HUD joystick path works too: the controller reads
`GameState.touch_vector` exactly like the 2D player).

- `scripts/iso/player_3d.gd` — `CharacterBody3D` controller. Camera-relative
  movement on the ground plane (45° iso mapping), same input actions as 2D,
  switches the visual's `idle`/`walk` clips, rotates only the `Visual` child
  to face travel. The ortho camera is a child of the player, so it follows
  for free.
- `scripts/iso/wanderer_3d.gd` — 3D cousin of `wanderer.gd`. Strolls between
  random points in an exported rectangle, idles between trips, drives the
  character's animations. Pix, Riot, Glitch, Marlowe, and Oracle wander the
  playground at personality-tuned speeds; Vex holds the counter and Cipher
  loiters by the shop.
- Collision: capsule on the player, invisible `StaticBody3D` boxes on
  towers/shop/counter/board/rack plus perimeter walls. Verified live: the
  player slides around building corners and stops at the map edge.

## Interaction (done)

- `scripts/iso/interactable_3d.gd` — `Interactable3D`, the Area3D port of
  `interactable.gd` with the same API (`configure(prompt, action, size)`,
  `interact()`, `set_dim()`). Attach as a child of the prop/character that IS
  the visual; it rides along with moving NPCs. `set_dim()` toggles
  `Full`/`Searched` child nodes when the prop has them (trash piles), else
  fades the meshes.
- `player_3d.gd` grew the same reach flow as the 2D player: a sphere reach
  area tracks nearby interactables, nearest one owns the prompt
  (`GameState.prompt_changed`), `interact` action / `interact_requested`
  fires its Callable.
- `scripts/iso/iso_playground.gd` — playground glue + minimal HUD (prompt
  label, toast feed off `GameState.toast`). The trash pile runs the REAL sim
  loop (energy, loot, cash, XP against live GameState — verified: $15→$23,
  copper wire + RAM stick looted); NPCs and props give flavor toasts.
  Safe by design: playing the scene directly never loads or saves the
  player's save file (`is_new_game` stays true).

## The city (done) — full game in 3D

`scenes/iso/iso_main.tscn` IS the game running in 3D: the real HUD (stats,
quest tracker, joystick, interact button), the real Terminal and Shop
panels, real dialogs, district travel, and the live simulation. Open it and
Play Current Scene. Verified end-to-end: intro dialog → apartment (bed
prompts Sleep) → Plaza travel via the exit arch → Riot's status-aware
banter → Market with the LOCKED Corp Row arch refusing entry with the
status-requirement toast.

- `scripts/iso/main_3d.gd` — 3D shell mirroring main.gd: same routing
  (`go_to`), same UI forwarding API (`use_desk`, `open_shop`, `show_jobs`,
  `open_apartments`, `open_contracts`, `talk_npc`, `talk_wanderer`), same
  busted handling, plus a screen-space toast feed (the 3D stand-in for the
  2D player's floating text). Districts can't tell which shell they run in.
- `scripts/npc_dialogs.gd` — NPC dialogue extracted from main.gd into
  static funcs shared by BOTH shells (main.gd now delegates too).
- `scripts/iso/district_3d.gd` — district base mirroring district.gd:
  `_build()` override, spawn marks, and helpers (`_ground`, `_patch`,
  `_wall`/`_border` with collision, `_sign` as billboard Label3D, `_prop`,
  `_interact`, `_box_interactable`, `_exit` with lock gating, `_trash_pile`
  with the real scavenge loop, `_spawn_npcs` from GameData at 80px = 1m,
  `_spawn_wanderers` tinting `char_citizen.tscn` to each ambient NPC's
  identity color).
- All five districts ported at the same layout proportions:
  `scripts/iso/districts/{home,plaza,market,corp_row,darknet}_3d.gd` +
  `scenes/iso/districts/*.tscn`. Market trash piles reuse the 2D save ids
  (`trash_0..2`), so persistence carries over.
- To make 3D the shipping game: point the title screen at
  `scenes/iso/iso_main.tscn` instead of `scenes/main.tscn`. The 2D game
  remains fully playable — both shells share all logic.

## Polish backlog

- ~~Cosmetics~~ DONE: `player_3d.gd::_apply_cosmetics()` tints body/arms via
  `material_override` from `GameState.cosmetic_color("outfit")` and toggles
  hat meshes (cap/beanie/crown nodes in `char_player.tscn`, crown emissive)
  on `cosmetics_changed`. Verified live: gold tracksuit + glowing crown
  (`docs/iso_cosmetics.png`).
- ~~Day/night~~ DONE: `main_3d.gd::_update_daylight()` tweens ambient/sun/
  background between warm DUSK and cold NIGHT keyed to energy remaining
  (fresh after sleep = dusk; running on fumes = dead of night). Compare
  `docs/underpass_dusk.png` vs `docs/underpass_night.png`.
- Per-district lighting moods (extra omni lights per district scene).
- Camera clamping to district bounds (2D shell clamps; 3D currently
  follows freely — fine at current district sizes).
- Wanderer obstacle avoidance (they roam through props, same as 2D).

## Tooling

- **No new tools required** for this style: the Godot MCP plugin (installed)
  builds/renders everything; scenes are hand-written `.tscn` with `BoxMesh` +
  `StandardMaterial3D`.
- Optional upgrades, only if the style needs to grow past boxes:
  - **Blender MCP** — bevels, chamfers, real low-poly modeling, exports GLB.
  - **Meshy / Tripo MCP** — AI text-to-3D for hero props (paid credits;
    output style is hard to keep consistent — use sparingly).
  - **CC0 packs** — Kenney (kenney.nl), KayKit, Quaternius cyberpunk pack for
    drop-in low-poly characters/buildings with animations.
