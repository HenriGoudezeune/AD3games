class_name TxPal
extends Object
## TELEX — palet, fonts, maten en stijlhulpen (design/ART.md §2–5). Alles statisch: `TxPal.lamp(ci, ...)`.
## Elementen (lint, sjabloon, machines, personages) tekent `TxDraw`; dit bestand bevat de bouwstenen.
## Tik nooit zelf hexwaarden in: gebruik de tokens hieronder.

# ---------------------------------------------------------------- palet: wereld (ver → dichtbij)
const NIGHT := Color("#0B1112")        ## diepste laag, vignet, gaten in het lint
const BUNKER := Color("#131C1B")       ## muur achter de console
const CONSOLE_LO := Color("#18221F")   ## verzonken vlakken (sleuven, rooster-achtergrond)
const CONSOLE := Color("#22302C")      ## hamerslaglak: hoofdpanelen
const CONSOLE_HI := Color("#2F403A")   ## opstaande randen, kopjes van panelen
const CONSOLE_EDGE := Color("#0A0F0E") ## contour, voegen
const BAKELITE_LO := Color("#1A120D")
const BAKELITE := Color("#2B1F18")     ## knoppen, behuizingen (tikteller, hendelknoppen)
const BAKELITE_HI := Color("#4A3527")
const BRASS_LO := Color("#7D5E26")
const BRASS := Color("#C9A04B")        ## messing: leeskop, typeplaatjes, randen, wijzers
const BRASS_HI := Color("#F0D68C")
const STEEL_LO := Color("#5E6A69")
const STEEL := Color("#9AA6A4")        ## sjabloon, naald, tanden
const STEEL_HI := Color("#DCE4E1")
const WOOD := Color("#6B4426")         ## kaartenbak, kist
const WOOD_HI := Color("#8E5F37")
const WOOD_LO := Color("#43291A")
const RUBBER := Color("#141414")       ## rol van de inlaat, kabelmantel

# ---------------------------------------------------------------- palet: papier & inkt
const PAPER := Color("#EFE3C4")        ## telexlint
const PAPER_HI := Color("#FBF4E1")
const PAPER_SHADE := Color("#D6C59C")
const PAPER_EDGE := Color("#B8A578")
const MANILA := Color("#E2C98E")       ## ponsstrook, ponskaarten, dossiermappen
const MANILA_LO := Color("#C4A866")
const CARD := Color("#F4EEDC")         ## kaartjes in de kaartenbak, notas
const INK := Color("#201A14")          ## typemachine-inkt (tekens op papier)
const INK_SOFT := Color("#5C5140")     ## posities, bijschriften op papier
const STAMP_RED := Color("#C23B2E")
const STAMP_BLUE := Color("#3E66C4")   ## gemeld voorkomen (stempelband), buizenpost-etiket
const PENCIL := Color("#6E6A62")

# ---------------------------------------------------------------- palet: signalen (lampen)
## Gelijk/verschil zijn ook kleurenblind-veilig: groen is blauwig en licht, rood is oranjeachtig en donkerder,
## en ze krijgen ALTIJD ook een vorm (✓ / ✕) — zie lamp().
const SIG_EQ := Color("#3FE6A6")       ## gelijk, treffer, stroom OK
const SIG_EQ_DIM := Color("#16443A")
const SIG_NE := Color("#FF5A36")       ## verschil, mismatch, gemist
const SIG_NE_DIM := Color("#4A1D14")
const SIG_AMBER := Color("#FFB23E")    ## waarschuwing, lusbak bijna vol, warme cel, geest-balk overschreden
const SIG_AMBER_DIM := Color("#4A3415")
const SIG_BLUE := Color("#6FA8FF")     ## gemeld / info / spookhand-hint
const SIG_WHITE := Color("#FFF4D6")    ## warm wit: leeskop gloeit ("gaat niet terug"), voedingslamp
const SIG_GREY := Color("#8C948F")     ## vals alarm (grijze speld), klem
const HEAT := Color("#FF8A3D")         ## WRONG_MIN-cel
const LAMP_GLASS := Color("#24322D")   ## lamp uit

