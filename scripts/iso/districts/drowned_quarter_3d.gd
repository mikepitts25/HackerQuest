extends "res://scripts/iso/district_3d.gd"
## The Drowned Quarter in 3D — flooded fiber tunnels under the bay, the
## endgame's endgame look: faintly glowing black water between walkways,
## tunnel ribs overhead, half-sunken server racks, fiber conduits tracing
## the floor, and THE TRUNK — a monolith with a floating core — at the end
## of the central walkway.


func _build() -> void:
	area_size = Vector2(40, 32)
	ambient_life_enabled = false
	wander_zone = Rect2(18.0, 12.3, 18.0, 7.4)

	# Recessed basin first, then dry deck patches. The water sits below the deck
	# instead of fighting the floor plane.
	_slab(Vector2.ZERO, area_size, 0.08, -0.16, Color(0.006, 0.014, 0.02))
	_patch(Vector2(0, 0), Vector2(40, 3), Color(0.03, 0.045, 0.055))
	_patch(Vector2(0, 12), Vector2(40, 9), Color(0.035, 0.047, 0.058))
	_patch(Vector2(0, 29), Vector2(40, 3), Color(0.03, 0.045, 0.055))
	_patch(Vector2(0, 3), Vector2(3, 9), Color(0.028, 0.04, 0.052))
	_patch(Vector2(17, 3), Vector2(5, 9), Color(0.028, 0.04, 0.052))
	_patch(Vector2(37, 3), Vector2(3, 9), Color(0.028, 0.04, 0.052))
	_patch(Vector2(0, 21), Vector2(3, 8), Color(0.028, 0.04, 0.052))
	_patch(Vector2(17, 21), Vector2(5, 8), Color(0.028, 0.04, 0.052))
	_patch(Vector2(37, 21), Vector2(3, 8), Color(0.028, 0.04, 0.052))
	_border()

	# Black water pools flanking the central walkway (glow faintly; collide so
	# you keep your shoes dry). The middle band (z ~12..20) stays dry for the
	# walkway out to the trunk.
	_water(Vector2(3, 3), Vector2(14, 9))
	_water(Vector2(22, 3), Vector2(15, 9))
	_water(Vector2(3, 21), Vector2(14, 8))
	_water(Vector2(22, 21), Vector2(15, 8))

	# Broken tunnel ribs at the basin edges. No full-width ceiling beams; the
	# camera needs a clean view of the final walkway.
	for z in [9.0, 22.0]:
		for x in [0.4, 16.2, 22.4, 38.9]:
			_wall(x, z, 0.7, 0.9, 2.65)
			_glow_box(Vector3(x + 0.35, 2.55, z + 0.45), Vector3(0.52, 0.08, 0.52), Color(0.18, 0.75, 0.95), 0.9)

	_sign("DROWNED QUARTER", Vector2(9, 2.0), 2.4, 60)
	_sign("the city's spine runs below", Vector2(9, 3.4), 1.7, 28)

	# THE TRUNK — the monolith every packet in the bay passes through. Anchored
	# at trunk_pos so its hugging glow strips stay correctly placed.
	var trunk_pos := Vector3(8, 0, 16)
	var tx := trunk_pos.x
	var tz := trunk_pos.z

	# Fiber conduits tracing the central walkway from the trunk to the exit.
	var run_cx := (tx + 38.0) / 2.0
	var run_len := 38.0 - tx
	_glow_box(Vector3(run_cx, 0.03, tz - 0.6), Vector3(run_len, 0.05, 0.1), Color(0.3, 0.85, 1.0), 1.6)
	_glow_box(Vector3(run_cx, 0.03, tz + 0.6), Vector3(run_len, 0.05, 0.1), Color(0.7, 0.47, 0.88), 1.6)
	_glow_box(Vector3(tx - 2.6, 0.035, tz), Vector3(4.4, 0.05, 1.9), Color(0.08, 0.38, 0.45), 0.75)
	for vein_z in [13.1, 14.2, 17.8, 18.9]:
		_glow_box(Vector3(20.0, 0.026, vein_z), Vector3(7.2, 0.035, 0.055), Color(0.25, 0.8, 1.0), 0.95)
		_glow_box(Vector3(31.0, 0.026, vein_z), Vector3(5.8, 0.035, 0.055), Color(0.95, 0.45, 0.95), 0.75)

	var trunk := Node3D.new()
	trunk.position = trunk_pos
	add_child(trunk)
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.6, 3.2, 1.6)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.045, 0.06, 0.08)
	mat.roughness = 0.4
	mat.metallic = 0.5
	bm.material = mat
	body.mesh = bm
	body.position.y = 1.6
	trunk.add_child(body)
	_glow_box(Vector3(tx + 0.82, 1.5, tz - 0.35), Vector3(0.04, 2.7, 0.12), Color(0.3, 0.85, 1.0), 2.2)
	_glow_box(Vector3(tx + 0.82, 1.5, tz + 0.35), Vector3(0.04, 2.7, 0.12), Color(0.7, 0.47, 0.88), 2.2)
	_glow_box(Vector3(tx, 1.5, tz + 0.82), Vector3(0.12, 2.7, 0.04), Color(0.3, 0.85, 1.0), 2.2)
	for spike in [Vector3(-1.15, 3.3, -1.15), Vector3(1.15, 3.3, -1.15), Vector3(-1.15, 3.3, 1.15), Vector3(1.15, 3.3, 1.15)]:
		var crown := _glow_box(trunk_pos + spike, Vector3(0.18, 1.4, 0.18), Color(0.42, 0.95, 1.0), 1.4)
		crown.rotation.z = deg_to_rad(12.0 if spike.x < 0.0 else -12.0)
	var core := _glow_box(Vector3(tx, 3.85, tz), Vector3(0.55, 0.55, 0.55), Color(0.75, 0.85, 1.0), 3.0)
	var spin := core.create_tween().set_loops()
	spin.tween_property(core, "rotation:y", TAU, 6.0).from(0.0)
	var bob := core.create_tween().set_loops()
	bob.tween_property(core, "position:y", 4.05, 1.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(core, "position:y", 3.85, 1.6).set_trans(Tween.TRANS_SINE)
	_collider(Vector2(tx, tz), Vector3(1.7, 3.2, 1.7))
	_interact(trunk, GameState.trunk_prompt(), Vector3(1.6, 2.0, 1.6), _on_trunk)

	# Abyssal lighting.
	_omni(Vector3(tx, 3.2, tz), Color(0.45, 0.8, 1.0), 2.6, 9.0)   # trunk core
	_omni(Vector3(27, 2.0, 7.0), Color(0.2, 0.7, 0.85), 1.6, 10.0)
	_omni(Vector3(30, 1.8, 25.0), Color(0.6, 0.4, 0.85), 1.5, 10.0)
	_omni(Vector3(20, 2.0, 16.0), Color(0.3, 0.7, 0.9), 1.4, 10.0)
	_omni(Vector3(13.5, 1.4, 13.0), Color(1.0, 0.32, 0.22), 0.9, 5.5)
	_omni(Vector3(34.5, 1.4, 18.8), Color(1.0, 0.32, 0.22), 0.9, 5.5)

	# Half-sunken racks, tilted where the water took them.
	for spot in [[8.0, 6.5, 0.14], [30.0, 6.8, -0.1], [31.0, 25.0, 0.18], [7.0, 25.0, -0.12]]:
		var rack := _prop(RACK_SCENE, Vector2(spot[0], spot[1]))
		rack.position.y = -0.5
		rack.rotation.z = spot[2]

	for obelisk in [Vector2(18.9, 8.6), Vector2(21.1, 8.6), Vector2(18.9, 23.0), Vector2(21.1, 23.0)]:
		_data_obelisk(obelisk)
	for beacon in [Vector2(13.5, 13.0), Vector2(34.5, 18.8)]:
		_warning_beacon(beacon)
	for rat in [Vector2(19.5, 13.5), Vector2(27.0, 14.0), Vector2(32.5, 18.0), Vector2(21.0, 18.6), Vector2(35.0, 15.5)]:
		_stray(rat, "rat", 2.6)

	# Fathom — the quarter's lone keeper, standing watch on the dry central
	# walkway between the exit and the Trunk (off the glowing conduit line).
	# The only named soul down here; reads the endgame in her lines.
	_npc_overrides = {"fathom": Vector2(24, 13), "riot": Vector2(34, 16)}
	_spawn_npcs("drowned_quarter")

	_exit("Darknet Cafe", Vector2(38, 16), "darknet", "from_drowned", 90)

	_mark("from_darknet", Vector2(35, 16))


func _on_trunk() -> void:
	if not GameState.trunk_ready():
		GameState.notify(GameState.final_contract_hint(), GameState.COL_WARN)
		return
	if main != null and main.has_method("start_combat"):
		main.start_combat("trunk")
	else:
		GameState.notify("THE TRUNK rises from the grid. No avatar left. No mercy left.", GameState.COL_BAD)


# A pool of black water: sunken glowing slab + a collider so it's impassable.
func _water(pos: Vector2, size: Vector2) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(size.x, 0.06, size.y)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.004, 0.045, 0.07)
	mat.roughness = 0.18
	mat.metallic = 0.15
	mat.emission_enabled = true
	mat.emission = Color(0.025, 0.16, 0.22)
	mat.emission_energy_multiplier = 0.5
	bm.material = mat
	m.mesh = bm
	m.position = Vector3(pos.x + size.x / 2.0, -0.07, pos.y + size.y / 2.0)
	add_child(m)
	for i in 4:
		var t := float(i + 1) / 5.0
		var glint_x := pos.x + size.x * t
		var glint_z := pos.y + randf_range(1.0, size.y - 1.0)
		_glow_box(Vector3(glint_x, -0.015, glint_z), Vector3(randf_range(0.65, 1.4), 0.018, 0.035), Color(0.16, 0.72, 0.95), 0.35)
	_collider(pos + size / 2.0, Vector3(size.x, 0.8, size.y))


