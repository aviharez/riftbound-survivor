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

var _choice_panel: ColorRect
var _choice_title: Label
var _choice_sub: Label
var _choice_row: HBoxContainer
var _choice_buttons: Array = []
var _choice_cb: Callable
var _pause_panel: PanelContainer
var _result_panel: PanelContainer
var _result_box: VBoxContainer
var _overlay_root: Control
var _result_title: Label
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
	_choice_title.text = title.get_slice(" — ", 0)
	_choice_sub.text = title.get_slice(" — ", 1).capitalize() if " — " in title else "Choose one"
	_choice_cb = cb
	for c in _choice_row.get_children():
		c.queue_free()
	_choice_buttons.clear()
	for i in options.size():
		var b := _choice_card(options[i])
		b.pressed.connect(pick_choice.bind(i))
		_choice_row.add_child(b)
		_choice_buttons.append(b)
	_choice_panel.visible = true
	get_tree().paused = true
	if map_open:
		toggle_map()


## One compact level-up / boon card: kind tag + level, icon slot, name, effect, rarity strip.
func _choice_card(opt: Dictionary) -> Button:
	var kind := String(opt.get("kind", "boon"))
	var d: Dictionary = opt.get("def", opt)
	var col: Color = opt.get("color", UiKit.GREEN)
	var tag: String = {"weapon": "WEAPON", "tome": "TOME", "fallback": "BONUS", "boon": "BOON"}.get(kind, "BOON")
	if kind == "weapon":
		col = Color("6fe3ff")
	elif kind == "boon":
		col = Color("6dff8a")
	elif kind == "fallback":
		col = UiKit.GOLD
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(128, 150)
	b.set_meta("option", opt)
	var st := UiKit.rarity_style(col, 6.0)
	st.drop = 2
	b.add_theme_stylebox_override("normal", st)
	var hv := UiKit.rarity_style(col.lightened(0.25), 6.0)
	hv.glow = Color(col, 0.6)
	hv.drop = 2
	b.add_theme_stylebox_override("hover", hv)
	var pr := UiKit.rarity_style(col, 6.0)
	pr.drop = 0
	b.add_theme_stylebox_override("pressed", pr)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 7
	box.offset_right = -7
	box.offset_top = 6
	box.offset_bottom = -6
	box.add_theme_constant_override("separation", 3)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	# top: kind tag and level
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(top)
	var t := UiKit.title(tag, 8, col)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	var lv := int(opt.get("level", -1))
	if lv >= 0:
		var lvl := UiKit.title("NEW" if lv == 0 else "LV %d>%d" % [lv, lv + 1], 8, UiKit.GREEN if lv == 0 else UiKit.IVORY)
		top.add_child(lvl)
	# icon slot
	var slot := UiKit.slot(UiKit.option_icon(opt), 72.0, col)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(slot)
	# name
	var nm := UiKit.title(String(d.get("name", opt.get("name", ""))).to_upper(), 8, IVORY)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.custom_minimum_size = Vector2(114, 0)
	box.add_child(nm)
	# effect text; a combo hint (second line) in gold
	var desc := String(opt.get("desc", ""))
	var lines := desc.split("\n")
	var main_text := lines[0]
	if kind == "tome" and "  ·  " in main_text:
		main_text = main_text.get_slice("  ·  ", 1)   # the rarity has its own strip
	var dl := UiKit.label(main_text, 8, Color("d8d2ee"))
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.custom_minimum_size = Vector2(114, 0)
	box.add_child(dl)
	for k in range(1, lines.size()):
		var cl := UiKit.label(lines[k], 8, UiKit.GOLD)
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cl.custom_minimum_size = Vector2(114, 0)
		box.add_child(cl)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(fill)
	# bottom strip: rarity for tomes, else the kind's colour
	var strip_text := "BOON"
	if kind == "tome":
		strip_text = String(GameData.RARITY_NAMES[int(opt.get("rarity", 0))]).to_upper()
	elif kind == "weapon":
		strip_text = "NEW SPELL" if lv == 0 else "LEVEL UP"
	elif kind == "fallback":
		strip_text = "BONUS"
	var strip := PanelContainer.new()
	var ss := PixelStyle.new()
	ss.pattern = false
	ss.drop = 0
	ss.border_w = 1
	ss.border = col.darkened(0.3)
	ss.light = col
	ss.shade = col.darkened(0.6)
	ss.fill = col.darkened(0.65)
	ss.set_content_margin_all(1)
	strip.add_theme_stylebox_override("panel", ss)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sl := UiKit.title(strip_text, 8, col.lightened(0.3))
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	strip.add_child(sl)
	box.add_child(strip)
	# the button is not a container: grow it with its content (the row then evens out the heights)
	var fit := func(): b.custom_minimum_size.y = maxf(150.0, box.get_combined_minimum_size().y + 12.0)
	box.minimum_size_changed.connect(fit)
	fit.call()
	return b


