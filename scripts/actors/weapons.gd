class_name Weapons
extends Node2D
## Fires every weapon the player owns. Attack types follow the "Riftbound Weapon Attack
## Design" doc (prototype set): Arcane Bolt, Flame Orb, Chain Lightning, Meteor Fall,
## Astral Blades, Void Well, Frost Lance, Thornseed. Numbers come from GameData.WEAPONS;
## this file holds each weapon's behaviour. Shots fly in Projectiles; ground effects
## (meteor strikes, roots, void wells) are plain dictionaries updated here.
## Every weapon fires on its own cooldown (attack speed), with or without a target.
## Evolutions (Prismatic Barrage, Solar Cataclysm, Thunderstorm Network, Starfall, Blade Halo,
## Event Horizon, Absolute Zero, Worldroot Bloom) replace their base weapon; most reuse the base
## behaviour with bigger numbers plus one new twist each.

const MAX_ROOTS := 28   # live root patches (oldest dropped first)
const PRISM_KINDS := ["prism_arcane", "prism_fire", "prism_ice", "prism_nature"]
# custom top-down bursts (tools/pixelfx_custom/riftbound): their ring's reach in px at scale 1
const BURST_REACH := {"solar_burst": 44.0, "frost_burst": 42.0, "void_collapse": 46.0}

var game: Node
var _cd := {}            # weapon id -> seconds until next use
var _time := 0.0
var _strikes: Array = [] # pending meteor impacts {pos, t, delay, r, dmg}
var _zones: Array = []   # roots / void wells {kind, pos, r, t, life, dmg, tick_dmg, ...}
var _blade_fx: Array = [] # looping astral-blade instances, one per blade
var _blade_arcs: Array = [] # this frame's blade sweeps for the trail {c, a, r_in, r_out, span}
var _trail: Node2D         # additive child that draws the Astral Blades sweep trails
var _halo_t := 0.5         # Blade Halo: seconds until the next thrown blade


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
	var orbit := false
	for id in p.weapon_levels.keys():
		var w: Dictionary = GameData.weapon_by_id(id)
		var lv: int = p.weapon_levels[id]
		if w.has("blade_len"):   # orbiting swords: Astral Blades, Blade Halo
			orbit = true
			_astral_blades(w, lv, delta)
			if id == "halo":
				_halo_throw(w, lv, delta)
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
			"prism": _prismatic_barrage(w, lv)
			"solar": _fan("solar", w, lv, _aim(float(w["range"])), 0.22, int(w["bounce"]) + int(p.stats["bounce"]), 0)
			"storm": _chain_lightning(w, lv)
			"starfall": _meteor_fall(w, lv)
			"horizon": _void_well(w, lv)
			"zero": _fan("zero", w, lv, _aim(float(w["range"])), 0.12, 0, int(w["pierce"]) + int(p.stats["bounce"]))
			"worldroot": _fan("worldseed", w, lv, _aim(float(w["range"])), 0.3, 0, 0)
		_cd[id] = level_cooldown(w, lv)
	_update_strikes(delta)
	_update_zones(delta)
	if not orbit:
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
		"flame", "solar":
			game.vfx.sparks(pos, Color(2.6, 1.3, 0.35), 6, 110.0, 0.25, 1.4)
			game.vfx.flash(pos, Color(2.0, 0.9, 0.3), 14.0 if shot["kind"] == "solar" else 10.0, 0.12)
		"lance", "zero", "prism_ice":
			if enemy != null:
				enemy.slow_t = maxf(enemy.slow_t, float(w.get("slow", 1.0)))
			game.vfx.shards(pos, Color(0.9, 1.8, 2.4), 5, 90.0, 0.5)
			game.vfx.motes(pos, Color(0.6, 1.2, 1.6), 2, 12.0, 0.6, 3.0, -8.0)
		"seed", "worldseed":
			_spawn_roots(w, int(game.player.weapon_levels.get(w["id"], 1)), pos)
		"prism_fire":
			# a small fire splash scorches foes next to the one hit
			for e in game.enemies.query_radius(pos, float(w["fire_splash_r"]) * game.player.area()):
				if e != enemy:
					_hit(e, float(shot["dmg"]) * float(w["fire_splash"]), Color(2.4, 1.1, 0.3))
			game.vfx.sparks(pos, Color(2.6, 1.3, 0.35), 5, 90.0, 0.22, 1.3)
		"prism_nature":
			if enemy != null:
				enemy.slow_t = maxf(enemy.slow_t, 0.6)
			game.vfx.motes(pos, Color(0.8, 2.0, 0.6), 3, 20.0, 0.5, 2.5, -10.0)


