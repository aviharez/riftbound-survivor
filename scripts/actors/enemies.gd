class_name Enemies
extends Node2D
## Data-oriented enemy manager: all enemies, the boss and enemy bullets live in
## arrays and are drawn by this one node (cheap on mobile, no node per enemy).

const HASH_CELL := 32.0
const SPAWN_ANIM := 0.5

class Enemy:
	var pos := Vector2.ZERO
	var type := "slime"
	var hp := 10.0
	var max_hp := 10.0
	var radius := 6.0
	var speed := 40.0
	var dmg := 5.0
	var color := Color.WHITE
	var xp := 1
	var ranged := false
	var elite := false
	var affix := ""
	var shield := 0
	var boss := false
	var trial_id := -1
	var spawn_t := 0.0
	var flash := 0.0
	var shoot_t := 2.0
	var blade_hit_at := -100.0  # Astral Blades re-hit timer
	var root_hit_at := -100.0   # Thornseed roots / Void Well tick timer
	var slow_t := 0.0           # seconds of slow left (roots, frost)
	var freeze_t := 0.0         # seconds frozen solid (Absolute Zero, Worldroot traps): no move, no contact damage
	var trap_at := -100.0       # last Worldroot trap (re-trap cooldown)
	var venom_hit_at := -100.0  # Venom Bloom tick timer
	var rooted_t := 0.0         # inside a Thornseed snare (drawn tinted green)
	var alive := true
	var ghost := false   # drifts through walls (Final Swarm wraiths)
	var def: Dictionary = {}    # its GameData.ENEMY_TYPES row (behaviour flags)
	var act_t := 0.0            # dash / blink cooldown
	# boss state machine
	var state := "idle"
	var state_t := 1.5
	var pattern := 0
	var dash_dir := Vector2.ZERO

var game: Node
var list: Array = []
var bullets: Array = []   # {pos, vel, dmg, life}
var boss: Enemy = null
var _hash := {}
var _flow_ok := false


func count() -> int:
	return list.size()


func spawn(type: String, pos: Vector2, hp_mult: float, speed_mult: float, elite := false, affix := "") -> Enemy:
	var d: Dictionary = GameData.ENEMY_TYPES[type]
	var e := Enemy.new()
	e.pos = pos
	e.type = type
	e.max_hp = float(d["hp"]) * hp_mult
	e.radius = float(d["radius"])
	e.speed = float(d["speed"]) * speed_mult * randf_range(0.9, 1.1)
	e.dmg = float(d["dmg"])
	e.color = d["color"]
	e.xp = int(d["xp"])
	e.ranged = bool(d.get("ranged", false))
	e.ghost = bool(d.get("ghost", false))
	e.def = d
	e.act_t = randf_range(1.0, GameData.ENEMY_DASH_EVERY)
	e.spawn_t = SPAWN_ANIM
	if elite:
		e.elite = true
		e.affix = affix
		e.max_hp *= GameData.ELITE_HP_MULT
		e.radius *= GameData.ELITE_SCALE
		e.dmg *= 1.5
		e.xp *= 10
		match affix:
			"swift": e.speed *= 1.4
			"warded": e.shield = 3
	e.hp = e.max_hp
	list.append(e)
	return e


func spawn_boss(pos: Vector2, hp_mult: float) -> Enemy:
	var cfg: Dictionary = game.boss_cfg
	var b := Enemy.new()
	b.boss = true
	b.type = "boss"
	b.pos = pos
	b.max_hp = float(cfg["hp"]) * hp_mult
	b.hp = b.max_hp
	b.radius = float(cfg["radius"])
	b.speed = float(cfg["speed"])
	b.dmg = float(cfg["dmg"])
	b.color = Color(0.45, 0.2, 0.55)
	b.xp = 50
	b.spawn_t = 1.0
	list.append(b)
	boss = b
	return b


