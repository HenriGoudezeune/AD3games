class_name TxChoice
extends Control
## Finale "Operatie Ekster": kies de machine uit het rek voor dit lint (GDD §5.10). De voorbereiding doe je zelf,
## de doorloop speelt de machine daarna met jouw tabellen.

signal picked(machine: String)

const ICONS := {"kmp": "doorloper", "bmh": "springer", "shift_and": "lampenbord", "shift_and_k": "ruisbord",
	"edit": "zoeklicht", "brute": "sjabloon", "rk": "vingerafdruk"}
const INFO := {"F-1": "LIVE · 2 tekens/s · lusbak B = 1: geen buffer", "F-2": "Ruis: de codewoorden komen verminkt aan",
	"F-3": "Lang lint, groot alfabet · budget 60 machinetijd"}
const TIPS := {"kmp": "leest zonder terug te spoelen", "shift_and": "één lampslag per teken", "bmh": "grote sprongen, maar heeft m tekens buffer nodig",
	"brute": "spoelt terug", "shift_and_k": "M⁰ en M¹: één fout toegelaten", "edit": "vult de tabel automatisch (204 relais)"}

var con: Node
var options: PackedStringArray
var st: Dictionary
var t := 0.0
var sel := 0
var _btns: Array = []


func setup(c: Node, opts: PackedStringArray, stage: Dictionary) -> void:
	con = c
	options = opts
	st = stage


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	TxUi.dimmer(self, 0.6)
	var x := 960.0 - options.size() * 140.0
	for i in options.size():
		var o := str(options[i])
		var b := TxUi.button(str(TxLevels.MACHINE_LABELS.get(o, o)), "brass" if i == 0 else "key", 22, 260)
		b.position = Vector2(x + i * 280, 640)
		var oo := o
		b.pressed.connect(func(): _pick(oo))
		add_child(b)
		_btns.append(b)
	TxSnd.play("crate_open", -6.0)


func key(e: InputEventKey) -> bool:
	if e.keycode >= KEY_1 and e.keycode < KEY_1 + options.size():
		_pick(str(options[e.keycode - KEY_1]))
		return true
	return false


func _pick(o: String) -> void:
	TxSnd.play("stinger_machine", -4.0)
	picked.emit(o)
	queue_free()


func _process(dt: float) -> void:
	t += dt
	queue_redraw()


func _draw() -> void:
	var r := Rect2(200, 180, 1520, 640)
	TxPal.panel(self, r, TxPal.CONSOLE, true, 14)
	var tape := str(st.get("tape", ""))
	TxPal.text_c(self, TxPal.STENCIL, Vector2(960, 236), "OPERATIE EKSTER  ·  LINT %s" % tape, 34, TxPal.BRASS)
	TxPal.text_c(self, TxPal.UI, Vector2(960, 284), str(INFO.get(tape, "")), 24, TxPal.TEXT)
	TxPal.text_c(self, TxPal.TAPE, Vector2(960, 336), "z = %s   ·   %d tekens" % [str(st.get("z", "")), str(st.get("t", "")).length()], 24, TxPal.TEXT_DIM)
	TxPal.text_c(self, TxPal.UI, Vector2(960, 384), "Kies de machine uit het rek. Jij doet de voorbereiding, de machine de doorloop.", 22, TxPal.TEXT_DIM)
	var x := 960.0 - options.size() * 140.0
	for i in options.size():
		var o := str(options[i])
		var c := Vector2(x + i * 280 + 130, 500)
		TxPal.well(self, Rect2(c - Vector2(110, 80), Vector2(220, 130)), TxPal.CONSOLE_LO, 10)
		TxDraw.icon(self, str(ICONS.get(o, "tik")), c + Vector2(0, -24), 64, TxPal.BRASS_HI)
		TxPal.text_c(self, TxPal.UI, c + Vector2(0, 30), str(TIPS.get(o, "")).substr(0, 28), 15, TxPal.TEXT_DIM)
		TxDraw.keycap(self, c + Vector2(-12, 186), str(i + 1), 16)
