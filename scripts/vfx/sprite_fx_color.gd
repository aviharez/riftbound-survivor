class_name SpriteFxColor
extends Node2D
## Draws the colour layer of Vfx sprite effects with normal blending, under the
## additive light layer that Vfx draws on top.

var game: Node


func _draw() -> void:
	if game != null and game.vfx != null:
		game.vfx.draw_sprite_layer(self, "color")
