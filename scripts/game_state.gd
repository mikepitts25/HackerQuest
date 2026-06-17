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
const DEBUG_GOD_CASH := 99999
const TRUNK_KEY_ITEM := "r10t_root_key"

# Fields written to / read from the save file. Listed once so save and load
# can't drift apart. Dictionaries/arrays of plain data round-trip through JSON;
# load re-casts ints and the typed upgrades array (see _coerce_loaded).
const PERSISTED := [
	"cash", "energy", "max_energy", "cpu", "max_cpu", "heat", "reputation",
	"botnet_size", "day", "has_computer", "upgrades", "xp", "level",
	"skill_points", "status_seen", "skills", "inventory", "quest_index", "total_hacks",
	"hacked_ever", "exploited", "botted", "trash_searched", "wired_cpu",
	"fixer_used", "apartment", "ambient", "known_networks", "wifi_backdoors",
	"active_contract", "completed_contracts", "owned_cosmetics", "equipped", "active_jobs",
	"mastery", "favors_done", "goods", "handle", "skin_tone", "background",
	"scrap_bounty_done", "owned_gear", "gear", "r10t_beaten", "owned_furniture",
	"defeated_crew_bosses", "owned_pets", "active_pet", "solved_cryptograms",
	"cafe_rig_rented", "cafe_hacked", "cafe_riot_beaten",
	"r10t_finale_won", "game_beaten",
	"music_vol", "sfx_vol",
]

# True until a save is loaded; lets the main scene pick intro vs "welcome back".
var is_new_game := true

var owned_gear: Array[String] = []
# Set once you beat R10T in combat (G6) — gates the rare boss encounter so the
# rival only ambushes you once.
var r10t_beaten := false
var defeated_crew_bosses: Array[String] = []
# Furniture you've bought for your apartment (Apartments v2). Drives perks +
# Style score; rendered in home_3d.
var owned_furniture: Array[String] = []
var owned_pets: Array[String] = []
var active_pet := ""
var solved_cryptograms: Array[String] = []
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

# Darknet Café side-arc: rent the back rig ($5/hr) to open the café LAN, then
# drain the other patrons' laptops. Clearing the room the first time summons
# R10T for a duel. The rental and the per-day drains reset on sleep; beating
# R10T is permanent (he doesn't ambush the café twice).
var cafe_rig_rented := false   # reset on sleep
var cafe_hacked := {}          # patron_id -> true; reset on sleep
var cafe_riot_beaten := false  # permanent — café duel done, R10T fled to the bay

# Drowned Quarter finale: beating the R10T + Deep Marrow gauntlet sets
# r10t_finale_won (and drops the root key); wiping the Trunk with that key sets
# game_beaten. Both permanent. See drowned_quarter_3d.
var r10t_finale_won := false
var game_beaten := false

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
var wifi_backdoors := {}     # district_id -> day-long cracked-network leverage

# Darknet contracts: one active bounty at a time, plus a record of finished ones.
var active_contract := ""
var completed_contracts: Array = []

# Audio volumes (0..1), persisted; applied by the Audio autoload.
var music_vol := 0.8
var sfx_vol := 0.9

# Generated field gigs you've accepted from the job board. Each entry is a
# plain Dictionary so it saves cleanly: template, uid, district, pos, step, etc.
var active_jobs: Array = []
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
	_migrate_legacy_pet_upgrade()
	_reset_trace()
	if heat >= 100:
		heat = trace_escape_heat()
	# Don't retroactively re-reward ranks already earned in the loaded run.
	status_seen = maxi(status_seen, status_index())
	_normalize_active_jobs()
	is_new_game = false
	stats_changed.emit()
	quest_changed.emit()
	cosmetics_changed.emit()
	return true


