class_name Hud
extends CanvasLayer
## Combat HUD for landscape mobile: bars, timer, minimap with fog, full map,
## edge arrows, virtual joystick, buttons, choice panels and the result screen.

const NAVY := Color(0.06, 0.08, 0.18, 0.92)
const GOLD := Color(0.86, 0.7, 0.32)
const IVORY := Color(0.96, 0.94, 0.86)
const CYAN := Color(0.4, 0.9, 1.0)
const CRIMSON := Color(0.95, 0.25, 0.4)
const MINIMAP_SIZE := 108.0
const MINIMAP_TILES := 54.0
const JOY_RADIUS := 34.0

var game: Node
var view: Control
var font: Font

var joystick_vector := Vector2.ZERO
var _joy_index := -1
var _joy_center := Vector2.ZERO
var _joy_knob := Vector2.ZERO

var map_open := false
var _banner := {"text": "", "t": 0.0, "color": IVORY}
var _toasts: Array = []

var _choice_panel: PanelContainer
var _choice_title: Label
var _choice_buttons: Array = []
var _choice_cb: Callable
var _pause_panel: PanelContainer
var _result_panel: PanelContainer
var _result_label: Label
var _dash_btn: Button
var _map_btn: Button
var _pause_btn: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	font = ThemeDB.fallback_font
	view = Control.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.draw.connect(_draw_view)
	add_child(view)

	_dash_btn = _make_button("DASH", Vector2(64, 64), _on_dash)
	_map_btn = _make_button("MAP", Vector2(48, 24), toggle_map)
	_pause_btn = _make_button("II", Vector2(24, 24), toggle_pause)
	_build_choice_panel()
	_build_pause_panel()
	_build_result_panel()


func _process(delta: float) -> void:
	var vs := view.size
	_dash_btn.position = Vector2(vs.x - 84, vs.y - 84)
	_map_btn.position = Vector2(vs.x - MINIMAP_SIZE - 10, MINIMAP_SIZE + 34)
	_pause_btn.position = Vector2(vs.x - 34, MINIMAP_SIZE + 34)
	var cd: float = game.player.dash_cd
	_dash_btn.text = "DASH" if cd <= 0.0 else "%.1f" % cd
	_dash_btn.disabled = cd > 0.0
	_banner["t"] = max(0.0, _banner["t"] - delta)
	for t in _toasts:
		t["t"] -= delta
	_toasts = _toasts.filter(func(t): return t["t"] > 0.0)
	view.queue_redraw()


# ------------------------------------------------------------------ input

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _joy_index == -1 and event.position.x < view.size.x * 0.5 and not get_tree().paused:
			_joy_index = event.index
			_joy_center = event.position
			_joy_knob = event.position
			joystick_vector = Vector2.ZERO
		elif not event.pressed and event.index == _joy_index:
			_joy_index = -1
			joystick_vector = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == _joy_index:
		var off: Vector2 = (event.position - _joy_center).limit_length(JOY_RADIUS)
		_joy_knob = _joy_center + off
		joystick_vector = off / JOY_RADIUS
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_SPACE: _on_dash()
			KEY_M: toggle_map()
			KEY_ESCAPE, KEY_P: toggle_pause()


func _on_dash() -> void:
	if not get_tree().paused:
		game.player.try_dash()


func toggle_map() -> void:
	if _result_panel.visible:
		return
	map_open = not map_open
	Engine.time_scale = 0.3 if map_open else 1.0


func toggle_pause() -> void:
	if _choice_panel.visible or _result_panel.visible:
		return
	_pause_panel.visible = not _pause_panel.visible
	get_tree().paused = _pause_panel.visible


# ------------------------------------------------------------------ messages

func banner(text: String, color := IVORY, seconds := 3.0) -> void:
	_banner = {"text": text, "t": seconds, "color": color}


func toast(text: String, color := IVORY) -> void:
	_toasts.push_front({"text": text, "t": 3.0, "color": color})
	if _toasts.size() > 4:
		_toasts.resize(4)


