class_name Home
extends Control
## Home screen (Syifa's layout, after mobile hero games): the academy map fills the screen and can be dragged;
## top-left the selected mage, below it the running quests; top-right the resources and a settings button;
## bottom-left Characters / Expedition / Codex; bottom-right the big Rift button. Tapping a building opens it.
## Characters / Expedition / Codex / Rift are full-screen pages with a back button.
##
## Command-line (after `--`): any --autotest* flag skips straight to the run;
## --academy-shot=/tmp/a.png saves a screenshot and quits; --academy-demo uses an in-memory sample save;
## --academy-page=characters|rift|expedition|codex opens a page; --academy-tab=enhance|gear|bond picks the
## character tab; --academy-building=<id> opens a building; --academy-lessons / -workshop / -dorm / -settings
## open those overlays; --academy-check opens everything once and quits (tests).

const RUN_SCENE := "res://scenes/main.tscn"
const NAV := [["characters", "Characters"], ["expedition", "Expedition"], ["codex", "Codex"]]

var save: Dictionary
var demo := false
var pages := {}
var current := "home"
var map: AcademyMap
var lessons: LessonsPanel
var workshop: WorkshopPanel
var dorm: DormPanel
var building: BuildingPanel
var settings: Control
var _home: Control
var _page_layer: Control
var _page_title: Label
var _res_rows: Array = []     # one resource strip per layer -> {kind: label}
var _quests: VBoxContainer
var _avatar_name: Label
var _avatar_lv: Label
var _avatar: Control
var _rift_char: Control
var _reset_btn: Button
var _armed := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autotest"):
			get_tree().change_scene_to_file.call_deferred(RUN_SCENE)
			return
	set_anchors_preset(Control.PRESET_FULL_RECT)
	save = SaveData.load_data()
	var args := OS.get_cmdline_user_args()
	if "--academy-demo" in args:
		save = _demo_save()
		demo = true
	_build()
	show_page("home")
	for a in args:
		if a.begins_with("--academy-page="):
			show_page(a.get_slice("=", 1))
		elif a.begins_with("--academy-tab="):
			pages["characters"].show_tab(a.get_slice("=", 1))
		elif a.begins_with("--academy-building="):
			building.open(a.get_slice("=", 1))
	if "--academy-lessons" in args:
		lessons.open(save)
	if "--academy-workshop" in args:
		workshop.open(save)
	if "--academy-dorm" in args:
		dorm.open(save)
	if "--academy-settings" in args:
		settings.visible = true
	if "--academy-check" in args:
		for p in pages:
			show_page(p)
		for t in ["enhance", "gear", "bond"]:
			pages["characters"].show_tab(t)
		show_page("home")
		for id in GameData.ACADEMY_PLOTS:
			building.open(id)
		lessons.open(save)
		workshop.open(save)
		dorm.open(save)
		refresh()
		print("[academy] ui check ok pages=%d" % pages.size())
		get_tree().quit()
		return
	for a in args:
		if a.begins_with("--academy-shot="):
			_screenshot_and_quit(a.get_slice("=", 1))


func _demo_save() -> Dictionary:
	var d := SaveData.defaults()
	for k in ["gold", "materials", "aether", "exp"]:
		d[k] = 3000
	d["shards"] = 9
	for b in ["staff_room", "frost_tower", "workshop", "dormitory", "library", "training"]:
		d["buildings"][b] = 2 if b in ["workshop", "dormitory", "library"] else 1
	d["lessons"] = {"might": 2, "vigor": 1}
	d["character"] = "selene"
	SaveData.add_char_exp(d, "selene", GameData.char_exp_for(7) + 40)
	SaveData.add_char_exp(d, "astra", GameData.char_exp_for(4))
	SaveData.char_state(d, "selene")["passive"] = 1
	d["essence"] = {"courtyard": 14}
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for r in [3, 2, 1, 0, 4, 1, 2]:
		SaveData.add_item(d, GameData.roll_item(rng, r))
	SaveData.equip(d, "selene", int(d["items"][0]["uid"]))
	SaveData.equip(d, "selene", int(d["items"][1]["uid"]))
	for id in ["astra", "lyra", "selene", "nym"]:
		SaveData.move_in(d, id)
	SaveData.add_bond(d, "selene", GameData.BOND_EXP[3] + 30)
	var now := int(Time.get_unix_time_from_system())
	SaveData.start_expedition(d, "lyra", "crystals", now - 3 * 3600)
	SaveData.start_expedition(d, "kael", "scout", now - 7200)
	d["runs"] = 6
	d["victories"] = 2
	d["best_kills"] = 812
	d["last_run"] = {"victory": true, "kills": 640, "gold": 420, "materials": 90, "aether": 25, "character": "selene"}
	return d


