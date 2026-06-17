class_name NpcDialogs
## NPC dialogue lines, shared by the 2D shell (main.gd) and the 3D shell
## (scripts/iso/main_3d.gd). Moved out of main.gd verbatim so both worlds
## speak with one voice. All state comes from GameState/GameData autoloads.


static func wanderer_line(npc_name: String) -> String:
	var lines := [
		"%s: \"Nice night for it, huh?\"" % npc_name,
		"%s: \"You look like you know your way around a terminal.\"" % npc_name,
		"%s: \"Did you hear something? ...Nah, probably nothing.\"" % npc_name,
		"%s: \"This city never sleeps. Neither do I, apparently.\"" % npc_name,
		"%s: \"Spare a thought for the little networks, yeah?\"" % npc_name,
	]
	return lines.pick_random()


static func lines_for(id: String) -> Array:
	match id:
		"pix":
			return pix_lines()
		"riot":
			return riot_lines()
		"glitch":
			return glitch_lines()
		"vex":
			return vex_lines()
		"marlowe":
			return marlowe_lines()
		"cipher":
			return cipher_lines()
		"oracle":
			return oracle_lines()
		"sparks":
			return sparks_lines()
		"tess":
			return tess_lines()
		"ozark":
			return ozark_lines()
		"fathom":
			return fathom_lines()
	if id in GameData.RIOT_CREW_BY_DISTRICT.values():
		return riot_crew_lines(id)
	return []


static func needs_confirmation(id: String) -> bool:
	match id:
		"sparks":
			return GameState.bulk_sell_loot_quote().count > 0
		"tess":
			return GameState.train_skill_quote().ok
		"ozark":
			return GameState.scrap_bounty_quote().ok
		"vex":
			return GameState.fence_stolen_data_quote().count > 0
		"marlowe":
			return GameState.bribe_fixer_quote().ok
	return false


static func confirm_lines_for(id: String) -> Array:
	match id:
		"sparks":
			return sparks_confirm_lines()
		"tess":
			return tess_confirm_lines()
		"ozark":
			return ozark_confirm_lines()
		"vex":
			return vex_confirm_lines()
		"marlowe":
			return marlowe_confirm_lines()
	return []


# Sparks — parts dealer. Talking dumps your whole loot bag for a premium.
static func sparks_lines() -> Array:
	var r := GameState.bulk_sell_loot_quote()
	if r.count <= 0:
		return [
			"Sparks: \"Bring me a bag of parts and I'll make it worth the walk.\"",
			"Sparks: \"Wire, drives, boards — I pay 10% over the counter for the lot.\"",
		]
	return [
		"Sparks: \"I can take the whole parts bag off you.\"",
		"Sparks: \"%d part(s), $%d for the lot. Say yes and I move it now.\"" % [r.count, r.total],
	]


static func sparks_confirm_lines() -> Array:
	var r := GameState.bulk_sell_loot()
	if r.count <= 0:
		return sparks_lines()
	return [
		"Sparks: \"Now THAT's a haul.\"",
		"Sparks: \"%d part(s), $%d. Pleasure doing business.\"" % [r.count, r.total],
	]


# Tess — trainer. Talking buys a skill point if you can pay.
static func tess_lines() -> Array:
	var r := GameState.train_skill_quote()
	if r.ok:
		return [
			"Tess: \"I can sharpen you up right now.\"",
			"Tess: \"A session runs $%d. Say yes and the skill point's yours.\"" % r.cost,
		]
	return [
		"Tess: \"I can teach you a thing or two. A session runs $%d.\"" % r.cost,
		"Tess: \"Come back when your wallet's as sharp as you think you are.\"",
	]


static func tess_confirm_lines() -> Array:
	var r := GameState.train_skill()
	if not r.ok:
		return tess_lines()
	return [
		"Tess: \"Sit. Watch. Don't blink.\"",
		"Tess: \"That'll stick. Cost you $%d — a skill point's yours.\"" % r.cost,
	]


