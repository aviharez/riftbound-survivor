class_name WeaponsArena
extends Node2D
## The "arena" weapon set from the attack design doc: Hex Mark (#23), Glacial Burst (#24), Riftstorm (#20),
## Phantom Knight (#17), Prism Sweep (#21), Gravity Lens (#25), Holy Nova (#33, replaced Mirror Gate), Crystal
## Barricade (#27). Weapons calls `fire()` when one comes off cooldown; numbers are rows in GameData.WEAPONS. Lens and
## Barricade also act on the player's projectiles through `on_shot()` (called by Projectiles every frame).
## Data-oriented like the rest: plain dictionaries in arrays, drawn by this node (+ one additive child).

const IDS := ["hex", "glacial", "riftstorm", "phantom", "sweep", "lens", "nova", "barricade",
	"doom", "shatter", "cataclysm", "cavalry", "cage", "singularity", "dawn", "fortress"]   # + evolutions
const STRIKE_REACH := 38.0   # meteor_strike's fire ring at scale 1 (riftbound/meteor-strike)

var game: Node
var weapons: Weapons
var _strikes: Array = []    # Riftstorm {pos, t, delay, r, dmg, bolt}
var _knights: Array = []    # Phantom Knight {pos, dir, t, life, speed, w, dmg, hit, trail}
var _sweeps: Array = []     # Prism Sweep {a0, t, time, len, width, dmg, hit}
var _lenses: Array = []     # Gravity Lens {pos, r, t, life, bend, amp, dmg, tick}
var _novas: Array = []      # Holy Nova waves {t, delay, time, r, dmg, knock, hit}
var _walls: Array = []      # Crystal Barricade {a, b, n, t, life, push, dmg, tick}
var _cages: Array = []      # Prismatic Cage {pos, r, sides, t, life, rot, turn, dmg, tick, tick_t, slow, width}
var _shatters := 0          # Shatterfield bursts this second (caps chain reactions)
var _shatter_t := 0.0
var _doom_links: Array = [] # Doom Sigil: short violet threads from a dead foe to the foes it cursed {a, b, t}
var _glow: Node2D
var _time := 0.0
var _knight_tex: Texture2D


func _ready() -> void:
	_glow = Node2D.new()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = mat
	_glow.modulate = Vfx.additive_tint()
	_glow.draw.connect(_draw_glow)
	add_child(_glow)
	var path := "res://assets/enemies/armor.png"
	_knight_tex = load(path) if ResourceLoader.exists(path) else null


func fire(id: String, w: Dictionary, lv: int) -> void:
	match id:
		"hex": _hex(w, lv)
		"glacial": _glacial(w, lv)
		"riftstorm": _riftstorm(w, lv)
		"phantom": _phantom(w, lv)
		"sweep": _sweep(w, lv)
		"lens": _lens(w, lv)
		"nova": _nova(w, lv)
		"barricade": _barricade(w, lv)
		"doom": _hex(w, lv)
		"shatter": _glacial(w, lv)
		"cataclysm": _cataclysm(w, lv)
		"cavalry": _phantom(w, lv)
		"cage": _cage(w, lv)
		"singularity": _lens(w, lv)
		"dawn": _nova(w, lv)
		"fortress": _fortress(w, lv)


func _p() -> Player:
	return game.player


func _foes(r: float) -> Array:
	return game.enemies.query_radius(_p().position, r)


# ------------------------------------------------------------------ the eight weapons

## Marks the toughest foes in range: they take hex_amp more damage from everything while marked.
func _hex(w: Dictionary, lv: int) -> void:
	var foes := _foes(float(w["range"]))
	foes.sort_custom(func(a, b): return a.hp > b.hp)
	var amp: float = float(w["hex_amp"]) + float(w["lvl_amp"]) * (lv - 1)
	var marked := 0
	for e in foes:
		if marked >= weapons.count_of(w, lv):
			break
		if e.hex_t > 0.5:
			continue
		e.hex_t = float(w["hex_time"])
		e.hex_amp = maxf(e.hex_amp, amp)
		if w.has("spread_r"):
			e.set_meta("doom", true)   # Doom Sigil: the curse jumps on when this foe dies (on_kill)
		weapons._hit(e, weapons.level_damage(w, lv), Color(1.6, 0.5, 2.4))
		game.vfx.motes(e.pos, Color(1.4, 0.4, 2.2), 6, 30.0, 0.5, 2.0, -20.0)
		marked += 1


