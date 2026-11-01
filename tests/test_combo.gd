extends SceneTree
## Evolution combo hints on level-up cards (GameData.combo_hint): plain while neither half is owned,
## a COMBO line once the other half is owned. Prints "combo tests: PASS" or the failures.

var _fails := 0


func _check(name: String, got: String, want_combo: bool, must_contain := "") -> void:
	var ok := (got != "") == want_combo and (must_contain == "" or got.contains(must_contain))
	if not ok:
		_fails += 1
		print("FAIL %s: got '%s'" % [name, got])


func _init() -> void:
	var none := {}
	# neither half owned: both cards plain
	_check("weapon plain", GameData.combo_hint("weapon", "flame", none, none), false)
	_check("tome plain", GameData.combo_hint("tome", "ricochet", none, none), false)
	# weapon owned, its tome offered as NEW -> hint names the weapon and the evolution
	_check("tome after weapon", GameData.combo_hint("tome", "ricochet", {"flame": 3}, none), true, "Flame Orb")
	_check("tome evo name", GameData.combo_hint("tome", "ricochet", {"flame": 3}, none), true, "Solar Cataclysm")
	# tome owned, weapon offered (new or level-up) -> hint names the tome
	_check("weapon after tome", GameData.combo_hint("weapon", "flame", none, {"ricochet": 1}), true, "Tome of Ricochet")
	_check("weapon levelup after tome", GameData.combo_hint("weapon", "flame", {"flame": 5}, {"ricochet": 2}), true)
	# unrelated pairs stay plain
	_check("wrong tome", GameData.combo_hint("tome", "power", {"flame": 3}, none), false)
	_check("wrong weapon", GameData.combo_hint("weapon", "bolt", none, {"ricochet": 1}), false)
	# tome already owned (leveling it up): requirement already met, no repeat
	_check("owned tome levelup", GameData.combo_hint("tome", "ricochet", {"flame": 3}, {"ricochet": 1}), false)
	# already evolved: no hint for the tome
	_check("after evolution", GameData.combo_hint("tome", "ricochet", {"solar": 8}, none), false)
	# weapons without an evolution never hint
	_check("no evolution", GameData.combo_hint("weapon", "hex", none, {"power": 1}), false)
	_check("alpha evolution", GameData.combo_hint("weapon", "slash", none, {"power": 1}), true)
	print("combo tests: PASS" if _fails == 0 else "combo tests: %d FAIL" % _fails)
	quit(1 if _fails > 0 else 0)
