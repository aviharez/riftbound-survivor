extends Node2D
## Rift run orchestration: builds the procedural map, runs the 10-minute
## timeline (elites, Rift Surges, Final Swarm), the in-run economy, shrines,
## the boss portal and the win / lose flow.
##
## Command-line (after `--`): --seed=123  --slots=4  --autotest  --autotest-die  --autotest-late  --shot=/tmp/shot.png
##   --char=kael  --weapons=meteor,void (extra weapons at Lv 1; evolved ids such as solar come evolved)
##   --lessons=might:3,vigor:2 (Staff Room lesson ranks for this run)
##   --char-level=10 --enhance=2,3 (character level and passive / signature enhance ranks for this run)
##   --gear=wand:3,robe:1 (equipment base:rarity worn this run, substats rolled from the seed)
##   --tomes=ricochet,haste (tomes owned at Lv 1 from the start)
##   --ready-evolve (owned weapons start at the evolve level with their tomes, so chests evolve them)
##   --swarm-at=30 (early Final Swarm); autotest only

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
var vfx: Vfx
var screen_fx: ScreenFx
var weapons: Weapons
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
var evolutions: Array = []      # evolved weapon ids, in the order they happened
var _evo_announced := {}        # base weapon id -> true once "ready to evolve" was shown
var shrines_used := 0
var difficulty := 1.0
var location_id := "courtyard"
var danger := 1
var boss_cfg: Dictionary = GameData.BOSSES["guardian"]
var run_mods := {"hp": 1.0, "dmg": 1.0, "spawn": 1.0, "elite": 1.0, "reward": 1.0}   # GameData.run_mods(location, danger)
var final_swarm := false
var final_swarm_t := 0.0
var boss_spawned := false
var boss_killed := false
var run_over := false
var victory := false
var tome_slots := GameData.BASE_TOME_SLOTS
var weapon_slots := GameData.BASE_WEAPON_SLOTS
var _forced_slots := 0
var character_id := ""

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
var _shot_times: Array = [3.0, 160.0]
var _finishing := false
var _choice_shot_done := false
var _revived := false
var _loc_forced := false
var _auto_portal_at := 240.0
var _swarm_at := -1.0  # --swarm-at=30: start the Final Swarm early (autotest only)
var _extra_weapons: Array = []  # --weapons=meteor,void: extra weapons at Lv 1 (autotest screenshots)
var _lessons_arg := {}          # --lessons=might:3,vigor:2: Staff Room ranks for an autotest run
var _lessons_applied := {}      # lesson id -> rank applied this run (autotest summary)
var _char_level_arg := 1        # --char-level=10 (autotest)
var _enhance_arg := [0, 0]      # --enhance=passive,weapon ranks (autotest)
var _gear_arg: Array = []       # --gear=wand:3,robe:1 (autotest)
var char_bonus := {}            # {level, mods, passive, weapon} applied this run
var elites_killed := 0
var equipment_dropped := 0
var _extra_tomes: Array = []    # --tomes=ricochet,haste: tomes owned from the start (autotest; combo hint checks)
var _ready_evolve := false      # --ready-evolve: owned weapons at the evolve level + their tomes
var _profile := false           # --profile: print load counters every 20 s of game time
var _profile_next := 20.0
var _profile_ms := 0


