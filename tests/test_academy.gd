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

	# --- characters: locked until their building is restored
	d = SaveData.reset()
	check(SaveData.character_unlocked(d, "astra") and SaveData.character_unlocked(d, "nym"), "starters unlocked")
	check(not SaveData.character_unlocked(d, "selene"), "selene locked at start")
	check(not SaveData.character_unlocked(d, "noah"), "noah locked at start")
	SaveData.bank_run(d, {"gold": 5000, "materials": 1000, "aether": 100, "exp": 5000}, {"victory": true, "kills": 10})
	check(SaveData.upgrade(d, "frost_tower"), "frost tower restored")
	check(not SaveData.upgrade(d, "frost_tower"), "frost tower has one level")
	check(SaveData.character_unlocked(d, "selene"), "frost tower unlocks selene")
	check(not SaveData.character_unlocked(d, "noah"), "noah still locked")
	check(SaveData.slots_for(d, "tome") == 2 and SaveData.slots_for(d, "weapon") == 2, "character buildings add no slots")

	# --- Staff Room lessons
	check(SaveData.lesson_cap(d) == 0 and not SaveData.buy_lesson(d, "might"), "no lessons while the staff room is in ruins")
	check(SaveData.upgrade(d, "staff_room"), "staff room Lv1")
	check(SaveData.lesson_cap(d) == GameData.LESSON_RANKS_PER_LEVEL, "staff room Lv1 -> rank cap")
	var exp0: int = d["exp"]
	check(SaveData.buy_lesson(d, "might"), "buy might rank 1")
	check(d["exp"] == exp0 - int(GameData.lesson_cost(1)["exp"]), "lesson cost paid in exp")
	for i in GameData.LESSON_RANKS_PER_LEVEL - 1:
		SaveData.buy_lesson(d, "might")
	check(SaveData.lesson_rank(d, "might") == GameData.LESSON_RANKS_PER_LEVEL, "might reaches the cap")
	check(not SaveData.buy_lesson(d, "might"), "cannot pass the rank cap")
	check(not SaveData.buy_lesson(d, "nonsense"), "unknown lesson refused")
	var mods := SaveData.lesson_mods(d)
	check(mods.size() == 1 and mods[0][0] == "damage_pct" and absf(mods[0][1] - 0.04 * GameData.LESSON_RANKS_PER_LEVEL) < 0.001, "lesson mods (%s)" % [mods])
	check(GameData.lesson_cost(2)["exp"] > GameData.lesson_cost(1)["exp"], "lesson cost grows")
	d["character"] = "selene"
	SaveData.save_data(d)
	loaded = SaveData.load_data()
	check(loaded["lessons"]["might"] == GameData.LESSON_RANKS_PER_LEVEL and typeof(loaded["lessons"]["might"]) == TYPE_INT, "lessons survive save/load as int")
	check(loaded["character"] == "selene", "unlocked character stays selected")

	# --- migration: a version 1 save (no lessons, only the two old buildings) loads cleanly
	var f := FileAccess.open(SaveData.path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "gold": 123.0, "materials": 4.0, "aether": 0.0, "exp": 9.0,
		"buildings": {"library": 1.0, "training": 0.0}, "runs": 3.0, "victories": 1.0, "best_kills": 50.0,
		"last_run": {}, "character": "noah"}))
	f.close()
	loaded = SaveData.load_data()
	check(loaded["version"] == SaveData.VERSION, "v1 save migrated to current version")
	check(loaded["gold"] == 123 and loaded["buildings"]["library"] == 1, "v1 values kept")
	check(loaded["lessons"] is Dictionary and loaded["lessons"].is_empty(), "v1 save gets empty lessons")
	check(loaded["buildings"].has("frost_tower") and loaded["buildings"]["frost_tower"] == 0, "new buildings start in ruins")
	check(loaded["character"] == "astra", "locked character in an old save falls back to astra")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.path))
	print("academy tests: ", "PASS" if failures == 0 else "%d FAILED" % failures)
	quit(1 if failures > 0 else 0)
