extends "res://scripts/iso/district_3d.gd"
## The Darknet Café in 3D — endgame haunt of the truly notorious. Unlocks at
## Zero Day status. Oracle keeps to the back rig hall (a guide who doesn't sit
## in the window); the contracts board pays the big jobs. Big City pass: ~10x
## footprint, with a roomy café floor, a deep rig hall, and a dim noodle counter.

# Worried mutterings a patron throws out when you drain their laptop.
const CAFE_PATRON_LINES := [
	"hey... my screen just flickered. anyone else seeing that?",
	"the hell? my files are opening by themselves.",
	"is the café wifi acting up for you too?",
	"my battery just dropped to zero. that's not normal.",
	"i swear my webcam light just came on by itself.",
	"did my cursor just move on its own?",
	"something's eating my bandwidth. this place is haunted.",
	"my laptop's burning up and i'm not even running anything.",
	"...who's in my files right now. WHO is in my files.",
]

# Ids of the hackable café-floor booths this build laid down, and a once-per-
# visit guard so R10T only storms in once.
var _cafe_patron_ids: Array[String] = []
var _riot_summoned := false


func _build() -> void:
	area_size = Vector2(58, 42)

	_ground(Color(0.055, 0.045, 0.08))
	_patch(Vector2(5, 4), Vector2(32, 30), Color(0.084, 0.064, 0.115))   # café floor
	_patch(Vector2(40, 4), Vector2(13, 30), Color(0.06, 0.045, 0.09))    # back-room rig hall
	_back_street(Vector2(5, 36), Vector2(48, 3))                         # alley out back
	_border()

	_sign("DARKNET CAFE", Vector2(9, 2.5), 2.6, 64)
	_sign("members only", Vector2(9, 4), 1.7, 30)
	_sign("NO CAMS · NO LOGS", Vector2(9, 5.3), 1.4, 26)
	_sign("RIG HALL", Vector2(42, 2.5), 1.8, 36)
	_sign("TIME · $5/HR\nCASH ONLY · BYO RIG", Vector2(14, 13), 1.9, 24)

	var contracts := _prop(JOB_BOARD_SCENE, Vector2(24, 9))
	_interact(contracts, "Contracts", Vector3(1.5, 1.5, 0.4),
			func() -> void: main.open_contracts())
	_collider(Vector2(24, 9), Vector3(1.5, 1.5, 0.3))

	# Back-room rigs — rows of them humming in the dark.
	for i in 12:
		var pos := Vector2(42.0 + (i % 2) * 6.0, 8.0 + floorf(i / 2.0) * 4.5)
		_prop(RACK_SCENE, pos)
		_collider(pos, Vector3(0.7, 1.5, 0.55))

	# The café floor proper: pay-by-the-hour booths. The first is the back rig you
	# rent for $5/hr — logging in opens the café LAN. The rest are taken by
	# anonymous patrons whose laptops you can drain once you're on the LAN. Drain
	# the whole room and R10T, whose turf this is, comes through the door. Monitors
	# are the only real light; glows cycle cyan/teal with the odd magenta rig.
	var screen_glows := [
		Color(0.2, 1.0, 0.7), Color(0.3, 0.85, 1.0),
		Color(0.5, 0.9, 0.6), Color(0.9, 0.3, 0.9),
	]
	# The rentable back rig — bright cyan, empty, waiting for you.
	_rig_booth(Vector2(6.5, 12.5), 90, Color(0.35, 1.0, 0.85))
	# Patron booths you can hack: the rest of the left wall + the right wall.
	var patrons := [
		[Vector2(6.5, 15.5), 90.0], [Vector2(6.5, 18.5), 90.0],
		[Vector2(6.5, 21.5), 90.0], [Vector2(6.5, 24.5), 90.0],
		[Vector2(35.5, 12.0), -90.0], [Vector2(35.5, 15.0), -90.0],
		[Vector2(35.5, 18.0), -90.0], [Vector2(35.5, 21.0), -90.0],
	]
	for i in patrons.size():
		var spot: Array = patrons[i]
		_patron_booth(spot[0], spot[1], screen_glows[i % screen_glows.size()],
				"cafe_patron_%d" % i, "%02d" % (i + 1))
	# Background booths — café staff and rig-hall operators, not part of the job.
	var bg := 0
	for x in [9.0, 11.5, 14.0]:
		_workstation(Vector2(x, 32.5), 180, screen_glows[bg % screen_glows.size()], true, false, "")
		bg += 1
	_workstation(Vector2(43, 32), 180, Color(0.9, 0.3, 0.9), true, true, "OP1")
	_workstation(Vector2(50, 32), 180, Color(0.9, 0.3, 0.9), false, true, "OP2")

	# Drinks coolers — fuel stocked along the café walls.
	_vending_machine(Vector2(6, 9), 90, Color(0.3, 0.85, 1.0), "COLD BYTES")
	_vending_machine(Vector2(36, 10), -90, Color(0.9, 0.4, 0.5), "CHARGE")

	# Tangles of floor cabling feeding the booths and the rig hall.
	_cable_run(Vector2(8, 18.5), 13, 90, Color(0.2, 0.95, 0.7))
	_cable_run(Vector2(45, 19), 22, 90, Color(0.5, 0.4, 0.95))

	# Oracle (endgame guide) holds court at the back of the rig hall — out of
	# sight from the door, as befits the city's most-watched fixer.
	_npc_overrides = {"oracle": Vector2(46, 12)}
	_spawn_npcs("darknet")  # Oracle

	# A dim noodle counter in the café — fuel for the all-nighters.
	_eatery("Zero/One Counter", Vector2(14, 10), 14, 5, Color(0.2, 1.0, 0.7), 90)

	_billboard(Vector2(16, 2), 0, {"slogan": "ZERO/ONE\nclub - all night", "color": Color(0.2, 1.0, 0.7)})
	_billboard(Vector2(30, 35), 180, {"slogan": "DERMA-INK\nget chromed", "color": Color(0.9, 0.3, 0.9)})

	for p in [Vector2(12, 16), Vector2(26, 18), Vector2(18, 26), Vector2(30, 24)]:
		_planter(p)
	for p in [Vector2(10, 12), Vector2(28, 30), Vector2(20, 20)]:
		_streetlamp(p, Color(0.7, 0.4, 0.85))

	# An underground shrine to the scene's origins — the café's landmark.
	_statue(Vector2(20, 30), "THE FIRST\nEXPLOIT", Color(0.2, 1.0, 0.7))

	# Dim potted trees softening the café floor corners.
	for p in [Vector2(8, 30), Vector2(34, 28), Vector2(10, 6), Vector2(34, 6)]:
		_tree(p, randf_range(0.8, 1.0))

	# Alley cats prowling the café floor and a glitchy drone overhead.
	_stray(Vector2(16, 32), "cat", 7.0)
	_stray(Vector2(30, 14), "cat", 6.0)
	_stray(Vector2(24, 16), "bird", 7.0)

	_exit("Corp Row", Vector2(1, 21), "corp_row", "from_darknet", 90)
	_exit("Drowned Quarter", Vector2(57, 21), "drowned_quarter", "from_darknet", 90)
	_spawn_wanderers("darknet")

	_mark("from_corp", Vector2(4, 21))
	_mark("from_drowned", Vector2(54, 21))

	# Sparse, seedy late-night traffic skirting the cafe (G7).
	_ring_road(-1.4, 4, 2.8, Color(0.32, 0.16, 0.18))

	# Cleared the room on an earlier visit but never settled with R10T? He's
	# already waiting when you walk back in.
	if _cafe_all_hacked():
		_summon_riot(false)


