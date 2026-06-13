extends "res://scripts/iso/district_3d.gd"
## The Plaza in 3D — social hub. Job board, the regulars (Pix, Riot, Glitch,
## Marlowe), doors home and to the Market, and a tower skyline.


func _build() -> void:
	area_size = Vector2(22, 15)

	_ground()
	_patch(Vector2(1.5, 1.5), Vector2(19, 12), Color(0.106, 0.122, 0.169))  # plaza pavers
	_back_street(Vector2(1.5, 12.2), Vector2(19, 1.3))  # promenade along the south
	_border()

	_sign("PLAZA", Vector2(2.5, 0.9), 2.3, 64)

	var board := _prop(JOB_BOARD_SCENE, Vector2(7, 3.5))
	_interact(board, "Check jobs", Vector3(1.5, 1.5, 0.4),
			func() -> void: main.show_jobs())
	_collider(Vector2(7, 3.5), Vector3(1.5, 1.5, 0.3))

	# Community board — favors for REP, the Plaza's grind identity.
	_box_interactable("Help out (favors)", Vector2(9.5, 3.5), Vector3(0.9, 1.3, 0.25),
			Color(0.227, 0.651, 0.541), "FAVORS",
			func() -> void: main.open_favors())

	_spawn_npcs("plaza")

	_exit("Home", Vector2(2.2, 13.9), "home", "from_plaza")
	_exit("Market", Vector2(20.4, 7.5), "market", "from_plaza", 90)
	_exit("Underpass", Vector2(0.85, 7.5), "underpass", "from_plaza", 90)
	_spawn_wanderers("plaza")

	_mark("from_home", Vector2(3.5, 12.8))
	_mark("from_market", Vector2(19.4, 7.5))
	_mark("from_underpass", Vector2(1.9, 7.5))

	# Skyline ringing the plaza — one call per edge via the chunk kit.
	_skyline_row(Vector2(3.5, -2), Vector2(3.6, 0), 5, ["tower", "shop"])        # north
	_skyline_row(Vector2(24, 3.5), Vector2(0, 3.8), 3, ["shop", "tower"], 90)    # east

	# Civic traffic circling the plaza (G7).
	_ring_road(-1.1, 4, 3.0, Color(0.42, 0.48, 0.6))
