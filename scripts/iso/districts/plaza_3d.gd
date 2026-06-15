extends "res://scripts/iso/district_3d.gd"
## The Plaza in 3D — social hub. Job board, the regulars (Pix, Riot, Glitch,
## Marlowe, Tess), doors home and to the Market/Underpass, and a tower skyline.
## Big City pass: ~10x the old footprint, with billboards, eateries, and the
## regulars spread out (the shadier ones tucked toward the back).


func _build() -> void:
	area_size = Vector2(70, 48)

	_ground()
	_patch(Vector2(8, 8), Vector2(54, 32), Color(0.106, 0.122, 0.169))  # central pavers
	_back_street(Vector2(6, 42), Vector2(58, 3.2), false)               # south promenade
	_border()

	_sign("PLAZA", Vector2(8, 4.5), 2.6, 80)
	_sign("CENTRAL", Vector2(34, 4.5), 1.8, 40)

	var board := _prop(JOB_BOARD_SCENE, Vector2(24, 12))
	_interact(board, "Check jobs", Vector3(1.5, 1.5, 0.4),
			func() -> void: main.show_jobs())
	_collider(Vector2(24, 12), Vector3(1.5, 1.5, 0.3))

	# Community board — favors for REP, the Plaza's grind identity.
	_box_interactable("Help out (favors)", Vector2(28, 12), Vector3(0.9, 1.3, 0.25),
			Color(0.227, 0.651, 0.541), "FAVORS",
			func() -> void: main.open_favors())
	_box_interactable("Visit pet shop", Vector2(39, 37), Vector3(2.2, 1.2, 1.2),
			Color(0.18, 0.56, 0.54), "PET SHOP",
			func() -> void: main.open_pet_shop())

	# Food on the square — a noodle bar and a coffee cart you can actually use.
	_eatery("Synth-Noodle Bar", Vector2(16, 11), 12, 4, Color(1.0, 0.45, 0.7), 90)
	_eatery("Wired Coffee", Vector2(46, 38), 8, 2, Color(0.85, 0.55, 0.35), 180)

	# The regulars, spread across the square. Mentor/trainer up front; the rival
	# broods off to the side; the broker and the fixer keep to the quiet corners.
	_npc_overrides = {
		"pix": Vector2(30, 18),      # mentor, dead center
		"tess": Vector2(54, 20),     # trainer, east side
		"riot": Vector2(12, 32),     # rival, brooding by the west wall
		"glitch": Vector2(62, 41),   # broker — shady, back of the promenade
		"marlowe": Vector2(60, 11),  # heat fixer — shady, quiet NE corner
	}
	_spawn_npcs("plaza")

	# Lit billboards facing into the square ("pictures" you can read across it).
	_billboard(Vector2(20, 5), 0)
	_billboard(Vector2(50, 5), 0)
	_billboard(Vector2(66, 30), 90)
	_billboard(Vector2(34, 41), 180)

	# Quiet dressing to break up the open ground.
	for p in [Vector2(20, 20), Vector2(40, 20), Vector2(30, 30), Vector2(48, 28),
			Vector2(16, 28), Vector2(52, 14)]:
		_planter(p)
	for p in [Vector2(14, 16), Vector2(56, 34), Vector2(34, 36), Vector2(24, 26)]:
		_streetlamp(p)
	_bench(Vector2(26, 22), 0)
	_bench(Vector2(44, 24), 180)
	_bench(Vector2(38, 16), 90)

	_exit("Home", Vector2(18, 46.5), "home", "from_plaza")
	_exit("Market", Vector2(69, 24), "market", "from_plaza", 90)
	_exit("Underpass", Vector2(1, 24), "underpass", "from_plaza", 90)
	_spawn_wanderers("plaza")

	_mark("from_home", Vector2(18, 43))
	_mark("from_market", Vector2(66, 24))
	_mark("from_underpass", Vector2(4, 24))

	# Skyline ringing the plaza — chunk-kit rows set back for the ring road.
	_skyline_row(Vector2(8, -3.5), Vector2(6.0, 0), 10, ["tower", "shop"])         # north
	_skyline_row(Vector2(73.5, 6), Vector2(0, 6.0), 7, ["shop", "tower"], 90)      # east
	_skyline_row(Vector2(-3.5, 6), Vector2(0, 6.0), 7, ["tower", "shop"], -90)     # west

	# Civic traffic circling the plaza (G7).
	_ring_road(-1.4, 6, 3.4, Color(0.42, 0.48, 0.6))