func new_game() -> void:
	_ui_locks = 0
	touch_vector = Vector2.ZERO
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
	cafe_rig_rented = false
	cafe_hacked = {}
	cafe_riot_beaten = false
	r10t_finale_won = false
	game_beaten = false
	wired_cpu = 0
	fixer_used = false
	apartment = "apt_4b"
	_seed_ambient()
	wifi_current = {}
	known_networks = []
	wifi_backdoors = {}
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
	defeated_crew_bosses = [] as Array[String]
	owned_furniture = [] as Array[String]
	owned_pets = [] as Array[String]
	active_pet = ""
	solved_cryptograms = [] as Array[String]
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
		"upgrades", "owned_cosmetics", "owned_gear", "owned_furniture", "defeated_crew_bosses", "owned_pets", "solved_cryptograms":
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
		"wifi_backdoors":
			var backs := {}
			for k in value:
				backs[str(k)] = int(value[k])
			return backs
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


func _migrate_legacy_pet_upgrade() -> void:
	if not ("robo_pet" in upgrades):
		return
	upgrades.erase("robo_pet")
	if not ("dog" in owned_pets):
		owned_pets.append("dog")
	if active_pet == "":
		active_pet = "dog"


func add_cash(amount: int) -> void:
	cash = maxi(0, cash + amount)
	stats_changed.emit()


# Buy a meal at a street eatery (Big City pass): spend cash to restore energy
# without sleeping. A handy cash sink in the bigger districts; refuses politely
# when you're already full or short on cash.
func buy_meal(place: String, cost: int, energy_gain: int) -> void:
	if energy >= max_energy:
		notify("Not hungry — energy's already full.", COL_WARN)
		return
	if cash < cost:
		notify("Not enough cash for %s ($%d)." % [place, cost], COL_WARN)
		return
	cash -= cost
	var gain: int = mini(energy_gain, max_energy - energy)
	energy += gain
	Audio.sfx("cash")
	notify("%s — +%d Energy (-$%d)" % [place, gain, cost], COL_GOOD)
	stats_changed.emit()


func max_reputation() -> int:
	return int(GameData.STATUS_RANKS[GameData.STATUS_RANKS.size() - 1]["rep"])


# TEMP DEBUG: remove before production. Lets playtests jump to endgame economy.
func grant_debug_god_mode() -> void:
	cash = DEBUG_GOD_CASH
	reputation = max_reputation()
	status_seen = status_index()
	notify("GOD TEST MODE: $%d and %s status." % [cash, status_title()], COL_WARN)
	stats_changed.emit()
	quest_changed.emit()


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
	cool += 4 * total_stealth()       # tradecraft helps you lie low
	cool += apartment_perk("cool")    # a safer place cools you off
	cool += furniture_perk("cool")    # ...and a VPN rack in the corner
	cool += int(pet_stat("cool"))
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
	return 1.0 + 0.15 * skill("hustle") + pet_stat("cash_mult")


# --- Pets --------------------------------------------------------------------

func owns_pet(id: String) -> bool:
	return id in owned_pets


func has_pet() -> bool:
	return active_pet != "" and owns_pet(active_pet) and GameData.PETS.has(active_pet)


func pet_stat(key: String) -> float:
	if not has_pet():
		return 0.0
	return float(GameData.PETS[active_pet].get(key, 0.0))


func buy_pet(id: String) -> bool:
	if not GameData.PETS.has(id):
		return false
	if owns_pet(id):
		notify("You already adopted that companion.", COL_WARN)
		return false
	var p: Dictionary = GameData.PETS[id]
	if cash < int(p.price):
		notify("Not enough cash.", COL_WARN)
		return false
	cash -= int(p.price)
	owned_pets.append(id)
	active_pet = id
	notify("%s is traveling with you." % p.name, COL_GOOD)
	stats_changed.emit()
	save_game()
	return true


func equip_pet(id: String) -> bool:
	if not owns_pet(id) or not GameData.PETS.has(id):
		return false
	active_pet = id
	notify("%s is traveling with you." % GameData.PETS[id].name, COL_GOOD)
	stats_changed.emit()
	save_game()
	return true


