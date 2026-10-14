class_name ScPal
extends Object
## Kortschrift: palet, fonts en teksthelpers (design/ART.md §2–4). Alles statisch: `ScPal.word(ci, ...)`.
## Elementen tekenen staat in ScDraw (rekwisieten, personages, stroken) en ScDrawTools (de werktuigen);
## knoppen/panelen in ScUi; partikels in ScFx. Licht valt van linksboven (de kaars), schaduw naar rechtsonder.

# ---------------------------------------------------------------- UI: leren boekband met goudstempeling
const PANEL := Color("#3B2420")        # ossenbloed leer (HUD, menu's, panelen)
const PANEL_HI := Color("#52332C")     # knoppen, kopjes
const PANEL_LO := Color("#2A1916")     # verzonken vakken, pillen
const SLOT := Color("#1C100E")         # gaten, track van meters
const OUTLINE := Color("#170D0B")      # outline van zwevende tekst
const TEXT := Color("#FBF0D9")         # tekst op leer/donker (warm wit)
const TEXT_DIM := Color("#CDB394")     # secundaire tekst op donker
const GILT := Color("#D9A93E")         # goudstempeling: randen, lijnen op leer
const GILT_LIGHT := Color("#F4D27A")
const GILT_DARK := Color("#9C7224")
const SHADOW := Color(0.05, 0.02, 0.01, 0.40)
const SHADOW_SOFT := Color(0.05, 0.02, 0.01, 0.22)

# ---------------------------------------------------------------- perkament en inkt
const VELLUM := Color("#F2E4C4")       # perkament (opdrachtband, stroken, kaartjes)
const VELLUM_HI := Color("#FBF3DE")    # licht perkament (tegels, actieve vakken)
const VELLUM_EDGE := Color("#D8BF8E")  # onderrand/dikte van perkament
const VELLUM_AGED := Color("#C9A66E")  # verbruinde rand
const INK := Color("#2B1D14")          # ijzergalinkt: ALLE letters op perkament/chips
const INK_SOFT := Color("#7A6249")     # posities, nummers, touwtjes
const INK_FADED := Color("#A68E70")    # al gecodeerd / gedimd
const SEPIA := Color("#8E5A2E")        # "anders gelezen": bruine inkt (+ altijd een inktvlek)

# ---------------------------------------------------------------- pigmenten (verluchting)
const RUBRIC := Color("#B8402C")       # vermiljoen: initialen, rubrieken, rode draad (nooit "fout")
const RUBRIC_LIGHT := Color("#DE6A4E")
const LAPIS := Color("#2E5AA8")        # lapis lazuli: initiaalvelden, glas
const LAPIS_LIGHT := Color("#6FA8E8")
const VERDIGRIS := Color("#3E9A7E")    # kopergroen
const FOLIUM := Color("#7E4A9E")       # paars (liturgisch: Advent, Vasten)
const GOLD := Color("#E2B13C")         # bladgoud: sterren, "gelijk gelezen", optimum, interval
const GOLD_LIGHT := Color("#F7DB86")
const GOLD_DARK := Color("#A87A1E")
const WAX := Color("#A8302A")          # zegelwas (lakzegels, sterren)
const WAX_LIGHT := Color("#D25A4A")
const WAX_DARK := Color("#6E1B18")
const WAX_GREEN := Color("#4F7A3A")    # groene was (wassen zegel LZ77: andere kleur dan lakzegel)
const WAX_GREEN_DARK := Color("#2F4E22")

# ---------------------------------------------------------------- semantisch (familie met H&D/Trietuin, getemperd)
const OK := Color("#4DBF8F")           # goed / gelijk (kopergroen)
const WARN := Color("#E89B2C")         # amber: inkt boven het optimum, let op
const ERR := Color("#D5533F")          # zeer spaarzaam (kaars helemaal op). Nooit voor "fout antwoord"
const INFO := Color("#6FA8E8")         # lapis: cursor, selectie, focus, "hier kijk je"
const STAR := Color("#E8B53A")
const STAR_DARK := Color("#B07F1C")
const MATCH := GOLD                    # gouden stip in de voorlezing
const DIFF := SEPIA                    # bruine inkt + inktvlek
const BRAND := Color("#C77DFF")        # hubkleur Kortschrift (HubRegistry)
const BRAND_DARK := Color("#8E4CC4")

