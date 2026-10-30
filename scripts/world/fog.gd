class_name Fog
extends RefCounted
## Fog-of-war for the minimap / full map. 1 fog cell = 4x4 tiles.
## Revealed cells stay revealed for the whole run.

const CELL := 4

var cw := 0
var ch := 0
var revealed := PackedByteArray()
var image: Image          # map-sized (1 px per tile): opaque dark = unexplored
var texture: ImageTexture
var revealed_count := 0


func setup(map_w: int, map_h: int) -> void:
	cw = ceili(float(map_w) / CELL)
	ch = ceili(float(map_h) / CELL)
	revealed.resize(cw * ch)
	revealed.fill(0)
	image = Image.create(map_w, map_h, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.03, 0.03, 0.07, 1.0))
	texture = ImageTexture.create_from_image(image)


## Returns true when at least one new cell was revealed.
func reveal(world_pos: Vector2, radius_tiles: float) -> bool:
	var t := world_pos / GameData.TILE
	var r_cells := ceili(radius_tiles / CELL) + 1
	var center := Vector2i(floori(t.x / CELL), floori(t.y / CELL))
	var changed := false
	for cy in range(center.y - r_cells, center.y + r_cells + 1):
		for cx in range(center.x - r_cells, center.x + r_cells + 1):
			if cx < 0 or cy < 0 or cx >= cw or cy >= ch:
				continue
			var i := cy * cw + cx
			if revealed[i] == 1:
				continue
			var cell_mid := (Vector2(cx, cy) + Vector2(0.5, 0.5)) * CELL
			if cell_mid.distance_to(t) <= radius_tiles:
				revealed[i] = 1
				revealed_count += 1
				image.fill_rect(Rect2i(cx * CELL, cy * CELL, CELL, CELL), Color(0, 0, 0, 0))
				changed = true
	if changed:
		texture.update(image)
	return changed


func is_revealed_world(p: Vector2) -> bool:
	var t := p / GameData.TILE
	var cx := floori(t.x / CELL)
	var cy := floori(t.y / CELL)
	if cx < 0 or cy < 0 or cx >= cw or cy >= ch:
		return false
	return revealed[cy * cw + cx] == 1


func explored_ratio() -> float:
	return float(revealed_count) / float(cw * ch)
