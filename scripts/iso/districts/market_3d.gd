extends "res://scripts/iso/district_3d.gd"
## The Market in 3D — commerce and the underbelly. Pawn shop counter, Vex the
## fence, e-waste piles to scavenge (same persistent ids as the 2D market),
## doors to the Plaza and Corp Row.


func _build() -> void:
	area_size = Vector2(20, 14)

	_ground()
	_patch(Vector2(1.5, 1.25), Vector2(9, 6), Color(0.125, 0.105, 0.145))      # pawn shop forecourt
	_patch(Vector2(1.5, 9), Vector2(15.5, 3.6), Color(0.068, 0.072, 0.085))    # grimy e-waste yard
	_back_street(Vector2(11, 1.5), Vector2(7.5, 1.2))                          # vendor alley, north-east
	_border()

	_sign("PAWN SHOP", Vector2(2.7, 0.8), 2.1, 52)
	_sign("E-WASTE", Vector2(2.4, 9.3), 1.4, 40)

	# The shop building looms behind its counter.
	_prop(SHOP_BLDG_SCENE, Vector2(4.75, 1.9))
	_collider(Vector2(4.75, 1.9), Vector3(2, 1.8, 2))

	var counter := _prop(COUNTER_SCENE, Vector2(4.75, 3.8))
	var shut := _night_shutter(Vector2(4.75, 3.8))  # stall keeps odd hours
	_interact(counter, "Browse wares" if not shut else "Knock (after hours)",
			Vector3(1.8, 1.2, 0.8), func() -> void:
				if shut:
					GameState.notify("The pawn shop's shuttered for the night. The owner sighs and lets you in anyway.", GameState.COL_INFO)
				main.open_shop())
	_collider(Vector2(4.75, 3.8), Vector3(1.8, 1.2, 0.7))

	_spawn_npcs("market")  # Vex the fence

	# Goods exchange — buy-low/sell-high commodities, the Market's grind loop.
	_box_interactable("Trade goods", Vector2(8.5, 3.8), Vector3(1.0, 0.8, 0.8),
			Color(0.49, 0.36, 0.2), "GOODS",
			func() -> void: main.open_goods())
	_collider(Vector2(8.5, 3.8), Vector3(1.0, 0.8, 0.7))

	# A bigger yard means more to scavenge (extra piles use new save ids).
	_trash_pile("trash_0", Vector2(3.5, 10.3))
	_trash_pile("trash_1", Vector2(6.5, 11))
	_trash_pile("trash_2", Vector2(9.5, 10.2))
	_trash_pile("market_trash_3", Vector2(12.5, 11))
	_trash_pile("market_trash_4", Vector2(15, 10.4))

	_exit("Plaza", Vector2(19.2, 4), "plaza", "from_market", 90)
	_exit("Corp Row", Vector2(19.2, 10), "corp_row", "from_market", 90)
	_spawn_wanderers("market")

	_mark("from_plaza", Vector2(18.2, 4))
	_mark("from_corp", Vector2(18.2, 10))

	# Tenements ringing the market — chunk-kit skyline.
	_skyline_row(Vector2(3.5, -2), Vector2(3.8, 0), 5, ["shop", "tower"])

	# Delivery vans working the market loop (G7) — warmer, a touch faster.
	_ring_road(-1.1, 4, 3.3, Color(0.6, 0.45, 0.3))
