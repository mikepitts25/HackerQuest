extends "res://scripts/iso/district_3d.gd"
## The Block — your apartment in 3D. Bed (sleep), desk (terminal), rentals
## board, and the door out to the Plaza. Mirrors home_district.gd at 80px = 1m.


func _build() -> void:
	area_size = Vector2(10.3, 8.5)

	_ground()
	_patch(Vector2(1, 1), Vector2(8.3, 5.5), Color(0.21, 0.18, 0.15))  # apartment floor
	_border()

	# Apartment walls with a door gap at the bottom (x 4.5..5.8).
	_wall(1, 0.8, 8.3, 0.2)
	_wall(0.8, 1, 0.2, 5.5)
	_wall(9.3, 1, 0.2, 5.5)
	_wall(1, 6.5, 3.5, 0.2)
	_wall(5.8, 6.5, 3.5, 0.2)

	_sign("APT 4B", Vector2(2.3, 0.8), 1.6, 44)

	var bed := _prop(BED_SCENE, Vector2(2.2, 2.5))
	_interact(bed, "Sleep", Vector3(0.9, 0.6, 1.8),
			func() -> void: main.do_sleep())
	_collider(Vector2(2.2, 2.5), Vector3(0.95, 0.5, 1.85))

	var desk := _prop(DESK_SCENE, Vector2(7, 1.8))
	_interact(desk, "Use desk", Vector3(1.4, 1.0, 0.7),
			func() -> void: main.use_desk())
	_collider(Vector2(7, 1.8), Vector3(1.4, 0.6, 0.65))

	_box_interactable("Browse rentals", Vector2(8.4, 5.9), Vector3(0.8, 1.1, 0.25),
			Color(0.48, 0.43, 0.29), "VACANCIES",
			func() -> void: main.open_apartments())

	_exit("Plaza", Vector2(5.15, 7.6), "plaza", "from_home")
	# Strangers stay on the street outside — nobody wanders into APT 4B.
	wander_zone = Rect2(0.6, 6.9, 9.1, 1.2)
	_spawn_wanderers("home")

	_mark("start", Vector2(3.8, 3.8))       # new-game spawn, inside the apartment
	_mark("from_plaza", Vector2(5.15, 6.9))  # arriving back from the plaza
