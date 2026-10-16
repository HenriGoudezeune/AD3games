class_name TtPauseMenu
extends Control
## Pauze (GDD §4.2, design/SHARED_UX.md §1): Verder · Opnieuw · Uitleg & theorie · Notas (spiekbriefje) ·
## Instellingen · Naar levelkeuze · Naar speelhal.
## `closed(choice)`: "resume" | "restart" | "map" | "hub". `guide_requested`: de tuin opent de gids (F1) bovenop.

signal closed(choice: String)
signal guide_requested

var level_id := ""
var season := 0
var _panel: PanelContainer
var _sub: Control
var _box: VBoxContainer
var _done := false


func setup(level: String, season_: int) -> void:
	level_id = level
	season = season_


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = TtUi.theme()
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.06, 0.04, 0.0)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	dim.create_tween().tween_property(dim, "color:a", 0.72, 0.2)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", TtUi.panel_box())
	add_child(_panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 14)
	_panel.add_child(_box)
	var t := TtUi.label("PAUZE", 56, TtPal.TEXT, TtPal.UI_BOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(t)
	var sub := TtUi.label("%s · %s" % [TtSession.season_name(season), level_id], 22, TtPal.TEXT_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(sub)
	_add("Verder", TtUi.Kind.PRIMARY, func(): _close("resume"))
	_add("Opnieuw", TtUi.Kind.SECONDARY, func(): _close("restart"))
	_add("Uitleg & theorie  (F1)", TtUi.Kind.SECONDARY, func(): guide_requested.emit())
	_add("Notas (spiekbriefje)", TtUi.Kind.SAP, _sheet)
	_add("Instellingen", TtUi.Kind.SECONDARY, _settings)
	_add("Naar levelkeuze", TtUi.Kind.GHOST, func(): _close("map"))
	_add("Naar speelhal", TtUi.Kind.GHOST, func(): _close("hub"))
	_panel.reset_size()
	_panel.position = Vector2(960, 540) - _panel.size / 2.0
	TtUi.pop_in(_panel, 0.0, 0.25)
	(_box.get_child(2) as Button).grab_focus.call_deferred()
	if TtSession.has("sheet"):
		_sheet.call_deferred()


func _add(txt: String, kind: int, cb: Callable) -> void:
	var b := TtUi.button(txt, kind, 30, 420)
	b.pressed.connect(cb)
	_box.add_child(b)


func _sheet() -> void:
	if _sub:
		return
	var cs := TtCheatSheet.new()
	cs.setup(season, mini(season, 4))
	_sub = cs
	add_child(cs)
	_panel.visible = false
	cs.closed.connect(func():
		_sub = null
		_panel.visible = true)


func _settings() -> void:
	if _sub:
		return
	var st := TtSettings.new()
	_sub = st
	add_child(st)
	_panel.visible = false
	st.closed.connect(func():
		_sub = null
		_panel.visible = true)


func _close(choice: String) -> void:
	if _done:
		return
	_done = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.14)
	tw.tween_callback(func():
		closed.emit(choice)
		queue_free())


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and (ev as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if _sub == null:
			_close("resume")
	elif ev is InputEventKey and ev.pressed and not ev.echo and (ev as InputEventKey).keycode == KEY_F1:
		get_viewport().set_input_as_handled()
		if _sub == null:
			guide_requested.emit()
