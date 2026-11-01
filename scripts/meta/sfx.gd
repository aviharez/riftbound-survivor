class_name Sfx
extends RefCounted
## Static front for the "Sound" autoload (scripts/meta/sound.gd), so scripts also parse and run where the
## autoload does not exist (SceneTree test scripts, --check-only): then every call simply does nothing.

static func _node() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("Sound") if tree != null else null


static func play(name: String, pitch_jitter := 0.06, extra_db := 0.0) -> void:
	var n := _node()
	if n != null:
		n.play(name, pitch_jitter, extra_db)


static func music(name: String) -> void:
	var n := _node()
	if n != null:
		n.music(name)


static func music_on() -> bool:
	var n := _node()
	return n != null and n.music_on


static func sfx_on() -> bool:
	var n := _node()
	return n != null and n.sfx_on


static func set_music_on(on: bool) -> void:
	var n := _node()
	if n != null:
		n.set_music_on(on)


static func set_sfx_on(on: bool) -> void:
	var n := _node()
	if n != null:
		n.set_sfx_on(on)
