extends Node3D
## Base for a 3D travelable district — the iso cousin of district.gd, same
## contract: subclasses override _build(), the router (main_3d.gd) instances
## the scene, calls build(main), then reads area_size / spawn_point().
##
## Coordinates are METERS on the XZ ground plane, origin at the district's
## top-left corner (the 2D top-left convention; 2D y maps to 3D z). Legacy
## pixel data (GameData.NPCS positions) converts via PX.
##
## Districts are rebuilt from scratch on every visit, so any persistent state
## (searched trash, etc.) must live in GameState, not here.

const PX := 1.0 / 80.0  # meters per legacy 2D pixel

const InteractableScript := preload("res://scripts/iso/interactable_3d.gd")
const WandererScript := preload("res://scripts/iso/wanderer_3d.gd")

const CHAR_SCENES := {
	"pix": "res://assets/iso/characters/char_pix.tscn",
	"riot": "res://assets/iso/characters/char_riot.tscn",
	"glitch": "res://assets/iso/characters/char_glitch.tscn",
	"marlowe": "res://assets/iso/characters/char_marlowe.tscn",
	"vex": "res://assets/iso/characters/char_vex.tscn",
	"cipher": "res://assets/iso/characters/char_cipher.tscn",
	"oracle": "res://assets/iso/characters/char_oracle.tscn",
}
const CITIZEN_SCENE := "res://assets/iso/characters/char_citizen.tscn"
const EXIT_SCENE := "res://assets/iso/props/prop_exit_marker.tscn"
const TRASH_SCENE := "res://assets/iso/props/prop_trash_pile.tscn"
const JOB_BOARD_SCENE := "res://assets/iso/props/prop_job_board.tscn"
const COUNTER_SCENE := "res://assets/iso/props/prop_shop_counter.tscn"
const RACK_SCENE := "res://assets/iso/props/prop_server_rack.tscn"
const BED_SCENE := "res://assets/iso/props/prop_bed.tscn"
const DESK_SCENE := "res://assets/iso/props/prop_desk_terminal.tscn"
const TOWER_SCENE := "res://assets/iso/buildings/bldg_tower.tscn"
const SHOP_BLDG_SCENE := "res://assets/iso/buildings/bldg_shop.tscn"

const GROUND_COLOR := Color(0.078, 0.086, 0.118)
const WALL_COLOR := Color(0.067, 0.078, 0.102)

var main: Node
var area_size := Vector2(12, 9)  # meters
var _spawns := {}                # spawn id -> Vector2 (x, z)
var _buildings: Array = []       # {node, tall} — for botnet LEDs

# Where ambient wanderers may roam. Empty = the whole district (minus a
# margin). Districts with interiors (the apartment) restrict this so
# strangers stay on the street where they belong.
var wander_zone := Rect2()


func build(p_main: Node) -> void:
	main = p_main
	_build()
	_add_heat_patrol()
	_add_police_presence()
	_add_botnet_glow()
	_spawn_crowd(_crowd_size())


# Override in subclasses. Set area_size, then lay out the district.
func _build() -> void:
	pass


func spawn_point(id: String) -> Vector3:
	var p: Vector2 = _spawns.get(id, area_size / 2.0)
	return Vector3(p.x, 0, p.y)


func _mark(id: String, pos: Vector2) -> void:
	_spawns[id] = pos


# --- layout helpers -----------------------------------------------------------

func _ground(color := GROUND_COLOR) -> void:
	_slab(Vector2.ZERO, area_size, 0.12, -0.06, color)


# Thin floor patch (pavers, room floors). pos is the top-left corner.
func _patch(pos: Vector2, size: Vector2, color: Color) -> void:
	_slab(pos, size, 0.04, 0.0, color)


func _slab(pos: Vector2, size: Vector2, thickness: float, y: float, color: Color) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(size.x, thickness, size.y)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	bm.material = mat
	m.mesh = bm
	m.position = Vector3(pos.x + size.x / 2.0, y, pos.y + size.y / 2.0)
	add_child(m)


# Walls the perimeter of area_size (low visible curbs that also collide).
func _border(thickness := 0.25) -> void:
	_wall(0, 0, area_size.x, thickness)
	_wall(0, area_size.y - thickness, area_size.x, thickness)
	_wall(0, 0, thickness, area_size.y)
	_wall(area_size.x - thickness, 0, thickness, area_size.y)


func _wall(x: float, z: float, w: float, d: float, h := 0.7) -> void:
	var body := StaticBody3D.new()
	body.position = Vector3(x + w / 2.0, h / 2.0, z + d / 2.0)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(w, h, d)
	cs.shape = shape
	body.add_child(cs)
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w, h, d)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = WALL_COLOR
	mat.roughness = 0.9
	bm.material = mat
	m.mesh = bm
	body.add_child(m)
	add_child(body)


