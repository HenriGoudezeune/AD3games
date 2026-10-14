class_name TtReport
extends Control
## Terugblik (GDD §6.5): sterren groeien als bloemen, honing telt op (uitsplitsing), sapbalk (gebruikt /
## optimum / budget + geestvergelijking), Bloeirij, misstappen-tijdlijn met herbeleving (de tuin van dat moment
## in een tweede, alleen-lezen model; jouw zet rood, de juiste zet groen + coachzin + notasverwijzing),
## oorzaakketens, Notas-weergave en Volgende / Opnieuw / Kaart.

var garden: Node
var rep: Dictionary = {}
var spec: TtLevelSpec
var level_id := ""
var t := 0.0
var _star_a := [0.0, 0.0, 0.0]
var _honey_shown := 0.0
var _rows_a := 0.0
var _sap_a := 0.0
var _bloom_a := 0.0
var _events: Array = []        # [{entry, mistake:bool, x}]
var _sel := -1
var _replay: TtReplayView
var _notes: TtNotesView
var _notes_on := false
var _coach := ""
var _ref := ""
var _yours := ""
var _right := ""
var _btns: HBoxContainer
var _notes_btn: Button
var _intro_a := 0.0
var _causes: Array = []

const TL := Rect2(980, 120, 880, 150)
const RP := Rect2(980, 300, 880, 520)


func setup(g: Node, report: Dictionary, s: TtLevelSpec, id: String) -> void:
	garden = g
	rep = report
	spec = s
	level_id = id


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = TtUi.theme()
	_collect_events()
	_replay = TtReplayView.new()
	_replay.position = RP.position
	_replay.size = RP.size
	_replay.visible = false
	add_child(_replay)
	_notes = TtNotesView.new()
	_notes.rect = Rect2(RP.position, RP.size)
	_notes.visible = false
	add_child(_notes)
	_btns = HBoxContainer.new()
	_btns.add_theme_constant_override("separation", 18)
	_btns.position = Vector2(60, 960)
	add_child(_btns)
	var stars: Array = rep.get("stars", [false, false, false])
	var has_next: bool = level_id != "endless" and stars[0]
	if has_next:
		_btn("Volgende", TtUi.Kind.PRIMARY, func(): garden.goto_next(), 260)
	_btn("Opnieuw", TtUi.Kind.SECONDARY, func(): garden.restart(), 220)
	_btn("Kaart", TtUi.Kind.GHOST, func(): garden.goto_map(), 180)
	_notes_btn = TtUi.button("Notas-weergave", TtUi.Kind.SAP, 24, 260)
	_notes_btn.position = Vector2(1600, 34)
	_notes_btn.pressed.connect(_toggle_notes)
	add_child(_notes_btn)
	_animate_in()
	if level_id == "endless":
		_highscore_ui()
	var nm := 0
	for e in _events:
		if e.mistake:
			nm += 1
	var beds: bool = garden.model.has_method("bed_model")
	_notes_btn.visible = not beds
	if beds:
		pass
	elif level_id == "2-4" or TtSession.has("notes") or nm == 0:
		_toggle_notes()
	else:
		for i in _events.size():
			if _events[i].mistake:
				get_tree().create_timer(2.6).timeout.connect(_select.bind(i))
				break



func _highscore_ui() -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	h.position = Vector2(60, 880)
	add_child(h)
	var l := TtUi.label("Jouw naam (3 letters):", 24)
	h.add_child(l)
	var e := LineEdit.new()
	e.max_length = 3
	e.custom_minimum_size = Vector2(110, 52)
	e.add_theme_font_override("font", TtPal.MONO)
	e.add_theme_font_size_override("font_size", 30)
	e.text = "TUI"
	h.add_child(e)
	var b := TtUi.button("Bewaar", TtUi.Kind.SAP, 24, 150)
	h.add_child(b)
	b.pressed.connect(func():
		var d := Time.get_date_dict_from_system()
		var rank := TtSave.add_highscore(int(rep.get("honey", 0)), e.text.to_upper().substr(0, 3), "%02d/%02d/%d" % [d.day, d.month, d.year])
		h.queue_free()
		var msg := TtUi.label("Plaats %d in de top 10!" % rank if rank > 0 else "Net niet in de top 10.", 26, TtPal.STAR, TtPal.UI_BOLD)
		msg.position = Vector2(60, 880)
		add_child(msg)
		TtSnd.play("star_3" if rank > 0 else "bee_hmm", -4.0))


