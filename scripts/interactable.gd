class_name Interactable
extends Area2D
## A world object the player can interact with. Built entirely in code by
## WorldBuilder: a colored rect, an optional label, and a Callable to run.

var prompt_text := "Interact"
var action := Callable()


func configure(p_prompt: String, p_action: Callable, p_size: Vector2, p_color: Color, p_label: String = "") -> void:
	prompt_text = p_prompt
	action = p_action

	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = p_size + Vector2(36, 36)  # padding so the player can reach from beside it
	cs.shape = shape
	add_child(cs)

	var rect := ColorRect.new()
	rect.size = p_size
	rect.position = -p_size / 2.0
	rect.color = p_color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)

	if p_label != "":
		var label := Label.new()
		label.text = p_label
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
		label.custom_minimum_size = Vector2(160, 0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(-80, p_size.y / 2.0 + 6)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)

	add_to_group("interactable")


func interact() -> void:
	if action.is_valid():
		action.call()


func set_dim(dim: bool) -> void:
	modulate = Color(0.45, 0.45, 0.45) if dim else Color.WHITE
