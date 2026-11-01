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
var _stats: Label
var _select: Button
var _tab := "enhance"
var _tabs := {}
var _enh_rows := {}
var _slots := {}
var _bond: Label
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
		b.add_theme_font_size_override("font_size", UiKit.fs(6))
		b.tooltip_text = c["name"]
		strip.add_child(b)
		_tiles[c["id"]] = b

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)

	# character card
	var cp := UiKit.panel(8.0)
	cp[0].custom_minimum_size = Vector2(168, 0)
	row.add_child(cp[0])
	var card: VBoxContainer = cp[1]
	_name = UiKit.title("", 13)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_name)
	_role = UiKit.label("", 7, UiKit.GOLD)
	_role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(_role)
	_level = UiKit.label("", 8, UiKit.IVORY)
	_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_level)
	_exp_bar_box = HBoxContainer.new()
	card.add_child(_exp_bar_box)
	card.add_child(UiKit.header("STATS", 8))
	_stats = UiKit.label("", 8, UiKit.IVORY)
	_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stats.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(_stats)
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
	for t in [["enhance", "Enhance"], ["gear", "Equipment"], ["bond", "Bond"]]:
		var b := UiKit.button(t[1], Vector2(0, 20), show_tab.bind(t[0]))
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
	_portrait.draw.connect(_draw_portrait)
	row.add_child(_portrait)
	show_tab("enhance")


func _process(delta: float) -> void:
	if visible:
		_anim_t += delta
		_portrait.queue_redraw()


# ------------------------------------------------------------------ tab content

func _build_enhance(box: VBoxContainer) -> void:
	var note := UiKit.label("Gold + Arcane Shards. Rank N needs character Lv %d x N." % GameData.ENHANCE_LEVEL_STEP, 7, Color(UiKit.IVORY, 0.7))
	box.add_child(note)
	for track in SaveData.ENHANCE_TRACKS:
		var pb := UiKit.panel(6.0)
		box.add_child(pb[0])
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 6)
		pb[1].add_child(r)
		var lab := UiKit.label("", 8, UiKit.IVORY)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(lab)
		var btn := UiKit.button("", Vector2(108, 32), _on_enhance.bind(track), "primary")
		btn.add_theme_font_size_override("font_size", UiKit.fs(8))
		r.add_child(btn)
		_enh_rows[track] = {"label": lab, "button": btn}


func _build_gear(box: VBoxContainer) -> void:
	box.add_child(UiKit.label("Any character can wear any piece, one character at a time.", 7, Color(UiKit.IVORY, 0.7)))
	for slot in GameData.EQUIP_SLOTS:
		var pb := UiKit.panel(6.0)
		box.add_child(pb[0])
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 6)
		pb[1].add_child(r)
		var lab := UiKit.label("", 8, UiKit.IVORY)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.custom_minimum_size = Vector2(0, 24)
		r.add_child(lab)
		var change := UiKit.button("Change", Vector2(54, 24), _open_picker.bind(slot), "accent")
		r.add_child(change)
		var remove := UiKit.button("Remove", Vector2(52, 24), _on_unequip.bind(slot))
		r.add_child(remove)
		_slots[slot] = {"label": lab, "change": change, "remove": remove}


func _build_bond(box: VBoxContainer) -> void:
	_bond = UiKit.label("", 8, UiKit.IVORY)
	_bond.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_bond)
	_bond_bar_box = HBoxContainer.new()
	box.add_child(_bond_bar_box)
	for lv in range(1, GameData.BOND_MAX + 1):
		var r := HBoxContainer.new()
		box.add_child(r)
		var lab := UiKit.label("", 8, UiKit.IVORY)
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(lab)
		var b := UiKit.button("Read", Vector2(48, 18), _read_scene.bind(lv), "accent")
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
	_role.text = "%s  ·  %s" % [c["role"], c["school"]]
	var lv := SaveData.char_level(save, char_id)
	var exp := int(SaveData.char_state(save, char_id)["exp"])
	for ch in _exp_bar_box.get_children():
		ch.queue_free()
	if lv < GameData.CHAR_MAX_LEVEL:
		var a := GameData.char_exp_for(lv)
		var b := GameData.char_exp_for(lv + 1)
		_level.text = "Level %d / %d   ·   EXP %d / %d" % [lv, GameData.CHAR_MAX_LEVEL, exp - a, b - a]
		var bar := UiKit.bar(float(exp - a) / float(b - a), 150.0)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_exp_bar_box.add_child(bar)
	else:
		_level.text = "Level %d / %d   ·   MAX" % [lv, GameData.CHAR_MAX_LEVEL]
	_stats.text = _stats_text(save, c)
	var selected := String(save["character"]) == char_id
	var away := SaveData.is_away(save, char_id)
	if not unlocked:
		_select.text = "LOCKED"
		_select.disabled = true
		_stats.text += "\n\n" + _unlock_hint(c)
	elif away:
		_select.text = "ON EXPEDITION"
		_select.disabled = true
	elif selected:
		_select.text = "IN RIFT TEAM"
		_select.disabled = true
	else:
		_select.text = "SELECT FOR RIFT"
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


