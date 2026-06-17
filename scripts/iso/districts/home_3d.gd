extends "res://scripts/iso/district_3d.gd"
## The Block — your apartment in 3D. Bed (sleep), desk (terminal), rentals
## board, and the door out to the Plaza. Mirrors home_district.gd at 80px = 1m.


# Where each piece of furniture sits in the room and how it looks (Apartments
# v2). Keyed by GameData.FURNITURE id. `y` overrides the default (size.y/2) for
# wall-mounted (raised) and floor (flat) pieces.
const FURNITURE_VISUALS := {
	"espresso": {"pos": Vector2(5.7, 1.5), "size": Vector3(0.45, 0.5, 0.4), "color": Color(0.18, 0.18, 0.2)},
	"vpn_rack": {"pos": Vector2(8.75, 2.1), "size": Vector3(0.5, 1.4, 0.5), "color": Color(0.1, 0.12, 0.14)},
	"server_closet": {"pos": Vector2(8.75, 3.4), "size": Vector3(0.6, 1.5, 0.6), "color": Color(0.13, 0.15, 0.17)},
	"potted_palm": {"pos": Vector2(1.6, 4.9), "size": Vector3(0.5, 1.0, 0.5), "color": Color(0.2, 0.5, 0.25)},
	"band_posters": {"pos": Vector2(4.3, 1.12), "size": Vector3(1.4, 1.0, 0.05), "color": Color(0.7, 0.3, 0.42), "y": 1.5},
	"shag_rug": {"pos": Vector2(4.7, 4.1), "size": Vector3(2.4, 0.04, 1.8), "color": Color(0.5, 0.2, 0.32), "y": 0.03},
	"neon_sign": {"pos": Vector2(6.3, 1.1), "size": Vector3(1.3, 0.5, 0.07), "color": Color(0.46, 0.9, 1.0), "emissive": true, "y": 1.65},
	"jelly_tank": {"pos": Vector2(1.6, 3.5), "size": Vector3(0.5, 1.1, 0.9), "color": Color(0.3, 0.7, 0.95), "emissive": true},
	"arcade_cab": {"pos": Vector2(8.75, 4.7), "size": Vector3(0.7, 1.5, 0.7), "color": Color(0.8, 0.3, 0.9), "emissive": true},
}

const TROPHY_COLORS := {
	"first_pwn": Color("7adfff"), "first_bot": Color("7ee787"),
	"black_hat": Color("ffd166"), "botnet_swarm": Color("9be9a8"),
	"rival_down": Color("ff6b6b"), "legend": Color("ffe680"),
}

