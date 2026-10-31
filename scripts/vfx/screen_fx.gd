class_name ScreenFx
extends Node
## Screen-level juice: HDR glow environment, post-process shader (shockwaves,
## chromatic aberration, damage vignette), camera shake and hit-stop.

const POST_SHADER := preload("res://shaders/post_fx.gdshader")

var game: Node
var _rect: ColorRect
var _mat: ShaderMaterial
var _waves: Array = []   # {pos (world), t, life, radius (px), strength}
var _trauma := 0.0       # 0..1, shake = trauma^2
var _chroma := 0.0
var _hurt := 0.0
var _hitstop := 0.0
var _time := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if GameData.VFX_GLOW:
		var env := Environment.new()
		env.background_mode = Environment.BG_CANVAS
		env.glow_enabled = true
		env.glow_intensity = GameData.VFX_GLOW_INTENSITY
		env.glow_strength = 1.0
		env.glow_bloom = 0.0
		env.glow_hdr_threshold = GameData.VFX_GLOW_THRESHOLD
		env.glow_hdr_scale = 1.5
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
		for i in 7:
			env.set_glow_level(i, i >= 1 and i <= 4)
		var we := WorldEnvironment.new()
		we.environment = env
		add_child(we)
	var layer := CanvasLayer.new()
	layer.layer = 5   # above the world, below the HUD (10)
	add_child(layer)
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = POST_SHADER
	_rect.material = _mat
	layer.add_child(_rect)


## World-space shockwave (distorts the screen around it).
func shockwave(world_pos: Vector2, radius: float, strength := 1.0, life := 0.45) -> void:
	if _waves.size() >= 4:
		_waves.pop_front()
	_waves.append({"pos": world_pos, "t": 0.0, "life": life, "radius": radius, "strength": strength})


func shake(amount: float) -> void:
	_trauma = min(1.0, _trauma + amount)


func chroma(amount: float) -> void:
	_chroma = min(1.0, _chroma + amount)


func hurt() -> void:
	_hurt = 1.0
	chroma(0.6)
	shake(0.35)


## Freezes gameplay for a few real-time milliseconds to sell big hits.
func hitstop(seconds: float) -> void:
	if game.hud.map_open or get_tree().paused:
		return
	_hitstop = max(_hitstop, seconds)
	Engine.time_scale = 0.05


func _process(delta: float) -> void:
	# real time, independent of Engine.time_scale (hit-stop, map slow-mo)
	var dt: float = min(delta / max(Engine.time_scale, 0.001), 0.05)
	_time += dt
	if _hitstop > 0.0:
		_hitstop -= dt
		if _hitstop <= 0.0 and not game.hud.map_open:
			Engine.time_scale = 1.0
	_trauma = max(0.0, _trauma - dt * 1.6)
	_chroma = max(0.0, _chroma - dt * 2.0)
	_hurt = max(0.0, _hurt - dt * 2.5)

	var cam: Camera2D = game.camera
	var s := _trauma * _trauma * GameData.VFX_SHAKE
	cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 7.0 * s

	var vp := get_viewport()
	var vs := vp.get_visible_rect().size
	var xf := vp.get_canvas_transform()
	var packed: Array = []
	for w in _waves:
		w["t"] += dt
	_waves = _waves.filter(func(w): return w["t"] < w["life"])
	for i in 4:
		if i < _waves.size():
			var w: Dictionary = _waves[i]
			var k: float = w["t"] / w["life"]
			var sp: Vector2 = xf * w["pos"]
			packed.append(Vector4(sp.x / vs.x, sp.y / vs.y, (w["radius"] * (0.2 + 0.8 * k)) / vs.y, w["strength"] * (1.0 - k)))
		else:
			packed.append(Vector4.ZERO)
	_mat.set_shader_parameter("waves", packed)
	_mat.set_shader_parameter("aspect", vs.x / vs.y)
	_mat.set_shader_parameter("chroma", _chroma)
	_mat.set_shader_parameter("vignette", _hurt)
	var p: Player = game.player
	_mat.set_shader_parameter("danger", clamp(1.0 - (p.hp / p.stats["max_hp"]) / 0.3, 0.0, 1.0))
	_mat.set_shader_parameter("time", _time)