func _screenshot_and_quit(path: String) -> void:
	for i in 5:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("[academy] screenshot ", path)
	get_tree().quit()


# ------------------------------------------------------------------ layout

func _build() -> void:
	_home = Control.new()
	_home.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_home)
	map = AcademyMap.new(self)
	map.set_anchors_preset(Control.PRESET_FULL_RECT)
	map.building_tapped.connect(func(id): building.open(id))
	_home.add_child(map)
	_build_home_hud()

	_page_layer = Control.new()
	_page_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_page_layer)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/ui_background.gdshader")
	bg.material = mat
	_page_layer.add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	_page_layer.add_child(root)
	root.add_child(_page_bar())
	var content := MarginContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "bottom"]:
		content.add_theme_constant_override("margin_" + side, 10)
	content.add_theme_constant_override("margin_top", 4)
	root.add_child(content)
	var stack := Control.new()
	content.add_child(stack)
	pages["characters"] = CharactersPage.new(self)
	pages["expedition"] = ExpeditionPage.new(self)
	pages["codex"] = CodexPage.new(self)
	pages["rift"] = RiftPage.new(self)
	for id in pages:
		var p: Control = pages[id]
		p.set_anchors_preset(Control.PRESET_FULL_RECT)
		p.visible = false
		stack.add_child(p)

	lessons = LessonsPanel.new(self, changed)
	workshop = WorkshopPanel.new(self, changed)
	dorm = DormPanel.new(self, changed)
	building = BuildingPanel.new(self, self)
	pages["characters"].build_overlays(self)
	_build_settings()