const APARTMENT_LAYOUTS := {
	"apt_4b": {
		"area": Vector2(10.3, 8.5), "shell": Rect2(1, 1, 8.3, 5.5), "door": Vector2(4.5, 5.8),
		"sign": "APT 4B", "sign_pos": Vector2(2.3, 0.8), "floor": Color(0.21, 0.18, 0.15),
		"bed": Vector2(2.2, 2.5), "desk": Vector2(7.0, 1.8), "rentals": Vector2(8.4, 5.9),
		"furnish": Vector2(1.6, 5.9), "exit": Vector2(5.15, 7.6), "start": Vector2(3.8, 3.8),
		"from_plaza": Vector2(5.15, 6.9), "wander": Rect2(0.6, 6.9, 9.1, 1.2),
		"furniture": {},
	},
	"studio_loft": {
		"area": Vector2(13.5, 10.5), "shell": Rect2(1, 1, 11.2, 7.2), "door": Vector2(6.1, 7.4),
		"sign": "STUDIO LOFT", "sign_pos": Vector2(2.7, 0.8), "floor": Color(0.24, 0.21, 0.18),
		"bed": Vector2(3.0, 3.0), "desk": Vector2(9.8, 2.0), "rentals": Vector2(11.1, 7.45),
		"furnish": Vector2(2.0, 7.45), "exit": Vector2(6.75, 9.35), "start": Vector2(5.1, 5.5),
		"from_plaza": Vector2(6.75, 8.35), "wander": Rect2(0.8, 8.7, 11.8, 1.2),
		"furniture": {
			"espresso": Vector2(10.9, 3.2), "vpn_rack": Vector2(11.0, 4.7), "server_closet": Vector2(10.2, 6.2),
			"potted_palm": Vector2(2.0, 6.6), "band_posters": Vector2(5.2, 1.12), "shag_rug": Vector2(5.2, 5.0),
			"neon_sign": Vector2(7.7, 1.12), "jelly_tank": Vector2(2.0, 4.7), "arcade_cab": Vector2(8.6, 6.7),
		},
	},
	"safehouse": {
		"area": Vector2(16.2, 12.2), "shell": Rect2(1, 1, 13.8, 8.8), "door": Vector2(7.1, 8.8),
		"sign": "SAFEHOUSE", "sign_pos": Vector2(3.0, 0.8), "floor": Color(0.16, 0.18, 0.19),
		"bed": Vector2(3.0, 3.1), "desk": Vector2(11.7, 2.2), "rentals": Vector2(13.6, 8.9),
		"furnish": Vector2(2.0, 8.9), "exit": Vector2(8.0, 11.0), "start": Vector2(5.0, 6.2),
		"from_plaza": Vector2(8.0, 10.0), "wander": Rect2(0.9, 10.3, 14.2, 1.2),
		"interior_walls": [Rect2(9.2, 1.2, 0.2, 3.6), Rect2(9.2, 6.1, 0.2, 3.4), Rect2(9.2, 4.8, 2.4, 0.2)],
		"furniture": {
			"espresso": Vector2(12.9, 4.3), "vpn_rack": Vector2(13.4, 2.4), "server_closet": Vector2(13.4, 3.9),
			"potted_palm": Vector2(2.1, 7.6), "band_posters": Vector2(4.8, 1.12), "shag_rug": Vector2(5.7, 6.4),
			"neon_sign": Vector2(7.0, 1.12), "jelly_tank": Vector2(2.2, 5.3), "arcade_cab": Vector2(11.6, 7.8),
		},
	},
	"penthouse": {
		"area": Vector2(19.0, 13.5), "shell": Rect2(1, 1, 16.2, 10.0), "door": Vector2(8.2, 9.7),
		"sign": "SKY PENTHOUSE", "sign_pos": Vector2(3.5, 0.8), "floor": Color(0.22, 0.23, 0.25),
		"bed": Vector2(3.4, 3.1), "desk": Vector2(13.2, 2.2), "rentals": Vector2(15.9, 10.05),
		"furnish": Vector2(2.0, 10.05), "exit": Vector2(9.5, 12.25), "start": Vector2(6.2, 7.0),
		"from_plaza": Vector2(9.5, 11.25), "wander": Rect2(1.0, 11.6, 16.8, 1.2),
		"interior_walls": [Rect2(6.8, 1.2, 0.2, 3.1), Rect2(11.5, 6.4, 0.2, 4.3)],
		"furniture": {
			"espresso": Vector2(15.0, 4.4), "vpn_rack": Vector2(15.3, 2.5), "server_closet": Vector2(16.0, 3.9),
			"potted_palm": Vector2(2.3, 8.9), "band_posters": Vector2(5.0, 1.12), "shag_rug": Vector2(8.8, 7.1),
			"neon_sign": Vector2(9.0, 1.12), "jelly_tank": Vector2(14.9, 7.8), "arcade_cab": Vector2(12.8, 9.3),
		},
	},
}


func _build() -> void:
	var layout := _layout()
	area_size = layout.area

	_ground()
	var shell: Rect2 = layout.shell
	_patch(shell.position, shell.size, layout.floor)
	_border()

	_apartment_walls(shell, layout.door)
	for wall_rect in layout.get("interior_walls", []):
		_wall(wall_rect.position.x, wall_rect.position.y, wall_rect.size.x, wall_rect.size.y)
	_render_tier_details(layout)

	_sign(layout.sign, layout.sign_pos, 1.6, 44)

	var bed := _prop(BED_SCENE, layout.bed)
	_interact(bed, "Sleep", Vector3(0.9, 0.6, 1.8),
			func() -> void: main.do_sleep())
	_collider(layout.bed, Vector3(0.95, 0.5, 1.85))

	var desk := _prop(DESK_SCENE, layout.desk)
	_interact(desk, "Use desk", Vector3(1.4, 1.0, 0.7),
			func() -> void: main.use_desk())
	_collider(layout.desk, Vector3(1.4, 0.6, 0.65))

	_box_interactable("Browse rentals", layout.rentals, Vector3(0.8, 1.1, 0.25),
			Color(0.48, 0.43, 0.29), "VACANCIES",
			func() -> void: main.open_apartments())

	_box_interactable("Furnish your place", layout.furnish, Vector3(0.8, 1.1, 0.25),
			Color(0.40, 0.32, 0.48), "FURNISH",
			func() -> void: main.open_furnish())

	_render_furniture(layout)
	_render_trophies(layout)

	_exit("Plaza", layout.exit, "plaza", "from_home")
	# Strangers stay on the street outside — nobody wanders into APT 4B.
	wander_zone = layout.wander
	_spawn_wanderers("home")

	_mark("start", layout.start)       # new-game spawn, inside the apartment
	_mark("from_plaza", layout.from_plaza)  # arriving back from the plaza


func _layout() -> Dictionary:
	return APARTMENT_LAYOUTS.get(GameState.apartment, APARTMENT_LAYOUTS["apt_4b"])


