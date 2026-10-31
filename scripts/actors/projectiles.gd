class_name Projectiles
extends Node2D
## Player magic bolts. A bolt that hits with bounces left jumps to the nearest other enemy.

const SPEED := 260.0
const LIFE := 1.2
const BOUNCE_RANGE := 140.0
const HIT_RADIUS := 4.0

var game: Node
var list: Array = []  # {pos, vel, dmg, bounces, life, size, last, trail}


var _light: Node2D   # additive child that draws the light layer on top


func _ready() -> void:
	_light = Node2D.new()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_light.material = mat
	_light.draw.connect(func(): _draw_layer(_light, "light"))
	add_child(_light)


func fire(from: Vector2, dir: Vector2, damage_amount: float, bounces: int, size: float) -> void:
	list.append({"pos": from, "vel": dir * SPEED, "dmg": damage_amount, "bounces": bounces, "life": LIFE, "size": size, "last": null, "trail": 0.0})


func _process(delta: float) -> void:
	var player: Player = game.player
	for p in list:
		p["pos"] += p["vel"] * delta
		p["life"] -= delta
		if game.world.is_solid_at(p["pos"]):
			p["life"] = 0.0
			game.vfx.sparks(p["pos"], Color(0.6, 1.6, 2.0), 4, 70.0, 0.2, 1.0)
			continue
		var hit = game.enemies.nearest(p["pos"], HIT_RADIUS * p["size"] + 2.0, p["last"])
		if hit == null:
			continue
		var crit := randf() < float(player.stats["crit"])
		game.enemies.damage(hit, p["dmg"] * (2.0 if crit else 1.0), crit)
		if crit:
			game.vfx.play("crit_hit", p["pos"], p["vel"].angle(), 0.26)
		else:
			game.vfx.play("hit_spark", p["pos"], p["vel"].angle(), 0.32)
		if p["bounces"] > 0:
			p["bounces"] -= 1
			p["last"] = hit
			p["life"] = LIFE
			var nxt = game.enemies.nearest(p["pos"], BOUNCE_RANGE, hit)
			if nxt != null:
				p["vel"] = (nxt.pos - p["pos"]).normalized() * SPEED
		else:
			p["life"] = 0.0
	list = list.filter(func(p): return p["life"] > 0.0)
	queue_redraw()


var _anim_t := 0.0


func _draw() -> void:
	_anim_t += get_process_delta_time()
	_draw_layer(self, "color")
	_light.queue_redraw()


## The arcane-bolt effect faces right; rotating it to the velocity keeps the trail straight behind the head.
func _draw_layer(ci: CanvasItem, layer: String) -> void:
	var def := Vfx.fx_def("arcane_bolt")
	if def.is_empty():
		return
	var region := Vfx.frame_region(def, _anim_t)
	var tint := Color(1.6, 1.6, 1.6) if layer == "light" else Color.WHITE
	for p in list:
		var s: float = 0.6 * p["size"]
		ci.draw_set_transform(p["pos"], p["vel"].angle(), Vector2(s, s))
		ci.draw_texture_rect_region(def[layer], Rect2(-def["pivot"], def["size"]), region, tint)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
