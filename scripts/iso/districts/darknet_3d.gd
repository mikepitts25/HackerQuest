extends "res://scripts/iso/district_3d.gd"
## The Darknet Café in 3D — endgame haunt of the truly notorious. Unlocks at
## Zero Day status. Oracle keeps to the back rig hall (a guide who doesn't sit
## in the window); the contracts board pays the big jobs. Big City pass: ~10x
## footprint, with a roomy café floor, a deep rig hall, and a dim noodle counter.


func _build() -> void:
	area_size = Vector2(58, 42)

	_ground(Color(0.055, 0.045, 0.08))
	_patch(Vector2(5, 4), Vector2(32, 30), Color(0.084, 0.064, 0.115))   # café floor
	_patch(Vector2(40, 4), Vector2(13, 30), Color(0.06, 0.045, 0.09))    # back-room rig hall
	_back_street(Vector2(5, 36), Vector2(48, 3))                         # alley out back
	_border()

	_sign("DARKNET CAFE", Vector2(9, 2.5), 2.6, 64)
	_sign("members only", Vector2(9, 4), 1.7, 30)
	_sign("RIG HALL", Vector2(42, 2.5), 1.8, 36)

	var contracts := _prop(JOB_BOARD_SCENE, Vector2(24, 9))
	_interact(contracts, "Contracts", Vector3(1.5, 1.5, 0.4),
			func() -> void: main.open_contracts())
	_collider(Vector2(24, 9), Vector3(1.5, 1.5, 0.3))

	# Back-room rigs — rows of them humming in the dark.
	for i in 12:
		var pos := Vector2(42.0 + (i % 2) * 6.0, 8.0 + floorf(i / 2.0) * 4.5)
		_prop(RACK_SCENE, pos)
		_collider(pos, Vector3(0.7, 1.5, 0.55))

	# Oracle (endgame guide) holds court at the back of the rig hall — out of
	# sight from the door, as befits the city's most-watched fixer.
	_npc_overrides = {"oracle": Vector2(46, 12)}
	_spawn_npcs("darknet")  # Oracle

	# A dim noodle counter in the café — fuel for the all-nighters.
	_eatery("Zero/One Counter", Vector2(14, 10), 14, 5, Color(0.2, 1.0, 0.7), 90)

	_billboard(Vector2(16, 2), 0, {"slogan": "ZERO/ONE\nclub - all night", "color": Color(0.2, 1.0, 0.7)})
	_billboard(Vector2(30, 35), 180, {"slogan": "DERMA-INK\nget chromed", "color": Color(0.9, 0.3, 0.9)})

	for p in [Vector2(12, 16), Vector2(26, 18), Vector2(18, 26), Vector2(30, 24)]:
		_planter(p)
	for p in [Vector2(10, 12), Vector2(28, 30), Vector2(20, 20)]:
		_streetlamp(p, Color(0.7, 0.4, 0.85))

	_exit("Corp Row", Vector2(1, 21), "corp_row", "from_darknet", 90)
	_exit("Drowned Quarter", Vector2(57, 21), "drowned_quarter", "from_darknet", 90)
	_spawn_wanderers("darknet")

	_mark("from_corp", Vector2(4, 21))
	_mark("from_drowned", Vector2(54, 21))

	# Sparse, seedy late-night traffic skirting the cafe (G7).
	_ring_road(-1.4, 4, 2.8, Color(0.32, 0.16, 0.18))
