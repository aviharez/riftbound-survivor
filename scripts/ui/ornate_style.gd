class_name OrnateStyle
extends StyleBox
## The academy UI frame drawn in code: a chamfered navy panel with a vertical gradient, a gold outer line, a thin
## inner line, small diamond ornaments on the corners and an optional soft outer glow (cyan for "selected").
## Used by every panel and button through UiKit, so the whole UI shares one look.

var fill_top := Color(0.09, 0.12, 0.25, 0.97)
var fill_bottom := Color(0.04, 0.06, 0.15, 0.97)
var border := Color(0.86, 0.7, 0.32)
var inner := Color(0.86, 0.7, 0.32, 0.35)
var glow := Color(0, 0, 0, 0)        # alpha 0 = no glow
var chamfer := 4.0
var ornaments := true
var gem := Color(0.4, 0.9, 1.0)
var border_width := 1.0


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var c := minf(chamfer, minf(rect.size.x, rect.size.y) * 0.3)
	var pts := _octagon(rect, c)
	var cols := PackedColorArray()
	for p in pts:
		var k := (p.y - rect.position.y) / maxf(1.0, rect.size.y)
		cols.append(fill_top.lerp(fill_bottom, k))
	if glow.a > 0.0:
		for i in 3:
			var g := rect.grow(1.5 + i * 1.5)
			var gp := _octagon(g, c + 1.0 + i)
			gp.append(gp[0])
			RenderingServer.canvas_item_add_polyline(to_canvas_item, gp, PackedColorArray([Color(glow, glow.a * (0.55 - i * 0.17))]), 1.5)
	RenderingServer.canvas_item_add_polygon(to_canvas_item, pts, cols)
	var outline := pts.duplicate()
	outline.append(pts[0])
	RenderingServer.canvas_item_add_polyline(to_canvas_item, outline, PackedColorArray([border]), border_width)
	if rect.size.x > 24 and rect.size.y > 18:
		var ins := _octagon(rect.grow(-3.0), maxf(1.0, c - 1.0))
		ins.append(ins[0])
		RenderingServer.canvas_item_add_polyline(to_canvas_item, ins, PackedColorArray([inner]), 1.0)
	if ornaments and rect.size.x > 40 and rect.size.y > 24:
		for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
			_diamond(to_canvas_item, corner, 3.0, border)
			_diamond(to_canvas_item, corner, 1.4, gem)


static func _octagon(r: Rect2, c: float) -> PackedVector2Array:
	var a := r.position
	var b := r.end
	return PackedVector2Array([Vector2(a.x + c, a.y), Vector2(b.x - c, a.y), Vector2(b.x, a.y + c), Vector2(b.x, b.y - c),
		Vector2(b.x - c, b.y), Vector2(a.x + c, b.y), Vector2(a.x, b.y - c), Vector2(a.x, a.y + c)])


static func _diamond(ci: RID, at: Vector2, r: float, col: Color) -> void:
	RenderingServer.canvas_item_add_polygon(ci, PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, 0), at + Vector2(0, r), at + Vector2(-r, 0)]),
		PackedColorArray([col]))
