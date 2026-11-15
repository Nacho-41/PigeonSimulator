extends CanvasLayer
## All 2D interface, built in code: bottle counter, lives, golden power-up bar,
## egg cooldown, menu, pause, shop and game-over panels.

var INK := Color("1d1236")
var PAPER := Color("fff6dd")
var TERRA := Color("ff4d8d")
var YELLOW := Color("ffd23f")
var TEXT := Color.WHITE
const BLUE := Color("3bb5ff")
const MINT := Color("7be0b0")

var comic: Font
var body_font: FontVariation
var lvl_name: Label
var lvl_bar: ProgressBar
var lvl_next: Label

var game: Node
var lbl_bottles: Label
var lives_box: HBoxContainer
var buff_panel: PanelContainer
var buff_name: Label
var buff_bar: ProgressBar
var egg_bar: ProgressBar
var flap_bar: ProgressBar
var hint: Label
var hint_chip: PanelContainer
var hud_root: Control
var menu: Control
var pause: Control
var over: Control
var loading: Control
var won: Control
var credit: Label
var video_root: Control
var video_player: VideoStreamPlayer
var video_sub: Label
var video_subs: Array = []
var video_done: Callable
var won_stats: Label
var boss_panel: PanelContainer
var boss_name: Label
var boss_bar: ProgressBar
var shop: Control
var shop_list: VBoxContainer
var shop_have: Label
var over_stats: Label


func _ready() -> void:
	INK = game.culoare_contur
	PAPER = game.culoare_fundal
	TERRA = game.culoare_accent
	YELLOW = game.culoare_butoane
	TEXT = game.culoare_text
	comic = game.font_titluri
	body_font = FontVariation.new()
	body_font.base_font = game.font_text
	body_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): game.grosime_font_text}
	var th := Theme.new()
	th.default_font = body_font
	th.default_font_size = 16
	hud_root = Control.new()
	hud_root.theme = th
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_root)
	# --- evolution level
	var lc := _chip(Vector2(18, 16))
	lc.visible = game.arata_evolutie
	var lvb := VBoxContainer.new()
	lvb.custom_minimum_size = Vector2(240, 0)
	lc.add_child(lvb)
	lvl_name = _label("Pigeon Basic", 26, TERRA, true)
	lvl_name.add_theme_constant_override("outline_size", 4)
	lvl_name.add_theme_color_override("font_outline_color", INK)
	lvb.add_child(lvl_name)
	lvl_bar = _bar(TERRA, Vector2(240, 14))
	lvb.add_child(lvl_bar)
	lvl_next = _label("evoluție  0 / 15", 13, TEXT)
	lvb.add_child(lvl_next)
	# --- wallet
	var wallet := _chip(Vector2(18, 112))
	wallet.visible = game.arata_numar_sticle
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	wallet.add_child(hb)
	var icon := TextureRect.new()
	icon.texture = load("res://ui/bottle.svg")
	icon.custom_minimum_size = Vector2(22, 34)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb.add_child(icon)
	lbl_bottles = _label("0", 34, TEXT, true)
	hb.add_child(lbl_bottles)
	# --- lives
	var lp := _chip(Vector2(150, 112))
	lp.visible = game.arata_vieti
	lives_box = HBoxContainer.new()
	lp.add_child(lives_box)
	for i in game.MAX_LIVES:
		var l := TextureRect.new()
		l.texture = load("res://ui/life.svg")
		l.custom_minimum_size = Vector2(26, 26)
		l.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		l.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lives_box.add_child(l)
	# --- golden power-up
	buff_panel = _chip(Vector2(18, 178))
	var vb := VBoxContainer.new()
	buff_panel.add_child(vb)
	buff_name = _label("", 22, YELLOW, true)
	vb.add_child(buff_name)
	buff_bar = _bar(YELLOW, Vector2(200, 12))
	vb.add_child(buff_bar)
	buff_panel.visible = false
	# --- egg cooldown + wing flaps (bottom centre)
	egg_bar = _bar(TERRA, Vector2(120, 8))
	egg_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	egg_bar.position = Vector2(-60, -34)
	hud_root.add_child(egg_bar)
	egg_bar.visible = game.arata_bara_oua
	flap_bar = _bar(MINT, Vector2(120, 10))
	flap_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	flap_bar.position = Vector2(-60, -50)
	hud_root.add_child(flap_bar)
	hint = _label("E  ·  chioșc Actimel", 16, TEXT)
	boss_panel = _chip(Vector2.ZERO)
	boss_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_panel.position = Vector2(-210, 16)
	var bvb := VBoxContainer.new()
	boss_panel.add_child(bvb)
	boss_name = _label(game.nume_boss, 26, TERRA, true)
	boss_name.add_theme_constant_override("outline_size", 4)
	boss_name.add_theme_color_override("font_outline_color", INK)
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bvb.add_child(boss_name)
	boss_bar = _bar(Color("e63946"), Vector2(396, 16))
	bvb.add_child(boss_bar)
	boss_panel.visible = false
	hint_chip = _chip(Vector2.ZERO)
	hint_chip.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint_chip.position = Vector2(-90, -110)
	hint_chip.add_child(hint)
	# --- screens
	if game.imagine_pornire and game.imagine_ca_meniu:
		menu = _splash_screen(game.imagine_pornire, game.text_meniu, [[game.buton_start, Callable(game, "start_game")]])
	else:
		menu = _screen(game.titlu_meniu, game.text_meniu, [[game.buton_start, Callable(game, "start_game")]])
	pause = _screen(game.titlu_pauza, "", [["CONTINUĂ", Callable(game, "resume_game")], ["DE LA CAPĂT", Callable(game, "start_game")]])
	over = _screen(game.titlu_prins, "", [["ÎNCĂ O DATĂ!", Callable(game, "start_game")]])
	over_stats = over.find_child("Body", true, false)
	won = _screen(game.titlu_victorie, "", [["CONTINUĂ", Callable(game, "continue_after_win")], ["ÎNCĂ O DATĂ!", Callable(game, "start_game")]])
	won_stats = won.find_child("Body", true, false)
	if game.imagine_pornire:
		loading = _splash_screen(game.imagine_pornire, game.text_incarcare)
	else:
		loading = _screen("SE ÎNCARCĂ…", "Construim Brașovul (418 clădiri). Durează câteva secunde.", [])
	_build_shop()
	# --- credit OpenStreetMap (licența ODbL cere să fie vizibil)
	credit = _label(game.text_credite, 13, Color(1, 1, 1, 0.92))
	credit.add_theme_constant_override("outline_size", 4)
	credit.add_theme_color_override("font_outline_color", Color(INK, 0.85))
	credit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(credit)
	credit.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 10)
	credit.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	credit.grow_vertical = Control.GROW_DIRECTION_BEGIN
	show_screen("loading")


