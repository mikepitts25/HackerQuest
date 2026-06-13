extends "res://scripts/iso/district_3d.gd"
## The Drowned Quarter in 3D — flooded fiber tunnels under the bay, the
## endgame's endgame look: faintly glowing black water between walkways,
## tunnel ribs overhead, half-sunken server racks, fiber conduits tracing
## the floor, and THE TRUNK — a monolith with a floating core — at the end
## of the central walkway.


func _build() -> void:
	area_size = Vector2(12.5, 10)

	_ground(Color(0.03, 0.045, 0.055))
	_border()

	# Black water pools (glow faintly; collide so you keep your shoes dry).
	_water(Vector2(1, 1), Vector2(4.7, 3.2))
	_water(Vector2(7, 1), Vector2(4.5, 2.7))
	_water(Vector2(1, 6), Vector2(3.7, 2.5))
	_water(Vector2(7.7, 5.7), Vector2(3.7, 2.7))

	# Tunnel ribs — beam + pillar pairs over the water (the central walkway
	# stays unroofed so the camera always sees the player).
	for z in [2.2, 7.6]:
		_slab(Vector2(0, z), Vector2(12.5, 0.7), 0.3, 3.0, Color(0.05, 0.06, 0.075))
		_wall(0.25, z, 0.6, 0.7, 2.85)
		_wall(11.65, z, 0.6, 0.7, 2.85)

	_sign("DROWNED QUARTER", Vector2(3.2, 0.8), 2.2, 56)
	_sign("the city's spine runs below", Vector2(3.0, 1.3), 1.6, 24)

	# Fiber conduits tracing the central walkway toward the trunk.
	_glow_box(Vector3(7.75, 0.03, 4.34), Vector3(7.1, 0.05, 0.08), Color(0.3, 0.85, 1.0), 1.6)
	_glow_box(Vector3(7.75, 0.03, 5.56), Vector3(7.1, 0.05, 0.08), Color(0.7, 0.47, 0.88), 1.6)

	# THE TRUNK — the monolith every packet in the bay passes through.
	var trunk := Node3D.new()
	trunk.position = Vector3(3.2, 0, 4.95)
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
	_glow_box(Vector3(4.02, 1.5, 4.6), Vector3(0.04, 2.7, 0.12), Color(0.3, 0.85, 1.0), 2.2)
	_glow_box(Vector3(4.02, 1.5, 5.3), Vector3(0.04, 2.7, 0.12), Color(0.7, 0.47, 0.88), 2.2)
	_glow_box(Vector3(3.2, 1.5, 5.77), Vector3(0.12, 2.7, 0.04), Color(0.3, 0.85, 1.0), 2.2)
	var core := _glow_box(Vector3(3.2, 3.85, 4.95), Vector3(0.55, 0.55, 0.55), Color(0.75, 0.85, 1.0), 3.0)
	var spin := core.create_tween().set_loops()
	spin.tween_property(core, "rotation:y", TAU, 6.0).from(0.0)
	var bob := core.create_tween().set_loops()
	bob.tween_property(core, "position:y", 4.05, 1.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(core, "position:y", 3.85, 1.6).set_trans(Tween.TRANS_SINE)
	_collider(Vector2(3.2, 4.95), Vector3(1.7, 3.2, 1.7))
	_interact(trunk, "Jack into the trunk", Vector3(1.6, 2.0, 1.6),
			func() -> void: GameState.notify("The city's spine. Every packet in the bay passes through here. Bring the final contract.", GameState.COL_INFO))

	# Abyssal lighting.
	_omni(Vector3(3.2, 3.2, 4.95), Color(0.45, 0.8, 1.0), 2.6, 7.0)   # trunk core
	_omni(Vector3(8.5, 2.0, 2.3), Color(0.2, 0.7, 0.85), 1.5, 7.0)
	_omni(Vector3(9.5, 1.8, 7.0), Color(0.6, 0.4, 0.85), 1.4, 7.0)

	# Half-sunken racks, tilted where the water took them.
	for spot in [[2.6, 2.1, 0.14], [9.1, 2.2, -0.1], [9.6, 6.9, 0.18], [2.4, 7.0, -0.12]]:
		var rack := _prop(RACK_SCENE, Vector2(spot[0], spot[1]))
		rack.position.y = -0.5
		rack.rotation.z = spot[2]

	_exit("Darknet Cafe", Vector2(11.6, 4.95), "darknet", "from_drowned", 90)
	_spawn_wanderers("drowned_quarter")

	_mark("from_darknet", Vector2(10.6, 4.95))


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
