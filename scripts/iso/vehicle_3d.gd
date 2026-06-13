extends Node3D
## Ambient traffic for the iso city (G7). A blocky vehicle that drives a fixed
## lane — a polyline of XZ waypoints in district meters — and loops back to the
## start when it reaches the end. Pure flavor: no collision, never blocks the
## player. Lanes are usually a rectangular ring just outside the playable area
## (see district_3d._ring_road), so the wrap from the last point to the first is
## a continuous loop rather than a visible teleport.
##
## Built in code (like the player's board) so it needs no scene of its own. The
## low body + cabin slab + two emissive headlights read as a car at city scale.

var path: PackedVector2Array
var speed := 3.0

var _seg := 1   # index of the waypoint we're driving toward
var _len := 0
var _y := 0.25  # body sits low on the ground plane


# Lay out the car and drop it onto the first waypoint, heading to the second.
func setup(p_path: PackedVector2Array, p_speed: float, color: Color) -> void:
	path = p_path
	speed = p_speed
	_len = path.size()
	_build_body(color)
	if _len > 0:
		position = Vector3(path[0].x, 0, path[0].y)
	_seg = 1 % maxi(_len, 1)


# Pre-drive the car `dist` meters along the loop so a lane's cars start spread
# out instead of stacked on the first waypoint.
func skip_ahead(dist: float) -> void:
	var remaining := dist
	var guard := 0
	while remaining > 0.0 and _len >= 2 and guard < _len * 4:
		guard += 1
		var target := Vector3(path[_seg].x, position.y, path[_seg].y)
		var to := target - position
		to.y = 0.0
		var d := to.length()
		if d <= remaining:
			position = target
			remaining -= d
			_seg = (_seg + 1) % _len
		else:
			position += to.normalized() * remaining
			rotation.y = atan2(to.x, to.z)
			remaining = 0.0


func _process(delta: float) -> void:
	if _len < 2:
		return
	var target := Vector3(path[_seg].x, position.y, path[_seg].y)
	var to := target - position
	to.y = 0.0
	var step := speed * delta
	if to.length() <= step:
		position = target
		_seg = (_seg + 1) % _len
	else:
		position += to.normalized() * step
		rotation.y = atan2(to.x, to.z)


func _build_body(color: Color) -> void:
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.7, 0.32, 1.6)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5
	mat.metallic = 0.3
	bm.material = mat
	body.mesh = bm
	body.position.y = _y
	add_child(body)

	var cabin := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.6, 0.26, 0.8)
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.06, 0.07, 0.1)
	cmat.roughness = 0.2
	cm.material = cmat
	cabin.mesh = cm
	cabin.position = Vector3(0, _y + 0.26, -0.05)
	add_child(cabin)

	# Two headlights up front (+z is the nose; rotation.y aims it down the lane).
	for sx in [-0.22, 0.22]:
		var lamp := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.12, 0.1, 0.06)
		var lmat := StandardMaterial3D.new()
		lmat.albedo_color = Color(1, 0.95, 0.8)
		lmat.emission_enabled = true
		lmat.emission = Color(1, 0.95, 0.8)
		lmat.emission_energy_multiplier = 2.2
		lm.material = lmat
		lamp.mesh = lm
		lamp.position = Vector3(sx, _y, 0.82)
		add_child(lamp)
