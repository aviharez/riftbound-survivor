class_name Weapons
extends Node2D
## Fires every weapon the player owns. Numbers come from GameData.WEAPONS;
## this file only holds each weapon's behaviour and its visual effect.

var game: Node
var _cd := {}          # weapon id -> seconds until next use
var _time := 0.0
var _orbs: Array = []  # world positions of Flame Orbs this frame (for drawing)
var _fx: Array = []    # short-lived visuals: {kind, t, life, ...}


func level_damage(w: Dictionary, lv: int) -> float:
	return game.player.dmg() * float(w["dmg"]) * (1.0 + float(w["lvl_dmg"]) * (lv - 1))


func level_cooldown(w: Dictionary, lv: int) -> float:
	return float(w["cd"]) / (1.0 + float(w["lvl_cd"]) * (lv - 1)) / (1.0 + game.player.stats["attack_speed_pct"])


func level_size(w: Dictionary, lv: int) -> float:
	return (1.0 + float(w["lvl_area"]) * (lv - 1)) * game.player.area()


func count_of(w: Dictionary, lv: int) -> int:
	return GameData.weapon_count(w, lv, int(game.player.stats["projectiles"]))


func _process(delta: float) -> void:
	_time += delta
	_orbs.clear()
	var p: Player = game.player
	for id in p.weapon_levels:
		var w: Dictionary = GameData.weapon_by_id(id)
		var lv: int = p.weapon_levels[id]
		if id == "orb":
			_flame_orb(w, lv)
			continue
		_cd[id] = float(_cd.get(id, 0.3)) - delta
		if _cd[id] > 0.0:
			continue
		var fired := false
		match id:
			"bolt": fired = _arcane_bolt(w, lv)
			"nova": fired = _frost_nova(w, lv)
			"burst": fired = _mana_burst(w, lv)
			"chain": fired = _storm_chain(w, lv)
			"blade": fired = _spirit_blade(w, lv)
		# no target: check again soon instead of waiting a full cooldown
		_cd[id] = level_cooldown(w, lv) if fired else 0.1
	for f in _fx:
		f["t"] += delta
	_fx = _fx.filter(func(f): return f["t"] < f["life"])
	queue_redraw()


func _hit(e, amount: float) -> void:
	var crit := randf() < float(game.player.stats["crit"])
	game.enemies.damage(e, amount * (2.0 if crit else 1.0), crit)


# ------------------------------------------------------------------ weapons

func _arcane_bolt(w: Dictionary, lv: int) -> bool:
	var p: Player = game.player
	var target = game.enemies.nearest(p.position, float(w["range"]), null)
	if target == null:
		return false
	var count := count_of(w, lv)
	var base_dir: Vector2 = (target.pos - p.position).normalized()
	for i in count:
		var spread: float = 0.0 if count == 1 else lerp(-0.18 * (count - 1), 0.18 * (count - 1), float(i) / (count - 1))
		game.projectiles.fire(p.position, base_dir.rotated(spread), level_damage(w, lv), int(p.stats["bounce"]), p.area())
	return true


func _frost_nova(w: Dictionary, lv: int) -> bool:
	var p: Player = game.player
	var r: float = float(w["radius"]) * level_size(w, lv)
	var foes: Array = game.enemies.query_radius(p.position, r)
	if foes.is_empty():
		return false
	for e in foes:
		_hit(e, level_damage(w, lv))
	_fx.append({"kind": "nova", "t": 0.0, "life": 0.3, "r": r})
	return true


func _flame_orb(w: Dictionary, lv: int) -> void:
	var p: Player = game.player
	var count := count_of(w, lv)
	var r: float = float(w["radius"]) * level_size(w, lv)
	var hit_r: float = 6.0 * level_size(w, lv)
	var rehit := level_cooldown(w, lv)
	for i in count:
		var pos := p.position + Vector2.from_angle(_time * float(w["spin"]) + TAU * i / count) * r
		_orbs.append(pos)
		for e in game.enemies.query_radius(pos, hit_r):
			if _time - e.orb_hit_at >= rehit:
				e.orb_hit_at = _time
				_hit(e, level_damage(w, lv))


