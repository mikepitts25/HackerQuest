extends RefCounted
## Headless turn-based combat core (G6). Pure logic — no GameState or UI deps —
## so it runs in the smoke test. Construct, call init(player_stats, enemy_id),
## then drive it with the player_* methods. Each player action resolves and then
## (unless the fight ended or you fled) the enemy takes its turn. Read `log` for
## narration and `outcome` for the result. Referenced by path (no class_name,
## per the repo's stale-cache gotcha).
##
## Combat math:
##   EXPLOIT  dmg = max(1, atk - def/2) * randf(0.85,1.15); x2 on crit; halved
##            if the target is guarding (used its FIREWALL last turn).
##   FIREWALL one-turn guard (halves the next incoming hit) + regen ~10% max.
##   PROGRAM  applies a combat item's effect (damage / heal / flee_bonus).
##   JACK OUT flee, chance = clamp(0.4 + stealth*0.1 + bonus - lock, .05, .95).
## Enemy-only moves: ddos (1.4x hit), trace_lock (0.5x hit + harder to flee).

const ONGOING := "ongoing"
const WIN := "win"
const LOSE := "lose"
const FLED := "fled"

var enemy_id := ""
var enemy: Dictionary = {}

var player_max := 20
var enemy_max := 10
var player_hp := 20
var enemy_hp := 10
var atk := 0
var def := 0
var crit := 0.0
var stealth := 0

var outcome := ONGOING
var turn := 0
var log: Array[String] = []

var _player_guard := false   # player used FIREWALL last turn → next enemy hit halved
var _enemy_guard := false    # enemy used FIREWALL → next player EXPLOIT halved
var _flee_penalty := 0.0     # trace_lock makes the next JACK OUT harder
var _flee_bonus := 0.0       # proxy_smoke etc. make the next JACK OUT easier
var rng := RandomNumberGenerator.new()


func init(player_stats: Dictionary, p_enemy_id: String, seed_val := -1) -> void:
	enemy_id = p_enemy_id
	enemy = GameData.ENEMIES[p_enemy_id].duplicate(true)
	atk = int(player_stats.get("attack", 0))
	def = int(player_stats.get("defense", 0))
	crit = float(player_stats.get("crit", 0.0))
	stealth = int(player_stats.get("stealth", 0))
	if enemy_id == "r10t" and not bool(player_stats.get("endgame_loadout", false)):
		_empower_r10t()
	player_max = maxi(1, int(player_stats.get("integrity", 20)))
	player_hp = player_max
	enemy_max = maxi(1, int(enemy.get("integrity", 10)))
	enemy_hp = enemy_max
	if seed_val >= 0:
		rng.seed = seed_val
	else:
		rng.randomize()
	_log("> %s" % enemy.get("intro", "%s blocks your path." % enemy.name))


func _empower_r10t() -> void:
	enemy["integrity"] = 220
	enemy["attack"] = 30
	enemy["defense"] = 24
	enemy["crit"] = 0.24
	enemy["intro"] = "R10T's avatar floods the channel, massively overclocked and already laughing."
	enemy["taunts"] = [
		"Come back when you own real gear.",
		"I could let the crew handle this, but watching you crash is fun.",
		"That deck is thrift-store noise.",
		"You haven't even bought the kit needed to stand here.",
	]


# --- player actions -----------------------------------------------------------

func player_exploit() -> void:
	if outcome != ONGOING:
		return
	_flee_penalty = 0.0  # acting shakes a trace lock
	var hit := _resolve_hit(atk, int(enemy.get("defense", 0)), crit, _enemy_guard)
	_enemy_guard = false
	enemy_hp = maxi(0, enemy_hp - hit.amount)
	_log("> you EXPLOIT for %d%s." % [hit.amount, "  ✦CRIT" if hit.crit else ""])
	_after_player_action()


func player_firewall() -> void:
	if outcome != ONGOING:
		return
	_flee_penalty = 0.0
	_player_guard = true
	var regen := int(round(player_max * 0.1))
	player_hp = mini(player_max, player_hp + regen)
	_log("> you raise a FIREWALL (+%d integrity, next hit softened)." % regen)
	_after_player_action()


