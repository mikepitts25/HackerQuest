extends RefCounted
## Authored local work. Positions are dry, accessible city locations, not random stops.

static func sources() -> Dictionary:
	return {
		"plaza_board": {"name": "Community dispatch", "district": "plaza", "pos": [24,12], "category": "Neighborhood errands", "tier": 0},
		"plaza_coffee": {"name": "Wired Coffee dispatch", "district": "plaza", "pos": [43,35], "category": "Deliveries & repairs", "tier": 0},
		"plaza_repair": {"name": "Patch repair kiosk", "district": "plaza", "pos": [50,22], "category": "Repairs, signals & starter stock", "tier": 0},
		"market_pawn": {"name": "Pawn service desk", "district": "market", "pos": [18,15], "category": "Drive services", "tier": 1},
		"market_salvage": {"name": "Sparks salvage dispatch", "district": "market", "pos": [43,25], "category": "Parts & recovery", "tier": 1},
		"market_vex": {"name": "Vex's drop terminal", "district": "market", "pos": [52,9], "category": "Discreet deliveries", "tier": 1},
		"underpass_ozark": {"name": "Ozark work station", "district": "underpass", "pos": [36,20], "category": "Salvage orders", "tier": 2},
		"underpass_courier": {"name": "Night courier drop", "district": "underpass", "pos": [17,27], "category": "Package runs", "tier": 2},
		"underpass_utility": {"name": "Tunnel utility console", "district": "underpass", "pos": [27,9], "category": "Signal & repair", "tier": 2},
		"corp_board": {"name": "AXIOM contractor terminal", "district": "corp_row", "pos": [12,24], "category": "Sanctioned diagnostics", "tier": 3},
		"corp_contact": {"name": "Atrium contact", "district": "corp_row", "pos": [25,27], "category": "Courier & security", "tier": 3},
		"corp_service": {"name": "Service lane console", "district": "corp_row", "pos": [53,39], "category": "Covert data work", "tier": 3},
		"darknet_counter": {"name": "Cafe counter dispatch", "district": "darknet", "pos": [19,28], "category": "Patron errands", "tier": 4},
		"darknet_rig": {"name": "Rig-hall service terminal", "district": "darknet", "pos": [46,29], "category": "Diagnostics & decryption", "tier": 4},
		"darknet_broker": {"name": "Alley broker", "district": "darknet", "pos": [28,37], "category": "Retrieval contracts", "tier": 4},
		"drowned_fathom": {"name": "Fathom recovery station", "district": "drowned_quarter", "pos": [26,19], "category": "Recovery orders", "tier": 5},
		"drowned_relay": {"name": "Spine relay terminal", "district": "drowned_quarter", "pos": [30,13], "category": "Relay restoration", "tier": 5},
		"drowned_drop": {"name": "Deep salvage dead drop", "district": "drowned_quarter", "pos": [36,19], "category": "Dangerous retrievals", "tier": 5},
	}

