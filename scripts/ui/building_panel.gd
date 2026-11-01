class_name BuildingPanel
extends RefCounted
## Opens when a building is tapped on the academy map: picture, state, what the next level gives, the
## requisitions (have / need), BUILD / UPGRADE, and the building's own action (Lessons, Craft, Rooms, Meet).

var shell
var root: Control
var id := ""
var _pic: Control
var _name: Label
var _state: Label
var _desc: Label
var _effect: Label
var _req: HBoxContainer
var _build: Button
var _pips: HBoxContainer
var _action: Button


func _init(s, parent: Control) -> void:
	shell = s
	var o := UiKit.overlay(parent, 470, "BUILDING", close)
	root = o[0]
	var box: VBoxContainer = o[1]
	_name = o[2]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	_pic = Control.new()
	_pic.custom_minimum_size = Vector2(150, 150)
	_pic.draw.connect(_draw_pic)
	row.add_child(_pic)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)
	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 6)
	info.add_child(srow)
	_state = UiKit.title("", 12, UiKit.CYAN)
	srow.add_child(_state)
	_pips = HBoxContainer.new()
	_pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	srow.add_child(_pips)
	_desc = UiKit.label("", 10, Color("d8d2ee"))
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size = Vector2(250, 0)
	info.add_child(_desc)
	var ew := UiKit.well(5.0)
	info.add_child(ew[0])
	var er := HBoxContainer.new()
	er.add_theme_constant_override("separation", 5)
	ew[1].add_child(er)
	er.add_child(UiKit.icon_rect("exp", 16))
	_effect = UiKit.label("", 10, UiKit.GOLD)
	_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_effect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	er.add_child(_effect)
	info.add_child(UiKit.header("NEEDED", 12, "materials"))
	_req = HBoxContainer.new()
	_req.add_theme_constant_override("separation", 6)
	info.add_child(_req)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	box.add_child(buttons)
	_action = UiKit.button("", Vector2(130, 34), _on_action, "accent")
	buttons.add_child(_action)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(sp)
	_build = UiKit.button("BUILD", Vector2(170, 34), _on_build, "primary")
	_build.add_theme_font_size_override("font_size", UiKit.tfs(20))
	buttons.add_child(_build)


func open(building_id: String) -> void:
	id = building_id
	refresh()
	root.visible = true


func close() -> void:
	root.visible = false


func is_open() -> bool:
	return root.visible


func refresh() -> void:
	var save: Dictionary = shell.save
	var b := GameData.building_by_id(id)
	var lv := SaveData.building_level(save, id)
	var max_lv: int = b["costs"].size()
	_name.text = b["name"]
	var state_name: String = "Restored" if lv >= max_lv else GameData.BUILDING_STATES[mini(lv, GameData.BUILDING_STATES.size() - 1)]
	_state.text = state_name.to_upper()
	for ch in _pips.get_children():
		ch.queue_free()
	_pips.add_child(UiKit.pips(lv, max_lv, UiKit.CYAN))
	_state.add_theme_color_override("font_color", UiKit.RED if lv == 0 else (UiKit.GREEN if lv >= max_lv else UiKit.CYAN))
	_desc.text = b["desc"]
	var cost := SaveData.next_cost(save, id)
	_effect.text = Home.building_effect(save, b, lv, cost.is_empty())
	for ch in _req.get_children():
		ch.queue_free()
	if cost.is_empty():
		_req.add_child(UiKit.label("Fully restored.", 10, UiKit.GREEN))
	else:
		# each requisition: icon slot with have / need under it (red while short)
		for k in cost:
			if int(cost[k]) <= 0:
				continue
			var have := int(save[k])
			var need := int(cost[k])
			var col := VBoxContainer.new()
			col.add_theme_constant_override("separation", 1)
			var sl := UiKit.slot(k, 38.0, UiKit.GOLD if have >= need else UiKit.PURPLE)
			sl.tooltip_text = UiKit.resource_name(k)
			sl.mouse_filter = Control.MOUSE_FILTER_PASS
			col.add_child(sl)
			var nl := UiKit.label("%s/%s" % [Home._short(have), Home._short(need)], 10, UiKit.GREEN if have >= need else UiKit.RED)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			col.add_child(nl)
			_req.add_child(col)
	if cost.is_empty():
		_build.text = "COMPLETE"
		_build.disabled = true
	else:
		_build.text = "BUILD" if lv == 0 else "UPGRADE"
		_build.disabled = not SaveData.can_afford(save, cost)
	var act := _action_name(b)
	_action.visible = act != ""
	_action.text = act
	_action.disabled = lv < 1
	_pic.queue_redraw()


static func _action_name(b: Dictionary) -> String:
	match b["unlocks"]:
		"lessons": return "LESSONS"
		"workshop": return "CRAFT"
		"dorm": return "ROOMS"
		"character": return "MEET %s" % GameData.character_by_id(b["character"])["name"].to_upper()
	if b["id"] == "library":
		return "MEET WREN"
	return ""


func _draw_pic() -> void:
	var r := Rect2(Vector2.ZERO, _pic.size)
	var ctr := r.get_center()
	_pic.draw_set_transform(ctr + Vector2(0, 40), 0.0, Vector2(1.0, 0.45))
	_pic.draw_circle(Vector2.ZERO, 70, Color(0.3, 0.6, 1.0, 0.18))
	_pic.draw_arc(Vector2.ZERO, 70, 0, TAU, 48, Color(0.5, 0.9, 1.0, 0.6), 1.5)
	_pic.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var path := "res://assets/academy/%s.png" % id
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	var lv := SaveData.building_level(shell.save, id)
	var s := Vector2(144, 144)
	_pic.draw_texture_rect(tex, Rect2(ctr - s * 0.5, s), false, Color.WHITE if lv > 0 else Color(0.45, 1.3, 1.6, 0.55))


func _on_build() -> void:
	if SaveData.upgrade(shell.save, id):
		shell.changed()
		refresh()


func _on_action() -> void:
	var b := GameData.building_by_id(id)
	close()
	match b["unlocks"]:
		"lessons": shell.lessons.open(shell.save)
		"workshop": shell.workshop.open(shell.save)
		"dorm": shell.dorm.open(shell.save)
		"character":
			shell.pages["characters"].select(b["character"])
			shell.show_page("characters")
		_:
			if b["id"] == "library":
				shell.pages["characters"].select("wren")
				shell.show_page("characters")