func _ready() -> void:
	_parse_args()
	if seed_value == 0:
		seed_value = randi() % 1000000 + 1
	rng.seed = seed_value
	if _forced_slots > 0:
		tome_slots = clampi(_forced_slots, 1, GameData.MAX_SLOTS)
		weapon_slots = tome_slots
	elif not _auto:
		var save := SaveData.load_data()
		tome_slots = SaveData.slots_for(save, "tome")
		weapon_slots = SaveData.slots_for(save, "weapon")
		if character_id == "":
			character_id = String(save.get("character", "astra"))
		if not _loc_forced:
			location_id = String(save["location"])
			danger = int(save["danger"])
	if character_id == "":
		character_id = "astra"
	run_mods = GameData.run_mods(location_id, danger)
	boss_cfg = GameData.BOSSES[GameData.location_by_id(location_id)["boss"]]

	var t0 := Time.get_ticks_msec()
	var map := MapGenerator.new().generate(seed_value)
	print("[run] seed=%d map %d ms, rerolls=%d" % [seed_value, Time.get_ticks_msec() - t0, map["rerolls"]])

	world = _add(World.new())
	world.setup(map, String(GameData.location_by_id(location_id)["tiles"]))
	fog = Fog.new()
	fog.setup(world.w, world.h)
	interactables = _add(Interactables.new())
	interactables.setup(map, world)
	pickups = _add(Pickups.new())
	enemies = _add(Enemies.new())
	player = _add(Player.new())
	player.setup_character(GameData.character_by_id(character_id))
	_apply_lessons()
	for id in _extra_weapons:
		var ew: Dictionary = GameData.weapon_by_id(id)
		if _auto and not ew.is_empty():
			player.weapon_levels[id] = GameData.WEAPON_MAX_LEVEL if ew.get("evolved", false) else 1
	for id in _extra_tomes:
		if _auto and not GameData.tome_by_id(id).is_empty():
			player.tomes[id] = 1
	if _auto and _ready_evolve:
		for id in player.weapon_levels.keys():
			var evo := GameData.evolution_of(id)
			if not evo.is_empty():
				player.weapon_levels[id] = GameData.EVOLVE_LEVEL
				player.tomes[evo["tome"]] = 1
	player.position = world.cell_center(map["spawn"])
	projectiles = _add(Projectiles.new())
	weapons = _add(Weapons.new())
	effects = _add(Effects.new())
	var sprite_color: SpriteFxColor = _add(SpriteFxColor.new())
	vfx = _add(Vfx.new())
	vfx.color_node = sprite_color

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

	screen_fx = _add(ScreenFx.new())
	hud = Hud.new()
	hud.game = self
	add_child(hud)

	fog.reveal(player.position, GameData.FOG_REVEAL_TILES)
	interactables.update_discovery(fog)
	world.update_flow(player.position)
	hud.banner("Find the Rift Portal before the timer ends", Color(1, 0.6, 0.6), 4.0)
	Sfx.music("rift")
	if _auto:
		player.god_mode = not _auto_die
		process_mode = Node.PROCESS_MODE_ALWAYS  # so the test can answer choice panels


## Staff Room lessons (permanent upgrades) and the character's level / enhance ranks from the save;
## autotests use --lessons / --char-level / --enhance instead.
func _apply_lessons() -> void:
	var src := {"lessons": _lessons_arg} if _auto else SaveData.load_data()
	_lessons_applied = src["lessons"].duplicate()
	player.apply_mods(SaveData.lesson_mods(src))
	if _auto:
		var lv := clampi(_char_level_arg, 1, GameData.CHAR_MAX_LEVEL)
		var mods := GameData.char_level_mods(lv)
		var grng := RandomNumberGenerator.new()
		grng.seed = seed_value
		for g in _gear_arg:
			mods += GameData.item_mods(GameData.roll_item(grng, int(g[1]), String(g[0])))
		char_bonus = {"level": lv, "mods": mods, "passive": _enhance_arg[0], "weapon": _enhance_arg[1]}
	else:
		char_bonus = SaveData.char_run_bonus(src, character_id)
	player.apply_mods(char_bonus["mods"])
	player.trait_power = 1.0 + GameData.ENHANCE_TRAIT_PER_RANK * int(char_bonus["passive"])
	player.signature_rank = int(char_bonus["weapon"])
	player.hp = player.stats["max_hp"]


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
		elif a == "--autotest-boss":
			_auto = true
			_auto_portal_at = 12.0
		elif a == "--autotest-late":
			_auto = true
			_auto_portal_at = 640.0
		elif a.begins_with("--swarm-at="):
			_swarm_at = float(a.get_slice("=", 1))
		elif a == "--profile":
			_profile = true
		elif a.begins_with("--lessons="):
			for part in a.get_slice("=", 1).split(","):
				if ":" in part:
					_lessons_arg[part.get_slice(":", 0)] = int(part.get_slice(":", 1))
		elif a.begins_with("--char-level="):
			_char_level_arg = int(a.get_slice("=", 1))
		elif a.begins_with("--enhance="):
			var parts := a.get_slice("=", 1).split(",")
			_enhance_arg = [int(parts[0]), int(parts[1]) if parts.size() > 1 else 0]
		elif a.begins_with("--gear="):
			for part in a.get_slice("=", 1).split(","):
				_gear_arg.append([part.get_slice(":", 0), int(part.get_slice(":", 1))])
		elif a.begins_with("--tomes="):
			_extra_tomes = Array(a.get_slice("=", 1).split(","))
		elif a == "--ready-evolve":
			_ready_evolve = true
		elif a.begins_with("--weapons="):
			_extra_weapons = Array(a.get_slice("=", 1).split(","))
		elif a.begins_with("--char="):
			character_id = a.get_slice("=", 1)
		elif a.begins_with("--slots="):
			_forced_slots = int(a.get_slice("=", 1))
		elif a.begins_with("--shot-times="):
			_shot_times.clear()
			for t in a.get_slice("=", 1).split(","):
				_shot_times.append(float(t))
		elif a.begins_with("--shot="):
			_shot_path = a.get_slice("=", 1)
		elif a.begins_with("--loc="):
			location_id = GameData.location_by_id(a.get_slice("=", 1))["id"]
			_loc_forced = true
		elif a.begins_with("--danger="):
			danger = clampi(int(a.get_slice("=", 1)), 1, GameData.DANGERS.size())
			_loc_forced = true


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
		hud.show_choices("LEVEL UP — choose one", _roll_levelup_offers(), _apply_offer)


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