func _build_home_hud() -> void:
	# soft dark bands top and bottom so the HUD reads over the map
	for top in [true, false]:
		var band := TextureRect.new()
		var g := Gradient.new()
		g.set_color(0, Color(0.01, 0.02, 0.07, 0.75))
		g.set_color(1, Color(0.01, 0.02, 0.07, 0.0))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill_from = Vector2(0, 0) if top else Vector2(0, 1)
		gt.fill_to = Vector2(0, 1) if top else Vector2(0, 0)
		band.texture = gt
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		band.stretch_mode = TextureRect.STRETCH_SCALE
		band.set_anchors_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		band.custom_minimum_size = Vector2(0, 46 if top else 62)
		if not top:
			band.offset_top = -62
		_home.add_child(band)

	# top-left: the selected mage
	var who := HBoxContainer.new()
	who.position = Vector2(10, 6)
	who.add_theme_constant_override("separation", 6)
	_home.add_child(who)
	_avatar = Control.new()
	_avatar.custom_minimum_size = Vector2(34, 34)
	_avatar.draw.connect(func(): _draw_portrait_circle(_avatar, String(save["character"]), 17.0))
	who.add_child(_avatar)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -2)
	who.add_child(names)
	_avatar_name = UiKit.title("", 11)
	names.add_child(_avatar_name)
	_avatar_lv = UiKit.label("", 7, UiKit.CYAN)
	names.add_child(_avatar_lv)

	# left: quests
	var qp := UiKit.panel(6.0)
	var qpanel: PanelContainer = qp[0]
	qpanel.position = Vector2(10, 48)
	qpanel.custom_minimum_size = Vector2(150, 0)
	var qs := UiKit.style(UiKit.GOLD, 6.0)
	qs.fill_top = Color(0.03, 0.06, 0.16, 0.6)
	qs.fill_bottom = Color(0.03, 0.06, 0.16, 0.45)
	qs.highlight = Color(0, 0, 0, 0)
	qpanel.add_theme_stylebox_override("panel", qs)
	_home.add_child(qpanel)
	qp[1].add_child(UiKit.title("QUESTS", 9, UiKit.GOLD))
	_quests = VBoxContainer.new()
	_quests.add_theme_constant_override("separation", 3)
	qp[1].add_child(_quests)

	# top-right: resources + settings
	var tr := HBoxContainer.new()
	tr.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tr.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tr.offset_right = -8
	tr.offset_top = 8
	tr.add_theme_constant_override("separation", 4)
	_home.add_child(tr)
	_res_rows.append(_resource_pills(tr))
	var gear := UiKit.button("", Vector2(24, 22), func(): settings.visible = true)
	gear.add_child(_icon_control("gear", Vector2(24, 22)))
	tr.add_child(gear)

	# bottom-left: navigation
	var nav := HBoxContainer.new()
	nav.name = "Nav"
	nav.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	nav.grow_vertical = Control.GROW_DIRECTION_BEGIN
	nav.offset_left = 14
	nav.offset_bottom = -6
	nav.add_theme_constant_override("separation", 14)
	_home.add_child(nav)
	for n in NAV:
		nav.add_child(_nav_button(n[0], n[1]))

	# bottom-right: the Rift
	var rift := HBoxContainer.new()
	rift.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	rift.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	rift.grow_vertical = Control.GROW_DIRECTION_BEGIN
	rift.offset_right = -10
	rift.offset_bottom = -8
	rift.add_theme_constant_override("separation", -6)
	_home.add_child(rift)
	_rift_char = Control.new()
	_rift_char.custom_minimum_size = Vector2(46, 46)
	_rift_char.z_index = 1
	_rift_char.draw.connect(func(): _draw_portrait_circle(_rift_char, String(save["character"]), 23.0, true))
	rift.add_child(_rift_char)
	var go := UiKit.button("", Vector2(176, 46), func(): show_page("rift"), "primary")
	go.text = ""
	var gl := VBoxContainer.new()
	gl.set_anchors_preset(Control.PRESET_FULL_RECT)
	gl.alignment = BoxContainer.ALIGNMENT_CENTER
	gl.add_theme_constant_override("separation", -4)
	gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	go.add_child(gl)
	var sub := UiKit.label("%s  ·  Danger 1" % GameData.LOCATIONS[0]["name"], 7, Color(0.35, 0.15, 0.0))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gl.add_child(sub)
	var big := UiKit.label("ENTER THE RIFT", 17, Color(0.25, 0.08, 0.0))
	big.add_theme_font_override("font", UiKit.TITLE_FONT)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gl.add_child(big)
	rift.add_child(go)


func _nav_button(page: String, text: String) -> Control:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(58, 50)
	b.pressed.connect(show_page.bind(page))
	var ic := _icon_control(page, Vector2(58, 34))
	b.add_child(ic)
	var l := UiKit.title(text, 9)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	l.offset_top = -14
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l)
	return b


## Code-drawn menu icons (characters, expedition, codex, gear) in the light-blue HUD colour.
func _icon_control(kind: String, sz: Vector2) -> Control:
	var c := Control.new()
	c.custom_minimum_size = sz
	c.size = sz
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(_draw_icon.bind(c, kind))
	return c