## Shows 1-of-3 choices; pauses the game until one is picked.
func show_choices(title: String, options: Array, cb: Callable) -> void:
	_choice_title.text = title
	_choice_cb = cb
	for i in _choice_buttons.size():
		var b: Button = _choice_buttons[i]
		if i < options.size():
			b.visible = true
			b.text = "%s\n%s" % [options[i]["name"], options[i]["desc"]]
			var col: Color = options[i].get("color", IVORY)
			b.add_theme_color_override("font_color", col)
			b.add_theme_color_override("font_hover_color", col.lightened(0.3))
			b.add_theme_color_override("font_pressed_color", col.lightened(0.3))
			b.set_meta("option", options[i])
		else:
			b.visible = false
	_choice_panel.visible = true
	get_tree().paused = true
	if map_open:
		toggle_map()


func choices_open() -> bool:
	return _choice_panel.visible


func pick_choice(i: int) -> void:
	var b: Button = _choice_buttons[i]
	if not b.visible:
		return
	_choice_panel.visible = false
	get_tree().paused = false
	_choice_cb.call(b.get_meta("option"))


func show_result(text: String) -> void:
	if map_open:
		toggle_map()
	_result_label.text = text
	_result_panel.visible = true
	_pause_panel.visible = false
	_choice_panel.visible = false
	get_tree().paused = true


# ------------------------------------------------------------------ drawing

func _draw_view() -> void:
	var vs := view.size
	_draw_player_panel()
	_draw_timer(vs)
	_draw_top_right(vs)
	_draw_minimap(Rect2(vs.x - MINIMAP_SIZE - 10, 28, MINIMAP_SIZE, MINIMAP_SIZE))
	_draw_edge_arrows(vs)
	if _joy_index != -1:
		view.draw_circle(_joy_center, JOY_RADIUS, Color(1, 1, 1, 0.12))
		view.draw_arc(_joy_center, JOY_RADIUS, 0, TAU, 32, Color(1, 1, 1, 0.35), 1.5)
		view.draw_circle(_joy_knob, 12, Color(1, 1, 1, 0.4))
	elif not game.run_over:
		_text(Vector2(70, vs.y - 30), "drag here to move", Color(1, 1, 1, 0.25), 8, true)
	var y := vs.y - 110
	for t in _toasts:
		_text(Vector2(vs.x * 0.5, y), t["text"], Color(t["color"], min(1.0, t["t"])), 10, true)
		y -= 14
	if _banner["t"] > 0.0:
		var a: float = min(1.0, _banner["t"])
		view.draw_rect(Rect2(vs.x * 0.5 - 150, 52, 300, 22), Color(0, 0, 0, 0.5 * a))
		_text(Vector2(vs.x * 0.5, 67), _banner["text"], Color(_banner["color"], a), 12, true)
	if map_open:
		_draw_full_map(vs)


