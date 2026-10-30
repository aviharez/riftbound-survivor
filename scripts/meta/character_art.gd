class_name CharacterArt
extends RefCounted
## Loads 8-direction character sprites from res://assets/characters/<id>/<direction>.png
## (south, south-east, east, north-east, north, north-west, west, south-west).
## Returns null when a sprite is missing, so callers fall back to placeholder drawing.

const DIRS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]

static var _cache := {}


static func texture(id: String, dir: String) -> Texture2D:
	var key := id + "/" + dir
	if _cache.has(key):
		return _cache[key]
	var path := "res://assets/characters/%s/%s.png" % [id, dir]
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_cache[key] = tex
	return tex


## Direction name for a facing vector (8-way).
static func dir_for(v: Vector2) -> String:
	if v.length() < 0.01:
		return "south"
	var idx := int(round(v.angle() / (TAU / 8.0))) % 8
	if idx < 0:
		idx += 8
	return DIRS[idx]


static func portrait(id: String) -> Texture2D:
	return texture(id, "south")
