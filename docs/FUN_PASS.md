# HackerQuest fun and visual pass — 2026-11-04

Implemented in the current checkout, preserving its pre-existing boss, companion,
travel, and other changes. No commits or release uploads were made.

## Player-facing changes

- Animated skyline title screen with a clearer start action.
- Wider isometric camera (9.5 versus 6.5) to show more of the neighborhood.
- Pavement shader with staggered pavers, wear, and varied surface roughness.
- District-specific light colors, glowing perimeter channels, and street grates.
- Smaller world labels and a bright ring around the current interaction target.
- Daily signal caches in Plaza, Market, and Underpass: $18 for one energy,
  once per district per game day. Claimed caches survive travel and save/load;
  sleeping refreshes them through the existing search ledger.
- Opening HUD tracks savings toward the first laptop, then shows purchase
  directions. Job objectives retain priority. Starter signs identify the job
  board and laptop shop; hints disappear once a computer is owned.
- Non-blocking reward banners for discovery, quest completion, and level-ups.
- Chat feed fades after nine seconds without a message to reveal the world.

## Verification

Run `tools/check_fun_pass.sh --preview` from the repository. Set `GODOT_BIN`
if Godot is installed outside the default macOS application location.
The script copies the project to a temporary directory and configures a
separate `HackerQuest-Fun-QA` save profile before any state-resetting tests.
The new test scripts refuse to run with the normal player profile.

Verified with Godot 4.7.2 using the Forward Mobile renderer on Apple M2 Max:

- Existing smoke suite: `SMOKE TEST PASSED`.
- Cache energy cost, reward, repeat claim, persistence, daily reset,
  unsupported district, and exhausted-player checks: `STREET CACHE TEST PASSED`.
- Real 3D proximity selection and touch-action signal, focus ring, reward
  visibility without locking play, opening instructions, district rebuilding,
  and all five atmosphere districts: `FUN PASS PREVIEW PASSED`.
- Rendered title, Plaza discovery, and Market screenshots inspected.
- Independent scoped code review found no actionable correctness issues.
- `git diff --check` passed.

Some test runs report Godot ObjectDB/resource cleanup warnings at shutdown.
The verbose smoke inventory includes unfreed FakeMain fixtures; gameplay
assertions pass and the final rendered preview exits without those warnings.
This pass does not establish physical-phone touch, performance, or accessibility
acceptance, nor a full economy/playthrough balance review.

Screenshots and final test output are in `docs/qa/fun-pass/`.


## City model kit follow-up

Eight reusable editable `.tscn` models now live in `assets/iso/props/city/`:
vending machine, noodle cart, arcade cabinet, transit shelter, repair bench,
cargo stack, utility cabinet, and rooftop air conditioner. Open
`scenes/proto/city_prop_library.tscn` to inspect and reuse the set in the editor.
Regenerate the mesh scenes with `python3 tools/generate_city_props.py`.

`scripts/iso/city_set_dressing.gd` holds 25 authored street placements across
Plaza, Market, Underpass, Corp Row, and Darknet, plus air conditioners on selected
shop rooftops. Four existing noodle/ramen venues use the detailed cart model.
Coffee and sushi venues retain their existing geometry. Existing prices,
energy benefits, shop access, quest targets, and save IDs remain intact.
The props animate steam from an extractor chimney, arcade pixels, a small
repair arm, screens, and air-conditioning fans using local mesh transforms.

The full isolated smoke/cache/render checks passed again. Expanded renderer
checks verify real pawn-shop proximity and the ramen cart touch interaction
($10 cost / four energy restored). An independent review found no blocking
model or placement issues. The eight-model contact sheet was rendered and
inspected using the same Forward Mobile renderer. Screenshots and logs live
in `docs/qa/city-models/`. Physical-phone performance remains unverified, and
shutdown resource warnings remain in some automated runs.


## Modern interface follow-up

The main HUD now uses a compact rounded operator card with identity, credits,
resources, and a distinct next-objective section. Map, Quests, Bag, and More
live in a four-button bottom dock. The More panel contains Skills, Loadout,
Messages, Settings, and Wi-Fi when unlocked, with reputation/botnet details.
A large mint contextual button sits above the dock beside a redesigned stick.
The existing developer boost remains available under Settings in debug builds.

The shared theme uses a system sans-serif font, rounded dark surfaces, subtle
borders, and readable spacing. Terminal output keeps its explicit monospace
font. Shared modals have a visible header close button, a return-to-city action,
and a steady fade. Dialogue uses plain text and Continue. Shop cards and
category headers use the same visual system. Notifications are capped to two
messages with two visible lines each and fade when inactive.

HUD safe-area layout maps mobile display insets into viewport coordinates.
Header/feed/trace positions follow content height; bottom controls clear the
home indicator. Simulated insets and repeated changes are checked, but this
is not physical-device acceptance. A first-frame modal refit prevents short
menus from retaining heights measured before wrapped text gets its width.
The Plaza shelter and adjacent vending machine were shifted away from the
camera sightline to the entrance cache.

`tools/check_fun_pass.sh --preview` now includes actual viewport pointer taps
through all four dock routes, More-to-Skills routing, modal-lock recovery,
dialogue stacking protection, touch-target sizing, repeated inset changes,
header/dock/action bounds, and compact-menu height. The full smoke suite,
cache checks, modern UI test, gameplay renderer checks, and five-screen UI
capture pass all passed. Independent review confirmed the resize fixes.
Some older automated runs still emit ObjectDB/resource cleanup warnings on
shutdown. Screenshots and the final log are in `docs/qa/modern-ui/`.


## Integration verification

The integration candidate was exported directly from the Git index and verified
without the checkout's unrelated uncommitted boss, companion, and travel fixes.
The original committed smoke suite and all new cache/UI/render checks passed
on that exact source tree. Output is in
`docs/qa/modern-ui/commit-verification.log`. Unrelated local changes and
`.claude/` remain outside this commit.
