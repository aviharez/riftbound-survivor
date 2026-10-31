class_name Projectiles
extends Node2D
## Player projectiles for every shooting weapon (Arcane Bolt, Flame Orb, Frost Lance, Thornseed and their
## evolutions, plus Blade Halo's thrown blades).
## Each shot carries its weapon id; the look is that weapon's pixelfx effect (faces right, rotated to
## the flight direction). A shot with bounces left ricochets to the nearest other foe; a shot with
## pierce left flies on through. On-hit extras (shards, roots) are handed back to Weapons.

const BOUNCE_RANGE := 140.0

## shot kind -> [pixelfx effect, impact effect, impact tint, spark colour, (optional) sprite scale multiplier]
const LOOKS := {
	"bolt": ["arcane_bolt", "hit_spark", Color(1, 1, 1), Color(0.6, 1.6, 2.0)],
	"flame": ["flame_orb", "hit_spark", Color(1.0, 0.6, 0.25), Color(2.4, 1.1, 0.3)],
	"lance": ["ice_lance", "hit_spark", Color(0.6, 0.95, 1.0), Color(0.8, 1.7, 2.4)],
	"seed": ["thorn_seed", "hit_spark", Color(0.6, 1.0, 0.4), Color(0.8, 2.0, 0.6)],
	# evolutions
	"solar": ["sun_orb", "hit_spark", Color(1.0, 0.8, 0.3), Color(2.6, 1.8, 0.5)],
	"zero": ["ice_lance", "hit_spark", Color(0.7, 1.0, 1.0), Color(1.0, 1.9, 2.6)],
	"worldseed": ["thorn_seed", "hit_spark", Color(0.6, 1.0, 0.4), Color(0.8, 2.0, 0.6), 1.25],
	"halo_blade": ["astral_blade", "hit_spark", Color(0.7, 0.95, 1.0), Color(0.9, 1.8, 2.6)],
	# Prismatic Barrage: one bolt per element, each wearing that element's projectile look
	"prism_arcane": ["arcane_bolt", "hit_spark", Color(1, 1, 1), Color(0.6, 1.6, 2.0), 1.0],
	"prism_fire": ["flame_orb", "hit_spark", Color(1.0, 0.6, 0.25), Color(2.4, 1.1, 0.3), 1.0],
	"prism_ice": ["ice_lance", "hit_spark", Color(0.6, 0.95, 1.0), Color(0.8, 1.7, 2.4), 0.62],
	"prism_nature": ["thorn_seed", "hit_spark", Color(0.6, 1.0, 0.4), Color(0.8, 2.0, 0.6), 1.1],
	# alpha weapons
	"slash": ["crescent_slash", "hit_spark", Color(0.75, 0.9, 1.0), Color(1.2, 1.7, 2.6)],
	"chakram": ["rune_chakram", "hit_spark", Color(1.0, 0.85, 0.45), Color(2.4, 1.8, 0.6)],
	"familiar_shot": ["arcane_bolt", "hit_spark", Color(0.8, 1.0, 1.0), Color(0.6, 1.6, 2.0)],
}

var game: Node
var list: Array = []  # {kind, pos, vel, dmg, bounces, pierce, life, life0, hit_r, scale, hit: Array}

var _light: Node2D   # additive child that draws the light layer on top
var _anim_t := 0.0


func _ready() -> void:
	_light = Node2D.new()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_light.material = mat
	_light.draw.connect(func(): _draw_layer(_light, "light"))
	add_child(_light)


## Fires one shot of weapon w. size scales hit radius and sprite (player area).
## Returns the shot so callers can tweak it. Shots of a piercing weapon never re-hit a foe.
func fire(kind: String, from: Vector2, dir: Vector2, damage_amount: float, w: Dictionary, bounces: int, pierce: int, size: float) -> Dictionary:
	var life := float(w.get("life", 1.2))
	var look: Array = LOOKS[kind]
	var shot := {"kind": kind, "pos": from, "vel": dir.normalized() * float(w.get("speed", 260.0)), "dmg": damage_amount,
		"bounces": bounces, "pierce": pierce, "piercing": pierce > 0, "life": life, "life0": life,
		"hit_r": float(w.get("hit_r", 4.0)) * size,
		"scale": float(w.get("fx_scale", 0.6)) * size * (float(look[4]) if look.size() > 4 else 1.0), "hit": [], "w": w,
		"age": 0.0, "returning": false}
	shot["scale0"] = shot["scale"]
	shot["hit_r0"] = shot["hit_r"]
	list.append(shot)
	return shot


