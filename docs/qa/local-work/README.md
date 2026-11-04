# Local work, equipment and shop implementation

Implemented on `codex/local-specialist-work`; production edits remain uncommitted
because several source files already contained unrelated work. The earlier
companion/player/drowned-quarter/smoke-test edits were preserved byte for byte.

## What changed

- 18 named specialist pickup points across six zones and 36 authored tasks.
- Local errands, three touch puzzle families, coherent staged contracts and
  guarded late retrievals. Daily offers have exact accepted terms; no random
  failure roll after a correct puzzle.
- Persisted paid-stage progress, attempts, clue usage, daily claims, tracking,
  abandonment, and once-only settlement. Existing active jobs keep their terms.
- Rigs provide 10/15/20% technical pay bonuses; firewalls protect against 1/2/3
  base heat before the shared heat calculation; implants provide 1/2/3 clues.
  Attack, defense, integrity, crit, and trophy target affinities still apply.
- Shop compares equipment and work utility, separates earned-only trophies,
  supports one saved purchase goal, and requires an explicit equip action.
- The Plaza repair kiosk has a limited consignment shelf so the first laptop
  and basic battle preparation are accessible before the Plaza boss. Full
  upgrades remain in the Market; boss gates are unchanged.
- Script Kiddie rewards are $35-55; Corner Cracker rewards are $100-160.
  Dedicated contract enemies pay through the accepted job terms.

## Evidence

Run `tools/check_local_work.sh --preview` and `tools/check_fun_pass.sh --preview`.
Both copy the game to temporary projects and use separate QA save profiles.

Both final commands exited 0. `work-tests.log` records the new lifecycle and real
renderer/pointer suites; `regression.log` records the five existing passing
suites. No script or parse errors were present; `git diff --check` also passed.

The real opening-route preview accepts and completes the two $48 neighborhood
jobs using city interactions and pointer taps, then buys the $100 laptop at the
Plaza kiosk using the initial $15: $11 remains, with no defeated bosses or debug
grants. Later preview sections grant test progress only to inspect every zone.
All 18 pickup interactions and authored task-stop collision points were checked.
Repair, signal and decryption puzzles were solved through actual pointer input.
Shop goal selection, rig purchase and explicit equipment switching were tapped.

Lifecycle checks cover atomic costs, retries, persistence, sleep, active-template
duplication, stale stage/puzzle callbacks, abandonment, old saves, unknown saved
source IDs, once-only companion modifiers, quoted heat, and reloading from real
combat victory/defeat panels before Continue. Independent review identified the
companion and combat-result issues; reproducing tests failed before their fixes.

`economy.json` records representative neutral-day pay and resource costs, with
an illustrative $4-per-energy food allowance (not a CPU restoration allowance).
Base job pay ranges by zone are $48-161, $70-235, $115-386, $240-576, $500-1200,
and $850-2040 before equipment, skills, companions, mastery and daily modifiers.
These are activity-budget checks, not measured phone session times or a full
campaign balance acceptance.

Screenshots include the first laptop purchase, offers, each puzzle family,
shopping comparisons, Loadout, journal and payout feedback. They were rendered
with Godot 4.7.2 Forward Mobile on Apple M2 Max and visually inspected.

Some runs still report ObjectDB/resource cleanup warnings at shutdown, including
the existing regression suites. Desktop rendering/pointer evidence does not
establish physical-phone touch, accessibility, performance, or full-campaign
playthrough acceptance.
