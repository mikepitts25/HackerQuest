extends Node
## Headless smoke test. Boots the real main scene and drives the core loop:
## shop purchase, every terminal command, jobs, sleep, and the heat bust.
## Run with:
##   godot --headless res://tests/smoke_test.tscn

var _failures: Array[String] = []

class FakeMain:
	extends Node
	var current_district_id := "drowned_quarter"
	var forced_street_enemy := ""
	var street_combat_started := ""
	func go_to(_district_id: String, _spawn_id: String) -> void:
		pass
	func talk_wanderer(_npc_name: String) -> void:
		pass
	func talk_npc(_npc_id: String) -> void:
		pass
	func open_pet_shop() -> void:
		pass
	func roll_street_encounter(_district_id: String) -> String:
		return forced_street_enemy
	func start_street_combat(enemy_id: String) -> void:
		street_combat_started = enemy_id


func _check(cond: bool, what: String) -> void:
	if not cond:
		_failures.append(what)


func _controls_fit_within(node: Node, rect: Rect2) -> bool:
	if node is Control and node.visible:
		var control := node as Control
		var bounds := control.get_global_rect()
		if bounds.position.x < rect.position.x - 0.5:
			return false
		if bounds.position.y < rect.position.y - 0.5:
			return false
		if bounds.end.x > rect.end.x + 0.5:
			return false
		if bounds.end.y > rect.end.y + 0.5:
			return false
		if node is ScrollContainer:
			return true
	for child in node.get_children():
		if not _controls_fit_within(child, rect):
			return false
	return true


func _action_prompt_wraps(hud: Control) -> bool:
	var button := hud.get_node_or_null("ActionButton") as Button
	var label := hud.get_node_or_null("ActionButton/ActionPromptLabel") as Label
	if button == null or label == null:
		return false
	if label.autowrap_mode == TextServer.AUTOWRAP_OFF:
		return false
	if label.get_global_rect().end.x > button.get_global_rect().end.x + 0.5:
		return false
	if label.get_global_rect().end.y > button.get_global_rect().end.y + 0.5:
		return false
	return label.text == "Greet a food-cart cook"


func _find_label_starting_at(node: Node, prefix: String) -> Label:
	if node is Label and node.is_visible_in_tree() and (node as Label).text.begins_with(prefix):
		return node as Label
	for child in node.get_children():
		var found := _find_label_starting_at(child, prefix)
		if found != null:
			return found
	return null


func _find_label_containing(node: Node, text: String) -> Label:
	if node is Label and node.is_visible_in_tree() and (node as Label).text.contains(text):
		return node as Label
	for child in node.get_children():
		var found := _find_label_containing(child, text)
		if found != null:
			return found
	return null


func _hud_feed_shows(hud: Control, text: String) -> bool:
	var feed := hud.get_node_or_null("ChatFeed") as PanelContainer
	if feed == null or not feed.visible:
		return false
	return _find_label_containing(feed, text) != null


func _first_rich_text(node: Node) -> RichTextLabel:
	if node is RichTextLabel:
		return node as RichTextLabel
	for child in node.get_children():
		var found := _first_rich_text(child)
		if found != null:
			return found
	return null


func _modal_panel_for_title(hud: Control, title_prefix: String) -> Control:
	var title := _find_label_starting_at(hud, title_prefix)
	if title == null:
		return null
	var node: Node = title
	while node != null and not (node is PanelContainer):
		node = node.get_parent()
	if node == null:
		return null
	return node as Control


func _modal_panel_fits_viewport(hud: Control, title_prefix: String) -> bool:
	var panel := _modal_panel_for_title(hud, title_prefix)
	if panel == null:
		return false
	var bounds := panel.get_global_rect()
	var viewport := Rect2(Vector2.ZERO, hud.get_viewport_rect().size)
	return bounds.position.x >= viewport.position.x - 0.5 \
			and bounds.position.y >= viewport.position.y - 0.5 \
			and bounds.end.x <= viewport.end.x + 0.5 \
			and bounds.end.y <= viewport.end.y + 0.5


