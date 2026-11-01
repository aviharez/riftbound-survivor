class_name WorkshopPanel
extends RefCounted
## Academy overlay for the Workshop: craft equipment (materials + Rift Essence, rarity capped by the
## Workshop level) and salvage pieces from the shared inventory.

var save: Dictionary
var on_change: Callable
var root: Control
var _header: Label
var _rarity := 0
var _rarity_buttons: Array = []
var _cost: Label
var _craft_rows := {}    # base id -> button
var _inv_list: VBoxContainer
var _last: Label
var _armed_uid := -1     # salvage needs a second tap


func _init(parent: Control, change_cb: Callable) -> void:
	on_change = change_cb
	var o := UiKit.overlay(parent, 600)
	root = o[0]
	var box: VBoxContainer = o[1]
	var head := HBoxContainer.new()
	box.add_child(head)
	_header = UiKit.label("", 10, UiKit.GOLD)
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_header)
	head.add_child(UiKit.button("Close", Vector2(56, 22), close))
	var rr := HBoxContainer.new()
	rr.add_theme_constant_override("separation", 4)
	box.add_child(rr)
	rr.add_child(UiKit.label("Craft rarity:", 8, UiKit.IVORY))
	for i in GameData.GEAR_RARITY_NAMES.size():
		var b := UiKit.button(GameData.GEAR_RARITY_NAMES[i], Vector2(64, 20), _pick_rarity.bind(i))
		b.add_theme_color_override("font_color", GameData.GEAR_RARITY_COLORS[i])
		rr.add_child(b)
		_rarity_buttons.append(b)
	_cost = UiKit.label("", 8, UiKit.IVORY)
	box.add_child(_cost)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 8)
	box.add_child(cols)
	var left := _scroll_column(cols, "CRAFT (substats are random)")
	for b in GameData.EQUIP_BASES:
		var r := HBoxContainer.new()
		left.add_child(r)
		var lab := UiKit.label("%s  (%s)" % [b["name"], GameData.EQUIP_SLOT_NAMES[b["slot"]]], 8, UiKit.IVORY)
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(lab)
		var btn := UiKit.button("Craft", Vector2(54, 20), _on_craft.bind(b["id"]))
		r.add_child(btn)
		_craft_rows[b["id"]] = {"button": btn, "label": lab}
	_inv_list = _scroll_column(cols, "INVENTORY  (Salvage returns %d%% of the craft cost)" % int(GameData.SALVAGE_SHARE * 100))
	_last = UiKit.label("", 8, UiKit.CYAN)
	box.add_child(_last)


func _scroll_column(parent: Control, title: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(col)
	col.add_child(UiKit.label(title, 8, UiKit.CYAN))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 200)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 3)
	sc.add_child(list)
	return list


func open(d: Dictionary) -> void:
	save = d
	_rarity = clampi(_rarity, 0, maxi(0, SaveData.craft_rarity_cap(save)))
	_last.text = ""
	_armed_uid = -1
	refresh()
	root.visible = true


func close() -> void:
	root.visible = false


func is_open() -> bool:
	return root.visible


func _loc() -> String:
	return GameData.LOCATIONS[0]["id"]


func refresh() -> void:
	var cap := SaveData.craft_rarity_cap(save)
	_header.text = "WORKSHOP  Lv %d   ·   Materials %d   ·   %s %d   ·   Inventory %d / %d" % [
		SaveData.building_level(save, "workshop"), int(save["materials"]), GameData.LOCATIONS[0]["essence"],
		SaveData.essence(save, _loc()), save["items"].size(), GameData.INVENTORY_CAP]
	for i in _rarity_buttons.size():
		var b: Button = _rarity_buttons[i]
		b.disabled = i > cap
		b.add_theme_stylebox_override("normal", UiKit.style(UiKit.CYAN if i == _rarity else UiKit.GOLD))
	var cost: Dictionary = GameData.CRAFT_COST[_rarity]
	var cap_text := "Restore the Workshop to craft." if cap < 0 else "Workshop Lv %d crafts up to %s; Legendary only drops in the Rift." % [
		SaveData.building_level(save, "workshop"), GameData.GEAR_RARITY_NAMES[cap]]
	_cost.text = "Cost: Materials %d + %s %d.   %s" % [int(cost["materials"]), GameData.LOCATIONS[0]["essence"], int(cost["essence"]), cap_text]
	var ok := SaveData.can_craft(save, _rarity, _loc())
	for id in _craft_rows:
		var base := GameData.equip_base(id)
		var row: Dictionary = _craft_rows[id]
		row["button"].disabled = not ok
		row["label"].text = "%s  (%s)  %s" % [base["name"], GameData.EQUIP_SLOT_NAMES[base["slot"]],
			GameData.mod_text(base["stat"], float(base["value"]) * GameData.RARITY_MAIN_MULT[_rarity])]
	_fill_inventory()


func _fill_inventory() -> void:
	for ch in _inv_list.get_children():
		ch.queue_free()
	var items: Array = save["items"].duplicate()
	items.sort_custom(func(a, b): return int(a["rarity"]) > int(b["rarity"]) or (int(a["rarity"]) == int(b["rarity"]) and int(a["uid"]) > int(b["uid"])))
	if items.is_empty():
		_inv_list.add_child(UiKit.label("Empty. Pieces drop from the boss and elites, or craft one.", 8, Color(UiKit.IVORY, 0.6)))
	for it in items:
		var r := HBoxContainer.new()
		_inv_list.add_child(r)
		var owner := SaveData.owner_of(save, int(it["uid"]))
		var lab := UiKit.label("%s%s\n%s" % [GameData.item_name(it), ("  · %s" % GameData.character_by_id(owner)["name"]) if owner != "" else "",
			CharacterPanel.item_stats(it)], 7, GameData.GEAR_RARITY_COLORS[int(it["rarity"])])
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		r.add_child(lab)
		var uid := int(it["uid"])
		r.add_child(UiKit.button("Sure?" if uid == _armed_uid else "Salvage", Vector2(56, 22), _on_salvage.bind(uid)))


func _pick_rarity(i: int) -> void:
	_rarity = i
	refresh()


func _on_craft(base_id: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var it := SaveData.craft(save, base_id, _rarity, _loc(), rng)
	if not it.is_empty():
		_last.text = "Crafted %s: %s" % [GameData.item_name(it), CharacterPanel.item_stats(it)]
		on_change.call()
	refresh()


func _on_salvage(uid: int) -> void:
	if _armed_uid != uid:
		_armed_uid = uid
		refresh()
		return
	_armed_uid = -1
	var it := SaveData.item_by_uid(save, uid)
	var name := GameData.item_name(it)
	if SaveData.salvage(save, uid, _loc()):
		_last.text = "Salvaged %s." % name
		on_change.call()
	refresh()
