class_name WorkshopPanel
extends RefCounted
## Academy overlay for the Workshop: craft equipment (materials + Rift Essence, rarity capped by the
## Workshop level) and salvage pieces from the shared inventory.

var save: Dictionary
var on_change: Callable
var root: Control
var _header: HBoxContainer
var _rarity := 0
var _rarity_buttons: Array = []
var _cost: HBoxContainer
var _craft_rows := {}    # base id -> button
var _inv_grid: GridContainer
var _detail: Label
var _salvage: Button
var _sel_uid := -1
var _last: Label
var _armed_uid := -1     # salvage needs a second tap


func _init(parent: Control, change_cb: Callable) -> void:
	on_change = change_cb
	var o := UiKit.overlay(parent, 600, "WORKSHOP", close)
	root = o[0]
	var box: VBoxContainer = o[1]
	_header = HBoxContainer.new()
	_header.add_theme_constant_override("separation", 10)
	box.add_child(_header)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 6)
	box.add_child(cols)

	# left: craft (rarity tabs, cost, bases)
	var lw := UiKit.well(5.0)
	lw[0].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(lw[0])
	var left: VBoxContainer = lw[1]
	left.add_child(UiKit.header("CRAFT", 12, "craft"))
	var rr := HBoxContainer.new()
	rr.add_theme_constant_override("separation", 3)
	left.add_child(rr)
	for i in GameData.GEAR_RARITY_NAMES.size():
		var b := UiKit.button(GameData.GEAR_RARITY_NAMES[i].left(3).to_upper(), Vector2(48, 22), _pick_rarity.bind(i))
		b.tooltip_text = GameData.GEAR_RARITY_NAMES[i]
		for k in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(k, GameData.GEAR_RARITY_COLORS[i])
		rr.add_child(b)
		_rarity_buttons.append(b)
	_cost = HBoxContainer.new()
	_cost.add_theme_constant_override("separation", 6)
	left.add_child(_cost)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 170)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 2)
	sc.add_child(list)
	for b in GameData.EQUIP_BASES:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 4)
		list.add_child(r)
		r.add_child(UiKit.slot(UiKit.stat_icon(b["stat"]), 26.0))
		var lab := UiKit.label("", 10, UiKit.IVORY)
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(lab)
		var btn := UiKit.button("CRAFT", Vector2(58, 24), _on_craft.bind(b["id"]), "accent")
		r.add_child(btn)
		_craft_rows[b["id"]] = {"button": btn, "label": lab}

	# right: inventory grid + selected piece
	var rw := UiKit.well(5.0)
	rw[0].custom_minimum_size = Vector2(262, 0)
	cols.add_child(rw[0])
	var right: VBoxContainer = rw[1]
	right.add_child(UiKit.header("BAG", 12, "chest"))
	var isc := ScrollContainer.new()
	isc.custom_minimum_size = Vector2(0, 150)
	isc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(isc)
	_inv_grid = GridContainer.new()
	_inv_grid.columns = 6
	_inv_grid.add_theme_constant_override("h_separation", 3)
	_inv_grid.add_theme_constant_override("v_separation", 3)
	isc.add_child(_inv_grid)
	var dr := HBoxContainer.new()
	dr.add_theme_constant_override("separation", 4)
	right.add_child(dr)
	_detail = UiKit.label("", 10, UiKit.IVORY)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.custom_minimum_size = Vector2(160, 30)
	dr.add_child(_detail)
	_salvage = UiKit.button("SALVAGE", Vector2(74, 26), func(): _on_salvage(_sel_uid), "danger")
	_salvage.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_salvage.tooltip_text = "Returns %d%% of the craft cost" % int(GameData.SALVAGE_SHARE * 100)
	dr.add_child(_salvage)
	_last = UiKit.label("", 10, UiKit.GREEN)
	box.add_child(_last)


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


## Essence for the picked craft rarity (CRAFT_ESSENCE: higher rarities need later locations).
func _loc() -> String:
	return SaveData.craft_loc(_rarity)


