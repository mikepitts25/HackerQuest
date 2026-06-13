extends Control
## Mobile-first HUD. Top: compact stats panel (day/cash/level + resource bars
## + current objective). Bottom: virtual joystick and interact button.
## Modals: dialog box, job board, skills, backpack — all built from one
## shared modal helper so they look identical. Action feedback floats above
## the player's head (see player.gd), not here.

var _cash_label: Label
var _status_label: Label
var _meta_label: Label   # DAY · LVL · REP · BOT, one quiet line
var _quest_label: Label
var _skills_btn: Button
var _wifi_btn: Button
var _xp_bar: ProgressBar  # thin ambient strip, no text
var _bars := {}  # key -> {"bar": ProgressBar, "label": Label}

var _interact_btn: Button

var _dialog_panel: PanelContainer
var _dialog_label: Label
var _dialog_queue: Array = []
var _type_tween: Tween
var _heat_tween: Tween
var _trace_banner: PanelContainer
var _trace_label: Label

var _jobs_modal := {}
var _skills_modal := {}
var _bag_modal := {}
var _wifi_modal := {}
var _apt_modal := {}
var _furnish_modal := {}
var _contracts_modal := {}
var _map_modal := {}
var _phone_modal := {}
var _favors_modal := {}
var _goods_modal := {}
var _quests_modal := {}
var _loadout_modal := {}
var _city_map: Control
var _modals: Array = []  # every modal, for one-at-a-time enforcement


func _ready() -> void:
	theme = UITheme.theme()
	_add_scanlines()
	_build_stats_bar()
	_build_trace_banner()
	_build_controls()
	_build_dialog()
	_jobs_modal = _make_modal("JOB BOARD")
	_skills_modal = _make_modal("SKILLS")
	_bag_modal = _make_modal("BACKPACK")
	_wifi_modal = _make_modal("WIFI SNIFFER")
	_apt_modal = _make_modal("VACANCIES")
	_furnish_modal = _make_modal("FURNISH")
	_contracts_modal = _make_modal("CONTRACTS")
	_favors_modal = _make_modal("COMMUNITY BOARD")
	_goods_modal = _make_modal("GOODS EXCHANGE")
	_quests_modal = _make_modal("QUEST LOG")
	_loadout_modal = _make_modal("LOADOUT")
	_phone_modal = _make_modal("BURNER PHONE")
	_map_modal = _make_modal("CITY GRID")
	_city_map = preload("res://scripts/ui/city_map.gd").new()
	_city_map.custom_minimum_size = Vector2(560, 540)
	_city_map.travel_requested.connect(_on_map_travel)
	_map_modal.rows.add_child(_city_map)
	_modals = [_jobs_modal, _skills_modal, _bag_modal, _wifi_modal, _apt_modal, _furnish_modal, _contracts_modal, _favors_modal, _goods_modal, _quests_modal, _loadout_modal, _phone_modal, _map_modal]
	GameState.stats_changed.connect(_refresh_stats)
	GameState.stats_changed.connect(_refresh_quest)  # active gigs surface here too
	GameState.prompt_changed.connect(_on_prompt_changed)
	GameState.quest_changed.connect(_refresh_quest)
	_refresh_stats()
	_refresh_quest()


# A whisper of CRT: 2px scanlines at very low alpha across the whole screen.
# Sits at index 0 so all real UI draws above it.
func _add_scanlines() -> void:
	var lines := ColorRect.new()
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
void fragment() {
	float l = step(mod(FRAGCOORD.y, 4.0), 1.5);
	COLOR = vec4(vec3(0.0), l * 0.06);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	lines.material = mat
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lines)
	lines.set_anchors_preset(Control.PRESET_FULL_RECT)


# --- Stats bar ---------------------------------------------------------------

