class_name AcademyMap
extends Control
## The academy hub map (home screen): a pannable world with the main hall, every building on its plot and
## decorations, after Syifa's mockup (2 Nov): painted ground (GroundArt "academy": grass, cobbled plaza and
## paths, a forest hedge around the grounds, scattered props), front-view PixelLab buildings drawn at the
## characters' pixel density (ACADEMY_SPRITE_SCALE), cream name tags, the selected mage standing on the plaza.
## Restored buildings show their sprite; ruined ones show rubble with a cyan hologram of the building.
## Drag to move; tap a building to open it (signal building_tapped).

signal building_tapped(id: String)

const TAP_SLOP := 8.0

var shell
var offset := Vector2.ZERO        # world position shown at the top-left of the control
var _tex := {}
var _ground: GroundArt
var _ground_origin := Vector2.ZERO
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
	for id in GameData.ACADEMY_PLOTS.keys() + GameData.ACADEMY_RUINS + ["main_hall", "tree", "lamp", "crystals", "fountain", "bench"]:
		var path := "res://assets/academy/%s.png" % id
		_tex[id] = load(path) if ResourceLoader.exists(path) else null
	if GroundArt.has_art("academy"):
		var m := ground_map()
		_ground_origin = m["origin"]
		_ground = GroundArt.new()
		_ground.show_behind_parent = true
		add_child(_ground)
		_ground.setup(m, "academy")


var _centered := false
var _pending_center := Vector2.INF


func center_on(world: Vector2) -> void:
	if size.x <= 0.0:
		_pending_center = world   # not laid out yet: centre on the first frame instead
		return
	_centered = true
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
		center_on(_pending_center if _pending_center != Vector2.INF else GameData.ACADEMY_MAIN_HALL + Vector2(0, 90))
	if not _pressed and _vel.length() > 5.0:
		offset -= _vel * delta
		_vel = _vel.lerp(Vector2.ZERO, minf(1.0, delta * 5.0))
		_clamp()
	if is_visible_in_tree():
		queue_redraw()
	if _ground != null:
		_ground.position = _ground_origin - offset.round()


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
		var r := _sprite_rect(id, p).grow(-4)
		if r.size == Vector2.ZERO:
			r = Rect2(p - Vector2(36, 36), Vector2(72, 72))
		if r.has_point(world) and p.y > best_y:
			best = id
			best_y = p.y
	return best


# ------------------------------------------------------------------ ground

## The academy grounds as a terrain grid for GroundArt: grass, a cobbled plaza in front of the main hall,
## cobbled paths to every plot, a forest hedge around the grounds (and past them, so panning never shows a
## bare edge). The grid starts ACADEMY_GROUND_MARGIN cells outside the world; returns the map dict + "origin".
static func ground_map() -> Dictionary:
	var T := float(GameData.TILE)
	var mgn := GameData.ACADEMY_GROUND_MARGIN
	var w := int(ceil(GameData.ACADEMY_WORLD.x / T)) + mgn * 2
	var h := int(ceil(GameData.ACADEMY_WORLD.y / T)) + mgn * 2
	var origin := -Vector2(mgn, mgn) * T
	var grid := PackedByteArray()
	grid.resize(w * h)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2611
	var hub: Vector2 = GameData.ACADEMY_MAIN_HALL + Vector2(0, 40)
	var plaza_c: Vector2 = GameData.ACADEMY_MAIN_HALL + GameData.ACADEMY_PLAZA_OFFSET
	var segs: Array = []
	for id in GameData.ACADEMY_PLOTS:
		var p: Vector2 = GameData.ACADEMY_PLOTS[id] + Vector2(0, 34)
		var mid := Vector2(p.x, hub.y) if absf(p.y - hub.y) > 60 else (hub + p) * 0.5
		segs.append([hub, mid])
		segs.append([mid, p])
	var world := Rect2(Vector2.ZERO, GameData.ACADEMY_WORLD)
	for y in h:
		for x in w:
			var c := origin + (Vector2(x, y) + Vector2(0.5, 0.5)) * T
			var t := GameData.T_GRASS
			# forest hedge: everything outside the grounds plus a ragged band inside the edge
			var edge_d := minf(minf(c.x, world.end.x - c.x), minf(c.y, world.end.y - c.y))
			if edge_d < GameData.ACADEMY_HEDGE_BAND + 18.0 * sin(c.x * 0.031) * cos(c.y * 0.027) + rng.randf_range(-4, 4):
				t = GameData.T_WALL
			else:
				var q := (c - plaza_c) / GameData.ACADEMY_PLAZA_RADIUS
				if q.length() < 1.0:
					t = GameData.T_RUINS
				else:
					for sg in segs:
						if _seg_dist(c, sg[0], sg[1]) < GameData.ACADEMY_PATH_HALF:
							t = GameData.T_RUINS
							break
			grid[y * w + x] = t
	# keep props off the buildings, the fountain and the decorations
	var clear: Array = []
	var cell := func(p: Vector2) -> Vector2i: return Vector2i(((p - origin) / T).floor())
	clear.append([cell.call(GameData.ACADEMY_MAIN_HALL), 7.0])
	for id in GameData.ACADEMY_PLOTS:
		clear.append([cell.call(GameData.ACADEMY_PLOTS[id]), 5.0])
	for d in GameData.ACADEMY_DECOR:
		clear.append([cell.call(d[1]), 3.0])
	return {"grid": grid, "w": w, "h": h, "effective_seed": 2611, "keep_clear": clear, "origin": origin}


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