func solve_cryptogram(id: String) -> bool:
	if GameData.cryptogram_clue(id).is_empty():
		return false
	if id in solved_cryptograms:
		return false
	solved_cryptograms.append(id)
	notify("Cryptogram fragment decoded (%d/%d)." % [
		solved_cryptograms.size(), GameData.CRYPTOGRAM_CLUES.size()], COL_INFO)
	stats_changed.emit()
	save_game()
	return true


func cryptogram_complete() -> bool:
	for clue in GameData.CRYPTOGRAM_CLUES:
		if not (str(clue.id) in solved_cryptograms):
			return false
	return GameData.CRYPTOGRAM_CLUES.size() > 0


func target_unlocked(id: String) -> bool:
	if not GameData.TARGETS.has(id):
		return false
	var t: Dictionary = GameData.TARGETS[id]
	if bool(t.get("cryptogram_req", false)) and not cryptogram_complete():
		return false
	return true


# --- Inventory ---------------------------------------------------------------

func add_item(id: String, count: int = 1) -> void:
	inventory[id] = inventory.get(id, 0) + count
	stats_changed.emit()


func is_key_item(id: String) -> bool:
	return GameData.ITEMS.has(id) and bool(GameData.ITEMS[id].get("key_item", false))


func is_junk_item(id: String) -> bool:
	return GameData.ITEMS.has(id) and not is_key_item(id)


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
	if is_key_item(id):
		notify("%s is too important to sell." % GameData.ITEMS[id]["name"], COL_WARN)
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


func grant_gear(id: String, auto_equip := true) -> bool:
	if not GameData.GEAR.has(id):
		return false
	var fresh := not owns_gear(id)
	if fresh:
		owned_gear.append(id)
	if auto_equip:
		equip_gear(id)
	else:
		stats_changed.emit()
	return fresh


func has_endgame_loadout() -> bool:
	return "quantum_rig" in upgrades \
		and owns_gear("rig_zeroday") \
		and owns_gear("fw_black") \
		and owns_gear("imp_ghost")


func crew_boss_defeated(enemy_id: String) -> bool:
	return enemy_id in defeated_crew_bosses


func mark_crew_boss_defeated(enemy_id: String) -> void:
	if enemy_id != "" and not crew_boss_defeated(enemy_id):
		defeated_crew_bosses.append(enemy_id)


func target_required_gear(t: Dictionary) -> String:
	return str(t.get("required_gear", ""))


func target_has_required_gear(t: Dictionary) -> bool:
	var id := target_required_gear(t)
	return id == "" or owns_gear(id)


func target_required_gear_equipped(t: Dictionary) -> bool:
	var id := target_required_gear(t)
	if id == "":
		return true
	return gear.get(GameData.GEAR[id].slot, "") == id


func target_tier_gear_modifier(t: Dictionary) -> float:
	var id := target_required_gear(t)
	if id == "":
		return 0.0
	if target_required_gear_equipped(t):
		return 0.20
	if owns_gear(id):
		return 0.08
	return -0.12


func gear_stat(slot: String, key: String) -> float:
	var id: String = gear.get(slot, "")
	return float(GameData.GEAR[id].get(key, 0)) if id != "" else 0.0


# Derived combat/hacking stats. Base integrity scales with level; the rest
# come from equipped gear plus the relevant skill.
func base_integrity() -> int:
	return 20 + level * 2


func total_cyber_attack() -> int:
	return int(gear_stat("rig", "cyber")) + skill("hardware") + int(pet_stat("attack"))


func total_defense() -> int:
	return int(gear_stat("firewall", "defense")) + total_stealth()


func total_stealth() -> int:
	return skill("stealth") + int(pet_stat("stealth"))


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
		"stealth": total_stealth(),
		"endgame_loadout": has_endgame_loadout(),
	}


# A sharper RIG nudges your exploit odds (capped), tying gear into hacking.
func gear_hack_bonus() -> float:
	return minf(0.2, total_cyber_attack() * 0.01)


# --- NPC services ------------------------------------------------------------

const FENCE_PRICE := 55  # Vex pays a premium over the pawn shop's $40