func refresh() -> void:
	var cap := SaveData.craft_rarity_cap(save)
	for ch in _header.get_children():
		ch.queue_free()
	_header.add_child(UiKit.title("Lv %d" % SaveData.building_level(save, "workshop"), 12, UiKit.CYAN))
	_header.add_child(UiKit.chip("materials", str(int(save["materials"]))))
	var ess := UiKit.chip("essence", str(SaveData.essence(save, _loc())))
	ess.tooltip_text = GameData.location_by_id(_loc())["essence"]
	_header.add_child(ess)
	_header.add_child(UiKit.chip("chest", "%d / %d" % [save["items"].size(), GameData.INVENTORY_CAP]))
	for i in _rarity_buttons.size():
		var b: Button = _rarity_buttons[i]
		b.disabled = i > cap
		UiKit.set_selected(b, i == _rarity)
	for ch in _cost.get_children():
		ch.queue_free()
	if cap < 0:
		_cost.add_child(UiKit.label("Restore the Workshop to craft.", 10, UiKit.RED))
	else:
		_cost.add_child(UiKit.label("Cost", 10, Color("d8d2ee")))
		_cost.tooltip_text = "Essence: " + GameData.location_by_id(_loc())["essence"]
		_cost.add_child(UiKit.cost_chips(GameData.CRAFT_COST[_rarity], {"materials": save["materials"], "essence": SaveData.essence(save, _loc())}))
	var ok := SaveData.can_craft(save, _rarity, _loc())
	for id in _craft_rows:
		var base := GameData.equip_base(id)
		var row: Dictionary = _craft_rows[id]
		row["button"].disabled = not ok
		row["label"].text = "%s  %s" % [base["name"], GameData.mod_text(base["stat"], float(base["value"]) * GameData.RARITY_MAIN_MULT[_rarity])]
	_fill_inventory()


func _fill_inventory() -> void:
	for ch in _inv_grid.get_children():
		ch.queue_free()
	var items: Array = save["items"].duplicate()
	items.sort_custom(func(a, b): return int(a["rarity"]) > int(b["rarity"]) or (int(a["rarity"]) == int(b["rarity"]) and int(a["uid"]) > int(b["uid"])))
	if SaveData.item_by_uid(save, _sel_uid).is_empty():
		_sel_uid = int(items[0]["uid"]) if not items.is_empty() else -1
	for it in items:
		var uid := int(it["uid"])
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(38, 38)
		b.pressed.connect(func():
			_sel_uid = uid
			_armed_uid = -1
			_fill_inventory())
		var sl := UiKit.item_slot(it, 38.0)
		sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(sl)
		if SaveData.owner_of(save, uid) != "":
			var e := UiKit.label("E", 10, UiKit.GOLD)
			e.position = Vector2(28, 22)
			b.add_child(e)
		if uid == _sel_uid:
			sl.get_theme_stylebox("panel").glow = Color(1, 1, 1, 0.8)
		_inv_grid.add_child(b)
	var sel := SaveData.item_by_uid(save, _sel_uid)
	_salvage.disabled = sel.is_empty()
	_salvage.text = "SURE?" if _sel_uid == _armed_uid and not sel.is_empty() else "SALVAGE"
	if sel.is_empty():
		_detail.text = "Empty. Pieces drop in the Rift, or craft one."
		_detail.add_theme_color_override("font_color", Color(UiKit.IVORY, 0.6))
	else:
		var owner := SaveData.owner_of(save, _sel_uid)
		_detail.text = "%s%s\n%s" % [GameData.item_name(sel), (" · " + GameData.character_by_id(owner)["name"]) if owner != "" else "", CharactersPage.item_stats(sel)]
		_detail.add_theme_color_override("font_color", GameData.GEAR_RARITY_COLORS[int(sel["rarity"])])


func _pick_rarity(i: int) -> void:
	_rarity = i
	refresh()


func _on_craft(base_id: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var it := SaveData.craft(save, base_id, _rarity, _loc(), rng)
	if not it.is_empty():
		_last.text = "Crafted %s: %s" % [GameData.item_name(it), CharactersPage.item_stats(it)]
		on_change.call()
	refresh()


func _on_salvage(uid: int) -> void:
	if uid < 0:
		return
	if _armed_uid != uid:
		_armed_uid = uid
		refresh()
		return
	_armed_uid = -1
	var it := SaveData.item_by_uid(save, uid)
	var name := GameData.item_name(it)
	if SaveData.salvage(save, uid, SaveData.craft_loc(int(it["rarity"]))):
		_last.text = "Salvaged %s." % name
		on_change.call()
	refresh()
