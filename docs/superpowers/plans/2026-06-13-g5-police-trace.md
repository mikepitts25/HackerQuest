# G5 Police Trace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build G5 police escalation: Heat 100 and failed high-risk hacks start a TRACE countdown that can be escaped by changing districts or ends in the existing bust penalty.

**Architecture:** `GameState` owns trace state, rules, and testable transitions. The terminal calls a new failed-hack Heat helper so high-risk failures max Heat and start TRACE. The 3D shell ticks the countdown, clears trace on successful district travel, closes blocking UI, and asks the current district to spawn police pressure.

**Tech Stack:** Godot 4.6, GDScript, existing `GameState` autoload, existing HUD/terminal/shop scenes, headless smoke test.

---

## File Structure

- Modify `tests/smoke_test.gd`: add failing trace/bust assertions and direct failed-hack Heat helper coverage.
- Modify `scripts/game_state.gd`: add transient trace state, signals, constants, helper methods, `add_heat()` behavior, and `new_game()`/`load_game()` cleanup.
- Modify `scripts/ui/terminal.gd`: call `GameState.apply_failed_hack_heat()` in failed exploit outcomes and narrate high-risk trace failures.
- Modify `scripts/ui/hud.gd`: add non-blocking TRACE countdown banner and `close_blocking_ui()`.
- Modify `scripts/iso/main_3d.gd`: tick trace, respond to trace start, escape on successful district transition, and refresh tracker pressure.
- Modify `scripts/iso/district_3d.gd`: spawn beat cops by Heat tier and tracker cops during TRACE.
- Modify `docs/TODO.md` and `docs/GAMEPLAY_ROADMAP.md` only after tests pass, marking G5 shipped.

## Task 1: RED Test For Trace State And Bust Timing

**Files:**
- Modify: `tests/smoke_test.gd`
- Modify next: `scripts/game_state.gd`

- [ ] **Step 1: Write the failing smoke-test assertions**

Replace the current heat bust block in `tests/smoke_test.gd`:

```gdscript
	# --- heat bust ---
	var bust_cash := GameState.cash
	GameState.add_heat(500)
	_check(GameState.heat == 50, "bust resets heat to 50")
	_check(GameState.cash == bust_cash / 2, "bust halves cash")
```

with:

```gdscript
	# --- trace / heat bust ---
	var has_trace_api := GameState.has_method("tick_trace") \
			and GameState.has_method("trace_duration") \
			and GameState.has_method("trace_escape_heat") \
			and GameState.has_method("escape_trace")
	_check(has_trace_api, "trace API exists")
	if has_trace_api:
		var bust_cash := GameState.cash
		var bust_botnet := GameState.botnet_size
		GameState.add_heat(500)
		_check(GameState.get("trace_active") == true, "heat 100 starts trace")
		_check(GameState.heat == 100, "trace holds heat at 100")
		GameState.tick_trace(GameState.trace_duration() + 0.1)
		_check(GameState.get("trace_active") == false, "trace ends after countdown")
		_check(GameState.heat == 50, "trace bust resets heat to 50")
		_check(GameState.cash == bust_cash / 2, "trace bust halves cash")
		_check(GameState.botnet_size == bust_botnet / 2, "trace bust halves botnet")

		GameState.heat = 0
		GameState.cash = 300
		GameState.botnet_size = 6
		GameState.add_heat(500)
		_check(GameState.get("trace_active") == true, "trace can restart after bust")
		_check(GameState.escape_trace(), "escape_trace returns true while active")
		_check(GameState.get("trace_active") == false, "escape clears trace")
		_check(GameState.heat == GameState.trace_escape_heat(), "escape lowers heat to escape target")
```

- [ ] **Step 2: Run the smoke test and verify RED**

Run:

```sh
Godot --headless --path . --import
Godot --headless --path . res://tests/smoke_test.tscn
```

Expected: the smoke test fails with `trace API exists` because `GameState.tick_trace()` is not implemented yet.

## Task 2: Implement Trace State In GameState

**Files:**
- Modify: `scripts/game_state.gd`
- Test: `tests/smoke_test.gd`

- [ ] **Step 1: Add trace signals and transient fields**

In `scripts/game_state.gd`, near the existing signal declarations, add:

```gdscript
signal trace_started(reason: String, seconds: float)
signal trace_cleared(escaped: bool)
```