var scrap_bounty_done := false  # Ozark's daily; cleared on sleep


# Sparks the parts dealer buys all your loot at once, +10% over the counter.
func bulk_sell_loot_quote() -> Dictionary:
	var junk: Array = inventory.keys().filter(func(k): return is_junk_item(k) and k != "stolen_data")
	var count := 0
	var total := 0
	for id in junk:
		var n: int = inventory[id]
		count += n
		total += int(round(GameData.ITEMS[id]["price"] * 1.1 * hustle_mult())) * n
	return {"count": count, "total": total}


func bulk_sell_loot() -> Dictionary:
	var junk: Array = inventory.keys().filter(func(k): return is_junk_item(k) and k != "stolen_data")
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
func train_skill_quote() -> Dictionary:
	var ranks := 0
	for k in skills:
		ranks += int(skills[k])
	var cost := 150 + ranks * 120
	return {"cost": cost, "ok": cash >= cost}


func train_skill() -> Dictionary:
	var quote := train_skill_quote()
	var cost: int = quote.cost
	if cash < cost:
		return {"ok": false, "cost": cost}
	cash -= cost
	skill_points += 1
	stats_changed.emit()
	return {"ok": true, "cost": cost}


# Ozark the scrap boss runs a daily bounty: bring him parts for cash + REP.
const SCRAP_BOUNTY_NEED := 5
func scrap_bounty_quote() -> Dictionary:
	if scrap_bounty_done:
		return {"ok": false, "reason": "done"}
	var junk: Array = inventory.keys().filter(func(k): return is_junk_item(k) and k != "stolen_data")
	var have := 0
	for id in junk:
		have += int(inventory[id])
	if have < SCRAP_BOUNTY_NEED:
		return {"ok": false, "reason": "short", "have": have, "need": SCRAP_BOUNTY_NEED}
	return {"ok": true, "have": have, "need": SCRAP_BOUNTY_NEED, "reward": 120}


func scrap_bounty() -> Dictionary:
	var quote := scrap_bounty_quote()
	if not quote.ok:
		return quote
	# Consume the cheapest parts first.
	var junk: Array = inventory.keys().filter(func(k): return is_junk_item(k) and k != "stolen_data")
	junk.sort_custom(func(a, b): return GameData.ITEMS[a]["price"] < GameData.ITEMS[b]["price"])
	var taken := 0
	for id in junk:
		while inventory.get(id, 0) > 0 and taken < SCRAP_BOUNTY_NEED:
			inventory[id] -= 1
			if inventory[id] <= 0:
				inventory.erase(id)
			taken += 1
	var reward: int = quote.reward
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

const JOB_DISTRICT_BOUNDS := {
	"plaza": [2.0, 2.0, 20.0, 13.0],
	"market": [2.0, 2.0, 18.0, 12.0],
	"underpass": [1.5, 1.5, 13.5, 9.5],
	"corp_row": [2.0, 2.0, 18.0, 12.0],
	"darknet": [2.0, 2.0, 16.0, 11.0],
	"drowned_quarter": [1.5, 1.5, 11.0, 8.5],
}
const JOB_GOALS := {
	"wifi": [
		{"prompt": "Spoof the relay", "objective": "spoof the access relay"},
		{"prompt": "Trace the signal", "objective": "trace the weak signal"},
		{"prompt": "Patch the handshake", "objective": "patch the handshake"},
	],
	"drop": [
		{"prompt": "Grab the package", "objective": "grab the package"},
		{"prompt": "Swap the bag", "objective": "swap the dead drop"},
		{"prompt": "Stash the goods", "objective": "stash the goods"},
	],
	"meet": [
		{"prompt": "Meet the contact", "objective": "meet the contact"},
		{"prompt": "Verify the phrase", "objective": "verify the code phrase"},
		{"prompt": "Shake the tail", "objective": "shake the tail"},
	],
	"heist": [
		{"prompt": "Plant the tap", "objective": "plant the tap"},
		{"prompt": "Lift the cache", "objective": "lift the data cache"},
		{"prompt": "Burn the logs", "objective": "burn the logs"},
	],
	"recon": [
		{"prompt": "Case the spot", "objective": "case the spot"},
		{"prompt": "Tag the camera", "objective": "tag the camera"},
		{"prompt": "Map the patrol", "objective": "map the patrol"},
	],
}


