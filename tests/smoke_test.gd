extends Node
## Headless smoke test. Boots the real main scene and drives the core loop:
## shop purchase, every terminal command, jobs, sleep, and the heat bust.
## Run with:
##   godot --headless res://tests/smoke_test.tscn

var _failures: Array[String] = []


func _check(cond: bool, what: String) -> void:
	if not cond:
		_failures.append(what)


func _ready() -> void:
	await get_tree().process_frame
	GameState.new_game()  # deterministic start, clears any prior save
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame

	var hud: Control = main.get_node("UILayer/HUD")
	var shop: Panel = main.get_node("UILayer/Shop")
	var terminal: Panel = main.get_node("UILayer/Terminal")

	# --- shop / upgrades ---
	_check(not GameState.buy_upgrade("used_laptop"), "laptop should be unaffordable at start")
	GameState.add_cash(1000)
	shop.open()
	_check(GameState.buy_upgrade("used_laptop"), "buy laptop")
	_check(GameState.has_computer, "has_computer set")
	_check(GameState.max_cpu == 6 and GameState.cpu == 6, "laptop grants 6 CPU")
	_check(GameState.buy_upgrade("vpn"), "buy vpn (prereq satisfied)")
	_check(not GameState.buy_upgrade("vpn"), "vpn not buyable twice")
	shop.close_shop()

	# --- terminal commands ---
	terminal.open()
	for cmd in ["help", "scan", "inspect coffee_shop_router", "inspect nope", "collect", "clear"]:
		terminal._on_submit(cmd)
	GameState.reputation = 60  # pin success chance at the 95% clamp
	var pwned := false
	for attempt in 10:
		terminal._on_submit("exploit parking_meter_node")
		if GameState.exploited.has("parking_meter_node"):
			pwned = true
			break
		GameState.sleep()
	_check(pwned, "exploit eventually succeeds")
	terminal._on_submit("install_bot parking_meter_node")
	_check(GameState.botnet_size >= 1, "install_bot grew botnet")
	var cash_before := GameState.cash
	terminal._on_submit("collect")
	_check(GameState.cash > cash_before, "collect paid out")
	terminal._on_submit("exit")
	_check(not terminal.visible, "exit closed terminal")

	# --- fatigue ---
	GameState.energy = GameState.max_energy
	_check(GameState.fatigue_penalty() == 0.0, "no fatigue when rested")
	_check(not GameState.is_fatigued(), "not fatigued when full")
	GameState.energy = 0
	_check(GameState.is_fatigued(), "fatigued when empty")
	_check(abs(GameState.fatigue_penalty() - GameState.FATIGUE_MAX) < 0.001, "max fatigue at empty energy")
	GameState.drain_energy(5)
	_check(GameState.energy == 0, "drain_energy floors at zero")
	# Exploit applies a soft energy cost.
	GameState.energy = 5
	GameState.cpu = GameState.max_cpu
	GameState.exploited.clear()
	var e_before := GameState.energy
	terminal.open()
	terminal._on_submit("exploit parking_meter_node")
	terminal.close_terminal()
	_check(GameState.energy == e_before - 1, "exploit drains 1 energy")

	# --- jobs ---
	hud.show_jobs()
	cash_before = GameState.cash
	hud._do_job("fix_router")
	_check(GameState.cash == cash_before + 20, "job paid $20")
	hud._close_jobs()

	# --- quests ---
	_check(GameState.quest_index >= 4, "quest line advanced through laptop + first bot")

	# --- xp / levels / skills ---
	var lvl_before := GameState.level
	GameState.add_xp(GameState.xp_needed())
	_check(GameState.level >= lvl_before + 1, "xp grants level up")
	_check(GameState.skill_points >= 1, "level up grants skill point")
	var cpu_max_before := GameState.max_cpu
	_check(GameState.buy_skill("hardware"), "buy hardware skill")
	_check(GameState.max_cpu == cpu_max_before + 2, "hardware skill grants +2 max CPU")
	_check(not GameState.buy_skill("stealth") or GameState.skill_points >= 0, "skill point bookkeeping sane")

	# --- inventory / selling ---
	GameState.add_item("ram_stick")
	_check(GameState.inventory.get("ram_stick", 0) >= 1, "loot lands in inventory")
	cash_before = GameState.cash
	_check(GameState.sell_item("ram_stick"), "sell item")
	_check(GameState.cash > cash_before, "selling pays out")

	# --- consumables ---
	_check(GameState.buy_consumable("energy_drink"), "buy energy drink")
	_check(GameState.inventory.get("energy_drink", 0) == 1, "energy drink in bag")
	GameState.energy = 2
	var base_max_cpu := GameState.max_cpu
	_check(GameState.use_consumable("energy_drink"), "use energy drink")
	_check(GameState.energy == 7, "energy drink restores +5 energy")
	_check(GameState.max_cpu == base_max_cpu + 2, "wired raises max CPU")
	_check(GameState.wired_cpu == 2, "wired bonus tracked")
	_check(GameState.inventory.get("energy_drink", 0) == 0, "energy drink consumed")
	GameState.buy_consumable("focus_pills")
	GameState.cpu = 0
	_check(GameState.use_consumable("focus_pills"), "use focus pills")
	_check(GameState.cpu == 4, "focus pills restore +4 CPU")

	# --- sleep ---
	GameState.energy = 0
	var day_before := GameState.day
	GameState.sleep()
	_check(GameState.day == day_before + 1, "sleep advances day")
	_check(GameState.energy == GameState.max_energy, "sleep restores energy")
	_check(GameState.exploited.is_empty(), "sleep re-secures targets")
	_check(GameState.wired_cpu == 0, "sleep clears wired bonus")
	_check(GameState.max_cpu == base_max_cpu, "sleep removes wired max CPU")

	# --- trace / heat bust ---
	var has_trace_api := GameState.has_method("tick_trace") \
			and GameState.has_method("trace_duration") \
			and GameState.has_method("trace_escape_heat") \
			and GameState.has_method("escape_trace")
	_check(has_trace_api, "trace API exists")
	if has_trace_api:
		var bust_cash := GameState.cash
		var bust_botnet := GameState.botnet_size
		GameState.add_heat(500)
		_check(GameState.get("trace_active") == true, "heat 100 starts trace")
		_check(GameState.heat == 100, "trace holds heat at 100")
		GameState.tick_trace(GameState.trace_duration() + 0.1)
		_check(GameState.get("trace_active") == false, "trace ends after countdown")
		_check(GameState.heat == 50, "trace bust resets heat to 50")
		_check(GameState.cash == bust_cash / 2, "trace bust halves cash")
		_check(GameState.botnet_size == bust_botnet / 2, "trace bust halves botnet")

		GameState.heat = 0
		GameState.cash = 300
		GameState.botnet_size = 6
		GameState.add_heat(500)
		_check(GameState.get("trace_active") == true, "trace can restart after bust")
		_check(GameState.escape_trace(), "escape_trace returns true while active")
		_check(GameState.get("trace_active") == false, "escape clears trace")
		_check(GameState.heat == GameState.trace_escape_heat(), "escape lowers heat to escape target")

		GameState.heat = 0
		GameState.force_trace("smoke_sleep")
		day_before = GameState.day
		GameState.sleep()
		_check(GameState.get("trace_active") == true, "trace-active sleep stays traced")
		_check(GameState.heat == 100, "trace-active sleep keeps heat maxed")
		_check(GameState.day == day_before, "trace-active sleep does not advance day")
		GameState._reset_trace()
		GameState.heat = 0

		GameState.heat = 0
		GameState.cash = 500
		GameState.fixer_used = false
		GameState.force_trace("smoke_fixer")
		cash_before = GameState.cash
		var trace_fixer := GameState.bribe_fixer()
		_check(not trace_fixer.ok, "trace-active fixer refuses scrub")
		_check(GameState.get("trace_active") == true, "trace-active fixer stays traced")
		_check(GameState.heat == 100, "trace-active fixer keeps heat maxed")
		_check(GameState.cash == cash_before, "trace-active fixer does not spend cash")
		GameState._reset_trace()
		GameState.heat = 0

		GameState.heat = 0
		GameState.add_heat(500)
		_check(GameState.get("trace_active") == true, "trace active before save")
		GameState.save_game()
		GameState.heat = 0
		GameState._reset_trace()
		_check(GameState.load_game(), "load trace save")
		_check(GameState.get("trace_active") == false, "load clears transient trace")
		_check(GameState.heat == GameState.trace_escape_heat(), "load normalizes saved trace heat")

	var has_failed_hack_api := GameState.has_method("apply_failed_hack_heat") \
			and GameState.has_method("high_risk_hack_heat_threshold")
	_check(has_failed_hack_api, "failed hack heat API exists")
	if has_failed_hack_api:
		GameState.reputation = 0
		GameState.upgrades.erase("vpn")
		GameState.skills["stealth"] = 0
		GameState.heat = 0
		GameState._reset_trace()
		var low_fail_heat: int = GameState.apply_failed_hack_heat(10)
		_check(low_fail_heat == 5, "low-risk failed hack applies half heat")
		_check(GameState.heat == 5, "low-risk failed hack changes heat by half")
		_check(GameState.get("trace_active") == false, "low-risk failed hack does not force trace")

		GameState.heat = 0
		GameState._reset_trace()
		var high_fail_heat: int = GameState.apply_failed_hack_heat(GameState.high_risk_hack_heat_threshold())
		_check(high_fail_heat == 100, "high-risk failed hack maxes heat")
		_check(GameState.get("trace_active") == true, "high-risk failed hack starts trace")
		GameState.escape_trace()

	# --- status (reputation ranks + rewards) ---
	GameState.reputation = 0
	GameState.status_seen = 0
	_check(GameState.status_index() == 0, "rep 0 = lowest rank")
	_check(GameState.status_title() == "Script Kiddie", "lowest status title")
	_check(GameState.status_index_for(8) == 2, "rep 8 maps to Operator index")
	_check(GameState.status_title_for(120) == "Legend", "rep 120 maps to Legend")
	_check(GameState.next_status().get("title", "") == "Pinger", "next status is Pinger")
	# Pinger reward = cash + a skill point.
	var rep_cash := GameState.cash
	var rep_sp := GameState.skill_points
	GameState.add_rep(3)
	_check(GameState.status_index() == 1, "add_rep advances rank")
	_check(GameState.cash == rep_cash + 40, "rank-up pays cash")
	_check(GameState.skill_points == rep_sp + 1, "rank-up grants a skill point")
	# Multi-rank cross: Pinger (cash 40) + Operator (cash 90, +2 max Energy).
	GameState.reputation = 0
	GameState.status_seen = 0
	rep_cash = GameState.cash
	var rep_maxe := GameState.max_energy
	GameState.add_rep(8)
	_check(GameState.status_seen == 2, "multi-rank cross recorded")
	_check(GameState.cash == rep_cash + 40 + 90, "multi-rank cash stacks")
	_check(GameState.max_energy == rep_maxe + 2, "rank reward raises max Energy")
	GameState.reputation = 120  # Legend, the top rank
	_check(GameState.next_status().is_empty(), "no next status at top rank")

	# --- heat / wanted tiers ---
	GameState.upgrades.erase("vpn")  # isolate from earlier VPN purchase
	GameState.skills["stealth"] = 0
	GameState.reputation = 0
	GameState.heat = 0
	GameState.add_heat(10)
	_check(GameState.heat == 10, "base-rank heat gain is unscaled")
	GameState.heat = 0
	GameState.reputation = 40  # Ghost: +50% heat surcharge
	GameState.add_heat(10)
	_check(GameState.heat == 15, "high rank adds a heat surcharge")
	GameState.heat = 60
	_check(GameState.heat_tier_name() == "Watched", "heat 60 = Watched")
	_check(GameState.heat_penalty() > 0.0, "watched tier penalizes hacks")
	GameState.heat = 10
	_check(GameState.heat_tier_name() == "Clean", "low heat = Clean")
	_check(GameState.heat_penalty() == 0.0, "clean tier has no penalty")
	GameState.reputation = 0
	_check(GameState.heat_cooldown_per_day() == 20, "base daily cooldown")
	GameState.reputation = 40  # status 5
	_check(GameState.heat_cooldown_per_day() == 10, "notoriety slows cooling")
	GameState.skills["stealth"] = 3
	_check(GameState.heat_cooldown_per_day() == 22, "stealth speeds cooling")
	GameState.skills["stealth"] = 0
	_check(GameData.TARGETS.has("ai_datacenter"), "endgame target exists")

	# Status gates prestige cosmetics.
	GameState.reputation = 0
	GameState.status_seen = 0
	GameState.cash = 1000
	_check(not GameState.buy_cosmetic("track_gold"), "status-locked cosmetic blocked")
	GameState.reputation = 10  # Operator
	_check(GameState.buy_cosmetic("track_gold"), "cosmetic unlocks at required status")
	GameState.equip_cosmetic("hoodie_gray")  # restore default look for the next block

	# --- endgame hardware + NPC services ---
	GameState.cash = 10000
	var hw_cpu := GameState.max_cpu
	_check(GameState.buy_upgrade("ram_upgrade"), "buy ram upgrade")
	_check(GameState.buy_upgrade("workstation"), "buy workstation")
	_check(GameState.buy_upgrade("server_rack"), "buy server rack")
	_check(GameState.buy_upgrade("quantum_rig"), "buy quantum rig")
	_check(GameState.max_cpu == hw_cpu + 4 + 8 + 12 + 18, "hardware tiers stack CPU")
	_check(GameState.max_cpu >= GameData.TARGETS["ai_datacenter"]["cpu_cost"], "endgame target is reachable")
	# Vex fences Stolen Data at a premium.
	GameState.inventory.erase("stolen_data")  # ignore any drops from earlier hacks
	GameState.add_item("stolen_data", 3)
	var fcash := GameState.cash
	var fres := GameState.fence_stolen_data()
	_check(fres.count == 3 and fres.total == 3 * GameState.FENCE_PRICE, "fence pays per packet")
	_check(GameState.cash == fcash + 3 * GameState.FENCE_PRICE, "fence cash paid out")
	_check(GameState.inventory.get("stolen_data", 0) == 0, "fence clears data")
	# Marlowe scrubs Heat once per day.
	GameState.heat = 50
	GameState.fixer_used = false
	GameState.cash = 1000
	var bres := GameState.bribe_fixer()
	_check(bres.ok and GameState.heat == 10, "fixer scrubs heat")
	_check(not GameState.bribe_fixer().ok, "fixer is once per day")

	# --- WiFi sniffing + war driving ---
	_check(GameState.skills.has("wardriving"), "wardriving skill exists")
	_check(not GameState.has_wifi_adapter(), "no adapter before purchase")
	GameState.cash = 500
	_check(GameState.buy_upgrade("wifi_adapter"), "buy wifi adapter")
	_check(GameState.has_wifi_adapter(), "adapter unlocks sniffing")
	var net := GameState.sniff_wifi()
	_check(net.has("ssid") and net.has("enc"), "sniff returns a network")
	_check(GameState.wifi_chance(net) > 0.0, "crack chance computed")
	# Force a guaranteed Open-network crack and check the payout path.
	GameState.wifi_current = {"ssid": "Loading...", "enc": 0, "bars": 4}
	GameState.cpu = GameState.max_cpu
	GameState.energy = 5
	GameState.reputation = 60  # pins odds high
	var wcash := GameState.cash
	var wres := GameState.crack_wifi()
	_check(wres.get("ok", false), "open network cracked")
	_check(GameState.cash > wcash, "wifi crack paid out")
	_check(GameState.wifi_current.is_empty(), "network consumed after crack")

	# --- apartments / vacancies ---
	_check(GameState.apartment == "apt_4b", "start in apt 4b")
	GameState.reputation = 10  # Operator, meets studio req
	GameState.cash = 2000
	var apt_maxe := GameState.max_energy
	_check(GameState.buy_apartment("studio_loft"), "rent studio loft")
	_check(GameState.apartment == "studio_loft", "moved into studio")
	_check(GameState.max_energy == apt_maxe + 2, "apartment grants +max Energy")
	_check(GameState.apartment_perk("cool") == 2, "apartment heat-cooldown perk reads")
	GameState.reputation = 0  # demote: penthouse should now be gated
	_check(not GameState.buy_apartment("penthouse"), "status gates premium apartment")

	# --- districts (status-gated) ---
	GameState.reputation = 0
	_check(GameState.district_unlocked("plaza"), "plaza always open")
	_check(not GameState.district_unlocked("corp_row"), "corp row gated early")
	GameState.reputation = 15  # Black Hat
	_check(GameState.district_unlocked("corp_row"), "corp row opens at Black Hat")
	_check(not GameState.district_unlocked("darknet"), "darknet still gated")
	GameState.reputation = 60  # Zero Day
	_check(GameState.district_unlocked("darknet"), "darknet opens at Zero Day")

	# --- known networks (wardriving map) ---
	GameState.known_networks = []
	GameState.sniff_wifi()
	_check(GameState.known_networks.size() >= 1, "sniffing logs a known network")
	var first_ssid: String = GameState.known_networks[0].ssid
	GameState.wifi_current = {}
	GameState.load_known(0)
	_check(GameState.wifi_current.get("ssid", "") == first_ssid, "can reload a saved network")

	# --- darknet contracts ---
	GameState.reputation = 60  # Zero Day — all contracts available
	GameState.completed_contracts = []
	GameState.active_contract = ""
	_check(GameState.accept_contract("bounty_bank"), "accept a contract")
	_check(GameState.active_contract == "bounty_bank", "contract is active")
	var con_cash := GameState.cash
	GameState.register_hack("bank_core", 7)  # fulfils the bounty
	_check(GameState.cash >= con_cash + GameData.CONTRACTS["bounty_bank"]["cash"], "contract pays its bonus")
	_check("bounty_bank" in GameState.completed_contracts, "contract marked complete")
	_check(GameState.active_contract == "", "active contract cleared on completion")

	# --- corp jobs are a separate board ---
	var corp_count := 0
	for jid in GameData.JOBS:
		if GameData.JOBS[jid].get("board", "plaza") == "corp":
			corp_count += 1
	_check(corp_count >= 2, "corp gig board has its own jobs")

	# --- ambient wanderers ---
	_check(GameState.ambient.size() == GameData.WANDERERS.size(), "ambient roster seeded")
	var moved := 0
	for i in 8:
		var before := []
		for w in GameState.ambient:
			before.append(w.district)
		GameState._migrate_ambient()
		for j in GameState.ambient.size():
			if GameState.ambient[j].district != before[j]:
				moved += 1
	_check(moved > 0, "wanderers migrate between districts")

	# --- cosmetics ---
	_check(GameState.owns_cosmetic("hoodie_gray"), "default outfit owned")
	_check(GameState.is_wearing("hoodie_gray"), "default outfit worn")
	_check(not GameState.owns_cosmetic("hoodie_red"), "red hoodie not owned yet")
	GameState.cash = 100
	_check(GameState.buy_cosmetic("hoodie_red"), "buy red hoodie")
	_check(GameState.cash == 100 - GameData.COSMETICS["hoodie_red"]["price"], "cosmetic cost deducted")
	_check(GameState.is_wearing("hoodie_red"), "buying a cosmetic equips it")
	_check(GameState.cosmetic_color("outfit", "x") == GameData.COSMETICS["hoodie_red"]["color"], "outfit color reflects equip")
	_check(GameState.equip_cosmetic("hoodie_gray"), "re-equip a previously owned cosmetic")
	_check(GameState.is_wearing("hoodie_gray"), "switched back to gray")
	GameState.equip_cosmetic("hoodie_red")  # leave red on for the save test

	# --- save / load round-trip ---
	# Finish the quest line first so load's stats_changed can't fire a pending
	# objective reward and skew the restored values.
	GameState.quest_index = GameData.QUESTS.size()
	GameState.cash = 777
	GameState.botnet_size = 9
	GameState.reputation = 15
	GameState.status_seen = 3
	GameState.add_item("old_gpu")
	GameState.skills["stealth"] = 2
	GameState.save_game()
	_check(GameState.has_save(), "save file written")
	var peek := GameState.peek_save()
	_check(peek.get("cash", -1) == 777, "peek_save reads cash without loading")
	_check(peek.has("day") and peek.has("level"), "peek_save returns day and level")
	# Scramble live state, then load should restore the saved snapshot.
	GameState.cash = 0
	GameState.botnet_size = 0
	GameState.reputation = 0
	GameState.status_seen = 0
	GameState.skills["stealth"] = 0
	GameState.inventory.clear()
	GameState.owned_cosmetics = ["hoodie_gray", "hat_none"] as Array[String]
	GameState.equipped = {"outfit": "hoodie_gray", "hat": "hat_none"}
	_check(GameState.load_game(), "load returns true")
	_check(GameState.cash == 777, "cash restored from save")
	_check(GameState.botnet_size == 9, "botnet restored from save")
	_check(GameState.reputation == 15, "reputation restored from save")
	_check(GameState.status_seen == 3, "status_seen restored from save")
	_check(GameState.skills["stealth"] == 2, "skill ranks restored from save")
	_check(GameState.inventory.get("old_gpu", 0) == 1, "inventory restored from save")
	_check(GameState.owns_cosmetic("hoodie_red"), "owned cosmetics restored from save")
	_check(GameState.is_wearing("hoodie_red"), "equipped cosmetic restored from save")
	_check(typeof(GameState.cash) == TYPE_INT, "loaded ints stay ints")
	_check(not GameState.is_new_game, "load clears new-game flag")

	# --- new game wipes save ---
	GameState.new_game()
	_check(not GameState.has_save(), "new_game deletes save file")
	_check(GameState.cash == 15 and GameState.is_new_game, "new_game resets defaults")

	# --- street life: ambient traffic path-follower (G7) ---
	var VehicleScript := load("res://scripts/iso/vehicle_3d.gd")
	var loop := PackedVector2Array([
		Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)])
	var car: Node3D = Node3D.new()
	car.set_script(VehicleScript)
	add_child(car)
	car.setup(loop, 5.0, Color(0.5, 0.5, 0.6))
	var car_start := car.position
	for i in 30:
		car._process(0.1)  # ~3m/frame * 30 ≈ a full lap, exercising the wrap
	_check(car.position.distance_to(car_start) >= 0.0 and is_finite(car.position.x)
			and is_finite(car.position.z), "traffic car drives its lane and stays finite")
	# A second car skipped halfway round the loop must start elsewhere.
	var car2: Node3D = Node3D.new()
	car2.set_script(VehicleScript)
	add_child(car2)
	car2.setup(loop, 5.0, Color(0.5, 0.5, 0.6))
	car2.skip_ahead(20.0)  # half of the 40m perimeter
	_check(car2.position.distance_to(Vector3(0, 0, 0)) > 1.0, "skip_ahead staggers cars along the loop")
	car.queue_free()
	car2.queue_free()

	# A hoverboarder builds its deck on spawn (rider mode).
	var rider: Node3D = load("res://assets/iso/characters/char_citizen.tscn").instantiate()
	rider.set_script(load("res://scripts/iso/wanderer_3d.gd"))
	rider.rider = true
	add_child(rider)  # _ready() runs here and builds the board
	_check(rider.get("_board") != null, "hoverboarder spawns with a glowing deck")
	rider.queue_free()

	# --- combat core (G6) ---
	var CombatSession := load("res://scripts/combat/combat_session.gd")
	# Overwhelming player one-shots a weak enemy → WIN.
	var cs1 = CombatSession.new()
	cs1.init({"attack": 100, "defense": 5, "integrity": 50, "crit": 0.0, "stealth": 0}, "script_kid", 1)
	cs1.player_exploit()
	_check(cs1.outcome == cs1.WIN, "combat: strong player wins")
	# Hopeless player vs the boss → LOSE within a bounded number of turns.
	var cs2 = CombatSession.new()
	cs2.init({"attack": 0, "defense": 0, "integrity": 6, "crit": 0.0, "stealth": 0}, "r10t", 1)
	var cguard := 0
	while cs2.outcome == cs2.ONGOING and cguard < 60:
		cs2.player_firewall()
		cguard += 1
	_check(cs2.outcome == cs2.LOSE, "combat: hopeless player loses")
	# Bosses / trace units can't be fled.
	var cs3 = CombatSession.new()
	cs3.init({"attack": 1, "defense": 99, "integrity": 200, "crit": 0.0, "stealth": 9}, "tracker_unit", 1)
	cs3.player_jack_out()
	_check(cs3.outcome != cs3.FLED, "combat: trace unit can't be fled")
	# A flee-able enemy with a smoke + stealth escapes (loop beats the 5% miss).
	var fled := 0
	for i in 20:
		var cs = CombatSession.new()
		cs.init({"attack": 1, "defense": 99, "integrity": 200, "crit": 0.0, "stealth": 5}, "script_kid", -1)
		cs.player_program({"flee_bonus": 1.0}, "Proxy Smoke")
		if cs.outcome == cs.ONGOING:
			cs.player_jack_out()
		if cs.outcome == cs.FLED:
			fled += 1
	_check(fled > 0, "combat: JACK OUT can succeed when flee-able")
	# Combat items surface as PROGRAM options and are guarded outside fights.
	GameState.new_game()
	GameState.add_item("logic_bomb")
	var has_bomb := false
	for p in CombatSession.available_programs(GameState.inventory):
		if p.id == "logic_bomb":
			has_bomb = true
	_check(has_bomb, "combat: owned combat items appear as PROGRAM options")
	var bomb_count: int = GameState.inventory.get("logic_bomb", 0)
	_check(not GameState.use_consumable("logic_bomb"), "combat item can't be used outside a fight")
	_check(GameState.inventory.get("logic_bomb", 0) == bomb_count, "refused combat item is not consumed")

	# --- encounter gating (G6 phase 3) ---
	var Main3D := load("res://scripts/iso/main_3d.gd")
	var erng := RandomNumberGenerator.new()
	erng.seed = 99
	_check(Main3D.roll_encounter(0, 0, false, 7, erng) == "", "no ambush below Operator status")
	_check(Main3D.roll_encounter(3, 50, false, 0, erng) == "", "no ambush without offense")
	var got_fight := false
	var got_r10t := false
	for i in 300:
		var e: String = Main3D.roll_encounter(3, 100, false, 7, erng)
		if e != "":
			got_fight = true
		if e == "r10t":
			got_r10t = true
	_check(got_fight, "high heat/status can spring an ambush")
	_check(got_r10t, "R10T can appear as a boss when unbeaten")
	var r10t_again := false
	for i in 300:
		if Main3D.roll_encounter(3, 100, true, 7, erng) == "r10t":
			r10t_again = true
	_check(not r10t_again, "R10T won't reappear once beaten")
	# The R10T flag survives a save/load round-trip, then clean up the save.
	GameState.new_game()
	GameState.r10t_beaten = true
	GameState.save_game()
	GameState.r10t_beaten = false
	GameState.load_game()
	_check(GameState.r10t_beaten, "r10t_beaten persists across save/load")
	GameState.new_game()

	if _failures.is_empty():
		print("SMOKE TEST PASSED")
	else:
		for f in _failures:
			print("SMOKE TEST FAIL: " + f)
	get_tree().quit(0 if _failures.is_empty() else 1)
