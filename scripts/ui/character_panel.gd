class_name CharacterPanel
extends RefCounted
## Academy overlay for one character: level / character EXP and the two enhance tracks (passive trait,
## signature weapon). Later phase-2 parts add equipment and bond here.

var save: Dictionary
var char_id := ""
var on_change: Callable   # called after a purchase (the academy saves and refreshes)
var root: Control
var _header: Label
var _level: Label
var _rows := {}   # track -> {label, button}


func _init(parent: Control, change_cb: Callable) -> void:
	on_change = change_cb
	var o := UiKit.overlay(parent, 520)
	root = o[0]
	var box: VBoxContainer = o[1]
	var head := HBoxContainer.new()
	box.add_child(head)
	_header = UiKit.label("", 11, UiKit.GOLD)
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_header)
	head.add_child(UiKit.button("Close", Vector2(60, 22), close))
	_level = UiKit.label("", 8, UiKit.IVORY)
	_level.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_level)
	box.add_child(UiKit.label("ENHANCE  (gold + Arcane Shards; rank N needs character Lv %d x N)" % GameData.ENHANCE_LEVEL_STEP, 9, UiKit.CYAN))
	for track in SaveData.ENHANCE_TRACKS:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 6)
		box.add_child(r)
		var lab := UiKit.label("", 8, UiKit.IVORY)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(lab)
		var btn := UiKit.button("", Vector2(150, 30), _on_enhance.bind(track))
		r.add_child(btn)
		_rows[track] = {"label": lab, "button": btn}


func open(d: Dictionary, id: String) -> void:
	save = d
	char_id = id
	refresh()
	root.visible = true


func close() -> void:
	root.visible = false


func is_open() -> bool:
	return root.visible


func refresh() -> void:
	if char_id == "":
		return
	var c := GameData.character_by_id(char_id)
	var st := SaveData.char_state(save, char_id)
	var lv := SaveData.char_level(save, char_id)
	_header.text = "%s  ·  %s  ·  %s" % [c["name"], c["role"], c["school"]]
	var exp := int(st["exp"])
	var exp_line := "MAX LEVEL"
	if lv < GameData.CHAR_MAX_LEVEL:
		var a := GameData.char_exp_for(lv)
		var b := GameData.char_exp_for(lv + 1)
		exp_line = "EXP %d / %d to Lv %d" % [exp - a, b - a, lv + 1]
	var bonus: Array = []
	for m in GameData.char_level_mods(lv):
		if float(m[1]) > 0.0:
			bonus.append(_mod_text(m[0], float(m[1])))
	_level.text = "Level %d / %d   ·   %s\nLevel bonus: %s\nCharacter EXP comes from runs played with %s (same amount as the academy EXP).   Arcane Shards: %d" % [
		lv, GameData.CHAR_MAX_LEVEL, exp_line, ", ".join(bonus) if not bonus.is_empty() else "none yet",
		c["name"], int(save["shards"])]
	for track in SaveData.ENHANCE_TRACKS:
		var rank := int(st[track])
		var lab: Label = _rows[track]["label"]
		var btn: Button = _rows[track]["button"]
		if track == "passive":
			lab.text = "Passive · %s   Rank %d / %d\n%s\nEach rank: trait +%d%% stronger (now +%d%%)" % [c["passive"], rank, GameData.ENHANCE_MAX,
				c["passive_desc"], int(GameData.ENHANCE_TRAIT_PER_RANK * 100), int(GameData.ENHANCE_TRAIT_PER_RANK * 100 * rank)]
		else:
			var w := GameData.weapon_by_id(c["starter"])
			lab.text = "Signature weapon · %s   Rank %d / %d\nAlso applies to its evolution.\nEach rank: +%d%% damage, +%d%% attack speed (now +%d%% / +%d%%)" % [
				w["name"], rank, GameData.ENHANCE_MAX, int(GameData.ENHANCE_WEAPON_DMG * 100), int(GameData.ENHANCE_WEAPON_CD * 100),
				int(GameData.ENHANCE_WEAPON_DMG * 100 * rank), int(GameData.ENHANCE_WEAPON_CD * 100 * rank)]
		var cost := SaveData.next_enhance_cost(save, char_id, track)
		if rank >= GameData.ENHANCE_MAX:
			btn.text = "Max rank"
			btn.disabled = true
		elif cost.is_empty():
			btn.text = "Needs character Lv %d" % ((rank + 1) * GameData.ENHANCE_LEVEL_STEP)
			btn.disabled = true
		else:
			var ok := SaveData.can_afford(save, cost)
			btn.text = ("Enhance\n" if ok else "Not enough\n") + UiKit.cost_text(cost)
			btn.disabled = not ok


func _on_enhance(track: String) -> void:
	if SaveData.enhance(save, char_id, track):
		on_change.call()
	refresh()


static func _mod_text(stat: String, v: float) -> String:
	if stat.ends_with("_pct"):
		return "+%d%% %s" % [int(round(v * 100)), stat.trim_suffix("_pct").replace("_", " ")]
	if stat == "max_hp":
		return "+%d HP" % int(v)
	return "+%s %s" % [str(v), stat.replace("_", " ")]
