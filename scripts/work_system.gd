extends RefCounted
## Transactional local-work service. Persisted data stays in GameState's save blob.
const Catalog = preload("res://scripts/work_catalog.gd")

static func gear_utility(state: Node) -> Dictionary:
	var rigs := {"rig_script": 0.10, "rig_breaker": 0.15, "rig_zeroday": 0.20}
	var walls := {"fw_foam": 1, "fw_ice": 2, "fw_black": 3}
	var implants := {"imp_reflex": 1, "imp_neural": 2, "imp_ghost": 3}
	return {"pay": rigs.get(state.gear.get("rig", ""), 0.0),
		"heat": walls.get(state.gear.get("firewall", ""), 0),
		"clues": implants.get(state.gear.get("implant", ""), 0)}

static func offers(state: Node, source_id: String) -> Array:
	var all_sources := Catalog.sources()
	if not all_sources.has(source_id): return []
	var source: Dictionary = all_sources[source_id]
	var out := []
	var utility := gear_utility(state)
	var bkind := "jobs_corp" if int(source.tier) >= 3 else "jobs_plaza"
	var all_templates := Catalog.templates()
	for id in all_templates:
		var t: Dictionary = all_templates[id]
		if t.source != source_id: continue
		var uid := "work:%s:%d" % [id, state.day]
		var active := false
		for j in state.active_jobs:
			if j.get("local_work", false) and j.template == id: active = true
		var technical: bool = t.kind in ["repair", "signal", "decrypt", "contract"]
		var raw_heat := maxi(0,int(t.heat)-(int(utility.heat) if technical else 0))
		var quoted_heat: int = state.heat_gain(raw_heat)
		var heat_saved: int = state.heat_gain(int(t.heat))-quoted_heat
		var work_bonus: float = float(utility.pay) if technical else 0.0
		var multiplier: float = state.hustle_mult() * state.daily_mult(bkind) * state.mastery_mult(bkind)
		var base_pay := int(round(int(t.cash) * multiplier))
		var bonus := int(round(base_pay * work_bonus))
		var energy := 0
		var cpu := 0
		for stage in t.stages:
			energy += int(stage.energy)
			cpu += int(stage.cpu)
		var locked := ""
		if not state.district_unlocked(source.district): locked = "Zone locked"
		elif t.computer and not state.has_computer: locked = "Needs a laptop"
		elif active: locked = "Already active"
		elif state.work_claims.has(uid): locked = "Taken today"
		elif state.active_jobs.size() >= 3: locked = "Finish or abandon a job first"
		out.append({"uid": uid, "template": id, "source": source_id, "name": t.name,
			"kind": t.kind, "stages": t.stages.duplicate(true), "cash": base_pay + bonus,
			"base_pay": base_pay, "bonus": bonus, "energy_total": energy, "cpu_total": cpu,
			"heat": quoted_heat,
			"heat_saved": heat_saved,
			"xp": t.xp, "rep": t.rep, "enemy": t.enemy,
			"seed": hash(uid), "locked": locked, "local_work": true})
	return out

static func accept(state: Node, uid: String) -> bool:
	if state.work_claims.has(uid): return false
	for source_id in Catalog.sources():
		for offer in offers(state, source_id):
			if offer.uid != uid: continue
			if offer.locked != "":
				state.notify(offer.locked, state.COL_WARN)
				return false
			var job: Dictionary = offer.duplicate(true)
			job.erase("locked")
			job.step = 1
			job.steps_total = job.stages.size()
			job.started = false
			job.puzzle = {}
			job.archetype = {"repair":"wifi","signal":"recon","decrypt":"heist","contract":"heist","combat":"heist"}.get(job.kind,"drop")
			_set_stage(job)
			state.work_claims[uid] = true
			state.active_jobs.append(job)
			state.tracked_job = uid
			state.notify("Accepted: %s · agreed $%d" % [job.name, job.cash], state.COL_INFO)
			_changed(state)
			return true
	return false

static func find(state: Node, uid: String) -> Dictionary:
	for j in state.active_jobs:
		if j.get("uid", "") == uid and j.get("local_work", false): return j.duplicate(true)
	return {}

static func _put(state: Node, job: Dictionary) -> void:
	for i in state.active_jobs.size():
		if state.active_jobs[i].get("uid", "") == job.uid:
			state.active_jobs[i] = job
			return

