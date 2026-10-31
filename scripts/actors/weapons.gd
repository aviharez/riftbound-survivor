class_name Weapons
extends Node2D
## Fires every weapon the player owns. Numbers come from GameData.WEAPONS;
## this file holds each weapon's behaviour; visuals are pixelfx sprite effects
## played through game.vfx.

var game: Node
var _cd := {}            # weapon id -> seconds until next use
var _time := 0.0
var _orbs: Array = []    # Flame Orb world positions this frame
var _orb_trail_t := 0.0
var _bursts: Array = []  # pending Mana Burst detonations {pos, t, delay, r, dmg}


func _ready() -> void:
	pass


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
		# every weapon fires on its own rhythm (attack speed), with or without a target
		_cd[id] = level_cooldown(w, lv)
	_update_bursts(delta)
	if not p.weapon_levels.has("orb") and not _orb_fx.is_empty():
		clear_orbs()


func _hit(e, amount: float, color: Color) -> void:
	var crit := randf() < float(game.player.stats["crit"])
	game.enemies.damage(e, amount * (2.0 if crit else 1.0), crit)
	if crit:
		game.vfx.play("crit_hit", e.pos, randf_range(-0.4, 0.4), 0.26)
	else:
		game.vfx.sparks(e.pos, color, 3, 70.0, 0.18, 1.0)


# ------------------------------------------------------------------ weapons
# Visuals are pixelfx sprite effects played through game.vfx (see assets/vfx).

func _arcane_bolt(w: Dictionary, lv: int) -> bool:
	var p: Player = game.player
	var target = game.enemies.nearest(p.position, float(w["range"]), null)
	var count := count_of(w, lv)
	var base_dir: Vector2 = (target.pos - p.position).normalized() if target != null else p.facing
	for i in count:
		var spread: float = 0.0 if count == 1 else lerp(-0.18 * (count - 1), 0.18 * (count - 1), float(i) / (count - 1))
		game.projectiles.fire(p.position, base_dir.rotated(spread), level_damage(w, lv), int(p.stats["bounce"]), p.area())
	return true


func _frost_nova(w: Dictionary, lv: int) -> bool:
	var p: Player = game.player
	var r: float = float(w["radius"]) * level_size(w, lv)
	for e in game.enemies.query_radius(p.position, r):
		_hit(e, level_damage(w, lv), Color(0.7, 1.6, 2.4))
	# riftbound/frost-nova-td: the ring lies on the floor round the feet and reaches 60 px at scale 1
	game.vfx.play("frost_nova", p.position + Vector2(0, 5), 0.0, r / 60.0, Color.WHITE, 1.6, -1.0, p)
	game.screen_fx.shockwave(p.position, r * 1.3, 0.7, 0.4)
	game.screen_fx.shake(0.08)
	return true


var _orb_fx: Array = []   # looping spirit-flame instances, one per orb


func _flame_orb(w: Dictionary, lv: int, delta: float) -> void:
	var p: Player = game.player
	var count := count_of(w, lv)
	var r: float = float(w["radius"]) * level_size(w, lv)
	var hit_r: float = 6.0 * level_size(w, lv)
	var rehit := level_cooldown(w, lv)
	while _orb_fx.size() < count:
		var inst: Dictionary = game.vfx.play("spirit_flame", p.position, 0.0, 0.22 * level_size(w, lv), Color.WHITE, 1.8)
		if inst.is_empty():
			break
		_orb_fx.append(inst)
	_orb_trail_t -= delta
	var emit := _orb_trail_t <= 0.0
	if emit:
		_orb_trail_t = 0.05
	for i in count:
		var pos := p.position + Vector2.from_angle(_time * float(w["spin"]) + TAU * i / count) * r
		_orbs.append(pos)
		if i < _orb_fx.size():
			_orb_fx[i]["pos"] = pos + Vector2(0, 6)
			_orb_fx[i]["t"] = fmod(_orb_fx[i]["t"], 100.0)
		if emit:
			game.vfx.trail(pos, Color(2.2, 0.8, 0.2), 2.0, 0.25)
		for e in game.enemies.query_radius(pos, hit_r):
			if _time - e.orb_hit_at >= rehit:
				e.orb_hit_at = _time
				_hit(e, level_damage(w, lv), Color(2.4, 1.0, 0.3))


func _mana_burst(w: Dictionary, lv: int) -> bool:
	var p: Player = game.player
	var foes: Array = game.enemies.query_radius(p.position, float(w["range"]))
	var center: Vector2
	if foes.is_empty():
		# nothing in range: burst ahead of the player
		center = p.position + p.facing * float(w["range"]) * randf_range(0.3, 0.6)
	else:
		center = foes[randi() % foes.size()].pos
	var r: float = float(w["radius"]) * level_size(w, lv)
	# the effect gathers for ~0.25 s, then bursts: damage lands with the burst
	game.vfx.play("mana_burst", center, 0.0, r / 55.0)
	_bursts.append({"pos": center, "t": 0.0, "delay": 0.25, "r": r, "dmg": level_damage(w, lv)})
	return true


func _update_bursts(delta: float) -> void:
	for b in _bursts:
		b["t"] += delta
		if b["t"] >= b["delay"] and not b.get("done", false):
			b["done"] = true
			for e in game.enemies.query_radius(b["pos"], b["r"]):
				_hit(e, b["dmg"], Color(1.6, 0.7, 2.6))
			game.screen_fx.shockwave(b["pos"], b["r"] * 1.6, 1.0, 0.45)
			game.screen_fx.shake(0.12)
	_bursts = _bursts.filter(func(b): return not b.get("done", false))


func _storm_chain(w: Dictionary, lv: int) -> bool:
	var p: Player = game.player
	var cur = game.enemies.nearest(p.position, float(w["range"]), null)
	if cur == null:
		# nothing in range: a lone zap strikes the ground ahead
		var spot: Vector2 = p.position + p.facing * float(w["range"]) * 0.4
		game.vfx.play("zap_hit", spot, p.facing.angle(), 0.6)
		return true
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
	return true


func _spirit_blade(w: Dictionary, lv: int) -> bool:
	var p: Player = game.player
	var r: float = float(w["radius"]) * level_size(w, lv)
	for e in game.enemies.query_radius(p.position, r):
		_hit(e, level_damage(w, lv), Color(0.9, 2.4, 1.9))
	# spin-slash: an ellipse on the ground plane around the hero, ~85 px half-width at scale 1
	game.vfx.play("spin_slash", p.position + Vector2(0, 2), 0.0, r / 80.0, Color(0.85, 1.15, 1.0), 1.7, -1.0, p, true)
	game.screen_fx.shake(0.05)
	return true


func clear_orbs() -> void:
	for inst in _orb_fx:
		inst["dead"] = true
	_orb_fx.clear()