# ---------------------------------------------------------------- palet: UI-tekst
const TEXT := Color("#EDE5D3")
const TEXT_DIM := Color("#96A39C")
const TEXT_ON_BRASS := Color("#2A1E0E")
const SHADOW := Color(0.0, 0.02, 0.02, 0.5)
const SHADOW_SOFT := Color(0.0, 0.02, 0.02, 0.28)

## kleuren voor kolommen van het ruisbord (M⁰, M¹, M²) en bellen
const LEVEL_COLORS := [Color("#3FE6A6"), Color("#FFB23E"), Color("#FF7AC8")]

# ---------------------------------------------------------------- fonts
const FONT_TAPE_PATH := "res://games/telex/assets/fonts/CourierPrime-Bold.ttf"      ## lint, sjabloon, strook, notas
const FONT_TAPE_REG_PATH := "res://games/telex/assets/fonts/CourierPrime-Regular.ttf"
const FONT_STENCIL_PATH := "res://games/telex/assets/fonts/SairaStencilOne-Regular.ttf" ## typeplaatjes, titel, stempels
const FONT_MONO_PATH := "res://assets/fonts/JetBrainsMono-ExtraBold.ttf"            ## rolcijfers, meters, indices
const FONT_MONO_B_PATH := "res://assets/fonts/JetBrainsMono-Bold.ttf"
const FONT_UI_PATH := "res://assets/fonts/Fredoka-SemiBold.ttf"                     ## UI-tekst, Chef
const FONT_UI_BOLD_PATH := "res://assets/fonts/Fredoka-Bold.ttf"                    ## knoppen, HUD-titels

static var TAPE: Font = load(FONT_TAPE_PATH)
static var TAPE_REG: Font = load(FONT_TAPE_REG_PATH)
static var STENCIL: Font = load(FONT_STENCIL_PATH)
static var MONO: Font = load(FONT_MONO_PATH)
static var MONO_B: Font = load(FONT_MONO_B_PATH)
static var UI: Font = load(FONT_UI_PATH)
static var UI_BOLD: Font = load(FONT_UI_BOLD_PATH)

# ---------------------------------------------------------------- maten (1920×1080, ART.md §4)
const TAPE_CELL := 44.0        ## kolombreedte lint/sjabloon/strook bij |t| ≤ 40 (fontgrootte 44)
const TAPE_CELL_SMALL := 34.0  ## bij langere linten (fontgrootte 32)
const TAPE_H := 106.0          ## hoogte papierstrook (code-gaten 0..34, tekens 34..100)
const STENCIL_H := 80.0
const STRIP_H := 46.0
const POS_FONT := 18
## verticale indeling van de console (y-waarden, zie ART.md §4.1)
const Y_HUD := 0.0
const Y_HEAD := 64.0
const Y_TAPE := 100.0
const Y_POS := 208.0
const Y_STENCIL := 236.0
const Y_STRIP := 334.0
const Y_PANEL := 392.0
const Y_BOTTOM := 868.0

# ---------------------------------------------------------------- texturen
const ART := "res://games/telex/assets/art/"
const SFX := "res://games/telex/assets/sfx/"
const MUSIC := "res://games/telex/assets/music/"

static var _tex := {}


static func tex(rel: String) -> Texture2D:
	## `tex("tex/paper_tile.png")`, `tex("particles/glow.png")`, `tex("stamps/ster.png")`
	if not _tex.has(rel):
		_tex[rel] = load(ART + rel)
	return _tex[rel]


# ---------------------------------------------------------------- ITA2 (Baudot-Murray): de 5 ponsgaten per teken
## bit 1..5 van boven naar onder (1 = gat). Enkel decor: het lint toont zo "echte" telexcode boven elk teken.
const ITA2 := {
	"a": "11000", "b": "10011", "c": "01110", "d": "10010", "e": "10000", "f": "10110", "g": "01011",
	"h": "00101", "i": "01100", "j": "11010", "k": "11110", "l": "01001", "m": "00111", "n": "00110",
	"o": "00011", "p": "01101", "q": "11101", "r": "01010", "s": "10100", "t": "00001", "u": "11100",
	"v": "01111", "w": "11001", "x": "10111", "y": "10101", "z": "10001", "_": "00100", " ": "00100",
	"0": "01101", "1": "11101", "2": "11001", "3": "10000", "4": "01010", "5": "00001", "6": "10101",
	"7": "11100", "8": "01100", "9": "00011", "'": "11010", "?": "10011", "#": "00000",
}


