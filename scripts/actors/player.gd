class_name Player
extends Node2D
## The controlled character (Astra placeholder): movement, dash, auto-attack,
## Frost Nova, stats. Visuals are placeholder shapes until sprites exist.

const RADIUS := 5.0
const DASH_TIME := 0.15
const DASH_MULT := 3.2
const DASH_COOLDOWN := 2.5
const HURT_IFRAMES := 0.5
const BASE_ATTACK_CD := 0.8
const ATTACK_RANGE := 220.0
const NOVA_BASE_CD := 3.0
const NOVA_BASE_RADIUS := 60.0

var game: Node  # main.gd

var stats := {
	"max_hp": 100.0, "speed": 90.0, "damage": 10.0, "damage_pct": 0.0,
	"attack_speed_pct": 0.0, "projectiles": 1.0, "bounce": 0.0, "crit": 0.0,
	"area_pct": 0.0, "pickup": 40.0, "pickup_pct": 0.0, "luck": 0.0, "regen": 0.0,
	"gold_pct": 0.0, "xp_pct": 0.0, "speed_pct": 0.0, "nova": 0.0, "nova_power": 0.0,
}
var hp := 100.0
var facing := Vector2.RIGHT
var move_dir := Vector2.ZERO
var dash_t := 0.0
var dash_cd := 0.0
var iframes := 0.0
var attack_t := 0.3
var nova_t := 0.0
var nova_flash := 0.0
var hurt_flash := 0.0
var damage_dealt := 0.0
var god_mode := false   # autotest only


func apply_mods(mods: Array) -> void:
	for m in mods:
		var key: String = m[0]
		var val: float = m[1]
		stats[key] = float(stats.get(key, 0.0)) + val
		if key == "max_hp":
			hp += val


func dmg() -> float: return stats["damage"] * (1.0 + stats["damage_pct"])
func move_speed() -> float: return stats["speed"] * (1.0 + stats["speed_pct"])
func attack_cd() -> float: return BASE_ATTACK_CD / (1.0 + stats["attack_speed_pct"])
func area() -> float: return 1.0 + stats["area_pct"]
func pickup_radius() -> float: return stats["pickup"] * (1.0 + stats["pickup_pct"])
func is_dashing() -> bool: return dash_t > 0.0


func try_dash() -> void:
	if dash_cd > 0.0:
		return
	dash_t = DASH_TIME
	dash_cd = DASH_COOLDOWN


func take_damage(amount: float) -> void:
	if iframes > 0.0 or is_dashing() or god_mode or hp <= 0.0:
		return
	hp -= amount
	iframes = HURT_IFRAMES
	hurt_flash = 0.15
	if hp <= 0.0:
		hp = 0.0
		game.on_player_died()


func heal(amount: float) -> void:
	hp = min(stats["max_hp"], hp + amount)


func _process(delta: float) -> void:
	dash_cd = max(0.0, dash_cd - delta)
	dash_t = max(0.0, dash_t - delta)
	iframes = max(0.0, iframes - delta)
	hurt_flash = max(0.0, hurt_flash - delta)
	nova_flash = max(0.0, nova_flash - delta)
	if stats["regen"] > 0.0 and hp > 0.0:
		heal(stats["regen"] * delta)

	move_dir = game.get_move_input()
	if move_dir.length() > 0.1:
		facing = move_dir.normalized()
	var spd := move_speed() * (DASH_MULT if is_dashing() else 1.0)
	var dir := facing if is_dashing() else move_dir
	position = game.world.move(position, dir * spd * delta, RADIUS)

	_auto_attack(delta)
	_frost_nova(delta)
	queue_redraw()


func _auto_attack(delta: float) -> void:
	attack_t -= delta
	if attack_t > 0.0:
		return
	var target = game.enemies.nearest(position, ATTACK_RANGE, null)
	if target == null:
		attack_t = 0.1
		return
	attack_t = attack_cd()
	var count := int(stats["projectiles"])
	var base_dir: Vector2 = (target.pos - position).normalized()
	for i in count:
		var spread: float = 0.0 if count == 1 else lerp(-0.18 * (count - 1), 0.18 * (count - 1), float(i) / (count - 1))
		game.projectiles.fire(position, base_dir.rotated(spread), dmg(), int(stats["bounce"]), area())


func _frost_nova(delta: float) -> void:
	if stats["nova"] < 1.0:
		return
	nova_t -= delta
	if nova_t > 0.0:
		return
	nova_t = NOVA_BASE_CD / (1.0 + 0.15 * stats["nova_power"])
	nova_flash = 0.25
	var radius := NOVA_BASE_RADIUS * area()
	var amount: float = dmg() * 0.8 * (1.0 + 0.3 * stats["nova_power"])
	for e in game.enemies.query_radius(position, radius):
		game.enemies.damage(e, amount)


func _draw() -> void:
	if nova_flash > 0.0:
		var r := NOVA_BASE_RADIUS * area() * (1.0 - nova_flash * 2.0)
		draw_arc(Vector2.ZERO, max(4.0, r), 0, TAU, 32, Color(0.6, 0.9, 1.0, nova_flash * 3.0), 2.0)
	var blink := iframes > 0.0 and int(iframes * 20.0) % 2 == 0
	if blink:
		return
	# shadow
	draw_circle(Vector2(0, 6), 5, Color(0, 0, 0, 0.3))
	var robe := Color(0.12, 0.18, 0.4) if hurt_flash <= 0.0 else Color(1, 0.4, 0.4)
	# robe (trapezoid)
	draw_colored_polygon(PackedVector2Array([Vector2(-5, 7), Vector2(5, 7), Vector2(3, -1), Vector2(-3, -1)]), robe)
	draw_rect(Rect2(-3, 0, 6, 1), Color(0.85, 0.7, 0.3)) # gold trim
	# head + silver hair
	draw_circle(Vector2(0, -4), 3.5, Color(0.98, 0.86, 0.78))
	draw_rect(Rect2(-4, -8, 8, 3), Color(0.85, 0.88, 0.95))
	draw_rect(Rect2(-4, -6, 2, 5), Color(0.85, 0.88, 0.95))
	draw_rect(Rect2(2, -6, 2, 5), Color(0.85, 0.88, 0.95))
	# staff on facing side
	var sx := 6.0 if facing.x >= 0.0 else -6.0
	draw_line(Vector2(sx, 7), Vector2(sx, -8), Color(0.55, 0.4, 0.25), 1.0)
	draw_circle(Vector2(sx, -9), 1.8, Color(0.4, 1.0, 1.0))
	if is_dashing():
		draw_line(-facing * 4.0, -facing * 14.0, Color(0.5, 0.9, 1.0, 0.6), 3.0)
