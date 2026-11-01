class_name UiKit
extends RefCounted
## Shared menu look: pixel-art UI (Syifa's reference: Overgeared Hero). Hard-edged PixelStyle frames (black
## outline, purple border with bevel, notched corners, striped fill), Galmuri pixel fonts (Galmuri 9 body,
## Galmuri 11 Bold titles/buttons, SIL OFL) and pixel icons (assets/ui/icons, PixelLab). Font sizes snap to the
## fonts' pixel grids (`fs`, `tfs`) so the letters stay crisp blocks.

const NAVY := Color("221a40")
const GOLD := Color("ffd062")
const GOLD_DIM := Color("b8872e")
const IVORY := Color("f4f0ff")
const CYAN := Color("6fe3ff")
const PURPLE := Color("a58cff")
const RED := Color("ff6b6b")
const GREEN := Color("6dff8a")
const GREY := Color("5a5570")

const TITLE_FONT := preload("res://assets/fonts/title.tres")
const BOLD_FONT := preload("res://assets/fonts/bold.tres")
const ICON_DIR := "res://assets/ui/icons/"

static var _icons := {}


## Font sizes on the fonts' pixel grids (whole virtual pixels, crisp at any integer screen scale):
## body Galmuri 9 = 10 / 20, titles and buttons Galmuri 11 Bold = 12 / 24.
static func fs(size: int) -> int:
	return 10 if size < 15 else 20


static func tfs(size: int) -> int:
	return 12 if size < 18 else 24


static func label(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs(size))
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color("05030c"))
	l.add_theme_constant_override("outline_size", 2)
	l.add_theme_constant_override("line_spacing", 0)
	return l


## A bold pixel title with a dark outline.
static func title(text: String, size: int, col := IVORY) -> Label:
	var l := label(text, size, col)
	l.add_theme_font_override("font", TITLE_FONT)
	l.add_theme_font_size_override("font_size", tfs(size))
	l.add_theme_constant_override("outline_size", 3)
	return l


## Panel style. `border` CYAN = selected, GREY = disabled, GOLD = highlighted frame, NAVY = dark inset well
## (rows inside a panel), else the main purple panel.
static func style(border: Color, margin := 8.0) -> PixelStyle:
	var sb := PixelStyle.new()
	sb.drop = 0
	if border == CYAN:
		sb.border = Color("ffd062")
		sb.light = Color("fff3c2")
		sb.shade = Color("a8721c")
		sb.glow = Color(1.0, 0.85, 0.35, 0.5)
		sb.fill = Color("4a3a9a")
		sb.fill_dark = Color("5444aa")
	elif border == GREY:
		sb.border = Color("4a4560")
		sb.light = Color("625c7c")
		sb.shade = Color("2a2638")
		sb.fill = Color("221e33")
		sb.fill_dark = Color("26223a")
	elif border == GOLD:
		sb.border = Color("e2a93a")
		sb.light = Color("ffe08a")
		sb.shade = Color("8a5a14")
	elif border == NAVY:
		sb.border = Color("3e3082")
		sb.light = Color("5040a0")
		sb.shade = Color("181034")
		sb.fill = Color("1b1440")
		sb.fill_dark = Color("201848")
		sb.border_w = 1
	sb.set_content_margin_all(margin)
	return sb


## A dark inset row / box inside a panel; returns [panel, vbox].
static func well(margin := 5.0) -> Array:
	return panel(margin, NAVY)


## Button looks: "normal" (lavender), "primary" (gold-framed dark call to action), "accent" (green confirm),
## "danger" (red), "info" (blue).
static func button_style(kind: String, state: String) -> PixelStyle:
	var sb := PixelStyle.new()
	sb.set_content_margin_all(4.0)
	sb.drop = 0 if state == "pressed" else 2
	if state == "disabled":
		sb.border = Color("4a4560")
		sb.light = Color("625c7c")
		sb.shade = Color("2a2638")
		sb.fill = Color("2a2640")
		sb.fill_dark = Color("2e2a46")
		return sb
	match kind:
		"normal":
			sb.fill = Color("5640b0")
			sb.fill_dark = Color("5e48bc")
			sb.border = Color("a08cf0")
			sb.light = Color("d6ccff")
			sb.shade = Color("33257a")
		"primary":
			sb.fill = Color("3a2412")
			sb.fill_dark = Color("452b15")
			sb.border = Color("f2b53a")
			sb.light = Color("ffe08a")
			sb.shade = Color("9a6512")
			sb.border_w = 3
		"accent":
			sb.fill = Color("1f8a5a")
			sb.fill_dark = Color("249864")
			sb.border = Color("6dffa8")
			sb.light = Color("c8ffe0")
			sb.shade = Color("135a38")
		"danger":
			sb.fill = Color("a3302a")
			sb.fill_dark = Color("b03832")
			sb.border = Color("ff8a6a")
			sb.light = Color("ffd0c0")
			sb.shade = Color("5a1612")
		"info":
			sb.fill = Color("2a5fb0")
			sb.fill_dark = Color("3068bc")
			sb.border = Color("8fd0ff")
			sb.light = Color("d8f0ff")
			sb.shade = Color("17356a")
	if state == "hover":
		sb.fill = sb.fill.lightened(0.12)
		sb.fill_dark = sb.fill_dark.lightened(0.12)
		sb.border = sb.border.lightened(0.2)
	elif state == "pressed":
		sb.fill = sb.fill.darkened(0.2)
		sb.fill_dark = sb.fill_dark.darkened(0.2)
	return sb


