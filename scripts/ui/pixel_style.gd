class_name PixelStyle
extends StyleBox
## Pixel-art UI frame (Syifa's reference: Overgeared Hero): hard 1 px black outline, a coloured border with a
## lighter top / darker bottom bevel, notched corners and a fill with wide diagonal stripes; optional gold
## rivets in the corners (main panels). All edges are snapped to whole virtual pixels, so with the integer
## canvas stretch every line is a crisp block.

var fill := Color("34286e")
var fill_dark := Color("3c2f7e")    # stripe colour of the pattern (lighter or darker than fill)
var border := Color("7b63d9")
var light := Color("b4a2ff")        # top bevel
var shade := Color("2a1f60")        # bottom bevel
var outline := Color("05030c")
var border_w := 2
var pattern := true
var rivets := false                 # gold corner studs (overlays, main page panels)
var glow := Color(0, 0, 0, 0)       # selected: an extra bright ring outside
var drop := 2                       # flat drop shadow under buttons

static var _stripes: ImageTexture


func _draw(ci: RID, rect: Rect2) -> void:
	var r := Rect2(rect.position.floor(), rect.size.floor())
	if r.size.x < 4 or r.size.y < 4:
		return
	if drop > 0:
		_notched(ci, Rect2(r.position + Vector2(0, drop), r.size), Color(0, 0, 0, 0.45))
	if glow.a > 0.0:
		_notched(ci, r.grow(2), glow)
	_notched(ci, r, outline)
	var b := r.grow(-1)
	_notched(ci, b, border)
	# bevel: light on the top edge, shade on the bottom edge of the border
	RenderingServer.canvas_item_add_rect(ci, Rect2(b.position + Vector2(1, 0), Vector2(b.size.x - 2, 1)), light)
	RenderingServer.canvas_item_add_rect(ci, Rect2(b.position + Vector2(1, b.size.y - 1), Vector2(b.size.x - 2, 1)), shade)
	var f := b.grow(-border_w)
	RenderingServer.canvas_item_add_rect(ci, f, outline)
	var inner := f.grow(-1)
	RenderingServer.canvas_item_add_rect(ci, inner, fill)
	if pattern and inner.size.x > 8 and inner.size.y > 8:
		var tex := _stripe_tex()
		RenderingServer.canvas_item_add_texture_rect_region(ci, inner, tex.get_rid(), Rect2(Vector2(fposmod(inner.position.x, 8.0), fposmod(inner.position.y, 8.0)), inner.size), fill_dark)
	# inner highlight line under the top edge
	RenderingServer.canvas_item_add_rect(ci, Rect2(inner.position, Vector2(inner.size.x, 1)), Color(1, 1, 1, 0.08))
	if rivets and r.size.x > 40 and r.size.y > 30:
		for c in [b.position + Vector2(3, 3), Vector2(b.end.x - 6, b.position.y + 3), Vector2(b.position.x + 3, b.end.y - 6), b.end - Vector2(6, 6)]:
			RenderingServer.canvas_item_add_rect(ci, Rect2(c, Vector2(3, 3)), outline)
			RenderingServer.canvas_item_add_rect(ci, Rect2(c, Vector2(2, 2)), Color("ffd062"))
			RenderingServer.canvas_item_add_rect(ci, Rect2(c, Vector2(1, 1)), Color("fff3c2"))


## A rectangle with its four corner pixels cut off.
static func _notched(ci: RID, r: Rect2, col: Color) -> void:
	RenderingServer.canvas_item_add_rect(ci, Rect2(r.position + Vector2(1, 0), Vector2(r.size.x - 2, r.size.y)), col)
	RenderingServer.canvas_item_add_rect(ci, Rect2(r.position + Vector2(0, 1), Vector2(1, r.size.y - 2)), col)
	RenderingServer.canvas_item_add_rect(ci, Rect2(r.position + Vector2(r.size.x - 1, 1), Vector2(1, r.size.y - 2)), col)


## White diagonal bands (4 px wide every 8 px) on transparent, tinted by fill_dark when drawn. Sampled in
## screen-aligned coordinates (region starts at the rect's position mod 8) so neighbouring panels' stripes line up.
static func _stripe_tex() -> ImageTexture:
	if _stripes == null:
		var img := Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
		for y in img.get_height():
			for x in img.get_width():
				if (x + y) % 8 < 4:
					img.set_pixel(x, y, Color.WHITE)
		_stripes = ImageTexture.create_from_image(img)
	return _stripes
