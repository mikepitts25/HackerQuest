extends Node
## Global game state autoload ("GameState"). All stat mutations go through
## these helpers so rule checks and player feedback stay consistent.
## Single-player for now, but kept as one serializable blob of plain data so
## a future multiplayer server could own this state instead of the client.

signal stats_changed
signal toast(text: String, color: Color)
signal prompt_changed(text: String)
signal interact_requested
signal day_changed(day: int)
signal busted
signal quest_changed
signal cosmetics_changed
signal trace_started(reason: String, seconds: float)
signal trace_cleared(escaped: bool)
signal jobs_changed  # active field gigs added/completed — districts re-mark
signal leveled_up    # hit a new level (Audio plays the level-up sting)

const COL_GOOD := Color("7ee787")
const COL_BAD := Color("ff6b6b")
const COL_WARN := Color("ffd166")
const COL_INFO := Color("e6edf3")

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1
const TRACE_BASE_SECONDS := 30.0
const TRACE_ESCAPE_HEAT := 75
const HIGH_RISK_HACK_HEAT := 20

# Fields written to / read from the save file. Listed once so save and load
# can't drift apart. Dictionaries/arrays of plain data round-trip through JSON;
# load re-casts ints and the typed upgrades array (see _coerce_loaded).
const PERSISTED := [
	"cash", "energy", "max_energy", "cpu", "max_cpu", "heat", "reputation",
	"botnet_size", "day", "has_computer", "upgrades", "xp", "level",
	"skill_points", "status_seen", "skills", "inventory", "quest_index", "total_hacks",
	"hacked_ever", "exploited", "botted", "trash_searched", "wired_cpu",
	"fixer_used", "apartment", "ambient", "known_networks",
	"active_contract", "completed_contracts", "owned_cosmetics", "equipped", "active_jobs",
	"mastery", "favors_done", "goods", "handle", "skin_tone", "background",
	"scrap_bounty_done", "owned_gear", "gear", "r10t_beaten", "owned_furniture",
	"music_vol", "sfx_vol",
]

# True until a save is loaded; lets the main scene pick intro vs "welcome back".
var is_new_game := true

var owned_gear: Array[String] = []
# Set once you beat R10T in combat (G6) — gates the rare boss encounter so the
# rival only ambushes you once.
var r10t_beaten := false
# Furniture you've bought for your apartment (Apartments v2). Drives perks +
# Style score; rendered in home_3d.
var owned_furniture: Array[String] = []
var gear := {}   # slot -> gear id (G4)

var trace_active := false
var trace_seconds_left := 0.0
var trace_reason := ""

var cash := 15
var energy := 10
var max_energy := 10
var cpu := 0
var max_cpu := 0
var heat := 0
var reputation := 0
var botnet_size := 0
var day := 1
var has_computer := false
var upgrades: Array[String] = []

var xp := 0
var level := 1
var skill_points := 0
var status_seen := 0    # highest status rank already announced/rewarded
var skills := {"hardware": 0, "stealth": 0, "hustle": 0, "wardriving": 0}

# Character creation (G2): your alias, skin tone, and background class.
var handle := "Anon"
var skin_tone := "e8b890"
var background := "none"   # scrapper | coder | face | runner | none
var inventory := {}        # item_id -> count
var quest_index := 0
var total_hacks := 0
var hacked_ever := {}      # target_id -> true; never resets (quest tracking)

var exploited := {}        # target_id -> true; reset on sleep (targets get re-secured)
var botted := {}           # target_id -> true; permanent
var trash_searched := {}   # pile_id -> true; reset on sleep

# Temporary +max CPU from energy drinks ("wired"). Baked into max_cpu; this
# tracks how much to peel back off the cap when you sleep.
var wired_cpu := 0

# Marlowe the fixer can scrub Heat once per day; resets on sleep.
var fixer_used := false

# Housing: the apartment you live in (highest you own grants its perks).
var apartment := "apt_4b"

# Ambient wanderers: [{id, name, color, district}]. They roam and migrate
# between districts on sleep so the world feels alive.
var ambient: Array = []

# The WiFi network currently sniffed (transient — not saved).
var wifi_current := {}

# Networks you've discovered, so you can revisit them. [{ssid, enc}], capped.
var known_networks: Array = []

# Darknet contracts: one active bounty at a time, plus a record of finished ones.
var active_contract := ""
var completed_contracts: Array = []

# Audio volumes (0..1), persisted; applied by the Audio autoload.
var music_vol := 0.8
var sfx_vol := 0.9

# Field gigs you've accepted from the job board (up to MAX_ACTIVE_JOBS). Each is
# a GameData.JOBS id; you complete it at a marker in its target district.
var active_jobs: Array = []
const MAX_ACTIVE_JOBS := 2
var _laptop_nudged := false  # one-time "you can afford the laptop" toast

# Cosmetics: which the player owns, and what's worn per slot. Free defaults are
# owned from the start. Purely visual — the player sprite reads `equipped`.
var owned_cosmetics: Array[String] = ["hoodie_gray", "hat_none"]
var equipped := {"outfit": "hoodie_gray", "hat": "hat_none"}

# Written by the on-screen joystick, read by the player each physics frame.
var touch_vector := Vector2.ZERO

var _ui_locks := 0


func _ready() -> void:
	randomize()
	_setup_input()
	stats_changed.connect(_check_quests)
	if ambient.is_empty():
		_seed_ambient()


# Autosave when the window closes (desktop) or the app is backgrounded (mobile),
# so progress made since the last day-checkpoint isn't lost on exit.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED:
			if not is_new_game:
				save_game()


# --- Save / load -------------------------------------------------------------

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


# Reads a few headline fields from the save without applying it, so the title
# screen can summarise the run on the CONTINUE button. Empty dict if no save.
func peek_save() -> Dictionary:
	if not has_save():
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return {
		"day": int(parsed.get("day", 1)),
		"level": int(parsed.get("level", 1)),
		"cash": int(parsed.get("cash", 0)),
		"reputation": int(parsed.get("reputation", 0)),
	}


func save_game() -> void:
	var data := {"version": SAVE_VERSION}
	for field in PERSISTED:
		data[field] = get(field)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("HackerQuest: could not open save file for writing")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("HackerQuest: save file unreadable, ignoring")
		return false
	for field in PERSISTED:
		if parsed.has(field):
			set(field, _coerce_loaded(field, parsed[field]))
	_reset_trace()
	if heat >= 100:
		heat = trace_escape_heat()
	# Don't retroactively re-reward ranks already earned in the loaded run.
	status_seen = maxi(status_seen, status_index())
	is_new_game = false
	stats_changed.emit()
	quest_changed.emit()
	cosmetics_changed.emit()
	return true