static func button(text: String, min_size: Vector2, cb: Callable, kind := "normal") -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_font_override("font", BOLD_FONT)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, button_style(kind, st))
	var txt := GOLD if kind == "primary" else IVORY
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, txt)
	b.add_theme_color_override("font_disabled_color", Color(IVORY, 0.35))
	b.add_theme_color_override("font_outline_color", Color("05030c"))
	b.add_theme_constant_override("outline_size", 2)
	b.pressed.connect(cb)
	return b


## Marks a button (tab, roster tile, picked option) as selected: cyan frame + glow.
static func set_selected(b: Button, on: bool, kind := "normal") -> void:
	var st := style(CYAN, 4.0) if on else button_style(kind, "normal")
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", style(CYAN, 4.0) if on else button_style(kind, "hover"))


## A pixel panel holding a VBox; returns [panel, vbox].
static func panel(margin := 8.0, border := PURPLE) -> Array:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(border, margin))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	p.add_child(box)
	return [p, box]


## A section header: dark bar with a gold title and an optional icon.
static func header(text: String, size := 12, icon_name := "") -> Control:
	var p := PanelContainer.new()
	var sb := style(NAVY, 2.0)
	sb.pattern = false
	sb.fill = Color("120c2c")
	sb.content_margin_left = 5
	p.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	p.add_child(row)
	if icon_name != "" and icon_tex(icon_name) != null:
		row.add_child(icon_rect(icon_name, 16))
	var t := title(text, size, GOLD)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(t)
	return p


## A full-screen dimmed overlay with a centred pixel panel; returns [overlay, content VBox, title Label].
## With a `heading`, a red ribbon sits on the panel's top edge; with `close`, a red diamond X sits at its corner.
static func overlay(parent: Control, width: float, heading := "", close := Callable()) -> Array:
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.0, 0.04, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	parent.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -12)
	col.custom_minimum_size = Vector2(width, 0)
	center.add_child(col)
	var t: Label = null
	if heading != "" or close.is_valid():
		var top := HBoxContainer.new()
		top.z_index = 1
		col.add_child(top)
		var pad := Control.new()
		pad.custom_minimum_size = Vector2(22, 0)
		top.add_child(pad)
		var rb := ribbon(heading)
		rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rb.visible = heading != ""
		top.add_child(rb)
		t = rb.get_child(0)
		if close.is_valid():
			var x := close_button(close)
			x.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			top.add_child(x)
		else:
			top.add_child(pad.duplicate())
	var p := PanelContainer.new()
	var ps := style(PURPLE, 10.0)
	ps.border_w = 3
	ps.rivets = true
	if heading != "":
		ps.content_margin_top = 18
	p.add_theme_stylebox_override("panel", ps)
	col.add_child(p)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	p.add_child(box)
	return [dim, box, t]


## The red diamond close button (top-right corner of overlays).
static func close_button(cb: Callable) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(22, 22)
	b.pressed.connect(cb)
	b.draw.connect(func():
		var m := (b.size * 0.5).floor()
		var down := b.is_pressed() and b.get_draw_mode() == BaseButton.DRAW_PRESSED
		var o := Vector2(0, 1) if down else Vector2.ZERO
		for ring in [[11, Color("05030c")], [9, Color("7a1414")], [8, Color("e0453a")]]:
			var r: int = ring[0]
			var pts := PackedVector2Array([m + o + Vector2(0, -r), m + o + Vector2(r, 0), m + o + Vector2(0, r), m + o + Vector2(-r, 0)])
			b.draw_colored_polygon(pts, ring[1])
		b.draw_colored_polygon(PackedVector2Array([m + o + Vector2(0, -8), m + o + Vector2(8, 0), m + o + Vector2(0, -2), m + o + Vector2(-8, 0)]), Color("ff7a5c"))
		for d in [Vector2(1, 1), Vector2(1, -1)]:
			for k in range(-3, 4):
				b.draw_rect(Rect2(m + o + d * k - Vector2(1, 1), Vector2(2, 2)), Color("fff1d6")))
	return b


