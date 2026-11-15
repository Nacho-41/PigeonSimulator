extends Node3D
## Pigeon Simulator – game manager.
## Builds the Brașov old town (assets/world.glb, made from OpenStreetMap), spawns the pigeon,
## the kids and the Actimel bottles, and owns the rules: lives, eggs, golden power-ups, the shop.
##
## Easy things to tweak are at the top of this file (shop prices, power-ups, numbers of things).

const PlayerScript := preload("res://scripts/player.gd")
const KidScript := preload("res://scripts/kid.gd")
const HudScript := preload("res://scripts/hud.gd")
const BossScript := preload("res://scripts/boss.gd")

# ------------------------------------------------------------------ setări (le schimbi din Inspector)
# Selectează nodul "Game" din panoul Scene; toate valorile de mai jos apar în Inspector, în dreapta.

@export_group("Porumbelul")
@export var vieti := 3
@export var secunde_invincibil_dupa_lovitura := 2.2
@export var impingere_la_lovitura := 9.0

@export_group("Evoluții")
@export var nume_basic := "Pigeon Basic"
@export var nume_semi := "Pigeon Semi-Evoluat"
@export var nume_evoluat := "Pigeon Evoluat"
@export var sticle_pentru_semi := 15
@export var sticle_pentru_evoluat := 40
@export var marime_basic := 1.2
@export var marime_semi := 1.7
@export var marime_evoluat := 2.3
@export var viteza_bonus_semi := 1.15
@export var viteza_bonus_evoluat := 1.3
@export var saritura_bonus_semi := 1.1
@export var saritura_bonus_evoluat := 1.2

@export_group("Ouă (a doua săritură)")
@export var pauza_intre_explozii := 1.4
@export var raza_explozie := 7.0
@export var raza_extra_pe_nivel := 2.6
@export var numar_oua := 7
@export var oua_extra_pe_nivel := 2
@export var putere_aruncare_copii := 1.0
@export var secunde_cat_raman_ouale_pe_jos := 12.0

@export_group("Copiii")
@export var maxim_copii := 13
@export var copii_la_start := 3
@export var secunde_pana_la_copil_nou := 28.0
@export var viteza_copii := 4.8
@export var gravitatie_zbor_copii := 5.5
@export var secunde_ameteala := 2.2
@export var distanta_aparitie_minima := 38.0
@export var distanta_aparitie_maxima := 85.0
@export var distanta_disparitie := 120.0
@export var secunde_pregatire_atac := 0.45
## Cât de mari sunt copiii (1 = mărimea inițială, 1.6 = cu 60% mai mari).
@export_range(0.5, 3.0, 0.05) var marime_copii := 1.6
## Cu câți metri pot rata ținta, la întâmplare (0 = țintesc perfect).
@export_range(0.0, 8.0, 0.1) var greseala_tinta_copii := 2.2
## Cât de mult ghicesc unde vei zbura (1 = perfect, 0 = trag unde erai).
@export_range(0.0, 1.0, 0.05) var anticipare_tinta_copii := 0.0

@export_group("Copii cu praștie")
@export var prastie_raza := 16.0
@export var prastie_pauza_minima := 2.2
@export var prastie_pauza_maxima := 3.2
@export var prastie_viteza_pietricica := 21.0

@export_group("Copii cu pistol cu apă")
@export var apa_raza := 10.0
@export var apa_pauza_minima := 1.6
@export var apa_pauza_maxima := 2.4
@export var apa_viteza_picaturi := 15.0
@export var apa_picaturi_pe_tragere := 4

@export_group("Copii cu plasă")
@export var plasa_raza := 2.3
@export var plasa_pauza_minima := 1.2
@export var plasa_pauza_maxima := 1.8
@export var plasa_viteza_salt := 9.0

@export_group("Sticle")
@export var sticle_normale := 70
@export var sticle_aurii := 3
@export var sticle_la_sticla_aurie := 5
@export var marime_sticla := 2.4
@export var marime_sticla_aurie := 2.8
@export var sansa_sticla_pe_acoperis := 0.22
@export var sansa_aurie_pe_acoperis := 0.8
@export var reaparitie_sticla_minim := 3.0
@export var reaparitie_sticla_maxim := 6.0
@export var prima_aurie_dupa_secunde := 25.0
@export var aurie_noua_minim := 45.0
@export var aurie_noua_maxim := 70.0

@export_group("Puteri aurii")
@export var nume_scut := "Scut de aur"
@export var durata_scut := 15.0
@export var nume_uriash := "Porumbel uriaș"
@export var durata_uriash := 15.0
@export var uriash_marime := 2.0
@export var uriash_viteza := 1.3
@export var nume_turbo := "Turbo"
@export var durata_turbo := 12.0
@export var turbo_viteza := 1.7
@export var nume_ploaie_oua := "Ploaie de ouă"
@export var durata_ploaie_oua := 12.0
@export var ploaie_oua_interval := 1.3

