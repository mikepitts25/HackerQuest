extends Node2D
## Base for a single travelable area. Subclasses (which `extends` this file by
## path) override `_build()` to lay out ground, walls, interactables, NPCs and
## exits. The router (main.gd) instances the district scene, calls build(main),
## then reads `area_size` and spawn_point() to place the player and camera.
##
## Deliberately NOT a `class_name` — referencing it by path everywhere keeps it
## independent of Godot's global class registry, which can go stale.
##
## Districts are rebuilt from scratch on every visit, so any persistent state
## (searched trash, etc.) must live in GameState, not here.

const WALL_COLOR := Color("14161c")
const WandererScript := preload("res://scripts/wanderer.gd")

var main: Node
var area_size := Vector2(1000, 800)
var _spawns := {}  # spawn id -> Vector2


func build(p_main: Node) -> void:
	main = p_main
	_build()


# Override in subclasses. Set area_size, then lay out the district.
func _build() -> void:
	pass


func spawn_point(id: String) -> Vector2:
	return _spawns.get(id, area_size / 2.0)


func _mark(id: String, pos: Vector2) -> void:
	_spawns[id] = pos


# --- layout helpers ----------------------------------------------------------

func _floor(pos: Vector2, size: Vector2, color: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)


# Walls the perimeter of area_size. Pass door gaps as [Rect2,...] to leave open.
func _border(thickness: float = 16.0) -> void:
	_wall(0, 0, area_size.x, thickness)
	_wall(0, area_size.y - thickness, area_size.x, thickness)
	_wall(0, 0, thickness, area_size.y)
	_wall(area_size.x - thickness, 0, thickness, area_size.y)


func _wall(x: float, y: float, w: float, h: float) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x + w / 2.0, y + h / 2.0)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	cs.shape = shape
	body.add_child(cs)
	add_child(body)
	_floor(Vector2(x, y), Vector2(w, h), WALL_COLOR)


func _sign(text: String, pos: Vector2, size: int = 26) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)


func _interactable(prompt: String, pos: Vector2, size: Vector2, color: Color, label: String, action: Callable) -> Interactable:
	var obj := Interactable.new()
	obj.position = pos
	add_child(obj)
	obj.configure(prompt, action, size, color, label)
	return obj


# A door to another district. Locked doors show a status requirement instead
# of travelling. Tapping interact travels there (or explains the lock).
func _exit(label: String, pos: Vector2, size: Vector2, target_district: String, target_spawn: String) -> void:
	var unlocked := GameState.district_unlocked(target_district)
	var color := Color("3b5dc9") if unlocked else Color("4a3a3a")
	var face := ("→ %s" % label) if unlocked else ("LOCKED %s" % label)
	var prompt := ("Go to %s" % label) if unlocked else ("%s — locked" % label)
	_interactable(prompt, pos, size, color, face,
			func() -> void: _try_exit(target_district, target_spawn, label))


func _try_exit(target_district: String, target_spawn: String, label: String) -> void:
	if GameState.district_unlocked(target_district):
		main.go_to(target_district, target_spawn)
	else:
		var req: int = GameData.DISTRICTS[target_district].get("status_req", 0)
		GameState.notify("%s opens up at %s status." % [label, GameData.STATUS_RANKS[req]["title"]], GameState.COL_WARN)


# Ambient friendly NPCs currently roaming this district (see GameState.ambient).
func _spawn_wanderers(district_id: String) -> void:
	for w in GameState.ambient_in(district_id):
		var wd: Area2D = WandererScript.new()
		wd.position = Vector2(randf_range(80, area_size.x - 80), randf_range(80, area_size.y - 80))
		wd.bounds = area_size
		add_child(wd)
		var nm: String = w.name
		wd.configure("Talk to %s" % nm, func() -> void: main.talk_wanderer(nm),
				Vector2(26, 26), Color(w.color), nm)


# Spawns every NPC whose `district` matches, at its district-local position.
func _spawn_npcs(district_id: String) -> void:
	for npc_id in GameData.NPCS:
		var npc: Dictionary = GameData.NPCS[npc_id]
		if npc.get("district", "") != district_id:
			continue
		var id: String = npc_id  # capture for the closure
		var label := "%s\n(%s)" % [npc.name, npc.get("role", "regular")]
		_interactable("Talk to %s" % npc.name, Vector2(npc.pos[0], npc.pos[1]),
				Vector2(32, 32), Color(npc.color), label,
				func() -> void: main.talk_npc(id))


# A scavengable e-waste pile. Dim state is derived from GameState so it stays
# correct across district rebuilds; sleeping clears GameState.trash_searched.
func _trash_pile(id: String, pos: Vector2) -> void:
	var pile := _interactable("Search trash", pos, Vector2(60, 48), Color("4a5d3a"), "e-waste", Callable())
	pile.action = func() -> void: _search_trash(id, pile)
	if GameState.trash_searched.has(id):
		pile.set_dim(true)


func _search_trash(id: String, pile: Interactable) -> void:
	if GameState.trash_searched.has(id):
		GameState.notify("Picked clean. Check back tomorrow.", GameState.COL_WARN)
		return
	if not GameState.use_energy(1):
		return
	GameState.trash_searched[id] = true
	var item_id: String = GameData.TRASH_LOOT.pick_random()
	var scrap := int(round(randi_range(2, 4) * GameState.hustle_mult()))
	GameState.add_item(item_id)
	GameState.add_cash(scrap)
	GameState.add_xp(3)
	GameState.notify("Found %s! (+$%d scrap, +3 XP)" % [GameData.ITEMS[item_id]["name"], scrap], GameState.COL_GOOD)
	pile.set_dim(true)