func has_active_job(id: String) -> bool:
	for job in active_jobs:
		var j := _active_job_dict(job)
		if j.get("template", "") == id or j.get("uid", "") == id:
			return true
	return false


func active_jobs_in(district: String) -> Array:
	_normalize_active_jobs()
	var out: Array = []
	for job in active_jobs:
		var j := _active_job_dict(job)
		if j.get("district", "") == district:
			out.append(j)
	return out


# Take a gig off the board. Doesn't spend energy — that happens when you do the
# work at the marker. Returns false (with a toast) if you can't take it.
func accept_job(id: String) -> bool:
	_normalize_active_jobs()
	if has_active_job(id):
		return false
	var job: Dictionary = GameData.JOBS[id]
	if status_index() < job.get("status_req", 0):
		notify("That gig needs %s status." % GameData.STATUS_RANKS[job.status_req]["title"], COL_WARN)
		return false
	if job.get("req_computer", false) and not has_computer:
		notify("You'll need a computer for that gig.", COL_WARN)
		return false
	var inst := _generate_job_instance(id)
	active_jobs.append(inst)
	var dname: String = GameData.DISTRICTS[inst.district]["name"]
	notify("Gig accepted: %s — %s in %s." % [inst.name, inst.objective, dname], COL_INFO)
	stats_changed.emit()
	jobs_changed.emit()
	save_game()
	return true


# Do one step of a field gig. Most gigs require multiple stops; only the final
# step resolves pay/risk and clears the job.
func complete_job(id: String) -> bool:
	_normalize_active_jobs()
	var idx := _active_job_index(id)
	if idx < 0:
		return false
	var job: Dictionary = active_jobs[idx]
	var cpu_cost: int = job.get("cpu", 0)
	if cpu_cost > 0 and not spend_cpu(cpu_cost):
		return false
	if not use_energy(job.energy):
		return false
	var bkind := "jobs_corp" if job.get("board", "plaza") == "corp" else "jobs_plaza"
	var pay := int(round(job.cash * hustle_mult() * daily_mult(bkind) * mastery_mult(bkind)))
	var heat_amt: int = job.get("heat", 0)
	var xp_clean := 8 if not has_computer else 2
	var xp_side := 4 if not has_computer else 1
	add_mastery("corp_row" if bkind == "jobs_corp" else "plaza")
	job.step = int(job.get("step", 1)) + 1
	if job.step <= int(job.get("steps_total", 1)):
		_assign_job_stop(job)
		active_jobs[idx] = job
		var dname_next: String = GameData.DISTRICTS[job.district]["name"]
		notify("Gig step done. Next: %s in %s." % [job.objective, dname_next], COL_INFO)
		stats_changed.emit()
		jobs_changed.emit()
		save_game()
		return true
	active_jobs.remove_at(idx)
	if randf() < float(job.get("risk", 0.0)):
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


func _active_job_index(id: String) -> int:
	for i in active_jobs.size():
		var j := _active_job_dict(active_jobs[i])
		if j.get("uid", "") == id or j.get("template", "") == id:
			return i
	return -1


func _active_job_dict(job: Variant) -> Dictionary:
	if job is Dictionary:
		return job
	if job is String and GameData.JOBS.has(job):
		return _generate_job_instance(job)
	return {}


func _normalize_active_jobs() -> void:
	for i in active_jobs.size():
		if active_jobs[i] is String:
			active_jobs[i] = _generate_job_instance(active_jobs[i])
		elif active_jobs[i] is Dictionary:
			active_jobs[i] = _normalize_job_instance(active_jobs[i])


