class_name CodexPage
extends Control
## Codex: archive of characters, weapons (with their evolution pairs) and enemies.
## Phase 5 adds per-location entries, discovery and quests.

var shell
var _tab := "characters"
var _tabs := {}
var _list: GridContainer
var _detail_title: Label
var _detail_sub: Label
var _detail: Label
var _combo: HBoxContainer
var _art: Control
var _art_kind := ""
var _art_id := ""


func _init(s) -> void:
	shell = s
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	# left: tabs + a grid of icon tiles
	var lp := UiKit.panel(6.0)
	lp[0].custom_minimum_size = Vector2(252, 0)
	row.add_child(lp[0])
	var left: VBoxContainer = lp[1]
	var tabbar := HBoxContainer.new()
	tabbar.add_theme_constant_override("separation", 4)
	left.add_child(tabbar)
	for t in [["characters", "MAGES"], ["weapons", "SPELLS"], ["enemies", "MONSTERS"]]:
		var b := UiKit.button(t[1], Vector2(0, 24), _show.bind(t[0]))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabbar.add_child(b)
		_tabs[t[0]] = b
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(sc)
	_list = GridContainer.new()
	_list.columns = 5
	_list.add_theme_constant_override("h_separation", 4)
	_list.add_theme_constant_override("v_separation", 4)
	sc.add_child(_list)

	# right: big art, name, text, evolution combo
	var rp := UiKit.panel(8.0)
	rp[0].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(rp[0])
	var right: VBoxContainer = rp[1]
	right.add_theme_constant_override("separation", 5)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	right.add_child(top)
	_art = Control.new()
	_art.custom_minimum_size = Vector2(112, 112)
	_art.draw.connect(_draw_art)
	top.add_child(_art)
	var tcol := VBoxContainer.new()
	tcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tcol.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(tcol)
	_detail_title = UiKit.title("", 24, UiKit.GOLD)
	tcol.add_child(_detail_title)
	_detail_sub = UiKit.label("", 10, UiKit.CYAN)
	_detail_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tcol.add_child(_detail_sub)
	var dw := UiKit.well(6.0)
	dw[0].size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(dw[0])
	_detail = UiKit.label("", 10, UiKit.IVORY)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(300, 0)
	dw[1].add_child(_detail)
	_combo = HBoxContainer.new()
	_combo.add_theme_constant_override("separation", 4)
	dw[1].add_child(_combo)


func refresh() -> void:
	_show(_tab)


func _show(t: String) -> void:
	_tab = t
	for k in _tabs:
		UiKit.set_selected(_tabs[k], k == t)
	for ch in _list.get_children():
		ch.queue_free()
	var first := ""
	match t:
		"characters":
			for c in GameData.CHARACTERS:
				var open := SaveData.character_unlocked(shell.save, c["id"])
				_add_entry(c["name"] if open else "???", _pick_char.bind(c["id"]), CharacterArt.portrait(c["id"]), open)
				if first == "":
					first = c["id"]
			if _art_kind != "char":
				_pick_char(first)
		"weapons":
			for w in GameData.WEAPONS:
				if not w.get("evolved", false):
					_add_entry(w["name"], _pick_weapon.bind(w["id"]), UiKit.icon_tex(w["id"]), true)
					if first == "":
						first = w["id"]
			if _art_kind != "weapon":
				_pick_weapon(first)
		"enemies":
			for e in GameData.CODEX_ENEMIES:
				var seen := SaveData.location_unlocked(shell.save, String(e.get("loc", "courtyard")))
				_add_entry(e["name"] if seen else "???", _pick_enemy.bind(e["id"]), _enemy_tex(e["id"]), seen)
			if _art_kind != "enemy":
				_pick_enemy(GameData.CODEX_ENEMIES[0]["id"])


func _add_entry(text: String, cb: Callable, icon: Texture2D, open: bool) -> void:
	var b := UiKit.button("", Vector2(42, 42), cb)
	b.tooltip_text = text
	if icon != null:
		var t := TextureRect.new()
		t.texture = icon
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.position = Vector2(5, 5)
		t.size = Vector2(32, 32)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not open:
			t.modulate = Color(0.08, 0.08, 0.15)
		b.add_child(t)
	_list.add_child(b)


static func _boss_cfg(id: String) -> Dictionary:
	return GameData.BOSSES["guardian"] if id == "boss" else GameData.BOSSES.get(id, {})


func _enemy_tex(id: String) -> Texture2D:
	var b := _boss_cfg(id)
	if not b.is_empty():
		return CharacterArt.texture(String(b["sprite"]), "south")
	var path := "res://assets/enemies/%s.png" % id
	return load(path) if ResourceLoader.exists(path) else PixelSprites.texture(id)