@export_group("Chioșc")
@export var distanta_chiosc := 6.0
@export var nume_viteza := "Picioare rapide"
@export var pret_viteza: Array[int] = [8, 14, 22]
@export var viteza_pe_nivel := 0.15
@export var nume_saritura := "Salt înalt"
@export var pret_saritura: Array[int] = [8, 14, 22]
@export var saritura_pe_nivel := 0.12
@export var nume_aripi := "Aripi"
@export var pret_aripi: Array[int] = [12, 20, 30]
@export var batai_aripi_pe_nivel: Array[int] = [0, 2, 4, 7]
@export var nume_planare := "Planare"
@export var pret_planare: Array[int] = [10]
@export var nume_oua := "Ouă grele"
@export var pret_oua: Array[int] = [10, 18, 26]
@export var nume_magnet := "Magnet"
@export var pret_magnet: Array[int] = [10, 18]
@export var raza_magnet_pe_nivel: Array[float] = [0.0, 4.0, 8.0]
@export var nume_vindecare := "Vindecare"
@export var pret_vindecare := 12

@export_group("Boss final")
@export var boss_activ := true
@export var imagine_boss: Texture2D = preload("res://ui/boss.png")
@export var nume_boss := "PORUMBELUL CU BUZE"
## 0 = Pigeon Basic, 1 = Semi-Evoluat, 2 = Evoluat
@export_range(0, 2) var boss_apare_la_nivel := 2
@export var secunde_pana_apare_boss := 4.0
@export var viata_boss := 12
@export var inaltime_boss := 8.0
@export var viteza_boss := 6.0
@export var pauza_calcat_boss := 5.0
@export var raza_calcat_boss := 9.0
@export var pauza_pupic_boss := 3.0
@export var viteza_pupic_boss := 10.0
@export var damage_oua_la_boss := 1
@export var titlu_victorie := "AI CÂȘTIGAT!"
## Videoclipul care pornește când boss-ul îți ia ultima viață (doar .ogv; lasă gol ca să nu apară).
@export var video_moarte_boss: VideoStream = preload("res://video/boss_kill.ogv")
## Subtitrările videoclipului, câte un rând: „început | sfârșit | text” (secunde).
@export var subtitrari_video_boss: PackedStringArray = PackedStringArray([
	"0.2 | 1.3 | ",
	"1.9 | 3.3 | ",
])
## Poți sări peste videoclip cu SPACE / ESC / click.
@export var poti_sari_video := true

@export_group("Sunete (trage fișierele .wav / .ogg aici)")
@export var sunet_saritura: AudioStream
@export var sunet_oua: AudioStream
@export var sunet_sticla: AudioStream
@export var sunet_sticla_aurie: AudioStream
@export var sunet_evolutie: AudioStream
@export var sunet_lovit: AudioStream
@export var sunet_copil_aruncat: AudioStream
@export var sunet_cumparare: AudioStream
@export var sunet_prins: AudioStream
@export var sunet_boss_apare: AudioStream
@export var sunet_boss_lovit: AudioStream
@export var sunet_boss_pupic: AudioStream
@export var sunet_victorie: AudioStream
@export var muzica: AudioStream
@export_range(-40.0, 6.0) var volum_efecte_db := 0.0
@export_range(-40.0, 6.0) var volum_muzica_db := -8.0
@export_range(0.0, 0.5) var variatie_ton := 0.08

@export_group("Interfață")
@export var titlu_meniu := "PIGEON SIMULATOR"
@export_multiline var text_meniu := "WASD mers  ·  SPACE săritură (a doua aruncă ouă)\nMouse cameră  ·  E chioșc Actimel  ·  ESC pauză"
@export var buton_start := "JOACĂ!"
## Creditul cerut de licența OpenStreetMap (ODbL). Apare jos în meniu și, mic, în colțul ecranului în timpul jocului.
@export var text_credite := "Harta: © OpenStreetMap contributors · openstreetmap.org/copyright"
@export var credite_in_joc := true
## Imaginea care apare la pornire, cât se încarcă orașul (pune „null” ca să revii la ecranul vechi).
@export var imagine_pornire: Texture2D = preload("res://ui/splash.png")
@export var text_incarcare := "Se încarcă Brașovul…"
## Bifat: meniul de start e imaginea de pornire cu butonul JOACĂ! jos. Debifat: meniul vechi peste oraș.
@export var imagine_ca_meniu := true
@export var titlu_pauza := "PAUZĂ"
@export var titlu_prins := "PRINS!"
## Culorile căsuțelor: contur/umbră, fundal, textul din ele, accent (nume nivel, bare) și butoane.
@export var culoare_contur := Color("0b1a2b")
@export var culoare_fundal := Color("1f4a6e")
@export var culoare_text := Color("ffffff")
@export var culoare_accent := Color("5ef0b0")
@export var culoare_butoane := Color("ffc83d")
## Fonturile: unul gros pentru titluri și butoane, unul pentru textul normal.
@export var font_titluri: Font = preload("res://ui/fonts/ArchivoBlack-Regular.ttf")
@export var font_text: Font = preload("res://ui/fonts/Montserrat.ttf")
## Grosimea fontului de text (400 normal, 700 bold, 900 foarte gros).
@export_range(100, 900, 100) var grosime_font_text := 700
@export var arata_bara_oua := true
@export var arata_numar_sticle := true
@export var arata_vieti := true
@export var arata_evolutie := true
@export var viteza_camera_meniu := 0.05

