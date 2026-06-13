class_name VirtualJoystick
extends Control
## Simple on-screen joystick. Writes its vector into GameState.touch_vector,
## which the player reads each physics frame. Works with mouse on desktop via
## touch emulation (enabled in project settings).

const DEAD_ZONE := 0.2

var _touch_index := -1
var _vec := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(_delta: float) -> void:
	# If a UI panel opened mid-drag we may never get the release event.
	if _touch_index != -1 and GameState.is_ui_locked():
		_release()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_update_vec(event.position)
		elif not event.pressed and event.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_vec(event.position)


func _update_vec(pos: Vector2) -> void:
	var center := size / 2.0
	var v := (pos - center) / (size.x / 2.0 - 20.0)
	_vec = v.limit_length(1.0)
	GameState.touch_vector = Vector2.ZERO if _vec.length() < DEAD_ZONE else _vec
	queue_redraw()


func _release() -> void:
	_touch_index = -1
	_vec = Vector2.ZERO
	GameState.touch_vector = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var radius := size.x / 2.0 - 10.0
	var cyan := Color(0.48, 0.87, 1.0)
	draw_circle(center, radius, Color(cyan, 0.04))
	draw_arc(center, radius, 0, TAU, 64, Color(cyan, 0.3), 1.5)
	draw_arc(center, radius - 6.0, 0, TAU, 64, Color(cyan, 0.08), 1.0)
	for i in 4:  # cardinal ticks
		var dir := Vector2.RIGHT.rotated(i * PI / 2.0)
		draw_line(center + dir * (radius - 8.0), center + dir * (radius - 1.0), Color(cyan, 0.45), 2.0)
	var knob := center + _vec * (radius - 28.0)
	draw_circle(knob, 26.0, Color(cyan, 0.1))
	draw_arc(knob, 26.0, 0, TAU, 40, Color(cyan, 0.65), 1.5)
	draw_circle(knob, 9.0, Color(0.49, 0.91, 0.53, 0.85))
