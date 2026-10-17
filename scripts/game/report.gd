extends Control
## Dagrapport (GDD §4.1, §7): sterren klappen in, tellers rollen, ritten vs. optimum, munten-uitsplitsing,
## herbeleving-tijdlijn (klik een amber stip → depot van dat moment + chefzin), notas-weergave.

const STAR_CAPTION := {"done": "uitgespeeld", "no_mistakes": "0 fouten", "io_optimal": "ritten = opt.",
	"time": "snel genoeg", "no_doubles": "0 dubbels + opt.", "customers": "alle klanten", "final_state": "eindtoestand correct", "end_state": "eindtoestand = Oef. 5"}

var rep: Dictionary
var spec
var entries: Array = []
var _stars_shown := [0.0, 0.0, 0.0]
var _star_on := [false, false, false]
var _coins_shown := 0.0
var _r_shown := 0.0
var _w_shown := 0.0
var _canvas: Node2D
var _t := 0.0
var _dots: Array = []        # [{rect, entry}]
var _sel := -1
var _notas: NotasView
var _coach: Label
var _notas_btn: Button
var _show_final := false
var day := 1


func _ready() -> void:
	theme = UIKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	rep = Game.last_report
	spec = Game.last_spec
	entries = Game.last_log
	day = Game.current_day
	add_child(Backdrop.new())
	_canvas = Node2D.new()
	_canvas.draw.connect(_draw_report)
	add_child(_canvas)
	var ttl: String = Game.last_title if Game.last_title != "" else (str(spec.title) if spec else "")
	var head := UIKit.label(("DAG %d" % day if day > 0 else "PIEKDAG") + "  ·  " + ttl, 48, Pal.TEXT, Pal.UI_BOLD)
	head.position = Vector2(190, 30)   # links ervan staat het HubNav-huisje
	add_child(head)
	# notas-weergave / herbeleving
	_notas = NotasView.new()
	_notas.position = Vector2(1000, 470)
	_notas.size = Vector2(860, 450)
	add_child(_notas)
	_coach = UIKit.label("", 26, Pal.WARN, Pal.UI_BOLD)
	_coach.position = Vector2(1000, 924)
	_coach.size = Vector2(860, 40)
	_coach.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(_coach)
	_show_final_state()
	var note := str(rep.get("note", ""))
	if note != "":
		var nl := UIKit.label(note, 22, Pal.WARN, Pal.UI_BOLD)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD
		nl.position = Vector2(1000, 964)
		nl.size = Vector2(880, 90)
		add_child(nl)
		_coach.position.y = 920
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 20)
	bar.position = Vector2(60, 980)
	add_child(bar)
	var stars_n := 0
	for s in rep.get("stars", []):
		if s:
			stars_n += 1
	var has_next: bool = day > 0 and day < Days.count() and stars_n >= 1
	if has_next:
		var nx := UIKit.button("Volgende dag", Pal.OK, Pal.INK, 30, 300)
		nx.pressed.connect(func(): Game.goto_day(day + 1))
		bar.add_child(nx)
		nx.grab_focus.call_deferred()
	var again := UIKit.button("Opnieuw", Pal.PANEL_HI, Pal.TEXT, 30, 240)
	again.pressed.connect(func(): Game.goto_day(day))
	bar.add_child(again)
	if not has_next:
		again.grab_focus.call_deferred()
	var mp := UIKit.button("Kaart", Pal.PANEL_HI, Pal.TEXT, 30, 200)
	mp.pressed.connect(func(): Transition.goto(Game.SCENE_MAP))
	bar.add_child(mp)
	# leerpad: 1–2 controlevragen over de delen van deze dag, op een nieuw voorbeeld
	if day > 0 and not HDLessons.report_parts(day).is_empty() and not Game.cmd.has("bot"):
		var ck := UIKit.button("Check", Pal.INFO, Pal.INK, 30, 180)
		ck.pressed.connect(_open_check)
		bar.add_child(ck)
	_notas_btn = UIKit.button("Notas-weergave", Pal.WARN, Pal.INK, 26, 280)
	_notas_btn.position = Vector2(1580, 400)
	_notas_btn.pressed.connect(_show_final_state)
	add_child(_notas_btn)
	Sfx.play_track("calm")
	if bool(rep.get("endless", false)):
		_setup_endless()
	_animate_in()


