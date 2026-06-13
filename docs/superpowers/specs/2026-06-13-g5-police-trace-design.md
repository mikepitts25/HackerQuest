# G5 Police Escalation Design

Date: 2026-06-13
Scope: G5 police escalation for the 3D shell only.

## Goal

Turn Heat from a passive meter into an active threat loop. When the player blows
cover, they should get a short, readable chance to escape the current district
before the existing bust penalty lands.

## Player Rule

TRACE starts in two cases:

1. Heat reaches 100 from any source.
2. A high-risk terminal exploit fails. High-risk means the target's base Heat is
   at or above the implementation threshold, initially `20`.

Failed high-risk exploits set Heat to 100 immediately. Lower-risk failures keep
the current partial Heat gain behavior.

During TRACE the instruction is simple: leave the district before the countdown
expires. Any successful district transition counts as an escape, whether it
comes from an exit marker or the city map fast travel action. Escaping clears
TRACE and drops Heat from 100 to a dangerous-but-playable level, initially 75.
Letting the countdown expire calls the existing bust penalty: half cash, half
botnet, Heat reset to 50, daily exploits cleared, save locked in.

## State Model

`GameState` owns the trace state because terminal, HUD, tests, and the 3D shell
all need to observe it.

- Add trace state fields:
  - `trace_active: bool`
  - `trace_seconds_left: float`
  - `trace_reason: String`
- Add signals:
  - `trace_started(reason: String, seconds: float)`
  - `trace_cleared(escaped: bool)`
- Add helpers:
  - `start_trace(reason: String, seconds := trace_duration())`
  - `tick_trace(delta: float)`
  - `escape_trace()`
  - `trace_duration() -> float`
  - `high_risk_hack_heat_threshold() -> int`

`add_heat()` clamps Heat to 100 as it does today, but reaching 100 starts TRACE
instead of immediately calling `_bust()`. If TRACE is already active, repeated
Heat gain keeps Heat capped and does not restart the timer.

`tick_trace()` decrements only while TRACE is active. When it reaches zero, it
clears the trace state and calls `_bust()`.

`escape_trace()` clears the state, reduces Heat to the escape target, emits
stats changes, saves the game, and notifies the player that the trace was
shaken.

## Terminal Flow

The terminal remains the source of exploit outcomes.

On failed exploit:

- If `t.heat >= high_risk_hack_heat_threshold()`, set Heat to 100 and start
  TRACE with a reason such as `high_risk_fail`.
- Otherwise, use the existing `ceil(t.heat / 2)` Heat penalty.

The terminal should narrate high-risk failure as a trace event, not just an IDS
trip. The 3D shell should close the terminal when TRACE starts so the player can
move immediately.

Successes still add normal Heat. If that pushes Heat to 100, TRACE starts via
`add_heat()`.

## 3D Shell Flow

`scripts/iso/main_3d.gd` owns live countdown behavior and district escape.

- In `_process(delta)`, call `GameState.tick_trace(delta)`.
- On `GameState.trace_started`, close the terminal and shop, hide blocking HUD
  modals through a small HUD helper, shake or flash the camera, show the
  countdown banner, and rebuild the current district so tracker pressure is
  visible immediately.
- In `go_to()`, after a successful district change, call
  `GameState.escape_trace()` if TRACE was active before travel.
- On bust, preserve the existing camera jolt and bust dialog.

Escaping must only happen after a valid district change. Attempts to enter a
locked district do not clear TRACE.

## HUD And Feedback

HUD feedback should be persistent and compact:

- Add a `TRACE ACTIVE` countdown banner near the existing top HUD.
- Show seconds remaining and the command: `LEAVE DISTRICT`.
- Keep the existing Heat bar at 100 while TRACE is active.
- Use red/cyan police styling consistent with the current terminal UI.

The first implementation can keep this in `hud.gd` rather than adding a new
scene. It should avoid blocking movement.

## Beat Cops And Trackers

Beat cops are visual pressure in G5 v1. They do not arrest, collide, or fight
yet.

`district_3d.gd` should add police presence based on Heat:

- Heat above Clean: 1 patrol cop, plus the existing drone.
- High tiers: 2 or more patrol cops.
- Active TRACE: tracker units spawn with faster movement and more urgent
  labels/colors.

They can reuse the citizen character scene with a police tint and the existing
wanderer movement script. Tracker units should move faster than normal
wanderers. Combat with tracker cops is deferred to G6.

## Tuning

Initial values:

- High-risk failed-hack threshold: target Heat `>= 20`.
- TRACE countdown: 30 seconds.
- Escape Heat target: 75.

Possible modifiers after the base loop works:

- Stealth skill extends the timer by a few seconds.
- FIREWALL gear can add a small timer bonus.
- Very high Heat tiers can shorten the timer slightly.

These modifiers are optional for G5 v1; the fixed 30-second loop is enough to
prove the mechanic.

## Tests

Update `tests/smoke_test.gd` around the old instant bust expectation.

Required coverage:

- `GameState.add_heat(500)` starts TRACE and sets Heat to 100 instead of
  immediately busting.
- Advancing `tick_trace()` past the countdown applies the existing bust penalty
  and resets Heat to 50.
- `escape_trace()` clears TRACE and lowers Heat to the escape target.
- A failed high-risk exploit path starts TRACE and maxes Heat.
- Lower-risk failed exploit paths still apply partial Heat and do not always
  start TRACE.

The standard smoke command remains:

```sh
Godot --headless --path . --import
Godot --headless --path . res://tests/smoke_test.tscn
```

## Out Of Scope

- Turn-based combat.
- Cops physically catching the player before the timer expires.
- Fighting tracker cops.
- New district content.
- Full economy rebalance.

Those belong to G6 or later balancing passes.
