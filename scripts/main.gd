extends Node2D
## Rift run orchestration: builds the procedural map, runs the 10-minute
## timeline (elites, Rift Surges, Final Swarm), the in-run economy, shrines,
## the boss portal and the win / lose flow.
##
## Command-line (after `--`): --seed=123  --autotest  --autotest-die  --shot=res://shot.png

var seed_value := 0
var rng := RandomNumberGenerator.new()

var world: World
var fog: Fog
var interactables: Interactables
var pickups: Pickups
var enemies: Enemies
var player: Player
var projectiles: Projectiles
var effects: Effects
var camera: Camera2D
var hud: Hud

# run state
var elapsed := 0.0
var gold := 0.0
var gold_collected := 0.0
var kills := 0
var level := 1
var xp := 0.0
var xp_next := GameData.xp_to_next(1)
var pending_levelups := 0
var items_owned := {}   # id -> count (insertion order = HUD order)
var chests_paid := 0
var chests_opened := 0
var shrines_used := 0
var difficulty := 1.0
var final_swarm := false
var final_swarm_t := 0.0
var boss_spawned := false
var boss_killed := false
var run_over := false
var victory := false

var _spawn_accum := 0.0
var _next_elite := GameData.ELITE_START
var _surge_index := 0          # next surge to warn/start
var _surge_end := -1.0
var _surge_mult := 1.0
var _surge_warned := -1
var _fog_t := 0.0
var _flow_t := 0.0
var _trials := {}              # trial_id -> {shrine, remaining}
var _next_trial_id := 0

# test hooks
var _auto := false
var _auto_die := false
var _auto_t := 0.0
var _shot_path := ""
var _shots_taken := 0
var _finishing := false
var _auto_portal_at := 240.0


func _ready() -> void:
	_parse_args()
	if seed_value == 0:
		seed_value = randi() % 1000000 + 1
	rng.seed = seed_value

	var t0 := Time.get_ticks_msec()
	var map := MapGenerator.new().generate(seed_value)
	print("[run] seed=%d map %d ms, rerolls=%d" % [seed_value, Time.get_ticks_msec() - t0, map["rerolls"]])

	world = _add(World.new())
	world.setup(map)
	fog = Fog.new()
	fog.setup(world.w, world.h)
	interactables = _add(Interactables.new())
	interactables.setup(map, world)
	pickups = _add(Pickups.new())
	enemies = _add(Enemies.new())
	player = _add(Player.new())
	player.position = world.cell_center(map["spawn"])
	projectiles = _add(Projectiles.new())
	effects = _add(Effects.new())

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world.world_size().x)
	camera.limit_bottom = int(world.world_size().y)
	camera.position = player.position
	add_child(camera)
	camera.make_current()

	hud = Hud.new()
	hud.game = self
	add_child(hud)

	fog.reveal(player.position, GameData.FOG_REVEAL_TILES)
	interactables.update_discovery(fog)
	world.update_flow(player.position)
	hud.banner("Find the Rift Portal before the timer ends", Color(1, 0.6, 0.6), 4.0)
	if _auto:
		player.god_mode = not _auto_die
		process_mode = Node.PROCESS_MODE_ALWAYS  # so the test can answer choice panels


func _add(n: Node) -> Node:
	n.set("game", self)
	add_child(n)
	return n


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			seed_value = int(a.get_slice("=", 1))
		elif a == "--autotest":
			_auto = true
		elif a == "--autotest-die":
			_auto = true
			_auto_die = true
		elif a == "--autotest-late":
			_auto = true
			_auto_portal_at = 640.0
		elif a.begins_with("--shot="):
			_shot_path = a.get_slice("=", 1)


# ------------------------------------------------------------------ main loop

