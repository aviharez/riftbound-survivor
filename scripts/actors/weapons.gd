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
const MAX_PLAGUE_CLOUDS := 6    # Noah's Plague: live spread clouds
const THORN_PATCH_TIME := 1.6  # riftbound/thorn-patch length (s)
const MINE_FX_SCALE := 1.5     # rune-sigil sheet (25 px wide) drawn ~38 px wide so the rune reads
const FAMILIAR_SCALE := 1.0   # 32 px PixelLab familiar (body ~24x18 px; hero is 33 tall)
const BURST_REACH := {"solar_burst": 44.0, "frost_burst": 42.0, "void_collapse": 46.0}

var game: Node
var arena: WeaponsArena   # the arena set (Hex Mark ... Crystal Barricade) and its 8 evolutions
var _cd := {}            # weapon id -> seconds until next use
var _time := 0.0
var _strikes: Array = [] # pending meteor impacts {pos, t, delay, r, dmg}
var _zones: Array = []   # roots / void wells {kind, pos, r, t, life, dmg, tick_dmg, ...}
var _blade_fx: Array = [] # looping astral-blade instances, one per blade
var _blade_arcs: Array = [] # this frame's blade sweeps for the trail {c, a, r_in, r_out, span}
var _trail: Node2D         # additive child that draws the Astral Blades sweep trails
var _halo_t := 0.5         # Blade Halo: seconds until the next thrown blade
var _familiars: Array = [] # Arcane Familiar: {cd, pos, hover, face} per familiar
var _beams: Array = []     # Aether Beam visuals {a, b, t, life, width}
var _mines: Array = []
var _trait_queue: Array = []  # kill-triggered trait effects, run next frame (no chain recursion within a frame)
var _retaliate_cd := 0.0
var _guard_cd := 0.0          # Wren's Page Guard
var _star_t := 2.0            # Celeste's Stargazer: seconds to the next star
var _static_kills := 0        # Raika's Static Charge
var trait_procs := 0          # how often the character trait fired (autotest summary)     # Arcane Mine runes on the floor {pos, t, life, arm, r, trig, dmg, fx}


func _ready() -> void:
	arena = WeaponsArena.new()
	arena.game = game
	arena.weapons = self
	add_child(arena)
	_trail = Node2D.new()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_trail.material = mat
	_trail.modulate = Vfx.additive_tint()
	_trail.draw.connect(_draw_additive)
	add_child(_trail)


func level_damage(w: Dictionary, lv: int) -> float:
	return game.player.dmg() * float(w["dmg"]) * (1.0 + float(w["lvl_dmg"]) * (lv - 1)) \
		* (1.0 + GameData.ENHANCE_WEAPON_DMG * _signature_rank(w))


func level_cooldown(w: Dictionary, lv: int) -> float:
	return float(w["cd"]) / (1.0 + float(w["lvl_cd"]) * (lv - 1)) / (1.0 + game.player.stats["attack_speed_pct"]) \
		/ (1.0 + GameData.ENHANCE_WEAPON_CD * _signature_rank(w))


## Signature-weapon enhance rank that applies to `w`: the character's starter weapon or its evolution.
func _signature_rank(w: Dictionary) -> int:
	var p: Player = game.player
	if p.signature_rank <= 0:
		return 0
	var starter: String = p.character.get("starter", "")
	return p.signature_rank if w.get("id", "") == starter or w.get("from", "") == starter else 0


