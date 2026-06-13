extends Node3D
## Byte — a salvaged robot-dog companion that trails the player across every
## district. Built entirely in code (blocky, glowing eyes), parented to the
## player so it survives district swaps. Lags behind with smoothing, bobs as
## it hovers, faces its travel direction, and yips occasionally.

const FOLLOW_DIST := 0.9
const SPEED := 4.5

var _t := 0.0
var _body: Node3D
var _bubble: Label3D
var _yip_at := 0.0


func _ready() -> void:
	_build()
	_yip_at = randf_range(8.0, 20.0)


func _build() -> void:
	_body = Node3D.new()
	add_child(_body)
	var dark := _mat(Color(0.09, 0.1, 0.13), false)
	var eye := _mat(Color(0.49, 0.91, 0.53), true)
	_box(_body, Vector3(0.26, 0.2, 0.4), Vector3(0, 0.28, 0), dark)        # torso
	_box(_body, Vector3(0.22, 0.2, 0.2), Vector3(0, 0.36, 0.28), dark)     # head
	_box(_body, Vector3(0.05, 0.05, 0.02), Vector3(-0.06, 0.38, 0.39), eye) # eyes
	_box(_body, Vector3(0.05, 0.05, 0.02), Vector3(0.06, 0.38, 0.39), eye)
	_box(_body, Vector3(0.04, 0.12, 0.04), Vector3(0, 0.46, -0.2), eye)    # antenna/tail
	for x in [-0.09, 0.09]:
		for z in [-0.13, 0.13]:
			_box(_body, Vector3(0.06, 0.18, 0.06), Vector3(x, 0.09, z), dark)  # legs


func _process(delta: float) -> void:
	_t += delta
	var player := get_parent() as Node3D
	if player == null:
		return
	# Trail a fixed distance behind the player's recent position.
	var to_me: Vector3 = global_position - player.global_position
	to_me.y = 0.0
	if to_me.length() > FOLLOW_DIST:
		var step: Vector3 = to_me.normalized() * (to_me.length() - FOLLOW_DIST)
		var move: Vector3 = step.limit_length(SPEED * delta)
		global_position -= move
		if move.length() > 0.001:
			_body.rotation.y = atan2(-move.x, -move.z)
	_body.position.y = sin(_t * 4.0) * 0.04  # hover bob

	_yip_at -= delta
	if _yip_at <= 0.0:
		_yip_at = randf_range(10.0, 25.0)
		_yip(["bark!", "bip.", "♪", "woof", "...boop"].pick_random())


func _yip(text: String) -> void:
	if _bubble == null:
		_bubble = Label3D.new()
		_bubble.font_size = 22
		_bubble.pixel_size = 0.01
		_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_bubble.outline_size = 7
		_bubble.modulate = Color(0.49, 0.91, 0.53)
		_bubble.position = Vector3(0, 0.8, 0)
		add_child(_bubble)
	_bubble.text = text
	_bubble.visible = true
	get_tree().create_timer(1.6).timeout.connect(func() -> void:
		if is_instance_valid(_bubble):
			_bubble.visible = false)


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = mat
	m.mesh = bm
	m.position = pos
	parent.add_child(m)


func _mat(col: Color, glow: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.7
	if glow:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 2.0
	return mat