func new_game() -> void:
	cash = 15
	energy = 10
	max_energy = 10
	cpu = 0
	max_cpu = 0
	heat = 0
	reputation = 0
	botnet_size = 0
	day = 1
	has_computer = false
	upgrades = [] as Array[String]
	xp = 0
	level = 1
	skill_points = 0
	status_seen = 0
	skills = {"hardware": 0, "stealth": 0, "hustle": 0, "wardriving": 0}
	inventory = {}
	quest_index = 0
	total_hacks = 0
	hacked_ever = {}
	exploited = {}
	botted = {}
	trash_searched = {}
	wired_cpu = 0
	fixer_used = false
	apartment = "apt_4b"
	_seed_ambient()
	wifi_current = {}
	known_networks = []
	active_contract = ""
	completed_contracts = []
	active_jobs = []
	_laptop_nudged = false
	mastery = {}
	favors_done = []
	goods = {}
	handle = "Anon"
	skin_tone = "e8b890"
	background = "none"
	owned_gear = [] as Array[String]
	gear = {}
	r10t_beaten = false
	owned_furniture = [] as Array[String]
	_reset_trace()
	owned_cosmetics = ["hoodie_gray", "hat_none"] as Array[String]
	equipped = {"outfit": "hoodie_gray", "hat": "hat_none"}
	is_new_game = true
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	stats_changed.emit()
	quest_changed.emit()
	cosmetics_changed.emit()


# JSON loses type info: numbers come back as floats and arrays come back
# untyped. Re-cast the fields where that matters.
func _coerce_loaded(field: String, value: Variant) -> Variant:
	match field:
		"upgrades", "owned_cosmetics", "owned_gear", "owned_furniture":
			var typed: Array[String] = []
			for v in value:
				typed.append(str(v))
			return typed
		"skills":
			var s := {"hardware": 0, "stealth": 0, "hustle": 0, "wardriving": 0}
			for k in value:
				s[k] = int(value[k])
			return s
		"inventory":
			var inv := {}
			for k in value:
				inv[k] = int(value[k])
			return inv
		"cash", "energy", "max_energy", "cpu", "max_cpu", "heat", "reputation", \
		"botnet_size", "day", "xp", "level", "skill_points", "status_seen", \
		"quest_index", "total_hacks":
			return int(value)
	return value


func notify(text: String, color: Color = COL_INFO) -> void:
	toast.emit(text, color)


func lock_ui() -> void:
	_ui_locks += 1
	touch_vector = Vector2.ZERO


func unlock_ui() -> void:
	_ui_locks = maxi(0, _ui_locks - 1)


func is_ui_locked() -> bool:
	return _ui_locks > 0


func owned(id: String) -> bool:
	return id in upgrades


func add_cash(amount: int) -> void:
	cash = maxi(0, cash + amount)
	stats_changed.emit()


func use_energy(amount: int) -> bool:
	if energy < amount:
		notify("Out of energy — sleep, or use food/energy drink from your BAG.", COL_WARN)
		return false
	energy -= amount
	stats_changed.emit()
	return true


# Soft energy cost (e.g. hacking): never blocks, just floors at zero. Running
# dry leaves you fatigued, which hurts hack odds — see fatigue_penalty().
func drain_energy(amount: int) -> void:
	energy = maxi(0, energy - amount)
	stats_changed.emit()


# Below FATIGUE_THRESHOLD of max energy, hack success starts slipping, scaling
# linearly to FATIGUE_MAX at empty. The drink-vs-sleep tradeoff lives here.
const FATIGUE_THRESHOLD := 0.30
const FATIGUE_MAX := 0.20


func fatigue_penalty() -> float:
	if max_energy <= 0:
		return 0.0
	var ratio := float(energy) / float(max_energy)
	if ratio >= FATIGUE_THRESHOLD:
		return 0.0
	return FATIGUE_MAX * (1.0 - ratio / FATIGUE_THRESHOLD)


func is_fatigued() -> bool:
	return fatigue_penalty() > 0.0


func spend_cpu(amount: int) -> bool:
	if cpu < amount:
		notify("CPU drained — sleep, or pop Focus Pills from your BAG.", COL_WARN)
		return false
	cpu -= amount
	stats_changed.emit()
	return true


func add_rep(amount: int) -> void:
	reputation += amount
	if amount > 0 and background == "face":
		reputation += 1  # the Face's reputation grows a little faster
	_check_status()
	stats_changed.emit()


# Background classes (G2): a small permanent bias picked at creation. Called
# once from the creation screen after new_game(). Passive perks (scrapper
# scrap bonus, face rep bonus) live in the relevant payout paths.
func apply_background(bg: String) -> void:
	background = bg
	match bg:
		"coder":
			max_cpu += 2
			cpu = max_cpu
			skill_points += 1
		"runner":
			if not owned("hoverboard"):
				upgrades.append("hoverboard")
		# scrapper & face are passive (see scavenge / add_rep).
	stats_changed.emit()


# Scrapper's permanent scrap bonus, applied alongside daily/mastery mults.
func background_scrap_mult() -> float:
	return 1.5 if background == "scrapper" else 1.0


# --- Status (reputation rank) ------------------------------------------------

func status_index_for(rep: int) -> int:
	var idx := 0
	for i in GameData.STATUS_RANKS.size():
		if rep >= GameData.STATUS_RANKS[i]["rep"]:
			idx = i
	return idx


func status_index() -> int:
	return status_index_for(reputation)


func status_title_for(rep: int) -> String:
	return GameData.STATUS_RANKS[status_index_for(rep)]["title"]


func status_title() -> String:
	return GameData.STATUS_RANKS[status_index()]["title"]


func status_color() -> String:
	return GameData.STATUS_RANKS[status_index()]["color"]


# Reputation toward the next rank, for HUD progress. Returns {cur, need, title}
# or empty when already at the top rank.
func next_status() -> Dictionary:
	var idx := status_index()
	if idx >= GameData.STATUS_RANKS.size() - 1:
		return {}
	var nxt: Dictionary = GameData.STATUS_RANKS[idx + 1]
	return {"need": nxt.rep, "title": nxt.title}


