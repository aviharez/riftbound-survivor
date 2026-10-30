class_name Projectiles
extends Node2D
## Player magic bolts. A bolt that hits with bounces left jumps to the nearest other enemy.

const SPEED := 260.0
const LIFE := 1.2
const BOUNCE_RANGE := 140.0
const HIT_RADIUS := 4.0

var game: Node
var list: Array = []  # {pos, vel, dmg, bounces, life, size, last, trail}


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat


func fire(from: Vector2, dir: Vector2, damage_amount: float, bounces: int, size: float) -> void:
	list.append({"pos": from, "vel": dir * SPEED, "dmg": damage_amount, "bounces": bounces, "life": LIFE, "size": size, "last": null, "trail": 0.0})


func _process(delta: float) -> void:
	var player: Player = game.player
	for p in list:
		p["pos"] += p["vel"] * delta
		p["life"] -= delta
		p["trail"] -= delta
		if p["trail"] <= 0.0:
			p["trail"] = 0.025
			game.vfx.trail(p["pos"], Color(0.5, 1.6, 2.2), 2.2 * p["size"], 0.22)
		if game.world.is_solid_at(p["pos"]):
			p["life"] = 0.0
			game.vfx.sparks(p["pos"], Color(0.6, 1.6, 2.0), 4, 70.0, 0.2, 1.0)
			continue
		var hit = game.enemies.nearest(p["pos"], HIT_RADIUS * p["size"] + 2.0, p["last"])
		if hit == null:
			continue
		var crit := randf() < float(player.stats["crit"])
		game.enemies.damage(hit, p["dmg"] * (2.0 if crit else 1.0), crit)
		game.vfx.hit(p["pos"], Color(0.7, 2.0, 2.6), crit)
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


func _draw() -> void:
	var tex: Texture2D = game.vfx.glow_tex
	for p in list:
		var s: float = p["size"]
		var pos: Vector2 = p["pos"]
		var back: Vector2 = p["vel"].normalized()
		draw_texture_rect(tex, Rect2(pos - Vector2(10, 10) * s, Vector2(20, 20) * s), false, Color(0.3, 1.1, 1.6, 0.9))
		draw_line(pos, pos - back * 9.0 * s, Color(0.5, 1.6, 2.2, 0.8), 2.5 * s)
		draw_circle(pos, 2.4 * s, Color(1.0, 2.4, 2.8))
		draw_circle(pos, 1.2 * s, Color(2.8, 2.8, 2.8))