func _build_stats_bar() -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(UITheme.INK, 0.92)
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_bottom = 1
	style.border_color = Color(UITheme.CYAN, 0.4)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	# Explicit anchors+offsets: with the slimmer content the preset alone
	# lets the container shrink-wrap instead of spanning the screen.
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 0.0
	panel.offset_right = 0.0
	panel.offset_top = 0.0

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 7)
	panel.add_child(vbox)

	# Row 1: who you are (left) · your money (right). Nothing else.
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 14)
	vbox.add_child(row1)
	_status_label = _text_label(row1, 18, Color("7adfff"))
	row1.add_child(_spacer())
	_cash_label = _text_label(row1, 22, GameState.COL_GOOD)

	# Row 2: one quiet meta line — DAY · LVL · REP · BOT.
	_meta_label = Label.new()
	_meta_label.add_theme_font_size_override("font_size", 11)
	_meta_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	vbox.add_child(_meta_label)

	# XP as a thin ambient strip — progress you feel, not a labeled widget.
	_xp_bar = ProgressBar.new()
	_xp_bar.show_percentage = false
	_xp_bar.custom_minimum_size = Vector2(0, 4)
	var xbg := StyleBoxFlat.new()
	xbg.bg_color = Color(0, 0, 0, 0.4)
	var xfg := StyleBoxFlat.new()
	xfg.bg_color = Color("9d6bff")
	_xp_bar.add_theme_stylebox_override("background", xbg)
	_xp_bar.add_theme_stylebox_override("fill", xfg)
	vbox.add_child(_xp_bar)

	# Row 3: vitals, full width, equal thirds.
	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", 8)
	vbox.add_child(row3)
	row3.add_child(_make_bar("energy", Color("e8a93d"), 0))
	row3.add_child(_make_bar("cpu", Color("35b6e8"), 0))
	row3.add_child(_make_bar("heat", Color("ff4f66"), 0))

	# Row 4: current objective.
	_quest_label = Label.new()
	_quest_label.add_theme_font_size_override("font_size", 13)
	_quest_label.add_theme_color_override("font_color", Color("7adfff"))
	_quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_quest_label)

	# Action rail: a vertical stack hugging the right edge, clear of the
	# info bar — actions live apart from readouts.
	var rail := VBoxContainer.new()
	rail.add_theme_constant_override("separation", 8)
	add_child(rail)
	rail.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	rail.offset_left = -132
	rail.offset_right = -10
	rail.offset_top = 158
	_skills_btn = _chip_button(rail, "SKILLS", func() -> void: _open_skills())
	_chip_button(rail, "QUESTS", func() -> void: show_quests())
	_chip_button(rail, "GEAR", func() -> void: show_loadout())
	_chip_button(rail, "BAG", func() -> void: _open_bag())
	_chip_button(rail, "MAP", func() -> void: _open_map())
	_chip_button(rail, "PHONE", func() -> void: _open_phone())
	_wifi_btn = _chip_button(rail, "📶 WIFI", func() -> void: _open_wifi())
	_wifi_btn.visible = false


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
	_trace_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_trace_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_trace_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_trace_label.add_theme_font_override("font", UITheme.mono_font())
	_trace_label.add_theme_font_size_override("font_size", 17)
	_trace_label.add_theme_color_override("font_color", Color("ffccd2"))
	_trace_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_trace_label.add_theme_constant_override("outline_size", 5)
	_trace_banner.add_child(_trace_label)


func _refresh_stats() -> void:
	var gs := GameState
	_status_label.text = gs.status_title()
	_status_label.add_theme_color_override("font_color", Color(gs.status_color()))
	_cash_label.text = "$%d" % gs.cash
	var nxt := gs.next_status()
	var rep_text := ("REP %d max" % gs.reputation) if nxt.is_empty() \
			else ("REP %d→%d %s" % [gs.reputation, nxt.need, nxt.title])
	_meta_label.text = "%s · DAY %d · LVL %d · %s · BOT %d" % [gs.handle, gs.day, gs.level, rep_text, gs.botnet_size]
	_skills_btn.text = "SKILLS +%d" % gs.skill_points if gs.skill_points > 0 else "SKILLS"
	_wifi_btn.visible = gs.has_wifi_adapter()

	_xp_bar.max_value = gs.xp_needed()
	_xp_bar.value = gs.xp
	var energy_text := "E %d/%d" % [gs.energy, gs.max_energy]
	if gs.is_fatigued():
		energy_text += "  TIRED"
	_set_bar("energy", gs.energy, gs.max_energy, energy_text)
	_bars["energy"].label.add_theme_color_override("font_color",
		Color("ff6b6b") if gs.is_fatigued() else Color(1, 1, 1, 0.95))
	if gs.has_computer:
		var cpu_text := "CPU %d/%d" % [gs.cpu, gs.max_cpu]
		if gs.wired_cpu > 0:
			cpu_text += " ⚡"
		_set_bar("cpu", gs.cpu, gs.max_cpu, cpu_text)
	else:
		_set_bar("cpu", 0, 1, "CPU —")
	_set_bar("heat", gs.heat, 100, "HEAT %d · %s" % [gs.heat, gs.heat_tier_name()])
	_bars["heat"].label.add_theme_color_override("font_color",
		Color(gs.heat_tier_color()) if gs.heat_penalty() > 0.0 else Color(1, 1, 1, 0.95))
	_set_heat_pulse(gs.heat_penalty() > 0.0)


# Above Clean, the heat bar breathes — you should feel hunted at a glance.
func _set_heat_pulse(on: bool) -> void:
	var bar: ProgressBar = _bars["heat"].bar
	if on and (_heat_tween == null or not _heat_tween.is_valid()):
		_heat_tween = bar.create_tween().set_loops()
		_heat_tween.tween_property(bar, "modulate", Color(1, 0.5, 0.5), 0.45)
		_heat_tween.tween_property(bar, "modulate", Color.WHITE, 0.45)
	elif not on and _heat_tween and _heat_tween.is_valid():
		_heat_tween.kill()
		_heat_tween = null
		bar.modulate = Color.WHITE


func _refresh_quest() -> void:
	# An accepted gig is your most immediate objective — surface where to go.
	if not GameState.active_jobs.is_empty():
		var jid: String = GameState.active_jobs[0]
		var job: Dictionary = GameData.JOBS[jid]
		var more := ""
		if GameState.active_jobs.size() > 1:
			more = "  (+%d more)" % (GameState.active_jobs.size() - 1)
		_quest_label.text = "◆ GIG: %s → %s%s" % [job.name, GameData.DISTRICTS[job.district]["name"], more]
		return
	_quest_label.text = "▸  " + GameState.current_quest_text()


