extends Node3D
## The active companion — trails the player across every district, parented to
## the player so it survives district swaps. Built entirely in code (blocky,
## glowing accents); each pet (dog/cat/bird/lizard) has its own silhouette and
## its GameData.PETS accent color, picked from the "pet_id" meta the player sets
## before adding it. Lags behind with smoothing, bobs as it hovers, faces its
## travel direction, and yips occasionally.

const FOLLOW_DIST := 0.9
const SPEED := 4.5

var _t := 0.0
var _body: Node3D
var _bubble: Label3D
var _yip_at := 0.0


func _ready() -> void:
	_build()
	_yip_at = randf_range(8.0, 20.0)


func _pet_id() -> String:
	return str(get_meta("pet_id", "dog"))


# The pet's GameData accent color (glow), falling back to the dog's cyan.
func _accent() -> Color:
	var p: Dictionary = GameData.PETS.get(_pet_id(), {})
	return Color(str(p.get("color", "7adfff")))


func _build() -> void:
	_body = Node3D.new()
	add_child(_body)
	match _pet_id():
		"cat": _build_cat()
		"bird": _build_bird()
		"lizard": _build_lizard()
		_: _build_dog()


# Byte — a four-legged robot dog: boxy torso, forward head, antenna tail.
func _build_dog() -> void:
	var dark := _mat(Color(0.09, 0.1, 0.13), false)
	var glow := _mat(_accent(), true)
	_box(_body, Vector3(0.26, 0.2, 0.4), Vector3(0, 0.28, 0), dark)        # torso
	_box(_body, Vector3(0.22, 0.2, 0.2), Vector3(0, 0.36, 0.28), dark)     # head
	_box(_body, Vector3(0.05, 0.05, 0.02), Vector3(-0.06, 0.38, 0.39), glow) # eyes
	_box(_body, Vector3(0.05, 0.05, 0.02), Vector3(0.06, 0.38, 0.39), glow)
	_box(_body, Vector3(0.04, 0.12, 0.04), Vector3(0, 0.46, -0.2), glow)   # antenna/tail
	for x in [-0.09, 0.09]:
		for z in [-0.13, 0.13]:
			_box(_body, Vector3(0.06, 0.18, 0.06), Vector3(x, 0.09, z), dark)  # legs


# Null — a sleek shadow cat: low slim torso, pointed ears, upright curl tail.
func _build_cat() -> void:
	var fur := _mat(Color(0.12, 0.1, 0.16), false)
	var glow := _mat(_accent(), true)
	_box(_body, Vector3(0.2, 0.16, 0.42), Vector3(0, 0.24, 0), fur)        # sleek torso
	_box(_body, Vector3(0.18, 0.17, 0.17), Vector3(0, 0.32, 0.27), fur)    # head
	_box(_body, Vector3(0.05, 0.09, 0.04), Vector3(-0.06, 0.43, 0.27), fur)  # ears
	_box(_body, Vector3(0.05, 0.09, 0.04), Vector3(0.06, 0.43, 0.27), fur)
	_box(_body, Vector3(0.045, 0.03, 0.02), Vector3(-0.05, 0.34, 0.36), glow)  # slit eyes
	_box(_body, Vector3(0.045, 0.03, 0.02), Vector3(0.05, 0.34, 0.36), glow)
	_box(_body, Vector3(0.05, 0.2, 0.05), Vector3(0, 0.32, -0.22), fur)    # upright tail
	_box(_body, Vector3(0.05, 0.05, 0.09), Vector3(0, 0.42, -0.24), glow)  # tail tip
	for x in [-0.07, 0.07]:
		for z in [-0.14, 0.14]:
			_box(_body, Vector3(0.045, 0.16, 0.045), Vector3(x, 0.08, z), fur)  # slim legs


# Cache — a courier drone bird: compact body floating high on rotor wings, beak.
func _build_bird() -> void:
	var dark := _mat(Color(0.1, 0.11, 0.13), false)
	var glow := _mat(_accent(), true)
	_box(_body, Vector3(0.2, 0.16, 0.3), Vector3(0, 0.52, 0), dark)        # body (raised: hovers)
	_box(_body, Vector3(0.12, 0.12, 0.12), Vector3(0, 0.58, 0.2), dark)    # head
	_box(_body, Vector3(0.06, 0.04, 0.1), Vector3(0, 0.57, 0.31), glow)    # beak
	_box(_body, Vector3(0.04, 0.04, 0.02), Vector3(-0.04, 0.6, 0.27), glow)  # eyes
	_box(_body, Vector3(0.04, 0.04, 0.02), Vector3(0.04, 0.6, 0.27), glow)
	_box(_body, Vector3(0.26, 0.03, 0.14), Vector3(-0.22, 0.54, 0), glow)  # rotor wings
	_box(_body, Vector3(0.26, 0.03, 0.14), Vector3(0.22, 0.54, 0), glow)
	_box(_body, Vector3(0.05, 0.1, 0.12), Vector3(0, 0.52, -0.2), dark)    # tail fin


# Glitch — a thermal lizard: long low body, glowing spine stripe, tapering tail.
func _build_lizard() -> void:
	var skin := _mat(Color(0.1, 0.13, 0.1), false)
	var glow := _mat(_accent(), true)
	_box(_body, Vector3(0.2, 0.1, 0.4), Vector3(0, 0.1, 0), skin)          # long low body
	_box(_body, Vector3(0.16, 0.08, 0.16), Vector3(0, 0.1, 0.27), skin)    # flat head
	_box(_body, Vector3(0.03, 0.02, 0.02), Vector3(-0.05, 0.12, 0.34), glow)  # eyes
	_box(_body, Vector3(0.03, 0.02, 0.02), Vector3(0.05, 0.12, 0.34), glow)
	_box(_body, Vector3(0.04, 0.03, 0.34), Vector3(0, 0.16, 0), glow)      # thermal spine stripe
	_box(_body, Vector3(0.1, 0.07, 0.16), Vector3(0, 0.09, -0.26), skin)   # tail base
	_box(_body, Vector3(0.06, 0.05, 0.14), Vector3(0, 0.08, -0.4), skin)   # tail mid
	_box(_body, Vector3(0.03, 0.03, 0.12), Vector3(0, 0.07, -0.52), glow)  # tail tip
	for x in [-0.13, 0.13]:
		for z in [-0.1, 0.12]:
			_box(_body, Vector3(0.05, 0.06, 0.05), Vector3(x, 0.04, z), skin)  # splayed legs


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
		_yip(_voice().pick_random())


# Per-pet chatter so the companions read as different creatures, not just shapes.
func _voice() -> Array:
	match _pet_id():
		"cat": return ["mrrp.", "...", "purr", "hiss", "♪"]
		"bird": return ["chirp!", "tweet", "♪", "beep-beep", "caw"]
		"lizard": return ["sss.", "...", "click", "hsss", "▮"]
		_: return ["bark!", "bip.", "♪", "woof", "...boop"]


func _yip(text: String) -> void:
	if _bubble == null:
		_bubble = Label3D.new()
		_bubble.font_size = 22
		_bubble.pixel_size = 0.01
		_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_bubble.outline_size = 7
		_bubble.modulate = _accent()
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
