class_name TxTapeView
extends Control
## Het lint met leeskop, naald, sjabloon(en), ponsstrook, sprongboog en ponskop (GDD §2.2, §4.3). Tekent in lokale
## coördinaten en scrolt horizontaal (venster rond de leeskop). Alle animatie = velden die de panelen tweenen.
## Versnipperaar en inlaat tekent de console naast dit venster (ze vallen buiten de clip).
## Muis: sjabloon slepen (stencil_drag), tekens/letters/vakjes klikken (signalen).

signal stencil_drag(cols: int, released: bool)
signal tape_clicked(pos: int)
signal stencil_clicked(i: int)
signal strip_clicked(j: int)
signal hover_changed(pos: int)

const ORIGIN := Vector2(168, 56)
const W := 1544.0
const H := 334.0
const YT := 44.0            # lint (lokaal)
const YP := 152.0           # posities
const YS := 182.0           # sjabloon
const YV := 280.0           # ponsstrook

var text := ""
var cell := 44.0
var fsize := 44
var scroll := 0.0
var scroll_target := 0.0
var follow := 0.0           # kolom die in beeld moet blijven
var follow_hi := -1.0       # en eventueel ook deze (rechterrand)
var states := {}
var front := -1             # −1 = alles binnen
var front_f := -1.0         # vloeiend (inlaat rolt)
var shred := -1
var hits: Array = []
var missed: Array = []
var falses: Array = []
var key_pos := -1
var spot: Array = []
var frame: Array = []
var glow := 0.0
var show_positions := true
var hover_pos := -1
var hover_enabled := false
var window_lo := -1         # klikbaar venster (Springer)
var window_hi := -1

var head_on := true
var head_col := 0.0
var head_strike := 0.0
var head_lit := ""
var head_warm := 0.0
var head_streak := 0.0

## sjablonen: [{z, start (float), teeth, cur, ghost, marks, dy, sq (squash), a, visible}]
var stencils: Array = []
var drag_enabled := false
var drag_stencil := 0
var _dragging := false
var _drag_x0 := 0.0
var _drag_cols := 0

var strip_vals: Array = []  # [] = geen strook
var strip_col := 0.0        # kolom van vakje 0
var strip_extra := false
var strip_hl := -1
var strip_dy := 0.0
var strip_a := 1.0
var strip_label := "V"

var arc := {}               # {from, to, u, label}
var punch := {}             # {a, b, v, hit}
var labels: Array = []      # [{col, y, text, col_c (Color), size}]
var ghost_hand := {}        # {pos: Vector2 (lokaal), t}
var _t := 0.0


func _init() -> void:
	position = ORIGIN
	size = Vector2(W, H)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP


func setup_text(s: String, keep_cell := false) -> void:
	text = s
	if not keep_cell:
		var n := s.length()
		cell = 44.0 if n <= 35 else 34.0
		fsize = 44 if cell >= 40.0 else 32
	states = {}
	hits = []
	missed = []
	falses = []
	key_pos = -1
	spot = []
	frame = []
	front = -1
	front_f = -1.0
	shred = -1


func visible_cols() -> float:
	return W / cell


func colx(c: float) -> float:
	return (c - scroll) * cell


func col_at(x: float) -> int:
	return int(floor(x / cell + scroll))


func global_col(c: float) -> Vector2:
	return ORIGIN + Vector2(colx(c) + cell / 2.0, 0)


## Globaal punt van t[pos] (midden van het teken).
func char_pos(pos: float) -> Vector2:
	return global_position + Vector2(colx(pos) + cell / 2.0, YT + 62)


func stencil_pos(si: int, i: float) -> Vector2:
	if si >= stencils.size():
		return global_position
	return global_position + Vector2(colx(float(stencils[si].start) + i) + cell / 2.0, YS + 48)


func strip_pos(j: float) -> Vector2:
	return global_position + Vector2(colx(strip_col + j) + cell / 2.0, YV + 24)


func head_pos() -> Vector2:
	return global_position + Vector2(colx(head_col) + cell / 2.0, YT - 20)


func add_stencil(z: String, start: float, ghost := false) -> int:
	stencils.append({"z": z, "start": start, "teeth": {}, "cur": -1, "ghost": ghost, "marks": {}, "dy": 0.0,
		"sq": 1.0, "a": 1.0, "visible": true})
	return stencils.size() - 1


func st(i: int) -> Dictionary:
	return stencils[i] if i < stencils.size() else {}


func set_stencil(i: int, k: String, v) -> void:
	if i < stencils.size():
		stencils[i][k] = v


