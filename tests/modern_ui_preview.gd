extends SceneTree

func _initialize() -> void:
	if not str(ProjectSettings.get_setting("application/config/custom_user_dir_name", "")).begins_with("HackerQuest-Fun-QA"):
		printerr("Use an isolated QA profile")
		quit(2)
		return
	root.content_scale_size = Vector2i(720, 1280)
	call_deferred("run")

func capture(name: String) -> void:
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/hackerquest-ui-" + name + ".png")

func run() -> void:
	var state := root.get_node("GameState")
	state.new_game()
	state.handle = "ZeroCool"
	seed(21)
	var main: Node3D = load("res://scenes/iso/iso_main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	var hud: Control = main.get_node("UILayer/HUD")
	hud.close_blocking_ui()
	state.defeated_crew_bosses.assign(GameData.RIOT_CREW_BY_DISTRICT.values())
	main.go_to("market", "from_plaza")
	main.get_node("Player").position = Vector3(14, 0, 13.5)
	hud.set("_feed_age", 20.0)
	hud.call("_process", 2.0)
	await capture("hud")
	hud.call("_open_modal", hud.get("_more_modal"))
	await capture("more")
	hud.close_blocking_ui()
	hud.call("_open_skills")
	await capture("skills")
	hud.close_blocking_ui()
	main.open_shop()
	await capture("shop")
	main.get_node("UILayer/Shop").close_shop()
	hud.show_dialog(["The city has a pulse. Follow the signal, find your crew, and make a name for yourself."])
	await create_timer(1.4).timeout
	await capture("dialogue")
	hud.close_blocking_ui()
	main.queue_free()
	await process_frame
	state.new_game()
	print("MODERN UI PREVIEW PASSED")
	quit()
