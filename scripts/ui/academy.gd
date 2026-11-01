extends Control
## Academy shell (phase 3 reskin): night-sky background, a top bar (title, page plate, resources) and a bottom
## navigation bar with five pages: Academy (buildings), Characters, Rift (battle prep), Expedition, Codex.
## Overlays (Staff Room lessons, Workshop, Dormitory rooms, inventory picker, story reader) sit above the pages.
##
## Command-line (after `--`): any --autotest* flag skips straight to the run;
## --academy-shot=/tmp/a.png saves a screenshot of this screen and quits.
## --academy-demo uses an in-memory sample save (never written) with progress, for screenshots;
## --academy-page=characters|rift|expedition|codex opens a page; --academy-tab=enhance|gear|bond picks the
## character tab; --academy-lessons / --academy-workshop / --academy-dorm open those overlays;
## --academy-scroll scrolls the strips to their end; --academy-check opens everything once and quits (tests).

const RUN_SCENE := "res://scenes/main.tscn"
const PAGES := [["academy", "Academy"], ["characters", "Characters"], ["rift", "Rift"], ["expedition", "Expedition"], ["codex", "Codex"]]
const NAV_ICONS := {"academy": "materials", "characters": "exp", "rift": "shards", "expedition": "essence", "codex": "aether"}

var save: Dictionary
var demo := false
var pages := {}
var current := "academy"
var lessons: LessonsPanel
var workshop: WorkshopPanel
var dorm: DormPanel
var _nav := {}
var _res := {}
var _plate: Label


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
	var start := "academy"
	var tab := ""
	for a in args:
		if a.begins_with("--academy-page="):
			start = a.get_slice("=", 1)
		elif a.begins_with("--academy-tab="):
			tab = a.get_slice("=", 1)
	show_page(start)
	if tab != "":
		pages["characters"].show_tab(tab)
	if "--academy-lessons" in args:
		lessons.open(save)
	if "--academy-workshop" in args:
		workshop.open(save)
	if "--academy-dorm" in args:
		dorm.open(save)
	if "--academy-check" in args:
		# UI smoke test: open every page and overlay once, then quit
		for p in PAGES:
			show_page(p[0])
		for t in ["enhance", "gear", "bond"]:
			pages["characters"].show_tab(t)
		lessons.open(save)
		workshop.open(save)
		dorm.open(save)
		refresh()
		print("[academy] ui check ok pages=%d" % pages.size())
		get_tree().quit()
		return
	if "--academy-scroll" in args:
		await get_tree().process_frame
		for sc in find_children("*", "ScrollContainer", true, false):
			sc.scroll_horizontal = 100000
	for a in args:
		if a.begins_with("--academy-shot="):
			_screenshot_and_quit(a.get_slice("=", 1))


func _demo_save() -> Dictionary:
	var d := SaveData.defaults()
	for k in ["gold", "materials", "aether", "exp"]:
		d[k] = 3000
	d["shards"] = 9
	for b in ["staff_room", "frost_tower", "workshop", "dormitory", "library"]:
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
	for i in 4:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("[academy] screenshot ", path)
	get_tree().quit()


# ------------------------------------------------------------------ layout

func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/ui_background.gdshader")
	bg.material = mat
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)
	root.add_child(_top_bar())
	var content := MarginContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		content.add_theme_constant_override("margin_" + side, 10)
	content.add_theme_constant_override("margin_top", 6)
	content.add_theme_constant_override("margin_bottom", 4)
	root.add_child(content)
	var stack := Control.new()
	content.add_child(stack)
	pages["academy"] = AcademyPage.new(self)
	pages["characters"] = CharactersPage.new(self)
	pages["rift"] = RiftPage.new(self)
	pages["expedition"] = ExpeditionPage.new(self)
	pages["codex"] = CodexPage.new(self)
	for id in pages:
		var p: Control = pages[id]
		p.set_anchors_preset(Control.PRESET_FULL_RECT)
		p.visible = false
		stack.add_child(p)
	root.add_child(_nav_bar())

	lessons = LessonsPanel.new(self, changed)
	workshop = WorkshopPanel.new(self, changed)
	dorm = DormPanel.new(self, changed)
	pages["characters"].build_overlays(self)


func _top_bar() -> Control:
	var bar := PanelContainer.new()
	var sb := UiKit.style(UiKit.GOLD, 4.0)
	sb.chamfer = 0.0
	sb.ornaments = false
	sb.fill_top = Color(0.03, 0.04, 0.1, 0.92)
	sb.fill_bottom = Color(0.05, 0.07, 0.16, 0.92)
	bar.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	bar.add_child(row)
	var logo := VBoxContainer.new()
	logo.add_theme_constant_override("separation", -3)
	logo.add_child(UiKit.title("RIFTBOUND", 12))
	logo.add_child(UiKit.title("ARCANE ACADEMY", 6, UiKit.CYAN))
	row.add_child(logo)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", UiKit.style(UiKit.GOLD, 3.0))
	plate.custom_minimum_size = Vector2(130, 0)
	_plate = UiKit.title("", 10)
	_plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.add_child(_plate)
	row.add_child(plate)
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp2)
	for k in ["gold", "materials", "aether", "exp", "shards"]:
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 2)
		chip.add_child(UiKit.icon(k, 9.0))
		var l := UiKit.label("0", 8, UiKit.IVORY)
		chip.add_child(l)
		chip.tooltip_text = UiKit.resource_name(k)
		row.add_child(chip)
		_res[k] = l
	return bar


func _nav_bar() -> Control:
	var bar := PanelContainer.new()
	var sb := UiKit.style(UiKit.GOLD, 3.0)
	sb.chamfer = 0.0
	sb.ornaments = false
	sb.fill_top = Color(0.05, 0.07, 0.16, 0.95)
	sb.fill_bottom = Color(0.02, 0.03, 0.08, 0.95)
	bar.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	bar.add_child(row)
	for p in PAGES:
		var b := UiKit.button(p[1], Vector2(104, 24), show_page.bind(p[0]))
		b.add_theme_font_override("font", UiKit.TITLE_FONT)
		b.add_theme_font_size_override("font_size", 9)
		row.add_child(b)
		_nav[p[0]] = b
	return bar


func show_page(id: String) -> void:
	if not pages.has(id):
		id = "academy"
	current = id
	for k in pages:
		pages[k].visible = k == id
		UiKit.set_selected(_nav[k], k == id)
	for p in PAGES:
		if p[0] == id:
			_plate.text = p[1].to_upper()
	refresh()


## Called by pages / overlays after any change: save (not in demo) and refresh what is visible.
func changed() -> void:
	if not demo:
		SaveData.save_data(save)
	refresh()


func refresh() -> void:
	for k in _res:
		_res[k].text = _short(int(save[k]))
	pages[current].refresh()
	for o in [lessons, workshop, dorm]:
		if o != null and o.is_open():
			o.refresh()


static func _short(n: int) -> String:
	if n >= 100000:
		return "%dk" % (n / 1000)
	if n >= 10000:
		return "%.1fk" % (n / 1000.0)
	return str(n)


func enter_rift() -> void:
	get_tree().change_scene_to_file(RUN_SCENE)


## Two-tap reset (lives on the Codex page, away from the play buttons).
func reset_save() -> void:
	save = SaveData.defaults() if demo else SaveData.reset()
	for k in pages:
		pages[k].on_reset()
	refresh()