## A square button with a pixel icon (gear, back) in the purple frame.
static func icon_button(icon_name: String, sz: Vector2, cb: Callable, kind := "normal") -> Button:
	var b := button("", sz, cb, kind)
	# 32 px icons drawn at 32 or 16 virtual px (= 1:1 on a 2x screen) stay crisp
	var room := minf(sz.x, sz.y) - 6.0
	var px := 32.0 if room >= 30.0 else (16.0 if room >= 16.0 else room)
	var ic := icon_rect(icon_name, px)
	ic.custom_minimum_size = Vector2.ZERO
	ic.position = ((sz - Vector2(px, px)) * 0.5).floor()
	ic.size = Vector2(px, px)
	b.add_child(ic)
	return b


## A square framed portrait: head and shoulders of the character's 64 px sprite (gold frame for the Rift button).
static func portrait(id_getter: Callable, px: float, frame := PURPLE) -> Control:
	var c := Panel.new()
	c.custom_minimum_size = Vector2(px, px)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := style(frame, 0.0)
	sb.pattern = false
	sb.fill = Color("2b2457")
	c.add_theme_stylebox_override("panel", sb)
	var pic := Control.new()
	pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	c.add_child(pic)
	pic.draw.connect(func():
		var tex := CharacterArt.portrait(String(id_getter.call()))
		if tex == null:
			return
		var inner := Rect2(Vector2(4, 4), pic.size - Vector2(8, 8)).abs()
		var src_px := 32.0
		var src := Rect2(16, 2, src_px, src_px * inner.size.y / maxf(1.0, inner.size.x))
		pic.draw_texture_rect_region(tex, inner, src))
	c.set_meta("pic", pic)
	return c


static func refresh_portrait(c: Control) -> void:
	(c.get_meta("pic") as Control).queue_redraw()


## A dark square item slot with an icon (cards, gear, inventory).
static func slot(icon_name: String, px: float, frame := PURPLE) -> Panel:
	var c := Panel.new()
	c.custom_minimum_size = Vector2(px, px)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := style(frame, 0.0)
	sb.pattern = false
	sb.fill = Color("120d24")
	c.add_theme_stylebox_override("panel", sb)
	var room := px - 6.0
	var ipx := 64.0 if room >= 64.0 else (32.0 if room >= 32.0 else 16.0)   # whole multiples of the 32 px art
	var ic := icon_rect(icon_name, ipx)
	ic.custom_minimum_size = Vector2.ZERO
	ic.position = ((Vector2(px, px) - Vector2(ipx, ipx)) * 0.5).floor()
	ic.size = Vector2(ipx, ipx)
	c.add_child(ic)
	return c


## Frame colour for a rarity colour: the rarity colour as border with a matching bevel.
static func rarity_style(col: Color, margin := 4.0) -> PixelStyle:
	var sb := style(PURPLE, margin)
	sb.border = col.darkened(0.15)
	sb.light = col.lightened(0.35)
	sb.shade = col.darkened(0.55)
	sb.fill = Color("1c1538")
	sb.fill_dark = Color("231a45")
	return sb


## A thin progress bar (EXP, bond).
static func bar(k: float, w: float, col := CYAN) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 6)
	c.draw.connect(func():
		var r := Rect2(Vector2.ZERO, c.size.floor())
		c.draw_rect(r, Color("05030c"))
		var inner := r.grow(-1)
		c.draw_rect(inner, Color("2a2148"))
		var fw := floorf(inner.size.x * clampf(k, 0, 1))
		c.draw_rect(Rect2(inner.position, Vector2(fw, inner.size.y)), col)
		c.draw_rect(Rect2(inner.position, Vector2(fw, 1)), col.lightened(0.45)))
	return c


## An icon + value pair (stats, resources). Returns the HBox; the value label is its child 1.
static func chip(icon_name: String, text: String, col := IVORY) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 2)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_child(icon_rect(icon_name, 16))
	var l := label(text, 10, col)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(l)
	return r


