extends Node3D
## Occasional neon flicker for prop_neon_sign: short bursts of stutter on the
## inner tube and its glow light, on a random cadence so every sign in a
## district misfires on its own rhythm. Attached to the sign scene root.

@onready var _inner: MeshInstance3D = $Inner
@onready var _glow: OmniLight3D = $Glow

var _base_energy := 1.5


func _ready() -> void:
	_base_energy = _glow.light_energy
	_schedule()


func _schedule() -> void:
	get_tree().create_timer(randf_range(3.0, 9.0)).timeout.connect(_flicker)


func _flicker() -> void:
	if not is_inside_tree():
		return
	var t := create_tween()
	for i in randi_range(2, 4):
		t.tween_callback(_set_on.bind(false))
		t.tween_interval(randf_range(0.03, 0.08))
		t.tween_callback(_set_on.bind(true))
		t.tween_interval(randf_range(0.04, 0.12))
	t.tween_callback(_schedule)


func _set_on(on: bool) -> void:
	_inner.visible = on
	_glow.light_energy = _base_energy if on else 0.15
