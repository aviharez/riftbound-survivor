class_name Player
extends Node2D
## The controlled character (Astra placeholder): movement, dash, HP and stats.
## Attacks live in weapons.gd. Visuals are placeholder shapes until sprites exist.

const RADIUS := 5.0
const DASH_TIME := 0.15
const DASH_MULT := 3.2
const DASH_COOLDOWN := 2.5
const HURT_IFRAMES := 0.5

var game: Node  # main.gd

var stats := {
	"max_hp": 100.0, "speed": 90.0, "damage": 10.0, "damage_pct": 0.0,
	"attack_speed_pct": 0.0, "projectiles": 0.0, "bounce": 0.0, "crit": 0.0,
	"area_pct": 0.0, "pickup": 40.0, "pickup_pct": 0.0, "luck": 0.0, "regen": 0.0,
	"gold_pct": 0.0, "xp_pct": 0.0, "speed_pct": 0.0, "armor": 0.0, "heal_pct": 0.0,
}
var hp := 100.0
var tomes := {}          # tome id -> level (insertion order = slot order)
var weapon_levels := {"bolt": 1}  # weapon id -> level (insertion order = slot order)
var character: Dictionary = GameData.CHARACTERS[0]
var facing := Vector2.RIGHT
var move_dir := Vector2.ZERO
var dash_t := 0.0
var dash_cd := 0.0
var iframes := 0.0
var hurt_flash := 0.0
var damage_dealt := 0.0
var god_mode := false   # autotest only
var trait_power := 1.0  # passive enhance: trait strength multiplier
var signature_rank := 0 # signature-weapon enhance rank (starter weapon and its evolution)


## Applies a character's base stats and starter weapon. Call before the run starts.
## Afterimages are drawn as flat silhouettes (sprite alpha, one colour) by a child node behind the hero.
const GHOST_SHADER := """
shader_type canvas_item;
varying vec4 vcol;
void vertex() { vcol = COLOR; }
void fragment() { COLOR = vec4(vcol.rgb, vcol.a * texture(TEXTURE, UV).a); }
"""
var _ghost_node: Node2D


func _ready() -> void:
	_ghost_node = Node2D.new()
	_ghost_node.show_behind_parent = true
	var sh := Shader.new()
	sh.code = GHOST_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	_ghost_node.material = mat
	_ghost_node.draw.connect(_draw_ghosts)
	add_child(_ghost_node)


func setup_character(c: Dictionary) -> void:
	character = c
	for k in c["base"]:
		stats[k] = float(c["base"][k])
	hp = stats["max_hp"]
	weapon_levels = {c["starter"]: 1}


func on_level_up() -> void:
	apply_mods(character["per_level"])


func apply_mods(mods: Array) -> void:
	for m in mods:
		var key: String = m[0]
		var val: float = m[1]
		stats[key] = float(stats.get(key, 0.0)) + val
		if key == "max_hp":
			hp += val


func dmg() -> float: return stats["damage"] * (1.0 + stats["damage_pct"])
func move_speed() -> float: return stats["speed"] * (1.0 + stats["speed_pct"])
func area() -> float: return 1.0 + stats["area_pct"]
func pickup_radius() -> float: return stats["pickup"] * (1.0 + stats["pickup_pct"])
func is_dashing() -> bool: return dash_t > 0.0


func try_dash() -> void:
	if dash_cd > 0.0:
		return
	dash_t = DASH_TIME
	Sfx.play("dash")
	dash_cd = DASH_COOLDOWN
	_dash_dir = facing.normalized() if facing != Vector2.ZERO else Vector2.RIGHT   # the dash keeps its start direction
	_ghost_t = 0.0
	# a puff of floor dust kicked up behind the hero (flat ellipses, normal blend: no glow)
	var back := -_dash_dir
	for i in GameData.DASH_DUST_COUNT:
		var d := back.rotated(randf_range(-0.9, 0.9))
		_dust.append({"pos": position + Vector2(0, 6) + d * randf_range(1, 5), "vel": d * randf_range(25, 55),
			"t": 0.0, "life": randf_range(0.3, 0.45), "r": randf_range(2.5, 4.5)})