# Ozark — scrap boss. Daily bounty: bring him parts for cash + REP.
static func ozark_lines() -> Array:
	var r := GameState.scrap_bounty_quote()
	if r.ok:
		return [
			"Ozark: \"Quota's %d parts. You've got enough.\"" % GameState.SCRAP_BOUNTY_NEED,
			"Ozark: \"Say yes and I'll take %d parts for $%d plus REP.\"" % [GameState.SCRAP_BOUNTY_NEED, r.reward],
		]
	if r.get("reason", "") == "done":
		return ["Ozark: \"You filled the quota today. Rest those hands.\""]
	return [
		"Ozark: \"Bring me %d parts and I'll pay cash AND put your name around.\"" % GameState.SCRAP_BOUNTY_NEED,
		"Ozark: \"You've got %d. Dig up the rest.\"" % r.get("have", 0),
	]


static func ozark_confirm_lines() -> Array:
	var r := GameState.scrap_bounty()
	if not r.ok:
		return ozark_lines()
	return [
		"Ozark: \"Good. The yard always needs more.\"",
		"Ozark: \"Here — $%d and a word in the right ears. Back tomorrow.\"" % r.reward,
	]


static func cipher_lines() -> Array:
	return [
		"Cipher: \"Corp Row. Took you long enough, %s.\"" % GameState.status_title(),
		"Cipher: \"The datacenters here run hot and careless. Sniff the air — the WiFi's dense.\"",
		"Cipher: \"Bring a real rig. The boxes up here don't fall to a toy.\"",
		"Cipher: \"Old procurement logs say a sentient trunk core was discarded under the bay, then someone re-keyed it as R10T.\"",
	]


static func oracle_lines() -> Array:
	return [
		"Oracle: \"Few make it to the café. Fewer leave the same.\"",
		"Oracle: \"You've got the whole grid in your pocket and you still want more. Good.\"",
		"Oracle: \"The AI datacenter is awake. When you take it, the city will remember your name.\"",
		"Oracle: \"R10T is not a rival. R10T is the Trunk's human form after a wetware implant learned to walk.\"",
	]


# Fathom — the drowned quarter's keeper. The last human voice before THE TRUNK;
# her lines track the endgame so she reads as the guide to the final contract.
static func fathom_lines() -> Array:
	if GameState.trunk_ready():
		return [
			"Fathom: \"You hear it too, don't you. The discarded Trunk has its strength back.\"",
			"Fathom: \"R10T was the mask. Jack in and you fight the thing wearing the whole grid.\"",
		]
	return [
		"Fathom: \"Careful on the walkway. The water down here remembers everyone who slipped.\"",
		"Fathom: \"I dive the dead fiber for a living. Every packet in the bay still runs through the Trunk.\"",
		"Fathom: \"They drowned it when it became sentient. R10T found it. Or maybe it found R10T.\"",
		"Fathom: \"%s\"" % GameState.final_contract_hint(),
	]


static func riot_crew_lines(id: String) -> Array:
	var enemy: Dictionary = GameData.ENEMIES.get(id, {})
	var district := str(enemy.get("district", ""))
	var gear_id := str(enemy.get("loot", {}).get("gear", ""))
	var district_name := str(GameData.DISTRICTS.get(district, {}).get("name", "this district"))
	var gear_name := str(GameData.GEAR.get(gear_id, {}).get("name", "their rig"))
	if GameState.crew_boss_defeated(id):
		return [
			"%s: \"Yeah, yeah. You won. Take the %s and keep walking.\"" % [enemy.get("name", id), gear_name],
			"%s: \"R10T heard about it. He laughed, but he heard.\"" % enemy.get("name", id),
		]
	return [
		"%s: \"%s is R10T territory. You want clean hacks past here, you go through me.\"" % [enemy.get("name", id), district_name],
		"%s: \"Beat me and maybe that %s stops looking ornamental.\"" % [enemy.get("name", id), gear_name],
	]