## Called by Projectiles for every shot that ends (last hit, wall, or out of time).
func on_projectile_end(shot: Dictionary) -> void:
	var w: Dictionary = shot["w"]
	match shot["kind"]:
		"solar":
			# Solar Cataclysm: the miniature sun detonates where it ends up
			_burst(shot["pos"], float(w["burst_r"]) * game.player.area(), float(shot["dmg"]) * float(w["burst_dmg"]),
				"solar_burst", Color(2.6, 1.6, 0.4), 0.0)
		"zero":
			# Absolute Zero: the spear shatters into a crystal blast that freezes the area
			_burst(shot["pos"], float(w["burst_r"]) * game.player.area(), float(shot["dmg"]) * float(w["burst_dmg"]),
				"frost_burst", Color(1.0, 1.9, 2.6), float(w["freeze"]))


## Radial blast used by the evolutions, drawn with that element's top-down burst effect.
func _burst(pos: Vector2, r: float, amount: float, fx: String, col: Color, freeze: float) -> void:
	for e in game.enemies.query_radius(pos, r):
		_hit(e, amount, col)
		if freeze > 0.0:
			_freeze(e, freeze)
	game.vfx.play(fx, pos, 0.0, r / float(BURST_REACH[fx]))
	game.screen_fx.shockwave(pos, r * 1.6, 0.8, 0.4)
	game.screen_fx.shake(0.08)


## Freezes a foe solid; bosses are only slowed.
func _freeze(e, t: float) -> void:
	if e.boss:
		e.slow_t = maxf(e.slow_t, t)
	else:
		e.freeze_t = maxf(e.freeze_t, t)


## Prismatic Barrage: a fan of bolts, each a different element (arcane, fire, ice, nature).
func _prismatic_barrage(w: Dictionary, lv: int) -> void:
	var p: Player = game.player
	var dir := _aim(float(w["range"]))
	var count := count_of(w, lv)
	var b: int = int(w["bounce"]) + int(p.stats["bounce"])
	var step := 0.16
	for i in count:
		var spread: float = 0.0 if count == 1 else lerp(-step * (count - 1), step * (count - 1), float(i) / (count - 1))
		game.projectiles.fire(PRISM_KINDS[i % PRISM_KINDS.size()], p.position, dir.rotated(spread), level_damage(w, lv), w, b, 0, p.area())


## Called by main when a weapon evolves: the new weapon fires almost at once.
func on_evolved(_base_id: String, evo_id: String) -> void:
	_cd[evo_id] = 0.2
	_halo_t = 0.3


## Root patch. Worldroot Bloom patches (w has "branches") trap foes and sprout smaller patches around them.
func _spawn_roots(w: Dictionary, lv: int, pos: Vector2, r_mult := 1.0, gen := 0) -> void:
	var roots := _zones.filter(func(z): return z["kind"] == "roots")
	if roots.size() >= MAX_ROOTS:
		roots[0]["t"] = roots[0]["life"]
	var r: float = float(w["root_r"]) * level_size(w, lv) * r_mult
	# nature/root-snare: the root tangle spans ~56 px at scale 1, pivot on the ground
	game.vfx.play("root_snare", pos + Vector2(0, 3), 0.0, r / 28.0)
	_zones.append({"kind": "roots", "pos": pos, "r": r, "t": 0.0, "life": float(w["root_time"]),
		"tick_dmg": level_damage(w, lv) * float(w["tick_dmg"]) / float(w["dmg"]), "slow": float(w["slow"]),
		"trap": float(w.get("trap", 0.0)), "branches": int(w.get("branches", 0)) if gen == 0 else 0,
		"w": w, "lv": lv})


# ------------------------------------------------------------------ Chain Lightning

