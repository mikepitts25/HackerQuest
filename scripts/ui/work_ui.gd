extends RefCounted
const Work = preload("res://scripts/work_system.gd")
const Catalog = preload("res://scripts/work_catalog.gd")
var hud: Control
var modal: Dictionary
var source_id := ""

func setup(owner_hud: Control) -> void:
	hud = owner_hud
	modal = hud._make_modal("Local work")
	hud._modals.append(modal)

func _label(text: String, color := Color("b8c9dc")) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 17)
	modal.rows.add_child(label)

func show_source(id: String) -> void:
	if not Catalog.sources().has(id): return
	source_id = id
	var source: Dictionary = Catalog.sources()[id]
	hud._clear_rows(modal)
	modal.title.text = source.name
	_label("%s · %s\nYour cash $%d · %d/3 jobs active" % [GameData.DISTRICTS[source.district].name, source.category, GameState.cash, GameState.active_jobs.size()])
	_label("Today's work · agreed pay is saved when you accept")
	for offer in Work.offers(GameState,id):
		var desc := "%s · %d stage%s · stays in %s\nTotal: %d energy · %d CPU · +%d heat\nAgreed pay $%d · +%d XP%s" % [
			offer.kind.capitalize(),offer.stages.size(),"s" if offer.stages.size()>1 else "", GameData.DISTRICTS[source.district].name,
			offer.energy_total,offer.cpu_total,offer.heat,offer.cash,offer.xp," · +%d REP" % offer.rep if offer.rep>0 else ""]
		if offer.bonus > 0: desc += "\nIncludes $%d technical rig bonus." % offer.bonus
		if offer.heat_saved > 0: desc += " Firewall avoids %d heat." % offer.heat_saved
		if offer.kind == "combat": desc += "\nGuarded retrieval: combat at final stage. Loss can cost data or 25% cash; retries spend stage energy again."
		if offer.locked != "": desc += "\n" + offer.locked
		hud._add_row(modal,offer.name,desc,"ACCEPT" if offer.locked=="" else "UNAVAILABLE",offer.locked!="",_accept.bind(offer.uid,id))
	if id == "plaza_repair": _starter_shelf()
	journal(modal)
	hud._open_modal(modal)

func _accept(uid: String, id: String) -> void:
	Work.accept(GameState,uid)
	show_source(id)

func journal(target: Dictionary) -> void:
	if GameState.active_jobs.is_empty(): return
	hud._modal_label(target,"YOUR ACTIVE WORK",Color("8af0d8"),17)
	for job in GameState.active_jobs.duplicate(true):
		var local: bool = job.get("local_work",false)
		var source: String = Catalog.sources().get(job.get("source",""),{}).get("name","Legacy job")
		var terms := Work.remaining(job) if local else "%d energy per stop" % job.energy
		var desc := "%s · stage %d/%d\n%s in %s\n%s · agreed $%d" % [source,job.step,job.steps_total,job.objective,GameData.DISTRICTS[job.district].name,terms,job.cash]
		var uid: String = job.uid
		hud._add_row(target,job.name,desc,"TRACKING" if GameState.tracked_job==uid else "TRACK",false,_track.bind(uid,target))
		hud._add_row(target,"Leave this job?","No pay. Spent resources stay spent. This offer stays taken today.","ABANDON",false,_abandon.bind(uid,target))

func _track(uid: String, target: Dictionary) -> void:
	Work.track(GameState,uid)
	_refresh_journal(target)
func _abandon(uid: String, target: Dictionary) -> void:
	hud._close_modal(target)
	hud.show_confirm_dialog(["Abandon this job? You receive no pay, and spent resources stay spent. The offer stays taken today."],"Abandon","Keep job",func() -> void:
		Work.abandon(GameState,uid)
		_refresh_journal(target))
func _refresh_journal(target: Dictionary) -> void:
	if target == modal: show_source(source_id)
	else: hud._refresh_quests()

func map_sources(target: Dictionary) -> void:
	# Rebuild only the directory; retain the map canvas itself.
	for child in target.rows.get_children():
		if child != hud._city_map:
			target.rows.remove_child(child)
			child.queue_free()
	hud._modal_label(target,"LOCAL SPECIALISTS · visit them in the city",Color("8af0d8"),17)
	for id in Catalog.sources():
		var source: Dictionary = Catalog.sources()[id]
		if not GameState.district_unlocked(source.district): continue
		var region := "north" if source.pos[1] < 18 else ("south" if source.pos[1] > 30 else "central")
		region += " / west" if source.pos[0] < 22 else (" / east" if source.pos[0] > 40 else "")
		hud._add_row(target,source.name,"%s · %s\n%s" % [GameData.DISTRICTS[source.district].name,region,source.category],"",true,Callable())

