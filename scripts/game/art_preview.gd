extends Node2D
## Art-proef "Hash & Dash": toont het depot (layout volgens GDD §7.1) in de stijl van design/ART.md,
## met lichte idle-animatie. Alles in code: StyleBoxFlat (afgeronde hoeken + zachte schaduw), Line2D-buizen,
## draw_*-calls en één achtergrondshader. Referentie voor de gameplay-engineer, geen gameplaycode.
##
## Getoonde toestand: a = 2, luiken 00+01 -> rek "0" (ab 1, blauw, 2 buizen), 10 -> oranje, 11 -> mint (vol).
## Pakje 11100 zit vast in de mint buis (vastloper: zwaailicht, hendel gloeit); speler sleept 01101 naar luik 01;
## een klant vraagt 01001.

# ---------------------------------------------------------------- palet (zie ART.md §2)
const C_BG_DEEP := Color("#121829")
const C_BG := Color("#1A2238")
const C_FLOOR_LINE := Color("#212B45")
const C_PANEL := Color("#28334F")
const C_PANEL_HI := Color("#34416A")
const C_PANEL_LO := Color("#1F2840")
const C_SLOT := Color("#141A2B")
const C_OUTLINE := Color("#0B101C")
const C_TEXT := Color("#F4F1EA")
const C_TEXT_DIM := Color("#8D97B5")
const C_KRAFT := Color("#E0A96D")
const C_KRAFT_DARK := Color("#B97F46")
const C_TAPE := Color("#F3DDB0")
const C_LABEL := Color("#FFFBF2")
const C_INK := Color("#1A1F2E")
const C_OK := Color("#3DDC97")
const C_ERR := Color("#FF5A5F")
const C_WARN := Color("#FFB020")
const C_COIN := Color("#FFD23F")
const C_COIN_DARK := Color("#E09A1B")
const C_HEART := Color("#FF5A7A")
const C_SHADOW := Color(0.02, 0.03, 0.08, 0.45)

## kleur per bitpositie (1e, 2e, 3e, ... bit) -- ART.md §2.2
const BIT_COLORS := [Color("#FFC94D"), Color("#5CD6C8"), Color("#FF8FAB"), Color("#A5E05A"), Color("#B39DFF"), Color("#FFA463")]
## kleur per emmer/rek (buizen) -- ART.md §2.3
const BUCKET_COLORS := [Color("#3A86FF"), Color("#FB8500"), Color("#06D6A0"), Color("#EF476F"), Color("#8338EC"), Color("#00B4D8"), Color("#E056FD"), Color("#FFD166")]
const SKIN := [Color("#F2C29B"), Color("#C68B59"), Color("#8D5524"), Color("#FFDBAC")]

var F_MONO: FontFile
var F_UI: FontFile
var F_UI_BOLD: FontFile
var TEX_PAUSE: Texture2D

const A := 2
const G := 4
var t := 0.0

var belt_parcels := [
	{"bits": "01101", "x": 560.0, "lifted": true},
	{"bits": "10110", "x": 1040.0, "lifted": false},
	{"bits": "00010", "x": 1420.0, "lifted": false},
]
var racks := [
	{"prefix": "0", "ab": 1, "col": 0, "items": ["00101", "01001", "00011"]},
	{"prefix": "10", "ab": 2, "col": 1, "items": ["10011", "10100"]},
	{"prefix": "11", "ab": 2, "col": 2, "items": ["11010", "11111", "11001", "11011"]},
]
var hatch_to_rack := [0, 0, 1, 2]
const STUCK_BITS := "11100"
const STUCK_RACK := 2

# layout (GDD §7.1)
const HUD_RECT := Rect2(16, 8, 1888, 60)
const BIN_RECT := Rect2(16, 84, 92, 140)
const BELT_RECT := Rect2(120, 84, 1784, 140)
const LEVER_RECT := Rect2(140, 262, 220, 330)
const WALL_RECT := Rect2(400, 250, 160, 790)
const RACK_X := 960.0
const RACK_W := 540.0
const RACK_H := 214.0
var rack_y := [262.0, 530.0, 798.0]
const DESK_X := 1560.0
const LIFT_POS := Vector2(668, 452)   # gesleept pakje, net naast luik 01

var layer_main: Node2D
var layer_pipes: Node2D
var layer_fx: Node2D
var pipe_paths: Array = []   # [points, color, rack]