# Announce + reward each newly crossed rank. Rewards come from the rank's
# `reward` block: cash, a skill point, and/or permanent +max Energy/CPU.
func _check_status() -> void:
	var idx := status_index()
	while status_seen < idx:
		status_seen += 1
		var rank: Dictionary = GameData.STATUS_RANKS[status_seen]
		var reward: Dictionary = rank.get("reward", {})
		var parts: Array[String] = []
		if reward.get("cash", 0) > 0:
			cash += reward.cash
			parts.append("+$%d" % reward.cash)
		if reward.get("skill", 0) > 0:
			skill_points += reward.skill
			parts.append("+%d skill point%s" % [reward.skill, "" if reward.skill == 1 else "s"])
		if reward.get("energy", 0) > 0:
			max_energy += reward.energy
			energy += reward.energy
			parts.append("+%d max Energy" % reward.energy)
		if reward.get("cpu", 0) > 0:
			max_cpu += reward.cpu
			cpu += reward.cpu
			parts.append("+%d max CPU" % reward.cpu)
		var suffix := "  (%s)" % ", ".join(parts) if not parts.is_empty() else ""
		notify("STATUS UP — you're now a %s!%s" % [rank.title, suffix], COL_GOOD)


func add_heat(amount: int) -> void:
	if amount > 0:
		# Bigger fish draw more attention: each rank adds a heat surcharge.
		var gain := 1.0 + 0.10 * status_index()
		# Tradecraft cuts it back down.
		var mult := 1.0 - 0.12 * skill("stealth")
		if owned("vpn"):
			mult *= 0.5
		amount = maxi(1, ceili(amount * gain * mult))
	heat = clampi(heat + amount, 0, 100)
	stats_changed.emit()
	if heat >= 100:
		start_trace("heat_max")


func trace_duration() -> float:
	return TRACE_BASE_SECONDS


func trace_escape_heat() -> int:
	return TRACE_ESCAPE_HEAT


func high_risk_hack_heat_threshold() -> int:
	return HIGH_RISK_HACK_HEAT


func start_trace(reason: String, seconds := TRACE_BASE_SECONDS) -> void:
	if trace_active:
		return
	trace_active = true
	trace_seconds_left = seconds
	trace_reason = reason
	notify("TRACE ACTIVE — leave the district!", COL_BAD)
	trace_started.emit(reason, seconds)
	stats_changed.emit()


func force_trace(reason: String) -> void:
	heat = 100
	stats_changed.emit()
	start_trace(reason)


func apply_failed_hack_heat(base_heat: int) -> int:
	if base_heat >= high_risk_hack_heat_threshold():
		force_trace("high_risk_fail")
		return heat
	var before := heat
	var fail_heat := ceili(base_heat / 2.0)
	add_heat(fail_heat)
	return heat - before


func tick_trace(delta: float) -> void:
	if not trace_active:
		return
	trace_seconds_left = maxf(0.0, trace_seconds_left - delta)
	if trace_seconds_left > 0.0:
		return
	trace_active = false
	trace_seconds_left = 0.0
	trace_reason = ""
	trace_cleared.emit(false)
	_bust()


func escape_trace() -> bool:
	if not trace_active:
		return false
	trace_active = false
	trace_seconds_left = 0.0
	trace_reason = ""
	heat = mini(heat, trace_escape_heat())
	stats_changed.emit()
	notify("Trace shaken — heat still hot at %d." % heat, COL_WARN)
	trace_cleared.emit(true)
	save_game()
	return true


# You stood and beat the trace unit in combat (G6). The trace ends cleanly —
# heat is zeroed by the fight's loot (heat_clear), so don't touch it here.
func defeat_trace() -> void:
	if not trace_active:
		return
	trace_active = false
	trace_seconds_left = 0.0
	trace_reason = ""
	stats_changed.emit()
	notify("Trace unit down — you're off the grid.", COL_GOOD)
	trace_cleared.emit(true)
	save_game()


# You lost the fight to the trace unit — same outcome as letting it complete.
func lose_trace_fight() -> void:
	if not trace_active:
		return
	trace_cleared.emit(false)
	_bust()  # also resets the trace state


func _reset_trace() -> void:
	trace_active = false
	trace_seconds_left = 0.0
	trace_reason = ""


# --- Heat / wanted level -----------------------------------------------------

func heat_tier_index() -> int:
	for i in GameData.HEAT_TIERS.size():
		if heat < GameData.HEAT_TIERS[i]["max"]:
			return i
	return GameData.HEAT_TIERS.size() - 1


func heat_tier_name() -> String:
	return GameData.HEAT_TIERS[heat_tier_index()]["name"]


func heat_tier_color() -> String:
	return GameData.HEAT_TIERS[heat_tier_index()]["color"]


# Hack-success penalty from current heat (folded into the terminal odds).
func heat_penalty() -> float:
	return GameData.HEAT_TIERS[heat_tier_index()]["penalty"]


# Heat shed per night's sleep. Climbs with Stealth/VPN, but high-rank scrutiny
# slows it down — so the cooling-off period stretches as you get notorious.
func heat_cooldown_per_day() -> int:
	var cool := 20
	cool -= 2 * status_index()        # notoriety = more eyes
	cool += 4 * skill("stealth")      # tradecraft helps you lie low
	cool += apartment_perk("cool")    # a safer place cools you off
	cool += furniture_perk("cool")    # ...and a VPN rack in the corner
	if owned("vpn"):
		cool += 8
	return maxi(5, cool)


# --- XP / levels / skills ---------------------------------------------------

func xp_needed() -> int:
	return 60 * level


func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		skill_points += 1
		energy = max_energy
		if has_computer:
			cpu = max_cpu
		notify("LEVEL UP! Now level %d (+1 skill point, fully rested)" % level, COL_GOOD)
		leveled_up.emit()
	stats_changed.emit()


func skill(id: String) -> int:
	return skills.get(id, 0)


func buy_skill(id: String) -> bool:
	var s: Dictionary = GameData.SKILLS[id]
	if skill_points < 1 or skill(id) >= s.max:
		return false
	skill_points -= 1
	skills[id] += 1
	if id == "hardware":
		max_cpu += 2
		cpu += 2
	notify("%s rank %d unlocked!" % [s.name, skills[id]], COL_GOOD)
	stats_changed.emit()
	save_game()
	return true


func hustle_mult() -> float:
	return 1.0 + 0.15 * skill("hustle")


# --- Inventory ---------------------------------------------------------------

func add_item(id: String, count: int = 1) -> void:
	inventory[id] = inventory.get(id, 0) + count
	stats_changed.emit()