## Passive enhance: trait strength multiplier (damage, heal, chance; cooldowns are divided by it).
func _tk() -> float:
	return game.player.trait_power


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
		if id == "familiar" or id == "legion":
			_arcane_familiars(w, lv, delta)
			continue
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
			"slash": _fan("slash", w, lv, _aim(float(w["range"])), float(w["spread"]), 0, int(w["pierce"]))
			"chakram": _fan("chakram", w, lv, _aim(float(w["range"])), float(w["spread"]), 0, int(w["pierce"]))
			"beam": _aether_beam(w, lv)
			"venom": _venom_bloom(w, lv)
			"mine": _drop_mines(w, lv)
			"lunar": _lunar_cross(w, lv)
			"infinity": _fan("chakram", w, lv, _aim(float(w["range"])), float(w["spread"]), 0, int(w["pierce"]))
			"celestial": _aether_beam(w, lv)
			"plague": _venom_bloom(w, lv)
			"runic": _drop_mines(w, lv)
			_:
				if id in WeaponsArena.IDS:
					arena.fire(id, w, lv)
		_cd[id] = level_cooldown(w, lv)
	_update_strikes(delta)
	_update_zones(delta)
	_update_mines(delta)
	_retaliate_cd = maxf(0.0, _retaliate_cd - delta)
	_guard_cd = maxf(0.0, _guard_cd - delta)
	if _trait() == "stargazer":
		_star_t -= delta
		if _star_t <= 0.0:
			_star_t = float(GameData.TRAITS["stargazer"]["interval"]) / _tk()
			_stargazer()
	if not _trait_queue.is_empty():
		var q := _trait_queue
		_trait_queue = []
		for t in q:
			_run_trait(t)
	for b in _beams:
		b["t"] += delta
	_beams = _beams.filter(func(b): return b["t"] < b["life"])
	if not p.weapon_levels.has("familiar") and not p.weapon_levels.has("legion") and not _familiars.is_empty():
		_familiars.clear()
	queue_redraw()
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
		"flame":
			_flame_splash(shot, pos, enemy)
		"solar":
			game.vfx.sparks(pos, Color(2.6, 1.3, 0.35), 6, 110.0, 0.25, 1.4)
			game.vfx.flash(pos, Color(2.0, 0.9, 0.3), 14.0, 0.12)
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


## Flame Orb: every hit bursts into a star of flame that scorches the foes around it.
func _flame_splash(shot: Dictionary, pos: Vector2, enemy) -> void:
	var w: Dictionary = shot["w"]
	var r: float = float(w["splash_r"]) * game.player.area()
	for e in game.enemies.query_radius(pos, r):
		if e != enemy:
			_hit(e, float(shot["dmg"]) * float(w["splash"]), Color(2.4, 1.1, 0.3))
	# solar_burst is a top-down star of flame whose ring reaches 44 px at scale 1
	game.vfx.play("solar_burst", pos, 0.0, r / 44.0)
	game.vfx.sparks(pos, Color(2.6, 1.3, 0.35), 5, 100.0, 0.25, 1.3)


## Called by Projectiles when a shot ricochets off a wall (Flame Orb, Solar Cataclysm).
func on_wall_bounce(shot: Dictionary) -> void:
	if shot["kind"] == "flame":
		_flame_splash(shot, shot["pos"], null)
	else:
		game.vfx.sparks(shot["pos"], Color(2.6, 1.6, 0.4), 6, 90.0, 0.25, 1.4)


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


## Lunar Cross: two big crescents start left and right of the hero and fly toward one point ahead, crossing there.
func _lunar_cross(w: Dictionary, lv: int) -> void:
	var p: Player = game.player
	var dir := _aim(float(w["range"]))
	var side := dir.orthogonal() * float(w["cross_offset"])
	var meet: Vector2 = p.position + dir * float(w["range"]) * 0.45
	for s in [-1.0, 1.0]:
		var from: Vector2 = p.position + side * s
		game.projectiles.fire("slash", from, (meet - from).normalized(), level_damage(w, lv), w, 0, int(w["pierce"]), p.area())
	game.vfx.sparks(p.position, Color(1.2, 1.7, 2.6), 6, 70.0, 0.2, 1.4)


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
	# riftbound/thorn-patch: snare ring 20 px in radius at scale 1, lasts 1.6 s; stretched to the patch's life
	var fx: Dictionary = game.vfx.play("thorn_patch", pos, 0.0, r / 20.0)
	if not fx.is_empty():
		fx["speed"] = THORN_PATCH_TIME / float(w["root_time"])
	_zones.append({"kind": "roots", "pos": pos, "r": r, "t": 0.0, "life": float(w["root_time"]),
		"tick_dmg": level_damage(w, lv) * float(w["tick_dmg"]) / float(w["dmg"]), "slow": float(w["slow"]),
		"trap": float(w.get("trap", 0.0)), "branches": int(w.get("branches", 0)) if gen == 0 else 0,
		"w": w, "lv": lv})


# ------------------------------------------------------------------ Chain Lightning

