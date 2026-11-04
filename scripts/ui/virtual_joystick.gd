class_name HackerQuestJoystick
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
	var active := _vec.length() > DEAD_ZONE
	draw_circle(center, radius, Color("101d30", 0.72))
	draw_arc(center, radius, 0, TAU, 64, Color("b9d3e5", 0.16), 1.5, true)
	for i in 4:
		var dir := Vector2.RIGHT.rotated(i * PI / 2.0)
		var p := center + dir * (radius - 17)
		var side := dir.orthogonal() * 3.5
		draw_polyline(PackedVector2Array([p - dir * 4 + side, p, p - dir * 4 - side]), Color("b9d3e5", 0.32), 1.5, true)
	var knob := center + _vec * (radius - 28.0)
	draw_circle(knob + Vector2(0, 3), 27, Color(0, 0, 0, 0.18))
	draw_circle(knob, 26, Color("8af0d8") if active else Color("d2e1e9", 0.90))
	draw_circle(knob, 6, Color("18313e", 0.45))