# --- the café LAN job (rent the rig, drain the room, then R10T) ---------------

# The rentable back rig: a bright, empty booth. Renting it ($5/hr) logs you onto
# the café LAN so you can reach the other patrons' machines.
func _rig_booth(pos: Vector2, yaw_deg: float, glow: Color) -> void:
	var booth := _workstation(pos, yaw_deg, glow, false, true, "")
	_sign("RENT $5/HR", pos + Vector2(0, -1.1), 1.7, 26)
	_interact(booth, "Rent rig ($5/hr)", Vector3(1.1, 1.5, 1.1), _rent_rig)


# An occupied patron booth you can drain once you're on the café LAN. Hacked
# state lives in GameState so it survives district rebuilds and save/load.
func _patron_booth(pos: Vector2, yaw_deg: float, glow: Color, id: String, tag: String) -> void:
	_cafe_patron_ids.append(id)
	var booth := _workstation(pos, yaw_deg, glow, true, false, tag)
	var it := _interact(booth, "Hack their laptop", Vector3(1.1, 1.5, 1.1), Callable())
	it.action = func() -> void: _hack_patron(id, booth, it)
	if GameState.cafe_hacked.has(id):
		it.set_dim(true)


func _rent_rig() -> void:
	if GameState.cafe_rig_rented:
		GameState.notify("Already logged in on the back rig.", GameState.COL_INFO)
		return
	if GameState.cash < 5:
		GameState.notify("The rig's $5/hr — cash only.", GameState.COL_WARN)
		return
	GameState.add_cash(-5)
	GameState.cafe_rig_rented = true
	Audio.sfx("cash")
	GameState.notify("Logged in. From here the whole café LAN is wide open.", GameState.COL_GOOD)