# Spend an item (combat programs, future crafting). Returns false if you don't
# have enough. Unlike use_consumable this applies no effect — the caller does.
func consume_item(id: String, count := 1) -> bool:
	if inventory.get(id, 0) < count:
		return false
	inventory[id] -= count
	if inventory[id] <= 0:
		inventory.erase(id)
	stats_changed.emit()
	return true


func sell_item(id: String) -> bool:
	if inventory.get(id, 0) <= 0:
		return false
	inventory[id] -= 1
	if inventory[id] <= 0:
		inventory.erase(id)
	var price := int(round(GameData.ITEMS[id]["price"] * hustle_mult()))
	cash += price
	notify("Sold %s for $%d" % [GameData.ITEMS[id]["name"], price], COL_GOOD)
	stats_changed.emit()
	return true


# --- Equipment / gear (G4) ----------------------------------------------------

func owns_gear(id: String) -> bool:
	return id in owned_gear


func buy_gear(id: String) -> bool:
	var g: Dictionary = GameData.GEAR[id]
	if owns_gear(id):
		notify("You already own that.", COL_WARN)
		return false
	if status_index() < int(g.get("status_req", 0)):
		notify("Need %s status first." % GameData.STATUS_RANKS[g.status_req]["title"], COL_WARN)
		return false
	if cash < g.price:
		notify("Not enough cash.", COL_WARN)
		return false
	cash -= g.price
	owned_gear.append(id)
	equip_gear(id)  # auto-equip on purchase
	notify("Bought %s." % g.name, COL_GOOD)
	return true


func equip_gear(id: String) -> void:
	if not owns_gear(id):
		return
	gear[GameData.GEAR[id].slot] = id
	stats_changed.emit()


func gear_stat(slot: String, key: String) -> float:
	var id: String = gear.get(slot, "")
	return float(GameData.GEAR[id].get(key, 0)) if id != "" else 0.0


# Derived combat/hacking stats. Base integrity scales with level; the rest
# come from equipped gear plus the relevant skill.
func base_integrity() -> int:
	return 20 + level * 2


func total_cyber_attack() -> int:
	return int(gear_stat("rig", "cyber")) + skill("hardware")


func total_defense() -> int:
	return int(gear_stat("firewall", "defense")) + skill("stealth")


func total_integrity() -> int:
	return base_integrity() + int(gear_stat("implant", "integrity"))


func total_crit() -> float:
	return gear_stat("implant", "crit")


# The player's combat loadout, snapshotted for a CombatSession (G6). Reads the
# same derived stats hacking uses; stealth feeds the JACK OUT (flee) odds.
func combat_stats() -> Dictionary:
	return {
		"attack": total_cyber_attack(),
		"defense": total_defense(),
		"integrity": total_integrity(),
		"crit": total_crit(),
		"stealth": skill("stealth"),
	}


# A sharper RIG nudges your exploit odds (capped), tying gear into hacking.
func gear_hack_bonus() -> float:
	return minf(0.2, total_cyber_attack() * 0.01)


# --- NPC services ------------------------------------------------------------

const FENCE_PRICE := 55  # Vex pays a premium over the pawn shop's $40

var scrap_bounty_done := false  # Ozark's daily; cleared on sleep


# Sparks the parts dealer buys all your loot at once, +10% over the counter.
func bulk_sell_loot() -> Dictionary:
	var junk: Array = inventory.keys().filter(func(k): return GameData.ITEMS.has(k) and k != "stolen_data")
	if junk.is_empty():
		return {"count": 0, "total": 0}
	var count := 0
	var total := 0
	for id in junk:
		var n: int = inventory[id]
		count += n
		total += int(round(GameData.ITEMS[id]["price"] * 1.1 * hustle_mult())) * n
		inventory.erase(id)
	cash += total
	add_mastery("market")
	stats_changed.emit()
	return {"count": count, "total": total}


# Tess the trainer sells you a skill point; price climbs as you invest.
func train_skill() -> Dictionary:
	var ranks := 0
	for k in skills:
		ranks += int(skills[k])
	var cost := 150 + ranks * 120
	if cash < cost:
		return {"ok": false, "cost": cost}
	cash -= cost
	skill_points += 1
	stats_changed.emit()
	return {"ok": true, "cost": cost}


# Ozark the scrap boss runs a daily bounty: bring him parts for cash + REP.
const SCRAP_BOUNTY_NEED := 5
func scrap_bounty() -> Dictionary:
	if scrap_bounty_done:
		return {"ok": false, "reason": "done"}
	var junk: Array = inventory.keys().filter(func(k): return GameData.ITEMS.has(k) and k != "stolen_data")
	var have := 0
	for id in junk:
		have += int(inventory[id])
	if have < SCRAP_BOUNTY_NEED:
		return {"ok": false, "reason": "short", "have": have, "need": SCRAP_BOUNTY_NEED}
	# Consume the cheapest parts first.
	junk.sort_custom(func(a, b): return GameData.ITEMS[a]["price"] < GameData.ITEMS[b]["price"])
	var taken := 0
	for id in junk:
		while inventory.get(id, 0) > 0 and taken < SCRAP_BOUNTY_NEED:
			inventory[id] -= 1
			if inventory[id] <= 0:
				inventory.erase(id)
			taken += 1
	var reward := 120
	scrap_bounty_done = true
	add_cash(reward)
	add_rep(2)
	add_mastery("underpass")
	return {"ok": true, "reward": reward}

# --- NPC schedules (Alive City) -----------------------------------------------

# Where a named NPC is today. Roamers (GameData.NPC_SCHEDULE) rotate by day;
# everyone else stays at their NPCS home district.
func npc_district(id: String) -> String:
	if GameData.NPC_SCHEDULE.has(id):
		var sched: Array = GameData.NPC_SCHEDULE[id]
		return sched[day % sched.size()]
	return GameData.NPCS[id].get("district", "")


# --- Plaza favors (Alive City) ------------------------------------------------

var favors_done: Array = []  # favor ids done today; cleared on sleep


func do_favor(id: String) -> bool:
	if id in favors_done:
		notify("Already did that one today.", COL_WARN)
		return false
	var fav: Dictionary = {}
	for f in GameData.FAVORS:
		if f.id == id:
			fav = f
			break
	if fav.is_empty():
		return false
	if not use_energy(fav.energy):
		return false
	favors_done.append(id)
	add_rep(fav.rep)
	add_xp(fav.xp)
	add_mastery("plaza")
	notify("Favor done: %s  (+%d REP, +%d XP)" % [fav.name, fav.rep, fav.xp], COL_GOOD)
	return true


# --- Market goods exchange (Alive City) ---------------------------------------