## Chain Lightning: one bolt that jumps foe to foe. Thunderstorm Network (w has "jumps") strikes
## several storms at once, each starting on a different nearby foe; the chains share their targets, so
## together they spread across the whole pack.
func _chain_lightning(w: Dictionary, lv: int) -> void:
	Sfx.play("zap")
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
			Sfx.play("explosion")
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
				e.rooted_t = 0.25   # drawn tinted green while snared
				if z["trap"] > 0.0 and _time - e.trap_at >= GameData.ROOT_TRAP_COOLDOWN:
					e.trap_at = _time
					_freeze(e, z["trap"])
				if _time - e.root_hit_at >= 0.45:
					e.root_hit_at = _time
					_hit(e, z["tick_dmg"], Color(0.8, 2.0, 0.6))
		elif z["kind"] == "venom":
			for e in game.enemies.query_radius(z["pos"], z["r"]):
				if _time - e.venom_hit_at >= z["tick"]:
					e.venom_hit_at = _time
					if z.get("garden", false):
						e.set_meta("garden", _time)
					_hit(e, z["tick_dmg"], Color(1.0, 2.2, 0.5))
		elif z["kind"] == "trace":
			z["next"] -= delta
			if z["next"] <= 0.0:
				z["next"] = z["tick"]
				for e in game.enemies.query_radius(z["pos"], z["r"] + z["w"] + 12.0):
					var q := Geometry2D.get_closest_point_to_segment(e.pos, z["a"], z["b"])
					if q.distance_to(e.pos) <= z["w"] * 0.5 + e.radius:
						_hit(e, z["tick_dmg"], Color(2.4, 2.0, 1.0))
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
	# the collapse is centred on the well itself (dark_explosion's pivot sits at its base, which drew the
	# blast ~40 px above the pull centre)
	game.vfx.play("void_collapse", z["pos"], 0.0, z["r"] / float(BURST_REACH["void_collapse"]))
	if z["horizon"]:
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
		var inst: Dictionary = game.vfx.play("astral_blade", p.position, 0.0, fx_scale, Color.WHITE, 0.45)
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
		if randf() < 0.12:
			game.vfx.trail(hilt + out * blen * randf_range(0.5, 0.85), Color(0.8, 1.3, 1.8), 1.2, 0.25)
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


# ------------------------------------------------------------------ Arcane Familiar

## Little crystal familiars circle the hero on a floor ellipse, hovering above their shadows, and each
## shoots a bolt at the nearest foe on its own cooldown (straight ahead when there is none).
func _arcane_familiars(w: Dictionary, lv: int, delta: float) -> void:
	var p: Player = game.player
	var n := count_of(w, lv)
	while _familiars.size() < n:
		_familiars.append({"cd": 0.2 + 0.3 * _familiars.size(), "pos": p.position, "hover": 0.0, "face": 1.0,
			"shot": 0.0, "phase": randf() * 2.0})
		game.vfx.play("blink_out", p.position + Vector2(0, -10), 0.0, 0.35, Color(0.7, 1.0, 1.0))
	while _familiars.size() > n:
		_familiars.pop_back()
	var cd := level_cooldown(w, lv)
	for i in n:
		var f: Dictionary = _familiars[i]
		var a: float = _time * float(w["orbit_speed"]) + TAU * i / n
		var target_pos: Vector2 = p.position + Vector2(cos(a), sin(a) * 0.6) * float(w["orbit_r"])
		f["pos"] = f["pos"].lerp(target_pos, clampf(delta * 8.0, 0.0, 1.0))
		f["hover"] = float(w["hover"]) + sin(_time * 3.0 + i * 1.7) * 2.0
		f["shot"] = maxf(0.0, float(f.get("shot", 0.0)) - delta)
		f["cd"] -= delta
		if f["cd"] > 0.0:
			continue
		f["cd"] = cd
		var muzzle: Vector2 = f["pos"] - Vector2(0, f["hover"])
		var foe = game.enemies.nearest(muzzle, float(w["range"]), null)
		var dir: Vector2 = (foe.pos - muzzle).normalized() if foe != null else p.facing
		f["face"] = -1.0 if dir.x < 0.0 else 1.0
		f["shot"] = GameData.FAMILIAR_SHOT_TIME   # plays the shoot animation
		if w.get("legion", false) and i % 3 == 1:
			for k in 3:   # fan familiar
				game.projectiles.fire("familiar_shot", muzzle, dir.rotated((k - 1) * 0.25), level_damage(w, lv), w, 0, 0, p.area())
		elif w.get("legion", false) and i % 3 == 2:
			game.projectiles.fire("familiar_shot", muzzle, dir, level_damage(w, lv) * 1.6, w, 0, 6, p.area())   # lance familiar
		else:
			game.projectiles.fire("familiar_shot", muzzle, dir, level_damage(w, lv), w, 0, 0, p.area())
		game.vfx.sparks(muzzle, Color(0.7, 1.8, 2.4), 3, 50.0, 0.15, 1.0)


