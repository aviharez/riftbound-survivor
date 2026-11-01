class_name PixelStyle
extends StyleBox
## Pixel-art UI frame (Syifa's reference: Overgeared Hero): hard 1 px black outline, a coloured border with a
## lighter top / darker bottom bevel, notched corners and a dark fill with a faint diagonal stripe pattern.
## All edges are snapped to whole virtual pixels, so with the 2x canvas stretch every line is a crisp block.

var fill := Color("221a40")
var fill_dark := Color("1a1433")    # stripe colour of the pattern
var border := Color("6a52c9")
var light := Color("8f7ae6")        # top / left bevel
var shade := Color("3b2c7a")        # bottom / right bevel
var outline := Color("05030c")
var border_w := 2
var pattern := true
var glow := Color(0, 0, 0, 0)       # selected: an extra bright 1 px ring outside
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
		RenderingServer.canvas_item_add_texture_rect_region(ci, inner, tex.get_rid(), Rect2(Vector2.ZERO, inner.size), fill_dark)


## A rectangle with its four corner pixels cut off.
static func _notched(ci: RID, r: Rect2, col: Color) -> void:
	RenderingServer.canvas_item_add_rect(ci, Rect2(r.position + Vector2(1, 0), Vector2(r.size.x - 2, r.size.y)), col)
	RenderingServer.canvas_item_add_rect(ci, Rect2(r.position + Vector2(0, 1), Vector2(1, r.size.y - 2)), col)
	RenderingServer.canvas_item_add_rect(ci, Rect2(r.position + Vector2(r.size.x - 1, 1), Vector2(1, r.size.y - 2)), col)


## White diagonal stripes (1 px every 4 px) on transparent, tinted by fill_dark when drawn.
static func _stripe_tex() -> ImageTexture:
	if _stripes == null:
		var img := Image.create(720, 420, false, Image.FORMAT_RGBA8)
		for y in img.get_height():
			for x in range((4 - y % 4) % 4, img.get_width(), 4):
				img.set_pixel(x, y, Color.WHITE)
		_stripes = ImageTexture.create_from_image(img)
	return _stripes
