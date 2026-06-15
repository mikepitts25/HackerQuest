class_name GameData
## Static game data. Everything here is fictional, locally simulated content —
## no real networking is performed anywhere in the game.

const TARGETS := {
	"parking_meter_node": {
		"name": "parking_meter_node",
		"desc": "A solar parking meter running firmware from 2009.",
		"difficulty": 1, "cpu_cost": 1, "payout_min": 10, "payout_max": 20,
		"heat": 3, "botnet_value": 1, "rep_req": 0,
		"district": "plaza", "district_tier": 1,
	},
	"coffee_shop_router": {
		"name": "coffee_shop_router",
		"desc": "Free wifi, default admin password. A classic.",
		"difficulty": 1, "cpu_cost": 2, "payout_min": 25, "payout_max": 40,
		"heat": 5, "botnet_value": 1, "rep_req": 0,
		"district": "plaza", "district_tier": 1,
	},
	"old_nas_box": {
		"name": "old_nas_box",
		"desc": "Somebody's forgotten home NAS, still chugging away.",
		"difficulty": 2, "cpu_cost": 3, "payout_min": 50, "payout_max": 80,
		"heat": 10, "botnet_value": 2, "rep_req": 2,
		"district": "market", "district_tier": 2, "required_gear": "rig_sidewalk_slicer",
	},
	"smart_billboard": {
		"name": "smart_billboard",
		"desc": "Downtown LED billboard. The ad rotation budget is juicy.",
		"difficulty": 3, "cpu_cost": 4, "payout_min": 90, "payout_max": 140,
		"heat": 15, "botnet_value": 3, "rep_req": 4,
		"district": "market", "district_tier": 2, "required_gear": "rig_sidewalk_slicer",
	},
	"crypto_kiosk": {
		"name": "crypto_kiosk",
		"desc": "A sketchy mall crypto ATM. Sketchier security.",
		"difficulty": 4, "cpu_cost": 5, "payout_min": 180, "payout_max": 260,
		"heat": 25, "botnet_value": 4, "rep_req": 6,
		"district": "underpass", "district_tier": 3, "required_gear": "rig_kiosk_needle",
	},
	"corp_mail_relay": {
		"name": "corp_mail_relay",
		"desc": "MegaCorp's neglected mail relay. The big leagues.",
		"difficulty": 5, "cpu_cost": 6, "payout_min": 350, "payout_max": 500,
		"heat": 40, "botnet_value": 6, "rep_req": 9,
		"district": "corp_row", "district_tier": 4, "required_gear": "rig_tunnel_splice",
	},
	"city_power_grid": {
		"name": "city_power_grid",
		"desc": "SCADA from the dial-up era. Don't trip the breakers.",
		"difficulty": 6, "cpu_cost": 7, "payout_min": 550, "payout_max": 800,
		"heat": 24, "botnet_value": 8, "rep_req": 14,
		"district": "underpass", "district_tier": 3, "required_gear": "rig_kiosk_needle",
	},
	"bank_core": {
		"name": "bank_core",
		"desc": "Mainframe behind seven firewalls. The real money.",
		"difficulty": 7, "cpu_cost": 9, "payout_min": 900, "payout_max": 1300,
		"heat": 30, "botnet_value": 11, "rep_req": 22,
		"district": "corp_row", "district_tier": 4, "required_gear": "rig_tunnel_splice",
	},
	"satellite_uplink": {
		"name": "satellite_uplink",
		"desc": "Orbital relay. Latency's a nightmare, payout isn't.",
		"difficulty": 8, "cpu_cost": 11, "payout_min": 1500, "payout_max": 2100,
		"heat": 36, "botnet_value": 15, "rep_req": 35,
		"district": "darknet", "district_tier": 5, "required_gear": "rig_corpbreaker",
	},
	"darknet_market": {
		"name": "darknet_market",
		"desc": "Hijack the escrow of the biggest market on the wire.",
		"difficulty": 9, "cpu_cost": 13, "payout_min": 2400, "payout_max": 3300,
		"heat": 42, "botnet_value": 20, "rep_req": 55,
		"district": "darknet", "district_tier": 5, "required_gear": "rig_corpbreaker",
	},
	"ai_datacenter": {
		"name": "ai_datacenter",
		"desc": "A sentient-grade cluster. Pwn it before it pwns you.",
		"difficulty": 10, "cpu_cost": 16, "payout_min": 4000, "payout_max": 5500,
		"heat": 50, "botnet_value": 28, "rep_req": 80,
		"district": "drowned_quarter", "district_tier": 6, "required_gear": "rig_ghostroot",
	},
	"motherlode_vault": {
		"name": "motherlode_vault",
		"desc": "The cache named by the citywide cryptogram trail. It only answers once the whole phrase is assembled.",
		"difficulty": 11, "cpu_cost": 18, "payout_min": 9000, "payout_max": 13000,
		"heat": 55, "botnet_value": 45, "rep_req": 60,
		"district": "drowned_quarter", "district_tier": 6, "required_gear": "rig_ghostroot",
		"cryptogram_req": true, "loot_item": "zero_day_cache",
	},
}

const UPGRADES := {
	"used_laptop": {
		"name": "Used Laptop",
		"desc": "Boots... mostly. Unlocks the terminal at your apartment desk. +6 max CPU.",
		"price": 100, "req": "",
	},
	"battery": {
		"name": "Better Battery",
		"desc": "For your phone and your soul. +4 max Energy per day.",
		"price": 120, "req": "",
	},
	"wifi_adapter": {
		"name": "Wireless Adapter",
		"desc": "High-gain USB antenna. Sniff and crack WiFi networks anywhere (📶 button).",
		"price": 80, "req": "",
	},
	"hoverboard": {
		"name": "Hoverboard",
		"desc": "Cracked-firmware deck. Glides you around the city +60% faster.",
		"price": 250, "req": "",
	},
	"maglev_board": {
		"name": "Maglev Deck",
		"desc": "Frictionless mag-lev upgrade. +120% move speed. The city shrinks.",
		"price": 1200, "req": "hoverboard",
	},
	"ram_upgrade": {
		"name": "RAM Upgrade",
		"desc": "Sticker still says 'GAMER'. +4 max CPU for bigger hacks.",
		"price": 150, "req": "used_laptop",
	},
	"vpn": {
		"name": "VPN Subscription",
		"desc": "Twelve hops through nowhere. Heat gains halved.",
		"price": 200, "req": "used_laptop",
	},
	"desk_setup": {
		"name": "Pro Desk Setup",
		"desc": "Three monitors, zero excuses. +2 Reputation, botnet collections +50%.",
		"price": 300, "req": "used_laptop",
	},
	"workstation": {
		"name": "Workstation",
		"desc": "A real machine with real cooling. +8 max CPU.",
		"price": 650, "req": "ram_upgrade",
	},
	"server_rack": {
		"name": "Closet Server Rack",
		"desc": "Your apartment runs hot now. +12 max CPU.",
		"price": 1600, "req": "workstation",
	},
	"quantum_rig": {
		"name": "Quantum Co-Processor",
		"desc": "Grey-market qubits. +18 max CPU. Cracks anything.",
		"price": 4500, "req": "server_rack",
	},
}

