class_name Ads
extends RefCounted
## Rewarded ads (design doc section 8: optional, never forced, daily cap in SaveData). There is no ad SDK yet:
## `show_rewarded` plays a short stand-in screen and then grants the reward, so every ad hook can be tested.
## When an ad SDK plugin (e.g. AdMob) is added, replace the body of `show_rewarded` with the plugin call and
## call `on_reward` only from its "user earned reward" callback.

## Placements: "build_speedup", "expedition_speedup", "revive", "double_rewards".
static func show_rewarded(parent: Node, placement: String, on_reward: Callable) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.get_tree().root.add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.02, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var p := UiKit.panel(12.0)
	center.add_child(p[0])
	var box: VBoxContainer = p[1]
	var t := UiKit.title("AD", 24, UiKit.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var l := UiKit.label("Ad placeholder (%s)\nNo ad SDK in this build." % placement, 10, UiKit.IVORY)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l)
	var tree := parent.get_tree()
	tree.create_timer(GameData.AD_PLACEHOLDER_SEC, true).timeout.connect(func():
		layer.queue_free()
		on_reward.call())
