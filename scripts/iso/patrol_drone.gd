extends Node3D
## Police patrol drone — orbits a district when the player's heat is above
## Clean, strobing red/blue. Pure presentation: it never catches anyone,
## it just makes the streets feel watched. Built in code by district_3d.

var center := Vector3.ZERO
var radius := 4.0
var height := 2.6
var orbit_speed := 0.45

var _a := 0.0

@onready var _light: OmniLight3D = $Light


func _ready() -> void:
	_a = randf() * TAU  # random phase so two districts never sync


func _process(delta: float) -> void:
	_a += delta * orbit_speed
	position = center + Vector3(cos(_a) * radius, height + sin(_a * 3.0) * 0.15, sin(_a) * radius)
	rotation.y = -_a
	_light.light_color = Color(1, 0.2, 0.25) if fmod(_a * 5.0, 2.0) < 1.0 else Color(0.3, 0.5, 1.0)