func _process(delta: float) -> void:
	if _auto:
		_autotest_step(delta)
	if run_over or get_tree().paused:
		return
	elapsed += delta
	camera.position = player.position

	_update_timeline(delta)
	_update_spawning(delta)

	_fog_t -= delta
	if _fog_t <= 0.0:
		_fog_t = 0.1
		if fog.reveal(player.position, GameData.FOG_REVEAL_TILES):
			interactables.update_discovery(fog)
	_flow_t -= delta
	if _flow_t <= 0.0:
		_flow_t = 0.4
		world.update_flow(player.position)

	if pending_levelups > 0 and not hud.choices_open():
		pending_levelups -= 1
		hud.show_choices("LEVEL UP — choose one", _roll_upgrades(), func(opt): player.apply_mods(opt["mods"]))


func get_move_input() -> Vector2:
	if _auto:
		return Vector2.ZERO
	var k := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	var v := k + hud.joystick_vector
	return v.limit_length(1.0)


func time_left() -> float:
	return max(0.0, GameData.RUN_TIME - elapsed)


func surge_active() -> bool:
	return elapsed < _surge_end


func hp_mult() -> float:
	var m := (1.0 + GameData.HP_SCALE_PER_MIN * elapsed / 60.0) * difficulty
	if final_swarm:
		m *= 1.0 + 0.10 * floorf(final_swarm_t / GameData.FINAL_SWARM_STEP)
	return m


func speed_mult() -> float:
	return 1.0 + (0.03 * floorf(final_swarm_t / GameData.FINAL_SWARM_STEP) if final_swarm else 0.0)


func _update_timeline(delta: float) -> void:
	# Elites every 60 s
	if elapsed >= _next_elite:
		_next_elite += GameData.ELITE_INTERVAL
		_spawn_elite()
		hud.toast("An Elite has appeared!", Color(1, 0.55, 0.2))
	# Rift Surges
	if _surge_index < GameData.SURGES.size():
		var s: Dictionary = GameData.SURGES[_surge_index]
		if _surge_warned != _surge_index and elapsed >= float(s["at"]) - GameData.SURGE_WARNING:
			_surge_warned = _surge_index
			hud.banner("RIFT SURGE INCOMING", Color(1, 0.55, 0.25), GameData.SURGE_WARNING)
		if elapsed >= float(s["at"]):
			_surge_end = elapsed + GameData.SURGE_DURATION
			_surge_mult = float(s["mult"])
			for i in int(s["elites"]):
				_spawn_elite()
			hud.banner("RIFT SURGE %d" % (_surge_index + 1), Color(1, 0.45, 0.2), 2.5)
			_surge_index += 1
	# Final Swarm
	if not final_swarm and elapsed >= GameData.RUN_TIME:
		_start_final_swarm()
	if final_swarm:
		final_swarm_t += delta


func _start_final_swarm() -> void:
	if final_swarm:
		return
	final_swarm = true
	hud.banner("FINAL SWARM", Color(1, 0.2, 0.3), 4.0)


func _update_spawning(delta: float) -> void:
	var rate: float
	if final_swarm:
		rate = GameData.FINAL_SWARM_RATE * (1.0 + 0.1 * floorf(final_swarm_t / GameData.FINAL_SWARM_STEP))
	else:
		rate = lerp(GameData.SPAWN_RATE_START, GameData.SPAWN_RATE_END, clamp(elapsed / GameData.RUN_TIME, 0.0, 1.0))
		if surge_active():
			rate *= _surge_mult
	rate *= difficulty
	if enemies.boss != null:
		rate *= GameData.BOSS_ALIVE_SPAWN_MULT
	_spawn_accum += rate * delta
	while _spawn_accum >= 1.0:
		_spawn_accum -= 1.0
		_spawn_one()


func _spawn_point() -> Vector2:
	for i in 10:
		var p := player.position + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(360.0, 420.0)
		if not world.box_hits(p, 6.0):
			return p
	return Vector2.INF


func _pick_type() -> String:
	var keys: Array = []
	var weights: Array = []
	for k in GameData.ENEMY_TYPES:
		var d: Dictionary = GameData.ENEMY_TYPES[k]
		if elapsed >= float(d["min_time"]):
			keys.append(k)
			weights.append(float(d["weight"]))
	return keys[GameData.weighted_index(rng, weights)]


func _spawn_one() -> void:
	var p := _spawn_point()
	if p == Vector2.INF:
		return
	if enemies.count() >= GameData.MAX_ENEMIES:
		enemies.recycle_farthest(p)
		return
	enemies.spawn(_pick_type(), p, hp_mult(), speed_mult())


