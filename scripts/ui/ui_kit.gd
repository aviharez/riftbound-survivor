class_name UiKit
extends RefCounted
## Shared look for the academy screens (navy panels, gold borders, cyan accents) until the phase 3 reskin.

const NAVY := Color(0.06, 0.08, 0.18, 0.94)
const GOLD := Color(0.86, 0.7, 0.32)
const IVORY := Color(0.96, 0.94, 0.86)
const CYAN := Color(0.4, 0.9, 1.0)
const RED := Color(1, 0.5, 0.5)
const GREY := Color(0.35, 0.35, 0.4)


static func label(text: String, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	return l


static func style(border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = NAVY
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.set_content_margin_all(8)
	return sb


static func button(text: String, min_size: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 9)
	b.add_theme_stylebox_override("normal", style(GOLD))
	b.add_theme_stylebox_override("hover", style(CYAN))
	b.add_theme_stylebox_override("pressed", style(CYAN))
	b.add_theme_stylebox_override("disabled", style(GREY))
	b.pressed.connect(cb)
	return b


## A full-screen dimmed overlay with a centred gold panel; returns [overlay, content VBox].
static func overlay(parent: Control, width: float) -> Array:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	parent.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style(GOLD))
	panel.custom_minimum_size = Vector2(width, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	return [dim, box]


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