Near the existing constants, add:

```gdscript
const TRACE_BASE_SECONDS := 30.0
const TRACE_ESCAPE_HEAT := 75
```

Near the existing top-level vars, add:

```gdscript
var trace_active := false
var trace_seconds_left := 0.0
var trace_reason := ""
```

- [ ] **Step 2: Add trace helper methods**

In `scripts/game_state.gd`, after `add_heat()` and before the heat-tier helpers, add:

```gdscript
func trace_duration() -> float:
	return TRACE_BASE_SECONDS


func trace_escape_heat() -> int:
	return TRACE_ESCAPE_HEAT


func start_trace(reason: String, seconds := TRACE_BASE_SECONDS) -> void:
	if trace_active:
		return
	trace_active = true
	trace_seconds_left = seconds
	trace_reason = reason
	notify("TRACE ACTIVE — leave the district!", COL_BAD)
	trace_started.emit(reason, seconds)
	stats_changed.emit()


func force_trace(reason: String) -> void:
	heat = 100
	stats_changed.emit()
	start_trace(reason)


func tick_trace(delta: float) -> void:
	if not trace_active:
		return
	trace_seconds_left = maxf(0.0, trace_seconds_left - delta)
	if trace_seconds_left > 0.0:
		return
	trace_active = false
	trace_seconds_left = 0.0
	trace_reason = ""
	trace_cleared.emit(false)
	_bust()


func escape_trace() -> bool:
	if not trace_active:
		return false
	trace_active = false
	trace_seconds_left = 0.0
	trace_reason = ""
	heat = mini(heat, trace_escape_heat())
	stats_changed.emit()
	notify("Trace shaken — heat still hot at %d." % heat, COL_WARN)
	trace_cleared.emit(true)
	save_game()
	return true


func _reset_trace() -> void:
	trace_active = false
	trace_seconds_left = 0.0
	trace_reason = ""
```

- [ ] **Step 3: Change `add_heat()` to start trace instead of instant bust**

Replace the end of `add_heat()`:

```gdscript
	heat = clampi(heat + amount, 0, 100)
	stats_changed.emit()
	if heat >= 100:
		_bust()
```

with:

```gdscript
	heat = clampi(heat + amount, 0, 100)
	stats_changed.emit()
	if heat >= 100:
		start_trace("heat_max")
```

- [ ] **Step 4: Reset transient trace state on new/load/bust**

In `new_game()`, after `gear = {}`, add:

```gdscript
	_reset_trace()
```

In `load_game()`, after the persisted-field loop and before `status_seen = ...`, add:

```gdscript
	_reset_trace()
```

At the start of `_bust()`, add:

```gdscript
	_reset_trace()
```

- [ ] **Step 5: Run the smoke test and verify GREEN for trace timing**

Run:

```sh
Godot --headless --path . --import
Godot --headless --path . res://tests/smoke_test.tscn
```

Expected: `SMOKE TEST PASSED`.

- [ ] **Step 6: Commit GameState trace state**

Run:

```sh
git add scripts/game_state.gd tests/smoke_test.gd
git commit -m "Add trace state machine"
```

## Task 3: RED/GREEN For Failed High-Risk Hack Heat

**Files:**
- Modify: `tests/smoke_test.gd`
- Modify: `scripts/ui/terminal.gd`
- Test indirectly through: `scripts/game_state.gd`

- [ ] **Step 1: Add failing failed-hack Heat assertions**

After the trace escape assertions in `tests/smoke_test.gd`, add:

```gdscript
	var has_failed_hack_api := GameState.has_method("apply_failed_hack_heat") \
			and GameState.has_method("high_risk_hack_heat_threshold")
	_check(has_failed_hack_api, "failed hack heat API exists")
	if has_failed_hack_api:
		GameState.heat = 0
		GameState._reset_trace()
		var low_fail_heat: int = GameState.apply_failed_hack_heat(10)
		_check(low_fail_heat == 5, "low-risk failed hack applies half heat")
		_check(GameState.get("trace_active") == false, "low-risk failed hack does not force trace")

		GameState.heat = 0
		GameState._reset_trace()
		var high_fail_heat: int = GameState.apply_failed_hack_heat(GameState.high_risk_hack_heat_threshold())
		_check(high_fail_heat == 100, "high-risk failed hack maxes heat")
		_check(GameState.get("trace_active") == true, "high-risk failed hack starts trace")
		GameState.escape_trace()
```

