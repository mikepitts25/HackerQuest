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
	return []


# Sparks — parts dealer. Talking dumps your whole loot bag for a premium.
static func sparks_lines() -> Array:
	var r := GameState.bulk_sell_loot()
	if r.count <= 0:
		return [
			"Sparks: \"Bring me a bag of parts and I'll make it worth the walk.\"",
			"Sparks: \"Wire, drives, boards — I pay 10% over the counter for the lot.\"",
		]
	return [
		"Sparks: \"Now THAT's a haul. Let's see...\"",
		"Sparks: \"%d parts, $%d. Pleasure doing business.\"" % [r.count, r.total],
	]


# Tess — trainer. Talking buys a skill point if you can pay.
static func tess_lines() -> Array:
	var r := GameState.train_skill()
	if r.ok:
		return [
			"Tess: \"Sit. Watch. Don't blink.\"",
			"Tess: \"That'll stick. Cost you $%d — a skill point's yours.\"" % r.cost,
		]
	return [
		"Tess: \"I can teach you a thing or two. A session runs $%d.\"" % r.cost,
		"Tess: \"Come back when your wallet's as sharp as you think you are.\"",
	]


# Ozark — scrap boss. Daily bounty: bring him parts for cash + REP.
static func ozark_lines() -> Array:
	var r := GameState.scrap_bounty()
	if r.ok:
		return [
			"Ozark: \"Good. The yard always needs more.\"",
			"Ozark: \"Here — $%d and a word in the right ears. Back tomorrow.\"" % r.reward,
		]
	if r.get("reason", "") == "done":
		return ["Ozark: \"You filled the quota today. Rest those hands.\""]
	return [
		"Ozark: \"Bring me %d parts and I'll pay cash AND put your name around.\"" % GameState.SCRAP_BOUNTY_NEED,
		"Ozark: \"You've got %d. Dig up the rest.\"" % r.get("have", 0),
	]


static func cipher_lines() -> Array:
	return [
		"Cipher: \"Corp Row. Took you long enough, %s.\"" % GameState.status_title(),
		"Cipher: \"The datacenters here run hot and careless. Sniff the air — the WiFi's dense.\"",
		"Cipher: \"Bring a real rig. The boxes up here don't fall to a toy.\"",
	]


static func oracle_lines() -> Array:
	return [
		"Oracle: \"Few make it to the café. Fewer leave the same.\"",
		"Oracle: \"You've got the whole grid in your pocket and you still want more. Good.\"",
		"Oracle: \"The AI datacenter is awake. When you take it, the city will remember your name.\"",
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
		]
	return [
		"Pix: \"REP builds your STATUS — and status opens doors.\"",
		"Pix: \"You're a %s now. Bigger rigs crack bigger targets; talk to the others around here.\"" % GameState.status_title(),
	]


static func riot_lines() -> Array:
	# Rival hacker; banter scales with how far you've climbed.
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


static func glitch_lines() -> Array:
	# Paranoid info broker; rotates a useful tip by day.
	var tips := [
		"Glitch: \"Heat's a clock, not a wall. Big jobs, then lie low a few nights.\"",
		"Glitch: \"Stealth skill and a VPN stack — that's how the Ghosts stay cold.\"",
		"Glitch: \"Energy drinks before a long session. Tired hands trip alarms.\"",
		"Glitch: \"Vex down the alley pays more for data than the pawn shop ever will.\"",
		"Glitch: \"Marlowe can make your heat disappear. Once a day. For a price.\"",
	]
	return [
		"Glitch: \"Don't say my name out loud. What do you want.\"",
		tips[GameState.day % tips.size()],
	]


static func vex_lines() -> Array:
	var result := GameState.fence_stolen_data()
	if result.count <= 0:
		return [
			"Vex: \"You bring me Stolen Data, I make it rain. Today? You got nothing.\"",
			"Vex: \"Pwn a box, exfiltrate the goods, come back. I pay $%d a packet.\"" % GameState.FENCE_PRICE,
		]
	return [
		"Vex: \"Mmm. Fresh records. Always a pleasure.\"",
		"Vex: \"%d packet(s) — that's $%d. Don't spend it all on hoodies.\"" % [result.count, result.total],
	]


static func marlowe_lines() -> Array:
	var result := GameState.bribe_fixer()
	if result.ok:
		return [
			"Marlowe: \"A name gets crossed off a list. Heat %d → %d.\"" % [result.before, result.after],
			"Marlowe: \"That's $%d. We never spoke.\"" % result.cost,
		]
	match result.reason:
		"clean":
			return ["Marlowe: \"You're clean as far as I can see. Come back when you're sweating.\""]
		"used":
			return ["Marlowe: \"One favor a day. Sleep on it and find me tomorrow.\""]
		"cash":
			return ["Marlowe: \"Making your heat vanish runs $%d today. Come back with the cash.\"" % result.cost]
	return ["Marlowe: \"...\""]
