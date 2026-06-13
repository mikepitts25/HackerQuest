extends "res://scripts/district.gd"
## The Block — your apartment. Bed (sleep), desk (terminal), and the door out
## to the Plaza.


func _build() -> void:
	area_size = Vector2(820, 680)

	_floor(Vector2.ZERO, area_size, Color("23252b"))                 # street outside
	_floor(Vector2(80, 80), Vector2(660, 440), Color("39322a"))      # apartment floor
	_border()

	# Apartment walls with a door gap at the bottom (x 360..460).
	_wall(80, 64, 660, 16)
	_wall(64, 80, 16, 440)
	_wall(740, 80, 16, 440)
	_wall(80, 520, 280, 16)
	_wall(460, 520, 296, 16)

	_sign("APT 4B", Vector2(110, 36), 22)

	_interactable("Sleep", Vector2(180, 200), Vector2(84, 130), Color("3b5dc9"), "Bed",
			func() -> void: main.do_sleep())
	_interactable("Use desk", Vector2(560, 170), Vector2(90, 64), Color("6b7280"), "Desk",
			func() -> void: main.use_desk())
	_interactable("Browse rentals", Vector2(660, 470), Vector2(70, 50), Color("7a6f4a"), "VACANCIES",
			func() -> void: main.open_apartments())

	# Door out, just below the apartment's bottom gap.
	_exit("Plaza", Vector2(410, 600), Vector2(90, 40), "plaza", "from_home")
	_spawn_wanderers("home")

	_mark("start", Vector2(300, 300))      # new-game spawn, inside the apartment
	_mark("from_plaza", Vector2(410, 560))  # arriving back from the plaza
