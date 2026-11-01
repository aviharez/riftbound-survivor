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
	# every locked character's building exists; Wren needs the Library at its max level
	for c in GameData.CHARACTERS:
		if c["unlock"] != "":
			check(GameData.BUILDINGS.any(func(b): return b["id"] == c["unlock"]), "%s has a home building" % c["id"])
	check(not SaveData.character_unlocked(d, "wren"), "wren locked at start")
	check(SaveData.upgrade(d, "library") and not SaveData.character_unlocked(d, "wren"), "library Lv1 does not bring wren")
	check(SaveData.upgrade(d, "library") and SaveData.character_unlocked(d, "wren"), "library at max brings wren")

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

	check(loaded["shards"] == 0 and loaded["characters"] is Dictionary and loaded["characters"].is_empty(), "v1 save gets shards / characters")

	# --- migration: a version 2 save (lessons, no shards / characters)
	f = FileAccess.open(SaveData.path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 2, "gold": 10.0, "materials": 0.0, "aether": 0.0, "exp": 0.0,
		"buildings": {}, "runs": 0.0, "victories": 0.0, "best_kills": 0.0, "last_run": {}, "character": "astra",
		"lessons": {"might": 2.0}}))
	f.close()
	loaded = SaveData.load_data()
	check(loaded["lessons"]["might"] == 2 and loaded["shards"] == 0 and loaded["characters"].is_empty(), "v2 save migrated")

	# --- character level + enhance
	d = SaveData.reset()
	check(GameData.char_exp_for(1) == 0 and GameData.char_exp_for(2) == int(GameData.CHAR_EXP_FIRST), "level EXP curve starts at CHAR_EXP_FIRST")
	check(GameData.char_level_for(GameData.char_exp_for(7)) == 7 and GameData.char_level_for(GameData.char_exp_for(7) - 1) == 6, "level from EXP")
	check(SaveData.char_level(d, "astra") == 1 and SaveData.enhance_cap(d, "astra") == 0, "new character Lv 1, no enhance")
	check(not SaveData.enhance(d, "astra", "passive"), "no enhance below Lv %d" % GameData.ENHANCE_LEVEL_STEP)
	SaveData.bank_run(d, {"gold": 3000, "shards": 20, "char_exp": GameData.char_exp_for(10)}, {"victory": true, "kills": 1, "character": "astra"})
	check(SaveData.char_level(d, "astra") == 10 and SaveData.char_level(d, "lyra") == 1, "run EXP goes to the played character only")
	check(d["shards"] == 20, "shards banked")
	check(SaveData.enhance_cap(d, "astra") == 2, "Lv 10 -> enhance cap 2")
	check(SaveData.enhance(d, "astra", "passive") and SaveData.enhance(d, "astra", "passive"), "two passive ranks")
	check(not SaveData.enhance(d, "astra", "passive"), "passive capped by level")
	check(SaveData.enhance(d, "astra", "weapon"), "weapon rank 1")
	check(not SaveData.enhance(d, "astra", "nonsense"), "unknown track refused")
	var paid: int = GameData.ENHANCE_COST_SHARDS[0] * 2 + GameData.ENHANCE_COST_SHARDS[1]
	check(d["shards"] == 20 - paid, "shards spent (%d)" % d["shards"])
	var bonus := SaveData.char_run_bonus(d, "astra")
	check(bonus["level"] == 10 and bonus["passive"] == 2 and bonus["weapon"] == 1, "run bonus (%s)" % [bonus])
	SaveData.add_char_exp(d, "astra", 10000000)
	check(SaveData.char_level(d, "astra") == GameData.CHAR_MAX_LEVEL, "level capped")
	SaveData.save_data(d)
	loaded = SaveData.load_data()
	check(loaded["characters"]["astra"]["passive"] == 2 and typeof(loaded["characters"]["astra"]["exp"]) == TYPE_INT, "character progress survives save/load")

	# --- equipment + crafting
	d = SaveData.reset()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var epic := GameData.roll_item(rng, 3, "focus")
	check(epic["base"] == "focus" and epic["rarity"] == 3 and epic["subs"].size() == GameData.RARITY_SUBSTATS[3], "epic focus has 2 substats")
	var subs_ok := true
	for sub in epic["subs"]:
		subs_ok = subs_ok and sub[0] != "crit"
	check(subs_ok, "substats never repeat the main stat")
	var main_mod: Array = GameData.item_mods(epic)[0]
	check(main_mod[0] == "crit" and absf(main_mod[1] - 0.03 * GameData.RARITY_MAIN_MULT[3]) < 0.0001, "main stat x rarity (%s)" % [main_mod])
	var uid := SaveData.add_item(d, epic)
	var uid2 := SaveData.add_item(d, GameData.roll_item(rng, 0, "robe"))
	check(uid != uid2 and d["items"].size() == 2, "items get unique uids")
	check(SaveData.equip(d, "astra", uid) and SaveData.equipped_item(d, "astra", "weapon")["uid"] == uid, "astra wears the focus")
	check(SaveData.equip(d, "lyra", uid) and SaveData.equipped_item(d, "astra", "weapon").is_empty() and SaveData.owner_of(d, uid) == "lyra", "equipping on lyra takes it off astra")
	check(not SaveData.equip(d, "lyra", 999), "unknown piece refused")
	var lyra_mods: Array = SaveData.char_run_bonus(d, "lyra")["mods"]
	var has_crit := false
	for m in lyra_mods:
		has_crit = has_crit or m[0] == "crit"
	check(has_crit, "equipment mods reach the run bonus")
	check(SaveData.craft_rarity_cap(d) == -1 and not SaveData.can_craft(d, 0, "courtyard"), "no crafting while the workshop is in ruins")
	d["gold"] = 10000
	d["materials"] = 5000
	d["aether"] = 500
	d["essence"]["courtyard"] = 30
	check(SaveData.upgrade(d, "workshop") and SaveData.craft_rarity_cap(d) == 1, "workshop Lv1 crafts up to uncommon")
	check(SaveData.craft(d, "wand", 2, "courtyard", rng).is_empty(), "cannot craft above the cap")
	var crafted := SaveData.craft(d, "wand", 1, "courtyard", rng)
	check(not crafted.is_empty() and crafted["base"] == "wand" and crafted["rarity"] == 1, "crafted an uncommon wand")
	check(d["essence"]["courtyard"] == 30 - GameData.CRAFT_COST[1]["essence"], "craft spends essence")
	var mats: int = d["materials"]
	check(SaveData.salvage(d, uid, "courtyard") and SaveData.item_by_uid(d, uid).is_empty() and SaveData.equipped_item(d, "lyra", "weapon").is_empty(), "salvage removes an equipped piece")
	check(d["materials"] == mats + int(round(GameData.CRAFT_COST[3]["materials"] * GameData.SALVAGE_SHARE)), "salvage refunds materials")
	SaveData.bank_run(d, {"essence": {"courtyard": 4}, "items": [GameData.roll_item(rng, 4)]}, {"victory": false, "kills": 0})
	check(d["items"].size() == 3 and d["essence"]["courtyard"] > 4, "run drops and essence are banked")
	SaveData.equip(d, "nym", uid2)
	SaveData.save_data(d)
	loaded = SaveData.load_data()
	check(loaded["items"].size() == 3 and typeof(loaded["items"][0]["uid"]) == TYPE_INT and SaveData.equipped_item(loaded, "nym", "armor")["uid"] == uid2, "equipment survives save/load")
	check(int(loaded["next_uid"]) > uid2, "next uid survives")
	for i in GameData.INVENTORY_CAP:
		SaveData.add_item(loaded, GameData.roll_item(rng, 0))
	check(loaded["items"].size() == GameData.INVENTORY_CAP and SaveData.add_item(loaded, GameData.roll_item(rng, 0)) == -1, "inventory cap")

	# --- bond, dormitory, expeditions
	d = SaveData.reset()
	check(GameData.bond_level_for(0) == 0 and GameData.bond_level_for(GameData.BOND_EXP[2]) == 2, "bond levels")
	for c in GameData.CHARACTERS:
		for lv in range(1, GameData.BOND_MAX + 1):
			check(BondScenes.scene(c["id"], lv).size() == 2, "%s has bond scene %d" % [c["id"], lv])
	SaveData.bank_run(d, {"char_exp": 10}, {"victory": true, "kills": 1, "character": "nym"})
	check(int(SaveData.char_state(d, "nym")["bond"]) == GameData.BOND_RUN + GameData.BOND_VICTORY, "a run gives bond")
	check(SaveData.dorm_rooms(d) == 0 and not SaveData.move_in(d, "astra"), "no rooms while the dormitory is in ruins")
	check(SaveData.expedition_slots(d) == 0 and not SaveData.start_expedition(d, "lyra", "scout", 1000), "no expeditions without a dormitory")
	d["gold"] = 10000
	d["materials"] = 5000
	d["aether"] = 500
	check(SaveData.upgrade(d, "dormitory"), "dormitory Lv1")
	check(SaveData.move_in(d, "astra") and not SaveData.move_in(d, "astra"), "move in once")
	check(not SaveData.move_in(d, "selene"), "locked character cannot move in")
	check(SaveData.talk(d, "astra", "2026-11-01") and not SaveData.talk(d, "astra", "2026-11-01"), "one talk per day")
	check(SaveData.talk(d, "astra", "2026-11-02"), "talk again the next day")
	check(int(SaveData.char_state(d, "astra")["bond"]) == GameData.BOND_TALK * 2, "talks give bond")
	check(not SaveData.talk(d, "lyra", "2026-11-02"), "non-residents cannot be talked to")
	d["character"] = "astra"
	check(not SaveData.start_expedition(d, "astra", "scout", 1000), "the Rift character cannot leave")
	check(not SaveData.start_expedition(d, "lyra", "nonsense", 1000), "unknown mission refused")
	check(SaveData.start_expedition(d, "lyra", "relics", 1000), "lyra leaves")
	check(SaveData.is_away(d, "lyra") and not SaveData.start_expedition(d, "kael", "scout", 1000), "one slot at dormitory Lv1")
	var r2 := RandomNumberGenerator.new()
	r2.seed = 5
	check(SaveData.collect_expedition(d, 0, 1000 + 3600, r2).is_empty(), "cannot collect early")
	var gold0: int = d["gold"]
	var got := SaveData.collect_expedition(d, 0, 1000 + 8 * 3600, r2)
	check(not got.is_empty() and got["char"] == "lyra" and got["items"].size() == 1, "relic hunt brings a piece")
	check(d["gold"] == gold0 + int(GameData.EXPEDITIONS[3]["rewards"]["gold"]) and not SaveData.is_away(d, "lyra"), "expedition rewards paid, lyra is back")
	check(int(SaveData.char_state(d, "lyra")["bond"]) == GameData.BOND_EXPEDITION, "expedition gives bond")
	check(SaveData.expedition_rewards("scout", 11)["gold"] > SaveData.expedition_rewards("scout", 1)["gold"], "higher level, better rewards")
	SaveData.start_expedition(d, "kael", "herbs", 5000)
	SaveData.cancel_expedition(d, 0)
	check(not SaveData.is_away(d, "kael") and d["expeditions"].is_empty(), "recall frees the slot")
	SaveData.start_expedition(d, "kael", "herbs", 5000)
	SaveData.save_data(d)
	loaded = SaveData.load_data()
	check(loaded["dorm"] == ["astra"] and loaded["expeditions"].size() == 1 and typeof(loaded["expeditions"][0]["end"]) == TYPE_INT, "dorm and expeditions survive save/load")
	check(SaveData.bond_level(loaded, "astra") == GameData.bond_level_for(GameData.BOND_TALK * 2), "bond survives save/load")
	var bonus_mods: Array = SaveData.char_run_bonus(loaded, "astra")["mods"]
	check(bonus_mods.size() == GameData.CHAR_LEVEL_MODS.size() + GameData.BOND_LEVEL_MODS.size(), "bond mods reach the run bonus")

	# --- v6: construction timers and rewarded-ad bookkeeping ---
	d = SaveData.defaults()
	d["gold"] = 5000
	d["materials"] = 1000
	d["aether"] = 200
	check(SaveData.start_build(d, "library", 100), "library construction starts")
	check(SaveData.building_level(d, "library") == 0 and d["gold"] == 5000 - 400, "paid now, level comes later")
	check(SaveData.build_block(d, "training") == "builders" and not SaveData.start_build(d, "training", 100), "one builder")
	check(SaveData.build_block(d, "library") == "building", "cannot start the same building twice")
	var t1 := GameData.build_time(GameData.building_by_id("library"), 0)
	check(SaveData.build_left(d, "library", 100) == t1, "timer length from BUILD_TIMES")
	if t1 <= GameData.FREE_FINISH_SEC:
		check(SaveData.finish_build(d, "library", 100), "short first build can be finished free")
	else:
		check(SaveData.complete_due(d, 100 + t1) == ["library"], "construction completes when due")
	check(SaveData.building_level(d, "library") == 1 and d["construction"].is_empty(), "library Lv1 after construction")
	check(SaveData.start_build(d, "library", 200), "library Lv2 construction")
	var t2 := GameData.build_time(GameData.building_by_id("library"), 1)
	check(not SaveData.finish_build(d, "library", 200), "long build cannot be finished free at once")
	SaveData.speed_up_build(d, "library", 200)
	check(SaveData.build_left(d, "library", 200) == maxi(0, t2 - SaveData.ad_speedup(t2)), "an ad takes time off")
	check(SaveData.complete_due(d, 200 + t2) == ["library"] and SaveData.building_level(d, "library") == 2, "completes when the timer ends")
	check(GameData.build_time(GameData.building_by_id("frost_tower"), 0) > GameData.FREE_FINISH_SEC, "character buildings take a while")
	check(SaveData.start_build(d, "frost_tower", 300), "frost tower construction")
	SaveData.save_data(d)
	loaded = SaveData.load_data()
	check(loaded["construction"].size() == 1 and typeof(loaded["construction"][0]["end"]) == TYPE_INT, "construction survives save/load")
	for i in GameData.ADS_PER_DAY:
		SaveData.use_ad(d, "2026-11-02")
	check(SaveData.ads_left(d, "2026-11-02") == 0 and not SaveData.use_ad(d, "2026-11-02"), "daily ad cap")
	check(SaveData.ads_left(d, "2026-11-03") == GameData.ADS_PER_DAY, "the cap resets the next day")
	var g0: int = d["gold"]
	SaveData.bank_bonus(d, {"gold": 100, "essence": {"courtyard": 3}})
	check(d["gold"] == g0 + 100 and SaveData.essence(d, "courtyard") == 3, "double rewards add the resources again")

	# --- v7: locations and danger ---
	d = SaveData.defaults()
	check(SaveData.location_unlocked(d, "courtyard") and not SaveData.location_unlocked(d, "forest"), "only the courtyard at first")
	check(SaveData.danger_unlocked(d, "courtyard", 1) and not SaveData.danger_unlocked(d, "courtyard", 2), "danger 1 only")
	SaveData.bank_run(d, {}, {"victory": false, "location": "courtyard", "danger": 1})
	check(SaveData.cleared(d, "courtyard") == 0, "a defeat opens nothing")
	SaveData.bank_run(d, {}, {"victory": true, "location": "courtyard", "danger": 1})
	check(SaveData.danger_unlocked(d, "courtyard", 2) and SaveData.location_unlocked(d, "forest"), "winning danger 1 opens danger 2 and the next location")
	check(not SaveData.danger_unlocked(d, "forest", 2) and not SaveData.location_unlocked(d, "library"), "the forest starts at danger 1")
	check(SaveData.record_victory(d, "courtyard", 1) == "", "winning again opens nothing new")
	var m1 := GameData.run_mods("courtyard", 1)
	var m5 := GameData.run_mods("nexus", 5)
	check(is_equal_approx(float(m1["hp"]), 1.0) and float(m5["hp"]) > float(m1["hp"]) * 10.0 and float(m5["reward"]) > float(m1["reward"]), "later locations and dangers are harder and pay more")
	check(GameData.recommended_level("nexus", 5) > GameData.recommended_level("forest", 1), "recommended level grows")
	d["location"] = "nexus"
	d["danger"] = 4
	SaveData.save_data(d)
	loaded = SaveData.load_data()
	check(loaded["location"] == "courtyard" and loaded["danger"] == 1, "a locked selection falls back on load")
	check(SaveData.craft_loc(0) == "courtyard" and SaveData.craft_loc(2) == "forest", "higher rarities use later essences")

	# --- v8: quests ---
	d = SaveData.defaults()
	SaveData.roll_day(d, "2026-11-02")
	var dailies := SaveData.daily_quests("2026-11-02")
	check(dailies.size() == GameData.DAILY_QUEST_COUNT and dailies == SaveData.daily_quests("2026-11-02"), "three dailies, stable for the day")
	var story := SaveData.story_quests(d)
	check(story.size() == 1 and story[0]["id"] == "s_first_run" and not SaveData.quest_done(d, story[0]), "first story quest open")
	check(SaveData.claim_quest(d, story[0], "2026-11-02").is_empty(), "cannot claim an unfinished quest")
	SaveData.bank_run(d, {}, {"victory": true, "kills": 450, "chests": 13, "boss": true, "location": "courtyard", "danger": 1})
	check(SaveData.counter(d, "kills") == 450 and SaveData.counter(d, "wins") == 1 and SaveData.counter(d, "bosses") == 1, "runs count kills, wins, bosses")
	check(SaveData.quest_done(d, story[0]), "first run quest done")
	var g0q: int = d["gold"]
	var got_q := SaveData.claim_quest(d, story[0], "2026-11-02")
	check(int(d["gold"]) == g0q + int(got_q.get("gold", 0)) and SaveData.claim_quest(d, story[0], "2026-11-02").is_empty(), "story reward paid once")
	check(SaveData.story_quests(d)[0]["id"] != "s_first_run", "the next story quest shows")
	var all_daily := {"id": "d_kills", "text": "", "counter": "kills", "goal": 400, "reward": {"gold": 250}}
	check(SaveData.quest_progress(d, all_daily)[0] == 400, "daily progress counts today's growth")
	SaveData.roll_day(d, "2026-11-03")
	check(SaveData.quest_progress(d, all_daily)[0] == 0, "a new day starts the dailies over")
	SaveData.talk(d, "astra", "2026-11-03") # not a resident: no count
	d["buildings"]["dormitory"] = 1
	SaveData.move_in(d, "astra")
	SaveData.talk(d, "astra", "2026-11-03")
	check(SaveData.counter(d, "talks") == 1, "talks are counted")
	SaveData.save_data(d)
	loaded = SaveData.load_data()
	check(loaded["counters"]["kills"] == 450 and typeof(loaded["counters"]["kills"]) == TYPE_INT and loaded["quests"]["story"].size() == 1, "quests survive save/load")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.path))
	print("academy tests: ", "PASS" if failures == 0 else "%d FAILED" % failures)
	quit(1 if failures > 0 else 0)
