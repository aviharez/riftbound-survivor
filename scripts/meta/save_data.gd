class_name SaveData
extends RefCounted
## Persistent academy progress (resources, building levels, run history), stored as JSON in user://.
## Autotests never write here; tests/test_academy.gd uses its own path.

const DEFAULT_PATH := "user://riftbound_save.json"
const VERSION := 7
# v1 -> v2: "lessons" (Staff Room permanent upgrades, id -> rank); new buildings start at 0 (handled generally).
# v2 -> v3: "shards" (Arcane Shards) and "characters" (id -> {exp, passive, weapon}: level EXP and enhance ranks).
# v3 -> v4: equipment ("items" inventory, "equipped" char -> slot -> uid, "next_uid") and "essence" (location -> n).
# v4 -> v5: character "bond" EXP, "dorm" (resident ids), "talked" (id -> date of the last talk), "expeditions".
# v5 -> v6: "construction" (buildings being built: {id, end, total}) and "ads" ({day, count}: rewarded ads today).
# v6 -> v7: "progress" (location id -> highest danger won), selected "location" and "danger".
const RESOURCES := ["gold", "materials", "aether", "exp", "shards"]
const ENHANCE_TRACKS := ["passive", "weapon"]

static var path := DEFAULT_PATH


static func defaults() -> Dictionary:
	var buildings := {}
	for b in GameData.BUILDINGS:
		buildings[b["id"]] = 0
	return {
		"version": VERSION,
		"gold": 0, "materials": 0, "aether": 0, "exp": 0, "shards": 0,
		"buildings": buildings,
		"runs": 0, "victories": 0, "best_kills": 0,
		"last_run": {},
		"character": "astra",
		"lessons": {},
		"characters": {},
		"items": [], "next_uid": 1, "equipped": {}, "essence": {},
		"dorm": [], "talked": {}, "expeditions": [],
		"construction": [], "ads": {"day": "", "count": 0},
		"progress": {}, "location": "courtyard", "danger": 1,
	}


static func load_data() -> Dictionary:
	var d := defaults()
	if not FileAccess.file_exists(path):
		return d
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return d
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveData: unreadable save, using defaults")
		return d
	for k in d:
		if parsed.has(k):
			d[k] = parsed[k]
	# new buildings added after the save was written start at level 0
	for b in GameData.BUILDINGS:
		if not d["buildings"].has(b["id"]):
			d["buildings"][b["id"]] = 0
	# v1 saves have no lessons; any version: lessons are id -> int rank
	if typeof(d["lessons"]) != TYPE_DICTIONARY:
		d["lessons"] = {}
	for k in d["lessons"]:
		d["lessons"][k] = int(d["lessons"][k])
	# v2 saves have no shards / characters; any version: character entries hold ints
	if typeof(d["characters"]) != TYPE_DICTIONARY:
		d["characters"] = {}
	for id in d["characters"].keys():
		var st = d["characters"][id]
		if typeof(st) != TYPE_DICTIONARY:
			d["characters"].erase(id)
			continue
		d["characters"][id] = _char_defaults()
		for k in d["characters"][id]:
			d["characters"][id][k] = int(st.get(k, 0))
	_clean_equipment(d)
	_clean_dorm(d)
	_clean_construction(d)
	_clean_progress(d)
	d["version"] = VERSION
	# a locked (or unknown) selected character falls back to Astra
	if not character_unlocked(d, String(d["character"])):
		d["character"] = "astra"
	# JSON numbers come back as floats
	for k in RESOURCES + ["runs", "victories", "best_kills"]:
		d[k] = int(d[k])
	for k in d["buildings"]:
		d["buildings"][k] = int(d["buildings"][k])
	return d


