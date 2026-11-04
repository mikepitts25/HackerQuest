extends SceneTree
var failures: Array[String] = []
const Work = preload("res://scripts/work_system.gd")
const Catalog = preload("res://scripts/work_catalog.gd")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func _initialize() -> void:
	if ProjectSettings.get_setting("application/config/custom_user_dir_name", "") != "HackerQuest-Work-QA":
		quit(2)
		return
	root.content_scale_size = Vector2i(720,1280)
	root.size = Vector2i(720,1280)
	call_deferred("run")
func capture(label: String) -> void:
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/hackerquest-work-" + label + ".png")
func buttons(node: Node) -> Array:
	var out := []
	if node is Button and node.is_visible_in_tree(): out.append(node)
	for c in node.get_children(): out.append_array(buttons(c))
	return out
func button(node: Node, text: String) -> Button:
	for b in buttons(node):
		if b.text == text: return b
	return null
func tap(b: Button) -> void:
	check(b != null,"Button exists")
	if b == null: return
	# Scroll the actual card/button into view, then send real viewport input.
	var p := b.get_parent()
	while p != null and not p is ScrollContainer: p = p.get_parent()
	if p is ScrollContainer: p.ensure_control_visible(b)
	await process_frame
	await process_frame
	var pos := b.get_global_rect().get_center()
	check(pos.y >= 0 and pos.y <= 1280,"Tap target inside viewport")
	for pressed in [true,false]:
		var ev := InputEventMouseButton.new()
		ev.position = pos
		ev.global_position = pos
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		root.push_input(ev, true)
		await process_frame
	await create_timer(0.2).timeout
