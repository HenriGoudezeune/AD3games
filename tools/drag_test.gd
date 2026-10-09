extends SceneTree
## Front-end-test (QA P0-2): slordige menselijke sleepbewegingen. Pakt elk pakje 40 px onder het midden vast,
## sleept in 0,6 s naar het juiste luik (gemikt op de cursor), en controleert dat het oplichtende luik == het luik
## waarin het pakje valt. Gebruik: "$G" --headless --path . --fixed-fps 30 --script res://tools/drag_test.gd -- --day=5
var depot
var mism := 0
var drops := 0
var last_hover := -1

func _init() -> void:
	var day := 5
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--day="):
			day = int(a.split("=")[1])
	await process_frame
	root.get_node("Game").current_day = day
	depot = load("res://scenes/depot.tscn").instantiate()
	root.add_child(depot)
	await _wait(3.0)
	var t0 := Time.get_ticks_msec()
	while not depot.finished and not depot._ending and drops < 14:
		await process_frame
		var m: ExtHashModel = depot.model
		if depot._lock or depot._running:
			_auto_structural()
			continue
		if not m.blocked.is_empty() or not m.splitting.is_empty():
			_auto_structural()
			await _wait(0.5)
			continue
		var fv = depot._front_view()
		if fv == null or fv.has_meta("anim"):
			continue
		var target: int = m.index_of(fv.hv)
		var start: Vector2 = fv.position + Vector2(0, 40)
		depot.mouse_override = start
		depot._on_press(start)
		if depot.drag_view == null:
			continue
		var end: Vector2 = depot.hatches[target].position + Vector2(10, 12)
		for i in 18:
			depot.mouse_override = start.lerp(end, (i + 1) / 18.0)
			await process_frame
		await process_frame
		last_hover = depot.hover_hatch
		var placed := [-1]
		var cb := func(_p, _b, idx, _v): placed[0] = idx
		var cb2 := func(_p, _b, idx): placed[0] = idx
		m.parcel_placed.connect(cb)
		m.parcel_blocked.connect(cb2)
		depot._on_release(depot.mouse_override)
		m.parcel_placed.disconnect(cb)
		m.parcel_blocked.disconnect(cb2)
		depot.mouse_override = null
		drops += 1
		var ok: bool = placed[0] == last_hover
		if not ok:
			mism += 1
		print("drop %d: hover %d, landt in %d, juist %d %s" % [drops, last_hover, placed[0], target, "OK" if ok else "!! MISMATCH"])
		await _wait(0.8)
		if Time.get_ticks_msec() - t0 > 240000:
			break
	print("DRAG_TEST drops=%d mismatches=%d lost=%d" % [drops, mism, depot.model.lost.size()])
	quit(1 if mism > 0 else 0)

func _auto_structural() -> void:
	var m: ExtHashModel = depot.model
	if depot._lock or depot._running:
		return
	var cm := m.correct_move()
	match cm.get("action", ""):
		"double", "fail":
			depot._pull_lever()
		"split":
			depot._try_split(int(cm.bucket_id))
		"assign":
			if depot.table.visible and depot.table.front() and not depot.table.front().has_meta("anim"):
				depot._do_assign(int(cm.parcel_id), int(cm.side))
		"retry":
			m.retry_blocked()

func _wait(s: float) -> void:
	var t := 0.0
	while t < s:
		await process_frame
		t += 1.0 / 30.0
