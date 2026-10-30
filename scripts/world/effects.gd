class_name Effects
extends Node2D
## Floating damage numbers.

const MAX_NUMBERS := 60
var game: Node
var numbers: Array = []  # {pos, text, t, crit}
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font


func damage_number(pos: Vector2, amount: float, crit: bool) -> void:
	if numbers.size() >= MAX_NUMBERS:
		numbers.pop_front()
	numbers.append({"pos": pos + Vector2(randf_range(-4, 4), -6), "text": str(int(round(amount))), "t": 0.6, "crit": crit})


func _process(delta: float) -> void:
	for n in numbers:
		n["t"] -= delta
		n["pos"].y -= 20.0 * delta
	numbers = numbers.filter(func(n): return n["t"] > 0.0)
	queue_redraw()


func _draw() -> void:
	for n in numbers:
		var a: float = min(1.0, n["t"] * 3.0)
		var col := Color(1, 0.55, 0.2, a) if n["crit"] else Color(1, 1, 1, a)
		var fs := 9 if n["crit"] else 7
		draw_string_outline(_font, n["pos"], n["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 2, Color(0, 0, 0, a))
		draw_string(_font, n["pos"], n["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