func _normalize_job_instance(job: Dictionary) -> Dictionary:
	var template: String = job.get("template", "")
	if template == "" and GameData.JOBS.has(job.get("uid", "")):
		template = job.uid
	if template == "" or not GameData.JOBS.has(template):
		return job
	var base: Dictionary = GameData.JOBS[template]
	job.template = template
	job.uid = str(job.get("uid", "gig_%s_%d" % [template, Time.get_ticks_msec()]))
	job.name = str(job.get("name", base.name))
	job.desc = str(job.get("desc", base.desc))
	job.archetype = str(job.get("archetype", base.get("archetype", "drop")))
	job.board = str(job.get("board", base.get("board", "plaza")))
	job.energy = int(job.get("energy", base.energy))
	job.cpu = int(job.get("cpu", 0))
	job.cash = int(job.get("cash", base.cash))
	job.heat = int(job.get("heat", base.get("heat", 0)))
	job.step = int(job.get("step", 1))
	job.steps_total = maxi(1, int(job.get("steps_total", 1)))
	job.rep_chance = float(job.get("rep_chance", base.get("rep_chance", 0.0)))
	job.risk = float(job.get("risk", base.get("risk", 0.0)))
	if not JOB_DISTRICT_BOUNDS.has(job.get("district", "")):
		_assign_job_stop(job)
	elif not job.has("pos"):
		_assign_job_stop(job)
	else:
		job.prompt = str(job.get("prompt", JOB_GOALS.get(job.archetype, JOB_GOALS["drop"])[0].prompt))
		job.objective = str(job.get("objective", JOB_GOALS.get(job.archetype, JOB_GOALS["drop"])[0].objective))
	return job


func _generate_job_instance(id: String) -> Dictionary:
	var base: Dictionary = GameData.JOBS[id]
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var cash_roll := int(round(base.cash * rng.randf_range(0.75, 1.45)))
	var energy_roll := maxi(1, int(base.energy) + rng.randi_range(-1, 1))
	var archetype: String = base.get("archetype", "drop")
	var cpu_roll := 0
	if archetype in ["wifi", "heist", "recon"] and base.get("req_computer", false):
		cpu_roll = rng.randi_range(1, maxi(1, min(4, int(base.get("energy", 1)))))
	if cash_roll == int(base.cash) and energy_roll == int(base.energy):
		cash_roll += maxi(1, int(round(base.cash * 0.1)))
	var inst := {
		"uid": "gig_%s_%d_%d" % [id, Time.get_ticks_msec(), rng.randi()],
		"template": id,
		"name": base.name,
		"desc": base.desc,
		"archetype": archetype,
		"board": base.get("board", "plaza"),
		"energy": energy_roll,
		"cpu": cpu_roll,
		"cash": cash_roll,
		"rep_chance": clampf(float(base.get("rep_chance", 0.0)) + rng.randf_range(-0.08, 0.12), 0.0, 0.95),
		"heat": maxi(0, int(round(base.get("heat", 0) * rng.randf_range(0.6, 1.35)))),
		"risk": clampf(float(base.get("risk", 0.0)) + rng.randf_range(-0.04, 0.08), 0.0, 0.8),
		"step": 1,
		"steps_total": rng.randi_range(2, 3),
	}
	_assign_job_stop(inst)
	return inst