static func _draw_icon(c: Control, kind: String) -> void:
		var m := c.size * 0.5
		var hi := Color(0.62, 0.86, 1.0)
		var dark := Color(0.12, 0.3, 0.6)
		match kind:
			"characters":
				c.draw_circle(m + Vector2(0, -7), 7, hi)
				c.draw_colored_polygon(PackedVector2Array([m + Vector2(-11, 13), m + Vector2(-8, 1), m + Vector2(8, 1), m + Vector2(11, 13)]), hi)
				c.draw_colored_polygon(PackedVector2Array([m + Vector2(-9, -9), m + Vector2(0, -20), m + Vector2(9, -9)]), dark)
			"expedition":
				c.draw_arc(m, 12, 0, TAU, 28, hi, 2.5)
				c.draw_colored_polygon(PackedVector2Array([m + Vector2(0, -10), m + Vector2(4, 0), m + Vector2(0, 10), m + Vector2(-4, 0)]), hi)
				c.draw_circle(m, 2.0, dark)
			"codex":
				c.draw_rect(Rect2(m + Vector2(-12, -11), Vector2(11, 22)), hi)
				c.draw_rect(Rect2(m + Vector2(1, -11), Vector2(11, 22)), hi)
				c.draw_line(m + Vector2(0, -11), m + Vector2(0, 11), dark, 2.0)
				for i in 3:
					c.draw_line(m + Vector2(-9, -6 + i * 5), m + Vector2(-3, -6 + i * 5), dark, 1.0)
			"gear":
				for i in 8:
					var a := TAU * i / 8.0
					c.draw_line(m + Vector2.from_angle(a) * 4, m + Vector2.from_angle(a) * 8, hi, 3.0)
				c.draw_circle(m, 5.5, hi)
				c.draw_circle(m, 2.5, Color(0.08, 0.14, 0.3))
			"back":
				c.draw_colored_polygon(PackedVector2Array([m + Vector2(-6, 0), m + Vector2(4, -7), m + Vector2(4, 7)]), hi)


func _resource_pills(parent: Control) -> Dictionary:
	var out := {}
	for k in ["gold", "materials", "aether", "shards"]:
		var pill := PanelContainer.new()
		var sb := UiKit.style(UiKit.GOLD, 2.0)
		sb.radius = 9.0
		sb.content_margin_left = 4
		sb.content_margin_right = 8
		sb.fill_top = Color(0.02, 0.04, 0.12, 0.75)
		sb.fill_bottom = Color(0.02, 0.04, 0.12, 0.75)
		sb.highlight = Color(0, 0, 0, 0)
		pill.add_theme_stylebox_override("panel", sb)
		pill.tooltip_text = UiKit.resource_name(k)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		pill.add_child(row)
		row.add_child(UiKit.icon(k, 11.0))
		var l := UiKit.label("0", 8, UiKit.IVORY)
		l.custom_minimum_size = Vector2(26, 0)
		row.add_child(l)
		parent.add_child(pill)
		out[k] = l
	return out


func _page_bar() -> Control:
	var bar := MarginContainer.new()
	bar.add_theme_constant_override("margin_left", 8)
	bar.add_theme_constant_override("margin_right", 8)
	bar.add_theme_constant_override("margin_top", 6)
	bar.add_theme_constant_override("margin_bottom", 2)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	bar.add_child(row)
	var back := UiKit.button("", Vector2(30, 24), func(): show_page("home"))
	back.add_child(_icon_control("back", Vector2(30, 24)))
	row.add_child(back)
	_page_title = UiKit.title("", 15)
	_page_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_page_title)
	_res_rows.append(_resource_pills(row))
	return bar


func _build_settings() -> void:
	var o := UiKit.overlay(self, 300)
	settings = o[0]
	var box: VBoxContainer = o[1]
	var head := HBoxContainer.new()
	box.add_child(head)
	var t := UiKit.title("SETTINGS", 14)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UiKit.button("X", Vector2(26, 22), func(): settings.visible = false))
	box.add_child(UiKit.label("Sound and language options come later.", 8, Color(UiKit.IVORY, 0.7)))
	_reset_btn = UiKit.button("Reset save", Vector2(0, 26), _on_reset)
	box.add_child(_reset_btn)
	var credits := UiKit.label("Fonts: Nunito, Exo 2 (SIL OFL).  VFX: pixelfx (MIT).\nArt: PixelLab.", 7, Color(UiKit.IVORY, 0.5))
	box.add_child(credits)


