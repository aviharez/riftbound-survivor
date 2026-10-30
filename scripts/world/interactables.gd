class_name Interactables
extends Node2D
## Chests, shrines, pots, the boss Rift Portal and the Exit Portal.
## Interaction is automatic: stand inside an object's circle (touch friendly).

const CHEST_RADIUS := 14.0
const CHEST_HOLD := 0.4
const SHRINE_RADIUS := 20.0
const PORTAL_RADIUS := 24.0
const POT_RADIUS := 8.0
const EXIT_RADIUS := 14.0

var game: Node
var chests: Array = []    # {pos, golden, opened, hold, discovered}
var shrines: Array = []   # {pos, type, used, charge, discovered, state, trial_t, trial_id}
var pots: Array = []      # {pos, broken}
var portal := {}          # {pos, discovered, state, charge, t}
var exit_portal := {}     # {pos, active}
var _font: Font
var _time := 0.0


func setup(m: Dictionary, world: World) -> void:
	_font = ThemeDB.fallback_font
	for c in m["chests"]:
		chests.append({"pos": world.cell_center(c), "golden": false, "opened": false, "hold": 0.0, "discovered": false})
	for s in m["shrines"]:
		shrines.append({"pos": world.cell_center(s["cell"]), "type": s["type"], "used": false, "charge": 0.0,
			"discovered": false, "state": "idle", "trial_t": 0.0, "trial_id": -1})
	for p in m["pots"]:
		pots.append({"pos": world.cell_center(p), "broken": false})
	portal = {"pos": world.cell_center(m["portal"]), "discovered": false, "state": "idle", "charge": 0.0, "t": 0.0}
	exit_portal = {"pos": Vector2.ZERO, "active": false}


func add_golden_chest(pos: Vector2) -> void:
	chests.append({"pos": pos, "golden": true, "opened": false, "hold": 0.0, "discovered": true})


func activate_exit(pos: Vector2) -> void:
	exit_portal = {"pos": pos, "active": true}


## Marks objects as discovered once the fog over them is revealed.
func update_discovery(fog: Fog) -> void:
	for c in chests:
		if not c["discovered"] and fog.is_revealed_world(c["pos"]):
			c["discovered"] = true
	for s in shrines:
		if not s["discovered"] and fog.is_revealed_world(s["pos"]):
			s["discovered"] = true
	if not portal["discovered"] and fog.is_revealed_world(portal["pos"]):
		portal["discovered"] = true
		game.on_portal_discovered()


func _process(delta: float) -> void:
	_time += delta
	var ppos: Vector2 = game.player.position

	for c in chests:
		if c["opened"]:
			continue
		if ppos.distance_to(c["pos"]) < CHEST_RADIUS and (c["golden"] or game.can_afford_chest()):
			c["hold"] += delta
			if c["hold"] >= CHEST_HOLD:
				game.open_chest(c)
		else:
			c["hold"] = 0.0

	for s in shrines:
		_update_shrine(s, ppos, delta)

	for p in pots:
		if not p["broken"] and ppos.distance_to(p["pos"]) < POT_RADIUS:
			p["broken"] = true
			game.on_pot_broken(p["pos"])

	_update_portal(ppos, delta)

	if exit_portal["active"] and ppos.distance_to(exit_portal["pos"]) < EXIT_RADIUS:
		exit_portal["active"] = false
		game.on_exit_entered()
	queue_redraw()


func _update_shrine(s: Dictionary, ppos: Vector2, delta: float) -> void:
	if s["used"]:
		return
	var cfg: Dictionary = GameData.SHRINE_TYPES[s["type"]]
	if s["state"] == "trial":
		s["trial_t"] -= delta
		if s["trial_t"] <= 0.0:
			s["used"] = true
			s["state"] = "done"
			game.on_trial_failed(s)
		return
	if ppos.distance_to(s["pos"]) < SHRINE_RADIUS:
		s["charge"] += delta
		if s["charge"] >= float(cfg["charge"]):
			if s["type"] == "trial":
				s["state"] = "trial"
				s["trial_t"] = GameData.TRIAL_DURATION
				game.start_trial(s)
			else:
				s["used"] = true
				game.on_shrine_activated(s)
	else:
		s["charge"] = max(0.0, s["charge"] - delta * 0.5)


func complete_trial(s: Dictionary) -> void:
	s["used"] = true
	s["state"] = "done"


func _update_portal(ppos: Vector2, delta: float) -> void:
	match portal["state"]:
		"idle":
			if ppos.distance_to(portal["pos"]) < PORTAL_RADIUS:
				portal["discovered"] = true
				portal["charge"] += delta
				if portal["charge"] >= GameData.PORTAL_CHARGE:
					portal["state"] = "summoning"
					portal["t"] = GameData.PORTAL_SUMMON_DELAY
					game.on_portal_activated()
			else:
				portal["charge"] = max(0.0, portal["charge"] - delta)
		"summoning":
			portal["t"] -= delta
			if portal["t"] <= 0.0:
				portal["state"] = "boss"
				game.summon_boss(portal["pos"])


