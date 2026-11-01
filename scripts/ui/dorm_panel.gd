class_name DormPanel
extends RefCounted
## Dormitory overlay: who lives here (rooms grow with the Dormitory level) and the daily talk that raises bond.
## Expeditions have their own page.

var save: Dictionary
var on_change: Callable
var root: Control
var _header: Label
var _list: VBoxContainer
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
	_header = UiKit.label("", 8, UiKit.CYAN)
	box.add_child(_header)
	box.add_child(UiKit.label("Residents can be talked to once a day (+%d bond). Bond also grows from runs and expeditions." % GameData.BOND_TALK,
		8, Color(UiKit.IVORY, 0.75)))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 200)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(sc)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 3)
	sc.add_child(_list)
	_last = UiKit.label("", 8, UiKit.CYAN)
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
	_header.text = "Lv %d   ·   Rooms %d / %d" % [SaveData.building_level(save, "dormitory"), save["dorm"].size(), SaveData.dorm_rooms(save)]
	for ch in _list.get_children():
		ch.queue_free()
	var day := SaveData.today()
	for c in GameData.CHARACTERS:
		var id: String = c["id"]
		if not SaveData.character_unlocked(save, id):
			continue
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 6)
		_list.add_child(r)
		var icon := TextureRect.new()
		icon.texture = CharacterArt.portrait(id)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(26, 26)
		r.add_child(icon)
		var resident: bool = id in save["dorm"]
		var away := SaveData.is_away(save, id)
		var lab := UiKit.label("%s   Bond Lv %d%s%s" % [c["name"], SaveData.bond_level(save, id), "   (living here)" if resident else "",
			"   (on expedition)" if away else ""], 8, UiKit.IVORY if resident else Color(UiKit.IVORY, 0.7))
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(lab)
		if resident:
			var talk := UiKit.button("Talk (+%d bond)" % GameData.BOND_TALK, Vector2(96, 22), _on_talk.bind(id), "accent")
			talk.disabled = not SaveData.can_talk(save, id, day)
			if String(save["talked"].get(id, "")) == day:
				talk.text = "Talked today"
			r.add_child(talk)
			r.add_child(UiKit.button("Move out", Vector2(66, 22), _on_move_out.bind(id)))
		else:
			var mi := UiKit.button("Move in", Vector2(66, 22), _on_move_in.bind(id))
			mi.disabled = save["dorm"].size() >= SaveData.dorm_rooms(save)
			r.add_child(mi)


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