## "You fell": revive once for an ad, or give up (ends the run).
func show_revive(on_revive: Callable, on_give_up: Callable) -> void:
	if map_open:
		toggle_map()
	_choice_panel.visible = false
	get_tree().paused = true
	var o := UiKit.overlay(self_control(), 260, "YOU FELL")
	var dim: Control = o[0]
	var box: VBoxContainer = o[1]
	var l := UiKit.label("Watch an ad to get back up with %d%% HP?" % int(GameData.AD_REVIVE_HP * 100), 10, UiKit.IVORY)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(230, 0)
	box.add_child(l)
	box.add_child(UiKit.button("REVIVE (AD)", Vector2(0, 30), func():
		dim.queue_free()
		on_revive.call(), "accent"))
	box.add_child(UiKit.button("GIVE UP", Vector2(0, 26), func():
		dim.queue_free()
		on_give_up.call(), "danger"))
	dim.visible = true


## A full-screen Control under the HUD layer for overlays (built on demand).
func self_control() -> Control:
	if _overlay_root == null:
		_overlay_root = Control.new()
		_overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_overlay_root)
	return _overlay_root


func choices_open() -> bool:
	return _choice_panel.visible


func pick_choice(i: int) -> void:
	var b: Button = _choice_buttons[i]
	if not b.visible:
		return
	_choice_panel.visible = false
	get_tree().paused = false
	_choice_cb.call(b.get_meta("option"))


## The end-of-run screen from main._end_run's summary: ribbon, run stats, the build, rewards and drops.
func show_result(d: Dictionary) -> void:
	if map_open:
		toggle_map()
	var won: bool = d["won"]
	_result_title.text = "VICTORY" if won else "DEFEAT"
	_result_title.add_theme_color_override("font_color", UiKit.GOLD if won else Color("fff1d6"))
	for ch in _result_box.get_children():
		ch.queue_free()
	var t: int = d["time"]
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 12)
	_result_box.add_child(stats)
	stats.add_child(UiKit.chip("damage", "%d kills" % d["kills"]))
	stats.add_child(UiKit.chip("bell", "%02d:%02d" % [t / 60, t % 60]))
	stats.add_child(UiKit.chip("exp", "Lv %d" % d["level"]))
	stats.add_child(UiKit.chip("chest", str(d["chests"])))
	# the build: weapons and tomes as icon slots with their level
	var build := HBoxContainer.new()
	build.alignment = BoxContainer.ALIGNMENT_CENTER
	build.add_theme_constant_override("separation", 3)
	_result_box.add_child(build)
	for group in [d["weapons"], d["tomes"]]:
		for id in group:
			var sl := UiKit.slot(UiKit.option_icon({"def": {"id": id}}), 30.0, UiKit.CYAN if group == d["weapons"] else UiKit.PURPLE)
			var lv := UiKit.label(str(group[id]), 10, UiKit.IVORY)
			lv.position = Vector2(20, 16)
			sl.add_child(lv)
			sl.tooltip_text = String(GameData.weapon_by_id(id).get("name", id)) if group == d["weapons"] else String(GameData.tome_by_id(id).get("name", id))
			build.add_child(sl)
		if group == d["weapons"] and not d["tomes"].is_empty():
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(6, 0)
			build.add_child(gap)
	_result_box.add_child(UiKit.header("REWARDS" if won else "REWARDS (50%)", 12, "gift"))
	var rw := HBoxContainer.new()
	rw.alignment = BoxContainer.ALIGNMENT_CENTER
	rw.add_theme_constant_override("separation", 4)
	_result_box.add_child(rw)
	var rewards: Dictionary = d["rewards"]
	for k in rewards:
		if int(rewards[k]) <= 0:
			continue
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.add_child(UiKit.slot(k, 34.0))
		var n := UiKit.label("+%d" % int(rewards[k]), 10, UiKit.IVORY)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(n)
		rw.add_child(col)
	for it in d["items"]:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		var sl := UiKit.item_slot(it, 34.0)
		sl.tooltip_text = GameData.item_name(it)
		sl.mouse_filter = Control.MOUSE_FILTER_PASS
		col.add_child(sl)
		var n := UiKit.label("NEW", 10, UiKit.GREEN)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(n)
		rw.add_child(col)
	if String(d.get("note", "")) != "":
		var note := UiKit.label(d["note"], 10, UiKit.GREEN)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_result_box.add_child(note)
	if d.get("can_double", false):
		var dbl := UiKit.button("x2 REWARDS (AD)", Vector2(0, 26), func(): pass, "info")
		var rewards_copy: Dictionary = rewards.duplicate()
		var cb: Callable = d["double"]
		dbl.pressed.connect(func():
			dbl.disabled = true
			dbl.text = "WATCHING AD..."
			Ads.show_rewarded(self, "double_rewards", func():
				cb.call(rewards_copy)
				dbl.text = "REWARDS DOUBLED!"))
		_result_box.add_child(dbl)
	var seed_l := UiKit.label("Seed %d" % d["seed"], 10, Color(1, 1, 1, 0.4))
	seed_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_box.add_child(seed_l)
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
	var face := CharacterArt.portrait(p.character["id"])
	if face != null:
		var w := float(face.get_width())
		var cs := w * 0.5   # head-and-shoulders crop, proportional to the sprite size
		view.draw_texture_rect_region(face, Rect2(7, 7, 28, 28), Rect2(w * 0.5 - cs * 0.5, 0, cs, cs))
	else:
		view.draw_circle(Vector2(21, 22), 8, Color(0.98, 0.86, 0.78))
		view.draw_rect(Rect2(12, 11, 18, 6), Color(p.character["colors"]["hair"]))
	view.draw_rect(Rect2(5, 5, 32, 32), Color("05030c"), false, 1.0)
	view.draw_rect(Rect2(6, 6, 30, 30), GOLD, false, 1.0)
	_text(Vector2(21, 46), "Lv %d" % game.level, IVORY, 8, true)
	_bar(Rect2(40, 8, 120, 8), p.hp / p.stats["max_hp"], Color(0.9, 0.25, 0.3))
	_text(Vector2(100, 15), "%d / %d" % [ceili(p.hp), int(p.stats["max_hp"])], IVORY, 7, true)
	_bar(Rect2(40, 19, 120, 4), game.xp / game.xp_next, CYAN)
	# weapon row (y 26) and tome row (y 45): pixel icon slots, filled / empty / locked (opens via academy buildings)
	_slot_row(26.0, p.weapon_levels, game.weapon_slots, Color(1.0, 0.75, 0.35))
	_slot_row(45.0, p.tomes, game.tome_slots, CYAN)
	# owned items (y 64)
	var x := 40.0
	for id in game.items_owned:
		var it: Dictionary = game.item_by_id(id)
		var col: Color = GameData.RARITY_COLORS[int(it["rarity"])]
		_slot_frame(Rect2(x, 64, 12, 12), col)
		_text(Vector2(x + 6, 73), it["name"].substr(0, 1), col, 8, true)
		var n: int = game.items_owned[id]
		if n > 1:
			_text(Vector2(x + 11, 79), str(n), IVORY, 8, true)
		x += 14.0