func _make_bar(key: String, fill_color: Color, width: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(width, 22)
	if width == 0:  # flexible: share the row equally with siblings
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.4)
	bg.set_corner_radius_all(2)
	bg.set_border_width_all(1)
	bg.border_color = Color(fill_color, 0.45)
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color(fill_color, 0.85)
	fg.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)

	var overlay := Label.new()
	overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay.add_theme_font_size_override("font_size", 11)
	overlay.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	overlay.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	overlay.add_theme_constant_override("outline_size", 4)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(overlay)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	_bars[key] = {"bar": bar, "label": overlay}
	return bar


func _set_bar(key: String, value: float, max_value: float, text: String) -> void:
	var b: Dictionary = _bars[key]
	b.bar.max_value = max_value
	b.bar.value = value
	b.label.text = text


func _text_label(parent: Control, size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _chip_button(parent: Control, text: String, on_press: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 40)
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(on_press)
	parent.add_child(btn)
	return btn


func _spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


# --- Touch controls ----------------------------------------------------------

func _build_controls() -> void:
	var joystick := VirtualJoystick.new()
	add_child(joystick)
	joystick.anchor_top = 1.0
	joystick.anchor_bottom = 1.0
	joystick.offset_left = 30
	joystick.offset_top = -290
	joystick.offset_right = 270
	joystick.offset_bottom = -50

	_interact_btn = Button.new()
	_interact_btn.text = "…"
	_interact_btn.disabled = true
	_interact_btn.clip_text = true
	_interact_btn.focus_mode = Control.FOCUS_NONE
	_interact_btn.add_theme_font_size_override("font_size", 18)
	# The world-verb button speaks cyan, not green — it's "what's in front of
	# you", not a menu action.
	var ib := StyleBoxFlat.new()
	ib.bg_color = Color(UITheme.INK, 0.85)
	ib.set_corner_radius_all(4)
	ib.set_border_width_all(1)
	ib.border_color = Color(UITheme.CYAN, 0.6)
	ib.set_content_margin_all(10)
	var ib_pressed := ib.duplicate()
	ib_pressed.bg_color = Color(UITheme.CYAN, 0.25)
	ib_pressed.border_color = UITheme.CYAN
	var ib_off := ib.duplicate()
	ib_off.border_color = Color(UITheme.CYAN, 0.12)
	_interact_btn.add_theme_stylebox_override("normal", ib)
	_interact_btn.add_theme_stylebox_override("hover", ib)
	_interact_btn.add_theme_stylebox_override("pressed", ib_pressed)
	_interact_btn.add_theme_stylebox_override("disabled", ib_off)
	_interact_btn.add_theme_color_override("font_color", UITheme.CYAN)
	_interact_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	_interact_btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.45, 0.55, 0.6))
	add_child(_interact_btn)
	_interact_btn.anchor_left = 1.0
	_interact_btn.anchor_right = 1.0
	_interact_btn.anchor_top = 1.0
	_interact_btn.anchor_bottom = 1.0
	_interact_btn.offset_left = -210
	_interact_btn.offset_top = -230
	_interact_btn.offset_right = -40
	_interact_btn.offset_bottom = -70
	_interact_btn.pressed.connect(func() -> void: GameState.interact_requested.emit())


func _on_prompt_changed(text: String) -> void:
	_interact_btn.text = text if text != "" else "…"
	_interact_btn.disabled = text == ""


func _process(_delta: float) -> void:
	_refresh_trace_banner()


func _refresh_trace_banner() -> void:
	if _trace_banner == null:
		return
	_trace_banner.visible = GameState.trace_active
	if not GameState.trace_active:
		return
	_trace_label.text = "TRACE ACTIVE  %02dS  //  LEAVE DISTRICT" % ceili(GameState.trace_seconds_left)


# --- Dialog box ----------------------------------------------------------------

func _build_dialog() -> void:
	_dialog_panel = PanelContainer.new()
	_dialog_panel.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(UITheme.INK, 0.97)
	style.set_content_margin_all(16)
	style.content_margin_left = 20
	style.set_corner_radius_all(4)
	style.set_border_width_all(1)
	style.border_color = Color(UITheme.GREEN, 0.45)
	style.border_width_left = 4
	_dialog_panel.add_theme_stylebox_override("panel", style)
	add_child(_dialog_panel)
	_dialog_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_dialog_panel.offset_left = 20
	_dialog_panel.offset_right = -20
	_dialog_panel.offset_top = -540
	_dialog_panel.offset_bottom = -310

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_dialog_panel.add_child(vbox)

	_dialog_label = Label.new()
	_dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_label.add_theme_font_size_override("font_size", 18)
	_dialog_label.add_theme_color_override("font_color", Color("c9f2d4"))
	_dialog_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_dialog_label)

	var ok := Button.new()
	ok.text = "OK"
	ok.focus_mode = Control.FOCUS_NONE
	ok.custom_minimum_size = Vector2(0, 52)
	ok.pressed.connect(_on_dialog_ok)
	vbox.add_child(ok)


