extends CanvasLayer
## Autoload "HubNav" (design/SHARED_UX.md §1): een klein huisje-knopje "Speelhal" linksboven op elke scène
## behalve de hub, plus sneltoets Ctrl+H. Buiten een level gaat het meteen naar de hub; in een level vraagt
## een klein venster eerst om bevestiging: [Naar speelhal] [Naar levelkeuze] [Verder spelen].
##
## Een scène meldt zich (typisch in _ready) met
##   HubNav.set_context({"in_level": true, "level_select_scene": "res://...", "on_leave": Callable,
##                       "corner_offset": Vector2(0, 70)})
## Alle sleutels zijn optioneel. De context hoort bij de huidige scène en vervalt vanzelf bij een scènewissel.
## Pauzemenu's gebruiken go_hub() / go_level_select() voor hun knoppen "Naar speelhal" / "Naar levelkeuze".
## Geen afhankelijkheid van game-specifieke klassen.

const HUB_SCENE := "res://scenes/hub.tscn"   # = HubRegistry.HUB_SCENE
const BASE_POS := Vector2(16, 16)
const FONT_PATH := "res://assets/fonts/Fredoka-Bold.ttf"
const FONT_TEXT_PATH := "res://assets/fonts/Fredoka-SemiBold.ttf"

## Standaardpositie per scène (verschuiving t.o.v. linksboven) waar het huisje anders over bestaande HUD valt.
## Een scène kan dit zelf overschrijven met set_context({"corner_offset": ...}).
## (Fase 1: gemeten met frame-opnames; huisje ≈ 142×40 px.)
const SCENE_OFFSETS := {
	"res://games/trietuin/scenes/season_map.tscn": Vector2(464, 24),     # naast "Seizoenkaart" (← Titel staat linksboven)
	"res://games/trietuin/scenes/garden.tscn": Vector2(0, 100),          # onder de kopbalk (pauzeknop linksboven)
	"res://games/telex/scenes/map.tscn": Vector2(1340, -12),             # in de kopbalk, links van de sterren
	"res://games/telex/scenes/console.tscn": Vector2(984, -11),          # in de kopbalk, links van de tikteller
	"res://games/scriptorium/scenes/book.tscn": Vector2(204, 8),         # naast "← Titel"
	"res://games/scriptorium/scenes/workbench.tscn": Vector2(1190, 2),   # in de kopbalk, links van de tellers
}

const C_BTN := Color("#28334F")
const C_BTN_HI := Color("#34416A")
const C_TEXT := Color("#F4F1EA")
const C_DIM := Color("#8D97B5")
const C_OK := Color("#3DDC97")
const C_WARN := Color("#FFB020")
const C_INK := Color("#1A1F2E")
const C_PANEL := Color("#1F2840")

var _ctx: Dictionary = {}
var _ctx_scene: Node = null
var _last_scene: Node = null
var _btn: Button
var _dialog: Control
var _was_paused := false
var _font: Font
var _font_text: Font
var _disabled := false     # "-- --no-hubnav" (vergelijkende schermopnames)


func _ready() -> void:
	layer = 95                       # boven elke game-HUD, onder Transition (100)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_disabled = OS.get_cmdline_user_args().has("--no-hubnav")
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)
	if ResourceLoader.exists(FONT_TEXT_PATH):
		_font_text = load(FONT_TEXT_PATH)
	_btn = _make_button("Speelhal", C_BTN, C_TEXT, 20)
	_btn.tooltip_text = "Terug naar de speelhal (Ctrl+H)"
	_btn.add_theme_constant_override("icon_max_width", 22)
	_btn.icon = _house_icon()
	_btn.expand_icon = false
	_btn.focus_mode = Control.FOCUS_NONE
	_btn.pressed.connect(request_home)
	_btn.visible = false
	add_child(_btn)


# ======================================================================
#  publieke API
# ======================================================================

## Meldt de huidige scène aan. Sleutels: in_level (bool), level_select_scene (String),
## on_leave (Callable, wordt opgeroepen vlak voor het verlaten), corner_offset (Vector2, verschuift het huisje),
## hidden (bool, huisje verbergen op deze scène).
func set_context(ctx: Dictionary) -> void:
	_ctx = ctx.duplicate()
	_ctx_scene = _scene()
	_update_button()


func clear_context() -> void:
	_ctx = {}
	_ctx_scene = null
	_update_button()


func in_level() -> bool:
	return bool(_ctx.get("in_level", false))


## Het huisje (of de bevestiging in een level), zoals een klik op de knop.
func request_home() -> void:
	if _dialog or not _btn.visible:
		return
	if in_level():
		_open_dialog()
	else:
		go_hub()


## Meteen naar de speelhal (zonder vragen). Voor pauzemenu's.
func go_hub() -> void:
	_leave(HUB_SCENE)


## Meteen naar de levelkeuze uit de context (zonder vragen); zonder levelkeuze naar de hub.
func go_level_select() -> void:
	var p := str(_ctx.get("level_select_scene", ""))
	_leave(p if p != "" else HUB_SCENE)


## Rechthoek van het huisje in canvascoördinaten (voor overlap-checks).
func button_rect() -> Rect2:
	return Rect2(_btn.position, _btn.size)