# `combat` is an item's combat block: {damage?, heal?, flee_bonus?}. The caller
# (combat UI) looks up the owned item and decrements inventory; the session just
# applies the effect, keeping this object free of GameState.
func player_program(combat: Dictionary, item_name := "a program") -> void:
	if outcome != ONGOING:
		return
	_flee_penalty = 0.0
	var dmg := int(combat.get("damage", 0))
	var heal := int(combat.get("heal", 0))
	var fb := float(combat.get("flee_bonus", 0.0))
	if dmg > 0:
		enemy_hp = maxi(0, enemy_hp - dmg)
		_log("> you run %s — %d damage, straight through the ICE." % [item_name, dmg])
	if heal > 0:
		player_hp = mini(player_max, player_hp + heal)
		_log("> you run %s — +%d integrity." % [item_name, heal])
	if fb > 0.0:
		_flee_bonus = fb
		_log("> you run %s — escape routes open." % item_name)
	_after_player_action()


func player_jack_out() -> void:
	if outcome != ONGOING:
		return
	if not enemy.get("flee", true):
		_log("> JACK OUT failed — %s has you locked in." % enemy.name)
		_flee_bonus = 0.0
		_enemy_turn()
		return
	var chance := clampf(0.4 + stealth * 0.1 + _flee_bonus - _flee_penalty, 0.05, 0.95)
	_flee_bonus = 0.0
	if rng.randf() < chance:
		outcome = FLED
		_log("> you JACK OUT — gone before the trace completes.")
		return
	_log("> JACK OUT failed!")
	_enemy_turn()


# Items the player can run as a PROGRAM this fight: owned consumables that carry
# a combat block. Returns [{id, name, combat}], for the UI to render.
static func available_programs(inventory: Dictionary) -> Array:
	var out: Array = []
	for id in inventory:
		if inventory[id] <= 0:
			continue
		var c: Dictionary = GameData.CONSUMABLES.get(id, {})
		if c.has("combat"):
			out.append({"id": id, "name": c.name, "combat": c.combat})
	return out


# --- enemy turn ---------------------------------------------------------------

func _after_player_action() -> void:
	if enemy_hp <= 0:
		outcome = WIN
		_log("> %s flatlines. you win." % enemy.name)
		return
	_enemy_turn()


func _enemy_turn() -> void:
	if outcome != ONGOING:
		return
	turn += 1
	var taunts: Array = enemy.get("taunts", [])
	if not taunts.is_empty() and rng.randf() < 0.25:
		_log("> %s: \"%s\"" % [enemy.name, taunts[rng.randi() % taunts.size()]])
	var moves: Array = enemy.get("moveset", ["exploit"])
	match String(moves[rng.randi() % moves.size()]):
		"firewall":
			_enemy_guard = true
			var regen := int(round(enemy_max * 0.08))
			enemy_hp = mini(enemy_max, enemy_hp + regen)
			_log("> %s hardens its ICE (+%d)." % [enemy.name, regen])
		"ddos":
			var h := _resolve_hit(int(enemy.get("attack", 0) * 1.4), def, float(enemy.get("crit", 0.0)), _player_guard)
			_player_guard = false
			player_hp = maxi(0, player_hp - h.amount)
			_log("> %s floods you with a DDOS — %d%s." % [enemy.name, h.amount, "  ✦CRIT" if h.crit else ""])
		"trace_lock":
			var h2 := _resolve_hit(int(enemy.get("attack", 0) * 0.5), def, 0.0, _player_guard)
			_player_guard = false
			player_hp = maxi(0, player_hp - h2.amount)
			_flee_penalty = 0.4
			_log("> %s locks your exit — %d damage, escape harder." % [enemy.name, h2.amount])
		_:
			var h3 := _resolve_hit(int(enemy.get("attack", 0)), def, float(enemy.get("crit", 0.0)), _player_guard)
			_player_guard = false
			player_hp = maxi(0, player_hp - h3.amount)
			_log("> %s exploits you — %d%s." % [enemy.name, h3.amount, "  ✦CRIT" if h3.crit else ""])
	if player_hp <= 0:
		outcome = LOSE
		_log("> your deck flatlines. you lose.")


# --- shared math --------------------------------------------------------------

func _resolve_hit(a: int, d: int, c: float, target_guarding: bool) -> Dictionary:
	var amt := maxf(1.0, a - d / 2.0) * rng.randf_range(0.85, 1.15)
	var is_crit := rng.randf() < c
	if is_crit:
		amt *= 2.0
	if target_guarding:
		amt *= 0.5
	return {"amount": maxi(1, int(round(amt))), "crit": is_crit}


func _log(line: String) -> void:
	log.append(line)