func _hack_patron(id: String, booth: Node3D, it: Area3D) -> void:
	if GameState.cafe_hacked.has(id):
		GameState.notify("That session's already drained.", GameState.COL_WARN)
		return
	if not GameState.cafe_rig_rented:
		GameState.notify("Rent the back rig first — you need to be on the café LAN.", GameState.COL_WARN)
		return
	GameState.drain_energy(1)
	GameState.cafe_hacked[id] = true
	var reward := randi_range(25, 50)
	GameState.add_cash(reward)
	GameState.add_xp(8)
	Audio.sfx("hack_ok")
	GameState.notify("Drained their session — +$%d." % reward, GameState.COL_GOOD)
	_say_over(booth, CAFE_PATRON_LINES.pick_random())
	it.set_dim(true)
	if _cafe_all_hacked():
		_summon_riot(true)


func _cafe_all_hacked() -> bool:
	if _cafe_patron_ids.is_empty():
		return false
	for id in _cafe_patron_ids:
		if not GameState.cafe_hacked.has(id):
			return false
	return true


# R10T storms the café once you've drained every booth — it's his turf. `walk_in`
# plays the door-kick entrance and starts the duel automatically; otherwise he's
# already waiting (you cleared the room on a previous visit) and you bump or talk
# to start it. Beating him is handled in resolve_street_encounter below.
func _summon_riot(walk_in: bool) -> void:
	if _riot_summoned or GameState.cafe_riot_beaten:
		return
	# The café duel is the first beat of the finale, so it's gated behind the
	# final contract (decision: keep that prerequisite). Drained the room early?
	# You get the cash, but R10T won't surface until the big job is done.
	if not GameState.final_contract_complete():
		if walk_in:
			GameState.notify("Room's tapped out — but R10T won't surface until you've pulled the final job.", GameState.COL_WARN)
		return
	_riot_summoned = true
	# The duel is the one R10T in the room: remove the talkable rival or any
	# roaming r10t boss that happens to be here before he storms in.
	_clear_r10t_avatars()
	var riot: Node3D = load(CHAR_SCENES["riot"]).instantiate()
	var stand := Vector2(20, 17)
	var entrance := Vector2(3.5, 21)
	riot.position = Vector3((entrance.x if walk_in else stand.x), 0, (entrance.y if walk_in else stand.y))
	riot.rotation.y = deg_to_rad(90)
	add_child(riot)
	riot.set_meta("enemy_id", "riot")
	riot.add_to_group("street_encounter")
	riot.add_to_group("r10t_avatar")
	var tag := Label3D.new()
	tag.text = "⚠ R10T"
	tag.font_size = 30
	tag.pixel_size = 0.01
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color("ff6b6b")
	tag.outline_size = 8
	tag.position = Vector3(0, 1.95, 0)
	riot.add_child(tag)
	# Set the active hostile at the moment combat begins (not at spawn), so a
	# stray street encounter spawning afterward can't steal the slot from R10T.
	var fight := func() -> void:
		_active_street_hostile = riot
		if main != null and main.has_method("start_combat"):
			main.start_combat("riot")
	if walk_in:
		Audio.sfx("riot_sting")
		GameState.notify("R10T kicks the café door open.", GameState.COL_BAD)
		_say_over(riot, "You drained every rig in MY house?!")
		var tw := create_tween()
		tw.tween_property(riot, "position", Vector3(stand.x, 0, stand.y), 1.2).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(fight)
	else:
		_say_over(riot, "Back in my café? We're not done.")
		var trigger := _interact(riot, "Face R10T", Vector3(1.0, 1.5, 1.0), fight)
		trigger.body_entered.connect(func(body: Node3D) -> void:
			if body.is_in_group("player"):
				fight.call())


# Combat closing routes here (main_3d._on_combat_closed). Beating R10T hands you
# the café for good; any other encounter falls through to base flee handling.
func resolve_street_encounter(enemy_id: String, outcome: String) -> void:
	if enemy_id == "riot" and outcome == "win":
		# He doesn't go down here — he bolts for the bay (the Drowned Quarter),
		# where the rematch + Deep Marrow gauntlet waits.
		GameState.cafe_riot_beaten = true
		Audio.sfx("escape")
		GameState.notify("R10T bolts mid-fight — \"This isn't over. The bay. Come finish it.\"", GameState.COL_WARN)
	super(enemy_id, outcome)