func _spawn_elite(at := Vector2.INF) -> Enemies.Enemy:
	var p := at if at != Vector2.INF else _spawn_point()
	if p == Vector2.INF:
		return null
	var affix: String = GameData.ELITE_AFFIXES[rng.randi_range(0, GameData.ELITE_AFFIXES.size() - 1)]
	return enemies.spawn(_pick_type(), p, hp_mult(), speed_mult(), true, affix)


# ------------------------------------------------------------------ combat events

func spawn_damage_number(pos: Vector2, amount: float, crit: bool) -> void:
	if pos.distance_to(player.position) < 340.0:
		effects.damage_number(pos, amount, crit)


func on_enemy_killed(e) -> void:
	kills += 1
	if e.boss:
		_on_boss_killed(e.pos)
		return
	pickups.drop(e.pos, Pickups.Kind.XP, e.xp)
	if e.elite:
		pickups.drop(e.pos, Pickups.Kind.GOLD, GameData.ELITE_GOLD)
		interactables.add_golden_chest(_walkable_near(e.pos))
	elif rng.randf() < 0.3:
		pickups.drop(e.pos, Pickups.Kind.GOLD, 1)
	if e.trial_id >= 0 and _trials.has(e.trial_id):
		var t: Dictionary = _trials[e.trial_id]
		t["remaining"] -= 1
		if t["remaining"] <= 0:
			interactables.complete_trial(t["shrine"])
			interactables.add_golden_chest(t["shrine"]["pos"] + Vector2(0, 14))
			_trials.erase(e.trial_id)
			hud.toast("Trial complete — Golden Chest!", Color(1, 0.85, 0.3))


func on_pickup(kind: int, value: float) -> void:
	match kind:
		Pickups.Kind.XP:
			xp += value * (1.0 + player.stats["xp_pct"])
			while xp >= xp_next:
				xp -= xp_next
				level += 1
				xp_next = GameData.xp_to_next(level)
				pending_levelups += 1
		Pickups.Kind.GOLD:
			var g: float = value * (1.0 + player.stats["gold_pct"])
			gold += g
			gold_collected += g
		Pickups.Kind.HEAL:
			player.heal(value)


func on_pot_broken(pos: Vector2) -> void:
	var r := rng.randf()
	if r < 0.5:
		pickups.drop(pos, Pickups.Kind.GOLD, rng.randi_range(1, 3))
	elif r < 0.85:
		pickups.drop(pos, Pickups.Kind.XP, 2)
	else:
		pickups.drop(pos, Pickups.Kind.HEAL, 10)


func on_player_died() -> void:
	_end_run(false)


# ------------------------------------------------------------------ chests & items

func chest_price() -> int:
	return GameData.chest_price(chests_paid)


func can_afford_chest() -> bool:
	return int(gold) >= chest_price()


func open_chest(c: Dictionary) -> void:
	if c["opened"]:
		return
	var min_rarity := 0
	if c["golden"]:
		min_rarity = 1
	else:
		if not can_afford_chest():
			return
		gold -= chest_price()
		chests_paid += 1
	c["opened"] = true
	chests_opened += 1
	var rarity := GameData.roll_rarity(rng, player.stats["luck"], min_rarity)
	var pool := GameData.items_of_rarity(rarity)
	while pool.is_empty() and rarity > 0:
		rarity -= 1
		pool = GameData.items_of_rarity(rarity)
	var it: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	player.apply_mods(it["mods"])
	items_owned[it["id"]] = int(items_owned.get(it["id"], 0)) + 1
	hud.toast("%s (%s): %s" % [it["name"], GameData.RARITY_NAMES[rarity], it["desc"]], GameData.RARITY_COLORS[rarity])


func item_by_id(id: String) -> Dictionary:
	for it in GameData.ITEMS:
		if it["id"] == id:
			return it
	return {}