## Tween een veld van een sjabloon (start, dy, sq, a).
func tween_stencil(i: int, k: String, to: float, dur: float, trans := Tween.TRANS_CUBIC, ease := Tween.EASE_OUT) -> Tween:
	var tw := create_tween()
	if i >= stencils.size():
		return tw
	var from := float(stencils[i][k])
	tw.tween_method(func(v: float):
		if i < stencils.size():
			stencils[i][k] = v, from, to, maxf(0.01, dur)).set_trans(trans).set_ease(ease)
	return tw


func _process(dt: float) -> void:
	_t += dt
	# volgen: houd follow (en follow_hi) in beeld
	var vis := visible_cols()
	var n := float(maxi(text.length(), 1))
	var maxs := maxf(0.0, n - vis + 0.5)
	var lo := follow - vis * 0.30
	var tgt := scroll_target
	if follow < scroll_target + vis * 0.15 or follow > scroll_target + vis * 0.75:
		tgt = lo
	if follow_hi >= 0.0 and follow_hi > tgt + vis - 2.0:
		tgt = follow_hi - vis + 2.0
	scroll_target = clampf(tgt, 0.0, maxs)
	scroll = lerpf(scroll, scroll_target, 1.0 - exp(-dt * 7.0))
	if absf(scroll - scroll_target) < 0.001:
		scroll = scroll_target
	if front >= 0:
		if front_f < 0.0:
			front_f = float(front)
		front_f = move_toward(front_f, float(front), dt * maxf(6.0, absf(front - front_f) * 6.0))
	queue_redraw()


func _draw() -> void:
	var n := text.length()
	if n == 0 and stencils.is_empty():
		return
	var first := maxi(0, int(floor(scroll)) - 1)
	var count := mini(n - first, int(ceil(visible_cols())) + 3)
	var opts := {"states": states, "size": fsize, "hits": hits, "missed": missed, "false": falses, "glow": glow}
	if front >= 0:
		opts["front"] = int(ceil(front_f)) if front_f >= 0.0 else front
	if shred > 0:
		opts["shred"] = shred
	if key_pos >= 0:
		opts["key"] = key_pos
	if spot.size() == 2:
		opts["spot"] = spot
	if frame.size() == 2:
		opts["frame"] = frame
	if n > 0 and count > 0:
		TxDraw.tape(self, colx(first), YT, text, first, count, cell, opts)
		if hover_enabled and hover_pos >= 0 and hover_pos < n:
			var hr := Rect2(colx(hover_pos) + 2, YT + 30, cell - 4, TxPal.TAPE_H - 34)
			var inside := window_lo < 0 or (hover_pos >= window_lo and hover_pos <= window_hi)
			draw_style_box(TxPal.sb(Color(0, 0, 0, 0), 5, 0, Vector2.ZERO, 3, TxPal.SIG_BLUE if inside else Color(TxPal.SIG_GREY, 0.6)), hr)
		if window_lo >= 0 and window_hi >= window_lo:
			var wr := Rect2(colx(window_lo), YT - 2, (window_hi - window_lo + 1) * cell, 4)
			draw_rect(wr, Color(TxPal.SIG_BLUE, 0.5))
		if show_positions:
			var hc := int(round(head_col)) if head_on else -1
			TxDraw.tape_positions(self, colx(first), YP, first, count, cell, n, hc)
	# ponsstrook
	if not strip_vals.is_empty() and strip_a > 0.01:
		var vals: Array = []
		for v in strip_vals:
			if int(v) == TxCodes.STRIP_EMPTY:
				vals.append(null)
			elif int(v) == TxCodes.STRIP_BURNT:
				vals.append("burnt")
			else:
				vals.append(int(v))
		if strip_a < 1.0:
			draw_set_transform(Vector2(0, strip_dy), 0.0, Vector2.ONE)
		else:
			draw_set_transform(Vector2(0, strip_dy), 0.0, Vector2.ONE)
		TxDraw.strip(self, colx(strip_col), YV, vals, cell, strip_extra, strip_hl, strip_label)
		if not punch.is_empty():
			TxDrawMachines.punch_head(self, colx(strip_col), YV, cell, int(punch.a), int(punch.b), int(punch.v), float(punch.get("hit", 0.0)))
		draw_set_transform(Vector2.ZERO)
	# sjablonen
	for i in stencils.size():
		var s: Dictionary = stencils[i]
		if not bool(s.visible) or float(s.a) <= 0.01:
			continue
		var x0 := colx(float(s.start))
		var sq := float(s.sq)
		if sq != 1.0 or float(s.dy) != 0.0:
			var piv := Vector2(x0 + str(s.z).length() * cell / 2.0, YS + 40)
			draw_set_transform(piv + Vector2(0, float(s.dy)), 0.0, Vector2(2.0 - sq, sq))
			x0 = -str(s.z).length() * cell / 2.0
			TxDraw.stencil(self, x0, -40, str(s.z), cell, s.teeth, int(s.cur), bool(s.ghost), fsize, s.marks)
			draw_set_transform(Vector2.ZERO)
		else:
			TxDraw.stencil(self, x0, YS, str(s.z), cell, s.teeth, int(s.cur), bool(s.ghost), fsize, s.marks)
	# sprongboog
	if not arc.is_empty():
		TxDrawMachines.jump_arc(self, colx(float(arc.from)) + cell / 2.0, colx(float(arc.to)) + cell / 2.0, YS + 4,
				float(arc.get("u", 1.0)), str(arc.get("label", "")), minf(110.0, 20.0 + absf(float(arc.to) - float(arc.from)) * 14.0))
	# leeskop
	if head_on and n > 0:
		TxDraw.head(self, colx(head_col) + cell / 2.0, YT, head_strike, head_lit, head_warm, head_streak)
	for l in labels:
		var c: Color = l.get("color", TxPal.TEXT)
		TxPal.text_l(self, TxPal.UI_BOLD, Vector2(colx(float(l.col)), float(l.y)), str(l.text), int(l.get("size", 24)), c)
	if not ghost_hand.is_empty():
		var bob := sin(_t * 6.0) * 6.0
		TxPal.ghost_hand(self, (ghost_hand.pos as Vector2) + Vector2(0, bob), 1.0, TxPal.SIG_BLUE, 0.85)