# ---------------------------------------------------------------- builders
func _style(bg: Color, radius := 18) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_color = INK
	s.set_border_width_all(4)
	s.shadow_color = INK
	s.shadow_size = 1
	s.shadow_offset = Vector2(5, 5)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


func _chip(pos: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(PAPER))
	p.position = pos
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(p)
	return p


func _label(text: String, size: int, col: Color, big := false) -> Label:
	var l := Label.new()
	l.text = text
	if big:
		l.add_theme_font_override("font", comic)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


func _bar(col: Color, size: Vector2) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = size
	b.size = size
	b.show_percentage = false
	b.max_value = 1.0
	b.step = 0.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = PAPER.darkened(0.45)
	bg.set_corner_radius_all(8)
	bg.border_color = INK
	bg.set_border_width_all(3)
	var fg := StyleBoxFlat.new()
	fg.bg_color = col
	fg.set_corner_radius_all(6)
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", comic)
	b.add_theme_font_size_override("font_size", 28)
	b.add_theme_stylebox_override("normal", _style(YELLOW, 14))
	b.add_theme_stylebox_override("hover", _style(YELLOW.lightened(0.3), 14))
	b.add_theme_stylebox_override("pressed", _style(TERRA, 14))
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.pressed.connect(cb)
	return b


func _screen(title: String, body: String, buttons: Array) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	root.theme = hud_root.theme
	var dim := ColorRect.new()
	dim.color = Color(0.11, 0.07, 0.21, 0.28)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var card := PanelContainer.new()
	var st := _style(PAPER, 14)
	st.content_margin_left = 34
	st.content_margin_right = 34
	st.content_margin_top = 28
	st.content_margin_bottom = 28
	card.add_theme_stylebox_override("panel", st)
	center.add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	card.add_child(vb)
	var tl := _label(title, 64, YELLOW, true)
	tl.add_theme_constant_override("outline_size", 10)
	tl.add_theme_color_override("font_outline_color", INK)
	tl.add_theme_constant_override("shadow_offset_x", 5)
	tl.add_theme_constant_override("shadow_offset_y", 5)
	tl.add_theme_color_override("font_shadow_color", INK)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(tl)
	var b := _label(body, 16, TEXT)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.name = "Body"
	vb.add_child(b)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)
	for item in buttons:
		row.add_child(_button(item[0], item[1]))
	return root