# tables built from the settings above (other scripts read these)
var SHOP: Array = []
var BUFFS: Dictionary = {}
var EVO: Array = []
var MAX_LIVES := 3
var MAX_KIDS := 13
var NORMAL_BOTTLES := 70
var GOLDEN_BOTTLES := 3


func _enter_tree() -> void:
	MAX_LIVES = vieti
	MAX_KIDS = maxim_copii
	NORMAL_BOTTLES = sticle_normale
	GOLDEN_BOTTLES = sticle_aurii
	EVO = [
		{"name": nume_basic, "scale": marime_basic, "sp": 1.0, "jp": 1.0, "at": 0},
		{"name": nume_semi, "scale": marime_semi, "sp": viteza_bonus_semi, "jp": saritura_bonus_semi, "at": sticle_pentru_semi},
		{"name": nume_evoluat, "scale": marime_evoluat, "sp": viteza_bonus_evoluat, "jp": saritura_bonus_evoluat, "at": sticle_pentru_evoluat},
	]
	BUFFS = {
		"shield": {"name": nume_scut, "dur": durata_scut},
		"giant": {"name": nume_uriash, "dur": durata_uriash},
		"turbo": {"name": nume_turbo, "dur": durata_turbo},
		"eggs": {"name": nume_ploaie_oua, "dur": durata_ploaie_oua},
	}
	SHOP = [
		{"id": "speed", "name": nume_viteza, "desc": "+%d%% viteză pe nivel" % int(viteza_pe_nivel * 100), "cost": pret_viteza},
		{"id": "jump", "name": nume_saritura, "desc": "+%d%% săritură pe nivel" % int(saritura_pe_nivel * 100), "cost": pret_saritura},
		{"id": "wings", "name": nume_aripi, "desc": "bătăi în aer: " + " / ".join(PackedStringArray(batai_aripi_pe_nivel.slice(1).map(func(x): return str(x)))), "cost": pret_aripi},
		{"id": "glide", "name": nume_planare, "desc": "ține SPACE când cazi", "cost": pret_planare},
		{"id": "egg", "name": nume_oua, "desc": "explozie de ouă mai mare", "cost": pret_oua},
		{"id": "magnet", "name": nume_magnet, "desc": "atrage sticlele de departe", "cost": pret_magnet},
		{"id": "heal", "name": nume_vindecare, "desc": "+1 viață", "cost": [pret_vindecare], "repeat": true},
	]

const WEAPONS := ["sling", "water", "net"]

# ------------------------------------------------------------------ state
var evo := 0
var state := "loading"        # menu / play / shop / pause / dying / over
var t := 0.0
var bottles := 0
var total := 0
var launched := 0
var lives := 3
var inv := 0.0
var levels := {}
var buff := ""
var buff_t := 0.0
var egg_cd := 0.0
var auto_egg := 0.0
var gold_timer := 25.0  # set from prima_aurie_dupa_secunde
var over_t := 0.0
var menu_a := 0.0

var data: Dictionary
var bounds: Array
var shop_pos := Vector3.ZERO
var ground_spots: Array = []
var roof_spots: Array = []
var astar := AStarGrid2D.new()
var nav_res := 2.0
var nav_size := Vector2i.ZERO

var player: CharacterBody3D
var hud: CanvasLayer
var kids: Array = []
var bottle_list: Array = []   # dictionaries {node, gold, alive, respawn, pos, ph}
var projectiles: Array = []
var eggs: Array = []
var menu_cam: Camera3D
var sun: DirectionalLight3D
var start_pos := Vector3.ZERO
var music_player: AudioStreamPlayer
var killed_by_boss := false
var boss: CharacterBody3D
var boss_timer := -1.0
var boss_done := false
var _last_sfx := {}
var loaded := false


func _ready() -> void:
	randomize()
	_setup_input()
	_load_data()
	# objects placed in the scene (you can move them in the editor)
	player = get_node_or_null("Porumbel")
	if player == null:
		player = PlayerScript.new()
		add_child(player)
		player.global_position = shop_pos + Vector3(10, 0.2, 10)
	player.game = self
	start_pos = player.global_position
	var kiosk := get_node_or_null("Chiosc") as Node3D
	if kiosk:
		shop_pos = Vector3(kiosk.global_position.x, 0, kiosk.global_position.z)
	sun = get_node_or_null("Soare")
	if get_node_or_null("Mediu") == null:
		_build_environment()
	menu_cam = Camera3D.new()
	menu_cam.far = 4000.0
	add_child(menu_cam)
	menu_cam.make_current()
	hud = HudScript.new()
	hud.game = self
	add_child(hud)
	hud.show_screen("loading")
	# let the loading screen appear before the heavy work (solid walls for 418 buildings)
	await get_tree().process_frame
	await get_tree().process_frame
	_build_world()
	if kiosk:
		_prepare_world(kiosk, true)
	for i in NORMAL_BOTTLES:
		_make_bottle(false)
	for i in GOLDEN_BOTTLES:
		_make_bottle(true)
	reset_run()
	loaded = true
	state = "menu"
	hud.show_screen("menu")