# ------------------------------------------------------------------ Aether Beam

## A straight beam from the hero through a whole line of foes (toward the nearest one, then other foes
## for the extra beams), with a short afterglow.
func _aether_beam(w: Dictionary, lv: int) -> void:
	var p: Player = game.player
	var size := level_size(w, lv)
	var length: float = float(w["length"]) * size
	var width: float = float(w["width"]) * size
	var foes: Array = game.enemies.query_radius(p.position, float(w["range"]))
	foes.sort_custom(func(a, b): return a.pos.distance_squared_to(p.position) < b.pos.distance_squared_to(p.position))
	var amount := level_damage(w, lv)
	for i in count_of(w, lv):
		var dir: Vector2 = (foes[i].pos - p.position).normalized() if i < foes.size() else p.facing.rotated(0.6 * i)
		var a: Vector2 = p.position + Vector2(0, -6) + dir * 6.0
		var b: Vector2 = a + dir * length
		for e in game.enemies.query_radius((a + b) * 0.5, length * 0.5 + width + 12.0):
			var q := Geometry2D.get_closest_point_to_segment(e.pos, a, b)
			if q.distance_to(e.pos) <= width * 0.5 + e.radius:
				_hit(e, amount, Color(1.0, 2.0, 2.8))
		_beams.append({"a": a, "b": b, "t": 0.0, "life": float(w["show_time"]), "width": width})
		if w.has("trace_time"):   # Celestial Ray: a burning trace stays on the ground
			_zones.append({"kind": "trace", "a": a, "b": b, "pos": (a + b) * 0.5, "r": a.distance_to(b) * 0.5, "w": width,
				"t": 0.0, "life": float(w["trace_time"]), "tick": float(w["trace_tick"]), "tick_dmg": amount * float(w["trace_dmg"]), "next": 0.0})
			_beams.append({"a": a, "b": b, "t": 0.0, "life": float(w["trace_time"]), "width": width * 0.35, "trace": true})
		game.vfx.flash(a, Color(1.2, 2.2, 2.8), 10.0, 0.12)
		for k in 6:
			game.vfx.trail(a.lerp(b, randf()), Color(0.8, 1.9, 2.6), 1.6, 0.35)
	game.screen_fx.chroma(0.12)


# ------------------------------------------------------------------ Venom Bloom

## Lobs poison clouds onto foes (ahead when there are none). A cloud ticks damage on every foe inside it.
func _venom_bloom(w: Dictionary, lv: int) -> void:
	var p: Player = game.player
	var foes: Array = game.enemies.query_radius(p.position, float(w["range"]))
	var r: float = float(w["radius"]) * level_size(w, lv)
	for i in count_of(w, lv):
		var center: Vector2 = foes[randi() % foes.size()].pos if not foes.is_empty() \
			else p.position + p.facing.rotated(randf_range(-0.7, 0.7)) * float(w["range"]) * 0.45
		# riftbound/venom-cloud: the floor stain is 30 px in radius at scale 1
		var fx: Dictionary = game.vfx.play("venom_cloud", center, 0.0, r / 30.0, Color.WHITE, 0.9, float(w["duration"]))
		game.vfx.sparks(center, Color(0.9, 2.2, 0.5), 6, 60.0, 0.3, 1.3)
		_zones.append({"kind": "venom", "pos": center, "r": r, "t": 0.0, "life": float(w["duration"]),
			"tick": float(w["tick"]), "tick_dmg": level_damage(w, lv), "fx": fx, "garden": w.has("spread_r")})


# ------------------------------------------------------------------ Arcane Mine

