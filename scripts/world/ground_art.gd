class_name GroundArt
extends Node2D
## Painted ground for locations that have PixelLab art (GameData.GROUND_ART): Wang corner tilesets drawn on a
## dual grid (every map cell is a tile CORNER, so terrain borders run through cell centres) plus scattered props.
## Everything is drawn at the characters' pixel density: 32 px art per 16 px map tile (scale 0.5).
##
## Tilesets (assets/tiles/<loc>/<set>.png + tiles.json with each tile's corners L/U/T):
##   hedge  = grass -> raised wall terrain (T = the wall's front face), used where a wall touches the tile
##   rift   = grass -> rift corruption
##   cobble = grass -> paving (T_RUINS)
## A tile whose corners mix three terrains uses the highest one in that order; the others count as grass.

const ART_PX := 32
const SCALE := 0.5
const CHUNK := 16                  # props are drawn by one node per CHUNK x CHUNK cells (culled when off screen)

var _cfg: Dictionary
var _grid: PackedByteArray
var _w := 0
var _h := 0
var _lookup := {}                  # set name -> {corner key -> Array[Vector2i]}
var _source := {}                  # set name -> TileSet source id
var _sets := {}                    # set name -> Array of {pos: Vector2i, c: String}
var _layer: TileMapLayer


static func has_art(loc_tiles: String) -> bool:
	return GameData.GROUND_ART.has(loc_tiles) and ResourceLoader.exists(String(GameData.GROUND_ART[loc_tiles]["dir"]) + "cobble.png")


func setup(map: Dictionary, loc_tiles: String) -> void:
	_cfg = GameData.GROUND_ART[loc_tiles]
	_grid = map["grid"]
	_w = map["w"]
	_h = map["h"]
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/ground_art.gdshader")
	for k in _cfg.get("grade", {}):
		mat.set_shader_parameter(k, _cfg["grade"][k])
	material = mat
	_build_tileset()
	_paint()
	_scatter_props(map)


# ---------------------------------------------------------------- tiles

func _build_tileset() -> void:
	var dir := String(_cfg["dir"])
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "tiles.json"))
	var ts := TileSet.new()
	ts.tile_size = Vector2i(ART_PX, ART_PX)
	for set_name in ["cobble", "hedge", "rift"]:
		var src := TileSetAtlasSource.new()
		src.texture = load(dir + set_name + ".png")
		src.texture_region_size = Vector2i(ART_PX, ART_PX)
		var table := {}
		var list: Array = []
		for t in meta["sets"][set_name]:
			var pos := Vector2i(int(t["x"]) / ART_PX, int(t["y"]) / ART_PX)
			if src.get_tile_at_coords(pos) == Vector2i(-1, -1):
				src.create_tile(pos)
			var key := "".join(t["c"])
			if not table.has(key):
				table[key] = []
			table[key].append(pos)
			list.append({"pos": pos, "c": key})
		_source[set_name] = ts.add_source(src)
		_lookup[set_name] = table
		_sets[set_name] = list
	_layer = TileMapLayer.new()
	_layer.tile_set = ts
	_layer.scale = Vector2(SCALE, SCALE)
	# dual grid: display tile (i, j) has its corners at the centres of cells (i, j) .. (i + 1, j + 1)
	_layer.position = Vector2.ONE * GameData.TILE * 0.5
	_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_layer.use_parent_material = true
	add_child(_layer)


func _cell(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= _w or y >= _h:
		return GameData.T_WALL
	return _grid[y * _w + x]


## Corner letter for the hedge (raised) set: U = wall top, T = the front face (a wall cell with open ground
## below it), L = ground. The face sits inside the wall cells so the walkable area stays clear.
func _hedge_corner(x: int, y: int) -> String:
	if _cell(x, y) != GameData.T_WALL:
		return "L"
	return "U" if _cell(x, y + 1) == GameData.T_WALL else "T"


func _paint() -> void:
	for j in range(-1, _h):
		for i in range(-1, _w):
			var cs := [_cell(i, j), _cell(i + 1, j), _cell(i, j + 1), _cell(i + 1, j + 1)]
			var set_name := "cobble"
			var key := ""
			if GameData.T_WALL in cs:
				set_name = "hedge"
				key = _hedge_corner(i, j) + _hedge_corner(i + 1, j) + _hedge_corner(i, j + 1) + _hedge_corner(i + 1, j + 1)
			else:
				var up := GameData.T_RUINS
				if GameData.T_RIFT in cs:
					set_name = "rift"
					up = GameData.T_RIFT
				key = ""
				for c in cs:
					key += "U" if c == up else "L"
			var h := _hash(i, j)
			if key == "LLLL":
				# plain grass: any set's grass tile, for variety (they share one base tile)
				var pick: Array = []
				for s in ["cobble", "rift", "hedge"]:
					for p in _lookup[s].get("LLLL", []):
						pick.append([s, p])
				var g: Array = pick[h % pick.size()]
				_layer.set_cell(Vector2i(i, j), _source[g[0]], g[1])
				continue
			var pos := _tile_for(set_name, key, h)
			_layer.set_cell(Vector2i(i, j), _source[set_name], pos)


func _tile_for(set_name: String, key: String, h: int) -> Vector2i:
	var table: Dictionary = _lookup[set_name]
	if table.has(key):
		var opts: Array = table[key]
		return opts[h % opts.size()]
	# no exact tile (a wall one cell thick): the closest corner pattern
	var best_pos := Vector2i.ZERO
	var best := -1.0
	for t in _sets[set_name]:
		var score := 0.0
		for k in 4:
			var a := key[k]
			var b := String(t["c"])[k]
			if a == b:
				score += 1.0
			elif (a == "T" and b == "U") or (a == "U" and b == "T"):
				score += 0.6
			elif (a == "T" and b == "L") or (a == "L" and b == "T"):
				score += 0.3
		if score > best:
			best = score
			best_pos = t["pos"]
	return best_pos


static func _hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663) ^ 0x5bd1e995) % 1000003


