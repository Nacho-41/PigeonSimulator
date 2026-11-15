extends CharacterBody3D
## The final boss: the picture in ui/boss.png, standing in the city and always facing the camera.
## It walks towards the pigeon, stomps (a shock wave on the ground: jump to dodge it)
## and blows kisses (slow projectiles). Egg blasts hurt it. All numbers are on the Game node.

var game: Node
var sprite: Sprite3D
var hp := 12
var max_hp := 12
var state := "intro"     # intro / walk / stomp / dead
var t := 0.0
var stomp_cd := 4.0
var kiss_cd := 3.0
var flash := 0.0
var path: PackedVector2Array = PackedVector2Array()
var path_i := 0
var repath := 0.0
var height := 8.0


func setup(g: Node) -> void:
	game = g
	max_hp = g.viata_boss
	hp = max_hp
	height = g.inaltime_boss
	stomp_cd = g.pauza_calcat_boss
	kiss_cd = g.pauza_pupic_boss


func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	sprite = Sprite3D.new()
	sprite.texture = game.imagine_boss
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y   # always faces the camera, stays upright
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.shaded = false
	sprite.double_sided = true
	var tex_h: float = game.imagine_boss.get_height()
	sprite.pixel_size = height / tex_h
	sprite.position.y = height * 0.5
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(sprite)
	var c := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = height * 0.2
	cap.height = height * 0.9
	c.shape = cap
	c.position.y = height * 0.45
	add_child(c)
	velocity = Vector3(0, -18, 0)


func radius() -> float:
	return height * 0.22


func hit(dmg: int) -> void:
	if state == "dead" or state == "intro":
		return
	hp = max(0, hp - dmg)
	flash = 0.35
	game.play_sfx(game.sunet_boss_lovit)
	game.puff(global_position + Vector3.UP * height * 0.6, 14, Color("ff8a6a"))
	if hp <= 0:
		state = "dead"
		t = 0.0
		game.boss_defeated()


func _physics_process(dt: float) -> void:
	if game == null or not (game.state == "play" or game.state == "dying"):
		return
	t += dt
	flash = max(0.0, flash - dt)
	sprite.modulate = Color(1, 0.55, 0.55) if flash > 0.0 and int(flash * 20.0) % 2 == 0 else Color.WHITE
	match state:
		"intro":
			_intro(dt)
		"walk":
			_walk(dt)
		"stomp":
			_stomp(dt)
		"dead":
			_dead(dt)


func _intro(dt: float) -> void:
	# falls from the sky and lands with a shock wave
	velocity.y -= 30.0 * dt
	move_and_slide()
	if is_on_floor():
		state = "walk"
		t = 0.0
		_shock(game.raza_calcat_boss * 1.3)


func _walk(dt: float) -> void:
	var p: Node3D = game.player
	var to: Vector3 = p.global_position - global_position
	var flat := Vector2(to.x, to.z)
	var dist := flat.length()
	var dir := Vector2.ZERO
	repath -= dt
	if dist < 14.0:
		dir = flat.normalized()
	else:
		if repath <= 0.0:
			repath = 0.8
			path = game.find_path(global_position, p.global_position)
			path_i = 0
		while path_i < path.size() and Vector2(global_position.x, global_position.z).distance_to(path[path_i]) < 2.5:
			path_i += 1
		if path_i < path.size():
			dir = (path[path_i] - Vector2(global_position.x, global_position.z)).normalized()
	var spd: float = game.viteza_boss
	velocity.x = lerp(velocity.x, dir.x * spd, 1.0 - exp(-7.0 * dt))
	velocity.z = lerp(velocity.z, dir.y * spd, 1.0 - exp(-7.0 * dt))
	velocity.y -= 30.0 * dt
	move_and_slide()
	# waddle: a little hop and sway while walking
	var bob: float = abs(sin(t * (3.0 + spd * 0.6))) * 0.25 * min(1.0, Vector2(velocity.x, velocity.z).length() / max(spd, 0.1))
	sprite.position.y = height * 0.5 + bob
	sprite.rotation.z = sin(t * (3.0 + spd * 0.6)) * 0.06
	# touching the boss hurts
	if dist < radius() + 0.6 * p.scale_now and abs(to.y) < height * 0.8:
		game.hurt_pigeon(global_position, true)
	stomp_cd -= dt
	kiss_cd -= dt
	if stomp_cd <= 0.0 and dist < game.raza_calcat_boss * 1.5:
		state = "stomp"
		t = 0.0
		velocity = Vector3.ZERO
	elif kiss_cd <= 0.0 and dist < 40.0:
		kiss_cd = game.pauza_pupic_boss
		_kiss()


func _stomp(dt: float) -> void:
	# crouch, jump, land: the shock wave hurts the pigeon if it is on the ground nearby
	if t < 0.6:
		sprite.scale = Vector3(1.0 + t * 0.25, 1.0 - t * 0.3, 1.0)
		return
	if t < 0.65:
		sprite.scale = Vector3.ONE
		velocity.y = 11.0
	velocity.y -= 30.0 * dt
	move_and_slide()
	if is_on_floor() and t > 0.8:
		_shock(game.raza_calcat_boss)
		stomp_cd = game.pauza_calcat_boss
		state = "walk"
		t = 0.0


func _shock(r: float) -> void:
	game.boss_shockwave(global_position, r)


func _kiss() -> void:
	var p: Node3D = game.player
	var src := global_position + Vector3.UP * height * 0.72
	var tgt: Vector3 = p.center()
	var v: Vector3 = (tgt - src).normalized() * game.viteza_pupic_boss
	game.spawn_projectile(src, v, "kiss", 0.0, 0.0, self)
	game.play_sfx(game.sunet_boss_pupic)


func _dead(dt: float) -> void:
	# tips over and sinks into the ground
	sprite.rotation.z = min(t * 1.5, PI * 0.5)
	sprite.position.y = height * 0.5 - t * 1.5
	sprite.modulate.a = max(0.0, 1.0 - t * 0.4)
	if t > 2.6:
		queue_free()