## An icy blast around the hero: slows (and from freeze_at, freezes) every foe it touches.
func _glacial(w: Dictionary, lv: int) -> void:
	var p := _p()
	var r: float = float(w["radius"]) * weapons.level_size(w, lv)
	game.vfx.play("frost_burst", p.position, 0.0, r / Weapons.BURST_REACH["frost_burst"])
	Sfx.play("freeze")
	game.screen_fx.shockwave(p.position, r * 1.5, 0.8, 0.4)
	for e in game.enemies.query_radius(p.position, r):
		if w.has("shatter_mult") and e.freeze_t > 0.0:
			# Shatterfield: a foe that is already frozen takes the heavy hit and bursts
			weapons._hit(e, weapons.level_damage(w, lv) * float(w["shatter_mult"]), Color(0.8, 1.8, 2.6))
			_shatter_burst(e.pos, w)
		else:
			weapons._hit(e, weapons.level_damage(w, lv), Color(0.8, 1.8, 2.6))
		if not e.alive:
			continue
		e.slow_t = maxf(e.slow_t, float(w["slow"]))
		if w.has("shatter_mult"):
			e.set_meta("shatter", true)
		if lv >= int(w["freeze_at"]):
			weapons._freeze(e, float(w["freeze"]))


## Rift lightning: marks foes (or random spots), then strikes each mark after a short warning.
func _riftstorm(w: Dictionary, lv: int) -> void:
	var p := _p()
	var foes := _foes(float(w["range"]))
	foes.shuffle()
	var r: float = float(w["radius"]) * weapons.level_size(w, lv)
	for i in weapons.count_of(w, lv):
		var spot: Vector2 = foes[i].pos if i < foes.size() \
			else p.position + Vector2.from_angle(randf() * TAU) * float(w["range"]) * randf_range(0.3, 0.7)
		_strikes.append({"pos": spot, "t": -0.12 * i, "delay": float(w["delay"]), "r": r, "dmg": weapons.level_damage(w, lv), "bolt": 0.0})


## A ghost knight rides out from behind the hero toward the nearest foe, cutting everything in its way.
func _phantom(w: Dictionary, lv: int) -> void:
	var p := _p()
	var foes := _foes(float(w["range"]))
	foes.sort_custom(func(a, b): return a.pos.distance_squared_to(p.position) < b.pos.distance_squared_to(p.position))
	for i in weapons.count_of(w, lv):
		var dir: Vector2 = (foes[i].pos - p.position).normalized() if i < foes.size() else p.facing.rotated(0.5 * i)
		_knights.append({"pos": p.position - dir * 20.0 + dir.orthogonal() * (i * 14.0), "dir": dir, "t": 0.0,
			"life": float(w["life"]), "speed": float(w["speed"]), "width": float(w["width"]) * weapons.level_size(w, lv),
			"dmg": weapons.level_damage(w, lv), "hit": [], "trail": [], "wait": float(w.get("stagger", 0.0)) * i,
			"big": w.has("stagger")})
	game.vfx.play("blink_out", p.position, 0.0, 0.5, Color(0.8, 0.6, 1.4))


## A beam that sweeps a full circle around the hero.
func _sweep(w: Dictionary, lv: int) -> void:
	var n := weapons.count_of(w, lv)
	var a0 := randf() * TAU
	for i in n:
		_sweeps.append({"a0": a0 + TAU * i / n, "t": 0.0, "time": float(w["sweep_time"]),
			"len": float(w["length"]) * weapons.level_size(w, lv), "width": float(w["width"]) * weapons.level_size(w, lv),
			"dmg": weapons.level_damage(w, lv), "hit": []})


## A lens over a random foe: shots passing through bend onto targets; foes inside take more damage.
func _lens(w: Dictionary, lv: int) -> void:
	var p := _p()
	var foes := _foes(float(w["range"]))
	for i in weapons.count_of(w, lv):
		var spot: Vector2 = foes[randi() % foes.size()].pos if not foes.is_empty() \
			else p.position + p.facing * float(w["range"]) * 0.5
		_lenses.append({"pos": spot, "r": float(w["radius"]) * weapons.level_size(w, lv), "t": 0.0, "life": float(w["duration"]),
			"bend": float(w["bend"]), "amp": float(w["lens_amp"]), "dmg": weapons.level_damage(w, lv), "tick": 0.0,
			"pull": float(w.get("pull", 0.0)), "w": w})


## A golden wave of light rings out from the hero (a second one follows from Lv 5): every foe the wave front
## passes is hit once and knocked back (bosses are only hit).
func _nova(w: Dictionary, lv: int) -> void:
	var r: float = float(w["radius"]) * weapons.level_size(w, lv)
	for i in weapons.count_of(w, lv):
		_novas.append({"t": -float(w["wave_gap"]) * i, "time": float(w["wave_time"]), "r": r,
			"dmg": weapons.level_damage(w, lv), "knock": float(w["knock"]), "hit": {}, "started": false,
			"heal": float(w.get("heal_per_hit", 0.0)), "heal_cap": float(w.get("heal_cap", 0.0)), "healed": 0.0})


