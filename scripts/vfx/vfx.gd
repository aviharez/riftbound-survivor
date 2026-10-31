class_name Vfx
extends Node2D
## Data-oriented particle and light system. One node draws everything with
## additive blending; colours above 1.0 feed the HDR glow (bloom).
## Presets live in GameData.VFX_* tables; this file only simulates and draws.

enum Shape { DOT, GLOW, STREAK, RING, SHARD }

const MAX_PARTICLES := 1800

var game: Node
var list: Array = []   # particle dictionaries (see _spawn)
var glow_tex: Texture2D
var _quality := 1.0     # 0.5 on low quality: halves particle counts


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	glow_tex = make_glow_texture()
	_quality = GameData.VFX_PARTICLE_SCALE


static func make_glow_texture() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.25, Color(1, 1, 1, 0.55))
	g.add_point(0.6, Color(1, 1, 1, 0.12))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t


# ------------------------------------------------------------------ spawning

func _spawn(pos: Vector2, vel: Vector2, life: float, size: float, c0: Color, c1: Color, shape: int, drag := 2.0, grow := 0.0, gravity := 0.0) -> void:
	if list.size() >= MAX_PARTICLES:
		return
	list.append({"pos": pos, "vel": vel, "t": 0.0, "life": life, "size": size, "c0": c0, "c1": c1,
		"shape": shape, "drag": drag, "grow": grow, "grav": gravity, "rot": randf() * TAU})


func _n(count: int) -> int:
	return maxi(1, int(round(count * _quality)))


## Radial spray of sparks / streaks.
func sparks(pos: Vector2, color: Color, count: int, speed: float, life := 0.35, size := 1.5) -> void:
	for i in _n(count):
		var v := Vector2.from_angle(randf() * TAU) * speed * randf_range(0.35, 1.0)
		_spawn(pos, v, life * randf_range(0.6, 1.2), size * randf_range(0.7, 1.3), color, Color(color, 0.0), Shape.STREAK, 5.0)


## Soft glowing motes drifting outward / upward.
func motes(pos: Vector2, color: Color, count: int, speed: float, life := 0.6, size := 3.0, gravity := -20.0) -> void:
	for i in _n(count):
		var v := Vector2.from_angle(randf() * TAU) * speed * randf_range(0.2, 1.0)
		_spawn(pos + Vector2(randf_range(-3, 3), randf_range(-3, 3)), v, life * randf_range(0.6, 1.3), size * randf_range(0.6, 1.4),
			color, Color(color.r * 0.6, color.g * 0.4, color.b * 0.8, 0.0), Shape.GLOW, 3.0, -0.5, gravity)


## Big short-lived light: sells every impact and explosion with bloom.
func flash(pos: Vector2, color: Color, radius: float, life := 0.18) -> void:
	# kept translucent so a flash lights the scene without hiding the sprites under it
	var c := Color(color.r, color.g, color.b, 0.45)
	_spawn(pos, Vector2.ZERO, life, radius * 0.8, c, Color(c, 0.0), Shape.GLOW, 0.0, 0.5)


func ring(pos: Vector2, color: Color, radius: float, life := 0.35, width := 2.0) -> void:
	_spawn(pos, Vector2.ZERO, life, width, color, Color(color, 0.0), Shape.RING, 0.0, radius)


func shards(pos: Vector2, color: Color, count: int, speed: float, life := 0.45) -> void:
	for i in _n(count):
		var v := Vector2.from_angle(randf() * TAU) * speed * randf_range(0.5, 1.0)
		_spawn(pos, v, life * randf_range(0.7, 1.2), randf_range(2.0, 3.5), color, Color(color, 0.0), Shape.SHARD, 4.0)


## Single trail mote, called every frame by moving effects.
func trail(pos: Vector2, color: Color, size := 2.5, life := 0.25) -> void:
	_spawn(pos, Vector2(randf_range(-6, 6), randf_range(-6, 6)), life, size, color, Color(color, 0.0), Shape.GLOW, 1.0, -0.6)


# ------------------------------------------------------------------ presets

func hit(pos: Vector2, color: Color, crit := false) -> void:
	sparks(pos, color, 7 if crit else 4, 120.0 if crit else 80.0, 0.22)
	flash(pos, color * (1.6 if crit else 1.0), 14.0 if crit else 9.0, 0.1)


func death(pos: Vector2, color: Color, radius: float, elite := false) -> void:
	var hot := Color(color.r * 2.2, color.g * 2.2, color.b * 2.2, 1.0)
	sparks(pos, hot, 10 if elite else 5, 110.0, 0.35)
	motes(pos, Color(0.9, 0.4, 1.6), 6 if elite else 2, 30.0, 0.8, 2.5, -40.0)  # rift soul wisps
	flash(pos, hot * 0.6, radius * (3.0 if elite else 2.0), 0.16)
	if elite:
		ring(pos, Color(2.0, 0.6, 0.4), radius * 4.0, 0.45, 3.0)
		shards(pos, Color(1.6, 0.4, 0.3), 12, 160.0)


func explosion(pos: Vector2, color: Color, radius: float) -> void:
	flash(pos, color * 1.8, radius * 1.6, 0.22)
	ring(pos, color * 1.5, radius * 1.2, 0.35, 3.0)
	sparks(pos, color * 2.0, 18, radius * 6.0, 0.4, 2.0)
	motes(pos, color, 10, radius * 2.0, 0.7, 4.0, -15.0)


# ------------------------------------------------------------------ simulate / draw

func _process(delta: float) -> void:
	for p in list:
		p["t"] += delta
		var d: float = p["drag"]
		p["vel"] = p["vel"] * max(0.0, 1.0 - d * delta)
		p["vel"].y += p["grav"] * delta
		p["pos"] += p["vel"] * delta
	list = list.filter(func(p): return p["t"] < p["life"])
	queue_redraw()


func _draw() -> void:
	var cam: Vector2 = game.player.position
	for p in list:
		var pos: Vector2 = p["pos"]
		if absf(pos.x - cam.x) > 380.0 or absf(pos.y - cam.y) > 230.0:
			continue
		var k: float = p["t"] / p["life"]
		var col: Color = p["c0"].lerp(p["c1"], k)
		match p["shape"]:
			Shape.GLOW:
				var s: float = p["size"] * (1.0 + p["grow"] * k) * 2.0
				draw_texture_rect(glow_tex, Rect2(pos - Vector2(s, s), Vector2(s, s) * 2.0), false, col)
			Shape.STREAK:
				var v: Vector2 = p["vel"]
				var tail := v * 0.035 if v.length() > 1.0 else Vector2.RIGHT
				draw_line(pos - tail, pos, col, p["size"])
			Shape.RING:
				var r: float = p["grow"] * (0.25 + 0.75 * sqrt(k))
				draw_arc(pos, r, 0, TAU, 40, col, p["size"] * (1.0 - k * 0.6))
			Shape.SHARD:
				var a: float = p["rot"] + k * 6.0
				var s2: float = p["size"]
				draw_colored_polygon(PackedVector2Array([pos + Vector2.from_angle(a) * s2 * 1.6, pos + Vector2.from_angle(a + 2.3) * s2 * 0.6, pos + Vector2.from_angle(a - 2.3) * s2 * 0.6]), col)
			_:
				draw_circle(pos, p["size"], col)
