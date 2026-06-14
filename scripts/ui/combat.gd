extends Panel
## The turn-based combat screen (G6). Renders a CombatSession (pure logic in
## scripts/combat/combat_session.gd) and drives it from the action buttons:
## EXPLOIT / FIREWALL / PROGRAM / JACK OUT. Each press resolves the player's
## move and the enemy's reply synchronously, so it's always the player's turn
## again afterward (or the fight is over). On resolve it applies the enemy's
## loot (win) or a mild setback (loss) — losing a fight is never a full bust.
## Mirrors the terminal/shop panel pattern: a full-rect Panel, built in code,
## opened with the UI lock held.

const CombatSessionScript := preload("res://scripts/combat/combat_session.gd")

const C_GREEN := Color("7ee787")
const C_RED := Color("ff6b6b")
const C_CYAN := Color("7adfff")
const C_YEL := Color("ffd166")
const C_DIM := Color("5a7a5a")

var _session  # CombatSession (RefCounted)
var _mono: SystemFont
var _prev_player_hp := 0
var _prev_enemy_hp := 0

var _enemy_name: Label
var _enemy_bar: ProgressBar
var _enemy_bar_label: Label
var _player_bar: ProgressBar
var _player_bar_label: Label
var _log: RichTextLabel
var _actions: HBoxContainer


func _ready() -> void:
	theme = UITheme.theme()
	_build_ui()
	visible = false


# Begin a fight against the given GameData.ENEMIES id.
func start(enemy_id: String) -> void:
	_session = CombatSessionScript.new()
	_session.init(GameState.combat_stats(), enemy_id)
	_enemy_name.text = "▓ %s" % _session.enemy.name
	_prev_player_hp = _session.player_hp
	_prev_enemy_hp = _session.enemy_hp
	visible = true
	GameState.lock_ui()
	_render()
	_render_actions("choose")


func _input(event: InputEvent) -> void:
	# No escape hatch mid-fight — only the buttons (or a resolved CONTINUE) exit.
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()


# --- UI construction ----------------------------------------------------------

func _build_ui() -> void:
	_mono = SystemFont.new()
	_mono.font_names = PackedStringArray(["Menlo", "Consolas", "DejaVu Sans Mono", "Courier New"])

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("0a0d10")
	add_theme_stylebox_override("panel", bg)

	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 16)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := _label("// INTRUSION COUNTERMEASURE", 18, C_CYAN)
	vbox.add_child(title)

	# Enemy block — name + integrity bar.
	_enemy_name = _label("▓ ENEMY", 24, C_RED)
	vbox.add_child(_enemy_name)
	_enemy_bar = _make_bar(C_RED)
	vbox.add_child(_enemy_bar)
	_enemy_bar_label = _label("", 14, C_DIM)
	vbox.add_child(_enemy_bar_label)

	# Combat log — fills the middle.
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_override("normal_font", _mono)
	_log.add_theme_font_size_override("normal_font_size", 15)
	var logbg := StyleBoxFlat.new()
	logbg.bg_color = Color("06080a")
	logbg.set_border_width_all(1)
	logbg.border_color = Color(0.18, 0.28, 0.22)
	logbg.set_content_margin_all(10)
	_log.add_theme_stylebox_override("normal", logbg)
	vbox.add_child(_log)

	# Player block — "YOU" + integrity bar.
	vbox.add_child(_label("▓ YOU", 18, C_GREEN))
	_player_bar = _make_bar(C_GREEN)
	vbox.add_child(_player_bar)
	_player_bar_label = _label("", 14, C_DIM)
	vbox.add_child(_player_bar_label)

	# Action row — rebuilt per state by _render_actions.
	_actions = HBoxContainer.new()
	_actions.add_theme_constant_override("separation", 8)
	_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_actions)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _mono)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _make_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 18)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var bgs := StyleBoxFlat.new()
	bgs.bg_color = Color(0.1, 0.12, 0.14)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bgs)
	return bar


func _make_button(text: String, color: Color, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", _mono)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", color)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(action)
	return b


# --- rendering ----------------------------------------------------------------

func _render() -> void:
	var crit: bool = not _session.log.is_empty() and "CRIT" in _session.log[-1]
	# Enemy bar flashes bright on your hits; player bar flashes red on theirs.
	_drain_bar(_enemy_bar, _session.enemy_max, _session.enemy_hp, _prev_enemy_hp, Color(1.8, 1.8, 1.8), crit)
	_enemy_bar_label.text = "INTEGRITY %d / %d" % [_session.enemy_hp, _session.enemy_max]
	_drain_bar(_player_bar, _session.player_max, _session.player_hp, _prev_player_hp, Color(2.0, 0.7, 0.7), crit)
	_player_bar_label.text = "INTEGRITY %d / %d" % [_session.player_hp, _session.player_max]
	_prev_enemy_hp = _session.enemy_hp
	_prev_player_hp = _session.player_hp
	var lines: Array[String] = []
	for line in _session.log:
		lines.append(_colorize(line))
	_log.text = "\n".join(lines)


# Tween the bar to its new value; flash it if integrity dropped (brighter and
# longer on a crit) so hits read at a glance.
func _drain_bar(bar: ProgressBar, max_v: int, hp: int, prev: int, flash: Color, crit: bool) -> void:
	bar.max_value = max_v
	create_tween().tween_property(bar, "value", hp, 0.25).from(prev)
	if hp < prev:
		bar.modulate = flash * 1.3 if crit else flash
		var t := create_tween()
		t.tween_interval(0.12 if crit else 0.05)
		t.tween_property(bar, "modulate", Color.WHITE, 0.3)