func _modal_contents_fit_panel(hud: Control, title_prefix: String) -> bool:
	var panel := _modal_panel_for_title(hud, title_prefix)
	if panel == null:
		return false
	return _controls_fit_within(panel, panel.get_global_rect())


func _phone_messages_use_modal_width(hud: Control) -> bool:
	var sender := _find_label_starting_at(hud, "CITY WIRE")
	if sender == null:
		return false
	var node: Node = sender
	while node != null and not (node is PanelContainer):
		node = node.get_parent()
	if node == null:
		return false
	var message_panel := node as Control
	while node != null and not (node is ScrollContainer):
		node = node.get_parent()
	if node == null:
		return false
	var scroll := node as Control
	return message_panel.get_global_rect().size.x >= scroll.get_global_rect().size.x - 4.0


func _count_nodes_with_script(node: Node, script_path: String) -> int:
	var count := 0
	var script: Variant = node.get_script()
	if script is Script and script.resource_path == script_path:
		count += 1
	for child in node.get_children():
		count += _count_nodes_with_script(child, script_path)
	return count


func _has_label3d_text(node: Node, text: String) -> bool:
	if node is Label3D and (node as Label3D).text.contains(text):
		return true
	for child in node.get_children():
		if _has_label3d_text(child, text):
			return true
	return false


func _first_in_group_under(node: Node, group_name: String) -> Node:
	if node.is_in_group(group_name):
		return node
	for child in node.get_children():
		var found := _first_in_group_under(child, group_name)
		if found != null:
			return found
	return null


