class_name ScView
extends Node2D
## Basis van de werktuig-weergaven op de werkbank (en, verkleind en alleen-lezen, in de herbeleving van het Kapittel).
## Een weergave tekent de toestand van haar werktuig uit de laatst bevestigde cursor (`cur`; de core geeft die mee met
## phase_changed) en speelt de animatiebeschrijvingen (`changed(fx)`) af die de werkbank in volgorde doorgeeft.
## Input: klikzones die tijdens het tekenen geregistreerd worden (`zone(rect, move)`); hover, toetsenbordselectie
## (←/→ + Enter) en de inkthand (spookhand) zitten hier. Zetten gaan als signaal `request` naar de werkbank.

signal request(move: Dictionary)
signal say(text: String)

const AREA := Rect2(0, 200, 1260, 680)   # de werkbank (GDD §4.3)

var tool: ScTool
var spec: ScLevelSpec
var stage: Dictionary = {}
var cur: Dictionary = {}
var prev: Dictionary = {}
var k := 1.0                    # overgang prev → cur (0..1)
var t := 0.0
var zones: Array = []
var _zprev: Array = []
var hover := -1
var sel := -1
var locked := false
var readonly := false
var alphabet := ""
var guides := false
var tutorial := false
var ghost: Dictionary = {}
var ghost_a := 0.0
var spd := 1.0
var fx_root: Node
var ov: Dictionary = {}
var last_move: Dictionary = {}
var _shake := 0.0
var _mouse := Vector2(-999, -999)
var _anims: Array = []          # [{key, t0, dur}] voor eenvoudige tijdsanimaties


func setup(t_: ScTool, cursor0: Dictionary, spec_: ScLevelSpec = null) -> void:
	tool = t_
	spec = spec_
	stage = tool.stage
	cur = cursor0.duplicate(true)
	prev = cur
	k = 1.0
	_setup()


func _setup() -> void:
	pass


## Nieuwe cursor (na phase_changed): de weergave glijdt van de vorige naar de nieuwe toestand.
func commit(c: Dictionary) -> void:
	prev = cur
	cur = c.duplicate(true)
	k = 0.0
	var tw := create_tween()
	tw.tween_property(self, "k", 1.0, commit_time()).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_on_commit()


func commit_time() -> float:
	return 0.35 * spd


func _on_commit() -> void:
	pass


## Speelt één animatiebeschrijving af. → seconden die de werkbank wacht vóór de volgende.
func play(fx: Dictionary) -> float:
	match str(fx.get("fx", "")):
		"bump":
			return _bump(fx)
	return 0.0


func _bump(fx: Dictionary) -> float:
	ScSnd.play("clamp", -4.0)
	var p := anchor(last_move) if not last_move.is_empty() else AREA.get_center()
	if fx_root:
		ScFx.dust_puff(fx_root, p)
	_shake = 1.0
	var r := str(fx.get("reason", ""))
	var line := bump_line(r, fx)
	if line != "":
		say.emit(line)
	return 0.25


## Korte uitleg bij een klem (≤ 12 woorden). Subklassen vullen aan.
func bump_line(reason: String, _fx: Dictionary) -> String:
	match reason:
		"unreadable":
			return "De strook is onleesbaar geworden."
		"same":
			return "Een stapel bind je niet met zichzelf."
	return ""


## Ankerpunt van een zet (inkthand, klemstof). Subklassen.
func anchor(_move: Dictionary) -> Vector2:
	return AREA.get_center()


## Contextknoppen onderaan: [{text, move, kind, key}] (key = sneltoets-label).
func buttons() -> Array:
	return []


## Sneltoetsen van het werktuig → zet ({} = niets).
func key_move(_ev: InputEventKey) -> Dictionary:
	return {}


## Opdrachtband: {text, cursor, done, label, chips}.
func band() -> Dictionary:
	return {}


## Kortschrift-strook: {tokens, consumed (ontvangen: al gelezen tokens), unit: "bits"|"zegels"|"stempels"|""}.
func strip() -> Dictionary:
	return {"tokens": [], "consumed": -1, "unit": ""}


## Tokens die een write-achtige fx aan de strook toevoegt.
func fx_tokens(fx: Dictionary) -> Array:
	return fx.get("tokens", [])