## Pixel slot frame: black outline, coloured 1 px border, dark fill.
func _slot_frame(r: Rect2, col: Color, fill := Color("140f2a")) -> void:
	view.draw_rect(r.grow(1), Color("05030c"))
	view.draw_rect(r, col)
	view.draw_rect(r.grow(-1), fill)


func _slot_row(y: float, owned: Dictionary, unlocked: int, col: Color) -> void:
	var ids: Array = owned.keys()
	var x := 40.0
	for i in GameData.MAX_SLOTS:
		var r := Rect2(x, y, 18, 18)
		if i < ids.size():
			var id := String(ids[i])
			var evolved: bool = GameData.weapon_by_id(id).get("evolved", false) if owned == game.player.weapon_levels else false
			_slot_frame(r, GOLD if evolved else col)
			var tex := UiKit.icon_tex(UiKit.option_icon({"def": {"id": id}}))
			if tex != null:
				view.draw_texture_rect(tex, Rect2(r.position + Vector2(1, 1), Vector2(16, 16)), false)
			_text(Vector2(r.end.x - 1, r.end.y + 2), "E" if evolved else str(owned[ids[i]]), GOLD if evolved else IVORY, 8, true)
		elif i < unlocked:
			_slot_frame(r, Color(col, 0.45), Color(0.05, 0.04, 0.12, 0.6))
		else:
			_slot_frame(r, Color(0.35, 0.33, 0.45, 0.6), Color(0, 0, 0, 0.45))
			var lock := UiKit.icon_tex("lock")
			if lock != null:
				view.draw_texture_rect(lock, Rect2(r.position + Vector2(1, 1), Vector2(16, 16)), false, Color(1, 1, 1, 0.45))
		x += 21.0


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
		# difficulty meter: threat name, reddening as it climbs; the swarm level during the Final Swarm
		var k := clampf(float(game.threat_level()) / float(GameData.THREAT_NAMES.size() - 1), 0.0, 1.0)
		var tcol := Color(0.75, 0.9, 0.7).lerp(Color(1, 0.6, 0.25), minf(k * 2.0, 1.0)).lerp(CRIMSON, maxf(k * 2.0 - 1.0, 0.0))
		var line := "Threat: %s" % game.threat_name()
		if game.final_swarm:
			line = "SWARM LV %d  ·  %s" % [game.swarm_level(), game.threat_name()]
		_text(Vector2(cx, 40), line, tcol, 7, true)


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
	# pixel bar: black outline, dark well, fill with a light top row
	r = Rect2(r.position.floor(), r.size.floor())
	view.draw_rect(r.grow(1), Color("05030c"))
	view.draw_rect(r, Color("2a2148"))
	var w := floorf(r.size.x * clampf(ratio, 0.0, 1.0))
	view.draw_rect(Rect2(r.position, Vector2(w, r.size.y)), col)
	view.draw_rect(Rect2(r.position, Vector2(w, 1)), col.lightened(0.45))
	if r.size.y > 4:
		view.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 1), Vector2(w, 1)), col.darkened(0.35))


