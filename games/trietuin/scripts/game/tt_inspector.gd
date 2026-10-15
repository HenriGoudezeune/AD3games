class_name TtInspector
extends Control
## Inspecteur Egel (§3.3): stapt binnen linksonder, stelt zijn vraag in een ballon en reageert
## (blij / boos / verbaasd). Puur weergave; de vraag zelf zit in de kaart (TtCard.q, word).

var text := ""
var letters := "acgt_"
var x := -200.0
var mood := 0
var t := 0.0
var _a := 0.0
var _stamp := 0.0
var _stamp_ok := true
var patience := -1.0   # 0..1 (4-4)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func arrive(q: String, alpha: String) -> void:
	text = q
	letters = alpha
	mood = 1
	visible = true
	if x < 0:
		x = -200.0
		var tw := create_tween()
		tw.tween_property(self, "x", 170.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_a = 0.0
	create_tween().tween_property(self, "_a", 1.0, 0.25).set_delay(0.3)


func react(ok: bool) -> void:
	mood = 2 if ok else 3
	_stamp_ok = ok
	_stamp = 1.0
	create_tween().tween_property(self, "_stamp", 0.0, 1.2).set_delay(0.6)


func leave_if_done(done: bool) -> void:
	if not done or not visible:
		return
	var tw := create_tween()
	tw.tween_property(self, "_a", 0.0, 0.2)
	tw.tween_property(self, "x", -220.0, 0.45).set_ease(Tween.EASE_IN)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	if x < -150:
		return
	var feet := Vector2(x, 852)
	TtDraw.dog(self, feet + Vector2(150, 2), 0.85, t, 1.0, 1 if mood == 2 else (2 if mood == 3 else 0))
	TtDraw.hedgehog(self, feet, 1.0, t, 1.0, mood)
	if _a > 0.01 and text != "":
		var parts := _parts(text)
		var w := TtPal.rich_line(self, Vector2.ZERO, parts, 26, TtPal.INK, true, letters, true)
		var r := Rect2(x + 90, 700, w + 44, 64)
		TtDraw.bubble(self, r, feet + Vector2(60, -100), Color(TtPal.PAPER, _a))
		TtPal.rich_line(self, Vector2(r.position.x + 22, r.get_center().y - 2), parts, 26, Color(TtPal.INK, _a), true, letters)
		if patience >= 0.0:
			var pr := Rect2(r.position.x + 16, r.end.y - 12, (r.size.x - 32), 8)
			draw_style_box(TtPal.sb(Color(TtPal.INK, 0.15), 4), pr)
			var col := TtPal.OK.lerp(TtPal.ERR, 1.0 - patience)
			draw_style_box(TtPal.sb(col, 4), Rect2(pr.position, Vector2(pr.size.x * patience, pr.size.y)))
	if _stamp > 0.01:
		var a := minf(_stamp * 2.0, 1.0)
		if _stamp_ok:
			TtDraw.stamp(self, Vector2(x + 60, 630), "OPGELOST", 34, -0.18, a)
		else:
			TtPal.text_outline_c(self, TtPal.UI_BOLD, Vector2(x + 60, 630), "hmm…", 34, Color(TtPal.TEXT, a), 8, TtPal.OUTLINE)


## "Komt cac voor?" -> mono voor het woord tussen de spaties dat in het alfabet past.
func _parts(s: String) -> Array:
	var out := []
	for w in s.split(" "):
		var core := w.trim_suffix("?").trim_suffix(".").trim_suffix(",")
		var is_word := core.length() > 0
		for ch in core:
			if not letters.contains(ch):
				is_word = false
		if is_word and core.length() >= 1 and core != "Van" and core.length() < 20 and core.to_lower() == core and _looks_dna(core):
			out.append([core, "mono"])
			out.append([w.substr(core.length()) + " ", "ui"])
		else:
			out.append([w + " ", "ui"])
	return out


func _looks_dna(s: String) -> bool:
	for ch in s:
		if not "acgt_".contains(ch):
			return false
	return true
