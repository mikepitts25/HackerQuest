extends Node3D
## Bounded, deterministic street dressing. No collision, full-screen effects,
## shadow-casting lights, or gameplay RNG consumption.

const Cache := preload("res://scripts/street_cache.gd")
const PALETTES := {
	"plaza": [Color("58e5d0"), Color("ffbe70")],
	"market": [Color("ff78bd"), Color("ffc36a")],
	"underpass": [Color("85b6ff"), Color("bc8aff")],
	"corp_row": [Color("69dfff"), Color("a8c5ed")],
	"darknet": [Color("ba85ff"), Color("ff538f")],
}

func build(district: Node3D, district_id: String, bounds: Vector2) -> void:
	if not PALETTES.has(district_id):
		return
	var colors: Array = PALETTES[district_id]
	# Inset perimeter channels give each district a recognizable color signature.
	for x in [2.0, bounds.x - 2.0]:
		box(Vector3(x, 0.045, bounds.y / 2), Vector3(0.06, 0.025, bounds.y - 5), colors[0], true)
	for z in [2.0, bounds.y - 2.0]:
		box(Vector3(bounds.x / 2, 0.045, z), Vector3(bounds.x - 5, 0.025, 0.06), colors[1], true)
	# Pavement seams and maintenance plates break up the large flat ground.
	for i in range(1, int(bounds.x / 4)):
		box(Vector3(i * 4, 0.027, bounds.y / 2), Vector3(0.018, 0.008, bounds.y - 4), Color("141c29"))
	for i in range(1, int(bounds.y / 4)):
		box(Vector3(bounds.x / 2, 0.028, i * 4), Vector3(bounds.x - 4, 0.008, 0.018), Color("141c29"))
	for i in 8:
		var p := Vector3(4 + fmod(i * 11.7, bounds.x - 8), 0.04, 4 + fmod(i * 7.3, bounds.y - 8))
		box(p, Vector3(1.1, 0.015, 0.65), Color("252e40"))
		for j in 4:
			box(p + Vector3(-0.35 + j * 0.23, 0.015, 0), Vector3(0.07, 0.01, 0.45), Color("101522"))
	# Four small pools of colored light; no shadows, tightly limited range.
	for i in 4:
		var light := OmniLight3D.new()
		light.position = Vector3(bounds.x * (0.22 if i % 2 == 0 else 0.78), 2.2, bounds.y * (0.24 if i < 2 else 0.76))
		light.light_color = colors[i % 2]
		light.light_energy = 1.5
		light.omni_range = 7.0
		add_child(light)
	if Cache.LOCATIONS.has(district_id):
		_add_cache(district, district_id, colors[0])

func box(pos: Vector3, dimensions: Vector3, color: Color, glow := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.72
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.4
	mesh.material = mat
	node.mesh = mesh
	node.position = pos
	add_child(node)
	return node

func _add_cache(district: Node3D, district_id: String, color: Color) -> void:
	var p: Vector2 = Cache.LOCATIONS[district_id]
	var marker := Node3D.new()
	marker.position = Vector3(p.x, 0, p.y)
	add_child(marker)
	var base := box(Vector3(p.x, 0.13, p.y), Vector3(0.7, 0.26, 0.7), Color("182737"))
	# Reparent while preserving local transforms for spent-state dimming.
	base.reparent(marker)
	var packet := box(Vector3(p.x, 0.85, p.y), Vector3(0.28, 0.28, 0.28), color, true)
	packet.reparent(marker)
	packet.rotation_degrees = Vector3(25, 45, 25)
	var spent: bool = GameState.trash_searched.has("signal_cache:" + district_id)
	var label: Label3D = district._sign("SIGNAL CACHE" if not spent else "DOWNLOADED", p, 1.45, 24)
	var area: Area3D = district._interact(marker, "Signal downloaded · return tomorrow" if spent else "Download signal · $18 / 1 energy", Vector3(0.9, 1.0, 0.9),
		func() -> void:
			if Cache.claim(GameState, district_id):
				Audio.sfx("search")
				packet.hide()
				label.text = "DOWNLOADED"
				for child in marker.get_children():
					if child is Area3D:
						child.prompt_text = "Signal downloaded · return tomorrow"
						GameState.prompt_changed.emit(child.prompt_text))
	area.add_to_group("signal_cache")
	packet.visible = not spent
	var tween := create_tween().set_loops()
	tween.tween_property(packet, "position:y", 1.05, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(packet, "position:y", 0.85, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
