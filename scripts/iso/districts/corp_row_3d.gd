extends "res://scripts/iso/district_3d.gd"
## Corp Row in 3D — glass towers and server farms. Unlocks at Black Hat
## status. Cipher works here; doors to the Market and the Darknet Café.


func _build() -> void:
	area_size = Vector2(20, 14)

	_ground(Color(0.083, 0.092, 0.11))
	_patch(Vector2(1.5, 1.5), Vector2(7, 5), Color(0.1, 0.118, 0.148))      # lobby plaza
	_patch(Vector2(11, 1.5), Vector2(7.5, 11), Color(0.088, 0.103, 0.128))  # server hall
	_back_street(Vector2(1.5, 8), Vector2(8, 1.2))                          # loading dock
	_border()

	_sign("CORP ROW", Vector2(2.7, 0.8), 2.3, 60)
	_sign("DATACENTER", Vector2(12, 1.9), 1.7, 36)

	var board := _prop(JOB_BOARD_SCENE, Vector2(4, 3.2))
	_interact(board, "Corp gigs", Vector3(1.5, 1.5, 0.4),
			func() -> void: main.show_jobs("corp"))
	_collider(Vector2(4, 3.2), Vector3(1.5, 1.5, 0.3))

	# Server farm — a fuller grid of humming racks in the datacenter hall.
	for i in 12:
		var pos := Vector2(11.8 + (i % 3) * 2.4, 3.0 + floorf(i / 3.0) * 2.3)
		_prop(RACK_SCENE, pos)
		_collider(pos, Vector3(0.7, 1.5, 0.55))

	_spawn_npcs("corp_row")  # Cipher
	_spawn_wanderers("corp_row")

	_exit("Market", Vector2(0.85, 7), "market", "from_corp", 90)
	_exit("Darknet Cafe", Vector2(19.2, 7), "darknet", "from_corp", 90)

	_mark("from_market", Vector2(2, 7))
	_mark("from_darknet", Vector2(18.2, 7))

	# Glass towers ringing the row — chunk-kit skyline.
	_skyline_row(Vector2(3.5, -2), Vector2(3.8, 0), 5, ["tower"])

	# Sleek corporate sedans gliding the row (G7) — dark, cyan-lit, quick.
	_ring_road(-1.1, 3, 3.6, Color(0.16, 0.2, 0.26))
