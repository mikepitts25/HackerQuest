extends SceneTree
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func _initialize() -> void:
	if ProjectSettings.get_setting("application/config/custom_user_dir_name", "") != "HackerQuest-Work-QA":
		quit(2)
		return
	call_deferred("run")
func run() -> void:
	var service = load("res://scripts/work_system.gd")
	check(service != null, "Local work service exists")
	if service == null:
		print("FAIL: Local work service exists")
		quit(1)
		return
	var catalog = load("res://scripts/work_catalog.gd")
	var state = root.get_node("GameState")
	state.new_game()
	check(catalog.sources().size() == 18, "18 specialist sources")
	check(catalog.templates().size() >= 36, "36 authored tasks")
	for zone in ["plaza", "market", "underpass", "corp_row", "darknet", "drowned_quarter"]:
		var count := 0
		for source in catalog.sources().values():
			if source.district == zone: count += 1
		check(count == 3, zone + " has three sources")
	var offers: Array = service.offers(state, "plaza_board")
	check(offers == service.offers(state, "plaza_board"), "Terms deterministic")
	for offer in offers:
		check(service.accept(state, offer.uid), "Accept starter work")
		var uid: String = offer.uid
		var job: Dictionary = service.find(state, uid)
		while not job.is_empty():
			check(service.start(state, uid, int(job.step)), "Start starter stage")
			if not job.get("puzzle", {}).is_empty():
				while not service.find(state, uid).is_empty() and int(service.find(state, uid).step) == int(job.step):
					var current: Dictionary = service.find(state, uid)
					service.submit(state, uid, int(job.step), current.puzzle.answer[current.puzzle.progress])
			job = service.find(state, uid)
	check(state.cash >= 100, "Two safe tasks earn laptop")
	check(state.energy >= 0, "Starter tasks fit initial energy")
	check(not service.accept(state, offers[0].uid), "Cannot repeat claimed offer")
	check(not service.start(state, offers[0].uid, 1), "Duplicate completion is harmless")
	check(state.buy_upgrade("used_laptop"), "Buy earned laptop")
	state.cash = 10000
	check(not state.buy_gear("rig_sidewalk_slicer"), "Trophies cannot be bought")
	check(state.buy_gear("rig_script"), "Buy starter rig")
	check(state.gear.is_empty(), "Purchase does not silently equip")
	state.equip_gear("rig_script")
	check(is_equal_approx(service.gear_utility(state).pay, 0.1), "Rig work utility")
	state.save_game()
	var claims: Dictionary = state.work_claims.duplicate(true)
	state.work_claims = {}
	check(state.load_game(), "Reload work save")
	check(state.work_claims == claims, "Used offers persist")
	state.sleep()
	check(service.offers(state, "plaza_board")[0].uid != offers[0].uid, "New day offers refresh")
	state.new_game()
	state.active_pet="bird"
	state.owned_pets.assign(["bird"])
	check(service.offers(state,"plaza_board")[0].cash==53,"Companion bonus applies exactly once")
	# Technical terms and paid stage state survive retries, gear changes and reloads.
	state.new_game()
	state.has_computer = true
	state.cash = 10000
	state.buy_gear("rig_script")
	state.equip_gear("rig_script")
	state.buy_gear("imp_reflex")
	state.equip_gear("imp_reflex")
	var tech: Dictionary = service.offers(state,"market_pawn")[0]
	check(tech.bonus > 0,"Technical offers show rig bonus")
	check(service.accept(state,tech.uid),"Accept technical work")
	state.energy = 10
	state.cpu = 0
	check(not service.start(state,tech.uid,1),"Insufficient CPU rejects stage")
	check(state.energy==10,"CPU rejection does not consume energy")
	state.cpu = 10
	check(service.start(state,tech.uid,1),"Start technical stage")
	var energy_paid: int = state.energy
	var cpu_paid: int = state.cpu
	check(service.start(state,tech.uid,1),"Resume paid stage")
	check(state.energy==energy_paid and state.cpu==cpu_paid,"Resume never double charges")
	var current: Dictionary = service.find(state,tech.uid)
	var correct: int = current.puzzle.answer[0]
	service.submit(state,tech.uid,1,(correct+1)%4)
	check(service.find(state,tech.uid).puzzle.progress==0,"Wrong answer gives feedback without loss")
	check(service.hint(state,tech.uid).contains("Clue:"),"Implant provides a clue")
	state.save_game()
	state.active_jobs=[]
	state.load_game()
	check(service.find(state,tech.uid).puzzle.hints_used==1,"Clue use persists")
	check(state.energy==energy_paid and state.cpu==cpu_paid,"Paid costs persist")
	service.submit(state,tech.uid,1,correct,0)
	check(not service.submit(state,tech.uid,1,correct,0),"Stale puzzle callbacks cannot advance")
	state.gear={}
	state.sleep()
	check(service.find(state,tech.uid).cash==tech.cash,"Accepted price survives gear change and sleep")
	check(service.offers(state,"market_pawn")[0].locked=="Already active","Sleep cannot duplicate active template")
	check(service.abandon(state,tech.uid),"Can abandon work")
	check(not service.accept(state,tech.uid),"Abandon cannot reroll same day's offer")
	# New purchase goals, earned-only gear and unknown saves.
	service.set_goal(state,"battery")
	state.save_game()
	state.purchase_goal=""
	state.load_game()
	check(service.goal_info(state).id=="battery","Purchase goal persists")
	check(not state.buy_gear("missing_item"),"Unknown equipment rejected")
	state.grant_gear("rig_sidewalk_slicer")
	check(state.gear.is_empty(),"Trophy award does not silently equip")
	# Combat completion requires an explicitly associated paid stage.
	state.reputation=120
	state.status_seen=8
	state.energy=100
	state.cpu=100
	var combat_offer: Dictionary = service.offers(state,"corp_service")[1]
	check(GameData.ENEMIES[combat_offer.enemy].loot.cash==[0,0],"Contract encounters pay through agreed job terms only")
	check(service.accept(state,combat_offer.uid),"Accept guarded work")
	service.start(state,combat_offer.uid,1)
	service.start(state,combat_offer.uid,2)
	check(not service.start(state,combat_offer.uid,2),"Stale stage cannot spend next stage cost")
	service.start(state,combat_offer.uid,3)
	service.finish_combat(state,combat_offer.enemy,"win")
	check(not service.find(state,combat_offer.uid).is_empty(),"Unrelated victory does not settle job")
	state.work_battle=combat_offer.uid
	service.finish_combat(state,combat_offer.enemy,"fled")
	check(not service.find(state,combat_offer.uid).started,"Flee permits explicit paid retry")
	service.start(state,combat_offer.uid,3)
	state.work_battle=combat_offer.uid
	var before_win: int = state.cash
	service.finish_combat(state,combat_offer.enemy,"win")
	var after_win: int = state.cash
	service.finish_combat(state,combat_offer.enemy,"win")
	check(after_win>=before_win+combat_offer.cash and state.cash==after_win,"Combat settles exactly once")
	# Resolve real combat panel outcomes, then reload before pressing Continue.
	for verdict in ["win","lose"]:
		state.new_game()
		state.reputation=120
		state.status_seen=8
		state.has_computer=true
		state.energy=100
		state.cpu=100
		state.cash=1000
		var q: Dictionary = service.offers(state,"corp_service")[1]
		service.accept(state,q.uid)
		for step in [1,2,3]: service.start(state,q.uid,step)
		state.work_battle=q.uid
		var panel: Panel = load("res://scenes/ui/combat.tscn").instantiate()
		root.add_child(panel)
		var session = load("res://scripts/combat/combat_session.gd").new()
		session.init(state.combat_stats(),q.enemy,23)
		session.outcome=verdict
		panel.set("_session",session)
		panel.call("_apply_outcome")
		state.load_game()
		var pending: Dictionary = service.find(state,q.uid)
		check(pending.is_empty() if verdict=="win" else (not pending.is_empty() and not pending.started),"Result-screen reload preserves "+verdict)
		panel.queue_free()
		await process_frame
	state.new_game()
	service.set_goal(state,"battery")
	state.cash=110
	state.inventory={"stolen_data":1}
	state.sell_item("stolen_data")
	check(state.goal_announced,"Loot sale announces reached purchase goal")
	state.new_game()
	state.has_computer=true
	state.cpu=10
	var future: Dictionary = service.offers(state,"market_pawn")[0]
	service.accept(state,future.uid)
	state.active_jobs[0].source="unknown_saved_source"
	service.start(state,future.uid,1)
	while not service.find(state,future.uid).is_empty():
		var j: Dictionary = service.find(state,future.uid)
		service.submit(state,future.uid,1,int(j.puzzle.answer[int(j.puzzle.progress)]))
	check(service.find(state,future.uid).is_empty(),"Saved work with unknown source still completes")
	state.new_game()
	state.active_jobs=[state._generate_job_instance("fix_router")]
	var legacy: Dictionary = state.active_jobs[0].duplicate(true)
	state.save_game()
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(state.SAVE_PATH))
	for field in ["work_claims","tracked_job","purchase_goal","goal_announced"]: parsed.erase(field)
	var old_save := FileAccess.open(state.SAVE_PATH,FileAccess.WRITE)
	old_save.store_string(JSON.stringify(parsed))
	old_save.close()
	state.purchase_goal="battery"
	state.work_claims={"wrong_run":true}
	state.load_game()
	check(state.purchase_goal=="" and state.work_claims.is_empty(),"Old save defaults additive work fields")
	check(state.active_jobs[0].cash==legacy.cash and Vector2(state.active_jobs[0].pos[0],state.active_jobs[0].pos[1]).is_equal_approx(Vector2(legacy.pos[0],legacy.pos[1])) and state.active_jobs[0].step==legacy.step,"Legacy active job terms retained")
	# Heat quoted on acceptance includes protection/status and settles exactly.
	for change_vpn in [false,true]:
		state.new_game()
		state.reputation=25
		state.status_seen=4
		state.has_computer=true
		state.energy=100
		state.cpu=100
		state.cash=10000
		state.buy_gear("fw_foam")
		state.equip_gear("fw_foam")
		var risky: Dictionary = service.offers(state,"underpass_courier")[1]
		service.accept(state,risky.uid)
		if change_vpn: state.upgrades.append("vpn")
		for step in [1,2,3]: service.start(state,risky.uid,step)
		while not service.find(state,risky.uid).is_empty():
			var j: Dictionary = service.find(state,risky.uid)
			service.submit(state,risky.uid,3,int(j.puzzle.answer[int(j.puzzle.progress)]))
		check(state.heat==int(risky.heat),"Accepted heat is exact, regardless of later VPN change")
	state.new_game()
	state.reputation=120
	state.status_seen=8
	state.has_computer=true
	for d in range(1,40):
		state.day=d
		if state.daily_mult("jobs_plaza")==1.0 and state.daily_mult("jobs_corp")==1.0: break
	var report := []
	for source in ["plaza_board","market_pawn","underpass_utility","corp_board","darknet_rig","drowned_relay"]:
		var quotes: Array = service.offers(state,source)
		var q: Dictionary = quotes[0]
		report.append({"source":source,"job":q.name,"pay":q.cash,"energy":q.energy_total,"cpu":q.cpu_total,"food_allowance":int(q.energy_total)*4,"net_after_food":int(q.cash)-int(q.energy_total)*4})
	var report_file := FileAccess.open("/tmp/hackerquest-work-economy.json",FileAccess.WRITE)
	report_file.store_string(JSON.stringify(report,"\t"))
	report_file.close()
	if failures.is_empty(): print("LOCAL WORK TEST PASSED")
	else:
		for failure in failures: print("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)