const PETS := {
	"dog": {
		"name": "Byte (Robot Dog)",
		"desc": "A salvaged companion drone with a bitey counter-intrusion suite.",
		"price": 400, "ability": "+2 cyber-attack", "attack": 2, "stealth": 0,
		"cash_mult": 0.0, "cool": 0, "color": "7adfff",
	},
	"cat": {
		"name": "Null (Shadow Cat)",
		"desc": "Sleeps on warm routers and somehow knows where the cameras are.",
		"price": 520, "ability": "+1 stealth", "attack": 0, "stealth": 1,
		"cash_mult": 0.0, "cool": 0, "color": "b277e0",
	},
	"bird": {
		"name": "Cache (Courier Bird)",
		"desc": "A jittery delivery drone that skims better tips and scrap buyers.",
		"price": 480, "ability": "+10% cash gains", "attack": 0, "stealth": 0,
		"cash_mult": 0.10, "cool": 0, "color": "ffd166",
	},
	"lizard": {
		"name": "Glitch (Thermal Lizard)",
		"desc": "A heat-sink crawler that helps your trail cool faster overnight.",
		"price": 650, "ability": "+3 Heat cooldown/day", "attack": 0, "stealth": 0,
		"cash_mult": 0.0, "cool": 3, "color": "7ee787",
	},
}

const CRYPTOGRAM_CLUES := [
	{
		"id": "plaza_cipher", "district": "plaza", "title": "Cipher Fragment 1",
		"encoded": "WKH ILUVW NHB VLWV XQGHU WKH ORXGHVW OLJKW.",
		"plain": "THE FIRST KEY SITS UNDER THE LOUDEST LIGHT.",
		"hint": "Caesar -3. Start where the Plaza signs never sleep.",
		"pos3d": [34, 36], "pos2d": [610, 650],
	},
	{
		"id": "market_cipher", "district": "market", "title": "Cipher Fragment 2",
		"encoded": "GUR FRPBAQ XRL VF OHEVRQ VA GUR FPEBCCRQ ENVQ.",
		"plain": "THE SECOND KEY IS BURIED IN THE SCRAPPED RAID.",
		"hint": "ROT13. The Market remembers every busted drive.",
		"pos3d": [42, 23], "pos2d": [700, 390],
	},
	{
		"id": "underpass_cipher", "district": "underpass", "title": "Cipher Fragment 3",
		"encoded": "13-15-20-8-5-18 / 12-15-4-5 / 12-9-19-20-5-14-19.",
		"plain": "MOTHER LODE LISTENS.",
		"hint": "A1Z26. The tunnel repeats what the city drops.",
		"pos3d": [20, 10], "pos2d": [420, 260],
	},
	{
		"id": "corp_cipher", "district": "corp_row", "title": "Cipher Fragment 4",
		"encoded": "bW90aGVybG9kZV92YXVsdCBhd2FpdHMgYSBnaG9zdCByaWcu",
		"plain": "motherlode_vault awaits a ghost rig.",
		"hint": "Base64. Corp Row leaves clean breadcrumbs.",
		"pos3d": [31, 30], "pos2d": [860, 520],
	},
]

# Travelable districts. status_req indexes STATUS_RANKS; 0 = always open.
const DISTRICTS := {
	"home": {"name": "Home", "scene": "res://scenes/districts/home.tscn", "status_req": 0},
	"plaza": {"name": "Plaza", "scene": "res://scenes/districts/plaza.tscn", "status_req": 0},
	"market": {"name": "Market", "scene": "res://scenes/districts/market.tscn", "status_req": 0},
	"underpass": {"name": "The Underpass", "scene": "res://scenes/districts/underpass.tscn", "status_req": 0},
	"corp_row": {"name": "Corp Row", "scene": "res://scenes/districts/corp_row.tscn", "status_req": 3},
	"darknet": {"name": "Darknet Cafe", "scene": "res://scenes/districts/darknet.tscn", "status_req": 6},
	"drowned_quarter": {"name": "Drowned Quarter", "scene": "res://scenes/districts/drowned_quarter.tscn", "status_req": 7},
}

const DISTRICT_TIERS := {
	"plaza": 1,
	"market": 2,
	"underpass": 3,
	"corp_row": 4,
	"darknet": 5,
	"drowned_quarter": 6,
}

const RIOT_CREW_BY_DISTRICT := {
	"plaza": "byte_bully",
	"market": "packet_jackal",
	"underpass": "tunnel_warden",
	"corp_row": "ice_barron",
	"darknet": "ghost_admin",
	"drowned_quarter": "deep_marrow",
}

# Plaza favors (Alive City phase 2): small community tasks that pay REP, not
# cash — the Plaza's grind identity. Repeatable, one of each per day.
const FAVORS := [
	{"id": "router_walk", "name": "Reboot Mrs. Kim's router",
		"desc": "Three flights up. Blow on it. Magic.", "energy": 1, "rep": 1, "xp": 4},
	{"id": "lost_drone", "name": "Find a kid's lost drone",
		"desc": "Last seen heading for the underpass. Brave kid.", "energy": 2, "rep": 1, "xp": 6},
	{"id": "wifi_setup", "name": "Set up the café's new WiFi",
		"desc": "Hide the password where the regulars can't lose it.", "energy": 2, "rep": 2, "xp": 8},
	{"id": "scam_warn", "name": "Warn the elders about a phishing scam",
		"desc": "Patience required. Worth more than money.", "energy": 3, "rep": 3, "xp": 10},
]

# Market goods exchange (Alive City phase 2): commodities with daily prices.
# Buy low, sell high — the Market's grind identity. Price swings are
# deterministic per day+good (GameState.goods_price), so no save data needed.
const GOODS := {
	"burner_phones": {"name": "Burner Phones", "base": 45},
	"sd_cards": {"name": "Bulk SD Cards", "base": 18},
	"vpn_keys": {"name": "VPN Key Cards", "base": 70},
	"sim_packs": {"name": "Prepaid SIM Packs", "base": 30},
}