func _draw_player_panel() -> void:
	var p: Player = game.player
	view.draw_rect(Rect2(6, 6, 30, 30), NAVY)
	view.draw_rect(Rect2(6, 6, 30, 30), GOLD, false, 1.0)
	view.draw_circle(Vector2(21, 22), 8, Color(0.98, 0.86, 0.78))
	view.draw_rect(Rect2(12, 11, 18, 6), Color(0.85, 0.88, 0.95))
	_text(Vector2(30, 44), "Lv %d" % game.level, IVORY, 8, true)
	_bar(Rect2(40, 8, 120, 8), p.hp / p.stats["max_hp"], Color(0.9, 0.25, 0.3))
	_text(Vector2(100, 15), "%d / %d" % [ceili(p.hp), int(p.stats["max_hp"])], IVORY, 7, true)
	_bar(Rect2(40, 19, 120, 4), game.xp / game.xp_next, CYAN)
	# tome slots (empty slots shown as dim frames)
	var tx := 40.0
	var tome_ids: Array = p.tomes.keys()
	for i in GameData.TOME_SLOTS:
		var r := Rect2(tx, 26, 28, 12)
		view.draw_rect(r, NAVY)
		if i < tome_ids.size():
			var t: Dictionary = GameData.tome_by_id(tome_ids[i])
			view.draw_rect(r, CYAN, false, 1.0)
			var short: String = t["name"].replace("Tome of ", "").replace(" Tome", "").substr(0, 3)
			_text(Vector2(tx + 2, 35), short, IVORY, 7, false)
			_text(Vector2(tx + 21, 35), str(p.tomes[tome_ids[i]]), CYAN, 7, true)
		else:
			view.draw_rect(r, Color(1, 1, 1, 0.15), false, 1.0)
		tx += 30.0
	if p.weapon_levels.has("nova"):
		_text(Vector2(tx + 2, 35), "Nova %d" % p.weapon_levels["nova"], Color(0.6, 0.9, 1.0), 7, false)
	# owned items
	var x := 40.0
	for id in game.items_owned:
		var it: Dictionary = game.item_by_id(id)
		var col: Color = GameData.RARITY_COLORS[int(it["rarity"])]
		view.draw_rect(Rect2(x, 41, 12, 12), NAVY)
		view.draw_rect(Rect2(x, 41, 12, 12), col, false, 1.0)
		_text(Vector2(x + 6, 50), it["name"].substr(0, 1), col, 8, true)
		var n: int = game.items_owned[id]
		if n > 1:
			_text(Vector2(x + 11, 56), str(n), IVORY, 6, true)
		x += 14.0


func _draw_timer(vs: Vector2) -> void:
	var cx := vs.x * 0.5
	var rem: float = game.time_left()
	var txt := "%02d:%02d" % [int(rem) / 60, int(rem) % 60]
	var col := IVORY
	if game.final_swarm:
		txt = "FINAL SWARM +%02d:%02d" % [int(game.final_swarm_t) / 60, int(game.final_swarm_t) % 60]
		col = CRIMSON
	elif game.surge_active():
		col = Color(1, 0.6, 0.3)
	_text(Vector2(cx, 20), txt, col, 14, true)
	var b = game.enemies.boss
	if b != null and b.spawn_t <= 0.0:
		_bar(Rect2(cx - 120, 26, 240, 6), b.hp / b.max_hp, CRIMSON)
		_text(Vector2(cx, 44), GameData.BOSS["name"], Color(1, 0.6, 0.6), 8, true)
	else:
		_bar(Rect2(cx - 120, 26, 240, 3), 1.0 - rem / GameData.RUN_TIME, Color(0.6, 0.4, 0.9))
		for s in GameData.SURGES:
			var sx: float = cx - 120 + 240 * float(s["at"]) / GameData.RUN_TIME
			view.draw_rect(Rect2(sx - 1, 24, 2, 7), Color(1, 0.55, 0.25))


func _draw_top_right(vs: Vector2) -> void:
	var x := vs.x - MINIMAP_SIZE - 10
	_text(Vector2(x, 20), "Kills %d" % game.kills, IVORY, 9, false)
	_text(Vector2(x + 62, 20), "%d g" % game.gold, Color(1, 0.85, 0.3), 9, false)


func _draw_minimap(r: Rect2) -> void:
	var world: World = game.world
	var ppos: Vector2 = game.player.position / GameData.TILE
	var half := MINIMAP_TILES * 0.5
	var center := Vector2(clamp(ppos.x, half, world.w - half), clamp(ppos.y, half, world.h - half))
	var src := Rect2(center - Vector2(half, half), Vector2(MINIMAP_TILES, MINIMAP_TILES))
	view.draw_rect(r.grow(2), NAVY)
	view.draw_texture_rect_region(world.minimap_texture, r, src)
	view.draw_texture_rect_region(game.fog.texture, r, src)
	view.draw_rect(r.grow(1), GOLD, false, 1.0)
	var to_screen := func(world_px: Vector2) -> Vector2:
		return r.position + (world_px / GameData.TILE - src.position) * (r.size.x / MINIMAP_TILES)
	var inside := func(p: Vector2) -> bool: return r.grow(-2).has_point(p)
	_draw_pois(to_screen, inside, 2.0)
	for e in game.enemies.list:
		if e.elite or e.boss:
			var sp: Vector2 = to_screen.call(e.pos)
			if inside.call(sp):
				view.draw_circle(sp, 2.5 if e.boss else 1.8, Color(1, 0.5, 0.1) if e.elite else CRIMSON)
	var pp: Vector2 = to_screen.call(game.player.position)
	view.draw_circle(pp, 2.5, Color.WHITE)