## Base stats plus level, equipment and bond bonuses (lessons and in-run tomes come on top in the Rift).
static func _stats_text(save: Dictionary, c: Dictionary) -> String:
	var base: Dictionary = c["base"]
	var add := {}
	for m in SaveData.char_run_bonus(save, c["id"])["mods"]:
		add[m[0]] = float(add.get(m[0], 0.0)) + float(m[1])
	var hp := float(base["max_hp"]) + float(add.get("max_hp", 0.0))
	var dmg := float(base["damage"]) * (1.0 + float(base.get("damage_pct", 0.0)) + float(add.get("damage_pct", 0.0)))
	var spd := float(base["speed"]) * (1.0 + float(add.get("speed_pct", 0.0)))
	var crit := float(base.get("crit", 0.0)) + float(add.get("crit", 0.0))
	var armor := float(base.get("armor", 0.0)) + float(add.get("armor", 0.0))
	var lines: Array = ["HP  %d" % int(round(hp)), "Damage  %.1f" % dmg, "Speed  %d" % int(round(spd)),
		"Crit  %d%%     Armour  %d%%" % [int(round(crit * 100)), int(round(armor * 100))]]
	var other: Array = []
	for k in add:
		if not k in ["max_hp", "damage_pct", "speed_pct", "crit", "armor"] and float(add[k]) > 0.0:
			other.append(GameData.mod_text(k, float(add[k])))
	for k in base:
		if not k in ["max_hp", "damage", "speed", "crit", "armor"]:
			other.append(GameData.mod_text(k, float(base[k])))
	if not other.is_empty():
		lines.append(", ".join(other))
	lines.append("%s: %s" % [c["passive"], c["passive_desc"]])
	return "\n".join(lines)


func _refresh_enhance(save: Dictionary, c: Dictionary, unlocked: bool) -> void:
	var st := SaveData.char_state(save, char_id)
	for track in SaveData.ENHANCE_TRACKS:
		var rank := int(st[track])
		var lab: Label = _enh_rows[track]["label"]
		var btn: Button = _enh_rows[track]["button"]
		if track == "passive":
			lab.text = "PASSIVE · %s   %s\nTrait +%d%% stronger per rank (now +%d%%)" % [c["passive"], _pips(rank),
				int(GameData.ENHANCE_TRAIT_PER_RANK * 100), int(GameData.ENHANCE_TRAIT_PER_RANK * 100 * rank)]
		else:
			var w := GameData.weapon_by_id(c["starter"])
			lab.text = "SIGNATURE · %s   %s\n+%d%% damage, +%d%% attack speed per rank, evolution included (now +%d%% / +%d%%)" % [
				w["name"], _pips(rank), int(GameData.ENHANCE_WEAPON_DMG * 100), int(GameData.ENHANCE_WEAPON_CD * 100),
				int(GameData.ENHANCE_WEAPON_DMG * 100 * rank), int(GameData.ENHANCE_WEAPON_CD * 100 * rank)]
		var cost := SaveData.next_enhance_cost(save, char_id, track)
		if rank >= GameData.ENHANCE_MAX:
			btn.text = "MAX"
			btn.disabled = true
		elif not unlocked:
			btn.text = "Locked"
			btn.disabled = true
		elif cost.is_empty():
			btn.text = "Needs Lv %d" % ((rank + 1) * GameData.ENHANCE_LEVEL_STEP)
			btn.disabled = true
		else:
			btn.text = "ENHANCE\n%d gold · %d shards" % [cost["gold"], cost["shards"]]
			btn.disabled = not SaveData.can_afford(save, cost)


static func _pips(rank: int) -> String:
	return "Rank %d / %d" % [rank, GameData.ENHANCE_MAX]


func _refresh_gear(save: Dictionary, unlocked: bool) -> void:
	for slot in GameData.EQUIP_SLOTS:
		var it := SaveData.equipped_item(save, char_id, slot)
		var row: Dictionary = _slots[slot]
		var lab: Label = row["label"]
		if it.is_empty():
			lab.text = "%s\n(empty)" % GameData.EQUIP_SLOT_NAMES[slot].to_upper()
			lab.add_theme_color_override("font_color", Color(UiKit.IVORY, 0.55))
		else:
			lab.text = "%s · %s\n%s" % [GameData.EQUIP_SLOT_NAMES[slot].to_upper(), GameData.item_name(it), item_stats(it)]
			lab.add_theme_color_override("font_color", GameData.GEAR_RARITY_COLORS[int(it["rarity"])])
		row["remove"].disabled = it.is_empty() or not unlocked
		row["change"].disabled = _items_for(slot).is_empty() or not unlocked


func _refresh_bond(save: Dictionary, c: Dictionary) -> void:
	var exp := int(SaveData.char_state(save, char_id)["bond"])
	var blv := SaveData.bond_level(save, char_id)
	var bonus: Array = []
	for m in GameData.bond_mods(blv):
		if float(m[1]) > 0.0:
			bonus.append(GameData.mod_text(m[0], float(m[1])))
	_bond.text = "BOND Lv %d / %d   ·   bonus %s\nFrom runs with %s (+%d, +%d on victory), expeditions (+%d) and a daily talk in the Dormitory (+%d)." % [
		blv, GameData.BOND_MAX, ", ".join(bonus) if not bonus.is_empty() else "none yet", c["name"],
		GameData.BOND_RUN, GameData.BOND_VICTORY, GameData.BOND_EXPEDITION, GameData.BOND_TALK]
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
		_scene_rows[i][0].text = ("Story %d · %s" % [lv, sc[0]]) if open else "Story %d · reach bond Lv %d" % [lv, lv]
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
