# Local Specialist Work Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Connect local work, useful equipment, and worthwhile purchases across six zones.

**Architecture:** A static WorkCatalog authors sources, routes and tasks. A WorkSystem service operates on GameState's additive persisted fields; the old job path remains for legacy jobs. Shared HUD modals handle offers and challenges, and district construction creates specialist interactions from the catalog.

**Tech Stack:** Godot 4.7, GDScript, existing modal UI and isolated QA scripts.

**Spec:** docs/superpowers/specs/2026-11-04-equipment-shops-local-work-design.md

## Global Constraints

- Preserve current saves, active legacy jobs, gear IDs, boss/story progression and unrelated checkout edits.
- Three sources per six main zones, at least two templates each; all three puzzle families and safe errands.
- No new currency, mandatory story puzzles, durability or recurring equipment costs.
- Snapshot accepted terms; atomic costs; once-only rewards; no random failure after solving a puzzle.
- Run state-mutating checks only in an isolated QA profile.

## Review Focus

- Reload mid-puzzle must preserve payment, layout, attempts and clues.
- Sleep with active work must not duplicate the same template or reroll its accepted terms.
- A queued duplicate callback must not complete the next stage or pay twice.
- Legacy saves and unknown IDs must not break new job or gear screens.
- Modal exit, combat interruption and insufficient resources must release UI and preserve work.

### Task 1: Catalog and work lifecycle

**Files:** Create scripts/work_catalog.gd, scripts/work_system.gd, tests/local_work_test.gd, tools/check_local_work.sh; modify scripts/game_state.gd.
**Interfaces:** WorkCatalog.sources()/templates()/challenge(kind,seed); WorkSystem.offers(state,source), accept(state,offer_id), start(state,uid,expected_step), submit(state,uid,expected_step,choice), hint(state,uid), abandon(state,uid), finish_combat(state,enemy,outcome). GameState persists work_claims, tracked_job, purchase_goal, goal_announced plus active_jobs.

- [x] Add lifecycle tests for source counts, deterministic terms, starter affordability, stage costs, insufficient resources, solve/retry/resume, daily claims, legacy normalization, duplicate actions, equipment bonuses and persistence. Run isolated runner; expect failure before service exists.
- [x] Author 18 sources / 36 templates with reachable stops, three deterministic clue-based puzzle families, one safe contract per early zone, combat contracts in later zones.
- [x] Implement new lifecycle with additive save fields and old complete_job routing preserved. Freeze accepted terms and stage tokens, charge atomically, persist challenge state, settle final payout through one path with cash modifiers applied once.
- [x] Run tests; expect LOCAL WORK TEST PASSED. Record results in progress ledger.

### Task 2: City pickup points, journal and challenge UI

**Files:** Modify scripts/iso/district_3d.gd, scripts/iso/main_3d.gd, scripts/ui/hud.gd; create scripts/ui/work_ui.gd, tests/local_work_preview.gd.
**Interfaces:** WorkUI.show_source(source), show_stage(uid), journal(modal), map_sources(modal); uses Task 1 service and existing HUD modal methods. Main routes world task markers to WorkUI and combat outcomes to WorkSystem.

- [x] Add UI assertions for source counts, pointer-driven offer acceptance and puzzles, tracking, abandonment, UI lock recovery, routes across all zones. Run before integration; expect failure.
- [x] Add source models/labels and interactions in shared district construction; reuse existing boards for Plaza/Corp sources without duplicate interaction volumes. Preserve all NPC/food services.
- [x] Build offers, journal and three challenge views with large wrapping tap targets, resource terms, feedback, hints, track/abandon and resume behavior. Show specialist directory in map.
- [x] Hook task markers and combat stages, retain legacy markers. Run headless tests and real-render preview.

### Task 3: Equipment, shops and purchase goals

**Files:** Modify scripts/game_state.gd, scripts/ui/shop.gd, scripts/ui/hud.gd, scripts/game_data.gd, scripts/ui/combat.gd; add assertions to tests/local_work_test.gd and tests/local_work_preview.gd.
**Interfaces:** WorkSystem.gear_utility(state), goal_info(state), set_goal(state,id); GameState buy_gear blocks trophies and purchase no longer auto-equips; grant_gear defaults to no auto-equip. Loadout explicitly equips owned gear.

- [x] Write tests for trophy rejection, no silent equip, comparisons, goal persistence and bonus/cost calculations. Observe failures.
- [x] Implement gear utility 10/15/20% work pay, 1/2/3 heat reduction, 1/2/3 clue allowances. Tune early/mid/late work pay and weak encounter payouts using activity-cost comparisons.
- [x] Split shop gear by slot/trophy, show equipped comparisons and work benefits, add saved goal actions and affordability notice; provide owned item switching in Loadout.
- [x] Run isolated suites plus preview, inspect captured screenshots and economy report.

### Task 4: Regression and independent review

**Files:** docs/qa/local-work/*, docs/superpowers/plans/2026-11-04-local-specialist-work-progress.md.

- [x] Run tools/check_fun_pass.sh --preview and tools/check_local_work.sh --preview. Require passing suites, no script errors, inspect representative rendered views.
- [x] Fresh reviewer reads full change against baseline /tmp/hackerquest-local-work-baseline and approved spec. Resolve important findings with reproducing tests and rerun suites.
- [x] Report implementation, measured balance, verification and physical-phone limits. Leave unrelated existing edits untouched; production commits deferred because overlapping files contain pre-existing work.
