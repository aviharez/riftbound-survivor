class_name AcademyPage
extends Control
## Academy page: every building as an ornate card (state, what the next level gives, cost, restore button and
## the building's own action: Lessons, Craft, Dormitory). Phase 4 replaces this with the tap-to-open hub map.

var shell
var _cards := {}   # building id -> {state, effect, cost, button, extra, badge}


func _init(s) -> void:
	shell = s
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiKit.header("RESTORE THE ACADEMY"))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	sc.add_child(grid)
	for b in GameData.BUILDINGS:
		grid.add_child(_card(b))


func _card(b: Dictionary) -> Control:
	var pb := UiKit.panel(7.0)
	var p: PanelContainer = pb[0]
	var box: VBoxContainer = pb[1]
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 1)
	var head := HBoxContainer.new()
	box.add_child(head)
	var t := UiKit.title(b["name"], 9)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var state := UiKit.label("", 7, UiKit.CYAN)
	head.add_child(state)
	var desc := UiKit.label(b["desc"], 7, Color(UiKit.IVORY, 0.72))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(170, 0)
	box.add_child(desc)
	var effect := UiKit.label("", 8, UiKit.IVORY)
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(effect)
	var cost := UiKit.label("", 7, UiKit.IVORY)
	box.add_child(cost)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 4)
	box.add_child(buttons)
	var btn := UiKit.button("Restore", Vector2(0, 20), _on_upgrade.bind(b["id"]))
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(btn)
	var extra: Button = null
	match b["unlocks"]:
		"lessons":
			extra = UiKit.button("Lessons", Vector2(60, 20), func(): shell.lessons.open(shell.save), "accent")
		"workshop":
			extra = UiKit.button("Craft", Vector2(60, 20), func(): shell.workshop.open(shell.save), "accent")
		"dorm":
			extra = UiKit.button("Rooms", Vector2(60, 20), func(): shell.dorm.open(shell.save), "accent")
		"character":
			extra = UiKit.button("Meet", Vector2(60, 20), func(): shell.pages["characters"].select(b["character"]); shell.show_page("characters"), "accent")
	if extra != null:
		buttons.add_child(extra)
	_cards[b["id"]] = {"state": state, "effect": effect, "cost": cost, "button": btn, "extra": extra}
	return p


func refresh() -> void:
	var save: Dictionary = shell.save
	for b in GameData.BUILDINGS:
		var id: String = b["id"]
		var c: Dictionary = _cards[id]
		var lv := SaveData.building_level(save, id)
		var max_lv: int = b["costs"].size()
		var state_name: String = "Restored" if lv >= max_lv else GameData.BUILDING_STATES[mini(lv, GameData.BUILDING_STATES.size() - 1)]
		c["state"].text = "%s %d/%d" % [state_name, lv, max_lv]
		c["state"].add_theme_color_override("font_color", UiKit.GREEN if lv >= max_lv else (UiKit.CYAN if lv > 0 else UiKit.RED))
		var cost := SaveData.next_cost(save, id)
		c["effect"].text = building_effect(save, b, lv, cost.is_empty())
		if c["extra"] != null:
			c["extra"].disabled = lv < 1
		if cost.is_empty():
			c["cost"].text = "Fully restored"
			c["cost"].add_theme_color_override("font_color", UiKit.GREEN)
			c["button"].text = "Complete"
			c["button"].disabled = true
		else:
			var ok := SaveData.can_afford(save, cost)
			c["cost"].text = "Cost: " + UiKit.cost_text(cost)
			c["cost"].add_theme_color_override("font_color", UiKit.IVORY if ok else UiKit.RED)
			c["button"].text = "Restore" if lv == 0 else "Upgrade"
			c["button"].disabled = not ok


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


func _on_upgrade(id: String) -> void:
	if SaveData.upgrade(shell.save, id):
		shell.changed()


func on_reset() -> void:
	pass