## Continuous Final Swarm progress in levels (0 at the start, 1.0 after the first minute ...).
func swarm_progress() -> float:
	return final_swarm_t / GameData.FINAL_SWARM_LEVEL_TIME if final_swarm else 0.0


## Swarm level shown on the HUD: 1 when the swarm starts, +1 every minute.
func swarm_level() -> int:
	return 1 + int(floorf(swarm_progress())) if final_swarm else 0


func hp_mult() -> float:
	var m := (1.0 + GameData.HP_SCALE_PER_MIN * elapsed / 60.0) * difficulty * float(run_mods["hp"])
	if final_swarm:
		m *= 1.0 + GameData.FINAL_SWARM_HP_PER_LEVEL * swarm_progress()
	return m


## Live speed multiplier, applied every frame in Enemies._walk (so the swarm speeds up as it ramps).
func speed_mult() -> float:
	if not final_swarm:
		return 1.0
	return minf(1.0 + GameData.FINAL_SWARM_SPEED_PER_LEVEL * swarm_progress(), GameData.FINAL_SWARM_SPEED_MAX)


func dmg_mult() -> float:
	return (1.0 + GameData.FINAL_SWARM_DMG_PER_LEVEL * swarm_progress()) * float(run_mods["dmg"])


## Threat step for the HUD difficulty meter: one step per two minutes of the run, plus curse
## (every +20% difficulty), plus one per swarm level.
func threat_level() -> int:
	return int(floorf(minf(elapsed, GameData.RUN_TIME) / 120.0)) + int(floorf((difficulty - 1.0) / 0.2)) + swarm_level()


func threat_name() -> String:
	var names: Array = GameData.THREAT_NAMES
	var t := threat_level()
	if t < names.size():
		return names[t]
	return "%s %d" % [names.back(), t - names.size() + 2]


func _update_timeline(delta: float) -> void:
	# Elites every 60 s
	if elapsed >= _next_elite:
		_next_elite += GameData.ELITE_INTERVAL / float(run_mods["elite"])
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
	if not final_swarm and (elapsed >= GameData.RUN_TIME or (_auto and _swarm_at > 0.0 and elapsed >= _swarm_at)):
		_start_final_swarm()
	if final_swarm:
		var before := swarm_level()
		final_swarm_t += delta
		if swarm_level() > before:
			hud.banner("SWARM LEVEL %d" % swarm_level(), Color(1, 0.25, 0.3), 2.5)
			hud.toast("The swarm grows faster and stronger", Color(1, 0.5, 0.4))


func _start_final_swarm() -> void:
	if final_swarm:
		return
	final_swarm = true
	hud.banner("FINAL SWARM", Color(1, 0.2, 0.3), 4.0)
	Sfx.music("boss")


func _update_spawning(delta: float) -> void:
	var rate: float
	if final_swarm:
		rate = GameData.FINAL_SWARM_RATE * (1.0 + GameData.FINAL_SWARM_RATE_PER_LEVEL * swarm_progress())
	else:
		rate = lerp(GameData.SPAWN_RATE_START, GameData.SPAWN_RATE_END, clamp(elapsed / GameData.RUN_TIME, 0.0, 1.0))
		if surge_active():
			rate *= _surge_mult
	rate *= difficulty * float(run_mods["spawn"])
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
	var allowed: Array = GameData.location_by_id(location_id)["enemies"]
	for k in GameData.ENEMY_TYPES:
		var d: Dictionary = GameData.ENEMY_TYPES[k]
		if d.get("swarm_only", false) or not k in allowed:
			continue
		if elapsed >= float(d["min_time"]):
			keys.append(k)
			weights.append(float(d["weight"]))
	return keys[GameData.weighted_index(rng, weights)]