var _check: CheckQuiz


func _open_check() -> void:
	if _check and is_instance_valid(_check):
		return
	_check = CheckQuiz.open(self, HDLessons.report_parts(day))


## Na de sterren: de Check opent vanzelf zolang een deel van deze dag nog niet "begrepen" is.
func _auto_check() -> void:
	if day <= 0 or Game.cmd.has("bot") or bool(rep.get("endless", false)):
		return
	var ps := HDLessons.report_parts(day)
	if ps.is_empty():
		return
	var need := false
	for id in ps:
		if HDLessons.level(id) < 3:
			need = true
	if need:
		_open_check()


func _animate_in() -> void:
	var st: Array = rep.get("stars", [false, false, false])
	for i in 3:
		_star_on[i] = i < st.size() and bool(st[i])
	await get_tree().create_timer(0.5).timeout
	for i in 3:
		var tw := create_tween()
		tw.tween_method(func(v): _stars_shown[i] = v, 0.0, 1.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if _star_on[i]:
			Sfx.play("sfx/star_%d.wav" % (i + 1), -4.0, 1.0, false)
			get_tree().create_timer(0.3).timeout.connect(func():
				Juice.burst(self, _star_pos(i), "star", 12, 0.6, 150, 320, Pal.COIN, 300, 0.1, 0.25, true)
				Juice.burst(self, _star_pos(i), "k_star_06", 1, 0.4, 0, 0, Pal.COIN, 0, 1.5, 1.5, true)
				Juice.shake(3.0, 0.15))
		else:
			Sfx.play("sfx/drop_soft.wav", -6.0)
		await get_tree().create_timer(0.45).timeout
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(self, "_coins_shown", float(rep.get("coins", 0)), 0.8).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw2.tween_property(self, "_r_shown", float(rep.get("reads", 0)), 0.8).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw2.tween_property(self, "_w_shown", float(rep.get("writes", 0)), 0.8).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	Sfx.play("sfx/kenney/coins_payout.ogg", -4.0)
	get_tree().create_timer(1.6).timeout.connect(_auto_check)
	if Game.cmd.has("demo-replay"):
		await get_tree().create_timer(1.0).timeout
		for d in _dots:
			if int(d.entry.verdict) != 0:
				_select(d)
				break


var _hs_list: Array = []
var _hs_rank := -1
var _endless := false


func _setup_endless() -> void:
	_endless = true
	var score := int(rep.get("coins", 0))
	if SaveData.is_highscore(score):
		var box := HBoxContainer.new()
		box.add_theme_constant_override("separation", 12)
		box.position = Vector2(560, 236)
		add_child(box)
		var le := LineEdit.new()
		le.max_length = 3
		le.placeholder_text = "AAA"
		le.custom_minimum_size = Vector2(130, 60)
		le.add_theme_font_override("font", Pal.MONO)
		le.add_theme_font_size_override("font_size", 36)
		le.alignment = HORIZONTAL_ALIGNMENT_CENTER
		le.text_changed.connect(func(t): le.text = t.to_upper(); le.caret_column = le.text.length(); Sfx.play("sfx/key_bit_%d.wav" % clampi(le.text.length(), 1, 6), -6.0))
		box.add_child(le)
		var ok := UIKit.button("Bewaar", Pal.COIN, Pal.INK, 26, 150)
		var save := func():
			var nm := le.text.strip_edges().to_upper()
			if nm == "":
				nm = "???"
			_hs_rank = SaveData.add_highscore(score, nm)
			_hs_list = SaveData.highscores()
			box.queue_free()
			Sfx.play("sfx/kenney/coins_payout.ogg")
			Juice.confetti(self, Vector2(700, 260), 30, [Pal.COIN, Pal.HEART, Pal.INFO, Pal.OK])
		ok.pressed.connect(save)
		le.text_submitted.connect(func(_t): save.call())
		box.add_child(ok)
		le.grab_focus.call_deferred()
		get_tree().create_timer(1.2).timeout.connect(func():
			Juice.confetti(self, Vector2(400, 200), 40, [Pal.COIN, Pal.HEART, Pal.INFO, Pal.OK])
			Sfx.play("sfx/day_complete.wav", -4.0, 1.0, false))
	_hs_list = SaveData.highscores()


func _star_pos(i: int) -> Vector2:
	return Vector2(260 + i * 210, 230)


func _process(d: float) -> void:
	_t += d
	_canvas.queue_redraw()


func _draw_report() -> void:
	var c := _canvas
	if _endless:
		_draw_endless(c)
	# sterren
	var kinds: Array = spec.stars if spec else []
	for i in (0 if _endless else 3):
		var p := _star_pos(i)
		var s: float = _stars_shown[i]
		Pal.star_shape(c, p, 80, Color(1, 1, 1, 0.08))
		if s > 0.01:
			if _star_on[i]:
				var from := p + Vector2(0, -300)
				var q := from.lerp(p, minf(s, 1.0))
				var sc := s * (1.0 + 0.04 * sin(_t * 3.0 + i))
				Pal.star_shape(c, q + Vector2(0, 6), 80 * sc, Pal.COIN_DARK)
				Pal.star_shape(c, q, 80 * sc, Pal.COIN)
				Pal.star_shape(c, q + Vector2(-14, -16) * sc, 22 * sc, Color(1, 1, 1, 0.5))
			var cap := ""
			if i < kinds.size():
				cap = STAR_CAPTION.get(str(kinds[i].get("kind", "")), "")
			Pal.text_c(c, Pal.UI_BOLD, p + Vector2(0, 112), cap, 22, Pal.TEXT if _star_on[i] else Pal.TEXT_DIM)
	# munten (paneel groeit mee met het aantal regels)
	var nrows: int = rep.get("breakdown", []).size()
	var mr := Rect2(60, 360, 860, maxf(230.0, 110.0 + nrows * 34.0))
	c.draw_style_box(Pal.sb(Pal.PANEL, 24, 16, Vector2(0, 10)), mr)
	Pal.coin(c, mr.position + Vector2(50, 50), 26)
	Pal.text_l(c, Pal.UI_BOLD, mr.position + Vector2(90, 50), "%d" % int(round(_coins_shown)), 52, Pal.COIN)
	var y := mr.position.y + 104
	for b in rep.get("breakdown", []):
		var amt := int(b.amount)
		Pal.text_l(c, Pal.UI, Vector2(mr.position.x + 40, y), str(b.label), 24, Pal.TEXT_DIM)
		Pal.text_r(c, Pal.MONO, Vector2(mr.end.x - 40, y), ("+%d" % amt) if amt >= 0 else "%d" % amt, 24, Pal.TEXT if amt >= 0 else Pal.ERR)
		y += 34
	# ritten vs optimum
	var tr := Rect2(60, mr.end.y + 16, 860, minf(250.0, 960.0 - mr.end.y - 16))
	c.draw_style_box(Pal.sb(Pal.PANEL, 24, 16, Vector2(0, 10)), tr)
	Pal.truck(c, tr.position + Vector2(56, 50), 1.6)
	Pal.text_l(c, Pal.UI_BOLD, tr.position + Vector2(100, 50), "Ritten (schijftoegang)", 30, Pal.TEXT)
	var opt: Dictionary = rep.get("opt_total", rep.get("opt", {}))
	var gap := (tr.size.y - 90.0) / 2.0
	_bar(c, Vector2(tr.position.x + 40, tr.position.y + 90 + gap * 0.35), "L lezen", _r_shown, float(opt.get("reads", 0)))
	_bar(c, Vector2(tr.position.x + 40, tr.position.y + 90 + gap * 1.35), "S schrijven", _w_shown, float(opt.get("writes", 0)))
	var cust := int(rep.get("customers_total", 0))
	if cust > 0:
		Pal.text_r(c, Pal.UI, Vector2(tr.end.x - 30, tr.position.y + 50), "opt L = pakjes + %d klant%s" % [cust, "" if cust == 1 else "en"], 18, Pal.TEXT_DIM)
	# tijdlijn herbeleving
	var hr := Rect2(1000, 120, 860, 260)
	c.draw_style_box(Pal.sb(Pal.PANEL, 24, 16, Vector2(0, 10)), hr)
	Pal.text_l(c, Pal.UI_BOLD, hr.position + Vector2(30, 36), "Herbeleving", 30, Pal.TEXT)
	var mist := 0
	for e in entries:
		if int(e.verdict) != 0 and not bool(e.data.get("excused", false)):
			mist += 1
	Pal.text_r(c, Pal.UI, hr.position + Vector2(hr.size.x - 30, 36), "%d fout%s" % [mist, "" if mist == 1 else "en"], 24, Pal.WARN if mist > 0 else Pal.OK)
	_dots.clear()
	var shown: Array = []
	for e in entries:
		if e.type in ["DROP", "DOUBLE", "SPLIT_BEGIN", "ASSIGN", "LOST", "LOOKUP", "DUMP"]:
			shown.append(e)
	var lx0 := hr.position.x + 40
	var lx1 := hr.end.x - 40
	var ly := hr.position.y + 140
	c.draw_line(Vector2(lx0, ly), Vector2(lx1, ly), Pal.PANEL_HI, 6, true)
	for i in shown.size():
		var e: Dictionary = shown[i]
		var x := lerpf(lx0, lx1, (i + 0.5) / maxf(1, shown.size()))
		var bad := int(e.verdict) != 0 and not bool(e.data.get("excused", false))
		var big: bool = e.type in ["DOUBLE", "SPLIT_BEGIN"]
		var rr := 13.0 if bad else (11.0 if big else 7.0)
		var col := Pal.WARN if bad else (Pal.INFO if big else Pal.OK)
		if _sel == i:
			c.draw_circle(Vector2(x, ly), rr + 8, Color(col, 0.35), true, -1, true)
		if bad:
			c.draw_circle(Vector2(x, ly), rr + 4 + 3 * sin(_t * 5.0), Color(col, 0.25), true, -1, true)
		c.draw_circle(Vector2(x, ly), rr, col, true, -1, true)
		if big:
			Pal.text_c(c, Pal.UI_BOLD, Vector2(x, ly - 34), "a+1" if e.type == "DOUBLE" else "zaag", 18, Pal.TEXT_DIM)
		_dots.append({"rect": Rect2(x - 16, ly - 20, 32, 40), "entry": e, "i": i})
	if shown.is_empty():
		Pal.text_c(c, Pal.UI, Vector2(hr.get_center().x, ly), "—", 24, Pal.TEXT_DIM)
	Pal.text_l(c, Pal.UI, Vector2(hr.position.x + 30, hr.end.y - 36), "klik een amber stip: zo zag je depot eruit, en dit was de juiste zet", 20, Pal.TEXT_DIM)


func _draw_endless(c: Node2D) -> void:
	var score := int(rep.get("coins", 0))
	Pal.text_l(c, Pal.UI_BOLD, Vector2(60, 170), "SCORE", 30, Pal.TEXT_DIM)
	Pal.coin(c, Vector2(90, 250), 30)
	Pal.text_l(c, Pal.UI_BOLD, Vector2(140, 250), "%d" % int(round(_coins_shown)), 80, Pal.COIN)
	Pal.text_l(c, Pal.UI, Vector2(60, 330), "%d s volgehouden · a = %d · %d pakjes" % [int(rep.get("time", 0)), int(rep.get("a", 0)), int(rep.get("parcels", 0))], 24, Pal.TEXT_DIM)
	var x := 560.0
	Pal.text_l(c, Pal.UI_BOLD, Vector2(x, 140), "Top 10", 26, Pal.TEXT)
	var y0 := 320.0 if (_hs_rank < 0 and SaveData.is_highscore(score)) else 184.0
	for i in mini(_hs_list.size(), 10):
		var h: Dictionary = _hs_list[i]
		var col := Pal.COIN if i == _hs_rank else Pal.TEXT_DIM
		var pos := Vector2(x + (i / 5) * 200, y0 + (i % 5) * 30)
		if pos.y > 370:
			continue
		Pal.text_l(c, Pal.MONO, pos, "%d. %s %d" % [i + 1, str(h.get("name", "???")), int(h.get("score", 0))], 20, col)


func _bar(c: Node2D, at: Vector2, label: String, val: float, opt: float) -> void:
	Pal.text_l(c, Pal.UI_BOLD, at + Vector2(0, 0), label, 24, Pal.TEXT_DIM)
	var x0 := at.x + 170
	var w := 560.0
	var mx := maxf(maxf(val, opt), 1.0) * 1.15
	c.draw_style_box(Pal.sb(Pal.SLOT, 12), Rect2(x0, at.y - 16, w, 32))
	var over := val > opt + 0.01 and opt > 0
	c.draw_style_box(Pal.sb(Pal.WARN if over else Pal.OK, 12), Rect2(x0, at.y - 16, maxf(24.0, w * val / mx), 32))
	if opt > 0:
		var ox := x0 + w * opt / mx
		c.draw_line(Vector2(ox, at.y - 26), Vector2(ox, at.y + 26), Pal.TEXT, 3)
		Pal.text_c(c, Pal.UI, Vector2(ox, at.y + 40), "opt %d" % int(opt), 18, Pal.TEXT_DIM)
	Pal.text_l(c, Pal.MONO, Vector2(x0 + 12, at.y), "%d" % int(round(val)), 24, Pal.INK)


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var m: Vector2 = ev.position
		for d in _dots:
			if (d.rect as Rect2).has_point(m):
				_select(d)
				return


func _select(d: Dictionary) -> void:
	_sel = d.i
	var e: Dictionary = d.entry
	Sfx.ui("click")
	var before: Dictionary = e.get("before", {})
	var lg := EventLog.new()
	lg.n = int(Game.last_model_snapshot.get("n", 5))
	var line := lg.coach_line(e).replace("`", "")
	var a_before := int(before.get("a", 1)) if not before.is_empty() else 1
	_notas.bad_index = -1
	_notas.good_index = -1
	var h: Dictionary = e.get("hint", {})
	if e.type == "DROP" or e.type == "LOOKUP":
		_notas.bad_index = int(e.data.get("dir_index", -1))
		_notas.good_index = int(e.data.get("correct_index", -1))
	elif str(h.get("action", "")) == "drop":
		_notas.good_index = int(h.get("dir_index", -1))
	if _notas.good_index >= (1 << a_before):
		_notas.good_index = -1
	if before.is_empty():
		_coach.text = line if line != "" else "Goed gedaan."
		return
	_notas.highlight_bucket = int(e.data.get("bucket_id", -1))
	_notas.set_snapshot(before, "Vóór je zet (t = %.0f s)" % float(e.t))
	_coach.text = line
	_coach.modulate.a = 0.0
	_coach.create_tween().tween_property(_coach, "modulate:a", 1.0, 0.25)
	UIKit.pop_in(_notas, 0.0, 0.2)


func _show_final_state() -> void:
	_sel = -1
	_notas.highlight_bucket = -1
	_notas.bad_index = -1
	_notas.good_index = -1
	_notas.set_snapshot(Game.last_model_snapshot, "Eindtoestand, zoals in de notas")
	if _coach:
		_coach.text = ""