func show_dialog(lines: Array) -> void:
	for line in lines:
		_dialog_queue.append(line)
	if not _dialog_panel.visible:
		_dialog_panel.visible = true
		GameState.lock_ui()
		_show_dialog_line(_dialog_queue.pop_front())


# Terminal typewriter: lines type themselves out. Tapping OK mid-type
# completes the line; tapping on a finished line advances.
func _show_dialog_line(line: String) -> void:
	_dialog_label.text = "> " + line
	_dialog_label.visible_ratio = 0.0
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
	_type_tween = _dialog_label.create_tween()
	_type_tween.tween_property(_dialog_label, "visible_ratio", 1.0,
			maxf(0.25, line.length() * 0.012))


func _on_dialog_ok() -> void:
	if _dialog_label.visible_ratio < 1.0:
		if _type_tween and _type_tween.is_valid():
			_type_tween.kill()
		_dialog_label.visible_ratio = 1.0
		return
	if _dialog_queue.is_empty():
		_dialog_panel.visible = false
		GameState.unlock_ui()
	else:
		_show_dialog_line(_dialog_queue.pop_front())


# --- Shared modal helper -------------------------------------------------------

func _make_modal(title: String) -> Dictionary:
	var root := Panel.new()
	root.visible = false
	var dim := StyleBoxFlat.new()
	dim.bg_color = Color(0, 0, 0, 0.65)
	root.add_theme_stylebox_override("panel", dim)
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# CenterContainer (with side margins) reliably centers the panel even though
	# its size is only known after rows are added.
	var center := MarginContainer.new()
	center.add_theme_constant_override("margin_left", 24)
	center.add_theme_constant_override("margin_right", 24)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE  # taps fall through to the dim
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(holder)

	var inner := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(UITheme.INK, 0.97)
	style.set_content_margin_all(18)
	style.set_corner_radius_all(4)
	style.set_border_width_all(1)
	style.border_color = Color(UITheme.GREEN, 0.45)
	style.border_width_top = 2
	inner.add_theme_stylebox_override("panel", style)
	holder.add_child(inner)
	inner.custom_minimum_size = Vector2(620, 0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	inner.add_child(vbox)

	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 21)
	title_label.add_theme_color_override("font_color", UITheme.GREEN)
	vbox.add_child(title_label)

	var rule := ColorRect.new()
	rule.color = Color(UITheme.GREEN, 0.3)
	rule.custom_minimum_size = Vector2(0, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(rule)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	vbox.add_child(rows)

	var modal := {"root": root, "title": title_label, "rows": rows}

	# Tapping the dimmed area outside the panel closes the modal — a reliable
	# escape on touch so a modal can never strand the player.
	root.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			_close_modal(modal))

	var close := Button.new()
	close.text = "CLOSE"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 52)
	close.pressed.connect(func() -> void: _close_modal(modal))
	vbox.add_child(close)

	return modal


func _on_map_travel(district_id: String) -> void:
	_close_modal(_map_modal)
	var scene := get_tree().current_scene
	if scene.has_method("go_to"):
		scene.go_to(district_id, "fast_travel")  # no such mark -> district center


func _open_phone() -> void:
	_clear_rows(_phone_modal)
	for msg in Inbox.messages():
		var panel := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.03)
		style.set_corner_radius_all(3)
		style.border_width_left = 3
		style.border_color = Color(msg.color)
		style.set_content_margin_all(10)
		panel.add_theme_stylebox_override("panel", style)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 2)
		panel.add_child(vb)
		var who := Label.new()
		who.text = msg.from
		who.add_theme_font_size_override("font_size", 13)
		who.add_theme_color_override("font_color", Color(msg.color))
		vb.add_child(who)
		var body := Label.new()
		body.text = msg.text
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_font_size_override("font_size", 15)
		vb.add_child(body)
		_phone_modal.rows.add_child(panel)
	_open_modal(_phone_modal)


func _open_map() -> void:
	# Both shells (main.gd / main_3d.gd) expose current_district_id; anything
	# else (title screen) just shows the map without a YOU ARE HERE marker.
	var cur: Variant = get_tree().current_scene.get("current_district_id")
	_city_map.current_district = cur if cur is String else ""
	_city_map.queue_redraw()
	_open_modal(_map_modal)


func _any_modal_open() -> bool:
	for m in _modals:
		if not m.is_empty() and m.root.visible:
			return true
	return false


func _open_modal(modal: Dictionary) -> void:
	if modal.root.visible:
		return
	# Don't stack a modal on a dialog (that double-locked the UI) — let the
	# player finish reading it first.
	if _dialog_panel.visible:
		return
	# If something non-HUD owns the screen (combat / terminal / shop), don't
	# open over it either — that's how the player got soft-locked.
	if GameState.is_ui_locked() and not _any_modal_open():
		return
	var was_open := _any_modal_open()
	# Only ever one modal at a time.
	for m in _modals:
		if m != modal and not m.is_empty():
			m.root.visible = false
	modal.root.visible = true
	# CRT power-on stutter.
	modal.root.modulate.a = 0.0
	var fl: Tween = modal.root.create_tween()
	fl.tween_property(modal.root, "modulate:a", 1.0, 0.05)
	fl.tween_property(modal.root, "modulate:a", 0.55, 0.04)
	fl.tween_property(modal.root, "modulate:a", 1.0, 0.06)
	if not was_open:
		GameState.lock_ui()


