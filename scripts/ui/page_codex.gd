class_name CodexPage
extends Control
## Codex: archive of characters, weapons (with their evolution pairs) and enemies, plus the settings corner
## (reset save). Phase 5 adds per-location entries, discovery and quests.

var shell
var _tab := "characters"
var _tabs := {}
var _list: VBoxContainer
var _detail_title: Label
var _detail: Label
var _art: Control
var _art_kind := ""
var _art_id := ""
var _reset: Button
var _armed := false


func _init(s) -> void:
	shell = s
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	var lp := UiKit.panel(8.0)
	lp[0].custom_minimum_size = Vector2(240, 0)
	row.add_child(lp[0])
	var left: VBoxContainer = lp[1]
	var tabbar := HBoxContainer.new()
	tabbar.add_theme_constant_override("separation", 4)
	left.add_child(tabbar)
	for t in [["characters", "Characters"], ["weapons", "Weapons"], ["enemies", "Bestiary"]]:
		var b := UiKit.button(t[1], Vector2(0, 20), _show.bind(t[0]))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_override("font", UiKit.TITLE_FONT)
		tabbar.add_child(b)
		_tabs[t[0]] = b
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(sc)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 3)
	sc.add_child(_list)

	var rp := UiKit.panel(10.0)
	rp[0].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(rp[0])
	var right: VBoxContainer = rp[1]
	_detail_title = UiKit.title("", 13)
	right.add_child(_detail_title)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	right.add_child(body)
	_art = Control.new()
	_art.custom_minimum_size = Vector2(110, 110)
	_art.draw.connect(_draw_art)
	body.add_child(_art)
	_detail = UiKit.label("", 8, UiKit.IVORY)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_detail)
	var foot := HBoxContainer.new()
	right.add_child(foot)
	var credits := UiKit.label("Fonts: Cinzel, Nunito (SIL OFL).  VFX: pixelfx (MIT).", 6, Color(UiKit.IVORY, 0.5))
	credits.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(credits)
	_reset = UiKit.button("Reset save", Vector2(80, 20), _on_reset)
	foot.add_child(_reset)


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
				_add_entry(c["name"] if open else "??? (%s)" % c["school"], _pick_char.bind(c["id"]), CharacterArt.portrait(c["id"]), open)
				if first == "":
					first = c["id"]
			if _art_kind != "char":
				_pick_char(first)
		"weapons":
			for w in GameData.WEAPONS:
				if not w.get("evolved", false):
					_add_entry(w["name"], _pick_weapon.bind(w["id"]), null, true)
					if first == "":
						first = w["id"]
			if _art_kind != "weapon":
				_pick_weapon(first)
		"enemies":
			for e in GameData.CODEX_ENEMIES:
				_add_entry(e["name"], _pick_enemy.bind(e["id"]), null, true)
			if _art_kind != "enemy":
				_pick_enemy(GameData.CODEX_ENEMIES[0]["id"])


func _add_entry(text: String, cb: Callable, icon: Texture2D, open: bool) -> void:
	var b := UiKit.button(text, Vector2(0, 22), cb)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 8)
	if icon != null:
		b.icon = icon
		b.expand_icon = true
	if not open:
		b.modulate = Color(0.6, 0.6, 0.7)
	_list.add_child(b)


func _pick_char(id: String) -> void:
	_art_kind = "char"
	_art_id = id
	var c := GameData.character_by_id(id)
	var open := SaveData.character_unlocked(shell.save, id)
	_detail_title.text = c["name"].to_upper() if open else "???"
	var home := "from the start"
	for b in GameData.BUILDINGS:
		if b["id"] == c["unlock"]:
			home = "returns when the %s is restored" % b["name"]
	_detail.text = "%s  ·  %s\nSignature weapon: %s\nPassive: %s\n%s\n\nHome: %s" % [c["role"], c["school"],
		GameData.weapon_by_id(c["starter"])["name"], c["passive"], c["passive_desc"], home] if open else \
		"A %s student or teacher still lost to the Rift.\nHome: %s." % [c["school"], home]
	_art.queue_redraw()


func _pick_weapon(id: String) -> void:
	_art_kind = "weapon"
	_art_id = id
	var w := GameData.weapon_by_id(id)
	var evo := GameData.evolution_of(id)
	_detail_title.text = w["name"].to_upper()
	var evo_text := "No evolution yet."
	if not evo.is_empty():
		evo_text = "EVOLUTION: %s\nLv %d + %s, then open any chest.\n%s" % [evo["name"], GameData.EVOLVE_LEVEL,
			GameData.tome_by_id(evo["tome"])["name"], evo.get("desc", "")]
	var users: Array = []
	for c in GameData.CHARACTERS:
		if c["starter"] == id:
			users.append(c["name"])
	_detail.text = "%s\nLevels: %s\n%s\n\n%s" % [w["desc"], w.get("level_desc", "-"),
		("Signature weapon of " + ", ".join(users)) if not users.is_empty() else "", evo_text]
	_art.queue_redraw()


func _pick_enemy(id: String) -> void:
	_art_kind = "enemy"
	_art_id = id
	for e in GameData.CODEX_ENEMIES:
		if e["id"] == id:
			_detail_title.text = e["name"].to_upper()
			var stats := ""
			if GameData.ENEMY_TYPES.has(id):
				var t: Dictionary = GameData.ENEMY_TYPES[id]
				stats = "\n\nHP %d   ·   Speed %d   ·   Contact damage %d" % [int(t["hp"]), int(t["speed"]), int(t["dmg"])]
			elif id == "boss":
				stats = "\n\nHP %d   ·   Contact damage %d" % [int(GameData.BOSS["hp"]), int(GameData.BOSS["dmg"])]
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
			tex = CharacterArt.texture("boss", "south") if _art_id == "boss" else PixelSprites.texture(_art_id)
		"weapon":
			UiKit.draw_icon(_art, "aether", r.get_center(), 26.0)
			return
	if tex == null:
		return
	var k := floorf(minf(r.size.x / tex.get_width(), r.size.y / tex.get_height()))
	var s := Vector2(tex.get_width(), tex.get_height()) * maxf(1.0, k)
	var tint := Color.WHITE
	if _art_kind == "char" and not SaveData.character_unlocked(shell.save, _art_id):
		tint = Color(0.05, 0.05, 0.12)
	_art.draw_texture_rect(tex, Rect2(r.get_center() - s * 0.5, s), false, tint)


func _on_reset() -> void:
	if not _armed:
		_armed = true
		_reset.text = "Tap again"
		return
	_armed = false
	_reset.text = "Reset save"
	shell.reset_save()


func on_reset() -> void:
	pass