func _splash_screen(tex: Texture2D, text: String, buttons: Array = []) -> Control:
	# imaginea de pornire pe tot ecranul + o etichetă mică „se încarcă” jos
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	root.theme = hud_root.theme
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var img := TextureRect.new()
	img.texture = tex
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(img)
	# jos, pe mijloc: butoanele (dacă sunt) și textul într-o etichetă
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_END
	box.add_theme_constant_override("separation", 12)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_bottom = -34
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)
	if not buttons.is_empty():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10)
		for item in buttons:
			row.add_child(_button(item[0], item[1]))
		box.add_child(row)
	var chip := _chip(Vector2.ZERO)
	hud_root.remove_child(chip)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var l := _label(text.strip_edges().replace("\n\n", "\n"), 16 if buttons.size() > 0 else 20, TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(l)
	box.add_child(chip)
	return root


func _build_shop() -> void:
	shop = Control.new()
	shop.theme = hud_root.theme
	shop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop.add_child(center)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style(PAPER, 14))
	card.custom_minimum_size = Vector2(560, 0)
	center.add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	card.add_child(vb)
	var st2 := _label("CHIOȘCUL DE ACTIMEL", 40, TERRA, true)
	st2.add_theme_constant_override("outline_size", 6)
	st2.add_theme_color_override("font_outline_color", INK)
	vb.add_child(st2)
	shop_have = _label("", 16, TEXT)
	vb.add_child(shop_have)
	shop_list = VBoxContainer.new()
	vb.add_child(shop_list)
	vb.add_child(_button("Închide  (E)", Callable(game, "close_shop")))


func refresh_shop() -> void:
	shop_have.text = "Ai %d sticle. Taste 1–7 pentru a cumpăra." % game.bottles
	for c in shop_list.get_children():
		c.queue_free()
	for i in game.SHOP.size():
		var it: Dictionary = game.SHOP[i]
		var cost = game.item_cost(i)
		var lvl: int = game.level_of(it.id)
		var levels := "" if it.get("repeat", false) else "   " + "■".repeat(lvl) + "□".repeat(it.cost.size() - lvl)
		var price := "maxim" if cost == null else "%d sticle" % cost
		var b := Button.new()
		b.text = "%d.  %s — %s%s   [%s]" % [i + 1, it.name, it.desc, levels, price]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 15)
		b.add_theme_stylebox_override("normal", _style(PAPER.lightened(0.14), 12))
		b.add_theme_stylebox_override("hover", _style(YELLOW, 12))
		b.add_theme_stylebox_override("disabled", _style(PAPER.darkened(0.25), 12))
		b.add_theme_color_override("font_color", TEXT)
		b.add_theme_color_override("font_hover_color", INK)
		b.add_theme_color_override("font_disabled_color", Color(TEXT, 0.4))
		b.disabled = not game.can_buy(i)
		b.pressed.connect(func(): game.buy(i))
		shop_list.add_child(b)


# ---------------------------------------------------------------- video
func play_video(stream: VideoStream, subs: PackedStringArray, on_done: Callable) -> void:
	# videoclipul pe tot ecranul (păstrează forma, cu negru pe margini) + subtitrări jos
	stop_video()
	video_root = Control.new()
	video_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	video_root.theme = hud_root.theme
	add_child(video_root)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	video_root.add_child(bg)
	var arc := AspectRatioContainer.new()
	arc.set_anchors_preset(Control.PRESET_FULL_RECT)
	video_root.add_child(arc)
	video_player = VideoStreamPlayer.new()
	video_player.stream = stream
	video_player.expand = true
	video_player.volume_db = game.volum_efecte_db
	arc.add_child(video_player)
	var vsize := Vector2(9, 16)
	video_player.play()
	if video_player.get_video_texture():
		var s: Vector2 = video_player.get_video_texture().get_size()
		if s.x > 0 and s.y > 0:
			vsize = s
	arc.ratio = vsize.x / vsize.y
	video_sub = _label("", 30, Color.WHITE, true)
	video_sub.add_theme_constant_override("outline_size", 10)
	video_sub.add_theme_color_override("font_outline_color", Color.BLACK)
	video_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	video_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	video_sub.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	video_sub.offset_top = -150
	video_sub.offset_bottom = -50
	video_sub.offset_left = 60
	video_sub.offset_right = -60
	video_sub.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	video_root.add_child(video_sub)
	video_subs.clear()
	for line in subs:
		var parts := line.split("|")
		if parts.size() >= 3 and parts[2].strip_edges() != "":
			video_subs.append([float(parts[0]), float(parts[1]), parts[2].strip_edges()])
	video_done = on_done
	video_player.finished.connect(_on_video_finished)
	hud_root.visible = false
	for s in [menu, pause, over, won, loading, shop]:
		s.visible = false


