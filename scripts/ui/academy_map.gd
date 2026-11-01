class_name AcademyMap
extends Control
## The academy hub map (home screen): a pannable world with the main hall, every building on its plot and
## decorations. Restored buildings show their PixelLab sprite; ruined ones show rubble with a cyan hologram of
## the building. Drag to move; tap a building to open it (signal building_tapped).

signal building_tapped(id: String)

const TAP_SLOP := 8.0

var shell
var offset := Vector2.ZERO        # world position shown at the top-left of the control
var _tex := {}
var _grass: Texture2D
var _drag_from := Vector2.ZERO
var _drag_start_offset := Vector2.ZERO
var _pressed := false
var _moved := false
var _vel := Vector2.ZERO
var _last_drag := Vector2.ZERO
var _t := 0.0


func _init(s) -> void:
	shell = s
	clip_contents = true
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	mouse_filter = Control.MOUSE_FILTER_STOP
	for id in GameData.ACADEMY_PLOTS.keys() + GameData.ACADEMY_RUINS + ["main_hall", "tree", "lamp", "crystals", "fountain"]:
		var path := "res://assets/academy/%s.png" % id
		_tex[id] = load(path) if ResourceLoader.exists(path) else null
	_grass = _make_grass()


var _centered := false


func center_on(world: Vector2) -> void:
	offset = world - size * 0.5
	_clamp()
	queue_redraw()


func _clamp() -> void:
	var max_off := GameData.ACADEMY_WORLD - size
	offset.x = clampf(offset.x, minf(0.0, max_off.x * 0.5), maxf(0.0, max_off.x))
	offset.y = clampf(offset.y, minf(0.0, max_off.y * 0.5), maxf(0.0, max_off.y))


func _process(delta: float) -> void:
	_t += delta
	if not _centered and size.x > 0.0:
		_centered = true
		center_on(GameData.ACADEMY_MAIN_HALL + Vector2(0, 90))
	if not _pressed and _vel.length() > 5.0:
		offset -= _vel * delta
		_vel = _vel.lerp(Vector2.ZERO, minf(1.0, delta * 5.0))
		_clamp()
	if is_visible_in_tree():
		queue_redraw()


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT or ev is InputEventScreenTouch:
		if ev.pressed:
			_pressed = true
			_moved = false
			_vel = Vector2.ZERO
			_drag_from = ev.position
			_drag_start_offset = offset
			_last_drag = ev.position
		elif _pressed:
			_pressed = false
			if not _moved:
				var id := building_at(ev.position + offset)
				if id != "":
					building_tapped.emit(id)
	elif (ev is InputEventMouseMotion or ev is InputEventScreenDrag) and _pressed:
		if ev.position.distance_to(_drag_from) > TAP_SLOP:
			_moved = true
		if _moved:
			offset = _drag_start_offset - (ev.position - _drag_from)
			_clamp()
			var dt := maxf(get_process_delta_time(), 0.001)
			_vel = (ev.position - _last_drag) / dt
			_last_drag = ev.position


## The building whose sprite covers a world point (front-most first), or "".
func building_at(world: Vector2) -> String:
	var best := ""
	var best_y := -INF
	for id in GameData.ACADEMY_PLOTS:
		var p: Vector2 = GameData.ACADEMY_PLOTS[id]
		var half := 96.0 * GameData.ACADEMY_SPRITE_SCALE * 0.8
		if Rect2(p - Vector2(half, half), Vector2(half, half) * 2).has_point(world) and p.y > best_y:
			best = id
			best_y = p.y
	return best


# ------------------------------------------------------------------ drawing

func _draw() -> void:
	var save: Dictionary = shell.save
	draw_set_transform(-offset.round(), 0.0, Vector2.ONE)
	var world := Rect2(Vector2.ZERO, GameData.ACADEMY_WORLD)
	draw_rect(world.grow(400), Color(0.05, 0.12, 0.08))
	draw_texture_rect(_grass, world, true)
	_draw_paths()
	# everything that stands on the ground, back to front
	var items: Array = []
	for d in GameData.ACADEMY_DECOR:
		items.append({"kind": "decor", "id": d[0], "pos": d[1]})
	items.append({"kind": "main", "id": "main_hall", "pos": GameData.ACADEMY_MAIN_HALL})
	for id in GameData.ACADEMY_PLOTS:
		items.append({"kind": "building", "id": id, "pos": GameData.ACADEMY_PLOTS[id]})
	items.sort_custom(func(a, b): return a["pos"].y < b["pos"].y)
	for it in items:
		match it["kind"]:
			"decor": _draw_sprite(it["id"], it["pos"], 1.8 if it["id"] == "fountain" else 1.0)
			"main": _draw_sprite("main_hall", it["pos"], 1.3)
			"building": _draw_building(save, it["id"], it["pos"])
	for id in GameData.ACADEMY_PLOTS:
		_draw_plate(save, id, GameData.ACADEMY_PLOTS[id])
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_sprite(id: String, pos: Vector2, scale: float, tint := Color.WHITE) -> void:
	var tex: Texture2D = _tex.get(id)
	if tex == null:
		return
	var s := Vector2(tex.get_width(), tex.get_height()) * GameData.ACADEMY_SPRITE_SCALE * scale
	draw_texture_rect(tex, Rect2(pos - s * 0.5, s), false, tint)


