class_name ScStrip
extends Node2D
## De kortschrift-strook (GDD §2.2, §4.3): tokens (bits, lakzegels, wassen zegels, stempelafdrukken, getallen) op een
## perkamentstrook die horizontaal scrolt. Nieuwe tokens verschijnen één voor één (de kopiist schrijft: 40 ms per bit)
## met een krabbelende ganzenveer. `koker_units` = het optimum: de gouden lijn, wat erover gaat wordt amber.
## Ontvangen: `consumed` = het aantal al gelezen tokens (gedimd, lapis cursor).

const SIZE := 28

var clip_w := 1200.0
var tokens: Array = []
var shown := 0.0              # aantal getoonde eenheden (bits; andere tokens = 1, lakzegel = 8)
var target := 0.0
var consumed := -1
var koker_units := -1
var spd := 1.0
var t := 0.0
var _off := 0.0
var _writing := 0.0
var _last_unit := 0
var fx_root: Node
var size := SIZE


static func units_of(tk: Dictionary) -> int:
	if tk.has("b"):
		return str(tk.b).length()
	if tk.has("raw"):
		return 8
	return 1


static func total_units(toks: Array) -> int:
	var n := 0
	for tk in toks:
		n += units_of(tk)
	return n


## Zet de tokens. Is de huidige lijst een prefix van de nieuwe, dan verschijnen de nieuwe met animatie; anders meteen.
func sync(new_tokens: Array, animate := true) -> float:
	var pre := true
	if new_tokens.size() < tokens.size():
		pre = false
	else:
		for i in tokens.size():
			if i == tokens.size() - 1 and tokens[i].has("b") and new_tokens[i].has("b"):
				if not str(new_tokens[i].b).begins_with(str(tokens[i].b)):
					pre = false
			elif tokens[i] != new_tokens[i]:
				pre = false
				break
	var old_units := total_units(tokens)
	tokens = new_tokens.duplicate(true)
	target = float(total_units(tokens))
	if not pre or not animate:
		shown = target
		return 0.0
	shown = minf(shown, float(old_units))
	return (target - shown) * per_unit()


## Voegt tokens toe (write/seal/stamp/number-fx). → duur van het schrijven.
func append(new_toks: Array) -> float:
	var all := tokens.duplicate(true)
	all.append_array(new_toks)
	return sync(all, true)


func per_unit() -> float:
	return (0.04 if not _fast_tokens() else 0.12) * spd


func _fast_tokens() -> bool:
	for tk in tokens:
		if not tk.has("b") and not tk.has("raw"):
			return true
	return false


func clear() -> void:
	tokens = []
	shown = 0.0
	target = 0.0
	consumed = -1
	_off = 0.0


func _process(delta: float) -> void:
	t += delta
	if shown < target:
		var step := delta / maxf(per_unit(), 0.001)
		shown = minf(target, shown + step)
		_writing = 1.0
		var u := int(floor(shown))
		if u != _last_unit:
			_last_unit = u
			_tick_sound(u)
	else:
		_writing = maxf(0.0, _writing - delta * 3.0)
	queue_redraw()


func _tick_sound(u: int) -> void:
	var acc := 0
	for tk in tokens:
		var n := units_of(tk)
		if u <= acc + n and u > acc:
			if tk.has("b"):
				ScSnd.bit(str(tk.b)[clampi(u - acc - 1, 0, n - 1)], -14.0)
			elif tk.has("raw"):
				if u - acc == 1:
					ScSnd.play("wax_seal", -10.0)
			elif tk.has("triple"):
				ScSnd.play("seal_plop", -8.0)
			elif tk.has("code"):
				ScSnd.play("stamp", -8.0)
			elif tk.has("num"):
				ScSnd.play("number_stamp", -10.0)
			return
		acc += n


## Zichtbare tokens (laatste bitstoken eventueel gedeeltelijk).
func visible_tokens() -> Array:
	var out: Array = []
	var left := int(floor(shown + 0.0001))
	for tk in tokens:
		if left <= 0:
			break
		var n := units_of(tk)
		if tk.has("b") and left < n:
			out.append({"b": str(tk.b).substr(0, left)})
			left = 0
			break
		if n > left:
			break
		out.append(tk)
		left -= n
	return out


static func tok_w(tk: Dictionary, size_: int) -> float:
	var bw := ScPal.char_w(size_) + 6.0
	if tk.has("b"):
		return str(tk.b).length() * bw
	if tk.has("raw"):
		return 2 * size_ * 0.68 + 4
	if tk.has("triple"):
		var tr: Array = tk.triple
		var s := "(%d,%d,%s)" % [tr[0], tr[1], ScPal.show(str(tr[2]))]
		return ScPal.text_w(ScPal.MONO_B, s, int(size_ * 0.8)) + size_ * 0.96 + 4
	if tk.has("code"):
		return ScPal.text_w(ScPal.MONO_B, str(tk.code), size_) + size_ * 0.9 + 4
	if tk.has("num"):
		return ScPal.text_w(ScPal.MONO, str(tk.num), size_) + 12
	return 0.0


static func width_of(toks: Array, size_: int) -> float:
	var x := 0.0
	for i in toks.size():
		if i > 0:
			x += 8
		x += tok_w(toks[i], size_)
	return x


## x-positie na `units` eenheden (voor de kokerlijn).
func _x_after_units(toks: Array, units: int) -> float:
	var x := 0.0
	var left := units
	var bw := ScPal.char_w(size) + 6.0
	for i in toks.size():
		var tk: Dictionary = toks[i]
		if i > 0:
			x += 8
		var n := units_of(tk)
		if left <= n:
			if tk.has("b"):
				return x + left * bw
			return x + tok_w(tk, size) * (float(left) / n)
		x += tok_w(tk, size)
		left -= n
	var unit_w := bw
	if not toks.is_empty() and not toks[0].has("b") and not toks[0].has("raw"):
		unit_w = tok_w(toks[toks.size() - 1], size) + 8
	return x + left * unit_w


func _draw() -> void:
	var vis := visible_tokens()
	var total := width_of(vis, size)
	var want := minf(0.0, clip_w - 90.0 - total)
	_off = lerpf(_off, want, 0.2) if absf(_off - want) > 0.5 else want
	var lm := Vector2(20 + _off, 46)
	var koker := -1.0
	if koker_units > 0:
		koker = _x_after_units(tokens, koker_units)
	if consumed >= 0:
		var cx := 0.0
		for i in mini(consumed, tokens.size()):
			if i > 0:
				cx += 8
			cx += tok_w(tokens[i], size)
		ScDraw.shorthand(self, lm, tokens, size, -1.0, t, false)
		if consumed > 0:
			draw_rect(Rect2(Vector2(lm.x - 10, 4), Vector2(cx + 14, 84)), Color(ScPal.VELLUM, 0.62))
		var bx := lm.x + cx + (4 if consumed > 0 else -6)
		draw_line(Vector2(bx, 8), Vector2(bx, 84), ScPal.INFO, 3.0, true)
		ScDraw.drop(self, Vector2(bx, 6), 6, ScPal.INFO, false)
		return
	var endx := ScDraw.shorthand(self, lm, vis, size, koker, t, _writing < 0.1)
	if _writing > 0.05 or shown < target:
		ScDraw.quill(self, Vector2(endx + 16, 42), 0.62, -1.0, t, _writing)