func _on_video_finished() -> void:
	var cb := video_done
	stop_video()
	if cb.is_valid():
		cb.call()


func stop_video() -> void:
	video_done = Callable()
	if video_root:
		video_root.queue_free()
		video_root = null
		video_player = null
		video_sub = null


func show_screen(which: String) -> void:
	loading.visible = which == "loading"
	won.visible = which == "won"
	menu.visible = which == "menu"
	pause.visible = which == "pause"
	over.visible = which == "over"
	shop.visible = which == "shop"
	hud_root.visible = which != "menu" and which != "loading" and which != "won"
	if credit:
		credit.visible = which in ["menu", "loading", "won", "over", "pause"] or game.credite_in_joc
	if which == "shop":
		refresh_shop()


func set_win_stats(time_s: int, total: int, launched: int) -> void:
	won_stats.text = "L-ai învins pe %s!\ntimp %d:%02d   ·   %d sticle strânse   ·   %d copii aruncați" % [game.nume_boss, time_s / 60, time_s % 60, total, launched]


func set_over_stats(time_s: int, total: int, launched: int) -> void:
	over_stats.text = "%s   ·   timp %d:%02d   ·   %d sticle strânse   ·   %d copii aruncați" % [game.EVO[game.evo].name, time_s / 60, time_s % 60, total, launched]


func _process(_dt: float) -> void:
	if video_player and video_sub:
		var pos := video_player.stream_position
		var txt := ""
		for s in video_subs:
			if pos >= s[0] and pos <= s[1]:
				txt = s[2]
		video_sub.text = txt
	if game == null or game.player == null:
		return
	lbl_bottles.text = str(game.bottles)
	# keep the centred panels centred whatever the window size
	var vw: float = get_viewport().get_visible_rect().size.x
	var vh: float = get_viewport().get_visible_rect().size.y
	boss_panel.position = Vector2((vw - boss_panel.size.x) * 0.5, 16)
	hint_chip.position = Vector2((vw - hint_chip.size.x) * 0.5, vh - 120)
	egg_bar.position = Vector2((vw - egg_bar.size.x) * 0.5, vh - 34)
	flap_bar.position = Vector2((vw - flap_bar.size.x) * 0.5, vh - 50)
	var b = game.boss
	boss_panel.visible = is_instance_valid(b) and b.state != "dead" and b.state != "intro"
	if boss_panel.visible:
		boss_bar.value = float(b.hp) / float(b.max_hp)
	lvl_name.text = game.EVO[game.evo].name
	if game.evo < game.EVO.size() - 1:
		var a: int = game.EVO[game.evo].at
		var nx: int = game.EVO[game.evo + 1].at
		lvl_bar.value = clamp(float(game.total - a) / float(nx - a), 0.0, 1.0)
		lvl_next.text = "evoluție  %d / %d" % [game.total, nx]
	else:
		lvl_bar.value = 1.0
		lvl_next.text = "evoluție  maxim"
	for i in lives_box.get_child_count():
		lives_box.get_child(i).modulate.a = 1.0 if i < game.lives else 0.22
	buff_panel.visible = game.buff != ""
	if game.buff != "":
		buff_name.text = game.BUFFS[game.buff].name.to_upper()
		buff_bar.value = game.buff_t / game.BUFFS[game.buff].dur
	egg_bar.value = 1.0 - game.egg_cd / max(game.pauza_intre_explozii, 0.01)
	var mf: int = game.player.max_flaps()
	flap_bar.visible = mf > 0 and mf < 50 and not game.player.is_on_floor()
	if flap_bar.visible:
		flap_bar.value = float(game.player.flaps) / mf
	hint_chip.visible = game.state == "play" and game.near_shop()
