extends Control
## Academy hub: spend run rewards restoring buildings. Each building brings something back: tome / weapon
## slots, a character who lives there (Frost Tower -> Selene, Alchemy Lab -> Noah), or the Staff Room whose
## teachers sell permanent lessons. Then enter the Rift.
##
## Command-line (after `--`): any --autotest* flag skips straight to the run;
## --academy-shot=/tmp/a.png saves a screenshot of this screen and quits.
## --academy-demo uses an in-memory sample save (never written) with some buildings restored, for screenshots;
## --academy-lessons opens the Staff Room lessons; --academy-scroll scrolls both strips to their end;
## --academy-character / --academy-gear open the selected character's panel (level / equipment tab);
## --academy-workshop opens the Workshop; --academy-bond the bond tab; --academy-dorm / --academy-expedition
## the Dormitory tabs.

const NAVY := Color(0.06, 0.08, 0.18, 0.94)
const GOLD := Color(0.86, 0.7, 0.32)
const IVORY := Color(0.96, 0.94, 0.86)
const CYAN := Color(0.4, 0.9, 1.0)
const RUN_SCENE := "res://scenes/main.tscn"

var save: Dictionary
var _res_label: Label
var _info_label: Label
var _cards := {}   # building id -> {state, effect, cost, button}
var _char_buttons := {}  # character id -> Button
var _char_detail: Label
var _reset_armed := false
var _reset_btn: Button
var _demo := false   # --academy-demo: the sample save is never written
var _lessons_panel: Control   # full-screen dimmed overlay holding the lessons panel
var _lesson_rows := {}   # lesson id -> {label, button}
var _lessons_header: Label
var _char_panel: CharacterPanel
var _char_btn: Button
var _workshop: WorkshopPanel
var _dorm: DormPanel


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autotest"):
			get_tree().change_scene_to_file.call_deferred(RUN_SCENE)
			return
	set_anchors_preset(Control.PRESET_FULL_RECT)
	save = SaveData.load_data()
	var args := OS.get_cmdline_user_args()
	if "--academy-demo" in args:
		save = SaveData.defaults()
		for k in ["gold", "materials", "aether", "exp"]:
			save[k] = 3000
		save["buildings"]["staff_room"] = 1
		save["buildings"]["frost_tower"] = 1
		save["lessons"] = {"might": 2, "vigor": 1}
		save["character"] = "selene"
		save["shards"] = 9
		SaveData.add_char_exp(save, "selene", GameData.char_exp_for(7) + 40)
		SaveData.char_state(save, "selene")["passive"] = 1
		save["buildings"]["workshop"] = 2
		save["essence"] = {"courtyard": 14}
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for r in [3, 2, 1, 0, 4, 1, 2]:
			SaveData.add_item(save, GameData.roll_item(rng, r))
		SaveData.equip(save, "selene", int(save["items"][0]["uid"]))
		SaveData.equip(save, "selene", int(save["items"][1]["uid"]))
		save["buildings"]["dormitory"] = 2
		for id in ["astra", "lyra", "selene", "nym"]:
			SaveData.move_in(save, id)
		SaveData.add_bond(save, "selene", GameData.BOND_EXP[3] + 30)
		var now := int(Time.get_unix_time_from_system())
		SaveData.start_expedition(save, "lyra", "crystals", now - 3 * 3600)
		SaveData.start_expedition(save, "kael", "scout", now - 7200)
		_demo = true
	_build()
	_refresh()
	if "--academy-lessons" in args:
		_on_open_lessons()
	if "--academy-character" in args:
		_on_open_character()
	if "--academy-gear" in args:
		_char_panel.open(save, String(save.get("character", "astra")), "gear")
	if "--academy-workshop" in args:
		_on_open_workshop()
	if "--academy-bond" in args:
		_char_panel.open(save, String(save.get("character", "astra")), "bond")
	if "--academy-dorm" in args:
		_dorm.open(save, "rooms")
	if "--academy-expedition" in args:
		_dorm.open(save, "exp")
	if "--academy-scroll" in args:
		await get_tree().process_frame
		for sc in find_children("*", "ScrollContainer", true, false):
			sc.scroll_horizontal = 100000
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--academy-shot="):
			_screenshot_and_quit(a.get_slice("=", 1))


