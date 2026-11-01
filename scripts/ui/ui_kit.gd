class_name UiKit
extends RefCounted
## Shared academy look (Syifa's references: navy panels, ornate gold frames, cyan glow, Cinzel titles).
## Every panel and button is drawn with OrnateStyle; fonts are Nunito (body) and Cinzel (titles), both OFL.

const NAVY := Color(0.06, 0.08, 0.18, 0.94)
const GOLD := Color(0.88, 0.72, 0.34)
const GOLD_DIM := Color(0.6, 0.48, 0.22)
const IVORY := Color(0.96, 0.94, 0.86)
const CYAN := Color(0.42, 0.9, 1.0)
const PURPLE := Color(0.72, 0.5, 1.0)
const RED := Color(1, 0.5, 0.5)
const GREEN := Color(0.55, 1.0, 0.6)
const GREY := Color(0.4, 0.4, 0.46)

const TITLE_FONT := preload("res://assets/fonts/title.tres")
const BOLD_FONT := preload("res://assets/fonts/bold.tres")


static func label(text: String, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	return l


## A Cinzel title with a soft dark outline.
static func title(text: String, fs: int, col := GOLD) -> Label:
	var l := label(text, fs, col)
	l.add_theme_font_override("font", TITLE_FONT)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.08, 0.9))
	l.add_theme_constant_override("outline_size", 3)
	return l


## Panel / frame style. `border` gold = normal, cyan = selected (with glow), grey = disabled.
static func style(border: Color, margin := 8.0) -> OrnateStyle:
	var sb := OrnateStyle.new()
	sb.border = border
	sb.inner = Color(border, 0.35)
	if border == CYAN:
		sb.glow = Color(CYAN, 0.9)
		sb.fill_top = Color(0.1, 0.18, 0.32, 0.97)
	if border == GREY:
		sb.fill_top = Color(0.1, 0.1, 0.16, 0.9)
		sb.fill_bottom = Color(0.06, 0.06, 0.1, 0.9)
		sb.ornaments = false
	sb.set_content_margin_all(margin)
	return sb


## Button looks: "normal" (navy + gold), "primary" (gold-amber, the big call to action), "accent" (blue-cyan).
static func button_style(kind: String, state: String) -> OrnateStyle:
	var sb := style(GREY if state == "disabled" else (CYAN if state == "hover" else GOLD), 4.0)
	if state == "disabled":
		return sb
	match kind:
		"primary":
			sb.fill_top = Color(1.0, 0.78, 0.36)
			sb.fill_bottom = Color(0.82, 0.45, 0.12)
			sb.border = Color(1.0, 0.92, 0.6)
			sb.gem = Color(1.0, 1.0, 0.85)
		"accent":
			sb.fill_top = Color(0.25, 0.6, 0.95)
			sb.fill_bottom = Color(0.1, 0.3, 0.7)
			sb.border = Color(0.6, 0.95, 1.0)
	if state == "pressed":
		var t := sb.fill_top
		sb.fill_top = sb.fill_bottom
		sb.fill_bottom = t
	if state == "hover":
		sb.glow = Color(CYAN if kind == "normal" else Color(1, 0.95, 0.7), 0.8)
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
	var txt := Color(0.18, 0.08, 0.02) if kind == "primary" else IVORY
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, txt)
	b.add_theme_color_override("font_disabled_color", Color(IVORY, 0.4))
	if kind == "primary":
		b.add_theme_font_override("font", TITLE_FONT)
	b.pressed.connect(cb)
	return b


## Marks a button (tab, roster tile, picked option) as selected: cyan frame + glow.
static func set_selected(b: Button, on: bool, kind := "normal") -> void:
	b.add_theme_stylebox_override("normal", style(CYAN, 4.0) if on else button_style(kind, "normal"))


## An ornate panel holding a VBox; returns [panel, vbox].
static func panel(margin := 8.0, border := GOLD) -> Array:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(border, margin))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	p.add_child(box)
	return [p, box]


## A section header: Cinzel text between two thin gold rules.
static func header(text: String, fs := 10) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for i in 2:
		var line := ColorRect.new()
		line.color = Color(GOLD, 0.5)
		line.custom_minimum_size = Vector2(0, 1)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(line)
		if i == 0:
			var t := title(text, fs)
			row.add_child(t)
	return row


## A full-screen dimmed overlay with a centred ornate panel; returns [overlay, content VBox].
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
	p.add_theme_stylebox_override("panel", style(GOLD, 10.0))
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
		c.draw_rect(r, Color(GOLD, 0.7), false, 1.0))
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