func take_damage(amount: float) -> void:
	if iframes > 0.0 or is_dashing() or hp <= 0.0:
		return
	if game.weapons.trait_block():   # Wren's Page Guard swallows the hit
		iframes = HURT_IFRAMES
		return
	game.weapons.trait_on_hurt()   # Kael's Retaliation (before god mode, so autotests exercise it)
	if god_mode:
		iframes = HURT_IFRAMES
		return
	hp -= amount * (1.0 - min(GameData.ARMOR_CAP, stats["armor"]))
	iframes = HURT_IFRAMES
	hurt_flash = 0.15
	Sfx.play("hurt")
	game.screen_fx.hurt()
	game.vfx.sparks(position, Color(2.4, 0.4, 0.5), 8, 90.0, 0.25)
	if hp <= 0.0:
		hp = 0.0
		game.on_player_died()


func heal(amount: float) -> void:
	hp = min(stats["max_hp"], hp + amount * (1.0 + stats["heal_pct"]))


func _process(delta: float) -> void:
	dash_cd = max(0.0, dash_cd - delta)
	dash_t = max(0.0, dash_t - delta)
	iframes = max(0.0, iframes - delta)
	hurt_flash = max(0.0, hurt_flash - delta)
	if stats["regen"] > 0.0 and hp > 0.0:
		heal(stats["regen"] * delta)

	move_dir = game.get_move_input()
	if move_dir.length() > 0.1:
		facing = move_dir.normalized()
	var spd := move_speed() * (DASH_MULT if is_dashing() else 1.0)
	var dir := _dash_dir if is_dashing() else move_dir
	position = game.world.move(position, dir * spd * delta, RADIUS)
	if is_dashing():
		_ghost_t -= delta
		if _ghost_t <= 0.0 and _last_tex != null:
			_ghost_t = GameData.DASH_GHOST_EVERY
			_ghosts.append({"pos": position, "tex": _last_tex, "rect": _last_rect, "t": 0.0})
	elif move_dir.length() > 0.1:
		_walk_trail(delta)
	for g in _ghosts:
		g["t"] += delta
	_ghosts = _ghosts.filter(func(g): return g["t"] < GameData.DASH_GHOST_LIFE)
	for d in _dust:
		d["t"] += delta
		d["pos"] += d["vel"] * delta
		d["vel"] *= exp(-6.0 * delta)
	_dust = _dust.filter(func(d): return d["t"] < d["life"])
	queue_redraw()


# Dash look: afterimages of the hero's own sprite in the accent colour, a dust puff, short speed lines.
var _ghosts: Array = []     # {pos, tex, rect, t}
var _dust: Array = []       # {pos, vel, t, life, r}
var _ghost_t := 0.0
var _dash_dir := Vector2.RIGHT
var _last_tex: Texture2D
var _last_rect := Rect2()


## Silhouettes in the accent colour, the oldest faintest (drawn by _ghost_node with GHOST_SHADER).
func _draw_ghosts() -> void:
	var acc := Color(character["colors"]["accent"])
	for g in _ghosts:
		var k: float = g["t"] / GameData.DASH_GHOST_LIFE
		var c := acc.lerp(Color.WHITE, 0.3)
		var col := Color(c.r, c.g, c.b, GameData.DASH_GHOST_ALPHA * (1.0 - k))
		var r: Rect2 = g["rect"]
		_ghost_node.draw_texture_rect(g["tex"], Rect2(r.position + (g["pos"] - position), r.size), false, col)


func _draw_dash_fx() -> void:
	for d in _dust:
		var k: float = d["t"] / d["life"]
		var r: float = d["r"] * (1.0 + k * 1.5)
		draw_set_transform(d["pos"] - position, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, r, Color(0.85, 0.82, 0.75, 0.45 * (1.0 - k)))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _ghost_node != null:
		_ghost_node.queue_redraw()
	if is_dashing():
		# three thin speed lines streaming behind
		var back := -_dash_dir
		var n := back.orthogonal()
		for i in 3:
			var o := n * (i - 1) * 5.0 + Vector2(0, -6)
			draw_line(o + back * 8.0, o + back * (18.0 + 6.0 * (i % 2)), Color(1, 1, 1, 0.55), 1.0)


var _trail_t := 0.0
var _trail_n := 0


