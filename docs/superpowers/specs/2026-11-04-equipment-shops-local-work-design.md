# Equipment, shops, and local work

Date: 2026-11-04
Status: Proposed for user approval; implementation has not started. Independent
builder review found no important unanswered planning questions.

## Intent and decisions

Make money and equipment feel earned: find worthwhile local work, complete it,
buy a useful upgrade, and use that upgrade to take on a harder challenge.

The user requested an equipment/shop revamp, meaningful rewards, better payouts
where needed, a good mixture of errands and hands-on tasks, and multiple task
pickup places within zones. They selected **local specialists** over a shared
citywide job network. All concrete counts, mechanics, and balance targets below
are proposed implementation choices, not additional user requirements.

## Approaches

1. Local specialists (selected): different contacts offer different work. This
   gives exploration and each district a purpose, but needs authored locations,
   offers, and routes.
2. Shared network: all terminals show the same citywide offers. Less authoring
   and easier access, but little reason to visit different sources. Not selected.
3. Payout-only tuning: cheapest, but preserves repetitive random routes and
   equipment overlap. Insufficient for the requested change.

## Scope and constraints

Use the existing Godot/GDScript game, modal theme, three gear slots, currency,
skills, daily cycle, district progression, and save system. Preserve character
data, cash, owned items, gear IDs, boss trophies, quest progress, companions,
existing active jobs, and unrelated checkout changes. No save reset.

This is one connected progression project covering jobs, their city pickup
points, equipment utility, shop/loadout presentation, and economy tuning.
No new currency, crafting tree, durability, recurring gear fees, multiplayer,
release upload, or wholesale city redesign. No new mandatory minigame in the
existing main-story hacking or boss path.

## Local specialists and content

Provide three distinct pickup points in each of the six main outdoor/social
zones. Use existing props and contacts where possible; add small service points
where necessary. Preserve each existing NPC service and conversation. A nearby
work interaction or an explicit Work option can expose jobs without replacing
their original function. Food vendors retain their food action.

| Zone | Specialist sources | Work identity |
| --- | --- | --- |
| Plaza | Community jobs board; coffee dispatch stand; repair kiosk | Local favors for cash, food deliveries, beginner repairs |
| Market | Pawn service desk; salvage dispatch beside Sparks; Vex's drop terminal | Drive services, parts recovery, discreet deliveries |
| Underpass | Ozark work station; courier dead drop; utility service box | Salvage orders, courier routes, signal work |
| Corp Row | Contractor terminal; cafe contact; service entrance console | Diagnostics, sanctioned security work, covert data jobs |
| Darknet Cafe | Counter dispatch; rig-hall terminal; alley broker | Diagnostics, decryption, high-risk retrievals |
| Drowned Quarter | Fathom recovery station; relay service terminal; salvage dead drop | Recovery, relay restoration, dangerous retrievals |

Each source has at least two distinct authored job templates. Initial scope is
18 sources and at least 36 templates, using reusable task mechanics. Across
each zone's six or more templates, include at least two simple errands, two
technical tasks, and one longer contract. A source may specialize strongly;
the zone as a whole provides the mixture. Early longer work is safe and local;
later contracts can include a normal combat encounter with declared risks.

Show sources on the map with names and task categories, and use readable world
labels and the existing contextual interaction control. Existing Plaza and
Corp boards become their respective specialist sources. Keep Darknet target
bounties accessible as their existing separate system.

## Offers, acceptance, and persistence

An offer identifies its source, activity type, district/route, number of stages,
total energy and CPU costs, exact base pay and any available bonus, requirements,
and heat/risk consequences. Never generate different terms after acceptance.
Create seeded daily offers from source ID, template ID, and game day. Snapshot
the quoted payout, costs, route, challenge seed, and equipment bonus on acceptance.
Changing gear or multipliers later cannot silently change accepted terms.