## Drops runes on the floor near the hero; after arming, a rune blows up when a foe steps close.
func _drop_mines(w: Dictionary, lv: int) -> void:
	var p: Player = game.player
	var size := level_size(w, lv)
	for i in count_of(w, lv):
		var spot: Vector2 = p.position + Vector2.from_angle(randf() * TAU) * randf_range(float(w["drop_min"]), float(w["drop_max"]))
		if game.world.is_solid_at(spot):
			spot = p.position
		if _mines.size() >= int(w["max_mines"]):
			var old: Dictionary = _mines.pop_front()
			if not old["fx"].is_empty():
				old["fx"]["dead"] = true
		var fx: Dictionary = game.vfx.play("rune_sigil", spot, 0.0, size * MINE_FX_SCALE, Color(1, 1, 1, 0.45), 0.6, float(w["mine_life"]))
		_mines.append({"pos": spot, "t": 0.0, "life": float(w["mine_life"]), "arm": float(w["arm"]),
			"r": float(w["radius"]) * size, "trig": float(w["trigger"]) * size, "dmg": level_damage(w, lv), "fx": fx,
			"chain_r": float(w.get("chain_r", 0.0)), "chain_delay": float(w.get("chain_delay", 0.0))})


func _update_mines(delta: float) -> void:
	for m in _mines:
		m["t"] += delta
		if m["t"] < m["arm"]:
			continue
		if not m.get("armed", false):
			m["armed"] = true
			if not m["fx"].is_empty():
				m["fx"]["tint"] = Color.WHITE
				m["fx"]["light_k"] = 1.2
		if m.has("chain_at") and m["t"] >= m["chain_at"]:
			_mine_blast(m)
			continue
		for e in game.enemies.query_radius(m["pos"], m["trig"] + 12.0):
			if e.pos.distance_to(m["pos"]) <= m["trig"] + e.radius:
				_mine_blast(m)
				break
	_mines = _mines.filter(func(m): return not m.get("done", false) and m["t"] < m["life"])


func _mine_blast(m: Dictionary) -> void:
	if m.get("done", false):
		return
	Sfx.play("explosion")
	m["done"] = true
	if m.get("chain_r", 0.0) > 0.0:
		# Runic Chain: every armed rune near this one goes off a moment later
		for o in _mines:
			if not o.get("done", false) and o.get("armed", false) and o["pos"].distance_to(m["pos"]) <= m["chain_r"]:
				o["chain_at"] = o["t"] + float(m["chain_delay"])
	if not m["fx"].is_empty():
		m["fx"]["dead"] = true
	for e in game.enemies.query_radius(m["pos"], m["r"]):
		_hit(e, m["dmg"], Color(1.2, 1.6, 2.8))
	# rune_burst is riftbound/solar-burst in arcane colours: its ring reaches 44 px at scale 1
	game.vfx.play("rune_burst", m["pos"], 0.0, m["r"] / 44.0)
	game.screen_fx.shockwave(m["pos"], m["r"] * 1.6, 0.7, 0.35)
	game.screen_fx.shake(0.06)


# ------------------------------------------------------------------ character traits (mechanical passives)

func _trait() -> String:
	return String(game.player.character.get("trait", ""))


## Astra, Arcane Echo: a crit arcs to the nearest other foe for part of its damage (never crits itself).
func trait_echo(e, amount: float) -> void:
	var cfg: Dictionary = GameData.TRAITS["arcane_echo"]
	var other = game.enemies.nearest(e.pos, float(cfg["range"]), e)
	if other == null:
		return
	trait_procs += 1
	var d: Vector2 = other.pos - e.pos
	game.vfx.play("zap_hit", other.pos, d.angle(), clampf(d.length() / 85.0, 0.3, 0.9), Color(0.7, 1.0, 1.0))
	game.enemies.damage(other, amount * float(cfg["mult"]) * _tk())


## Kael, Retaliation: getting hit sends a sword wave through the foes around him.
func trait_on_hurt() -> void:
	if _trait() != "retaliation" or _retaliate_cd > 0.0:
		return
	var cfg: Dictionary = GameData.TRAITS["retaliation"]
	_retaliate_cd = float(cfg["cooldown"]) / _tk()
	trait_procs += 1
	var p: Player = game.player
	var r: float = float(cfg["radius"]) * p.area()
	for e in game.enemies.query_radius(p.position, r):
		_hit(e, p.dmg() * float(cfg["dmg"]) * _tk(), Color(0.9, 1.6, 2.4))
	game.vfx.ring(p.position, Color(0.8, 1.4, 2.0), r, 0.3, 2.0)
	for i in 8:
		var dir := Vector2.from_angle(TAU * i / 8.0)
		game.vfx.trail(p.position + dir * r * 0.6, Color(0.8, 1.3, 1.8), 2.0, 0.25)
	game.screen_fx.shockwave(p.position, r * 1.5, 0.6, 0.3)