## Chain Lightning: one bolt that jumps foe to foe. Thunderstorm Network (w has "jumps") strikes
## several storms at once, each starting on a different nearby foe; the chains share their targets, so
## together they spread across the whole pack.
func _chain_lightning(w: Dictionary, lv: int) -> void:
	var p: Player = game.player
	var storm: bool = w.has("jumps")
	var chains := count_of(w, lv) if storm else 1
	var jumps: int = int(w["jumps"]) if storm else count_of(w, lv)
	var starts: Array = game.enemies.query_radius(p.position, float(w["range"]))
	if starts.is_empty():
		# nothing in range: lone zaps strike the ground ahead
		for c in chains:
			var spot: Vector2 = p.position + p.facing.rotated(randf_range(-0.6, 0.6) * c) * float(w["range"]) * 0.4
			game.vfx.play("zap_hit", spot, p.facing.angle(), 0.6)
		return
	starts.sort_custom(func(a, b): return a.pos.distance_squared_to(p.position) < b.pos.distance_squared_to(p.position))
	var done: Array = []
	var amount := level_damage(w, lv)
	var si := 0
	for c in chains:
		while si < starts.size() and starts[si] in done:
			si += 1
		if si >= starts.size():
			break
		var cur = starts[si]
		var prev: Vector2 = p.position + Vector2(0, -6)
		if storm:
			# each storm cell opens with a bright flash and ring on its first foe
			game.vfx.flash(cur.pos, Color(1.4, 2.0, 2.8), 18.0, 0.16)
			game.vfx.ring(cur.pos, Color(1.0, 1.7, 2.8), 22.0, 0.3, 2.0)
			game.vfx.play("zap_hit", cur.pos, -PI * 0.5, 0.9)
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
	game.screen_fx.chroma(0.25 if storm else 0.15)
	if storm:
		game.screen_fx.shake(0.06)


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
		# Starfall staggers its meteors more, so they rain down one after another
		_strikes.append({"pos": spot, "t": -float(w.get("stagger", 0.08)) * i, "delay": float(w["delay"]), "r": r,
			"dmg": level_damage(w, lv), "fx": false})


func _update_strikes(delta: float) -> void:
	for s in _strikes:
		s["t"] += delta
		if not s["fx"] and s["t"] >= 0.0:
			# riftbound/meteor-strike: warning ring, the rock lands at 0.5 s, fire ring reaches 38 px at scale 1
			s["fx"] = true
			game.vfx.play("meteor_strike", s["pos"], 0.0, s["r"] / 38.0)
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
	# Event Horizon is much bigger: its light is turned down so the huge vortex is heavy, not blinding
	var light_k: float = GameData.VFX_LIGHT_BOOST * (0.45 if w["id"] == "horizon" else 1.0)
	var fx: Dictionary = game.vfx.play("void_orb", center, 0.0, r / 50.0, Color.WHITE, light_k, -1.0, null, true)
	_zones.append({"kind": "void", "pos": center, "r": r, "t": 0.0, "life": float(w["duration"]), "fx": fx,
		"horizon": w["id"] == "horizon",
		"pull": float(w["pull"]) * level_size(w, lv), "dmg": level_damage(w, lv),
		"tick_dmg": level_damage(w, lv) * float(w["tick_dmg"]) / float(w["dmg"])})


# ------------------------------------------------------------------ zones (roots, void wells)

func _update_zones(delta: float) -> void:
	for z in _zones.duplicate():   # copy: Worldroot patches can sprout new zones mid-loop
		z["t"] += delta
		if z["kind"] == "roots":
			if z["branches"] > 0 and z["t"] >= 0.35:
				# Worldroot Bloom: the patch spreads, sprouting smaller patches around itself
				var n: int = z["branches"]
				z["branches"] = 0
				var a0 := randf() * TAU
				for i in n:
					var spot: Vector2 = z["pos"] + Vector2.from_angle(a0 + TAU * i / n) * z["r"] * 1.3
					if not game.world.is_solid_at(spot):
						_spawn_roots(z["w"], z["lv"], spot, 0.7, 1)
			for e in game.enemies.query_radius(z["pos"], z["r"]):
				e.slow_t = maxf(e.slow_t, 0.3)
				if z["trap"] > 0.0 and _time - e.trap_at >= GameData.ROOT_TRAP_COOLDOWN:
					e.trap_at = _time
					_freeze(e, z["trap"])
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
	if z["horizon"]:
		# Event Horizon collapses with a violet plasma ring on top of the dark blast
		game.vfx.play("void_collapse", z["pos"], 0.0, z["r"] / float(BURST_REACH["void_collapse"]))
		game.screen_fx.chroma(0.3)
	game.vfx.ring(z["pos"], Color(1.6, 0.7, 2.6), z["r"], 0.35, 2.0)
	game.screen_fx.shockwave(z["pos"], z["r"] * 1.8, 1.0, 0.45)
	game.screen_fx.shake(0.14)