static func _set_stage(job: Dictionary) -> void:
	var stage: Dictionary = job.stages[int(job.step)-1]
	job.district = stage.district
	job.pos = stage.pos.duplicate()
	job.objective = stage.objective
	job.prompt = ("Resume " if job.get("started", false) else "Start ") + str(stage.objective).to_lower()
	job.energy = int(stage.energy)
	job.cpu = int(stage.cpu)

static func start(state: Node, uid: String, expected_step: int) -> bool:
	if state.work_battle != "": return false
	var job := find(state, uid)
	if job.is_empty() or int(job.step) != expected_step: return false
	if not job.started:
		if state.energy < job.energy or state.cpu < job.cpu:
			state.notify("Need %d energy and %d CPU. Nothing spent." % [job.energy,job.cpu], state.COL_WARN)
			return false
		state.energy -= int(job.energy)
		state.cpu -= int(job.cpu)
		job.started = true
		var stage: Dictionary = job.stages[expected_step-1]
		if stage.kind in ["repair", "signal", "decrypt"]:
			job.puzzle = Catalog.challenge(stage.kind, int(job.seed) + expected_step)
			job.puzzle.clues = int(gear_utility(state).clues)
		_set_stage(job)
		_put(state, job)
		_changed(state)
	var stage: Dictionary = job.stages[expected_step-1]
	if stage.kind == "errand": _finish_stage(state, uid, expected_step)
	return true

static func submit(state: Node, uid: String, expected_step: int, choice: int, expected_progress := -1) -> bool:
	var job := find(state, uid)
	if job.is_empty() or int(job.step) != expected_step or not job.started or job.puzzle.is_empty(): return false
	var p: Dictionary = job.puzzle
	if expected_progress >= 0 and int(p.progress) != expected_progress: return false
	if choice < 0 or choice >= p.labels.size(): return false
	p.attempts = int(p.attempts) + 1
	var correct: bool = choice == int(p.answer[int(p.progress)])
	if correct:
		p.progress = int(p.progress) + 1
		p.feedback = "Correct. Link %d of %d restored." % [p.progress,p.answer.size()]
	else:
		p.feedback = "That component is OK; choose the next FAILED component." if p.kind == "repair" else "That is not the next entry. Follow the displayed order; your correct entries are kept."
	_put(state, job)
	if int(p.progress) == p.answer.size():
		_finish_stage(state, uid, expected_step)
	else:
		_changed(state)
	return correct

static func hint(state: Node, uid: String) -> String:
	var job := find(state, uid)
	if job.is_empty() or job.puzzle.is_empty(): return ""
	var p: Dictionary = job.puzzle
	if int(p.hints_used) >= int(p.get("clues", 0)): return "No implant clues left. The on-screen rule contains everything you need."
	p.hints_used = int(p.hints_used) + 1
	var next_label: String = p.labels[int(p.answer[int(p.progress)])]
	p.feedback = "Clue: choose %s next." % next_label
	_put(state, job)
	_changed(state)
	return p.feedback

static func _finish_stage(state: Node, uid: String, expected_step: int) -> void:
	var job := find(state, uid)
	if job.is_empty() or int(job.step) != expected_step or not job.started: return
	if int(job.step) < job.stages.size():
		job.step = int(job.step) + 1
		job.started = false
		job.puzzle = {}
		_set_stage(job)
		_put(state, job)
		state.notify("Stage complete · next: %s" % job.objective, state.COL_GOOD)
	else:
		# Remove before any signals or payouts so duplicate callbacks cannot settle again.
		for i in state.active_jobs.size():
			if state.active_jobs[i].get("uid", "") == uid:
				state.active_jobs.remove_at(i)
				break
		if state.tracked_job == uid: state.tracked_job = ""
		state.add_cash(int(job.cash))
		state.add_xp(int(job.xp))
		if int(job.rep) > 0: state.add_rep(int(job.rep))
		if int(job.heat) > 0: state.add_heat(int(job.heat),true)
		state.add_mastery("corp_row" if int(Catalog.sources().get(job.source,{"tier":0}).tier) >= 3 else "plaza")
		state.notify("JOB COMPLETE · +$%d · +%d XP%s%s" % [job.cash,job.xp,
			" · gear bonus $%d included" % job.bonus if int(job.bonus)>0 else "",
			" · +%d REP" % job.rep if int(job.rep)>0 else ""], state.COL_GOOD)
		state._maybe_nudge_laptop()
	_changed(state)