func _spawn_one() -> void:
	var p := _spawn_point()
	if p == Vector2.INF:
		return
	var cap: int = GameData.FINAL_SWARM_MAX_ENEMIES if final_swarm else GameData.MAX_ENEMIES
	if enemies.count() >= cap:
		enemies.recycle_farthest(p)
		return
	var type := _pick_type()
	if final_swarm and enemies.boss == null:
		var share := minf(GameData.FINAL_SWARM_WRAITH_START + GameData.FINAL_SWARM_WRAITH_PER_LEVEL * swarm_progress(), GameData.FINAL_SWARM_WRAITH_MAX)
		if rng.randf() < share:
			type = "wraith"
	var e := enemies.spawn(type, p, hp_mult(), 1.0)
	e.dmg *= dmg_mult()


func _spawn_elite(at := Vector2.INF) -> Enemies.Enemy:
	var p := at if at != Vector2.INF else _spawn_point()
	if p == Vector2.INF:
		return null
	var affix: String = GameData.ELITE_AFFIXES[rng.randi_range(0, GameData.ELITE_AFFIXES.size() - 1)]
	var e := enemies.spawn(_pick_type(), p, hp_mult(), 1.0, true, affix)
	e.dmg *= dmg_mult()
	return e


# ------------------------------------------------------------------ combat events

func spawn_damage_number(pos: Vector2, amount: float, crit: bool) -> void:
	if pos.distance_to(player.position) < 340.0:
		effects.damage_number(pos, amount, crit)


func on_enemy_killed(e) -> void:
	kills += 1
	Sfx.play("kill")
	if e.pos.distance_to(player.position) < 420.0:
		if e.elite:
			vfx.play("dark_explosion", e.pos, 0.0, 0.45)
		elif vfx.sprites.size() < 100:
			vfx.play("poof", e.pos + Vector2(0, e.radius * 0.5), 0.0, e.radius / 24.0, Color(e.color.lightened(0.5)))
		else:
			vfx.death(e.pos, e.color, e.radius, false)
	if e.elite:
		screen_fx.hitstop(0.05)
		screen_fx.shake(0.3)
		screen_fx.shockwave(e.pos, 90.0, 1.0, 0.5)
	weapons.trait_on_kill(e)
	if e.elite:
		elites_killed += 1
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
			Sfx.play("gem", 0.12)
			xp += value * (1.0 + player.stats["xp_pct"])
			while xp >= xp_next:
				xp -= xp_next
				level += 1
				xp_next = GameData.xp_to_next(level)
				pending_levelups += 1
				Sfx.play("levelup", 0.0)
				player.on_level_up()
				_level_up_vfx()
		Pickups.Kind.GOLD:
			Sfx.play("coin")
			var g: float = value * (1.0 + player.stats["gold_pct"])
			gold += g
			gold_collected += g
		Pickups.Kind.HEAL:
			Sfx.play("heal", 0.0)
			player.heal(value)


func _level_up_vfx() -> void:
	vfx.play("level_up", player.position + Vector2(0, 6), 0.0, 0.5, Color.WHITE, GameData.VFX_LIGHT_BOOST, -1.0, player)
	screen_fx.shockwave(player.position, 70.0, 0.5, 0.4)


func on_pot_broken(pos: Vector2) -> void:
	vfx.sparks(pos, Color(0.9, 0.6, 0.35), 6, 60.0, 0.25, 1.2)
	var r := rng.randf()
	if r < 0.5:
		pickups.drop(pos, Pickups.Kind.GOLD, rng.randi_range(1, 3))
	elif r < 0.85:
		pickups.drop(pos, Pickups.Kind.XP, 2)
	else:
		pickups.drop(pos, Pickups.Kind.HEAL, 10)


func on_player_died() -> void:
	# one revive per run for a rewarded ad (never in autotests; daily ad cap)
	if not _auto and not _revived and not run_over:
		var save := SaveData.load_data()
		if SaveData.ads_left(save, SaveData.today()) > 0:
			hud.show_revive(_revive, func(): _end_run(false))
			return
	_end_run(false)


func _revive() -> void:
	var save := SaveData.load_data()
	if not SaveData.use_ad(save, SaveData.today()):
		_end_run(false)
		return
	SaveData.save_data(save)
	_revived = true
	Ads.show_rewarded(self, "revive", func():
		player.hp = player.stats["max_hp"] * GameData.AD_REVIVE_HP
		player.iframes = 2.5
		vfx.play("heal", player.position + Vector2(0, 6), 0.0, 1.0, Color.WHITE, GameData.VFX_LIGHT_BOOST, -1.0, player)
		get_tree().paused = false)