# ---------------------------------------------------------------- hout, steen, kaars
const OAK := Color("#9A6A3E")          # werktuigen: raam, kast, trommel, plank, boom
const OAK_LIGHT := Color("#C08A55")
const OAK_DARK := Color("#5E3B22")
const WALNUT := Color("#4A2E1C")
const STONE := Color("#4A3B39")
const STONE_DARK := Color("#2A2024")
const STONE_LIGHT := Color("#8C7562")
const COOL := Color("#33374A")         # De Overkant: koele maansteen
const COOL_LIGHT := Color("#6A6A80")
const FLAME := Color("#FFD27A")
const FLAME_CORE := Color("#FFF6D8")
const FLAME_OUT := Color("#FF9A3C")
const GLOW := Color("#FFB35A")
const CANDLE := Color("#EFE3C4")
const CANDLE_SHADE := Color("#CDB98E")
const BRASS := Color("#C79A45")
const BRASS_DARK := Color("#7E5C22")
const IRON := Color("#4B4A50")
const IRON_LIGHT := Color("#8E8C96")
const TWINE := Color("#C9A66B")
const TWINE_DARK := Color("#8E6E3E")
const THREAD := Color("#B8402C")       # rode draad (LZ77-match)

# ---------------------------------------------------------------- personages
const SKIN := Color("#EDBE9C")
const SKIN_SHADE := Color("#C98F73")
const BLUSH := Color("#E88A7E")
const BEARD := Color("#EEE8DC")
const HAIR := Color("#6B4A33")
const HABIT_ZENO := Color("#2F2A2C")       # zwart benedictijns habijt (mentor)
const HABIT_LETTERLIJK := Color("#8F887C") # grijs habijt (de lezer aan de overkant)
const HABIT_GOMMAAR := Color("#6B5233")    # bruin (kelner, telt de inkt)
const HABIT_NOVICE := Color("#B5A58A")     # ongebleekte wol
const HABITS := [Color("#7A6450"), Color("#6E6458"), Color("#857058"), Color("#6A5A4E")]  # processie (variatie)
const CORD := Color("#E6D3A8")
const DOVE := Color("#CFCAD4")
const DOVE_DARK := Color("#8F8A9A")
const DOVE_NECK := Color("#7FA897")
const DOVE_NECK2 := Color("#9A7FB3")
const DOVE_BEAK := Color("#E39A8C")
const SEED := Color("#7FB04F")             # nng-zaadje
const SEED_DARK := Color("#4E7A2C")

## Letterpigmenten: bleke manuscriptkleuren. Chip achter de letter, letter altijd INK (zoals de chips in Trietuin).
const LETTER_CYCLE := [Color("#F2C76B"), Color("#9FD0C0"), Color("#E8A2A0"), Color("#A9BCEB"), Color("#C9B3E0"),
	Color("#BFD889"), Color("#F0B07A"), Color("#8FD3E0"), Color("#E3B9D6"), Color("#D9CBA3")]
const CHIP_NEUTRAL := Color("#EDE1C4")
const CHIP_SPACE := Color("#E0D3B5")

## Meetlat: vakken krijgen kleur ÉN arcering (kleurenblind): 0 geen, 1 schuin, 2 recht, 3 stippen, 4 kruis.
const SEGMENT_COLORS := [Color("#E9C46A"), Color("#8FC1E3"), Color("#E79A8F"), Color("#A7D18B"), Color("#C9A9E0")]

