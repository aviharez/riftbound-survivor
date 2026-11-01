class_name DormPanel
extends RefCounted
## Academy overlay for the Dormitory: rooms (who lives here; a daily talk raises bond) and expeditions
## (send characters out for real hours; rewards are collected when they are back).

var save: Dictionary
var on_change: Callable
var root: Control
var _header: Label
var _tabs := {}
var _tab := "rooms"
var _rooms_list: VBoxContainer
var _exp_active: VBoxContainer
var _mission_buttons := {}
var _mission := "scout"
var _mission_info: Label
var _char_row: HFlowContainer
var _last: Label
var _armed_recall := -1


func _init(parent: Control, change_cb: Callable) -> void:
	on_change = change_cb
	var o := UiKit.overlay(parent, 580)
	root = o[0]
	var box: VBoxContainer = o[1]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	box.add_child(head)
	_header = UiKit.label("", 10, UiKit.GOLD)
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_header)
	for t in [["rooms", "Rooms"], ["exp", "Expeditions"]]:
		var b := UiKit.button(t[1], Vector2(84, 22), _show_tab.bind(t[0]))
		head.add_child(b)
		_tabs[t[0]] = {"button": b}
	head.add_child(UiKit.button("Close", Vector2(56, 22), close))

	var rooms := VBoxContainer.new()
	box.add_child(rooms)
	_tabs["rooms"]["box"] = rooms
	rooms.add_child(UiKit.label("Residents can be talked to once a day (+%d bond). Bond also grows from runs and expeditions." % GameData.BOND_TALK, 8, Color(UiKit.IVORY, 0.75)))
	_rooms_list = _scroll(rooms, 230)

	var ex := VBoxContainer.new()
	ex.add_theme_constant_override("separation", 4)
	box.add_child(ex)
	_tabs["exp"]["box"] = ex
	ex.add_child(UiKit.label("ON EXPEDITION  (time passes while the game is closed)", 8, UiKit.CYAN))
	_exp_active = _scroll(ex, 70)
	ex.add_child(UiKit.label("SEND SOMEONE OUT", 8, UiKit.CYAN))
	var mr := HBoxContainer.new()
	mr.add_theme_constant_override("separation", 4)
	ex.add_child(mr)
	for m in GameData.EXPEDITIONS:
		var b := UiKit.button("%s\n%dh" % [m["name"], int(m["hours"])], Vector2(128, 28), _pick_mission.bind(m["id"]))
		b.add_theme_font_size_override("font_size", 8)
		mr.add_child(b)
		_mission_buttons[m["id"]] = b
	_mission_info = UiKit.label("", 8, UiKit.IVORY)
	ex.add_child(_mission_info)
	_char_row = HFlowContainer.new()
	_char_row.add_theme_constant_override("h_separation", 4)
	_char_row.add_theme_constant_override("v_separation", 4)
	ex.add_child(_char_row)
	_last = UiKit.label("", 8, UiKit.CYAN)
	_last.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_last)
	# the expedition timers count down while the panel is open
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(func():
		if root.visible and _tab == "exp":
			_refresh_expeditions())
	root.add_child(timer)


func _scroll(parent: Control, h: float) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, h)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 3)
	sc.add_child(list)
	return list


func open(d: Dictionary, tab := "rooms") -> void:
	save = d
	_last.text = ""
	_armed_recall = -1
	root.visible = true
	_show_tab(tab)


func close() -> void:
	root.visible = false


func is_open() -> bool:
	return root.visible


func _show_tab(t: String) -> void:
	_tab = t
	for k in _tabs:
		_tabs[k]["box"].visible = k == t
		_tabs[k]["button"].add_theme_stylebox_override("normal", UiKit.style(UiKit.CYAN if k == t else UiKit.GOLD))
	refresh()


func _now() -> int:
	return int(Time.get_unix_time_from_system())


func refresh() -> void:
	_header.text = "DORMITORY  Lv %d   ·   Rooms %d / %d   ·   Expedition slots %d / %d" % [
		SaveData.building_level(save, "dormitory"), save["dorm"].size(), SaveData.dorm_rooms(save),
		save["expeditions"].size(), SaveData.expedition_slots(save)]
	_refresh_rooms()
	_refresh_expeditions()


func _refresh_rooms() -> void:
	for ch in _rooms_list.get_children():
		ch.queue_free()
	var day := SaveData.today()
	for c in GameData.CHARACTERS:
		var id: String = c["id"]
		if not SaveData.character_unlocked(save, id):
			continue
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 6)
		_rooms_list.add_child(r)
		var icon := TextureRect.new()
		icon.texture = CharacterArt.portrait(id)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(26, 26)
		r.add_child(icon)
		var resident: bool = id in save["dorm"]
		var away := SaveData.is_away(save, id)
		var blv := SaveData.bond_level(save, id)
		var lab := UiKit.label("%s   Bond Lv %d%s%s" % [c["name"], blv, "   (living here)" if resident else "",
			"   (on expedition)" if away else ""], 8, UiKit.IVORY if resident else Color(UiKit.IVORY, 0.7))
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(lab)
		if resident:
			var talk := UiKit.button("Talk (+%d bond)" % GameData.BOND_TALK, Vector2(96, 22), _on_talk.bind(id))
			talk.disabled = not SaveData.can_talk(save, id, day)
			if resident and not away and String(save["talked"].get(id, "")) == day:
				talk.text = "Talked today"
			r.add_child(talk)
			r.add_child(UiKit.button("Move out", Vector2(66, 22), _on_move_out.bind(id)))
		else:
			var mi := UiKit.button("Move in", Vector2(66, 22), _on_move_in.bind(id))
			mi.disabled = save["dorm"].size() >= SaveData.dorm_rooms(save)
			r.add_child(mi)


