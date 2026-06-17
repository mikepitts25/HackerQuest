class_name Inbox
## The burner phone — messages from your contacts, generated from live
## GameState. Tips, nudges, and the occasional lead, addressed to you (unlike
## the CITY WIRE, which talks ABOUT you). Used by the HUD PHONE modal.


# Returns [{from, color, text}] — newest-feeling first.
static func messages() -> Array:
	var out: Array = []

	# Pix mentors early, hypes you late.
	if not GameState.has_computer:
		out.append(_m("Pix", "7ee787", "scrap up $100 and grab that laptop. you can't hack on vibes."))
	elif GameState.botnet_size == 0:
		out.append(_m("Pix", "7ee787", "got the rig? sit at the desk: scan, inspect, exploit. then install_bot."))
	else:
		out.append(_m("Pix", "7ee787", "%d bots and climbing. you're somebody now." % GameState.botnet_size))

	# Glitch sells warnings.
	if GameState.heat >= 80:
		out.append(_m("Glitch", "e0894a", "they're SWEEPING. go dark. do NOT hit anything tonight."))
	elif GameState.heat_penalty() > 0.0:
		out.append(_m("Glitch", "e0894a", "heat's up. patrols out. sleep it off before the big jobs."))
	else:
		out.append(_m("Glitch", "e0894a", "you're cold right now. good window for a fat target."))

	# Vex wants product when you're holding.
	var data: int = GameState.inventory.get("stolen_data", 0)
	if data > 0:
		out.append(_m("Vex", "c060c0", "heard you're holding %d packet(s). my stall, today. don't dawdle." % data))

	# R10T taunts up the ladder.
	var idx := GameState.status_index()
	if idx >= 4:
		out.append(_m("R10T", "ff4f66", "saw '%s' on a job board. cute handle. i got there first 😏" % GameState.handle))

	# Marlowe surfaces when you're hot and flush.
	if GameState.heat >= 40 and GameState.cash >= 200:
		out.append(_m("Marlowe", "3b5dc9", "a name can vanish for the right price. you know where i am."))

	# Today's opportunity, echoing the daily modifier.
	var mod: Dictionary = GameState.daily_modifier()
	out.append(_m("CITY WIRE", "7adfff", "today: %s — %s" % [mod.name, mod.desc]))

	return out


static func _m(who: String, color: String, text: String) -> Dictionary:
	return {"from": who, "color": color, "text": text}
