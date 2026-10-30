class_name Weapons
extends Node2D
## Fires every weapon the player owns. Numbers come from GameData.WEAPONS;
## this file holds each weapon's behaviour and its layered VFX. The node draws
## additively, and colours above 1.0 bloom through the HDR glow.

var game: Node
var _cd := {}            # weapon id -> seconds until next use
var _time := 0.0
var _orbs: Array = []    # Flame Orb world positions this frame
var _orb_trail_t := 0.0
var _bursts: Array = []  # pending Mana Burst detonations {pos, t, delay, r, dmg}
var _fx: Array = []      # drawn effects {kind, t, life, ...}


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat


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
			_flame_orb(w, lv, delta)
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
		_cd[id] = level_cooldown(w, lv) if fired else 0.1  # no target: check again soon
	_update_bursts(delta)
	for f in _fx:
		f["t"] += delta
		if f["kind"] == "chain" and int(f["t"] / 0.04) != f.get("seed_step", -1):
			f["seed_step"] = int(f["t"] / 0.04)
			f["bolt"] = _jagged(f["points"], 7.0)   # flicker: re-roll the lightning shape
	_fx = _fx.filter(func(f): return f["t"] < f["life"])
	queue_redraw()


func _hit(e, amount: float, color: Color) -> void:
	var crit := randf() < float(game.player.stats["crit"])
	game.enemies.damage(e, amount * (2.0 if crit else 1.0), crit)
	game.vfx.hit(e.pos, color, crit)


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
	game.vfx.flash(p.position + base_dir * 8.0, Color(0.8, 2.2, 2.6), 10.0, 0.08)
	game.vfx.sparks(p.position + base_dir * 8.0, Color(0.6, 1.8, 2.2), 3, 70.0, 0.15, 1.0)
	return true


func _frost_nova(w: Dictionary, lv: int) -> bool:
	var p: Player = game.player
	var r: float = float(w["radius"]) * level_size(w, lv)
	var foes: Array = game.enemies.query_radius(p.position, r)
	if foes.is_empty():
		return false
	var ice := Color(0.7, 1.6, 2.4)
	for e in foes:
		_hit(e, level_damage(w, lv), ice)
	game.vfx.ring(p.position, ice * 1.3, r, 0.35, 4.0)
	game.vfx.ring(p.position, Color(1.5, 2.0, 2.4), r * 0.7, 0.3, 2.0)
	game.vfx.flash(p.position, Color(0.4, 0.9, 1.4), r * 0.9, 0.2)
	game.vfx.shards(p.position, Color(0.8, 1.6, 2.2), 14, r * 3.5, 0.4)
	game.vfx.motes(p.position, Color(0.5, 0.9, 1.3), 10, r * 1.2, 0.8, 4.0, 0.0)
	game.screen_fx.shockwave(p.position, r * 1.3, 0.7, 0.4)
	game.screen_fx.shake(0.08)
	_fx.append({"kind": "nova", "t": 0.0, "life": 0.35, "r": r})
	return true


func _flame_orb(w: Dictionary, lv: int, delta: float) -> void:
	var p: Player = game.player
	var count := count_of(w, lv)
	var r: float = float(w["radius"]) * level_size(w, lv)
	var hit_r: float = 6.0 * level_size(w, lv)
	var rehit := level_cooldown(w, lv)
	_orb_trail_t -= delta
	var emit := _orb_trail_t <= 0.0
	if emit:
		_orb_trail_t = 0.03
	for i in count:
		var pos := p.position + Vector2.from_angle(_time * float(w["spin"]) + TAU * i / count) * r
		_orbs.append(pos)
		if emit:
			game.vfx.trail(pos, Color(2.4, 0.9, 0.2), 3.0, 0.3)
		for e in game.enemies.query_radius(pos, hit_r):
			if _time - e.orb_hit_at >= rehit:
				e.orb_hit_at = _time
				_hit(e, level_damage(w, lv), Color(2.4, 1.0, 0.3))


