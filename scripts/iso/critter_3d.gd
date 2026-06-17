extends Node3D
## A small ambient street animal for the iso city — a stray cat or a little
## hover-drone "bird". Built entirely in code (blocky, like the pet/Byte), it
## wanders a small patch, faces its travel direction, and occasionally chirps.
## Cheap, harmless flavor life so the streets aren't just people and props.

@export var area_center := Vector3.ZERO
@export var area_size := Vector2(4, 4)
@export var speed := 1.1
@export var kind := "cat"  # "cat" | "bird" | "rat"

const BIRD_HOVER := 0.7

var _target := Vector3.ZERO
var _wait := 0.0
var _t := 0.0
var _body: Node3D
var _bubble: Label3D
var _chirp_at := 0.0


func _ready() -> void:
	_build()
	_wait = randf_range(0.3, 2.5)
	_chirp_at = randf_range(6.0, 16.0)


func _process(delta: float) -> void:
	_t += delta
	if kind == "bird":
		_body.position.y = BIRD_HOVER + sin(_t * 5.0) * 0.08  # hover bob
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			_pick_target()
		return
	var to_target := _target - global_position
	to_target.y = 0.0
	if to_target.length() < 0.1:
		_wait = randf_range(1.0, 3.5)
		return
	global_position += to_target.normalized() * minf(speed * delta, to_target.length())
	_body.rotation.y = atan2(to_target.x, to_target.z)
	_chirp_at -= delta
	if _chirp_at <= 0.0:
		_chirp_at = randf_range(8.0, 20.0)
		_say(_pick_line())


func _pick_target() -> void:
	_target = area_center + Vector3(
		randf_range(-area_size.x * 0.5, area_size.x * 0.5), 0.0,
		randf_range(-area_size.y * 0.5, area_size.y * 0.5))


# --- build --------------------------------------------------------------------

func _build() -> void:
	_body = Node3D.new()
	add_child(_body)
	if kind == "bird":
		_build_bird()
	elif kind == "rat":
		_build_rat()
	else:
		_build_cat()


# A low four-legged stray with glowing eyes and an angled tail. Fur color varies.
func _build_cat() -> void:
	var palette := [
		Color(0.12, 0.12, 0.14), Color(0.5, 0.42, 0.3),
		Color(0.7, 0.7, 0.72), Color(0.28, 0.22, 0.18), Color(0.9, 0.6, 0.3),
	]
	var fur := _mat(palette.pick_random())
	var eye := _mat_glow(Color(0.6, 0.95, 0.5))
	_box(_body, Vector3(0.18, 0.16, 0.34), Vector3(0, 0.18, 0), fur)        # torso
	_box(_body, Vector3(0.16, 0.15, 0.15), Vector3(0, 0.24, 0.22), fur)     # head
	_box(_body, Vector3(0.04, 0.07, 0.02), Vector3(-0.05, 0.34, 0.24), fur) # ears
	_box(_body, Vector3(0.04, 0.07, 0.02), Vector3(0.05, 0.34, 0.24), fur)
	_box(_body, Vector3(0.03, 0.03, 0.02), Vector3(-0.04, 0.25, 0.3), eye)  # eyes
	_box(_body, Vector3(0.03, 0.03, 0.02), Vector3(0.04, 0.25, 0.3), eye)
	var tail := _box(_body, Vector3(0.04, 0.04, 0.2), Vector3(0, 0.26, -0.24), fur)
	tail.rotation.x = deg_to_rad(-35)                                       # angled tail
	for x in [-0.06, 0.06]:
		for z in [-0.1, 0.12]:
			_box(_body, Vector3(0.05, 0.16, 0.05), Vector3(x, 0.08, z), fur)  # legs


func _build_rat() -> void:
	var fur := _mat([Color(0.10, 0.10, 0.12), Color(0.18, 0.16, 0.14), Color(0.28, 0.25, 0.22)].pick_random())
	var eye := _mat_glow(Color(0.9, 0.1, 0.18))
	var tail_mat := _mat(Color(0.34, 0.22, 0.24))
	_box(_body, Vector3(0.14, 0.1, 0.3), Vector3(0, 0.12, 0), fur)
	_box(_body, Vector3(0.11, 0.09, 0.11), Vector3(0, 0.15, 0.19), fur)
	_box(_body, Vector3(0.02, 0.025, 0.015), Vector3(-0.035, 0.16, 0.255), eye)
	_box(_body, Vector3(0.02, 0.025, 0.015), Vector3(0.035, 0.16, 0.255), eye)
	var tail := _box(_body, Vector3(0.025, 0.025, 0.28), Vector3(0, 0.12, -0.27), tail_mat)
	tail.rotation.x = deg_to_rad(-16)
	for x in [-0.05, 0.05]:
		for z in [-0.08, 0.11]:
			_box(_body, Vector3(0.035, 0.08, 0.035), Vector3(x, 0.04, z), fur)


# A tiny hover-drone "bird" — a dark pod with a glowing rotor bar and an eye.
# Built around local origin; _process lifts the whole body to hover height.
func _build_bird() -> void:
	var dark := _mat(Color(0.1, 0.11, 0.14))
	var glow := _mat_glow(Color(0.4, 0.8, 1.0))
	_box(_body, Vector3(0.16, 0.1, 0.24), Vector3(0, 0, 0), dark)      # pod
	_box(_body, Vector3(0.34, 0.02, 0.12), Vector3(0, 0.02, 0), glow)  # rotor/wing bar
	_box(_body, Vector3(0.05, 0.05, 0.02), Vector3(0, 0.0, 0.13), glow) # eye
	_body.position.y = BIRD_HOVER


# --- chatter ------------------------------------------------------------------

func _say(line: String) -> void:
	if _bubble == null:
		_bubble = Label3D.new()
		_bubble.font_size = 22
		_bubble.pixel_size = 0.01
		_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_bubble.outline_size = 7
		_bubble.modulate = Color(0.8, 0.9, 0.95, 0.95)
		_bubble.position = Vector3(0, 0.85, 0)
		add_child(_bubble)
	_bubble.text = line
	_bubble.visible = true
	get_tree().create_timer(1.8).timeout.connect(func() -> void:
		if is_instance_valid(_bubble):
			_bubble.visible = false)


func _pick_line() -> String:
	if kind == "bird":
		return ["bip", "▲▲", "scanning.", "♪", "...zzt"].pick_random()
	if kind == "rat":
		return ["skrrt", "tik tik", "...", "krrr", "squeak"].pick_random()
	return ["mrrp", "meow", "...", "prrr", "hsss"].pick_random()


# --- box kit ------------------------------------------------------------------

func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = mat
	m.mesh = bm
	m.position = pos
	parent.add_child(m)
	return m


func _mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.85
	return m


func _mat_glow(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 2.0
	return m
