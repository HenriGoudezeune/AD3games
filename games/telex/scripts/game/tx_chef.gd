class_name TxChef
extends Node2D
## Chef Ponsaert: portret + getypte spreekwolk (≤ 12 woorden). say() typt de tekst letter per letter (tak-geluidjes),
## praat (mond), knippert en verdwijnt na een tijd.

var anchor := Vector2(1150, 600)
var scale_k := 0.9
var text := ""
var shown := 0.0
var talk := 0.0
var blink := 0.0
var hold := 0.0
var alpha := 0.0
var small := false
var _t := 0.0
var _next_blink := 2.0
var brow := 0.4


func say(s: String, secs := 4.5, worried := false) -> void:
	if s == "":
		return
	text = _wrap(s, 30)
	shown = 0.0
	hold = secs + s.length() * 0.03
	brow = 0.9 if worried else 0.4
	var tw := create_tween()
	tw.tween_property(self, "alpha", 1.0, 0.18)
	TxSnd.play("typewriter", -12.0)


func quiet() -> void:
	hold = 0.0


static func _wrap(s: String, w: int) -> String:
	var words := s.split(" ")
	var lines: Array = []
	var cur := ""
	for wd in words:
		if cur.length() + wd.length() + 1 > w and cur != "":
			lines.append(cur)
			cur = wd
		else:
			cur = wd if cur == "" else cur + " " + wd
	if cur != "":
		lines.append(cur)
	return "\n".join(lines)


func _process(dt: float) -> void:
	_t += dt
	if shown < text.length():
		var before := int(shown)
		shown = minf(float(text.length()), shown + dt * 45.0)
		if int(shown) != before and int(shown) % 3 == 0:
			TxSnd.play("tak_%d" % (randi() % 3 + 1), -22.0, 1.3)
		talk = absf(sin(_t * 18.0)) * 0.8
	else:
		talk = move_toward(talk, 0.0, dt * 4.0)
		if hold > 0.0:
			hold -= dt
			if hold <= 0.0:
				create_tween().tween_property(self, "alpha", 0.0, 0.35)
	_next_blink -= dt
	if _next_blink <= 0.0:
		blink = 1.0
		_next_blink = randf_range(2.2, 4.5)
	blink = move_toward(blink, 0.0, dt * 8.0)
	queue_redraw()


func _draw() -> void:
	var s := scale_k * (0.6 if small else 1.0)
	TxDraw.chef(self, anchor, s, talk, blink, brow)
	if alpha > 0.01 and text != "":
		var vis := text.substr(0, int(shown))
		var lines := text.split("\n")
		var w := 0.0
		for l in lines:
			w = maxf(w, TxPal.text_w(TxPal.TAPE_REG, l, 22))
		var h := 40.0 + lines.size() * 28.0
		var br := Rect2(anchor + Vector2(100 * s, -h - 10), Vector2(w + 44, h))
		if br.end.x > 1900:
			br.position.x = anchor.x - 100 * s - br.size.x
		modulate.a = 1.0
		draw_set_transform(Vector2.ZERO)
		var col := Color(1, 1, 1, alpha)
		self_modulate = Color(1, 1, 1, 1)
		_balloon(br, vis, anchor + Vector2(60 * s * signf(br.position.x - anchor.x), -40 * s), col)


func _balloon(r: Rect2, vis: String, tail: Vector2, col: Color) -> void:
	# getypt telegramstrookje (alfa via kleur)
	draw_rect(Rect2(r.position + Vector2(3, 6), r.size), Color(0, 0, 0, 0.35 * col.a))
	var tipx := clampf(tail.x, r.position.x + 20, r.end.x - 20)
	draw_colored_polygon(PackedVector2Array([Vector2(tipx - 14, r.end.y - 1), Vector2(tipx + 14, r.end.y - 1), tail]), Color(TxPal.CARD, col.a))
	draw_texture_rect(TxPal.tex("tex/paper_tile.png"), r, true, Color(1.12, 1.1, 1.02, col.a))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 4)), Color(TxPal.STAMP_BLUE, 0.7 * col.a))
	TxPal.text_l(self, TxPal.TAPE_REG, r.position + Vector2(16, 16), "CHEF PONSAERT  —  STOP", 12, Color(TxPal.INK_SOFT, col.a))
	var y := r.position.y + 42
	for l in vis.split("\n"):
		TxPal.text_l(self, TxPal.TAPE, Vector2(r.position.x + 20, y), l, 22, Color(TxPal.INK, col.a))
		y += 28
