extends Control
## Academy hub (placeholder): spend run rewards on buildings that unlock
## tome / weapon slots, then enter the Rift.
##
## Command-line (after `--`): any --autotest* flag skips straight to the run;
## --academy-shot=/tmp/a.png saves a screenshot of this screen and quits.

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


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autotest"):
			get_tree().change_scene_to_file.call_deferred(RUN_SCENE)
			return
	set_anchors_preset(Control.PRESET_FULL_RECT)
	save = SaveData.load_data()
	_build()
	_refresh()
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

	# character select
	var chars := HBoxContainer.new()
	chars.alignment = BoxContainer.ALIGNMENT_CENTER
	chars.add_theme_constant_override("separation", 8)
	root.add_child(chars)
	for c in GameData.CHARACTERS:
		var b := _button("%s\n%s" % [c["name"], c["role"]], Vector2(132, 56), _on_pick_character.bind(c["id"]))
		b.add_theme_font_size_override("font_size", 10)
		b.expand_icon = false
		var tex := CharacterArt.portrait(c["id"])
		if tex != null:
			b.icon = tex
		chars.add_child(b)
		_char_buttons[c["id"]] = b
	_char_detail = _label("", 8, IVORY)
	_char_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_char_detail)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	root.add_child(row)
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


func _building_card(b: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(GOLD))
	panel.custom_minimum_size = Vector2(270, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	box.add_theme_constant_override("separation", 2)
	box.add_child(_label(b["name"], 12, GOLD))
	var state := _label("", 9, CYAN)
	box.add_child(state)
	var desc := _label(b["desc"], 8, Color(IVORY, 0.75))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(desc)
	var effect := _label("", 10, IVORY)
	box.add_child(effect)
	var cost := _label("", 9, IVORY)
	box.add_child(cost)
	var btn := _button("Upgrade", Vector2(0, 24), _on_upgrade.bind(b["id"]))
	box.add_child(btn)
	_cards[b["id"]] = {"state": state, "effect": effect, "cost": cost, "button": btn}
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
		var on: bool = id == sel
		btn.add_theme_stylebox_override("normal", _style(CYAN if on else Color(0.4, 0.4, 0.55)))
		btn.add_theme_color_override("font_color", CYAN if on else IVORY)
	var cdef := GameData.character_by_id(sel)
	_char_detail.text = "%s\nStarter weapon: %s   ·   Passive %s: %s" % [_stat_line(cdef), GameData.weapon_by_id(cdef["starter"])["name"], cdef["passive"], cdef["passive_desc"]]
	_res_label.text = "Gold %d   Materials %d   Aether %d   EXP %d" % [save["gold"], save["materials"], save["aether"], save["exp"]]
	for b in GameData.BUILDINGS:
		var id: String = b["id"]
		var c: Dictionary = _cards[id]
		var lv := SaveData.building_level(save, id)
		var max_lv: int = b["costs"].size()
		c["state"].text = "%s   (Lv %d / %d)" % [GameData.BUILDING_STATES[min(lv, GameData.BUILDING_STATES.size() - 1)], lv, max_lv]
		var kind_name := "Tome" if b["unlocks"] == "tome" else "Weapon"
		var slots := SaveData.slots_for(save, b["unlocks"])
		var cost := SaveData.next_cost(save, id)
		if cost.is_empty():
			c["effect"].text = "%s slots: %d (max)" % [kind_name, slots]
			c["cost"].text = "Fully restored"
			c["button"].text = "Complete"
			c["button"].disabled = true
		else:
			c["effect"].text = "%s slots: %d  >  %d" % [kind_name, slots, slots + 1]
			var parts: Array = []
			for k in ["gold", "materials", "aether"]:
				if int(cost[k]) > 0:
					parts.append("%s %d" % [k.capitalize(), int(cost[k])])
			c["cost"].text = "Cost: " + ", ".join(parts)
			var ok := SaveData.can_afford(save, cost)
			c["cost"].add_theme_color_override("font_color", IVORY if ok else Color(1, 0.5, 0.5))
			c["button"].text = "Upgrade" if ok else "Not enough resources"
			c["button"].disabled = not ok
	var lr: Dictionary = save["last_run"]
	var last := "No runs yet."
	if not lr.is_empty():
		last = "Last run: %s, %d kills, +%d gold, +%d materials, +%d aether" % [
			"Victory" if lr.get("victory", false) else "Defeat", int(lr.get("kills", 0)),
			int(lr.get("gold", 0)), int(lr.get("materials", 0)), int(lr.get("aether", 0))]
	queue_redraw()
	_info_label.text = "%s\nRuns %d   Victories %d   Best kills %d" % [last, save["runs"], save["victories"], save["best_kills"]]


# ------------------------------------------------------------------ actions

func _on_pick_character(id: String) -> void:
	save["character"] = id
	SaveData.save_data(save)
	_refresh()


func _on_upgrade(id: String) -> void:
	if SaveData.upgrade(save, id):
		SaveData.save_data(save)
	_refresh()


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
	save = SaveData.reset()
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