func damage(e: Enemy, amount: float, crit := false) -> void:
	if not e.alive or e.spawn_t > 0.0:
		return
	if e.shield > 0:
		e.shield -= 1
		e.flash = 0.08
		return
	var tr: String = game.player.character.get("trait", "")
	if tr == "frostbite" and (e.slow_t > 0.0 or e.freeze_t > 0.0):
		amount *= 1.0 + (float(GameData.TRAITS["frostbite"]["mult"]) - 1.0) * game.player.trait_power   # Selene: slowed / frozen foes take more
		game.weapons.trait_procs += 1
	if tr == "duelist" and (e.elite or e.boss):
		amount *= 1.0 + (float(GameData.TRAITS["duelist"]["mult"]) - 1.0) * game.player.trait_power   # Sera: elites and bosses take more
		game.weapons.trait_procs += 1
	e.hp -= amount
	e.flash = 0.08
	game.player.damage_dealt += amount
	game.spawn_damage_number(e.pos, amount, crit)
	if crit and tr == "arcane_echo" and e.alive:
		game.weapons.trait_echo(e, amount)   # Astra: crits arc to a nearby foe
	if e.hp <= 0.0:
		if tr == "overflow" and e.alive:
			game.weapons.trait_overflow(e, -e.hp)   # Lumi: overkill refracts to the nearest foe
		_kill(e)


func _kill(e: Enemy) -> void:
	e.alive = false
	game.on_enemy_killed(e)
	var split = e.def.get("split")
	if split != null and not e.elite:
		for i in int(split[1]):
			var s2 := spawn(String(split[0]), e.pos + Vector2.from_angle(TAU * i / float(split[1]) + randf()) * 8.0, game.hp_mult(), 1.0)
			s2.spawn_t = 0.0
	if e.affix == "splitter":
		for i in 4:
			var s := spawn(String(GameData.location_by_id(game.location_id)["enemies"][0]), e.pos + Vector2.from_angle(TAU * i / 4.0) * 8.0, game.hp_mult() * 0.6, 1.2)
			s.spawn_t = 0.0
	if e == boss:
		boss = null


## Moves the farthest enemy back onto the spawn ring instead of creating a new one.
func recycle_farthest(new_pos: Vector2) -> bool:
	var far: Enemy = null
	var far_d := -1.0
	for e in list:
		if e.elite or e.boss or e.trial_id >= 0:
			continue
		var d: float = e.pos.distance_squared_to(game.player.position)
		if d > far_d:
			far_d = d
			far = e
	if far == null:
		return false
	far.pos = new_pos
	far.spawn_t = SPAWN_ANIM
	return true


func nearest(p: Vector2, max_dist: float, exclude) -> Enemy:
	var best: Enemy = null
	var best_d := max_dist * max_dist
	for e in query_radius(p, max_dist):
		if e == exclude:
			continue
		var d: float = e.pos.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = e
	return best