static func pix_lines() -> Array:
	if not GameState.has_computer:
		return [
			"Pix: \"New face. Listen — scrap first, odd jobs second, hardware third.\"",
			"Pix: \"The pawn shop has a beat-up laptop for $100. Junk, but junk gets you in the game.\"",
		]
	elif GameState.botnet_size == 0:
		return [
			"Pix: \"Got a rig? Sit at your desk and run scan, inspect, then exploit.\"",
			"Pix: \"After you pwn a box, install_bot on it. Bots pay you while you sleep.\"",
			"Pix: \"Watch your HEAT. Hit 100 and you get traced. Sleeping cools you off.\"",
			"Pix: \"If a street kid says R10T, ask whether they mean the hacker or the thing wearing him.\"",
		]
	return [
		"Pix: \"REP builds your STATUS — and status opens doors.\"",
		"Pix: \"You're a %s now. Bigger rigs crack bigger targets; talk to the others around here.\"" % GameState.status_title(),
		"Pix: \"People say the Trunk was discarded because it became sentient. People say a lot. This one scares me.\"",
	]


static func riot_lines() -> Array:
	var district := GameState.npc_district("riot")
	if district != "":
		return riot_lines_for_district(district)
	# Fallback rival banter scales with how far you've climbed.
	var idx := GameState.status_index()
	if idx <= 1:
		return [
			"Riot: \"Cute hoodie. Lemme guess — you 'hacked' your school wifi once?\"",
			"Riot: \"Come back when your botnet's bigger than your ego, %s.\"" % GameState.status_title(),
		]
	elif idx <= 3:
		return [
			"Riot: \"Huh. %s. You're actually moving up. Didn't think you had it.\"" % GameState.status_title(),
			"Riot: \"Word is the bank core's crackable if your rig's fat enough. I'm not scared. You?\"",
		]
	return [
		"Riot: \"%s. Okay. Okay. You've got the whole grid whispering your handle.\"" % GameState.status_title(),
		"Riot: \"Whatever. Race you to the AI datacenter. Loser deletes their bots.\"",
	]


static func riot_lines_for_district(district: String) -> Array:
	var idx := GameState.status_index()
	match district:
		"plaza":
			return [
				"Riot: \"Still taking plaza jobs? Cute. I cleared three before breakfast.\"",
				"Riot: \"Watch the boards. If a gig says CLAIMED, that was me reminding you who runs first.\"",
				"Riot: \"Old city myth: there is a Trunk under the bay that learned to hate being discarded.\"",
			]
		"market":
			return [
				"Riot: \"Vex likes you? That's adorable. I sold her cleaner packets yesterday.\"",
				"Riot: \"The Market teaches one thing: every favor has a hook. Mine are just sharper.\"",
				"Riot: \"R10T buys implant parts here. Not vanity chrome. Spine-interface grade.\"",
			]
		"underpass":
			return [
				"Riot: \"Underpass is where amateurs learn what a tail looks like.\"",
				"Riot: \"If you hear footsteps after a drop, don't run straight. I used to make that mistake. Once.\"",
				"Riot: \"The relays down here started answering to R10T before anyone saw a face.\"",
			]
		"corp_row":
			return [
				"Riot: \"Corp Row boxes punch back. Finally, something almost as annoying as me.\"",
				"Riot: \"Bring real defense up here. Your hoodie won't block Black ICE.\"",
				"Riot: \"A corp memo called the Trunk sentient, then stamped DISCARDED like that solved it.\"",
			]
		"darknet":
			return [
				"Riot: \"Oracle told you about the machine yet? She tells everyone. Few survive the lesson.\"",
				"Riot: \"The AI datacenter isn't the door. It's the lock. I have the other half of the key.\"",
				"Riot: \"R10T's human form is just the implant layer. The final voice is lower.\"",
			]
		"drowned_quarter":
			var key_line := "Riot: \"Beat R10T and take the root key, or the Trunk won't even hear you knock.\""
			if GameState.inventory.get("r10t_root_key", 0) > 0:
				key_line = "Riot: \"So you took my root key. Good. Now prove you know what it opens.\""
			return [
				"Riot: \"End of the line looks smaller when you're standing in it, huh?\"",
				key_line,
				"Riot: \"Past me is the Trunk itself. R10T was only how it learned to stand up.\"",
			]
	var status_line := "Riot: \"You're %s now. Try not to look impressed with yourself.\"" % GameState.status_title()
	if idx >= 6:
		status_line = "Riot: \"Zero Day and still chasing me. Maybe you're learning.\""
	return [status_line]


