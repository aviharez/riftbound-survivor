extends SceneTree
func _init() -> void:
	var gen := MapGenerator.new()
	var total_ms := 0
	var rerolls := 0
	var walls_sum := 0.0
	var fails := 0
	var min_portal := 9999.0
	for s in range(1, 41):
		var t0 := Time.get_ticks_msec()
		var m := gen.generate(s * 7919)
		total_ms += Time.get_ticks_msec() - t0
		if m.is_empty():
			fails += 1
			continue
		rerolls += int(m["rerolls"])
		var g: PackedByteArray = m["grid"]
		var walls := 0
		for v in g:
			if v == GameData.T_WALL: walls += 1
		walls_sum += float(walls) / g.size()
		min_portal = min(min_portal, Vector2(m["spawn"]).distance_to(Vector2(m["portal"])))
		assert(m["chests"].size() == GameData.CHEST_COUNT)
		assert(m["shrines"].size() == GameData.SHRINE_COUNT)
	var a := gen.generate(12345)
	var b := gen.generate(12345)
	print("deterministic=", a["grid"] == b["grid"] and a["portal"] == b["portal"] and a["chests"] == b["chests"])
	print("fails=", fails, " avg_ms=", total_ms / 40.0, " total_rerolls=", rerolls, " avg_wall_ratio=", walls_sum / (40 - fails), " min_portal_dist=", min_portal)
	print("pots=", a["pots"].size(), " shrines=", a["shrines"])
	quit()
