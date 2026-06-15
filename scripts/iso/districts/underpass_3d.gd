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