## A crystal wall across the line between the hero and the nearest foe.
func _barricade(w: Dictionary, lv: int) -> void:
	var p := _p()
	var foes := _foes(220.0)
	foes.sort_custom(func(a, b): return a.pos.distance_squared_to(p.position) < b.pos.distance_squared_to(p.position))
	for i in weapons.count_of(w, lv):
		var dir: Vector2 = (foes[i].pos - p.position).normalized() if i < foes.size() else p.facing.rotated(PI * i)
		var mid: Vector2 = p.position + dir * 44.0
		var half: Vector2 = dir.orthogonal() * float(w["length"]) * weapons.level_size(w, lv) * 0.5
		_walls.append({"a": mid - half, "b": mid + half, "n": dir, "t": 0.0, "life": float(w["duration"]),
			"push": float(w["push"]), "dmg": weapons.level_damage(w, lv), "tick": 0.0, "tick_t": float(w["tick"])})
		game.vfx.sparks(mid, Color(0.9, 1.6, 2.6), 8, 80.0, 0.3, 1.5)
	while _walls.size() > 4:
		_walls.pop_front()


# ------------------------------------------------------------------ per frame

func _process(delta: float) -> void:
	_time += delta
	_update_strikes(delta)
	_update_knights(delta)
	_update_sweeps(delta)
	_update_lenses(delta)
	_update_novas(delta)
	_update_walls(delta)
	_update_cages(delta)
	_shatter_t -= delta
	if _shatter_t <= 0.0:
		_shatter_t = 1.0
		_shatters = 0
	for l in _doom_links:
		l["t"] += delta
	_doom_links = _doom_links.filter(func(l): return l["t"] < 0.35)
	queue_redraw()
	_glow.queue_redraw()


func _update_strikes(delta: float) -> void:
	for s in _strikes:
		s["t"] += delta
		s["bolt"] = maxf(0.0, s["bolt"] - delta)
		if s["t"] >= s["delay"] and not s.get("done", false):
			s["done"] = true
			s["bolt"] = 0.18
			for e in game.enemies.query_radius(s["pos"], s["r"]):
				weapons._hit(e, s["dmg"], Color(1.8, 0.7, 2.6))
			if s.get("big", false):
				# Cataclysm: the merged blast
				game.vfx.play("void_collapse", s["pos"], 0.0, s["r"] / Weapons.BURST_REACH["void_collapse"], Color(0.9, 0.7, 1.0), 0.35)
				game.screen_fx.shockwave(s["pos"], s["r"] * 1.6, 0.9, 0.45)
				game.screen_fx.shake(0.15)
			game.vfx.play("zap_hit", s["pos"], 0.0, s["r"] / 22.0, Color(1.0, 0.6, 1.4))
			Sfx.play("zap")
			game.vfx.flash(s["pos"], Color(1.6, 0.7, 2.4), s["r"] * 1.2, 0.15)
			game.screen_fx.shake(0.05)
	_strikes = _strikes.filter(func(s): return not s.get("done", false) or s["bolt"] > 0.0)


func _update_knights(delta: float) -> void:
	for k in _knights:
		if k["wait"] > 0.0:
			k["wait"] -= delta   # Spectral Cavalry: knights set off one after another
			continue
		k["t"] += delta
		var step: Vector2 = k["dir"] * k["speed"] * delta
		k["trail"].push_front(k["pos"])
		if k["trail"].size() > 5:
			k["trail"].pop_back()
		var a: Vector2 = k["pos"]
		k["pos"] += step
		for e in game.enemies.query_radius((a + k["pos"]) * 0.5, step.length() + k["width"] + 16.0):
			if e in k["hit"]:
				continue
			var q := Geometry2D.get_closest_point_to_segment(e.pos, a, k["pos"])
			if q.distance_to(e.pos) <= k["width"] * 0.5 + e.radius:
				k["hit"].append(e)
				weapons._hit(e, k["dmg"], Color(1.4, 0.8, 2.4))
	_knights = _knights.filter(func(k): return k["t"] < k["life"])


func _sweep_seg(s: Dictionary) -> Array:
	var p := _p()
	var ang: float = s["a0"] + TAU * clampf(s["t"] / s["time"], 0.0, 1.0)
	var a: Vector2 = p.position + Vector2(0, -6)
	return [a, a + Vector2.from_angle(ang) * s["len"]]


