extends SceneTree
# Headless smoke test: boots the game, plays a few seconds, prints what happened.

func _initialize() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	while not main.loaded:
		await process_frame
	var g := main
	print("state=", g.state, " bottles placed=", g.bottle_list.filter(func(b): return b.alive).size())
	g.start_game()
	var p: CharacterBody3D = g.player
	print("player at ", p.global_position)
	Input.action_press("move_forward")
	for i in 90:
		await physics_frame
	Input.action_release("move_forward")
	print("after walking: ", p.global_position, " on floor=", p.is_on_floor())
	p.do_jump()
	for i in 8:
		await physics_frame
	var y1 := p.global_position.y
	p.do_jump()
	for i in 4:
		await physics_frame
	print("jump y=", y1, " double jump y=", p.global_position.y, " egg_cd=", g.egg_cd)
	for i in 5:
		g.spawn_kid()
	for k in g.kids:
		k.global_position = p.global_position + Vector3(randf_range(-8, 8), 0.2, randf_range(-8, 8))
	g.inv = 0.0
	for i in 240:
		await physics_frame
	print("kids=", g.kids.size(), " states=", g.kids.map(func(k): return k.state), " lives=", g.lives, " projectiles=", g.projectiles.size())
	g.egg_cd = 0.0
	for k in g.kids:
		k.global_position = p.global_position + Vector3(2, 0.2, 1)
	await physics_frame
	g.egg_blast(false)
	for i in 30:
		await physics_frame
	print("after blast states=", g.kids.map(func(k): return k.state), " launched=", g.launched)
	var path: PackedVector2Array = g.find_path(Vector3(-100, 0, 200), p.global_position)
	print("path len=", path.size())
	g.bottles = 50
	g.open_shop()
	g.buy(0); g.buy(2); g.buy(3)
	print("shop: bottles=", g.bottles, " levels=", g.levels, " state=", g.state)
	g.close_shop()
	var gb: Dictionary = g.bottle_list.filter(func(b): return b.gold)[0]
	g._collect(gb)
	print("buff=", g.buff, " bottles=", g.bottles)
	for b in g.bottle_list.filter(func(b): return not b.gold).slice(0, 45):
		b.alive = true
		g._collect(b)
	print("evo=", g.evo, " name=", g.EVO[g.evo].name, " scale=", g.player.scale_now, " model=", g.player.model.name)
	g.buff = ""
	g.inv = 99.0
	g.boss_timer = 0.01
	for i in 5:
		await physics_frame
	print("boss spawned=", g.boss != null)
	for i in 120:
		await physics_frame
	print("boss state=", g.boss.state, " hp=", g.boss.hp, " pos=", g.boss.global_position, " projectiles=", g.projectiles.size())
	for i in 20:
		g.boss.global_position = p.global_position + Vector3(4, 0, 0)
		g.egg_cd = 0.0
		g.egg_blast(false)
		await physics_frame
	print("boss hp after eggs=", g.boss.hp if is_instance_valid(g.boss) else -1, " done=", g.boss_done)
	for i in 200:
		await process_frame
	await create_timer(2.5).timeout
	print("state after win=", g.state)
	g.continue_after_win()
	g.inv = 0.0; g.hurt_pigeon(Vector3.ZERO); g.inv = 0.0; g.hurt_pigeon(Vector3.ZERO); g.inv = 0.0; g.hurt_pigeon(Vector3.ZERO)
	for i in 150:
		await process_frame
	print("final state=", g.state, " lives=", g.lives)
	quit()