func run() -> void:
	var state = root.get_node("GameState")
	state.new_game()
	var main: Node3D = load("res://scenes/iso/iso_main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	var hud: Control = main.hud
	hud.close_blocking_ui()
	check(hud.get("work_ui")!=null,"Work UI integrated")
	if hud.get("work_ui")==null:
		print("FAIL: Work UI integrated")
		quit(1)
		return
	# Actual opening: earn the laptop and buy it before any boss is defeated.
	main.go_to("plaza","from_home")
	for offer in Work.offers(state,"plaza_board"):
		hud.work_ui.show_source("plaza_board")
		await process_frame
		await tap(button(hud.work_ui.modal.root,"ACCEPT"))
		hud.close_blocking_ui()
		var j: Dictionary = Work.find(state,offer.uid)
		check(not j.is_empty(),"Opening job accepted")
		if j.is_empty(): continue
		main.player.position=Vector3(j.pos[0],0,j.pos[1])
		await create_timer(0.2).timeout
		state.interact_requested.emit()
		await process_frame
		await tap(button(hud.work_ui.modal.root,"START"))
	check(state.cash>=100 and state.defeated_crew_bosses.is_empty(),"Opening jobs earn laptop before boss")
	main.player.position=Vector3(50,0,22.7)
	await create_timer(0.2).timeout
	state.interact_requested.emit()
	await process_frame
	await tap(button(hud.work_ui.modal.root,"$100"))
	check(state.has_computer and state.owned("used_laptop"),"Actual opening route buys laptop at consignment shelf")
	await create_timer(3.0).timeout
	await capture("first-laptop")
	hud.close_blocking_ui()
	state.new_game()
	state.defeated_crew_bosses.assign(GameData.RIOT_CREW_BY_DISTRICT.values())
	state.reputation = 120
	state.status_seen = 8
	state.max_energy = 100
	state.energy = 100
	state.max_cpu = 100
	state.cpu = 100
	state.has_computer = true
	for zone in ["plaza","market","underpass","corp_row","darknet","drowned_quarter"]:
		main.go_to(zone,"fast_travel")
		await process_frame
		check(get_nodes_in_group("work_source").size()==3,zone+" source geometry")
		# Source positions and stops must not be inside static collision volumes.
		var district: Node3D = main.world_container.get_child(0)
		await physics_frame
		for source in Catalog.sources().values():
			if source.district != zone: continue
			var query := PhysicsPointQueryParameters3D.new()
			query.position = Vector3(source.pos[0],0.5,source.pos[1]+1.4)
			query.collision_mask = 1
			for hit in district.get_world_3d().direct_space_state.intersect_point(query):
				check(not hit.collider is StaticBody3D,source.name+" reachable pickup")
			main.player.position=Vector3(source.pos[0],0,source.pos[1]+0.7)
			await create_timer(0.15).timeout
			state.interact_requested.emit()
			await process_frame
			check(hud.work_ui.modal.root.visible and hud.work_ui.modal.title.text==source.name,source.name+" actual proximity action opens work")
			if not hud.work_ui.modal.root.visible or hud.work_ui.modal.title.text!=source.name:
				var target = main.player.get("_current")
				print("SOURCE DIAGNOSTIC ",source.name," pos=",main.player.position," target=",target.prompt_text if target!=null else "none"," locked=",state.is_ui_locked())
			hud.close_blocking_ui()
		for template in Catalog.templates().values():
			for stage in template.stages:
				if stage.district != zone: continue
				var query := PhysicsPointQueryParameters3D.new()
				query.position = Vector3(stage.pos[0],0.5,stage.pos[1])
				query.collision_mask = 1
				for hit in district.get_world_3d().direct_space_state.intersect_point(query):
					check(not hit.collider is StaticBody3D,template.name+" reachable stop "+str(stage.pos)+" collider="+str(hit.collider.get_path()))
	main.go_to("plaza","fast_travel")
	hud.work_ui.show_source("plaza_repair")
	await process_frame
	check(button(hud.work_ui.modal.root,"$100")!=null,"Plaza starter shelf makes laptop reachable before boss")
	hud.close_blocking_ui()
	hud.work_ui.show_source("plaza_board")
	await capture("offers")
	await tap(button(hud.work_ui.modal.root,"ACCEPT"))
	check(state.active_jobs.size()==1,"Pointer accepts actual offer")
	check(hud._city_map.has_method("is_tracked_destination"),"Map distinguishes tracked destination")
	if hud._city_map.has_method("is_tracked_destination"):
		check(hud._city_map.is_tracked_destination("plaza"),"Tracked Plaza job marks Plaza")
		check(not hud._city_map.is_tracked_destination("market"),"Untracked zone is not marked as tracked")
	hud.close_blocking_ui()
	# Complete all three puzzle families through their actual button views.
	for pair in [["plaza_coffee",1],["plaza_repair",0],["market_pawn",0]]:
		var offer: Dictionary = Work.offers(state,pair[0])[pair[1]]
		check(Work.accept(state,offer.uid),"Accept puzzle family")
		var job: Dictionary = Work.find(state,offer.uid)
		hud.work_ui.show_stage(job.uid)
		await process_frame
		await tap(button(hud.work_ui.modal.root,"START"))
		job = Work.find(state,offer.uid)
		check(not job.puzzle.is_empty(),"Pointer starts puzzle")
		if job.puzzle.is_empty():
			print("FAIL: start did not reach puzzle; job=",job)
			quit(1)
			return
		await capture(job.puzzle.kind)
		check(hud.work_ui.modal.inner.size.y < 1100,"Puzzle modal fits its content without excessive blank space")
		var guard := 0
		while not job.is_empty() and not job.puzzle.is_empty() and guard < 5:
			var label: String = job.puzzle.labels[int(job.puzzle.answer[int(job.puzzle.progress)])]
			await tap(button(hud.work_ui.modal.root,label))
			job = Work.find(state,offer.uid)
			guard += 1
		check(job.is_empty(),"Pointer solves "+offer.kind)
		check(hud._reward_title.text=="WORK PAID","Completed work has a clear reward banner")
		check(not state.is_ui_locked(),"Puzzle completion unlocks city")
	await capture("reward")
	await create_timer(3.0).timeout
	state.cash = 125
	state.stats_changed.emit()
	main.open_shop()
	await process_frame
	await tap(button(main.shop,"SAVE FOR THIS"))
	check(state.purchase_goal=="used_laptop","Pointer sets shop savings goal")
	await capture("shop")
	# Collapse hardware and open rigs for a readable comparison view.
	for b in buttons(main.shop):
		if "UPGRADES" in b.text:
			await tap(b)
			break
	for b in buttons(main.shop):
		if "RIGS" in b.text:
			await tap(b)
			break
	await create_timer(3.0).timeout
	await capture("gear")
	await tap(button(main.shop,"$120"))
	check(state.owns_gear("rig_script") and state.gear.is_empty(),"Purchase retains chosen loadout")
	await tap(button(main.shop,"EQUIP"))
	check(state.gear.get("rig","")=="rig_script","Pointer explicitly equips bought gear")
	main.shop.close_shop()
	hud.show_loadout()
	await capture("loadout")
	hud.close_blocking_ui()
	hud.show_quests()
	await capture("journal")
	hud.close_blocking_ui()
	main.queue_free()
	await process_frame
	state.new_game()
	if failures.is_empty(): print("LOCAL WORK PREVIEW PASSED")
	else:
		for failure in failures: print("FAIL: "+failure)
	quit(0 if failures.is_empty() else 1)