## Hoofdstukken (getijdenboek): kleur van lint en initiaal per kerkelijke tijd.
const CHAPTERS := [
	{"id": "advent", "name": "Advent", "tool": "codeboom", "col": Color("#6E3F9E"), "field": LAPIS},
	{"id": "kerstmis", "name": "Kerstmis", "tool": "binderij", "col": Color("#B8402C"), "field": Color("#2F6E4E")},
	{"id": "vasten", "name": "Vasten", "tool": "levende boom", "col": Color("#6E3F9E"), "field": Color("#5A2E3A")},
	{"id": "pasen", "name": "Pasen", "tool": "meetlat", "col": Color("#E2B13C"), "field": LAPIS},
	{"id": "pinksteren", "name": "Pinksteren", "tool": "leesraam", "col": Color("#B8402C"), "field": Color("#8A2A20")},
	{"id": "hooimaand", "name": "Hooimaand", "tool": "stempelkast", "col": Color("#3E9A7E"), "field": Color("#6A5420")},
	{"id": "wijnmaand", "name": "Wijnmaand", "tool": "draaitrommel", "col": Color("#7A2E4A"), "field": Color("#3A2A5E")},
	{"id": "allerheiligen", "name": "Allerheiligen", "tool": "codex", "col": Color("#E2B13C"), "field": Color("#2A2A3A")},
]

# ---------------------------------------------------------------- paden en fonts
const ASSETS := "res://games/scriptorium/assets/"
const FONT_MONO_PATH := "res://assets/fonts/JetBrainsMono-ExtraBold.ttf"
const FONT_MONO_B_PATH := "res://assets/fonts/JetBrainsMono-Bold.ttf"
const FONT_MONO_M_PATH := "res://assets/fonts/JetBrainsMono-Medium.ttf"
const FONT_UI_PATH := "res://assets/fonts/Fredoka-SemiBold.ttf"
const FONT_UI_BOLD_PATH := "res://assets/fonts/Fredoka-Bold.ttf"
const FONT_UI_MED_PATH := "res://assets/fonts/Fredoka-Medium.ttf"
const FONT_TITLE_PATH := "res://games/scriptorium/assets/fonts/GrenzeGotisch-Variable.ttf"
const FONT_INITIAL_PATH := "res://games/scriptorium/assets/fonts/UnifrakturMaguntia-Book.ttf"

## JetBrains Mono als MSDF: bits, codes, letters en getallen blijven scherp bij zoom (meetlat) en schaal-tweens.
static var MONO: Font = _msdf(FONT_MONO_PATH)
static var MONO_B: Font = _msdf(FONT_MONO_B_PATH)
static var MONO_M: Font = _msdf(FONT_MONO_M_PATH)
static var UI: Font = load(FONT_UI_PATH)
static var UI_BOLD: Font = load(FONT_UI_BOLD_PATH)
static var UI_MED: Font = load(FONT_UI_MED_PATH)
## Titels, hoofdstukken, kopjes van panelen: Grenze Gotisch (OFL), gewicht 700. Nooit voor bits/codes of lopende zinnen.
static var TITLE: Font = _variable(FONT_TITLE_PATH, 700)
static var TITLE_LIGHT: Font = _variable(FONT_TITLE_PATH, 500)
## Verluchte initialen (één hoofdletter op een goud/lapisveld): UnifrakturMaguntia (OFL).
static var INITIAL: Font = load(FONT_INITIAL_PATH)

static var _sb_cache := {}
static var _tex_cache := {}


static func _msdf(path: String) -> Font:
	var src := load(path) as FontFile
	if src == null:
		return ThemeDB.fallback_font
	var f := src.duplicate() as FontFile
	f.multichannel_signed_distance_field = true
	f.msdf_pixel_range = 8
	f.msdf_size = 48
	return f


static func _variable(path: String, wght: int) -> Font:
	var base := load(path) as FontFile
	if base == null:
		return ThemeDB.fallback_font
	var fv := FontVariation.new()
	fv.base_font = base
	var ts := TextServerManager.get_primary_interface()
	fv.variation_opentype = {ts.name_to_tag("wght"): wght}
	return fv


## Textuur uit assets/ (gecachet). `rel` bv. "art/tex/vellum.png".
static func tex(rel: String) -> Texture2D:
	if not _tex_cache.has(rel):
		var p := ASSETS + rel
		_tex_cache[rel] = load(p) if ResourceLoader.exists(p) else null
	return _tex_cache[rel]


static func particle(name_: String) -> Texture2D:
	return tex("art/particles/%s.png" % name_)


static func chapter(i: int) -> Dictionary:
	return CHAPTERS[clampi(i, 0, CHAPTERS.size() - 1)]


## Weergave van een teken: spatie = ␣ (GDD §3.0); EOF blijft "EOF".
static func show(ch: String) -> String:
	return "␣" if ch == " " else ch


