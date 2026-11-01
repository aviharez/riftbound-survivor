class_name LessonsPanel
extends RefCounted
## Staff Room overlay: every lesson with its teacher, effect, rank and a buy button (EXP + gold).

var save: Dictionary
var on_change: Callable
var root: Control
var _header: Label
var _rows := {}


func _init(parent: Control, change_cb: Callable) -> void:
	on_change = change_cb
	var o := UiKit.overlay(parent, 500, "LESSONS", close)
	root = o[0]
	var box: VBoxContainer = o[1]
	_header = UiKit.label("", 8, UiKit.CYAN)
	box.add_child(_header)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 240)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 3)
	sc.add_child(list)
	for l in GameData.LESSONS:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 6)
		list.add_child(r)
		var lab := UiKit.label("", 8, UiKit.IVORY)
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(lab)
		var btn := UiKit.button("", Vector2(130, 26), _on_buy.bind(l["id"]))
		r.add_child(btn)
		_rows[l["id"]] = {"label": lab, "button": btn}


func open(d: Dictionary) -> void:
	save = d
	refresh()
	root.visible = true


func close() -> void:
	root.visible = false


func is_open() -> bool:
	return root.visible


func refresh() -> void:
	var cap := SaveData.lesson_cap(save)
	_header.text = "Rank cap %d (x3 per Staff Room level)   ·   EXP %d   ·   Gold %d" % [cap, save["exp"], save["gold"]]
	for l in GameData.LESSONS:
		var row: Dictionary = _rows[l["id"]]
		var rank := SaveData.lesson_rank(save, l["id"])
		var total: float = float(l["per"]) * rank
		var pct: bool = l["stat"] in GameData.PCT_STATS
		var now := "+%d%%" % int(round(total * 100)) if pct else "+%d" % int(round(total))
		var per := "+%d%%" % int(round(float(l["per"]) * 100)) if pct else "+%d" % int(round(float(l["per"])))
		row["label"].text = "%s  (%s)\n%s %s per rank   ·   now %s   ·   rank %d / %d" % [l["name"], l["teacher"], per, l["label"], now, rank, cap]
		var cost := SaveData.next_lesson_cost(save, l["id"])
		var btn: Button = row["button"]
		if cost.is_empty():
			btn.text = "Max rank" if cap > 0 else "Locked"
			btn.disabled = true
		else:
			btn.text = "EXP %d  Gold %d" % [cost["exp"], cost["gold"]]
			btn.disabled = not SaveData.can_afford(save, cost)


func _on_buy(id: String) -> void:
	if SaveData.buy_lesson(save, id):
		on_change.call()
	refresh()
