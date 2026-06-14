extends Control
## Boot screen. Continue an existing save or start fresh. Set as the project's
## main scene; both buttons hand off to the world scene — the 3D isometric
## city (the legacy 2D shell lives on at res://scenes/main.tscn).

const WORLD_SCENE := "res://scenes/iso/iso_main.tscn"
const CREATION_SCENE := "res://scenes/ui/char_creation.tscn"

var _new_btn: Button
var _confirm_wipe := false


func _ready() -> void:
	theme = UITheme.theme()
	Audio.music("title")
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
	col.add_theme_constant_override("separation", 16)
	col.custom_minimum_size = Vector2(420, 0)
	center.add_child(col)

	var title := Label.new()
	title.text = "HACKER QUEST"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color("7ee787"))
	col.add_child(title)

	var sub := Label.new()
	sub.text = "from broke wannabe to elite operator"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	col.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	col.add_child(spacer)

	if GameState.has_save():
		var s := GameState.peek_save()
		var label := "CONTINUE"
		if not s.is_empty():
			var rank := GameState.status_title_for(s.get("reputation", 0))
			label = "CONTINUE\nDay %d · Lvl %d · %s\n$%d" % [s.day, s.level, rank, s.cash]
		var cont := _button(col, label)
		cont.custom_minimum_size = Vector2(0, 96)
		cont.add_theme_color_override("font_color", Color("7ee787"))
		cont.pressed.connect(_on_continue)

	_new_btn = _button(col, "NEW GAME")
	_new_btn.pressed.connect(_on_new_game)


func _button(parent: Control, text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 60)
	btn.add_theme_font_size_override("font_size", 20)
	parent.add_child(btn)
	return btn


func _on_continue() -> void:
	GameState.load_game()
	get_tree().change_scene_to_file(WORLD_SCENE)


func _on_new_game() -> void:
	# Guard against wiping an existing save with a single mis-tap.
	if GameState.has_save() and not _confirm_wipe:
		_confirm_wipe = true
		_new_btn.text = "ERASE SAVE & START OVER?"
		_new_btn.add_theme_color_override("font_color", Color("ff6b6b"))
		return
	GameState.new_game()
	get_tree().change_scene_to_file(CREATION_SCENE)