# ------------------------------------------------------------------ sounds
## Plays one of the sounds set in the Inspector (does nothing if the slot is empty).
func play_sfx(stream: AudioStream, min_gap := 0.08) -> void:
	if stream == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_sfx.get(stream, -10.0)) < min_gap:
		return   # the same sound many times in the same instant would just be loud
	_last_sfx[stream] = now
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volum_efecte_db
	p.pitch_scale = randf_range(1.0 - variatie_ton, 1.0 + variatie_ton)
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


func _start_music() -> void:
	if muzica == null:
		return
	if music_player == null:
		music_player = AudioStreamPlayer.new()
		add_child(music_player)
		music_player.finished.connect(music_player.play)   # loop
	music_player.stream = muzica
	music_player.volume_db = volum_muzica_db
	if not music_player.playing:
		music_player.play()


# ------------------------------------------------------------------ setup
func _setup_input() -> void:
	var map := {
		"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN], "move_left": [KEY_A], "move_right": [KEY_D],
		"jump": [KEY_SPACE], "interact": [KEY_E], "pause": [KEY_ESCAPE], "cam_left": [KEY_LEFT], "cam_right": [KEY_RIGHT],
	}
	for action in map:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


func _load_data() -> void:
	var f := FileAccess.open("res://data/world_data.json", FileAccess.READ)
	data = JSON.parse_string(f.get_as_text())
	bounds = data.bounds
	shop_pos = Vector3(data.shop[0], 0, data.shop[1])
	ground_spots = data.ground
	roof_spots = data.roof
	var nav: Dictionary = data.nav
	nav_res = nav.res
	nav_size = Vector2i(int(nav.w), int(nav.h))
	var walk := Marshalls.base64_to_raw(nav.walk)
	astar.region = Rect2i(Vector2i.ZERO, nav_size)
	astar.cell_size = Vector2(nav_res, nav_res)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for j in nav_size.y:
		for i in nav_size.x:
			if walk[j * nav_size.x + i] == 0:
				astar.set_point_solid(Vector2i(i, j), true)


func _build_environment() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("4f9eea")
	sm.sky_horizon_color = Color("cfe6f7")
	sm.ground_horizon_color = Color("cfe6f7")
	sm.ground_bottom_color = Color("6fae4a")
	sm.sun_angle_max = 20.0
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = Color("cfe6f7")
	env.fog_density = 0.0009
	env.fog_sky_affect = 0.2
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.light_color = Color("fff1d6")
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 140.0
	add_child(sun)
	sun.look_at_from_position(Vector3.ZERO, Vector3(-0.45, -0.85, -0.4), Vector3.UP)


func _build_world() -> void:
	var world := get_node_or_null("Oras") as Node3D
	if world == null:
		world = load("res://assets/world.glb").instantiate()
		add_child(world)
	_prepare_world(world, false)
	# flat ground + invisible walls around the playable area
	var ground := StaticBody3D.new()
	var gs := CollisionShape3D.new()
	gs.shape = WorldBoundaryShape3D.new()
	ground.add_child(gs)
	add_child(ground)
	var b := bounds
	var cx: float = (b[0] + b[1]) * 0.5
	var cz: float = (b[2] + b[3]) * 0.5
	var w: float = b[1] - b[0]
	var d: float = b[3] - b[2]
	for side in [[Vector3(b[0], 50, cz), Vector3(1, 100, d)], [Vector3(b[1], 50, cz), Vector3(1, 100, d)], [Vector3(cx, 50, b[2]), Vector3(w, 100, 1)], [Vector3(cx, 50, b[3]), Vector3(w, 100, 1)]]:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = side[1]
		cs.shape = box
		sb.position = side[0]
		sb.add_child(cs)
		add_child(sb)


## Vertex colours carry the facade/roof colours: make materials use them,
## and give every "col_*" object (buildings, walls, trees, kiosk…) a trimesh collider.
func _prepare_world(n: Node, solid: bool) -> void:
	var is_solid := solid or String(n.name).begins_with("col_")
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(s)
			if mat is BaseMaterial3D and (mi.mesh.surface_get_format(s) & Mesh.ARRAY_FORMAT_COLOR):
				(mat as BaseMaterial3D).vertex_color_use_as_albedo = true
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if is_solid:
			mi.create_trimesh_collision()
	for c in n.get_children():
		_prepare_world(c, is_solid)


# ------------------------------------------------------------------ flow
func reset_run() -> void:
	for k in kids:
		k.queue_free()
	kids.clear()
	for p in projectiles:
		p.node.queue_free()
	projectiles.clear()
	if is_instance_valid(boss):
		boss.queue_free()
	boss = null
	boss_timer = -1.0
	boss_done = false
	t = 0.0
	evo = 0
	bottles = 0
	total = 0
	launched = 0
	lives = MAX_LIVES
	inv = 0.0
	levels = {}
	buff = ""
	buff_t = 0.0
	egg_cd = 0.0
	gold_timer = prima_aurie_dupa_secunde
	player.reset_at(start_pos)
	var look := Vector3(15, 0, -40) - start_pos   # face Piața Sfatului
	player.yaw = atan2(-look.x, -look.z)
	for b in bottle_list:
		if b.gold:
			_hide_bottle(b)
			b.respawn = 0.0
		else:
			_place_bottle(b)


func start_game() -> void:
	reset_run()
	killed_by_boss = false
	if music_player:
		music_player.stream_paused = false
	state = "play"
	player.camera.make_current()
	hud.show_screen("play")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_start_music()