# Entries: source, title, kind, route points, objective text. No travel padding.
static func templates() -> Dictionary:
	var rows := [
		["plaza_board", "Deliver a neighbor's charger", "errand", [[28,20]], "Leave the charger at the bench"],
		["plaza_board", "Restock the community stand", "errand", [[32,14]], "Drop off the notice supplies"],
		["plaza_coffee", "Coffee for the night crew", "errand", [[41,31],[34,28]], "Deliver the insulated coffee bag"],
		["plaza_coffee", "Repair the order tablet", "repair", [[44,33]], "Diagnose the order tablet"],
		["plaza_repair", "Reconnect a neighbor's router", "signal", [[48,24]], "Reconnect the local relay"],
		["plaza_repair", "Restore the community hotspot", "contract", [[50,26],[46,26],[42,26]], "Restore the hotspot service"],
		["market_pawn", "Wipe the returned drives", "decrypt", [[21,15]], "Unlock and wipe the returned drives"],
		["market_pawn", "Deliver a repaired handheld", "errand", [[27,20]], "Deliver the serviced handheld"],
		["market_salvage", "Collect a boxed parts order", "errand", [[45,28],[38,26]], "Move the boxed replacement parts"],
		["market_salvage", "Rebuild the yard scanner", "repair", [[42,28],[36,28]], "Repair the salvage scanner"],
		["market_vex", "A sealed parcel for Vex", "errand", [[49,12],[54,13]], "Move the sealed parcel"],
		["market_vex", "Recover a broker's archive", "contract", [[51,15],[47,18],[42,17]], "Recover the broker's archive"],
		["underpass_ozark", "Sort Ozark's cable order", "errand", [[33,23]], "Deliver the sorted cable bundle"],
		["underpass_ozark", "Revive a salvaged controller", "repair", [[29,23]], "Diagnose the salvaged controller"],
		["underpass_courier", "Medicine for the tunnel camp", "errand", [[19,25],[25,27]], "Deliver the sealed medical pack"],
		["underpass_courier", "Recover the courier manifest", "contract", [[21,28],[25,25],[29,27]], "Recover the missing manifest"],
		["underpass_utility", "Find the broken relay", "signal", [[29,10]], "Trace the utility relay"],
		["underpass_utility", "Decode the maintenance log", "decrypt", [[31,9]], "Decode the maintenance log"],
		["corp_board", "Repair an access badge reader", "repair", [[15,25]], "Repair the contractor badge reader"],
		["corp_board", "Deliver the audit kit", "errand", [[18,23],[25,23]], "Deliver the signed audit kit"],
		["corp_contact", "A coffee bag for security", "errand", [[28,27],[32,25]], "Deliver the security team's order"],
		["corp_contact", "Audit the visitor network", "signal", [[29,29]], "Trace the visitor network"],
		["corp_service", "Decrypt the service backups", "decrypt", [[50,38]], "Unlock the service backup"],
		["corp_service", "Extract a guarded data case", "combat", [[48,39],[44,38],[40,39]], "Retrieve the guarded data case"],
		["darknet_counter", "Deliver a patron's replacement deck", "errand", [[22,28]], "Deliver the replacement deck"],
		["darknet_counter", "Repair the booth hub", "repair", [[25,28]], "Repair the booth network hub"],
		["darknet_rig", "Trace rig-hall packet loss", "signal", [[48,30]], "Trace the rig-hall signal"],
		["darknet_rig", "Decrypt a locked diagnostics dump", "decrypt", [[49,33]], "Unlock the diagnostics dump"],
		["darknet_broker", "Move the sealed escrow token", "errand", [[26,37],[30,37]], "Move the escrow token"],
		["darknet_broker", "Retrieve a runner's hot archive", "combat", [[24,37],[20,37],[16,37]], "Retrieve the runner's archive"],
		["drowned_fathom", "Deliver dry storage cells", "errand", [[28,18]], "Deliver the dry storage cells"],
		["drowned_fathom", "Repair a recovered data buoy", "repair", [[29,19]], "Repair the recovered buoy"],
		["drowned_relay", "Restore the spine relay", "signal", [[29,14]], "Restore the spine signal"],
		["drowned_relay", "Decrypt a flooded archive", "decrypt", [[32,14]], "Decrypt the recovered archive"],
		["drowned_drop", "Carry a recovered black box", "errand", [[35,18],[31,18]], "Deliver the recovered black box"],
		["drowned_drop", "Recover the guarded root backup", "combat", [[33,19],[30,18],[27,17]], "Recover the guarded root backup"],
	]
	var result := {}
	var per_source := {}
	for row in rows:
		var source: String = row[0]
		var n: int = per_source.get(source, 0)
		per_source[source] = n + 1
		var tier: int = sources()[source].tier
		var kind: String = row[2]
		var technical := kind in ["repair", "signal", "decrypt", "contract"]
		var long_job := kind in ["contract", "combat"]
		var pays := [48,70,115,240,500,850]
		var pay := int(pays[tier])
		if technical: pay = int(round(pay * 1.4))
		if long_job: pay = int(round(pay * 2.4))
		var stages := []
		for i in row[3].size():
			var last: bool = i == row[3].size() - 1
			stages.append({"pos": row[3][i], "district": sources()[source].district,
				"kind": ("decrypt" if kind == "contract" else kind) if last else "errand",
				"objective": row[4] if last else "Collect the next job package",
				"energy": 2 if last and technical else 1,
				"cpu": (mini(tier + 1, 3) if technical and tier > 0 and last else 0)})
		result[source + "_%d" % n] = {"source": source, "name": row[1], "kind": kind,
			"stages": stages, "cash": pay, "xp": 8 + tier * 4 + (8 if long_job else 0),
			"rep": 1 if long_job else 0, "computer": technical and tier > 0,
			"heat": tier * 2 if (long_job or source.ends_with("vex") or (kind=="decrypt" and tier>=3)) else 0,
			"enemy": ("contract_sentry" if tier == 3 else ("contract_ice" if tier == 4 else "contract_guardian")) if kind == "combat" else ""}
	return result

static func challenge(kind: String, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var puzzle := {"kind": kind, "progress": 0, "attempts": 0, "hints_used": 0, "feedback": "", "labels": [], "answer": [], "rule": "", "clue": ""}
	if kind == "repair":
		var labels := ["Power: OK", "Cooler: FAILED", "Port: OK", "Memory: FAILED"]
		for i in range(3, 0, -1):
			var j := rng.randi_range(0, i)
			var temp: String = labels[i]
			labels[i] = labels[j]
			labels[j] = temp
		puzzle.labels = labels
		var answer := []
		for i in labels.size():
			if "FAILED" in labels[i]: answer.append(i)
		puzzle.answer = answer
		puzzle.rule = "Replace each FAILED component, from top to bottom. Leave the OK components alone."
		puzzle.clue = "The diagnostics already identify the failed components."
	elif kind == "signal":
		var a := rng.randi_range(2, 5)
		puzzle.labels = ["Relay %d" % a, "Relay %d" % (a+2), "Relay %d" % (a+1), "Relay %d" % (a+3)]
		puzzle.answer = [0,2,1]
		puzzle.rule = "Connect three relays in order: %d → %d → %d. Each tap adds the next link." % [a,a+1,a+2]
		puzzle.clue = "Follow the requested numbers in ascending order; the fourth relay is unused."
	else:
		var symbols := ["MOON", "KEY", "WAVE", "EYE"]
		var start := rng.randi_range(0, 3)
		puzzle.labels = symbols
		puzzle.answer = [start, (start+2)%4, (start+1)%4]
		puzzle.rule = "Archive key: %s → %s → %s. Enter the three symbols in that order." % [symbols[start], symbols[(start+2)%4], symbols[(start+1)%4]]
		puzzle.clue = "Read the archive key from left to right; repeat it using the symbol buttons."
	return puzzle