func _close_modal(modal: Dictionary) -> void:
	if not modal.root.visible:
		return
	modal.root.visible = false
	GameState.unlock_ui()


func close_blocking_ui() -> void:
	_dismiss_dialog()
	for m in _modals:
		if not m.is_empty() and m.root.visible:
			_close_modal(m)


# Dismiss the dialog box and release its UI lock, if one is showing.
func _dismiss_dialog() -> void:
	if not _dialog_panel.visible:
		return
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
	_dialog_panel.visible = false
	_dialog_queue.clear()
	GameState.unlock_ui()


func _clear_rows(modal: Dictionary) -> void:
	for child in modal.rows.get_children():
		modal.rows.remove_child(child)
		child.queue_free()


# Standard modal row: name + dim description on the left, action button right.
func _add_row(modal: Dictionary, name_text: String, desc_text: String, btn_text: String, btn_disabled: bool, on_press: Callable) -> void:
	var row_panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.04)
	style.set_content_margin_all(12)
	style.set_corner_radius_all(10)
	row_panel.add_theme_stylebox_override("panel", style)
	modal.rows.add_child(row_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row_panel.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var name_label := Label.new()
	name_label.text = name_text
	name_label.add_theme_font_size_override("font_size", 18)
	info.add_child(name_label)
	if desc_text != "":
		var desc := Label.new()
		desc.text = desc_text
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 14)
		desc.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
		info.add_child(desc)

	if btn_text != "":
		var btn := Button.new()
		btn.text = btn_text
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(150, 56)
		btn.disabled = btn_disabled
		if not btn_disabled and on_press.is_valid():
			btn.pressed.connect(on_press)
		row.add_child(btn)


# --- Job board ------------------------------------------------------------------

var _jobs_board := "plaza"


func show_jobs(board: String = "plaza") -> void:
	_jobs_board = board
	_refresh_jobs()
	_open_modal(_jobs_modal)


# Loadout — derived combat/hacking stats + equipped gear. Buy/equip at shop.
func show_loadout() -> void:
	_clear_rows(_loadout_modal)
	var rows: VBoxContainer = _loadout_modal.rows
	var gs := GameState
	var stats := Label.new()
	stats.text = "CYBER-ATK %d   ·   DEF %d   ·   INTEGRITY %d   ·   CRIT %d%%" % [
			gs.total_cyber_attack(), gs.total_defense(), gs.total_integrity(), int(gs.total_crit() * 100)]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_color_override("font_color", Color("7ee787"))
	rows.add_child(stats)
	var hint := Label.new()
	hint.text = "a sharper RIG also lifts your hack odds (+%d%%)." % int(gs.gear_hack_bonus() * 100)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	rows.add_child(hint)
	for slot in GameData.GEAR_SLOTS:
		var id: String = gs.gear.get(slot, "")
		var nm := "— empty —"
		if id != "":
			nm = GameData.GEAR[id].name
		var l := Label.new()
		l.text = "  %s:  %s" % [slot.to_upper(), nm]
		l.add_theme_color_override("font_color", Color("d8e2ec") if id != "" else Color(1, 1, 1, 0.4))
		rows.add_child(l)
	var tip := Label.new()
	tip.text = "Buy & swap gear at the pawn shop (Market)."
	tip.add_theme_font_size_override("font_size", 12)
	tip.add_theme_color_override("font_color", Color("7adfff"))
	rows.add_child(tip)
	_open_modal(_loadout_modal)


# Quest log — the main story chain + repeatable district bounties.
func show_quests() -> void:
	_refresh_quests()
	_open_modal(_quests_modal)


func _refresh_quests() -> void:
	_clear_rows(_quests_modal)
	var rows: VBoxContainer = _quests_modal.rows
	_quest_section(rows, "OBJECTIVE")
	var active := Label.new()
	active.text = "▸ " + GameState.current_quest_text()
	active.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	active.add_theme_color_override("font_color", Color("7adfff"))
	rows.add_child(active)

	_quest_section(rows, "STORY")
	for i in GameData.QUESTS.size():
		var q: Dictionary = GameData.QUESTS[i]
		var mark := "✓" if i < GameState.quest_index else ("▸" if i == GameState.quest_index else "·")
		var col := Color(0.5, 0.7, 0.5) if i < GameState.quest_index else (Color("d8e2ec") if i == GameState.quest_index else Color(1, 1, 1, 0.35))
		var l := Label.new()
		l.text = "  %s  %s" % [mark, q.text]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color", col)
		rows.add_child(l)

	_quest_section(rows, "DISTRICT BOUNTIES")
	var b := Label.new()
	if GameState.scrap_bounty_done:
		b.text = "  ✓ Ozark's scrap quota filled today (Underpass)."
		b.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
	else:
		b.text = "  ▸ Ozark (Underpass): bring %d scrap parts → $120 + 2 REP." % GameState.SCRAP_BOUNTY_NEED
		b.add_theme_color_override("font_color", Color("d8e2ec"))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 13)
	rows.add_child(b)