func _update_sweeps(delta: float) -> void:
	for s in _sweeps:
		s["t"] += delta
		var seg := _sweep_seg(s)
		for e in game.enemies.query_radius(_p().position, s["len"] + 16.0):
			if e in s["hit"]:
				continue
			var q := Geometry2D.get_closest_point_to_segment(e.pos, seg[0], seg[1])
			if q.distance_to(e.pos) <= s["width"] * 0.5 + e.radius:
				s["hit"].append(e)
				weapons._hit(e, s["dmg"], Color(2.2, 1.2, 2.6))
	_sweeps = _sweeps.filter(func(s): return s["t"] < s["time"])


func _update_lenses(delta: float) -> void:
	for l in _lenses:
		l["t"] += delta
		l["tick"] -= delta
		for e in game.enemies.query_radius(l["pos"], l["r"]):
			if l["pull"] > 0.0 and not e.boss and e.pos.distance_to(l["pos"]) > 6.0:
				# Singularity Engine: foes are dragged toward the centre
				e.pos = game.world.move(e.pos, (l["pos"] - e.pos).normalized() * l["pull"] * delta, e.radius * 0.6)
			e.hex_t = maxf(e.hex_t, 0.25)
			e.hex_amp = maxf(e.hex_amp, l["amp"])
			if l["tick"] <= 0.0:
				weapons._hit(e, l["dmg"], Color(0.8, 1.2, 2.6))
		if l["tick"] <= 0.0:
			l["tick"] = 0.6
	_lenses = _lenses.filter(func(l): return l["t"] < l["life"])


func _update_novas(delta: float) -> void:
	var c: Vector2 = _p().position
	for n in _novas:
		n["t"] += delta
		if n["t"] < 0.0:
			continue
		if not n["started"]:
			n["started"] = true
			Sfx.play("nova")
			game.vfx.flash(c, Color(2.2, 1.8, 0.9), 26.0, 0.2)
			game.screen_fx.shockwave(c, n["r"] * 1.3, 0.9, n["time"] + 0.1)
		var front: float = n["r"] * _ease_out(clampf(n["t"] / n["time"], 0.0, 1.0))
		var hit: Dictionary = n["hit"]
		for e in game.enemies.query_radius(c, front + 8.0):
			if hit.has(e) or not e.alive:
				continue
			hit[e] = true
			weapons._hit(e, n["dmg"], Color(2.4, 1.9, 0.9))
			if not e.boss:
				var away: Vector2 = (e.pos - c).normalized() if e.pos != c else Vector2.RIGHT
				e.knock = away * n["knock"] * GameData.ENEMY_KNOCK_DECAY
			game.vfx.sparks(e.pos, Color(2.4, 2.0, 1.0), 3, 50.0, 0.2, 1.2)
			if n["heal"] > 0.0 and n["healed"] < n["heal_cap"]:
				# Sacred Dawn: each foe the wave hits heals the hero a little (capped per wave)
				var h: float = minf(n["heal"], n["heal_cap"] - n["healed"])
				n["healed"] += h
				_p().heal(h)
	_novas = _novas.filter(func(n): return n["t"] < n["time"] + 0.25)


static func _ease_out(k: float) -> float:
	return 1.0 - (1.0 - k) * (1.0 - k)


func _update_walls(delta: float) -> void:
	for wl in _walls:
		wl["t"] += delta
		wl["tick"] -= delta
		var tick: bool = wl["tick"] <= 0.0
		if tick:
			wl["tick"] = wl["tick_t"]
		var mid: Vector2 = (wl["a"] + wl["b"]) * 0.5
		for e in game.enemies.query_radius(mid, wl["a"].distance_to(wl["b"]) * 0.5 + 16.0):
			var q := Geometry2D.get_closest_point_to_segment(e.pos, wl["a"], wl["b"])
			if q.distance_to(e.pos) <= e.radius + 4.0:
				# push the foe back to the far side of the wall
				var away: Vector2 = wl["n"] if (e.pos - q).dot(wl["n"]) >= 0.0 else -wl["n"]
				if not e.boss:
					e.pos = game.world.move(e.pos, away * wl["push"] * delta * 3.0, e.radius * 0.6)
				if tick:
					weapons._hit(e, wl["dmg"], Color(0.9, 1.6, 2.6))
		# enemy bolts break on the crystal
		for b in game.enemies.bullets:
			var qb := Geometry2D.get_closest_point_to_segment(b["pos"], wl["a"], wl["b"])
			if qb.distance_to(b["pos"]) <= 5.0:
				b["life"] = 0.0
	_walls = _walls.filter(func(wl): return wl["t"] < wl["life"])


