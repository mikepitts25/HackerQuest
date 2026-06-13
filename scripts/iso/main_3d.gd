extends Node3D
## 3D main shell — the isometric counterpart of main.gd. Persistent root that
## owns the Player, lighting, and the SAME UI panels as the 2D game (HUD,
## Terminal, Shop), and routes between 3D districts. World interactions call
## back into here, which forwards them to the right UI panel — districts and
## interactables can't tell which shell they're running under.

const DISTRICT_SCENES := {
	"home": "res://scenes/iso/districts/home_3d.tscn",
	"plaza": "res://scenes/iso/districts/plaza_3d.tscn",
	"market": "res://scenes/iso/districts/market_3d.tscn",
	"underpass": "res://scenes/iso/districts/underpass_3d.tscn",
	"corp_row": "res://scenes/iso/districts/corp_row_3d.tscn",
	"darknet": "res://scenes/iso/districts/darknet_3d.tscn",
	"drowned_quarter": "res://scenes/iso/districts/drowned_quarter_3d.tscn",
}

@onready var world_container: Node3D = $WorldContainer
@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $UILayer/HUD
@onready var terminal: Panel = $UILayer/Terminal
@onready var shop: Panel = $UILayer/Shop

# Day/night ambience. The "clock" is your energy: fresh after sleep = warm
# dusk; running on fumes = dead of night. Sleeping resets it to dusk.
const DUSK := {
	"amb": Color(0.4, 0.37, 0.47), "amb_e": 1.7,
	"sun": Color(1.0, 0.87, 0.78), "sun_e": 1.3,
	"bg": Color(0.06, 0.052, 0.09),
}
const NIGHT := {
	"amb": Color(0.2, 0.23, 0.38), "amb_e": 1.05,
	"sun": Color(0.68, 0.76, 1.0), "sun_e": 0.75,
	"bg": Color(0.025, 0.035, 0.06),
}

var current_district_id := ""
var _toasts: VBoxContainer
var _day_t := -1.0
var _day_tween: Tween
var _news_day := -1


func _ready() -> void:
	GameState.busted.connect(_on_busted)
	GameState.trace_started.connect(_on_trace_started)
	_build_toast_feed()
	GameState.toast.connect(_on_toast)
	GameState.stats_changed.connect(_update_daylight)
	GameState.stats_changed.connect(_check_morning_news)
	_news_day = GameState.day
	go_to("home", "start")
	_update_daylight()
	_announce_daily_mod()


func _process(delta: float) -> void:
	GameState.tick_trace(delta)


# A new day = one CITY WIRE headline + today's district modifier.
func _check_morning_news() -> void:
	if GameState.day == _news_day:
		return
	_news_day = GameState.day
	_on_toast("// CITY WIRE: " + NewsFeed.morning_headline(), Color("7adfff"))
	_announce_daily_mod()


func _announce_daily_mod() -> void:
	var m: Dictionary = GameState.daily_modifier()
	_on_toast("★ TODAY: %s — %s" % [m.name, m.desc], Color(0.91, 0.66, 0.24))
	if GameState.is_new_game:
		hud.show_dialog([
			"Another overdue rent notice. You're broke — but you've got a plan: become the best hacker this city has ever seen.",
			"Step 1: cash. Head out to the PLAZA — there's a job board and people who can help.",
			"The MARKET past the plaza scraps e-waste and sells a (mostly working) laptop for $100.",
		])
	else:
		hud.show_dialog([
			"Welcome back. Day %d, $%d in your pocket." % [GameState.day, GameState.cash],
			"Next up — %s." % GameState.current_quest_text(),
		])


# Swap the active district, repositioning the player at the named spawn.
# Districts are rebuilt fresh each visit. The camera rides the player, so no
# camera work is needed here (unlike the 2D shell's limit clamping).
func go_to(district_id: String, spawn_id: String) -> void:
	if not DISTRICT_SCENES.has(district_id):
		push_warning("Unknown district: %s" % district_id)
		return
	if not GameState.district_unlocked(district_id):
		GameState.notify("That district is locked.", GameState.COL_WARN)
		return
	var escaped_trace := GameState.trace_active and current_district_id != "" and district_id != current_district_id
	for child in world_container.get_children():
		world_container.remove_child(child)
		child.queue_free()

	var district: Node3D = load(DISTRICT_SCENES[district_id]).instantiate()
	world_container.add_child(district)
	district.build(self)
	current_district_id = district_id

	player.global_position = district.spawn_point(spawn_id)
	player.reset_proximity()
	GameState.touch_vector = Vector2.ZERO
	if escaped_trace:
		GameState.escape_trace()


