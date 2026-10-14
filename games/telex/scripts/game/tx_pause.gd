class_name TxPause
extends Control
## Pauze (GDD §4.2): Verder · Opnieuw · Notas (spiekbriefje) · Instellingen · Missiekaart. Esc = verder.
## Het lint staat stil zolang de pauze open is (de console tikt de director niet).

signal closed

var con: Node
var sub: Control = null
var _col: VBoxContainer


func setup(c: Node) -> void:
	con = c


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	TxUi.dimmer(self, 0.7)
	var pnl := PanelContainer.new()
	pnl.add_theme_stylebox_override("panel", TxPal.panel_box(TxPal.CONSOLE, 14))
	pnl.position = Vector2(720, 230)
	pnl.custom_minimum_size = Vector2(480, 0)
	add_child(pnl)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 14)
	pnl.add_child(_col)
	var ttl := TxUi.label("PAUZE", 40, TxPal.BRASS, TxPal.STENCIL)
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_col.add_child(ttl)
	var items := [["Verder", "brass", close], ["Opnieuw", "key", func(): con.restart()],
		["Notas", "key", _notes], ["Instellingen", "key", _settings], ["Missiekaart", "key", func(): con.to_map()]]
	for it in items:
		var b := TxUi.button(str(it[0]), str(it[1]), 28, 420)
		b.pressed.connect(it[2])
		_col.add_child(b)
	var keys := TxUi.label("F1 hint · Ctrl+Z terugnemen · Esc pauze", 18, TxPal.TEXT_DIM)
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_col.add_child(keys)
	TxUi.pop_in(pnl)
	TxSnd.play("relay", -6.0)


func key(e: InputEventKey) -> bool:
	if sub != null:
		if e.keycode == KEY_ESCAPE:
			sub.queue_free()
			sub = null
			return true
		if sub.has_method("key"):
			return sub.key(e)
		return false
	if e.keycode == KEY_ESCAPE:
		close()
		return true
	return false


func close() -> void:
	closed.emit()
	queue_free()


func _notes() -> void:
	sub = TxCheatSheet.new()
	add_child(sub)
	sub.tree_exited.connect(func(): sub = null)


func _settings() -> void:
	sub = TxSettings.new()
	add_child(sub)
	sub.tree_exited.connect(func(): sub = null)
