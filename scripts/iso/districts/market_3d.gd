extends "res://scripts/iso/district_3d.gd"
## The Market in 3D — commerce and the underbelly. Pawn shop counter, Vex the
## fence (tucked down the back alley where a fence belongs), e-waste piles to
## scavenge (same persistent ids as before), doors to the Plaza and Corp Row.
## Big City pass: ~10x footprint, with a sprawling e-waste yard, food stalls,
## billboards, and the scavenge piles scattered across the lot.


func _build() -> void:
	area_size = Vector2(64, 45)

	_ground()
	_patch(Vector2(5, 4), Vector2(26, 17), Color(0.125, 0.105, 0.145))   # pawn shop forecourt
	_patch(Vector2(5, 26), Vector2(48, 14), Color(0.068, 0.072, 0.085))  # grimy e-waste yard
	_back_street(Vector2(40, 4), Vector2(20, 3.5))                       # vendor alley, north-east
	_border()

	_sign("MARKET", Vector2(8, 2.5), 2.6, 72)
	_sign("PAWN SHOP", Vector2(9, 6.5), 2.0, 48)
	_sign("E-WASTE YARD", Vector2(8, 27), 1.6, 44)

	# The shop building looms behind its counter.
	_prop(SHOP_BLDG_SCENE, Vector2(14, 8))
	_collider(Vector2(14, 8), Vector3(2, 1.8, 2))

	var counter := _prop(COUNTER_SCENE, Vector2(14, 12))
	var shut := _night_shutter(Vector2(14, 12))  # stall keeps odd hours
	_interact(counter, "Browse wares" if not shut else "Knock (after hours)",
			Vector3(1.8, 1.2, 0.8), func() -> void:
				if shut:
					GameState.notify("The pawn shop's shuttered for the night. The owner sighs and lets you in anyway.", GameState.COL_INFO)
				main.open_shop())
	_collider(Vector2(14, 12), Vector3(1.8, 1.2, 0.7))

	# Vex the fence keeps to the back alley; Sparks the parts-buyer works a mid-
	# yard stall. Spread out so the market isn't one clump of regulars.
	_npc_overrides = {
		"vex": Vector2(56, 6),       # data fence — shady, down the vendor alley
		"sparks": Vector2(40, 22),   # parts buyer, mid-lot stall
	}
	_spawn_npcs("market")

	# Goods exchange — buy-low/sell-high commodities, the Market's grind loop.
	_box_interactable("Trade goods", Vector2(24, 12), Vector3(1.0, 0.8, 0.8),
			Color(0.49, 0.36, 0.2), "GOODS",
			func() -> void: main.open_goods())
	_collider(Vector2(24, 12), Vector3(1.0, 0.8, 0.7))

	# Street food along the market — a ramen stall to refuel between deals.
	_eatery("Kage Ramen", Vector2(34, 8), 10, 4, Color(1.0, 0.7, 0.2), 90)

	# A sprawling yard means more to scavenge, scattered across the lot (same
	# save ids — only their positions moved).
	_trash_pile("trash_0", Vector2(10, 30))
	_trash_pile("trash_1", Vector2(20, 36))
	_trash_pile("trash_2", Vector2(30, 31))
	_trash_pile("market_trash_3", Vector2(40, 37))
	_trash_pile("market_trash_4", Vector2(48, 30))

	# Lit billboards over the market.
	_billboard(Vector2(28, 2), 0)
	_billboard(Vector2(8, 22), 90)
	_billboard(Vector2(50, 24), 180)

	for p in [Vector2(20, 18), Vector2(34, 18), Vector2(12, 24), Vector2(46, 16)]:
		_planter(p)
	for p in [Vector2(18, 30), Vector2(36, 33), Vector2(48, 24)]:
		_streetlamp(p)

	# A weathered monument in the forecourt — the market's landmark.
	_statue(Vector2(28, 9), "TRADERS'\nMEMORIAL", Color(0.85, 0.6, 0.3))

	# A few hardy trees breaking up the forecourt and the e-waste yard edges.
	for p in [Vector2(10, 14), Vector2(30, 16), Vector2(50, 18), Vector2(8, 38),
			Vector2(46, 38), Vector2(52, 33)]:
		_tree(p, randf_range(0.85, 1.1))

	# Alley cats picking through the e-waste yard, plus a scanner drone.
	_stray(Vector2(22, 33), "cat", 8.0)
	_stray(Vector2(44, 33), "cat", 7.0)
	_stray(Vector2(16, 31), "bird", 6.0)

	_exit("Plaza", Vector2(63, 14), "plaza", "from_market", 90)
	_exit("Corp Row", Vector2(63, 32), "corp_row", "from_market", 90)
	_spawn_wanderers("market")

	_mark("from_plaza", Vector2(60, 14))
	_mark("from_corp", Vector2(60, 32))

	# Tenements ringing the market — chunk-kit skyline on all four sides.
	_skyline_row(Vector2(8, -3.5), Vector2(6.0, 0), 9, ["shop", "tower"])       # north
	_skyline_row(Vector2(-3.5, 8), Vector2(0, 6.0), 6, ["tower", "shop"], -90)  # west
	_skyline_row(Vector2(67.5, 8), Vector2(0, 6.0), 6, ["shop", "tower"], 90)   # east
	_skyline_row(Vector2(8, 48.5), Vector2(6.0, 0), 9, ["tower", "shop"], 180)  # south

	# Delivery vans working the market loop (G7) — warmer, a touch faster.
	_ring_road(-1.4, 5, 3.4, Color(0.6, 0.45, 0.3))