func do_sleep() -> void:
	GameState.sleep()


func use_desk() -> void:
	if GameState.has_computer:
		terminal.open()
	else:
		hud.show_dialog([
			"An empty desk with a laptop-shaped hole in your life.",
			"The pawn shop sells a used laptop for $%d." % GameData.UPGRADES["used_laptop"]["price"],
		])


func open_shop() -> void:
	shop.open()


func show_jobs(board: String = "plaza") -> void:
	hud.show_jobs(board)


func open_apartments() -> void:
	hud.show_apartments()


func open_contracts() -> void:
	hud.show_contracts()


func open_quests() -> void:
	hud.show_quests()


func open_favors() -> void:
	hud.show_favors()


func open_goods() -> void:
	hud.show_goods()


func talk_wanderer(npc_name: String) -> void:
	hud.show_dialog([NpcDialogs.wanderer_line(npc_name)])


func talk_npc(id: String) -> void:
	hud.show_dialog(NpcDialogs.lines_for(id))


# Hard jolt when you get TRACED — the one moment that deserves violence.
func _shake_camera() -> void:
	var cam: Camera3D = player.get_node("Camera3D")
	var base := cam.position
	var shake := create_tween()
	for i in 6:
		shake.tween_property(cam, "position",
				base + Vector3(randf_range(-0.2, 0.2), randf_range(-0.14, 0.14), 0), 0.04)
	shake.tween_property(cam, "position", base, 0.07)


func _update_daylight() -> void:
	var t := 1.0 - float(GameState.energy) / maxf(1.0, float(GameState.max_energy))
	if absf(t - _day_t) < 0.01:
		return
	_day_t = t
	var env: Environment = $WorldEnvironment.environment
	var sun: DirectionalLight3D = $Sun
	if _day_tween and _day_tween.is_valid():
		_day_tween.kill()
	_day_tween = create_tween().set_parallel(true)
	_day_tween.tween_property(env, "ambient_light_color", DUSK.amb.lerp(NIGHT.amb, t), 1.2)
	_day_tween.tween_property(env, "ambient_light_energy", lerpf(DUSK.amb_e, NIGHT.amb_e, t), 1.2)
	_day_tween.tween_property(env, "background_color", DUSK.bg.lerp(NIGHT.bg, t), 1.2)
	_day_tween.tween_property(sun, "light_color", DUSK.sun.lerp(NIGHT.sun, t), 1.2)
	_day_tween.tween_property(sun, "light_energy", lerpf(DUSK.sun_e, NIGHT.sun_e, t), 1.2)


# Screen-space toast feed — the 3D stand-in for the 2D player's floating
# text (player.gd renders GameState.toast in world space; here it's UI).
func _build_toast_feed() -> void:
	_toasts = VBoxContainer.new()
	_toasts.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toasts.offset_top = 110.0
	_toasts.offset_bottom = 560.0
	_toasts.offset_left = -330.0
	_toasts.offset_right = 330.0
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UILayer.add_child(_toasts)


func _on_toast(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", UITheme.mono_font())
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.add_child(label)
	var fade := label.create_tween()
	fade.tween_interval(2.6)
	fade.tween_property(label, "modulate:a", 0.0, 0.6)
	fade.tween_callback(label.queue_free)


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


func _on_busted() -> void:
	_shake_camera()
	if terminal.visible:
		terminal.close_terminal()
	if shop.visible:
		shop.close_shop()
	if hud.has_method("close_blocking_ui"):
		hud.close_blocking_ui()
	hud.show_dialog([
		"CARRIER LOST — you got traced.",
		"A fixer made the report disappear... for half your cash. Half your botnet got burned too.",
		"Lay low. Sleeping lowers your Heat.",
	])
