class_name ExpeditionPage
extends Control
## Expedition page: pick a mission (left), pick who goes (right), START EXPEDITION; the characters already out
## are listed with live timers, Collect when back, Recall (no reward) early. Slots = Dormitory level.

var shell
var _mission := "scout"
var _mission_cards := {}
var _pick := ""
var _team: HFlowContainer
var _active: VBoxContainer
var _info: Label
var _start: Button
var _last: Label
var _armed_recall := -1


func _init(s) -> void:
	shell = s
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 6)
	add_child(row)

	var lp := UiKit.panel(8.0)
	lp[0].custom_minimum_size = Vector2(230, 0)
	row.add_child(lp[0])
	var left: VBoxContainer = lp[1]
	left.add_child(UiKit.header("CHOOSE EXPEDITION", 8))
	for m in GameData.EXPEDITIONS:
		var b := UiKit.button("", Vector2(0, 44), _pick_mission.bind(m["id"]))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 8)
		b.text = "  %s\n  %dh  ·  %s" % [m["name"], int(m["hours"]), ExpeditionPage.rewards_text(SaveData.expedition_rewards(m["id"], 1))]
		left.add_child(b)
		_mission_cards[m["id"]] = b

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	row.add_child(right)
	var tp := UiKit.panel(8.0)
	right.add_child(tp[0])
	tp[1].add_child(UiKit.header("SELECT WHO GOES", 8))
	_team = HFlowContainer.new()
	_team.add_theme_constant_override("h_separation", 4)
	_team.add_theme_constant_override("v_separation", 4)
	tp[1].add_child(_team)
	var ap := UiKit.panel(8.0)
	ap[0].size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(ap[0])
	ap[1].add_child(UiKit.header("ON EXPEDITION", 8))
	_active = VBoxContainer.new()
	_active.add_theme_constant_override("separation", 3)
	ap[1].add_child(_active)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	right.add_child(bottom)
	var info_box := VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(info_box)
	_info = UiKit.label("", 7, UiKit.IVORY)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_box.add_child(_info)
	_last = UiKit.label("", 7, UiKit.CYAN)
	_last.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_box.add_child(_last)
	_start = UiKit.button("START EXPEDITION", Vector2(150, 36), _on_start, "primary")
	_start.add_theme_font_size_override("font_size", 10)
	bottom.add_child(_start)
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(func():
		if visible and not shell.save["expeditions"].is_empty():
			_refresh_active())
	add_child(timer)


func _now() -> int:
	return int(Time.get_unix_time_from_system())


func refresh() -> void:
	var save: Dictionary = shell.save
	for id in _mission_cards:
		UiKit.set_selected(_mission_cards[id], id == _mission)
	for ch in _team.get_children():
		ch.queue_free()
	if _pick != "" and (SaveData.is_away(save, _pick) or _pick == String(save["character"]) or not SaveData.character_unlocked(save, _pick)):
		_pick = ""
	for c in GameData.CHARACTERS:
		var id: String = c["id"]
		if not SaveData.character_unlocked(save, id):
			continue
		var b := UiKit.button("Lv %d" % SaveData.char_level(save, id), Vector2(44, 44), _pick_char.bind(id))
		b.icon = CharacterArt.portrait(id)
		b.expand_icon = true
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_font_size_override("font_size", 6)
		b.tooltip_text = c["name"]
		var busy := SaveData.is_away(save, id) or id == String(save["character"])
		b.disabled = busy
		if SaveData.is_away(save, id):
			b.text = "Away"
		elif id == String(save["character"]):
			b.text = "Rift"
		UiKit.set_selected(b, id == _pick)
		_team.add_child(b)
	_refresh_active()


func _refresh_active() -> void:
	var save: Dictionary = shell.save
	for ch in _active.get_children():
		ch.queue_free()
	var slots := SaveData.expedition_slots(save)
	var now := _now()
	if slots == 0:
		_active.add_child(UiKit.label("Restore the Dormitory to send expeditions (slots = Dormitory level).", 8, UiKit.RED))
	elif save["expeditions"].is_empty():
		_active.add_child(UiKit.label("Nobody is out. Slots: %d" % slots, 8, Color(UiKit.IVORY, 0.6)))
	for i in save["expeditions"].size():
		var e: Dictionary = save["expeditions"][i]
		var left := int(e["end"]) - now
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 4)
		_active.add_child(r)
		var icon := TextureRect.new()
		icon.texture = CharacterArt.portrait(e["char"])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(20, 20)
		r.add_child(icon)
		var lab := UiKit.label("%s  ·  %s  ·  %s" % [GameData.character_by_id(e["char"])["name"], GameData.expedition_by_id(e["mission"])["name"],
			"back!" if left <= 0 else time_text(left) + " left"], 8, UiKit.CYAN if left <= 0 else UiKit.IVORY)
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(lab)
		if left <= 0:
			r.add_child(UiKit.button("Collect", Vector2(60, 18), _on_collect.bind(i), "primary"))
		else:
			r.add_child(UiKit.button("Sure? No reward" if _armed_recall == i else "Recall", Vector2(86, 18), _on_recall.bind(i)))
	var m := GameData.expedition_by_id(_mission)
	var lv := SaveData.char_level(save, _pick) if _pick != "" else 1
	_info.text = "%s  ·  %dh\nRewards%s: %s  ·  slots %d / %d" % [m["desc"], int(m["hours"]),
		(" for %s (Lv %d)" % [GameData.character_by_id(_pick)["name"], lv]) if _pick != "" else "", rewards_text(SaveData.expedition_rewards(_mission, lv)),
		save["expeditions"].size(), slots]
	_start.disabled = _pick == "" or save["expeditions"].size() >= slots
	_start.text = "START EXPEDITION" if _pick != "" else "PICK SOMEONE"


static func time_text(sec: int) -> String:
	var h := sec / 3600
	var m := (sec % 3600) / 60
	var s := sec % 60
	return "%dh %02dm" % [h, m] if h > 0 else "%dm %02ds" % [m, s]


static func rewards_text(r: Dictionary) -> String:
	var parts: Array = []
	for k in r:
		if k == "items":
			var n: int = r[k] if r[k] is int else r[k].size()
			if n > 0:
				parts.append("%d equipment" % n)
		elif k == "essence":
			parts.append("Essence %d" % int(r[k]))
		elif k != "char":
			parts.append("%s %d" % [UiKit.resource_name(k), int(r[k])])
	return ", ".join(parts)


func _pick_mission(id: String) -> void:
	_mission = id
	refresh()


func _pick_char(id: String) -> void:
	_pick = id
	refresh()


func _on_start() -> void:
	if SaveData.start_expedition(shell.save, _pick, _mission, _now()):
		_last.text = "%s left for %s." % [GameData.character_by_id(_pick)["name"], GameData.expedition_by_id(_mission)["name"]]
		_pick = ""
		shell.changed()


func _on_collect(i: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var got := SaveData.collect_expedition(shell.save, i, _now(), rng)
	if not got.is_empty():
		var items: Array = []
		for it in got["items"]:
			items.append(GameData.item_name(it))
		_last.text = "%s is back: %s%s (+%d bond)" % [GameData.character_by_id(got["char"])["name"], rewards_text(got),
			(" - " + ", ".join(items)) if not items.is_empty() else "", GameData.BOND_EXPEDITION]
		shell.changed()


func _on_recall(i: int) -> void:
	if _armed_recall != i:
		_armed_recall = i
		_refresh_active()
		return
	_armed_recall = -1
	SaveData.cancel_expedition(shell.save, i)
	shell.changed()


func on_reset() -> void:
	_pick = ""
