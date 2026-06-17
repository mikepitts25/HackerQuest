extends "res://scripts/iso/district_3d.gd"
## Corp Row in 3D — glass towers and corporate plaza. Unlocks at Black Hat
## status. Cipher works here; doors to the Market and the Darknet Café. The
## servers no longer sprawl across the row: they live behind the doors of the
## AXIOM DATACENTER (corp_datacenter_3d), entered from the plaza. Big City pass:
## ~10x footprint, a wide corporate plaza ringed by skyscrapers, storefronts and
## eateries, and the datacenter block at the back.


func _build() -> void:
	area_size = Vector2(64, 45)

	_ground(Color(0.083, 0.092, 0.11))
	_patch(Vector2(4, 20), Vector2(56, 21), Color(0.1, 0.118, 0.148))     # corporate plaza
	_patch(Vector2(4, 4), Vector2(33, 14), Color(0.092, 0.107, 0.134))    # lobby forecourt
	_back_street(Vector2(4, 41), Vector2(56, 3))                          # service lane
	_border()

	_sign("CORP ROW", Vector2(8, 2.5), 2.6, 72)

	var board := _prop(JOB_BOARD_SCENE, Vector2(12, 24))
	_interact(board, "Corp gigs", Vector3(1.5, 1.5, 0.4),
			func() -> void: main.show_jobs("corp"))
	_collider(Vector2(12, 24), Vector3(1.5, 1.5, 0.3))

	# The AXIOM DATACENTER — the servers moved off the row and behind its doors.
	# A glass-and-steel block at the back; walk to the lit entrance to go inside.
	_datacenter_building(Vector2(40, 4), Vector2(20, 12))
	_sign("AXIOM DATACENTER", Vector2(50, 3), 7.4, 48)
	_sign("badge access · enter →", Vector2(50, 14.6), 2.2, 28)
	_exit("Datacenter", Vector2(50, 16.6), "corp_datacenter", "from_corp", 0)
	_mark("from_datacenter", Vector2(50, 19))

	# Corporate towers standing right in the plaza, so you're among skyscrapers
	# (the skyline rows below ring the district from outside the walls).
	_prop(TOWER_SCENE, Vector2(22, 9))
	_prop(TOWER_SCENE, Vector2(31, 10))
	_collider(Vector2(22, 9), Vector3(2.4, 4, 2.4))
	_collider(Vector2(31, 10), Vector3(2.4, 4, 2.4))

	# Cipher (corp intel) keeps a quiet spot off the plaza — discreet, not on the
	# main concourse.
	_npc_overrides = {"cipher": Vector2(10, 32)}
	_spawn_npcs("corp_row")  # Cipher

	# Storefronts and eateries so the row reads like a corporate strip, not an
	# empty courtyard. Overpriced food restores a lot; a chrome boutique for show.
	_eatery("Atrium Cafe", Vector2(22, 24), 16, 5, Color(0.3, 0.8, 1.0), 90)
	_eatery("Skyline Sushi", Vector2(46, 34), 14, 4, Color(0.5, 0.85, 1.0), 180)
	_prop(SHOP_BLDG_SCENE, Vector2(34, 30))
	_collider(Vector2(34, 30), Vector3(2, 1.8, 2))
	_sign("CHROME & CO", Vector2(34, 30), 2.4, 30)

	_billboard(Vector2(16, 18.5), 0, {"slogan": "AXIOM CORP\nwe own tomorrow", "color": Color(0.3, 0.8, 1.0)})
	_billboard(Vector2(58, 30), 90, {"slogan": "RAMWORKS\noverclock your life", "color": Color(0.3, 0.8, 1.0)})
	_billboard(Vector2(12, 39), 180, {"slogan": "GHOST VPN\ndisappear.", "color": Color(0.5, 0.4, 0.95)})

	for p in [Vector2(18, 28), Vector2(30, 36), Vector2(44, 26), Vector2(26, 22), Vector2(52, 38)]:
		_planter(p)
	for p in [Vector2(16, 26), Vector2(28, 34), Vector2(48, 24), Vector2(40, 36)]:
		_streetlamp(p, Color(0.6, 0.9, 1.0))
	_bench(Vector2(24, 30), 0)
	_bench(Vector2(42, 30), 180)

	# A polished corporate monument fronting the lobby — the row's landmark.
	_statue(Vector2(10, 10), "AXIOM\nPLAZA", Color(0.3, 0.8, 1.0))

	# Manicured trees lining the corporate plaza.
	for p in [Vector2(38, 24), Vector2(50, 26), Vector2(20, 38), Vector2(48, 40),
			Vector2(8, 40), Vector2(16, 38)]:
		_tree(p, randf_range(0.95, 1.15))

	# Surveillance drones drifting the row, and a stray cat slumming the back lane.
	_stray(Vector2(28, 26), "bird", 9.0)
	_stray(Vector2(44, 22), "bird", 8.0)
	_stray(Vector2(14, 38), "cat", 6.0)

	_exit("Market", Vector2(1, 24), "market", "from_corp", 90)
	_exit("Darknet Cafe", Vector2(63, 24), "darknet", "from_corp", 90)
	_spawn_wanderers("corp_row")

	_mark("from_market", Vector2(4, 24))
	_mark("from_darknet", Vector2(60, 24))

	# Glass-tower skyline ringing the row — chunk-kit rows set back for the road.
	_skyline_row(Vector2(8, -3.5), Vector2(6.0, 0), 9, ["tower"])             # north
	_skyline_row(Vector2(-3.5, 8), Vector2(0, 6.0), 6, ["tower"], -90)       # west
	_skyline_row(Vector2(67.5, 8), Vector2(0, 6.0), 6, ["tower"], 90)        # east
	_skyline_row(Vector2(8, 48.5), Vector2(6.0, 0), 9, ["tower", "shop"], 180) # south

	# Sleek corporate sedans gliding the row (G7) — dark, cyan-lit, quick.
	_ring_road(-1.4, 5, 3.8, Color(0.16, 0.2, 0.26))


