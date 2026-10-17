extends SceneTree
## QA-script (Kortschrift): muiscontrole van ALLE werktuigen + gids, tutorial en pauzemenu, met echte muisevents
## (Input.parse_input_event in venstercoördinaten; draai zonder --headless onder xvfb-run).
## Per werktuig: eerste level met dat werktuig → de tutorial opent (eerste keer) en wordt met de muis doorgebladerd en
## gesloten → elke klikzone van het werktuig: muis erboven = handcursor + hover_move() + zichtbare verandering →
## klikken geeft een zet (signaal request) → "?" opent de gids → pauzeknop → Uitleg & theorie / Naar levelkeuze /
## Naar speelhal aanwezig → Verder.
##
## Gebruik (vanuit de projectmap; save=qa raakt de echte opslag niet, de QA-save wordt eerst gewist):
##   xvfb-run -a -s "-screen 0 1920x1080x24" $G --path . --rendering-driver opengl3 --fixed-fps 30 \
##     --script res://games/scriptorium/tests/sc_mouse_qa.gd -- save=qa brief=0 [tools=bindery,drum] [shots=<map>]
## Uitvoer: regels "SCMOUSE ..." en een slotregel "SC_MOUSE_QA ok=<n> fail=<n>". Exitcode 1 bij een fout.

var fails := 0
var oks := 0
var shots := ""
var _requests := 0


func _init() -> void:
	var only := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		var s := str(a)
		if s.begins_with("tools="):
			only = s.substr(6).split(",")
		elif s.begins_with("shots="):
			shots = s.substr(6)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://scriptorium_qa.json"))
	await _frames(2)
	# eerste level per werktuig
	var first := {}
	for id in ScLevels.ids():
		var sp := ScLevels.get_spec(id)
		if sp == null or sp.stages.is_empty():
			continue
		var tl := str(sp.stages[0].get("tool", ""))
		if tl != "" and not first.has(tl):
			first[tl] = id
	for tl in ScGuide.TOOL_KEY.keys():
		if not only.is_empty() and not only.has(tl):
			continue
		_check(first.has(tl), "er is een level dat met %s begint" % tl)
		if first.has(tl):
			await _tool(str(tl), str(first[tl]))
	print("SC_MOUSE_QA ok=%d fail=%d" % [oks, fails])
	quit(1 if fails > 0 else 0)


