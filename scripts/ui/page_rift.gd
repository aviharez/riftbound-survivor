class_name RiftPage
extends Control
## Rift page (battle preparation): the location, the chosen character with their loadout, what the academy
## adds to the run, the record so far, and the big ENTER THE RIFT button. Danger levels come in phase 5.

var shell
var _char_name: Label
var _char_lv: Label
var _kit: HBoxContainer
var _support: GridContainer
var _record: GridContainer
var _last: Label
var _sprite: Control
var _anim_t := 0.0

const BANNER := "res://assets/ui/banner_courtyard.png"


func _init(s) -> void:
	shell = s
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 6)
	add_child(row)

	# left: the location (banner art, danger, time, rewards)
	var lp := UiKit.panel(6.0)
	lp[0].custom_minimum_size = Vector2(232, 0)
	row.add_child(lp[0])
	var left: VBoxContainer = lp[1]
	left.add_theme_constant_override("separation", 5)
	left.add_child(UiKit.header("LOCATION", 12, "expedition"))
	var banner := UiKit.banner(BANNER, 220, 88)
	left.add_child(banner)
	var ln := UiKit.title(GameData.LOCATIONS[0]["name"].to_upper(), 12, UiKit.CYAN)
	ln.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(ln)
	var facts := HBoxContainer.new()
	facts.alignment = BoxContainer.ALIGNMENT_CENTER
	facts.add_theme_constant_override("separation", 12)
	left.add_child(facts)
	var danger := HBoxContainer.new()
	danger.add_theme_constant_override("separation", 3)
	danger.add_child(UiKit.label("Danger", 10, UiKit.RED))
	var dp := UiKit.pips(1, 5, UiKit.RED)
	dp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	danger.add_child(dp)
	facts.add_child(danger)
	facts.add_child(UiKit.chip("bell", "10:00"))
	var rw := UiKit.well(4.0)
	rw[0].size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(rw[0])
	rw[1].add_child(UiKit.title("REWARDS", 12, UiKit.GOLD))
	var rg := GridContainer.new()
	rg.columns = 4
	rg.add_theme_constant_override("h_separation", 4)
	rg.add_theme_constant_override("v_separation", 4)
	rw[1].add_child(rg)
	for r in [["gold", "Gold"], ["materials", "Materials"], ["aether", "Aether"], ["exp", "EXP"], ["essence", GameData.LOCATIONS[0]["essence"]],
			["shards", "Arcane Shards"], ["chest", "Equipment"]]:
		var sl := UiKit.slot(r[0], 38.0)
		sl.tooltip_text = r[1]
		sl.mouse_filter = Control.MOUSE_FILTER_PASS
		rg.add_child(sl)

	# middle: the mage and their kit
	var cp := UiKit.panel(6.0)
	cp[0].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cp[0])
	var mid: VBoxContainer = cp[1]
	mid.add_child(UiKit.header("YOUR MAGE", 12, "characters"))
	var nr := HBoxContainer.new()
	nr.alignment = BoxContainer.ALIGNMENT_CENTER
	nr.add_theme_constant_override("separation", 6)
	mid.add_child(nr)
	_char_name = UiKit.title("", 24, UiKit.GOLD)
	nr.add_child(_char_name)
	_char_lv = UiKit.title("", 12, UiKit.IVORY)
	_char_lv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nr.add_child(_char_lv)
	_sprite = Control.new()
	_sprite.custom_minimum_size = Vector2(0, 110)
	_sprite.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sprite.draw.connect(_draw_sprite)
	mid.add_child(_sprite)
	_kit = HBoxContainer.new()
	_kit.alignment = BoxContainer.ALIGNMENT_CENTER
	_kit.add_theme_constant_override("separation", 4)
	mid.add_child(_kit)
	mid.add_child(UiKit.button("CHANGE MAGE", Vector2(0, 24), func(): shell.show_page("characters"), "info"))

	# right: academy support, record, START
	var rp := VBoxContainer.new()
	rp.custom_minimum_size = Vector2(168, 0)
	rp.add_theme_constant_override("separation", 6)
	row.add_child(rp)
	var lo := UiKit.panel(6.0)
	lo[0].size_flags_vertical = Control.SIZE_EXPAND_FILL
	rp.add_child(lo[0])
	lo[1].add_child(UiKit.header("SUPPORT", 12, "lessons"))
	_support = GridContainer.new()
	_support.columns = 2
	_support.add_theme_constant_override("h_separation", 10)
	lo[1].add_child(_support)
	lo[1].add_child(UiKit.header("RECORD", 12, "trophy"))
	_record = GridContainer.new()
	_record.columns = 2
	_record.add_theme_constant_override("h_separation", 10)
	lo[1].add_child(_record)
	_last = UiKit.label("", 10, Color("d8d2ee"))
	_last.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_last.custom_minimum_size = Vector2(150, 0)
	lo[1].add_child(_last)
	var go := UiKit.rich_button(Vector2(0, 52), func(): shell.enter_rift(), "primary")
	go[1].add_child(UiKit.icon_rect("rift", 32))
	go[1].add_child(UiKit.title("START", 24, UiKit.GOLD))
	rp.add_child(go[0])