# The datacenter shell: a tall dark glass block with a lit entrance bay on its
# south face. Solid (colliders on the side walls), with the doorway left open so
# the _exit marker in front of it reads as the way in.
func _datacenter_building(pos: Vector2, size: Vector2) -> void:
	var h := 7.0
	var cx := pos.x + size.x / 2.0
	var cz := pos.y + size.y / 2.0

	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(size.x, h, size.y)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.1, 0.14)
	mat.metallic = 0.55
	mat.roughness = 0.3
	bm.material = mat
	body.mesh = bm
	body.position = Vector3(cx, h / 2.0, cz)
	add_child(body)

	# Emissive window banding so it reads as a glass tower, not a slab.
	for y in [2.0, 3.6, 5.2]:
		var band := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(size.x + 0.04, 0.5, size.y + 0.04)
		var smat := StandardMaterial3D.new()
		var c := Color(0.3, 0.7, 1.0)
		smat.albedo_color = c.darkened(0.3)
		smat.emission_enabled = true
		smat.emission = c
		smat.emission_energy_multiplier = 0.8
		sm.material = smat
		band.mesh = sm
		band.position = Vector3(cx, y, cz)
		add_child(band)

	# Lit entrance bay on the south face.
	var bay := MeshInstance3D.new()
	var ym := BoxMesh.new()
	ym.size = Vector3(3.2, 2.6, 0.3)
	var ymat := StandardMaterial3D.new()
	ymat.albedo_color = Color(0.25, 0.6, 0.9)
	ymat.emission_enabled = true
	ymat.emission = Color(0.35, 0.75, 1.0)
	ymat.emission_energy_multiplier = 1.3
	ym.material = ymat
	bay.mesh = ym
	bay.position = Vector3(cx, 1.3, pos.y + size.y)
	add_child(bay)

	# Solid walls flanking the doorway (a ~3.6m gap centred on the south face),
	# plus the back and sides, so you can't walk through the building.
	var t := 0.4
	_collider(Vector2(cx, pos.y + t / 2.0), Vector3(size.x, h, t))                 # back (north)
	_collider(Vector2(pos.x + t / 2.0, cz), Vector3(t, h, size.y))                 # west
	_collider(Vector2(pos.x + size.x - t / 2.0, cz), Vector3(t, h, size.y))        # east
	var gap := 3.6
	var seg := (size.x - gap) / 2.0
	_collider(Vector2(pos.x + seg / 2.0, pos.y + size.y - t / 2.0), Vector3(seg, h, t))
	_collider(Vector2(pos.x + size.x - seg / 2.0, pos.y + size.y - t / 2.0), Vector3(seg, h, t))