static func save_data(d: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("SaveData: cannot write %s" % path)
		return
	f.store_string(JSON.stringify(d, "\t"))


static func reset() -> Dictionary:
	var d := defaults()
	save_data(d)
	return d


static func building_level(d: Dictionary, id: String) -> int:
	return int(d["buildings"].get(id, 0))


static func slots_for(d: Dictionary, kind: String) -> int:
	var base: int = GameData.BASE_TOME_SLOTS if kind == "tome" else GameData.BASE_WEAPON_SLOTS
	for b in GameData.BUILDINGS:
		if b["unlocks"] == kind:
			base += building_level(d, b["id"])
	return min(base, GameData.MAX_SLOTS)


## Cost of the next level, or {} when the building is maxed.
static func next_cost(d: Dictionary, id: String) -> Dictionary:
	var b := GameData.building_by_id(id)
	var lv := building_level(d, id)
	if lv >= b["costs"].size():
		return {}
	return b["costs"][lv]


static func can_afford(d: Dictionary, cost: Dictionary) -> bool:
	if cost.is_empty():
		return false
	for k in cost:
		if int(d.get(k, 0)) < int(cost[k]):
			return false
	return true


## Pays and levels up. Returns false (and changes nothing) if maxed or unaffordable.
static func upgrade(d: Dictionary, id: String) -> bool:
	var cost := next_cost(d, id)
	if not can_afford(d, cost):
		return false
	for k in cost:
		d[k] = int(d[k]) - int(cost[k])
	d["buildings"][id] = building_level(d, id) + 1
	return true


# ------------------------------------------------------------------ locations and danger

static func _clean_progress(d: Dictionary) -> void:
	if typeof(d["progress"]) != TYPE_DICTIONARY:
		d["progress"] = {}
	for k in d["progress"].keys():
		d["progress"][k] = clampi(int(d["progress"][k]), 0, GameData.DANGERS.size())
	d["danger"] = int(d["danger"])
	if not location_unlocked(d, String(d["location"])):
		d["location"] = "courtyard"
	if not danger_unlocked(d, String(d["location"]), int(d["danger"])):
		d["danger"] = 1


## Highest danger won in a location (0 = none).
static func cleared(d: Dictionary, loc: String) -> int:
	return int(d["progress"].get(loc, 0))


static func location_unlocked(d: Dictionary, loc: String) -> bool:
	var i := GameData.location_index(loc)
	if GameData.LOCATIONS[i]["id"] != loc:
		return false
	return i == 0 or cleared(d, GameData.LOCATIONS[i - 1]["id"]) >= 1


static func danger_unlocked(d: Dictionary, loc: String, danger: int) -> bool:
	return location_unlocked(d, loc) and danger >= 1 and danger <= GameData.DANGERS.size() and danger <= cleared(d, loc) + 1


## A victory at `danger` in `loc`; returns what it opened ("" , "danger" or "location").
static func record_victory(d: Dictionary, loc: String, danger: int) -> String:
	if danger <= cleared(d, loc):
		return ""
	var first := cleared(d, loc) == 0
	d["progress"][loc] = danger
	var i := GameData.location_index(loc)
	if first and i + 1 < GameData.LOCATIONS.size():
		return "location"
	return "danger" if danger < GameData.DANGERS.size() else ""


# ------------------------------------------------------------------ construction (real-time timers)

static func _clean_construction(d: Dictionary) -> void:
	if typeof(d["construction"]) != TYPE_ARRAY:
		d["construction"] = []
	var keep: Array = []
	for c in d["construction"]:
		if typeof(c) == TYPE_DICTIONARY and not GameData.building_by_id(String(c.get("id", ""))).is_empty():
			keep.append({"id": String(c["id"]), "end": int(c.get("end", 0)), "total": int(c.get("total", 1))})
	d["construction"] = keep
	if typeof(d["ads"]) != TYPE_DICTIONARY:
		d["ads"] = {"day": "", "count": 0}
	d["ads"] = {"day": String(d["ads"].get("day", "")), "count": int(d["ads"].get("count", 0))}


## The building's running construction {id, end, total}, or {}.
static func construction_of(d: Dictionary, id: String) -> Dictionary:
	for c in d["construction"]:
		if c["id"] == id:
			return c
	return {}


static func builders_free(d: Dictionary) -> int:
	return GameData.BUILDER_SLOTS - d["construction"].size()


## Why the next level cannot start now: "" (it can), "max", "building", "builders" or "cost".
static func build_block(d: Dictionary, id: String) -> String:
	var cost := next_cost(d, id)
	if cost.is_empty():
		return "max"
	if not construction_of(d, id).is_empty():
		return "building"
	if builders_free(d) <= 0:
		return "builders"
	if not can_afford(d, cost):
		return "cost"
	return ""


## Pays and starts building the next level (it is gained when the timer ends). False changes nothing.
static func start_build(d: Dictionary, id: String, now: int) -> bool:
	if build_block(d, id) != "":
		return false
	var cost := next_cost(d, id)
	for k in cost:
		d[k] = int(d[k]) - int(cost[k])
	var t := GameData.build_time(GameData.building_by_id(id), building_level(d, id))
	d["construction"].append({"id": id, "end": now + t, "total": t})
	return true


static func build_left(d: Dictionary, id: String, now: int) -> int:
	var c := construction_of(d, id)
	return 0 if c.is_empty() else maxi(0, int(c["end"]) - now)


## Finishes a construction whose time is up or nearly up (under FREE_FINISH_SEC): the level is gained.
static func finish_build(d: Dictionary, id: String, now: int) -> bool:
	var c := construction_of(d, id)
	if c.is_empty() or build_left(d, id, now) > GameData.FREE_FINISH_SEC:
		return false
	d["construction"].erase(c)
	d["buildings"][id] = building_level(d, id) + 1
	return true


## Completes every construction whose timer has ended; returns their building ids.
static func complete_due(d: Dictionary, now: int) -> Array:
	var done: Array = []
	for c in d["construction"].duplicate():
		if int(c["end"]) <= now:
			finish_build(d, String(c["id"]), now)
			done.append(String(c["id"]))
	return done


## How much one speed-up ad takes off `left` seconds.
static func ad_speedup(left: int) -> int:
	return maxi(GameData.AD_SPEEDUP_SEC, int(left * GameData.AD_SPEEDUP_SHARE))


static func speed_up_build(d: Dictionary, id: String, now: int) -> void:
	var c := construction_of(d, id)
	if not c.is_empty():
		c["end"] = int(c["end"]) - ad_speedup(build_left(d, id, now))


static func speed_up_expedition(d: Dictionary, index: int, now: int) -> void:
	if index >= 0 and index < d["expeditions"].size():
		var e: Dictionary = d["expeditions"][index]
		e["end"] = int(e["end"]) - ad_speedup(maxi(0, int(e["end"]) - now))


# ------------------------------------------------------------------ rewarded ads (daily cap)

static func ads_left(d: Dictionary, day: String) -> int:
	if String(d["ads"]["day"]) != day:
		return GameData.ADS_PER_DAY
	return maxi(0, GameData.ADS_PER_DAY - int(d["ads"]["count"]))


## Counts one watched ad; false when today's cap is used up.
static func use_ad(d: Dictionary, day: String) -> bool:
	if ads_left(d, day) <= 0:
		return false
	if String(d["ads"]["day"]) != day:
		d["ads"] = {"day": day, "count": 0}
	d["ads"]["count"] = int(d["ads"]["count"]) + 1
	return true


## Adds a second copy of a run's resource rewards (the "double rewards" ad); items and stats are not doubled.
static func bank_bonus(d: Dictionary, rewards: Dictionary) -> void:
	for k in RESOURCES:
		d[k] = int(d[k]) + int(rewards.get(k, 0))
	var ess: Dictionary = rewards.get("essence", {})
	for loc in ess:
		d["essence"][loc] = essence(d, loc) + int(ess[loc])


## Characters with an `unlock` building need it restored (Lv 1+); the rest are always available.
static func character_unlocked(d: Dictionary, id: String) -> bool:
	for c in GameData.CHARACTERS:
		if c["id"] == id:
			# unlock_level: the building level that brings them back (Wren: Library at max level)
			return c["unlock"] == "" or building_level(d, c["unlock"]) >= int(c.get("unlock_level", 1))
	return false


# ------------------------------------------------------------------ Staff Room lessons

static func lesson_rank(d: Dictionary, id: String) -> int:
	return int(d["lessons"].get(id, 0))


## Highest rank a lesson can reach right now (0 while the Staff Room is in ruins).
static func lesson_cap(d: Dictionary) -> int:
	return GameData.LESSON_RANKS_PER_LEVEL * building_level(d, "staff_room")


## Cost of the next rank, or {} when capped.
static func next_lesson_cost(d: Dictionary, id: String) -> Dictionary:
	var rank := lesson_rank(d, id)
	if rank >= lesson_cap(d):
		return {}
	return GameData.lesson_cost(rank + 1)


## Pays and raises a lesson by one rank. Returns false (and changes nothing) if capped or unaffordable.
static func buy_lesson(d: Dictionary, id: String) -> bool:
	if GameData.lesson_by_id(id).is_empty():
		return false
	var cost := next_lesson_cost(d, id)
	if not can_afford(d, cost):
		return false
	for k in cost:
		d[k] = int(d[k]) - int(cost[k])
	d["lessons"][id] = lesson_rank(d, id) + 1
	return true


## Stat mods ([[stat, value], ...]) of every lesson bought, applied to the player at run start.
static func lesson_mods(d: Dictionary) -> Array:
	var out: Array = []
	for l in GameData.LESSONS:
		var rank := lesson_rank(d, l["id"])
		if rank > 0:
			out.append([l["stat"], float(l["per"]) * rank])
	return out


# ------------------------------------------------------------------ characters: level + enhance

static func _char_defaults() -> Dictionary:
	return {"exp": 0, "passive": 0, "weapon": 0, "bond": 0}


## The character's saved progress (created on first use).
static func char_state(d: Dictionary, id: String) -> Dictionary:
	if not d["characters"].has(id):
		d["characters"][id] = _char_defaults()
	return d["characters"][id]


static func char_level(d: Dictionary, id: String) -> int:
	return GameData.char_level_for(int(char_state(d, id)["exp"]))


static func add_char_exp(d: Dictionary, id: String, amount: int) -> void:
	var st := char_state(d, id)
	st["exp"] = mini(int(st["exp"]) + amount, GameData.char_exp_for(GameData.CHAR_MAX_LEVEL))


## Highest enhance rank the character's level allows right now.
static func enhance_cap(d: Dictionary, id: String) -> int:
	return mini(GameData.ENHANCE_MAX, char_level(d, id) / GameData.ENHANCE_LEVEL_STEP)


## Cost of the next rank of an enhance track ("passive" / "weapon"), or {} when capped.
static func next_enhance_cost(d: Dictionary, id: String, track: String) -> Dictionary:
	var rank := int(char_state(d, id)[track])
	if rank >= enhance_cap(d, id):
		return {}
	return GameData.enhance_cost(rank + 1)


## Pays and raises an enhance track by one rank. Returns false (and changes nothing) if capped or unaffordable.
static func enhance(d: Dictionary, id: String, track: String) -> bool:
	if not track in ENHANCE_TRACKS:
		return false
	var cost := next_enhance_cost(d, id, track)
	if not can_afford(d, cost):
		return false
	for k in cost:
		d[k] = int(d[k]) - int(cost[k])
	char_state(d, id)[track] = int(char_state(d, id)[track]) + 1
	return true


## What a run starts with for this character: level + equipment stat mods and enhance ranks.
static func char_run_bonus(d: Dictionary, id: String) -> Dictionary:
	var st := char_state(d, id)
	var lv := char_level(d, id)
	return {"level": lv, "mods": GameData.char_level_mods(lv) + equip_mods(d, id) + GameData.bond_mods(bond_level(d, id)),
		"passive": int(st["passive"]), "weapon": int(st["weapon"]), "bond": bond_level(d, id)}


# ------------------------------------------------------------------ bond, dormitory, expeditions

static func _clean_dorm(d: Dictionary) -> void:
	if typeof(d["dorm"]) != TYPE_ARRAY:
		d["dorm"] = []
	if typeof(d["talked"]) != TYPE_DICTIONARY:
		d["talked"] = {}
	if typeof(d["expeditions"]) != TYPE_ARRAY:
		d["expeditions"] = []
	var dorm: Array = []
	for id in d["dorm"]:
		if character_unlocked(d, String(id)) and not String(id) in dorm and dorm.size() < dorm_rooms(d):
			dorm.append(String(id))
	d["dorm"] = dorm
	var exps: Array = []
	for e in d["expeditions"]:
		if typeof(e) == TYPE_DICTIONARY and not GameData.expedition_by_id(String(e.get("mission", ""))).is_empty():
			exps.append({"char": String(e["char"]), "mission": String(e["mission"]), "start": int(e["start"]), "end": int(e["end"])})
	d["expeditions"] = exps


static func bond_level(d: Dictionary, id: String) -> int:
	return GameData.bond_level_for(int(char_state(d, id)["bond"]))


static func add_bond(d: Dictionary, id: String, amount: int) -> void:
	var st := char_state(d, id)
	st["bond"] = mini(int(st["bond"]) + amount, GameData.BOND_EXP[GameData.BOND_MAX])


static func dorm_rooms(d: Dictionary) -> int:
	return GameData.DORM_ROOMS[mini(building_level(d, "dormitory"), GameData.DORM_ROOMS.size() - 1)]


static func move_in(d: Dictionary, id: String) -> bool:
	if not character_unlocked(d, id) or id in d["dorm"] or d["dorm"].size() >= dorm_rooms(d):
		return false
	d["dorm"].append(id)
	return true


static func move_out(d: Dictionary, id: String) -> void:
	d["dorm"].erase(id)


## Today's date as "YYYY-MM-DD" (local time): one talk per character per day.
static func today() -> String:
	var t := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [t["year"], t["month"], t["day"]]


static func can_talk(d: Dictionary, id: String, day: String) -> bool:
	return id in d["dorm"] and String(d["talked"].get(id, "")) != day and not is_away(d, id)


static func talk(d: Dictionary, id: String, day: String) -> bool:
	if not can_talk(d, id, day):
		return false
	d["talked"][id] = day
	add_bond(d, id, GameData.BOND_TALK)
	return true


## Expedition slots = Dormitory level.
static func expedition_slots(d: Dictionary) -> int:
	return building_level(d, "dormitory")


static func is_away(d: Dictionary, id: String) -> bool:
	for e in d["expeditions"]:
		if e["char"] == id:
			return true
	return false


## Sends a character out (not the one selected for the Rift). `now` = unix seconds.
static func start_expedition(d: Dictionary, id: String, mission: String, now: int) -> bool:
	var m := GameData.expedition_by_id(mission)
	if m.is_empty() or not character_unlocked(d, id) or is_away(d, id) or id == String(d["character"]):
		return false
	if d["expeditions"].size() >= expedition_slots(d):
		return false
	d["expeditions"].append({"char": id, "mission": mission, "start": now, "end": now + int(float(m["hours"]) * 3600.0)})
	return true


## Rewards of a mission for a character level (items = number of equipment pieces).
static func expedition_rewards(mission: String, char_lv: int) -> Dictionary:
	var m := GameData.expedition_by_id(mission)
	var k := 1.0 + GameData.EXPEDITION_LEVEL_BONUS * (char_lv - 1)
	var out := {}
	for key in m["rewards"]:
		out[key] = int(m["rewards"][key]) if key == "items" else int(round(int(m["rewards"][key]) * k))
	return out


## Collects a finished expedition: pays its rewards (+ bond) and frees the slot. Returns what was given
## ({} if not finished yet). Essence goes to the first location; items are rolled with `rng`.
static func collect_expedition(d: Dictionary, index: int, now: int, rng: RandomNumberGenerator) -> Dictionary:
	if index < 0 or index >= d["expeditions"].size():
		return {}
	var e: Dictionary = d["expeditions"][index]
	if now < int(e["end"]):
		return {}
	var got := expedition_rewards(e["mission"], char_level(d, e["char"]))
	var items: Array = []
	for i in int(got.get("items", 0)):
		var it := GameData.roll_item(rng, GameData.roll_gear_rarity(rng))
		if add_item(d, it) >= 0:
			items.append(it)
	got["items"] = items
	for key in got:
		if key in RESOURCES:
			d[key] = int(d[key]) + int(got[key])
		elif key == "essence":
			var loc: String = GameData.LOCATIONS[0]["id"]
			d["essence"][loc] = essence(d, loc) + int(got[key])
	add_bond(d, e["char"], GameData.BOND_EXPEDITION)
	d["expeditions"].remove_at(index)
	got["char"] = e["char"]
	return got


## Calls a character back early: no rewards.
static func cancel_expedition(d: Dictionary, index: int) -> void:
	if index >= 0 and index < d["expeditions"].size():
		d["expeditions"].remove_at(index)


# ------------------------------------------------------------------ equipment + crafting

## JSON turns ints into floats and old saves lack the keys: normalise items, drop dangling equips.
static func _clean_equipment(d: Dictionary) -> void:
	for k in ["items"]:
		if typeof(d[k]) != TYPE_ARRAY:
			d[k] = []
	for k in ["equipped", "essence"]:
		if typeof(d[k]) != TYPE_DICTIONARY:
			d[k] = {}
	var items: Array = []
	for it in d["items"]:
		if typeof(it) == TYPE_DICTIONARY and not GameData.equip_base(String(it.get("base", ""))).is_empty():
			var subs: Array = []
			for sub in it.get("subs", []):
				subs.append([String(sub[0]), float(sub[1])])
			items.append({"uid": int(it["uid"]), "base": String(it["base"]), "rarity": int(it["rarity"]), "subs": subs})
	d["items"] = items
	d["next_uid"] = int(d["next_uid"])
	for it in items:
		d["next_uid"] = maxi(int(d["next_uid"]), int(it["uid"]) + 1)
	for cid in d["equipped"].keys():
		var slots: Dictionary = d["equipped"][cid]
		for slot in slots.keys():
			slots[slot] = int(slots[slot])
			if item_by_uid(d, slots[slot]).is_empty():
				slots.erase(slot)
	for k in d["essence"]:
		d["essence"][k] = int(d["essence"][k])


static func item_by_uid(d: Dictionary, uid: int) -> Dictionary:
	for it in d["items"]:
		if int(it["uid"]) == uid:
			return it
	return {}


## Adds a rolled piece to the inventory; returns its uid, or -1 when the inventory is full.
static func add_item(d: Dictionary, item: Dictionary) -> int:
	if d["items"].size() >= GameData.INVENTORY_CAP:
		return -1
	var it := item.duplicate(true)
	it["uid"] = int(d["next_uid"])
	d["next_uid"] = int(d["next_uid"]) + 1
	d["items"].append(it)
	return it["uid"]


static func equipped_item(d: Dictionary, char_id: String, slot: String) -> Dictionary:
	var slots: Dictionary = d["equipped"].get(char_id, {})
	return item_by_uid(d, int(slots[slot])) if slots.has(slot) else {}


## Character currently wearing the piece ("" = in the inventory).
static func owner_of(d: Dictionary, uid: int) -> String:
	for cid in d["equipped"]:
		for slot in d["equipped"][cid]:
			if int(d["equipped"][cid][slot]) == uid:
				return cid
	return ""


## Puts a piece on a character (taking it off whoever wore it). Returns false for an unknown piece.
static func equip(d: Dictionary, char_id: String, uid: int) -> bool:
	var it := item_by_uid(d, uid)
	if it.is_empty():
		return false
	var prev := owner_of(d, uid)
	if prev != "":
		for slot in d["equipped"][prev].keys():
			if int(d["equipped"][prev][slot]) == uid:
				d["equipped"][prev].erase(slot)
	if not d["equipped"].has(char_id):
		d["equipped"][char_id] = {}
	d["equipped"][char_id][GameData.equip_base(String(it["base"]))["slot"]] = uid
	return true


static func unequip(d: Dictionary, char_id: String, slot: String) -> void:
	if d["equipped"].has(char_id):
		d["equipped"][char_id].erase(slot)


static func equip_mods(d: Dictionary, char_id: String) -> Array:
	var out: Array = []
	for slot in GameData.EQUIP_SLOTS:
		var it := equipped_item(d, char_id, slot)
		if not it.is_empty():
			out += GameData.item_mods(it)
	return out


static func essence(d: Dictionary, loc: String) -> int:
	return int(d["essence"].get(loc, 0))


## Highest rarity the Workshop can craft right now: its level (Lv 1 = Uncommon ... Lv 3 = Epic), -1 in ruins.
static func craft_rarity_cap(d: Dictionary) -> int:
	var lv := building_level(d, "workshop")
	return lv if lv > 0 else -1


## Location whose essence a craft (or salvage) of `rarity` uses.
static func craft_loc(rarity: int) -> String:
	return GameData.CRAFT_ESSENCE[clampi(rarity, 0, GameData.CRAFT_ESSENCE.size() - 1)]


static func can_craft(d: Dictionary, rarity: int, loc: String) -> bool:
	if rarity < 0 or rarity > craft_rarity_cap(d) or d["items"].size() >= GameData.INVENTORY_CAP:
		return false
	var cost: Dictionary = GameData.CRAFT_COST[rarity]
	return int(d["materials"]) >= int(cost["materials"]) and essence(d, loc) >= int(cost["essence"])


## Crafts a piece of `base_id` at `rarity` with essence from `loc`. Returns the new item or {}.
static func craft(d: Dictionary, base_id: String, rarity: int, loc: String, rng: RandomNumberGenerator) -> Dictionary:
	if GameData.equip_base(base_id).is_empty() or not can_craft(d, rarity, loc):
		return {}
	var cost: Dictionary = GameData.CRAFT_COST[rarity]
	d["materials"] = int(d["materials"]) - int(cost["materials"])
	d["essence"][loc] = essence(d, loc) - int(cost["essence"])
	var uid := add_item(d, GameData.roll_item(rng, rarity, base_id))
	return item_by_uid(d, uid)


## Breaks a piece down (taking it off first) for part of its craft cost; essence goes to `loc`.
static func salvage(d: Dictionary, uid: int, loc: String) -> bool:
	var it := item_by_uid(d, uid)
	if it.is_empty():
		return false
	var prev := owner_of(d, uid)
	if prev != "":
		unequip(d, prev, GameData.equip_base(String(it["base"]))["slot"])
	var cost: Dictionary = GameData.CRAFT_COST[int(it["rarity"])]
	d["materials"] = int(d["materials"]) + int(round(int(cost["materials"]) * GameData.SALVAGE_SHARE))
	d["essence"][loc] = essence(d, loc) + int(round(int(cost["essence"]) * GameData.SALVAGE_SHARE))
	d["items"].erase(it)
	return true


## Adds a finished run's rewards and summary. rewards["char_exp"] goes to summary["character"].
static func bank_run(d: Dictionary, rewards: Dictionary, summary: Dictionary) -> void:
	for k in RESOURCES:
		d[k] = int(d[k]) + int(rewards.get(k, 0))
	if summary.has("character") and rewards.has("char_exp"):
		add_char_exp(d, String(summary["character"]), int(rewards["char_exp"]))
		add_bond(d, String(summary["character"]), GameData.BOND_RUN + (GameData.BOND_VICTORY if summary.get("victory", false) else 0))
	var ess: Dictionary = rewards.get("essence", {})
	for loc in ess:
		d["essence"][loc] = essence(d, loc) + int(ess[loc])
	for it in rewards.get("items", []):
		add_item(d, it)   # a full inventory loses the extra drops (the result screen says so)
	d["runs"] = int(d["runs"]) + 1
	if summary.get("victory", false):
		d["victories"] = int(d["victories"]) + 1
		record_victory(d, String(summary.get("location", "courtyard")), int(summary.get("danger", 1)))
	d["best_kills"] = max(int(d["best_kills"]), int(summary.get("kills", 0)))
	d["last_run"] = summary