func _mana_burst(w: Dictionary, lv: int) -> bool:
	var p: Player = game.player
	var foes: Array = game.enemies.query_radius(p.position, float(w["range"]))
	if foes.is_empty():
		return false
	var center: Vector2 = foes[randi() % foes.size()].pos
	var r: float = float(w["radius"]) * level_size(w, lv)
	# short telegraph so the blast reads: a sigil gathers, then detonates
	_bursts.append({"pos": center, "t": 0.0, "delay": 0.28, "r": r, "dmg": level_damage(w, lv)})
	return true


func _update_bursts(delta: float) -> void:
	for b in _bursts:
		b["t"] += delta
		if b["t"] >= b["delay"] and not b.get("done", false):
			b["done"] = true
			var arcane := Color(1.6, 0.7, 2.6)
			for e in game.enemies.query_radius(b["pos"], b["r"]):
				_hit(e, b["dmg"], arcane)
			game.vfx.explosion(b["pos"], arcane, b["r"])
			game.screen_fx.shockwave(b["pos"], b["r"] * 1.6, 1.0, 0.45)
			game.screen_fx.shake(0.12)
			_fx.append({"kind": "burst", "t": 0.0, "life": 0.3, "pos": b["pos"], "r": b["r"]})
	_bursts = _bursts.filter(func(b): return not b.get("done", false))


func _storm_chain(w: Dictionary, lv: int) -> bool:
	var p: Player = game.player
	var cur = game.enemies.nearest(p.position, float(w["range"]), null)
	if cur == null:
		return false
	var points: Array = [p.position]
	var done: Array = []
	var jumps := count_of(w, lv)
	var amount := level_damage(w, lv)
	var volt := Color(1.2, 1.8, 2.8)
	for j in jumps:
		points.append(cur.pos)
		done.append(cur)
		_hit(cur, amount, volt)
		game.vfx.flash(cur.pos, volt, 16.0, 0.14)
		game.vfx.sparks(cur.pos, Color(1.5, 2.0, 2.8), 5, 140.0, 0.2, 1.2)
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
	game.screen_fx.chroma(0.15)
	_fx.append({"kind": "chain", "t": 0.0, "life": 0.22, "points": points, "bolt": _jagged(points, 7.0)})
	return true


