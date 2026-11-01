class_name UiKit
extends RefCounted
## Shared menu look (mobile hero-game style, Syifa's direction): rounded translucent navy glass panels with a light
## rim and glossy top, gold slanted call-to-action buttons, white bold text. Fonts: Nunito (body) and Exo 2 Italic
## (titles / buttons), both SIL OFL. Every panel and button is a GlassStyle.

const NAVY := Color(0.06, 0.08, 0.18, 0.94)
const GOLD := Color(1.0, 0.82, 0.38)
const GOLD_DIM := Color(0.7, 0.55, 0.25)
const IVORY := Color(0.97, 0.97, 1.0)
const CYAN := Color(0.42, 0.9, 1.0)
const PURPLE := Color(0.72, 0.5, 1.0)
const RED := Color(1, 0.45, 0.45)
const GREEN := Color(0.5, 1.0, 0.55)
const GREY := Color(0.4, 0.42, 0.5)

const TITLE_FONT := preload("res://assets/fonts/title.tres")
const BOLD_FONT := preload("res://assets/fonts/bold.tres")


static func label(text: String, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	return l


## A display title (Exo 2 italic) with a soft dark outline.
static func title(text: String, fs: int, col := IVORY) -> Label:
	var l := label(text, fs, col)
	l.add_theme_font_override("font", TITLE_FONT)
	l.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.08, 0.85))
	l.add_theme_constant_override("outline_size", 3)
	return l


## Panel style. `border` CYAN = selected (rim + glow), GREY = disabled, anything else = normal glass.
static func style(border: Color, margin := 8.0) -> GlassStyle:
	var sb := GlassStyle.new()
	if border == CYAN:
		sb.rim = Color(CYAN, 0.95)
		sb.glow = Color(CYAN, 0.8)
		sb.fill_top = Color(0.14, 0.32, 0.55, 0.92)
		sb.fill_bottom = Color(0.06, 0.13, 0.3, 0.92)
	elif border == GREY:
		sb.fill_top = Color(0.16, 0.17, 0.22, 0.8)
		sb.fill_bottom = Color(0.09, 0.1, 0.14, 0.85)
		sb.rim = Color(1, 1, 1, 0.1)
		sb.highlight = Color(1, 1, 1, 0.05)
	sb.set_content_margin_all(margin)
	return sb


## Button looks: "normal" (blue glass), "primary" (gold, slanted: the call to action), "accent" (bright blue).
static func button_style(kind: String, state: String) -> GlassStyle:
	var sb := style(GREY if state == "disabled" else (CYAN if state == "hover" and kind == "normal" else GOLD), 4.0)
	sb.radius = 5.0
	if state == "disabled":
		if kind == "primary":
			sb.slant = 8.0
		return sb
	match kind:
		"normal":
			if state != "hover":
				sb.fill_top = Color(0.2, 0.3, 0.55, 0.92)
				sb.fill_bottom = Color(0.09, 0.14, 0.32, 0.92)
		"primary":
			sb.fill_top = Color(1.0, 0.9, 0.5)
			sb.fill_bottom = Color(0.95, 0.56, 0.12)
			sb.rim = Color(1.0, 0.97, 0.8, 0.9)
			sb.highlight = Color(1, 1, 1, 0.5)
			sb.slant = 8.0
		"accent":
			sb.fill_top = Color(0.3, 0.72, 1.0)
			sb.fill_bottom = Color(0.1, 0.36, 0.8)
			sb.rim = Color(0.75, 0.95, 1.0, 0.8)
			sb.highlight = Color(1, 1, 1, 0.35)
	if state == "pressed":
		var t := sb.fill_top
		sb.fill_top = sb.fill_bottom
		sb.fill_bottom = t
	if state == "hover" and kind != "normal":
		sb.glow = Color(1, 1, 1, 0.5)
	return sb


static func button(text: String, min_size: Vector2, cb: Callable, kind := "normal") -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 9)
	b.add_theme_font_override("font", BOLD_FONT)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, button_style(kind, st))
	var txt := Color(0.25, 0.1, 0.0) if kind == "primary" else IVORY
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, txt)
	b.add_theme_color_override("font_disabled_color", Color(IVORY, 0.4))
	if kind != "primary":
		b.add_theme_color_override("font_outline_color", Color(0, 0, 0.1, 0.6))
		b.add_theme_constant_override("outline_size", 2)
	if kind == "primary":
		b.add_theme_font_override("font", TITLE_FONT)
	b.pressed.connect(cb)
	return b


## Marks a button (tab, roster tile, picked option) as selected: cyan rim + glow.
static func set_selected(b: Button, on: bool, kind := "normal") -> void:
	b.add_theme_stylebox_override("normal", style(CYAN, 4.0) if on else button_style(kind, "normal"))


## A glass panel holding a VBox; returns [panel, vbox].
static func panel(margin := 8.0, border := GOLD) -> Array:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(border, margin))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	p.add_child(box)
	return [p, box]


## A section header: italic title between two thin light rules.
static func header(text: String, fs := 10) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for i in 2:
		var line := ColorRect.new()
		line.color = Color(0.6, 0.8, 1.0, 0.3)
		line.custom_minimum_size = Vector2(0, 1)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(line)
		if i == 0:
			var t := title(text, fs, GOLD)
			row.add_child(t)
	return row


## A full-screen dimmed overlay with a centred glass panel; returns [overlay, content VBox].
static func overlay(parent: Control, width: float) -> Array:
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.01, 0.05, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	parent.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var p := PanelContainer.new()
	var ps := style(GOLD, 10.0)
	ps.fill_top = Color(0.1, 0.16, 0.33, 0.97)
	ps.fill_bottom = Color(0.04, 0.07, 0.17, 0.98)
	p.add_theme_stylebox_override("panel", ps)
	p.custom_minimum_size = Vector2(width, 0)
	center.add_child(p)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	p.add_child(box)
	return [dim, box]


## A thin progress bar (EXP, bond).
static func bar(k: float, w: float, col := CYAN) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 6)
	c.draw.connect(func():
		var r := Rect2(Vector2.ZERO, c.size)
		c.draw_rect(r, Color(0.02, 0.03, 0.08))
		c.draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(k, 0, 1), r.size.y)), col)
		c.draw_rect(r, Color(0.6, 0.8, 1.0, 0.5), false, 1.0))
	return c


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


## Small resource icon drawn in code (gold coin, materials brick, aether crystal, shard, EXP star, essence).
static func icon(kind: String, size := 10.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(size, size)
	c.draw.connect(func(): draw_icon(c, kind, c.size * 0.5, size * 0.5))
	return c


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