func _draw_pois(to_screen: Callable, inside: Callable, s: float) -> void:
	var it: Interactables = game.interactables
	for c in it.chests:
		if not c["discovered"]:
			continue
		var sp: Vector2 = to_screen.call(c["pos"])
		if inside.call(sp):
			var col := Color(1, 0.8, 0.2) if c["golden"] else Color(0.7, 0.5, 1.0)
			if c["opened"]:
				col = Color(col, 0.25)
			view.draw_rect(Rect2(sp - Vector2(s, s), Vector2(s, s) * 2), col)
	for sh in it.shrines:
		if not sh["discovered"]:
			continue
		var sp: Vector2 = to_screen.call(sh["pos"])
		if inside.call(sp):
			var col: Color = GameData.SHRINE_TYPES[sh["type"]]["color"]
			view.draw_circle(sp, s * 1.1, Color(col, 0.25 if sh["used"] else 1.0))
	if it.portal["discovered"]:
		var sp: Vector2 = to_screen.call(it.portal["pos"])
		if inside.call(sp):
			view.draw_circle(sp, s * 1.8, CRIMSON)
			view.draw_circle(sp, s * 0.8, Color(0.1, 0, 0.1))
	if it.exit_portal["active"]:
		var sp: Vector2 = to_screen.call(it.exit_portal["pos"])
		if inside.call(sp):
			view.draw_circle(sp, s * 1.8, CYAN)


func _draw_full_map(vs: Vector2) -> void:
	view.draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.75))
	var side: float = min(vs.y - 50, vs.x - 40)
	var r := Rect2(Vector2((vs.x - side) * 0.5, 30), Vector2(side, side))
	var world: World = game.world
	view.draw_texture_rect(world.minimap_texture, r, false)
	view.draw_texture_rect(game.fog.texture, r, false)
	view.draw_rect(r.grow(1), GOLD, false, 1.0)
	var scale := side / world.w
	var to_screen := func(world_px: Vector2) -> Vector2: return r.position + world_px / GameData.TILE * scale
	var inside := func(p: Vector2) -> bool: return r.has_point(p)
	_draw_pois(to_screen, inside, 2.5)
	view.draw_circle(to_screen.call(game.player.position), 3.0, Color.WHITE)
	_text(Vector2(vs.x * 0.5, 22), "MAP  —  explored %d%%   (time slowed)" % int(game.fog.explored_ratio() * 100), IVORY, 10, true)
	_text(Vector2(vs.x * 0.5, r.end.y + 12), "purple: chest   gold: free chest   circle: shrine   red: Rift Portal", Color(1, 1, 1, 0.6), 8, true)


func _draw_edge_arrows(vs: Vector2) -> void:
	if game.run_over:
		return
	var cam: Camera2D = game.camera
	var center := cam.get_screen_center_position()
	var it: Interactables = game.interactables
	if it.portal["discovered"] and it.portal["state"] != "boss":
		_edge_arrow(vs, center, it.portal["pos"], CRIMSON, 7.0)
	if it.exit_portal["active"]:
		_edge_arrow(vs, center, it.exit_portal["pos"], CYAN, 7.0)
	var shown := 0
	for e in game.enemies.list:
		if (e.elite or e.boss) and shown < 3:
			_edge_arrow(vs, center, e.pos, Color(1, 0.55, 0.15), 5.0)
			shown += 1