## De Overkant: miniatuur van de structuur van Letterlijk (zenden) of het notasvoorbeeld.
func draw_overkant(_ci: CanvasItem, _r: Rect2) -> void:
	pass


func set_overkant(state: Dictionary) -> void:
	ov = state.duplicate(true)


func overkant_copy() -> String:
	return str(ov.get("text", ""))


# ------------------------------------------------------------------ tekenen en zones

func _process(delta: float) -> void:
	t += delta
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 4.0)
	queue_redraw()


func _draw() -> void:
	_zprev = zones
	zones = []
	if _shake > 0.0:
		var s := ScSession.shake_scale() * 3.0 * _shake
		draw_set_transform(Vector2(sin(t * 90.0) * s, cos(t * 70.0) * s * 0.5))
	_paint()
	draw_set_transform(Vector2.ZERO)
	_update_hover()
	if not readonly and sel >= 0 and sel < _kbd().size():
		var z: Dictionary = _kbd()[sel]
		ScPal.ring(self, (z.r as Rect2).grow(5), 10, Color(ScPal.INFO, 0.6 + 0.3 * sin(t * 7.0)), 3)
	if not ghost.is_empty() and ghost_a > 0.01:
		var a := anchor(ghost)
		var press := clampf(sin(t * 3.0) * 1.4, 0.0, 1.0)
		ScDraw.inkhand(self, a + Vector2(6, 8), 0.9, t, 0.62 * ghost_a, press)


func _paint() -> void:
	pass


## Registreert een klikzone (in tekenvolgorde; latere zones liggen bovenop). kbd = bereikbaar met ←/→.
func zone(r: Rect2, move: Dictionary, kbd := true) -> void:
	zones.append({"r": r, "m": move, "kbd": kbd})


func _kbd() -> Array:
	var out: Array = []
	for z in zones:
		if z.kbd:
			out.append(z)
	return out


func _update_hover() -> void:
	hover = -1
	if readonly or locked:
		return
	for i in range(zones.size() - 1, -1, -1):
		if (zones[i].r as Rect2).has_point(_mouse):
			hover = i
			return


## De zet onder de muis (of de toetsenbordselectie), {} als er geen is. Bruikbaar in _paint (vorige frame).
func hover_move() -> Dictionary:
	var zl := _zprev
	for i in range(zl.size() - 1, -1, -1):
		if (zl[i].r as Rect2).has_point(_mouse):
			return zl[i].m
	if sel >= 0:
		var kz: Array = []
		for z in zl:
			if z.kbd:
				kz.append(z)
		if sel < kz.size():
			return kz[sel].m
	return {}


func is_hover(m: Dictionary) -> bool:
	return not readonly and not locked and not m.is_empty() and hover_move() == m


func is_ghost(m: Dictionary) -> bool:
	return not ghost.is_empty() and ghost_a > 0.3 and ghost == m


## Input vanuit de werkbank. → true als de weergave het event gebruikte.
func handle(ev: InputEvent) -> bool:
	if readonly:
		return false
	if ev is InputEventMouseMotion:
		_mouse = (ev as InputEventMouseMotion).position
		if (ev as InputEventMouseMotion).relative.length() > 2.0:
			sel = -1
		return false
	if locked:
		return false
	if ev is InputEventMouseButton and ev.pressed:
		var mb := ev as InputEventMouseButton
		_mouse = mb.position
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_update_hover()
			if hover >= 0:
				var m: Dictionary = zones[hover].m
				if not m.is_empty():
					_click(m)
				return true
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			return _right_click(mb.position)
		return false
	if ev is InputEventKey and ev.pressed:
		var ke := ev as InputEventKey
		var kz := _kbd()
		match ke.keycode:
			KEY_LEFT, KEY_UP:
				if kz.size() > 0 and _arrows_ok(ke.keycode):
					sel = (sel - 1 + kz.size()) % kz.size() if sel >= 0 else kz.size() - 1
					ScSnd.play("ui_wood", -14.0)
					return true
			KEY_RIGHT, KEY_DOWN:
				if kz.size() > 0 and _arrows_ok(ke.keycode):
					sel = (sel + 1) % kz.size() if sel >= 0 else 0
					ScSnd.play("ui_wood", -14.0)
					return true
			KEY_ENTER, KEY_KP_ENTER:
				if sel >= 0 and sel < kz.size():
					_click(kz[sel].m)
					return true
		var m2 := key_move(ke)
		if not m2.is_empty():
			_click(m2)
			return true
	return false