func _assign_job_stop(job: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var districts := _job_district_candidates()
	job.district = districts[rng.randi_range(0, districts.size() - 1)]
	var bounds: Array = JOB_DISTRICT_BOUNDS.get(job.district, [2.0, 2.0, 10.0, 8.0])
	job.pos = [
		rng.randf_range(float(bounds[0]), float(bounds[2])),
		rng.randf_range(float(bounds[1]), float(bounds[3])),
	]
	var goals: Array = JOB_GOALS.get(job.get("archetype", "drop"), JOB_GOALS["drop"])
	var goal: Dictionary = goals[rng.randi_range(0, goals.size() - 1)]
	job.prompt = goal.prompt
	job.objective = goal.objective


func _job_district_candidates() -> Array:
	var out := []
	for id in JOB_DISTRICT_BOUNDS:
		if GameData.DISTRICTS.has(id) and district_unlocked(id):
			out.append(id)
	if out.is_empty():
		out.append("plaza")
	return out


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
func fence_stolen_data_quote() -> Dictionary:
	var n: int = inventory.get("stolen_data", 0)
	if n <= 0:
		return {"count": 0, "total": 0}
	var total := int(round(n * FENCE_PRICE * daily_mult("fence") * mastery_mult("fence")))
	return {"count": n, "total": total}


func fence_stolen_data() -> Dictionary:
	var quote := fence_stolen_data_quote()
	var n: int = quote.count
	if n <= 0:
		return quote
	inventory.erase("stolen_data")
	var total: int = quote.total
	cash += total
	add_mastery("market")
	stats_changed.emit()
	return {"count": n, "total": total}


# Marlowe scrubs Heat once per day for a fee that scales with how hot you are.
# Returns {ok, reason, cost, before, after}.
func bribe_fixer_quote() -> Dictionary:
	if trace_active:
		return {"ok": false, "reason": "trace"}
	if fixer_used:
		return {"ok": false, "reason": "used"}
	if heat <= 0:
		return {"ok": false, "reason": "clean"}
	var cost := maxi(25, heat * 4)
	if cash < cost:
		return {"ok": false, "reason": "cash", "cost": cost}
	return {"ok": true, "cost": cost, "before": heat, "after": maxi(0, heat - 40)}


func bribe_fixer() -> Dictionary:
	var quote := bribe_fixer_quote()
	if not quote.ok:
		if quote.get("reason", "") == "trace":
			notify("TRACE ACTIVE — leave the district before scrubbing Heat.", COL_BAD)
		return quote
	var cost: int = quote.cost
	cash -= cost
	var before: int = quote.before
	heat = quote.after
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
func sniff_wifi(district := "") -> Dictionary:
	var top := mini(GameData.WIFI_ENCRYPTION.size() - 1, 1 + skill("wardriving") + status_index() / 2)
	var tier: int = randi_range(0, top)
	wifi_current = {
		"ssid": GameData.WIFI_SSIDS.pick_random(),
		"enc": tier,
		"bars": randi_range(1, 4),
		"district": district,
	}
	_remember_network(wifi_current)
	return wifi_current


# Log a discovered network so it can be revisited. Deduped by ssid+enc, newest
# first, capped.
func _remember_network(net: Dictionary) -> void:
	for k in known_networks:
		if k.ssid == net.ssid and k.enc == net.enc:
			return
	known_networks.push_front({"ssid": net.ssid, "enc": net.enc, "district": net.get("district", "")})
	if known_networks.size() > 10:
		known_networks.resize(10)


# Re-target a saved network (sets it as the current sniff).
func load_known(index: int) -> void:
	if index < 0 or index >= known_networks.size():
		return
	var k: Dictionary = known_networks[index]
	wifi_current = {"ssid": k.ssid, "enc": k.enc, "bars": randi_range(1, 4), "district": k.get("district", "")}


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
	var seeded_bots := _seed_wifi_botnet(net)
	var backdoor_power := _add_wifi_backdoor(net)
	var got_data: bool = randf() < enc.data
	if got_data:
		add_item("stolen_data")
	stats_changed.emit()
	return {"ok": true, "ssid": net.ssid, "enc": net.enc, "payout": payout, "heat": enc.heat,
		"data": got_data, "bots": seeded_bots, "backdoor": backdoor_power,
		"district": net.get("district", "")}


func _seed_wifi_botnet(net: Dictionary) -> int:
	var enc: Dictionary = GameData.WIFI_ENCRYPTION[net.enc]
	var bots: int = maxi(1, int(enc.diff) + int(net.get("bars", 1)) / 2)
	botnet_size += bots
	return bots


func _add_wifi_backdoor(net: Dictionary) -> int:
	var district := str(net.get("district", ""))
	if district == "" or not GameData.DISTRICTS.has(district):
		return 0
	var enc: Dictionary = GameData.WIFI_ENCRYPTION[net.enc]
	var power: int = maxi(1, int(enc.diff) + 1)
	wifi_backdoors[district] = int(wifi_backdoors.get(district, 0)) + power
	return power


func wifi_backdoor_bonus(district: String) -> float:
	return minf(0.18, int(wifi_backdoors.get(district, 0)) * 0.06)


func target_wifi_backdoor_modifier(t: Dictionary) -> float:
	return wifi_backdoor_bonus(str(t.get("district", "")))


const BOTNET_FLOOD_MIN := 10


func botnet_flood_available() -> bool:
	return botnet_size >= BOTNET_FLOOD_MIN


func botnet_flood_damage() -> int:
	if not botnet_flood_available():
		return 0
	return clampi(18 + botnet_size, 35, 70)


func consume_botnet_flood() -> Dictionary:
	if not botnet_flood_available():
		return {"ok": false, "reason": "botnet", "need": BOTNET_FLOOD_MIN}
	var before := botnet_size
	var burn := ceili(before * 0.5)
	var damage := botnet_flood_damage()
	botnet_size = maxi(0, botnet_size - burn)
	add_heat(8 + burn / 2)
	stats_changed.emit()
	return {"ok": true, "name": "Botnet Flood", "burn": burn, "before": before,
		"combat": {"damage": damage}}


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
	# Interiors reached only from within another district (e.g. the corp
	# datacenter) aren't in DISTRICTS — they inherit their parent's gating by
	# virtue of the door living inside it, so treat the unlisted as open.
	return status_index() >= GameData.DISTRICTS.get(id, {}).get("status_req", 0)


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


func final_contract_id() -> String:
	var best_id := ""
	var best_req := -1
	for id in GameData.CONTRACTS:
		var c: Dictionary = GameData.CONTRACTS[id]
		var req: int = c.get("status_req", 0)
		if req > best_req:
			best_req = req
			best_id = id
	return best_id


func final_contract_complete() -> bool:
	var id := final_contract_id()
	return id != "" and id in completed_contracts


func has_trunk_key() -> bool:
	return inventory.get(TRUNK_KEY_ITEM, 0) > 0


# Drive the R10T Root Key into the breached Trunk — the final act. Consumes the
# key, flags the game beaten, and persists. Drowned Quarter plays the in-world
# victory beat around this (see drowned_quarter_3d._play_victory).
func mark_game_beaten() -> void:
	if game_beaten:
		return
	if inventory.get(TRUNK_KEY_ITEM, 0) > 0:
		consume_item(TRUNK_KEY_ITEM)
	game_beaten = true
	save_game()
	stats_changed.emit()
	quest_changed.emit()


func trunk_ready() -> bool:
	return final_contract_complete() and has_trunk_key()


func final_contract_hint() -> String:
	var id := final_contract_id()
	if id == "":
		return "No final contract is listed."
	var c: Dictionary = GameData.CONTRACTS[id]
	if not final_contract_complete():
		return "Complete the Darknet contract '%s' by pwning %s before jacking in." % [c.name, c.target]
	if not has_trunk_key():
		return "Beat R10T and take the R10T Root Key before jacking in."
	return "The final contract is done and the R10T Root Key is in your bag."


func trunk_prompt() -> String:
	if game_beaten:
		return "The Trunk is wiped"
	if r10t_finale_won:
		return "Jack into the trunk"   # R10T down, key in hand — finish it
	if cafe_riot_beaten:
		return "R10T guards the trunk"  # the rematch waits on the walkway
	if trunk_ready():
		return "Jack into the trunk"
	var id := final_contract_id()
	if id == "":
		return "Jack into the trunk"
	if final_contract_complete() and not has_trunk_key():
		return "Jack in needs R10T Root Key"
	return "Jack in needs %s" % GameData.CONTRACTS[id].name


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
	cafe_rig_rented = false
	cafe_hacked.clear()
	wifi_backdoors.clear()
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
