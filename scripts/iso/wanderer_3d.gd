extends Node3D
## Ambient wanderer for the iso city: the 3D cousin of wanderer.gd.
## Attach to a character scene instance; it strolls between random points
## inside a rectangular patch, idling between trips, driving the character's
## built-in idle/walk animations. Idle moments sometimes produce a speech
## bubble — generic muttering, sweep-nerves when your heat is up, and
## starstruck recognition when somebody notorious walks past.

@export var area_center := Vector3.ZERO
@export var area_size := Vector2(5, 3)
@export var speed := 0.9
# Hoverboarder mode (G7): rides a glowing deck, glides (legs still) instead of
# walking, banks into turns, and barely pauses between trips.
@export var rider := false

var _target := Vector3.ZERO
var _wait := 0.0
var _bubble: Label3D
var _recognized := false
var _board: MeshInstance3D

@onready var _anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	_wait = randf_range(0.5, 3.0)
	if rider:
		_build_board()


func _process(delta: float) -> void:
	_check_recognition()
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			_pick_target()
			# Riders glide (legs still); walkers play the walk cycle.
			_anim.play("idle" if rider else "walk")
		return
	var to_target := _target - global_position
	to_target.y = 0.0
	if to_target.length() < 0.1:
		_wait = randf_range(0.3, 1.2) if rider else randf_range(1.5, 4.5)
		_anim.play("idle")
		if _board:
			_board.rotation.z = lerp_angle(_board.rotation.z, 0.0, 0.2)
		if randf() < 0.3:
			_say(_pick_line())
		return
	global_position += to_target.normalized() * minf(speed * delta, to_target.length())
	rotation.y = atan2(to_target.x, to_target.z)
	if _board:  # bank into the cruise
		_board.rotation.z = lerp_angle(_board.rotation.z, -0.22, 0.15)


# A glowing deck under the rider's feet, mirroring the player's board look.
func _build_board() -> void:
	_board = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.42, 0.06, 0.95)
	var mat := StandardMaterial3D.new()
	var glow := Color("7ee787")
	mat.albedo_color = glow
	mat.emission_enabled = true
	mat.emission = glow
	mat.emission_energy_multiplier = 1.4
	bm.material = mat
	_board.mesh = bm
	_board.position.y = 0.09
	add_child(_board)


func _pick_target() -> void:
	_target = area_center + Vector3(
		randf_range(-area_size.x * 0.5, area_size.x * 0.5),
		0.0,
		randf_range(-area_size.y * 0.5, area_size.y * 0.5)
	)


# --- street chatter ------------------------------------------------------------

func _say(line: String) -> void:
	if _bubble == null:
		_bubble = Label3D.new()
		_bubble.font_size = 26
		_bubble.pixel_size = 0.01
		_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_bubble.outline_size = 8
		_bubble.modulate = Color(0.85, 0.9, 0.95, 0.95)
		_bubble.position = Vector3(0, 1.65, 0)
		add_child(_bubble)
	_bubble.text = line
	_bubble.visible = true
	get_tree().create_timer(2.8).timeout.connect(func() -> void:
		if is_instance_valid(_bubble):
			_bubble.visible = false)


func _pick_line() -> String:
	if GameState.heat >= 80:
		return ["drones EVERYWHERE tonight...", "keep your head down.",
				"sweeps again. third night running."].pick_random()
	if GameState.heat_penalty() > 0.0:
		return ["lot of patrols lately, huh.", "saw a drone over the market...",
				"somebody's been busy. cops are twitchy."].pick_random()
	return ["nice night for it.", "...", "long day.",
			"these streets hum. you hear it?",
			"don't take the underpass at night.",
			"my landlord takes crypto now. ugh.",
			"the noodle place got a firewall??"].pick_random()


# Somebody notorious just walked past. Once per street life.
func _check_recognition() -> void:
	if _recognized or GameState.status_index() < 4:
		return
	var p := get_tree().get_first_node_in_group("player")
	if p == null or global_position.distance_to(p.global_position) > 2.0:
		return
	_recognized = true
	rotation.y = atan2(p.global_position.x - global_position.x,
			p.global_position.z - global_position.z)
	_say(["wait — is that %s?" % GameState.handle,
			"no way. it's really %s." % GameState.handle,
			"*whispers* that's %s, the %s..." % [GameState.handle, GameState.status_title()]].pick_random())