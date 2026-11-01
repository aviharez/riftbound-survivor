class_name CharactersPage
extends Control
## Characters page: roster strip on top; below, the picked character's card (level, EXP, total stats, select
## for the Rift), tabs (Enhance / Equipment / Bond) and a large portrait. The portrait shows the big anime
## illustration `res://assets/illustrations/<id>.png` when Syifa adds one, otherwise the idle sprite scaled up.

const ILLUSTRATION_DIR := "res://assets/illustrations/"

var shell
var char_id := "astra"
var _tiles := {}
var _name: Label
var _role: Label
var _level: Label
var _exp_bar_box: HBoxContainer
var _stat_grid: GridContainer
var _trait_name: Label
var _trait_desc: Label
var _select: Button
var _tab := "enhance"
var _tabs := {}
var _enh_rows := {}
var _slots := {}
var _bond: Label
var _bond_bonus: Label
var _bond_bar_box: HBoxContainer
var _scene_rows: Array = []
var _portrait: Control
var _anim_t := 0.0
# overlays (built by the shell after the pages so they sit on top)
var _picker: Control
var _picker_list: VBoxContainer
var _picker_title: Label
var _picker_slot := ""
var _reader: Control
var _reader_title: Label
var _reader_text: Label


func _init(s) -> void:
	shell = s
	char_id = String(s.save["character"])
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 5)
	add_child(box)

	# roster strip
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 50)
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(sc)
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 4)
	sc.add_child(strip)
	for c in GameData.CHARACTERS:
		var b := UiKit.button("", Vector2(46, 44), select.bind(c["id"]))
		b.icon = CharacterArt.portrait(c["id"])
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_font_size_override("font_size", UiKit.tfs(6))
		b.tooltip_text = c["name"]
		strip.add_child(b)
		_tiles[c["id"]] = b

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)

	# character card: name, level, stat chips, trait, select
	var cp := UiKit.panel(7.0)
	cp[0].custom_minimum_size = Vector2(176, 0)
	row.add_child(cp[0])
	var card: VBoxContainer = cp[1]
	card.add_theme_constant_override("separation", 3)
	_name = UiKit.title("", 24, UiKit.GOLD)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_name)
	_role = UiKit.label("", 10, UiKit.CYAN)
	_role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_role.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_role.custom_minimum_size = Vector2(160, 0)
	card.add_child(_role)
	var lvrow := HBoxContainer.new()
	lvrow.add_theme_constant_override("separation", 4)
	card.add_child(lvrow)
	_level = UiKit.title("", 12, UiKit.IVORY)
	lvrow.add_child(_level)
	_exp_bar_box = HBoxContainer.new()
	_exp_bar_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_exp_bar_box.alignment = BoxContainer.ALIGNMENT_CENTER
	lvrow.add_child(_exp_bar_box)
	var sw := UiKit.well(4.0)
	card.add_child(sw[0])
	_stat_grid = GridContainer.new()
	_stat_grid.columns = 2
	_stat_grid.add_theme_constant_override("h_separation", 8)
	_stat_grid.add_theme_constant_override("v_separation", 1)
	sw[1].add_child(_stat_grid)
	var tw := UiKit.well(4.0)
	tw[0].size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(tw[0])
	_trait_name = UiKit.title("", 12, UiKit.GOLD)
	tw[1].add_child(_trait_name)
	_trait_desc = UiKit.label("", 10, Color("d8d2ee"))
	_trait_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_trait_desc.custom_minimum_size = Vector2(150, 0)
	tw[1].add_child(_trait_desc)
	_select = UiKit.button("SELECT", Vector2(0, 26), _on_select, "primary")
	card.add_child(_select)

	# tabs
	var tp := UiKit.panel(8.0)
	tp[0].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(tp[0])
	var tbox: VBoxContainer = tp[1]
	var tabbar := HBoxContainer.new()
	tabbar.add_theme_constant_override("separation", 4)
	tbox.add_child(tabbar)
	for t in [["enhance", "ENHANCE"], ["gear", "EQUIPMENT"], ["bond", "BOND"]]:
		var b := UiKit.button(t[1], Vector2(0, 24), show_tab.bind(t[0]))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_override("font", UiKit.TITLE_FONT)
		tabbar.add_child(b)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 5)
		content.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tbox.add_child(content)
		_tabs[t[0]] = {"button": b, "box": content}
	_build_enhance(_tabs["enhance"]["box"])
	_build_gear(_tabs["gear"]["box"])
	_build_bond(_tabs["bond"]["box"])

	# portrait
	_portrait = Control.new()
	_portrait.custom_minimum_size = Vector2(150, 0)
	_portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_portrait.size_flags_stretch_ratio = 0.5
	_portrait.draw.connect(_draw_portrait)
	row.add_child(_portrait)
	show_tab("enhance")


