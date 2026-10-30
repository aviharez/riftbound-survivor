class_name Projectiles
extends Node2D
## Player magic bolts. A bolt that hits with bounces left jumps to the nearest other enemy.

const SPEED := 260.0
const LIFE := 1.2
const BOUNCE_RANGE := 140.0
const HIT_RADIUS := 4.0

var game: Node
var list: Array = []  # {pos, vel, dmg, bounces, life, size, last}


func fire(from: Vector2, dir: Vector2, damage_amount: float, bounces: int, size: float) -> void:
	list.append({"pos": from, "vel": dir * SPEED, "dmg": damage_amount, "bounces": bounces, "life": LIFE, "size": size, "last": null})


func _process(delta: float) -> void:
	var player: Player = game.player
	for p in list:
		p["pos"] += p["vel"] * delta
		p["life"] -= delta
		if game.world.is_solid_at(p["pos"]):
			p["life"] = 0.0
			continue
		var hit = game.enemies.nearest(p["pos"], HIT_RADIUS * p["size"] + 2.0, p["last"])
		if hit == null:
			continue
		var crit := randf() < float(player.stats["crit"])
		game.enemies.damage(hit, p["dmg"] * (2.0 if crit else 1.0), crit)
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
	for p in list:
		var s: float = p["size"]
		draw_line(p["pos"], p["pos"] - p["vel"].normalized() * 7.0 * s, Color(0.4, 0.9, 1.0, 0.5), 2.0 * s)
		draw_circle(p["pos"], 3.0 * s, Color(0.4, 0.95, 1.0))
		draw_circle(p["pos"], 1.5 * s, Color(1, 1, 1))