func _quest_section(parent: Control, text: String) -> void:
	var h := Label.new()
	h.text = text
	h.add_theme_font_size_override("font_size", 12)
	h.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	parent.add_child(h)


# Plaza favors — REP, not cash. One of each per day.
func show_favors() -> void:
	_refresh_favors()
	_open_modal(_favors_modal)


func _refresh_favors() -> void:
	_favors_modal.title.text = "COMMUNITY BOARD   (REP %d · E %d/%d)" % [
			GameState.reputation, GameState.energy, GameState.max_energy]
	_clear_rows(_favors_modal)
	for fav in GameData.FAVORS:
		var done: bool = fav.id in GameState.favors_done
		var btn := "DONE ✓" if done else "-%dE → +%d REP" % [fav.energy, fav.rep]
		var disabled: bool = done or GameState.energy < fav.energy
		_add_row(_favors_modal, fav.name, fav.desc, btn, disabled,
				func() -> void:
					if GameState.do_favor(fav.id):
						_refresh_favors())


# Market goods exchange — buy low, sell high. Prices reset each day.
func show_goods() -> void:
	_refresh_goods()
	_open_modal(_goods_modal)


func _refresh_goods() -> void:
	_goods_modal.title.text = "GOODS EXCHANGE   ($%d)" % GameState.cash
	_clear_rows(_goods_modal)
	for id in GameData.GOODS:
		var g: Dictionary = GameData.GOODS[id]
		var price: int = GameState.goods_price(id)
		var held: int = GameState.goods.get(id, 0)
		var base: int = g.base
		var arrow := "▲" if price > base else ("▼" if price < base else "•")
		var desc := "today $%d %s   (you hold %d)" % [price, arrow, held]
		var row := _favor_row_buysell(g.name, desc, id, held, price)
		_goods_modal.rows.add_child(row)


# A goods row with paired BUY / SELL buttons (the standard _add_row has one).
func _favor_row_buysell(name_text: String, desc_text: String, id: String, held: int, price: int) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.04)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var nm := Label.new()
	nm.text = name_text
	nm.add_theme_font_size_override("font_size", 16)
	col.add_child(nm)
	var ds := Label.new()
	ds.text = desc_text
	ds.add_theme_font_size_override("font_size", 13)
	ds.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	col.add_child(ds)
	var buy := Button.new()
	buy.text = "BUY"
	buy.focus_mode = Control.FOCUS_NONE
	buy.disabled = GameState.cash < price
	buy.pressed.connect(func() -> void:
		if GameState.buy_good(id):
			_refresh_goods())
	row.add_child(buy)
	var sell := Button.new()
	sell.text = "SELL"
	sell.focus_mode = Control.FOCUS_NONE
	sell.disabled = held <= 0
	sell.pressed.connect(func() -> void:
		if GameState.sell_good(id):
			_refresh_goods())
	row.add_child(sell)
	return panel


func _close_jobs() -> void:
	_close_modal(_jobs_modal)


func _refresh_jobs() -> void:
	var title := "GIG BOARD" if _jobs_board == "corp" else "JOB BOARD"
	_jobs_modal.title.text = "%s   ($%d · gigs %d/%d)" % [
		title, GameState.cash, GameState.active_jobs.size(), GameState.MAX_ACTIVE_JOBS]
	_clear_rows(_jobs_modal)
	# Active gigs up top with their destination, so you know where to go.
	for jid in GameState.active_jobs:
		var aj: Dictionary = GameData.JOBS[jid]
		_add_row(_jobs_modal, "● " + aj.name,
				"ACTIVE — go to %s and do the work (marked on the ground)." % GameData.DISTRICTS[aj.district]["name"],
				"", true, Callable())
	# Today's board. R10T may have beaten you to one of them.
	var gigs: Array = GameState.daily_gigs(_jobs_board)
	var claimed := -1
	if hash("r10t_%s_%d" % [_jobs_board, GameState.day]) % 4 == 0 and gigs.size() > 0:
		claimed = hash("r10ti_%s_%d" % [_jobs_board, GameState.day]) % gigs.size()
	for i in gigs.size():
		var id: String = gigs[i]
		if GameState.has_active_job(id):
			continue  # already shown in the active list above
		var job: Dictionary = GameData.JOBS[id]
		if i == claimed:
			_add_row(_jobs_modal, job.name,
					"CLAIMED — R10T got here first. Check back tomorrow.", "TAKEN", true, Callable())
			continue
		var bkind := "jobs_corp" if _jobs_board == "corp" else "jobs_plaza"
		var pay := int(round(job.cash * GameState.hustle_mult()
				* GameState.daily_mult(bkind) * GameState.mastery_mult(bkind)))
		var heat: int = job.get("heat", 0)
		var success := int(round((1.0 - GameState.gig_risk(id)) * 100.0))
		var status_req: int = job.get("status_req", 0)
		var dname: String = GameData.DISTRICTS[job.district]["name"]
		var desc: String = "%s   → %s · -%dE · ~$%d" % [job.desc, dname, job.energy, pay]
		if heat > 0:
			desc += "   [risk: +%d heat · %d%% clean]" % [heat, success]
		var btn_text := "ACCEPT"
		var disabled := false
		var on_press := _accept_job.bind(id)
		if GameState.status_index() < status_req:
			btn_text = "LOCKED"
			disabled = true
			on_press = Callable()
			desc += "  (requires %s status)" % GameData.STATUS_RANKS[status_req]["title"]
		elif job.req_computer and not GameState.has_computer:
			btn_text = "NEED PC"
			disabled = true
			on_press = Callable()
		elif GameState.active_jobs.size() >= GameState.MAX_ACTIVE_JOBS:
			btn_text = "FULL"
			disabled = true
			on_press = Callable()
		_add_row(_jobs_modal, job.name, desc, btn_text, disabled, on_press)


