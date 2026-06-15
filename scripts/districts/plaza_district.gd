extends "res://scripts/district.gd"
## The Plaza — the social hub. Job board, the regulars (Pix, Riot, Glitch,
## Marlowe), and doors home and to the Market.


func _build() -> void:
	area_size = Vector2(1200, 900)

	_floor(Vector2.ZERO, area_size, Color("23252b"))
	_floor(Vector2(120, 120), Vector2(960, 660), Color("2c2f37"))   # plaza pavers
	_border()

	_sign("PLAZA", Vector2(150, 70), 30)

	_interactable("Check jobs", Vector2(420, 230), Vector2(120, 76), Color("8a5a2b"), "JOB BOARD",
			func() -> void: main.show_jobs())
	_interactable("Visit pet shop", Vector2(760, 620), Vector2(130, 84), Color("2f8f8a"), "PET SHOP",
			func() -> void: main.open_pet_shop())

	_spawn_npcs("plaza")

	_exit("Home", Vector2(120, 820), Vector2(90, 40), "home", "from_plaza")
	_exit("Market", Vector2(1080, 460), Vector2(46, 110), "market", "from_plaza")
	_exit("Underpass", Vector2(60, 460), Vector2(46, 110), "underpass", "from_plaza")
	_spawn_wanderers("plaza")

	_mark("from_home", Vector2(220, 760))
	_mark("from_market", Vector2(1010, 460))
	_mark("from_underpass", Vector2(150, 460))
