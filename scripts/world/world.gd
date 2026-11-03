class_name World
extends Node2D
## Renders the generated map, answers collision queries, and keeps a local
## flow field (BFS distance to the player) so enemies walk around walls.

const PX_PER_TILE := 8          # baked texture resolution; drawn at 2x => 16 px tiles
const FLOW_R := 40              # flow field half-size in tiles (81x81 window)

var map: Dictionary
var grid: PackedByteArray
var w := 0
var h := 0
var ground_texture: ImageTexture
var minimap_image: Image
var minimap_texture: ImageTexture

var _flow := PackedInt32Array()
var _flow_origin := Vector2i.ZERO
var _flow_size := FLOW_R * 2 + 1


var _ground_mat: ShaderMaterial
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	if _ground_mat != null:
		_ground_mat.set_shader_parameter("time", _time)


var tiles: Dictionary = GameData.TILESETS["courtyard"]
var art: GroundArt


func setup(m: Dictionary, tiles_id := "courtyard") -> void:
	tiles = GameData.TILESETS.get(tiles_id, GameData.TILESETS["courtyard"])
	_ground_mat = ShaderMaterial.new()
	_ground_mat.shader = load("res://shaders/rift_ground.gdshader")
	material = _ground_mat
	map = m
	grid = m["grid"]
	w = m["w"]
	h = m["h"]
	_bake_textures(int(m["effective_seed"]))
	# painted PixelLab ground (tilesets + props) where the location has art; the baked texture stays for the minimap
	art = null
	if GroundArt.has_art(tiles_id):
		material = null
		art = GroundArt.new()
		add_child(art)
		art.setup(m, tiles_id)
		# the minimap follows the painted ground: paved / rift cells without their own tiles read as plain ground
		var plain := Color(tiles["floor"]).lightened(0.05)
		for y in h:
			for x in w:
				var t := grid[y * w + x]
				if (t == GameData.T_RUINS and not art.has_set("cobble")) or (t == GameData.T_RIFT and not art.has_set("rift")):
					minimap_image.set_pixel(x, y, plain)
		minimap_texture.update(minimap_image)
	_flow.resize(_flow_size * _flow_size)
	queue_redraw()


func _draw() -> void:
	if art != null:
		return
	draw_texture_rect(ground_texture, Rect2(0, 0, w * GameData.TILE, h * GameData.TILE), false)


func _bake_textures(s: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	var img := Image.create(w * PX_PER_TILE, h * PX_PER_TILE, false, Image.FORMAT_RGBA8)
	minimap_image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var p := PX_PER_TILE
	for y in h:
		for x in w:
			var t := grid[y * w + x]
			var r := Rect2i(x * p, y * p, p, p)
			var v := rng.randf_range(-0.03, 0.03)
			var T := tiles
			match t:
				GameData.T_WALL:
					var base: Color = T["wall"]
					img.fill_rect(r, base.lightened(v))
					if T["style"] == "planks":
						# bookshelves: coloured spines in rows
						for row in 2:
							for k in 3:
								if rng.randf() < 0.8:
									var spine := Color.from_hsv(rng.randf(), 0.5, 0.45)
									img.fill_rect(Rect2i(x * p + 1 + k * 2, y * p + 1 + row * 4, 1, 3), spine)
					elif T["style"] == "sparkle" and rng.randf() < 0.25:
						img.fill_rect(Rect2i(x * p + rng.randi_range(1, 5), y * p + rng.randi_range(2, 5), 2, 2), T["wall_top"])
					elif T["style"] == "leaves" and rng.randf() < 0.5:
						img.fill_rect(Rect2i(x * p + rng.randi_range(0, 5), y * p + rng.randi_range(0, 5), 3, 2), Color(T["wall_top"]).darkened(0.25))
					# lit top edge where the wall faces open floor below
					if y + 1 < h and grid[(y + 1) * w + x] != GameData.T_WALL:
						img.fill_rect(Rect2i(x * p, y * p + p - 2, p, 2), T["wall_shade"])
					if y > 0 and grid[(y - 1) * w + x] != GameData.T_WALL:
						img.fill_rect(Rect2i(x * p, y * p, p, 2), T["wall_top"])
					minimap_image.set_pixel(x, y, Color(base).lightened(0.25))
				GameData.T_RUINS:
					img.fill_rect(r, Color(T["deco"]).lightened(v))
					if rng.randf() < 0.5:
						img.fill_rect(Rect2i(x * p, y * p, p, 1), T["deco_line"])
						img.fill_rect(Rect2i(x * p, y * p, 1, p), T["deco_line"])
					minimap_image.set_pixel(x, y, Color(T["deco"]).lightened(0.15))
				GameData.T_RIFT:
					img.fill_rect(r, Color(T["rift"]).lightened(v))
					img.fill_rect(Rect2i(x * p + rng.randi_range(1, 4), y * p + rng.randi_range(1, 4), 3, 1), GameData.RIFT_CRACK)
					minimap_image.set_pixel(x, y, Color(0.4, 0.3, 0.5))
				_:
					img.fill_rect(r, Color(T["floor"]).lightened(v))
					match String(T["style"]):
						"planks":
							img.fill_rect(Rect2i(x * p, y * p + (3 if x % 2 == 0 else 7), p, 1), T["floor_dot"])
						"sparkle":
							if rng.randf() < 0.12:
								img.set_pixel(x * p + rng.randi_range(0, 7), y * p + rng.randi_range(0, 7), T["floor_dot"])
						"void":
							if rng.randf() < 0.18:
								img.fill_rect(Rect2i(x * p + rng.randi_range(0, 6), y * p + rng.randi_range(0, 6), 2, 1), T["floor_dot"])
						"leaves":
							if rng.randf() < 0.4:
								img.fill_rect(Rect2i(x * p + rng.randi_range(0, 6), y * p + rng.randi_range(0, 6), 2, 1), T["floor_dot"])
						_:
							if rng.randf() < 0.35:
								img.fill_rect(Rect2i(x * p + rng.randi_range(0, 6), y * p + rng.randi_range(0, 6), 1, 2), T["floor_dot"])
					minimap_image.set_pixel(x, y, Color(T["floor"]).lightened(0.05))
	ground_texture = ImageTexture.create_from_image(img)
	minimap_texture = ImageTexture.create_from_image(minimap_image)


# ---------------------------------------------------------------- queries

func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / GameData.TILE), floori(p.y / GameData.TILE))