## A light trail of the character's accent colour at the feet while walking, with a small spark now and then.
func _walk_trail(delta: float) -> void:
	_trail_t -= delta
	if _trail_t > 0.0:
		return
	_trail_t = GameData.WALK_TRAIL_EVERY
	_trail_n += 1
	var acc := Color(character["colors"]["accent"])
	var feet := position + Vector2(randf_range(-2, 2), 5)
	game.vfx.trail(feet, Color(acc.r * 2.0, acc.g * 2.0, acc.b * 2.0, GameData.WALK_TRAIL_ALPHA), GameData.WALK_TRAIL_SIZE, GameData.WALK_TRAIL_LIFE)
	if _trail_n % 3 == 0:
		game.vfx.motes(feet, Color(acc.r * 1.6, acc.g * 1.6, acc.b * 1.6, GameData.WALK_TRAIL_ALPHA), 1, 10.0, 0.5, 1.2, -14.0)


var _walk_t := 0.0
var _anim_t := 0.0


func _draw() -> void:
	_draw_dash_fx()
	var blink := iframes > 0.0 and int(iframes * 20.0) % 2 == 0
	if blink:
		return
	var moving := move_dir.length() > 0.1
	_walk_t += get_process_delta_time() * (1.0 if moving else 0.0)
	_anim_t += get_process_delta_time()
	var bob := -absf(sin(_walk_t * 11.0)) * 1.5
	draw_set_transform(Vector2(0, 6), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 6, Color(0, 0, 0, 0.35))  # shadow
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var tint := Color(2.2, 0.8, 0.8) if hurt_flash > 0.0 else Color.WHITE
	var cid: String = character["id"]
	var dir_name := CharacterArt.dir_for(facing)
	var anim := "walk" if moving else "idle"
	var anim_frames := CharacterArt.frames(cid, anim, dir_name)
	var tex: Texture2D = CharacterArt.texture(cid, dir_name)
	if not anim_frames.is_empty():
		# animated sprite: the frames carry the step motion, so no procedural bob / squash
		var fps := GameData.CHARACTER_WALK_FPS if moving else GameData.CHARACTER_IDLE_FPS
		tex = anim_frames[int((_walk_t if moving else _anim_t) * fps) % anim_frames.size()]
		bob = 0.0
	if tex != null:
		# 48 px sprite, feet at the shadow; slight squash on each step
		var sz := Vector2(tex.get_width(), tex.get_height()) * (GameData.CHARACTER_SPRITE_HEIGHT / tex.get_height())
		var squash := 1.0 + bob * 0.02
		# sprite feet sit on the last pixel row; anchor them on the shadow
		var rect := Rect2(Vector2(-sz.x * 0.5, 7.0 - sz.y * squash + bob), Vector2(sz.x, sz.y * squash))
		draw_texture_rect(tex, rect, false, tint)
		_last_tex = tex
		_last_rect = rect
		return
	_draw_placeholder(bob, tint)


func _draw_placeholder(bob: float, tint: Color) -> void:
	var col: Dictionary = character["colors"]
	var o := Vector2(0, bob)
	draw_colored_polygon(PackedVector2Array([Vector2(-5, 7) + o, Vector2(5, 7) + o, Vector2(3, -1) + o, Vector2(-3, -1) + o]), Color(col["robe"]) * tint)
	draw_rect(Rect2(Vector2(-3, 0) + o, Vector2(6, 1)), Color(0.85, 0.7, 0.3))
	draw_circle(Vector2(0, -4) + o, 3.5, Color(0.98, 0.86, 0.78) * tint)
	var hair: Color = col["hair"]
	draw_rect(Rect2(Vector2(-4, -8) + o, Vector2(8, 3)), hair)
	draw_rect(Rect2(Vector2(-4, -6) + o, Vector2(2, 5)), hair)
	draw_rect(Rect2(Vector2(2, -6) + o, Vector2(2, 5)), hair)
	var sx := 6.0 if facing.x >= 0.0 else -6.0
	draw_line(Vector2(sx, 7) + o, Vector2(sx, -8) + o, Color(0.55, 0.4, 0.25), 1.0)
	draw_circle(Vector2(sx, -9) + o, 1.8, Color(col["accent"]) * 1.8)