# District mastery (Alive City phase 2): doing a district's thing fills its
# meter; crossing TIERS thresholds grants permanent multiplier perks, looked
# up by `kind` via GameState.mastery_mult(). Grinding claims territory.
const MASTERY_TIERS := [5, 15, 30]
const MASTERY := {
	"home": {"kind": "sleep_cool", "per_tier": 0.10,
		"perk": "sleep cools +10% more heat per tier"},
	"plaza": {"kind": "jobs_plaza", "per_tier": 0.05,
		"perk": "plaza jobs pay +5% per tier"},
	"market": {"kind": "fence", "per_tier": 0.10,
		"perk": "Vex pays +10% more per tier"},
	"underpass": {"kind": "scrap", "per_tier": 0.25,
		"perk": "scrap pays +25% more per tier"},
	"corp_row": {"kind": "jobs_corp", "per_tier": 0.05,
		"perk": "corp gigs pay +5% per tier"},
	"darknet": {"kind": "contracts", "per_tier": 0.05,
		"perk": "contracts pay +5% per tier"},
	"drowned_quarter": {"kind": "taps", "per_tier": 0.0,
		"perk": "reserved — the trunk remembers"},
}

# Daily district modifiers (Alive City phase 3). One is active per day,
# picked deterministically from the day number (GameState.daily_modifier),
# so it needs no save data. kind/mult are consulted at payout time via
# GameState.daily_mult().
const DAILY_MODS := [
	{"id": "gig_surge", "district": "plaza", "name": "Gig Surge",
		"desc": "Plaza job board pays +50% today.", "kind": "jobs_plaza", "mult": 1.5},
	{"id": "corp_crunch", "district": "corp_row", "name": "Corp Crunch",
		"desc": "Corp gigs pay +50% today.", "kind": "jobs_corp", "mult": 1.5},
	{"id": "scrap_rush", "district": "underpass", "name": "Scrap Rush",
		"desc": "Underpass e-waste pays double scrap today.", "kind": "scrap", "mult": 2.0},
	{"id": "ewaste_drop", "district": "market", "name": "E-Waste Drop",
		"desc": "Market trash pays double scrap today.", "kind": "scrap", "mult": 2.0},
	{"id": "fence_demand", "district": "market", "name": "Fence Demand",
		"desc": "Vex pays +50% per data packet today.", "kind": "fence", "mult": 1.5},
]

# The city map (HUD "MAP" modal, drawn by scripts/ui/city_map.gd) as a
# subway-style network diagram. `stations` are live districts (names/locks
# come from DISTRICTS + GameState); positions are normalized 0..1 over the
# map canvas. `future` stations are planned expansions — drawn as faint
# "???" teaser stops in-game, revealed by name on the docs render.
const DISTRICT_MAP := {
	"stations": {
		"home": {"pos": [0.14, 0.82]},
		"plaza": {"pos": [0.36, 0.64]},
		"market": {"pos": [0.58, 0.48]},
		"underpass": {"pos": [0.14, 0.52]},
		"corp_row": {"pos": [0.58, 0.26]},
		"darknet": {"pos": [0.82, 0.12]},
		"drowned_quarter": {"pos": [0.56, 0.04]},
	},
	"links": [
		["home", "plaza"], ["plaza", "market"], ["plaza", "underpass"],
		["market", "corp_row"], ["corp_row", "darknet"],
		["darknet", "drowned_quarter"],
	],
	"future": {
		"the_stacks": {"name": "The Stacks", "pos": [0.40, 0.90], "from": "home",
			"hook": "container-home maze · hideout with heat-decay perk"},
		"neon_strip": {"name": "Neon Strip", "pos": [0.84, 0.60], "from": "market",
			"hook": "casino row · rival crews · cosmetic exclusives"},
		"signal_yards": {"name": "Signal Yards", "pos": [0.32, 0.18], "from": "corp_row",
			"hook": "antenna farm · rare encrypted WiFi"},
		"rooftops": {"name": "Rooftops", "pos": [0.12, 0.10], "from": "signal_yards",
			"hook": "relay network endgame · city-wide botnet range"},
		"old_exchange": {"name": "Old Exchange", "pos": [0.86, 0.36], "from": "corp_row",
			"hook": "abandoned trading floor · time-window heists"},
	},
}

# World NPCs. Each lives in a `district`; `pos` is [x, y] local to that
# district scene. Spawned by District._spawn_npcs(); talked to via
# Main.talk_npc(id).
const NPCS := {
	"pix": {"name": "Pix", "district": "plaza", "pos": [820, 480], "color": "b277e0", "role": "starter mentor"},
	"riot": {"name": "Riot", "district": "plaza", "pos": [520, 420], "color": "3aa68a", "role": "rival hacker"},
	"glitch": {"name": "Glitch", "district": "plaza", "pos": [960, 380], "color": "e0894a", "role": "street tips"},
	"marlowe": {"name": "Marlowe", "district": "plaza", "pos": [680, 600], "color": "3b5dc9", "role": "heat fixer"},
	"vex": {"name": "Vex", "district": "market", "pos": [320, 300], "color": "c060c0", "role": "data fence"},
	"cipher": {"name": "Cipher", "district": "corp_row", "pos": [380, 360], "color": "5ad1c0", "role": "corp intel"},
	"oracle": {"name": "Oracle", "district": "darknet", "pos": [520, 360], "color": "d06fff", "role": "endgame guide"},
	# G3 service NPCs — populate the bigger districts with people who DO things.
	# No dedicated char scene → spawned as a tinted citizen (district_3d).
	"sparks": {"name": "Sparks", "district": "market", "pos": [1300, 880], "color": "e0b050", "role": "parts buyer"},
	"tess": {"name": "Tess", "district": "plaza", "pos": [1500, 460], "color": "70d0c0", "role": "skill trainer"},
	"ozark": {"name": "Ozark", "district": "underpass", "pos": [1040, 880], "color": "c07040", "role": "scrap bounty"},
	# The drowned quarter's lone keeper — a drift-diver who lives in the flooded
	# fiber and listens to THE TRUNK. The endgame's human voice (reads the final
	# contract state in her lines); spawned as a tinted citizen.
	"fathom": {"name": "Fathom", "district": "drowned_quarter", "pos": [480, 640], "color": "4fd0e0", "role": "drift diver"},
	"byte_bully": {"name": "Byte Bully", "district": "plaza", "pos": [1180, 520], "color": "ff5a66", "role": "R10T crew boss"},
	"packet_jackal": {"name": "Packet Jackal", "district": "market", "pos": [920, 420], "color": "ff7a3d", "role": "R10T crew boss"},
	"tunnel_warden": {"name": "Tunnel Warden", "district": "underpass", "pos": [760, 620], "color": "b277e0", "role": "R10T crew boss"},
	"ice_barron": {"name": "ICE Barron", "district": "corp_row", "pos": [820, 500], "color": "7adfff", "role": "R10T crew boss"},
	"ghost_admin": {"name": "Ghost Admin", "district": "darknet", "pos": [760, 520], "color": "d06fff", "role": "R10T crew boss"},
	"deep_marrow": {"name": "Deep Marrow", "district": "drowned_quarter", "pos": [860, 660], "color": "9fffe0", "role": "R10T crew boss"},
}