## The result screen's "double rewards" ad: banks the resource rewards a second time.
func _double_rewards(rewards: Dictionary) -> void:
	var save := SaveData.load_data()
	if not SaveData.use_ad(save, SaveData.today()):
		return
	var loc := location_id
	var r := rewards.duplicate()
	r["essence"] = {loc: int(rewards.get("essence", 0))}
	SaveData.bank_bonus(save, r)
	SaveData.save_data(save)


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
	Sfx.play("chest", 0.0)
	var ready := ready_evolutions()
	if not ready.is_empty():
		_evolve(ready[0], c["pos"])
		return
	var rarity := GameData.roll_rarity(rng, player.stats["luck"], min_rarity)
	var pool := GameData.items_of_rarity(rarity)
	while pool.is_empty() and rarity > 0:
		rarity -= 1
		pool = GameData.items_of_rarity(rarity)
	var it: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	player.apply_mods(it["mods"])
	items_owned[it["id"]] = int(items_owned.get(it["id"], 0)) + 1
	# no lingering effect on chests (Syifa: not important); only rare+ items get a short punch
	if rarity >= 2:
		screen_fx.shockwave(c["pos"], 80.0, 0.8, 0.45)
		screen_fx.hitstop(0.04)
	hud.toast("%s (%s): %s" % [it["name"], GameData.RARITY_NAMES[rarity], it["desc"]], GameData.RARITY_COLORS[rarity])


# ------------------------------------------------------------------ evolutions

## Owned base weapons that meet their evolution's rule: weapon at EVOLVE_LEVEL and its tome owned.
func ready_evolutions() -> Array:
	var out: Array = []
	for id in player.weapon_levels:
		var evo := GameData.evolution_of(id)
		if evo.is_empty():
			continue
		if int(player.weapon_levels[id]) >= GameData.EVOLVE_LEVEL and int(player.tomes.get(evo["tome"], 0)) > 0:
			out.append(id)
	return out


## Shows "ready to evolve" once per weapon, the moment its rule is met.
func _check_evolution_ready() -> void:
	for id in ready_evolutions():
		if _evo_announced.has(id):
			continue
		_evo_announced[id] = true
		var evo := GameData.evolution_of(id)
		hud.banner("%s can evolve — open a chest!" % GameData.weapon_by_id(id)["name"], Color(1.0, 0.85, 0.35), 4.0)
		hud.toast("Next chest: %s" % evo["name"], Color(1.0, 0.85, 0.35))


## Replaces a base weapon by its evolution in the same slot (slot order is kept).
func _evolve(base_id: String, at: Vector2) -> void:
	Sfx.play("evolve", 0.0)
	var evo := GameData.evolution_of(base_id)
	var levels := {}
	for id in player.weapon_levels:
		if id == base_id:
			levels[evo["id"]] = GameData.WEAPON_MAX_LEVEL
		else:
			levels[id] = player.weapon_levels[id]
	player.weapon_levels = levels
	evolutions.append(evo["id"])
	weapons.on_evolved(base_id, evo["id"])
	vfx.play("loot_beam", at, 0.0, 0.9, Color(1.0, 0.85, 0.4))
	vfx.play("level_up", player.position + Vector2(0, 6), 0.0, 0.7, Color(1.0, 0.85, 0.4), GameData.VFX_LIGHT_BOOST, -1.0, player)
	screen_fx.shockwave(player.position, 140.0, 1.0, 0.6)
	screen_fx.hitstop(0.08)
	screen_fx.shake(0.25)
	hud.banner("EVOLUTION!  %s  >  %s" % [GameData.weapon_by_id(base_id)["name"], evo["name"]], Color(1.0, 0.85, 0.35), 4.0)
	hud.toast("%s: %s" % [evo["name"], evo["desc"]], Color(1.0, 0.85, 0.35))


func item_by_id(id: String) -> Dictionary:
	for it in GameData.ITEMS:
		if it["id"] == id:
			return it
	return {}


## Builds 3 level-up cards from tomes (new while a slot is free, or +1 level on an
## owned one) and weapons. Each card rolls a rarity; Luck raises the odds.
func _roll_levelup_offers() -> Array:
	var pool: Array = []
	var weights: Array = []
	var slots_free: bool = player.tomes.size() < tome_slots
	for t in GameData.TOMES:
		var lv: int = int(player.tomes.get(t["id"], 0))
		if lv == 0 and not slots_free:
			continue
		if lv >= int(t["max"]):
			continue
		pool.append({"kind": "tome", "def": t, "level": lv})
		weights.append(float(t["weight"]) * (1.5 if lv > 0 else 1.0))  # owned tomes show up a bit more
	var weapon_slot_free: bool = player.weapon_levels.size() < weapon_slots
	for w in GameData.WEAPONS:
		if w.get("evolved", false):
			continue   # evolutions only come from chests
		var evo := GameData.evolution_of(w["id"])
		if not evo.is_empty() and player.weapon_levels.has(evo["id"]):
			continue   # already evolved: the base weapon is gone for this run
		var lv: int = int(player.weapon_levels.get(w["id"], 0))
		if lv == 0 and not weapon_slot_free:
			continue
		if lv >= GameData.WEAPON_MAX_LEVEL:
			continue
		pool.append({"kind": "weapon", "def": w, "level": lv})
		weights.append(float(w["weight"]))
	var out: Array = []
	while out.size() < 3 and not pool.is_empty():
		var i := GameData.weighted_index(rng, weights)
		out.append(_make_offer(pool[i]))
		pool.remove_at(i)
		weights.remove_at(i)
	if out.is_empty():
		for f in GameData.LEVELUP_FALLBACK:
			out.append({"kind": "fallback", "def": f, "name": f["name"], "desc": f["desc"]})
	return out