func _arrows_ok(_code: int) -> bool:
	return true


## Klik op een zone: standaard meteen een zet. Subklassen (binderij: eerst selecteren) overschrijven.
func _click(m: Dictionary) -> void:
	if m.has("_local"):
		_local(m)
		return
	request.emit(m)


func _local(_m: Dictionary) -> void:
	pass


func _right_click(_p: Vector2) -> bool:
	return false


# ------------------------------------------------------------------ hulpjes

func lerpv(a: Vector2, b: Vector2) -> Vector2:
	return a.lerp(b, k)


static func ease_out(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)


## Start een benoemde tijdsanimatie; anim(key) geeft 0..1 (1 = af of nooit gestart).
func start_anim(key: String, dur: float) -> void:
	for a in _anims:
		if a.key == key:
			_anims.erase(a)
			break
	_anims.append({"key": key, "t0": t, "dur": maxf(dur, 0.001)})


func anim(key: String) -> float:
	for a in _anims:
		if a.key == key:
			return clampf((t - float(a.t0)) / float(a.dur), 0.0, 1.0)
	return 1.0


func anim_running(key: String) -> bool:
	var v := anim(key)
	return v < 1.0 and _has_anim(key)


func _has_anim(key: String) -> bool:
	for a in _anims:
		if a.key == key:
			return true
	return false


func burst_at(kind: String, p: Vector2) -> void:
	if fx_root == null:
		return
	match kind:
		"ink":
			ScFx.ink_flick(fx_root, p)
		"wax":
			ScFx.wax_splat(fx_root, p)
		"wax_green":
			ScFx.wax_splat(fx_root, p, ScPal.WAX_GREEN)
		"twine":
			ScFx.twine_knot(fx_root, p)
		"snip":
			ScFx.snip(fx_root, p)
		"shavings":
			ScFx.shavings(fx_root, p, 7)
		"dust":
			ScFx.dust_puff(fx_root, p)
		"gold":
			ScFx.ring_wave(fx_root, p, ScPal.GOLD, 0.2, 1.6, 0.4)
		"splash":
			ScFx.ink_splash(fx_root, p)


## Titel van de werkbank-zone (klein kopje linksboven).
func caption(text: String, sub := "", pos := Vector2(24, 214)) -> void:
	var w := ScPal.text_w(ScPal.TITLE, text, 26) + (ScPal.text_w(ScPal.UI_MED, sub, 18) + 22 if sub != "" else 0.0) + 36
	var r := Rect2(pos, Vector2(w, 40))
	draw_style_box(ScPal.sb(Color(ScPal.PANEL, 0.9), 20, 8, Vector2(0, 4)), r)
	ScPal.ring(self, r.grow(-4), 16, Color(ScPal.GILT, 0.55), 1)
	var x := ScPal.text_l(self, ScPal.TITLE, pos + Vector2(18, 20), text, 26, ScPal.GILT_LIGHT)
	if sub != "":
		ScPal.text_l(self, ScPal.UI_MED, pos + Vector2(18 + x + 16, 21), sub, 18, ScPal.TEXT_DIM)


## Label op het tafelblad (leesbaar op hout).
func table_label(p: Vector2, s: String, size := 20, col := ScPal.TEXT, center := false) -> void:
	var f := ScPal.UI_MED
	var w := ScPal.text_w(f, s, size)
	var r := Rect2(Vector2(p.x - (w / 2 if center else 0.0) - 10, p.y - size * 0.75), Vector2(w + 20, size * 1.5))
	draw_style_box(ScPal.sb(Color(ScPal.PANEL_LO, 0.78), int(size * 0.6)), r)
	if center:
		ScPal.text_c(self, f, p, s, size, col)
	else:
		ScPal.text_l(self, f, p, s, size, col)
