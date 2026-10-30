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
	var orb_hit_at := -100.0  # Flame Orb re-hit timer
	var alive := true
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
	var b := Enemy.new()
	b.boss = true
	b.type = "boss"
	b.pos = pos
	b.max_hp = GameData.BOSS["hp"] * hp_mult
	b.hp = b.max_hp
	b.radius = GameData.BOSS["radius"]
	b.speed = GameData.BOSS["speed"]
	b.dmg = GameData.BOSS["dmg"]
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
	e.hp -= amount
	e.flash = 0.08
	game.player.damage_dealt += amount
	game.spawn_damage_number(e.pos, amount, crit)
	if e.hp <= 0.0:
		_kill(e)


func _kill(e: Enemy) -> void:
	e.alive = false
	game.on_enemy_killed(e)
	if e.affix == "splitter":
		for i in 4:
			var s := spawn("slime", e.pos + Vector2.from_angle(TAU * i / 4.0) * 8.0, game.hp_mult() * 0.6, 1.2)
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
		if e.spawn_t > 0.0:
			e.spawn_t -= delta
			continue
		if e.boss:
			_boss_update(e, delta)
		else:
			_walk(e, ppos, delta, speed_mult)
			if e.ranged:
				e.shoot_t -= delta
				if e.shoot_t <= 0.0 and e.pos.distance_to(ppos) < 200.0:
					e.shoot_t = 2.5
					_shoot(e.pos, (ppos - e.pos).normalized() * 70.0, 8.0)
		if e.pos.distance_to(ppos) < e.radius + Player.RADIUS:
			player.take_damage(e.dmg)
	list = list.filter(func(e): return e.alive)
	_update_bullets(delta, player)
	queue_redraw()


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
	var v := (dir + push * 0.6) * e.speed * speed_mult
	e.pos = game.world.move(e.pos, v * delta, e.radius * 0.6)


func _boss_update(b: Enemy, delta: float) -> void:
	var ppos: Vector2 = game.player.position
	var cfg: Dictionary = GameData.BOSS
	var enraged := b.hp < b.max_hp * 0.5
	b.state_t -= delta
	match b.state:
		"idle":
			b.pos = game.world.move(b.pos, (ppos - b.pos).normalized() * b.speed * delta, b.radius * 0.5)
			if b.state_t <= 0.0:
				b.pattern = (b.pattern + 1) % 3
				match b.pattern:
					0:
						var n := int(cfg["ring_bullets"])
						var off := randf() * TAU
						for i in n:
							_shoot(b.pos, Vector2.from_angle(off + TAU * i / n) * float(cfg["bullet_speed"]), float(cfg["bullet_dmg"]))
						_back_to_idle(b, enraged)
					1:
						b.state = "telegraph"
						b.state_t = cfg["dash_telegraph"]
						b.dash_dir = (ppos - b.pos).normalized()
					2:
						for i in int(cfg["summon"]):
							spawn("slime", b.pos + Vector2.from_angle(TAU * i / 6.0) * 30.0, game.hp_mult(), 1.0)
						_back_to_idle(b, enraged)
		"telegraph":
			if b.state_t <= 0.0:
				b.state = "dash"
				b.state_t = cfg["dash_time"]
		"dash":
			b.pos = game.world.move(b.pos, b.dash_dir * float(cfg["dash_speed"]) * delta, b.radius * 0.5)
			if b.state_t <= 0.0:
				_back_to_idle(b, enraged)


func _back_to_idle(b: Enemy, enraged: bool) -> void:
	b.state = "idle"
	b.state_t = GameData.BOSS["gap_enraged"] if enraged else GameData.BOSS["gap"]


func _shoot(from: Vector2, vel: Vector2, dmg_amount: float) -> void:
	bullets.append({"pos": from, "vel": vel, "dmg": dmg_amount, "life": 5.0})


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
		draw_circle(e.pos + Vector2(0, e.radius * 0.7), e.radius * 0.9, Color(0, 0, 0, 0.25))
		if e.boss:
			_draw_boss(e, col)
			continue
		draw_circle(e.pos, e.radius, col)
		draw_circle(e.pos + Vector2(-e.radius * 0.35, -e.radius * 0.2), max(1.0, e.radius * 0.18), Color(1, 0.9, 0.3))
		draw_circle(e.pos + Vector2(e.radius * 0.35, -e.radius * 0.2), max(1.0, e.radius * 0.18), Color(1, 0.9, 0.3))
		if e.elite:
			draw_arc(e.pos, e.radius + 1.5, 0, TAU, 20, Color(1, 0.2, 0.2), 1.5)
			if e.shield > 0:
				draw_arc(e.pos, e.radius + 4.0, 0, TAU, 20, Color(0.5, 0.8, 1.0, 0.8), 1.0)
			var w: float = e.radius * 2.2
			draw_rect(Rect2(e.pos.x - w / 2, e.pos.y - e.radius - 6, w, 2), Color(0.2, 0, 0))
			draw_rect(Rect2(e.pos.x - w / 2, e.pos.y - e.radius - 6, w * e.hp / e.max_hp, 2), Color(1, 0.3, 0.3))
	for b in bullets:
		draw_circle(b["pos"], 3.0, Color(1, 0.3, 0.5))
		draw_circle(b["pos"], 1.5, Color(1, 0.9, 0.95))


func _draw_boss(b: Enemy, col: Color) -> void:
	if b.state == "telegraph":
		draw_line(b.pos, b.pos + b.dash_dir * float(GameData.BOSS["dash_speed"]) * float(GameData.BOSS["dash_time"]), Color(1, 0.1, 0.1, 0.6), 4.0)
	draw_circle(b.pos, b.radius, col)
	draw_arc(b.pos, b.radius, 0, TAU, 32, Color(0.9, 0.2, 0.3), 2.0)
	draw_colored_polygon(PackedVector2Array([b.pos + Vector2(-12, -14), b.pos + Vector2(-6, -26), b.pos + Vector2(-2, -15)]), Color(0.8, 0.75, 0.65))
	draw_colored_polygon(PackedVector2Array([b.pos + Vector2(12, -14), b.pos + Vector2(6, -26), b.pos + Vector2(2, -15)]), Color(0.8, 0.75, 0.65))
	draw_circle(b.pos + Vector2(0, -3), 5.0, Color(1, 0.15, 0.15))
	draw_circle(b.pos + Vector2(0, -3), 2.0, Color(1, 0.9, 0.5))
