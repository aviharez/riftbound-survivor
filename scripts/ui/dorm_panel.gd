class_name DormPanel
extends RefCounted
## Dormitory overlay: who lives here (rooms grow with the Dormitory level) and the daily talk that raises bond.
## Expeditions have their own page.

var save: Dictionary
var on_change: Callable
var root: Control
var _header: Label
var _list: GridContainer
var _last: Label

const _TALK_LINES := [
	"You chat with %s about the day's battles.",
	"%s shows you something they found in the ruins.",
	"You share a pot of tea with %s.",
	"%s tells you a story about the academy before the Rift.",
	"You help %s tidy their room.",
]


func _init(parent: Control, change_cb: Callable) -> void:
	on_change = change_cb
	var o := UiKit.overlay(parent, 540, "DORMITORY", close)
	root = o[0]
	var box: VBoxContainer = o[1]
	var hr := HBoxContainer.new()
	hr.add_theme_constant_override("separation", 6)
	box.add_child(hr)
	hr.add_child(UiKit.icon_rect("rooms", 16))
	_header = UiKit.title("", 12, UiKit.CYAN)
	hr.add_child(_header)
	var hint := UiKit.label("Talk once a day: +%d bond" % GameData.BOND_TALK, 10, Color("d8d2ee"))
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hr.add_child(hint)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 176)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(sc)
	_list = GridContainer.new()
	_list.columns = 3
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("h_separation", 4)
	_list.add_theme_constant_override("v_separation", 4)
	sc.add_child(_list)
	_last = UiKit.label("", 10, UiKit.GREEN)
	_last.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_last)


func open(d: Dictionary) -> void:
	save = d
	_last.text = ""
	refresh()
	root.visible = true


func close() -> void:
	root.visible = false


func is_open() -> bool:
	return root.visible


func refresh() -> void:
	_header.text = "Rooms %d / %d" % [save["dorm"].size(), SaveData.dorm_rooms(save)]
	for ch in _list.get_children():
		ch.queue_free()
	var day := SaveData.today()
	for c in GameData.CHARACTERS:
		var id: String = c["id"]
		if not SaveData.character_unlocked(save, id):
			continue
		var resident: bool = id in save["dorm"]
		var pb := UiKit.well(4.0) if resident else UiKit.panel(4.0, UiKit.GREY)
		pb[0].size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_list.add_child(pb[0])
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 4)
		pb[1].add_child(r)
		r.add_child(UiKit.portrait(func(): return id, 36.0, UiKit.GOLD if resident else UiKit.PURPLE))
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 1)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(col)
		col.add_child(UiKit.title(c["name"], 12, UiKit.IVORY if resident else Color(UiKit.IVORY, 0.6)))
		var info := HBoxContainer.new()
		info.add_theme_constant_override("separation", 6)
		col.add_child(info)
		info.add_child(UiKit.chip("hp", "Lv %d" % SaveData.bond_level(save, id), Color("ff9ac8")))
		if SaveData.is_away(save, id):
			info.add_child(UiKit.chip("expedition", "Away", UiKit.CYAN))
		var br := HBoxContainer.new()
		br.add_theme_constant_override("separation", 3)
		pb[1].add_child(br)
		if resident:
			var talked := String(save["talked"].get(id, "")) == day
			var talk := UiKit.button("TALKED" if talked else "TALK", Vector2(0, 22), _on_talk.bind(id), "accent")
			talk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			talk.disabled = not SaveData.can_talk(save, id, day)
			br.add_child(talk)
			var out := UiKit.button("X", Vector2(24, 22), _on_move_out.bind(id), "danger")
			out.tooltip_text = "Move out"
			br.add_child(out)
		else:
			var mi := UiKit.button("MOVE IN", Vector2(0, 22), _on_move_in.bind(id), "info")
			mi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			mi.disabled = save["dorm"].size() >= SaveData.dorm_rooms(save)
			br.add_child(mi)


func _on_talk(id: String) -> void:
	var before := SaveData.bond_level(save, id)
	if SaveData.talk(save, id, SaveData.today()):
		var after := SaveData.bond_level(save, id)
		var line: String = _TALK_LINES[randi() % _TALK_LINES.size()] % GameData.character_by_id(id)["name"]
		_last.text = line + ("   Bond Lv %d! A new story is open on the Characters page." % after if after > before else "")
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