func _process(delta: float) -> void:
	if visible:
		_anim_t += delta
		_portrait.queue_redraw()


# ------------------------------------------------------------------ tab content

## One tab row: dark well with an icon slot, a text column and room for buttons; returns the parts.
func _row(box: VBoxContainer, icon_name: String) -> Dictionary:
	var pb := UiKit.well(4.0)
	box.add_child(pb[0])
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 6)
	pb[1].add_child(r)
	var slot := UiKit.slot(icon_name, 40.0)
	r.add_child(slot)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	r.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	col.add_child(head)
	var name_l := UiKit.title("", 12)
	head.add_child(name_l)
	var sub := UiKit.label("", 10, Color("d8d2ee"))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(120, 0)
	col.add_child(sub)
	return {"row": r, "slot": slot, "name": name_l, "head": head, "sub": sub}


func _build_enhance(box: VBoxContainer) -> void:
	for track in SaveData.ENHANCE_TRACKS:
		var p := _row(box, "crit")
		var pips_holder := HBoxContainer.new()
		pips_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		p["head"].add_child(pips_holder)
		var rb := UiKit.rich_button(Vector2(112, 40), _on_enhance.bind(track), "primary")
		var btn: Button = rb[0]
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		p["row"].add_child(btn)
		p["button"] = btn
		p["content"] = rb[1]
		p["pips"] = pips_holder
		_enh_rows[track] = p


func _build_gear(box: VBoxContainer) -> void:
	for slot in GameData.EQUIP_SLOTS:
		var icon_name: String = {"weapon": "damage", "armor": "armor", "accessory": "gift"}[slot]
		var p := _row(box, icon_name)
		var change := UiKit.button("CHANGE", Vector2(64, 26), _open_picker.bind(slot), "accent")
		change.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		p["row"].add_child(change)
		var remove := UiKit.button("X", Vector2(26, 26), _on_unequip.bind(slot), "danger")
		remove.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		p["row"].add_child(remove)
		p["change"] = change
		p["remove"] = remove
		_slots[slot] = p


func _build_bond(box: VBoxContainer) -> void:
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	box.add_child(top)
	top.add_child(UiKit.icon_rect("hp", 32))
	var tcol := VBoxContainer.new()
	tcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tcol.add_theme_constant_override("separation", 1)
	top.add_child(tcol)
	_bond = UiKit.title("", 12, Color("ff9ac8"))
	tcol.add_child(_bond)
	_bond_bar_box = HBoxContainer.new()
	tcol.add_child(_bond_bar_box)
	_bond_bonus = UiKit.label("", 10, Color("d8d2ee"))
	tcol.add_child(_bond_bonus)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 2)
	sc.add_child(list)
	for lv in range(1, GameData.BOND_MAX + 1):
		var pb := UiKit.well(3.0)
		list.add_child(pb[0])
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 4)
		pb[1].add_child(r)
		r.add_child(UiKit.icon_rect("scroll", 16))
		var lab := UiKit.label("", 10, UiKit.IVORY)
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(lab)
		var b := UiKit.button("READ", Vector2(52, 22), _read_scene.bind(lv), "accent")
		r.add_child(b)
		_scene_rows.append([lab, b])