func _btn(txt: String, kind: int, cb: Callable, w: float) -> void:
	var b := TtUi.button(txt, kind, 30, w)
	b.pressed.connect(cb)
	_btns.add_child(b)
	b.modulate.a = 0.0
	b.create_tween().tween_property(b, "modulate:a", 1.0, 0.3).set_delay(2.2 + _btns.get_child_count() * 0.08)


func _collect_events() -> void:
	var log: TtEventLog = garden.model.log
	var skip := ["CARD_START", "CARD_END", "HINT", "REWIND", "BLOOM", "LEVEL_END", "ITERATION"]
	var list := []
	for e in log.entries:
		if skip.has(str(e.get("type", ""))):
			continue
		var v := int(e.get("verdict", 0))
		var mist: bool = v != TtCodes.Verdict.OK and (v != TtCodes.Verdict.BUMP or spec.count_bumps)
		list.append({"entry": e, "mistake": mist, "bump": v == TtCodes.Verdict.BUMP})
	_events = list
	var n := maxi(1, _events.size())
	for i in _events.size():
		_events[i].x = TL.position.x + 40 + (TL.size.x - 80) * (float(i) / maxf(n - 1, 1))
	for b in rep.get("bloom", []):
		if not bool(b.get("ok", true)):
			var cs := int(b.get("cause_seq", -1))
			_causes.append({"word": str(b.get("word", "")), "seq": cs})


