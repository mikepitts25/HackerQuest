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
	# Interior reached only via the door inside Corp Row — not a fast-travel
	# stop (absent from DISTRICT_MAP) and not in GameData.DISTRICTS.
	"corp_datacenter": "res://scenes/iso/districts/corp_datacenter_3d.tscn",
}

@onready var world_container: Node3D = $WorldContainer
@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $UILayer/HUD
@onready var terminal: Panel = $UILayer/Terminal
@onready var shop: Panel = $UILayer/Shop
@onready var combat: Panel = $UILayer/Combat

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
var _day_t := -1.0
var _day_tween: Tween
var _news_day := -1


func _ready() -> void:
	GameState.busted.connect(_on_busted)
	GameState.trace_started.connect(_on_trace_started)
	GameState.trace_cleared.connect(_on_trace_cleared)
	GameState.jobs_changed.connect(_on_jobs_changed)
	GameState.stats_changed.connect(_update_daylight)
	GameState.stats_changed.connect(_check_morning_news)
	combat.closed.connect(_on_combat_closed)
	_news_day = GameState.day
	_enc_rng.randomize()
	Audio.apply_volumes()  # a loaded save may carry custom volumes
	go_to("home", "start")
	_update_daylight()
	_announce_daily_mod()


func _process(delta: float) -> void:
	# The trace countdown pauses while you're in a fight — standing to fight a
	# tracker shouldn't let the timer bust you mid-combat.
	if not combat.visible:
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
		GameState.is_new_game = false  # intro shows once, not every morning
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
	if escaped_trace:
		GameState.escape_trace()
	if current_district_id != "" and current_district_id != district_id:
		Audio.sfx("travel")
	for child in world_container.get_children():
		world_container.remove_child(child)
		child.queue_free()

	var district: Node3D = load(DISTRICT_SCENES[district_id]).instantiate()
	current_district_id = district_id  # set before build() so it can place gig markers
	world_container.add_child(district)
	district.build(self)

	player.global_position = district.spawn_point(spawn_id)
	player.reset_proximity()
	GameState.touch_vector = Vector2.ZERO
	Audio.music(DISTRICT_MUSIC.get(district_id, "city"))


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


func open_pet_shop() -> void:
	hud.show_pet_shop()


# Drop into a turn-based fight against a GameData.ENEMIES id (G6).
func start_combat(enemy_id: String) -> void:
	combat.start(enemy_id)


func start_street_combat(enemy_id: String) -> void:
	if enemy_id == "r10t":
		_on_toast("// UNKNOWN SIGNAL converging on your position...", GameState.COL_BAD)
	else:
		_on_toast("AMBUSH — %s makes contact." % GameData.ENEMIES[enemy_id].name, GameState.COL_BAD)
	start_combat(enemy_id)


func _on_combat_closed(enemy_id: String, outcome: String) -> void:
	var district := world_container.get_child(0) if world_container.get_child_count() > 0 else null
	if district != null and district.has_method("resolve_street_encounter"):
		district.resolve_street_encounter(enemy_id, outcome)


# --- street encounters (G6 phase 3) -------------------------------------------

const NO_ENCOUNTER_DISTRICTS := ["home", "corp_datacenter"]
const ENCOUNTER_COOLDOWN := 2  # safe travels after any fight

# Background music per district (track files in assets/audio/music/).
const DISTRICT_MUSIC := {
	"home": "city", "plaza": "city", "market": "city", "underpass": "city",
	"corp_row": "corp", "darknet": "darknet", "drowned_quarter": "drowned",
	"corp_datacenter": "corp",
}

var _enc_rng := RandomNumberGenerator.new()
var _travels_since_combat := 99  # high so the first trip out can spring one