# bbcode coloring for log lines so the fight reads: your hits green, theirs red,
# crits gold, the verdict in its outcome color.
func _colorize(line: String) -> String:
	var col := ""
	if "you win" in line or "spoils" in line:
		col = "7ee787"
	elif "you lose" in line or "JACK OUT failed" in line or "ripped" in line or "bled" in line:
		col = "ff6b6b"
	elif "CRIT" in line:
		col = "ffd166"
	elif line.begins_with("> you"):
		col = "7ee787"
	elif _session != null and line.begins_with("> %s" % _session.enemy.name):
		col = "ff9b9b"
	if col == "":
		return line
	return "[color=#%s]%s[/color]" % [col, line]


# state: "choose" (4 actions), "program" (item list), "done" (continue).
func _render_actions(state: String) -> void:
	for c in _actions.get_children():
		c.queue_free()
	match state:
		"choose":
			_actions.add_child(_make_button("EXPLOIT", C_GREEN, _on_exploit))
			_actions.add_child(_make_button("FIREWALL", C_CYAN, _on_firewall))
			_actions.add_child(_make_button("PROGRAM", C_YEL, _on_program))
			_actions.add_child(_make_button("JACK OUT", C_RED, _on_jack_out))
		"program":
			var progs: Array = CombatSessionScript.available_programs(GameState.inventory)
			for p in progs:
				var entry: Dictionary = p
				_actions.add_child(_make_button(
					entry.name.to_upper(), C_YEL,
					func() -> void: _on_run_program(entry)))
			_actions.add_child(_make_button("BACK", C_DIM, func() -> void: _render_actions("choose")))
		"done":
			_actions.add_child(_make_button("CONTINUE", C_GREEN, _on_continue))


# --- player actions -----------------------------------------------------------

func _on_exploit() -> void:
	Audio.sfx("hit")
	_session.player_exploit()
	_post_move()


func _on_firewall() -> void:
	_session.player_firewall()
	_post_move()


func _on_program() -> void:
	if CombatSessionScript.available_programs(GameState.inventory).is_empty():
		_session._log("> no combat programs loaded.")
		_render()
		return
	_render_actions("program")


func _on_run_program(entry: Dictionary) -> void:
	GameState.consume_item(entry.id)
	_session.player_program(entry.combat, entry.name)
	_post_move()


func _on_jack_out() -> void:
	_session.player_jack_out()
	_post_move()


# After any resolved move, refresh the view and branch on the outcome.
func _post_move() -> void:
	_render()
	if _session.outcome == _session.ONGOING:
		_render_actions("choose")
	else:
		Audio.sfx("win" if _session.outcome == _session.WIN else "lose")
		_apply_outcome()
		_render()  # loot/penalty lines were appended to the log
		_render_actions("done")


func _on_continue() -> void:
	# A trace fight resolves its trace state here, after the panel closes, so the
	# bust dialog (on a loss) doesn't stack on top of combat.
	var was_tracker: bool = _session.enemy_id == "tracker_unit"
	var won: bool = _session.outcome == _session.WIN
	visible = false
	GameState.unlock_ui()
	_session = null
	if was_tracker and GameState.trace_active:
		if won:
			GameState.defeat_trace()
		else:
			GameState.lose_trace_fight()


# --- outcome / rewards --------------------------------------------------------

func _apply_outcome() -> void:
	match _session.outcome:
		_session.WIN:
			_award_loot()
		_session.LOSE:
			if _session.enemy_id == "tracker_unit" and GameState.trace_active:
				_session._log("> they had you cold. the trace completes...")  # bust applied on CONTINUE
			else:
				_apply_loss()
		_session.FLED:
			_session._log("> you slipped the net. no reward, no scars.")


func _award_loot() -> void:
	var loot: Dictionary = _session.enemy.get("loot", {})
	var parts: Array[String] = []
	var cash_range: Array = loot.get("cash", [0, 0])
	var cash := randi_range(int(cash_range[0]), int(cash_range[1]))
	if cash > 0:
		GameState.add_cash(cash)
		parts.append("+$%d" % cash)
	var xp := int(loot.get("xp", 0))
	if xp > 0:
		GameState.add_xp(xp)
		parts.append("+%d XP" % xp)
	var rep := int(loot.get("rep", 0))
	if rep > 0:
		GameState.add_rep(rep)
		parts.append("+%d REP" % rep)
	if loot.has("gear") and not GameState.owned(loot.gear):
		GameState.owned_gear.append(loot.gear)
		parts.append("GEAR: %s" % GameData.GEAR[loot.gear].name)
	if loot.get("heat_clear", false):
		GameState.heat = 0
		GameState.stats_changed.emit()
		parts.append("heat cleared")
	if _session.enemy_id == "r10t":
		GameState.r10t_beaten = true
	GameState.save_game()
	_session._log("> spoils: %s" % (", ".join(parts) if not parts.is_empty() else "nothing of value"))


func _apply_loss() -> void:
	# A setback, not a bust: lose one stolen_data if you have it, else ~25% cash.
	if GameState.inventory.get("stolen_data", 0) > 0:
		GameState.consume_item("stolen_data")
		_session._log("> they ripped a stolen_data packet off your deck.")
	else:
		var lost := int(GameState.cash * 0.25)
		if lost > 0:
			GameState.add_cash(-lost)
			_session._log("> you bled $%d in the scramble out." % lost)
		else:
			_session._log("> nothing left to take. just your pride.")
	GameState.save_game()