## Midpoint-displaced polyline through the given points (lightning look).
func _jagged(points: Array, amp: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in points.size() - 1:
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var seg: Array = [a, b]
		var spread := amp
		for depth in 3:
			var next: Array = [seg[0]]
			for k in seg.size() - 1:
				var m: Vector2 = (seg[k] + seg[k + 1]) * 0.5
				var n: Vector2 = (seg[k + 1] - seg[k]).orthogonal().normalized()
				next.append(m + n * randf_range(-spread, spread))
				next.append(seg[k + 1])
			seg = next
			spread *= 0.5
		for q in seg:
			out.append(q)
	return out


func _spirit_blade(w: Dictionary, lv: int) -> bool:
	var p: Player = game.player
	var r: float = float(w["radius"]) * level_size(w, lv)
	var foes: Array = game.enemies.query_radius(p.position, r)
	if foes.is_empty():
		return false
	var dir := p.facing
	var half: float = float(w["arc"]) * 0.5
	var spirit := Color(0.9, 2.4, 1.9)
	for e in foes:
		var to: Vector2 = e.pos - p.position
		if to.length() < 1.0 or absf(dir.angle_to(to)) <= half:
			_hit(e, level_damage(w, lv), spirit)
	for i in 6:
		var a := dir.angle() - half + (2.0 * half) * i / 5.0
		game.vfx.sparks(p.position + Vector2.from_angle(a) * r * 0.9, spirit, 1, 90.0, 0.2, 1.2)
	game.screen_fx.shake(0.05)
	_fx.append({"kind": "blade", "t": 0.0, "life": 0.22, "dir": dir.angle(), "half": half, "r": r})
	return true


# ------------------------------------------------------------------ drawing

func _draw() -> void:
	var tex: Texture2D = game.vfx.glow_tex
	var pp: Vector2 = game.player.position
	var flicker := 0.85 + 0.15 * sin(_time * 40.0)
	for o in _orbs:
		draw_texture_rect(tex, Rect2(o - Vector2(14, 14), Vector2(28, 28)), false, Color(1.8, 0.6, 0.15, 0.9) * flicker)
		draw_circle(o, 3.2, Color(2.6, 1.3, 0.35))
		draw_circle(o, 1.6, Color(3.0, 2.6, 1.6))
	for b in _bursts:
		var k: float = b["t"] / b["delay"]
		var rr: float = b["r"] * (1.4 - 0.4 * k)
		draw_arc(b["pos"], rr, _time * 4.0, _time * 4.0 + TAU, 32, Color(1.4, 0.5, 2.2, 0.4 + 0.6 * k), 1.5)
		draw_arc(b["pos"], rr * 0.6, -_time * 6.0, -_time * 6.0 + PI * 1.5, 24, Color(1.6, 0.8, 2.4, k), 1.0)
		draw_texture_rect(tex, Rect2(b["pos"] - Vector2(rr, rr) * 0.5, Vector2(rr, rr)), false, Color(1.2, 0.4, 2.0, 0.5 * k))
	for f in _fx:
		var k: float = f["t"] / f["life"]
		match f["kind"]:
			"nova":
				var r: float = f["r"] * (0.3 + 0.7 * sqrt(k))
				draw_arc(pp, r, 0, TAU, 48, Color(1.0, 1.8, 2.6, 1.0 - k), 5.0 * (1.0 - k) + 1.0)
				for i in 12:
					var a := TAU * i / 12.0 + k
					var tip := pp + Vector2.from_angle(a) * r
					draw_line(tip, tip + Vector2.from_angle(a) * 6.0 * (1.0 - k), Color(1.6, 2.2, 2.6, 1.0 - k), 2.0)
			"burst":
				draw_circle(f["pos"], f["r"] * (0.5 + 0.5 * k), Color(1.2, 0.5, 2.0, 0.35 * (1.0 - k)))
			"chain":
				var a: float = 1.0 - k
				draw_polyline(f["bolt"], Color(0.5, 0.9, 2.2, 0.5 * a), 5.0)
				draw_polyline(f["bolt"], Color(1.2, 1.8, 3.0, a), 2.0)
				draw_polyline(f["bolt"], Color(2.5, 2.6, 3.0, a), 1.0)
			"blade":
				_draw_crescent(pp, f["dir"], f["half"], f["r"], k)


func _draw_crescent(center: Vector2, dir: float, half: float, r: float, k: float) -> void:
	# a sweeping crescent: the outer edge travels across the arc, the band thins as it fades
	var sweep := clampf(k * 2.2, 0.0, 1.0)
	var a0 := dir - half
	var a1 := dir - half + 2.0 * half * sweep
	var steps := 18
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	var thick := r * 0.38 * (1.0 - k * 0.7)
	for i in steps + 1:
		var a := lerpf(a0, a1, float(i) / steps)
		var taper := sin(PI * float(i) / steps)  # thick in the middle, sharp ends
		outer.append(center + Vector2.from_angle(a) * r)
		inner.append(center + Vector2.from_angle(a) * (r - thick * taper))
	var poly := PackedVector2Array()
	poly.append_array(outer)
	inner.reverse()
	poly.append_array(inner)
	var fade := 1.0 - k
	if sweep > 0.08 and poly.size() >= 3:
		draw_colored_polygon(poly, Color(0.5, 1.6, 1.3, 0.55 * fade))
	if outer.size() >= 2:
		draw_polyline(outer, Color(1.8, 2.8, 2.4, fade), 2.0)
