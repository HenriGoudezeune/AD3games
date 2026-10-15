class_name TtWorkbench
extends Control
## Werkbank onderaan de tuin (GDD §4.3): de actieve kaart links, het lint in het midden (woordlint met indices,
## vergelijkingslint, hoplint, slingerstuk, vraagkaart) en de contextknoppen rechts. Klikken op een lintcel geeft
## `cell_clicked(row, i)`; knoppen geven `action(id)`.

signal cell_clicked(row: String, i: int)
signal action(id: String)

const AREA := Rect2(16, 864, 1888, 200)
const RIB_X0 := 330.0
const RIB_X1 := 1400.0

var mode := ""               # "" | word | compare | hop | answer | ternary | place | prune | cut | suffix | label | ask | ukkonen | bloom | info
var card_kind := ""          # seed | bee | wasp | prune | patricify | ternarify | suffix | ask | ukkonen | beds
var card_word := ""
var letters := "ACGT_"
var season := 0
var word := ""               # lint (rij 1)
var word2 := ""              # vergelijkingslint: rij 2 (het nieuwe woord / gezochte woord)
var d := 0                   # al gelezen tot d (exclusief)
var cursor := -1             # toetsenbordcursor (kolom)
var hint := 0                # TtCodes.Hint
var read_hint := -1          # te lezen positie (FULL/CURSOR)
var ghost_from := -1         # Patricia: overgeslagen
var ghost_to := -1
var chosen := -1
var row_names := ["", ""]
var title := ""              # zin boven het lint
var title_parts: Array = []  # rich_line-onderdelen (wint van title)
var subtitle := ""
var index_base := 0          # suffix: eerste index die onder het lint staat
var index_offset := 0        # suffix: de posities onder het lint = index_offset + i
var place_letters: Array = []
var ball_letter := ""
var cmp_letter := ""
var numpad := false
var num_value := ""
var t := 0.0
var shake := 0.0
var hover_col := -1
var clickable := false       # lintcellen klikbaar
var clickable_from := 0

var _buttons := {}           # id -> Button
var _btn_box: HBoxContainer
var _btn_box2: HBoxContainer
var _cells: Array = []       # [{rect, row, i}]
var _pop := 1.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_btn_box = HBoxContainer.new()
	_btn_box.add_theme_constant_override("separation", 12)
	_btn_box.alignment = BoxContainer.ALIGNMENT_END
	_btn_box.position = Vector2(1410, 890)
	_btn_box.size = Vector2(480, 64)
	add_child(_btn_box)
	_btn_box2 = HBoxContainer.new()
	_btn_box2.add_theme_constant_override("separation", 12)
	_btn_box2.alignment = BoxContainer.ALIGNMENT_END
	_btn_box2.position = Vector2(1410, 972)
	_btn_box2.size = Vector2(480, 64)
	add_child(_btn_box2)


## Knoppen: [{id, text, kind(TtUi.Kind), row(0/1), w}]
func set_buttons(list: Array) -> void:
	for b in _buttons.values():
		b.queue_free()
	_buttons.clear()
	for spec in list:
		var b := TtUi.button(spec.text, spec.get("kind", TtUi.Kind.SECONDARY), spec.get("size", 26), spec.get("w", 150))
		b.focus_mode = Control.FOCUS_NONE
		var id: String = spec.id
		b.pressed.connect(func(): action.emit(id))
		(_btn_box2 if spec.get("row", 0) == 1 else _btn_box).add_child(b)
		_buttons[id] = b
		TtUi.pop_in(b, 0.03 * _buttons.size(), 0.2)


func button(id: String) -> Button:
	return _buttons.get(id)


