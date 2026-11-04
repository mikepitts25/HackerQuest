extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	if not str(ProjectSettings.get_setting("application/config/custom_user_dir_name", "")).begins_with("HackerQuest-Fun-QA"):
		printerr("Use the isolated QA profile")
		quit(2)
		return
	root.content_scale_size = Vector2i(720, 1280)
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func tap(button: Button) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = button.get_global_rect().get_center()
	root.push_input(press, true)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = press.position
	root.push_input(release, true)
	await process_frame

func run() -> void:
	var state := root.get_node("GameState")
	state.new_game()
	var main: Node = load("res://scenes/iso/iso_main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	var hud: Control = main.get_node("UILayer/HUD")
	hud.close_blocking_ui()
	var dock := hud.get_node_or_null("NavigationDock")
	check(dock != null, "Compact primary navigation exists")
	if dock != null:
		for name in ["MapButton", "QuestsButton", "BagButton", "MoreButton"]:
			var button := dock.find_child(name, true, false) as Button
			check(button != null, name + " is discoverable in the dock")
			if button == null:
				continue
			check(button.size.y >= 48, name + " has a usable touch target")
			await tap(button)
			check(state.is_ui_locked(), name + " actually opens its panel from a pointer tap")
			if name == "MoreButton":
				await process_frame
				check(hud.get("_more_modal").inner.size.y < 800, "More panel fits its contents without a large empty area")
			hud.close_blocking_ui()
			check(not state.is_ui_locked(), name + " closes without stranding input")
		var more := dock.find_child("MoreButton", true, false) as Button
		if more:
			await tap(more)
			var skill := hud.find_child("SkillsButton", true, false) as Button
			check(skill != null and skill.is_visible_in_tree(), "Skills remains reachable from More")
			if skill:
				await tap(skill)
				check(hud.get("_skills_modal").root.visible, "More routes to Skills")
				hud.close_blocking_ui()
				check(not state.is_ui_locked(), "Switching More to Skills retains exactly one UI lock")
	check(not hud.get_node("GodTestButton").is_visible_in_tree(), "Developer boost stays off the gameplay HUD")
	check(hud.has_method("_apply_hud_insets"), "HUD supports device safe-area insets")
	if hud.has_method("_apply_hud_insets"):
		var original_height: float = hud.get_node("StatusCard").size.y
		hud.call("_apply_hud_insets", 52.0, 34.0)
		check(hud.get_node("StatusCard").position.y >= 52, "Header clears a simulated camera cutout")
		check(dock.get_global_rect().end.y <= 1246.5, "Dock clears a simulated home indicator")
		check(hud.get_node("ActionButton").get_global_rect().end.y < dock.get_global_rect().position.y, "Context action stays above navigation")
		hud.call("_apply_hud_insets", 18.0, 18.0)
		for i in 3:
			hud.call("_apply_hud_insets", 52.0, 34.0)
			hud.call("_apply_hud_insets", 18.0, 18.0)
		check(absf(hud.get_node("StatusCard").size.y - original_height) < 0.5, "Safe-area changes do not accumulate header height")
	hud.show_dialog(["Finish this conversation before opening another panel."])
	if dock != null:
		var map_button := dock.find_child("MapButton", true, false) as Button
		if map_button:
			await tap(map_button)
			check(not hud.get("_map_modal").root.visible, "Navigation cannot stack a panel over dialogue")
	hud.close_blocking_ui()
	main.queue_free()
	await process_frame
	state.new_game()
	if failures.is_empty():
		print("MODERN UI TEST PASSED")
	else:
		for failure in failures:
			print("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)
