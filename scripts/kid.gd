extends CharacterBody3D
## A kid chasing the pigeon with a toy weapon: "sling" (pebbles), "water" (water pistol) or "net".
## Hit by the egg blast, the kid flies away in low gravity, lands and stays dazed for a moment.

const LOW_GRAVITY := 5.5
const GRAVITY := 24.0

var game: Node
var weapon := "sling"
var model: Node3D
var parts := {}
var state := "chase"      # chase / fly / dazed
var t := 0.0
var cooldown := 2.0
var windup := 0.0
var lunge := 0.0
var speed := 4.8
var yaw := 0.0
var walk := 0.0
var spin := 0.0
var path: PackedVector2Array = PackedVector2Array()
var path_i := 0
var repath := 0.0


func setup(g: Node, w: String, variant: int) -> void:
	game = g
	weapon = w
	speed = g.viteza_copii * randf_range(0.9, 1.1)
	cooldown = randf_range(1.0, 3.0)
	repath = randf() * 0.6


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	floor_max_angle = deg_to_rad(50.0)
	model = load("res://assets/kid_%s_%d.glb" % [weapon, randi() % 3]).instantiate()
	model.scale = Vector3.ONE * game.marime_copii
	add_child(model)
	for n in ["head", "legL", "legR", "armL", "armR"]:
		parts[n] = model.find_child(n, true, false)
	var c := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	var m: float = game.marime_copii
	cap.radius = 0.3 * m
	cap.height = 1.45 * m
	c.shape = cap
	c.position.y = 0.73 * m
	add_child(c)


func launch(dir: Vector3, power: float) -> void:
	state = "fly"
	t = 0.0
	velocity = Vector3(dir.x * (6.0 + 7.0 * power), 5.5 + 4.0 * power, dir.z * (6.0 + 7.0 * power))
	spin = randf_range(2.0, 3.5) * (1.0 if randf() < 0.5 else -1.0)
	game.launched += 1
	game.play_sfx(game.sunet_copil_aruncat, 0.15)
	game.puff(global_position + Vector3.UP * 0.8, 6, Color(0.97, 0.95, 0.89))


func _physics_process(dt: float) -> void:
	if game == null or not (game.state == "play" or game.state == "dying"):
		return
	t += dt
	cooldown -= dt
	match state:
		"fly":
			_fly(dt)
		"dazed":
			_dazed(dt)
		_:
			_chase(dt)


func _fly(dt: float) -> void:
	velocity.y -= game.gravitatie_zbor_copii * dt
	move_and_slide()
	model.rotation.x += spin * dt
	model.rotation.z += spin * 0.6 * dt
	if is_on_floor() and velocity.y <= 0.0 and t > 0.2:
		state = "dazed"
		t = 0.0
		velocity = Vector3.ZERO
		model.rotation = Vector3(0, yaw, 0)
		game.puff(global_position + Vector3.UP * 0.1, 6, Color(0.81, 0.78, 0.72))


func _dazed(_dt: float) -> void:
	model.rotation = Vector3(sin(t * 9.0) * 0.12, yaw + sin(t * 3.0) * 0.5, cos(t * 9.0) * 0.12)
	if parts["head"]:
		parts["head"].rotation.z = sin(t * 6.0) * 0.3
	velocity.x = 0
	velocity.z = 0
	velocity.y -= GRAVITY * _dt
	move_and_slide()
	if t > game.secunde_ameteala:
		state = "chase"
		cooldown = randf_range(0.8, 1.6)
		if parts["head"]:
			parts["head"].rotation.z = 0.0