func _draw_building(save: Dictionary, id: String, pos: Vector2) -> void:
	var lv := SaveData.building_level(save, id)
	if lv > 0:
		_draw_sprite(id, pos, 1.0)
		return
	var ruin: String = GameData.ACADEMY_RUINS[abs(hash(id)) % GameData.ACADEMY_RUINS.size()]
	_draw_sprite(ruin, pos + Vector2(0, 6), 0.85)
	# blueprint hologram of what will stand here
	var flick := 0.22 + 0.06 * sin(_t * 3.0 + pos.x * 0.01)
	_draw_sprite(id, pos - Vector2(0, 4), 1.0, Color(0.45, 1.3, 1.6, flick))


func _draw_plate(save: Dictionary, id: String, pos: Vector2) -> void:
	var b := GameData.building_by_id(id)
	var lv := SaveData.building_level(save, id)
	var font := UiKit.BOLD_FONT
	var name: String = b["name"]
	var fs := 8
	var w := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 26
	var at := pos + Vector2(-w * 0.5, 42)
	var r := Rect2(at, Vector2(w, 13))
	draw_rect(r, Color(0.03, 0.06, 0.16, 0.78))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color(0.6, 0.85, 1.0, 0.5))
	var max_lv: int = b["costs"].size()
	var badge := Rect2(at + Vector2(1, 1), Vector2(13, 11))
	draw_rect(badge, Color(0.95, 0.65, 0.15) if lv > 0 else Color(0.4, 0.2, 0.6))
	draw_string(font, badge.position + Vector2(0, 9), str(lv), HORIZONTAL_ALIGNMENT_CENTER, badge.size.x, 7, Color(0.1, 0.05, 0))
	draw_string_outline(font, at + Vector2(17, 10), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 2, Color(0, 0, 0.1, 0.8))
	draw_string(font, at + Vector2(17, 10), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	# "ready" marker when the next level is affordable
	var cost := SaveData.next_cost(save, id)
	if lv < max_lv and SaveData.can_afford(save, cost):
		var bob := sin(_t * 4.0 + pos.x) * 2.0
		var c := pos + Vector2(26, -44 + bob)
		draw_circle(c, 7, Color(0.1, 0.6, 0.2))
		draw_circle(c, 6, Color(0.35, 0.95, 0.4))
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -4), c + Vector2(4, 1), c + Vector2(1.5, 1), c + Vector2(1.5, 4),
			c + Vector2(-1.5, 4), c + Vector2(-1.5, 1), c + Vector2(-4, 1)]), Color.WHITE)


## Stone paths from the main hall to every plot (drawn under everything).
func _draw_paths() -> void:
	var hub: Vector2 = GameData.ACADEMY_MAIN_HALL + Vector2(0, 40)
	for id in GameData.ACADEMY_PLOTS:
		var p: Vector2 = GameData.ACADEMY_PLOTS[id] + Vector2(0, 30)
		var mid := Vector2(p.x, hub.y) if absf(p.y - hub.y) > 60 else (hub + p) * 0.5
		var line := PackedVector2Array([hub, mid, p])
		for layer in [[Color(0.3, 0.25, 0.2), 18.0], [Color(0.62, 0.55, 0.44), 14.0]]:
			draw_polyline(line, layer[0], layer[1])
			for q in line:
				draw_circle(q, layer[1] * 0.5, layer[0])
		# cobbles
		for i in line.size() - 1:
			var a: Vector2 = line[i]
			var bpt: Vector2 = line[i + 1]
			var n := int(a.distance_to(bpt) / 9.0)
			for j in n:
				var q := a.lerp(bpt, (j + 0.5) / maxf(1.0, n))
				var side := Vector2(0, 3) if absf(bpt.x - a.x) > absf(bpt.y - a.y) else Vector2(3, 0)
				draw_rect(Rect2(q - side - Vector2(2, 1.5), Vector2(4, 3)), Color(0.7, 0.64, 0.52))
				draw_rect(Rect2(q + side - Vector2(2, 1.5), Vector2(4, 3)), Color(0.55, 0.49, 0.4))
	draw_set_transform(-offset.round() + GameData.ACADEMY_MAIN_HALL + Vector2(0, 145), 0.0, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, 92, Color(0.3, 0.25, 0.2))
	draw_circle(Vector2.ZERO, 89, Color(0.62, 0.55, 0.44))
	draw_arc(Vector2.ZERO, 70, 0, TAU, 48, Color(0.42, 0.75, 0.95, 0.5), 2.0)
	draw_set_transform(-offset.round(), 0.0, Vector2.ONE)


## A 64 px tiling grass texture made once in code (deterministic noise, a few tufts and flowers).
static func _make_grass() -> Texture2D:
	var N := 128
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var base := [Color(0.24, 0.45, 0.2), Color(0.27, 0.5, 0.22), Color(0.22, 0.42, 0.19), Color(0.3, 0.53, 0.24)]
	var k := TAU / N
	for y in N:
		for x in N:
			# periodic low-frequency patches so the tile repeats seamlessly
			var n := (sin(x * k * 2.0) * cos(y * k * 3.0) + sin((x + 2 * y) * k) * 0.7 + cos((3 * x - y) * k) * 0.5) * 0.5
			var c: Color = base[rng.randi() % 4]
			img.set_pixel(x, y, c.lightened(n * 0.06) if n > 0 else c.darkened(-n * 0.08))
	for i in 70:
		var x := rng.randi() % N
		var y := rng.randi() % (N - 2)
		img.set_pixel(x, y, Color(0.36, 0.6, 0.27))
		img.set_pixel(x, y + 1, Color(0.17, 0.35, 0.15))
	for i in 6:
		var x := rng.randi() % N
		var y := rng.randi() % N
		img.set_pixel(x, y, [Color(0.95, 0.9, 0.5), Color(0.9, 0.6, 0.9), Color(0.7, 0.85, 1.0)][i % 3])
	return ImageTexture.create_from_image(img)