var goods := {}  # good id -> qty owned (persisted)


# Today's price for a good — base scaled 0.55..1.6, deterministic per day+id.
func goods_price(id: String) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("goods_%s_%d" % [id, day])
	var factor := 0.55 + rng.randf() * 1.05
	return maxi(1, int(round(GameData.GOODS[id]["base"] * factor)))


func buy_good(id: String) -> bool:
	var price := goods_price(id)
	if cash < price:
		notify("Not enough cash.", COL_WARN)
		return false
	cash -= price
	goods[id] = int(goods.get(id, 0)) + 1
	stats_changed.emit()
	return true


func sell_good(id: String) -> bool:
	if int(goods.get(id, 0)) <= 0:
		return false
	var price := goods_price(id)
	goods[id] = int(goods[id]) - 1
	if goods[id] <= 0:
		goods.erase(id)
	cash += price
	add_mastery("market")
	stats_changed.emit()
	return true


# --- District mastery (Alive City) --------------------------------------------

var mastery := {}  # district_id -> activity points (persisted)


# Award activity points toward a district's mastery. Tier-ups toast and
# permanently improve that district's payout kind (see GameData.MASTERY).
func add_mastery(district: String, pts := 1) -> void:
	if not GameData.MASTERY.has(district):
		return
	var before := mastery_tier(district)
	mastery[district] = int(mastery.get(district, 0)) + pts
	var after := mastery_tier(district)
	if after > before:
		notify("DISTRICT MASTERY: %s tier %d/3 — %s" % [
				GameData.DISTRICTS[district]["name"], after,
				GameData.MASTERY[district]["perk"]], COL_GOOD)
		stats_changed.emit()


func mastery_tier(district: String) -> int:
	var p := int(mastery.get(district, 0))
	var tier := 0
	for need in GameData.MASTERY_TIERS:
		if p >= int(need):
			tier += 1
	return tier


# Permanent payout multiplier earned through mastery, looked up by kind.
func mastery_mult(kind: String) -> float:
	for district in GameData.MASTERY:
		var m: Dictionary = GameData.MASTERY[district]
		if m.kind == kind:
			return 1.0 + mastery_tier(district) * float(m.per_tier)
	return 1.0


# --- Daily district modifier (Alive City) -------------------------------------

# Today's modifier, deterministic from the day number — stable all day,
# rolls over on sleep, needs no save data.
func daily_modifier() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("citywire_%d" % day)
	return GameData.DAILY_MODS[rng.randi() % GameData.DAILY_MODS.size()]


# The board's gigs for today — a randomized 3, deterministic per day so the
# board is stable until you sleep, with at least one status-gated gig. No
# save data needed.
func daily_gigs(board: String) -> Array:
	var normal: Array = []
	var advanced: Array = []
	for id in GameData.JOBS:
		var j: Dictionary = GameData.JOBS[id]
		if j.get("board", "plaza") != board:
			continue
		if int(j.get("status_req", 0)) > 0:
			advanced.append(id)
		else:
			normal.append(id)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("gigs_%s_%d" % [board, day])
	_seeded_shuffle(normal, rng)
	_seeded_shuffle(advanced, rng)
	var out: Array = []
	for i in mini(2, normal.size()):
		out.append(normal[i])
	if not advanced.is_empty():
		out.append(advanced[0])  # always one advanced gig
	var leftover: Array = normal.slice(2) + advanced.slice(1)
	_seeded_shuffle(leftover, rng)
	while out.size() < 3 and not leftover.is_empty():
		out.append(leftover.pop_front())
	return out


# A gig's effective failure chance — base risk minus tradecraft (Stealth).
func gig_risk(id: String) -> float:
	var base: float = GameData.JOBS[id].get("risk", 0.0)
	return maxf(0.0, base - 0.04 * skill("stealth"))


# --- Field gigs (accept from the board, do them out in the city) -------------

func has_active_job(id: String) -> bool:
	return id in active_jobs


func active_jobs_in(district: String) -> Array:
	var out: Array = []
	for jid in active_jobs:
		if GameData.JOBS.get(jid, {}).get("district", "") == district:
			out.append(jid)
	return out


# Take a gig off the board. Doesn't spend energy — that happens when you do the
# work at the marker. Returns false (with a toast) if you can't take it.
func accept_job(id: String) -> bool:
	if id in active_jobs:
		return false
	if active_jobs.size() >= MAX_ACTIVE_JOBS:
		notify("Two gigs is your limit — finish one first.", COL_WARN)
		return false
	var job: Dictionary = GameData.JOBS[id]
	if status_index() < job.get("status_req", 0):
		notify("That gig needs %s status." % GameData.STATUS_RANKS[job.status_req]["title"], COL_WARN)
		return false
	if job.get("req_computer", false) and not has_computer:
		notify("You'll need a computer for that gig.", COL_WARN)
		return false
	active_jobs.append(id)
	var dname: String = GameData.DISTRICTS[job.district]["name"]
	notify("Gig accepted: %s — head to %s." % [job.name, dname], COL_INFO)
	stats_changed.emit()
	jobs_changed.emit()
	save_game()
	return true


# Do the work at the gig's marker. Spends energy and resolves the risk/reward
# bet here. Returns true if the gig was attempted (consumed), false if you
# couldn't (e.g. out of energy — already toasted). Mirrors the old instant
# payout, with the pre/post-laptop XP taper.
func complete_job(id: String) -> bool:
	if not (id in active_jobs):
		return false
	var job: Dictionary = GameData.JOBS[id]
	if not use_energy(job.energy):
		return false
	var bkind := "jobs_corp" if job.get("board", "plaza") == "corp" else "jobs_plaza"
	var pay := int(round(job.cash * hustle_mult() * daily_mult(bkind) * mastery_mult(bkind)))
	var heat_amt: int = job.get("heat", 0)
	var xp_clean := 8 if not has_computer else 2
	var xp_side := 4 if not has_computer else 1
	add_mastery("corp_row" if bkind == "jobs_corp" else "plaza")
	active_jobs.erase(id)
	if randf() < gig_risk(id):
		var salvage := int(pay * 0.25)
		add_cash(salvage)
		add_heat(int(heat_amt * 1.5) + 5)
		add_xp(xp_side)
		notify("Job went sideways! Salvaged +$%d — and you're hot now." % salvage, COL_BAD)
	else:
		add_cash(pay)
		add_xp(xp_clean)
		if heat_amt > 0:
			add_heat(heat_amt)
		notify("+$%d, +%d XP — %s done clean" % [pay, xp_clean, job.name], COL_GOOD)
		if randf() < job.rep_chance:
			add_rep(1)
			notify("+1 REP — word gets around", COL_INFO)
	_maybe_nudge_laptop()
	stats_changed.emit()
	jobs_changed.emit()
	save_game()
	return true


