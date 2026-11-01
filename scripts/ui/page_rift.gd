class_name RiftPage
extends Control
## Rift page (battle preparation): the location, the chosen character with their loadout, what the academy
## adds to the run, the record so far, and the big ENTER THE RIFT button. Danger levels come in phase 5.

var shell
var _loc: Label
var _char_name: Label
var _char_info: Label
var _loadout: Label
var _record: Label
var _sprite: Control
var _anim_t := 0.0


func _init(s) -> void:
	shell = s
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 6)
	add_child(row)

	var lp := UiKit.panel(8.0)
	lp[0].custom_minimum_size = Vector2(190, 0)
	row.add_child(lp[0])
	var left: VBoxContainer = lp[1]
	left.add_child(UiKit.header("LOCATION", 8))
	var ln := UiKit.title(GameData.LOCATIONS[0]["name"].to_upper(), 11, UiKit.CYAN)
	ln.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(ln)
	var scene := Control.new()
	scene.custom_minimum_size = Vector2(0, 70)
	scene.draw.connect(_draw_location.bind(scene))
	left.add_child(scene)
	_loc = UiKit.label("", 7, UiKit.IVORY)
	_loc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_loc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_loc)

	var cp := UiKit.panel(8.0)
	cp[0].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cp[0])
	var mid: VBoxContainer = cp[1]
	mid.add_child(UiKit.header("YOUR MAGE", 8))
	_char_name = UiKit.title("", 13)
	_char_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(_char_name)
	_sprite = Control.new()
	_sprite.custom_minimum_size = Vector2(0, 100)
	_sprite.draw.connect(_draw_sprite)
	mid.add_child(_sprite)
	_char_info = UiKit.label("", 8, UiKit.IVORY)
	_char_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_char_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_char_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_child(_char_info)
	mid.add_child(UiKit.button("Change character", Vector2(0, 20), func(): shell.show_page("characters"), "accent"))

	var rp := VBoxContainer.new()
	rp.custom_minimum_size = Vector2(200, 0)
	rp.add_theme_constant_override("separation", 6)
	row.add_child(rp)
	var lo := UiKit.panel(8.0)
	lo[0].size_flags_vertical = Control.SIZE_EXPAND_FILL
	rp.add_child(lo[0])
	lo[1].add_child(UiKit.header("ACADEMY SUPPORT", 8))
	_loadout = UiKit.label("", 7, UiKit.IVORY)
	_loadout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lo[1].add_child(_loadout)
	lo[1].add_child(UiKit.header("RECORD", 8))
	_record = UiKit.label("", 7, UiKit.IVORY)
	_record.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lo[1].add_child(_record)
	var go := UiKit.button("ENTER THE RIFT", Vector2(0, 44), func(): shell.enter_rift(), "primary")
	go.add_theme_font_size_override("font_size", 14)
	rp.add_child(go)


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
	var gear: Array = []
	for slot in GameData.EQUIP_SLOTS:
		var it := SaveData.equipped_item(save, id, slot)
		if not it.is_empty():
			gear.append(GameData.item_name(it))
	_char_info.text = "%s · %s · Level %d · Bond %d\nSignature: %s (rank %d)   Passive: %s (rank %d)\nGear: %s" % [c["role"], c["school"],
		bonus["level"], bonus["bond"], GameData.weapon_by_id(c["starter"])["name"], bonus["weapon"], c["passive"], bonus["passive"],
		", ".join(gear) if not gear.is_empty() else "none"]
	_loc.text = "The ruined grounds where the Rift first opened. Slimes, bats, brutes and casters; the Corrupted Guardian waits at the portal.\n\nDanger 1   ·   10 minutes\nRewards: gold, materials, aether, EXP, %s, Arcane Shards, equipment.\n\nMore locations and danger levels come later." % GameData.LOCATIONS[0]["essence"]
	var lessons: Array = []
	for l in GameData.LESSONS:
		var rank := SaveData.lesson_rank(save, l["id"])
		if rank > 0:
			lessons.append("%s %d" % [l["name"], rank])
	_loadout.text = "Weapon slots %d   ·   Tome slots %d\nLessons: %s" % [SaveData.slots_for(save, "weapon"), SaveData.slots_for(save, "tome"),
		", ".join(lessons) if not lessons.is_empty() else "none yet (Staff Room)"]
	var lr: Dictionary = save["last_run"]
	var last := "No runs yet."
	if not lr.is_empty():
		last = "Last run: %s, %d kills, +%d gold, +%d materials" % ["Victory" if lr.get("victory", false) else "Defeat",
			int(lr.get("kills", 0)), int(lr.get("gold", 0)), int(lr.get("materials", 0))]
	_record.text = "%s\nRuns %d   ·   Victories %d   ·   Best kills %d" % [last, save["runs"], save["victories"], save["best_kills"]]


func _draw_sprite() -> void:
	var r := Rect2(Vector2.ZERO, _sprite.size)
	var ctr := r.get_center()
	_sprite.draw_set_transform(Vector2(ctr.x, r.end.y - 8), 0.0, Vector2(1.0, 0.3))
	_sprite.draw_circle(Vector2.ZERO, 40, Color(0.3, 0.6, 0.95, 0.25))
	_sprite.draw_arc(Vector2.ZERO, 40, 0, TAU, 40, Color(0.5, 0.9, 1.0, 0.6), 1.5)
	_sprite.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var tex := CharacterArt.frame_at(String(shell.save["character"]), "idle", "south", _anim_t, GameData.CHARACTER_IDLE_FPS)
	if tex != null:
		var s := Vector2(96, 96)
		_sprite.draw_texture_rect(tex, Rect2(Vector2(ctr.x - s.x * 0.5, r.end.y - 6 - s.y), s), false)


## A tiny code-drawn vignette of the Ruined Courtyard: night sky, broken arches, a purple Rift crack.
func _draw_location(c: Control) -> void:
	var r := Rect2(Vector2.ZERO, c.size)
	c.draw_rect(r, Color(0.05, 0.07, 0.16))
	c.draw_rect(Rect2(r.position.x, r.end.y - 18, r.size.x, 18), Color(0.12, 0.2, 0.16))
	var stone := Color(0.32, 0.34, 0.42)
	for x in [0.15, 0.4, 0.75]:
		var px: float = r.size.x * x
		c.draw_rect(Rect2(px - 10, r.end.y - 50, 6, 34), stone)
		c.draw_rect(Rect2(px + 6, r.end.y - 44, 6, 28), stone)
		c.draw_arc(Vector2(px + 1, r.end.y - 50), 9, PI, TAU, 10, stone, 4.0)
	var crack := PackedVector2Array([Vector2(r.size.x * 0.58, 6), Vector2(r.size.x * 0.55, 22), Vector2(r.size.x * 0.61, 34), Vector2(r.size.x * 0.57, 52)])
	c.draw_polyline(crack, Color(0.85, 0.5, 1.0), 3.0)
	c.draw_polyline(crack, Color(1.0, 0.9, 1.0), 1.0)
	c.draw_rect(r, Color(UiKit.GOLD, 0.6), false, 1.0)


func on_reset() -> void:
	pass