## A round character portrait with a light rim (avatar, Rift button).
func _draw_portrait_circle(c: Control, id: String, r: float, gold := false) -> void:
	var m := c.size * 0.5
	c.draw_circle(m, r, Color(0.9, 0.7, 0.3) if gold else Color(0.55, 0.8, 1.0))
	c.draw_circle(m, r - 2, Color(0.08, 0.14, 0.32))
	var tex := CharacterArt.portrait(id)
	if tex == null:
		return
	# head and shoulders of the 64 px sprite, cut to the circle (polygon with UVs)
	var src := Rect2(16, 4, 32, 32)
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in 32:
		var d := Vector2.from_angle(TAU * i / 32.0)
		pts.append(m + d * (r - 2))
		uvs.append((src.get_center() + d * src.size.x * 0.5) / Vector2(tex.get_width(), tex.get_height()))
	c.draw_colored_polygon(pts, Color.WHITE, uvs, tex)


# ------------------------------------------------------------------ state

func show_page(id: String) -> void:
	if id != "home" and not pages.has(id):
		id = "home"
	current = id
	_home.visible = id == "home"
	_page_layer.visible = id != "home"
	for k in pages:
		pages[k].visible = k == id
	if pages.has(id):
		_page_title.text = {"characters": "CHARACTERS", "expedition": "EXPEDITION", "codex": "CODEX", "rift": "THE RIFT"}[id]
	refresh()


## Called after any change: save (not in demo) and refresh what is visible.
func changed() -> void:
	if not demo:
		SaveData.save_data(save)
	refresh()


func refresh() -> void:
	for row in _res_rows:
		for k in row:
			row[k].text = _short(int(save[k]))
	if current == "home":
		_refresh_home()
	else:
		pages[current].refresh()
	for o in [lessons, workshop, dorm, building]:
		if o != null and o.is_open():
			o.refresh()


func _refresh_home() -> void:
	var c := GameData.character_by_id(String(save["character"]))
	_avatar_name.text = c["name"]
	var total := 0
	for b in GameData.BUILDINGS:
		total += SaveData.building_level(save, b["id"])
	_avatar_lv.text = "Lv %d  ·  Academy Lv %d" % [SaveData.char_level(save, c["id"]), 1 + total]
	_avatar.queue_redraw()
	_rift_char.queue_redraw()
	for ch in _quests.get_children():
		ch.queue_free()
	for q in quests():
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = ("> " if q.get("ready", false) else "- ") + q["text"]
		b.custom_minimum_size = Vector2(140, 14)
		b.add_theme_font_size_override("font_size", 7)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var col: Color = UiKit.GREEN if q.get("ready", false) else UiKit.IVORY
		for k in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(k, col)
		b.add_theme_color_override("font_outline_color", Color(0, 0, 0.1, 0.8))
		b.add_theme_constant_override("outline_size", 2)
		b.pressed.connect(q["go"])
		_quests.add_child(b)