# Invisible static box, for props that need solidity.
func _collider(pos: Vector2, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = Vector3(pos.x, size.y / 2.0, pos.y)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	add_child(body)


func _sign(text: String, pos: Vector2, height := 1.9, font_size := 48) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = font_size
	l.pixel_size = 0.01
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(1, 1, 1, 0.8)
	l.outline_size = 10
	l.position = Vector3(pos.x, height, pos.y)
	add_child(l)


func _prop(path: String, pos: Vector2, yaw_deg := 0.0) -> Node3D:
	var p: Node3D = load(path).instantiate()
	p.position = Vector3(pos.x, 0, pos.y)
	p.rotation.y = deg_to_rad(yaw_deg)
	add_child(p)
	if path.begins_with("res://assets/iso/buildings/"):
		_buildings.append({"node": p, "tall": path.contains("tower")})
	return p


# Attach an interaction volume to a visual (prop instance, character...).
func _interact(visual: Node3D, prompt: String, size: Vector3, action: Callable) -> Area3D:
	var obj: Area3D = InteractableScript.new()
	visual.add_child(obj)
	obj.configure(prompt, action, size)
	return obj


# Generic colored-box interactable for things without a dedicated prop yet —
# the 3D equivalent of the 2D colored rect + label.
func _box_interactable(prompt: String, pos: Vector2, size: Vector3, color: Color, label: String, action: Callable) -> Area3D:
	var holder := Node3D.new()
	holder.position = Vector3(pos.x, 0, pos.y)
	add_child(holder)
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	bm.material = mat
	m.mesh = bm
	m.position.y = size.y / 2.0
	holder.add_child(m)
	if label != "":
		_sign(label, pos, size.y + 0.45, 36)
	return _interact(holder, prompt, size, action)


# A door to another district: glowing arch + travel interactable. Locked
# doors dim and explain the status requirement instead of travelling.
func _exit(label: String, pos: Vector2, target_district: String, target_spawn: String, yaw_deg := 0.0) -> void:
	var marker := _prop(EXIT_SCENE, pos, yaw_deg)
	var unlocked: bool = GameState.district_unlocked(target_district)
	var face := ("→ %s" % label) if unlocked else ("LOCKED %s" % label)
	_sign(face, pos, 2.1, 40)
	var prompt := ("Go to %s" % label) if unlocked else ("%s — locked" % label)
	var it := _interact(marker, prompt, Vector3(1.2, 1.6, 1.0),
			func() -> void: _try_exit(target_district, target_spawn, label))
	if not unlocked:
		it.set_dim(true)


func _try_exit(target_district: String, target_spawn: String, label: String) -> void:
	if GameState.district_unlocked(target_district):
		main.go_to(target_district, target_spawn)
	else:
		var req: int = GameData.DISTRICTS[target_district].get("status_req", 0)
		GameState.notify("%s opens up at %s status." % [label, GameData.STATUS_RANKS[req]["title"]], GameState.COL_WARN)


# Spawns every NPC whose `district` matches, at its (converted) data position.
func _spawn_npcs(district_id: String) -> void:
	var visitors := 0
	for npc_id in GameData.NPCS:
		var npc: Dictionary = GameData.NPCS[npc_id]
		if GameState.npc_district(npc_id) != district_id:
			continue
		# At their home district they stand at their fixed mark; visiting a
		# different district, they loiter near the entrance plaza instead of
		# their home-local pixel coords (which could land inside a wall).
		var home: bool = npc.get("district", "") == district_id
		var pos: Vector2
		if home:
			pos = Vector2(npc.pos[0] * PX, npc.pos[1] * PX)
		else:
			pos = Vector2(area_size.x * 0.5 + visitors * 1.2 - 1.2, area_size.y * 0.32)
			visitors += 1
		# Named NPCs without a dedicated scene spawn as a tinted citizen.
		var scene_path: String = CHAR_SCENES.get(npc_id, CITIZEN_SCENE)
		var ch: Node3D = load(scene_path).instantiate()
		if scene_path == CITIZEN_SCENE:
			_tint_body(ch, Color(npc.color))
		ch.position = Vector3(pos.x, 0, pos.y)
		ch.rotation.y = deg_to_rad(30)
		add_child(ch)
		var id: String = npc_id  # capture for the closure
		_interact(ch, "Talk to %s" % npc.name, Vector3(0.6, 1.3, 0.6),
				func() -> void: main.talk_npc(id))
		_sign(npc.name + ("" if home else " (visiting)"), pos, 1.75, 32)


# Ambient friendly NPCs currently roaming this district (see GameState.ambient).
# When the sweeps are on (heat above Clean) the streets thin out and whoever
# is left walks fast and doesn't linger; deep in the night they thin further.
func _spawn_wanderers(district_id: String) -> void:
	var margin := 1.0
	var zone := wander_zone
	if zone.size == Vector2.ZERO:
		zone = Rect2(margin, margin, area_size.x - margin * 2.0, area_size.y - margin * 2.0)
	var sweeps := GameState.heat_penalty() > 0.0
	var late := GameState.energy <= int(GameState.max_energy * 0.3)
	var skip_chance := minf(0.8, (0.55 if sweeps else 0.0) + (0.35 if late else 0.0))
	for w in GameState.ambient_in(district_id):
		if randf() < skip_chance:
			continue
		var ch: Node3D = load(CITIZEN_SCENE).instantiate()
		ch.set_script(WandererScript)
		ch.area_center = Vector3(zone.get_center().x, 0, zone.get_center().y)
		ch.area_size = zone.size
		ch.speed = randf_range(0.5, 0.9) * (1.8 if sweeps else 1.0)
		ch.position = Vector3(
			randf_range(zone.position.x, zone.end.x), 0,
			randf_range(zone.position.y, zone.end.y))
		add_child(ch)
		_tint_body(ch, Color(w.color))
		var nm: String = w.name
		_interact(ch, "Talk to %s" % nm, Vector3(0.6, 1.3, 0.6),
				func() -> void: main.talk_wanderer(nm))


# Crowd size scales with district area so the bigger districts feel busier.
func _crowd_size() -> int:
	return int(area_size.x * area_size.y / 45.0)


# Anonymous pedestrians (G3) — regular people who fill the streets, roam, and
# mutter. Not from the migrating roster; respawned each visit, thinned under
# sweeps/night like the named wanderers. Respects wander_zone (keeps strangers
# out of the apartment).
func _spawn_crowd(n: int) -> void:
	var margin := 1.0
	var zone := wander_zone
	if zone.size == Vector2.ZERO:
		zone = Rect2(margin, margin, area_size.x - margin * 2.0, area_size.y - margin * 2.0)
	var sweeps := GameState.heat_penalty() > 0.0
	var late := GameState.energy <= int(GameState.max_energy * 0.3)
	var skip := minf(0.8, (0.5 if sweeps else 0.0) + (0.35 if late else 0.0))
	for i in n:
		if randf() < skip:
			continue
		var ch: Node3D = load(CITIZEN_SCENE).instantiate()
		ch.set_script(WandererScript)
		ch.area_center = Vector3(zone.get_center().x, 0, zone.get_center().y)
		ch.area_size = zone.size
		ch.speed = randf_range(0.5, 1.0) * (1.8 if sweeps else 1.0)
		ch.position = Vector3(
			randf_range(zone.position.x, zone.end.x), 0,
			randf_range(zone.position.y, zone.end.y))
		add_child(ch)
		_tint_body(ch, Color(GameData.CITIZEN_TINTS.pick_random()))
		var nm: String = GameData.CITIZEN_NAMES.pick_random()
		_interact(ch, "Greet %s" % nm, Vector3(0.6, 1.3, 0.6),
				func() -> void: main.talk_wanderer(nm))


# Recolors a citizen's torso so wanderers keep their GameState identity color.
# Mesh and material are shared resources, so both get duplicated per instance.
func _tint_body(ch: Node3D, color: Color) -> void:
	var body: MeshInstance3D = ch.get_node_or_null("Body")
	if body == null or body.mesh == null:
		return
	var mesh: Mesh = body.mesh.duplicate()
	var mat: StandardMaterial3D = mesh.material.duplicate()
	mat.albedo_color = color.darkened(0.35)
	mesh.material = mat
	body.mesh = mesh


# A scavengable e-waste pile. Dim state derives from GameState so it stays
# correct across district rebuilds; sleeping clears GameState.trash_searched.
func _trash_pile(id: String, pos: Vector2) -> void:
	var pile := _prop(TRASH_SCENE, pos)
	var it := _interact(pile, "Search trash", Vector3(0.9, 0.6, 0.8), Callable())
	it.action = func() -> void: _search_trash(id, it)
	if GameState.trash_searched.has(id):
		it.set_dim(true)


# --- the world reacting to you (Alive City phase 1) ---------------------------

# A police drone circles the district while your heat is above Clean.
func _add_heat_patrol() -> void:
	if GameState.heat_penalty() <= 0.0:
		return
	var drone := Node3D.new()
	drone.set_script(preload("res://scripts/iso/patrol_drone.gd"))
	drone.center = Vector3(area_size.x / 2.0, 0, area_size.y / 2.0)
	drone.radius = minf(area_size.x, area_size.y) * 0.32
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.34, 0.1, 0.34)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.06, 0.08)
	mat.metallic = 0.4
	mat.roughness = 0.4
	bm.material = mat
	body.mesh = bm
	drone.add_child(body)
	var light := OmniLight3D.new()
	light.name = "Light"
	light.position.y = -0.15
	light.light_energy = 1.8
	light.omni_range = 4.5
	drone.add_child(light)
	add_child(drone)


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