## Inventory picker and story reader live on the shell so they cover the whole screen.
func build_overlays(parent: Control) -> void:
	var p := UiKit.overlay(parent, 500, "EQUIP", func(): _picker.visible = false)
	_picker = p[0]
	var pbox: VBoxContainer = p[1]
	_picker_title = p[2]
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 240)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pbox.add_child(sc)
	_picker_list = VBoxContainer.new()
	_picker_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_picker_list.add_theme_constant_override("separation", 3)
	sc.add_child(_picker_list)

	var rd := UiKit.overlay(parent, 440, "STORY", func(): _reader.visible = false)
	_reader = rd[0]
	var rbox: VBoxContainer = rd[1]
	_reader_title = rd[2]
	_reader_text = UiKit.label("", 9, UiKit.IVORY)
	_reader_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reader_text.custom_minimum_size = Vector2(420, 0)
	rbox.add_child(_reader_text)


# ------------------------------------------------------------------ state

func select(id: String) -> void:
	char_id = id
	refresh()


func show_tab(t: String) -> void:
	if t == "level":
		t = "enhance"
	if not _tabs.has(t):
		return
	_tab = t
	for k in _tabs:
		_tabs[k]["box"].visible = k == t
		UiKit.set_selected(_tabs[k]["button"], k == t)


func on_reset() -> void:
	char_id = String(shell.save["character"])


func _save() -> Dictionary:
	return shell.save


func refresh() -> void:
	var save := _save()
	var c := GameData.character_by_id(char_id)
	var unlocked := SaveData.character_unlocked(save, char_id)
	for id in _tiles:
		var b: Button = _tiles[id]
		var open := SaveData.character_unlocked(save, id)
		b.text = ("Lv %d" % SaveData.char_level(save, id)) if open else "?"
		b.modulate = Color.WHITE if open else Color(0.35, 0.35, 0.45)
		UiKit.set_selected(b, id == char_id)
	_name.text = c["name"].to_upper()
	_role.text = c["school"]
	_role.tooltip_text = c["role"]
	var lv := SaveData.char_level(save, char_id)
	var exp := int(SaveData.char_state(save, char_id)["exp"])
	for ch in _exp_bar_box.get_children():
		ch.queue_free()
	_level.text = "Lv %d" % lv
	if lv < GameData.CHAR_MAX_LEVEL:
		var a := GameData.char_exp_for(lv)
		var b := GameData.char_exp_for(lv + 1)
		var bar := UiKit.bar(float(exp - a) / float(b - a), 110.0)
		bar.tooltip_text = "EXP %d / %d" % [exp - a, b - a]
		_exp_bar_box.add_child(bar)
	else:
		_exp_bar_box.add_child(UiKit.title("MAX", 12, UiKit.GOLD))
	for ch in _stat_grid.get_children():
		ch.queue_free()
	for st in _stat_list(save, c):
		_stat_grid.add_child(UiKit.chip(st[0], st[1]))
	_trait_name.text = c["passive"]
	_trait_desc.text = c["passive_desc"]
	var selected := String(save["character"]) == char_id
	var away := SaveData.is_away(save, char_id)
	if not unlocked:
		_select.text = "LOCKED"
		_select.disabled = true
		_trait_desc.text = _unlock_hint(c)
	elif away:
		_select.text = "ON EXPEDITION"
		_select.disabled = true
	elif selected:
		_select.text = "IN RIFT TEAM"
		_select.disabled = true
	else:
		_select.text = "SELECT"
		_select.disabled = false
	_refresh_enhance(save, c, unlocked)
	_refresh_gear(save, unlocked)
	_refresh_bond(save, c)
	if _picker != null and _picker.visible:
		_fill_picker()
	_portrait.queue_redraw()


