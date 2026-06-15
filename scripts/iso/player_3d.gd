extends CharacterBody3D
## Isometric 3D player. Same input scheme as the 2D player (WASD/arrows or
## the HUD virtual joystick via GameState.touch_vector), moving on the ground
## plane in camera-relative space. The visual is the blocky char_player scene;
## only it rotates to face travel, the body itself never turns.
## Interaction mirrors player.gd: a reach volume tracks nearby Interactable3D
## areas, the nearest one owns the prompt, and interact() fires its Callable.

# Big City pass: districts are ~10x larger, so the base walk is faster to keep
# traversal from feeling tedious (boards still multiply on top, see _move_speed).
const SPEED := 5.0
const InteractableScript := preload("res://scripts/iso/interactable_3d.gd")

# The iso camera yaw is fixed at 45 deg; these map screen-space input axes
# onto the ground plane so "up" on the stick walks up the screen.
const SCREEN_RIGHT := Vector3(0.707107, 0, -0.707107)
const SCREEN_DOWN := Vector3(0.707107, 0, 0.707107)

var _near: Array = []          # Interactable3Ds currently in reach
var _current: Area3D = null

@onready var _visual: Node3D = $Visual
@onready var _anim: AnimationPlayer = $Visual/AnimationPlayer
var _board: MeshInstance3D
var _pet: Node3D


func _ready() -> void:
	add_to_group("player")  # wanderers look you up for recognition
	var reach := Area3D.new()
	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.0
	cs.shape = shape
	cs.position.y = 0.5
	reach.add_child(cs)
	add_child(reach)
	reach.area_entered.connect(_on_reach_entered)
	reach.area_exited.connect(_on_reach_exited)
	GameState.interact_requested.connect(try_interact)
	GameState.cosmetics_changed.connect(_apply_cosmetics)
	_apply_cosmetics()
	GameState.stats_changed.connect(_update_pet)
	_update_pet()


func _physics_process(_delta: float) -> void:
	var dir := Vector2.ZERO
	if not GameState.is_ui_locked():
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if dir == Vector2.ZERO:
			dir = GameState.touch_vector
		dir = dir.limit_length(1.0)
	var world := SCREEN_RIGHT * dir.x + SCREEN_DOWN * dir.y
	var spd := _move_speed()
	velocity = Vector3(world.x * spd, 0.0, world.z * spd)
	move_and_slide()
	var moving := world.length() > 0.05
	if moving:
		_visual.rotation.y = atan2(world.x, world.z)
	_update_board(moving)
	# On a board you glide (legs still) instead of walking.
	if moving and not _on_board():
		if _anim.current_animation != "walk":
			_anim.play("walk")
	elif _anim.current_animation != "idle":
		_anim.play("idle")
	_update_nearest()


# The active companion trails the player; it stays top-level so it is not yanked
# around by the player's own facing rotation.
func _update_pet() -> void:
	if not GameState.has_pet():
		if _pet != null:
			_pet.queue_free()
			_pet = null
		return
	if _pet != null and str(_pet.get_meta("pet_id", "")) != GameState.active_pet:
		_pet.queue_free()
		_pet = null
	if _pet == null and is_inside_tree():
		_pet = Node3D.new()
		_pet.set_script(preload("res://scripts/iso/pet_3d.gd"))
		add_child(_pet)
		_pet.set_meta("pet_id", GameState.active_pet)
		_pet.top_level = true  # ignore the player's transform; follow in world space
		_pet.global_position = global_position - Vector3(0.9, 0, 0.9)


func _on_board() -> bool:
	return GameState.owned("hoverboard") or GameState.owned("maglev_board")


func _move_speed() -> float:
	if GameState.owned("maglev_board"):
		return SPEED * 2.2
	if GameState.owned("hoverboard"):
		return SPEED * 1.6
	return SPEED


# The board materializes under you when owned and banks into turns. Built in
# code so it never touches the shared char_player scene.
func _update_board(moving: bool) -> void:
	if not _on_board():
		if _board:
			_board.visible = false
		return
	if _board == null:
		_board = MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.42, 0.06, 0.95)
		var mat := StandardMaterial3D.new()
		var glow := Color("7adfff") if GameState.owned("maglev_board") else Color("7ee787")
		mat.albedo_color = glow
		mat.emission_enabled = true
		mat.emission = glow
		mat.emission_energy_multiplier = 1.6
		bm.material = mat
		_board.mesh = bm
		_visual.add_child(_board)
	_board.visible = true
	_board.position.y = 0.07 + (0.04 if moving else 0.0)  # hovers higher when cruising
	_board.rotation.z = lerp_angle(_board.rotation.z, -0.25 if moving else 0.0, 0.2)


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


# Wardrobe parity with the 2D player's _draw: outfit tints the torso/arms,
# the hat slot toggles between the cap/beanie/crown meshes on the head.
# material_override keeps the shared BoxMesh resources untouched.
func _apply_cosmetics() -> void:
	var outfit_mat := StandardMaterial3D.new()
	outfit_mat.albedo_color = Color(GameState.cosmetic_color("outfit", "3c4454"))
	outfit_mat.roughness = 0.9
	for path in ["Visual/Body", "Visual/Body/ArmL", "Visual/Body/ArmR"]:
		(get_node(path) as MeshInstance3D).material_override = outfit_mat

	# Skin tone tints the head and hands (chosen at character creation).
	var skin_mat := StandardMaterial3D.new()
	skin_mat.albedo_color = Color(GameState.skin_tone)
	skin_mat.roughness = 0.9
	for path in ["Visual/Body/Head", "Visual/Body/ArmL/HandL", "Visual/Body/ArmR/HandR"]:
		var n := get_node_or_null(path)
		if n:
			(n as MeshInstance3D).material_override = skin_mat

	var head: Node3D = $Visual/Body/Head
	const HAT_NODES := ["Cap", "CapBrim", "CapLogo", "Beanie", "BeanieFold",
			"CrownBand", "CrownSpikeL", "CrownSpikeM", "CrownSpikeR"]
	for n in HAT_NODES:
		head.get_node(n).visible = false

	var style := GameState.cosmetic_style("hat")
	if style == "" or style == "none":
		return
	var hat_mat := StandardMaterial3D.new()
	hat_mat.albedo_color = Color(GameState.cosmetic_color("hat", "5a5f6e"))
	hat_mat.roughness = 0.85
	var shown: Array = []
	match style:
		"cap":
			shown = ["Cap", "CapBrim"]
			head.get_node("CapLogo").visible = true  # keeps its emissive trim
		"beanie":
			shown = ["Beanie", "BeanieFold"]
		"crown":
			shown = ["CrownBand", "CrownSpikeL", "CrownSpikeM", "CrownSpikeR"]
			hat_mat.emission_enabled = true
			hat_mat.emission = hat_mat.albedo_color
			hat_mat.emission_energy_multiplier = 1.2
	for n in shown:
		var mi: MeshInstance3D = head.get_node(n)
		mi.visible = true
		mi.material_override = hat_mat


func _on_reach_entered(area: Area3D) -> void:
	if area is InteractableScript:
		_near.append(area)


func _on_reach_exited(area: Area3D) -> void:
	_near.erase(area)


func _update_nearest() -> void:
	_near = _near.filter(is_instance_valid)
	var best: Area3D = null
	var best_dist := INF
	for a in _near:
		var d: float = global_position.distance_squared_to(a.global_position)
		if d < best_dist:
			best_dist = d
			best = a
	if best != _current:
		_current = best
		GameState.prompt_changed.emit(_current.prompt_text if _current else "")