static func show_text(s: String) -> String:
	return s.replace(" ", "␣")


## Pigmentchip voor een letter. `alphabet` = de letters van het level in vaste volgorde (bv. van de stapelrij);
## > 10 letters -> neutrale chips. De spatie krijgt altijd CHIP_SPACE.
static func letter_color(ch: String, alphabet := "") -> Color:
	if ch == " " or ch == "␣":
		return CHIP_SPACE
	if alphabet == "" or alphabet.length() > LETTER_CYCLE.size():
		return CHIP_NEUTRAL
	var i := alphabet.find(ch)
	if i < 0:
		return CHIP_NEUTRAL
	return LETTER_CYCLE[i % LETTER_CYCLE.size()]


## Kleur van het k-de vak op de meetlat (+ arceringsindex via `segment_hatch`).
static func segment_color(k: int) -> Color:
	return SEGMENT_COLORS[k % SEGMENT_COLORS.size()]


static func segment_hatch(k: int) -> int:
	return k % 5


# ---------------------------------------------------------------- styleboxen
## Gecachete StyleBoxFlat (niet muteren!).
static func sb(col: Color, radius: int, shadow := 0, shadow_off := Vector2(0, 6), shadow_col := SHADOW) -> StyleBoxFlat:
	var key := [col, radius, shadow, shadow_off, shadow_col]
	var hit = _sb_cache.get(key)
	if hit:
		return hit
	var s := sbn(col, radius, shadow, shadow_off, shadow_col)
	if _sb_cache.size() > 4000:
		_sb_cache.clear()
	_sb_cache[key] = s
	return s


## Nieuwe (muteerbare) StyleBoxFlat.
static func sbn(col: Color, radius: int, shadow := 0, shadow_off := Vector2(0, 6), shadow_col := SHADOW) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(radius)
	s.anti_aliasing = true
	s.corner_detail = 8
	if shadow > 0:
		s.shadow_color = shadow_col
		s.shadow_size = shadow
		s.shadow_offset = shadow_off
	return s


## Tastbaar vlak met dikke onderrand (tegels, kaartjes), gecachet.
static func sb_thick(col: Color, radius: int, bottom: int, edge: Color) -> StyleBoxFlat:
	var key := ["thick", col, radius, bottom, edge]
	var hit = _sb_cache.get(key)
	if hit:
		return hit
	var s := sbn(col, radius)
	s.border_color = edge
	s.border_width_bottom = bottom
	_sb_cache[key] = s
	return s