## Resource icons + amounts for a cost dictionary, red when the save cannot pay that part.
static func cost_chips(cost: Dictionary, save := {}) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 6)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k in cost:
		if int(cost[k]) <= 0:
			continue
		var ok := save.is_empty() or int(save.get(k, 0)) >= int(cost[k])
		r.add_child(chip(k if icon_tex(k) != null else "materials", str(int(cost[k])), IVORY if ok else RED))
	return r


## Rank pips: filled gold squares for the ranks owned, dark ones for the rest.
static func pips(n: int, total: int, col := GOLD) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(total * 8, 8)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		for i in total:
			var r := Rect2(i * 8, 1, 6, 6)
			c.draw_rect(r.grow(1), Color("05030c"))
			c.draw_rect(r, col if i < n else Color("2a2148"))
			if i < n:
				c.draw_rect(Rect2(r.position, Vector2(6, 1)), col.lightened(0.5)))
	return c


## A button holding an icon row (label + cost chips) instead of plain text; returns [button, content HBox].
static func rich_button(min_size: Vector2, cb: Callable, kind := "primary") -> Array:
	var b := button("", min_size, cb, kind)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	return [b, row]


## The pixel icon for a stat key (equipment, lessons, boons).
static func stat_icon(stat: String) -> String:
	match stat:
		"damage_pct", "damage": return "damage"
		"crit": return "crit"
		"attack_speed_pct": return "haste"
		"max_hp": return "hp"
		"armor": return "armor"
		"speed_pct": return "speed"
		"luck": return "fortune"
		"xp_pct": return "study"
		"pickup_pct": return "attraction"
		"regen": return "mending"
		"gold_pct": return "greed"
	return "exp"


## An equipment piece as a rarity-framed icon slot (its main stat's icon).
static func item_slot(it: Dictionary, px := 38.0) -> Panel:
	var base := GameData.equip_base(String(it["base"]))
	var col: Color = GameData.GEAR_RARITY_COLORS[int(it["rarity"])]
	var sl: Panel = slot(stat_icon(String(base["stat"])), px)
	var sb := rarity_style(col, 0.0)
	sb.fill = col.darkened(0.78)
	sb.fill_dark = col.darkened(0.72)
	sl.add_theme_stylebox_override("panel", sb)
	return sl


## A framed banner illustration (assets/ui/banner_*.png, PixelLab) scaled by whole pixels to fit w x h.
static func banner(path: String, w: float, h: float) -> Control:
	var p := PanelContainer.new()
	var sb := style(GOLD, 2.0)
	sb.pattern = false
	sb.fill = Color("05030c")
	p.add_theme_stylebox_override("panel", sb)
	var t := TextureRect.new()
	t.texture = load(path) if ResourceLoader.exists(path) else null
	t.custom_minimum_size = Vector2(w - 8, h - 8)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(t)
	return p


## "Gold 250, Arcane Shards 2" for a cost dictionary.
static func cost_text(cost: Dictionary) -> String:
	var parts: Array = []
	for k in cost:
		if int(cost[k]) > 0:
			parts.append("%s %d" % [resource_name(k), int(cost[k])])
	return ", ".join(parts)


static func resource_name(k: String) -> String:
	match k:
		"shards": return "Arcane Shards"
		"exp": return "EXP"
	return k.capitalize()


## Pixel icon texture assets/ui/icons/<name>.png (PixelLab), or null.
static func icon_tex(name: String) -> Texture2D:
	if not _icons.has(name):
		var path := ICON_DIR + name + ".png"
		_icons[name] = load(path) if ResourceLoader.exists(path) else null
	return _icons[name]


