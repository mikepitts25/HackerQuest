extends "res://scripts/iso/district_3d.gd"
## The Underpass in 3D — beneath the expressway deck. E-waste motherlode (six
## piles scattered across the lot), neon graffiti on the pillars, a grimy food
## cart, and a locked stash that isn't yours. Yet. Ozark runs scrap bounties
## from the shadows under the deck. Big City pass: ~10x footprint.


func _build() -> void:
	area_size = Vector2(48, 35)

	_ground(Color(0.066, 0.07, 0.082))
	_patch(Vector2(1, 14), Vector2(46, 6), Color(0.052, 0.055, 0.065))  # deck shadow band
	_border()

	_sign("THE UNDERPASS", Vector2(8, 2.5), 2.4, 64)
	_sign("keep your voice down", Vector2(8, 4), 1.6, 28)

	# The expressway deck overhead, on concrete pillars marching the length.
	_slab(Vector2(0, 14), Vector2(48, 6), 0.4, 2.9, Color(0.08, 0.085, 0.1))
	for px in [6.0, 16.0, 26.0, 36.0]:
		_wall(px, 16.0, 1.0, 1.0, 2.75)
		_graffiti(Vector2(px + 0.5, 17.2), Color(1, 0.243, 0.784) if int(px) % 12 == 0 else Color(0.494, 0.906, 0.529))

	# The motherlode — six piles scattered across the lot (same save ids; only
	# their positions moved, north and south of the deck shadow).
	_trash_pile("underpass_trash_0", Vector2(6, 7))
	_trash_pile("underpass_trash_1", Vector2(18, 5))
	_trash_pile("underpass_trash_2", Vector2(32, 8))
	_trash_pile("underpass_trash_3", Vector2(10, 28))
	_trash_pile("underpass_trash_4", Vector2(26, 30))
	_trash_pile("underpass_trash_5", Vector2(40, 27))

	_box_interactable("Inspect crate", Vector2(42, 16.5), Vector3(0.8, 0.6, 0.6),
			Color(0.29, 0.23, 0.35), "???",
			func() -> void: GameState.notify("A padlocked crate. Somebody's stash — not yours. Yet.", GameState.COL_WARN))

	# A greasy cart slings noodles to the night crowd. Ozark works scrap bounties
	# from the shadows under the deck — shady, off to the side.
	_eatery("Underpass Cart", Vector2(20, 24), 7, 3, Color(0.7, 0.5, 0.3), 0)
	_npc_overrides = {"ozark": Vector2(40, 17)}
	_spawn_npcs("underpass")  # roamers (e.g. Glitch) may be visiting

	_billboard(Vector2(14, 2), 0)
	_billboard(Vector2(38, 33), 180)
	for p in [Vector2(8, 22), Vector2(24, 11), Vector2(34, 24), Vector2(44, 8)]:
		_streetlamp(p, Color(0.6, 0.85, 1.0))

	# A makeshift memorial tucked south of the deck — the underpass's quiet landmark.
	_statue(Vector2(32, 28), "FOR THE\nLOST", Color(0.6, 0.85, 1.0))

	# Shady life under the deck: camps, fires, carts, and little crime tableaux.
	for camp in [[5.0, 21.7, 0.0], [15.0, 22.8, 12.0], [36.0, 21.5, -8.0], [43.0, 12.0, 180.0]]:
		_encampment(Vector2(camp[0], camp[1]), camp[2])
	for cart in [[8.5, 25.5, -20.0], [22.0, 7.3, 15.0], [30.5, 25.5, 35.0], [44.0, 23.3, -35.0]]:
		_shopping_cart(Vector2(cart[0], cart[1]), cart[2])
	for fire in [Vector2(12.5, 16.7), Vector2(35.0, 16.6), Vector2(43.5, 28.6)]:
		_dumpster_fire(fire)
	_crime_vignette(Vector2(12.0, 12.0), "shakedown", 25.0)
	_crime_vignette(Vector2(30.0, 12.2), "handoff", -20.0)
	_crime_vignette(Vector2(41.0, 20.8), "lookout", 180.0)

	# Scrubby trees that took root at the edges (kept clear of the deck overhead).
	for p in [Vector2(4, 10), Vector2(46, 30), Vector2(6, 32), Vector2(46, 10)]:
		_tree(p, randf_range(0.8, 1.05))

	# A colony of strays living under the bridge — cats among the junk, a drone.
	_stray(Vector2(10, 10), "cat", 7.0)
	_stray(Vector2(34, 10), "cat", 7.0)
	_stray(Vector2(14, 26), "cat", 7.0)
	_stray(Vector2(38, 28), "cat", 6.0)
	_stray(Vector2(24, 24), "bird", 8.0)

	# Tenements crowding the expressway on both sides — buildings to frame the lot.
	_skyline_row(Vector2(6, -3.5), Vector2(6.0, 0), 7, ["shop", "tower"])       # north
	_skyline_row(Vector2(6, 38.5), Vector2(6.0, 0), 7, ["tower", "shop"], 180)  # south

	_exit("Plaza", Vector2(47, 17), "plaza", "from_underpass", 90)
	_spawn_wanderers("underpass")

	_mark("from_plaza", Vector2(44, 17))


# Glowing tag on a pillar face — pure flavor.
func _graffiti(pos: Vector2, color: Color) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.7, 0.5, 0.03)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.4
	bm.material = mat
	m.mesh = bm
	m.position = Vector3(pos.x, 1.1, pos.y)
	add_child(m)


