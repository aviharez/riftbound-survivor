class_name GlassStyle
extends StyleBox
## The menu look (Syifa's direction, mobile hero-game style): a rounded, slightly translucent gradient panel
## with a thin light rim, a bright top highlight, an optional soft glow (selected) and an optional slant
## (parallelogram call-to-action buttons). Drawn in code for every panel and button through UiKit.

var fill_top := Color(0.11, 0.18, 0.36, 0.86)
var fill_bottom := Color(0.04, 0.07, 0.17, 0.9)
var rim := Color(0.55, 0.75, 1.0, 0.35)
var highlight := Color(1, 1, 1, 0.16)
var glow := Color(0, 0, 0, 0)
var radius := 6.0
var slant := 0.0          # horizontal offset of the top edge (right) vs the bottom edge (left)
var shadow := Color(0, 0, 0, 0.35)


func _draw(ci: RID, rect: Rect2) -> void:
	var pts := _shape(rect, radius, slant)
	if shadow.a > 0.0:
		var sp := _shape(Rect2(rect.position + Vector2(0, 2), rect.size), radius, slant)
		RenderingServer.canvas_item_add_polygon(ci, sp, PackedColorArray([shadow]))
	if glow.a > 0.0:
		for i in 3:
			var g := _shape(rect.grow(1.5 + i * 1.5), radius + 1.5 + i * 1.5, slant)
			g.append(g[0])
			RenderingServer.canvas_item_add_polyline(ci, g, PackedColorArray([Color(glow, glow.a * (0.6 - i * 0.18))]), 1.5, true)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(fill_top.lerp(fill_bottom, clampf((p.y - rect.position.y) / maxf(1.0, rect.size.y), 0.0, 1.0)))
	RenderingServer.canvas_item_add_polygon(ci, pts, cols)
	# glossy top band
	if highlight.a > 0.0 and rect.size.y > 10:
		var band := _shape(Rect2(rect.position + Vector2(1.5, 1.5), Vector2(rect.size.x - 3, rect.size.y * 0.42)), maxf(0.0, radius - 1.5), slant * 0.42)
		var bc := PackedColorArray()
		for p in band:
			var k := clampf((p.y - rect.position.y) / maxf(1.0, rect.size.y * 0.42), 0.0, 1.0)
			bc.append(Color(highlight, highlight.a * (1.0 - k) * 0.6))
		RenderingServer.canvas_item_add_polygon(ci, band, bc)
	if rim.a > 0.0:
		var o := pts.duplicate()
		o.append(pts[0])
		RenderingServer.canvas_item_add_polyline(ci, o, PackedColorArray([rim]), 1.0, true)


## Rounded rectangle (optionally sheared into a parallelogram) as a polygon.
static func _shape(r: Rect2, rad: float, sl: float) -> PackedVector2Array:
	rad = minf(rad, minf(r.size.x, r.size.y) * 0.5)
	var pts := PackedVector2Array()
	var corners := [[Vector2(r.end.x - rad, r.position.y + rad), -PI / 2], [Vector2(r.end.x - rad, r.end.y - rad), 0.0],
		[Vector2(r.position.x + rad, r.end.y - rad), PI / 2], [Vector2(r.position.x + rad, r.position.y + rad), PI]]
	for c in corners:
		for i in 4:
			var a: float = c[1] + i * (PI / 2) / 3.0
			var p: Vector2 = c[0] + Vector2.from_angle(a) * rad
			# shear: points near the top move right, near the bottom move left
			var k := 1.0 - (p.y - r.position.y) / maxf(1.0, r.size.y)
			p.x += sl * (k - 0.5)
			pts.append(p)
	return pts
