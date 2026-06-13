extends Node2D
## Main scene controller. Persistent shell that owns the Player, UI and camera,
## and routes between districts. World interactions call back into here, which
## forwards them to the right UI panel.

@onready var world_container: Node2D = $WorldContainer
@onready var player: CharacterBody2D = $Player
@onready var hud: Control = $UILayer/HUD
@onready var terminal: Panel = $UILayer/Terminal
@onready var shop: Panel = $UILayer/Shop

var current_district_id := ""


func _ready() -> void:
	GameState.busted.connect(_on_busted)
	go_to("home", "start")
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


# Swap the active district, repositioning the player at the named spawn and
# clamping the camera to the new area. Districts are rebuilt fresh each visit.
func go_to(district_id: String, spawn_id: String) -> void:
	if not GameData.DISTRICTS.has(district_id):
		push_warning("Unknown district: %s" % district_id)
		return
	if not GameState.district_unlocked(district_id):
		GameState.notify("That district is locked.", GameState.COL_WARN)
		return
	for child in world_container.get_children():
		world_container.remove_child(child)
		child.queue_free()

	# Typed as Node2D (not District) so this script doesn't hard-depend on the
	# District class being registered when it loads.
	var district: Node2D = load(GameData.DISTRICTS[district_id]["scene"]).instantiate()
	world_container.add_child(district)
	district.build(self)
	current_district_id = district_id

	player.global_position = district.spawn_point(spawn_id)
	player.reset_proximity()
	GameState.touch_vector = Vector2.ZERO

	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(district.area_size.x)
	cam.limit_bottom = int(district.area_size.y)
	cam.reset_smoothing()


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


func talk_wanderer(npc_name: String) -> void:
	hud.show_dialog([NpcDialogs.wanderer_line(npc_name)])


func talk_npc(id: String) -> void:
	hud.show_dialog(NpcDialogs.lines_for(id))


func _on_busted() -> void:
	if terminal.visible:
		terminal.close_terminal()
	if shop.visible:
		shop.close_shop()
	hud.show_dialog([
		"CARRIER LOST — you got traced.",
		"A fixer made the report disappear... for half your cash. Half your botnet got burned too.",
		"Lay low. Sleeping lowers your Heat.",
	])