func _chase(dt: float) -> void:
	var p: Node3D = game.player
	var to: Vector3 = p.global_position - global_position
	var flat := Vector2(to.x, to.z)
	var dist := flat.length()
	var range_m: float = game.plasa_raza if weapon == "net" else (game.apa_raza if weapon == "water" else game.prastie_raza)
	var sees: bool = game.line_of_sight(global_position + Vector3.UP * 1.15, p.center(), self)
	# steering: straight at the pigeon when close and visible, otherwise follow the grid path
	var dir := Vector2.ZERO
	var on_roof: bool = p.global_position.y - global_position.y > 2.0
	repath -= dt
	if dist < 7.0 and sees and not on_roof:
		dir = flat.normalized()
	else:
		if repath <= 0.0:
			repath = 0.6
			path = game.find_path(global_position, p.global_position)
			path_i = 0
		while path_i < path.size() and Vector2(global_position.x, global_position.z).distance_to(path[path_i]) < 1.2:
			path_i += 1
		if path_i < path.size():
			dir = (path[path_i] - Vector2(global_position.x, global_position.z)).normalized()
	var stop := weapon != "net" and dist < range_m * 0.7 and sees
	if lunge > 0.0:
		lunge -= dt
	else:
		var v := Vector2.ZERO if stop else dir * speed
		for o in game.kids:
			if o == self:
				continue
			var d: Vector3 = global_position - o.global_position
			var dl := Vector2(d.x, d.z).length()
			if dl < 1.2 and dl > 0.001:
				v += Vector2(d.x, d.z) / dl * 3.0
		var k := 1.0 - exp(-8.0 * dt)
		velocity.x = lerp(velocity.x, v.x, k)
		velocity.z = lerp(velocity.z, v.y, k)
	velocity.y -= GRAVITY * dt
	move_and_slide()
	# facing + walk cycle
	var sp := Vector2(velocity.x, velocity.z).length()
	var face_to := yaw
	if dist < 18.0:
		face_to = atan2(to.x, to.z)
	elif sp > 0.3:
		face_to = atan2(velocity.x, velocity.z)
	yaw = lerp_angle(yaw, face_to, 1.0 - exp(-8.0 * dt))
	model.rotation = Vector3(0, yaw, 0)
	walk += sp * dt * 2.4
	if parts["legL"]:
		var a: float = sin(walk) * 0.8 * min(1.0, sp / 4.0)
		parts["legL"].rotation.x = a
		parts["legR"].rotation.x = -a
		parts["armL"].rotation.x = -a * 0.8
	# attack
	if windup > 0.0:
		windup -= dt
		if parts["armR"]:
			parts["armR"].rotation.x = -1.5
		if windup <= 0.0:
			_fire()
			cooldown = randf_range(game.plasa_pauza_minima, game.plasa_pauza_maxima) if weapon == "net" else (randf_range(game.apa_pauza_minima, game.apa_pauza_maxima) if weapon == "water" else randf_range(game.prastie_pauza_minima, game.prastie_pauza_maxima))
	elif parts["armR"]:
		parts["armR"].rotation.x = lerp(parts["armR"].rotation.x, -0.6 if weapon == "net" else -0.9, 1.0 - exp(-6.0 * dt))
	if cooldown <= 0.0 and windup <= 0.0 and dist < range_m and sees and game.state == "play":
		windup = 0.2 if weapon == "net" else game.secunde_pregatire_atac
	if lunge > 0.0 and dist < 1.4 * game.marime_copii + 0.3 * p.scale_now and abs(p.global_position.y - global_position.y) < 1.4:
		game.hurt_pigeon(global_position)
		lunge = 0.0


func _fire() -> void:
	var p: Node3D = game.player
	var src: Vector3 = global_position + Vector3.UP * 1.15 * game.marime_copii
	var tgt: Vector3 = p.center() + Vector3(p.velocity.x, 0, p.velocity.z) * 0.25 * game.anticipare_tinta_copii
	# ținta proastă: fiecare tragere nimerește un punct la întâmplare în jurul porumbelului
	var miss: Vector2 = Vector2.from_angle(randf() * TAU) * sqrt(randf()) * game.greseala_tinta_copii
	tgt += Vector3(miss.x, randf_range(-0.4, 0.6) * game.greseala_tinta_copii * 0.5, miss.y)
	if weapon == "net":
		lunge = 0.3
		var d: Vector2 = Vector2(tgt.x - src.x, tgt.z - src.z).normalized() * game.plasa_viteza_salt
		velocity.x = d.x
		velocity.z = d.y
		return
	var n: int = game.apa_picaturi_pe_tragere if weapon == "water" else 1
	var spd: float = game.apa_viteza_picaturi if weapon == "water" else game.prastie_viteza_pietricica
	var grav := 7.0 if weapon == "water" else 9.8
	var flat := Vector2(tgt.x - src.x, tgt.z - src.z).length()
	var tt: float = max(flat / spd, 0.05)
	for i in n:
		var spread := (0.08 if weapon == "water" else 0.05) * spd
		var v := Vector3((tgt.x - src.x) / tt + randf_range(-1, 1) * spread,
			(tgt.y - src.y) / tt + 0.5 * grav * tt + randf_range(-1, 1) * spread,
			(tgt.z - src.z) / tt + randf_range(-1, 1) * spread)
		game.spawn_projectile(src, v, weapon, grav, i * 0.07, self)