func _apartment_walls(rect: Rect2, door: Vector2) -> void:
	_wall(rect.position.x, rect.position.y - 0.2, rect.size.x, 0.2)
	_wall(rect.position.x - 0.2, rect.position.y, 0.2, rect.size.y)
	_wall(rect.end.x, rect.position.y, 0.2, rect.size.y)
	_wall(rect.position.x, rect.end.y, door.x - rect.position.x, 0.2)
	_wall(door.y, rect.end.y, rect.end.x - door.y, 0.2)


func _render_tier_details(layout: Dictionary) -> void:
	match GameState.apartment:
		"studio_loft":
			_decor_box(Vector2(6.3, 1.03), Vector3(3.6, 0.06, 0.08), Color(0.5, 0.85, 1.0), true, 1.55)
			_decor_box(Vector2(5.1, 5.5), Vector3(3.4, 0.05, 2.3), Color(0.32, 0.24, 0.18), false, 0.03)
			_home_light(Vector3(8.8, 1.8, 4.7), Color(0.7, 0.85, 1.0), 1.2, 5.5)
		"safehouse":
			_decor_box(Vector2(12.6, 2.8), Vector3(2.4, 0.05, 2.9), Color(0.08, 0.12, 0.14), false, 0.035)
			_decor_box(Vector2(10.7, 4.9), Vector3(1.5, 0.06, 0.08), Color(0.95, 0.25, 0.18), true, 1.35)
			_decor_box(Vector2(4.9, 7.5), Vector3(4.2, 0.05, 1.6), Color(0.12, 0.16, 0.16), false, 0.03)
			_home_light(Vector3(12.5, 1.4, 3.2), Color(0.45, 0.9, 0.75), 1.3, 5.5)
		"penthouse":
			_decor_box(Vector2(8.9, 1.03), Vector3(6.0, 0.06, 0.08), Color(0.7, 0.9, 1.0), true, 1.7)
			_decor_box(Vector2(16.5, 6.6), Vector3(0.08, 0.06, 6.6), Color(0.7, 0.9, 1.0), true, 1.55)
			_decor_box(Vector2(8.5, 7.4), Vector3(5.0, 0.05, 2.8), Color(0.28, 0.22, 0.33), false, 0.03)
			_decor_box(Vector2(13.5, 8.8), Vector3(2.4, 0.45, 1.0), Color(0.18, 0.18, 0.22), false, 0.24)
			_home_light(Vector3(10.5, 2.1, 6.8), Color(0.95, 0.75, 1.0), 1.5, 7.0)
		_:
			_decor_box(Vector2(5.2, 3.9), Vector3(2.1, 0.035, 1.3), Color(0.22, 0.12, 0.1), false, 0.025)


# Stamp a colored box for each piece of furniture you own. Decor only — no
# colliders, so you never get trapped behind the couch.
func _render_furniture(layout: Dictionary) -> void:
	for id in GameState.owned_furniture:
		if not FURNITURE_VISUALS.has(id):
			continue
		var v: Dictionary = FURNITURE_VISUALS[id].duplicate()
		var tier_positions: Dictionary = layout.get("furniture", {})
		if tier_positions.has(id):
			v.pos = tier_positions[id]
		var size: Vector3 = v.size
		var y: float = v.get("y", size.y / 2.0)
		_decor_box(v.pos, size, v.color, v.get("emissive", false), y)


# A shelf on the back wall with a glowing token for each milestone you've hit.
func _render_trophies(layout: Dictionary) -> void:
	var earned: Array = GameState.trophies()
	if earned.is_empty():
		return
	var shell: Rect2 = layout.shell
	var shelf_x: float = shell.position.x + 1.6
	var shelf_z: float = shell.position.y + 0.25
	var shelf := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(2.8, 0.06, 0.32)
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.15, 0.13, 0.11)
	sm.material = smat
	shelf.mesh = sm
	shelf.position = Vector3(shelf_x, 1.55, shelf_z)
	add_child(shelf)
	_sign("TROPHIES", Vector2(shelf_x, shelf_z), 1.95, 20)
	for i in earned.size():
		var c: Color = TROPHY_COLORS.get(earned[i], Color.WHITE)
		var t := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(0.18, 0.3, 0.18)
		var tmat := StandardMaterial3D.new()
		tmat.albedo_color = c
		tmat.emission_enabled = true
		tmat.emission = c
		tmat.emission_energy_multiplier = 1.5
		tm.material = tmat
		t.mesh = tm
		t.position = Vector3(shelf_x - 1.15 + i * 0.42, 1.73, shelf_z)
		add_child(t)


func _decor_box(pos: Vector2, size: Vector3, color: Color, emissive := false, y := -1.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	if emissive:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.6
	bm.material = mat
	m.mesh = bm
	m.position = Vector3(pos.x, size.y / 2.0 if y < 0.0 else y, pos.y)
	add_child(m)
	return m


func _home_light(pos: Vector3, color: Color, energy: float, range_m: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_m
	add_child(light)