func query_radius(p: Vector2, r: float) -> Array:
	var out: Array = []
	var c0 := Vector2i(floori((p.x - r) / HASH_CELL), floori((p.y - r) / HASH_CELL))
	var c1 := Vector2i(floori((p.x + r) / HASH_CELL), floori((p.y + r) / HASH_CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var bucket = _hash.get(Vector2i(cx, cy))
			if bucket == null:
				continue
			for e in bucket:
				if e.alive and e.spawn_t <= 0.0 and e.pos.distance_to(p) <= r + e.radius:
					out.append(e)
	return out


func _rebuild_hash() -> void:
	_hash.clear()
	for e in list:
		var k := Vector2i(floori(e.pos.x / HASH_CELL), floori(e.pos.y / HASH_CELL))
		if not _hash.has(k):
			_hash[k] = []
		_hash[k].append(e)


func _process(delta: float) -> void:
	var player: Player = game.player
	var ppos := player.position
	var speed_mult: float = game.speed_mult()
	_rebuild_hash()
	for e in list:
		if not e.alive:
			continue
		e.flash = max(0.0, e.flash - delta)
		e.slow_t = max(0.0, e.slow_t - delta)
		e.rooted_t = max(0.0, e.rooted_t - delta)
		if e.spawn_t > 0.0:
			e.spawn_t -= delta
			continue
		if e.freeze_t > 0.0:
			e.freeze_t -= delta
			continue
		if e.boss:
			_boss_update(e, delta)
		else:
			if not _act(e, ppos, delta):
				_walk(e, ppos, delta, speed_mult)
			if e.ranged:
				e.shoot_t -= delta
				if e.shoot_t <= 0.0 and e.pos.distance_to(ppos) < 200.0:
					e.shoot_t = 2.5
					var n := int(e.def.get("spread", 1))
					var aim: float = (ppos - e.pos).angle()
					for i in n:
						_shoot(e.pos, Vector2.from_angle(aim + (i - (n - 1) * 0.5) * GameData.ENEMY_SPREAD_ANGLE) * 70.0, 8.0)
		if e.pos.distance_to(ppos) < e.radius + Player.RADIUS:
			player.take_damage(e.dmg)
	list = list.filter(func(e): return e.alive)
	_update_bullets(delta, player)
	queue_redraw()


## Special moves from the enemy's flags (dash charge, blink). True while it replaces walking this frame.
func _act(e: Enemy, ppos: Vector2, delta: float) -> bool:
	if e.def.get("dash", false):
		match e.state:
			"telegraph":
				e.state_t -= delta
				if e.state_t <= 0.0:
					e.state = "dash"
					e.state_t = GameData.ENEMY_DASH_TIME
				return true
			"dash":
				e.state_t -= delta
				e.pos = game.world.move(e.pos, e.dash_dir * e.speed * GameData.ENEMY_DASH_SPEED * delta, e.radius * 0.6)
				if e.state_t <= 0.0:
					e.state = "idle"
					e.act_t = GameData.ENEMY_DASH_EVERY
				return true
		e.act_t -= delta
		if e.act_t <= 0.0 and e.pos.distance_to(ppos) < GameData.ENEMY_DASH_RANGE:
			e.state = "telegraph"
			e.state_t = GameData.ENEMY_DASH_TELEGRAPH
			e.dash_dir = (ppos - e.pos).normalized()
			return true
	if e.def.get("blink", false):
		e.act_t -= delta
		if e.act_t <= 0.0:
			e.act_t = GameData.ENEMY_BLINK_EVERY
			if e.pos.distance_to(ppos) > GameData.ENEMY_BLINK_DIST * 1.3:
				var to := ppos + Vector2.from_angle(randf() * TAU) * GameData.ENEMY_BLINK_DIST
				if not game.world.box_hits(to, e.radius * 0.6):
					game.vfx.motes(e.pos, Color(1.6, 0.6, 2.2), 6, 30.0, 0.4, 2.0, -10.0)
					e.pos = to
					e.shoot_t = minf(e.shoot_t, 0.6)
					game.vfx.motes(to, Color(1.6, 0.6, 2.2), 6, 30.0, 0.4, 2.0, -10.0)
	return false


func _walk(e: Enemy, target: Vector2, delta: float, speed_mult: float) -> void:
	# Walk straight at the player in open ground; follow the flow field only
	# when it disagrees strongly with the straight line (a wall is in the way).
	var direct := (target - e.pos).normalized()
	var dir := direct
	var flow: Vector2 = game.world.flow_dir(e.pos)
	if flow != Vector2.ZERO and flow.dot(direct) < 0.5:
		dir = flow
	if e.ranged and e.pos.distance_to(target) < 110.0:
		dir = -dir * 0.5  # casters keep distance
	# separation from neighbours in the same / adjacent hash cells
	var push := Vector2.ZERO
	var k := Vector2i(floori(e.pos.x / HASH_CELL), floori(e.pos.y / HASH_CELL))
	var bucket = _hash.get(k)
	if bucket != null:
		var checked := 0
		for o in bucket:
			if o == e or checked > 8:
				continue
			checked += 1
			var diff: Vector2 = e.pos - o.pos
			var min_d: float = e.radius + o.radius
			var d2 := diff.length_squared()
			if d2 > 0.01 and d2 < min_d * min_d:
				push += diff / sqrt(d2)
	var v := (dir + push * 0.6) * e.speed * speed_mult * (GameData.SLOW_MULT if e.slow_t > 0.0 else 1.0)
	if e.ghost:
		e.pos += ((direct + push * 0.4) * e.speed * speed_mult * (GameData.SLOW_MULT if e.slow_t > 0.0 else 1.0)) * delta
		return
	e.pos = game.world.move(e.pos, v * delta, e.radius * 0.6)


func _boss_update(b: Enemy, delta: float) -> void:
	var ppos: Vector2 = game.player.position
	var cfg: Dictionary = game.boss_cfg
	var enraged := b.hp < b.max_hp * 0.5
	var pats: Array = cfg["patterns"]
	b.state_t -= delta
	match b.state:
		"idle":
			b.pos = game.world.move(b.pos, (ppos - b.pos).normalized() * b.speed * delta, b.radius * 0.5)
			if b.state_t <= 0.0:
				b.pattern = (b.pattern + 1) % pats.size()
				match String(pats[b.pattern]):
					"ring":
						_ring(b.pos, int(cfg["ring_bullets"]), float(cfg["bullet_speed"]), float(cfg["bullet_dmg"]), randf() * TAU)
						_back_to_idle(b, enraged)
					"spiral":
						# several rings, each turned a little and a little slower: a flower of bullets
						var n := int(cfg["ring_bullets"])
						var off := randf() * TAU
						for w in int(cfg.get("spiral_waves", 3)):
							_ring(b.pos, n, float(cfg["bullet_speed"]) * (1.0 - 0.15 * w), float(cfg["bullet_dmg"]), off + w * PI / n)
						_back_to_idle(b, enraged)
					"volley":
						var k := int(cfg.get("volley", 5))
						var aim: float = (ppos - b.pos).angle()
						for i in k:
							_shoot(b.pos, Vector2.from_angle(aim + (i - (k - 1) * 0.5) * GameData.ENEMY_SPREAD_ANGLE) * float(cfg["bullet_speed"]) * 1.3, float(cfg["bullet_dmg"]))
						_back_to_idle(b, enraged)
					"blink":
						var to := ppos + Vector2.from_angle(randf() * TAU) * 120.0
						if not game.world.box_hits(to, b.radius * 0.5):
							game.vfx.motes(b.pos, Color(1.6, 0.6, 2.2), 12, 50.0, 0.5, 3.0, -10.0)
							b.pos = to
							game.vfx.motes(to, Color(1.6, 0.6, 2.2), 12, 50.0, 0.5, 3.0, -10.0)
						_ring(b.pos, int(cfg["ring_bullets"]) / 2, float(cfg["bullet_speed"]), float(cfg["bullet_dmg"]), randf() * TAU)
						_back_to_idle(b, enraged)
					"dash":
						b.state = "telegraph"
						b.state_t = cfg["dash_telegraph"]
						b.dash_dir = (ppos - b.pos).normalized()
					"summon":
						var cnt := int(cfg["summon"])
						for i in cnt:
							spawn(String(cfg.get("summon_type", "slime")), b.pos + Vector2.from_angle(TAU * i / float(cnt)) * 30.0, game.hp_mult(), 1.0)
						_back_to_idle(b, enraged)
		"telegraph":
			if b.state_t <= 0.0:
				b.state = "dash"
				b.state_t = cfg["dash_time"]
		"dash":
			b.pos = game.world.move(b.pos, b.dash_dir * float(cfg["dash_speed"]) * delta, b.radius * 0.5)
			if b.state_t <= 0.0:
				_back_to_idle(b, enraged)


func _ring(at: Vector2, n: int, spd: float, dmg_amount: float, off: float) -> void:
	for i in n:
		_shoot(at, Vector2.from_angle(off + TAU * i / n) * spd, dmg_amount)


func _back_to_idle(b: Enemy, enraged: bool) -> void:
	b.state = "idle"
	b.state_t = game.boss_cfg["gap_enraged"] if enraged else game.boss_cfg["gap"]


func _shoot(from: Vector2, vel: Vector2, dmg_amount: float) -> void:
	bullets.append({"pos": from, "vel": vel, "dmg": dmg_amount * float(game.run_mods["dmg"]), "life": 5.0})


func _update_bullets(delta: float, player: Player) -> void:
	for b in bullets:
		b["pos"] += b["vel"] * delta
		b["life"] -= delta
		if b["pos"].distance_to(player.position) < Player.RADIUS + 3.0:
			player.take_damage(b["dmg"])
			b["life"] = 0.0
		elif game.world.is_solid_at(b["pos"]):
			b["life"] = 0.0
	bullets = bullets.filter(func(b): return b["life"] > 0.0)


func clear_all() -> void:
	list.clear()
	bullets.clear()
	boss = null


func _draw() -> void:
	var cam: Vector2 = game.player.position
	var view := 420.0
	for e in list:
		if absf(e.pos.x - cam.x) > view or absf(e.pos.y - cam.y) > view * 0.7:
			continue
		if e.spawn_t > 0.0:
			# Rift crack opening before the enemy steps out
			var k: float = 1.0 - e.spawn_t / (1.0 if e.boss else SPAWN_ANIM)
			draw_line(e.pos + Vector2(-e.radius, 0) * k, e.pos + Vector2(e.radius, 0) * k, Color(0.9, 0.3, 1.0), 2.0)
			continue
		var col: Color = Color.WHITE if e.flash > 0.0 else e.color
		if not e.boss:
			draw_circle(e.pos + Vector2(0, e.radius * 0.7), e.radius * 0.9, Color(0, 0, 0, 0.25))
		if e.boss:
			_draw_boss(e, col)
			continue
		if e.state == "telegraph":
			draw_line(e.pos, e.pos + e.dash_dir * e.speed * GameData.ENEMY_DASH_SPEED * GameData.ENEMY_DASH_TIME, Color(2.0, 0.2, 0.2, 0.6), 2.0)
		_draw_sprite(e, cam)
		if e.elite:
			var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.008)
			draw_texture_rect(game.vfx.glow_tex, Rect2(e.pos - Vector2(e.radius, e.radius) * 2.2, Vector2(e.radius, e.radius) * 4.4), false, Color(1.6, 0.25, 0.2, 0.45 * pulse))
			draw_arc(e.pos, e.radius + 1.5, 0, TAU, 20, Color(2.0, 0.4, 0.3), 1.5)
			if e.shield > 0:
				draw_arc(e.pos, e.radius + 4.0, 0, TAU, 20, Color(0.5, 0.8, 1.0, 0.8), 1.0)
			var w: float = e.radius * 2.2
			draw_rect(Rect2(e.pos.x - w / 2, e.pos.y - e.radius - 6, w, 2), Color(0.2, 0, 0))
			draw_rect(Rect2(e.pos.x - w / 2, e.pos.y - e.radius - 6, w * e.hp / e.max_hp, 2), Color(1, 0.3, 0.3))
	var tex: Texture2D = game.vfx.glow_tex
	for b in bullets:
		draw_texture_rect(tex, Rect2(b["pos"] - Vector2(9, 9), Vector2(18, 18)), false, Color(2.0, 0.3, 0.8, 0.8))
		draw_circle(b["pos"], 2.6, Color(2.2, 0.5, 1.0))
		draw_circle(b["pos"], 1.2, Color(2.6, 2.2, 2.4))


var _art_cache := {}


## PixelLab enemy sprite assets/enemies/<id>.png, or null (the hand-made grids are used then).
func _art(id: String) -> Texture2D:
	if not _art_cache.has(id):
		var path := "res://assets/enemies/%s.png" % id
		_art_cache[id] = load(path) if ResourceLoader.exists(path) else null
	return _art_cache[id]


func _draw_sprite(e: Enemy, cam: Vector2) -> void:
	var name := e.type
	if name == "bat" and int(Time.get_ticks_msec() / 120 + e.max_hp) % 2 == 0:
		name = "bat_up"
	var tex: Texture2D = _art(String(e.def.get("sprite", e.type)))
	var scale: float
	if tex != null:
		scale = (e.radius * 3.4) / float(tex.get_width())   # 48 px PixelLab sprites (a little padding round them)
	else:
		tex = PixelSprites.texture(name, "bat" if name == "bat_up" else "")
		scale = (e.radius * 2.6) / float(tex.get_width())
	var tw := float(tex.get_width())
	var flip := -1.0 if cam.x < e.pos.x else 1.0
	# idle squash for slimes, hover bob for bats
	var sy := 1.0
	var lift := 0.0
	var t := Time.get_ticks_msec() * 0.001 + e.max_hp
	if e.type in ["slime", "inkblot", "inkdrop", "voidling", "voidmite", "sprout"]:
		sy = 1.0 + sin(t * 9.0) * 0.08
	elif e.type in ["moth", "quill_owl", "shardbat", "wisp", "phantom", "prism_eye", "seer", "rift_ray"]:
		lift = -3.0 + sin(t * 6.0) * 1.5
	elif e.type == "bat":
		lift = -3.0 + sin(t * 7.0) * 1.5
	elif e.type == "wraith":
		lift = -4.0 + sin(t * 5.0) * 2.0
	var mod := Color(1, 1, 1, 0.85) if e.ghost else Color.WHITE
	if e.flash > 0.0:
		mod = Color(3.0, 3.0, 3.0)
	elif e.freeze_t > 0.0:
		mod = GameData.FROZEN_TINT
	elif e.rooted_t > 0.0:
		mod = GameData.ROOTED_TINT
	elif e.elite:
		mod = Color(1.35, 0.85, 0.85)
	var size := Vector2(tw, tex.get_height()) * scale
	draw_set_transform(e.pos + Vector2(0, lift + size.y * (1.0 - sy) * 0.5), 0.0, Vector2(flip, sy))
	draw_texture_rect(tex, Rect2(-size * 0.5, size), false, mod)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_boss(b: Enemy, col: Color) -> void:
	if b.state == "telegraph":
		draw_line(b.pos, b.pos + b.dash_dir * float(game.boss_cfg["dash_speed"]) * float(game.boss_cfg["dash_time"]), Color(2.0, 0.15, 0.2, 0.7), 4.0)
	var tex := CharacterArt.texture(String(game.boss_cfg["sprite"]), CharacterArt.dir_for(game.player.position - b.pos))
	if tex != null:
		draw_texture_rect(game.vfx.glow_tex, Rect2(b.pos - Vector2(40, 40), Vector2(80, 80)), false, Color(1.2, 0.1, 0.6, 0.35))
		var sz := Vector2(tex.get_width(), tex.get_height()) * float(game.boss_cfg["sprite_scale"])
		var feet := b.pos + Vector2(0, b.radius * 0.8)
		draw_set_transform(feet, 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, b.radius * 1.3, Color(0, 0, 0, 0.4))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_texture_rect(tex, Rect2(feet + Vector2(-sz.x * 0.5, -sz.y), sz), false, Color(2.2, 1.6, 1.6) if b.flash > 0.0 else Color.WHITE)
		return
	draw_circle(b.pos, b.radius, col)
	draw_arc(b.pos, b.radius, 0, TAU, 32, Color(0.9, 0.2, 0.3), 2.0)
	draw_colored_polygon(PackedVector2Array([b.pos + Vector2(-12, -14), b.pos + Vector2(-6, -26), b.pos + Vector2(-2, -15)]), Color(0.8, 0.75, 0.65))
	draw_colored_polygon(PackedVector2Array([b.pos + Vector2(12, -14), b.pos + Vector2(6, -26), b.pos + Vector2(2, -15)]), Color(0.8, 0.75, 0.65))
	draw_texture_rect(game.vfx.glow_tex, Rect2(b.pos - Vector2(40, 40), Vector2(80, 80)), false, Color(1.2, 0.1, 0.6, 0.35))
	draw_circle(b.pos + Vector2(0, -3), 5.0, Color(2.6, 0.3, 0.3))
	draw_circle(b.pos + Vector2(0, -3), 2.0, Color(3.0, 2.4, 1.2))