func pause_game() -> void:
	state = "pause"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.show_screen("pause")


func resume_game() -> void:
	state = "play"
	hud.show_screen("play")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func open_shop() -> void:
	state = "shop"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.show_screen("shop")


func close_shop() -> void:
	state = "play"
	hud.show_screen("play")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func game_over() -> void:
	if killed_by_boss and video_moarte_boss != null and state != "video":
		# boss-ul te-a prins: întâi videoclipul, apoi ecranul de final
		state = "video"
		if music_player:
			music_player.stream_paused = true
		hud.play_video(video_moarte_boss, subtitrari_video_boss, Callable(self, "_after_boss_video"))
		return
	state = "over"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.set_over_stats(int(t), total, launched)
	hud.show_screen("over")


func _after_boss_video() -> void:
	if state != "video":
		return
	killed_by_boss = false
	if music_player:
		music_player.stream_paused = false
	state = "dying"
	game_over()


func _unhandled_input(event: InputEvent) -> void:
	if state == "video":
		if poti_sari_video and event.is_pressed() and not event.is_echo() and (event is InputEventKey or event is InputEventMouseButton):
			hud.stop_video()
			_after_boss_video()
		return
	if event.is_action_pressed("interact"):
		if state == "play" and near_shop():
			open_shop()
		elif state == "shop":
			close_shop()
	elif event.is_action_pressed("pause"):
		if state == "shop":
			close_shop()
		elif state == "play":
			pause_game()
		elif state == "pause":
			resume_game()
	elif state == "shop" and event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.physical_keycode
		if k >= KEY_1 and k <= KEY_7:
			buy(k - KEY_1)


# ------------------------------------------------------------------ shop
func level_of(id: String) -> int:
	return levels.get(id, 0)


func item_cost(i: int):
	var it: Dictionary = SHOP[i]
	if it.get("repeat", false):
		return it.cost[0]
	var l := level_of(it.id)
	return it.cost[l] if l < it.cost.size() else null


func can_buy(i: int) -> bool:
	var c = item_cost(i)
	if c == null or c > bottles:
		return false
	return not (SHOP[i].id == "heal" and lives >= MAX_LIVES)


func buy(i: int) -> void:
	if i < 0 or i >= SHOP.size() or not can_buy(i):
		return
	var it: Dictionary = SHOP[i]
	bottles -= item_cost(i)
	play_sfx(sunet_cumparare)
	if it.id == "heal":
		lives += 1
	else:
		levels[it.id] = level_of(it.id) + 1
	player.flaps = player.max_flaps()
	hud.refresh_shop()


func near_shop() -> bool:
	var p := player.global_position
	return Vector2(p.x - shop_pos.x, p.z - shop_pos.z).length() < distanta_chiosc and p.y < 4.0


# ------------------------------------------------------------------ main loop
func _process(dt: float) -> void:
	if not loaded:
		return
	if state == "menu":
		menu_a += dt * viteza_camera_meniu
		menu_cam.global_position = shop_pos + Vector3(sin(menu_a) * 70, 34, -40 + cos(menu_a) * 70)
		menu_cam.look_at(shop_pos + Vector3(-10, 8, -40))
		_spin_bottles(dt)
		return
	if state != "play" and state != "dying":
		return
	var sdt := dt * (0.3 if state == "dying" else 1.0)
	t += sdt
	inv = max(0.0, inv - sdt)
	egg_cd = max(0.0, egg_cd - sdt)
	if buff != "":
		buff_t -= sdt
		if buff == "eggs":
			auto_egg -= sdt
			if auto_egg <= 0.0:
				auto_egg = ploaie_oua_interval
				egg_blast(true)
		if buff_t <= 0.0:
			buff = ""
	if boss_timer >= 0.0:
		boss_timer -= sdt
		if boss_timer < 0.0:
			spawn_boss()
	_update_kids_spawn(sdt)
	_update_projectiles(sdt)
	_update_eggs(sdt)
	_update_bottles(sdt)
	_bump_kids_when_big()
	# keep the sun's shadow box around the pigeon
	if state == "dying":
		over_t += dt
		if over_t > 1.4:
			game_over()


# ------------------------------------------------------------------ kids
func _update_kids_spawn(dt: float) -> void:
	var want: int = min(copii_la_start + int(t / secunde_pana_la_copil_nou), MAX_KIDS)
	if kids.size() < want and randf() < dt * 1.2:
		spawn_kid()
	for k in kids.duplicate():
		if Vector2(k.global_position.x - player.global_position.x, k.global_position.z - player.global_position.z).length() > distanta_disparitie and k.state != "fly":
			kids.erase(k)
			k.queue_free()


func spawn_kid() -> void:
	var p := player.global_position
	var cands: Array = []
	for s in ground_spots:
		var d := Vector2(s[0] - p.x, s[1] - p.z).length()
		if d > distanta_aparitie_minima and d < distanta_aparitie_maxima:
			cands.append(s)
	if cands.is_empty():
		return
	var s: Array = cands.pick_random()
	var k := KidScript.new()
	k.setup(self, WEAPONS[kids.size() % 3], 0)
	add_child(k)
	k.global_position = Vector3(s[0], 0.1, s[1])
	kids.append(k)