# ---------------------------------------------------------------- per werktuig
func _tool(tl: String, id: String) -> void:
	ScSession.level_id = id
	change_scene_to_file(ScSession.SCENE_BENCH)
	await _wait(2.5)
	var wb = current_scene
	_check(wb != null and wb.scene_file_path == ScSession.SCENE_BENCH, "%s: werkbank geladen (%s)" % [tl, id])
	# tutorial (eerste keer dit werktuig)
	var g := _guide_open()
	_check(g != null, "%s: tutorial opent de eerste keer" % tl)
	if g != null:
		await _shot("%s_tutorial" % tl)
		var pages := 0
		while _find_button(g, "Volgende") != null and pages < 8:
			await click(_find_button(g, "Volgende").get_global_rect().get_center())
			await _wait(0.2)
			pages += 1
		var b := _find_button(g, "Aan de slag")
		_check(b != null, "%s: tutorial eindigt met 'Aan de slag!' (%d keer gebladerd)" % [tl, pages])
		if b != null:
			await click(b.get_global_rect().get_center())
		await _wait(0.6)
		_check(_guide_open() == null, "%s: tutorial sluit met een muisklik" % tl)
	await _wait(0.8)
	var v: ScView = wb.view
	_check(v != null and v.tool != null, "%s: werktuig zichtbaar" % tl)
	if v == null:
		return
	var tries := 0
	while wb.busy() and tries < 90:
		await _frames(1)
		tries += 1
	# hover op elke klikzone
	var zs: Array = v.zones.duplicate()
	var seen := {}
	var n_ok := 0
	var n_bad := 0
	for z in zs:
		var r: Rect2 = v.get_global_transform() * (z.r as Rect2)
		if (z.m as Dictionary).is_empty() or seen.has(str(z.m)):
			continue
		seen[str(z.m)] = true
		if seen.size() > 8:
			break
		var p := _free_point(v, z.r)
		_motion(Vector2(30, 1060))
		await _frames(3)
		var before := await _grab(r)
		_motion(p + Vector2(2, 0), Vector2(2, 0))
		await _frames(1)
		_motion(p, Vector2(-2, 0))
		await _frames(3)
		var after := await _grab(r)
		var hm := v.hover_move()
		var hand := Input.get_current_cursor_shape() == Input.CURSOR_POINTING_HAND
		var diff := _diff(before, after)
		if not hm.is_empty() and hand and diff > 0.002:
			n_ok += 1
		else:
			n_bad += 1
			print("SCMOUSE %s: zone %s op (%d,%d): hover=%s hand=%s verschil=%.4f" % [tl, str(z.m), int(p.x), int(p.y),
				str(not hm.is_empty()), str(hand), diff])
	print("SCMOUSE %s (%s): hover-feedback op %d/%d klikzones" % [tl, id, n_ok, n_ok + n_bad])
	_check(n_ok + n_bad > 0 or wb.ctx_row.get_child_count() > 0, "%s: het werktuig heeft klikzones of knoppen" % tl)
	_check(n_bad == 0, "%s: elke klikzone toont hover-feedback (handje + oplichten)" % tl)
	await _shot("%s_hover" % tl)
	# klikken: de eerste zones tot er een zet vertrekt (de binderij selecteert eerst)
	_requests = 0
	if not v.request.is_connected(_on_request):
		v.request.connect(_on_request)
	var log0: int = wb.director.log.size()
	var k := 0
	if zs.is_empty():
		# geen klikzones (bv. het leesraam vóór er iets in het venster staat): de knoppen van het werktuig
		for bt in wb.ctx_row.get_children():
			if bt is Button and not (bt as Button).disabled:
				_check((bt as Button).mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND, "%s: knop '%s' met handcursor" % [tl, (bt as Button).text])
				await click((bt as Button).get_global_rect().get_center())
				await _wait(0.4)
				k += 1
				break
		if wb.director.log.size() > log0:
			_requests += 1
	var clicked := {}
	while not zs.is_empty() and k < 4:
		# telkens de eerste nog niet aangeklikte zone van NU (binderij/duiventil: eerst kiezen, dan binden/plaatsen)
		var zz: Dictionary = {}
		for z in v.zones:
			if not (z.m as Dictionary).is_empty() and not clicked.has(str(z.m)):
				zz = z
				break
		if zz.is_empty():
			break
		clicked[str(zz.m)] = true
		await click(_free_point(v, zz.r))
		await _wait(0.4)
		k += 1
		if wb.director.log.size() > log0:
			_requests += 1
		if _requests > 0 or k >= 4:
			break
	if _requests == 0:
		var hc := root.gui_get_hovered_control()
		print("SCMOUSE %s: geen zet na %d klikken (overlay=%s paused=%s locked=%s busy=%s boom-pauze=%s onder de muis=%s)" % [tl, k,
			str(wb.get("_overlay_open")), str(wb.get("_paused")), str(v.locked), str(wb.busy()), str(paused),
			str(hc.get_path()) if hc else "-"])
	_check(_requests > 0, "%s: een klik op het werktuig geeft een zet" % tl)
	await _wait(0.8)
	while wb.busy() and tries < 300:
		await _frames(1)
		tries += 1
	if _guide_open() != null:
		await _close_guide()
	# "?" in de kopbalk → gids
	var qb := _find_tip(root, "Uitleg & theorie")
	_check(qb != null and qb.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND, "%s: knop ? met handcursor" % tl)
	if qb != null:
		await click(qb.get_global_rect().get_center())
		await _wait(0.6)
		_check(_guide_open() != null, "%s: klik op ? opent de gids" % tl)
		await _shot("%s_guide" % tl)
		await _close_guide()
	# pauzeknop → pauzemenu
	var pb := _find_tip(root, "Pauze")
	_check(pb != null, "%s: pauzeknop" % tl)
	if pb != null:
		await click(pb.get_global_rect().get_center())
		await _wait(0.6)
		var ok := _find_button(root, "Naar levelkeuze") != null and _find_button(root, "Naar speelhal") != null
		_check(ok, "%s: pauze heeft Naar levelkeuze + Naar speelhal" % tl)
		var ub := _find_button(root, "Uitleg & theorie")
		_check(ub != null, "%s: pauze heeft Uitleg & theorie" % tl)
		if ub != null:
			await click(ub.get_global_rect().get_center())
			await _wait(0.6)
			_check(_guide_open() != null, "%s: pauze → gids" % tl)
			await _close_guide()
		var vb := _find_button(root, "Verder")
		if vb != null:
			await click(vb.get_global_rect().get_center())
			await _wait(0.5)
		_check(_find_button(root, "Naar speelhal") == null, "%s: Verder sluit de pauze" % tl)