# Anonymous crowd flavor (G3): names + body tints for the ambient pedestrians
# that fill each district (district_3d._spawn_crowd). Pure life, no services.
const CITIZEN_NAMES := [
	"a commuter", "a street vendor", "a student", "a courier", "a barista",
	"a busker", "a delivery rider", "a night-shift worker", "an old-timer",
	"a tourist", "a dog-walker", "a street medic", "a hawker", "a teen",
	"a data-mule", "a janitor", "a food-cart cook", "a off-duty guard",
]
const CITIZEN_TINTS := [
	"8a93a6", "d8a657", "89b4d6", "c98aa6", "9ad08a", "b0a0c0", "c0c0a0",
	"a0b0c0", "d0a0a0", "90c0b0", "c0a070", "7088b0",
]

# NPC schedules (Alive City phase 4): regulars who don't sit still. Each
# listed NPC rotates through these districts by day (GameState.npc_district),
# so the city's faces move around — and the CITY GRID map shows where they
# are today. NPCs not listed stay in their NPCS "district". Mentors and
# endgame contacts (Pix, Marlowe, Vex, Cipher, Oracle) stay put on purpose.
const NPC_SCHEDULE := {
	"riot": ["plaza", "market", "underpass", "corp_row", "darknet", "drowned_quarter"],
	"glitch": ["plaza", "underpass", "plaza", "market"], # the broker keeps moving
}

# Ambient wanderers — friendly NPCs that roam a district and migrate between
# districts on sleep, so the city feels lived-in. Pure flavor.
const WANDERERS := [
	{"id": "w_dog", "name": "Guy with Laptop", "color": "8a93a6"},
	{"id": "w_courier", "name": "Courier", "color": "d8a657"},
	{"id": "w_busker", "name": "Busker", "color": "89b4d6"},
	{"id": "w_tourist", "name": "Lost Tourist", "color": "c98aa6"},
	{"id": "w_skater", "name": "Skater Kid", "color": "9ad08a"},
]

const ITEMS := {
	"copper_wire": {"name": "Copper Wire", "price": 8},
	"cracked_phone": {"name": "Cracked Phone", "price": 12},
	"ram_stick": {"name": "RAM Stick", "price": 18},
	"old_hdd": {"name": "Old HDD", "price": 22},
	"old_gpu": {"name": "Dusty GPU", "price": 35},
	"stolen_data": {"name": "Stolen Data", "price": 40},
	"circuit_gold": {"name": "Gold-Trace Board", "price": 70},
	"salvaged_rig": {"name": "Salvaged Rig Core", "price": 120},
	"crypto_wallet": {"name": "Forgotten Wallet", "price": 200},
	"zero_day_cache": {"name": "Zero-Day Cache", "price": 2500,
		"desc": "A motherlode bundle of exploits, creds, and sellable leverage."},
	"r10t_root_key": {"name": "R10T Root Key", "price": 0, "key_item": true,
		"desc": "Riot's private trunk credential. The city core will not open without it."},
}

# Weighted pool for alley scavenging (GPU is the rare find).
const TRASH_LOOT := [
	"copper_wire", "copper_wire", "cracked_phone", "cracked_phone",
	"ram_stick", "ram_stick", "old_hdd", "old_gpu",
]

# District-flavored scavenging (G1 economy): per-district scrap-cash range,
# loot pool, XP, and the chance of a RARE high-value bonus find on top.
# Underpass is the motherlode; Corp Row e-waste is sparse but classy.
# Falls back to "default" for any district not listed (GameData.trash_table).
const TRASH_TABLES := {
	"underpass": {
		"scrap": [3, 8], "xp": 4, "rare_chance": 0.20,
		"pool": ["ram_stick", "ram_stick", "old_hdd", "old_hdd", "old_gpu", "old_gpu", "circuit_gold"],
		"rare": ["salvaged_rig", "circuit_gold", "crypto_wallet"],
	},
	"market": {
		"scrap": [2, 5], "xp": 3, "rare_chance": 0.12,
		"pool": ["copper_wire", "cracked_phone", "ram_stick", "ram_stick", "old_hdd", "old_gpu"],
		"rare": ["circuit_gold", "salvaged_rig"],
	},
	"corp_row": {
		"scrap": [2, 4], "xp": 3, "rare_chance": 0.16,
		"pool": ["ram_stick", "old_hdd", "old_gpu", "old_gpu", "circuit_gold"],
		"rare": ["salvaged_rig", "crypto_wallet"],
	},
	"default": {
		"scrap": [2, 4], "xp": 3, "rare_chance": 0.06,
		"pool": ["copper_wire", "copper_wire", "cracked_phone", "ram_stick", "old_hdd"],
		"rare": ["circuit_gold"],
	},
}


static func trash_table(district: String) -> Dictionary:
	return TRASH_TABLES.get(district, TRASH_TABLES["default"])


static func district_tier_name(district: String) -> String:
	var d: Dictionary = DISTRICTS.get(district, {})
	var tier: int = int(DISTRICT_TIERS.get(district, 0))
	if tier <= 0:
		return str(d.get("name", "Unknown"))
	return "tier %d %s" % [tier, str(d.get("name", "Unknown"))]


static func cryptogram_clue(id: String) -> Dictionary:
	for clue in CRYPTOGRAM_CLUES:
		if str(clue.get("id", "")) == id:
			return clue
	return {}

# Buyable, repeatable, usable items. Effects applied by GameState.use_consumable:
#   energy : restores Energy (capped at max)
#   cpu    : restores CPU now (capped at max)
#   wired  : temporary +max CPU until you next sleep ("perform at higher capacity")
const CONSUMABLES := {
	"instant_noodles": {
		"name": "Instant Noodles",
		"desc": "+3 Energy. Sad, salty, effective.",
		"price": 10, "energy": 3, "cpu": 0, "wired": 0,
	},
	"energy_drink": {
		"name": "Energy Drink",
		"desc": "+5 Energy and WIRED: +2 max CPU until you sleep.",
		"price": 22, "energy": 5, "cpu": 0, "wired": 2,
	},
	"focus_pills": {
		"name": "Focus Pills",
		"desc": "+4 CPU right now. Needs a computer to matter.",
		"price": 28, "energy": 0, "cpu": 4, "wired": 0,
	},
	# Combat programs (G6) — PROGRAM action in a fight. No out-of-combat effect
	# (energy/cpu/wired all 0); GameState.use_consumable refuses them outside a
	# fight so they aren't wasted. The `combat` block is read by the combat UI.
	"logic_bomb": {
		"name": "Logic Bomb",
		"desc": "Combat: a burst payload — 14 damage that ignores their firewall.",
		"price": 70, "energy": 0, "cpu": 0, "wired": 0,
		"combat": {"damage": 14},
	},
	"patch_kit": {
		"name": "Patch Kit",
		"desc": "Combat: hotfix your deck mid-fight for +20 integrity.",
		"price": 55, "energy": 0, "cpu": 0, "wired": 0,
		"combat": {"heal": 20},
	},
	"proxy_smoke": {
		"name": "Proxy Smoke",
		"desc": "Combat: bounce your signal — your next JACK OUT can't fail.",
		"price": 40, "energy": 0, "cpu": 0, "wired": 0,
		"combat": {"flee_bonus": 1.0},
	},
}