# One-time nudge when you first scrape together enough for the used laptop.
func _maybe_nudge_laptop() -> void:
	if has_computer or _laptop_nudged:
		return
	var price: int = GameData.UPGRADES["used_laptop"]["price"]
	if cash >= price:
		_laptop_nudged = true
		notify("That's enough for the used laptop — grab it at the PAWN SHOP.", COL_GOOD)


func _seeded_shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


# Payout multiplier for a modifier kind (optionally district-scoped).
func daily_mult(kind: String, district: String = "") -> float:
	var m := daily_modifier()
	if m.kind != kind:
		return 1.0
	if district != "" and m.district != district:
		return 1.0
	return m.mult


# Vex buys all your Stolen Data at a premium. Returns {count, total}.
func fence_stolen_data() -> Dictionary:
	var n: int = inventory.get("stolen_data", 0)
	if n <= 0:
		return {"count": 0, "total": 0}
	inventory.erase("stolen_data")
	var total := int(round(n * FENCE_PRICE * daily_mult("fence") * mastery_mult("fence")))
	cash += total
	add_mastery("market")
	stats_changed.emit()
	return {"count": n, "total": total}


# Marlowe scrubs Heat once per day for a fee that scales with how hot you are.
# Returns {ok, reason, cost, before, after}.
func bribe_fixer() -> Dictionary:
	if trace_active:
		notify("TRACE ACTIVE — leave the district before scrubbing Heat.", COL_BAD)
		return {"ok": false, "reason": "trace"}
	if fixer_used:
		return {"ok": false, "reason": "used"}
	if heat <= 0:
		return {"ok": false, "reason": "clean"}
	var cost := maxi(25, heat * 4)
	if cash < cost:
		return {"ok": false, "reason": "cash", "cost": cost}
	cash -= cost
	var before := heat
	heat = maxi(0, heat - 40)
	fixer_used = true
	stats_changed.emit()
	return {"ok": true, "cost": cost, "before": before, "after": heat}


# --- Housing -----------------------------------------------------------------

func apartment_perk(key: String) -> int:
	return GameData.APARTMENTS[apartment].get(key, 0)


func apartment_name() -> String:
	return GameData.APARTMENTS[apartment]["name"]


func buy_apartment(id: String) -> bool:
	if id == apartment:
		return false
	var apt: Dictionary = GameData.APARTMENTS[id]
	if status_index() < apt.get("status_req", 0):
		notify("That building won't rent to a %s." % status_title(), COL_WARN)
		return false
	if cash < apt.price:
		notify("Not enough cash for the deposit.", COL_WARN)
		return false
	# Move: swap the max-energy perk delta from old place to new.
	var delta: int = apt.max_energy - apartment_perk("max_energy")
	cash -= apt.price
	apartment = id
	max_energy += delta
	energy += maxi(0, delta)
	notify("Moved into %s!" % apt.name, COL_GOOD)
	stats_changed.emit()
	save_game()
	return true


# --- Apartments v2: furniture, Style, trophies -------------------------------

func owns_furniture(id: String) -> bool:
	return id in owned_furniture


# Sum a functional furniture effect across everything you own (cool, income).
# max_energy is NOT summed here — it's applied once at purchase, like moving.
func furniture_perk(key: String) -> int:
	var total := 0
	for id in owned_furniture:
		total += int(GameData.FURNITURE[id].get("effect", {}).get(key, 0))
	return total


func style_score() -> int:
	var total := 0
	for id in owned_furniture:
		total += int(GameData.FURNITURE[id].get("style", 0))
	return total


# A decked-out apartment pays a small daily REP trickle (you're somebody now).
func style_rep_per_day() -> int:
	return mini(6, style_score() / 30)


func buy_furniture(id: String) -> bool:
	if owns_furniture(id):
		return false
	var f: Dictionary = GameData.FURNITURE[id]
	if status_index() < f.get("status_req", 0):
		notify("You're not %s enough for that yet." % GameData.STATUS_RANKS[f.status_req]["title"], COL_WARN)
		return false
	if cash < f.price:
		notify("Not enough cash for that.", COL_WARN)
		return false
	cash -= f.price
	owned_furniture.append(id)
	# Functional max-energy furniture bumps the cap once, here (like moving).
	var bump: int = int(f.get("effect", {}).get("max_energy", 0))
	if bump > 0:
		max_energy += bump
		energy += bump
	notify("Bought %s. Style is up." % f.name, COL_GOOD)
	stats_changed.emit()
	save_game()
	return true


# Milestone trophies that appear on the shelf as you earn them (derived from
# live state — not bought). Returns the ids currently earned, in shelf order.
func trophies() -> Array:
	var out: Array = []
	if total_hacks >= 1:
		out.append("first_pwn")
	if botnet_size >= 1:
		out.append("first_bot")
	if status_index() >= 3:
		out.append("black_hat")
	if botnet_size >= 25:
		out.append("botnet_swarm")
	if r10t_beaten:
		out.append("rival_down")
	if status_index() >= 8:
		out.append("legend")
	return out


# --- WiFi sniffing ("wild encounters") ---------------------------------------

func has_wifi_adapter() -> bool:
	return owned("wifi_adapter")


# Generate a nearby network. Stronger gear/skill/status surface tougher (richer)
# encryption tiers. Stores and returns it.
func sniff_wifi() -> Dictionary:
	var top := mini(GameData.WIFI_ENCRYPTION.size() - 1, 1 + skill("wardriving") + status_index() / 2)
	var tier: int = randi_range(0, top)
	wifi_current = {
		"ssid": GameData.WIFI_SSIDS.pick_random(),
		"enc": tier,
		"bars": randi_range(1, 4),
	}
	_remember_network(wifi_current)
	return wifi_current


# Log a discovered network so it can be revisited. Deduped by ssid+enc, newest
# first, capped.
func _remember_network(net: Dictionary) -> void:
	for k in known_networks:
		if k.ssid == net.ssid and k.enc == net.enc:
			return
	known_networks.push_front({"ssid": net.ssid, "enc": net.enc})
	if known_networks.size() > 10:
		known_networks.resize(10)


