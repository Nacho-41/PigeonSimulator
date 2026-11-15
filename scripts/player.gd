extends CharacterBody3D
## The pigeon. WASD to walk, SPACE to jump; the second jump throws eggs,
## extra jumps are wing flaps (bought in the shop). Mouse turns the camera.

@export_group("Mișcare")
@export var viteza := 7.4
@export var saritura := 8.4
@export var gravitatie := 24.0
@export var distanta_camera := 8.0
@export var acceleratie_pe_sol := 16.0
@export var acceleratie_in_aer := 7.0
@export var viteza_cadere_planare := 2.0
@export var putere_bataie_aripi := 7.6
@export var timp_coyote := 0.12
@export var unghi_maxim_acoperis := 52.0

@export_group("Cameră")
@export var sensibilitate_mouse := 0.0028
@export var zoom_minim := 4.0
@export var zoom_maxim := 16.0
@export var viteza_rotire_sageti := 2.0

var game: Node            # the game manager (game.gd)
var model: Node3D
var parts := {}           # named model parts: body, head, tail, wingL, wingR, legL, legR, shield
var pivot: Node3D         # camera yaw/pitch pivot
var spring: SpringArm3D
var camera: Camera3D

var face := 0.0           # direction the pigeon looks at (radians)
var yaw := 2.5            # camera yaw
var pitch := -0.33        # camera pitch
var cam_dist := 8.0
var jumps := 0
var flaps := 0
var coyote := 0.0
var flap_anim := 0.0
var walk := 0.0
var gliding := false
var scale_now := 1.2
var base_scale := 1.2
var level := -1
var collider: CollisionShape3D


func _ready() -> void:
	if game == null:
		game = get_parent()
	cam_dist = distanta_camera
	collision_layer = 2
	collision_mask = 1
	floor_max_angle = deg_to_rad(unghi_maxim_acoperis)
	floor_snap_length = 0.6
	collider = CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.0
	collider.shape = cap
	add_child(collider)
	pivot = Node3D.new()
	pivot.top_level = true
	add_child(pivot)
	spring = SpringArm3D.new()
	spring.collision_mask = 1
	spring.margin = 0.3
	spring.shape = SphereShape3D.new()
	(spring.shape as SphereShape3D).radius = 0.25
	pivot.add_child(spring)
	camera = Camera3D.new()
	camera.fov = 60.0
	camera.far = 4000.0
	spring.add_child(camera)
	set_level(0)


## Swap the pigeon model: 0 = Pigeon Basic, 1 = Pigeon Semi-Evoluat, 2 = Pigeon Evoluat.
func set_level(lv: int) -> void:
	if lv == level:
		return
	if level == -1 and lv == 0 and get_node_or_null("Model"):
		model = get_node("Model")      # the pigeon placed in the scene
	else:
		if model:
			model.queue_free()
		model = load("res://assets/pigeon_%d.glb" % lv).instantiate()
		add_child(model)
	level = lv
	for n in ["body", "head", "tail", "wingL", "wingR", "legL", "legR", "beakU", "beakL", "shield"]:
		parts[n] = model.find_child(n, true, false)
	if parts["shield"]:
		parts["shield"].visible = false
	base_scale = game.EVO[lv].scale if game and not game.EVO.is_empty() else 1.2
	scale_now = base_scale
	_apply_scale()


func _apply_scale() -> void:
	model.scale = Vector3.ONE * scale_now
	var cap := collider.shape as CapsuleShape3D
	cap.radius = 0.32 * scale_now
	cap.height = max(cap.radius * 2.0, 0.85 * scale_now)
	collider.position.y = cap.height * 0.5