func cell_center(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * GameData.TILE


func is_solid_cell(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= w or y >= h:
		return true
	return grid[y * w + x] == GameData.T_WALL


func is_solid_at(p: Vector2) -> bool:
	return is_solid_cell(floori(p.x / GameData.TILE), floori(p.y / GameData.TILE))


func box_hits(p: Vector2, r: float) -> bool:
	return is_solid_at(p + Vector2(-r, -r)) or is_solid_at(p + Vector2(r, -r)) \
		or is_solid_at(p + Vector2(-r, r)) or is_solid_at(p + Vector2(r, r))


## Axis-separated movement with wall sliding.
func move(pos: Vector2, motion: Vector2, r: float) -> Vector2:
	var np := pos
	np.x += motion.x
	if box_hits(np, r):
		np.x = pos.x
	np.y += motion.y
	if box_hits(np, r):
		np.y = pos.y
	return np


func world_size() -> Vector2:
	return Vector2(w, h) * GameData.TILE


# ---------------------------------------------------------------- flow field

func update_flow(target: Vector2) -> void:
	var tc := cell_of(target)
	_flow_origin = tc - Vector2i(FLOW_R, FLOW_R)
	_flow.fill(-1)
	var start := _local_index(tc)
	if start < 0:
		return
	var queue := PackedInt32Array()
	queue.append(start)
	_flow[start] = 0
	var head := 0
	var n := _flow_size
	while head < queue.size():
		var li: int = queue[head]
		head += 1
		var lx := li % n
		var ly := li / n
		var d: int = _flow[li] + 1
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: int = lx + dir.x
			var ny: int = ly + dir.y
			if nx < 0 or ny < 0 or nx >= n or ny >= n:
				continue
			var ni := ny * n + nx
			if _flow[ni] != -1:
				continue
			if is_solid_cell(_flow_origin.x + nx, _flow_origin.y + ny):
				_flow[ni] = -2
				continue
			_flow[ni] = d
			queue.append(ni)


## Direction to walk from p toward the flow target, or ZERO when the caller
## should steer directly (very close, or outside the flow window).
func flow_dir(p: Vector2) -> Vector2:
	var c := cell_of(p)
	var li := _local_index(c)
	if li < 0:
		return Vector2.ZERO
	var here: int = _flow[li]
	if here <= 1:
		return Vector2.ZERO
	var best := here
	var best_cell := c
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		var nc: Vector2i = c + dir
		var nli := _local_index(nc)
		if nli < 0:
			continue
		var d: int = _flow[nli]
		if d < 0 or d >= best:
			continue
		# no corner cutting on diagonals
		if dir.x != 0 and dir.y != 0 and (is_solid_cell(c.x + dir.x, c.y) or is_solid_cell(c.x, c.y + dir.y)):
			continue
		best = d
		best_cell = nc
	if best_cell == c:
		return Vector2.ZERO
	return (cell_center(best_cell) - p).normalized()


func _local_index(c: Vector2i) -> int:
	var l := c - _flow_origin
	if l.x < 0 or l.y < 0 or l.x >= _flow_size or l.y >= _flow_size:
		return -1
	return l.y * _flow_size + l.x