func _make_offer(entry: Dictionary) -> Dictionary:
	var d: Dictionary = entry["def"]
	var lv: int = entry["level"]
	if entry["kind"] == "weapon":
		var unlocking := lv == 0
		var desc: String = d["desc"] if unlocking else d["level_desc"]
		var combo := GameData.combo_hint("weapon", d["id"], player.weapon_levels, player.tomes)
		if combo != "":
			desc += "\n" + combo
		return {"kind": "weapon", "def": d, "rarity": 0, "level": lv,
			"name": ("%s (NEW)" % d["name"]) if unlocking else ("%s  Lv %d > %d" % [d["name"], lv, lv + 1]),
			"desc": desc,
			"color": Color(0.6, 0.9, 1.0)}
	var rarity := GameData.roll_rarity(rng, player.stats["luck"])
	var gain := GameData.tome_gain(d, rarity)
	var title: String = ("%s (NEW)" % d["name"]) if lv == 0 else ("%s  Lv %d > %d" % [d["name"], lv, lv + 1])
	var tdesc := "%s  ·  %s" % [GameData.RARITY_NAMES[rarity], GameData.format_gain(d, gain)]
	var tcombo := GameData.combo_hint("tome", d["id"], player.weapon_levels, player.tomes)
	if tcombo != "":
		tdesc += "\n" + tcombo
	return {"kind": "tome", "def": d, "rarity": rarity, "gain": gain, "level": lv,
		"name": title,
		"desc": tdesc,
		"color": GameData.RARITY_COLORS[rarity]}


func _apply_offer(opt: Dictionary) -> void:
	var d: Dictionary = opt["def"]
	match opt["kind"]:
		"tome":
			player.tomes[d["id"]] = int(player.tomes.get(d["id"], 0)) + 1
			if d["stat"] == "curse":
				difficulty += float(opt["gain"])
			else:
				player.apply_mods([[d["stat"], float(opt["gain"])]])
		"weapon":
			player.weapon_levels[d["id"]] = int(player.weapon_levels.get(d["id"], 0)) + 1
		"fallback":
			if d["kind"] == "heal":
				player.heal(player.stats["max_hp"] * float(d["value"]))
			else:
				gold += float(d["value"])
				gold_collected += float(d["value"])
	_check_evolution_ready()


# ------------------------------------------------------------------ shrines

func on_shrine_activated(s: Dictionary) -> void:
	shrines_used += 1
	Sfx.play("shrine", 0.0)
	# the shrine's idle beam goes out (Interactables._ambient); just a small puff where it stood
	var sc: Color = GameData.SHRINE_TYPES[s["type"]]["color"]
	vfx.motes(s["pos"] + Vector2(0, -6), Color(sc.r, sc.g, sc.b) * 1.6, 6, 30.0, 0.6, 2.5, -30.0)
	if s["type"] == "moon":
		vfx.play("heal", player.position + Vector2(0, 6), 0.0, 0.7, Color.WHITE, GameData.VFX_LIGHT_BOOST, -1.0, player)
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
		var e := enemies.spawn(_pick_type(), p, hp_mult(), 1.0)
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
	Sfx.play("portal", 0.0)
	screen_fx.shockwave(interactables.portal["pos"], 120.0, 1.0, 0.6)
	screen_fx.shake(0.3)
	hud.banner("The Rift Portal is opening...", Color(1, 0.3, 0.4), 2.0)


func summon_boss(pos: Vector2) -> void:
	boss_spawned = true
	vfx.play("spawn_portal", pos + Vector2(0, 10), 0.0, 0.75)
	screen_fx.shockwave(pos, 200.0, 1.6, 0.8)
	screen_fx.shake(0.6)
	screen_fx.chroma(0.8)
	screen_fx.hitstop(0.12)
	var b := enemies.spawn_boss(pos, (1.0 + GameData.HP_SCALE_PER_MIN * elapsed / 60.0) * float(run_mods["hp"]))
	b.dmg *= float(run_mods["dmg"])
	hud.banner("%s has emerged!" % boss_cfg["name"], Color(1, 0.3, 0.35), 3.0)
	Sfx.play("boss_roar", 0.0)
	Sfx.music("boss")


