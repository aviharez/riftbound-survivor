class_name MapGenerator
extends RefCounted
## Deterministic procedural Rift map. Same seed -> same terrain and same object positions.
##
## Steps: noise terrain -> cellular-automata smoothing -> border -> keep largest
## connected region -> place spawn / portal / chests / shrines / pots with distance rules.
## If any placement rule cannot be satisfied, the seed is re-rolled deterministically.

const PLACE_TRIES := 300
const MAX_REROLLS := 20

var w := GameData.MAP_W
var h := GameData.MAP_H


func generate(seed_value: int) -> Dictionary:
	var s := seed_value
	for attempt in MAX_REROLLS:
		var result := _try_generate(s)
		if not result.is_empty():
			result["seed"] = seed_value
			result["effective_seed"] = s
			result["rerolls"] = attempt
			return result
		s = int(hash(str(s) + "reroll")) & 0x7fffffff
	push_error("MapGenerator: failed after %d rerolls" % MAX_REROLLS)
	return {}


func _try_generate(s: int) -> Dictionary:
	var grid := _make_terrain(s)
	_smooth(grid, 2)
	_apply_border(grid, 3)
	_keep_largest_region(grid)

	var rng := RandomNumberGenerator.new()
	rng.seed = s
	var walkable := PackedInt32Array()
	for i in grid.size():
		if grid[i] != GameData.T_WALL:
			walkable.append(i)
	if walkable.size() < int(w * h * 0.45):
		return {}

	# Player spawn
	var spawn := _pick(rng, walkable, grid, 3, func(c: Vector2i) -> bool:
		return c.x >= GameData.SPAWN_EDGE_MIN and c.y >= GameData.SPAWN_EDGE_MIN \
			and c.x < w - GameData.SPAWN_EDGE_MIN and c.y < h - GameData.SPAWN_EDGE_MIN)
	if spawn.x < 0:
		return {}

	# Boss portal: far from the player
	var portal := _pick(rng, walkable, grid, 3, func(c: Vector2i) -> bool:
		return c.distance_to(spawn) >= GameData.PORTAL_MIN_DIST \
			and c.x >= GameData.PORTAL_EDGE_MIN and c.y >= GameData.PORTAL_EDGE_MIN \
			and c.x < w - GameData.PORTAL_EDGE_MIN and c.y < h - GameData.PORTAL_EDGE_MIN)
	if portal.x < 0:
		return {}

	var taken: Array[Vector2i] = [spawn, portal]

	var chests: Array[Vector2i] = []
	for n in GameData.CHEST_COUNT:
		var c := _pick(rng, walkable, grid, 1, func(cell: Vector2i) -> bool:
			if cell.distance_to(spawn) < GameData.CHEST_SPAWN_MIN or cell.distance_to(portal) < 6:
				return false
			for o in chests:
				if cell.distance_to(o) < GameData.CHEST_SPACING:
					return false
			return true)
		if c.x < 0:
			return {}
		chests.append(c)
		taken.append(c)

	var shrines: Array = []
	var type_count := {}
	var type_keys: Array = GameData.SHRINE_TYPES.keys()
	for n in GameData.SHRINE_COUNT:
		var c := _pick(rng, walkable, grid, 2, func(cell: Vector2i) -> bool:
			if cell.distance_to(spawn) < 6 or cell.distance_to(portal) < 10:
				return false
			for o in shrines:
				if cell.distance_to(o["cell"]) < GameData.SHRINE_SPACING:
					return false
			for o in chests:
				if cell.distance_to(o) < 5:
					return false
			return true)
		if c.x < 0:
			return {}
		var t: String
		if n < GameData.SHRINE_GUARANTEED.size():
			t = GameData.SHRINE_GUARANTEED[n]
		else:
			var weights: Array = []
			for k in type_keys:
				var full: bool = int(type_count.get(k, 0)) >= GameData.SHRINE_MAX_PER_TYPE
				weights.append(0.0 if full else float(GameData.SHRINE_TYPES[k]["weight"]))
			t = type_keys[GameData.weighted_index(rng, weights)]
		type_count[t] = int(type_count.get(t, 0)) + 1
		shrines.append({"cell": c, "type": t})
		taken.append(c)

	var pots: Array[Vector2i] = []
	for n in GameData.POT_COUNT:
		var c := _pick(rng, walkable, grid, 0, func(cell: Vector2i) -> bool:
			for o in taken:
				if cell.distance_to(o) < GameData.POT_SPACING:
					return false
			for o in pots:
				if cell.distance_to(o) < GameData.POT_SPACING:
					return false
			return true)
		if c.x < 0:
			break # pots are optional decoration-loot; never fail the map for them
		pots.append(c)

	return {
		"w": w, "h": h, "grid": grid,
		"spawn": spawn, "portal": portal,
		"chests": chests, "shrines": shrines, "pots": pots,
	}


