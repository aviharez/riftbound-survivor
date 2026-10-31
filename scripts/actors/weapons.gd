class_name Weapons
extends Node2D
## Fires every weapon the player owns. Attack types follow the "Riftbound Weapon Attack
## Design" doc (prototype set): Arcane Bolt, Flame Orb, Chain Lightning, Meteor Fall,
## Astral Blades, Void Well, Frost Lance, Thornseed. Numbers come from GameData.WEAPONS;
## this file holds each weapon's behaviour. Shots fly in Projectiles; ground effects
## (meteor strikes, roots, void wells) are plain dictionaries updated here.
## Every weapon fires on its own cooldown (attack speed), with or without a target.

const MAX_ROOTS := 14   # live Thornseed root patches (oldest dropped first)

var game: Node
var _cd := {}            # weapon id -> seconds until next use
var _time := 0.0
var _strikes: Array = [] # pending meteor impacts {pos, t, delay, r, dmg}
var _zones: Array = []   # roots / void wells {kind, pos, r, t, life, dmg, tick_dmg, ...}
var _blade_fx: Array = [] # looping astral-blade instances, one per blade
var _blade_arcs: Array = [] # this frame's blade sweeps for the trail {c, a, r_in, r_out, span}
var _trail: Node2D         # additive child that draws the Astral Blades sweep trails


func _ready() -> void:
	_trail = Node2D.new()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_trail.material = mat
	_trail.draw.connect(_draw_blade_trails)
	add_child(_trail)


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
	var p: Player = game.player
	for id in p.weapon_levels:
		var w: Dictionary = GameData.weapon_by_id(id)
		var lv: int = p.weapon_levels[id]
		if id == "blades":
			_astral_blades(w, lv, delta)
			continue
		_cd[id] = float(_cd.get(id, 0.3)) - delta
		if _cd[id] > 0.0:
			continue
		match id:
			"bolt": _arcane_bolt(w, lv)
			"flame": _flame_orb(w, lv)
			"chain": _chain_lightning(w, lv)
			"meteor": _meteor_fall(w, lv)
			"void": _void_well(w, lv)
			"lance": _frost_lance(w, lv)
			"seed": _thornseed(w, lv)
		_cd[id] = level_cooldown(w, lv)
	_update_strikes(delta)
	_update_zones(delta)
	if not p.weapon_levels.has("blades"):
		_blade_arcs.clear()
		if not _blade_fx.is_empty():
			clear_blades()
	_trail.queue_redraw()


func _hit(e, amount: float, color: Color) -> void:
	var crit := randf() < float(game.player.stats["crit"])
	game.enemies.damage(e, amount * (2.0 if crit else 1.0), crit)
	if crit:
		game.vfx.play("crit_hit", e.pos, randf_range(-0.4, 0.4), 0.26)
	else:
		game.vfx.sparks(e.pos, color, 3, 70.0, 0.18, 1.0)


## Aim at the nearest foe in range, or straight ahead when there is none.
func _aim(range_px: float) -> Vector2:
	var p: Player = game.player
	var target = game.enemies.nearest(p.position, range_px, null)
	return (target.pos - p.position).normalized() if target != null else p.facing


## count shots fanned round dir.
func _fan(kind: String, w: Dictionary, lv: int, dir: Vector2, step: float, bounces: int, pierce: int) -> void:
	var p: Player = game.player
	var count := count_of(w, lv)
	for i in count:
		var spread: float = 0.0 if count == 1 else lerp(-step * (count - 1), step * (count - 1), float(i) / (count - 1))
		game.projectiles.fire(kind, p.position, dir.rotated(spread), level_damage(w, lv), w, bounces, pierce, p.area())


# ------------------------------------------------------------------ projectile weapons

## Arcane Bolt: a cyan orb that seeks a foe and ricochets a limited number of times.
func _arcane_bolt(w: Dictionary, lv: int) -> void:
	var b: int = int(w.get("bounce", 0)) + int(game.player.stats["bounce"])
	_fan("bolt", w, lv, _aim(float(w["range"])), 0.18, b, 0)


## Flame Orb (Lyra): a fireball that ricochets between foes; ricochets grow with level.
func _flame_orb(w: Dictionary, lv: int) -> void:
	var b: int = int(w.get("bounce", 0)) + GameData.weapon_bonus(w, "bounce_at", lv) + int(game.player.stats["bounce"])
	_fan("flame", w, lv, _aim(float(w["range"])), 0.22, b, 0)


## Frost Lance: an ice spear that pierces through several foes, chilling them and leaving shards.
func _frost_lance(w: Dictionary, lv: int) -> void:
	var pierce: int = int(w.get("pierce", 0)) + GameData.weapon_bonus(w, "pierce_at", lv) + int(game.player.stats["bounce"])
	_fan("lance", w, lv, _aim(float(w["range"])), 0.12, 0, pierce)


