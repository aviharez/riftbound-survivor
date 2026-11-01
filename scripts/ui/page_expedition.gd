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


const BANNER := "res://assets/ui/banner_expedition.png"


func _init(s) -> void:
	shell = s
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 6)
	add_child(row)

	# left: banner + mission cards
	var lp := UiKit.panel(6.0)
	lp[0].custom_minimum_size = Vector2(250, 0)
	row.add_child(lp[0])
	var left: VBoxContainer = lp[1]
	left.add_theme_constant_override("separation", 4)
	left.add_child(UiKit.banner(BANNER, 238, 64))
	for m in GameData.EXPEDITIONS:
		var rb := UiKit.rich_button(Vector2(0, 44), _pick_mission.bind(m["id"]), "normal")
		var content: HBoxContainer = rb[1]
		content.alignment = BoxContainer.ALIGNMENT_BEGIN
		content.offset_left = 8
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 1)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(col)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 8)
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(top)
		top.add_child(UiKit.title(m["name"], 12, UiKit.IVORY))
		top.add_child(UiKit.chip("bell", "%dh" % int(m["hours"]), UiKit.CYAN))
		col.add_child(reward_chips(SaveData.expedition_rewards(m["id"], 1)))
		left.add_child(rb[0])
		_mission_cards[m["id"]] = rb[0]

	# right: who goes, who is out, start
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	row.add_child(right)
	var tp := UiKit.panel(6.0)
	right.add_child(tp[0])
	tp[1].add_child(UiKit.header("WHO GOES", 12, "characters"))
	_team = HFlowContainer.new()
	_team.add_theme_constant_override("h_separation", 4)
	_team.add_theme_constant_override("v_separation", 4)
	tp[1].add_child(_team)
	var ap := UiKit.panel(6.0)
	ap[0].size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(ap[0])
	ap[1].add_child(UiKit.header("ON EXPEDITION", 12, "expedition"))
	_active = VBoxContainer.new()
	_active.add_theme_constant_override("separation", 3)
	ap[1].add_child(_active)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	right.add_child(bottom)
	var info_box := VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_child(info_box)
	_info = UiKit.label("", 10, Color("d8d2ee"))
	info_box.add_child(_info)
	_last = UiKit.label("", 10, UiKit.GREEN)
	_last.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_last.custom_minimum_size = Vector2(180, 0)
	info_box.add_child(_last)
	_start = UiKit.button("START", Vector2(130, 40), _on_start, "primary")
	_start.add_theme_font_size_override("font_size", UiKit.tfs(20))
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
		var b := UiKit.button("Lv %d" % SaveData.char_level(save, id), Vector2(44, 48), _pick_char.bind(id))
		b.icon = CharacterArt.portrait(id)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
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
		var l := UiKit.label("Restore the Dormitory to send expeditions.", 10, UiKit.RED)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_active.add_child(l)
	elif save["expeditions"].is_empty():
		_active.add_child(UiKit.label("Nobody is out.", 10, Color(UiKit.IVORY, 0.6)))
	for i in save["expeditions"].size():
		var e: Dictionary = save["expeditions"][i]
		var left := int(e["end"]) - now
		var pb := UiKit.well(3.0)
		_active.add_child(pb[0])
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 5)
		pb[1].add_child(r)
		var face := UiKit.portrait(func(): return e["char"], 30.0)
		r.add_child(face)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 1)
		r.add_child(col)
		var m := GameData.expedition_by_id(e["mission"])
		col.add_child(UiKit.label("%s · %s" % [GameData.character_by_id(e["char"])["name"], m["name"]], 10, UiKit.IVORY))
		var total := float(m["hours"]) * 3600.0
		var tr := HBoxContainer.new()
		tr.add_theme_constant_override("separation", 4)
		col.add_child(tr)
		var bar := UiKit.bar(clampf(1.0 - left / total, 0.0, 1.0), 90.0, UiKit.GREEN if left <= 0 else UiKit.CYAN)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tr.add_child(bar)
		tr.add_child(UiKit.label("Done!" if left <= 0 else time_text(left), 10, UiKit.GREEN if left <= 0 else UiKit.CYAN))
		if left <= 0:
			var cb := UiKit.button("CLAIM", Vector2(60, 26), _on_collect.bind(i), "accent")
			cb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			r.add_child(cb)
		else:
			var ab := UiKit.button("AD", Vector2(36, 26), _on_speed.bind(i), "info")
			ab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			ab.tooltip_text = "Watch an ad: -%s (%d left today)" % [time_text(mini(left, SaveData.ad_speedup(left))), SaveData.ads_left(save, SaveData.today())]
			ab.disabled = SaveData.ads_left(save, SaveData.today()) <= 0
			r.add_child(ab)
			var rb := UiKit.button("SURE?" if _armed_recall == i else "RECALL", Vector2(60, 26), _on_recall.bind(i), "danger")
			rb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			rb.tooltip_text = "Come back now, no reward"
			r.add_child(rb)
	var lv := SaveData.char_level(save, _pick) if _pick != "" else 1
	_info.text = "%s · slots %d / %d" % [GameData.expedition_by_id(_mission)["name"], save["expeditions"].size(), slots]
	_info.tooltip_text = rewards_text(SaveData.expedition_rewards(_mission, lv))
	_start.disabled = _pick == "" or save["expeditions"].size() >= slots
	_start.text = "START" if _pick != "" else "PICK"


static func time_text(sec: int) -> String:
	var h := sec / 3600
	var m := (sec % 3600) / 60
	var s := sec % 60
	return "%dh %02dm" % [h, m] if h > 0 else "%dm %02ds" % [m, s]


## Reward icons with amounts (items show as a chest).
static func reward_chips(r: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k in r:
		if k == "char":
			continue
		if k == "items":
			var n: int = r[k] if r[k] is int else r[k].size()
			if n > 0:
				row.add_child(UiKit.chip("chest", str(n)))
		else:
			row.add_child(UiKit.chip(k, str(int(r[k]))))
	return row


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


func _on_speed(i: int) -> void:
	shell.watch_ad("expedition_speedup", func(): SaveData.speed_up_expedition(shell.save, i, _now()))


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