func _data_obelisk(pos: Vector2) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(pos.x, 0, pos.y)
	add_child(holder)
	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(0.9, 0.22, 0.9)
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.035, 0.045, 0.06)
	base_mat.metallic = 0.35
	base_mat.roughness = 0.55
	base_mesh.material = base_mat
	base.mesh = base_mesh
	base.position.y = 0.11
	holder.add_child(base)
	var shard := _glow_box(Vector3(pos.x, 1.05, pos.y), Vector3(0.24, 1.9, 0.24), Color(0.65, 0.35, 1.0), 1.35)
	shard.rotation.y = randf_range(-0.45, 0.45)
	shard.rotation.z = randf_range(-0.08, 0.08)
	_collider(pos, Vector3(0.75, 1.2, 0.75))


func _warning_beacon(pos: Vector2) -> void:
	var post := _glow_box(Vector3(pos.x, 0.7, pos.y), Vector3(0.16, 1.35, 0.16), Color(1.0, 0.22, 0.15), 1.1)
	post.rotation.y = randf_range(-0.25, 0.25)
	_glow_box(Vector3(pos.x, 1.45, pos.y), Vector3(0.7, 0.1, 0.7), Color(1.0, 0.22, 0.15), 1.8)
	_sign("NO HUMAN\nMAINTENANCE", pos + Vector2(0.2, -0.35), 2.1, 22)


func _glow_box(pos: Vector3, size: Vector3, color: Color, energy: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	bm.material = mat
	m.mesh = bm
	m.position = pos
	add_child(m)
	return m


func _omni(pos: Vector3, color: Color, energy: float, range_m: float) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = range_m
	add_child(l)
