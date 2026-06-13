class_name NewsFeed
## CITY WIRE — procedural news generated from live GameState. The city
## talking about what you did, without knowing it was you. Used by the
## terminal's `news` command and the morning headline toast (main_3d.gd).


static func headlines(count := 4) -> Array:
	var pool: Array = []

	# Your unattributed crimes (targets currently pwned).
	for id in GameState.exploited:
		var tname: String = GameData.TARGETS[id]["name"]
		pool.append([
			"Intrusion reported at %s — operators 'investigating'." % tname,
			"%s breached overnight. No suspects. No leads." % tname,
			"Insiders say %s never patched. Now it's somebody's." % tname,
		].pick_random())

	# The botnet hum.
	if GameState.botnet_size >= 12:
		pool.append("Grid analysts baffled: zombie traffic at an all-time high.")
	elif GameState.botnet_size >= 4:
		pool.append("ISPs report 'unusual coordinated traffic' across the bay.")

	# Police pressure mirrors your heat.
	if GameState.heat >= 80:
		pool.append("CITYWIDE SWEEP: cyber-division drones authorized in all districts.")
	elif GameState.heat_penalty() > 0.0:
		pool.append("Police cyber-division steps up patrols. 'We are closing in.'")

	# Whispers about whoever you are now.
	var idx := GameState.status_index()
	if idx >= 6:
		pool.append("Forum thread of the week: 'the %s' — myth, or menace?" % GameState.status_title())
	elif idx >= 3:
		pool.append("Street word: a new %s is working the bay's networks." % GameState.status_title())

	# Day-seeded city flavor so the wire never runs dry.
	var flavor := [
		"Rolling brownouts in Corp Row. Datacenter demand blamed.",
		"Market stall fined for selling 'haunted' RAM. Again.",
		"Plaza job board vandalized; notes reposted within the hour.",
		"Underpass residents petition for brighter lighting. Petition lost.",
		"Drone traffic rerouted over the Plaza for 'maintenance'.",
		"Drowned Quarter pumps fail for 6th straight week. Fish thriving.",
		"Darknet Café denies existing. Reporters can't find the door.",
		"City council debates neon curfew. Neon wins, 7–2.",
	]
	flavor.shuffle()
	pool.append_array(flavor)

	return pool.slice(0, count)


static func morning_headline() -> String:
	return headlines(1)[0]
