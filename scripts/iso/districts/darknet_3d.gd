extends "res://scripts/iso/district_3d.gd"
## The Darknet Café in 3D — endgame haunt of the truly notorious. Unlocks at
## Zero Day status. Oracle holds court; the contracts board pays the big jobs.


func _build() -> void:
	area_size = Vector2(18, 13)

	_ground(Color(0.055, 0.045, 0.08))
	_patch(Vector2(1.75, 1.5), Vector2(10, 9.5), Color(0.084, 0.064, 0.115))   # café floor
	_patch(Vector2(12.5, 1.5), Vector2(4, 9.5), Color(0.06, 0.045, 0.09))      # back-room rig hall
	_back_street(Vector2(1.75, 11.5), Vector2(14.75, 1.0))                     # alley out back
	_border()

	_sign("DARKNET CAFE", Vector2(3.1, 0.8), 2.3, 56)
	_sign("members only", Vector2(2.9, 1.3), 1.6, 26)
	_sign("RIG HALL", Vector2(13, 1.9), 1.4, 30)

	var contracts := _prop(JOB_BOARD_SCENE, Vector2(8, 3.2))
	_interact(contracts, "Contracts", Vector3(1.5, 1.5, 0.4),
			func() -> void: main.open_contracts())
	_collider(Vector2(8, 3.2), Vector3(1.5, 1.5, 0.3))

	# Back-room rigs — a wall of them now, humming in the dark.
	for i in 6:
		var pos := Vector2(13.2 + (i % 2) * 2.0, 3.0 + floorf(i / 2.0) * 2.4)
		_prop(RACK_SCENE, pos)
		_collider(pos, Vector3(0.7, 1.5, 0.55))

	_spawn_npcs("darknet")  # Oracle
	_spawn_wanderers("darknet")

	_exit("Corp Row", Vector2(0.85, 6.5), "corp_row", "from_darknet", 90)
	_exit("Drowned Quarter", Vector2(17.2, 6.5), "drowned_quarter", "from_darknet", 90)

	_mark("from_corp", Vector2(2.1, 6.5))
	_mark("from_drowned", Vector2(16, 6.5))

	# Sparse, seedy late-night traffic skirting the cafe (G7).
	_ring_road(-1.0, 2, 2.6, Color(0.32, 0.16, 0.18))
