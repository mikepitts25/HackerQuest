extends "res://scripts/district.gd"
## The Darknet Café — endgame haunt of the truly notorious. Unlocks at Zero Day
## status. Oracle holds court here. Door back to Corp Row.


func _build() -> void:
	area_size = Vector2(1000, 760)

	_floor(Vector2.ZERO, area_size, Color("16121f"))
	_floor(Vector2(140, 120), Vector2(720, 520), Color("221a2e"))   # café floor
	_border()

	_sign("DARKNET CAFE", Vector2(170, 60), 28)
	_sign("members only", Vector2(180, 100), 16)

	_interactable("Contracts", Vector2(620, 240), Vector2(130, 70), Color("8a3a6a"), "CONTRACTS",
			func() -> void: main.open_contracts())

	_spawn_npcs("darknet")  # Oracle
	_spawn_wanderers("darknet")

	_exit("Corp Row", Vector2(60, 360), Vector2(40, 120), "corp_row", "from_darknet")
	_exit("Drowned Quarter", Vector2(900, 360), Vector2(40, 120), "drowned_quarter", "from_darknet")

	_mark("from_corp", Vector2(170, 360))
	_mark("from_drowned", Vector2(840, 360))
