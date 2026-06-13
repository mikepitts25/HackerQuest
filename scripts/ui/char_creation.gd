extends Control
## Character creation (G2). Reached from the title's NEW GAME after
## GameState.new_game() has reset state. Collects a handle, look (skin tone +
## starting outfit + hat, granted free), and a background class, applies them,
## then hands off to the world.

const WORLD_SCENE := "res://scenes/iso/iso_main.tscn"

const SKINS := ["f0c8a0", "e8b890", "c89868", "9a6a44", "6e4a30"]
const OUTFITS := [
	["hoodie_gray", "Gray"], ["hoodie_red", "Red"], ["jacket_neon", "Neon"],
]
const HATS := [
	["hat_none", "None"], ["hat_beanie", "Beanie"], ["hat_cap", "Cap"],
]
const BACKGROUNDS := [
	["scrapper", "Scrapper", "Grew up in the e-waste. +50% scrap from trash."],
	["coder", "Coder", "Self-taught on a cracked IDE. +2 max CPU, +1 skill point."],
	["face", "Face", "You know everyone. Reputation grows faster."],
	["runner", "Runner", "Always moving. Start with a Hoverboard."],
]

var _handle_edit: LineEdit
var _skin := 1
var _outfit := "hoodie_gray"
var _hat := "hat_none"
var _bg := "scrapper"
var _skin_swatch: ColorRect


func _ready() -> void:
	theme = UITheme.theme()
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("0a0e14")
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.custom_minimum_size = Vector2(460, 0)
	center.add_child(col)

	var title := Label.new()
	title.text = "CREATE YOUR OPERATOR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("7ee787"))
	col.add_child(title)

	# Handle
	_label(col, "HANDLE")
	_handle_edit = LineEdit.new()
	_handle_edit.placeholder_text = "pick an alias..."
	_handle_edit.max_length = 16
	_handle_edit.text = ""
	col.add_child(_handle_edit)

	# Skin tone swatches
	_label(col, "SKIN")
	var skin_row := HBoxContainer.new()
	skin_row.add_theme_constant_override("separation", 8)
	col.add_child(skin_row)
	for i in SKINS.size():
		var idx := i
		var b := Button.new()
		b.custom_minimum_size = Vector2(52, 40)
		b.focus_mode = Control.FOCUS_NONE
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(SKINS[i])
		sb.set_corner_radius_all(3)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		b.pressed.connect(func() -> void:
			_skin = idx
			_refresh_preview())
		skin_row.add_child(b)

	# Outfit + hat choice rows
	_label(col, "OUTFIT")
	col.add_child(_choice_row(OUTFITS, func(id): _outfit = id, _outfit))
	_label(col, "HAT")
	col.add_child(_choice_row(HATS, func(id): _hat = id, _hat))

	# Background cards
	_label(col, "BACKGROUND")
	var bg_box := VBoxContainer.new()
	bg_box.add_theme_constant_override("separation", 6)
	col.add_child(bg_box)
	var bg_btns := {}
	for entry in BACKGROUNDS:
		var id: String = entry[0]
		var btn := Button.new()
		btn.text = "%s — %s" % [entry[1], entry[2]]
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(0, 46)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(func() -> void:
			_bg = id
			for k in bg_btns:
				bg_btns[k].add_theme_color_override("font_color",
						Color("7ee787") if k == id else Color("d8e2ec"))
		)
		bg_box.add_child(btn)
		bg_btns[id] = btn
	bg_btns[_bg].add_theme_color_override("font_color", Color("7ee787"))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	col.add_child(spacer)

	var begin := Button.new()
	begin.text = "JACK IN ▸"
	begin.focus_mode = Control.FOCUS_NONE
	begin.custom_minimum_size = Vector2(0, 56)
	begin.add_theme_font_size_override("font_size", 22)
	begin.add_theme_color_override("font_color", Color("7ee787"))
	begin.pressed.connect(_on_begin)
	col.add_child(begin)


func _label(parent: Control, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	parent.add_child(l)


# A row of mutually-exclusive choice buttons; highlights the selected one.
func _choice_row(options: Array, on_select: Callable, initial: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var btns := {}
	for entry in options:
		var id: String = entry[0]
		var btn := Button.new()
		btn.text = entry[1]
		btn.focus_mode = Control.FOCUS_NONE
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 40)
		btn.pressed.connect(func() -> void:
			on_select.call(id)
			for k in btns:
				btns[k].add_theme_color_override("font_color",
						Color("7ee787") if k == id else Color("d8e2ec"))
		)
		row.add_child(btn)
		btns[id] = btn
	btns[initial].add_theme_color_override("font_color", Color("7ee787"))
	return row


func _refresh_preview() -> void:
	pass  # swatch selection is implicit; full 3D preview is a later nicety


func _on_begin() -> void:
	GameState.handle = _handle_edit.text.strip_edges() if _handle_edit.text.strip_edges() != "" else "Anon"
	GameState.skin_tone = SKINS[_skin]
	# Grant + equip the chosen starter look for free.
	for id in [_outfit, _hat]:
		if not GameState.owns_cosmetic(id):
			GameState.owned_cosmetics.append(id)
		GameState.equip_cosmetic(id)
	GameState.apply_background(_bg)
	GameState.save_game()
	get_tree().change_scene_to_file(WORLD_SCENE)