func _cell(x: float, z: float) -> Vector2i:
	return Vector2i(int(floor((x - bounds[0]) / nav_res)), int(floor((z - bounds[2]) / nav_res)))


func _walkable_near(c: Vector2i) -> Vector2i:
	for r in 14:
		for dj in range(-r, r + 1):
			for di in range(-r, r + 1):
				if max(abs(di), abs(dj)) != r:
					continue
				var q := c + Vector2i(di, dj)
				if astar.is_in_boundsv(q) and not astar.is_point_solid(q):
					return q
	return Vector2i(-1, -1)


## Path for a kid on the 2 m street grid (built from the map), as world x/z points.
func find_path(from: Vector3, to: Vector3) -> PackedVector2Array:
	var out := PackedVector2Array()
	var a := _walkable_near(_cell(from.x, from.z))
	var b := _walkable_near(_cell(to.x, to.z))
	if a.x < 0 or b.x < 0:
		return out
	var ids := astar.get_id_path(a, b)
	for id in ids:
		out.append(Vector2(bounds[0] + (id.x + 0.5) * nav_res, bounds[2] + (id.y + 0.5) * nav_res))
	return out


func line_of_sight(a: Vector3, b: Vector3, _from: Node) -> bool:
	var q := PhysicsRayQueryParameters3D.create(a, b, 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func hurt_pigeon(from: Vector3, by_boss := false) -> void:
	if inv > 0.0 or buff == "shield" or state != "play":
		return
	lives -= 1
	killed_by_boss = by_boss
	play_sfx(sunet_lovit)
	inv = secunde_invincibil_dupa_lovitura
	var d := player.global_position - from
	d.y = 0
	d = d.normalized()
	player.velocity += Vector3(d.x * impingere_la_lovitura, 5.0, d.z * impingere_la_lovitura)
	puff(player.center(), 10, Color(0.6, 0.63, 0.69))
	if lives <= 0:
		state = "dying"
		over_t = 0.0
		play_sfx(sunet_prins)


func _bump_kids_when_big() -> void:
	if buff != "giant" and buff != "shield":
		return
	for k in kids:
		if k.state == "fly":
			continue
		var d: Vector3 = k.global_position - player.global_position
		var dl := Vector2(d.x, d.z).length()
		if dl < 0.9 * player.scale_now + 0.3 and abs(d.y) < 1.5 * player.scale_now:
			k.launch(Vector3(d.x, 0, d.z).normalized(), 0.8)


# ------------------------------------------------------------------ boss
func spawn_boss() -> void:
	if boss != null or boss_done:
		return
	var p := player.global_position
	var best: Array = []
	for s in ground_spots:
		var d := Vector2(s[0] - p.x, s[1] - p.z).length()
		if d > 18.0 and d < 40.0:
			best.append(s)
	if best.is_empty():
		best = ground_spots
	var s: Array = best.pick_random()
	boss = BossScript.new()
	boss.setup(self)
	add_child(boss)
	boss.global_position = Vector3(s[0], 40.0, s[1])
	play_sfx(sunet_boss_apare)


## Ground shock wave (boss landing / stomping): hurts the pigeon if it stands on the ground nearby.
func boss_shockwave(at: Vector3, r: float) -> void:
	_shock_ring(at, r)
	puff(at + Vector3.UP * 0.3, 20, Color(0.81, 0.78, 0.72))
	var d := Vector2(player.global_position.x - at.x, player.global_position.z - at.z).length()
	if d < r and player.is_on_floor() and player.global_position.y - at.y < 1.5:
		hurt_pigeon(at, true)
	for k in kids:
		var dk := Vector2(k.global_position.x - at.x, k.global_position.z - at.z).length()
		if dk < r and k.state != "fly":
			k.launch(Vector3(k.global_position.x - at.x, 0, k.global_position.z - at.z).normalized(), 0.6)


func boss_defeated() -> void:
	boss_done = true
	play_sfx(sunet_victorie)
	for c in [Color("ff4d8d"), Color("ffd23f"), Color("3bb5ff"), Color("7be0b0")]:
		puff(boss.global_position + Vector3.UP * 4.0, 20, c)
	await get_tree().create_timer(2.2).timeout
	if state == "play":
		state = "won"
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		hud.set_win_stats(int(t), total, launched)
		hud.show_screen("won")


func continue_after_win() -> void:
	state = "play"
	hud.show_screen("play")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# ------------------------------------------------------------------ eggs
func egg_blast(auto: bool) -> void:
	if egg_cd > 0.0 and not auto:
		return
	if not auto:
		egg_cd = pauza_intre_explozii
	play_sfx(sunet_oua)
	var radius := raza_explozie + raza_extra_pe_nivel * level_of("egg") + (4.0 if buff == "giant" else 0.0)
	var n := numar_oua + oua_extra_pe_nivel * level_of("egg")
	var origin: Vector3 = player.center()
	for i in n:
		var a := float(i) / n * TAU + randf() * 0.4
		var s := randf_range(4.0, 7.0)
		var m := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.11
		sp.height = 0.28
		m.mesh = sp
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("f8f1e2")
		mat.roughness = 0.5
		m.material_override = mat
		add_child(m)
		m.global_position = origin
		eggs.append({"node": m, "vel": Vector3(cos(a) * s, randf_range(1, 4), sin(a) * s)})
	_shock_ring(player.global_position, radius)
	if is_instance_valid(boss) and boss.state != "dead":
		var db := Vector2(boss.global_position.x - player.global_position.x, boss.global_position.z - player.global_position.z).length()
		if db < radius + boss.radius():
			boss.hit(damage_oua_la_boss + level_of("egg"))
	for k in kids:
		var d: Vector3 = k.global_position - player.global_position
		var dl := Vector2(d.x, d.z).length()
		if dl < radius and abs(d.y) < radius * 0.9 and k.state != "fly":
			k.launch(Vector3(d.x, 0, d.z).normalized() if dl > 0.01 else Vector3.FORWARD, (1.0 - dl / radius) * putere_aruncare_copii)


func _update_eggs(dt: float) -> void:
	var space := get_world_3d().direct_space_state
	for e in eggs.duplicate():
		var n: MeshInstance3D = e.node
		var a := n.global_position
		e.vel.y -= 24.0 * dt
		var b: Vector3 = a + e.vel * dt
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(a, b, 1))
		if not hit.is_empty() or b.y < 0.0:
			var at: Vector3 = hit.position if not hit.is_empty() else Vector3(b.x, 0, b.z)
			_splat(at)
			n.queue_free()
			eggs.erase(e)
		else:
			n.global_position = b
			n.rotate_x(8.0 * dt)


