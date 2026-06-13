extends "res://scripts/iso/district_3d.gd"
## The Underpass in 3D — beneath the expressway deck. E-waste motherlode
## (four piles vs the market's three), neon graffiti on the pillars, and a
## locked stash that isn't yours. Yet.


func _build() -> void:
	area_size = Vector2(15, 11)

	_ground(Color(0.066, 0.07, 0.082))
	_patch(Vector2(0.3, 4.2), Vector2(14.4, 2.6), Color(0.052, 0.055, 0.065))  # deck shadow band
	_border()

	_sign("THE UNDERPASS", Vector2(2.4, 0.8), 2.0, 56)
	_sign("keep your voice down", Vector2(2.3, 1.3), 1.4, 24)

	# The expressway deck overhead, on concrete pillars marching the length.
	_slab(Vector2(0, 4.2), Vector2(15, 2.6), 0.35, 2.9, Color(0.08, 0.085, 0.1))
	for px in [2.2, 6.4, 10.6]:
		_wall(px, 4.6, 0.9, 0.9, 2.75)
		_graffiti(Vector2(px + 0.45, 5.53), Color(1, 0.243, 0.784) if int(px) % 2 == 0 else Color(0.494, 0.906, 0.529))

	# The motherlode — six piles across a longer underpass (new save ids).
	_trash_pile("underpass_trash_0", Vector2(1.8, 2.4))
	_trash_pile("underpass_trash_1", Vector2(5.5, 2.0))
	_trash_pile("underpass_trash_2", Vector2(9.5, 2.3))
	_trash_pile("underpass_trash_3", Vector2(3.2, 9.0))
	_trash_pile("underpass_trash_4", Vector2(8.0, 9.3))
	_trash_pile("underpass_trash_5", Vector2(12.0, 8.8))

	_box_interactable("Inspect crate", Vector2(13.0, 5.1), Vector3(0.8, 0.6, 0.6),
			Color(0.29, 0.23, 0.35), "???",
			func() -> void: GameState.notify("A padlocked crate. Somebody's stash — not yours. Yet.", GameState.COL_WARN))

	_spawn_npcs("underpass")  # roamers (e.g. Glitch) may be visiting

	_exit("Plaza", Vector2(14.2, 6.6), "plaza", "from_underpass", 90)
	_spawn_wanderers("underpass")

	_mark("from_plaza", Vector2(13.2, 6.6))


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
