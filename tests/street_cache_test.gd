extends SceneTree

var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _initialize() -> void:
	# These checks deliberately reset and save progress: refuse a normal profile.
	if not str(ProjectSettings.get_setting("application/config/custom_user_dir_name", "")).begins_with("HackerQuest-Fun-QA"):
		printerr("Refusing to reset a real save. Run tools/check_fun_pass.sh instead.")
		quit(2)
		return
	call_deferred("run")

func run() -> void:
	var state := root.get_node("GameState")
	state.new_game()
	var cache_script = load("res://scripts/street_cache.gd")
	check(cache_script != null, "Street cache gameplay exists")
	if cache_script != null:
		var cash_before: int = state.cash
		var energy_before: int = state.energy
		check(cache_script.claim(state, "plaza"), "First discovery pays out")
		check(state.cash == cash_before + 18, "Discovery grants a modest fixed cash reward")
		check(state.energy == energy_before - 1, "Discovery spends one energy")
		check(not cache_script.claim(state, "plaza"), "Cannot farm the same cache by revisiting")
		check(state.cash == cash_before + 18, "Repeat discovery gives no extra cash")
		state.save_game()
		state.trash_searched.clear()
		state.load_game()
		check(not cache_script.claim(state, "plaza"), "Claim survives save and reload")
		state.sleep()
		check(cache_script.claim(state, "plaza"), "Sleep refreshes daily discoveries")
		state.energy = 0
		check(not cache_script.claim(state, "market"), "Exhausted players cannot claim")
		check(not state.trash_searched.has("signal_cache:market"), "Failed claim stays available")
		state.energy = 5
		check(not cache_script.claim(state, "home"), "Only supported street districts have caches")
	if failures.is_empty():
		print("STREET CACHE TEST PASSED")
	else:
		for failure in failures:
			print("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)