## Thornseed (Nym): seeds that burst into a patch of thorny roots where they land.
func _thornseed(w: Dictionary, lv: int) -> void:
	_fan("seed", w, lv, _aim(float(w["range"])), 0.3, 0, 0)


## Called by Projectiles when a shot hits a foe (enemy set) or a wall (seed only).
func on_projectile_hit(shot: Dictionary, pos: Vector2, enemy = null) -> void:
	var w: Dictionary = shot["w"]
	match shot["kind"]:
		"flame":
			game.vfx.sparks(pos, Color(2.6, 1.3, 0.35), 6, 110.0, 0.25, 1.4)
			game.vfx.flash(pos, Color(2.0, 0.9, 0.3), 10.0, 0.12)
		"lance":
			if enemy != null:
				enemy.slow_t = maxf(enemy.slow_t, float(w.get("slow", 1.0)))
			game.vfx.shards(pos, Color(0.9, 1.8, 2.4), 5, 90.0, 0.5)
			game.vfx.motes(pos, Color(0.6, 1.2, 1.6), 2, 12.0, 0.6, 3.0, -8.0)
		"seed":
			_spawn_roots(w, game.player.weapon_levels.get("seed", 1), pos)


func _spawn_roots(w: Dictionary, lv: int, pos: Vector2) -> void:
	var roots := _zones.filter(func(z): return z["kind"] == "roots")
	if roots.size() >= MAX_ROOTS:
		roots[0]["t"] = roots[0]["life"]
	var r: float = float(w["root_r"]) * level_size(w, lv)
	# nature/root-snare: the root tangle spans ~56 px at scale 1, pivot on the ground
	game.vfx.play("root_snare", pos + Vector2(0, 3), 0.0, r / 28.0)
	_zones.append({"kind": "roots", "pos": pos, "r": r, "t": 0.0, "life": float(w["root_time"]),
		"tick_dmg": level_damage(w, lv) * float(w["tick_dmg"]) / float(w["dmg"]), "slow": float(w["slow"])})


# ------------------------------------------------------------------ Chain Lightning

func _chain_lightning(w: Dictionary, lv: int) -> void:
	var p: Player = game.player
	var cur = game.enemies.nearest(p.position, float(w["range"]), null)
	if cur == null:
		# nothing in range: a lone zap strikes the ground ahead
		var spot: Vector2 = p.position + p.facing * float(w["range"]) * 0.4
		game.vfx.play("zap_hit", spot, p.facing.angle(), 0.6)
		return
	var prev: Vector2 = p.position + Vector2(0, -6)
	var done: Array = []
	var jumps := count_of(w, lv)
	var amount := level_damage(w, lv)
	for j in jumps:
		done.append(cur)
		_hit(cur, amount, Color(1.2, 1.8, 2.8))
		# zap-hit's bolt arrives from the left of its pivot (~85 px long at scale 1)
		var d: Vector2 = cur.pos - prev
		game.vfx.play("zap_hit", cur.pos, d.angle(), clampf(d.length() / 85.0, 0.35, 1.2))
		prev = cur.pos
		var best = null
		var best_d := INF
		for e in game.enemies.query_radius(cur.pos, float(w["jump_range"])):
			if e in done:
				continue
			var dd: float = e.pos.distance_squared_to(cur.pos)
			if dd < best_d:
				best_d = dd
				best = e
		if best == null:
			break
		cur = best
	game.screen_fx.chroma(0.15)


# ------------------------------------------------------------------ Meteor Fall

## Marks foes in range (different ones when there are enough), then meteors land on the marks.
func _meteor_fall(w: Dictionary, lv: int) -> void:
	var p: Player = game.player
	var r: float = float(w["radius"]) * level_size(w, lv)
	var foes: Array = game.enemies.query_radius(p.position, float(w["range"]))
	foes.shuffle()
	for i in count_of(w, lv):
		var spot: Vector2
		if i < foes.size():
			spot = foes[i].pos
		else:
			spot = p.position + p.facing.rotated(randf_range(-0.8, 0.8)) * float(w["range"]) * randf_range(0.25, 0.6)
		# riftbound/meteor-strike: warning ring, the rock lands at 0.5 s, fire ring reaches 38 px at scale 1
		game.vfx.play("meteor_strike", spot, 0.0, r / 38.0)
		_strikes.append({"pos": spot, "t": -0.08 * i, "delay": float(w["delay"]), "r": r, "dmg": level_damage(w, lv)})