# Turn-based combat opponents (G6). Same four stats as the player
# (attack/defense/integrity/crit) so the math is symmetric. `moveset` is the
# pool the dumb AI picks from each turn; enemy-only moves are `ddos` (heavy hit)
# and `trace_lock` (chip damage + makes the next JACK OUT harder). `loot` pays
# out on a win. `flee: false` forbids JACK OUT (bosses, trace units). `tier`
# gates which enemies appear in random street encounters.
const ENEMIES := {
	"script_kid": {
		"name": "Script Kiddie", "integrity": 18, "attack": 3, "defense": 1, "crit": 0.0,
		"moveset": ["exploit", "exploit", "firewall"],
		"loot": {"cash": [20, 45], "xp": 15, "rep": 1},
		"flee": true, "tier": 0,
		"intro": "Some kid in a hoodie squares up, cracking their knuckles.",
		"taunts": ["u even got a 0day, bro?", "ez.", "skill issue lol"]},
	"street_hacker": {
		"name": "Corner Cracker", "integrity": 34, "attack": 6, "defense": 4, "crit": 0.05,
		"moveset": ["exploit", "exploit", "ddos", "firewall"],
		"loot": {"cash": [60, 120], "xp": 35, "rep": 2},
		"flee": true, "tier": 1,
		"intro": "A wiry runner steps from a doorway, deck already humming.",
		"taunts": ["wrong corner, friend.", "pay the toll.", "nothing personal."]},
	"tracker_unit": {
		"name": "Trace Unit", "integrity": 42, "attack": 7, "defense": 6, "crit": 0.05,
		"moveset": ["exploit", "trace_lock", "exploit", "firewall"],
		"loot": {"cash": [0, 0], "xp": 45, "rep": 0, "heat_clear": true},
		"flee": false, "tier": 2,
		"intro": "The trace resolves into a corp enforcer. No more running.",
		"taunts": ["located.", "hold still.", "resistance logged."]},
	"byte_bully": {
		"name": "Byte Bully", "integrity": 38, "attack": 7, "defense": 4, "crit": 0.06,
		"moveset": ["exploit", "exploit", "ddos", "firewall"],
		"loot": {"cash": [95, 150], "xp": 55, "rep": 2, "gear": "rig_sidewalk_slicer"},
		"flee": false, "tier": 1, "crew": "r10t", "district": "plaza",
		"intro": "R10T's Plaza bruiser blocks your path, running a dirty sidewalk rig.",
		"taunts": ["R10T said you still click tutorials.", "This block pays tribute.", "Drop your deck and walk."]},
	"packet_jackal": {
		"name": "Packet Jackal", "integrity": 50, "attack": 10, "defense": 6, "crit": 0.08,
		"moveset": ["exploit", "ddos", "trace_lock", "exploit", "firewall"],
		"loot": {"cash": [180, 280], "xp": 75, "rep": 3, "gear": "rig_kiosk_needle"},
		"flee": false, "tier": 2, "crew": "r10t", "district": "market",
		"intro": "Packet Jackal paces between stalls, selling fear with a sharpened kiosk rig.",
		"taunts": ["Market tax. Pay in packets.", "Your signal smells cheap.", "R10T already owns your route."]},
	"tunnel_warden": {
		"name": "Tunnel Warden", "integrity": 64, "attack": 13, "defense": 8, "crit": 0.10,
		"moveset": ["trace_lock", "exploit", "ddos", "firewall", "exploit"],
		"loot": {"cash": [300, 460], "xp": 95, "rep": 4, "gear": "rig_tunnel_splice"},
		"flee": false, "tier": 3, "crew": "r10t", "district": "underpass",
		"intro": "Tunnel Warden steps out of the dark, every relay in the Underpass bending toward them.",
		"taunts": ["The Underpass echoes when you miss.", "R10T said break your knees first.", "No exits down here."]},
	"ice_barron": {
		"name": "ICE Barron", "integrity": 78, "attack": 16, "defense": 11, "crit": 0.12,
		"moveset": ["firewall", "exploit", "ddos", "trace_lock", "exploit"],
		"loot": {"cash": [520, 760], "xp": 120, "rep": 5, "gear": "rig_corpbreaker"},
		"flee": false, "tier": 4, "crew": "r10t", "district": "corp_row",
		"intro": "ICE Barron descends from a Corp Row lobby like a hostile audit.",
		"taunts": ["You are not enterprise-ready.", "R10T gave me your threat model.", "Your rig voids the warranty."]},
	"ghost_admin": {
		"name": "Ghost Admin", "integrity": 94, "attack": 19, "defense": 14, "crit": 0.15,
		"moveset": ["trace_lock", "exploit", "ddos", "firewall", "ddos"],
		"loot": {"cash": [780, 1100], "xp": 150, "rep": 6, "gear": "rig_ghostroot"},
		"flee": false, "tier": 5, "crew": "r10t", "district": "darknet",
		"intro": "Ghost Admin appears in the Darknet Cafe feed before their body reaches the door.",
		"taunts": ["I moderated your whole career.", "Root denied.", "R10T is waiting past your ceiling."]},
	"deep_marrow": {
		"name": "Deep Marrow", "integrity": 112, "attack": 22, "defense": 16, "crit": 0.16,
		"moveset": ["trace_lock", "ddos", "exploit", "firewall", "ddos"],
		"loot": {"cash": [1000, 1400], "xp": 180, "rep": 7, "gear": "rig_trunkneedle"},
		"flee": false, "tier": 6, "crew": "r10t", "district": "drowned_quarter",
		"intro": "Deep Marrow rises out of the Drowned Quarter fog, carrying R10T's trunk-side kit.",
		"taunts": ["The water remembers weak signals.", "R10T keeps you alive as a joke.", "No one jacks in clean."]},
	"r10t": {
		"name": "R10T", "integrity": 95, "attack": 14, "defense": 8, "crit": 0.14,
		"moveset": ["exploit", "exploit", "ddos", "firewall", "exploit"],
		"loot": {"cash": [300, 500], "xp": 120, "rep": 8, "gear": "rig_breaker", "item": "r10t_root_key"},
		"flee": false, "boss": true, "tier": 3,
		"intro": "R10T's avatar flickers in — your old rival, grinning.",
		"taunts": ["thought you were better than me?", "still running scripts?",
			"i taught you everything. badly."]},
}

