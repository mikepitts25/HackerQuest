extends Control
## "City Grid" — the subway-style network map of the districts, drawn
## entirely in _draw (no assets). Live stations come from
## GameData.DISTRICT_MAP.stations + GameData.DISTRICTS (+ GameState lock
## state); planned expansions render as faint teaser stops. Set
## `current_district` before showing. Flip `reveal_future` to label the
## planned stops with names and hooks (used for docs renders).

signal travel_requested(district_id: String)

var current_district := ""
var reveal_future := false

var _t := 0.0

const COL_GRID := Color(0.49, 0.91, 0.53, 0.045)
const COL_LINE := Color(0.49, 0.91, 0.53, 0.85)
const COL_LINE_GLOW := Color(0.49, 0.91, 0.53, 0.15)
const COL_OPEN := Color(0.48, 0.87, 1.0)
const COL_LOCKED := Color(0.55, 0.58, 0.66)
const COL_FUTURE := Color(0.7, 0.47, 0.88)
const COL_TEXT := Color(0.9, 0.93, 0.96)
const COL_DIM := Color(1, 1, 1, 0.45)
const COL_YOU := Color(0.49, 0.91, 0.53)


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_t += delta
		queue_redraw()


# Tap a station to fast-travel (touch arrives as mouse via emulation).
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)


func _handle_tap(pos: Vector2) -> void:
	for id in GameData.DISTRICT_MAP.stations:
		var p := _pt(GameData.DISTRICT_MAP.stations[id].pos)
		if pos.distance_to(p) > 34.0:
			continue
		if id == current_district:
			return
		if GameState.district_unlocked(id):
			travel_requested.emit(id)
		else:
			var req: int = GameData.DISTRICTS[id].get("status_req", 0)
			GameState.notify("%s opens up at %s status." % [GameData.DISTRICTS[id]["name"], GameData.STATUS_RANKS[req]["title"]], GameState.COL_WARN)
		return


# Normalized map coords -> canvas pixels, inset so edge labels stay inside.
func _pt(p: Array) -> Vector2:
	const INSET := Vector2(50, 42)
	return Vector2(
		INSET.x + p[0] * (size.x - INSET.x * 2.0),
		INSET.y + p[1] * (size.y - INSET.y * 2.0 - 26.0))  # extra room for the legend