func _pick_char(id: String) -> void:
	_art_kind = "char"
	_art_id = id
	_clear_combo()
	var c := GameData.character_by_id(id)
	var open := SaveData.character_unlocked(shell.save, id)
	_detail_title.text = c["name"].to_upper() if open else "???"
	var home := "From the start"
	for b in GameData.BUILDINGS:
		if b["id"] == c["unlock"]:
			home = "Returns with the %s" % b["name"]
	_detail_sub.text = "%s · %s" % [c["role"], c["school"]] if open else c["school"]
	if open:
		_detail.text = "%s: %s\n%s" % [c["passive"], c["passive_desc"], home]
		_combo.add_child(UiKit.slot(c["starter"], 40.0, UiKit.CYAN))
		_combo.add_child(UiKit.label(GameData.weapon_by_id(c["starter"])["name"], 10, UiKit.CYAN))
	else:
		_detail.text = "Still lost to the Rift.\n%s." % home
	_art.queue_redraw()


func _clear_combo() -> void:
	for ch in _combo.get_children():
		ch.queue_free()


func _pick_weapon(id: String) -> void:
	_art_kind = "weapon"
	_art_id = id
	_clear_combo()
	var w := GameData.weapon_by_id(id)
	var evo := GameData.evolution_of(id)
	_detail_title.text = w["name"].to_upper()
	var users: Array = []
	for c in GameData.CHARACTERS:
		if c["starter"] == id:
			users.append(c["name"])
	_detail_sub.text = ("Signature of " + ", ".join(users)) if not users.is_empty() else "Spell"
	_detail.text = "%s\nLevels: %s" % [w["desc"], w.get("level_desc", "-")]
	if not evo.is_empty():
		# evolution recipe as icons: weapon Lv 8 + tome -> evolution
		_combo.add_child(UiKit.slot(id, 40.0))
		_combo.add_child(UiKit.title("Lv%d +" % GameData.EVOLVE_LEVEL, 12, UiKit.IVORY))
		_combo.add_child(UiKit.slot(evo["tome"], 40.0))
		_combo.add_child(UiKit.title(">", 24, UiKit.GOLD))
		var es := UiKit.slot(evo["id"], 40.0, UiKit.GOLD)
		es.tooltip_text = evo.get("desc", "")
		es.mouse_filter = Control.MOUSE_FILTER_PASS
		_combo.add_child(es)
		var en := UiKit.label(evo["name"], 10, UiKit.GOLD)
		en.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		en.custom_minimum_size = Vector2(70, 0)
		en.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_combo.add_child(en)
	_art.queue_redraw()


func _pick_enemy(id: String) -> void:
	_art_kind = "enemy"
	_art_id = id
	_clear_combo()
	for e in GameData.CODEX_ENEMIES:
		if e["id"] == id:
			var loc := String(e.get("loc", "courtyard"))
			_detail_sub.text = "%s · %s" % [GameData.location_by_id(loc)["name"], "Boss" if not _boss_cfg(id).is_empty() else "Monster"]
			if not SaveData.location_unlocked(shell.save, loc):
				_detail_title.text = "???"
				_detail.text = "Not met yet. Reach the %s." % GameData.location_by_id(loc)["name"]
				_art.queue_redraw()
				return
			_detail_title.text = e["name"].to_upper()
			var stats := ""
			if GameData.ENEMY_TYPES.has(id):
				var t: Dictionary = GameData.ENEMY_TYPES[id]
				_combo.add_child(UiKit.chip("hp", str(int(t["hp"]))))
				_combo.add_child(UiKit.chip("speed", str(int(t["speed"]))))
				_combo.add_child(UiKit.chip("damage", str(int(t["dmg"]))))
			elif not _boss_cfg(id).is_empty():
				_combo.add_child(UiKit.chip("hp", str(int(_boss_cfg(id)["hp"]))))
				_combo.add_child(UiKit.chip("damage", str(int(_boss_cfg(id)["dmg"]))))
			_detail.text = e["desc"] + stats
	_art.queue_redraw()


func _draw_art() -> void:
	var r := Rect2(Vector2.ZERO, _art.size)
	_art.draw_circle(r.get_center(), r.size.x * 0.45, Color(0.4, 0.2, 0.75, 0.25))
	_art.draw_arc(r.get_center(), r.size.x * 0.45, 0, TAU, 40, Color(UiKit.GOLD, 0.6), 1.0)
	var tex: Texture2D = null
	match _art_kind:
		"char":
			tex = CharacterArt.portrait(_art_id)
		"enemy":
			tex = _enemy_tex(_art_id)
		"weapon":
			tex = UiKit.icon_tex(_art_id)
	if tex == null:
		return
	var k := floorf(minf(r.size.x / tex.get_width(), r.size.y / tex.get_height()))
	if _art_kind == "char":
		k = 1.0   # 64 px sprite in a 112 px circle
	var s := Vector2(tex.get_width(), tex.get_height()) * maxf(1.0, k)
	var tint := Color.WHITE
	if _art_kind == "char" and not SaveData.character_unlocked(shell.save, _art_id):
		tint = Color(0.05, 0.05, 0.12)
	if _art_kind == "enemy":
		for e in GameData.CODEX_ENEMIES:
			if e["id"] == _art_id and not SaveData.location_unlocked(shell.save, String(e.get("loc", "courtyard"))):
				tint = Color(0.05, 0.05, 0.12)
	_art.draw_texture_rect(tex, Rect2(r.get_center() - s * 0.5, s), false, tint)


func on_reset() -> void:
	pass
