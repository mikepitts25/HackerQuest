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
	_sign("NO CAMS · NO LOGS", Vector2(9, 5.3), 1.4, 26)
	_sign("RIG HALL", Vector2(42, 2.5), 1.8, 36)
	_sign("TIME · $5/HR\nCASH ONLY · BYO RIG", Vector2(14, 13), 1.9, 24)

	var contracts := _prop(JOB_BOARD_SCENE, Vector2(24, 9))
	_interact(contracts, "Contracts", Vector3(1.5, 1.5, 0.4),
			func() -> void: main.open_contracts())
	_collider(Vector2(24, 9), Vector3(1.5, 1.5, 0.3))

	# Back-room rigs — rows of them humming in the dark.
	for i in 12:
		var pos := Vector2(42.0 + (i % 2) * 6.0, 8.0 + floorf(i / 2.0) * 4.5)
		_prop(RACK_SCENE, pos)
		_collider(pos, Vector3(0.7, 1.5, 0.55))

	# The café floor proper: banks of pay-by-the-hour booths, monitors glowing in
	# the dark, half of them hunched over by anonymous patrons. This is what makes
	# the place read as an internet café rather than a back room — rows of screens
	# the only real light. Glows cycle through the club's cyan/teal with the odd
	# magenta rig. Every third booth gets a real light so the floor isn't pitch.
	var screen_glows := [
		Color(0.2, 1.0, 0.7), Color(0.3, 0.85, 1.0),
		Color(0.5, 0.9, 0.6), Color(0.9, 0.3, 0.9),
	]
	var station := 0
	# Left-wall row, screens facing into the room.
	for z in [12.5, 15.5, 18.5, 21.5, 24.5]:
		station += 1
		_workstation(Vector2(6.5, z), 90, screen_glows[station % screen_glows.size()],
				station % 2 == 0, station % 3 == 0, "%02d" % station)
	# Right-wall row, facing back across the floor.
	for z in [12.0, 15.0, 18.0, 21.0]:
		station += 1
		_workstation(Vector2(35.5, z), -90, screen_glows[station % screen_glows.size()],
				station % 2 == 0, station % 3 == 0, "%02d" % station)
	# A short bottom row tucked under the back wall, patrons facing in.
	for x in [9.0, 11.5, 14.0]:
		station += 1
		_workstation(Vector2(x, 32.5), 180, screen_glows[station % screen_glows.size()],
				station % 2 == 0, station % 3 == 0, "%02d" % station)
	# Two "operator" desks down in the rig hall — the serious seats, magenta-lit.
	_workstation(Vector2(43, 32), 180, Color(0.9, 0.3, 0.9), true, true, "OP1")
	_workstation(Vector2(50, 32), 180, Color(0.9, 0.3, 0.9), false, true, "OP2")

	# Drinks coolers — fuel stocked along the café walls.
	_vending_machine(Vector2(6, 9), 90, Color(0.3, 0.85, 1.0), "COLD BYTES")
	_vending_machine(Vector2(36, 10), -90, Color(0.9, 0.4, 0.5), "CHARGE")

	# Tangles of floor cabling feeding the booths and the rig hall.
	_cable_run(Vector2(8, 18.5), 13, 90, Color(0.2, 0.95, 0.7))
	_cable_run(Vector2(45, 19), 22, 90, Color(0.5, 0.4, 0.95))

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

	# An underground shrine to the scene's origins — the café's landmark.
	_statue(Vector2(20, 30), "THE FIRST\nEXPLOIT", Color(0.2, 1.0, 0.7))

	# Dim potted trees softening the café floor corners.
	for p in [Vector2(8, 30), Vector2(34, 28), Vector2(10, 6), Vector2(34, 6)]:
		_tree(p, randf_range(0.8, 1.0))

	# Alley cats prowling the café floor and a glitchy drone overhead.
	_stray(Vector2(16, 32), "cat", 7.0)
	_stray(Vector2(30, 14), "cat", 6.0)
	_stray(Vector2(24, 16), "bird", 7.0)

	_exit("Corp Row", Vector2(1, 21), "corp_row", "from_darknet", 90)
	_exit("Drowned Quarter", Vector2(57, 21), "drowned_quarter", "from_darknet", 90)
	_spawn_wanderers("darknet")

	_mark("from_corp", Vector2(4, 21))
	_mark("from_drowned", Vector2(54, 21))

	# Sparse, seedy late-night traffic skirting the cafe (G7).
	_ring_road(-1.4, 4, 2.8, Color(0.32, 0.16, 0.18))