static func _unlock_hint(c: Dictionary) -> String:
	var home := ""
	for b in GameData.BUILDINGS:
		if b["id"] == c["unlock"]:
			home = b["name"]
	var need := int(c.get("unlock_level", 1))
	return "Restore the %s%s to bring %s back." % [home, (" to Lv %d" % need) if need > 1 else "", c["name"]]


## Base stats plus level, equipment and bond bonuses as [icon, text] chips (lessons and in-run tomes come on
## top in the Rift).
static func _stat_list(save: Dictionary, c: Dictionary) -> Array:
	var base: Dictionary = c["base"]
	var add := {}
	for m in SaveData.char_run_bonus(save, c["id"])["mods"]:
		add[m[0]] = float(add.get(m[0], 0.0)) + float(m[1])
	var hp := float(base["max_hp"]) + float(add.get("max_hp", 0.0))
	var dmg := float(base["damage"]) * (1.0 + float(base.get("damage_pct", 0.0)) + float(add.get("damage_pct", 0.0)))
	var spd := float(base["speed"]) * (1.0 + float(add.get("speed_pct", 0.0)))
	var crit := float(base.get("crit", 0.0)) + float(add.get("crit", 0.0))
	var armor := float(base.get("armor", 0.0)) + float(add.get("armor", 0.0))
	var out: Array = [["hp", "%d" % int(round(hp))], ["damage", "%.1f" % dmg], ["speed", "%d" % int(round(spd))],
		["crit", "%d%%" % int(round(crit * 100))], ["armor", "%d%%" % int(round(armor * 100))]]
	var xp := float(base.get("xp_pct", 0.0)) + float(add.get("xp_pct", 0.0))
	if xp > 0.0:
		out.append(["exp", "+%d%%" % int(round(xp * 100))])
	return out


func _refresh_enhance(save: Dictionary, c: Dictionary, unlocked: bool) -> void:
	var st := SaveData.char_state(save, char_id)
	for track in SaveData.ENHANCE_TRACKS:
		var rank := int(st[track])
		var p: Dictionary = _enh_rows[track]
		var btn: Button = p["button"]
		var content: HBoxContainer = p["content"]
		if track == "passive":
			p["name"].text = c["passive"]
			p["sub"].text = "Trait +%d%% per rank" % int(GameData.ENHANCE_TRAIT_PER_RANK * 100)
			_set_slot_icon(p["slot"], "crit")
		else:
			var w := GameData.weapon_by_id(c["starter"])
			p["name"].text = w["name"]
			p["sub"].text = "+%d%% dmg, +%d%% atk speed per rank" % [int(GameData.ENHANCE_WEAPON_DMG * 100), int(GameData.ENHANCE_WEAPON_CD * 100)]
			_set_slot_icon(p["slot"], w["id"])
		for ch in p["pips"].get_children():
			ch.queue_free()
		p["pips"].add_child(UiKit.pips(rank, GameData.ENHANCE_MAX))
		for ch in content.get_children():
			ch.queue_free()
		var cost := SaveData.next_enhance_cost(save, char_id, track)
		if rank >= GameData.ENHANCE_MAX:
			content.add_child(UiKit.title("MAX", 12, UiKit.GOLD))
			btn.disabled = true
		elif not unlocked:
			content.add_child(UiKit.icon_rect("lock", 16))
			btn.disabled = true
		elif cost.is_empty():
			content.add_child(UiKit.icon_rect("lock", 16))
			content.add_child(UiKit.title("Lv %d" % ((rank + 1) * GameData.ENHANCE_LEVEL_STEP), 12))
			btn.disabled = true
		else:
			var col := VBoxContainer.new()
			col.alignment = BoxContainer.ALIGNMENT_CENTER
			col.add_theme_constant_override("separation", 0)
			col.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content.add_child(col)
			var t := UiKit.title("ENHANCE", 12, UiKit.GOLD)
			t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			col.add_child(t)
			var cc := UiKit.cost_chips(cost, save)
			cc.alignment = BoxContainer.ALIGNMENT_CENTER
			col.add_child(cc)
			btn.disabled = not SaveData.can_afford(save, cost)