func _screenshot_and_quit(path: String) -> void:
	for i in 3:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("[academy] screenshot ", path)
	get_tree().quit()


# ------------------------------------------------------------------ layout

func _build() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 16
	root.offset_right = -16
	root.offset_top = 10
	root.offset_bottom = -10
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var title := _label("ARCANE ACADEMY", 16, GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	_res_label = _label("", 10, IVORY)
	top.add_child(_res_label)

	# character select (scrolls sideways once there are more characters than fit)
	var chars := HBoxContainer.new()
	chars.alignment = BoxContainer.ALIGNMENT_CENTER
	chars.add_theme_constant_override("separation", 6)
	root.add_child(_hscroll(chars, 54))
	for c in GameData.CHARACTERS:
		var b := _button("", Vector2(112, 48), _on_pick_character.bind(c["id"]))
		b.add_theme_font_size_override("font_size", 9)
		b.expand_icon = false
		var tex := CharacterArt.portrait(c["id"])
		if tex != null:
			b.icon = tex
		chars.add_child(b)
		_char_buttons[c["id"]] = b
	var detail_row := HBoxContainer.new()
	detail_row.add_theme_constant_override("separation", 8)
	root.add_child(detail_row)
	_char_detail = _label("", 8, IVORY)
	_char_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_char_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_row.add_child(_char_detail)
	_char_btn = _button("Level · Enhance\nEquipment · Bond", Vector2(116, 30), _on_open_character)
	detail_row.add_child(_char_btn)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	root.add_child(_hscroll(row, 112))
	for b in GameData.BUILDINGS:
		row.add_child(_building_card(b))

	var spacer2 := Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer2)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 10)
	root.add_child(bottom)
	_reset_btn = _button("Reset save", Vector2(80, 28), _on_reset)
	bottom.add_child(_reset_btn)
	_info_label = _label("", 8, Color(IVORY, 0.75))
	_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom.add_child(_info_label)
	var enter := _button("ENTER THE RIFT", Vector2(150, 40), _on_enter)
	enter.add_theme_font_size_override("font_size", 12)
	bottom.add_child(enter)
	_build_lessons_panel()
	_char_panel = CharacterPanel.new(self, func():
		_persist()
		_refresh())
	_workshop = WorkshopPanel.new(self, func():
		_persist()
		_refresh())
	_dorm = DormPanel.new(self, func():
		_persist()
		_refresh())


## A sideways-scrolling strip (touch-drag on phones) holding `content`.
func _hscroll(content: Control, height: float) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, height)
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(content)
	return sc


## Staff Room lessons: an overlay listing every lesson with its teacher, effect, rank and a buy button.
func _build_lessons_panel() -> void:
	_lessons_panel = ColorRect.new()
	(_lessons_panel as ColorRect).color = Color(0, 0, 0, 0.6)
	_lessons_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lessons_panel.visible = false
	add_child(_lessons_panel)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lessons_panel.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(GOLD))
	panel.custom_minimum_size = Vector2(500, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	_lessons_header = _label("", 10, GOLD)
	_lessons_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_lessons_header)
	head.add_child(_button("Close", Vector2(60, 22), func(): _lessons_panel.visible = false))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 270)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 3)
	sc.add_child(list)
	for l in GameData.LESSONS:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 6)
		list.add_child(r)
		var lab := _label("", 8, IVORY)
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(lab)
		var btn := _button("", Vector2(130, 26), _on_buy_lesson.bind(l["id"]))
		r.add_child(btn)
		_lesson_rows[l["id"]] = {"label": lab, "button": btn}