# Status ranks earned by Reputation. Ordered low → high; your rank is the
# highest entry whose `rep` you've reached. Crossing a threshold is announced
# and pays a `reward` (cash / skill point / +max energy / +max cpu), and higher
# ranks unlock status-symbol gear, better jobs, and tougher targets.
const STATUS_RANKS := [
	{"title": "Script Kiddie", "rep": 0, "color": "9aa4b2", "reward": {}},
	{"title": "Pinger", "rep": 3, "color": "7ee787", "reward": {"cash": 40, "skill": 1}},
	{"title": "Operator", "rep": 8, "color": "7adfff", "reward": {"cash": 90, "energy": 2}},
	{"title": "Black Hat", "rep": 15, "color": "b277e0", "reward": {"cash": 180, "skill": 1}},
	{"title": "Shadow Broker", "rep": 25, "color": "ffd166", "reward": {"cash": 320, "cpu": 2}},
	{"title": "Ghost", "rep": 40, "color": "ff6b6b", "reward": {"cash": 550, "skill": 1, "energy": 2}},
	{"title": "Zero Day", "rep": 60, "color": "ff8cc6", "reward": {"cash": 850, "cpu": 2}},
	{"title": "Architect", "rep": 85, "color": "c9a0ff", "reward": {"cash": 1300, "skill": 1, "energy": 2}},
	{"title": "Legend", "rep": 120, "color": "ffe680", "reward": {"cash": 2200, "skill": 1, "cpu": 3, "energy": 3}},
]

# Wanted tiers driven by Heat. Above "Clean", hacks get harder (heat_penalty);
# at "Hunted" the riskiest jobs lock until you cool off.
const HEAT_TIERS := [
	{"name": "Clean", "max": 25, "color": "7ee787", "penalty": 0.0},
	{"name": "Flagged", "max": 50, "color": "ffd166", "penalty": 0.05},
	{"name": "Watched", "max": 75, "color": "ff9f43", "penalty": 0.12},
	{"name": "Hunted", "max": 101, "color": "ff6b6b", "penalty": 0.22},
]

# Cosmetics — bought once, then equippable. Purely visual: the player sprite
# (player.gd) recolors its outfit and draws the equipped hat. One item per
# "slot" is worn at a time. The price-0 defaults are owned from the start.
#   slot  : "outfit" (recolors body) or "hat" (drawn on the head)
#   color : hex used by the sprite
#   style : hat shape — "none" | "beanie" | "cap" | "crown"
const COSMETICS := {
	"hoodie_gray": {"name": "Gray Hoodie", "desc": "The classic. You started in this.", "slot": "outfit", "price": 0, "color": "3c4454"},
	"hoodie_red": {"name": "Red Hoodie", "desc": "A little louder.", "slot": "outfit", "price": 40, "color": "b3433a"},
	"jacket_neon": {"name": "Neon Windbreaker", "desc": "Visible from orbit.", "slot": "outfit", "price": 90, "color": "2bd4a8"},
	"track_gold": {"name": "Gold Tracksuit", "desc": "For when the botnet pays the bills.", "slot": "outfit", "price": 300, "color": "d4af37", "status_req": 2},
	"hat_none": {"name": "No Hat", "desc": "Bare head.", "slot": "hat", "price": 0, "color": "000000", "style": "none"},
	"hat_beanie": {"name": "Beanie", "desc": "Keeps the ideas warm.", "slot": "hat", "price": 30, "color": "5a5f6e", "style": "beanie"},
	"hat_cap": {"name": "Snapback", "desc": "Brim down, eyes up.", "slot": "hat", "price": 70, "color": "2f4a8a", "style": "cap"},
	"hat_crown": {"name": "Hacker Crown", "desc": "Self-appointed royalty of the subnet.", "slot": "hat", "price": 450, "color": "ffd166", "style": "crown", "status_req": 4},
}

const SKILLS := {
	"hardware": {"name": "Hardware", "desc": "+2 max CPU per rank.", "max": 3},
	"stealth": {"name": "Stealth", "desc": "-12% Heat gain per rank.", "max": 3},
	"hustle": {"name": "Hustle", "desc": "+15% cash from jobs, scrap and loot sales per rank.", "max": 3},
	"wardriving": {"name": "War Driving", "desc": "Sniff stronger WiFi and crack it easier. +10% odds, better finds per rank.", "max": 3},
}

# WiFi sniffing ("wild encounters"). Encryption tiers, hardest last. diff drives
# crack odds + CPU cost; payout/heat/data scale with it.
const WIFI_ENCRYPTION := [
	{"name": "Open", "diff": 0, "min": 5, "max": 15, "heat": 2, "data": 0.05, "color": "7ee787"},
	{"name": "WEP", "diff": 1, "min": 15, "max": 35, "heat": 4, "data": 0.10, "color": "7adfff"},
	{"name": "WPA", "diff": 2, "min": 40, "max": 80, "heat": 7, "data": 0.20, "color": "ffd166"},
	{"name": "WPA2", "diff": 3, "min": 90, "max": 170, "heat": 12, "data": 0.30, "color": "ff9f43"},
	{"name": "WPA3-Enterprise", "diff": 4, "min": 220, "max": 380, "heat": 20, "data": 0.45, "color": "ff6b6b"},
]

const WIFI_SSIDS := [
	"linksys", "NETGEAR47", "FBI_Surveillance_Van", "Pretty_Fly_4_WiFi",
	"xfinitywifi", "TellMyWiFiLoveHer", "Apt2B_5G", "DROP_BEAR_NET",
	"VirusFactory", "Mom_Click_Here", "TheLANBeforeTime", "Skynet_Guest",
	"Loading...", "HideYoKids_HideYoWiFi", "404_Network_Unfound", "Pretty_Paranoid",
]

# Rentable apartments. Each is a one-time purchase granting permanent perks;
# you "live" in the highest you own. status_req indexes STATUS_RANKS.
const APARTMENTS := {
	"apt_4b": {"name": "Apt 4B", "desc": "Your dump. Roaches included, rent overdue.", "price": 0, "status_req": 0, "max_energy": 0, "cool": 0, "income": 0},
	"studio_loft": {"name": "Studio Loft", "desc": "Actual windows. +2 max Energy, cools Heat a little faster.", "price": 900, "status_req": 2, "max_energy": 2, "cool": 2, "income": 0},
	"safehouse": {"name": "The Safehouse", "desc": "Off the grid. +3 max Energy, +4 Heat cooldown, $10/day.", "price": 3000, "status_req": 3, "max_energy": 3, "cool": 4, "income": 10},
	"penthouse": {"name": "Sky Penthouse", "desc": "You made it. +5 max Energy, +6 Heat cooldown, $45/day.", "price": 9000, "status_req": 6, "max_energy": 5, "cool": 6, "income": 45},
}