func _process(delta: float) -> void:
	var player: Player = game.player
	for p in list:
		p["pos"] += p["vel"] * delta
		p["life"] -= delta
		p["age"] += delta
		var w: Dictionary = p["w"]
		if w.has("grow"):
			# Crescent Slash widens as it flies
			var k: float = 1.0 + float(w["grow"]) * clampf(p["age"] / p["life0"], 0.0, 1.0)
			p["scale"] = p["scale0"] * k
			p["hit_r"] = p["hit_r0"] * k
		if w.has("out_time"):
			# Rune Chakram: flies out, then homes back to the hero, able to cut every foe once more
			if not p["returning"] and p["age"] >= float(w["out_time"]):
				p["returning"] = true
				p["hit"].clear()
			if p["returning"]:
				var to: Vector2 = player.position - p["pos"]
				if to.length() < 10.0:
					p["life"] = 0.0
					continue
				# speeds back up on the way home
				p["vel"] = to.normalized() * minf(float(w["speed"]) * 1.15, p["vel"].length() + 500.0 * delta)
			else:
				p["vel"] *= 1.0 - 1.6 * delta   # slows toward the turn
		var look: Array = LOOKS[p["kind"]]
		if game.world.is_solid_at(p["pos"]) and not w.has("out_time"):
			p["life"] = 0.0
			game.vfx.sparks(p["pos"], look[3], 4, 70.0, 0.2, 1.0)
			if p["kind"] == "seed" or p["kind"] == "worldseed":
				game.weapons.on_projectile_hit(p, p["pos"])
			continue
		var hit = _first_hit(p)
		if hit == null:
			continue
		p["hit"].append(hit)
		var crit := randf() < float(player.stats["crit"])
		game.enemies.damage(hit, p["dmg"] * (2.0 if crit else 1.0), crit)
		if crit:
			game.vfx.play("crit_hit", p["pos"], p["vel"].angle(), 0.26)
		else:
			game.vfx.play(look[1], p["pos"], p["vel"].angle(), 0.32, look[2])
		game.weapons.on_projectile_hit(p, hit.pos, hit)
		if p["pierce"] > 0:
			p["pierce"] -= 1
		elif p["bounces"] > 0:
			p["bounces"] -= 1
			p["life"] = p["life0"]
			var nxt = game.enemies.nearest(p["pos"], BOUNCE_RANGE, hit)
			if nxt != null:
				p["vel"] = (nxt.pos - p["pos"]).normalized() * p["vel"].length()
		else:
			p["life"] = 0.0
	# shots that ended this frame (last hit, wall or out of time): Solar / Absolute Zero detonate here
	for p in list:
		if p["life"] <= 0.0:
			game.weapons.on_projectile_end(p)
	list = list.filter(func(p): return p["life"] > 0.0)
	queue_redraw()


## Nearest foe touching the shot that it has not hit yet (pierce) / did not just bounce off.
func _first_hit(p: Dictionary):
	var best = null
	var best_d := INF
	for e in game.enemies.query_radius(p["pos"], p["hit_r"] + 8.0):
		if e in p["hit"] and (p["piercing"] or e == p["hit"].back()):
			continue
		var d: float = e.pos.distance_to(p["pos"]) - e.radius
		if d <= p["hit_r"] and d < best_d:
			best_d = d
			best = e
	return best


func _draw() -> void:
	_anim_t += get_process_delta_time()
	_draw_layer(self, "color")
	_light.queue_redraw()


## Every look faces right; rotating it to the velocity keeps the trail straight behind the head.
func _draw_layer(ci: CanvasItem, layer: String) -> void:
	var lk: float = GameData.VFX_PROJECTILE_LIGHT
	var tint := Color(lk, lk, lk) if layer == "light" else Color.WHITE
	for p in list:
		var def := Vfx.fx_def(LOOKS[p["kind"]][0])
		if def.is_empty():
			continue
		var region := Vfx.frame_region(def, _anim_t)
		var s: float = p["scale"]
		ci.draw_set_transform(p["pos"], p["vel"].angle(), Vector2(s, s))
		ci.draw_texture_rect_region(def[layer], Rect2(-def["pivot"], def["size"]), region, tint)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
