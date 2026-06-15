extends Panel
## Pawn shop UI. Lists upgrades from GameData.UPGRADES with prerequisite and
## cash checks; purchases go through GameState.buy_upgrade.

var _rows_box: VBoxContainer
var _cash_label: Label
var _cur: VBoxContainer        # the section currently being filled
var _collapsed := {}           # section title -> collapsed?  (persists per session)


func _ready() -> void:
	theme = UITheme.theme()
	_build_ui()
	GameState.stats_changed.connect(_refresh)


func open() -> void:
	visible = true
	GameState.lock_ui()
	_refresh()


func close_shop() -> void:
	visible = false
	GameState.unlock_ui()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_shop()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("12101a")
	add_theme_stylebox_override("panel", bg)

	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 20)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "PAWN SHOP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "tech & parts — no refunds, no receipts"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	vbox.add_child(subtitle)

	_cash_label = Label.new()
	_cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cash_label.add_theme_font_size_override("font_size", 20)
	_cash_label.add_theme_color_override("font_color", GameState.COL_GOOD)
	vbox.add_child(_cash_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_rows_box = VBoxContainer.new()
	_rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_rows_box)

	var close := Button.new()
	close.text = "LEAVE"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 56)
	close.pressed.connect(close_shop)
	vbox.add_child(close)


func _refresh() -> void:
	if not visible:
		return
	_cash_label.text = "Your cash: $%d" % GameState.cash
	for child in _rows_box.get_children():
		_rows_box.remove_child(child)
		child.queue_free()

	_begin_section("UPGRADES", GameData.UPGRADES.size())
	for id in GameData.UPGRADES:
		var u: Dictionary = GameData.UPGRADES[id]
		var ud: String = u.desc
		var ubtn: String
		var udis := false
		var uop := Callable()
		if GameState.owned(id):
			ubtn = "OWNED"
			udis = true
		elif u.req != "" and not GameState.owned(u.req):
			ubtn = "LOCKED"
			udis = true
			ud += "  (requires %s)" % GameData.UPGRADES[u.req]["name"]
		else:
			ubtn = "$%d" % u.price
			udis = GameState.cash < u.price
			uop = func() -> void: GameState.buy_upgrade(id)
		_shop_row(u.name, ud, ubtn, udis, uop, "cash")

	_begin_section("GEAR — rig · firewall · implant", GameData.GEAR.size())
	for gid in GameData.GEAR:
		var g: Dictionary = GameData.GEAR[gid]
		var stat := ""
		if g.has("cyber"): stat = "ATK +%d" % g.cyber
		elif g.has("defense"): stat = "DEF +%d" % g.defense
		else: stat = "INT +%d · CRIT +%d%%" % [g.get("integrity", 0), int(g.get("crit", 0) * 100)]
		var gd: String = "%s  [%s]" % [g.desc, stat]
		var gbtn: String = "$%d" % g.price
		var gdis: bool = GameState.cash < g.price
		if GameState.owns_gear(gid):
			gbtn = "EQUIPPED" if GameState.gear.get(g.slot, "") == gid else "EQUIP"
			gdis = false
		elif GameState.status_index() < int(g.get("status_req", 0)):
			gbtn = "LOCKED"; gdis = true
			gd += "  (needs %s)" % GameData.STATUS_RANKS[g.status_req]["title"]
		_shop_row(g.name, gd, gbtn, gdis, _on_gear_pressed.bind(gid))

	_begin_section("CONSUMABLES — keep going", GameData.CONSUMABLES.size())
	for cid in GameData.CONSUMABLES:
		var c: Dictionary = GameData.CONSUMABLES[cid]
		var have: int = GameState.inventory.get(cid, 0)
		var name_text: String = c.name + ("  (have %d)" % have if have > 0 else "")
		_shop_row(name_text, c.desc, "$%d" % c.price, GameState.cash < c.price,
				func() -> void: GameState.buy_consumable(cid), "cash")

	_begin_section("STYLE — dress the part", GameData.COSMETICS.size())
	for cid in GameData.COSMETICS:
		var item: Dictionary = GameData.COSMETICS[cid]
		var status_req: int = item.get("status_req", 0)
		var desc: String = item.desc
		var btn_text: String
		var disabled := false
		var on_press: Callable
		if GameState.is_wearing(cid):
			btn_text = "WEARING"
			disabled = true
		elif GameState.owns_cosmetic(cid):
			btn_text = "WEAR"
			on_press = func() -> void: GameState.equip_cosmetic(cid)
		elif GameState.status_index() < status_req:
			btn_text = "LOCKED"
			disabled = true
			desc += "  (requires %s status)" % GameData.STATUS_RANKS[status_req]["title"]
		else:
			btn_text = "$%d" % item.price
			disabled = GameState.cash < item.price
			on_press = func() -> void: GameState.buy_cosmetic(cid)
		_shop_row(item.name, desc, btn_text, disabled, on_press)

	# Sell loot — junk items only (consumables are bought/used, not sold here).
	var junk: Array = GameState.inventory.keys().filter(func(k): return GameState.is_junk_item(k))
	if not junk.is_empty():
		_begin_section("YOUR LOOT — sell for cash", junk.size())
		for item_id in junk:
			var item: Dictionary = GameData.ITEMS[item_id]
			var price := int(round(item.price * GameState.hustle_mult()))
			_shop_row("%s  ×%d" % [item.name, GameState.inventory[item_id]], "",
					"SELL  $%d" % price, false,
					func() -> void: GameState.sell_item(item_id), "cash")


# Reusable shop row: name + optional description, action button on the right.
func _on_gear_pressed(id: String) -> void:
	if GameState.owns_gear(id):
		GameState.equip_gear(id)
	else:
		GameState.buy_gear(id)
	_refresh()


func _shop_row(name_text: String, desc_text: String, btn_text: String, disabled: bool, on_press: Callable, sfx_name := "click") -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.05)
	style.set_content_margin_all(12)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	_cur.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var name_label := Label.new()
	name_label.text = name_text
	name_label.add_theme_font_size_override("font_size", 18)
	info.add_child(name_label)
	if desc_text != "":
		var desc := Label.new()
		desc.text = desc_text
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 14)
		desc.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
		info.add_child(desc)

	var btn := Button.new()
	btn.text = btn_text
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(150, 56)
	btn.disabled = disabled
	if not disabled and on_press.is_valid():
		btn.pressed.connect(func() -> void:
			Audio.sfx(sfx_name)
			on_press.call())
	row.add_child(btn)


# A tappable, collapsible category header. Rows added after it (via _shop_row)
# land in this section's box and hide/show with it. Collapsed state persists for
# the session; everything starts collapsed except UPGRADES.
func _begin_section(title: String, count: int) -> void:
	var collapsed: bool = _collapsed.get(title, title != "UPGRADES")
	var header := Button.new()
	header.text = "%s  %s   [%d]" % ["▾" if not collapsed else "▸", title, count]
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.focus_mode = Control.FOCUS_NONE
	header.custom_minimum_size = Vector2(0, 44)
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color("7ee787"))
	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(0.49, 0.91, 0.53, 0.1)
	hs.set_content_margin_all(8)
	hs.set_corner_radius_all(6)
	header.add_theme_stylebox_override("normal", hs)
	header.add_theme_stylebox_override("hover", hs)
	header.add_theme_stylebox_override("pressed", hs)
	header.pressed.connect(func() -> void:
		Audio.sfx("ui_open")
		_collapsed[title] = not collapsed
		_refresh())
	_rows_box.add_child(header)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.visible = not collapsed
	_rows_box.add_child(box)
	_cur = box