func _ready() -> void:
	F_MONO = load("res://assets/fonts/JetBrainsMono-ExtraBold.ttf")
	F_UI = load("res://assets/fonts/Fredoka-SemiBold.ttf")
	F_UI_BOLD = load("res://assets/fonts/Fredoka-Bold.ttf")
	TEX_PAUSE = load("res://assets/art/icons/pause.png")
	_build_background()
	layer_pipes = Node2D.new()
	add_child(layer_pipes)
	_build_pipes()
	layer_main = _draw_layer(_draw_main)
	layer_fx = _draw_layer(_draw_fx)


func _process(delta: float) -> void:
	t += delta
	layer_main.queue_redraw()
	layer_fx.queue_redraw()


func _draw_layer(cb: Callable) -> Node2D:
	var n := Node2D.new()
	add_child(n)
	n.draw.connect(func(): cb.call(n))
	return n

# ================================================================ achtergrond
func _build_background() -> void:
	var rect := ColorRect.new()
	rect.size = Vector2(1920, 1080)
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform vec4 c_bg : source_color;
uniform vec4 c_deep : source_color;
uniform vec4 c_line : source_color;
void fragment() {
	vec2 px = UV * vec2(1920.0, 1080.0);
	vec2 g = abs(fract(px / 64.0) - 0.5);
	float line = 1.0 - smoothstep(0.475, 0.49, max(g.x, g.y));
	vec3 col = mix(c_bg.rgb, c_line.rgb, (1.0 - line) * 0.9);
	vec2 q = UV - vec2(0.5, 0.55);
	float v = smoothstep(0.35, 0.95, length(q * vec2(1.0, 1.25)));
	col = mix(col, c_deep.rgb, v * 0.85);
	COLOR = vec4(col, 1.0);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("c_bg", C_BG)
	mat.set_shader_parameter("c_deep", C_BG_DEEP)
	mat.set_shader_parameter("c_line", C_FLOOR_LINE)
	rect.material = mat
	add_child(rect)
	_draw_layer(_draw_zones)


func _draw_zones(n: Node2D) -> void:
	for r in [Rect2(120, 240, 460, 820), Rect2(930, 240, 600, 820), Rect2(1548, 240, 356, 820)]:
		var sb := _sb(Color(1, 1, 1, 0.022), 24)
		sb.border_color = Color(1, 1, 1, 0.05)
		sb.set_border_width_all(2)
		n.draw_style_box(sb, r)

# ================================================================ helpers
func _sb(col: Color, radius: int, shadow := 0, shadow_off := Vector2(0, 6)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	sb.corner_detail = 10
	if shadow > 0:
		sb.shadow_color = C_SHADOW
		sb.shadow_size = shadow
		sb.shadow_offset = shadow_off
	return sb


func _ring(n: CanvasItem, r: Rect2, radius: int, col: Color, w: int) -> void:
	var g := _sb(Color(0, 0, 0, 0), radius)
	g.draw_center = false
	g.border_color = col
	g.set_border_width_all(w)
	n.draw_style_box(g, r)


func _text_c(n: CanvasItem, font: Font, center: Vector2, s: String, size: int, col: Color) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var asc := font.get_ascent(size)
	var desc := font.get_descent(size)
	n.draw_string(font, Vector2(center.x - w.x / 2.0, center.y + (asc - desc) / 2.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _text_l(n: CanvasItem, font: Font, left_mid: Vector2, s: String, size: int, col: Color) -> float:
	var asc := font.get_ascent(size)
	var desc := font.get_descent(size)
	n.draw_string(font, Vector2(left_mid.x, left_mid.y + (asc - desc) / 2.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## Bitlabel: de eerste `hi` bits op een chip in hun positiekleur, daarna een kleine extra spatie, rest in inkt.
## Vaste kolombreedte (mono). Geeft de totale breedte terug.
func _bits(n: CanvasItem, center: Vector2, bits: String, size: int, hi: int, ink := C_INK) -> float:
	var cw := F_MONO.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var gap := maxf(3.0, size * 0.12)
	var sep := size * 0.3 if hi > 0 and hi < bits.length() else 0.0
	var total := bits.length() * cw + (bits.length() - 1) * gap + sep
	var x := center.x - total / 2.0
	var asc := F_MONO.get_ascent(size)
	var desc := F_MONO.get_descent(size)
	for i in bits.length():
		if i < hi:
			var r := Rect2(x - size * 0.09, center.y - size * 0.62, cw + size * 0.18, size * 1.24)
			n.draw_style_box(_sb(BIT_COLORS[i % BIT_COLORS.size()], int(size * 0.24)), r)
		n.draw_string(F_MONO, Vector2(x, center.y + (asc - desc) / 2.0), bits[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, ink)
		x += cw + gap
		if i == hi - 1:
			x += sep
	return total


func _fillet(pts: PackedVector2Array, radius: float, seg := 10) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.append(pts[0])
	for i in range(1, pts.size() - 1):
		var p0 := pts[i - 1]
		var p1 := pts[i]
		var p2 := pts[i + 1]
		var r := minf(radius, minf(p0.distance_to(p1), p1.distance_to(p2)) * 0.5)
		var a := p1 + (p0 - p1).normalized() * r
		var b := p1 + (p2 - p1).normalized() * r
		for k in seg + 1:
			var s := float(k) / seg
			out.append(a.lerp(p1, s).lerp(p1.lerp(b, s), s))
	out.append(pts[pts.size() - 1])
	return out


func _path_point(pts: PackedVector2Array, f: float) -> Vector2:
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i - 1].distance_to(pts[i])
	var target := f * total
	for i in range(1, pts.size()):
		var l := pts[i - 1].distance_to(pts[i])
		if target <= l:
			return pts[i - 1].lerp(pts[i], target / maxf(l, 0.001))
		target -= l
	return pts[pts.size() - 1]

# ================================================================ buizen
func _hatch_rect(i: int) -> Rect2:
	var top := WALL_RECT.position.y + 84
	var avail := WALL_RECT.end.y - 20 - top
	var h := minf(150.0, avail / 4.0 - 24)
	var step := avail / 4.0
	return Rect2(WALL_RECT.position.x + 18, top + i * step + (step - h) / 2.0, WALL_RECT.size.x - 36, h)


func _build_pipes() -> void:
	var used := {}
	for i in 4:
		var hr := _hatch_rect(i)
		var ri: int = hatch_to_rack[i]
		var col: Color = BUCKET_COLORS[racks[ri]["col"]]
		var k: int = used.get(ri, 0)
		used[ri] = k + 1
		var share: int = hatch_to_rack.count(ri)
		var start := Vector2(WALL_RECT.end.x - 4, hr.get_center().y)
		var ty: float = rack_y[ri] + RACK_H * 0.5 + 28
		var pts: PackedVector2Array
		if share > 1:
			# gedeelde pointers: buizen komen samen in één verzamelbuis (GDD §3)
			var mx := 690.0
			pts = PackedVector2Array([start, Vector2(mx, start.y), Vector2(mx, ty), Vector2(RACK_X + 6, ty)])
		else:
			var mx2 := 760.0
			pts = PackedVector2Array([start, Vector2(mx2, start.y), Vector2(mx2, ty), Vector2(RACK_X + 6, ty)])
		pts = _fillet(pts, 40)
		pipe_paths.append([pts, col, ri])
		for spec in [[34.0, C_OUTLINE], [24.0, col.darkened(0.12)]]:
			var l := Line2D.new()
			l.points = pts
			l.width = spec[0]
			l.default_color = spec[1]
			l.joint_mode = Line2D.LINE_JOINT_ROUND
			l.begin_cap_mode = Line2D.LINE_CAP_ROUND
			l.antialiased = true
			layer_pipes.add_child(l)
		var shine := Line2D.new()
		var sp := PackedVector2Array()
		for p in pts:
			sp.append(p + Vector2(0, -5))
		shine.points = sp
		shine.width = 6
		shine.default_color = Color(col.lightened(0.45), 0.9)
		shine.joint_mode = Line2D.LINE_JOINT_ROUND
		shine.antialiased = true
		layer_pipes.add_child(shine)

# ================================================================ hoofdlaag
func _draw_main(n: Node2D) -> void:
	_draw_belt(n)
	_draw_lever(n)
	_draw_wall(n)
	for i in racks.size():
		_draw_rack(n, i)
	_draw_desk_and_customer(n)
	_draw_hud(n)
	# opgetild pakje bovenaan alles
	for p in belt_parcels:
		if p["lifted"]:
			_draw_parcel(n, LIFT_POS + Vector2(0, sin(t * 3.0) * 3.0), Vector2(176, 104), p["bits"], A, true, 40)


func _draw_belt(n: Node2D) -> void:
	# retourbak
	n.draw_style_box(_sb(C_PANEL_LO, 18, 12, Vector2(0, 8)), BIN_RECT)
	n.draw_style_box(_sb(C_SLOT, 12), BIN_RECT.grow(-12))
	_text_c(n, F_UI, BIN_RECT.get_center() + Vector2(0, 46), "retour", 17, C_TEXT_DIM)
	# band
	var r := BELT_RECT
	n.draw_style_box(_sb(C_PANEL_LO, 22, 16, Vector2(0, 10)), r)
	var inner := r.grow(-14)
	n.draw_style_box(_sb(C_SLOT, 14), inner)
	var pitch := 44.0
	var off := fmod(t * 70.0, pitch)   # band loopt naar links (instroom rechts)
	var x := inner.end.x + pitch - off
	while x > inner.position.x:
		if x < inner.end.x - 8:
			var rr := Rect2(x, inner.position.y + 8, 14, inner.size.y - 16)
			n.draw_style_box(_sb(Color("#28314D"), 7), rr)
			n.draw_line(Vector2(x + 4, rr.position.y + 6), Vector2(x + 4, rr.end.y - 6), Color(1, 1, 1, 0.06), 2)
		x -= pitch
	for y in [r.position.y + 7, r.end.y - 7]:
		n.draw_line(Vector2(r.position.x + 24, y), Vector2(r.end.x - 24, y), Color(C_WARN, 0.5), 4)
	for p in belt_parcels:
		if p["lifted"]:
			# lege plek + 'ghost' waar het pakje lag
			_ring(n, Rect2(Vector2(p["x"], r.get_center().y) - Vector2(80, 46), Vector2(160, 92)), 14, Color(1, 1, 1, 0.12), 3)
			continue
		_draw_parcel(n, Vector2(p["x"], r.get_center().y), Vector2(176, 104), p["bits"], A, false, 40)


func _draw_parcel(n: CanvasItem, c: Vector2, sz: Vector2, bits: String, hi: int, lifted := false, label_size := 40) -> void:
	var s := 1.08 if lifted else 1.0
	sz *= s
	var r := Rect2(c - sz / 2.0, sz)
	var rad := int(sz.y * 0.13)
	var sh := _sb(Color(0, 0, 0, 0), rad)
	sh.shadow_color = Color(0.02, 0.03, 0.08, 0.5)
	sh.shadow_size = 22 if lifted else 7
	sh.shadow_offset = Vector2(8, 22) if lifted else Vector2(0, 6)
	n.draw_style_box(sh, r)
	var box := _sb(C_KRAFT, rad)
	box.border_color = C_KRAFT_DARK
	box.border_width_bottom = maxi(4, int(sz.y * 0.08))
	n.draw_style_box(box, r)
	n.draw_rect(Rect2(c.x - sz.x * 0.07, r.position.y, sz.x * 0.14, sz.y * 0.92), Color(C_TAPE, 0.55))
	var lw := sz.x * 0.88
	var lh := sz.y * 0.54
	var lr := Rect2(c.x - lw / 2.0, c.y - lh / 2.0 - sz.y * 0.05, lw, lh)
	var lab := _sb(C_LABEL, int(lh * 0.2))
	lab.shadow_color = Color(0, 0, 0, 0.18)
	lab.shadow_size = 2
	lab.shadow_offset = Vector2(0, 2)
	n.draw_style_box(lab, lr)
	_bits(n, lr.get_center(), bits, int(label_size * s), hi)
	if lifted:
		_ring(n, r.grow(7), rad + 6, Color(1, 1, 1, 0.75 + 0.25 * sin(t * 6.0)), 4)


func _draw_lever(n: Node2D) -> void:
	# hendel = muur verdubbelen. Gloeit (amber) want het vastzittende rek heeft ab = a.
	var r := LEVER_RECT
	n.draw_style_box(_sb(C_PANEL, 24, 16, Vector2(0, 10)), r)
	_text_c(n, F_UI_BOLD, Vector2(r.get_center().x, r.position.y + 32), "hendel", 22, C_TEXT_DIM)
	var slot := Rect2(r.get_center().x - 14, r.position.y + 64, 28, r.size.y - 110)
	n.draw_style_box(_sb(C_SLOT, 14), slot)
	var pull := 0.12 + 0.06 * sin(t * 4.0)   # wiebelt uitnodigend
	var knob := Vector2(slot.get_center().x, slot.position.y + 24 + pull * (slot.size.y - 48))
	n.draw_line(Vector2(slot.get_center().x, slot.end.y - 10), knob, Color("#566390"), 12, true)
	var glow := 0.5 + 0.5 * sin(t * 6.0)
	n.draw_circle(knob, 40 + 6 * glow, Color(C_WARN, 0.18 * glow), true, -1, true)
	n.draw_circle(knob + Vector2(0, 4), 30, C_WARN.darkened(0.35), true, -1, true)
	n.draw_circle(knob, 30, C_WARN, true, -1, true)
	n.draw_circle(knob + Vector2(-9, -10), 9, Color(1, 1, 1, 0.45), true, -1, true)
	_text_c(n, F_UI_BOLD, Vector2(r.get_center().x, r.end.y - 26), "a + 1", 22, C_WARN)


func _draw_wall(n: Node2D) -> void:
	var r := WALL_RECT
	n.draw_style_box(_sb(C_PANEL, 24, 18, Vector2(0, 10)), r)
	var top := _sb(C_PANEL_HI, 24)
	top.corner_radius_bottom_left = 0
	top.corner_radius_bottom_right = 0
	n.draw_style_box(top, Rect2(r.position, Vector2(r.size.x, 64)))
	var badge := Rect2(r.get_center().x - 50, r.position.y + 12, 100, 40)
	n.draw_style_box(_sb(C_TEXT, 20), badge)
	_text_c(n, F_UI_BOLD, badge.get_center(), "a = %d" % A, 26, C_INK)
	for i in 4:
		_draw_hatch(n, i)


func _draw_hatch(n: Node2D, i: int) -> void:
	var r := _hatch_rect(i)
	var code := String.num_int64(i, 2).pad_zeros(A)
	var target := i == 1
	var col: Color = BUCKET_COLORS[racks[hatch_to_rack[i]]["col"]]
	var frame := _sb(C_PANEL_LO, 18)
	frame.border_color = col
	frame.set_border_width_all(4)
	n.draw_style_box(frame, r)
	var hole := Rect2(r.position.x + 16, r.position.y + 58, r.size.x - 32, r.size.y - 72)
	n.draw_style_box(_sb(Color("#06090F"), 12), hole)
	var open := (0.5 + 0.5 * sin(t * 5.0)) if target else 0.0
	var flap := _sb(C_PANEL_HI, 10)
	flap.border_color = col.darkened(0.1)
	flap.border_width_bottom = 5
	n.draw_style_box(flap, Rect2(hole.position, Vector2(hole.size.x, hole.size.y * (0.6 - 0.5 * open))))
	_bits(n, Vector2(r.get_center().x, r.position.y + 30), code, 30, A)
	if target:
		var s := 1.0 + 0.03 * sin(t * 6.0)   # luik "ademt" onder het gesleepte pakje
		var rr := Rect2(r.get_center() - r.size * s / 2.0, r.size * s).grow(8)
		_ring(n, rr, 24, Color(C_OK, 0.6 + 0.4 * sin(t * 6.0)), 5)


func _draw_rack(n: Node2D, i: int) -> void:
	var rk: Dictionary = racks[i]
	var col: Color = BUCKET_COLORS[rk["col"]]
	var items: Array = rk["items"]
	var stuck := i == STUCK_RACK
	var breathe := 1.0 + (0.012 * sin(t * 8.0) if stuck else 0.0)   # vastloper: rek bolt
	var base := Rect2(RACK_X, rack_y[i], RACK_W, RACK_H)
	var r := Rect2(base.get_center() - base.size * breathe / 2.0, base.size * breathe)
	n.draw_style_box(_sb(C_PANEL, 22, 18, Vector2(0, 10)), r)
	var head := _sb(col, 22)
	head.corner_radius_bottom_left = 0
	head.corner_radius_bottom_right = 0
	n.draw_style_box(head, Rect2(r.position, Vector2(r.size.x, 58)))
	# bordje: prefix (= eerste ab bits) + ab-badge + diepte-stippen
	var plate := Rect2(r.position.x + 12, r.position.y + 9, 104, 40)
	n.draw_style_box(_sb(C_LABEL, 12), plate)
	_bits(n, plate.get_center(), rk["prefix"], 26, rk["prefix"].length())
	var abr := Rect2(plate.end.x + 10, r.position.y + 11, 96, 36)
	n.draw_style_box(_sb(Color(0, 0, 0, 0.28), 18), abr)
	_text_c(n, F_UI_BOLD, abr.get_center(), "ab = %d" % rk["ab"], 23, C_TEXT)
	for k in A:
		var dp := Vector2(abr.end.x + 18 + k * 22, r.position.y + 29)
		if k < rk["ab"]:
			n.draw_circle(dp, 8, C_TEXT, true, -1, true)
		else:
			n.draw_circle(dp, 7, Color(0, 0, 0, 0.4), false, 3, true)
	_text_c(n, F_UI_BOLD, Vector2(r.end.x - 44, r.position.y + 29), "%d/%d" % [items.size(), G], 26, C_INK)
	# zaag-knop (alleen zinvol als ab < a)
	if rk["ab"] < A:
		var sc := Vector2(r.end.x - 110, r.position.y + 29)
		n.draw_circle(sc, 20, Color(0, 0, 0, 0.28), true, -1, true)
		_saw_icon(n, sc, 13, C_TEXT)
	# vakken
	var shelf := Rect2(r.position.x + 12, r.position.y + 70, r.size.x - 24, r.size.y - 82)
	n.draw_style_box(_sb(C_SLOT, 14), shelf)
	var slot_w := shelf.size.x / G
	for s in G:
		var sc2 := Vector2(shelf.position.x + slot_w * (s + 0.5), shelf.get_center().y)
		if s < items.size():
			_draw_parcel(n, sc2, Vector2(slot_w - 14, 104), items[s], rk["ab"], false, 26)
		else:
			_ring(n, Rect2(sc2 - Vector2(slot_w - 18, 100) / 2.0, Vector2(slot_w - 18, 100)), 12, Color(1, 1, 1, 0.07), 3)
	if stuck:
		_ring(n, r.grow(8), 28, Color(C_WARN, 0.35 + 0.5 * (0.5 + 0.5 * sin(t * 7.0))), 5)
		_beacon(n, Vector2(r.end.x - 26, r.position.y - 6))


func _saw_icon(n: CanvasItem, c: Vector2, rad: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 10:   # zaagblad: 10 schuine tanden
		var a := k * TAU / 10 + t * 1.5
		pts.append(c + Vector2(cos(a), sin(a)) * rad * 0.7)
		pts.append(c + Vector2(cos(a + 0.5), sin(a + 0.5)) * rad * 1.15)
	n.draw_colored_polygon(pts, col)
	n.draw_circle(c, rad * 0.3, C_PANEL, true, -1, true)


func _beacon(n: CanvasItem, c: Vector2) -> void:
	# oranje zwaailicht met draaiende lichtbundel
	var a := t * 5.0
	for side in [0.0, PI]:
		var dir := Vector2(cos(a + side), sin(a + side) * 0.35)
		var tip := c + dir * 80
		var perp := Vector2(-dir.y, dir.x) * 26
		n.draw_colored_polygon(PackedVector2Array([c, tip + perp, tip - perp]), Color(C_WARN, 0.16))
	n.draw_style_box(_sb(C_PANEL_LO, 6), Rect2(c + Vector2(-20, 4), Vector2(40, 12)))
	n.draw_circle(c, 16, C_WARN, true, -1, true)
	n.draw_circle(c + Vector2(-5, -5), 5, Color(1, 1, 1, 0.6), true, -1, true)


func _draw_desk_and_customer(n: Node2D) -> void:
	var feet := Vector2(1732, 700)
	var bob := sin(t * 3.2) * 4.0
	# klant
	var body_col := Color("#7B61FF")
	var body := Rect2(feet + Vector2(-54, -160 + bob), Vector2(108, 160 - bob))
	n.draw_style_box(_sb(body_col, 48, 10, Vector2(0, 6)), body)
	n.draw_style_box(_sb(body_col.lightened(0.15), 14), Rect2(body.position + Vector2(22, 18), Vector2(64, 18)))
	var hc := feet + Vector2(0, -206 + bob)
	n.draw_circle(hc, 46, C_OUTLINE, true, -1, true)
	n.draw_circle(hc, 42, SKIN[0], true, -1, true)
	n.draw_arc(hc + Vector2(0, -6), 40, PI * 1.05, PI * 1.95, 24, Color("#4A2E1F"), 18, true)
	var blink := 1.0 if fmod(t, 3.1) > 0.12 else 0.15
	for ex in [-15.0, 15.0]:
		n.draw_set_transform(hc + Vector2(ex, 4), 0, Vector2(1, blink))
		n.draw_circle(Vector2.ZERO, 5.5, C_INK, true, -1, true)
		n.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	n.draw_arc(hc + Vector2(0, 12), 13, 0.25, PI - 0.25, 16, C_INK, 4, true)
	n.draw_circle(hc + Vector2(-26, 14), 7, Color(C_HEART, 0.35), true, -1, true)
	n.draw_circle(hc + Vector2(26, 14), 7, Color(C_HEART, 0.35), true, -1, true)
	# ballon
	var br := Rect2(feet.x - 124, feet.y - 384 + bob * 0.5, 248, 80)
	n.draw_style_box(_sb(C_LABEL, 24, 10, Vector2(0, 6)), br)
	n.draw_colored_polygon(PackedVector2Array([br.position + Vector2(104, br.size.y - 2), br.position + Vector2(140, br.size.y - 2), br.position + Vector2(112, br.size.y + 24)]), C_LABEL)
	var w := _bits(n, br.get_center() + Vector2(-12, -4), "01001", 36, A)
	_text_c(n, F_UI_BOLD, Vector2(br.get_center().x + w / 2.0 + 6, br.get_center().y - 4), "?", 40, C_INK)
	# geduldsbalk in de ballon
	var pb := Rect2(br.position.x + 22, br.end.y - 16, br.size.x - 44, 8)
	n.draw_style_box(_sb(Color(C_INK, 0.12), 4), pb)
	var patience := 0.66 - 0.02 * fmod(t, 1.0)
	n.draw_style_box(_sb(C_OK, 4), Rect2(pb.position, Vector2(pb.size.x * patience, pb.size.y)))
	# toonbank (voor het onderlijf)
	var desk := Rect2(DESK_X + 20, feet.y - 64, 324, 112)
	n.draw_style_box(_sb(C_PANEL_HI, 20, 16, Vector2(0, 10)), desk)
	var top := _sb(C_PANEL_HI.lightened(0.14), 20)
	top.corner_radius_bottom_left = 0
	top.corner_radius_bottom_right = 0
	n.draw_style_box(top, Rect2(desk.position, Vector2(desk.size.x, 20)))
	for hx in [-60.0, 60.0]:
		n.draw_circle(Vector2(feet.x + hx, desk.position.y + 6 + bob * 0.3), 14, SKIN[0], true, -1, true)
	var bell := Vector2(desk.end.x - 40, desk.position.y)
	n.draw_arc(bell + Vector2(0, -2), 14, PI, TAU, 16, C_COIN, 12, true)
	n.draw_line(bell + Vector2(-20, 4), bell + Vector2(20, 4), C_COIN_DARK, 5)
	_text_c(n, F_UI_BOLD, Vector2(desk.get_center().x, desk.get_center().y + 14), "BALIE", 26, Color(1, 1, 1, 0.22))
	# wachtrij: twee silhouetten
	for q in 2:
		var qc := Vector2(1640 + q * 150, 900)
		n.draw_style_box(_sb(Color(1, 1, 1, 0.07), 30), Rect2(qc + Vector2(-32, -10), Vector2(64, 90)))
		n.draw_circle(qc + Vector2(0, -38), 26, Color(1, 1, 1, 0.07), true, -1, true)
	_text_c(n, F_UI, Vector2(1726, 1010), "wachtrij: 2", 22, C_TEXT_DIM)


func _draw_hud(n: Node2D) -> void:
	var bar := HUD_RECT
	n.draw_style_box(_sb(Color(C_PANEL, 0.97), 22, 14, Vector2(0, 6)), bar)
	var cy := bar.get_center().y
	# pauze
	var pr := Rect2(bar.position.x + 10, bar.position.y + 8, 44, 44)
	n.draw_style_box(_sb(C_PANEL_HI, 14), pr)
	n.draw_texture_rect(TEX_PAUSE, pr.grow(-10), false, C_TEXT)
	var x := pr.end.x + 16
	x += _text_l(n, F_UI_BOLD, Vector2(x, cy), "DAG 2", 28, C_TEXT) + 10
	x += _text_l(n, F_UI, Vector2(x, cy), "· Eerste verdubbeling", 24, C_TEXT_DIM)
	# reputatie-hartjes
	x = 680.0
	for k in 5:
		_heart(n, Vector2(x + k * 38, cy), 14, k < 4)
	# munten
	x = 920.0
	_coin(n, Vector2(x, cy), 17)
	_text_l(n, F_UI_BOLD, Vector2(x + 26, cy), "128", 28, C_COIN)
	# ritten L/S (schijftoegang)
	x = 1110.0
	_truck(n, Vector2(x, cy))
	x += 34
	x += _text_l(n, F_UI_BOLD, Vector2(x, cy), "L 3", 28, C_TEXT) + 14
	x += _text_l(n, F_UI_BOLD, Vector2(x, cy), "S 5", 28, C_TEXT) + 12
	_text_l(n, F_UI, Vector2(x, cy + 1), "(opt 3/4)", 20, C_TEXT_DIM)
	# combo
	var cr := Rect2(bar.end.x - 200, bar.position.y + 8, 188, 44)
	n.draw_style_box(_sb(BIT_COLORS[0], 22), cr)
	var pop := 1.0 + 0.05 * maxf(0.0, sin(t * 4.0))
	_text_c(n, F_UI_BOLD, cr.get_center(), "COMBO ×3", int(26 * pop), C_INK)


func _heart(n: CanvasItem, c: Vector2, r: float, filled: bool) -> void:
	var col := C_HEART if filled else Color(1, 1, 1, 0.15)
	n.draw_circle(c + Vector2(-r * 0.5, -r * 0.25), r * 0.56, col, true, -1, true)
	n.draw_circle(c + Vector2(r * 0.5, -r * 0.25), r * 0.56, col, true, -1, true)
	n.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 1.04, -r * 0.08), c + Vector2(r * 1.04, -r * 0.08), c + Vector2(0, r * 0.95)]), col)


func _coin(n: CanvasItem, c: Vector2, r: float) -> void:
	n.draw_circle(c + Vector2(0, 3), r, C_COIN_DARK, true, -1, true)
	n.draw_circle(c, r, C_COIN, true, -1, true)
	n.draw_circle(c, r * 0.62, C_COIN_DARK.lightened(0.25), false, 3, true)
	n.draw_arc(c, r * 0.8, PI * 1.1, PI * 1.45, 8, Color(1, 1, 1, 0.8), 3, true)


func _truck(n: CanvasItem, c: Vector2) -> void:
	n.draw_style_box(_sb(C_WARN, 5), Rect2(c + Vector2(-18, -8), Vector2(24, 16)))
	n.draw_style_box(_sb(C_WARN.darkened(0.2), 3), Rect2(c + Vector2(-12, -18), Vector2(12, 12)))
	n.draw_line(c + Vector2(10, -16), c + Vector2(10, 10), C_TEXT_DIM, 3)
	n.draw_line(c + Vector2(10, 10), c + Vector2(22, 10), C_TEXT_DIM, 3)
	n.draw_circle(c + Vector2(-12, 11), 5, C_INK, true, -1, true)
	n.draw_circle(c + Vector2(2, 11), 5, C_INK, true, -1, true)

# ================================================================ fx-laag
func _draw_fx(n: Node2D) -> void:
	# lichtpuntjes stromen door de buizen (behalve de verstopte)
	for pp in pipe_paths:
		var pts: PackedVector2Array = pp[0]
		var col: Color = pp[1]
		if pp[2] == STUCK_RACK:
			continue
		for k in 2:
			var f := fmod(t * 0.4 + k / 2.0, 1.0)
			var p := _path_point(pts, f)
			n.draw_circle(p, 9, Color(col.lightened(0.5), 0.25), true, -1, true)
			n.draw_circle(p, 5, Color(col.lightened(0.7), 0.95), true, -1, true)
	# vastzittend pakje in de mint buis: buis zwelt op (4 Hz)
	for pp in pipe_paths:
		if pp[2] != STUCK_RACK:
			continue
		var pts2: PackedVector2Array = pp[0]
		var col2: Color = pp[1]
		var p2 := _path_point(pts2, 0.86)
		var sw := 1.0 + 0.12 * sin(t * TAU * 4.0)
		var bulge := Rect2(p2 - Vector2(64, 30) * sw, Vector2(128, 60) * sw)
		n.draw_style_box(_sb(C_OUTLINE, 30), bulge.grow(5))
		n.draw_style_box(_sb(col2.darkened(0.12), 30), bulge)
		_draw_parcel(n, p2, Vector2(104, 50), STUCK_BITS, A, false, 18)
	# aanwijsboog van het opgetilde pakje naar luik 01
	var from := Vector2(560, 210)
	var to := LIFT_POS + Vector2(-30, -70)
	for i in 8:
		var f := (i + fmod(t * 2.0, 1.0)) / 8.0
		var p3 := from.lerp(to, f) + Vector2(sin(f * PI) * 50, 0)
		n.draw_circle(p3, 4.5, Color(1, 1, 1, 0.7 * (1.0 - absf(f - 0.5) * 1.6)), true, -1, true)