func _on_boss_killed(pos: Vector2) -> void:
	boss_killed = true
	vfx.play("big_explosion", pos + Vector2(0, 10), 0.0, 0.8)
	vfx.play("dark_explosion", pos, 0.0, 0.6)
	screen_fx.shockwave(pos, 260.0, 2.0, 0.9)
	screen_fx.shake(0.8)
	screen_fx.chroma(1.0)
	screen_fx.hitstop(0.18)
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
	Sfx.music("")
	Sfx.play("victory" if won else "defeat", 0.0)
	victory = won
	var share := (1.0 if won else GameData.DEFEAT_REWARD_SHARE) * float(run_mods["reward"])
	var academy_gold := int((gold_collected * 2.0 + kills * 0.5) * share)
	var materials := int(kills / 5.0 * share)
	var aether := int(((25 if boss_killed else 0) + final_swarm_t / 10.0) * float(run_mods["reward"]))
	var exp_gain := int((level * 20 + kills * 0.2) * share)
	# Arcane Shards are kept in full on defeat (they come from hard fights, not from the clock)
	var shards := (GameData.SHARDS_BOSS * danger if boss_killed else 0) + elites_killed / GameData.ELITES_PER_SHARD
	# equipment drops and Rift Essence (kept on defeat too: they were found, not earned by the clock)
	var drop_rng := RandomNumberGenerator.new()
	drop_rng.seed = seed_value * 7919 + kills
	var drops: Array = []
	var n_drops := (GameData.EQUIP_DROP_BOSS if boss_killed else 0) + (GameData.EQUIP_DROP_VICTORY if won else 0)
	for i in elites_killed:
		if drop_rng.randf() < GameData.EQUIP_DROP_ELITE_CHANCE:
			n_drops += 1
	for i in n_drops:
		drops.append(GameData.roll_item(drop_rng, GameData.roll_gear_rarity(drop_rng)))
	var loc := location_id
	var essence := kills / GameData.ESSENCE_PER_KILLS + (GameData.ESSENCE_BOSS * danger if boss_killed else 0)
	equipment_dropped = drops.size()
	var drop_names: Array = []
	for it in drops:
		drop_names.append(GameData.item_name(it))
	var char_name: String = player.character["name"]
	var lv_line := ""
	if not _auto:
		var before := SaveData.load_data()
		var lv0 := SaveData.char_level(before, character_id)
		SaveData.add_char_exp(before, character_id, exp_gain)
		var lv1 := SaveData.char_level(before, character_id)
		var b0 := SaveData.bond_level(before, character_id)
		SaveData.add_bond(before, character_id, GameData.BOND_RUN + (GameData.BOND_VICTORY if won else 0))
		var b1 := SaveData.bond_level(before, character_id)
		lv_line = "\n%s Lv %d%s · Bond +%d%s" % [char_name, lv1, ("  (LEVEL UP from %d!)" % lv0) if lv1 > lv0 else "",
			GameData.BOND_RUN + (GameData.BOND_VICTORY if won else 0), ("  (Bond Lv %d: new story!)" % b1) if b1 > b0 else ""]
	var t := int(elapsed)
	var tome_list: Array = []
	for id in player.tomes:
		tome_list.append("%s %d" % [GameData.tome_by_id(id)["name"].replace("Tome of ", "").replace(" Tome", ""), player.tomes[id]])
	var weapon_list: Array = []
	for id in player.weapon_levels:
		weapon_list.append("%s %d" % [GameData.weapon_by_id(id)["name"], player.weapon_levels[id]])
	var text := "%s\n\nKills: %d\nTime: %02d:%02d\nLevel: %d\nChests opened: %d   Shrines used: %d\nExplored: %d%%\nWeapons: %s\nTomes: %s\nDamage dealt: %d\nFinal Swarm survived: %ds\n\nRewards%s:\nGold +%d   Materials +%d   Aether +%d   EXP +%d   Arcane Shards +%d\n%s +%d   Equipment: %s%s\n\nSeed %d" % [
		"VICTORY" if won else "DEFEAT", kills, t / 60, t % 60, level, chests_opened, shrines_used,
		int(fog.explored_ratio() * 100), ", ".join(weapon_list), ", ".join(tome_list) if not tome_list.is_empty() else "-", int(player.damage_dealt), int(final_swarm_t),
		" (sent to the academy)" if won else " (50% on defeat, sent to the academy)", academy_gold, materials, aether, exp_gain, shards,
		GameData.location_by_id(loc)["essence"], essence, ", ".join(drop_names) if not drop_names.is_empty() else "none", lv_line, seed_value]
	print("[run] END ", text.replace("\n", " | "))
	if not _auto:
		var save := SaveData.load_data()
		SaveData.bank_run(save, {"gold": academy_gold, "materials": materials, "aether": aether, "exp": exp_gain,
			"shards": shards, "char_exp": exp_gain, "essence": {loc: essence}, "items": drops},
			{"victory": won, "kills": kills, "time": t, "level": level, "seed": seed_value, "character": character_id,
			"location": location_id, "danger": danger, "chests": chests_opened, "boss": boss_killed,
			"gold": academy_gold, "materials": materials, "aether": aether, "exp": exp_gain, "shards": shards})
		SaveData.save_data(save)
	hud.show_result({"won": won, "kills": kills, "time": t, "level": level, "chests": chests_opened, "shrines": shrines_used,
		"weapons": player.weapon_levels.duplicate(), "tomes": player.tomes.duplicate(), "seed": seed_value, "note": lv_line.strip_edges(),
		"rewards": {"gold": academy_gold, "materials": materials, "aether": aether, "exp": exp_gain, "shards": shards, "essence": essence},
		"items": drops, "can_double": not _auto and SaveData.ads_left(SaveData.load_data(), SaveData.today()) > 0,
		"double": _double_rewards})