## Called by Projectiles for every player shot each frame: lenses bend it onto targets, walls bounce it.
func on_shot(s: Dictionary, delta: float) -> void:
	if s.has("orbit"):
		_orbit_shot(s, delta)
		return
	for l in _lenses:
		if l["pull"] > 0.0 and not s.get("orbited", false) and s["pos"].distance_to(l["pos"]) <= l["r"]:
			# Singularity Engine: the shot is captured and circles the centre before it strikes
			var lw: Dictionary = l["w"]
			s["orbit"] = {"c": l["pos"], "a": (s["pos"] - l["pos"]).angle(), "t": 0.0, "r": float(lw["orbit_r"]),
				"time": float(lw["orbit_time"]), "speed": float(lw["orbit_speed"]), "boost": float(lw["orbit_boost"]),
				"v": s["vel"].length()}
			s["orbited"] = true
			_orbit_shot(s, delta)
			return
		if s["pos"].distance_to(l["pos"]) <= l["r"]:
			var foe = game.enemies.nearest(s["pos"], l["r"] * 1.5, null)
			if foe != null:
				var want: float = (foe.pos - s["pos"]).angle()
				var cur: float = s["vel"].angle()
				var turn := clampf(wrapf(want - cur, -PI, PI), -l["bend"] * delta, l["bend"] * delta)
				s["vel"] = s["vel"].rotated(turn)
	for wl in _walls:
		if s.get("walled", 0.0) > _time:
			continue
		var q := Geometry2D.get_closest_point_to_segment(s["pos"], wl["a"], wl["b"])
		if q.distance_to(s["pos"]) <= 4.0 and s["vel"].dot(wl["n"]) < 0.0:
			# shots coming back at the hero side bounce off the crystal (outbound ones pass through)
			s["vel"] = s["vel"].bounce(wl["n"])
			s["walled"] = _time + 0.2
			if wl.get("boost", 0.0) > 0.0 and int(s.get("fort_bounces", 0)) < 4:
				# Prismatic Fortress: each bounce off a fortress wall makes the shot stronger (up to 4 times)
				s["fort_bounces"] = int(s.get("fort_bounces", 0)) + 1
				s["dmg"] *= 1.0 + wl["boost"]
				game.vfx.sparks(s["pos"], Color(1.2, 1.6, 2.6), 3, 60.0, 0.15, 1.2)
			s["hit"].clear()


## A shot held by a Singularity Engine: circles the centre, then flies at the nearest foe with a damage boost.
func _orbit_shot(s: Dictionary, delta: float) -> void:
	var o: Dictionary = s["orbit"]
	o["t"] += delta
	o["a"] += o["speed"] * delta
	s["life"] = maxf(s["life"], 0.3)
	var r: float = lerpf(s["pos"].distance_to(o["c"]), o["r"], minf(1.0, delta * 10.0))
	s["pos"] = o["c"] + Vector2.from_angle(o["a"]) * r
	s["vel"] = Vector2.from_angle(o["a"] + PI * 0.5) * o["v"]
	if o["t"] >= o["time"]:
		s.erase("orbit")
		s["dmg"] *= 1.0 + o["boost"]
		s["hit"].clear()
		s["life"] = maxf(s["life"], s["life0"] * 0.7)
		var foe = game.enemies.nearest(s["pos"], 220.0, null)
		var dir: Vector2 = (foe.pos - s["pos"]).normalized() if foe != null else Vector2.from_angle(o["a"])
		s["vel"] = dir * o["v"] * 1.2


## Called by Weapons.trait_on_kill for every kill: Doom Sigil spreads its curse, Shatterfield bursts frozen foes.
func on_kill(e) -> void:
	var lv_of: Dictionary = _p().weapon_levels
	if lv_of.has("doom") and e.has_meta("doom"):
		var w := GameData.weapon_by_id("doom")
		var near: Array = game.enemies.query_radius(e.pos, float(w["spread_r"]))
		near.sort_custom(func(a, b): return a.pos.distance_squared_to(e.pos) < b.pos.distance_squared_to(e.pos))
		var n := 0
		for f in near:
			if n >= int(w["spread_n"]) or f == e or not f.alive or f.has_meta("doom"):
				continue
			f.hex_t = float(w["hex_time"])
			f.hex_amp = maxf(f.hex_amp, float(w["hex_amp"]))
			f.set_meta("doom", true)
			_doom_links.append({"a": e.pos, "b": f.pos, "t": 0.0})
			weapons._hit(f, weapons.level_damage(w, 8) * float(w["spread_dmg"]), Color(1.6, 0.5, 2.4))
			n += 1
		if n > 0:
			game.vfx.play("rune_burst", e.pos, 0.0, 0.5, Color(1.3, 0.5, 1.8))
	if lv_of.has("shatter") and e.has_meta("shatter") and e.freeze_t > 0.0:
		_shatter_burst(e.pos, GameData.weapon_by_id("shatter"))