static func ring(ci: CanvasItem, r: Rect2, radius: int, col: Color, w: int) -> void:
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
	if s == "␣" or s == " ":
		space_glyph(ci, center, size, col)
		return
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var asc := font.get_ascent(size)
	var desc := font.get_descent(size)
	ci.draw_string(font, Vector2(round(center.x - w.x / 2.0), round(center.y + (asc - desc) / 2.0)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## Zichtbare spatie ␣ als getekend open bakje met hoge pootjes: in JetBrains Mono lijkt ␣ op klein formaat te veel op
## het liggend streepje `_`, dat in Oef. 81/97/101 een gewoon teken is (GDD §3.0).
static func space_glyph(ci: CanvasItem, center: Vector2, size: int, col: Color) -> void:
	var w := char_w(size) * 0.62
	var y0 := center.y - size * 0.02
	var y1 := center.y + size * 0.30
	var lw := maxf(2.0, size * 0.09)
	ci.draw_polyline(PackedVector2Array([Vector2(center.x - w / 2, y0), Vector2(center.x - w / 2, y1),
		Vector2(center.x + w / 2, y1), Vector2(center.x + w / 2, y0)]), col, lw, true)


static func text_l(ci: CanvasItem, font: Font, left_mid: Vector2, s: String, size: int, col: Color) -> float:
	var asc := font.get_ascent(size)
	var desc := font.get_descent(size)
	ci.draw_string(font, Vector2(round(left_mid.x), round(left_mid.y + (asc - desc) / 2.0)), s, HORIZONTAL_ALIGNMENT_LEFT,
		-1, size, col)
	return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func text_r(ci: CanvasItem, font: Font, right_mid: Vector2, s: String, size: int, col: Color) -> float:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var asc := font.get_ascent(size)
	var desc := font.get_descent(size)
	ci.draw_string(font, Vector2(round(right_mid.x - w), round(right_mid.y + (asc - desc) / 2.0)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	return w


static func text_w(font: Font, s: String, size: int) -> float:
	return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func text_outline_c(ci: CanvasItem, font: Font, center: Vector2, s: String, size: int, col: Color, outline := 8,
		ocol := OUTLINE) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var asc := font.get_ascent(size)
	var desc := font.get_descent(size)
	var p := Vector2(round(center.x - w.x / 2.0), round(center.y + (asc - desc) / 2.0))
	ci.draw_string_outline(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, ocol)
	ci.draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## Zin met gemengde fonts: parts = [["Bind ", "ui"], ["b", "mono"], [" en ", "ui"], ["s", "mono"]]. Mono-stukken
## krijgen pigmentchips als `chips`. Geeft de breedte terug. `measure_only` tekent niets.
static func rich_line(ci: CanvasItem, left_mid: Vector2, parts: Array, size: int, col := INK, chips := true,
		alphabet := "", measure_only := false) -> float:
	var x := left_mid.x
	for p in parts:
		var s: String = p[0]
		var kind: String = p[1] if p.size() > 1 else "ui"
		if kind == "mono":
			var ms := int(round(size * 0.95))
			var w := word_width(s.length(), ms)
			if not measure_only:
				word(ci, Vector2(x + w / 2.0 + 2, left_mid.y), s, ms, chips, alphabet)
			x += w + 4
		else:
			var f := UI_BOLD if kind == "bold" else (TITLE if kind == "title" else UI)
			var w2 := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			if not measure_only:
				text_l(ci, f, Vector2(x, left_mid.y), s, size, col)
			x += w2
	return x - left_mid.x


# ---------------------------------------------------------------- woorden (mono, pigmentchips)
static func char_w(size: int) -> float:
	return MONO.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func word_gap(size: int) -> float:
	return maxf(2.0, size * 0.10)


static func word_width(n: int, size: int) -> float:
	if n <= 0:
		return 0.0
	return n * char_w(size) + (n - 1) * word_gap(size)


## Woord in JetBrains Mono, gecentreerd op `center` (spaties tonen als ␣). `chips`: pigmentchip per letter.
## `hi_from..hi_to`: ring in `hi_col`. `dim_before`/`dim_after`: gedimde letters (al gecodeerd / nog niet gelezen).
static func word(ci: CanvasItem, center: Vector2, s: String, size: int, chips := true, alphabet := "",
		hi_from := -1, hi_to := -1, hi_col := INFO, dim_after := -1, ink := INK, dim_before := -1) -> float:
	var cw := char_w(size)
	var gap := word_gap(size)
	var total := word_width(s.length(), size)
	var x := center.x - total / 2.0
	var asc := MONO.get_ascent(size)
	var desc := MONO.get_descent(size)
	var rad := int(size * 0.22)
	for i in s.length():
		var ch := s[i]
		var r := Rect2(x - size * 0.05, center.y - size * 0.62, cw + size * 0.10, size * 1.24)
		var dim := (dim_after >= 0 and i >= dim_after) or (dim_before >= 0 and i < dim_before)
		var a := 0.4 if dim else 1.0
		if chips:
			var cc := letter_color(ch, alphabet)
			cc.a *= a
			ci.draw_style_box(sb(cc, rad), r)
		if i >= hi_from and i <= hi_to and hi_from >= 0:
			ring(ci, r.grow(3), rad + 3, hi_col, 3)
		if ch == " ":
			space_glyph(ci, Vector2(x + cw / 2.0, center.y), size, Color(ink, a))
		else:
			ci.draw_string(MONO, Vector2(round(x), round(center.y + (asc - desc) / 2.0)), ch, HORIZONTAL_ALIGNMENT_LEFT,
				-1, size, Color(ink, a))
		x += cw + gap
	return total


## Grootste fontgrootte (>= min_size) zodat een woord van n letters in `width` past.
static func fit_word(n: int, width: float, max_size: int, min_size := 18) -> int:
	var s := max_size
	while s > min_size and word_width(n, s) > width:
		s -= 1
	return s