# Roll for a hostile street NPC to spawn in the district. The fight itself only
# starts when the player collides with/touches that NPC.
func roll_street_encounter(district_id: String) -> String:
	_travels_since_combat += 1
	if district_id in NO_ENCOUNTER_DISTRICTS or GameState.trace_active or GameState.is_ui_locked():
		return ""
	if _travels_since_combat < ENCOUNTER_COOLDOWN:
		return ""
	var enemy_id := roll_encounter(
		GameState.status_index(), GameState.heat, GameState.r10t_beaten,
		GameState.combat_stats().attack, _enc_rng, district_id, GameState.defeated_crew_bosses)
	if enemy_id == "":
		return ""
	_travels_since_combat = 0
	return enemy_id


# Pure encounter decision (no node/GameState deps, so it's unit-testable).
# Returns a GameData.ENEMIES id, or "" for no fight.
static func roll_encounter(status_idx: int, heat: int, r10t_beaten: bool, attack: int,
		rng: RandomNumberGenerator, district_id := "", defeated_crew_bosses: Array = []) -> String:
	if attack < 3 or status_idx < 1:
		return ""  # no real offense, or too green to be worth ambushing
	if GameData.RIOT_CREW_BY_DISTRICT.has(district_id):
		var crew_id: String = GameData.RIOT_CREW_BY_DISTRICT[district_id]
		if not (crew_id in defeated_crew_bosses):
			var district_req: int = int(GameData.DISTRICTS[district_id].get("status_req", 0))
			if status_idx >= district_req and rng.randf() < 0.24:
				return crew_id
	# R10T no longer roams as a random street boss — his whole arc is the café
	# duel (Darknet) → the rematch + Deep Marrow gauntlet (Drowned Quarter), which
	# is where the R10T Root Key drops now. See darknet_3d / drowned_quarter_3d.
	var chance := 0.10 + 0.20 * (heat / 100.0)  # heat makes the street meaner
	if rng.randf() > chance:
		return ""
	var pool := ["script_kid"]
	if status_idx >= 2:  # the tougher runner shows up once you're climbing
		pool.append("street_hacker")
		pool.append("street_hacker")
	return pool[rng.randi() % pool.size()]


func show_jobs(board: String = "plaza") -> void:
	hud.show_jobs(board)


func open_apartments() -> void:
	hud.show_apartments()


func open_furnish() -> void:
	hud.show_furnish()


func open_contracts() -> void:
	hud.show_contracts()


func show_cryptogram_clue(id: String) -> void:
	var clue := GameData.cryptogram_clue(id)
	if clue.is_empty():
		return
	GameState.solve_cryptogram(id)
	hud.show_dialog([
		str(clue.title),
		"CIPHER: %s" % str(clue.encoded),
		"HINT: %s" % str(clue.hint),
		"DECODED: %s" % str(clue.plain),
		"Fragments decoded: %d/%d" % [GameState.solved_cryptograms.size(), GameData.CRYPTOGRAM_CLUES.size()],
	])


func open_quests() -> void:
	hud.show_quests()


func open_favors() -> void:
	hud.show_favors()


func open_goods() -> void:
	hud.show_goods()


func talk_wanderer(npc_name: String) -> void:
	hud.show_dialog([NpcDialogs.wanderer_line(npc_name)])


func talk_npc(id: String) -> void:
	if NpcDialogs.needs_confirmation(id):
		hud.show_confirm_dialog(NpcDialogs.lines_for(id), "YES", "NO",
				func() -> void: hud.show_dialog(NpcDialogs.confirm_lines_for(id)))
	else:
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


func _on_toast(text: String, color: Color) -> void:
	if hud.has_method("add_feed_message"):
		hud.add_feed_message(text, color)


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


# Trace over (escaped, fought off, or busted) — pull the cop pressure from the
# current district so the streets settle.
func _on_trace_cleared(_escaped: bool) -> void:
	var district := world_container.get_child(0) if world_container.get_child_count() > 0 else null
	if district != null and district.has_method("_clear_police_pressure"):
		district._clear_police_pressure()


# A gig was accepted/completed — re-mark the current district so the glowing
# marker appears or clears without needing to leave and come back.
func _on_jobs_changed() -> void:
	var district := world_container.get_child(0) if world_container.get_child_count() > 0 else null
	if district != null and district.has_method("refresh_job_markers"):
		district.refresh_job_markers()


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