func _mana_burst(w: Dictionary, lv: int) -> bool:
	var p: Player = game.player
	var foes: Array = game.enemies.query_radius(p.position, float(w["range"]))
	if foes.is_empty():
		return false
	var center: Vector2 = foes[randi() % foes.size()].pos
	var r: float = float(w["radius"]) * level_size(w, lv)
	for e in game.enemies.query_radius(center, r):
		_hit(e, level_damage(w, lv))
	_fx.append({"kind": "burst", "t": 0.0, "life": 0.35, "pos": center, "r": r})
	return true


func _storm_chain(w: Dictionary, lv: int) -> bool:
	var p: Player = game.player
	var cur = game.enemies.nearest(p.position, float(w["range"]), null)
	if cur == null:
		return false
	var points: Array = [p.position]
	var done: Array = []
	var jumps := count_of(w, lv)
	var amount := level_damage(w, lv)
	for j in jumps:
		points.append(cur.pos)
		done.append(cur)
		_hit(cur, amount)
		var best = null
		var best_d := INF
		for e in game.enemies.query_radius(cur.pos, float(w["jump_range"])):
			if e in done:
				continue
			var d: float = e.pos.distance_squared_to(cur.pos)
			if d < best_d:
				best_d = d
				best = e
		if best == null:
			break
		cur = best
	_fx.append({"kind": "chain", "t": 0.0, "life": 0.18, "points": points})
	return true


func _spirit_blade(w: Dictionary, lv: int) -> bool:
	var p: Player = game.player
	var r: float = float(w["radius"]) * level_size(w, lv)
	var foes: Array = game.enemies.query_radius(p.position, r)
	if foes.is_empty():
		return false
	var dir := p.facing
	var half: float = float(w["arc"]) * 0.5
	for e in foes:
		var to: Vector2 = e.pos - p.position
		if to.length() < 1.0 or absf(dir.angle_to(to)) <= half:
			_hit(e, level_damage(w, lv))
	_fx.append({"kind": "blade", "t": 0.0, "life": 0.2, "dir": dir.angle(), "half": half, "r": r})
	return true


# ------------------------------------------------------------------ visuals

func _draw() -> void:
	var pp: Vector2 = game.player.position
	for o in _orbs:
		draw_circle(o, 4.5, Color(1.0, 0.45, 0.1, 0.5))
		draw_circle(o, 3.0, Color(1.0, 0.7, 0.2))
		draw_circle(o, 1.5, Color(1.0, 0.95, 0.7))
	for f in _fx:
		var k: float = f["t"] / f["life"]
		match f["kind"]:
			"nova":
				draw_arc(pp, max(4.0, f["r"] * k), 0, TAU, 40, Color(0.6, 0.9, 1.0, 1.0 - k), 2.0)
			"burst":
				draw_circle(f["pos"], f["r"] * (0.4 + 0.6 * k), Color(0.75, 0.4, 1.0, 0.35 * (1.0 - k)))
				draw_arc(f["pos"], f["r"] * (0.4 + 0.6 * k), 0, TAU, 32, Color(0.9, 0.7, 1.0, 1.0 - k), 1.5)
			"chain":
				var pts := PackedVector2Array()
				for q in f["points"]:
					pts.append(q)
				pts[0] = pp
				draw_polyline(pts, Color(0.75, 0.9, 1.0, 1.0 - k), 2.0)
				draw_polyline(pts, Color(1, 1, 1, 1.0 - k), 1.0)
			"blade":
				var a0: float = f["dir"] - f["half"]
				var a1: float = f["dir"] + f["half"]
				draw_arc(pp, f["r"] * (0.6 + 0.4 * k), a0, a1, 20, Color(0.85, 1.0, 0.95, 1.0 - k), 3.0)
				draw_arc(pp, f["r"] * (0.45 + 0.4 * k), a0, a1, 20, Color(0.5, 0.95, 0.85, 0.6 * (1.0 - k)), 2.0)