func _animate_in() -> void:
	var tw := create_tween()
	tw.tween_property(self, "_intro_a", 1.0, 0.3)
	var stars: Array = rep.get("stars", [false, false, false])
	for i in 3:
		var ii := i
		tw.tween_callback(func():
			if stars[ii]:
				TtSnd.play("star_%d" % (ii + 1), -2.0)
				TtFx.burst(self, _star_pos(ii), "petal", 10, 1.0, 120, 260, Color.WHITE, 400, 0.3, 0.6, false, Vector2.UP, 120, [TtPal.STAR, TtPal.BLUSH, Color.WHITE])
			else:
				TtSnd.play("bud_plop", -10.0, 0.8))
		tw.tween_method(func(v: float): _star_a[ii] = v, 0.0, 1.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "_rows_a", 1.0, 0.3)
	tw.tween_method(func(v: float): _honey_shown = v, 0.0, float(rep.get("honey", 0)), 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): TtSnd.play("honey", -4.0))
	tw.tween_property(self, "_sap_a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "_bloom_a", 1.0, 0.4)


static func wrap_text(s: String, font: Font, size: int, maxw: float) -> Array:
	var out := []
	var cur := ""
	for w in s.split(" "):
		var tryl := w if cur == "" else cur + " " + w
		if font.get_string_size(tryl, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > maxw and cur != "":
			out.append(cur)
			cur = w
		else:
			cur = tryl
	if cur != "":
		out.append(cur)
	return out


func _star_pos(i: int) -> Vector2:
	return Vector2(200 + i * 230, 210)


func _toggle_notes() -> void:
	_notes_on = not _notes_on
	if _notes_on:
		_sel = -1
		_replay.visible = false
		_notes.visible = true
		_notes.setup(garden.model.render_nodes(), garden.kind, garden.letters, spec.pos_base, garden._full_text(),
			"Jouw eindboom, getekend zoals in de notas")
		_notes_btn.text = "Tuinweergave"
	else:
		_notes.visible = false
		_notes_btn.text = "Notas-weergave"
	TtSnd.play("ribbon_roll", -6.0)


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = ev.position
		for i in _events.size():
			if Vector2(_events[i].x, TL.position.y + 90).distance_to(p) < 16:
				_select(i)
				return


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k := (ev as InputEventKey).keycode
		if k == KEY_RIGHT or k == KEY_LEFT:
			var dir := 1 if k == KEY_RIGHT else -1
			var i := _sel
			for _n in _events.size():
				i = (i + dir + _events.size()) % _events.size()
				if _events[i].mistake:
					_select(i)
					break
			get_viewport().set_input_as_handled()
		elif k == KEY_ENTER or k == KEY_KP_ENTER:
			var st: Array = rep.get("stars", [false])
			if st[0] and level_id != "endless":
				garden.goto_next()
			else:
				garden.restart()
		elif k == KEY_ESCAPE:
			garden.goto_map()


func _select(i: int) -> void:
	_sel = i
	_notes_on = false
	_notes.visible = false
	_notes_btn.text = "Notas-weergave"
	var e: Dictionary = _events[i].entry
	var log: TtEventLog = garden.model.log
	_coach = log.coach_line(e) if _events[i].mistake else ""
	_ref = log.notes_ref(e) if _events[i].mistake else ""
	var played: Dictionary = e.get("data", {}).get("move", e.get("data", {}))
	_yours = _describe(played)
	_right = _describe(e.get("hint", {}))
	TtSnd.play("ui_whoosh", -8.0, 1.3)
	var before: Dictionary = e.get("before", {})
	if before.is_empty():
		# geen snapshot bij OK-zetten midden in een kaart: zoek de laatste ervoor
		for k in range(i, -1, -1):
			var b2: Dictionary = _events[k].entry.get("before", {})
			if not b2.is_empty():
				before = b2
				break
	_replay.visible = true
	_replay.show_moment(spec, garden.kind, garden.letters, garden.art_season, before, played, e.get("hint", {}), _events[i].mistake)


func _describe(mv: Dictionary) -> String:
	var a := str(mv.get("act", mv.get("type", "")))
	match a:
		"move":
			return "knop %s" % str(mv.get("letter", "?"))
		"split":
			return "j = %d" % int(mv.get("j", -1))
		"same":
			return "Zit er al"
		"answer":
			return "Pluk" if bool(mv.get("found", false)) else "Niet hier"
		"cut":
			return "knip tak"
		"read":
			return "lees positie %d" % int(mv.get("pos", -1))
		"short":
			return "te kort"
		"pick_leaf":
			return "vrucht kiezen"
		"prune":
			return "snoei top"
		"prune_done":
			return "klaar met snoeien"
		"go":
			return {"lo": "kleiner", "eq": "gelijk", "hi": "groter"}.get(str(mv.get("dir", "")), "?")
		"place":
			return "plant %s" % str(mv.get("letter", "?"))
		"attach":
			return "aanhechten"
		"label":
			return "b = %d" % (int(mv.get("b", 0)) + spec.pos_base)
		"locate":
			return "loep zetten"
		"absent":
			return "komt niet voor"
		"where":
			return "positie %d" % (int(mv.get("pos", 0)) + spec.pos_base)
		"count":
			return "%d keer" % int(mv.get("n", 0))
		"pick":
			return "%d vruchten" % (mv.get("leaves", []) as Array).size()
		"owner":
			return "eigenaars %s" % str(mv.get("texts", []))
		"rule":
			return "Groei!" if bool(mv.get("grow", false)) else "Zit er al"
		"hop":
			return "spring"
		"link":
			return "link vasthechten"
		"follow":
			return "volg link" if str(mv.get("mode", "")) == "link" else "x − 1"
	return a


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color(0.05, 0.09, 0.07, 0.93 * _intro_a))
	var se := TtPal.season(garden.art_season)
	var title := "%s %s · %s" % [TtSession.season_name(garden.season).to_upper(), level_id, spec.title] if level_id != "endless" else "VRIJE TUIN"
	TtPal.text_l(self, TtPal.UI_BOLD, Vector2(60, 70), title, 46, TtPal.TEXT)
	TtPal.text_l(self, TtPal.UI, Vector2(62, 112), spec.notes_ref, 22, TtPal.TEXT_DIM)
	# sterren
	var stars: Array = rep.get("stars", [false, false, false])
	var labels: Array = rep.get("star_labels", ["", "", ""])
	for i in 3:
		var a: float = _star_a[i]
		var c := _star_pos(i)
		draw_set_transform(c, sin(t * 1.5 + i) * 0.04 if stars[i] else 0.0, Vector2(a, a))
		if stars[i]:
			for k in 5:
				var ang := k * TAU / 5 + t * 0.2
				draw_circle(Vector2(cos(ang), sin(ang)) * 46, 26, Color(TtPal.BLUSH, 0.5), true, -1, true)
		TtDraw.star_slot(self, Vector2.ZERO, 58, stars[i])
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var lines := wrap_text(str(labels[i] if i < labels.size() else ""), TtPal.UI_BOLD, 19, 210.0)
		for li in lines.size():
			TtPal.text_c(self, TtPal.UI_BOLD, c + Vector2(0, 86 + li * 24), lines[li], 19, TtPal.TEXT if stars[i] else TtPal.TEXT_DIM)
	# honing
	var hp := Rect2(60, 340, 860, 250)
	draw_style_box(TtPal.sb(Color(TtPal.PANEL, 0.95), 24, 12, Vector2(0, 6)), hp)
	draw_circle(Vector2(110, 392), 24, TtPal.SAP_DARK, true, -1, true)
	draw_circle(Vector2(110, 390), 21, TtPal.SAP, true, -1, true)
	TtPal.text_l(self, TtPal.UI_BOLD, Vector2(148, 392), "%d honing" % int(round(_honey_shown)), 40, TtPal.TEXT)
	var y := 446.0
	var bd: Array = rep.get("breakdown", [])
	var shown := 0
	for row in bd:
		if shown >= 5:
			break
		var amt := int(row.get("amount", 0))
		TtPal.text_l(self, TtPal.UI, Vector2(100, y), str(row.get("label", "")), 22, Color(TtPal.TEXT_DIM, _rows_a))
		TtPal.text_r(self, TtPal.MONO_B, Vector2(880, y), ("+%d" % amt) if amt >= 0 else str(amt), 22, Color(TtPal.OK if amt >= 0 else TtPal.ERR, _rows_a))
		y += 30
		shown += 1
	# sap
	var sp := Rect2(60, 610, 860, 170)
	draw_style_box(TtPal.sb(Color(TtPal.PANEL, 0.95), 24, 12, Vector2(0, 6)), sp)
	var used := int(rep.get("sap_used", 0))
	var opt := int(rep.get("sap_optimum", 0))
	var bud := int(rep.get("sap_budget", 0))
	if bud >= 1000000:
		bud = 0
	var top := float(maxi(maxi(used, opt), maxi(bud, 1)))
	TtPal.text_l(self, TtPal.UI_BOLD, Vector2(90, 646), "Sap (geheugen)", 26, TtPal.TEXT)
	var bar := Rect2(90, 680, 780, 34)
	draw_style_box(TtPal.sb(TtPal.SLOT, 17), bar)
	var fw := bar.size.x * used / top * _sap_a
	if fw > 10:
		draw_style_box(TtPal.sb_thick(TtPal.SAP, 17, 6, TtPal.SAP_DARK), Rect2(bar.position, Vector2(fw, bar.size.y)))
	TtPal.text_l(self, TtPal.MONO_B, bar.position + Vector2(14, 17), "%d" % used, 22, TtPal.INK)
	if opt > 0:
		var ox := bar.position.x + bar.size.x * opt / top
		draw_line(Vector2(ox, bar.position.y - 8), Vector2(ox, bar.end.y + 8), TtPal.OK, 3.0)
		TtPal.text_c(self, TtPal.UI_BOLD, Vector2(ox, bar.end.y + 22), "optimum %d" % opt, 18, TtPal.OK)
	if bud > 0:
		var bx := bar.position.x + bar.size.x * bud / top
		draw_line(Vector2(bx, bar.position.y - 8), Vector2(bx, bar.end.y + 8), TtPal.TEXT_DIM, 3.0)
		TtPal.text_c(self, TtPal.UI, Vector2(bx, bar.position.y - 18), "budget %d" % bud, 18, TtPal.TEXT_DIM)
	var ghost: Dictionary = rep.get("ghost", {})
	if not ghost.is_empty() and int(ghost.get("sap", 0)) > 0:
		TtPal.text_l(self, TtPal.UI, Vector2(90, 760), "%s: %d sap · jouw boom: %d" % [str(ghost.get("label", "")), int(ghost.get("sap", 0)), used], 20, TtPal.TEXT_DIM)
	var cmp := int(rep.get("comparisons", -1))
	if cmp >= 0 and int(rep.get("comparisons_opt", -1)) > 0:
		TtPal.text_r(self, TtPal.UI, Vector2(890, 760), "vluchtlengte %d (opt. %d)" % [cmp, int(rep.comparisons_opt)], 20, TtPal.TEXT_DIM)
	# bloeirij
	var bl: Array = rep.get("bloom", [])
	var bx0 := 90.0
	TtPal.text_l(self, TtPal.UI_BOLD, Vector2(60, 822), "Bloei", 24, Color(TtPal.TEXT, _bloom_a))
	for i in bl.size():
		var ok := bool(bl[i].get("ok", true))
		var c2 := Vector2(bx0 + 70 + i * 40, 822)
		if c2.x > 900:
			break
		draw_circle(c2, 15 * _bloom_a, TtPal.OK if ok else TtPal.WARN, true, -1, true)
		TtPal.text_c(self, TtPal.UI_BOLD, c2, "✓" if ok else "✗", 18, TtPal.INK)
	if not _causes.is_empty():
		var cs: Dictionary = _causes[0]
		TtPal.text_l(self, TtPal.UI, Vector2(60, 870), "← %s faalde: oorzaak in de tijdlijn (amber stip)" % cs.word, 20, TtPal.WARN)
	# tijdlijn
	draw_style_box(TtPal.sb(Color(TtPal.PANEL, 0.95), 24, 12, Vector2(0, 6)), TL)
	TtPal.text_l(self, TtPal.UI_BOLD, TL.position + Vector2(28, 34), "Herbeleving", 28, TtPal.TEXT)
	var nm := 0
	for e in _events:
		if e.mistake:
			nm += 1
	TtPal.text_r(self, TtPal.UI_BOLD, Vector2(TL.end.x - 28, TL.position.y + 34), "%d misstap%s" % [nm, "" if nm == 1 else "pen"], 22, TtPal.WARN if nm > 0 else TtPal.OK)
	var ly := TL.position.y + 90
	if _events.size() > 1:
		draw_line(Vector2(_events[0].x, ly), Vector2(_events[_events.size() - 1].x, ly), Color(TtPal.TEXT_DIM, 0.4), 3.0)
	for i in _events.size():
		var e2: Dictionary = _events[i]
		var col := TtPal.WARN if e2.mistake else (Color("#9AA8A0") if e2.bump else TtPal.OK)
		var r := 11.0 if e2.mistake else 7.0
		if i == _sel:
			draw_circle(Vector2(e2.x, ly), r + 7 + 2 * sin(t * 6.0), Color(col, 0.35), true, -1, true)
		draw_circle(Vector2(e2.x, ly), r, col, true, -1, true)
	TtPal.text_l(self, TtPal.UI, TL.position + Vector2(28, 126), "klik een amber stip (of ←/→): de tuin van dat moment en de juiste zet", 18, TtPal.TEXT_DIM)
	# herbeleving / coach
	if not _replay.visible and not _notes.visible:
		draw_style_box(TtPal.sb(Color(TtPal.PANEL, 0.6), 24), RP)
		var msg := "Geen misstappen: een zuivere boom!" if nm == 0 else "Kies een misstap in de tijdlijn."
		TtPal.text_c(self, TtPal.UI_BOLD, RP.get_center(), msg, 30, TtPal.TEXT_DIM)
	if _replay.visible and _sel >= 0:
		var cy := RP.end.y + 22
		if _events[_sel].mistake:
			TtPal.text_l(self, TtPal.UI_BOLD, Vector2(RP.position.x, cy), "jij: " + _yours, 22, TtPal.ERR)
			TtPal.text_l(self, TtPal.UI_BOLD, Vector2(RP.position.x + 330, cy), "juist: " + _right, 22, TtPal.OK)
			var cr := Rect2(RP.position.x, cy + 26, RP.size.x, 84)
			draw_style_box(TtPal.sb(TtPal.PAPER, 16), cr)
			TtPal.text_l(self, TtPal.UI_BOLD, cr.position + Vector2(20, 28), "Uil: " + _coach, 22, TtPal.INK)
			TtPal.text_l(self, TtPal.UI, cr.position + Vector2(20, 60), _ref, 20, TtPal.INK_SOFT)
		else:
			TtPal.text_l(self, TtPal.UI_BOLD, Vector2(RP.position.x, cy), "Goede zet: " + _yours, 22, TtPal.OK)
