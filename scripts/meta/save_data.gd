class_name SaveData
extends RefCounted
## Persistent academy progress (resources, building levels, run history), stored as JSON in user://.
## Autotests never write here; tests/test_academy.gd uses its own path.

const DEFAULT_PATH := "user://riftbound_save.json"
const VERSION := 2
# v1 -> v2: "lessons" (Staff Room permanent upgrades, id -> rank); new buildings start at 0 (handled generally).

static var path := DEFAULT_PATH


static func defaults() -> Dictionary:
	var buildings := {}
	for b in GameData.BUILDINGS:
		buildings[b["id"]] = 0
	return {
		"version": VERSION,
		"gold": 0, "materials": 0, "aether": 0, "exp": 0,
		"buildings": buildings,
		"runs": 0, "victories": 0, "best_kills": 0,
		"last_run": {},
		"character": "astra",
		"lessons": {},
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
	d["version"] = VERSION
	# a locked (or unknown) selected character falls back to Astra
	if not character_unlocked(d, String(d["character"])):
		d["character"] = "astra"
	# JSON numbers come back as floats
	for k in ["gold", "materials", "aether", "exp", "runs", "victories", "best_kills"]:
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


## Adds a finished run's rewards and summary.
static func bank_run(d: Dictionary, rewards: Dictionary, summary: Dictionary) -> void:
	for k in ["gold", "materials", "aether", "exp"]:
		d[k] = int(d[k]) + int(rewards.get(k, 0))
	d["runs"] = int(d["runs"]) + 1
	if summary.get("victory", false):
		d["victories"] = int(d["victories"]) + 1
	d["best_kills"] = max(int(d["best_kills"]), int(summary.get("kills", 0)))
	d["last_run"] = summary