static func _set_slot_icon(slot: Control, icon_name: String) -> void:
	var ic := slot.get_child(0) as TextureRect
	ic.texture = UiKit.icon_tex(icon_name)


func _refresh_gear(save: Dictionary, unlocked: bool) -> void:
	for slot in GameData.EQUIP_SLOTS:
		var it := SaveData.equipped_item(save, char_id, slot)
		var p: Dictionary = _slots[slot]
		if it.is_empty():
			p["name"].text = GameData.EQUIP_SLOT_NAMES[slot]
			p["name"].add_theme_color_override("font_color", Color(UiKit.IVORY, 0.5))
			p["sub"].text = "Empty"
		else:
			var col: Color = GameData.GEAR_RARITY_COLORS[int(it["rarity"])]
			p["name"].text = GameData.item_name(it)
			p["name"].add_theme_color_override("font_color", col)
			p["sub"].text = item_stats(it)
			var sb := UiKit.rarity_style(col, 0.0)
			sb.pattern = false
			sb.fill = Color("120d24")
			p["slot"].add_theme_stylebox_override("panel", sb)
		if it.is_empty():
			var eb := UiKit.style(UiKit.PURPLE, 0.0)
			eb.pattern = false
			eb.fill = Color("120d24")
			p["slot"].add_theme_stylebox_override("panel", eb)
		p["remove"].disabled = it.is_empty() or not unlocked
		p["change"].disabled = _items_for(slot).is_empty() or not unlocked


func _refresh_bond(save: Dictionary, c: Dictionary) -> void:
	var exp := int(SaveData.char_state(save, char_id)["bond"])
	var blv := SaveData.bond_level(save, char_id)
	var bonus: Array = []
	for m in GameData.bond_mods(blv):
		if float(m[1]) > 0.0:
			bonus.append(GameData.mod_text(m[0], float(m[1])))
	_bond.text = "BOND Lv %d / %d" % [blv, GameData.BOND_MAX]
	_bond_bonus.text = ", ".join(bonus) if not bonus.is_empty() else "Runs, expeditions and talks raise bond"
	_bond_bonus.tooltip_text = "Runs with %s +%d (+%d on victory), expeditions +%d, daily talk in the Dormitory +%d." % [
		c["name"], GameData.BOND_RUN, GameData.BOND_VICTORY, GameData.BOND_EXPEDITION, GameData.BOND_TALK]
	for ch in _bond_bar_box.get_children():
		ch.queue_free()
	if blv < GameData.BOND_MAX:
		var bar := UiKit.bar(float(exp - GameData.BOND_EXP[blv]) / float(GameData.BOND_EXP[blv + 1] - GameData.BOND_EXP[blv]), 200.0, Color(1.0, 0.55, 0.75))
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_bond_bar_box.add_child(bar)
	for i in _scene_rows.size():
		var lv := i + 1
		var sc := BondScenes.scene(char_id, lv)
		var open := blv >= lv and not sc.is_empty()
		_scene_rows[i][0].text = sc[0] if open else "Bond Lv %d" % lv
		_scene_rows[i][0].add_theme_color_override("font_color", UiKit.IVORY if open else Color(UiKit.IVORY, 0.45))
		_scene_rows[i][1].disabled = not open


static func item_stats(it: Dictionary) -> String:
	var parts: Array = []
	for m in GameData.item_mods(it):
		parts.append(GameData.mod_text(m[0], float(m[1])))
	return ", ".join(parts)


func _items_for(slot: String) -> Array:
	var out: Array = []
	for it in _save()["items"]:
		if GameData.equip_base(String(it["base"]))["slot"] == slot:
			out.append(it)
	out.sort_custom(func(a, b): return int(a["rarity"]) > int(b["rarity"]) or (int(a["rarity"]) == int(b["rarity"]) and int(a["uid"]) > int(b["uid"])))
	return out


# ------------------------------------------------------------------ portrait