## Shatterfield: a frozen foe breaks into a crystal burst that hits the foes around it.
func _shatter_burst(pos: Vector2, w: Dictionary) -> void:
	if _shatters >= int(w["shatter_max"]):
		return
	_shatters += 1
	var r: float = float(w["shatter_r"]) * _p().area()
	game.vfx.play("frost_burst", pos, 0.0, r / Weapons.BURST_REACH["frost_burst"], Color(0.9, 1.1, 1.3))
	game.vfx.sparks(pos, Color(1.0, 1.8, 2.6), 6, 90.0, 0.25, 1.4)
	var dmg: float = weapons.level_damage(w, 8) * float(w["shatter_dmg"]) / float(w["dmg"])
	for f in game.enemies.query_radius(pos, r):
		if f.alive:
			weapons._hit(f, dmg, Color(0.8, 1.8, 2.6))


## Cataclysm: a ring of strikes around the biggest crowd, then one large blast where they meet.
func _cataclysm(w: Dictionary, lv: int) -> void:
	var p := _p()
	var foes := _foes(float(w["range"]))
	var c: Vector2 = p.position + p.facing * 90.0
	if not foes.is_empty():
		var best := -1
		for f in foes.slice(0, 12):
			var k: int = game.enemies.query_radius(f.pos, 60.0).size()
			if k > best:
				best = k
				c = f.pos
	var n := weapons.count_of(w, lv)
	var size := weapons.level_size(w, lv)
	var a0 := randf() * TAU
	for i in n:
		_strikes.append({"pos": c + Vector2.from_angle(a0 + TAU * i / n) * float(w["ring_r"]) * size * Vector2(1.0, 0.6),
			"t": -0.06 * i, "delay": float(w["delay"]), "r": float(w["radius"]) * size, "dmg": weapons.level_damage(w, lv), "bolt": 0.0})
	_strikes.append({"pos": c, "t": -0.06 * n - float(w["big_delay"]), "delay": float(w["delay"]), "r": float(w["big_r"]) * size,
		"dmg": weapons.level_damage(w, lv) * float(w["big_dmg"]), "bolt": 0.0, "big": true})


## Prismatic Cage: a turning hexagon of prism beams around a crowd.
func _cage(w: Dictionary, lv: int) -> void:
	var p := _p()
	var foes := _foes(float(w["range"]))
	var size := weapons.level_size(w, lv)
	for i in weapons.count_of(w, lv):
		var spot: Vector2 = foes[randi() % foes.size()].pos if not foes.is_empty() else p.position + p.facing * 80.0
		_cages.append({"pos": spot, "r": float(w["radius"]) * size, "sides": int(w["sides"]), "t": 0.0, "life": float(w["duration"]),
			"rot": randf() * TAU, "turn": float(w["turn"]), "dmg": weapons.level_damage(w, lv), "tick": 0.0,
			"tick_t": float(w["tick"]), "slow": float(w["slow"]), "width": float(w["width"]) * size})
		game.vfx.flash(spot, Color(1.6, 1.4, 2.2), 30.0, 0.15)
	while _cages.size() > 3:
		_cages.pop_front()


func _cage_points(c: Dictionary) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in c["sides"] + 1:
		pts.append(c["pos"] + Vector2.from_angle(c["rot"] + TAU * i / c["sides"]) * c["r"] * Vector2(1.0, 0.7))
	return pts


func _update_cages(delta: float) -> void:
	for c in _cages:
		c["t"] += delta
		c["rot"] += c["turn"] * delta
		c["tick"] -= delta
		var tick: bool = c["tick"] <= 0.0
		if tick:
			c["tick"] = c["tick_t"]
		var pts := _cage_points(c)
		for e in game.enemies.query_radius(c["pos"], c["r"] + 12.0):
			if not e.alive:
				continue
			var inside := Geometry2D.is_point_in_polygon(e.pos, pts.slice(0, c["sides"]))
			if inside:
				e.slow_t = maxf(e.slow_t, c["slow"])
			if not tick:
				continue
			for i in c["sides"]:
				var q := Geometry2D.get_closest_point_to_segment(e.pos, pts[i], pts[i + 1])
				if q.distance_to(e.pos) <= c["width"] * 0.5 + e.radius:
					weapons._hit(e, c["dmg"], Color(2.2, 1.2, 2.6))
					break
	_cages = _cages.filter(func(c): return c["t"] < c["life"])


