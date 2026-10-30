class_name Pickups
extends Node2D
## XP gems, gold coins and small heals dropped on the ground.

enum Kind { XP, GOLD, HEAL }
const MAX_PICKUPS := 500
const COLLECT_DIST := 8.0

var game: Node
var list: Array = []  # {pos, kind, value, pulled, speed}


func drop(pos: Vector2, kind: int, value: float) -> void:
	if list.size() >= MAX_PICKUPS and kind == Kind.XP:
		# merge into an existing gem instead of growing forever
		for p in list:
			if p["kind"] == Kind.XP:
				p["value"] += value
				return
	list.append({"pos": pos + Vector2(randf_range(-4, 4), randf_range(-4, 4)), "kind": kind, "value": value, "pulled": false, "speed": 0.0})


## Aether Well: pull every XP gem on the map to the player.
func pull_all_xp() -> int:
	var n := 0
	for p in list:
		if p["kind"] == Kind.XP:
			p["pulled"] = true
			n += 1
	return n


func _process(delta: float) -> void:
	var player: Player = game.player
	var r := player.pickup_radius()
	for p in list:
		var d: float = p["pos"].distance_to(player.position)
		if p["pulled"] or d < r:
			p["pulled"] = true
			p["speed"] = min(p["speed"] + 600.0 * delta, 400.0)
			p["pos"] = p["pos"].move_toward(player.position, p["speed"] * delta)
			if p["pos"].distance_to(player.position) < COLLECT_DIST:
				game.on_pickup(p["kind"], p["value"])
				p["kind"] = -1
	list = list.filter(func(p): return p["kind"] != -1)
	queue_redraw()


func _draw() -> void:
	var cam: Vector2 = game.player.position
	for p in list:
		var pos: Vector2 = p["pos"]
		if absf(pos.x - cam.x) > 400 or absf(pos.y - cam.y) > 260:
			continue
		match p["kind"]:
			Kind.XP:
				var big: bool = p["value"] >= 5
				var c := Color(0.95, 0.4, 1.0) if big else Color(0.4, 0.75, 1.0)
				var s := 3.5 if big else 2.5
				draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -s), pos + Vector2(s * 0.7, 0), pos + Vector2(0, s), pos + Vector2(-s * 0.7, 0)]), c)
			Kind.GOLD:
				draw_circle(pos, 2.5, Color(1.0, 0.8, 0.2))
				draw_circle(pos + Vector2(-0.5, -0.5), 1.0, Color(1.0, 0.95, 0.6))
			Kind.HEAL:
				draw_rect(Rect2(pos.x - 3, pos.y - 1, 6, 2), Color(1, 0.35, 0.4))
				draw_rect(Rect2(pos.x - 1, pos.y - 3, 2, 6), Color(1, 0.35, 0.4))