## Wren, Page Guard: returns true (and starts the cooldown) when the ward swallows this hit.
func trait_block() -> bool:
	if _trait() != "page_guard" or _guard_cd > 0.0:
		return false
	_guard_cd = float(GameData.TRAITS["page_guard"]["cooldown"]) / _tk()
	trait_procs += 1
	var p: Player = game.player
	game.vfx.ring(p.position + Vector2(0, -6), Color(1.6, 1.5, 1.1), 16.0, 0.3, 1.5)
	game.vfx.motes(p.position + Vector2(0, -8), Color(1.8, 1.7, 1.3), 6, 30.0, 0.5, 2.0, -15.0)
	return true


## Lumi, Overflow: the damage past a foe's last HP refracts into the nearest other foe (next frame).
func trait_overflow(e, excess: float) -> void:
	if excess < float(GameData.TRAITS["overflow"]["min"]):
		return
	_trait_queue.append({"kind": "overflow", "pos": e.pos, "amount": excess})


## Celeste, Stargazer: a small star falls on a random nearby foe (uses the meteor strike queue).
func _stargazer() -> void:
	var cfg: Dictionary = GameData.TRAITS["stargazer"]
	var p: Player = game.player
	var foes: Array = game.enemies.query_radius(p.position, float(cfg["range"]))
	if foes.is_empty():
		return
	trait_procs += 1
	var e = foes[randi() % foes.size()]
	_strikes.append({"pos": e.pos, "t": 0.0, "delay": float(cfg["delay"]), "r": float(cfg["radius"]) * p.area(),
		"dmg": p.dmg() * float(cfg["dmg"]) * _tk(), "fx": false})


## Called by main for every kill: Lyra's Kindling, Nym's Thornheal, Noah's Plague, Raika, Vesper, Runa.
func trait_on_kill(e) -> void:
	arena.on_kill(e)   # Doom Sigil / Shatterfield
	# Plague Garden: a foe that dies poisoned by a garden cloud bursts into a small cloud of its own
	if e.has_meta("garden") and _time - float(e.get_meta("garden")) < 1.0 and game.player.weapon_levels.has("plague"):
		var w := GameData.weapon_by_id("plague")
		var clouds := _zones.filter(func(z): return z["kind"] == "venom" and z.get("small", false))
		if clouds.size() < int(w["spread_max"]):
			var fx: Dictionary = game.vfx.play("venom_cloud", e.pos, 0.0, float(w["spread_r"]) / 30.0, Color.WHITE, 0.9, float(w["spread_life"]))
			_zones.append({"kind": "venom", "pos": e.pos, "r": float(w["spread_r"]), "t": 0.0, "life": float(w["spread_life"]),
				"tick": float(w["tick"]), "tick_dmg": level_damage(w, int(game.player.weapon_levels["plague"])), "fx": fx, "garden": true, "small": true})
	match _trait():
		"static_charge":
			_static_kills += 1
			if _static_kills >= int(GameData.TRAITS["static_charge"]["kills"]):
				_static_kills = 0
				_trait_queue.append({"kind": "static", "pos": e.pos})
		"gravity_pull":
			if randf() < minf(0.9, float(GameData.TRAITS["gravity_pull"]["chance"]) * _tk()):
				_trait_queue.append({"kind": "gravity", "pos": e.pos})
		"rune_ward":
			if randf() < minf(0.9, float(GameData.TRAITS["rune_ward"]["chance"]) * _tk()):
				_trait_queue.append({"kind": "rune", "pos": e.pos})
		"kindling":
			if randf() < minf(0.9, float(GameData.TRAITS["kindling"]["chance"]) * _tk()):
				_trait_queue.append({"kind": "kindling", "pos": e.pos})
		"thornheal":
			if e.rooted_t > 0.0:
				trait_procs += 1
				game.player.heal(float(GameData.TRAITS["thornheal"]["heal"]) * _tk())
				game.vfx.motes(e.pos, Color(0.8, 2.0, 0.6), 3, 20.0, 0.5, 2.5, -20.0)
		"plague":
			var cfg: Dictionary = GameData.TRAITS["plague"]
			if _time - e.venom_hit_at <= float(cfg["poisoned_window"]) and randf() < minf(0.9, float(cfg["chance"]) * _tk()):
				_trait_queue.append({"kind": "plague", "pos": e.pos})