func _make_terrain(s: int) -> PackedByteArray:
	var grid := PackedByteArray()
	grid.resize(w * h)
	var obstacles := FastNoiseLite.new()
	obstacles.seed = s
	obstacles.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	obstacles.frequency = 0.07
	var zones := FastNoiseLite.new()
	zones.seed = s + 101
	zones.frequency = 0.02
	var cracks := FastNoiseLite.new()
	cracks.seed = s + 202
	cracks.frequency = 0.09
	for y in h:
		for x in w:
			var i := y * w + x
			if obstacles.get_noise_2d(x, y) > 0.30:
				grid[i] = GameData.T_WALL
			elif zones.get_noise_2d(x, y) > 0.33:
				grid[i] = GameData.T_RUINS
			elif cracks.get_noise_2d(x, y) > 0.5:
				grid[i] = GameData.T_RIFT
			else:
				grid[i] = GameData.T_GRASS
	return grid


## Cellular automata: a cell becomes wall if >=5 of its 3x3 block are walls.
func _smooth(grid: PackedByteArray, iterations: int) -> void:
	for it in iterations:
		var copy := grid.duplicate()
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				var n := 0
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if copy[(y + dy) * w + x + dx] == GameData.T_WALL:
							n += 1
				var i := y * w + x
				if n >= 5:
					grid[i] = GameData.T_WALL
				elif copy[i] == GameData.T_WALL:
					grid[i] = GameData.T_RUINS # eroded wall leaves rubble floor


func _apply_border(grid: PackedByteArray, thickness: int) -> void:
	for y in h:
		for x in w:
			if x < thickness or y < thickness or x >= w - thickness or y >= h - thickness:
				grid[y * w + x] = GameData.T_WALL


## Fills every walkable pocket that is not connected to the biggest region.
func _keep_largest_region(grid: PackedByteArray) -> void:
	var label := PackedInt32Array()
	label.resize(w * h)
	label.fill(-1)
	var best_label := -1
	var best_size := 0
	var current := 0
	var stack := PackedInt32Array()
	for start in grid.size():
		if grid[start] == GameData.T_WALL or label[start] != -1:
			continue
		var size := 0
		stack.clear()
		stack.append(start)
		label[start] = current
		while not stack.is_empty():
			var i: int = stack[stack.size() - 1]
			stack.remove_at(stack.size() - 1)
			size += 1
			var x := i % w
			var y := i / w
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					continue
				var j := ny * w + nx
				if grid[j] != GameData.T_WALL and label[j] == -1:
					label[j] = current
					stack.append(j)
		if size > best_size:
			best_size = size
			best_label = current
		current += 1
	for i in grid.size():
		if grid[i] != GameData.T_WALL and label[i] != best_label:
			grid[i] = GameData.T_WALL


func _pick(rng: RandomNumberGenerator, walkable: PackedInt32Array, grid: PackedByteArray, clear_radius: int, rule: Callable) -> Vector2i:
	for t in PLACE_TRIES:
		var i: int = walkable[rng.randi_range(0, walkable.size() - 1)]
		var c := Vector2i(i % w, i / w)
		if _is_clear(grid, c, clear_radius) and rule.call(c):
			return c
	return Vector2i(-1, -1)


func _is_clear(grid: PackedByteArray, c: Vector2i, r: int) -> bool:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var x := c.x + dx
			var y := c.y + dy
			if x < 0 or y < 0 or x >= w or y >= h or grid[y * w + x] == GameData.T_WALL:
				return false
	return true
