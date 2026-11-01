class_name CharacterPanel
extends RefCounted
## Academy overlay for one character, in tabs: level / character EXP with the two enhance tracks (passive
## trait, signature weapon), and equipment (three slots filled from the shared inventory).

var save: Dictionary
var char_id := ""
var on_change: Callable   # called after any change (the academy saves and refreshes)
var root: Control
var _header: Label
var _tabs := {}       # tab name -> {button, box}
var _tab := "level"
var _level: Label
var _rows := {}       # enhance track -> {label, button}
var _slots := {}      # equip slot -> {label, change, remove}
var _picker: Control  # inventory picker overlay
var _picker_list: VBoxContainer
var _picker_title: Label
var _picker_slot := ""


func _init(parent: Control, change_cb: Callable) -> void:
	on_change = change_cb
	var o := UiKit.overlay(parent, 540)
	root = o[0]
	var box: VBoxContainer = o[1]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	box.add_child(head)
	_header = UiKit.label("", 11, UiKit.GOLD)
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_header)
	for t in [["level", "Level & Enhance"], ["gear", "Equipment"]]:
		var b := UiKit.button(t[1], Vector2(96, 22), _show_tab.bind(t[0]))
		head.add_child(b)
		_tabs[t[0]] = {"button": b}
	head.add_child(UiKit.button("Close", Vector2(56, 22), close))

	# --- level & enhance
	var lv_box := VBoxContainer.new()
	lv_box.add_theme_constant_override("separation", 4)
	box.add_child(lv_box)
	_tabs["level"]["box"] = lv_box
	_level = UiKit.label("", 8, UiKit.IVORY)
	_level.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lv_box.add_child(_level)
	lv_box.add_child(UiKit.label("ENHANCE  (gold + Arcane Shards; rank N needs character Lv %d x N)" % GameData.ENHANCE_LEVEL_STEP, 9, UiKit.CYAN))
	for track in SaveData.ENHANCE_TRACKS:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 6)
		lv_box.add_child(r)
		var lab := UiKit.label("", 8, UiKit.IVORY)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(lab)
		var btn := UiKit.button("", Vector2(150, 30), _on_enhance.bind(track))
		r.add_child(btn)
		_rows[track] = {"label": lab, "button": btn}

	# --- equipment
	var gear_box := VBoxContainer.new()
	gear_box.add_theme_constant_override("separation", 6)
	box.add_child(gear_box)
	_tabs["gear"]["box"] = gear_box
	gear_box.add_child(UiKit.label("Any character can wear any piece; a piece is worn by one character at a time.", 8, Color(UiKit.IVORY, 0.75)))
	for slot in GameData.EQUIP_SLOTS:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 6)
		gear_box.add_child(r)
		var lab := UiKit.label("", 8, UiKit.IVORY)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.custom_minimum_size = Vector2(0, 30)
		r.add_child(lab)
		var change := UiKit.button("Change", Vector2(70, 28), _open_picker.bind(slot))
		r.add_child(change)
		var remove := UiKit.button("Remove", Vector2(64, 28), _on_unequip.bind(slot))
		r.add_child(remove)
		_slots[slot] = {"label": lab, "change": change, "remove": remove}

	# --- inventory picker (on top of the panel)
	var p := UiKit.overlay(parent, 520)
	_picker = p[0]
	var pbox: VBoxContainer = p[1]
	var phead := HBoxContainer.new()
	pbox.add_child(phead)
	_picker_title = UiKit.label("", 10, UiKit.GOLD)
	_picker_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phead.add_child(_picker_title)
	phead.add_child(UiKit.button("Back", Vector2(56, 22), func(): _picker.visible = false))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 250)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pbox.add_child(sc)
	_picker_list = VBoxContainer.new()
	_picker_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_picker_list.add_theme_constant_override("separation", 3)
	sc.add_child(_picker_list)
	_show_tab("level")


func open(d: Dictionary, id: String, tab := "level") -> void:
	save = d
	char_id = id
	_show_tab(tab)
	root.visible = true


func close() -> void:
	root.visible = false
	_picker.visible = false


func is_open() -> bool:
	return root.visible


func _show_tab(t: String) -> void:
	_tab = t
	for k in _tabs:
		_tabs[k]["box"].visible = k == t
		_tabs[k]["button"].add_theme_stylebox_override("normal", UiKit.style(UiKit.CYAN if k == t else UiKit.GOLD))
	refresh()


func refresh() -> void:
	if char_id == "":
		return
	var c := GameData.character_by_id(char_id)
	_header.text = "%s  ·  %s" % [c["name"], c["role"]]
	_refresh_level(c)
	_refresh_gear()
	if _picker.visible:
		_fill_picker()