func _update_strikes(delta: float) -> void:
	for s in _strikes:
		s["t"] += delta
		if s["t"] >= s["delay"] and not s.get("done", false):
			s["done"] = true
			for e in game.enemies.query_radius(s["pos"], s["r"]):
				_hit(e, s["dmg"], Color(2.6, 1.2, 0.3))
			game.screen_fx.shockwave(s["pos"], s["r"] * 1.6, 1.0, 0.45)
			game.screen_fx.shake(0.12)
	_strikes = _strikes.filter(func(s): return not s.get("done", false))


# ------------------------------------------------------------------ Void Well

## Opens a singularity on the densest nearby spot (a random foe): it drags foes in, nibbling at
## them, then detonates.
func _void_well(w: Dictionary, lv: int) -> void:
	var p: Player = game.player
	var foes: Array = game.enemies.query_radius(p.position, float(w["range"]))
	var center: Vector2 = foes[randi() % foes.size()].pos if not foes.is_empty() \
		else p.position + p.facing * float(w["range"]) * 0.4
	var r: float = float(w["radius"]) * level_size(w, lv)
	# shadow/void-orb: the swirl with its pulse ring is ~50 px in radius at scale 1
	var fx: Dictionary = game.vfx.play("void_orb", center, 0.0, r / 50.0, Color.WHITE, GameData.VFX_LIGHT_BOOST, -1.0, null, true)
	_zones.append({"kind": "void", "pos": center, "r": r, "t": 0.0, "life": float(w["duration"]), "fx": fx,
		"pull": float(w["pull"]) * level_size(w, lv), "dmg": level_damage(w, lv),
		"tick_dmg": level_damage(w, lv) * float(w["tick_dmg"]) / float(w["dmg"])})


# ------------------------------------------------------------------ zones (roots, void wells)

func _update_zones(delta: float) -> void:
	for z in _zones:
		z["t"] += delta
		if z["kind"] == "roots":
			for e in game.enemies.query_radius(z["pos"], z["r"]):
				e.slow_t = maxf(e.slow_t, 0.3)
				if _time - e.root_hit_at >= 0.45:
					e.root_hit_at = _time
					_hit(e, z["tick_dmg"], Color(0.8, 2.0, 0.6))
		elif z["kind"] == "void":
			var reach: float = z["r"] * 1.5
			for e in game.enemies.query_radius(z["pos"], reach):
				if e.boss:
					continue
				var to: Vector2 = z["pos"] - e.pos
				if to.length() > 3.0:
					e.pos = game.world.move(e.pos, to.normalized() * z["pull"] * delta, e.radius * 0.6)
				if _time - e.root_hit_at >= 0.4:
					e.root_hit_at = _time
					_hit(e, z["tick_dmg"], Color(1.6, 0.6, 2.6))
			if randf() < 0.5:
				game.vfx.suck(z["pos"], reach, Color(1.4, 0.6, 2.4))
			if z["t"] >= z["life"]:
				_detonate(z)
	_zones = _zones.filter(func(z): return z["t"] < z["life"])


func _detonate(z: Dictionary) -> void:
	if not z["fx"].is_empty():
		z["fx"]["dead"] = true
	for e in game.enemies.query_radius(z["pos"], z["r"]):
		_hit(e, z["dmg"], Color(1.8, 0.7, 2.8))
	game.vfx.play("dark_explosion", z["pos"], 0.0, z["r"] / 90.0)
	game.vfx.ring(z["pos"], Color(1.6, 0.7, 2.6), z["r"], 0.35, 2.0)
	game.screen_fx.shockwave(z["pos"], z["r"] * 1.8, 1.0, 0.45)
	game.screen_fx.shake(0.14)


# ------------------------------------------------------------------ Astral Blades