func _draw_portrait() -> void:
	var r := Rect2(Vector2.ZERO, _portrait.size)
	var ctr := r.get_center()
	# soft rift glow and a floor disc
	for i in 6:
		_portrait.draw_circle(ctr + Vector2(0, -10), 70.0 - i * 10.0, Color(0.45, 0.2, 0.8, 0.06 + i * 0.015))
	_portrait.draw_set_transform(Vector2(ctr.x, r.end.y - 22), 0.0, Vector2(1.0, 0.32))
	_portrait.draw_circle(Vector2.ZERO, 54, Color(0.25, 0.6, 0.9, 0.25))
	_portrait.draw_arc(Vector2.ZERO, 54, 0, TAU, 48, Color(0.5, 0.9, 1.0, 0.7), 2.0)
	_portrait.draw_arc(Vector2.ZERO, 44, 0, TAU, 48, Color(0.86, 0.7, 0.32, 0.6), 1.0)
	_portrait.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var path := ILLUSTRATION_DIR + char_id + ".png"
	if ResourceLoader.exists(path):
		var ill: Texture2D = load(path)
		var k := r.size.y / ill.get_height()
		var sz := Vector2(ill.get_width(), ill.get_height()) * k
		_portrait.draw_texture_rect(ill, Rect2(Vector2(ctr.x - sz.x * 0.5, r.end.y - sz.y), sz), false)
		return
	var tex: Texture2D = CharacterArt.frame_at(char_id, "idle", "south", _anim_t, GameData.CHARACTER_IDLE_FPS)
	if tex == null:
		return
	var scale := floorf(minf(r.size.x / 64.0, (r.size.y - 10.0) / 64.0))
	var s := Vector2(64, 64) * maxf(1.0, scale)
	var tint := Color.WHITE if SaveData.character_unlocked(_save(), char_id) else Color(0.08, 0.08, 0.15)
	_portrait.draw_texture_rect(tex, Rect2(Vector2(ctr.x - s.x * 0.5, r.end.y - 18 - s.y), s), false, tint)


# ------------------------------------------------------------------ actions

func _on_select() -> void:
	var save := _save()
	if SaveData.character_unlocked(save, char_id) and not SaveData.is_away(save, char_id):
		save["character"] = char_id
		shell.changed()


func _on_enhance(track: String) -> void:
	if SaveData.enhance(_save(), char_id, track):
		shell.changed()


func _open_picker(slot: String) -> void:
	_picker_slot = slot
	_fill_picker()
	_picker.visible = true


func _fill_picker() -> void:
	for ch in _picker_list.get_children():
		ch.queue_free()
	var save := _save()
	_picker_title.text = "%s for %s" % [GameData.EQUIP_SLOT_NAMES[_picker_slot].to_upper(), GameData.character_by_id(char_id)["name"]]
	for it in _items_for(_picker_slot):
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 6)
		_picker_list.add_child(r)
		var owner := SaveData.owner_of(save, int(it["uid"]))
		var lab := UiKit.label("%s%s\n%s" % [GameData.item_name(it),
			("   (worn by %s)" % GameData.character_by_id(owner)["name"]) if owner != "" else "", item_stats(it)], 8,
			GameData.GEAR_RARITY_COLORS[int(it["rarity"])])
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(lab)
		var b := UiKit.button("Wearing" if owner == char_id else "Equip", Vector2(70, 26), _on_equip.bind(int(it["uid"])), "accent")
		b.disabled = owner == char_id
		r.add_child(b)


func _on_equip(uid: int) -> void:
	SaveData.equip(_save(), char_id, uid)
	_picker.visible = false
	shell.changed()


func _on_unequip(slot: String) -> void:
	SaveData.unequip(_save(), char_id, slot)
	shell.changed()


func _read_scene(lv: int) -> void:
	var sc := BondScenes.scene(char_id, lv)
	if sc.is_empty():
		return
	_reader_title.text = "%s · %s" % [GameData.character_by_id(char_id)["name"], sc[0]]
	_reader_text.text = sc[1]
	_reader.visible = true