func _refresh_level(c: Dictionary) -> void:
	var st := SaveData.char_state(save, char_id)
	var lv := SaveData.char_level(save, char_id)
	var exp := int(st["exp"])
	var exp_line := "MAX LEVEL"
	if lv < GameData.CHAR_MAX_LEVEL:
		var a := GameData.char_exp_for(lv)
		var b := GameData.char_exp_for(lv + 1)
		exp_line = "EXP %d / %d to Lv %d" % [exp - a, b - a, lv + 1]
	var bonus: Array = []
	for m in GameData.char_level_mods(lv):
		if float(m[1]) > 0.0:
			bonus.append(GameData.mod_text(m[0], float(m[1])))
	_level.text = "%s  ·  Level %d / %d   ·   %s\nLevel bonus: %s\nCharacter EXP comes from runs played with %s (same amount as the academy EXP).   Arcane Shards: %d" % [
		c["school"], lv, GameData.CHAR_MAX_LEVEL, exp_line, ", ".join(bonus) if not bonus.is_empty() else "none yet",
		c["name"], int(save["shards"])]
	for track in SaveData.ENHANCE_TRACKS:
		var rank := int(st[track])
		var lab: Label = _rows[track]["label"]
		var btn: Button = _rows[track]["button"]
		if track == "passive":
			lab.text = "Passive · %s   Rank %d / %d\n%s\nEach rank: trait +%d%% stronger (now +%d%%)" % [c["passive"], rank, GameData.ENHANCE_MAX,
				c["passive_desc"], int(GameData.ENHANCE_TRAIT_PER_RANK * 100), int(GameData.ENHANCE_TRAIT_PER_RANK * 100 * rank)]
		else:
			var w := GameData.weapon_by_id(c["starter"])
			lab.text = "Signature weapon · %s   Rank %d / %d\nAlso applies to its evolution.\nEach rank: +%d%% damage, +%d%% attack speed (now +%d%% / +%d%%)" % [
				w["name"], rank, GameData.ENHANCE_MAX, int(GameData.ENHANCE_WEAPON_DMG * 100), int(GameData.ENHANCE_WEAPON_CD * 100),
				int(GameData.ENHANCE_WEAPON_DMG * 100 * rank), int(GameData.ENHANCE_WEAPON_CD * 100 * rank)]
		var cost := SaveData.next_enhance_cost(save, char_id, track)
		if rank >= GameData.ENHANCE_MAX:
			btn.text = "Max rank"
			btn.disabled = true
		elif cost.is_empty():
			btn.text = "Needs character Lv %d" % ((rank + 1) * GameData.ENHANCE_LEVEL_STEP)
			btn.disabled = true
		else:
			var ok := SaveData.can_afford(save, cost)
			btn.text = ("Enhance\n" if ok else "Not enough\n") + UiKit.cost_text(cost)
			btn.disabled = not ok


func _refresh_gear() -> void:
	for slot in GameData.EQUIP_SLOTS:
		var it := SaveData.equipped_item(save, char_id, slot)
		var row: Dictionary = _slots[slot]
		var lab: Label = row["label"]
		if it.is_empty():
			lab.text = "%s:  (empty)" % GameData.EQUIP_SLOT_NAMES[slot]
			lab.add_theme_color_override("font_color", Color(UiKit.IVORY, 0.6))
		else:
			lab.text = "%s:  %s\n%s" % [GameData.EQUIP_SLOT_NAMES[slot], GameData.item_name(it), item_stats(it)]
			lab.add_theme_color_override("font_color", GameData.GEAR_RARITY_COLORS[int(it["rarity"])])
		row["remove"].disabled = it.is_empty()
		row["change"].disabled = _items_for(slot).is_empty()


static func item_stats(it: Dictionary) -> String:
	var parts: Array = []
	for m in GameData.item_mods(it):
		parts.append(GameData.mod_text(m[0], float(m[1])))
	return ", ".join(parts)


## Inventory pieces for a slot, best rarity first.
func _items_for(slot: String) -> Array:
	var out: Array = []
	for it in save["items"]:
		if GameData.equip_base(String(it["base"]))["slot"] == slot:
			out.append(it)
	out.sort_custom(func(a, b): return int(a["rarity"]) > int(b["rarity"]) or (int(a["rarity"]) == int(b["rarity"]) and int(a["uid"]) > int(b["uid"])))
	return out


func _open_picker(slot: String) -> void:
	_picker_slot = slot
	_fill_picker()
	_picker.visible = true


func _fill_picker() -> void:
	for ch in _picker_list.get_children():
		ch.queue_free()
	var c := GameData.character_by_id(char_id)
	_picker_title.text = "%s for %s" % [GameData.EQUIP_SLOT_NAMES[_picker_slot], c["name"]]
	for it in _items_for(_picker_slot):
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 6)
		_picker_list.add_child(r)
		var owner := SaveData.owner_of(save, int(it["uid"]))
		var lab := UiKit.label("%s%s\n%s" % [GameData.item_name(it),
			("   (worn by %s)" % GameData.character_by_id(owner)["name"]) if owner != "" else "", item_stats(it)], 8, GameData.GEAR_RARITY_COLORS[int(it["rarity"])])
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(lab)
		var b := UiKit.button("Wearing" if owner == char_id else "Equip", Vector2(70, 26), _on_equip.bind(int(it["uid"])))
		b.disabled = owner == char_id
		r.add_child(b)


func _on_equip(uid: int) -> void:
	SaveData.equip(save, char_id, uid)
	_picker.visible = false
	on_change.call()
	refresh()


func _on_unequip(slot: String) -> void:
	SaveData.unequip(save, char_id, slot)
	on_change.call()
	refresh()


func _on_enhance(track: String) -> void:
	if SaveData.enhance(save, char_id, track):
		on_change.call()
	refresh()