static func ita2(ch: String) -> String:
	return ITA2.get(ch.to_lower(), "00000")


# ---------------------------------------------------------------- styleboxen
static var _sb_cache := {}


## Gecachete StyleBoxFlat. Niet muteren.
static func sb(col: Color, radius: int, shadow := 0, shadow_off := Vector2(0, 5), border := 0, border_col := Color.TRANSPARENT) -> StyleBoxFlat:
	var key := [col, radius, shadow, shadow_off, border, border_col]
	var hit = _sb_cache.get(key)
	if hit:
		return hit
	var s := sbn(col, radius, shadow, shadow_off)
	if border > 0:
		s.set_border_width_all(border)
		s.border_color = border_col
	if _sb_cache.size() > 4000:
		_sb_cache.clear()
	_sb_cache[key] = s
	return s


## Nieuwe (muteerbare) StyleBoxFlat.
static func sbn(col: Color, radius: int, shadow := 0, shadow_off := Vector2(0, 5)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(radius)
	s.anti_aliasing = true
	s.corner_detail = 8
	if shadow > 0:
		s.shadow_color = SHADOW
		s.shadow_size = shadow
		s.shadow_offset = shadow_off
	return s


static func box(ci: CanvasItem, r: Rect2, col: Color, radius := 6, shadow := 0, border := 0, border_col := Color.TRANSPARENT) -> void:
	ci.draw_style_box(sb(col, radius, shadow, Vector2(0, shadow * 0.5), border, border_col), r)


static func ring(ci: CanvasItem, r: Rect2, col: Color, radius := 6, w := 2) -> void:
	var key := ["ring", col, radius, w]
	var g = _sb_cache.get(key)
	if g == null:
		g = sbn(Color(0, 0, 0, 0), radius)
		g.draw_center = false
		g.border_color = col
		g.set_border_width_all(w)
		_sb_cache[key] = g
	ci.draw_style_box(g, r)


# ---------------------------------------------------------------- tekst
static func text_c(ci: CanvasItem, font: Font, center: Vector2, s: String, size: int, col: Color) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var asc := font.get_ascent(size)
	var desc := font.get_descent(size)
	ci.draw_string(font, Vector2(center.x - w / 2.0, center.y + (asc - desc) / 2.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


static func text_l(ci: CanvasItem, font: Font, left_mid: Vector2, s: String, size: int, col: Color) -> float:
	var asc := font.get_ascent(size)
	var desc := font.get_descent(size)
	ci.draw_string(font, Vector2(left_mid.x, left_mid.y + (asc - desc) / 2.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func text_r(ci: CanvasItem, font: Font, right_mid: Vector2, s: String, size: int, col: Color) -> float:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var asc := font.get_ascent(size)
	var desc := font.get_descent(size)
	ci.draw_string(font, Vector2(right_mid.x - w, right_mid.y + (asc - desc) / 2.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	return w


static func text_w(font: Font, s: String, size: int) -> float:
	return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## Gegraveerde tekst (messing/staal): donkere letter + 1 px lichte rand eronder.
static func engraved(ci: CanvasItem, font: Font, center: Vector2, s: String, size: int, base: Color) -> void:
	text_c(ci, font, center + Vector2(0, 1), s, size, base.lightened(0.45))
	text_c(ci, font, center, s, size, base.darkened(0.62))


# ---------------------------------------------------------------- bouwstenen
## Console-paneel: hamerslaglak met schuine rand (licht linksboven), optioneel klinknagels en een messing kopplaatje.
static func panel(ci: CanvasItem, r: Rect2, col := CONSOLE, rivets := true, radius := 10) -> void:
	ci.draw_style_box(sb(SHADOW, radius + 2), Rect2(r.position + Vector2(0, 6), r.size))
	ci.draw_style_box(sb(col.darkened(0.45), radius), r)
	var inner := r.grow(-3)
	ci.draw_style_box(sb(col, radius - 2), inner)
	ci.draw_texture_rect(tex("tex/hammertone.png"), inner.grow(-2), true, Color(1, 1, 1, 0.07))
	# schuine rand: licht boven/links, donker onder/rechts
	ci.draw_line(inner.position + Vector2(radius, 1), Vector2(inner.end.x - radius, inner.position.y + 1), col.lightened(0.22), 2.0)
	ci.draw_line(inner.position + Vector2(1, radius), Vector2(inner.position.x + 1, inner.end.y - radius), col.lightened(0.12), 2.0)
	ci.draw_line(Vector2(inner.position.x + radius, inner.end.y - 1), inner.end - Vector2(radius, 1), col.darkened(0.35), 2.0)
	if rivets:
		for p in [inner.position + Vector2(12, 12), Vector2(inner.end.x - 12, inner.position.y + 12),
				Vector2(inner.position.x + 12, inner.end.y - 12), inner.end - Vector2(12, 12)]:
			rivet(ci, p, 4.0)


## Verzonken vlak (sleuf, venster) in een paneel.
static func well(ci: CanvasItem, r: Rect2, col := CONSOLE_LO, radius := 6) -> void:
	ci.draw_style_box(sb(col, radius), r)
	ci.draw_line(r.position + Vector2(radius, 1.5), Vector2(r.end.x - radius, r.position.y + 1.5), Color(0, 0, 0, 0.55), 3.0)
	ci.draw_line(Vector2(r.position.x + radius, r.end.y - 1), r.end - Vector2(radius, 1), Color(1, 1, 1, 0.06), 2.0)


static func rivet(ci: CanvasItem, p: Vector2, r := 4.0, col := STEEL) -> void:
	ci.draw_circle(p + Vector2(0.6, 1.2), r, Color(0, 0, 0, 0.45), true, -1.0, true)
	ci.draw_circle(p, r, col.darkened(0.25), true, -1.0, true)
	ci.draw_circle(p - Vector2(r * 0.25, r * 0.25), r * 0.55, col.lightened(0.25), true, -1.0, true)


static func screw(ci: CanvasItem, p: Vector2, r := 6.0, ang := 0.6) -> void:
	rivet(ci, p, r, STEEL)
	var d := Vector2(cos(ang), sin(ang)) * r * 0.7
	ci.draw_line(p - d, p + d, STEEL_LO.darkened(0.4), 1.6, true)


## Messing typeplaatje met gegraveerde tekst en twee klinknagels. `sheen` 0..1 = glansstreep (juice #37).
static func brass_plate(ci: CanvasItem, center: Vector2, s: String, size := 20, font: Font = null, sheen := -1.0) -> Rect2:
	var f := font if font else STENCIL
	var w := text_w(f, s, size) + size * 2.6
	var h := size * 1.7
	var r := Rect2(center - Vector2(w, h) / 2.0, Vector2(w, h))
	ci.draw_style_box(sb(SHADOW, 5), Rect2(r.position + Vector2(1, 3), r.size))
	ci.draw_style_box(sb(BRASS_LO, 5), r)
	ci.draw_style_box(sb(BRASS, 4), r.grow(-2))
	ci.draw_rect(Rect2(r.position + Vector2(4, 3), Vector2(r.size.x - 8, r.size.y * 0.32)), Color(BRASS_HI, 0.35))
	if sheen >= 0.0 and sheen <= 1.0:
		var x := r.position.x + r.size.x * (sheen * 1.4 - 0.2)
		var pts := PackedVector2Array([Vector2(x, r.position.y + 2), Vector2(x + 18, r.position.y + 2),
			Vector2(x + 6, r.end.y - 2), Vector2(x - 12, r.end.y - 2)])
		ci.draw_colored_polygon(pts, Color(1, 1, 0.9, 0.45))
	engraved(ci, f, center, s, size, BRASS)
	rivet(ci, Vector2(r.position.x + size * 0.55, center.y), 3.0, BRASS)
	rivet(ci, Vector2(r.end.x - size * 0.55, center.y), 3.0, BRASS)
	return r


## Signaallamp met chromen rand, glas, gloed en (kleurenblind-veilige) vorm.
## state: 0 uit, 1 aan. shape: "", "ok" (✓), "ne" (✕), "dot". glow 0..1 extra nagloei.
static func lamp(ci: CanvasItem, c: Vector2, r: float, col: Color, state := 1.0, shape := "", glow := 0.0) -> void:
	ci.draw_circle(c + Vector2(0, 2), r + 4, Color(0, 0, 0, 0.5), true, -1.0, true)
	ci.draw_circle(c, r + 3.5, STEEL_LO, true, -1.0, true)
	ci.draw_arc(c, r + 2.5, PI * 1.05, PI * 1.75, 16, STEEL_HI, 1.5, true)
	var on := clampf(state, 0.0, 1.0)
	var glass := LAMP_GLASS.lerp(col, 0.18).lerp(col, on * 0.82)
	ci.draw_circle(c, r, glass, true, -1.0, true)
	if on > 0.01 or glow > 0.01:
		var g := maxf(on, glow)
		var gs := r * 5.0
		ci.draw_texture_rect(tex("particles/glow.png"), Rect2(c - Vector2(gs, gs) / 2.0, Vector2(gs, gs)), false, Color(col, 0.45 * g))
		ci.draw_circle(c, r * 0.62, col.lightened(0.55 * on), true, -1.0, true)
	ci.draw_circle(c + Vector2(-r * 0.32, -r * 0.36), r * 0.28, Color(1, 1, 1, 0.22 + 0.25 * on), true, -1.0, true)
	var ink := Color(0.05, 0.08, 0.07, 0.85) if on > 0.5 else Color(col.lightened(0.2), 0.8)
	var k := r * 0.42
	match shape:
		"ok":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-k, 0), c + Vector2(-k * 0.25, k * 0.75), c + Vector2(k, -k * 0.7)]), ink, maxf(2.0, r * 0.22), true)
		"ne":
			ci.draw_line(c + Vector2(-k, -k), c + Vector2(k, k), ink, maxf(2.0, r * 0.22), true)
			ci.draw_line(c + Vector2(-k, k), c + Vector2(k, -k), ink, maxf(2.0, r * 0.22), true)
		"dot":
			ci.draw_circle(c, r * 0.22, ink, true, -1.0, true)


## Zachte gloed (geen additive blend nodig op donkere achtergrond).
static func glow(ci: CanvasItem, c: Vector2, size: float, col: Color, a := 0.5) -> void:
	ci.draw_texture_rect(tex("particles/glow.png"), Rect2(c - Vector2(size, size) / 2.0, Vector2(size, size)), false, Color(col, a))


## Bakelieten draaiknop met messing wijzer (waarde-instelling, ponsbank).
static func knob(ci: CanvasItem, c: Vector2, r: float, ang: float, label := "") -> void:
	ci.draw_circle(c + Vector2(0, 3), r + 2, SHADOW, true, -1.0, true)
	var n := 18
	var pts := PackedVector2Array()
	for i in n * 2:
		var a := TAU * i / (n * 2)
		var rr := r if i % 2 == 0 else r - 3.0
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	ci.draw_colored_polygon(pts, BAKELITE)
	ci.draw_circle(c, r - 5, BAKELITE_HI, true, -1.0, true)
	ci.draw_circle(c - Vector2(r, r) * 0.18, r * 0.5, Color(1, 1, 1, 0.05), true, -1.0, true)
	var d := Vector2(cos(ang), sin(ang))
	ci.draw_line(c + d * r * 0.2, c + d * (r - 6), BRASS_HI, 3.0, true)
	if label != "":
		text_c(ci, MONO, c + Vector2(0, r + 16), label, 16, TEXT_DIM)


## Kleine Chef-/hint-wijzerhand (spookhand): handschoen-silhouet, voor tutorials.
static func ghost_hand(ci: CanvasItem, tip: Vector2, s := 1.0, col := SIG_BLUE, a := 0.8) -> void:
	var c := Color(col, a)
	var o := tip
	var pts := PackedVector2Array([o, o + Vector2(7, 2) * s, o + Vector2(9, 22) * s, o + Vector2(16, 18) * s,
		o + Vector2(24, 22) * s, o + Vector2(31, 26) * s, o + Vector2(34, 44) * s, o + Vector2(26, 58) * s,
		o + Vector2(8, 58) * s, o + Vector2(-2, 42) * s, o + Vector2(-8, 30) * s, o + Vector2(-4, 26) * s,
		o + Vector2(2, 32) * s, o + Vector2(-2, 4) * s])
	ci.draw_colored_polygon(pts, c)
	pts.append(pts[0])
	ci.draw_polyline(pts, Color(1, 1, 1, a * 0.9), 2.0, true)


# ---------------------------------------------------------------- UI-thema (knoppen = bakelieten toetsen)
static var _theme: Theme


static func theme() -> Theme:
	if _theme:
		return _theme
	_theme = Theme.new()
	_theme.default_font = UI
	_theme.default_font_size = 24
	_theme.set_color("font_color", "Label", TEXT)
	return _theme


static func _key_box(col: Color, lift := 0.0, rim := BRASS) -> StyleBoxFlat:
	var s := sbn(col, 10)
	s.border_color = col.darkened(0.55)
	s.border_width_bottom = int(7 - lift)
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.content_margin_left = 30
	s.content_margin_right = 30
	s.content_margin_top = 10 + lift
	s.content_margin_bottom = 10
	s.expand_margin_top = lift
	s.shadow_color = Color(0, 0.02, 0.02, 0.45)
	s.shadow_size = 7
	s.shadow_offset = Vector2(0, 5)
	if rim.a > 0.0:
		s.border_color = rim.darkened(0.25) if lift >= 0 else rim.darkened(0.45)
		s.border_width_bottom = int(7 - lift)
	return s


## Bakelieten toets (UI-knop). kind: "key" (donker, messing rand), "brass" (primair), "red" (gevaar), "flat".
## Hover: 3 px omhoog; klik: squash. Geluid koppelt de front-end (sfx/ui_key.wav, ui_hover.wav).
static func button(text: String, kind := "key", size := 28, min_w := 260.0) -> Button:
	var col := BAKELITE
	var fg := TEXT
	var rim := BRASS
	match kind:
		"brass":
			col = BRASS
			fg = TEXT_ON_BRASS
			rim = BRASS_LO
		"red":
			col = Color("#8E2A20")
			fg = Color("#FFE9DC")
			rim = Color("#5A1710")
		"flat":
			col = CONSOLE_HI
			rim = Color.TRANSPARENT
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", UI_BOLD)
	b.add_theme_font_size_override("font_size", size)
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(st, fg)
	b.add_theme_color_override("font_disabled_color", Color(fg, 0.4))
	b.add_theme_stylebox_override("normal", _key_box(col, 0, rim))
	b.add_theme_stylebox_override("hover", _key_box(col.lightened(0.10), 3, rim))
	b.add_theme_stylebox_override("pressed", _key_box(col.darkened(0.10), -3, rim))
	b.add_theme_stylebox_override("disabled", _key_box(col.darkened(0.35), 0, rim.darkened(0.4)))
	var f := _key_box(col.lightened(0.10), 3, rim)
	f.border_color = SIG_AMBER
	f.set_border_width_all(3)
	f.border_width_bottom = 4
	b.add_theme_stylebox_override("focus", f)
	b.custom_minimum_size = Vector2(min_w, 0)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.button_down.connect(func():
		b.pivot_offset = b.size / 2.0
		var tw := b.create_tween().set_ignore_time_scale(true)
		tw.tween_property(b, "scale", Vector2(1.04, 0.92), 0.05)
		tw.tween_property(b, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT))
	return b


static func label(text: String, size := 24, col := TEXT, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if font else UI)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


## Paneel-stylebox voor Control-panelen (PanelContainer).
static func panel_box(col := CONSOLE, radius := 12) -> StyleBoxFlat:
	var s := sbn(col, radius, 16, Vector2(0, 8))
	s.border_color = col.darkened(0.45)
	s.set_border_width_all(3)
	s.content_margin_left = 28
	s.content_margin_right = 28
	s.content_margin_top = 24
	s.content_margin_bottom = 24
	return s


## Papieren notitie-stylebox (Chef-ballon, tooltip, briefing).
static func paper_box(radius := 4) -> StyleBoxFlat:
	var s := sbn(CARD, radius, 10, Vector2(2, 6))
	s.border_color = PAPER_EDGE
	s.set_border_width_all(1)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	return s