# ------------------------------------------------------------------ Astral Blades

## Kael's spectral swords: they orbit the hero pointing outward, cutting what they touch, each
## trailing a curved streak of starlight (spawned along the orbit, so it follows the circle).
func _astral_blades(w: Dictionary, lv: int, delta: float) -> void:
	var p: Player = game.player
	var count := count_of(w, lv)
	var size := level_size(w, lv)
	var r: float = float(w["radius"]) * size
	var blen: float = float(w["blade_len"]) * size
	var fx_scale: float = blen / 26.0   # riftbound/astral-blade: 26 px from guard to tip at scale 1
	var hit_r: float = 5.0 * size
	var rehit := level_cooldown(w, lv)
	while _blade_fx.size() < count:
		var inst: Dictionary = game.vfx.play("astral_blade", p.position, 0.0, fx_scale, Color.WHITE, 0.8)
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
		_blade_arcs.append({"c": p.position, "a": a, "r_in": r + blen * 0.25, "r_out": r + blen, "span": float(w["trail_arc"])})
		if randf() < 0.25:
			game.vfx.trail(hilt + out * blen * randf_range(0.5, 0.85), Color(1.2, 1.9, 2.6), 1.4, 0.3)
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


## Blade Halo: every so often one sword leaves the halo and flies, piercing, at the nearest foe.
func _halo_throw(w: Dictionary, lv: int, delta: float) -> void:
	_halo_t -= delta
	if _halo_t > 0.0:
		return
	var p: Player = game.player
	_halo_t = float(w["launch_cd"]) / (1.0 + float(p.stats["attack_speed_pct"]))
	var target = game.enemies.nearest(p.position, float(w["launch_range"]), null)
	if target == null:
		return
	var dir: Vector2 = (target.pos - p.position).normalized()
	var from: Vector2 = p.position + dir * float(w["radius"]) * level_size(w, lv)
	game.projectiles.fire("halo_blade", from, dir, level_damage(w, lv) * float(w["launch_dmg"]), w,
		0, int(w["pierce"]) + int(p.stats["bounce"]), p.area())
	game.vfx.sparks(from, Color(0.9, 1.8, 2.6), 4, 60.0, 0.2, 1.2)


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
			var col0 := _trail_col(u0, k0)
			var col1 := _trail_col(u1, k1)
			var d0 := Vector2.from_angle(g0)
			var d1 := Vector2.from_angle(g1)
			var inner0 := Color(col0, col0.a * 0.15)
			var inner1 := Color(col1, col1.a * 0.15)
			_trail.draw_polygon(PackedVector2Array([c + d0 * ri0, c + d0 * r_out, c + d1 * r_out, c + d1 * ri1]),
				PackedColorArray([inner0, col0, col1, inner1]))
			# hot rim along the tip's path, kept soft right at the blade tip so the tip does not flare
			var rim := Color(1.6, 2.2, 2.8, k0 * 0.9 * smoothstep(0.0, 0.25, u0 + 0.05))
			_trail.draw_line(c + d0 * (r_out - 0.5), c + d1 * (r_out - 0.5), rim, 1.5 * (1.0 - u0 * 0.6))


func _trail_col(u: float, k: float) -> Color:
	var head := Color(1.4, 2.0, 2.6)   # white-cyan at the blade
	var mid := Color(0.35, 0.9, 1.9)   # cyan-blue
	var tail := Color(0.7, 0.35, 1.6)  # violet
	var col := head.lerp(mid, clampf(u * 2.5, 0.0, 1.0)) if u < 0.4 else mid.lerp(tail, (u - 0.4) / 0.6)
	return Color(col, k * 0.75)


func clear_blades() -> void:
	for inst in _blade_fx:
		inst["dead"] = true
	_blade_fx.clear()
