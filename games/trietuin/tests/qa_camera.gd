extends SceneTree
## QA camera: scrollen zoomt rond de muis (het wereldpunt onder de muis blijft staan) en een lege plek met de linker-
## muisknop vastpakken en slepen verschuift de tuin zonder zet. Echte renderer nodig:
##   xvfb-run -a -s "-screen 0 1920x1080x24" $G --path . --rendering-driver opengl3 --audio-driver Dummy \
##     --resolution 1920x1080 --script res://games/trietuin/tests/qa_camera.gd -- level=2-3 intro=0
## Uitvoer: "CAMERA_RESULT ok=… fout=…".

var g: Node
var fails := 0
var oks := 0


func _check(cond: bool, what: String) -> void:
	if cond:
		oks += 1
	else:
		fails += 1
	print("CAMERA %s %s" % ["ok" if cond else "FOUT", what])


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _init() -> void:
	await process_frame
	g = load("res://games/trietuin/scenes/garden.tscn").instantiate()
	root.add_child(g)
	var t0 := Time.get_ticks_msec()
	while str(g.state) != "play" and Time.get_ticks_msec() - t0 < 20000:
		await process_frame
	await _frames(60)
	# 1. zoomen (in, of uit als de camera al dicht staat) rond een punt linksboven: het wereldpunt onder de muis blijft (na het uitdempen) op zijn plaats
	var m := Vector2(500, 380)
	var before: Vector2 = g._screen_to_world(m)
	var z0: float = g.cam.zoom.x
	for i in 3:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_WHEEL_UP if z0 < 1.0 else MOUSE_BUTTON_WHEEL_DOWN
		ev.pressed = true
		ev.position = m
		ev.global_position = m
		g._unhandled_input(ev)
	await _frames(120)
	var after: Vector2 = g._screen_to_world(m)
	_check(absf(g.cam.zoom.x - z0) > z0 * 0.2, "zoom (%.2f → %.2f)" % [z0, g.cam.zoom.x])
	_check(before.distance_to(after) < 3.0, "punt onder de muis blijft staan (%.1f px)" % before.distance_to(after))
	# 2. lege plek vastpakken (linkermuisknop) en slepen: camera schuift, geen zet
	var empty := Vector2(-1, -1)
	for y in range(140, 1000, 40):
		for x in range(200, 1700, 40):
			if g.view.pick(g._screen_to_world(Vector2(x, y))).is_empty():
				empty = Vector2(x, y)
				break
		if empty.x >= 0:
			break
	_check(empty.x >= 0, "lege plek gevonden %s" % empty)
	var moves0: int = g.model.log.entries.size() if "log" in g.model else -1
	var wp0: Vector2 = g._screen_to_world(empty)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = empty
	g._unhandled_input(press)
	for i in 10:
		var mm := InputEventMouseMotion.new()
		mm.relative = Vector2(15, 8)
		mm.position = empty + mm.relative * (i + 1)
		g._unhandled_input(mm)
	var rel := InputEventMouseButton.new()
	rel.button_index = MOUSE_BUTTON_LEFT
	rel.pressed = false
	rel.position = empty + Vector2(150, 80)
	g._unhandled_input(rel)
	await _frames(120)
	var wp1: Vector2 = g._screen_to_world(empty + Vector2(150, 80))
	_check(wp0.distance_to(wp1) < 3.0, "gesleept punt volgt de muis (%.1f px)" % wp0.distance_to(wp1))
	_check(not g._drag, "slepen stopt bij loslaten")
	if moves0 >= 0:
		var added := []   # tijdgebeurtenissen (kaart verloopt, nieuwe kaart) tellen niet als zet
		for e in g.model.log.entries.slice(moves0):
			if not str(e.get("type", "")) in ["EXPIRE", "CARD_END", "CARD_START"]:
				added.append(str(e.get("type", "?")))
		_check(added.is_empty(), "geen zet gespeeld door slepen %s" % [added])
	print("CAMERA_RESULT ok=%d fout=%d" % [oks, fails])
	quit(1 if fails > 0 else 0)