func _building_card(b: Dictionary) -> Control:
	# compact: five buildings scroll sideways and the bottom bar must stay on a 360 px tall screen
	var panel := PanelContainer.new()
	var sb := _style(GOLD)
	sb.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(196, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	panel.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	var title := _label(b["name"], 11, GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var state := _label("", 8, CYAN)
	head.add_child(state)
	var desc := _label(b["desc"], 7, Color(IVORY, 0.75))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(184, 0)
	box.add_child(desc)
	var effect := _label("", 9, IVORY)
	box.add_child(effect)
	var cost := _label("", 8, IVORY)
	box.add_child(cost)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 4)
	box.add_child(buttons)
	var btn := _button("Upgrade", Vector2(0, 20), _on_upgrade.bind(b["id"]))
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(btn)
	var extra: Button = null
	if b["unlocks"] == "lessons":
		extra = _button("Lessons", Vector2(64, 20), _on_open_lessons)
		buttons.add_child(extra)
	elif b["unlocks"] == "workshop":
		extra = _button("Craft", Vector2(64, 20), _on_open_workshop)
		buttons.add_child(extra)
	elif b["unlocks"] == "dorm":
		extra = _button("Open", Vector2(64, 20), func(): _dorm.open(save))
		buttons.add_child(extra)
	_cards[b["id"]] = {"state": state, "effect": effect, "cost": cost, "button": btn, "extra": extra}
	return panel


func _stat_line(c: Dictionary) -> String:
	var b: Dictionary = c["base"]
	var parts: Array = ["HP %d" % int(b["max_hp"]), "Speed %d" % int(b["speed"]), "Damage %d" % int(b["damage"])]
	if b.has("crit"): parts.append("Crit %d%%" % int(b["crit"] * 100))
	if b.has("area_pct"): parts.append("Area +%d%%" % int(b["area_pct"] * 100))
	if b.has("armor"): parts.append("Armor %d%%" % int(b["armor"] * 100))
	if b.has("regen"): parts.append("Regen %.1f/s" % b["regen"])
	if b.has("luck"): parts.append("Luck %d" % int(b["luck"]))
	return "  ·  ".join(parts)


func _refresh() -> void:
	var sel: String = String(save.get("character", "astra"))
	for id in _char_buttons:
		var btn: Button = _char_buttons[id]
		var c := GameData.character_by_id(id)
		var open := SaveData.character_unlocked(save, id)
		var on: bool = id == sel
		if open and SaveData.is_away(save, id):
			btn.text = "%s  Lv %d\nOn expedition" % [c["name"], SaveData.char_level(save, id)]
		elif open:
			btn.text = "%s  Lv %d\n%s" % [c["name"], SaveData.char_level(save, id), c["school"]]
		else:
			btn.text = "%s\nLocked" % c["name"]
		btn.modulate = Color.WHITE if open else Color(0.55, 0.55, 0.65)
		btn.add_theme_stylebox_override("normal", _style(CYAN if on else Color(0.4, 0.4, 0.55)))
		btn.add_theme_color_override("font_color", CYAN if on else IVORY)
	var cdef := GameData.character_by_id(sel)
	_char_detail.text = "%s  ·  %s  ·  %s\nStarter weapon: %s   ·   %s: %s" % [cdef["role"], cdef["school"], _stat_line(cdef),
		GameData.weapon_by_id(cdef["starter"])["name"], cdef["passive"], cdef["passive_desc"]]
	_res_label.text = "Gold %d   Materials %d   Aether %d   EXP %d   Shards %d" % [save["gold"], save["materials"], save["aether"], save["exp"], save["shards"]]
	if _char_panel != null and _char_panel.is_open():
		_char_panel.refresh()
	if _workshop != null and _workshop.is_open():
		_workshop.refresh()
	if _dorm != null and _dorm.is_open():
		_dorm.refresh()
	for b in GameData.BUILDINGS:
		var id: String = b["id"]
		var c: Dictionary = _cards[id]
		var lv := SaveData.building_level(save, id)
		var max_lv: int = b["costs"].size()
		var state_name: String = "Restored" if lv >= max_lv else GameData.BUILDING_STATES[min(lv, GameData.BUILDING_STATES.size() - 1)]
		c["state"].text = "%s %d/%d" % [state_name, lv, max_lv]
		var cost := SaveData.next_cost(save, id)
		c["effect"].text = _building_effect(b, lv, cost.is_empty())
		if c["extra"] != null:
			c["extra"].disabled = lv < 1
		if cost.is_empty():
			c["cost"].text = "Fully restored"
			c["button"].text = "Complete"
			c["button"].disabled = true
		else:
			var parts: Array = []
			for k in ["gold", "materials", "aether"]:
				if int(cost[k]) > 0:
					parts.append("%s %d" % [k.capitalize(), int(cost[k])])
			c["cost"].text = "Cost: " + ", ".join(parts)
			var ok := SaveData.can_afford(save, cost)
			c["cost"].add_theme_color_override("font_color", IVORY if ok else Color(1, 0.5, 0.5))
			c["button"].text = "Upgrade" if ok else "Not enough resources"
			c["button"].disabled = not ok
	_refresh_lessons()
	var lr: Dictionary = save["last_run"]
	var last := "No runs yet."
	if not lr.is_empty():
		last = "Last run: %s, %d kills, +%d gold, +%d materials, +%d aether" % [
			"Victory" if lr.get("victory", false) else "Defeat", int(lr.get("kills", 0)),
			int(lr.get("gold", 0)), int(lr.get("materials", 0)), int(lr.get("aether", 0))]
	queue_redraw()
	_info_label.text = "%s\nRuns %d   Victories %d   Best kills %d" % [last, save["runs"], save["victories"], save["best_kills"]]


# ------------------------------------------------------------------ actions

## What restoring the next level of a building gives (or gave).
func _building_effect(b: Dictionary, lv: int, maxed: bool) -> String:
	match b["unlocks"]:
		"tome", "weapon":
			var kind_name := "Tome" if b["unlocks"] == "tome" else "Weapon"
			var slots := SaveData.slots_for(save, b["unlocks"])
			return "%s slots: %d (max)" % [kind_name, slots] if maxed else "%s slots: %d  >  %d" % [kind_name, slots, slots + 1]
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


func _refresh_lessons() -> void:
	var cap := SaveData.lesson_cap(save)
	_lessons_header.text = "STAFF ROOM LESSONS  ·  rank cap %d  ·  EXP %d  ·  Gold %d" % [cap, save["exp"], save["gold"]]
	for l in GameData.LESSONS:
		var row: Dictionary = _lesson_rows[l["id"]]
		var rank := SaveData.lesson_rank(save, l["id"])
		var total: float = float(l["per"]) * rank
		var fmt := "+%d%%" % int(round(total * 100)) if l["stat"] in GameData.PCT_STATS else "+%d" % int(round(total))
		var per := "+%d%%" % int(round(float(l["per"]) * 100)) if l["stat"] in GameData.PCT_STATS else "+%d" % int(round(float(l["per"])))
		row["label"].text = "%s  (%s)\n%s %s per rank   ·   now %s   ·   rank %d / %d" % [l["name"], l["teacher"], per, l["label"], fmt, rank, cap]
		var cost := SaveData.next_lesson_cost(save, l["id"])
		var btn: Button = row["button"]
		if cost.is_empty():
			btn.text = "Max rank" if cap > 0 else "Locked"
			btn.disabled = true
		else:
			btn.text = "EXP %d  Gold %d" % [cost["exp"], cost["gold"]]
			btn.disabled = not SaveData.can_afford(save, cost)


func _on_open_lessons() -> void:
	_refresh_lessons()
	_lessons_panel.visible = true


func _on_buy_lesson(id: String) -> void:
	if SaveData.buy_lesson(save, id):
		_persist()
	_refresh()


func _on_pick_character(id: String) -> void:
	if SaveData.is_away(save, id):
		_char_detail.text = "%s is on an expedition. Collect or recall them in the Dormitory first." % GameData.character_by_id(id)["name"]
		return
	if not SaveData.character_unlocked(save, id):
		# show who they are and where they live instead of selecting them
		var c := GameData.character_by_id(id)
		var home := ""
		for b in GameData.BUILDINGS:
			if b["id"] == c["unlock"]:
				home = b["name"]
		var need := int(c.get("unlock_level", 1))
		if need > 1:
			home += " to Lv %d" % need
		_char_detail.text = "%s, %s (%s) is locked.\nRestore the %s to bring %s back to the academy." % [c["name"], c["role"], c["school"], home, c["name"]]
		return
	save["character"] = id
	_persist()
	_refresh()


func _on_open_workshop() -> void:
	_workshop.open(save)


func _on_open_character() -> void:
	_char_panel.open(save, String(save.get("character", "astra")))


func _on_upgrade(id: String) -> void:
	if SaveData.upgrade(save, id):
		_persist()
	_refresh()


func _persist() -> void:
	if not _demo:
		SaveData.save_data(save)


func _on_enter() -> void:
	get_tree().change_scene_to_file(RUN_SCENE)


func _on_reset() -> void:
	# two taps so a stray touch never wipes progress
	if not _reset_armed:
		_reset_armed = true
		_reset_btn.text = "Tap again"
		return
	_reset_armed = false
	_reset_btn.text = "Reset save"
	save = SaveData.defaults() if _demo else SaveData.reset()
	_refresh()


# ------------------------------------------------------------------ look

func _draw() -> void:
	var vs := size
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.05, 0.06, 0.14))
	draw_rect(Rect2(0, vs.y * 0.55, vs.x, vs.y * 0.45), Color(0.07, 0.09, 0.2))
	# academy silhouette; more lit windows as buildings are restored
	var lit := 0
	for b in GameData.BUILDINGS:
		lit += SaveData.building_level(save, b["id"]) if not save.is_empty() else 0
	var cx := vs.x * 0.5
	var base := vs.y * 0.55
	var sil := Color(0.1, 0.12, 0.26)
	draw_rect(Rect2(cx - 22, base - 120, 44, 120), sil)
	draw_colored_polygon(PackedVector2Array([Vector2(cx - 28, base - 120), Vector2(cx + 28, base - 120), Vector2(cx, base - 160)]), sil)
	draw_rect(Rect2(cx - 150, base - 60, 110, 60), sil)
	draw_rect(Rect2(cx + 40, base - 70, 120, 70), sil)
	var windows := [Vector2(cx - 6, base - 100), Vector2(cx - 120, base - 40), Vector2(cx + 70, base - 50), Vector2(cx + 110, base - 50), Vector2(cx - 80, base - 40)]
	for i in windows.size():
		var on := i < 1 + lit
		draw_rect(Rect2(windows[i], Vector2(8, 10)), Color(1.0, 0.8, 0.4, 0.9) if on else Color(0.2, 0.22, 0.35))
	draw_circle(Vector2(vs.x * 0.85, vs.y * 0.18), 14, Color(0.9, 0.9, 1.0, 0.25))


func _label(text: String, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	return l


func _style(border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = NAVY
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.set_content_margin_all(8)
	return sb


func _button(text: String, min_size: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 9)
	b.add_theme_stylebox_override("normal", _style(GOLD))
	b.add_theme_stylebox_override("hover", _style(CYAN))
	b.add_theme_stylebox_override("pressed", _style(CYAN))
	b.add_theme_stylebox_override("disabled", _style(Color(0.35, 0.35, 0.4)))
	b.pressed.connect(cb)
	return b