func _run_trait(t: Dictionary) -> void:
	var p: Player = game.player
	trait_procs += 1
	match t["kind"]:
		"static":
			var cfg: Dictionary = GameData.TRAITS["static_charge"]
			var cur = game.enemies.nearest(t["pos"], float(cfg["range"]), null)
			var prev: Vector2 = t["pos"]
			var done: Array = []
			game.vfx.flash(t["pos"], Color(1.4, 2.0, 2.8), 14.0, 0.14)
			for j in int(cfg["jumps"]):
				if cur == null:
					break
				done.append(cur)
				_hit(cur, p.dmg() * float(cfg["dmg"]) * _tk(), Color(1.2, 1.8, 2.8))
				var d: Vector2 = cur.pos - prev
				game.vfx.play("zap_hit", cur.pos, d.angle(), clampf(d.length() / 85.0, 0.35, 1.2))
				prev = cur.pos
				var nxt = null
				var best := INF
				for e in game.enemies.query_radius(cur.pos, float(cfg["jump_range"])):
					if e in done or not e.alive:
						continue
					var dd: float = e.pos.distance_squared_to(cur.pos)
					if dd < best:
						best = dd
						nxt = e
				cur = nxt
		"gravity":
			var cfg: Dictionary = GameData.TRAITS["gravity_pull"]
			var r: float = float(cfg["radius"]) * p.area()
			for e in game.enemies.query_radius(t["pos"], r):
				if not (e.boss or e.elite):
					var d: Vector2 = t["pos"] - e.pos
					e.pos += d.limit_length(minf(float(cfg["pull"]), d.length()))
				_hit(e, p.dmg() * float(cfg["dmg"]) * _tk(), Color(1.6, 0.9, 2.6))
			game.vfx.play("void_collapse", t["pos"], 0.0, r / BURST_REACH["void_collapse"] * 0.8, Color.WHITE, 0.5)
		"rune":
			var cfg: Dictionary = GameData.TRAITS["rune_ward"]
			var wards := _mines.filter(func(m): return m.get("ward", false))
			if wards.size() >= int(cfg["max"]):
				_mines.erase(wards[0])
				if not wards[0]["fx"].is_empty():
					wards[0]["fx"]["dead"] = true
			var size := p.area()
			var fx: Dictionary = game.vfx.play("rune_sigil", t["pos"], 0.0, size * MINE_FX_SCALE * 0.8, Color(1, 1, 1, 0.45), 0.6, float(cfg["life"]))
			_mines.append({"pos": t["pos"], "t": 0.0, "life": float(cfg["life"]), "arm": float(cfg["arm"]), "ward": true,
				"r": float(cfg["radius"]) * size, "trig": float(cfg["trigger"]) * size, "dmg": p.dmg() * float(cfg["dmg"]) * _tk(), "fx": fx})
		"overflow":
			var cfg: Dictionary = GameData.TRAITS["overflow"]
			var e = game.enemies.nearest(t["pos"], float(cfg["range"]), null)
			if e == null:
				return
			var d: Vector2 = e.pos - t["pos"]
			game.vfx.play("zap_hit", e.pos, d.angle(), clampf(d.length() / 85.0, 0.3, 0.9), Color(1.2, 0.9, 1.6))
			game.enemies.damage(e, t["amount"] * _tk())
		"kindling":
			var cfg: Dictionary = GameData.TRAITS["kindling"]
			var r: float = float(cfg["radius"]) * p.area()
			for e in game.enemies.query_radius(t["pos"], r):
				_hit(e, p.dmg() * float(cfg["dmg"]) * _tk(), Color(2.4, 1.1, 0.3))
			game.vfx.play("solar_burst", t["pos"], 0.0, r / 44.0)
		"plague":
			var cfg: Dictionary = GameData.TRAITS["plague"]
			if _zones.filter(func(z): return z.get("plague", false)).size() >= MAX_PLAGUE_CLOUDS:
				return
			var r: float = float(cfg["radius"]) * p.area()
			var fx: Dictionary = game.vfx.play("venom_cloud", t["pos"], 0.0, r / 30.0, Color.WHITE, 0.8, float(cfg["duration"]))
			_zones.append({"kind": "venom", "plague": true, "pos": t["pos"], "r": r, "t": 0.0, "life": float(cfg["duration"]),
				"tick": float(cfg["tick"]), "tick_dmg": p.dmg() * float(cfg["dmg"]) * _tk(), "fx": fx})


# ------------------------------------------------------------------ drawing