# ---------------------------------------------------------------- invoer
func _hit_stencil(lp: Vector2) -> int:
	if lp.y < YS - 14 or lp.y > YS + TxPal.STENCIL_H:
		return -1
	for i in range(stencils.size() - 1, -1, -1):
		var s: Dictionary = stencils[i]
		if not bool(s.visible) or bool(s.ghost):
			continue
		var x0 := colx(float(s.start))
		if lp.x >= x0 - 10 and lp.x <= x0 + str(s.z).length() * cell + 10:
			return i
	return -1


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var lp: Vector2 = e.position
		if _dragging:
			var cols := int(round((lp.x - _drag_x0) / cell))
			if cols != _drag_cols:
				_drag_cols = cols
				stencil_drag.emit(cols, false)
			accept_event()
			return
		var hp := -1
		if lp.y >= YT and lp.y <= YT + TxPal.TAPE_H:
			hp = col_at(lp.x)
			if hp >= text.length():
				hp = -1
		if hp != hover_pos:
			hover_pos = hp
			hover_changed.emit(hp)
		var over_st := drag_enabled and _hit_stencil(lp) == drag_stencil
		mouse_default_cursor_shape = Control.CURSOR_DRAG if over_st else (Control.CURSOR_POINTING_HAND if hover_enabled and hp >= 0 else Control.CURSOR_ARROW)
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		var lp2: Vector2 = e.position
		if e.pressed:
			var si := _hit_stencil(lp2)
			if drag_enabled and si == drag_stencil:
				_dragging = true
				_drag_x0 = lp2.x
				_drag_cols = 0
				stencil_drag.emit(0, false)
				accept_event()
				return
			if si >= 0:
				var i := int(floor((lp2.x - colx(float(stencils[si].start))) / cell))
				if i >= 0 and i < str(stencils[si].z).length():
					stencil_clicked.emit(i)
					accept_event()
					return
			if lp2.y >= YT and lp2.y <= YT + TxPal.TAPE_H:
				var p := col_at(lp2.x)
				if p >= 0 and p < text.length():
					tape_clicked.emit(p)
					accept_event()
					return
			if not strip_vals.is_empty() and lp2.y >= YV and lp2.y <= YV + TxPal.STRIP_H:
				var lx := lp2.x - colx(strip_col)
				var j := int(floor(lx / cell))
				if strip_extra and j >= strip_vals.size() - 1:
					j = int(floor((lx - 18) / cell))
				if j >= 0 and j < strip_vals.size():
					strip_clicked.emit(j)
					accept_event()
		elif _dragging:
			_dragging = false
			stencil_drag.emit(_drag_cols, true)
			accept_event()


func is_dragging() -> bool:
	return _dragging


func cancel_drag() -> void:
	_dragging = false