func show_stage(uid: String) -> void:
	var job := Work.find(GameState,uid)
	if job.is_empty(): return
	hud._clear_rows(modal)
	modal.title.text = job.name
	_label("%s · stage %d/%d\nAgreed pay $%d · %s" % [job.objective,job.step,job.steps_total,job.cash,Work.remaining(job)])
	if not job.started:
		_label("Start this stage: %d energy · %d CPU. Closing a puzzle keeps your progress without charging again." % [job.energy,job.cpu])
		var stage: Dictionary = job.stages[int(job.step)-1]
		if stage.kind == "combat": _label("Guarded retrieval · defeat %s. Losing can cost data or 25%% of your cash. A retry spends this stage's resources again." % GameData.ENEMIES[job.enemy].name)
		hud._add_row(modal,"Ready to begin?","Costs are checked together before anything is spent.","START",false,_launch.bind(uid,int(job.step)))
	elif not job.puzzle.is_empty():
		_draw_puzzle(job)
	else:
		hud._add_row(modal,"Resume guarded retrieval","Resume your paid attempt.","CONTINUE",false,_launch.bind(uid,int(job.step)))
	hud._open_modal(modal)

func _draw_puzzle(job: Dictionary) -> void:
	var p: Dictionary = job.puzzle
	_label(p.rule,Color("edf5fa"))
	_label("Progress %d/%d · %d submission%s\n%s" % [p.progress,p.answer.size(),p.attempts,"s" if p.attempts!=1 else "",p.feedback])
	for i in p.labels.size():
		var button := Button.new()
		button.text = p.labels[i]
		button.custom_minimum_size = Vector2(0,64)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_choose.bind(job.uid,int(job.step),i,int(p.progress)))
		modal.rows.add_child(button)
	hud._add_row(modal,"Implant clue","%d of %d clues left. Every task is solvable using the rule above." % [int(p.clues)-int(p.hints_used),p.clues],"REVEAL",int(p.hints_used)>=int(p.clues),_hint.bind(job.uid))

func _launch(uid: String, step: int) -> void:
	if not Work.start(GameState,uid,step):
		show_stage(uid)
		return
	var job := Work.find(GameState,uid)
	if job.is_empty() or int(job.step)!=step:
		hud._close_modal(modal)
		return
	var stage: Dictionary = job.stages[step-1]
	if stage.kind == "combat":
		hud._close_modal(modal)
		GameState.work_battle = uid
		var main: Node = hud.get_tree().current_scene
		main.start_combat(job.enemy)
	else: show_stage(uid)

func _choose(uid: String, step: int, choice: int, progress: int) -> void:
	Work.submit(GameState,uid,step,choice,progress)
	var job := Work.find(GameState,uid)
	if job.is_empty() or int(job.step)!=step:
		hud._close_modal(modal)
	else: show_stage(uid)
func _hint(uid: String) -> void:
	Work.hint(GameState,uid)
	show_stage(uid)


func _starter_shelf() -> void:
	_label("STARTER CONSIGNMENT · prepare before the Plaza boss",Color("8af0d8"))
	_label("The Market pawn shop sends a few basics here. Visit the Market for the full upgrade range.")
	var laptop: Dictionary = GameData.UPGRADES.used_laptop
	var owns_laptop: bool = GameState.owned("used_laptop")
	hud._add_row(modal,laptop.name,laptop.desc,"OWNED" if owns_laptop else "$%d" % laptop.price,owns_laptop or GameState.cash<int(laptop.price),_buy_starter.bind("upgrade","used_laptop"))
	for id in ["rig_script","fw_foam","imp_reflex"]:
		var item: Dictionary = GameData.GEAR[id]
		var owned: bool = GameState.owns_gear(id)
		var selected: bool = GameState.gear.get(item.slot,"")==id
		hud._add_row(modal,item.name,Work.equipment_text(id,GameState),("EQUIPPED" if selected else "EQUIP") if owned else "$%d" % item.price,selected or (not owned and GameState.cash<int(item.price)),_buy_starter.bind("gear",id))
	for id in ["logic_bomb","patch_kit"]:
		var item: Dictionary = GameData.CONSUMABLES[id]
		hud._add_row(modal,item.name,"%s · owned %d" % [item.desc,GameState.inventory.get(id,0)],"$%d" % item.price,GameState.cash<int(item.price),_buy_starter.bind("supply",id))

func _buy_starter(kind: String, id: String) -> void:
	if kind=="upgrade": GameState.buy_upgrade(id)
	elif kind=="gear":
		if GameState.owns_gear(id): GameState.equip_gear(id)
		else: GameState.buy_gear(id)
	else: GameState.buy_consumable(id)
	show_source("plaza_repair")