func reset_at(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	set_level(0)
	base_scale = game.EVO[0].scale
	scale_now = base_scale
	_apply_scale()
	face = PI
	jumps = 0
	flaps = 0


func _unhandled_input(event: InputEvent) -> void:
	if game.state != "play":
		return
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam_dist = clamp(cam_dist - 0.8, zoom_minim, zoom_maxim)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam_dist = clamp(cam_dist + 0.8, zoom_minim, zoom_maxim)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * sensibilitate_mouse
		pitch = clamp(pitch - event.relative.y * sensibilitate_mouse * 0.8, -1.25, 0.15)
	if event.is_action_pressed("jump"):
		do_jump()


# ---------------------------------------------------------------- abilities
func speed_max() -> float:
	var s: float = viteza * game.EVO[level].sp * (1.0 + game.viteza_pe_nivel * game.level_of("speed"))
	if game.buff == "turbo":
		s *= game.turbo_viteza
	if game.buff == "giant":
		s *= game.uriash_viteza
	return s


func jump_velocity() -> float:
	return saritura * game.EVO[level].jp * (1.0 + game.saritura_pe_nivel * game.level_of("jump")) * (1.25 if game.buff == "giant" else 1.0)


func max_flaps() -> int:
	if game.buff == "turbo":
		return 99
	var t: Array[int] = game.batai_aripi_pe_nivel
	return t[min(game.level_of("wings"), t.size() - 1)]


func do_jump() -> void:
	if is_on_floor() or coyote > 0.0:
		velocity.y = jump_velocity()
		jumps = 1
		coyote = 0.0
		game.play_sfx(game.sunet_saritura)
		flap_anim = 1.0
		game.puff(global_position + Vector3.UP * 0.1, 4, Color(0.81, 0.78, 0.72))
	elif jumps == 1:
		velocity.y = jump_velocity() * 0.95
		jumps = 2
		flap_anim = 1.0
		game.egg_blast(false)
	elif flaps > 0:
		flaps -= 1
		game.play_sfx(game.sunet_saritura)
		velocity.y = max(velocity.y, 0.0) * 0.3 + putere_bataie_aripi
		flap_anim = 1.0


# ---------------------------------------------------------------- movement
func _physics_process(dt: float) -> void:
	if game == null:
		return
	if game.state == "play":
		_move(dt)
	elif game.state == "dying":
		velocity.y -= gravitatie * dt * 0.3
		move_and_slide()
	_animate(dt)
	_update_camera(dt)


func _move(dt: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var wish := fwd * input.y + right * input.x
	if wish.length() > 1.0:
		wish = wish.normalized()
	var acc := acceleratie_pe_sol if is_on_floor() else acceleratie_in_aer
	var k := 1.0 - exp(-acc * dt)
	velocity.x = lerp(velocity.x, wish.x * speed_max(), k)
	velocity.z = lerp(velocity.z, wish.z * speed_max(), k)
	if wish.length() > 0.05:
		face = lerp_angle(face, atan2(wish.x, wish.z), 1.0 - exp(-12.0 * dt))
	var was_floor := is_on_floor()
	velocity.y -= gravitatie * dt
	gliding = not is_on_floor() and Input.is_action_pressed("jump") and velocity.y < 0.0 and game.level_of("glide") > 0
	if gliding:
		velocity.y = max(velocity.y, -viteza_cadere_planare)
	velocity.y = max(velocity.y, -30.0)
	move_and_slide()
	if is_on_floor():
		jumps = 0
		flaps = max_flaps()
	elif was_floor and velocity.y <= 0.0:
		coyote = timp_coyote
	coyote = max(0.0, coyote - dt)
	# keep inside the old town
	var b: Array = game.bounds
	global_position.x = clamp(global_position.x, b[0] + 2.0, b[1] - 2.0)
	global_position.z = clamp(global_position.z, b[2] + 2.0, b[3] - 2.0)
	# giant mode
	var target_scale: float = base_scale * (game.uriash_marime if game.buff == "giant" else 1.0)
	if abs(scale_now - target_scale) > 0.01:
		scale_now = lerp(scale_now, target_scale, 1.0 - exp(-5.0 * dt))
		_apply_scale()
	walk += Vector2(velocity.x, velocity.z).length() * dt * (2.6 if is_on_floor() else 0.0)


func center() -> Vector3:
	return global_position + Vector3.UP * 0.6 * scale_now


# ---------------------------------------------------------------- looks
var evo_spin := 0.0


func _animate(dt: float) -> void:
	evo_spin = max(0.0, evo_spin - dt)
	model.rotation.y = face + (1.0 - evo_spin / 1.2) * TAU * 2.0 if evo_spin > 0.0 else face
	var spd: float = Vector2(velocity.x, velocity.z).length()
	var grounded := is_on_floor()
	var w: float = clamp(spd / 5.0, 0.0, 1.0) if grounded else 0.0
	var ph := walk * 2.2
	var sw := sin(ph) * 0.9 * w
	var t: float = game.t
	if parts["legL"]:
		parts["legL"].rotation.x = sw if grounded else 0.8
		parts["legR"].rotation.x = -sw if grounded else 0.8
	if parts["body"]:
		parts["body"].position.y = 0.62 + abs(sin(ph)) * 0.045 * w + sin(t * 3.0) * 0.008
		parts["body"].rotation.x = w * 0.06 if grounded else (-0.2 if velocity.y > 0.0 else 0.15)
	if parts["head"]:
		parts["head"].position.z = 0.46 + sin(ph * 2.0) * 0.06 * w
		parts["head"].rotation.z = sin(t * 0.9) * 0.12 * (1.0 - w) + sin(t * 0.37) * 0.08
	if parts["tail"]:
		parts["tail"].rotation.y = sin(ph) * 0.2 * w
	flap_anim = max(0.0, flap_anim - dt * 2.2)
	var wa := 0.06 + sin(ph) * 0.03 * w
	if not grounded:
		wa = 1.35 + sin(t * 6.0) * 0.08 if gliding else 0.5 + (sin(t * 36.0) * 0.5 + 0.5) * 1.4
	if parts["wingL"]:
		parts["wingL"].rotation.z = -wa
		parts["wingR"].rotation.z = wa
	if parts["beakU"]:
		var beak := 0.25 if not grounded else 0.0
		parts["beakU"].rotation.x = -beak * 0.45
		parts["beakL"].rotation.x = beak * 0.85
	if parts["shield"]:
		parts["shield"].visible = game.buff == "shield"
	var pulse := 1.0 + sin(evo_spin * 14.0) * 0.08 if evo_spin > 0.0 else 1.0
	model.scale = Vector3.ONE * scale_now * pulse
	model.visible = true if game.inv <= 0.0 else int(game.t * 14.0) % 2 == 0


func _update_camera(dt: float) -> void:
	if game.state == "play" or game.state == "dying" or game.state == "shop" or game.state == "pause":
		if Input.is_action_pressed("cam_left"):
			yaw += viteza_rotire_sageti * dt
		if Input.is_action_pressed("cam_right"):
			yaw -= viteza_rotire_sageti * dt
		var target := global_position + Vector3.UP * 1.0 * scale_now
		pivot.global_position = pivot.global_position.lerp(target, 1.0 - exp(-14.0 * dt))
		pivot.global_position.x = target.x
		pivot.global_position.z = target.z
		pivot.rotation = Vector3(pitch, yaw, 0)
		spring.spring_length = cam_dist * (scale_now / 1.2 * 0.6 + 0.4)