# ---------------------------------------------------------------- props

func _scatter_props(map: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(map["effective_seed"]) ^ 0x51ab
	var keep_clear: Array = [map["spawn"], map["portal"]]
	keep_clear.append_array(map["chests"])
	keep_clear.append_array(map["pots"])
	for s in map["shrines"]:
		keep_clear.append(s["cell"])
	var clear_r := float(_cfg["clear_radius"])
	var pdir := String(_cfg["props_dir"])
	var tex := {}
	for group in ["small", "edge", "plaza"]:
		for row in _cfg[group]:
			if not tex.has(row[0]):
				tex[row[0]] = load(pdir + String(row[0]) + ".png")
	var chunks := {}
	for y in _h:
		for x in _w:
			var t := _cell(x, y)
			if t == GameData.T_WALL:
				continue
			var c := Vector2i(x, y)
			var r := rng.randf()
			var group := ""
			if _cell(x, y - 1) == GameData.T_WALL and t != GameData.T_RIFT and r < float(_cfg["edge_chance"]):
				group = "edge"          # tall props stand against the hedge, so they read as part of the wall
			elif t == GameData.T_GRASS and _next_to(x, y, GameData.T_RUINS) and r < float(_cfg["plaza_chance"]):
				group = "plaza"         # lamps and banners line the paved squares
			elif t != GameData.T_RIFT and r < float(_cfg["small_chance"]):
				group = "small"
			if group == "":
				continue
			var near := false
			for k in keep_clear:
				if Vector2(c).distance_to(Vector2(k)) < clear_r:
					near = true
					break
			if near:
				continue
			var name := _weighted(rng, _cfg[group])
			var tx: Texture2D = tex[name]
			var size := tx.get_size() * SCALE
			# anchored at the bottom centre of the cell, nudged a little for a hand-placed feel
			var foot := Vector2(x + 0.5, y + 1.0) * GameData.TILE + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 0))
			if group == "edge":
				foot.y = y * GameData.TILE + 6.0
			var key := Vector2i(x / CHUNK, y / CHUNK)
			if not chunks.has(key):
				chunks[key] = []
			chunks[key].append([tx, Rect2((foot - Vector2(size.x * 0.5, size.y)).round(), size), rng.randf() < 0.5 and group == "small"])
	for key in chunks:
		var n := PropChunk.new()
		n.items = chunks[key]
		n.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		n.use_parent_material = true
		add_child(n)


func _next_to(x: int, y: int, t: int) -> bool:
	return _cell(x - 1, y) == t or _cell(x + 1, y) == t or _cell(x, y - 1) == t or _cell(x, y + 1) == t


static func _weighted(rng: RandomNumberGenerator, rows: Array) -> String:
	var total := 0.0
	for r in rows:
		total += float(r[1])
	var v := rng.randf() * total
	for r in rows:
		v -= float(r[1])
		if v <= 0.0:
			return String(r[0])
	return String(rows[-1][0])


## Static props of one chunk, sorted top to bottom so lower ones overlap the ones behind them.
class PropChunk extends Node2D:
	var items: Array

	func _ready() -> void:
		items.sort_custom(func(a, b): return a[1].end.y < b[1].end.y)

	func _draw() -> void:
		for it in items:
			var r: Rect2 = it[1]
			if it[2]:
				# mirrored copy for variety
				draw_set_transform(Vector2(r.position.x * 2 + r.size.x, 0), 0, Vector2(-1, 1))
				draw_texture_rect(it[0], r, false)
				draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			else:
				draw_texture_rect(it[0], r, false)