func _ready() -> void:
	await get_tree().process_frame
	GameState.lock_ui()
	GameState.new_game()  # deterministic start, clears any prior save
	_check(not GameState.is_ui_locked(), "new_game clears stale UI locks")
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame

	var hud: Control = main.get_node("UILayer/HUD")
	var shop: Panel = main.get_node("UILayer/Shop")
	var terminal: Panel = main.get_node("UILayer/Terminal")

	# --- HUD controls ---
	GameState.notify("STATIC FEED CHECK", GameState.COL_INFO)
	await get_tree().process_frame
	_check(_hud_feed_shows(hud, "STATIC FEED CHECK"), "HUD chat feed persists toast messages")
	GameState.prompt_changed.emit("Greet a food-cart cook")
	await get_tree().process_frame
	_check(_action_prompt_wraps(hud), "action prompt wraps inside action button")
	GameState.prompt_changed.emit("")
	_check(hud.get_node_or_null("GodTestButton") != null, "temporary god test button exists")

	# --- modal layout ---
	hud.close_blocking_ui()
	hud.show_furnish()
	var furnish_modal: Dictionary = hud.get("_furnish_modal")
	for i in 18:
		hud.call("_add_row", furnish_modal, "Overflow row %02d" % i,
				"This forces a tall modal so the shared shell must scroll instead of centering content offscreen.",
				"", true, Callable())
	await get_tree().process_frame
	_check(_modal_panel_fits_viewport(hud, "FURNISH"), "tall modal panel fits viewport")
	_check(_modal_contents_fit_panel(hud, "FURNISH"), "tall modal contents stay inside panel")
	hud.close_blocking_ui()
	hud.call("_open_phone")
	await get_tree().process_frame
	_check(_phone_messages_use_modal_width(hud), "burner phone messages use modal width")
	hud.close_blocking_ui()

	# --- shop / upgrades ---
	_check(not GameState.buy_upgrade("used_laptop"), "laptop should be unaffordable at start")
	GameState.add_cash(1000)
	shop.open()
	_check(GameState.buy_upgrade("used_laptop"), "buy laptop")
	_check(GameState.has_computer, "has_computer set")
	_check(GameState.max_cpu == 6 and GameState.cpu == 6, "laptop grants 6 CPU")
	_check(GameState.buy_upgrade("vpn"), "buy vpn (prereq satisfied)")
	_check(not GameState.buy_upgrade("vpn"), "vpn not buyable twice")
	_check(not GameData.UPGRADES.has("robo_pet"), "robot dog moved out of pawn upgrades")
	shop.close_shop()

	# --- pet shop / companion perks ---
	_check(GameData.PETS.has("dog") and GameData.PETS.has("cat") and GameData.PETS.has("bird"),
			"pet shop carries dog, cat, and bird companions")
	GameState.cash = 5000
	GameState.skills["hustle"] = 0
	GameState.skills["stealth"] = 0
	GameState.owned_pets = [] as Array[String]
	GameState.active_pet = ""
	var atk_before := GameState.total_cyber_attack()
	_check(GameState.buy_pet("dog"), "buy dog companion")
	_check(GameState.active_pet == "dog", "first bought pet becomes active")
	_check(GameState.total_cyber_attack() == atk_before + int(GameData.PETS["dog"].attack),
			"dog companion grants attack")
	_check(GameState.buy_pet("cat"), "buy cat companion")
	GameState.equip_pet("cat")
	_check(GameState.combat_stats().stealth == int(GameData.PETS["cat"].stealth),
			"cat companion grants stealth")
	var base_hustle := 1.0 + 0.15 * GameState.skill("hustle")
	_check(GameState.buy_pet("bird"), "buy bird companion")
	GameState.equip_pet("bird")
	_check(GameState.hustle_mult() > base_hustle, "bird companion boosts cash multiplier")
	hud.show_pet_shop()
	await get_tree().process_frame
	_check(_modal_panel_fits_viewport(hud, "PET SHOP"), "pet shop modal fits viewport")
	hud.close_blocking_ui()

	# --- terminal commands ---
	GameState.cpu = 10
	GameState.max_cpu = 18
	GameState.energy = 0
	GameState.max_energy = 16
	GameState.heat = 89
	GameState.cash = 456
	terminal.open()
	GameState.stats_changed.emit()
	await get_tree().process_frame
	_check(_controls_fit_within(terminal, terminal.get_global_rect()), "terminal controls fit viewport under long stats")
	GameState.heat = 0
	GameState.energy = 5
	GameState.cpu = GameState.max_cpu
	GameState.stats_changed.emit()
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

	# --- field gigs: accept from the board, complete out in the city ---
	GameState.active_jobs.clear()
	GameState.energy = 9
	cash_before = GameState.cash
	_check(GameState.accept_job("fix_router"), "accept a gig (no energy spent)")
	_check(GameState.has_active_job("fix_router"), "gig is now active")
	var first_job: Dictionary = GameState.active_jobs[0]
	_check(first_job.get("template", "") == "fix_router", "accepted gig becomes a generated instance")
	_check(first_job.get("district", "") != "home", "generated gig never targets the apartment")
	_check(first_job.has("pos") and first_job.pos.size() == 2, "generated gig has a field position")
	_check(first_job.get("steps_total", 0) >= 2, "generated gig requires multiple field steps")
	_check(first_job.get("cash", 0) != GameData.JOBS["fix_router"].cash or first_job.get("energy", 0) != GameData.JOBS["fix_router"].energy,
			"generated gig randomizes reward or effort")
	_check(first_job in GameState.active_jobs_in(first_job.district), "gig is flagged in its target district")
	_check(not GameState.accept_job("fix_router"), "can't re-accept the same gig")
	var e_job := GameState.energy
	_check(GameState.complete_job(first_job.uid), "work the first gig step at its marker")
	_check(GameState.has_active_job("fix_router"), "multi-step gig stays active after first step")
	_check(GameState.cash == cash_before, "multi-step gig does not pay until final step")
	_check(GameState.energy == e_job - first_job.energy, "gig spent its energy when worked, not when accepted")
	while GameState.has_active_job("fix_router"):
		GameState.energy = 9
		_check(GameState.complete_job(first_job.uid), "complete another gig step")
	_check(GameState.cash > cash_before, "gig paid on final step")
	_check(not GameState.has_active_job("fix_router"), "completed gig clears from active")
	GameState.energy = 9
	GameState.cpu = 0
	_check(GameState.accept_job("neighbor_wifi"), "accept a tech gig")
	var tech_job: Dictionary = GameState.active_jobs[0]
	_check(tech_job.get("cpu", 0) > 0, "tech gig generated a CPU requirement")
	_check(not GameState.complete_job(tech_job.uid), "tech gig cannot be completed without CPU")
	GameState.active_jobs.clear()
	GameState.cpu = GameState.max_cpu
	# No active-gig cap.
	GameState.accept_job("fix_router")
	GameState.accept_job("ewaste_run")
	_check(GameState.accept_job("courier"), "third gig accepted after removing the queue cap")
	_check(GameState.active_jobs.size() == 3, "can hold more than two gigs at once")
	# Persist across save/load.
	GameState.save_game()
	GameState.active_jobs = []
	GameState.load_game()
	_check(GameState.active_jobs.size() == 3, "active gigs persist across save/load")
	_check(GameState.active_jobs[0] is Dictionary, "generated active gigs persist as instance data")
	GameState.active_jobs.clear()

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
	GameState.cash = 0
	GameState.reputation = 0
	GameState.status_seen = 0
	GameState.grant_debug_god_mode()
	_check(GameState.cash == 99999, "god test mode grants cash")
	_check(GameState.status_title() == "Legend", "god test mode grants max status")
	_check(GameState.status_seen == GameState.status_index(), "god test mode suppresses rank reward spam")
	var plaza3d: Node3D = load("res://scenes/iso/districts/plaza_3d.tscn").instantiate()
	add_child(plaza3d)
	plaza3d.build(FakeMain.new())
	await get_tree().process_frame
	_check(_has_label3d_text(plaza3d, "Pix\n(starter mentor)"), "named NPC labels include role descriptions")
	_check(_has_label3d_text(plaza3d, "PET SHOP"), "plaza has a visible pet shop")
	remove_child(plaza3d)
	plaza3d.queue_free()

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
	_check(GameData.TARGETS.has("motherlode_vault"), "cryptogram motherlode target exists")
	_check(GameData.CRYPTOGRAM_CLUES.size() >= 4, "cryptogram clues are scattered through districts")
	GameState.solved_cryptograms = [] as Array[String]
	_check(not GameState.cryptogram_complete(), "cryptogram trail starts incomplete")
	_check(not GameState.target_unlocked("motherlode_vault"), "motherlode target is locked until clues are solved")
	for clue in GameData.CRYPTOGRAM_CLUES:
		GameState.solve_cryptogram(str(clue.id))
	_check(GameState.cryptogram_complete(), "solving every cryptogram completes the trail")
	_check(GameState.target_unlocked("motherlode_vault"), "motherlode target unlocks after cryptogram completion")

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
	for npc_id in GameData.NPCS:
		_check(str(GameData.NPCS[npc_id].get("role", "")) != "", "%s has a role label" % npc_id)
	for district_id in ["plaza", "market", "underpass", "corp_row", "darknet", "drowned_quarter"]:
		_check(district_id in GameData.NPC_SCHEDULE["riot"], "Riot has a scheduled encounter in %s" % district_id)
		var rlines: Array = NpcDialogs.riot_lines_for_district(district_id)
		_check(rlines.size() >= 2 and str(rlines[0]).contains("Riot:"), "Riot has district dialogue in %s" % district_id)
		_check(GameData.RIOT_CREW_BY_DISTRICT.has(district_id), "R10T crew has a mini-boss in %s" % district_id)
		var crew_id: String = GameData.RIOT_CREW_BY_DISTRICT[district_id]
		_check(GameData.ENEMIES.has(crew_id), "R10T crew mini-boss enemy exists for %s" % district_id)
		_check(GameData.ENEMIES[crew_id].get("crew", "") == "r10t", "mini-boss is tagged as R10T crew")
		var crew_loot: Dictionary = GameData.ENEMIES[crew_id].get("loot", {})
		_check(crew_loot.has("gear") and GameData.GEAR.has(crew_loot.gear), "mini-boss drops notable gear in %s" % district_id)
		_check(GameData.GEAR[crew_loot.gear].get("crew_drop", false), "mini-boss gear is marked as crew-drop progression gear")
	_check(GameData.TARGETS["corp_mail_relay"].get("district_tier", 0) >= 4, "corp mail relay carries a district tier")
	_check(GameData.TARGETS["corp_mail_relay"].get("required_gear", "") == "rig_tunnel_splice",
			"corp row hacking expects the previous district boss rig")
	GameState.owned_gear = [] as Array[String]
	GameState.gear = {}
	var corp_odds_without: float = terminal.call("_chance", GameData.TARGETS["corp_mail_relay"])
	GameState.owned_gear = ["rig_tunnel_splice"] as Array[String]
	GameState.equip_gear("rig_tunnel_splice")
	var corp_odds_with: float = terminal.call("_chance", GameData.TARGETS["corp_mail_relay"])
	_check(corp_odds_with > corp_odds_without + 0.20, "previous district boss rig materially improves next-tier hack odds")
	terminal.open()
	terminal._on_submit("scan")
	var term_output := _first_rich_text(terminal)
	var term_text := term_output.get_parsed_text() if term_output != null else ""
	_check(term_text.contains("tier 4") and term_text.contains("Corp Row"),
			"terminal scan shows target district tier")
	terminal._on_submit("inspect corp_mail_relay")
	term_text = term_output.get_parsed_text() if term_output != null else ""
	_check(term_text.contains("recommended rig") and term_text.contains("Tunnel Splice"),
			"terminal inspect names the progression rig for that tier")
	terminal.close_terminal()
	GameState.inventory.clear()
	GameState.add_item("stolen_data", 2)
	GameState.add_item("old_gpu", 6)
	GameState.cash = 1000
	GameState.heat = 60
	GameState.fixer_used = false
	var service_cash_before := GameState.cash
	var service_heat_before := GameState.heat
	var service_data_before: int = GameState.inventory.get("stolen_data", 0)
	var service_parts_before: int = GameState.inventory.get("old_gpu", 0)
	var service_skill_before := GameState.skill_points
	NpcDialogs.lines_for("vex")
	NpcDialogs.lines_for("marlowe")
	NpcDialogs.lines_for("tess")
	NpcDialogs.lines_for("sparks")
	NpcDialogs.lines_for("ozark")
	_check(NpcDialogs.needs_confirmation("vex"), "Vex requires confirmation before fencing data")
	_check(NpcDialogs.needs_confirmation("marlowe"), "Marlowe requires confirmation before taking cash")
	_check(NpcDialogs.needs_confirmation("tess"), "Tess requires confirmation before training")
	_check(NpcDialogs.needs_confirmation("sparks"), "Sparks requires confirmation before buying parts")
	_check(NpcDialogs.needs_confirmation("ozark"), "Ozark requires confirmation before taking bounty parts")
	_check(GameState.cash == service_cash_before, "NPC dialog previews do not spend or pay cash")
	_check(GameState.heat == service_heat_before, "NPC dialog previews do not scrub heat")
	_check(GameState.inventory.get("stolen_data", 0) == service_data_before, "NPC dialog previews do not consume items")
	_check(GameState.inventory.get("old_gpu", 0) == service_parts_before, "NPC dialog previews do not consume junk parts")
	_check(GameState.skill_points == service_skill_before, "NPC dialog previews do not grant skill points")
	GameState.inventory.clear()
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
	GameState.wifi_backdoors = {}
	GameState.botnet_size = 0
	GameState.cpu = GameState.max_cpu
	GameState.energy = 5
	var seeded := false
	for i in 8:
		GameState.wifi_current = {"ssid": "CorpGuest_%d" % i, "enc": 0, "bars": 4, "district": "corp_row"}
		var seeded_res := GameState.crack_wifi()
		if seeded_res.get("ok", false):
			seeded = true
			break
		GameState.cpu = GameState.max_cpu
		GameState.energy = 5
	_check(seeded, "wifi crack can seed a district backdoor")
	_check(GameState.botnet_size >= 1, "wifi crack seeds botnet nodes")
	_check(GameState.wifi_backdoor_bonus("corp_row") > 0.0, "district backdoor grants a hack odds bonus")
	var backdoor_target: Dictionary = GameData.TARGETS["corp_mail_relay"]
	_check(GameState.target_wifi_backdoor_modifier(backdoor_target) > 0.0,
			"target reads matching district wifi backdoor bonus")
	var rep_before_backdoor_odds := GameState.reputation
	GameState.reputation = 0
	var odds_with_backdoor: float = terminal.call("_chance", backdoor_target)
	GameState.wifi_backdoors = {}
	var odds_without_backdoor: float = terminal.call("_chance", backdoor_target)
	GameState.reputation = rep_before_backdoor_odds
	_check(odds_with_backdoor > odds_without_backdoor, "wifi backdoor improves terminal hack chance")

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
	var final_hint: String = GameState.final_contract_hint() if GameState.has_method("final_contract_hint") else ""
	_check(final_hint.contains("Kill the machine") and final_hint.contains("ai_datacenter"),
			"trunk hint names the final contract and target")
	GameState.completed_contracts.append(GameState.final_contract_id())
	GameState.inventory.erase("r10t_root_key")
	_check(not GameState.trunk_ready(), "final contract alone does not unlock the trunk")
	_check(GameState.trunk_prompt().contains("R10T"), "trunk prompt names the missing Riot key")
	GameState.add_item("r10t_root_key")
	_check(GameState.trunk_ready(), "R10T key plus final contract unlocks the trunk")
	_check(GameState.trunk_prompt() == "Jack into the trunk", "ready trunk uses jack-in prompt")

	# --- corp jobs are a separate board ---
	var corp_count := 0
	for jid in GameData.JOBS:
		if GameData.JOBS[jid].get("board", "plaza") == "corp":
			corp_count += 1
	_check(corp_count >= 2, "corp gig board has its own jobs")
	_check(GameData.TRASH_TABLES["underpass"].scrap == [3, 8], "underpass trash cash is tuned down")
	_check(GameData.TRASH_TABLES["market"].scrap == [2, 5], "market trash cash is tuned down")
	_check(GameData.TRASH_TABLES["corp_row"].scrap == [2, 4], "corp row trash cash is tuned down")
	_check(GameData.TRASH_TABLES["default"].scrap == [2, 4], "default trash cash is tuned down")

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

	# --- street encounters: contact NPCs trigger fights, then flee afterward ---
	var street_fake := FakeMain.new()
	street_fake.current_district_id = "plaza"
	street_fake.forced_street_enemy = "street_hacker"
	var street_district: Node3D = load("res://scenes/iso/districts/plaza_3d.tscn").instantiate()
	add_child(street_district)
	street_district.build(street_fake)
	await get_tree().process_frame
	var hostile := _first_in_group_under(street_district, "street_encounter")
	var hostile_trigger := _first_in_group_under(street_district, "street_encounter_trigger")
	_check(hostile != null, "street encounter spawns a visible hostile NPC")
	_check(hostile_trigger != null, "street encounter has a collision trigger")
	if hostile_trigger != null and hostile_trigger.has_method("interact"):
		hostile_trigger.call("interact")
	_check(street_fake.street_combat_started == "street_hacker", "street encounter contact starts combat")
	if street_district.has_method("resolve_street_encounter"):
		street_district.call("resolve_street_encounter", "street_hacker", "win")
		await get_tree().process_frame
		_check(hostile != null and hostile.get_meta("street_fleeing", false), "street encounter NPC taunts and flees after combat")
	else:
		_check(false, "district can resolve street encounter aftermath")
	remove_child(street_district)
	street_district.queue_free()

	# --- combat core (G6) ---
	var CombatSession := load("res://scripts/combat/combat_session.gd")
	# Overwhelming player one-shots a weak enemy → WIN.
	var cs1 = CombatSession.new()
	cs1.init({"attack": 100, "defense": 5, "integrity": 50, "crit": 0.0, "stealth": 0}, "script_kid", 1)
	cs1.player_exploit()
	_check(cs1.outcome == cs1.WIN, "combat: strong player wins")
	var combat_anim_panel: Panel = load("res://scenes/ui/combat.tscn").instantiate()
	add_child(combat_anim_panel)
	combat_anim_panel.start("script_kid")
	_check(combat_anim_panel.visible and combat_anim_panel.get_meta("animating_in", false),
			"combat panel animates in when a fight starts")
	var anim_session = combat_anim_panel.get("_session")
	anim_session.outcome = anim_session.WIN
	combat_anim_panel.call("_on_continue")
	await get_tree().process_frame
	_check(combat_anim_panel.get_meta("animating_out", false), "combat panel animates away after a fight")
	await get_tree().create_timer(0.25).timeout
	remove_child(combat_anim_panel)
	combat_anim_panel.queue_free()
	var combat_panel: Panel = load("res://scenes/ui/combat.tscn").instantiate()
	add_child(combat_panel)
	combat_panel.visible = true
	var boss_session = CombatSession.new()
	boss_session.init({"attack": 999, "defense": 99, "integrity": 999, "crit": 0.0, "stealth": 0}, "r10t", 1)
	boss_session.player_exploit()
	combat_panel.set("_session", boss_session)
	GameState.inventory.erase("r10t_root_key")
	combat_panel.call("_award_loot")
	await get_tree().process_frame
	var burst := combat_panel.get_node_or_null("BossBurstOverlay")
	_check(burst != null and burst.visible, "combat: R10T win shows boss burst overlay")
	_check(_find_label_containing(combat_panel, "R10T DOWN") != null, "combat: boss burst names the defeated boss")
	_check(GameState.inventory.get("r10t_root_key", 0) == 1, "R10T drops the trunk root key")
	remove_child(combat_panel)
	combat_panel.queue_free()
	var early_r10t = CombatSession.new()
	early_r10t.init({"attack": 18, "defense": 18, "integrity": 80, "crit": 0.15, "stealth": 3,
			"endgame_loadout": false}, "r10t", 4)
	var early_guard := 0
	while early_r10t.outcome == early_r10t.ONGOING and early_guard < 80:
		early_r10t.player_exploit()
		early_guard += 1
	_check(early_r10t.outcome == early_r10t.LOSE, "combat: R10T is overpowering before top-end gear")
	_check(early_r10t.enemy_max >= 180 and early_r10t.enemy.attack >= 26, "combat: R10T gets an early-game overpower stat package")
	var geared_r10t = CombatSession.new()
	geared_r10t.init({"attack": 22, "defense": 18, "integrity": 95, "crit": 0.20, "stealth": 3,
			"endgame_loadout": true}, "r10t", 4)
	var geared_guard := 0
	while geared_r10t.outcome == geared_r10t.ONGOING and geared_guard < 80:
		geared_r10t.player_exploit()
		geared_guard += 1
	_check(geared_r10t.outcome == geared_r10t.WIN, "combat: top-end gear makes R10T beatable")
	GameState.owned_gear = ["rig_zeroday", "fw_black", "imp_ghost"] as Array[String]
	GameState.gear = {"rig": "rig_zeroday", "firewall": "fw_black", "implant": "imp_ghost"}
	GameState.upgrades = ["used_laptop", "ram_upgrade", "workstation", "server_rack", "quantum_rig"] as Array[String]
	_check(GameState.has_endgame_loadout(), "top-end purchased gear marks player ready for R10T")
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
	GameState.botnet_size = 20
	var has_flood := false
	var flood_entry := {}
	for p in CombatSession.available_programs(GameState.inventory, GameState.botnet_size):
		if p.id == "botnet_flood":
			has_flood = true
			flood_entry = p
	_check(has_flood, "combat: botnet flood appears as a PROGRAM when botnet is large enough")
	var bots_before_flood := GameState.botnet_size
	var heat_before_flood := GameState.heat
	var flood_payload: Dictionary = GameState.consume_botnet_flood()
	_check(flood_payload.get("ok", false), "combat: botnet flood payload can be consumed")
	_check(GameState.botnet_size == bots_before_flood - ceili(bots_before_flood * 0.5),
			"combat: botnet flood burns half the botnet")
	_check(GameState.heat > heat_before_flood, "combat: botnet flood adds heat")
	_check(flood_payload.get("combat", {}).get("damage", 0) >= 35, "combat: botnet flood hits hard")
	var flood_session = CombatSession.new()
	flood_session.init({"attack": 1, "defense": 1, "integrity": 80, "crit": 0.0, "stealth": 0}, "street_hacker", 2)
	var flood_enemy_before: int = flood_session.enemy_hp
	flood_session.player_program(flood_payload.combat, flood_payload.name)
	_check(flood_session.enemy_hp < flood_enemy_before, "combat: botnet flood damages the enemy")

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

	# --- fight-the-tracker trace resolution (G6 follow-up) ---
	GameState.start_trace("test")
	_check(GameState.trace_active, "trace starts active")
	GameState.defeat_trace()
	_check(not GameState.trace_active, "winning the trace fight ends the trace")
	GameState.new_game()
	GameState.cash = 100
	GameState.start_trace("test")
	GameState.lose_trace_fight()
	_check(not GameState.trace_active, "losing the trace fight ends the trace")
	_check(GameState.cash == 50, "losing the trace fight busts (half cash)")
	GameState.new_game()

	# --- apartments v2: furniture, style, trophies ---
	_check(GameState.style_score() == 0, "no furniture = no Style")
	GameState.cash = 5000
	GameState.reputation = 999  # unlock status-gated furniture for these checks
	var e0 := GameState.max_energy
	_check(GameState.buy_furniture("smart_bed"), "buy functional furniture")
	_check(GameState.owns_furniture("smart_bed"), "furniture marked owned")
	_check(GameState.max_energy == e0 + 3, "smart_bed raises max energy at purchase")
	_check(not GameState.buy_furniture("smart_bed"), "can't double-buy furniture")
	_check(GameState.style_score() == GameData.FURNITURE["smart_bed"].style, "Style reflects owned furniture")
	var home_script: Script = load("res://scripts/iso/districts/home_3d.gd")
	var furniture_visuals: Dictionary = home_script.get_script_constant_map().get("FURNITURE_VISUALS", {})
	_check(not furniture_visuals.has("smart_bed"), "smart bed upgrade does not render a second bed")
	GameState.buy_furniture("vpn_rack")
	GameState.buy_furniture("server_closet")
	_check(GameState.furniture_perk("cool") == 4, "VPN rack adds heat cooldown")
	_check(GameState.furniture_perk("income") == 20, "server closet adds daily income")
	GameState.reputation = 0
	_check(not GameState.buy_furniture("arcade_cab"), "high-status furniture is gated")

	# --- endgame district ambience ---
	var drowned: Node3D = load("res://scenes/iso/districts/drowned_quarter_3d.tscn").instantiate()
	add_child(drowned)
	drowned.build(FakeMain.new())
	await get_tree().process_frame
	_check(_count_nodes_with_script(drowned, "res://scripts/iso/wanderer_3d.gd") == 0,
			"drowned quarter does not spawn wandering NPCs")
	remove_child(drowned)
	drowned.queue_free()
	GameState.reputation = 999
	GameState.cash = 99999
	for fid in GameData.FURNITURE:
		GameState.buy_furniture(fid)
	_check(GameState.style_rep_per_day() > 0, "a stylish place pays a daily REP trickle")
	# trophies derive from milestones
	GameState.new_game()
	_check(GameState.trophies().is_empty(), "no trophies at the start")
	GameState.botnet_size = 1
	GameState.total_hacks = 1
	_check("first_bot" in GameState.trophies(), "botnet milestone earns a trophy")
	_check("first_pwn" in GameState.trophies(), "first hack earns a trophy")
	GameState.r10t_beaten = true
	_check("rival_down" in GameState.trophies(), "beating R10T earns a trophy")
	# persistence
	GameState.new_game()
	GameState.cash = 1000
	GameState.buy_furniture("potted_palm")
	GameState.save_game()
	GameState.owned_furniture = [] as Array[String]
	GameState.load_game()
	_check(GameState.owns_furniture("potted_palm"), "owned furniture persists across save/load")
	GameState.new_game()

	if _failures.is_empty():
		print("SMOKE TEST PASSED")
	else:
		for f in _failures:
			print("SMOKE TEST FAIL: " + f)
	get_tree().quit(0 if _failures.is_empty() else 1)
