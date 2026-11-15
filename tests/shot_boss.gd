extends SceneTree
func _initialize() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	while not main.loaded:
		await process_frame
	main.start_game()
	main.inv = 99.0
	var p = main.player
	p.yaw = 0.6
	main.spawn_boss()
	main.boss.global_position = p.global_position + Vector3(-9, 20, -12)
	for i in 150:
		await physics_frame
	main.boss.hit(3)
	for i in 30:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/gd_boss.png")
	quit()
