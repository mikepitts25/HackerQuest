extends Node3D
## Local mesh animation only: no particles, extra lights, or gameplay timers.
@export_enum("none", "steam", "fan", "screen", "arcade", "repair") var motion := "none"
var _time := 0.0
var _parts: Array[Node3D] = []

func set_accent(color: Color) -> void:
	for path in ["Canopy", "FrontPanel", "CanopyTrim"]:
		var mesh := get_node_or_null(path) as MeshInstance3D
		if mesh:
			var material := mesh.mesh.material.duplicate() as StandardMaterial3D
			material.albedo_color = color
			if material.emission_enabled:
				material.emission = color
			mesh.material_override = material

func _ready() -> void:
	add_to_group("city_prop")
	for part in ["Steam0", "Steam1", "Steam2"] if motion == "steam" else ["Fan", "Screen", "Arm", "Pixel0", "Pixel1", "Pixel2", "Pixel3", "Pixel4"]:
		var node := get_node_or_null(part) as Node3D
		if node:
			_parts.append(node)
	set_process(motion != "none")

func _process(delta: float) -> void:
	_time += delta
	match motion:
		"steam":
			for i in _parts.size():
				var t := fmod(_time * 0.45 + i / 3.0, 1.0)
				_parts[i].position.y = 2.38 + t * 0.6
				_parts[i].position.x = -0.5 + sin(_time + i) * 0.09
				_parts[i].scale = Vector3.ONE * (0.6 + t * 0.8)
				(_parts[i] as MeshInstance3D).transparency = 0.35 + t * 0.65
		"fan":
			if not _parts.is_empty():
				_parts[0].rotation.z += delta * 2.8
		"repair":
			var arm := get_node_or_null("Arm") as Node3D
			if arm:
				arm.rotation.y = sin(_time * 0.7) * 0.45
		"screen":
			var screen := get_node_or_null("Screen") as Node3D
			if screen:
				screen.scale.x = 0.96 + sin(_time * 1.5) * 0.04
		"arcade":
			for part in _parts:
				if part.name.begins_with("Pixel"):
					part.position.y = 1.19 + sin(_time * 1.6 + float(str(part.name).right(1))) * 0.10