Each source offers its two or more templates once per in-game day. Accepted jobs
remain accepted over sleep and save/load; do not duplicate them on the next day.
Persist claimed/completed offer identities, and refresh availability on sleep.
Always provide two safe, computer-free Plaza jobs on a fresh day. R10T must not
remove these starter opportunities. Use up to three concurrent new jobs, while
preserving any larger legacy active list without dropping jobs.

The task journal shows source, current objective, stage progress, agreed pay,
remaining total costs, and district. Let the player track one job for HUD/map
guidance. Allow abandonment with no payment or reputation penalty; consumed
resources stay consumed and the offer remains used for that day. Cancellation
cannot refresh or reroll an offer. Pay once at the final stage, clearly showing
cash, XP, any bonus, and new affordability of a tracked shop purchase.

## Routes and job mechanics

Quick errands take one nearby action or a coherent pickup-and-delivery pair.
Technical jobs combine one brief puzzle with at most one nearby destination.
Long contracts have two or three deliberate stages. Keep ordinary jobs in their
source district; explicitly label cross-zone courier/contract routes, using only
already accessible zones. Stops use authored reachable locations matched to the
job fiction, not arbitrary coordinates across every unlocked district.

Reuse three touch-friendly technical challenge families:

- Repair: select and replace faulty components using visible diagnostic clues.
- Signal trace: choose relay connections that match the displayed signal rules.
- Decrypt: solve a short symbol/order pattern from an explicit clue.

Each challenge uses a small number of large tap targets and readable instructions.
No precision timing or required typing. Explain correctness through visible
clues rather than guessing. Wrong submissions give specific feedback; basic
work can be retried without extra resource charges. Optional advanced contracts
may declare a limited-attempt quality bonus, while preserving the stated base
pay for eventual successful completion. Do not add an invisible failure roll
after a player correctly solves a technical task.

Spend a stage's resources only when the player explicitly starts it, after
atomically validating all costs. Persist the started stage and challenge state;
closing/reopening or reloading resumes it without another charge or new puzzle.
Insufficient energy/CPU spends neither. Closing a puzzle restores normal UI
control and leaves the job resumable. A combat loss/flee leaves its stage
incomplete and uses existing encounter loss rules, disclosed in the offer;
retries require a new explicitly started attempt with its declared cost.

Legacy active jobs retain their saved terms and current completion behavior
until completed or abandoned. Add defaults during normalization; never reroll
or reinterpret a legacy job as a new offer.

## Equipment and earning utility

Keep rigs, firewalls, and implants as the three functional slots. Keep existing
combat effects: attack, defense, integrity, and critical chance. Add modest,
explicit work utility to purchaseable gear, while retaining trophy rigs' target
affinities. Purchased rigs become work/offense alternatives, not weaker copies
of free story drops.

- Shop rigs: retain attack and provide increasing technical-job bonuses, proposed
  at 10/15/20 percent across the three existing tiers.
- Firewalls: retain defense and reduce declared heat on risky technical work,
  proposed at 1/2/3 points per completed job, floored at zero.
- Implants: retain integrity/crit and provide 1/2/3 optional clue reveals per
  technical challenge. Every puzzle remains solvable without an implant.
- Boss rigs: retain earned origin, attack progression, and district-target
  affinity. These must be earned, never purchased for their data-table $0 price.

Show which of these effects applies on the offer before acceptance. Cap and
apply bonuses in one shared calculation so stacking with Hustle, companions,
daily modifiers, and mastery is consistent and does not double-pay. Snapshot
work bonuses on acceptance and clue allowances at stage start. Exact balance
constants may be adjusted after simulations; document the final values.

Do not automatically replace equipped gear on purchase or trophy award. Show
an Equip action with a comparison; allow all owned gear to be equipped directly
from Loadout. Preserve existing quest/endgame ownership and trophy requirements.
Combat previews/help must explain why a loadout matters without exposing hidden
story events or promising a guaranteed win.

## Shops and purchase goals

Keep the Market pawn shop as the central equipment store. Specialist pickup
points offer work; they do not each require a duplicate store interface.