func flash_button(id: String) -> void:
	var b: Button = _buttons.get(id)
	if b == null:
		return
	b.pivot_offset = b.size / 2.0
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(1.12, 0.9), 0.06)
	tw.tween_property(b, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func bump() -> void:
	shake = 1.0
	var tw := create_tween()
	tw.tween_property(self, "shake", 0.0, 0.35)


func pop() -> void:
	_pop = 0.85
	create_tween().tween_property(self, "_pop", 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


# ================================================================ invoer
func _gui_input(_ev: InputEvent) -> void:
	pass


func _input(ev: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if ev is InputEventMouseMotion:
		var p := get_local_mouse_position()
		var h := -1
		for c in _cells:
			if c.rect.has_point(p) and clickable and int(c.i) >= clickable_from:
				h = c.i
		hover_col = h
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var p2 := get_local_mouse_position()
		if not AREA.has_point(p2):
			return
		for c in _cells:
			if c.rect.has_point(p2):
				if clickable:
					cell_clicked.emit(c.row, c.i)
					get_viewport().set_input_as_handled()
				return


# ================================================================ tekenen
func _draw() -> void:
	_cells.clear()
	var ox := sin(t * 60.0) * 10.0 * shake
	draw_set_transform(Vector2(ox, 0), 0.0, Vector2.ONE)
	var r := AREA
	draw_style_box(TtPal.sb(Color(TtPal.PANEL, 0.95), 26, 16, Vector2(0, -2)), r)
	draw_line(Vector2(r.position.x + 24, r.position.y + 3), Vector2(r.end.x - 24, r.position.y + 3), Color(1, 1, 1, 0.08), 2.0)
	_draw_card(Rect2(34, 880, 270, 168))
	match mode:
		"word", "cut":
			_draw_title()
			_ribbon_word(Vector2((RIB_X0 + RIB_X1) / 2.0, 966), word, "s")
		"compare":
			_draw_title()
			_ribbon_compare()
		"answer":
			_draw_title()
			_ribbon_compare(false)
		"hop":
			_draw_title()
			_ribbon_word(Vector2((RIB_X0 + RIB_X1) / 2.0, 966), word, "s", true)
		"ternary":
			_draw_title()
			_ribbon_word(Vector2(RIB_X0 + 330, 966), word, "s")
			_draw_versus(Vector2(1180, 975))
		"place":
			_draw_title()
			_draw_place()
		"suffix", "label":
			_draw_title()
			_ribbon_word(Vector2((RIB_X0 + RIB_X1) / 2.0, 966), word, "s")
		"ask", "ukkonen", "prune", "info", "bloom", "beds":
			_draw_title()
			if word != "":
				_ribbon_word(Vector2((RIB_X0 + RIB_X1) / 2.0, 966), word, "s")
	if numpad:
		_draw_numpad()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_title() -> void:
	var p := Vector2(RIB_X0 + 10, 902)
	if not title_parts.is_empty():
		var w := TtPal.rich_line(self, p, title_parts, 26, TtPal.TEXT, true, letters, true)
		TtPal.rich_line(self, Vector2((RIB_X0 + RIB_X1) / 2.0 - w / 2.0, 900), title_parts, 26, TtPal.TEXT, true, letters)
	elif title != "":
		TtPal.text_c(self, TtPal.UI_BOLD, Vector2((RIB_X0 + RIB_X1) / 2.0, 906), title, 26, TtPal.TEXT)
	if subtitle != "":
		TtPal.text_c(self, TtPal.UI, Vector2((RIB_X0 + RIB_X1) / 2.0, 1050), subtitle, 18, TtPal.TEXT_DIM)


func _draw_card(r: Rect2) -> void:
	if card_kind == "":
		return
	var se := TtPal.season(mini(season, 3))
	var s := _pop
	draw_set_transform(r.get_center() + Vector2(sin(t * 60.0) * 10.0 * shake, 0), 0.0, Vector2(s, s))
	var lr := Rect2(-r.size / 2.0, r.size)
	match card_kind:
		"seed":
			TtDraw.seed_packet(self, Vector2.ZERO, card_word, se, lr.size, false, t, letters, 30)
		_:
			draw_style_box(TtPal.sb(Color(0, 0, 0, 0), 14, 8, Vector2(3, 6)), lr)
			draw_style_box(TtPal.sb_thick(TtPal.PAPER, 14, 6, TtPal.PAPER_EDGE), lr)
			var band := Rect2(lr.position, Vector2(lr.size.x, 44))
			var bc := TtPal.BEE_DARK
			var lab := "bestelling"
			match card_kind:
				"prune":
					bc = TtPal.GREATER
					lab = "verwelkt"
				"patricify":
					bc = TtPal.RAFFIA_DARK
					lab = "snoeien"
				"ternarify":
					bc = TtPal.TENDRIL_DARK
					lab = "rankknopen"
				"suffix":
					bc = TtPal.ROPE
					lab = "staartje"
				"ask":
					bc = TtPal.HOG
					lab = "inspecteur"
				"ukkonen":
					bc = Color("#C9A227")
					lab = "slinger"
				"beds":
					bc = TtPal.TENDRIL_DARK
					lab = "tuinbedden"
			draw_style_box(TtPal.sb(bc, 14), band)
			draw_rect(Rect2(band.position.x, band.end.y - 14, band.size.x, 14), bc)
			TtPal.text_l(self, TtPal.UI_BOLD, Vector2(band.position.x + 56, band.get_center().y), lab, 20, Color.WHITE)
			var ic := Vector2(band.position.x + 30, band.get_center().y)
			match card_kind:
				"bee", "wasp":
					TtDraw.bee(self, ic + Vector2(0, 2), 0.55, t, 1.0, 0, "", letters)
				"prune", "patricify":
					TtDraw.shears(self, ic, 0.5, 0.4 + 0.3 * sin(t * 3.0), TtPal.GREATER, Color.WHITE)
				"ask":
					TtDraw.magnifier(self, ic + Vector2(-3, -3), 11)
				_:
					draw_circle(ic, 12, TtPal.STAR, true, -1, true)
					draw_circle(ic, 8, TtPal.PAPER, true, -1, true)
			if card_word != "":
				var fs := TtPal.fit_word(card_word.length(), lr.size.x - 28, 30, 16)
				TtPal.word(self, Vector2(0, lr.position.y + 44 + (lr.size.y - 44) / 2.0), card_word, fs, true, letters)
	draw_set_transform(Vector2(sin(t * 60.0) * 10.0 * shake, 0), 0.0, Vector2.ONE)


## Eén lint (TtDraw.ribbon): chips per letter, indices eronder (in `index_offset`). `hop`: Patricia-leescursor
## met sprongboog van `ghost_from` (next) naar de cursor; letters vóór next zijn gedimd.
func _ribbon_word(center: Vector2, s: String, row: String, hop := false) -> void:
	if s == "":
		return
	var n := s.length()
	var cell := clampf((RIB_X1 - RIB_X0 - 80) / n, 30.0, 58.0)
	var fs := int(cell * 0.62)
	var w := n * cell + 24
	var left := Vector2(center.x - w / 2.0, center.y)
	var disp := ""
	for ch in s:
		disp += _disp(ch)
	var cur := -1
	var grey := d if not hop else ghost_from
	var hops := []
	if hop:
		cur = cursor
		if cursor > ghost_from and ghost_from >= 0:
			hops = [[maxi(ghost_from - 1, 0), cursor]]
	elif read_hint >= 0 and hint != TtCodes.Hint.NONE:
		cur = read_hint
	var centers := TtDraw.ribbon(self, left, disp, cell, fs, cur, grey, chosen, TtPal.OK, letters, true, false, t, hops)
	for i in centers.size():
		var c: Vector2 = centers[i]
		_cells.append({"rect": Rect2(c.x - cell / 2.0, c.y - cell * 0.6, cell, cell * 1.6), "row": row, "i": i})
		var on_read := i == read_hint and hint == TtCodes.Hint.FULL and not hop
		var idx := str(i + index_offset)
		var iw := TtPal.MONO_B.get_string_size(idx, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 12
		var ir := Rect2(c.x - iw / 2.0, center.y + cell * 0.66 + 4, iw, 22)
		draw_style_box(TtPal.sb(TtPal.STAR if on_read else Color(TtPal.PANEL_LO, 0.95), 7), ir)
		TtPal.text_c(self, TtPal.MONO_B, ir.get_center(), idx, 16, TtPal.INK if on_read else TtPal.TEXT_DIM)
		if on_read:
			var pr := 0.5 + 0.5 * sin(t * 6.0)
			TtPal.ring(self, Rect2(c.x - cell / 2.0 - 2, center.y - cell * 0.66, cell + 4, cell * 1.3), 12, Color(TtPal.INFO, 0.5 + 0.5 * pr), 3)
		if i == hover_col and clickable and i >= clickable_from:
			TtPal.ring(self, Rect2(c.x - cell / 2.0 + 2, center.y - cell * 0.6, cell - 4, cell * 1.2), 10, TtPal.WARN, 4)


func _disp(ch: String) -> String:
	match ch:
		"1":
			return "₁"
		"2":
			return "₂"
		"3":
			return "₃"
	return ch


## Vergelijkingslint (TtDraw.compare_ribbon): rij l (vrucht) boven, s (zaadje/bij) onder. Kolommen < d grijs.
func _ribbon_compare(click_cols := true) -> void:
	var n := maxi(word.length(), word2.length())
	if n == 0:
		return
	var cell := clampf((RIB_X1 - RIB_X0 - 160) / n, 30.0, 50.0)
	var fs := int(cell * 0.6)
	var w := n * cell + 70
	var left := Vector2((RIB_X0 + RIB_X1) / 2.0 - w / 2.0, 978)
	var hov := hover_col if (click_cols and clickable and hover_col >= clickable_from) else -1
	if click_cols and clickable and hov < 0:
		hov = cursor
	var centers := TtDraw.compare_ribbon(self, left, word, word2, d, hov, chosen, cell, fs, letters, t)
	TtPal.text_r(self, TtPal.UI_BOLD, Vector2(left.x - 14, 978 - cell * 0.6), row_names[0], 18, TtPal.TEXT_DIM)
	TtPal.text_r(self, TtPal.UI_BOLD, Vector2(left.x - 14, 978 + cell * 0.25), row_names[1], 18, TtPal.TEXT_DIM)
	for i in centers.size():
		var c: Vector2 = centers[i]
		if click_cols:
			_cells.append({"rect": Rect2(c.x - cell / 2.0, 978 - cell * 1.15, cell, cell * 2.3), "row": "col", "i": i})
		if click_cols and clickable and i == cursor:
			TtPal.ring(self, Rect2(c.x - cell / 2.0 + 1, 978 - cell * 1.15 + 2, cell - 2, cell * 2.3 - 4), 10, TtPal.TEXT, 3)
		if i == hov and i < word.length() and i < word2.length() and i >= d:
			var same := word[i] == word2[i]
			TtPal.text_outline_c(self, TtPal.UI_BOLD, Vector2(c.x, 978 - cell * 1.15 - 14), "=" if same else "≠", 24, TtPal.OK if same else TtPal.WARN, 5)


func _draw_versus(c: Vector2) -> void:
	if cmp_letter == "" or ball_letter == "":
		return
	var r := Rect2(c.x - 150, c.y - 54, 300, 108)
	draw_style_box(TtPal.sb(TtPal.PANEL_LO, 20), r)
	TtDraw.letter_tag(self, c + Vector2(-70, 0), cmp_letter, 40, letters)
	TtPal.text_c(self, TtPal.UI_BOLD, c, "?", 40, TtPal.TEXT)
	draw_circle(c + Vector2(70, 0), 36, TtPal.KNOT_RIM, true, -1, true)
	draw_circle(c + Vector2(69, -2), 33, TtPal.KNOT, true, -1, true)
	TtDraw.letter_tag(self, c + Vector2(70, -2), ball_letter, 32, letters)
	TtPal.text_c(self, TtPal.UI, c + Vector2(-70, 46), "letter", 16, TtPal.TEXT_DIM)
	TtPal.text_c(self, TtPal.UI, c + Vector2(70, 46), "bol", 16, TtPal.TEXT_DIM)


func _draw_place() -> void:
	var n := place_letters.size()
	if n == 0:
		return
	var step := 74.0
	var x0 := (RIB_X0 + RIB_X1) / 2.0 - (n - 1) * step / 2.0
	for i in n:
		var c := Vector2(x0 + i * step, 990)
		var r := Rect2(c - Vector2(30, 30), Vector2(60, 60))
		_cells.append({"rect": r.grow(4), "row": "place", "i": i})
		if i == hover_col:
			TtPal.ring(self, r.grow(6), 16, TtPal.WARN, 4)
		TtDraw.letter_tag(self, c, str(place_letters[i]), 40, letters)


func _draw_numpad() -> void:
	var x0 := RIB_X0 + 120
	var y := 1000.0
	for i in 10:
		var r := Rect2(x0 + i * 62, y - 28, 54, 56)
		_cells.append({"rect": r, "row": "num", "i": i})
		var hov := hover_col == i
		draw_style_box(TtPal.sb_thick(TtPal.PANEL_HI.lightened(0.1 if hov else 0.0), 12, 5, TtPal.PANEL_LO), r)
		TtPal.text_c(self, TtPal.MONO, r.get_center() + Vector2(0, -2), str(i), 28, TtPal.TEXT)
	var vr := Rect2(x0 + 10 * 62 + 20, y - 30, 110, 60)
	draw_style_box(TtPal.sb(TtPal.PAPER, 12), vr)
	TtPal.text_c(self, TtPal.MONO, vr.get_center(), num_value if num_value != "" else "_", 32, TtPal.INK)
