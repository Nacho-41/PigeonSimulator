extends SceneTree
# Renders a few screenshots (needs a display, e.g. xvfb-run).

func _shot(name: String) -> void:
	for i in 20:
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("/tmp/gd_" + name + ".png")

func _initialize() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	while not main.loaded:
		await process_frame
	await _shot("menu")
	main.start_game()
	var p = main.player
	await _shot("start")
	pass
	p.global_position = Vector3(20, 0.3, 10); p.yaw = 0.4; p.pitch = -0.35; p.cam_dist = 11.0
	for i in 4:
		main.spawn_kid()
	for k in main.kids:
		k.global_position = p.global_position + Vector3(randf_range(-6, 6), 0.2, randf_range(-6, 6))
	main.inv = 99.0
	await _shot("kids")
	main.egg_cd = 0.0
	main.egg_blast(false)
	for i in 10:
		await physics_frame
	await _shot("blast")
	for b in main.bottle_list.filter(func(b): return not b.gold).slice(0, 16):
		b.alive = true
		main._collect(b)
	main.inv = 0.0
	for k in main.kids:
		k.queue_free()
	main.kids.clear()
	p.global_position = Vector3(30, 0.3, 22); p.yaw = 0.6; p.pitch = -0.3
	await _shot("evo1")
	for b in main.bottle_list.filter(func(b): return not b.gold).slice(0, 30):
		b.alive = true
		main._collect(b)
	await _shot("evo2")
	main.bottles = 40
	main.open_shop()
	await _shot("shop")
	quit()