## Prismatic Fortress: four crystal walls in a diamond around the hero (each wall faces outward).
func _fortress(w: Dictionary, lv: int) -> void:
	var p := _p()
	var size := weapons.level_size(w, lv)
	var n := weapons.count_of(w, lv)
	for i in n:
		var dir := Vector2.from_angle(PI * 0.25 + TAU * i / n)
		var mid: Vector2 = p.position + dir * float(w["ring_r"]) * size
		var half: Vector2 = dir.orthogonal() * float(w["length"]) * size * 0.5
		_walls.append({"a": mid - half, "b": mid + half, "n": dir, "t": 0.0, "life": float(w["duration"]),
			"push": float(w["push"]), "dmg": weapons.level_damage(w, lv), "tick": 0.0, "tick_t": float(w["tick"]),
			"boost": float(w["bounce_boost"])})
		game.vfx.sparks(mid, Color(0.9, 1.6, 2.6), 6, 80.0, 0.3, 1.5)
	while _walls.size() > 8:
		_walls.pop_front()


func clear_all() -> void:
	for a in [_strikes, _knights, _sweeps, _lenses, _novas, _walls, _cages, _doom_links]:
		a.clear()


# ------------------------------------------------------------------ drawing

func _draw() -> void:
	# Phantom Knight: the hollow armor sprite, ghostly violet, with fading afterimages
	if _knight_tex != null:
		for k in _knights:
			var fade: float = 1.0 - k["t"] / k["life"]
			if k["wait"] > 0.0:
				continue
			var sz := Vector2(44, 44) if k["big"] else Vector2(36, 36)
			var flip := -1.0 if k["dir"].x < 0.0 else 1.0
			for i in k["trail"].size():
				draw_set_transform(k["trail"][i], 0.0, Vector2(flip, 1.0))
				draw_texture_rect(_knight_tex, Rect2(-sz * 0.5, sz), false, Color(0.7, 0.5, 1.4, 0.18 * fade * (1.0 - i / 5.0)))
			draw_set_transform(k["pos"], 0.0, Vector2(flip, 1.0))
			draw_texture_rect(_knight_tex, Rect2(-sz * 0.5, sz), false, Color(0.85, 0.7, 1.5, 0.8 * fade))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Crystal Barricade: faceted wall (top-down: a row of crystal prisms)
	for wl in _walls:
		var k: float = clampf((wl["life"] - wl["t"]) / 0.4, 0.0, 1.0) * clampf(wl["t"] / 0.15, 0.0, 1.0)
		var seg: Vector2 = wl["b"] - wl["a"]
		var n := int(maxf(3.0, seg.length() / 10.0))
		for i in n:
			var c: Vector2 = wl["a"] + seg * ((i + 0.5) / n)
			var hgt := 10.0 + 4.0 * sin(i * 2.3)
			var pts := PackedVector2Array([c + Vector2(-5, 2), c + Vector2(-3, -hgt), c + Vector2(0, -hgt - 4), c + Vector2(3, -hgt), c + Vector2(5, 2)])
			draw_colored_polygon(pts, Color(0.35, 0.55, 0.95, 0.85 * k))
			draw_polyline(pts, Color(0.75, 0.95, 1.0, k), 1.0)
			draw_line(c + Vector2(0, -hgt - 3), c + Vector2(0, 1), Color(0.8, 0.6, 1.0, 0.7 * k), 1.0)