func _on_request(_m: Dictionary) -> void:
	_requests += 1


## Een punt in r dat niet onder een latere (bovenliggende) zone met een andere zet valt.
func _free_point(v: ScView, r: Rect2) -> Vector2:
	var c := r.get_center()
	for f in [Vector2(0.5, 0.5), Vector2(0.3, 0.5), Vector2(0.7, 0.5), Vector2(0.5, 0.3), Vector2(0.5, 0.7), Vector2(0.2, 0.2)]:
		var p: Vector2 = r.position + r.size * f
		var top: Rect2 = Rect2()
		for z in v.zones:
			if (z.r as Rect2).has_point(p):
				top = z.r
		if top == r:
			return v.get_global_transform() * p
	return v.get_global_transform() * c


# ---------------------------------------------------------------- gids
func _find_guide(n: Node) -> HubGuide:
	if n is HubGuide and not (n as HubGuide)._closing:
		return n
	for c in n.get_children():
		var r := _find_guide(c)
		if r != null:
			return r
	return null


func _guide_open() -> HubGuide:
	return _find_guide(root)


func _close_guide() -> void:
	var g := _guide_open()
	if g == null:
		return
	await _wait(0.3)
	var b := _find_button(g, "Aan de slag")
	if b == null:
		b = _find_button(g, "Sluiten")
	if b != null:
		await click(b.get_global_rect().get_center())
	await _wait(0.5)
	_check(_guide_open() == null, "gids sluit met een muisklik")


# ---------------------------------------------------------------- hulpjes
func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _wait(sec: float) -> void:
	await _frames(maxi(1, int(sec * 30.0)))


func _win(p: Vector2) -> Vector2:
	return root.get_final_transform() * p


func _send(ev: InputEvent) -> void:
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _motion(p: Vector2, rel := Vector2.ZERO) -> void:
	var m := InputEventMouseMotion.new()
	m.position = _win(p)
	m.global_position = m.position
	m.relative = rel
	_send(m)


func _button(p: Vector2, pressed: bool) -> void:
	var b := InputEventMouseButton.new()
	b.position = _win(p)
	b.global_position = b.position
	b.button_index = MOUSE_BUTTON_LEFT
	b.pressed = pressed
	b.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	_send(b)


func click(p: Vector2) -> void:
	_motion(p + Vector2(3, 0), Vector2(3, 0))
	await _frames(1)
	_motion(p, Vector2(-3, 0))
	await _frames(2)
	_button(p, true)
	await _frames(2)
	_button(p, false)
	await _frames(2)


func _grab(r: Rect2) -> Image:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var k := Vector2(img.get_width(), img.get_height()) / Vector2(1920, 1080)
	var rr := Rect2i(Rect2(r.position * k, r.size * k)).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if rr.size.x <= 0 or rr.size.y <= 0:
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	return img.get_region(rr)


## Gemiddeld kleurverschil per pixel (0..1).
func _diff(a: Image, b: Image) -> float:
	if a.get_size() != b.get_size():
		return 1.0
	var s := 0.0
	var n := 0
	for y in range(0, a.get_height(), 2):
		for x in range(0, a.get_width(), 2):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			s += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
			n += 1
	return s / maxf(1.0, n * 3.0)


func _find_button(n: Node, text: String) -> Button:
	if n is Button and (n as Button).is_visible_in_tree() and (n as Button).text.contains(text):
		return n
	for c in n.get_children():
		var r := _find_button(c, text)
		if r != null:
			return r
	return null


func _find_tip(n: Node, tip: String) -> Control:
	if n is BaseButton and (n as Control).is_visible_in_tree() and (n as Control).tooltip_text.begins_with(tip):
		return n
	for c in n.get_children():
		var r := _find_tip(c, tip)
		if r != null:
			return r
	return null


func _shot(name: String) -> void:
	if shots == "":
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img != null:
		img.save_png(shots.path_join(name + ".png"))


func _check(cond: bool, msg: String) -> void:
	if cond:
		oks += 1
	else:
		fails += 1
		print("SCMOUSE FAIL " + msg)
