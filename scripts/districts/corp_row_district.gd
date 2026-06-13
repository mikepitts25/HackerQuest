extends "res://scripts/district.gd"
## Corp Row — glass towers and server farms. Unlocks at Black Hat status.
## Cipher works here, the WiFi is thick, and a door leads to the Darknet Café.


func _build() -> void:
	area_size = Vector2(1100, 800)

	_floor(Vector2.ZERO, area_size, Color("1e2128"))
	_floor(Vector2(120, 120), Vector2(420, 300), Color("232a36"))   # lobby
	_floor(Vector2(640, 120), Vector2(360, 540), Color("202630"))   # server hall
	_border()

	_sign("CORP ROW", Vector2(150, 60), 30)
	_sign("DATACENTER", Vector2(670, 150), 18)

	_interactable("Corp gigs", Vector2(300, 240), Vector2(120, 70), Color("8a5a2b"), "GIG BOARD",
			func() -> void: main.show_jobs("corp"))

	_spawn_npcs("corp_row")  # Cipher
	_spawn_wanderers("corp_row")

	_exit("Market", Vector2(60, 380), Vector2(40, 110), "market", "from_corp")
	_exit("Darknet Cafe", Vector2(1000, 380), Vector2(46, 120), "darknet", "from_corp")

	_mark("from_market", Vector2(160, 380))
	_mark("from_darknet", Vector2(940, 380))
