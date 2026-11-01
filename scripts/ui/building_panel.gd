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
var _req: VBoxContainer
var _build: Button
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
	_state = UiKit.label("", 9, UiKit.CYAN)
	info.add_child(_state)
	_desc = UiKit.label("", 8, Color(UiKit.IVORY, 0.8))
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_desc)
	_effect = UiKit.label("", 9, UiKit.GOLD)
	_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_effect)
	info.add_child(UiKit.header("REQUISITIONS", 8))
	_req = VBoxContainer.new()
	_req.add_theme_constant_override("separation", 2)
	info.add_child(_req)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	box.add_child(buttons)
	_action = UiKit.button("", Vector2(120, 32), _on_action, "accent")
	buttons.add_child(_action)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(sp)
	_build = UiKit.button("BUILD", Vector2(170, 34), _on_build, "primary")
	_build.add_theme_font_size_override("font_size", UiKit.fs(14))
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
	_state.text = "%s   ·   Level %d / %d" % [state_name.to_upper(), lv, max_lv]
	_state.add_theme_color_override("font_color", UiKit.RED if lv == 0 else (UiKit.GREEN if lv >= max_lv else UiKit.CYAN))
	_desc.text = b["desc"]
	var cost := SaveData.next_cost(save, id)
	_effect.text = Home.building_effect(save, b, lv, cost.is_empty())
	for ch in _req.get_children():
		ch.queue_free()
	if cost.is_empty():
		_req.add_child(UiKit.label("Fully restored.", 8, UiKit.GREEN))
	else:
		for k in cost:
			if int(cost[k]) <= 0:
				continue
			var r := HBoxContainer.new()
			r.add_theme_constant_override("separation", 4)
			r.add_child(UiKit.icon(k, 10.0))
			var have := int(save[k])
			var need := int(cost[k])
			var name := UiKit.label(UiKit.resource_name(k), 8, UiKit.IVORY)
			name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r.add_child(name)
			r.add_child(UiKit.label("%d / %d" % [have, need], 8, UiKit.GREEN if have >= need else UiKit.RED))
			_req.add_child(r)
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
		"lessons": return "Lessons"
		"workshop": return "Craft"
		"dorm": return "Rooms"
		"character": return "Meet %s" % GameData.character_by_id(b["character"])["name"]
	if b["id"] == "library":
		return "Meet Wren"
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
