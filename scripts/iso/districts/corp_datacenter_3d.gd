extends "res://scripts/iso/district_3d.gd"
## The Corp Datacenter — the server hall that used to sprawl across Corp Row,
## now its own secured interior reached only through the datacenter doors on the
## row. Cold blue light, raised access flooring, rows of humming racks, glowing
## cable runs, and the AXIOM mainframe at the back. No street crowd (it's behind
## a badge reader), no fast-travel stop — you come in from Corp Row and leave the
## same way. Not registered in GameData.DISTRICTS; gated by the row around it.


func _build() -> void:
	area_size = Vector2(42, 30)
	ambient_life_enabled = false  # secured floor — no pedestrians, no boarders

	_ground(Color(0.05, 0.06, 0.085))
	_patch(Vector2(3, 3), Vector2(36, 16), Color(0.07, 0.085, 0.12))   # raised access floor
	_patch(Vector2(3, 21), Vector2(36, 6), Color(0.06, 0.07, 0.095))   # entrance approach
	_border()

	_sign("AXIOM DATACENTER", Vector2(8, 1.6), 2.4, 56)
	_sign("authorized access only", Vector2(8, 3.0), 1.6, 26)
	_sign("COLD AISLE", Vector2(21, 19.5), 1.4, 28)

	# Rows of racks in cold aisles — the servers that no longer clutter the row.
	for i in 28:
		var col := i % 7
		var row := int(i / 7.0)
		var pos := Vector2(6.0 + col * 4.5, 5.5 + row * 3.8)
		_prop(RACK_SCENE, pos)
		_collider(pos, Vector3(0.7, 1.5, 0.55))

	# Glowing cable runs tracing the aisles (the floor "spine" of the hall).
	for z in [7.4, 11.2, 15.0]:
		_glow_strip(Vector2(4, z), Vector2(34, 0.12), Color(0.3, 0.8, 1.0))

	# Cold overhead lighting down the aisles.
	for p in [Vector3(10, 3.4, 8), Vector3(24, 3.4, 8), Vector3(34, 3.4, 12),
			Vector3(14, 3.4, 14), Vector3(28, 3.4, 14)]:
		_cold_light(p)

	# The AXIOM mainframe — a glowing monolith at the back, inspectable flavor.
	_mainframe(Vector2(34, 5))

	# Door back out to the row (you can only have arrived from there).
	_exit("Corp Row", Vector2(21, 28.6), "corp_row", "from_datacenter", 0)

	_mark("from_corp", Vector2(21, 25))


# A flat emissive cable run on the floor.
func _glow_strip(pos: Vector2, size: Vector2, color: Color) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(size.x, 0.05, size.y)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.4
	bm.material = mat
	m.mesh = bm
	m.position = Vector3(pos.x + size.x / 2.0, 0.04, pos.y + size.y / 2.0)
	add_child(m)


func _cold_light(pos: Vector3) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = Color(0.6, 0.85, 1.0)
	l.light_energy = 1.5
	l.omni_range = 9.0
	add_child(l)


# A dark monolith with stacked glowing strips and a hovering core — the heart of
# the hall. Inspecting it is pure flavor for now.
func _mainframe(pos: Vector2) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(pos.x, 0, pos.y)
	add_child(holder)
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.2, 3.4, 1.4)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.065, 0.09)
	mat.metallic = 0.5
	mat.roughness = 0.35
	bm.material = mat
	body.mesh = bm
	body.position.y = 1.7
	holder.add_child(body)
	for y in [0.9, 1.7, 2.5]:
		var strip := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(2.24, 0.12, 1.44)
		var smat := StandardMaterial3D.new()
		var c := Color(0.3, 0.8, 1.0)
		smat.albedo_color = c
		smat.emission_enabled = true
		smat.emission = c
		smat.emission_energy_multiplier = 2.0
		sm.material = smat
		strip.mesh = sm
		strip.position.y = y
		holder.add_child(strip)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 2.6, 1.0)
	light.light_color = Color(0.4, 0.8, 1.0)
	light.light_energy = 2.2
	light.omni_range = 8.0
	holder.add_child(light)
	_collider(pos, Vector3(2.2, 3.4, 1.4))
	_sign("AXIOM CORE", pos, 3.8, 36)
	_interact(holder, "Inspect the mainframe", Vector3(2.4, 2.0, 1.6),
			func() -> void: GameState.notify(
				"The AXIOM core hums behind hardened glass. Every byte Corp Row touches passes through here. Not today.",
				GameState.COL_INFO))
