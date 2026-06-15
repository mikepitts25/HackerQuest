extends "res://scripts/iso/district_3d.gd"
## The Drowned Quarter in 3D — flooded fiber tunnels under the bay, the
## endgame's endgame look: faintly glowing black water between walkways,
## tunnel ribs overhead, half-sunken server racks, fiber conduits tracing
## the floor, and THE TRUNK — a monolith with a floating core — at the end
## of the central walkway.


func _build() -> void:
	area_size = Vector2(40, 32)
	ambient_life_enabled = false

	_ground(Color(0.03, 0.045, 0.055))
	_border()

	# Black water pools flanking the central walkway (glow faintly; collide so
	# you keep your shoes dry). The middle band (z ~12..20) stays dry for the
	# walkway out to the trunk.
	_water(Vector2(3, 3), Vector2(14, 9))
	_water(Vector2(22, 3), Vector2(15, 9))
	_water(Vector2(3, 21), Vector2(14, 8))
	_water(Vector2(22, 21), Vector2(15, 8))

	# Tunnel ribs — beam + pillar pairs over the water (the central walkway
	# stays unroofed so the camera always sees the player).
	for z in [9.0, 22.0]:
		_slab(Vector2(0, z), Vector2(40, 0.9), 0.3, 3.0, Color(0.05, 0.06, 0.075))
		_wall(0.4, z, 0.7, 0.9, 2.85)
		_wall(38.9, z, 0.7, 0.9, 2.85)

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

	# Half-sunken racks, tilted where the water took them.
	for spot in [[8.0, 6.5, 0.14], [30.0, 6.8, -0.1], [31.0, 25.0, 0.18], [7.0, 25.0, -0.12]]:
		var rack := _prop(RACK_SCENE, Vector2(spot[0], spot[1]))
		rack.position.y = -0.5
		rack.rotation.z = spot[2]

	# Fathom — the quarter's lone keeper, standing watch on the dry central
	# walkway between the exit and the Trunk (off the glowing conduit line).
	# The only named soul down here; reads the endgame in her lines.
	_npc_overrides = {"fathom": Vector2(24, 13)}
	_spawn_npcs("drowned_quarter")

	_exit("Darknet Cafe", Vector2(38, 16), "darknet", "from_drowned", 90)

	_mark("from_darknet", Vector2(35, 16))


func _on_trunk() -> void:
	if not GameState.trunk_ready():
		GameState.notify(GameState.final_contract_hint(), GameState.COL_WARN)
		return
	GameState.notify("THE TRUNK recognizes the final contract. The city waits for the next move.", GameState.COL_INFO)


# A pool of black water: sunken glowing slab + a collider so it's impassable.
func _water(pos: Vector2, size: Vector2) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(size.x, 0.06, size.y)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.015, 0.07, 0.095)
	mat.roughness = 0.05
	mat.metallic = 0.4
	mat.emission_enabled = true
	mat.emission = Color(0.05, 0.3, 0.4)
	mat.emission_energy_multiplier = 0.35
	bm.material = mat
	m.mesh = bm
	m.position = Vector3(pos.x + size.x / 2.0, -0.03, pos.y + size.y / 2.0)
	add_child(m)
	_collider(pos + size / 2.0, Vector3(size.x, 0.8, size.y))


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