func _encampment(pos: Vector2, yaw_deg := 0.0) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(pos.x, 0, pos.y)
	holder.rotation.y = deg_to_rad(yaw_deg)
	holder.add_to_group("underpass_encampment")
	add_child(holder)
	_underpass_box(holder, Vector3(1.5, 0.08, 0.75), Vector3(0, 0.04, 0), Color(0.24, 0.12, 0.09))
	_underpass_box(holder, Vector3(1.1, 0.06, 0.55), Vector3(0.15, 0.11, -0.04), Color(0.32, 0.26, 0.18))
	_underpass_box(holder, Vector3(1.2, 0.9, 0.07), Vector3(-0.45, 0.45, -0.55), Color(0.30, 0.23, 0.14))
	_underpass_box(holder, Vector3(0.55, 0.45, 0.45), Vector3(0.55, 0.23, -0.45), Color(0.16, 0.13, 0.10))
	_person_silhouette(holder, Vector3(-0.15, 0, 0.45), Color(0.18, 0.17, 0.18), true)


func _shopping_cart(pos: Vector2, yaw_deg := 0.0) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(pos.x, 0, pos.y)
	holder.rotation.y = deg_to_rad(yaw_deg)
	holder.add_to_group("underpass_cart")
	add_child(holder)
	var metal := Color(0.42, 0.45, 0.46)
	_underpass_box(holder, Vector3(0.9, 0.05, 0.65), Vector3(0, 0.45, 0), metal)
	_underpass_box(holder, Vector3(0.08, 0.55, 0.65), Vector3(-0.45, 0.3, 0), metal)
	_underpass_box(holder, Vector3(0.08, 0.55, 0.65), Vector3(0.45, 0.3, 0), metal)
	_underpass_box(holder, Vector3(0.9, 0.55, 0.06), Vector3(0, 0.3, -0.33), metal)
	_underpass_box(holder, Vector3(0.9, 0.08, 0.06), Vector3(0, 0.72, 0.38), metal)
	for x in [-0.32, 0.32]:
		for z in [-0.25, 0.25]:
			_underpass_box(holder, Vector3(0.12, 0.12, 0.12), Vector3(x, 0.06, z), Color(0.06, 0.06, 0.07))


func _dumpster_fire(pos: Vector2) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(pos.x, 0, pos.y)
	holder.add_to_group("underpass_fire")
	add_child(holder)
	_underpass_box(holder, Vector3(1.4, 0.75, 0.9), Vector3(0, 0.38, 0), Color(0.10, 0.13, 0.13))
	_underpass_box(holder, Vector3(1.5, 0.12, 0.95), Vector3(0, 0.82, 0), Color(0.05, 0.06, 0.06))
	for i in 3:
		var flame := _underpass_box(holder, Vector3(0.22, 0.65 - i * 0.1, 0.22), Vector3(-0.25 + i * 0.25, 1.0 + i * 0.08, 0.0),
				Color(1.0, 0.35 + i * 0.16, 0.08), true)
		flame.rotation.y = randf_range(-0.4, 0.4)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.42, 0.14)
	light.light_energy = 1.4
	light.omni_range = 6.0
	light.position = Vector3(0, 1.2, 0)
	holder.add_child(light)


func _crime_vignette(pos: Vector2, kind: String, yaw_deg := 0.0) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(pos.x, 0, pos.y)
	holder.rotation.y = deg_to_rad(yaw_deg)
	holder.add_to_group("underpass_crime")
	add_child(holder)
	match kind:
		"shakedown":
			_person_silhouette(holder, Vector3(-0.35, 0, 0), Color(0.12, 0.11, 0.13), false)
			_person_silhouette(holder, Vector3(0.45, 0, 0.2), Color(0.22, 0.16, 0.12), true)
			_underpass_box(holder, Vector3(0.32, 0.08, 0.12), Vector3(0.0, 1.05, 0.03), Color(0.65, 0.66, 0.6))
			_sign("PAY UP", pos + Vector2(0.0, -0.8), 1.8, 20)
		"handoff":
			_person_silhouette(holder, Vector3(-0.35, 0, 0), Color(0.10, 0.13, 0.16), false)
			_person_silhouette(holder, Vector3(0.35, 0, 0), Color(0.18, 0.12, 0.20), false)
			_underpass_box(holder, Vector3(0.22, 0.12, 0.18), Vector3(0.0, 0.8, 0.0), Color(0.52, 0.38, 0.14), true)
		_:
			_person_silhouette(holder, Vector3(0, 0, 0), Color(0.13, 0.14, 0.13), false)
			_underpass_box(holder, Vector3(0.5, 0.06, 0.08), Vector3(0.0, 1.1, -0.28), Color(0.8, 0.12, 0.12), true)
			_sign("LOOKOUT", pos + Vector2(0.2, -0.7), 1.8, 20)


func _person_silhouette(parent: Node3D, pos: Vector3, color: Color, seated := false) -> void:
	var body_h := 0.55 if seated else 0.9
	_underpass_box(parent, Vector3(0.28, body_h, 0.22), pos + Vector3(0, 0.38 if seated else 0.55, 0), color)
	_underpass_box(parent, Vector3(0.24, 0.24, 0.24), pos + Vector3(0, 0.82 if seated else 1.15, 0.01), color.lightened(0.08))
	if seated:
		_underpass_box(parent, Vector3(0.55, 0.18, 0.25), pos + Vector3(0, 0.16, 0.22), color.darkened(0.1))


func _underpass_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, emissive := false) -> MeshInstance3D:
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
	m.position = pos
	parent.add_child(m)
	return m