# One winking green LED per bot, scattered over the district's buildings —
# the city visibly becomes yours as the botnet grows.
func _add_botnet_glow() -> void:
	if _buildings.is_empty() or GameState.botnet_size <= 0:
		return
	var count := mini(GameState.botnet_size, _buildings.size() * 4)
	for i in count:
		var b: Dictionary = _buildings[i % _buildings.size()]
		var half_w: float = 1.2 if b.tall else 1.0
		var max_y: float = 3.4 if b.tall else 1.5
		var led := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.1, 0.1, 0.06)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.494, 0.906, 0.529)
		mat.emission_enabled = true
		mat.emission = Color(0.494, 0.906, 0.529)
		mat.emission_energy_multiplier = 2.0
		bm.material = mat
		led.mesh = bm
		led.position = Vector3(
			randf_range(-half_w * 0.7, half_w * 0.7),
			randf_range(0.5, max_y),
			half_w + 0.04)
		(b.node as Node3D).add_child(led)
		var wink := led.create_tween().set_loops()
		wink.tween_interval(randf_range(0.5, 2.4))
		wink.tween_property(led, "transparency", 0.9, 0.18)
		wink.tween_property(led, "transparency", 0.0, 0.18)


# --- chunk kit (Alive City phase 3) -------------------------------------------
# Stamp a row of skyline buildings along an edge with one call, so enlarging
# a district is data, not dozens of hand-placed props. `kinds` cycles through
# "tower"/"shop"; each building sits on its own ground patch.
func _skyline_row(start: Vector2, step: Vector2, n: int, kinds: Array, yaw := 0.0) -> void:
	for i in n:
		var pos := start + step * i
		_patch(pos - Vector2(1.6, 1.6), Vector2(3.2, 3.2), GROUND_COLOR)
		var scene: String = TOWER_SCENE if kinds[i % kinds.size()] == "tower" else SHOP_BLDG_SCENE
		_prop(scene, pos, yaw)