func _roll_upgrades() -> Array:
	var pool: Array = []
	var weights: Array = []
	for u in GameData.UPGRADES:
		if u.get("unique", false) and player.stats.get(u["id"], 0.0) >= 1.0:
			continue
		if u.has("requires") and player.stats.get(u["requires"], 0.0) < 1.0:
			continue
		pool.append(u)
		weights.append(float(u["weight"]))
	var out: Array = []
	while out.size() < 3 and not pool.is_empty():
		var i := GameData.weighted_index(rng, weights)
		out.append(pool[i])
		pool.remove_at(i)
		weights.remove_at(i)
	return out


# ------------------------------------------------------------------ shrines

func on_shrine_activated(s: Dictionary) -> void:
	shrines_used += 1
	match s["type"]:
		"ley":
			var boons: Array = GameData.BOONS.duplicate()
			var opts: Array = []
			for i in 3:
				opts.append(boons.pop_at(rng.randi_range(0, boons.size() - 1)))
			hud.show_choices("LEY SHRINE — choose a boon", opts, func(opt): player.apply_mods(opt["mods"]))
		"avarice":
			gold += GameData.AVARICE_GOLD
			gold_collected += GameData.AVARICE_GOLD
			difficulty += GameData.AVARICE_DIFFICULTY
			hud.toast("+%d gold. The Rift grows stronger (+%d%%)" % [GameData.AVARICE_GOLD, int(GameData.AVARICE_DIFFICULTY * 100)], Color(1, 0.8, 0.2))
		"well":
			var n := pickups.pull_all_xp()
			hud.toast("Aether Well pulls %d gems to you" % n, Color(0.55, 1.0, 0.6))
		"moon":
			player.heal(player.stats["max_hp"] * 0.5)
			hud.toast("Moon Fountain restores your health", Color(0.85, 0.85, 1.0))


func start_trial(s: Dictionary) -> void:
	shrines_used += 1
	var id := _next_trial_id
	_next_trial_id += 1
	s["trial_id"] = id
	var count := 0
	var elite := _spawn_elite(_walkable_near(s["pos"] + Vector2(40, 0)))
	if elite != null:
		elite.trial_id = id
		count += 1
	for i in GameData.TRIAL_MINIONS:
		var p := _walkable_near(s["pos"] + Vector2.from_angle(TAU * i / GameData.TRIAL_MINIONS) * 70.0)
		var e := enemies.spawn(_pick_type(), p, hp_mult(), speed_mult())
		e.trial_id = id
		count += 1
	_trials[id] = {"shrine": s, "remaining": count}
	hud.banner("TRIAL: defeat them in %ds" % int(GameData.TRIAL_DURATION), Color(1, 0.5, 0.4), 2.5)


func on_trial_failed(s: Dictionary) -> void:
	var id: int = s["trial_id"]
	_trials.erase(id)
	for e in enemies.list:
		if e.trial_id == id:
			e.trial_id = -1
	hud.toast("Trial failed", Color(1, 0.4, 0.4))


func _walkable_near(p: Vector2) -> Vector2:
	if not world.box_hits(p, 5.0):
		return p
	for r in [12.0, 24.0, 36.0]:
		for i in 8:
			var q: Vector2 = p + Vector2.from_angle(TAU * i / 8.0) * r
			if not world.box_hits(q, 5.0):
				return q
	return player.position


# ------------------------------------------------------------------ portal & boss

func on_portal_discovered() -> void:
	hud.banner("Rift Portal discovered!", Color(1, 0.4, 0.45), 3.0)


func on_portal_activated() -> void:
	hud.banner("The Rift Portal is opening...", Color(1, 0.3, 0.4), 2.0)


func summon_boss(pos: Vector2) -> void:
	boss_spawned = true
	enemies.spawn_boss(pos, 1.0 + GameData.HP_SCALE_PER_MIN * elapsed / 60.0)
	hud.banner("%s has emerged!" % GameData.BOSS["name"], Color(1, 0.3, 0.35), 3.0)