# Apartments v2 (G/LAST) — furniture you buy for your place, the cosmetic money
# sink. `category` is "functional" (carries an `effect`) or "cosmetic" (pure
# `style`). Every piece adds to your Style score, which pays a small daily REP
# trickle. Effects stack on top of the apartment-tier perks: max_energy is
# applied once at purchase (like moving), cool/income are summed live. Visual
# placement lives in home_3d.FURNITURE_VISUALS.
const FURNITURE := {
	# --- functional ---
	"smart_bed": {"name": "Memory-Foam Bed", "desc": "Sleep like the rich. +3 max Energy.",
		"price": 450, "status_req": 0, "category": "functional", "style": 6, "effect": {"max_energy": 3}},
	"espresso": {"name": "Espresso Machine", "desc": "Wake up wired. +2 max Energy.",
		"price": 600, "status_req": 0, "category": "functional", "style": 7, "effect": {"max_energy": 2}},
	"vpn_rack": {"name": "VPN Rack", "desc": "Bounce your traffic. +4 Heat cooldown/day.",
		"price": 1100, "status_req": 2, "category": "functional", "style": 5, "effect": {"cool": 4}},
	"server_closet": {"name": "Server Closet", "desc": "Rent out spare compute. +$20/day.",
		"price": 1600, "status_req": 2, "category": "functional", "style": 8, "effect": {"income": 20}},
	# --- cosmetic (pure Style) ---
	"potted_palm": {"name": "Potted Palm", "desc": "A small living thing. It's a start.",
		"price": 90, "status_req": 0, "category": "cosmetic", "style": 5, "effect": {}},
	"band_posters": {"name": "Band Posters", "desc": "Cover the water stains.",
		"price": 140, "status_req": 0, "category": "cosmetic", "style": 7, "effect": {}},
	"shag_rug": {"name": "Shag Rug", "desc": "Ties the room together.",
		"price": 280, "status_req": 0, "category": "cosmetic", "style": 9, "effect": {}},
	"neon_sign": {"name": "Neon Wall Sign", "desc": "Your handle in glowing tubes.",
		"price": 650, "status_req": 1, "category": "cosmetic", "style": 14, "effect": {}},
	"jelly_tank": {"name": "Jellyfish Tank", "desc": "Hypnotic. Low maintenance. Pricey.",
		"price": 1800, "status_req": 3, "category": "cosmetic", "style": 18, "effect": {}},
	"arcade_cab": {"name": "Arcade Cabinet", "desc": "A whole machine, just to flex.",
		"price": 2600, "status_req": 4, "category": "cosmetic", "style": 22, "effect": {}},
}

# Sequential main quest line. cond/value checked in GameState._check_quests.
const QUESTS := [
	{"text": "Scrape together $100 (alley trash + job board)", "cond": "cash", "value": 100, "xp": 20, "cash": 0},
	{"text": "Buy the used laptop at the PAWN SHOP", "cond": "computer", "value": 1, "xp": 30, "cash": 0},
	{"text": "Pwn your first target from your desk", "cond": "hacks", "value": 1, "xp": 25, "cash": 25},
	{"text": "Install your first bot (install_bot)", "cond": "botnet", "value": 1, "xp": 30, "cash": 0},
	{"text": "Grow your botnet to 5", "cond": "botnet", "value": 5, "xp": 50, "cash": 100},
	{"text": "Reach Operator status", "cond": "status", "value": 2, "xp": 75, "cash": 0},
	{"text": "Pwn MegaCorp's mail relay", "cond": "target", "value": "corp_mail_relay", "xp": 150, "cash": 500},
	{"text": "Make Black Hat status", "cond": "status", "value": 3, "xp": 120, "cash": 0},
	{"text": "Crack the bank core", "cond": "target", "value": "bank_core", "xp": 250, "cash": 1000},
	{"text": "Grow your botnet to 25", "cond": "botnet", "value": 25, "xp": 300, "cash": 500},
	{"text": "Pwn the AI datacenter", "cond": "target", "value": "ai_datacenter", "xp": 600, "cash": 4000},
	{"text": "Become a Legend", "cond": "status", "value": 8, "xp": 1000, "cash": 5000},
]

# Gigs on the job boards. Each is a risk/reward bet, not a free payout:
# `heat` is added on success, and `risk` (0..1) is the chance the gig goes
# sideways — partial pay + a heat spike. Higher reward = more heat + more
# risk. Stealth skill lowers effective risk. The board shows a randomized
# daily subset (GameState.daily_gigs) with at least one status-gated gig.
# status_req indexes STATUS_RANKS; `board` is "plaza" (default) or "corp".
# Equipment with combat/hacking stats (G4). Three functional slots beyond the
# cosmetic outfit/hat: RIG (cyber_attack — offense + nudges hack odds),
# FIREWALL (defense), IMPLANT (integrity = combat HP + crit). Bought at the
# pawn shop; derived totals live in GameState (total_cyber_attack, etc.) and
# feed both hacking odds now and turn-based combat later (G6).
const GEAR_SLOTS := ["rig", "firewall", "implant"]
const GEAR := {
	"rig_script": {"name": "Script Deck", "slot": "rig", "cyber": 3, "price": 120,
		"desc": "A starter deck. Better than your bare hands."},
	"rig_breaker": {"name": "Breaker Rig", "slot": "rig", "cyber": 7, "price": 600, "status_req": 2,
		"desc": "Purpose-built for cracking. It hums."},
	"rig_zeroday": {"name": "Zero-Day Cannon", "slot": "rig", "cyber": 14, "price": 2500, "status_req": 4,
		"desc": "Point it at anything. Anything breaks."},
	"rig_sidewalk_slicer": {"name": "Sidewalk Slicer", "slot": "rig", "cyber": 6, "price": 0, "crew_drop": true,
		"desc": "Byte Bully's stripped street rig. It bites into Market-tier nodes."},
	"rig_kiosk_needle": {"name": "Kiosk Needle", "slot": "rig", "cyber": 9, "price": 0, "crew_drop": true,
		"desc": "Packet Jackal's precise skimmer rig. It makes Underpass targets much less stubborn."},
	"rig_tunnel_splice": {"name": "Tunnel Splice", "slot": "rig", "cyber": 12, "price": 0, "crew_drop": true,
		"desc": "Tunnel Warden's relay splice. Corp Row mailrooms hate this thing."},
	"rig_corpbreaker": {"name": "Corpbreaker", "slot": "rig", "cyber": 16, "price": 0, "crew_drop": true,
		"desc": "ICE Barron's audited intrusion rig. Built to pry open Darknet-tier infrastructure."},
	"rig_ghostroot": {"name": "Ghostroot Rig", "slot": "rig", "cyber": 19, "price": 0, "crew_drop": true,
		"desc": "Ghost Admin's root kit deck. It gives you a real shot at Drowned Quarter targets."},
	"rig_trunkneedle": {"name": "Trunkneedle", "slot": "rig", "cyber": 21, "price": 0, "crew_drop": true,
		"desc": "Deep Marrow's trunk-side rig. It is tuned for the last door, not the shop window."},
	"fw_foam": {"name": "Foam Firewall", "slot": "firewall", "defense": 3, "price": 100,
		"desc": "Cheap, but it'll soak a hit."},
	"fw_ice": {"name": "Hardened ICE", "slot": "firewall", "defense": 7, "price": 550, "status_req": 2,
		"desc": "Intrusion Countermeasures. The good kind."},
	"fw_black": {"name": "Black ICE Wall", "slot": "firewall", "defense": 13, "price": 2200, "status_req": 4,
		"desc": "Hits back. Don't touch it. You can, though."},
	"imp_reflex": {"name": "Reflex Booster", "slot": "implant", "integrity": 10, "crit": 0.05, "price": 150,
		"desc": "Wetware tune-up. +10 integrity, +5% crit."},
	"imp_neural": {"name": "Neural Co-Proc", "slot": "implant", "integrity": 20, "crit": 0.10, "price": 700, "status_req": 3,
		"desc": "A second brain for the hard parts."},
	"imp_ghost": {"name": "Ghost Implant", "slot": "implant", "integrity": 35, "crit": 0.15, "price": 2600, "status_req": 5,
		"desc": "You're barely on the grid anymore."},
}

