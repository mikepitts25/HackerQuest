extends Node3D
## Playground glue: attaches Interactable3D volumes to the static props and
## the wandering NPCs, wired to real GameState calls where the sim already
## supports them (trash scavenging works for real — energy, loot, cash, XP),
## and builds a minimal HUD (prompt + toasts) so it's all testable without
## porting the full 2D game UI.

const InteractableScript := preload("res://scripts/iso/interactable_3d.gd")

const TALK_LINES := {
	"Pix": "Pix: \"Saw a fat contract drop on the board. You didn't hear it from me.\"",
	"R10T": "R10T: \"Keep your heat down. The sweeps got upgraded last patch.\"",
	"Glitch": "Glitch: \"I can route around anything except rent.\"",
	"Marlowe": "Marlowe: \"Word is Corp Row's hiring... if your status checks out.\"",
	"Vex": "Vex: \"Buying? Selling? Either way, it never happened.\"",
	"Cipher": "Cipher: \"Come back when your reputation precedes you.\"",
	"Oracle": "Oracle: \"The darknet remembers what you are about to do.\"",
}

var _prompt: Label
var _toasts: VBoxContainer


func _ready() -> void:
	_build_hud()
	GameState.prompt_changed.connect(_on_prompt)
	GameState.toast.connect(_on_toast)

	var trash: Area3D = _attach($Trash, "Search trash", Vector3(0.9, 0.6, 0.8), Callable())
	trash.action = func() -> void: _search_trash("iso_playground", trash)
	if GameState.trash_searched.has("iso_playground"):
		trash.set_dim(true)

	_attach($JobBoard, "Check job board", Vector3(1.5, 1.5, 0.4),
			func() -> void: GameState.notify("Job board hooks up when the WorldRouter lands. The notes still glow, though.", GameState.COL_INFO))
	_attach($Counter, "Browse the stall", Vector3(1.8, 1.2, 0.8),
			func() -> void: GameState.notify("Vex's stall: shop UI port pending. Window shopping is free.", GameState.COL_INFO))
	_attach($ExitMarker, "Go to The Market", Vector3(1.2, 1.6, 1),
			func() -> void: GameState.notify("The arch hums. District travel arrives with the WorldRouter.", GameState.COL_WARN))
	_attach($Rack, "Inspect server rack", Vector3(0.7, 1.5, 0.6),
			func() -> void: GameState.notify("Rack lights blink green. Somebody's botnet is warm.", GameState.COL_INFO))

	for npc_name in TALK_LINES:
		var node := get_node_or_null(NodePath(npc_name))
		if node == null:
			continue
		var line: String = TALK_LINES[npc_name]
		_attach(node, "Talk to %s" % npc_name, Vector3(0.6, 1.3, 0.6),
				func() -> void: GameState.notify(line, GameState.COL_INFO))


func _attach(visual: Node3D, prompt: String, size: Vector3, action: Callable) -> Area3D:
	var obj: Area3D = InteractableScript.new()
	visual.add_child(obj)
	obj.configure(prompt, action, size)
	return obj


# Real sim hookup — same flow as district.gd's _search_trash, against the
# live GameState. Resets on sleep like the 2D piles (trash_searched clears).
func _search_trash(id: String, pile: Area3D) -> void:
	if GameState.trash_searched.has(id):
		GameState.notify("Picked clean. Check back tomorrow.", GameState.COL_WARN)
		return
	if not GameState.use_energy(1):
		return
	GameState.trash_searched[id] = true
	var item_id: String = GameData.TRASH_LOOT.pick_random()
	var scrap := int(round(randi_range(2, 4) * GameState.hustle_mult()))
	GameState.add_item(item_id)
	GameState.add_cash(scrap)
	GameState.add_xp(3)
	GameState.notify("Found %s! (+$%d scrap, +3 XP)" % [GameData.ITEMS[item_id]["name"], scrap], GameState.COL_GOOD)
	pile.set_dim(true)


# --- minimal HUD --------------------------------------------------------------

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)

	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", 22)
	_prompt.add_theme_color_override("font_color", Color("7ee787"))
	_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_prompt.add_theme_constant_override("outline_size", 6)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -120.0
	_prompt.offset_bottom = -90.0
	_prompt.offset_left = -250.0
	_prompt.offset_right = 250.0
	hud.add_child(_prompt)

	_toasts = VBoxContainer.new()
	_toasts.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toasts.offset_top = 70.0
	_toasts.offset_bottom = 520.0
	_toasts.offset_left = -330.0
	_toasts.offset_right = 330.0
	hud.add_child(_toasts)


func _on_prompt(text: String) -> void:
	_prompt.text = ("[E] %s" % text) if text != "" else ""


func _on_toast(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toasts.add_child(label)
	var fade := label.create_tween()
	fade.tween_interval(2.6)
	fade.tween_property(label, "modulate:a", 0.0, 0.6)
	fade.tween_callback(label.queue_free)
