class_name ScPause
extends Control
## Pauze (GDD §4.2): Verder · Opnieuw · Notas · Instellingen · Kaart, plus een kaartje met alle toetsen.
## Nachtwake: Verder · Stoppen (score bewaren) · Titel.

signal action(a: String)

var spec: ScLevelSpec
var wake := false
var _box: VBoxContainer
var _child: Control
var _keys: Node2D


func setup(s: ScLevelSpec, w := false) -> void:
	spec = s
	wake = w


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.015, 0.01, 0.62)
	dim.size = size
	add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ScUi.panel_box())
	panel.position = Vector2(300, 220)
	add_child(panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 14)
	panel.add_child(_box)
	_box.add_child(ScUi.title_label("Pauze", 56))
	var sub := ScUi.label("%s · %s" % [spec.id, spec.title] if not wake else "Nachtwake", 22, ScPal.TEXT_DIM)
	_box.add_child(sub)
	var items := []
	if wake:
		items = [["Verder", "resume", ScUi.Kind.PRIMARY], ["Stoppen en score bewaren", "stop", ScUi.Kind.WAX],
			["Notas", "notes", ScUi.Kind.SECONDARY], ["Instellingen", "settings", ScUi.Kind.SECONDARY],
			["Naar de titel", "map", ScUi.Kind.GHOST]]
	else:
		items = [["Verder", "resume", ScUi.Kind.PRIMARY], ["Opnieuw", "retry", ScUi.Kind.SECONDARY],
			["Notas", "notes", ScUi.Kind.SECONDARY], ["Instellingen", "settings", ScUi.Kind.SECONDARY],
			["Getijdenboek", "map", ScUi.Kind.GHOST]]
	for it in items:
		var b := ScUi.button(it[0], it[2], 28, 420)
		var a: String = it[1]
		b.pressed.connect(func(): _do(a))
		_box.add_child(b)
	_box.get_child(2).grab_focus.call_deferred()
	_keys = Node2D.new()
	_keys.draw.connect(_draw_keys)
	add_child(_keys)
	ScSnd.play("page_turn", -8.0)


func _do(a: String) -> void:
	match a:
		"notes":
			_child = ScCheatSheet.new()
			(_child as ScCheatSheet).setup(spec.id if not wake else "nachtwake", "")
			add_child(_child)
			_child.closed.connect(func(): _child = null)
		"settings":
			_child = ScSettings.new()
			add_child(_child)
			_child.closed.connect(func(): _child = null)
		_:
			action.emit(a)
			queue_free()


func _unhandled_input(ev: InputEvent) -> void:
	if _child != null:
		return
	if ev is InputEventKey and ev.pressed and not ev.echo and (ev as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_do("resume")


func _draw_keys() -> void:
	var c := _keys
	var r := Rect2(900, 220, 720, 640)
	ScDraw.parchment(c, r, 23, ScPal.VELLUM, true, 0.6)
	ScPal.text_l(c, ScPal.TITLE, r.position + Vector2(36, 50), "Toetsen", 40, ScPal.RUBRIC)
	var rows := [["klikken", "blad, stapel, monnik, vak, letter, rij, blokje"], ["← → ↑ ↓ + Enter", "kiezen met het toetsenbord"],
		["Spatie", "binderij: markeren/binden · kopiist sneller (ingedrukt)"], ["B", "levende boom: blijf staan"],
		["1 / 0", "binaire naald: stap / blijf"], ["G", "leesraam: geen match"], ["V / S", "stempelkast: verleng / stempel"],
		["cijfers", "letterplank: getal stempelen · snijbank: letter"], ["R", "codebord: opnieuw lezen"],
		["F1", "Zeno's inkthand (kost ★★★)"], ["Ctrl+Z", "zet terugnemen (kost ★★★)"], ["Esc", "pauze"]]
	var y := r.position.y + 110
	for row in rows:
		ScPal.text_l(c, ScPal.MONO_B, Vector2(r.position.x + 40, y), row[0], 22, ScPal.INK)
		ScPal.text_l(c, ScPal.UI, Vector2(r.position.x + 250, y), row[1], 21, ScPal.INK)
		y += 41