func _draw_glow() -> void:
	# Riftstorm: warning circle, then a bolt from the sky
	for s in _strikes:
		if not s.get("done", false):
			var k := clampf(s["t"] / s["delay"], 0.0, 1.0)
			_glow.draw_set_transform(s["pos"], 0.0, Vector2(1.0, 0.6))
			_glow.draw_arc(Vector2.ZERO, s["r"], 0, TAU, 28, Color(0.8, 0.3, 1.2, 0.5 * k), 1.5)
			_glow.draw_circle(Vector2.ZERO, s["r"] * k, Color(0.5, 0.15, 0.8, 0.18))
			_glow.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		elif s["bolt"] > 0.0:
			var b: float = s["bolt"] / 0.18
			var top: Vector2 = s["pos"] + Vector2(randf_range(-6, 6), -160)
			var pts := PackedVector2Array([top])
			for i in range(1, 6):
				pts.append(top.lerp(s["pos"], i / 6.0) + Vector2(randf_range(-7, 7), 0))
			pts.append(s["pos"])
			_glow.draw_polyline(pts, Color(1.2, 0.5, 2.0, b), 3.0)
			_glow.draw_polyline(pts, Color(2.0, 1.6, 2.6, b), 1.0)
	# Prism Sweep: a rainbow-edged beam
	for s in _sweeps:
		var seg := _sweep_seg(s)
		var hue := fmod(_time * 0.8, 1.0)
		var col := Color.from_hsv(hue, 0.5, 1.0)
		_glow.draw_line(seg[0], seg[1], Color(col.r * 0.4, col.g * 0.4, col.b * 0.4, 0.4), s["width"] * 1.8)
		_glow.draw_line(seg[0], seg[1], Color(col.r, col.g, col.b, 0.7), s["width"] * 0.6)
		_glow.draw_line(seg[0], seg[1], Color(1.4, 1.4, 1.5, 0.9), maxf(1.0, s["width"] * 0.2))
	# Gravity Lens: rings drawn inward
	for l in _lenses:
		var k: float = clampf((l["life"] - l["t"]) / 0.5, 0.0, 1.0)
		_glow.draw_set_transform(l["pos"], 0.0, Vector2(1.0, 0.6))
		for i in 3:
			var rr: float = l["r"] * (1.0 - fmod(_time * 0.6 + i / 3.0, 1.0))
			_glow.draw_arc(Vector2.ZERO, rr, 0, TAU, 32, Color(0.3, 0.6, 1.3, 0.35 * k), 1.5)
		_glow.draw_arc(Vector2.ZERO, l["r"], 0, TAU, 40, Color(0.5, 0.8, 1.6, 0.6 * k), 1.0)
		_glow.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Holy Nova: a flat golden floor ring (ellipse, sy 0.6) with a soft inner glow, thinning as it widens
	for n in _novas:
		if n["t"] < 0.0:
			continue
		var k: float = clampf(n["t"] / n["time"], 0.0, 1.0)
		var fade: float = 1.0 - clampf((n["t"] - n["time"]) / 0.25, 0.0, 1.0)
		var front: float = n["r"] * _ease_out(k)
		_glow.draw_set_transform(_p().position, 0.0, Vector2(1.0, 0.6))
		_glow.draw_circle(Vector2.ZERO, front, Color(0.5, 0.38, 0.1, 0.22 * (1.0 - k) * fade))
		_glow.draw_arc(Vector2.ZERO, front, 0, TAU, 48, Color(1.0, 0.75, 0.25, 0.55 * fade), 7.0 * (1.0 - 0.6 * k))
		_glow.draw_arc(Vector2.ZERO, front, 0, TAU, 48, Color(1.9, 1.6, 0.8, 0.9 * fade), 2.0)
		_glow.draw_arc(Vector2.ZERO, front * 0.8, 0, TAU, 40, Color(1.2, 1.0, 0.5, 0.35 * fade), 1.0)
		for i in 12:
			var a: float = TAU * i / 12.0 + _time * 0.8
			_glow.draw_circle(Vector2.from_angle(a) * front, 2.0, Color(2.0, 1.8, 1.0, 0.8 * fade))
		_glow.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Prismatic Cage: a turning hexagon of rainbow beams over a faint floor fill
	for c in _cages:
		var k: float = clampf((c["life"] - c["t"]) / 0.4, 0.0, 1.0) * clampf(c["t"] / 0.2, 0.0, 1.0)
		var pts := _cage_points(c)
		_glow.draw_colored_polygon(pts.slice(0, c["sides"]), Color(0.35, 0.25, 0.55, 0.12 * k))
		for i in c["sides"]:
			var col := Color.from_hsv(fmod(_time * 0.5 + float(i) / c["sides"], 1.0), 0.5, 1.0)
			_glow.draw_line(pts[i], pts[i + 1], Color(col.r * 0.4, col.g * 0.4, col.b * 0.4, 0.4 * k), c["width"] * 1.6)
			_glow.draw_line(pts[i], pts[i + 1], Color(col.r, col.g, col.b, 0.75 * k), c["width"] * 0.5)
			_glow.draw_circle(pts[i], 2.5, Color(1.4, 1.4, 1.6, 0.8 * k))
	# Doom Sigil: violet threads from a dead foe to the foes its curse jumped to
	for l in _doom_links:
		var k: float = 1.0 - l["t"] / 0.35
		_glow.draw_line(l["a"], l["b"], Color(1.2, 0.3, 1.8, 0.8 * k), 2.0)
	# Hex marks: violet runes circling under marked foes
	for e in game.enemies.list:
		if e.hex_t > 0.0 and e.alive:
			var k := clampf(e.hex_t / 0.5, 0.0, 1.0)
			_glow.draw_set_transform(e.pos + Vector2(0, e.radius * 0.6), 0.0, Vector2(1.0, 0.55))
			_glow.draw_arc(Vector2.ZERO, e.radius + 4.0, _time * 3.0, _time * 3.0 + TAU * 0.8, 16, Color(1.3, 0.3, 1.8, 0.7 * k), 1.5)
			_glow.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
