extends SceneTree
## Academy save / upgrade / slot rules. Uses its own save file, never the player's.

var failures := 0


func check(cond: bool, what: String) -> void:
	if not cond:
		failures += 1
		print("FAIL: ", what)


func _init() -> void:
	SaveData.path = "user://test_academy_save.json"
	var d := SaveData.reset()
	check(SaveData.slots_for(d, "tome") == 2, "base tome slots = 2")
	check(SaveData.slots_for(d, "weapon") == 2, "base weapon slots = 2")
	check(not SaveData.upgrade(d, "library"), "cannot upgrade with no resources")
	check(SaveData.building_level(d, "library") == 0, "failed upgrade changes nothing")

	SaveData.bank_run(d, {"gold": 5000, "materials": 1000, "aether": 100, "exp": 50}, {"victory": true, "kills": 900})
	check(d["runs"] == 1 and d["victories"] == 1 and d["best_kills"] == 900, "run is banked")
	check(SaveData.upgrade(d, "library"), "library Lv1")
	check(SaveData.upgrade(d, "library"), "library Lv2")
	check(not SaveData.upgrade(d, "library"), "library is capped at Lv2")
	check(SaveData.slots_for(d, "tome") == 4, "library Lv2 -> 4 tome slots")
	check(SaveData.upgrade(d, "training"), "training Lv1")
	check(SaveData.slots_for(d, "weapon") == 3, "training Lv1 -> 3 weapon slots")
	var spent: int = 400 + 1200 + 350
	check(d["gold"] == 5000 - spent, "gold spent correctly (%d)" % d["gold"])
	check(d["aether"] == 80, "aether spent correctly (%d)" % d["aether"])

	SaveData.save_data(d)
	var loaded := SaveData.load_data()
	check(loaded["buildings"]["library"] == 2 and loaded["buildings"]["training"] == 1, "levels survive save/load")
	check(loaded["gold"] == d["gold"] and typeof(loaded["gold"]) == TYPE_INT, "gold survives save/load as int")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.path))
	print("academy tests: ", "PASS" if failures == 0 else "%d FAILED" % failures)
	quit(1 if failures > 0 else 0)