# ======================================================================
#  intern
# ======================================================================

func _scene() -> Node:
	return get_tree().current_scene if is_inside_tree() else null


func _process(_d: float) -> void:
	var cur := _scene()
	if cur != _last_scene:
		_last_scene = cur
		if _ctx_scene != null and (not is_instance_valid(_ctx_scene) or _ctx_scene != cur):
			_ctx = {}
			_ctx_scene = null
		if _dialog and cur != null:
			_close_dialog(false)
		_update_button()


func _update_button() -> void:
	var cur := _scene()
	var path := cur.scene_file_path if cur != null else ""
	var show := path != "" and path != HUB_SCENE and not bool(_ctx.get("hidden", false)) and not _disabled
	_btn.visible = show
	var off: Vector2 = _ctx.get("corner_offset", SCENE_OFFSETS.get(path, Vector2.ZERO))
	_btn.position = BASE_POS + off
	_btn.reset_size()


func _input(ev: InputEvent) -> void:
	if not (ev is InputEventKey and ev.pressed and not ev.echo):
		return
	var k := ev as InputEventKey
	if _dialog:
		if k.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_close_dialog(true)
		return
	if k.keycode == KEY_H and k.ctrl_pressed and _btn.visible:
		get_viewport().set_input_as_handled()
		request_home()


func _leave(path: String) -> void:
	var cb = _ctx.get("on_leave", null)
	if cb is Callable and (cb as Callable).is_valid():
		(cb as Callable).call()
	if _dialog:
		_close_dialog(false)
	_ctx = {}
	_ctx_scene = null
	get_tree().paused = false
	Engine.time_scale = 1.0
	# gebruik de scène-overgang van het project als die er is (duck typing, geen klasse-afhankelijkheid)
	var tr := get_node_or_null("/root/Transition")
	if tr and tr.has_method("goto"):
		tr.goto(path)
	else:
		get_tree().change_scene_to_file(path)


func _open_dialog() -> void:
	_was_paused = get_tree().paused
	get_tree().paused = true
	_dialog = Control.new()
	_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dialog)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.08, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.add_child(cc)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_PANEL
	sb.set_corner_radius_all(22)
	sb.border_color = C_WARN
	sb.border_width_top = 8
	sb.set_content_margin_all(32)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 14
	panel.add_theme_stylebox_override("panel", sb)
	cc.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	box.add_child(_label("Level verlaten?", 40, C_TEXT, _font))
	box.add_child(_label("Je voortgang in dit level gaat verloren.", 24, C_DIM, _font_text))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	var b_hub := _make_button("Naar speelhal", C_BTN_HI, C_TEXT, 24)
	b_hub.pressed.connect(go_hub)
	row.add_child(b_hub)
	if str(_ctx.get("level_select_scene", "")) != "":
		var b_sel := _make_button("Naar levelkeuze", C_BTN_HI, C_TEXT, 24)
		b_sel.pressed.connect(go_level_select)
		row.add_child(b_sel)
	var b_go := _make_button("Verder spelen", C_OK, C_INK, 24)
	b_go.pressed.connect(func(): _close_dialog(true))
	row.add_child(b_go)
	b_go.grab_focus.call_deferred()
	panel.pivot_offset = Vector2(300, 100)
	panel.scale = Vector2(0.9, 0.9)
	var tw := panel.create_tween().set_ignore_time_scale(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _close_dialog(restore_pause: bool) -> void:
	if _dialog:
		_dialog.queue_free()
		_dialog = null
	if restore_pause:
		get_tree().paused = _was_paused


func _label(t: String, size: int, col: Color, f: Font) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if f:
		l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


func _box(col: Color, lift := 0.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(14)
	s.border_color = col.darkened(0.35)
	s.border_width_bottom = int(4 - lift)
	s.content_margin_left = 16
	s.content_margin_right = 18
	s.content_margin_top = 6 + lift
	s.content_margin_bottom = 6
	s.shadow_color = Color(0.02, 0.03, 0.08, 0.35)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 3)
	return s


func _make_button(t: String, col: Color, fg: Color, size: int) -> Button:
	var b := Button.new()
	b.text = t
	if _font:
		b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", size)
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(st, fg)
	for st in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		b.add_theme_color_override(st, fg)
	b.add_theme_stylebox_override("normal", _box(col))
	b.add_theme_stylebox_override("hover", _box(col.lightened(0.1), 2))
	b.add_theme_stylebox_override("pressed", _box(col.darkened(0.1), -2))
	var f := _box(col.lightened(0.1), 2)
	f.border_color = Color("#4CC9F0")
	f.set_border_width_all(3)
	b.add_theme_stylebox_override("focus", f)
	b.add_theme_constant_override("h_separation", 8)
	return b


## Klein wit huisje (22×20) als icoon; de knop kleurt het via icon_*_color.
func _house_icon() -> Texture2D:
	var w := 22
	var h := 20
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var on := false
			if y < 10:
				# dak: driehoek met top (11, 0) en basis y = 9 over de volle breedte
				var half := (y + 1) * 1.1
				on = absf(x + 0.5 - 11.0) <= half
			else:
				on = x >= 3 and x <= 18
				# deur
				if y >= 13 and x >= 9 and x <= 12:
					on = false
			if on:
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)