func _edge_arrow(vs: Vector2, cam_center: Vector2, target: Vector2, col: Color, size: float) -> void:
	var rel := target - cam_center
	var half := vs * 0.5
	var inset := half - Vector2(26, 26)
	if absf(rel.x) < half.x - 8 and absf(rel.y) < half.y - 8:
		return
	var k: float = min(inset.x / max(0.001, absf(rel.x)), inset.y / max(0.001, absf(rel.y)))
	var p := half + rel * k
	p.y = max(p.y, 72.0)  # keep arrows below the top HUD band (bars, timer, minimap)
	if p.x > vs.x - MINIMAP_SIZE - 20 and p.y < MINIMAP_SIZE + 64:
		p.y = MINIMAP_SIZE + 64
	var d := rel.normalized()
	var n := d.orthogonal()
	view.draw_colored_polygon(PackedVector2Array([p + d * size, p - d * size * 0.6 + n * size * 0.8, p - d * size * 0.6 - n * size * 0.8]), col)


func _bar(r: Rect2, ratio: float, col: Color) -> void:
	view.draw_rect(r.grow(1), Color(0, 0, 0, 0.7))
	view.draw_rect(Rect2(r.position, Vector2(r.size.x * clamp(ratio, 0.0, 1.0), r.size.y)), col)


func _text(p: Vector2, s: String, col: Color, fs: int, centered: bool) -> void:
	var pos := p
	if centered:
		pos.x -= font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * 0.5
	view.draw_string_outline(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, col.a * 0.85))
	view.draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


# ------------------------------------------------------------------ widgets

func _style(border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = NAVY
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.set_content_margin_all(6)
	return sb


func _make_button(text: String, size: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 9)
	b.add_theme_stylebox_override("normal", _style(GOLD))
	b.add_theme_stylebox_override("hover", _style(CYAN))
	b.add_theme_stylebox_override("pressed", _style(CYAN))
	b.add_theme_stylebox_override("disabled", _style(Color(0.4, 0.4, 0.4)))
	b.pressed.connect(cb)
	add_child(b)
	return b


func _centered_panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(GOLD))
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.visible = false
	add_child(p)
	return p


func _build_choice_panel() -> void:
	_choice_panel = _centered_panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_choice_panel.add_child(box)
	_choice_title = Label.new()
	_choice_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_choice_title.add_theme_font_size_override("font_size", 12)
	_choice_title.add_theme_color_override("font_color", GOLD)
	box.add_child(_choice_title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	for i in 3:
		var b := Button.new()
		b.custom_minimum_size = Vector2(186, 56)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 9)
		b.add_theme_stylebox_override("normal", _style(Color(0.5, 0.45, 0.7)))
		b.add_theme_stylebox_override("hover", _style(CYAN))
		b.add_theme_stylebox_override("pressed", _style(CYAN))
		b.pressed.connect(pick_choice.bind(i))
		row.add_child(b)
		_choice_buttons.append(b)


func _build_pause_panel() -> void:
	_pause_panel = _centered_panel()
	var box := VBoxContainer.new()
	_pause_panel.add_child(box)
	var l := Label.new()
	l.text = "PAUSED"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", GOLD)
	box.add_child(l)
	var info := Label.new()
	info.name = "Info"
	info.add_theme_font_size_override("font_size", 9)
	box.add_child(info)
	var resume := Button.new()
	resume.text = "Resume"
	resume.pressed.connect(toggle_pause)
	box.add_child(resume)
	var restart := Button.new()
	restart.text = "New run (new map)"
	restart.pressed.connect(func(): game.restart())
	box.add_child(restart)
	_pause_panel.visibility_changed.connect(func():
		if _pause_panel.visible:
			info.text = "Seed %d\nEsc/P pause · M map · Space dash · WASD move" % game.seed_value)


func _build_result_panel() -> void:
	_result_panel = _centered_panel()
	var box := VBoxContainer.new()
	_result_panel.add_child(box)
	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 10)
	_result_label.custom_minimum_size = Vector2(260, 0)
	box.add_child(_result_label)
	var again := Button.new()
	again.text = "Run again (new map)"
	again.pressed.connect(func(): game.restart())
	box.add_child(again)