# ------------------------------------------------------------------ drawing

func _draw() -> void:
	var save: Dictionary = shell.save
	draw_set_transform(-offset.round(), 0.0, Vector2.ONE)
	if _ground == null:
		draw_rect(Rect2(Vector2.ZERO, GameData.ACADEMY_WORLD).grow(400), Color(0.2, 0.36, 0.16))
	# everything that stands on the ground, back to front (by the foot of each sprite)
	var items: Array = []
	for d in GameData.ACADEMY_DECOR:
		items.append({"kind": "decor", "id": d[0], "pos": d[1], "foot": _foot(d[0], d[1])})
	items.append({"kind": "main", "id": "main_hall", "pos": GameData.ACADEMY_MAIN_HALL, "foot": _foot("main_hall", GameData.ACADEMY_MAIN_HALL)})
	for id in GameData.ACADEMY_PLOTS:
		items.append({"kind": "building", "id": id, "pos": GameData.ACADEMY_PLOTS[id], "foot": _foot(id, GameData.ACADEMY_PLOTS[id])})
	var hero_at: Vector2 = GameData.ACADEMY_MAIN_HALL + GameData.ACADEMY_HERO_OFFSET
	items.append({"kind": "hero", "pos": hero_at, "foot": hero_at.y})
	items.sort_custom(func(a, b): return a["foot"] < b["foot"])
	for it in items:
		match it["kind"]:
			"decor", "main": _draw_sprite(it["id"], it["pos"])
			"building": _draw_building(save, it["id"], it["pos"])
			"hero": _draw_hero(save, it["pos"])
	for id in GameData.ACADEMY_PLOTS:
		_draw_plate(save, id, GameData.ACADEMY_PLOTS[id])
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Where a sprite centred on `pos` touches the ground (its bottom edge), for back-to-front sorting.
func _foot(id: String, pos: Vector2) -> float:
	return _sprite_rect(id, pos).end.y if _tex.get(id) != null else pos.y


func _sprite_rect(id: String, pos: Vector2) -> Rect2:
	var tex: Texture2D = _tex.get(id)
	if tex == null:
		return Rect2(pos, Vector2.ZERO)
	var s := (Vector2(tex.get_width(), tex.get_height()) * GameData.ACADEMY_SPRITE_SCALE).round()
	return Rect2((pos - s * 0.5).round(), s)


func _draw_sprite(id: String, pos: Vector2, tint := Color.WHITE) -> void:
	var tex: Texture2D = _tex.get(id)
	if tex == null:
		return
	draw_texture_rect(tex, _sprite_rect(id, pos), false, tint)


## A rubble sprite whose bottom lines up with the bottom of building `id`'s sprite.
func _draw_rubble(id: String, pos: Vector2) -> void:
	var ruin: String = GameData.ACADEMY_RUINS[abs(hash(id)) % GameData.ACADEMY_RUINS.size()]
	var b := _sprite_rect(id, pos)
	var tex: Texture2D = _tex.get(ruin)
	if tex == null:
		return
	var s := (Vector2(tex.get_width(), tex.get_height()) * GameData.ACADEMY_SPRITE_SCALE).round()
	draw_texture_rect(tex, Rect2(Vector2(roundf(pos.x - s.x * 0.5), b.end.y - s.y), s), false)


func _draw_building(save: Dictionary, id: String, pos: Vector2) -> void:
	var lv := SaveData.building_level(save, id)
	if not SaveData.construction_of(save, id).is_empty():
		# under construction: the building half-built (warm, see-through) with scaffold poles in front
		if lv == 0:
			_draw_rubble(id, pos)
		_draw_sprite(id, pos, Color(1.0, 0.85, 0.6, 0.75))
		var r := _sprite_rect(id, pos)
		var wood := Color("8a5a2c")
		var xs := [r.position.x + 6, r.position.x + r.size.x * 0.36, r.position.x + r.size.x * 0.64, r.end.x - 7]
		for x in xs:
			draw_rect(Rect2(Vector2(roundf(x) - 1, r.position.y + r.size.y * 0.25), Vector2(3, r.size.y * 0.75)), Color("05030c"))
			draw_rect(Rect2(Vector2(roundf(x), r.position.y + r.size.y * 0.25 + 1), Vector2(1, r.size.y * 0.75 - 2)), wood)
		for fy in [0.45, 0.75]:
			var y := roundf(r.position.y + r.size.y * fy)
			draw_rect(Rect2(Vector2(r.position.x + 4, y - 1), Vector2(r.size.x - 8, 3)), Color("05030c"))
			draw_rect(Rect2(Vector2(r.position.x + 5, y), Vector2(r.size.x - 10, 1)), wood.lightened(0.2))
		return
	if lv > 0:
		_draw_sprite(id, pos)
		return
	_draw_rubble(id, pos)
	# blueprint hologram of what will stand here
	var flick := 0.22 + 0.06 * sin(_t * 3.0 + pos.x * 0.01)
	_draw_sprite(id, pos - Vector2(0, 2), Color(0.45, 1.3, 1.6, flick))