func _accept_job(id: String) -> void:
	GameState.accept_job(id)
	_refresh_jobs()


# --- Skills ------------------------------------------------------------------------

func _open_skills() -> void:
	_refresh_skills()
	_open_modal(_skills_modal)


func _refresh_skills() -> void:
	var pts := GameState.skill_points
	_skills_modal.title.text = "SKILLS — %d point%s" % [pts, "" if pts == 1 else "s"]
	_clear_rows(_skills_modal)
	for id in GameData.SKILLS:
		var s: Dictionary = GameData.SKILLS[id]
		var rank := GameState.skill(id)
		var pips := "● ".repeat(rank) + "○ ".repeat(s.max - rank)
		var maxed: bool = rank >= s.max
		var btn_text := "MAXED" if maxed else "+1 RANK"
		_add_row(_skills_modal, "%s   %s" % [s.name, pips], s.desc, btn_text,
				maxed or pts < 1, _buy_skill.bind(id))
	if pts < 1:
		var hint := Label.new()
		hint.text = "Level up to earn skill points."
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_font_size_override("font_size", 14)
		hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
		_skills_modal.rows.add_child(hint)


func _buy_skill(id: String) -> void:
	GameState.buy_skill(id)
	_refresh_skills()


# --- Backpack -----------------------------------------------------------------------

func _open_bag() -> void:
	_refresh_bag()
	_open_modal(_bag_modal)


func _refresh_bag() -> void:
	_bag_modal.title.text = "BACKPACK"
	_clear_rows(_bag_modal)
	if GameState.inventory.is_empty():
		var empty := Label.new()
		empty.text = "Empty. Scavenge THE ALLEY, pwn boxes, or buy gear at the PAWN SHOP."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_font_size_override("font_size", 15)
		empty.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
		_bag_modal.rows.add_child(empty)
		return

	# Consumables first (with USE buttons), then junk loot (sold at the shop).
	for id in GameState.inventory:
		if not GameState.is_consumable(id):
			continue
		var c: Dictionary = GameData.CONSUMABLES[id]
		_add_row(_bag_modal, "%s  ×%d" % [c.name, GameState.inventory[id]], c.desc,
				"USE", false, _use_consumable.bind(id))
	for id in GameState.inventory:
		if GameState.is_consumable(id):
			continue
		var item: Dictionary = GameData.ITEMS[id]
		_add_row(_bag_modal, "%s  ×%d" % [item.name, GameState.inventory[id]],
				"Junk — sell for ~$%d each at the pawn shop." % int(round(item.price * GameState.hustle_mult())),
				"", true, Callable())


func _use_consumable(id: String) -> void:
	GameState.use_consumable(id)
	_refresh_bag()


# --- WiFi sniffer (wild encounters) ------------------------------------------

func _open_wifi() -> void:
	GameState.sniff_wifi()
	_refresh_wifi()
	_open_modal(_wifi_modal)


func _refresh_wifi() -> void:
	_clear_rows(_wifi_modal)
	var net: Dictionary = GameState.wifi_current
	if net.is_empty():
		_modal_label(_wifi_modal, "No signal. Sniff again.", Color(1, 1, 1, 0.5))
	else:
		var enc: Dictionary = GameData.WIFI_ENCRYPTION[net.enc]
		var pct := int(GameState.wifi_chance(net) * 100)
		var bars := "▮".repeat(net.bars) + "▯".repeat(4 - net.bars)
		_modal_label(_wifi_modal, "📶  %s   %s" % [net.ssid, bars], Color("e6edf3"), 22)
		_modal_label(_wifi_modal, enc.name, Color(enc.color), 18)
		_modal_label(_wifi_modal, "~%d%% crack chance   ·   $%d–$%d" % [pct, enc.min, enc.max], Color(1, 1, 1, 0.7), 15)
		_modal_label(_wifi_modal, "cost: %d CPU, 1 Energy   ·   +%d Heat" % [enc.diff, enc.heat], Color(1, 1, 1, 0.5), 14)
		var no_cpu: bool = GameState.cpu < enc.diff
		_add_row(_wifi_modal, "Crack it", "", "NEED CPU" if no_cpu else "CRACK", no_cpu, _do_crack)
	_add_row(_wifi_modal, "Keep driving", "", "SNIFF AGAIN", false, func() -> void:
		GameState.sniff_wifi()
		_refresh_wifi())

	# Saved networks you've found — revisit any to re-target it.
	if not GameState.known_networks.is_empty():
		_modal_label(_wifi_modal, "— SAVED NETWORKS —", Color(1, 1, 1, 0.45), 13)
		for i in GameState.known_networks.size():
			var k: Dictionary = GameState.known_networks[i]
			var kenc: Dictionary = GameData.WIFI_ENCRYPTION[k.enc]
			var idx := i  # capture
			_add_row(_wifi_modal, "%s" % k.ssid, kenc.name, "LOAD", false, func() -> void:
				GameState.load_known(idx)
				_refresh_wifi())


