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


func setup(m: Dictionary) -> void:
	map = m
	grid = m["grid"]
	w = m["w"]
	h = m["h"]
	_bake_textures(int(m["effective_seed"]))
	_flow.resize(_flow_size * _flow_size)
	queue_redraw()


func _draw() -> void:
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
			match t:
				GameData.T_WALL:
					var base := Color(0.2, 0.2, 0.27)
					img.fill_rect(r, base.lightened(v))
					# lit top edge where the wall faces open floor below
					if y + 1 < h and grid[(y + 1) * w + x] != GameData.T_WALL:
						img.fill_rect(Rect2i(x * p, y * p + p - 2, p, 2), Color(0.12, 0.12, 0.16))
					if y > 0 and grid[(y - 1) * w + x] != GameData.T_WALL:
						img.fill_rect(Rect2i(x * p, y * p, p, 2), Color(0.38, 0.38, 0.48))
					minimap_image.set_pixel(x, y, Color(0.32, 0.32, 0.42))
				GameData.T_RUINS:
					img.fill_rect(r, Color(0.42, 0.42, 0.45).lightened(v))
					if rng.randf() < 0.5:
						img.fill_rect(Rect2i(x * p, y * p, p, 1), Color(0.35, 0.35, 0.38))
						img.fill_rect(Rect2i(x * p, y * p, 1, p), Color(0.35, 0.35, 0.38))
					minimap_image.set_pixel(x, y, Color(0.5, 0.5, 0.55))
				GameData.T_RIFT:
					img.fill_rect(r, Color(0.24, 0.36, 0.2).lightened(v))
					img.fill_rect(Rect2i(x * p + rng.randi_range(1, 4), y * p + rng.randi_range(1, 4), 3, 1), Color(0.75, 0.25, 0.95))
					minimap_image.set_pixel(x, y, Color(0.4, 0.3, 0.5))
				_:
					img.fill_rect(r, Color(0.27, 0.42, 0.22).lightened(v))
					if rng.randf() < 0.35:
						img.fill_rect(Rect2i(x * p + rng.randi_range(0, 6), y * p + rng.randi_range(0, 6), 1, 2), Color(0.36, 0.55, 0.28))
					minimap_image.set_pixel(x, y, Color(0.3, 0.45, 0.26))
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