## The selected mage idling on the plaza (as in the mockup), drawn at the in-run size.
func _draw_hero(save: Dictionary, pos: Vector2) -> void:
	var id := String(save.get("character", "astra"))
	var fr: Array = CharacterArt.frames(id, "idle", "south")
	var tex: Texture2D = null
	if fr.size() > 0:
		tex = fr[int(_t * 6.0) % fr.size()]
	else:
		tex = CharacterArt.texture(id, "south")
	if tex == null:
		return
	var s := Vector2(tex.get_width(), tex.get_height()) * 0.5
	draw_set_transform(-offset.round() + pos + Vector2(0, -2), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 9.0, Color(0, 0, 0, 0.25))
	draw_set_transform(-offset.round(), 0.0, Vector2.ONE)
	draw_texture_rect(tex, Rect2((pos - Vector2(s.x * 0.5, s.y * 0.85)).round(), s), false)


## Cream name tag under each building (mockup), with the level in a small gold badge.
func _draw_plate(save: Dictionary, id: String, pos: Vector2) -> void:
	var b := GameData.building_by_id(id)
	var lv := SaveData.building_level(save, id)
	var font := UiKit.BOLD_FONT
	var name: String = b["name"]
	var fs := 12
	var tw := floorf(font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var w := tw + 32
	var sr := _sprite_rect(id, pos)
	var at := Vector2(roundf(pos.x - w * 0.5), roundf(maxf(sr.end.y, pos.y + 20) + 1))
	var r := Rect2(at, Vector2(w, 17))
	draw_style_box(UiKit.frame("tag"), r)
	var badge_c := at + Vector2(12, 8.5)
	draw_circle(badge_c, 6.5, Color("2a1c24"))
	draw_circle(badge_c, 5.5, Color(0.95, 0.7, 0.25) if lv > 0 else Color(0.55, 0.45, 0.62))
	draw_string(UiKit.TITLE_FONT, Vector2(badge_c.x - 6, at.y + 13), str(lv), HORIZONTAL_ALIGNMENT_CENTER, 12, 12, Color("2a1c24") if lv > 0 else Color.WHITE)
	draw_string(font, at + Vector2(22, 13), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("3a2630"))
	var max_lv: int = b["costs"].size()
	# construction timer bubble above the building
	if not SaveData.construction_of(save, id).is_empty():
		var left := SaveData.build_left(save, id, int(Time.get_unix_time_from_system()))
		var done := left <= GameData.FREE_FINISH_SEC
		var txt := "DONE!" if done else ExpeditionPage.time_text(left)
		var tw2 := floorf(font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x) + 26
		var bob2 := roundf(sin(_t * 3.0 + pos.x) * 1.5)
		var br := Rect2(Vector2(roundf(pos.x - tw2 * 0.5), roundf(sr.position.y - 20 + bob2)), Vector2(tw2, 19))
		draw_style_box(UiKit.frame("button", Color(0.6, 1.2, 0.7) if done else Color.WHITE), br)
		var hammer := UiKit.icon_tex("craft")
		if hammer != null:
			draw_texture_rect(hammer, Rect2(br.position + Vector2(3, 1), Vector2(16, 16)), false)
		draw_string_outline(font, br.position + Vector2(20, 14), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 2, Color("05030c"))
		draw_string(font, br.position + Vector2(20, 14), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE if done else Color("ffd062"))
		return
	# "ready" marker when the next level can be started
	if lv < max_lv and SaveData.build_block(save, id) == "":
		var bob := sin(_t * 4.0 + pos.x) * 2.0
		var c := Vector2(sr.end.x - 8, sr.position.y + 10 + bob)
		draw_circle(c, 7, Color(0.1, 0.6, 0.2))
		draw_circle(c, 6, Color(0.35, 0.95, 0.4))
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -4), c + Vector2(4, 1), c + Vector2(1.5, 1), c + Vector2(1.5, 4),
			c + Vector2(-1.5, 4), c + Vector2(-1.5, 1), c + Vector2(-4, 1)]), Color.WHITE)