Group the store into hardware upgrades, rigs, firewalls, implants, supplies, and
style. Keep owned entries understandable and show trophy gear separately with
earned/where-to-earn information rather than a price or Buy button. Enforce that
rule in the state purchase API as well as the UI.

Gear cards show equipped item, candidate stats, exact stat/utility differences,
price, unlock condition, and remaining cash needed. Hardware cards describe the
concrete capacity or activity unlocked. Do not use a universal 'better' badge
for items that trade attack for work income or target affinity.

Allow one saved purchase goal. Show savings and shortfall in the shop and a
compact journal/HUD hint when no tracked task takes priority. Announce reaching
its price once, then offer directions to the shop. Purchase confirmation shows
the acquired benefit and the optional equip action. Buying keeps existing save
and quest checks intact; all mutations and persistence go through GameState.

## Economy targets

Balance around completed activities and resources, with elapsed playtime checked
in a real playthrough rather than invented from unit tests.

- New player begins with the existing $15. Keep the laptop at $100. Provide at
  least two guaranteed safe starter tasks paying a proposed $45-50 each with
  combined cost no more than the starting ten energy and no CPU requirement.
  The laptop is reachable in two or three jobs without relying on scrap luck,
  puzzle bonuses, or random reputation gains.
- A meaningful early gear purchase should take approximately two to four
  appropriate activities after the laptop; buying it should improve the next
  relevant work/fight rather than merely change a number in the bag.
- Midgame purchases target three to five activities at the relevant tier;
  late expensive upgrades target several larger contracts/encounters. Tune
  equipment prices and job/encounter pay together, including food and supplies.
- Longer routes and declared danger must improve net returns over safe local
  errands. Increase low encounter rewards where expected cost/time warrants it;
  avoid a blanket multiplier on already-large late target and bounty payouts.
- Safe daily work stays a reliable recovery route after a setback. Completion
  yields modest predictable XP; use declared guaranteed reputation on selected
  milestone contracts, preserving existing other reputation paths.
- No reward for repeated UI presses, reloads, duplicated callbacks, or retries.
  Do not add a new sell-back system or sleep-only profit loop in this scope.

## Builder discretion

The builder chooses exact prop placement, character copy, puzzle variants,
authored route coordinates, internal file organization, and tuned numeric values
within the above intent. Reuse current UI styling and stock geometry. Keep first
implementation content compact but satisfy all zone/source and activity counts.
New persistence fields should be additive and default safely on old saves.

## Acceptance and verification

Use an isolated project/user-data profile for every automated state-mutating test.
Never reset or overwrite the user's real save. Required evidence:

1. Source/template coverage: all six zones have three reachable distinct pickup
   points, correctly filtered offers, intended variety, and discoverable markers.
2. A deterministic starter route earns the laptop in two or three jobs within
   starting resources. Simulations cover safe/technical/contract earnings at
   early, middle, and late tiers, including modifiers and consumable costs.
3. Equipment effects change actual work/combat calculations. Shop comparisons
   match equipped state; trophies cannot be bought; buying/earning never silently
   swaps the selected loadout; Loadout permits owned-item switching.
4. Offers, stages, resource charges, clue counts, rewards, purchase goals, and
   used-offer records survive save/load and sleep correctly. Validate legacy
   saves/jobs, duplicate actions, abandonment, insufficient resources, and
   interrupted challenges/combat.
5. All three puzzle families can be completed through real UI pointer input;
   retry/close/resume and map/journal tracking work without locking the city.
   Render and inspect representative phone-size shop, offer, puzzle, and reward
   views, with readable wrapping and adequate tap targets.
6. Existing smoke, street-cache, modern UI, and renderer checks continue to pass.
   Preserve main-story/boss/companion and existing city services. Run scoped diff
   checks and review the final patch against unrelated dirty work.

Automated and desktop-render evidence does not establish physical-phone touch,
accessibility, performance, or final perceptual/economy acceptance. Report those
limits explicitly in the implementation handoff.
