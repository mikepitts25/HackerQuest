extends "res://scripts/district.gd"
## The Underpass — beneath the expressway. E-waste motherlode and deals best
## not asked about. Early-economy district: more scavenge piles than the
## market, and a locked stash that isn't yours. Yet.


func _build() -> void:
	area_size = Vector2(800, 720)

	_floor(Vector2.ZERO, area_size, Color("1b1c20"))
	_floor(Vector2(0, 260), Vector2(800, 200), Color("141518"))  # shadow of the road deck
	_border()

	# Expressway pillars.
	_wall(180, 300, 80, 120)
	_wall(420, 300, 80, 120)

	_sign("THE UNDERPASS", Vector2(120, 50), 26)
	_sign("keep your voice down", Vector2(130, 92), 14)

	_trash_pile("underpass_trash_0", Vector2(140, 180))
	_trash_pile("underpass_trash_1", Vector2(560, 160))
	_trash_pile("underpass_trash_2", Vector2(300, 560))
	_trash_pile("underpass_trash_3", Vector2(620, 580))

	_interactable("Inspect crate", Vector2(660, 330), Vector2(70, 56), Color("4a3a5a"), "???",
			func() -> void: GameState.notify("A padlocked crate. Somebody's stash — not yours. Yet.", GameState.COL_WARN))

	_exit("Plaza", Vector2(740, 380), Vector2(46, 110), "plaza", "from_underpass")
	_spawn_wanderers("underpass")

	_mark("from_plaza", Vector2(680, 380))
