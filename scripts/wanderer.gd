extends "res://scripts/interactable.gd"
## A friendly ambient NPC that strolls between random points within its
## district. It's a normal Interactable (so you can talk to it), it just moves.
## Cross-district movement is handled by GameState migrating the roster on sleep.
## Not a `class_name` — instanced by path (district.gd) to avoid registry races.

var bounds := Vector2(1000, 800)
var _target := Vector2.ZERO
var _speed := 38.0


func _ready() -> void:
	_pick_target()


func _pick_target() -> void:
	_target = Vector2(randf_range(70.0, bounds.x - 70.0), randf_range(70.0, bounds.y - 70.0))


func _process(delta: float) -> void:
	var to_target := _target - position
	if to_target.length() < 6.0:
		_pick_target()
	else:
		position += to_target.normalized() * _speed * delta