# A back-street strip: darker pavement, walled on the far side. Pure layout.
func _back_street(pos: Vector2, size: Vector2) -> void:
	_patch(pos, size, Color(0.06, 0.066, 0.082))
	_wall(pos.x, pos.y - 0.2, size.x, 0.2)


# Is the city in its late-night phase? The "clock" is energy: fresh after
# sleep = day, running on fumes = deep night (matches the daylight tween).
func is_night() -> bool:
	return GameState.energy <= int(GameState.max_energy * 0.3)


# Drops a roll-down shutter + "CLOSED" sign over a stall when it's night, and
# returns whether the stall is shut (callers can gate or reflavor). Stalls
# keep working — this is schedule flavor, not a lockout.
func _night_shutter(pos: Vector2, w := 1.8) -> bool:
	if not is_night():
		return false
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w, 0.9, 0.05)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.13, 0.16)
	mat.roughness = 0.6
	bm.material = mat
	m.mesh = bm
	m.position = Vector3(pos.x, 0.95, pos.y + 0.42)
	add_child(m)
	_sign("CLOSED · back at dawn", pos, 1.6, 28)
	return true


func _search_trash(id: String, pile: Area3D) -> void:
	if GameState.trash_searched.has(id):
		GameState.notify("Picked clean. Check back tomorrow.", GameState.COL_WARN)
		return
	if not GameState.use_energy(1):
		return
	GameState.trash_searched[id] = true
	var t: Dictionary = GameData.trash_table(main.current_district_id)
	var item_id: String = t.pool.pick_random()
	var scrap := int(round(randi_range(t.scrap[0], t.scrap[1]) * GameState.hustle_mult()
			* GameState.daily_mult("scrap", main.current_district_id)
			* GameState.mastery_mult("scrap") * GameState.background_scrap_mult()))
	GameState.add_mastery(main.current_district_id)
	GameState.add_item(item_id)
	GameState.add_cash(scrap)
	var msg := "Found %s! (+$%d scrap)" % [GameData.ITEMS[item_id]["name"], scrap]
	# Rare find on top — the reason to keep digging.
	if randf() < float(t.rare_chance):
		var rare_id: String = t.rare.pick_random()
		GameState.add_item(rare_id)
		msg += "   ✦ RARE: %s ($%d)!" % [GameData.ITEMS[rare_id]["name"], GameData.ITEMS[rare_id]["price"]]
	GameState.notify(msg, GameState.COL_GOOD)
	pile.set_dim(true)