func _on_boss_killed(pos: Vector2) -> void:
	boss_killed = true
	interactables.portal["state"] = "done"
	interactables.add_golden_chest(_walkable_near(pos + Vector2(-22, 0)))
	for i in 3:
		pickups.drop(_walkable_near(pos + Vector2(22, -10 + i * 10)), Pickups.Kind.GOLD, 10)
	interactables.activate_exit(_walkable_near(pos))
	hud.banner("Boss defeated! Enter the Exit Portal — or stay for the Final Swarm", Color(0.6, 1.0, 1.0), 5.0)
	_start_final_swarm()


func on_exit_entered() -> void:
	_end_run(true)


# ------------------------------------------------------------------ end of run

func _end_run(won: bool) -> void:
	if run_over:
		return
	run_over = true
	victory = won
	var share := 1.0 if won else GameData.DEFEAT_REWARD_SHARE
	var academy_gold := int((gold_collected * 2.0 + kills * 0.5) * share)
	var materials := int(kills / 5.0 * share)
	var aether := int((25 if boss_killed else 0) + final_swarm_t / 10.0)
	var exp_gain := int((level * 20 + kills * 0.2) * share)
	var t := int(elapsed)
	var text := "%s\n\nKills: %d\nTime: %02d:%02d\nLevel: %d\nChests opened: %d   Shrines used: %d\nExplored: %d%%\nDamage dealt: %d\nFinal Swarm survived: %ds\n\nRewards%s:\nGold +%d   Materials +%d   Aether +%d   EXP +%d\n\nSeed %d" % [
		"VICTORY" if won else "DEFEAT", kills, t / 60, t % 60, level, chests_opened, shrines_used,
		int(fog.explored_ratio() * 100), int(player.damage_dealt), int(final_swarm_t),
		"" if won else " (50% on defeat)", academy_gold, materials, aether, exp_gain, seed_value]
	print("[run] END ", text.replace("\n", " | "))
	hud.show_result(text)


func restart() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()


# ------------------------------------------------------------------ autotest

## Headless smoke test: teleports between objectives, auto-picks choices,
## activates the portal, kills the boss, exits. Prints a summary and quits.
func _autotest_step(delta: float) -> void:
	if hud.choices_open():
		hud.pick_choice(0)
	if run_over:
		if _finishing:
			return
		_finishing = true
		if _shot_path != "":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(_shot_path.replace(".png", "_end.png"))
		print("[autotest] done victory=%s elapsed=%.0f kills=%d level=%d chests=%d shrines=%d explored=%.2f enemies_alive=%d final_swarm=%s" % [
			victory, elapsed, kills, level, chests_opened, shrines_used, fog.explored_ratio(), enemies.count(), final_swarm])
		get_tree().quit()
		return
	_maybe_shot(false)
	if get_tree().paused:
		return
	if _auto_die:
		if elapsed > 900.0:
			print("[autotest] FAIL: player never died")
			get_tree().quit(1)
		return
	_auto_t -= delta
	if _auto_t > 0.0:
		return
	_auto_t = 1.0
	if elapsed > 1500.0:
		print("[autotest] FAIL: timeout")
		get_tree().quit(1)
		return
	gold += 5.0  # let the test afford chests
	var target := Vector2.INF
	if interactables.exit_portal["active"]:
		target = interactables.exit_portal["pos"]
	elif enemies.boss != null:
		target = enemies.boss.pos + Vector2(30, 0)
		player.stats["damage_pct"] += 0.5
	elif elapsed > _auto_portal_at and interactables.portal["state"] == "idle":
		target = interactables.portal["pos"]
	else:
		for c in interactables.chests:
			if not c["opened"] and (c["golden"] or can_afford_chest()):
				target = c["pos"]
				break
		if target == Vector2.INF:
			for s in interactables.shrines:
				if not s["used"] and s["state"] == "idle":
					target = s["pos"]
					break
	if target != Vector2.INF:
		player.position = _walkable_near(target)


func _maybe_shot(_final: bool) -> void:
	if _shot_path == "":
		return
	var times := [3.0, 160.0]
	if _shots_taken < times.size() and elapsed >= times[_shots_taken]:
		var path := _shot_path.replace(".png", "_%d.png" % _shots_taken)
		_shots_taken += 1
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(path)
		print("[autotest] screenshot ", path)