# Field gigs: accept up to two (GameState.active_jobs), then travel to the
# `district` where a glowing marker spawns and DO the work (energy + the
# risk/reward bet resolve there, not at the board). `archetype` flavors the
# marker and the action prompt (see district_3d.JOB_ARCHETYPES):
#   wifi  — crack a node for a client      drop  — grab/deliver a package
#   meet  — meet a shady contact           heist — lift corporate data (advanced)
const JOBS := {
	"fix_router": {
		"name": "Fix a neighbor's router",
		"desc": "Reboot it, blow on the ports, look professional.",
		"archetype": "wifi", "district": "plaza",
		"energy": 2, "cash": 20, "rep_chance": 0.25, "req_computer": false,
		"heat": 0, "risk": 0.0,
	},
	"ewaste_run": {
		"name": "E-waste recycling run",
		"desc": "Haul dead monitors to the Market depot. Honest, sweaty money.",
		"archetype": "drop", "district": "market",
		"energy": 3, "cash": 35, "rep_chance": 0.1, "req_computer": false,
		"heat": 0, "risk": 0.0,
	},
	"neighbor_wifi": {
		"name": "Crack a client's WiFi",
		"desc": "A Market tenant locked themselves out. Get them back in.",
		"archetype": "wifi", "district": "market",
		"energy": 2, "cash": 55, "rep_chance": 0.2, "req_computer": true,
		"heat": 2, "risk": 0.08,
	},
	"wipe_drives": {
		"name": "Wipe drives for the pawn shop",
		"desc": "Meet the broker at the Market. No questions, none answered.",
		"archetype": "meet", "district": "market",
		"energy": 2, "cash": 30, "rep_chance": 0.2, "req_computer": true,
		"heat": 3, "risk": 0.10,
	},
	"courier": {
		"name": "Run a package, no peeking",
		"desc": "Pick up a drop in the Underpass, don't get curious.",
		"archetype": "drop", "district": "underpass",
		"energy": 2, "cash": 45, "rep_chance": 0.25, "req_computer": false,
		"heat": 4, "risk": 0.12,
	},
	"data_broker": {
		"name": "Move scraped records",
		"desc": "Meet a broker under the expressway. They pay for 'legal' data.",
		"archetype": "meet", "district": "underpass",
		"energy": 3, "cash": 90, "rep_chance": 0.35, "req_computer": true, "status_req": 2,
		"heat": 6, "risk": 0.15,
	},
	"fixer_job": {
		"name": "A job for the fixer",
		"desc": "A discreet meet in the Underpass. Reputation opens this door.",
		"archetype": "meet", "district": "underpass",
		"energy": 4, "cash": 180, "rep_chance": 0.5, "req_computer": true, "status_req": 3,
		"heat": 10, "risk": 0.20,
	},
	# --- Corp Row gigs (board: "corp") — serious money for serious status. ---
	"pentest": {
		"name": "Sanctioned pentest",
		"desc": "Break into a firm's server on Corp Row. 'Legally.' Wink.",
		"archetype": "heist", "district": "corp_row",
		"energy": 4, "cash": 400, "rep_chance": 0.6, "req_computer": true, "status_req": 3, "board": "corp",
		"heat": 12, "risk": 0.20,
	},
	"corp_sabotage": {
		"name": "Corporate sabotage",
		"desc": "Lift a rival's quarterly off a Corp Row node. Untraceable.",
		"archetype": "heist", "district": "corp_row",
		"energy": 5, "cash": 750, "rep_chance": 0.7, "req_computer": true, "status_req": 4, "board": "corp",
		"heat": 20, "risk": 0.30,
	},
	"insider_feed": {
		"name": "Feed the insiders",
		"desc": "Drop a board's secrets to a Darknet contact who trades on them.",
		"archetype": "heist", "district": "darknet",
		"energy": 5, "cash": 1300, "rep_chance": 0.8, "req_computer": true, "status_req": 6, "board": "corp",
		"heat": 30, "risk": 0.35,
	},
}

# Darknet contracts — bounties on the endgame targets. Accept one (you can hold
# one at a time); pwning its target while active pays the bonus on top.
const CONTRACTS := {
	"bounty_corp": {"name": "Burn the relay", "target": "corp_mail_relay", "desc": "A client wants MegaCorp's mail relay gutted.", "cash": 800, "rep": 3, "xp": 100, "status_req": 3},
	"bounty_bank": {"name": "Empty the vault", "target": "bank_core", "desc": "Crack the bank core. No questions, big numbers.", "cash": 2500, "rep": 5, "xp": 250, "status_req": 4},
	"bounty_sat": {"name": "Own the sky", "target": "satellite_uplink", "desc": "Hijack the orbital relay for a silent backer.", "cash": 4000, "rep": 8, "xp": 350, "status_req": 5},
	"bounty_ai": {"name": "Kill the machine", "target": "ai_datacenter", "desc": "Pwn the AI cluster. The whole grid is watching.", "cash": 9000, "rep": 15, "xp": 600, "status_req": 6},
}