func _draw() -> void:
	var font := get_theme_default_font()
	var stations: Dictionary = GameData.DISTRICT_MAP.stations
	var future: Dictionary = GameData.DISTRICT_MAP.future
	var links: Array = GameData.DISTRICT_MAP.links

	# Faint grid — the "network diagram" backdrop.
	var step := 36.0
	var gx := step
	while gx < size.x:
		draw_line(Vector2(gx, 0), Vector2(gx, size.y), COL_GRID, 1.0)
		gx += step
	var gy := step
	while gy < size.y:
		draw_line(Vector2(0, gy), Vector2(size.x, gy), COL_GRID, 1.0)
		gy += step

	# Planned spurs first (dotted, under everything). A spur may branch off
	# another planned stop (e.g. Rooftops hangs off Signal Yards).
	for fid in future:
		var f: Dictionary = future[fid]
		var src: Array
		if stations.has(f.from):
			src = stations[f.from].pos
		else:
			src = future[f.from].pos
		draw_dashed_line(_pt(src), _pt(f.pos), Color(COL_FUTURE, 0.45), 2.0, 7.0)

	# The live line, with glow.
	for link in links:
		var a := _pt(stations[link[0]].pos)
		var b := _pt(stations[link[1]].pos)
		draw_line(a, b, COL_LINE_GLOW, 12.0)
		draw_line(a, b, COL_LINE, 4.0)

	# Planned teaser stops.
	for fid in future:
		var f: Dictionary = future[fid]
		var p := _pt(f.pos)
		draw_arc(p, 8.0, 0, TAU, 24, Color(COL_FUTURE, 0.8), 2.0)
		var label: String = f.name if reveal_future else "???"
		draw_string(font, p + Vector2(-110, 24), label,
				HORIZONTAL_ALIGNMENT_CENTER, 220, 13, Color(COL_FUTURE, 0.9))
		if reveal_future:
			draw_string(font, p + Vector2(-130, 40), f.hook,
					HORIZONTAL_ALIGNMENT_CENTER, 260, 10, Color(COL_FUTURE, 0.65))

	# Live stations.
	for id in stations:
		var p := _pt(stations[id].pos)
		var unlocked: bool = GameState.district_unlocked(id)
		var col := COL_OPEN if unlocked else COL_LOCKED
		var dname: String = GameData.DISTRICTS[id]["name"].to_upper()
		draw_circle(p, 13.0, Color(0.03, 0.05, 0.08))
		draw_arc(p, 13.0, 0, TAU, 32, col, 3.5)
		if unlocked:
			draw_circle(p, 5.0, col)
		else:
			# Tiny padlock: body + shackle.
			draw_rect(Rect2(p + Vector2(-4.5, -1), Vector2(9, 7)), COL_LOCKED)
			draw_arc(p + Vector2(0, -2), 3.5, PI, TAU, 12, COL_LOCKED, 2.0)
		draw_string(font, p + Vector2(-110, 32), dname,
				HORIZONTAL_ALIGNMENT_CENTER, 220, 15,
				COL_TEXT if unlocked else COL_DIM)
		if unlocked and GameData.MASTERY.has(id):
			var tier: int = GameState.mastery_tier(id)
			for i in 3:  # mastery pips
				var pc := p + Vector2((i - 1) * 13.0, 44.0)
				if i < tier:
					draw_circle(pc, 4.0, Color(0.91, 0.66, 0.24))
				else:
					draw_arc(pc, 4.0, 0, TAU, 12, Color(0.91, 0.66, 0.24, 0.3), 1.5)
		if not unlocked:
			var req: int = GameData.DISTRICTS[id].get("status_req", 0)
			draw_string(font, p + Vector2(-110, 47),
					"unlocks at %s" % GameData.STATUS_RANKS[req]["title"],
					HORIZONTAL_ALIGNMENT_CENTER, 220, 11, COL_DIM)
		if id == current_district:
			draw_arc(p, 18.0 + sin(_t * 4.0) * 2.5, 0, TAU, 32, COL_YOU, 2.5)
			draw_string(font, p + Vector2(-110, -24), "YOU ARE HERE",
					HORIZONTAL_ALIGNMENT_CENTER, 220, 12, COL_YOU)

	# Where everyone is today — a colored initial per named NPC, stacked
	# beside the station they're currently in (roamers move day to day).
	var by_station := {}
	for nid in GameData.NPCS:
		var loc: String = GameState.npc_district(nid)
		if not stations.has(loc):
			continue
		by_station.get_or_add(loc, []).append(nid)
	for loc in by_station:
		var p := _pt(stations[loc].pos)
		var list: Array = by_station[loc]
		for i in list.size():
			var nid: String = list[i]
			var col := Color(GameData.NPCS[nid]["color"])
			var mp := p + Vector2(20.0, -10.0 + i * 13.0)
			draw_circle(mp, 4.5, col)
			draw_string(font, mp + Vector2(8, 4), GameData.NPCS[nid]["name"],
					HORIZONTAL_ALIGNMENT_LEFT, 90, 11, col)

	# Today's district modifier — amber star over the affected station.
	var mod: Dictionary = GameState.daily_modifier()
	if stations.has(mod.district):
		var mp := _pt(stations[mod.district].pos)
		draw_string(font, mp + Vector2(-110, -38), "★ " + mod.name,
				HORIZONTAL_ALIGNMENT_CENTER, 220, 12, Color(0.91, 0.66, 0.24))

	# Hint + legend.
	draw_string(font, Vector2(0, 16), "tap an open station to travel",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, COL_DIM)
	var ly := size.y - 10.0
	draw_circle(Vector2(20, ly - 5), 5.0, COL_OPEN)
	draw_string(font, Vector2(30, ly), "open", HORIZONTAL_ALIGNMENT_LEFT, 80, 12, COL_DIM)
	draw_arc(Vector2(105, ly - 5), 5.0, 0, TAU, 16, COL_LOCKED, 2.0)
	draw_string(font, Vector2(115, ly), "status-locked", HORIZONTAL_ALIGNMENT_LEFT, 140, 12, COL_DIM)
	draw_arc(Vector2(245, ly - 5), 5.0, 0, TAU, 16, Color(COL_FUTURE, 0.8), 1.5)
	draw_string(font, Vector2(255, ly), "under construction", HORIZONTAL_ALIGNMENT_LEFT, 200, 12, COL_DIM)