## Kael's spectral swords: they orbit the hero pointing outward, cutting what they touch, each
## trailing a curved streak of starlight (spawned along the orbit, so it follows the circle).
func _astral_blades(w: Dictionary, lv: int, delta: float) -> void:
	var p: Player = game.player
	var count := mini(count_of(w, lv), int(w.get("max_count", 99)))
	var size := level_size(w, lv)
	var r: float = float(w["radius"]) * size
	var blen: float = float(w["blade_len"]) * size
	var fx_scale: float = blen / 26.0   # riftbound/astral-blade: 26 px from guard to tip at scale 1
	var hit_r: float = 5.0 * size
	var rehit := level_cooldown(w, lv)
	while _blade_fx.size() < count:
		var inst: Dictionary = game.vfx.play("astral_blade", p.position, 0.0, fx_scale, Color.WHITE, 0.6)
		if inst.is_empty():
			break
		_blade_fx.append(inst)
	while _blade_fx.size() > count:
		_blade_fx.pop_back()["dead"] = true
	var spin: float = float(w["spin"])
	_blade_arcs.clear()
	for i in count:
		var a: float = _time * spin + TAU * i / count
		var out := Vector2.from_angle(a)
		var hilt := p.position + out * r
		if i < _blade_fx.size():
			_blade_fx[i]["pos"] = hilt
			_blade_fx[i]["rot"] = a
			_blade_fx[i]["scale"] = fx_scale
			_blade_fx[i]["t"] = fmod(_blade_fx[i]["t"], 100.0)
		# sweep trail: a crescent of light swept along the orbit behind the blade (drawn by _trail)
		# with many blades the crescents would overlap into a solid disc: shorten them to fit the gaps
		var span: float = minf(float(w["trail_arc"]), TAU / count * 0.55)
		_blade_arcs.append({"c": p.position, "a": a, "r_in": r + blen * 0.25, "r_out": r + blen, "span": span,
			"k": 1.0 / sqrt(maxf(1.0, count / 2.0))})
		if randf() < 0.25:
			game.vfx.trail(hilt + out * blen * randf_range(0.6, 1.0), Color(0.9, 1.4, 1.9), 1.4, 0.3)
		# the cut runs from the hero's centre to the tip, so foes pressed against the hero are hit too
		var tip := hilt + out * blen
		for e in game.enemies.query_radius(p.position, r + blen + hit_r):
			if _time - e.blade_hit_at < rehit:
				continue
			var q := Geometry2D.get_closest_point_to_segment(e.pos, p.position, tip)
			if q.distance_to(e.pos) <= hit_r + e.radius:
				e.blade_hit_at = _time
				_hit(e, level_damage(w, lv), Color(0.9, 1.8, 2.6))
				game.vfx.play("hit_spark", e.pos, a + PI * 0.5, 0.28, Color(0.7, 0.95, 1.0))


## Each blade drags a crescent behind it: bright, white-cyan right at the blade, thinning towards the
## inner edge and fading through blue to violet along the orbit, with a hot rim at the tip radius.
## Segments are short so the crescent follows the circle exactly.
func _draw_blade_trails() -> void:
	const SEGS := 14
	for b in _blade_arcs:
		var c: Vector2 = b["c"]
		var a0: float = b["a"]
		var span: float = b["span"]
		var r_in: float = b["r_in"]
		var r_out: float = b["r_out"]
		var bk: float = b["k"]
		for i in SEGS:
			var u0 := float(i) / SEGS
			var u1 := float(i + 1) / SEGS
			var g0 := a0 - span * u0
			var g1 := a0 - span * u1
			# the crescent narrows towards its tail: its inner edge climbs to the tip radius
			var ri0: float = lerp(r_in, r_out - 2.0, u0 * u0)
			var ri1: float = lerp(r_in, r_out - 2.0, u1 * u1)
			var k0 := pow(1.0 - u0, 1.6)
			var k1 := pow(1.0 - u1, 1.6)
			var col0 := _trail_col(u0, k0 * bk)
			var col1 := _trail_col(u1, k1 * bk)
			var d0 := Vector2.from_angle(g0)
			var d1 := Vector2.from_angle(g1)
			var inner0 := Color(col0, col0.a * 0.15)
			var inner1 := Color(col1, col1.a * 0.15)
			_trail.draw_polygon(PackedVector2Array([c + d0 * ri0, c + d0 * r_out, c + d1 * r_out, c + d1 * ri1]),
				PackedColorArray([inner0, col0, col1, inner1]))
			# hot rim along the tip's path
			var rim := Color(1.1, 1.6, 2.0, k0 * 0.8 * bk)
			_trail.draw_line(c + d0 * (r_out - 0.5), c + d1 * (r_out - 0.5), rim, 1.5 * (1.0 - u0 * 0.6))
		# a soft light at the blade's tip where the trail starts
		var tip: Vector2 = c + Vector2.from_angle(a0) * r_out
		_trail.draw_circle(tip, 3.0, Color(0.6, 1.2, 1.8, 0.3 * bk))


func _trail_col(u: float, k: float) -> Color:
	var head := Color(1.0, 1.45, 1.8)  # white-cyan at the blade
	var mid := Color(0.3, 0.75, 1.4)   # cyan-blue
	var tail := Color(0.55, 0.3, 1.2)  # violet
	var col := head.lerp(mid, clampf(u * 2.5, 0.0, 1.0)) if u < 0.4 else mid.lerp(tail, (u - 0.4) / 0.6)
	return Color(col, k * 0.6)


func clear_blades() -> void:
	for inst in _blade_fx:
		inst["dead"] = true
	_blade_fx.clear()