func _refresh_expeditions() -> void:
	for ch in _exp_active.get_children():
		ch.queue_free()
	var now := _now()
	if save["expeditions"].is_empty():
		_exp_active.add_child(UiKit.label("Nobody is out.", 8, Color(UiKit.IVORY, 0.6)))
	for i in save["expeditions"].size():
		var e: Dictionary = save["expeditions"][i]
		var m := GameData.expedition_by_id(e["mission"])
		var left := int(e["end"]) - now
		var r := HBoxContainer.new()
		_exp_active.add_child(r)
		var lab := UiKit.label("%s  ·  %s  ·  %s" % [GameData.character_by_id(e["char"])["name"], m["name"],
			"back!" if left <= 0 else _time_text(left) + " left"], 8, UiKit.CYAN if left <= 0 else UiKit.IVORY)
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(lab)
		if left <= 0:
			r.add_child(UiKit.button("Collect", Vector2(70, 22), _on_collect.bind(i)))
		else:
			r.add_child(UiKit.button("Sure? (no reward)" if _armed_recall == i else "Recall", Vector2(96, 22), _on_recall.bind(i)))
	for id in _mission_buttons:
		_mission_buttons[id].add_theme_stylebox_override("normal", UiKit.style(UiKit.CYAN if id == _mission else UiKit.GOLD))
	var m := GameData.expedition_by_id(_mission)
	_mission_info.text = "%s  ·  %dh  ·  Rewards (Lv 1): %s" % [m["desc"], int(m["hours"]), _rewards_text(SaveData.expedition_rewards(_mission, 1))]
	for ch in _char_row.get_children():
		ch.queue_free()
	var free_slot: bool = save["expeditions"].size() < SaveData.expedition_slots(save)
	for c in GameData.CHARACTERS:
		var id: String = c["id"]
		if not SaveData.character_unlocked(save, id) or SaveData.is_away(save, id):
			continue
		var b := UiKit.button("Send %s" % c["name"], Vector2(86, 20), _on_send.bind(id))
		b.add_theme_font_size_override("font_size", 8)
		b.disabled = not free_slot or id == String(save["character"])
		if id == String(save["character"]):
			b.text = "%s (in the Rift team)" % c["name"]
		_char_row.add_child(b)


static func _time_text(sec: int) -> String:
	var h := sec / 3600
	var m := (sec % 3600) / 60
	var s := sec % 60
	return "%dh %02dm" % [h, m] if h > 0 else "%dm %02ds" % [m, s]


static func _rewards_text(r: Dictionary) -> String:
	var parts: Array = []
	for k in r:
		if k == "items":
			parts.append("%d equipment" % int(r[k]) if r[k] is int else "%d equipment" % r[k].size())
		elif k == "essence":
			parts.append("%s %d" % [GameData.LOCATIONS[0]["essence"], int(r[k])])
		elif k != "char":
			parts.append("%s %d" % [UiKit.resource_name(k), int(r[k])])
	return ", ".join(parts)


func _pick_mission(id: String) -> void:
	_mission = id
	_refresh_expeditions()


func _on_send(id: String) -> void:
	if SaveData.start_expedition(save, id, _mission, _now()):
		_last.text = "%s left for %s." % [GameData.character_by_id(id)["name"], GameData.expedition_by_id(_mission)["name"]]
		on_change.call()
	refresh()


func _on_collect(i: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var got := SaveData.collect_expedition(save, i, _now(), rng)
	if not got.is_empty():
		var items: Array = []
		for it in got["items"]:
			items.append(GameData.item_name(it))
		_last.text = "%s is back: %s%s  (+%d bond)" % [GameData.character_by_id(got["char"])["name"], _rewards_text(got),
			(" — " + ", ".join(items)) if not items.is_empty() else "", GameData.BOND_EXPEDITION]
		on_change.call()
	refresh()


func _on_recall(i: int) -> void:
	if _armed_recall != i:
		_armed_recall = i
		_refresh_expeditions()
		return
	_armed_recall = -1
	SaveData.cancel_expedition(save, i)
	on_change.call()
	refresh()


func _on_talk(id: String) -> void:
	var before := SaveData.bond_level(save, id)
	if SaveData.talk(save, id, SaveData.today()):
		var after := SaveData.bond_level(save, id)
		var line: String = _TALK_LINES[randi() % _TALK_LINES.size()] % GameData.character_by_id(id)["name"]
		_last.text = line + ("   Bond Lv %d! A new story scene is open in the character panel." % after if after > before else "")
		on_change.call()
	refresh()


func _on_move_in(id: String) -> void:
	if SaveData.move_in(save, id):
		on_change.call()
	refresh()


func _on_move_out(id: String) -> void:
	SaveData.move_out(save, id)
	on_change.call()
	refresh()


const _TALK_LINES := [
	"You chat with %s about the day's battles.",
	"%s shows you something they found in the ruins.",
	"You share a pot of tea with %s.",
	"%s tells you a story about the academy before the Rift.",
	"You help %s tidy their room.",
]