func _splat(at: Vector3) -> void:
	var m := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = randf_range(0.4, 0.6)
	c.bottom_radius = c.top_radius
	c.height = 0.02
	m.mesh = c
	var white := StandardMaterial3D.new()
	white.albedo_color = Color("fffaeb")
	m.material_override = white
	add_child(m)
	m.global_position = at + Vector3.UP * 0.02
	var y := MeshInstance3D.new()
	var yc := CylinderMesh.new()
	yc.top_radius = 0.17
	yc.bottom_radius = 0.17
	yc.height = 0.04
	y.mesh = yc
	var ym := StandardMaterial3D.new()
	ym.albedo_color = Color("f2b225")
	y.material_override = ym
	m.add_child(y)
	var tw := create_tween()
	tw.tween_interval(secunde_cat_raman_ouale_pe_jos)
	tw.tween_callback(m.queue_free)


func _shock_ring(at: Vector3, radius: float) -> void:
	var m := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.9
	tor.outer_radius = 1.0
	m.mesh = tor
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.95, 0.84, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	add_child(m)
	m.global_position = at + Vector3.UP * 0.15
	m.scale = Vector3(0.5, 0.2, 0.5)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(m, "scale", Vector3(radius, 0.2, radius), 0.55).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.55)
	tw.chain().tween_callback(m.queue_free)


# ------------------------------------------------------------------ projectiles
func spawn_projectile(from: Vector3, vel: Vector3, kind: String, grav: float, delay: float, owner_kid: Node) -> void:
	var m := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.09 if kind == "water" else (0.45 if kind == "kiss" else 0.07)
	sp.height = sp.radius * 2.0
	m.mesh = sp
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.49, 0.78, 0.92, 0.75) if kind == "water" else (Color("ff6f8f") if kind == "kiss" else Color("8b847a"))
	if kind == "kiss":
		mat.emission_enabled = true
		mat.emission = Color("ff3d6e")
	if kind == "water":
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material_override = mat
	add_child(m)
	m.global_position = from
	m.visible = delay <= 0.0
	projectiles.append({"node": m, "vel": vel, "grav": grav, "delay": delay, "life": 3.0, "from": owner_kid.global_position, "kind": kind})


func _update_projectiles(dt: float) -> void:
	var space := get_world_3d().direct_space_state
	for p in projectiles.duplicate():
		var n: MeshInstance3D = p.node
		if p.delay > 0.0:
			p.delay -= dt
			continue
		n.visible = true
		var a := n.global_position
		p.vel.y -= p.grav * dt
		var b: Vector3 = a + p.vel * dt
		p.life -= dt
		var dead := false
		if b.distance_to(player.center()) < 0.55 * player.scale_now + 0.1:
			hurt_pigeon(p.from, p.kind == "kiss")
			dead = true
		elif not space.intersect_ray(PhysicsRayQueryParameters3D.create(a, b, 1)).is_empty() or p.life <= 0.0 or b.y < 0.0:
			dead = true
		if dead:
			puff(b, 3, Color(0.49, 0.78, 0.92) if p.kind == "water" else Color("8b847a"))
			n.queue_free()
			projectiles.erase(p)
		else:
			n.global_position = b


