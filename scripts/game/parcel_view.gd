class_name ParcelView
extends Node2D
## Eén pakje (karton + sticker + bitlabel). Positie/schaal/rotatie worden getweend door de depot.

var pid := -1
var hv := 0
var n := 5
var key_label := ""
var bits_str := ""
var box := Vector2(176, 104)
var label_size := 40
var chips := 0          # aantal bits met kleurchip
var knip := 0           # extra spatie na bit k
var accolade := false
var lifted := false
var ring_col := Color(0, 0, 0, 0)
var pulse := 0          # 1-gebaseerde bit die pulseert (sorteertafel)
var pulse_s := 1.0
var ghost := 1.0        # alfa (spookzet)
var _t := 0.0
var _animating_redraw := false


func setup(id_: int, hv_: int, n_: int, key := "") -> ParcelView:
	pid = id_
	hv = hv_
	n = n_
	key_label = key
	bits_str = HashUtil.bits(hv, n)
	return self


## Stijl op basis van bits-markering: hint 0 FULL, 1 COLORS, 2 NONE; `a` = huidige globale diepte.
func apply_hint(hint: int, a: int, loupe := false) -> void:
	if loupe:
		hint = 0
	match hint:
		0:
			chips = a
			knip = a
			accolade = a > 0 and a < n
		1:
			chips = n
			knip = a
			accolade = false
		_:
			chips = 0
			knip = 0
			accolade = false
	queue_redraw()


func set_size(b: Vector2, ls: int) -> void:
	box = b
	label_size = ls
	queue_redraw()


func set_lifted(v: bool) -> void:
	lifted = v
	_animating_redraw = v or pulse > 0
	queue_redraw()


func set_pulse(pos: int) -> void:
	pulse = pos
	_animating_redraw = lifted or pulse > 0
	queue_redraw()


func _process(delta: float) -> void:
	if _animating_redraw:
		_t += delta
		if pulse > 0:
			pulse_s = 1.0 + 0.25 * (0.5 + 0.5 * sin(_t * TAU / 0.6))
		queue_redraw()


func _draw() -> void:
	if ghost < 1.0:
		modulate.a = ghost
	Pal.parcel(self, Vector2.ZERO, box * (1.08 if lifted else 1.0), bits_str, int(label_size * (1.08 if lifted else 1.0)),
		chips, knip, lifted, accolade, _t, key_label, pulse, pulse_s, ring_col)


func rect_global() -> Rect2:
	var s := global_scale
	return Rect2(global_position - box * s / 2.0, box * s)
