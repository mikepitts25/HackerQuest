class_name Interactable3D
extends Area3D
## 3D port of Interactable (interactable.gd): a volume the player can act on,
## holding a prompt and a Callable. Unlike the 2D version it draws nothing —
## attach it as a child of the prop/character instance that IS the visual,
## and it inherits that node's position (including moving NPCs).

var prompt_text := "Interact"
var action := Callable()


func configure(p_prompt: String, p_action: Callable, p_size: Vector3 = Vector3.ONE) -> void:
	prompt_text = p_prompt
	action = p_action

	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = p_size + Vector3(0.7, 0.5, 0.7)  # padding so the player can reach from beside it
	cs.shape = shape
	cs.position.y = (p_size.y + 0.5) * 0.5
	add_child(cs)

	add_to_group("interactable")


func interact() -> void:
	if action.is_valid():
		action.call()


# Visual feedback for spent objects. Props that model their own states (like
# the trash pile's Full/Searched children) get toggled; anything else fades.
func set_dim(dim: bool) -> void:
	var visual := get_parent()
	if visual == null:
		return
	var full := visual.get_node_or_null("Full")
	var searched := visual.get_node_or_null("Searched")
	if full and searched:
		full.visible = not dim
		searched.visible = dim
		return
	_fade(visual, dim)


func _fade(node: Node, dim: bool) -> void:
	if node is MeshInstance3D:
		node.transparency = 0.55 if dim else 0.0
	for c in node.get_children():
		_fade(c, dim)
