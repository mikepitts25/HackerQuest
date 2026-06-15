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


func _build() -> void:
	area_size = Vector2(10.3, 8.5)

	_ground()
	_patch(Vector2(1, 1), Vector2(8.3, 5.5), Color(0.21, 0.18, 0.15))  # apartment floor
	_border()

	# Apartment walls with a door gap at the bottom (x 4.5..5.8).
	_wall(1, 0.8, 8.3, 0.2)
	_wall(0.8, 1, 0.2, 5.5)
	_wall(9.3, 1, 0.2, 5.5)
	_wall(1, 6.5, 3.5, 0.2)
	_wall(5.8, 6.5, 3.5, 0.2)

	_sign("APT 4B", Vector2(2.3, 0.8), 1.6, 44)

	var bed := _prop(BED_SCENE, Vector2(2.2, 2.5))
	_interact(bed, "Sleep", Vector3(0.9, 0.6, 1.8),
			func() -> void: main.do_sleep())
	_collider(Vector2(2.2, 2.5), Vector3(0.95, 0.5, 1.85))

	var desk := _prop(DESK_SCENE, Vector2(7, 1.8))
	_interact(desk, "Use desk", Vector3(1.4, 1.0, 0.7),
			func() -> void: main.use_desk())
	_collider(Vector2(7, 1.8), Vector3(1.4, 0.6, 0.65))

	_box_interactable("Browse rentals", Vector2(8.4, 5.9), Vector3(0.8, 1.1, 0.25),
			Color(0.48, 0.43, 0.29), "VACANCIES",
			func() -> void: main.open_apartments())

	_box_interactable("Furnish your place", Vector2(1.6, 5.9), Vector3(0.8, 1.1, 0.25),
			Color(0.40, 0.32, 0.48), "FURNISH",
			func() -> void: main.open_furnish())

	_render_furniture()
	_render_trophies()

	_exit("Plaza", Vector2(5.15, 7.6), "plaza", "from_home")
	# Strangers stay on the street outside — nobody wanders into APT 4B.
	wander_zone = Rect2(0.6, 6.9, 9.1, 1.2)
	_spawn_wanderers("home")

	_mark("start", Vector2(3.8, 3.8))       # new-game spawn, inside the apartment
	_mark("from_plaza", Vector2(5.15, 6.9))  # arriving back from the plaza


# Stamp a colored box for each piece of furniture you own. Decor only — no
# colliders, so you never get trapped behind the couch.
func _render_furniture() -> void:
	for id in GameState.owned_furniture:
		if not FURNITURE_VISUALS.has(id):
			continue
		var v: Dictionary = FURNITURE_VISUALS[id]
		var size: Vector3 = v.size
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		var mat := StandardMaterial3D.new()
		mat.albedo_color = v.color
		mat.roughness = 0.85
		if v.get("emissive", false):
			mat.emission_enabled = true
			mat.emission = v.color
			mat.emission_energy_multiplier = 1.6
		bm.material = mat
		m.mesh = bm
		var y: float = v.get("y", size.y / 2.0)
		m.position = Vector3(v.pos.x, y, v.pos.y)
		add_child(m)


# A shelf on the back wall with a glowing token for each milestone you've hit.
func _render_trophies() -> void:
	var earned: Array = GameState.trophies()
	if earned.is_empty():
		return
	var shelf := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(2.8, 0.06, 0.32)
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.15, 0.13, 0.11)
	sm.material = smat
	shelf.mesh = sm
	shelf.position = Vector3(2.6, 1.55, 1.25)
	add_child(shelf)
	_sign("TROPHIES", Vector2(2.6, 1.25), 1.95, 20)
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
		t.position = Vector3(1.45 + i * 0.42, 1.73, 1.25)
		add_child(t)