func _draw() -> void:
	var cam: Vector2 = game.player.position
	var near := func(p: Vector2) -> bool: return absf(p.x - cam.x) < 380 and absf(p.y - cam.y) < 230

	for p in pots:
		if p["broken"] or not near.call(p["pos"]):
			continue
		var q: Vector2 = p["pos"]
		draw_rect(Rect2(q.x - 3, q.y - 3, 6, 6), Color(0.65, 0.42, 0.25))
		draw_rect(Rect2(q.x - 2, q.y - 5, 4, 2), Color(0.5, 0.32, 0.2))

	for s in shrines:
		if near.call(s["pos"]):
			_draw_shrine(s)

	for c in chests:
		if not c["opened"] and near.call(c["pos"]):
			_draw_chest(c)

	if near.call(portal["pos"]):
		_draw_portal()

	if exit_portal["active"]:
		var e: Vector2 = exit_portal["pos"]
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		draw_circle(e, 12.0, Color(0.3, 0.9, 1.0, 0.25 + 0.2 * pulse))
		draw_arc(e, 12.0, 0, TAU, 32, Color(0.6, 1.0, 1.0), 2.0)
		_label(e + Vector2(0, -18), "EXIT", Color(0.7, 1.0, 1.0))


func _draw_chest(c: Dictionary) -> void:
	var p: Vector2 = c["pos"]
	var body := Color(0.95, 0.75, 0.2) if c["golden"] else Color(0.45, 0.3, 0.6)
	var trim := Color(1.0, 0.95, 0.6) if c["golden"] else Color(0.85, 0.7, 0.3)
	draw_rect(Rect2(p.x - 7, p.y - 4, 14, 9), body)
	draw_rect(Rect2(p.x - 7, p.y - 7, 14, 4), body.lightened(0.15))
	draw_rect(Rect2(p.x - 7, p.y - 3, 14, 1), trim)
	draw_rect(Rect2(p.x - 1, p.y - 3, 2, 3), trim)
	if c["hold"] > 0.0:
		draw_arc(p, 11, -PI / 2, -PI / 2 + TAU * c["hold"] / CHEST_HOLD, 24, Color.WHITE, 1.5)
	if c["golden"]:
		_label(p + Vector2(0, -11), "FREE", Color(1, 0.9, 0.4))
	else:
		var price: int = game.chest_price()
		_label(p + Vector2(0, -11), "%d g" % price, Color(1, 0.85, 0.3) if game.can_afford_chest() else Color(1, 0.4, 0.4))


func _draw_shrine(s: Dictionary) -> void:
	var cfg: Dictionary = GameData.SHRINE_TYPES[s["type"]]
	var p: Vector2 = s["pos"]
	var col: Color = cfg["color"]
	if s["used"]:
		col = col.darkened(0.6)
	draw_arc(p, SHRINE_RADIUS, 0, TAU, 40, Color(col, 0.5), 1.0)
	draw_rect(Rect2(p.x - 4, p.y - 10, 8, 14), Color(0.55, 0.55, 0.62) if not s["used"] else Color(0.3, 0.3, 0.35))
	draw_circle(p + Vector2(0, -12), 3.0, col)
	if not s["used"] and s["charge"] > 0.0 and s["state"] == "idle":
		draw_arc(p, SHRINE_RADIUS - 3, -PI / 2, -PI / 2 + TAU * min(1.0, s["charge"] / float(cfg["charge"])), 40, col, 2.0)
	if s["state"] == "trial":
		_label(p + Vector2(0, -20), "%ds" % ceili(s["trial_t"]), Color(1, 0.5, 0.4))
	elif not s["used"]:
		_label(p + Vector2(0, -20), cfg["name"], Color(col, 0.9))


func _draw_portal() -> void:
	var p: Vector2 = portal["pos"]
	var st: String = portal["state"]
	var t := _time
	var col := Color(0.9, 0.15, 0.3) if st != "done" else Color(0.4, 0.4, 0.4)
	for i in 3:
		var r := 10.0 + i * 5.0 + sin(t * 3.0 + i) * 1.5
		draw_arc(p, r, t * (1.5 + i), t * (1.5 + i) + PI * 1.4, 24, Color(col, 0.9 - i * 0.25), 2.0)
	draw_circle(p, 7.0, Color(0.15, 0.0, 0.15))
	draw_arc(p, PORTAL_RADIUS, 0, TAU, 48, Color(col, 0.35), 1.0)
	if st == "idle" and portal["charge"] > 0.0:
		draw_arc(p, PORTAL_RADIUS + 3, -PI / 2, -PI / 2 + TAU * portal["charge"] / GameData.PORTAL_CHARGE, 48, Color(1, 0.4, 0.4), 2.5)
	if st == "summoning":
		draw_circle(p, 18.0 * (1.0 - portal["t"] / GameData.PORTAL_SUMMON_DELAY), Color(1, 0.2, 0.3, 0.4))
	if st == "idle":
		_label(p + Vector2(0, -30), "RIFT PORTAL", Color(1, 0.5, 0.5))


func _label(p: Vector2, text: String, col: Color) -> void:
	var fs := 8
	var size := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string_outline(_font, p - Vector2(size.x / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 2, Color(0, 0, 0, 0.8))
	draw_string(_font, p - Vector2(size.x / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