## The running goals shown on the home screen (proper quests with rewards come with the locations phase).
func quests() -> Array:
	var out: Array = []
	var now := int(Time.get_unix_time_from_system())
	for e in save["expeditions"]:
		if now >= int(e["end"]):
			out.append({"text": "%s is back from %s" % [GameData.character_by_id(e["char"])["name"], GameData.expedition_by_id(e["mission"])["name"]],
				"ready": true, "go": show_page.bind("expedition")})
	var best := ""
	var best_cost := INF
	for b in GameData.BUILDINGS:
		var cost := SaveData.next_cost(save, b["id"])
		if cost.is_empty():
			continue
		if SaveData.can_afford(save, cost):
			out.append({"text": "Restore the %s" % b["name"] if SaveData.building_level(save, b["id"]) == 0 else "Upgrade the %s" % b["name"],
				"ready": true, "go": _focus_building.bind(b["id"])})
		elif int(cost["gold"]) < best_cost:
			best_cost = int(cost["gold"])
			best = b["id"]
	if best != "":
		var cost := SaveData.next_cost(save, best)
		out.append({"text": "Restore the %s (gold %d / %d)" % [GameData.building_by_id(best)["name"], int(save["gold"]), int(cost["gold"])],
			"go": _focus_building.bind(best)})
	var cid := String(save["character"])
	for track in SaveData.ENHANCE_TRACKS:
		var cost := SaveData.next_enhance_cost(save, cid, track)
		if not cost.is_empty() and SaveData.can_afford(save, cost):
			out.append({"text": "Enhance %s's %s" % [GameData.character_by_id(cid)["name"], "passive" if track == "passive" else "signature weapon"],
				"ready": true, "go": func(): pages["characters"].select(cid); show_page("characters")})
			break
	var day := SaveData.today()
	for id in save["dorm"]:
		if SaveData.can_talk(save, id, day):
			out.append({"text": "Talk to the residents (Dormitory)", "ready": true, "go": func(): dorm.open(save)})
			break
	if int(save["victories"]) == 0:
		out.append({"text": "Win a run in the %s" % GameData.LOCATIONS[0]["name"], "go": show_page.bind("rift")})
	return out.slice(0, 4)


func _focus_building(id: String) -> void:
	map.center_on(GameData.ACADEMY_PLOTS[id])
	building.open(id)


static func _short(n: int) -> String:
	if n >= 100000:
		return "%dk" % (n / 1000)
	if n >= 10000:
		return "%.1fk" % (n / 1000.0)
	return str(n)


## What restoring the next level of a building gives (or gave).
static func building_effect(save: Dictionary, b: Dictionary, lv: int, maxed: bool) -> String:
	match b["unlocks"]:
		"tome", "weapon":
			var kind_name := "Tome" if b["unlocks"] == "tome" else "Weapon"
			var slots := SaveData.slots_for(save, b["unlocks"])
			var s := "%s slots: %d (max)" % [kind_name, slots] if maxed else "%s slots: %d  >  %d" % [kind_name, slots, slots + 1]
			if b["id"] == "library":
				s += "\nAt max level Wren returns"
			return s
		"character":
			var c := GameData.character_by_id(b["character"])
			return "%s has returned" % c["name"] if lv >= 1 else "Brings back %s (%s)" % [c["name"], c["school"]]
		"dorm":
			var rooms := SaveData.dorm_rooms(save)
			if maxed:
				return "Rooms %d, expedition slots %d (max)" % [rooms, lv]
			return "Rooms %d > %d, expedition slots %d > %d" % [rooms, GameData.DORM_ROOMS[lv + 1], lv, lv + 1]
		"workshop":
			if maxed:
				return "Crafts up to %s (max)" % GameData.GEAR_RARITY_NAMES[lv]
			return "Crafts up to %s  >  %s" % [GameData.GEAR_RARITY_NAMES[lv] if lv > 0 else "nothing", GameData.GEAR_RARITY_NAMES[lv + 1]]
		"lessons":
			var cap := SaveData.lesson_cap(save)
			return "Lesson rank cap: %d (max)" % cap if maxed else "Lesson rank cap: %d  >  %d" % [cap, cap + GameData.LESSON_RANKS_PER_LEVEL]
	return ""


func enter_rift() -> void:
	get_tree().change_scene_to_file(RUN_SCENE)


func _on_reset() -> void:
	if not _armed:
		_armed = true
		_reset_btn.text = "Tap again to erase everything"
		return
	_armed = false
	_reset_btn.text = "Reset save"
	save = SaveData.defaults() if demo else SaveData.reset()
	for k in pages:
		pages[k].on_reset()
	settings.visible = false
	refresh()