## Normal-blend layer: the familiars (sprite above a soft floor shadow).
func _draw() -> void:
	if _familiars.is_empty():
		return
	# PixelLab familiar: idle loop, shoot animation after each shot (crystal grid sprite if the strips are missing)
	var idle := CharacterArt.strip("res://assets/weapons/familiar/idle.png")
	var shoot := CharacterArt.strip("res://assets/weapons/familiar/shoot.png")
	var still := PixelSprites.texture("familiar")
	for f in _familiars:
		var pos: Vector2 = f["pos"]
		var tex: Texture2D = still
		var scale := 1.6
		if not idle.is_empty():
			scale = FAMILIAR_SCALE
			var sh: float = f.get("shot", 0.0)
			if sh > 0.0 and not shoot.is_empty():
				var k := 1.0 - sh / GameData.FAMILIAR_SHOT_TIME
				tex = shoot[mini(int(k * shoot.size()), shoot.size() - 1)]
			else:
				tex = idle[int((_time + float(f.get("phase", 0.0))) * GameData.FAMILIAR_ANIM_FPS) % idle.size()]
		var sz := Vector2(tex.get_width(), tex.get_height()) * scale
		draw_set_transform(pos, 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 7.0, Color(0, 0, 0, 0.28))
		draw_set_transform(pos - Vector2(0, f["hover"]), 0.0, Vector2(f["face"], 1.0))
		draw_texture_rect(tex, Rect2(-sz * 0.5, sz), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Additive layer: Astral Blades trails, Aether Beams and the familiars' glow.
func _draw_additive() -> void:
	_draw_blade_trails()
	for b in _beams:
		var k: float = 1.0 - b["t"] / b["life"]
		var wd: float = b["width"]
		if b.get("trace", false):
			# Celestial Ray's ground trace: a warm golden line that slowly fades
			_trail.draw_line(b["a"], b["b"], Color(0.9, 0.7, 0.2, 0.35 * k), wd * 2.2)
			_trail.draw_line(b["a"], b["b"], Color(1.3, 1.1, 0.5, 0.6 * k), maxf(1.0, wd * 0.6))
			continue
		# wide soft body, bright mid band, white-hot core that thins as the beam fades (afterglow)
		# kept below the bloom threshold except the thin core, so a long beam is heavy but not blinding
		_trail.draw_line(b["a"], b["b"], Color(0.15, 0.5, 0.9, 0.3 * k), wd * 1.8)
		_trail.draw_line(b["a"], b["b"], Color(0.3, 0.85, 1.2, 0.6 * k), wd * (0.5 + 0.5 * k))
		_trail.draw_line(b["a"], b["b"], Color(1.0, 1.4, 1.6, 0.8 * k), maxf(1.0, wd * 0.25 * k))
		_trail.draw_circle(b["b"], wd * 0.6 * k, Color(0.6, 1.2, 1.6, 0.6 * k))
		_trail.draw_circle(b["a"], wd * 0.8 * k, Color(0.9, 1.5, 1.8, 0.7 * k))
	for f in _familiars:
		var c: Vector2 = f["pos"] - Vector2(0, f["hover"])
		_trail.draw_texture_rect(game.vfx.glow_tex, Rect2(c - Vector2(9, 9), Vector2(18, 18)), false, Color(0.3, 0.9, 1.4, 0.22))


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
			var rim := Color(1.15, 1.55, 1.9, k0 * 0.85 * smoothstep(0.0, 0.25, u0 + 0.05))
			_trail.draw_line(c + d0 * (r_out - 0.5), c + d1 * (r_out - 0.5), rim, 1.0 * (1.0 - u0 * 0.5))


func _trail_col(u: float, k: float) -> Color:
	# the crescent's body stays under the bloom threshold (1.0) so it reads as a clear shape instead of a thick
	# glow (Syifa: glow too thick); only the thin rim drawn above it blooms
	var head := Color(0.85, 1.15, 1.4)  # white-cyan at the blade
	var mid := Color(0.25, 0.62, 1.05)  # cyan-blue
	var tail := Color(0.48, 0.25, 0.9)  # violet
	var col := head.lerp(mid, clampf(u * 2.5, 0.0, 1.0)) if u < 0.4 else mid.lerp(tail, (u - 0.4) / 0.6)
	return Color(col, k * 0.62)


func clear_blades() -> void:
	for inst in _blade_fx:
		inst["dead"] = true
	_blade_fx.clear()