func _do_crack() -> void:
	var r := GameState.crack_wifi()
	if r.has("blocked"):
		GameState.notify("Can't crack that right now.", GameState.COL_WARN)
	elif r.ok:
		var msg := "Cracked %s! +$%d, +%d Heat" % [r.ssid, r.payout, r.heat]
		if r.data:
			msg += " (+Stolen Data)"
		GameState.notify(msg, GameState.COL_GOOD)
	else:
		GameState.notify("%s shrugged you off. +%d Heat." % [r.ssid, r.heat], GameState.COL_BAD)
	GameState.sniff_wifi()  # next network rolls in
	_refresh_wifi()


# --- Apartments (vacancies) --------------------------------------------------

func _show_apartments_impl() -> void:
	_clear_rows(_apt_modal)
	_apt_modal.title.text = "VACANCIES   ($%d)" % GameState.cash
	for id in GameData.APARTMENTS:
		var apt: Dictionary = GameData.APARTMENTS[id]
		var btn_text: String
		var disabled := false
		var on_press := Callable()
		if id == GameState.apartment:
			btn_text = "HOME"
			disabled = true
		elif apt.price == 0:
			btn_text = "—"
			disabled = true
		elif GameState.status_index() < apt.get("status_req", 0):
			btn_text = "LOCKED"
			disabled = true
		else:
			btn_text = "$%d" % apt.price
			disabled = GameState.cash < apt.price
			on_press = _buy_apartment.bind(id)
		var desc: String = apt.desc
		if GameState.status_index() < apt.get("status_req", 0):
			desc += "  (needs %s status)" % GameData.STATUS_RANKS[apt.status_req]["title"]
		_add_row(_apt_modal, apt.name, desc, btn_text, disabled, on_press)


func show_apartments() -> void:
	_show_apartments_impl()
	_open_modal(_apt_modal)


func _buy_apartment(id: String) -> void:
	GameState.buy_apartment(id)
	_show_apartments_impl()


# --- Furnish (Apartments v2 furniture catalog) -------------------------------

func _show_furnish_impl() -> void:
	_clear_rows(_furnish_modal)
	_furnish_modal.title.text = "FURNISH   ($%d · Style %d · +%d REP/day)" % [
		GameState.cash, GameState.style_score(), GameState.style_rep_per_day()]
	for id in GameData.FURNITURE:
		var f: Dictionary = GameData.FURNITURE[id]
		var btn_text: String
		var disabled := false
		var on_press := Callable()
		if GameState.owns_furniture(id):
			btn_text = "OWNED"
			disabled = true
		elif GameState.status_index() < f.get("status_req", 0):
			btn_text = "LOCKED"
			disabled = true
		else:
			btn_text = "$%d" % f.price
			disabled = GameState.cash < f.price
			on_press = _buy_furniture.bind(id)
		var desc: String = "%s  ·  +%d Style" % [f.desc, f.style]
		if GameState.status_index() < f.get("status_req", 0):
			desc += "  (needs %s)" % GameData.STATUS_RANKS[f.status_req]["title"]
		_add_row(_furnish_modal, f.name, desc, btn_text, disabled, on_press)


func show_furnish() -> void:
	_show_furnish_impl()
	_open_modal(_furnish_modal)


func _buy_furniture(id: String) -> void:
	GameState.buy_furniture(id)
	_show_furnish_impl()


# --- Darknet contracts -------------------------------------------------------

func show_contracts() -> void:
	_refresh_contracts()
	_open_modal(_contracts_modal)


func _refresh_contracts() -> void:
	_clear_rows(_contracts_modal)
	for id in GameData.CONTRACTS:
		var c: Dictionary = GameData.CONTRACTS[id]
		var desc := "%s  ·  reward $%d, +%d REP" % [c.desc, c.cash, c.rep]
		var btn_text: String
		var disabled := false
		var on_press := Callable()
		if id in GameState.completed_contracts:
			btn_text = "DONE"
			disabled = true
		elif GameState.active_contract == id:
			btn_text = "ACTIVE"
			disabled = true
			desc += "  →  pwn %s" % c.target
		elif GameState.status_index() < c.get("status_req", 0):
			btn_text = "LOCKED"
			disabled = true
			desc += "  (needs %s)" % GameData.STATUS_RANKS[c.status_req]["title"]
		else:
			btn_text = "ACCEPT"
			on_press = _accept_contract.bind(id)
		_add_row(_contracts_modal, c.name, desc, btn_text, disabled, on_press)


func _accept_contract(id: String) -> void:
	GameState.accept_contract(id)
	_refresh_contracts()


# A centered, optionally-large label inside a modal's row area.
func _modal_label(modal: Dictionary, text: String, color: Color, size: int = 16) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	modal.rows.add_child(label)