# ------------------------------------------------------------------ bottles
func _make_bottle(gold: bool) -> void:
	var root := Node3D.new()
	var model: Node3D = load("res://assets/bottle_gold.glb" if gold else "res://assets/bottle.glb").instantiate()
	model.scale = Vector3.ONE * (marime_sticla_aurie if gold else marime_sticla)
	root.add_child(model)
	var halo := Sprite3D.new()
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 1))
	gr.set_color(1, Color(1, 1, 1, 0))
	gt.gradient = gr
	halo.texture = gt
	halo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	halo.modulate = Color(1, 0.83, 0.42, 0.8) if gold else Color(1, 0.96, 0.88, 0.55)
	halo.pixel_size = (3.0 if gold else 2.0) / 64.0
	halo.position.y = 0.45
	halo.shaded = false
	halo.no_depth_test = false
	root.add_child(halo)
	if gold:
		var beam := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.35
		cyl.bottom_radius = 0.35
		cyl.height = 60.0
		beam.mesh = cyl
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color(1, 0.83, 0.42, 0.16)
		bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bm.cull_mode = BaseMaterial3D.CULL_DISABLED
		beam.material_override = bm
		beam.position.y = 30.0
		root.add_child(beam)
	add_child(root)
	bottle_list.append({"node": root, "model": model, "gold": gold, "alive": false, "respawn": 0.0, "pos": Vector3.ZERO, "ph": randf() * 6.0})


func _hide_bottle(b: Dictionary) -> void:
	b.alive = false
	b.node.visible = false


func _place_bottle(b: Dictionary) -> void:
	for tries in 40:
		var roof := randf() < (sansa_aurie_pe_acoperis if b.gold else sansa_sticla_pe_acoperis)
		var src: Array = roof_spots if roof and not roof_spots.is_empty() else ground_spots
		var s: Array = src.pick_random()
		var pos := Vector3(s[0], (s[2] if s.size() > 2 else 0.0) + 0.35, s[1])
		if Vector2(pos.x - player.global_position.x, pos.z - player.global_position.z).length() < (50.0 if b.gold else 12.0):
			continue
		var close := false
		for o in bottle_list:
			if o != b and o.alive and Vector2(o.pos.x - pos.x, o.pos.z - pos.z).length() < 7.0:
				close = true
				break
		if close:
			continue
		b.pos = pos
		b.alive = true
		b.node.visible = true
		b.node.global_position = pos
		return
	_hide_bottle(b)
	b.respawn = 1.0


func _spin_bottles(dt: float) -> void:
	for b in bottle_list:
		if b.alive:
			b.ph += dt
			b.model.rotation.y += dt * 1.8
			b.node.global_position = b.pos + Vector3.UP * sin(b.ph * 2.4) * 0.12


func _update_bottles(dt: float) -> void:
	var mag: float = raza_magnet_pe_nivel[min(level_of("magnet"), raza_magnet_pe_nivel.size() - 1)] + (2.0 if buff == "giant" else 0.0)
	var c: Vector3 = player.center()
	var golds := 0
	for b in bottle_list:
		if b.gold and (b.alive or b.respawn > 0.0):
			golds += 1
		if not b.alive:
			if b.respawn > 0.0:
				b.respawn -= dt
				if b.respawn <= 0.0 and not b.gold:
					_place_bottle(b)
			continue
		var d: Vector3 = c - b.pos
		var dl := d.length()
		if mag > 0.0 and dl < mag and dl > 0.1:
			b.pos += d * min(1.0, dt * 9.0 / dl * 1.5)
		if dl < 0.95 * player.scale_now + 0.35:
			_collect(b)
	_spin_bottles(dt)
	gold_timer -= dt
	if gold_timer <= 0.0:
		gold_timer = randf_range(aurie_noua_minim, aurie_noua_maxim)
		if golds < GOLDEN_BOTTLES:
			for b in bottle_list:
				if b.gold and not b.alive:
					_place_bottle(b)
					break


func _collect(b: Dictionary) -> void:
	_hide_bottle(b)
	puff(b.pos, 16 if b.gold else 7, Color("f2c14e") if b.gold else Color("fdf7ea"))
	play_sfx(sunet_sticla_aurie if b.gold else sunet_sticla, 0.03)
	if b.gold:
		bottles += sticle_la_sticla_aurie
		total += sticle_la_sticla_aurie
		buff = BUFFS.keys().pick_random()
		buff_t = BUFFS[buff].dur
		auto_egg = 0.0
		_shock_ring(player.global_position, 6.0)
	else:
		bottles += 1
		total += 1
		b.respawn = randf_range(reaparitie_sticla_minim, reaparitie_sticla_maxim)
	while evo < EVO.size() - 1 and total >= EVO[evo + 1].at:
		evolve()


func evolve() -> void:
	evo += 1
	play_sfx(sunet_evolutie)
	if boss_activ and not boss_done and boss == null and evo >= boss_apare_la_nivel and boss_timer < 0.0:
		boss_timer = secunde_pana_apare_boss
	player.set_level(evo)
	player.evo_spin = 1.2
	_shock_ring(player.global_position, 9.0)
	for c in [Color("ff4d8d"), Color("ffd23f"), Color("3bb5ff"), Color("7be0b0")]:
		puff(player.center() + Vector3.UP * player.scale_now * 0.6, 10, c)


# ------------------------------------------------------------------ small effects
func puff(at: Vector3, amount: int, col: Color) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = max(1, amount)
	p.lifetime = 0.7
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.5
	p.gravity = Vector3(0, -6, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var bm := BoxMesh.new()
	bm.size = Vector3(0.12, 0.06, 0.16)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	bm.material = mat
	p.mesh = bm
	add_child(p)
	p.global_position = at
	p.emitting = true
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_callback(p.queue_free)