# Re-target a saved network (sets it as the current sniff).
func load_known(index: int) -> void:
	if index < 0 or index >= known_networks.size():
		return
	var k: Dictionary = known_networks[index]
	wifi_current = {"ssid": k.ssid, "enc": k.enc, "bars": randi_range(1, 4)}


func wifi_chance(net: Dictionary) -> float:
	var enc: Dictionary = GameData.WIFI_ENCRYPTION[net.enc]
	var base: float = 0.9 - enc.diff * 0.17 + skill("wardriving") * 0.10 + reputation * 0.004
	return clampf(base - fatigue_penalty() - heat_penalty(), 0.05, 0.97)


# Attempt the sniffed network. Costs 1 Energy + (diff) CPU. Returns a result
# dict the UI narrates: {ok, ssid, enc, payout, data, heat, leveled?...} or
# {blocked, reason}.
func crack_wifi() -> Dictionary:
	if wifi_current.is_empty():
		return {"blocked": "none"}
	var enc: Dictionary = GameData.WIFI_ENCRYPTION[wifi_current.enc]
	var cpu_cost: int = enc.diff
	if cpu < cpu_cost:
		return {"blocked": "cpu", "need": cpu_cost}
	if energy < 1:
		return {"blocked": "energy"}
	cpu -= cpu_cost
	drain_energy(1)
	var net := wifi_current
	wifi_current = {}
	var success := randf() < wifi_chance(net)
	if not success:
		add_heat(maxi(1, enc.heat / 2))
		stats_changed.emit()
		return {"ok": false, "ssid": net.ssid, "enc": net.enc, "heat": ceili(enc.heat / 2.0)}
	var payout := int(round(randi_range(enc.min, enc.max) * (1.0 + 0.15 * skill("wardriving")) * hustle_mult()))
	add_cash(payout)
	add_xp(6 + enc.diff * 4)
	add_heat(enc.heat)
	var got_data: bool = randf() < enc.data
	if got_data:
		add_item("stolen_data")
	stats_changed.emit()
	return {"ok": true, "ssid": net.ssid, "enc": net.enc, "payout": payout, "heat": enc.heat, "data": got_data}


# --- Ambient wanderers -------------------------------------------------------

func _seed_ambient() -> void:
	ambient = []
	var open_districts := ["home", "plaza", "market", "underpass"]
	for w in GameData.WANDERERS:
		ambient.append({
			"id": w.id, "name": w.name, "color": w.color,
			"district": open_districts.pick_random(),
		})


func _migrate_ambient() -> void:
	var unlocked := unlocked_districts()
	for w in ambient:
		if randf() < 0.6:  # most move on each night
			w["district"] = unlocked.pick_random()


func ambient_in(district_id: String) -> Array:
	return ambient.filter(func(w): return w.get("district", "") == district_id)


func unlocked_districts() -> Array:
	var out := []
	for id in GameData.DISTRICTS:
		if status_index() >= GameData.DISTRICTS[id].get("status_req", 0):
			out.append(id)
	return out


func district_unlocked(id: String) -> bool:
	return status_index() >= GameData.DISTRICTS[id].get("status_req", 0)


# --- Consumables -------------------------------------------------------------

func is_consumable(id: String) -> bool:
	return GameData.CONSUMABLES.has(id)


func buy_consumable(id: String) -> bool:
	var c: Dictionary = GameData.CONSUMABLES[id]
	if cash < c.price:
		notify("Not enough cash.", COL_WARN)
		return false
	cash -= c.price
	add_item(id)
	notify("Bought %s." % c.name, COL_GOOD)
	stats_changed.emit()
	return true


func use_consumable(id: String) -> bool:
	if inventory.get(id, 0) <= 0 or not is_consumable(id):
		return false
	var c: Dictionary = GameData.CONSUMABLES[id]
	# Combat programs only matter in a fight — don't let them be wasted here.
	if c.has("combat") and c.energy == 0 and c.cpu == 0 and c.wired == 0:
		notify("Save it for a fight — use it from the PROGRAM menu.", COL_WARN)
		return false
	if c.cpu > 0 and not has_computer:
		notify("You need a computer for that.", COL_WARN)
		return false
	# No effect to gain? Don't waste the item.
	var gain_energy: int = mini(c.energy, max_energy - energy)
	var gain_cpu: int = mini(c.cpu, max_cpu - cpu)
	if c.energy > 0 and gain_energy <= 0 and c.wired == 0 and c.cpu == 0:
		notify("Energy already full.", COL_WARN)
		return false
	if c.cpu > 0 and gain_cpu <= 0 and c.energy == 0 and c.wired == 0:
		notify("CPU already full.", COL_WARN)
		return false

	inventory[id] -= 1
	if inventory[id] <= 0:
		inventory.erase(id)

	var parts: Array[String] = []
	if gain_energy > 0:
		energy += gain_energy
		parts.append("+%d Energy" % gain_energy)
	if c.wired > 0:
		max_cpu += c.wired
		cpu += c.wired
		wired_cpu += c.wired
		parts.append("WIRED +%d CPU" % c.wired)
	if gain_cpu > 0:
		cpu += gain_cpu
		parts.append("+%d CPU" % gain_cpu)

	notify("%s — %s" % [c.name, ", ".join(parts)] if not parts.is_empty() else c.name, COL_GOOD)
	stats_changed.emit()
	return true


# --- Cosmetics ---------------------------------------------------------------

func owns_cosmetic(id: String) -> bool:
	return id in owned_cosmetics


func is_wearing(id: String) -> bool:
	var c: Dictionary = GameData.COSMETICS[id]
	return equipped.get(c.slot, "") == id


func buy_cosmetic(id: String) -> bool:
	if owns_cosmetic(id):
		return false
	var c: Dictionary = GameData.COSMETICS[id]
	var req: int = c.get("status_req", 0)
	if status_index() < req:
		notify("Reach %s status first." % GameData.STATUS_RANKS[req]["title"], COL_WARN)
		return false
	if cash < c.price:
		notify("Not enough cash.", COL_WARN)
		return false
	cash -= c.price
	owned_cosmetics.append(id)
	equipped[c.slot] = id  # wear it right away
	notify("Bought %s — looking sharp." % c.name, COL_GOOD)
	stats_changed.emit()
	cosmetics_changed.emit()
	save_game()
	return true


func equip_cosmetic(id: String) -> bool:
	if not owns_cosmetic(id):
		return false
	var c: Dictionary = GameData.COSMETICS[id]
	equipped[c.slot] = id
	notify("Now wearing %s." % c.name, COL_INFO)
	cosmetics_changed.emit()
	save_game()
	return true