## A small icon: the pixel icon when there is one, else a code-drawn fallback.
static func icon(kind: String, size := 10.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(size, size)
	c.draw.connect(func():
		var tex := icon_tex(kind)
		if tex != null:
			c.draw_texture_rect(tex, Rect2(Vector2.ZERO, c.size), false)
		else:
			draw_icon(c, kind, c.size * 0.5, size * 0.5))
	return c


## A TextureRect for a pixel icon at an integer scale of its 32 px source.
static func icon_rect(name: String, px: float) -> TextureRect:
	var t := TextureRect.new()
	t.texture = icon_tex(name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(px, px)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## A red ribbon banner with a title (overlay and level-up headers), drawn centred in its rect.
static func ribbon(text: String, size := 8) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 24)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := title(text, size, Color("fff1d6"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.offset_top = -1
	c.add_child(l)
	var last := [""]
	l.draw.connect(func():
		if l.text != last[0]:   # the band width follows the text
			last[0] = l.text
			c.queue_redraw())
	c.draw.connect(func():
		var w := floorf(c.size.x)
		var h := floorf(c.size.y)
		var f := l.get_theme_font("font")
		var tw := floorf(f.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x) + 36.0
		tw = maxf(tw, 90.0)
		var x0 := floorf((w - tw) * 0.5)
		var band := Rect2(x0, 0, tw, h - 4)
		# folded tails, a little lower than the band
		for side in [-1, 1]:
			var tx := x0 - 9.0 if side < 0 else x0 + tw - 3.0
			var tail := Rect2(tx, 5, 12, h - 5)
			c.draw_rect(tail.grow(1), Color("05030c"))
			c.draw_rect(tail, Color("8e1f1a"))
			var nx := tail.position.x if side < 0 else tail.end.x - 1
			for k in 4:
				var notch := Rect2(nx + (k if side < 0 else -k), tail.position.y + tail.size.y * 0.5 - (4 - k), 1, (4 - k) * 2)
				c.draw_rect(notch, Color("05030c"))
		c.draw_rect(band.grow(1), Color("05030c"))
		c.draw_rect(band, Color("c8352b"))
		c.draw_rect(Rect2(band.position, Vector2(band.size.x, 2)), Color("ff6a52"))
		c.draw_rect(Rect2(band.position + Vector2(0, band.size.y - 2), Vector2(band.size.x, 2)), Color("8e1f1a"))
		c.draw_rect(Rect2(band.position + Vector2(0, 3), Vector2(band.size.x, 1)), Color("f2b53a"))
		c.draw_rect(Rect2(band.position + Vector2(0, band.size.y - 4), Vector2(band.size.x, 1)), Color("f2b53a")))
	return c


## The pixel icon for an in-run choice card (weapon / tome / fallback / shrine boon).
static func option_icon(opt: Dictionary) -> String:
	var d: Dictionary = opt.get("def", opt)
	var id := String(d.get("id", ""))
	if icon_tex(id) != null:
		return id
	match id:
		"cursed": return "rift"
		"fb_heal": return "potion"
		"fb_gold": return "gold"
		"b_dmg": return "damage"
		"b_spd": return "speed"
		"b_hp": return "hp"
		"b_aspd": return "haste"
		"b_luck": return "fortune"
		"b_crit": return "crit"
	return "exp"


static func draw_icon(ci: CanvasItem, kind: String, at: Vector2, r: float) -> void:
	match kind:
		"gold":
			ci.draw_circle(at, r, Color(0.75, 0.5, 0.1))
			ci.draw_circle(at, r * 0.78, Color(1.0, 0.8, 0.25))
			ci.draw_rect(Rect2(at - Vector2(r * 0.15, r * 0.45), Vector2(r * 0.3, r * 0.9)), Color(0.8, 0.55, 0.1))
		"materials":
			ci.draw_rect(Rect2(at - Vector2(r, r * 0.6), Vector2(r * 2, r * 1.2)), Color(0.45, 0.47, 0.52))
			ci.draw_rect(Rect2(at - Vector2(r, r * 0.6), Vector2(r * 2, r * 0.4)), Color(0.7, 0.72, 0.78))
		"aether":
			ci.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -r), at + Vector2(r * 0.7, 0), at + Vector2(0, r), at + Vector2(-r * 0.7, 0)]), Color(0.4, 0.9, 1.0))
			ci.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -r * 0.6), at + Vector2(r * 0.3, 0), at + Vector2(0, r * 0.2), at + Vector2(-r * 0.3, 0)]), Color(0.9, 1.0, 1.0))
		"shards":
			ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-r * 0.2, -r), at + Vector2(r * 0.6, -r * 0.2), at + Vector2(r * 0.2, r), at + Vector2(-r * 0.6, r * 0.2)]), Color(0.75, 0.45, 1.0))
			ci.draw_line(at + Vector2(-r * 0.2, -r), at + Vector2(r * 0.2, r), Color(1, 0.85, 1), 1.0)
		"exp":
			var pts := PackedVector2Array()
			for i in 10:
				var rr := r if i % 2 == 0 else r * 0.45
				pts.append(at + Vector2.from_angle(-PI / 2 + i * PI / 5) * rr)
			ci.draw_colored_polygon(pts, Color(1.0, 0.95, 0.5))
		"essence":
			ci.draw_circle(at, r * 0.8, Color(0.35, 0.85, 0.45))
			ci.draw_circle(at + Vector2(-r * 0.25, -r * 0.25), r * 0.3, Color(0.85, 1.0, 0.85))
