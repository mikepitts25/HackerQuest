extends SceneTree
## Render the eight real mesh assets together; this never resets player state.

func _initialize() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1400, 1000)
	root.content_scale_size = Vector2i(1400, 1000)
	call_deferred("run")

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0c1425")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a5bedb")
	env.ambient_light_energy = 0.8
	env.glow_enabled = true
	environment.environment = env
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -25, 0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	world.add_child(sun)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = 18.5
	world.add_child(camera)
	camera.position = Vector3(6.0, 12, 19)
	camera.look_at(Vector3(0, 0.4, 0))
	var models := ["vending_machine", "noodle_cart", "arcade_cabinet", "transit_shelter", "repair_bench", "cargo_stack", "utility_cabinet", "rooftop_aircon"]
	for i in models.size():
		var model: Node3D = load("res://assets/iso/props/city/prop_%s.tscn" % models[i]).instantiate()
		world.add_child(model)
		model.position = Vector3(-6.0 + (i % 4) * 4.0, 0, -2.8 + (i / 4) * 5.6)
		var label := Label3D.new()
		label.text = str(models[i]).replace("_", " ").to_upper()
		label.no_depth_test = true
		label.font_size = 30
		label.pixel_size = 0.006
		label.outline_size = 3
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = model.position + Vector3(0, 0.15, 1.65)
		world.add_child(label)
		var platform := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(3.6, 0.10, 2.8)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("1d293d")
		box.material = mat
		platform.mesh = box
		platform.position = model.position + Vector3(0, -0.08, 0)
		world.add_child(platform)
	await create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/hackerquest-city-models.png")
	world.queue_free()
	await process_frame
	print("CITY MODELS PREVIEW PASSED")
	quit()