# Sprite lookups (player.gd). Fall back gracefully if equipped id is unknown.
func cosmetic_color(slot: String, fallback: String) -> String:
	var id: String = equipped.get(slot, "")
	if GameData.COSMETICS.has(id):
		return GameData.COSMETICS[id].get("color", fallback)
	return fallback


func cosmetic_style(slot: String) -> String:
	var id: String = equipped.get(slot, "")
	if GameData.COSMETICS.has(id):
		return GameData.COSMETICS[id].get("style", "")
	return ""


# Called by the terminal on every successful exploit. Returns true when the
# hack also yielded a sellable data item.
func register_hack(id: String, difficulty: int) -> bool:
	total_hacks += 1
	hacked_ever[id] = true
	add_xp(10 * difficulty)
	_check_contract(id)
	if randf() < 0.35:
		add_item("stolen_data")
		return true
	return false


# --- Darknet contracts -------------------------------------------------------

func accept_contract(id: String) -> bool:
	var c: Dictionary = GameData.CONTRACTS[id]
	if id in completed_contracts:
		return false
	if status_index() < c.get("status_req", 0):
		notify("Oracle won't trust that job to a %s." % status_title(), COL_WARN)
		return false
	active_contract = id
	notify("Contract accepted: %s. Pwn %s." % [c.name, c.target], COL_INFO)
	stats_changed.emit()
	return true


# Pay out when the active contract's target gets pwned.
func _check_contract(target_id: String) -> void:
	if active_contract == "":
		return
	var c: Dictionary = GameData.CONTRACTS[active_contract]
	if c.target != target_id:
		return
	var pay := int(round(c.cash * mastery_mult("contracts")))
	cash += pay
	add_rep(c.rep)
	add_xp(c.xp)
	completed_contracts.append(active_contract)
	add_mastery("darknet", 2)  # big jobs claim territory faster
	notify("CONTRACT COMPLETE: %s! +$%d, +%d REP" % [c.name, pay, c.rep], COL_GOOD)
	active_contract = ""
	stats_changed.emit()


# --- Quest line ---------------------------------------------------------------

var _quest_checking := false


func current_quest_text() -> String:
	if quest_index >= GameData.QUESTS.size():
		return "Free play — the city is yours"
	return GameData.QUESTS[quest_index]["text"]


func _check_quests() -> void:
	if _quest_checking:
		return
	_quest_checking = true
	while quest_index < GameData.QUESTS.size() and _quest_met(GameData.QUESTS[quest_index]):
		var q: Dictionary = GameData.QUESTS[quest_index]
		quest_index += 1
		var reward := ""
		if q.cash > 0:
			cash += q.cash
			reward += " +$%d" % q.cash
		if q.xp > 0:
			add_xp(q.xp)
			reward += " +%d XP" % q.xp
		notify("OBJECTIVE COMPLETE!%s" % reward, COL_GOOD)
		quest_changed.emit()
	_quest_checking = false


func _quest_met(q: Dictionary) -> bool:
	match q.cond:
		"cash":
			return cash >= q.value
		"computer":
			return has_computer
		"hacks":
			return total_hacks >= q.value
		"botnet":
			return botnet_size >= q.value
		"rep":
			return reputation >= q.value
		"status":
			return status_index() >= q.value
		"target":
			return hacked_ever.has(q.value)
	return false


func buy_upgrade(id: String) -> bool:
	if owned(id):
		notify("You already own that.", COL_WARN)
		return false
	var u: Dictionary = GameData.UPGRADES[id]
	if u.req != "" and not owned(u.req):
		notify("You need a %s first." % GameData.UPGRADES[u.req]["name"], COL_WARN)
		return false
	if cash < u.price:
		notify("Not enough cash.", COL_WARN)
		return false
	cash -= u.price
	upgrades.append(id)
	match id:
		"used_laptop":
			has_computer = true
			max_cpu += 6
			cpu = max_cpu
		"ram_upgrade":
			max_cpu += 4
			cpu += 4
		"workstation":
			max_cpu += 8
			cpu += 8
		"server_rack":
			max_cpu += 12
			cpu += 12
		"quantum_rig":
			max_cpu += 18
			cpu += 18
		"battery":
			max_energy += 4
			energy += 4
		"desk_setup":
			reputation += 2
	notify("Bought %s!" % u.name, COL_GOOD)
	if id == "used_laptop":
		notify("Use the desk in your apartment to open the terminal.", COL_INFO)
	stats_changed.emit()
	save_game()
	return true


func sleep() -> void:
	if trace_active:
		notify("TRACE ACTIVE — leave the district before you sleep.", COL_BAD)
		return
	day += 1
	var income := botnet_size * 2
	if owned("desk_setup"):
		income = int(income * 1.5)
	income += apartment_perk("income")  # rent out the spare room, etc.
	income += furniture_perk("income")  # the server closet earns its keep
	if income > 0:
		cash += income
	# A stylish place pays a small daily REP trickle — you're somebody now.
	var style_rep := style_rep_per_day()
	if style_rep > 0:
		add_rep(style_rep)
	# Sleeping it off ends any energy-drink high and resets daily favors.
	max_cpu -= wired_cpu
	wired_cpu = 0
	fixer_used = false
	energy = max_energy
	cpu = max_cpu
	var cooled := int(round(heat_cooldown_per_day() * mastery_mult("sleep_cool")))
	var prev_heat := heat
	heat = maxi(0, heat - cooled)
	exploited.clear()
	trash_searched.clear()
	favors_done.clear()
	scrap_bounty_done = false
	add_mastery("home")  # routine is its own mastery
	_migrate_ambient()
	stats_changed.emit()
	day_changed.emit(day)
	notify("Day %d — you wake up rested. Targets got re-secured overnight." % day)
	if prev_heat > 0:
		notify("Heat cooled %d → %d overnight" % [prev_heat, heat], COL_INFO)
	if income > 0:
		notify("+$%d overnight income" % income, COL_GOOD)
	save_game()  # day boundary is the main checkpoint


func _bust() -> void:
	_reset_trace()
	cash = cash / 2
	botnet_size = botnet_size / 2
	heat = 50
	exploited.clear()
	stats_changed.emit()
	notify("TRACED! Lost half your cash and half your botnet.", COL_BAD)
	busted.emit()
	save_game()  # lock in the loss so quitting can't dodge it


# Input actions are registered in code so project.godot stays clean and the
# bindings are easy to read and tweak.
func _setup_input() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("interact", [KEY_E, KEY_SPACE])


func _add_key_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
