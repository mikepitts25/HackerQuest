extends "res://scripts/district.gd"
## The Drowned Quarter — flooded fiber tunnels under the bay. Endgame haunt
## (Architect status): the city's trunk lines run through here, half a meter
## under black water. Walkways thread between the pools; THE TRUNK hums in
## the middle of it all.


func _build() -> void:
	area_size = Vector2(1000, 760)

	_floor(Vector2.ZERO, area_size, Color("0e1418"))
	_border()

	# Black water pools — collide like walls, drawn as still water.
	_pool(Vector2(80, 80), Vector2(380, 260))
	_pool(Vector2(560, 80), Vector2(360, 220))
	_pool(Vector2(80, 480), Vector2(300, 200))
	_pool(Vector2(620, 460), Vector2(300, 220))

	_sign("DROWNED QUARTER", Vector2(120, 26), 26)
	_sign("mind the water. mind the current.", Vector2(130, 68), 14)

	_interactable(GameState.trunk_prompt(), Vector2(500, 380), Vector2(110, 110), Color("123a4a"), "THE TRUNK",
			func() -> void:
				if not GameState.trunk_ready():
					GameState.notify(GameState.final_contract_hint(), GameState.COL_WARN)
				else:
					GameState.notify("THE TRUNK drops the R10T mask. The final boss is awake below the bay.", GameState.COL_BAD))

	_exit("Darknet Cafe", Vector2(940, 360), Vector2(46, 110), "darknet", "from_drowned")

	_mark("from_darknet", Vector2(880, 360))


# A pool is a wall (so you can't walk in) skinned as water (drawn after, on top).
func _pool(pos: Vector2, size: Vector2) -> void:
	_wall(pos.x, pos.y, size.x, size.y)
	_floor(pos, size, Color("0a2330"))
