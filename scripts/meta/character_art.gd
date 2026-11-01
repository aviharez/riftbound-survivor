class_name CharacterArt
extends RefCounted
## Loads 8-direction character sprites from res://assets/characters/<id>/<direction>.png
## (south, south-east, east, north-east, north, north-west, west, south-west).
## Returns null when a sprite is missing, so callers fall back to placeholder drawing.
## Animations: res://assets/characters/<id>/<anim>/<direction>.png, a horizontal strip of square frames
## (`walk`, `idle`); frames() returns [] when the strip is missing (callers use the static sprite).

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


static var _anim_cache := {}


static func frames(id: String, anim: String, dir: String) -> Array:
	var key := id + "/" + anim + "/" + dir
	if _anim_cache.has(key):
		return _anim_cache[key]
	var out: Array = []
	var path := "res://assets/characters/%s/%s/%s.png" % [id, anim, dir]
	if ResourceLoader.exists(path):
		var strip: Texture2D = load(path)
		var h := strip.get_height()
		for i in strip.get_width() / h:
			var at := AtlasTexture.new()
			at.atlas = strip
			at.region = Rect2(i * h, 0, h, h)
			out.append(at)
	_anim_cache[key] = out
	return out


## Frame of an animation at time t (seconds), or the static sprite when the animation is missing.
static func frame_at(id: String, anim: String, dir: String, t: float, fps: float) -> Texture2D:
	var f := frames(id, anim, dir)
	if f.is_empty():
		return texture(id, dir)
	return f[int(t * fps) % f.size()]


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