func _text(p: Vector2, s: String, col: Color, size: int, centered: bool) -> void:
	var fs := UiKit.fs(size)
	var pos := p
	if centered:
		pos.x -= font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * 0.5
	view.draw_string_outline(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, col.a * 0.85))
	view.draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


# ------------------------------------------------------------------ widgets

func _style(border: Color) -> StyleBox:
	return UiKit.style(border, 6.0)


func _make_button(text: String, size: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", UiKit.tfs(9))
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, UiKit.button_style("normal", st))
	b.add_theme_font_override("font", UiKit.BOLD_FONT)
	b.pressed.connect(cb)
	add_child(b)
	return b


func _centered_panel() -> PanelContainer:
	var p := PanelContainer.new()
	var st := UiKit.style(UiKit.PURPLE, 10.0)
	st.border_w = 3
	st.rivets = true
	p.add_theme_stylebox_override("panel", st)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.visible = false
	add_child(p)
	return p


func _build_choice_panel() -> void:
	# no big panel: a dimmed screen, a red ribbon and three compact cards
	_choice_panel = ColorRect.new()
	_choice_panel.color = Color(0.01, 0.0, 0.05, 0.62)
	_choice_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_choice_panel.visible = false
	add_child(_choice_panel)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_choice_panel.add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	center.add_child(col)
	var rb := UiKit.ribbon("LEVEL UP", 16)
	rb.custom_minimum_size = Vector2(300, 28)
	col.add_child(rb)
	_choice_title = rb.get_child(0)
	_choice_sub = UiKit.label("Choose one", 8, Color("d8d2ee"))
	_choice_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_choice_sub)
	_choice_row = HBoxContainer.new()
	_choice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_choice_row.add_theme_constant_override("separation", 8)
	col.add_child(_choice_row)


func _build_pause_panel() -> void:
	_pause_panel = _centered_panel()
	var box := VBoxContainer.new()
	_pause_panel.add_child(box)
	box.add_theme_constant_override("separation", 5)
	box.add_child(UiKit.ribbon("PAUSED", 16))
	var info := Label.new()
	info.name = "Info"
	info.add_theme_font_size_override("font_size", UiKit.fs(9))
	box.add_child(info)
	box.add_child(UiKit.button("RESUME", Vector2(220, 30), toggle_pause, "primary"))
	box.add_child(UiKit.button("NEW RUN", Vector2(220, 26), func(): game.restart(), "info"))
	box.add_child(UiKit.button("ABANDON (NO REWARDS)", Vector2(220, 26), func(): game.return_to_academy(), "danger"))
	_pause_panel.visibility_changed.connect(func():
		if _pause_panel.visible:
			info.text = "Seed %d\nEsc/P pause · M map · Space dash · WASD move" % game.seed_value)


func _build_result_panel() -> void:
	_result_panel = _centered_panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	_result_panel.add_child(box)
	var rb := UiKit.ribbon("", 24)
	rb.custom_minimum_size = Vector2(0, 34)
	box.add_child(rb)
	_result_title = rb.get_child(0)
	_result_box = VBoxContainer.new()
	_result_box.custom_minimum_size = Vector2(400, 0)
	_result_box.add_theme_constant_override("separation", 5)
	box.add_child(_result_box)
	var academy := UiKit.button("RETURN TO ACADEMY", Vector2(0, 30), func(): game.return_to_academy(), "primary")
	box.add_child(academy)
	var again := UiKit.button("RUN AGAIN", Vector2(0, 26), func(): game.restart(), "info")
	box.add_child(again)
	for b in [academy, again]:
		b.add_theme_font_size_override("font_size", UiKit.tfs(10))
