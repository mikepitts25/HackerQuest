extends "res://scripts/district.gd"
## The Market — commerce and the underbelly. Pawn shop counter, Vex the fence,
## and e-waste piles to scavenge. Door back to the Plaza.


func _build() -> void:
	area_size = Vector2(1100, 800)

	_floor(Vector2.ZERO, area_size, Color("23252b"))
	_floor(Vector2(120, 100), Vector2(520, 360), Color("322a3a"))   # pawn shop floor
	_floor(Vector2(120, 520), Vector2(860, 220), Color("1b1c21"))   # grimy e-waste strip
	_border()

	# Pawn shop walls, door gap at the bottom (x 330..430).
	_wall(120, 84, 520, 16)
	_wall(104, 100, 16, 360)
	_wall(640, 100, 16, 360)
	_wall(120, 460, 210, 16)
	_wall(430, 460, 210, 16)

	_sign("PAWN SHOP", Vector2(150, 50), 22)
	_sign("E-WASTE", Vector2(140, 540), 20)

	_interactable("Browse wares", Vector2(380, 240), Vector2(150, 50), Color("3aa68a"), "Counter",
			func() -> void: main.open_shop())

	_spawn_npcs("market")  # Vex the fence

	_trash_pile("trash_0", Vector2(300, 640))
	_trash_pile("trash_1", Vector2(540, 660))
	_trash_pile("trash_2", Vector2(800, 630))

	_exit("Plaza", Vector2(1040, 240), Vector2(46, 110), "plaza", "from_market")
	_exit("Corp Row", Vector2(1040, 560), Vector2(46, 110), "corp_row", "from_market")
	_spawn_wanderers("market")

	_mark("from_plaza", Vector2(980, 240))
	_mark("from_corp", Vector2(980, 560))