func return_to_academy() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/academy.tscn")


func restart() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()


# ------------------------------------------------------------------ autotest

## Headless smoke test: teleports between objectives, auto-picks choices,
## activates the portal, kills the boss, exits. Prints a summary and quits.
func _autotest_step(delta: float) -> void:
	if _shot_path != "" and not _choice_shot_done and elapsed > 4.0 and not hud.choices_open() and "--shot-choice" in OS.get_cmdline_user_args():
		hud.show_choices("LEVEL UP — choose one", _roll_levelup_offers(), _apply_offer)
		return
	if _choice_shot_done and "--shot-result" in OS.get_cmdline_user_args() and not run_over:
		_end_run(true)
		return
	if hud.choices_open():
		if _shot_path != "" and not _choice_shot_done and hud._choice_title.text.begins_with("LEVEL"):
			_choice_shot_done = true
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(_shot_path.replace(".png", "_choice.png"))
		hud.pick_choice(0)
	if run_over:
		if _finishing:
			return
		_finishing = true
		if _shot_path != "":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(_shot_path.replace(".png", "_end.png"))
		print("[autotest] slots=%d/%d tomes=%s weapons=%s items=%d evolutions=%s char=%s trait_procs=%d lessons=%s char_level=%d enhance=%d,%d max_hp=%d shards=%d equipment=%d loc=%s danger=%d" % [tome_slots, weapon_slots, player.tomes, player.weapon_levels, items_owned.size(), evolutions,
			character_id, weapons.trait_procs, _lessons_applied, char_bonus["level"], char_bonus["passive"], char_bonus["weapon"], int(player.stats["max_hp"]),
			(GameData.SHARDS_BOSS if boss_killed else 0) + elites_killed / GameData.ELITES_PER_SHARD, equipment_dropped, location_id, danger])
		print("[autotest] done victory=%s elapsed=%.0f kills=%d level=%d chests=%d shrines=%d explored=%.2f enemies_alive=%d final_swarm=%s swarm_t=%.0f swarm_lv=%d threat=%s" % [
			victory, elapsed, kills, level, chests_opened, shrines_used, fog.explored_ratio(), enemies.count(), final_swarm, final_swarm_t, swarm_level(), threat_name()])
		get_tree().quit()
		return
	_maybe_shot(false)
	if _profile and elapsed >= _profile_next:
		_profile_next += 20.0
		var now := Time.get_ticks_msec()
		print("[profile] t=%.0f real_ms_per_20s=%d enemies=%d shots=%d zones=%d strikes=%d sprites=%d weapons=%s" % [
			elapsed, now - _profile_ms, enemies.count(), projectiles.list.size(), weapons._zones.size(),
			weapons._strikes.size(), vfx.sprites.size(), player.weapon_levels])
		_profile_ms = now
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
	var times := _shot_times
	if _shots_taken < times.size() and elapsed >= float(times[_shots_taken]):
		var path := _shot_path.replace(".png", "_%d.png" % _shots_taken)
		_shots_taken += 1
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(path)
		print("[autotest] screenshot ", path)