- [ ] **Step 2: Run the smoke test and verify RED**

Run:

```sh
Godot --headless --path . res://tests/smoke_test.tscn
```

Expected: the smoke test fails with `failed hack heat API exists`.

- [ ] **Step 3: Add high-risk failed-hack rules to `GameState`**

Near the trace constants in `scripts/game_state.gd`, add:

```gdscript
const HIGH_RISK_HACK_HEAT := 20
```

After `trace_escape_heat()`, add:

```gdscript
func high_risk_hack_heat_threshold() -> int:
	return HIGH_RISK_HACK_HEAT
```

After `force_trace()`, add:

```gdscript
func apply_failed_hack_heat(base_heat: int) -> int:
	if base_heat >= high_risk_hack_heat_threshold():
		force_trace("high_risk_fail")
		return heat
	var fail_heat := ceili(base_heat / 2.0)
	add_heat(fail_heat)
	return fail_heat
```

- [ ] **Step 4: Wire terminal failed exploits through the helper**

In `scripts/ui/terminal.gd`, replace the failed exploit branch:

```gdscript
	else:
		var fail_heat := ceili(t.heat / 2.0)
		GameState.add_heat(fail_heat)
		_say("ACCESS DENIED — IDS tripped  (+%d HEAT, -%d CPU, -%d Energy)" % [fail_heat, t.cpu_cost, EXPLOIT_ENERGY], C_RED)
```

with:

```gdscript
	else:
		var fail_heat := GameState.apply_failed_hack_heat(t.heat)
		if GameState.trace_active:
			_say("ACCESS DENIED — TRACE LOCKED  (HEAT MAX, -%d CPU, -%d Energy)" % [t.cpu_cost, EXPLOIT_ENERGY], C_RED)
			_say("RUN. leave the district before the countdown hits zero.", C_YEL)
		else:
			_say("ACCESS DENIED — IDS tripped  (+%d HEAT, -%d CPU, -%d Energy)" % [fail_heat, t.cpu_cost, EXPLOIT_ENERGY], C_RED)
```

- [ ] **Step 5: Run the smoke test and verify GREEN**

Run:

```sh
Godot --headless --path . res://tests/smoke_test.tscn
```

Expected: `SMOKE TEST PASSED`.

- [ ] **Step 6: Commit high-risk failed hack behavior**

Run:

```sh
git add scripts/ui/terminal.gd tests/smoke_test.gd
git commit -m "Trigger trace on failed high-risk hacks"
```

## Task 4: HUD Trace Banner And Blocking UI Helper

**Files:**
- Modify: `scripts/ui/hud.gd`
- Test: headless smoke test plus manual 3D play check

- [ ] **Step 1: Add HUD fields**

Near the existing `_heat_tween` field in `scripts/ui/hud.gd`, add:

```gdscript
var _trace_banner: PanelContainer
var _trace_label: Label
```

- [ ] **Step 2: Build the banner in `_ready()`**

In `_ready()`, after `_build_stats_bar()`, add:

```gdscript
	_build_trace_banner()
```

Add this function after `_build_stats_bar()`:

```gdscript
func _build_trace_banner() -> void:
	_trace_banner = PanelContainer.new()
	_trace_banner.visible = false
	_trace_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.02, 0.04, 0.94)
	style.border_color = Color(GameState.COL_BAD, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	_trace_banner.add_theme_stylebox_override("panel", style)
	add_child(_trace_banner)
	_trace_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_trace_banner.offset_left = 28
	_trace_banner.offset_right = -160
	_trace_banner.offset_top = 118
	_trace_banner.offset_bottom = 170

	_trace_label = Label.new()
	_trace_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_trace_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_trace_label.add_theme_font_override("font", UITheme.mono_font())
	_trace_label.add_theme_font_size_override("font_size", 17)
	_trace_label.add_theme_color_override("font_color", Color("ffccd2"))
	_trace_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_trace_label.add_theme_constant_override("outline_size", 5)
	_trace_banner.add_child(_trace_label)
```

- [ ] **Step 3: Add per-frame banner refresh and blocking UI close**

Add these functions near the modal helpers:

```gdscript
func _process(_delta: float) -> void:
	_refresh_trace_banner()


func _refresh_trace_banner() -> void:
	if _trace_banner == null:
		return
	_trace_banner.visible = GameState.trace_active
	if not GameState.trace_active:
		return
	_trace_label.text = "TRACE ACTIVE  %02dS  //  LEAVE DISTRICT" % ceili(GameState.trace_seconds_left)


func close_blocking_ui() -> void:
	if _dialog_panel.visible:
		_dialog_panel.visible = false
		_dialog_queue.clear()
		GameState.unlock_ui()
	for m in _modals:
		if not m.is_empty() and m.root.visible:
			_close_modal(m)
```

- [ ] **Step 4: Run the smoke test**

Run:

```sh
Godot --headless --path . res://tests/smoke_test.tscn
```

Expected: `SMOKE TEST PASSED`.

- [ ] **Step 5: Commit HUD trace UI**

Run:

```sh
git add scripts/ui/hud.gd
git commit -m "Add trace countdown HUD"
```

## Task 5: Wire 3D Countdown, Trace Start Response, And Escape

**Files:**
- Modify: `scripts/iso/main_3d.gd`
- Test: headless smoke test plus manual 3D play check

- [ ] **Step 1: Connect trace signal and tick countdown**

In `_ready()`, after `GameState.busted.connect(_on_busted)`, add:

```gdscript
	GameState.trace_started.connect(_on_trace_started)
```

Add `_process()` near `_ready()`:

```gdscript
func _process(delta: float) -> void:
	GameState.tick_trace(delta)
```

- [ ] **Step 2: Escape trace only after successful district travel**

At the start of `go_to()`, after the lock checks pass and before freeing the old district, add:

```gdscript
	var escaped_trace := GameState.trace_active and current_district_id != ""
```

At the end of `go_to()`, after `GameState.touch_vector = Vector2.ZERO`, add:

```gdscript
	if escaped_trace:
		GameState.escape_trace()
```

- [ ] **Step 3: Respond to trace start**

Add this method before `_on_busted()`:

```gdscript
func _on_trace_started(_reason: String, _seconds: float) -> void:
	_shake_camera()
	if terminal.visible:
		terminal.close_terminal()
	if shop.visible:
		shop.close_shop()
	if hud.has_method("close_blocking_ui"):
		hud.close_blocking_ui()
	_on_toast("TRACE ACTIVE — LEAVE THE DISTRICT", GameState.COL_BAD)
	var district := world_container.get_child(0) if world_container.get_child_count() > 0 else null
	if district != null and district.has_method("add_trace_pressure"):
		district.add_trace_pressure()
```

- [ ] **Step 4: Run the smoke test**

Run:

```sh
Godot --headless --path . res://tests/smoke_test.tscn
```

Expected: `SMOKE TEST PASSED`.

- [ ] **Step 5: Commit 3D trace runtime**

Run:

```sh
git add scripts/iso/main_3d.gd
git commit -m "Wire trace countdown in 3D shell"
```

## Task 6: Add Beat Cops And Tracker Pressure

**Files:**
- Modify: `scripts/iso/district_3d.gd`
- Test: headless smoke test plus visual 3D play check

- [ ] **Step 1: Call police presence during district build**

In `build(p_main)`, after `_add_heat_patrol()`, add:

```gdscript
	_add_police_presence()
```

- [ ] **Step 2: Add police spawning helpers**

After `_add_heat_patrol()`, add:

```gdscript
func add_trace_pressure() -> void:
	_clear_police_pressure()
	_add_police_presence()


func _clear_police_pressure() -> void:
	for n in get_tree().get_nodes_in_group("police_pressure"):
		if is_ancestor_of(n):
			n.queue_free()


func _add_police_presence() -> void:
	if GameState.heat_penalty() <= 0.0 and not GameState.trace_active:
		return
	var count := 1
	if GameState.heat >= 70:
		count = 2
	if GameState.trace_active:
		count = 4
	for i in count:
		_spawn_cop(i, GameState.trace_active)


func _spawn_cop(_index: int, tracker := false) -> void:
	var margin := 1.0
	var zone := wander_zone
	if zone.size == Vector2.ZERO:
		zone = Rect2(margin, margin, area_size.x - margin * 2.0, area_size.y - margin * 2.0)
	var ch: Node3D = load(CITIZEN_SCENE).instantiate()
	ch.set_script(WandererScript)
	ch.area_center = Vector3(zone.get_center().x, 0, zone.get_center().y)
	ch.area_size = zone.size
	ch.speed = 1.65 if tracker else 1.05
	ch.position = Vector3(
		randf_range(zone.position.x, zone.end.x), 0,
		randf_range(zone.position.y, zone.end.y)
	)
	ch.add_to_group("police_pressure")
	add_child(ch)
	_tint_body(ch, Color("2f5f86") if not tracker else Color("b91c2b"))
	var label := Label3D.new()
	label.text = "TRACE UNIT" if tracker else "BEAT COP"
	label.font_size = 28
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("ffccd2") if tracker else Color("7adfff")
	label.outline_size = 8
	label.position = Vector3(0, 1.75, 0)
	ch.add_child(label)
```

- [ ] **Step 3: Run the smoke test**

Run:

```sh
Godot --headless --path . res://tests/smoke_test.tscn
```

Expected: `SMOKE TEST PASSED`.

- [ ] **Step 4: Commit police pressure**

Run:

```sh
git add scripts/iso/district_3d.gd
git commit -m "Add police presence during heat and trace"
```

## Task 7: Final Verification And Roadmap Update

**Files:**
- Modify: `docs/TODO.md`
- Modify: `docs/GAMEPLAY_ROADMAP.md`
- Test: headless smoke test and manual 3D trace check

- [ ] **Step 1: Run final headless verification**

Run:

```sh
Godot --headless --path . --import
Godot --headless --path . res://tests/smoke_test.tscn
```

Expected: `SMOKE TEST PASSED`.

- [ ] **Step 2: Manual 3D verification in editor**

Open `scenes/iso/iso_main.tscn` in Godot 4.6, start the game, and verify:

```text
1. Raising Heat to 100 starts TRACE instead of instant bust.
2. The terminal/shop/modal closes when TRACE starts.
3. The TRACE banner counts down from 30.
4. Exiting to another unlocked district clears TRACE and leaves Heat at 75.
5. Waiting out the timer applies the existing bust dialog and penalty.
6. Beat cops appear above Clean, and tracker units appear during TRACE.
```

- [ ] **Step 3: Update `docs/GAMEPLAY_ROADMAP.md`**

Change the G5 heading from:

```markdown
## G5 — Police escalation: beat cops & the trace countdown
```

to:

```markdown
## G5 — Police escalation: beat cops & the trace countdown (SHIPPED)
```

Replace the first design paragraph under G5 with:

```markdown
Shipped: Heat 100 now starts a 30-second TRACE countdown instead of an instant
bust. Failed high-risk terminal hacks force Heat to 100 and start TRACE
immediately. Leaving the district through an exit or city-map travel shakes the
trace and leaves Heat at 75; waiting out the timer applies the existing bust
penalty. Districts now show beat cops under elevated Heat and faster tracker
units during active TRACE.
```

- [ ] **Step 4: Update `docs/TODO.md`**

Change the G5 bullet from:

```markdown
- [ ] **G5 — police escalation**: beat cops + a TRACE countdown when caught
      hacking — flee the district before the timer or get busted.
```

to:

```markdown
- [x] **G5 — police escalation** SHIPPED: beat cops + a 30-second TRACE
      countdown. Heat 100 and failed high-risk hacks start TRACE; leaving the
      district shakes it, while timeout applies the existing bust penalty.
```

- [ ] **Step 5: Commit docs**

Run:

```sh
git add docs/TODO.md docs/GAMEPLAY_ROADMAP.md
git commit -m "Mark police trace shipped"
```

## Self-Review Notes

- Spec coverage: Heat 100 trace, high-risk failed hack trace, countdown bust,
  district escape, HUD banner, UI close, beat cops, tracker units, and smoke
  tests all have tasks.
- Out of scope preserved: no combat, no physical cop collision, no new
  districts, no economy rebalance.
- Trace state is intentionally transient and not added to `PERSISTED`; loading a
  save clears it to avoid stale countdowns.
- The legacy 2D shell is not wired for live countdown ticking because G5 is
  scoped to the 3D shell. Headless tests cover trace rules through `GameState`.
