extends CharacterBody2D
## Top-down player. Moves via keyboard (WASD/arrows) or the HUD virtual
## joystick, and interacts with the nearest Interactable in reach.

const SPEED := 230.0

var _near: Array = []          # Interactables currently in reach
var _current: Interactable = null
var _face := Vector2.DOWN
var _floaters: Array = []      # active floating feedback labels


func _ready() -> void:
	GameState.toast.connect(_spawn_float_text)
	GameState.cosmetics_changed.connect(queue_redraw)
	var reach := Area2D.new()
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 54.0
	cs.shape = shape
	reach.add_child(cs)
	add_child(reach)
	reach.area_entered.connect(_on_reach_entered)
	reach.area_exited.connect(_on_reach_exited)
	GameState.interact_requested.connect(try_interact)


func _physics_process(_delta: float) -> void:
	if GameState.is_ui_locked():
		velocity = Vector2.ZERO
	else:
		var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if dir == Vector2.ZERO:
			dir = GameState.touch_vector
		dir = dir.limit_length(1.0)
		velocity = dir * SPEED
		if dir != Vector2.ZERO:
			_face = dir.normalized()
			queue_redraw()
	move_and_slide()
	_update_nearest()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		try_interact()


func try_interact() -> void:
	if GameState.is_ui_locked():
		return
	if is_instance_valid(_current):
		_current.interact()


# Called by the router when the district changes out from under us.
func reset_proximity() -> void:
	_near.clear()
	_current = null
	GameState.prompt_changed.emit("")


func _on_reach_entered(area: Area2D) -> void:
	if area is Interactable:
		_near.append(area)


func _on_reach_exited(area: Area2D) -> void:
	_near.erase(area)


func _update_nearest() -> void:
	# Drop any interactables freed by a district swap.
	_near = _near.filter(is_instance_valid)
	var best: Interactable = null
	var best_dist := INF
	for a in _near:
		var d: float = global_position.distance_squared_to(a.global_position)
		if d < best_dist:
			best_dist = d
			best = a
	if best != _current:
		_current = best
		GameState.prompt_changed.emit(_current.prompt_text if _current else "")


# Feedback messages float up from above the player's head and fade out.
func _spawn_float_text(text: String, color: Color) -> void:
	_floaters = _floaters.filter(is_instance_valid)
	for f in _floaters:
		f.position.y -= 22.0
	var label := Label.new()
	label.text = text
	label.z_index = 100
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(240, 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = global_position + Vector2(-120, -58)
	get_parent().add_child(label)
	_floaters.append(label)
	var rise := label.create_tween()
	rise.tween_property(label, "position:y", label.position.y - 30.0, 2.2)
	var fade := label.create_tween()
	fade.tween_interval(1.7)
	fade.tween_property(label, "modulate:a", 0.0, 0.5)
	fade.tween_callback(label.queue_free)


func _draw() -> void:
	var outfit := Color(GameState.cosmetic_color("outfit", "3c4454"))
	draw_circle(Vector2.ZERO, 15.0, Color("20242c"))   # outline
	draw_circle(Vector2.ZERO, 12.0, outfit)            # body / outfit
	_draw_hat()
	draw_circle(_face * 7.0, 4.0, Color("7ee787"))     # face, pointing where we walk


# Hats are drawn top-down over the head; the face dot is drawn after so it
# stays visible. Shapes are intentionally simple to read at the 2x camera zoom.
func _draw_hat() -> void:
	var style := GameState.cosmetic_style("hat")
	if style == "" or style == "none":
		return
	var col := Color(GameState.cosmetic_color("hat", "5a5f6e"))
	match style:
		"beanie":
			draw_circle(Vector2.ZERO, 10.0, col)
		"cap":
			draw_circle(Vector2.ZERO, 10.0, col)
			draw_circle(_face * 11.0, 4.0, col)        # brim toward facing
		"crown":
			draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 24, col, 3.5)
