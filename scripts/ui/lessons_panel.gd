class_name LessonsPanel
extends RefCounted
## Staff Room overlay: every lesson with its teacher, effect, rank and a buy button (EXP + gold).

var save: Dictionary
var on_change: Callable
var root: Control
var _header: Label
var _rows := {}


const ICONS := {"might": "damage", "vigor": "hp", "haste": "haste", "stride": "speed", "fortune": "fortune",
	"wisdom": "study", "greed": "greed", "magnet": "attraction"}


func _init(parent: Control, change_cb: Callable) -> void:
	on_change = change_cb
	var o := UiKit.overlay(parent, 520, "LESSONS", close)
	root = o[0]
	var box: VBoxContainer = o[1]
	_header = UiKit.label("", 10, UiKit.CYAN)
	box.add_child(_header)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 236)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	sc.add_child(grid)
	for l in GameData.LESSONS:
		var pb := UiKit.well(4.0)
		pb[0].size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(pb[0])
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 5)
		pb[1].add_child(r)
		var sl := UiKit.slot(ICONS.get(l["id"], "lessons"), 40.0)
		sl.tooltip_text = l["teacher"]
		sl.mouse_filter = Control.MOUSE_FILTER_PASS
		r.add_child(sl)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 1)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(col)
		col.add_child(UiKit.title(l["name"], 12))
		var eff := UiKit.label("", 10, UiKit.GOLD)
		col.add_child(eff)
		var pips := HBoxContainer.new()
		col.add_child(pips)
		var rb := UiKit.rich_button(Vector2(0, 26), _on_buy.bind(l["id"]), "accent")
		pb[1].add_child(rb[0])
		_rows[l["id"]] = {"effect": eff, "pips": pips, "button": rb[0], "content": rb[1]}


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
	_header.text = "Rank cap %d · +%d per Staff Room level" % [cap, GameData.LESSON_RANKS_PER_LEVEL]
	for l in GameData.LESSONS:
		var row: Dictionary = _rows[l["id"]]
		var rank := SaveData.lesson_rank(save, l["id"])
		var total: float = float(l["per"]) * rank
		var pct: bool = l["stat"] in GameData.PCT_STATS
		var now := "+%d%%" % int(round(total * 100)) if pct else "+%d" % int(round(total))
		row["effect"].text = "%s %s" % [now, l["label"]]
		for ch in row["pips"].get_children():
			ch.queue_free()
		row["pips"].add_child(UiKit.pips(rank, maxi(cap, 1), UiKit.GOLD))
		var cost := SaveData.next_lesson_cost(save, l["id"])
		var btn: Button = row["button"]
		var content: HBoxContainer = row["content"]
		for ch in content.get_children():
			ch.queue_free()
		if cost.is_empty():
			content.add_child(UiKit.title("MAX" if cap > 0 else "LOCKED", 12, UiKit.IVORY))
			btn.disabled = true
		else:
			content.add_child(UiKit.title("LEARN", 12, UiKit.IVORY))
			content.add_child(UiKit.cost_chips(cost, save))
			btn.disabled = not SaveData.can_afford(save, cost)


func _on_buy(id: String) -> void:
	if SaveData.buy_lesson(save, id):
		on_change.call()
	refresh()