func _process(delta: float) -> void:
	if visible:
		_anim_t += delta
		_sprite.queue_redraw()


func refresh() -> void:
	var save: Dictionary = shell.save
	var id := String(save["character"])
	var c := GameData.character_by_id(id)
	var bonus := SaveData.char_run_bonus(save, id)
	_char_name.text = c["name"].to_upper()
	_char_lv.text = "Lv %d" % bonus["level"]
	for ch in _kit.get_children():
		ch.queue_free()
	var w := GameData.weapon_by_id(c["starter"])
	var ws := UiKit.slot(w["id"], 38.0, UiKit.CYAN)
	ws.tooltip_text = "%s (rank %d)" % [w["name"], bonus["weapon"]]
	ws.mouse_filter = Control.MOUSE_FILTER_PASS
	_kit.add_child(ws)
	for slot in GameData.EQUIP_SLOTS:
		var it := SaveData.equipped_item(save, id, slot)
		var icon_name: String = {"weapon": "damage", "armor": "armor", "accessory": "gift"}[slot]
		var gs := UiKit.slot(icon_name, 38.0)
		gs.mouse_filter = Control.MOUSE_FILTER_PASS
		if it.is_empty():
			gs.modulate = Color(1, 1, 1, 0.35)
			gs.tooltip_text = "No %s" % GameData.EQUIP_SLOT_NAMES[slot]
		else:
			var sb := UiKit.rarity_style(GameData.GEAR_RARITY_COLORS[int(it["rarity"])], 0.0)
			sb.pattern = false
			sb.fill = Color("120d24")
			gs.add_theme_stylebox_override("panel", sb)
			gs.tooltip_text = GameData.item_name(it)
		_kit.add_child(gs)
	for ch in _support.get_children():
		ch.queue_free()
	var lessons := 0
	for l in GameData.LESSONS:
		lessons += SaveData.lesson_rank(save, l["id"])
	_support.add_child(UiKit.chip("damage", "Weapons %d" % SaveData.slots_for(save, "weapon")))
	_support.add_child(UiKit.chip("power", "Tomes %d" % SaveData.slots_for(save, "tome")))
	_support.add_child(UiKit.chip("lessons", "Lessons %d" % lessons))
	_support.add_child(UiKit.chip("hp", "Bond %d" % bonus["bond"]))
	for ch in _record.get_children():
		ch.queue_free()
	_record.add_child(UiKit.chip("rift", "Runs %d" % save["runs"]))
	_record.add_child(UiKit.chip("trophy", "Wins %d" % save["victories"]))
	_record.add_child(UiKit.chip("damage", "Best %d" % save["best_kills"]))
	var lr: Dictionary = save["last_run"]
	_last.text = ""
	if not lr.is_empty():
		_last.text = "Last run: %s, %d kills" % ["Victory" if lr.get("victory", false) else "Defeat", int(lr.get("kills", 0))]


func _draw_sprite() -> void:
	var r := Rect2(Vector2.ZERO, _sprite.size)
	var ctr := r.get_center()
	_sprite.draw_set_transform(Vector2(ctr.x, r.end.y - 8), 0.0, Vector2(1.0, 0.3))
	_sprite.draw_circle(Vector2.ZERO, 40, Color(0.3, 0.6, 0.95, 0.25))
	_sprite.draw_arc(Vector2.ZERO, 40, 0, TAU, 40, Color(0.5, 0.9, 1.0, 0.6), 1.5)
	_sprite.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var tex := CharacterArt.frame_at(String(shell.save["character"]), "idle", "south", _anim_t, GameData.CHARACTER_IDLE_FPS)
	if tex != null:
		var k := floorf(clampf((r.size.y - 10.0) / 64.0, 1.0, 3.0))
		var s := Vector2(64, 64) * k
		_sprite.draw_texture_rect(tex, Rect2(Vector2(ctr.x - s.x * 0.5, r.end.y - 6 - s.y), s), false)


func on_reset() -> void:
	pass