static func abandon(state: Node, uid: String) -> bool:
	for i in state.active_jobs.size():
		if state.active_jobs[i].get("uid", "") == uid:
			state.active_jobs.remove_at(i)
			if state.tracked_job == uid: state.tracked_job = ""
			_changed(state)
			return true
	return false

static func track(state: Node, uid: String) -> void:
	for job in state.active_jobs:
		if job.get("uid", "") == uid:
			state.tracked_job = uid
			_changed(state)
			return

static func finish_combat(state: Node, enemy: String, outcome: String) -> void:
	# Only the explicitly launched work fight may settle a combat stage.
	var uid: String = state.work_battle
	state.work_battle = ""
	var job := find(state, uid)
	if job.is_empty() or job.enemy != enemy or not job.started: return
	if outcome == "win":
		_finish_stage(state, uid, int(job.step))
	else:
		job.started = false
		_set_stage(job)
		_put(state, job)
		_changed(state)

static func remaining(job: Dictionary) -> String:
	var energy := 0
	var cpu := 0
	for i in range(int(job.step)-1, job.stages.size()):
		if i == int(job.step)-1 and job.started: continue
		energy += int(job.stages[i].energy)
		cpu += int(job.stages[i].cpu)
	return "%d energy · %d CPU remaining" % [energy,cpu]

static func goal_info(state: Node) -> Dictionary:
	var id: String = state.purchase_goal
	var item: Dictionary = GameData.UPGRADES.get(id, GameData.GEAR.get(id, {}))
	if item.is_empty() or state.owned(id) or state.owns_gear(id): return {}
	return {"id": id, "name": item.name, "price": int(item.price), "shortfall": maxi(0,int(item.price)-state.cash), "location": "Plaza Patch kiosk" if id in ["used_laptop","rig_script","fw_foam","imp_reflex"] else "Market pawn shop"}

static func set_goal(state: Node, id: String) -> void:
	if id != "" and not GameData.UPGRADES.has(id) and not GameData.GEAR.has(id): return
	if GameData.GEAR.get(id, {}).get("crew_drop", false): return
	state.purchase_goal = id
	state.goal_announced = false
	_changed(state)

static func check_goal(state: Node) -> void:
	var goal := goal_info(state)
	if not goal.is_empty() and goal.shortfall == 0 and not state.goal_announced:
		state.goal_announced = true
		state.notify("GOAL READY · %s · %s" % [goal.name,goal.location], state.COL_GOOD)
		state.save_game()

static func _changed(state: Node) -> void:
	check_goal(state)
	state.stats_changed.emit()
	state.jobs_changed.emit()
	state.save_game()

static func equipment_text(id: String, state: Node) -> String:
	var item: Dictionary = GameData.GEAR.get(id,{})
	if item.is_empty(): return ""
	var current_id: String = state.gear.get(item.slot,"")
	var current: Dictionary = GameData.GEAR.get(current_id,{})
	var out := "Equipped: %s" % current.get("name","empty")
	for key in ["cyber","defense","integrity","crit"]:
		if not item.has(key): continue
		var factor := 100.0 if key=="crit" else 1.0
		var value := int(round(float(item[key])*factor))
		var delta := value-int(round(float(current.get(key,0))*factor))
		var labels := {"cyber":"Attack","defense":"Defense","integrity":"Integrity","crit":"Critical chance"}
		out += "\n%s %d%s (%+d%s)" % [labels[key],value,"%" if key=="crit" else "",delta,"%" if key=="crit" else ""]
	var rigs := {"rig_script":10,"rig_breaker":15,"rig_zeroday":20}
	var walls := {"fw_foam":1,"fw_ice":2,"fw_black":3}
	var implants := {"imp_reflex":1,"imp_neural":2,"imp_ghost":3}
	if rigs.has(id): out += "\nTechnical work pay +%d%% (%+d%%)" % [rigs[id],int(rigs[id])-int(rigs.get(current_id,0))]
	elif item.slot=="rig": out += "\nTechnical work pay +0%% (%+d%%). Trophy target affinity retained." % -int(rigs.get(current_id,0))
	if walls.has(id): out += "\nRisky technical work heat -%d (%+d protection)" % [walls[id],int(walls[id])-int(walls.get(current_id,0))]
	if implants.has(id): out += "\nPuzzle clues %d (%+d)" % [implants[id],int(implants[id])-int(implants.get(current_id,0))]
	return out
