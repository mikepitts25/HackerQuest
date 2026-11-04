extends SceneTree
## Run in an isolated project/user directory. Saves real renderer captures to
## /tmp/hackerquest-*.png and exercises actual player proximity + interaction.

var failures: Array[String] = []

func _initialize() -> void:
	# These checks deliberately reset and save progress: refuse a normal profile.
	if not str(ProjectSettings.get_setting("application/config/custom_user_dir_name", "")).begins_with("HackerQuest-Fun-QA"):
		printerr("Refusing to reset a real save. Run tools/check_fun_pass.sh instead.")
		quit(2)
		return
	root.content_scale_size = Vector2i(720, 1280)
	root.size = Vector2i(720, 1280)
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func capture(name: String) -> void:
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/hackerquest-" + name + ".png")

func run() -> void:
	var state := root.get_node("GameState")
	state.new_game()
	var title: Control = load("res://scenes/ui/title_screen.tscn").instantiate()
	root.add_child(title)
	await capture("title")
	title.queue_free()
	await process_frame
	var main: Node3D = load("res://scenes/iso/iso_main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var hud: Control = main.get_node("UILayer/HUD")
	hud.close_blocking_ui()
	check(hud.get("_quest_label").text.contains("$15 / $100"), "Opening shows laptop savings progress")
	main.go_to("plaza", "from_home")
	await process_frame
	var player: CharacterBody3D = main.get_node("Player")
	player.position = Vector3(22, 0, 39.1)
	await create_timer(0.6).timeout
	var target = player.get("_current")
	check(target != null and target.is_in_group("signal_cache"), "Walking up selects signal cache")
	check(player.get("_focus_ring").visible, "Selected cache has a visible focus ring")
	await capture("plaza-cache")
	var before: int = state.cash
	# The actual touch action button uses this signal.
	state.interact_requested.emit()
	await create_timer(0.25).timeout
	check(state.cash == before + 18, "Touch interaction downloads cache and pays out")
	check(hud.get_node("RewardBanner").visible, "Discovery displays non-blocking reward banner")
	check(not state.is_ui_locked(), "Reward feedback allows play to continue")
	await capture("discovery")
	state.defeated_crew_bosses.assign(GameData.RIOT_CREW_BY_DISTRICT.values())
	main.go_to("market", "from_plaza")
	check(main.current_district_id == "market", "Market preview reaches the real Market")
	await process_frame
	player.position = Vector3(14, 0, 13.5)
	await create_timer(2.8).timeout
	await capture("market")
	var shop_target = player.get("_current")
	check(shop_target != null and ("wares" in shop_target.prompt_text or "after hours" in shop_target.prompt_text), "New Market props leave the pawn shop reachable")
	state.cash = 100
	state.stats_changed.emit()
	check(hud.get("_quest_label").text.contains("READY TO UPGRADE"), "Affordable laptop gives concrete shop directions")
	state.energy = 5
	player.position = Vector3(35, 0, 8)
	await create_timer(0.5).timeout
	var meal_target = player.get("_current")
	check(meal_target != null and "Kage Ramen" in meal_target.prompt_text, "Detailed noodle cart keeps its meal interaction reachable")
	before = state.cash
	state.interact_requested.emit()
	check(state.cash == before - 10 and state.energy == 9, "Noodle cart touch action preserves meal price and energy benefit")
	await capture("noodle-cart")
	main.go_to("plaza", "from_home")
	await process_frame
	player.position = Vector3(22, 0, 39.1)
	await create_timer(0.5).timeout
	before = state.cash
	state.interact_requested.emit()
	check(state.cash == before, "Re-entering district cannot farm claimed cache")
	# Build every district touched by the atmosphere pass, then free it through
	# the real router to catch dangling signal callbacks and teardown problems.
	state.reputation = 999
	state.defeated_crew_bosses.assign(GameData.RIOT_CREW_BY_DISTRICT.values())
	for id in ["underpass", "corp_row", "darknet", "home"]:
		main.go_to(id, "fast_travel")
		await process_frame
		state.stats_changed.emit()
		await create_timer(0.15).timeout
	main.queue_free()
	await process_frame
	state.new_game()
	if failures.is_empty():
		print("FUN PASS PREVIEW PASSED")
	else:
		for failure in failures:
			print("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)