static func glitch_lines() -> Array:
	# Paranoid info broker; rotates a useful tip by day.
	var tips := [
		"Glitch: \"Heat's a clock, not a wall. Big jobs, then lie low a few nights.\"",
		"Glitch: \"Stealth skill and a VPN stack — that's how the Ghosts stay cold.\"",
		"Glitch: \"Energy drinks before a long session. Tired hands trip alarms.\"",
		"Glitch: \"Vex down the alley pays more for data than the pawn shop ever will.\"",
		"Glitch: \"Marlowe can make your heat disappear. Once a day. For a price.\"",
		"Glitch: \"R10T pings like a person and routes like a trunk line. That is not normal.\"",
	]
	return [
		"Glitch: \"Don't say my name out loud. What do you want.\"",
		tips[GameState.day % tips.size()],
	]


static func vex_lines() -> Array:
	var result := GameState.fence_stolen_data_quote()
	if result.count <= 0:
		return [
			"Vex: \"You bring me Stolen Data, I make it rain. Today? You got nothing.\"",
			"Vex: \"Pwn a box, exfiltrate the goods, come back. I pay $%d a packet.\"" % GameState.FENCE_PRICE,
			"Vex: \"I fenced implant schematics once. Buyer signed R10T. Delivery address was below sea level.\"",
		]
	return [
		"Vex: \"Fresh records. I can move those.\"",
		"Vex: \"%d packet(s) for $%d. Say yes and they're gone.\"" % [result.count, result.total],
		"Vex: \"Careful with R10T files. Some of them breathe back.\"",
	]


static func vex_confirm_lines() -> Array:
	var result := GameState.fence_stolen_data()
	if result.count <= 0:
		return vex_lines()
	return [
		"Vex: \"Mmm. Fresh records. Always a pleasure.\"",
		"Vex: \"%d packet(s) — that's $%d. Don't spend it all on hoodies.\"" % [result.count, result.total],
	]


static func marlowe_lines() -> Array:
	var result := GameState.bribe_fixer_quote()
	if result.ok:
		return [
			"Marlowe: \"I can cross a name off a list.\"",
			"Marlowe: \"Heat %d to %d for $%d. Say yes and we never spoke.\"" % [result.before, result.after, result.cost],
			"Marlowe: \"R10T's records never stay crossed off. Like the grid keeps writing the body back in.\"",
		]
	match result.reason:
		"trace":
			return ["Marlowe: \"Not while a trace is live. Run first. Talk later.\""]
		"clean":
			return ["Marlowe: \"You're clean as far as I can see. Come back when you're sweating.\""]
		"used":
			return ["Marlowe: \"One favor a day. Sleep on it and find me tomorrow.\""]
		"cash":
			return ["Marlowe: \"Making your heat vanish runs $%d today. Come back with the cash.\"" % result.cost]
	return ["Marlowe: \"...\""]


static func marlowe_confirm_lines() -> Array:
	var result := GameState.bribe_fixer()
	if not result.ok:
		return marlowe_lines()
	return [
		"Marlowe: \"A name gets crossed off a list. Heat %d → %d.\"" % [result.before, result.after],
		"Marlowe: \"That's $%d. We never spoke.\"" % result.cost,
	]
