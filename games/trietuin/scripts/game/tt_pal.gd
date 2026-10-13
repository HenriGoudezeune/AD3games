class_name TtPal
extends Object
## Trietuin: palet, seizoenen, fonts en teksthelpers (design/ART.md §2–4). Alles statisch: `TtPal.word(ci, ...)`.
## Elementen (takken, vruchten, bijen ...) tekenen staat in TtDraw; knoppen/panelen in TtUi.

enum Season { LENTE, ZOMER, HERFST, WINTER }

# ---------------------------------------------------------------- UI (gelijk in alle seizoenen)
const PANEL := Color("#24372E")        # "bosgroen" paneel (HUD, menu's)
const PANEL_HI := Color("#30493D")     # knoppen, kopjes
const PANEL_LO := Color("#1A2A23")     # verzonken vakken, pillen
const SLOT := Color("#13201A")         # gaten, track van meters
const OUTLINE := Color("#0E1813")      # outline van zwevende tekst
const TEXT := Color("#FFF8EA")         # tekst op donker (warm wit)
const TEXT_DIM := Color("#A9C0AC")     # secundaire tekst op donker
const PAPER := Color("#FFF7E6")        # labels, kaartjes, rapport (inkt erop)
const PAPER_EDGE := Color("#E6D3AE")   # onderrand/dikte van papier
const INK := Color("#2A2118")          # ALLE letters op papier/chips
const INK_SOFT := Color("#7A6853")     # secundaire inkt (indices op papier, touwtjes)
const SHADOW := Color(0.06, 0.09, 0.03, 0.32)
const SHADOW_SOFT := Color(0.06, 0.09, 0.03, 0.18)

# ---------------------------------------------------------------- semantisch (= Hash & Dash, familie)
const OK := Color("#3DDC97")
const WARN := Color("#FFB020")
const ERR := Color("#FF5A5F")
const INFO := Color("#4CC9F0")
const STAR := Color("#FFD23F")
const STAR_DARK := Color("#E09A1B")
const BRAND := Color("#7BC96F")        # hubkleur Trietuin (HubRegistry)
const BRAND_DARK := Color("#4E9A47")

# ---------------------------------------------------------------- hout, knoppen, sap
const BARK := Color("#6E4C34")
const BARK_DARK := Color("#4B3224")
const BARK_LIGHT := Color("#9A7451")
const KNOT := Color("#5A3D2B")         # knoest (interne top)
const KNOT_TOP := Color("#7A573D")
const KNOT_RIM := Color("#3E2A1E")
const BUD := Color("#8FD46B")          # knop met kind (pointer gebruikt)
const BUD_DARK := Color("#4E9A47")
const BUD_EMPTY := Color("#C9BFA4")    # slapende knop (NULL-pointer)
const BUD_EMPTY_DARK := Color("#8E836A")
const SAP := Color("#F2A541")
const SAP_DARK := Color("#C8761E")
const SAP_LIGHT := Color("#FFD58A")
const GLASS := Color(1, 1, 1, 0.22)
const RAFFIA := Color("#E3C27E")       # entband (Patricia)
const RAFFIA_DARK := Color("#B8934B")
const TENDRIL := Color("#86C25A")      # rank (ternary)
const TENDRIL_DARK := Color("#5E9640")
const ROPE := Color("#6E8F3E")         # slinger-touw (suffixboom)
const ROPE_DARK := Color("#4C6A2A")
const SNOW := Color("#F4F8FF")

# ternary: kleiner / gelijk / groter (altijd mét symbool en positie, nooit enkel kleur)
const LESS := Color("#7DB8F0")
const EQUAL := Color("#7BC96F")
const GREATER := Color("#F5A35C")

# bij & speurneus
const BEE := Color("#FFC93C")
const BEE_DARK := Color("#E0A21C")
const BEE_STRIPE := Color("#3A2A1E")
const WING := Color(1, 1, 1, 0.55)
const HOG := Color("#7A5A44")          # stekels
const HOG_DARK := Color("#563E2F")
const HOG_FACE := Color("#EBC9A0")
const HAT := Color("#B78B52")
const HAT_DARK := Color("#8A6538")
const BLUSH := Color("#FF8FA3")
const WASP := Color("#FFD21F")         # wesp: feller geel, dikkere zwarte banden
const WASP_STRIPE := Color("#1B1714")
const OWL := Color("#8B6E58")          # de Uil (coach)
const OWL_DARK := Color("#634C3C")
const OWL_BELLY := Color("#EBD7B8")
const STRAW := Color("#E2B65A")        # bijenkorf
const STRAW_DARK := Color("#B98A35")
const HONEY := Color("#F5A623")
const HONEY_DARK := Color("#C77D12")
const TERRACOTTA := Color("#C8643B")   # plantpotten (seizoenkaart)
const TERRACOTTA_HI := Color("#E07B4F")
const FIREFLY := Color("#E4FF7A")      # Ukkonen-wijzer
const DOG := Color("#C98B52")
const DOG_DARK := Color("#7A4E2C")
const STAMP := Color("#2F8F57")        # stempel OPGELOST (goed = groen, nooit rood)

## Verdachten (veralgemeende suffixboom): kleur ÉN vorm (kleurenblind-veilig).
const SUSPECTS := [
	{"name": "Vos", "col": Color("#F28C38"), "shape": "circle"},
	{"name": "Das", "col": Color("#4F8BEA"), "shape": "triangle"},
	{"name": "Ekster", "col": Color("#B36AE2"), "shape": "square"},
	{"name": "Mol", "col": Color("#2FB59A"), "shape": "diamond"},
]

# ---------------------------------------------------------------- letters (chips, zoals de bitchips in H&D)
## Vaste kleuren voor het DNA-alfabet (Figuur 13–14). Chip achter de letter, letter altijd INK.
const LETTER_COLORS := {
	"A": Color("#FFC94D"),  # goud
	"C": Color("#5CD6C8"),  # aqua
	"G": Color("#FF8FAB"),  # roze
	"T": Color("#B39DFF"),  # lavendel
	"_": Color("#E4DCCB"),  # afsluitteken: neutraal
}
## Overige letters (klein alfabet ≤ 8): cyclus in alfabetvolgorde. Groot alfabet: neutrale chips (CHIP_NEUTRAL).
const LETTER_CYCLE := [Color("#FFC94D"), Color("#5CD6C8"), Color("#FF8FAB"), Color("#B39DFF"), Color("#A5E05A"),
	Color("#FFA463"), Color("#7CC6FE"), Color("#8EE3B5")]
const CHIP_NEUTRAL := Color("#F1E6CF")

# ---------------------------------------------------------------- seizoenen
## Per seizoen: lucht, blad, vrucht, partikel, muziek. Achtergronden: assets/art/bg/bg_<id>.jpg (+ fg_<id>.png).
const SEASONS := [
	{
		"id": "lente", "name": "Lente", "topic": "gewone trie",
		"sky_top": Color("#8FD3E8"), "sky_bottom": Color("#F6F8DE"), "ground": Color("#6AAE64"),
		"leaf": [Color("#7CC274"), Color("#93D180"), Color("#5FAE60")], "leaf_dark": Color("#3F8A45"),
		"accent": Color("#F8B8C8"),
		"fruit": Color("#FF8FAB"), "fruit_hi": Color("#FFD3DE"), "fruit_dark": Color("#D9607F"), "fruit_kind": "bloesem",
		"particle": "petal", "particle_col": Color("#FFD0DC"), "particle2": "pollen", "particle2_col": Color("#FFF3B0"),
		"snow": false, "night": false, "light": Color("#FFF6C8"),
		"music": "music/tt_lente_loop.ogg", "ambience": "sfx/amb_lente_loop.ogg",
	},
	{
		"id": "zomer", "name": "Zomer", "topic": "Patricia-trie",
		"sky_top": Color("#4FB0E3"), "sky_bottom": Color("#FFEFC2"), "ground": Color("#5C9E45"),
		"leaf": [Color("#4F9A3E"), Color("#65B04A"), Color("#3E8534")], "leaf_dark": Color("#2E6A28"),
		"accent": Color("#FFC93C"),
		"fruit": Color("#F2683C"), "fruit_hi": Color("#FFB08A"), "fruit_dark": Color("#C4442A"), "fruit_kind": "appel",
		"particle": "pollen", "particle_col": Color("#FFF0A0"), "particle2": "leaf_round", "particle2_col": Color("#7CC274"),
		"snow": false, "night": false, "light": Color("#FFF0A0"),
		"music": "music/tt_zomer_loop.ogg", "ambience": "sfx/amb_zomer_loop.ogg",
	},
	{
		"id": "herfst", "name": "Herfst", "topic": "ternary trie",
		"sky_top": Color("#7FA2C6"), "sky_bottom": Color("#FAD29A"), "ground": Color("#857941"),
		"leaf": [Color("#E07A2E"), Color("#F2B33D"), Color("#C9472C")], "leaf_dark": Color("#8E3A1E"),
		"accent": Color("#F2B33D"),
		"fruit": Color("#F2B33D"), "fruit_hi": Color("#FFE49A"), "fruit_dark": Color("#C47F1C"), "fruit_kind": "peer",
		"particle": "leaf", "particle_col": Color("#E98A3A"), "particle2": "leaf", "particle2_col": Color("#F2B33D"),
		"snow": false, "night": false, "light": Color("#FFD08A"),
		"music": "music/tt_herfst_loop.ogg", "ambience": "sfx/amb_herfst_loop.ogg",
	},
	{
		"id": "winter", "name": "Winter", "topic": "suffixboom",
		"sky_top": Color("#2F3F73"), "sky_bottom": Color("#D8C9E0"), "ground": Color("#EEF3FA"),
		"leaf": [Color("#9FB6D6"), Color("#C5D4EA"), Color("#7F98BE")], "leaf_dark": Color("#5C7398"),
		"accent": Color("#FFD27A"),
		"fruit": Color("#FFB547"), "fruit_hi": Color("#FFE7A8"), "fruit_dark": Color("#D9822B"), "fruit_kind": "lampion",
		"particle": "snowflake", "particle_col": Color("#FFFFFF"), "particle2": "pollen", "particle2_col": Color("#FFFFFF"),
		"snow": true, "night": true, "light": Color("#FFF4D6"),
		"music": "music/tt_winter_loop.ogg", "ambience": "sfx/amb_winter_loop.ogg",
	},
]

# ---------------------------------------------------------------- paden
const ASSETS := "res://games/trietuin/assets/"
const FONT_MONO_PATH := "res://assets/fonts/JetBrainsMono-ExtraBold.ttf"
const FONT_MONO_B_PATH := "res://assets/fonts/JetBrainsMono-Bold.ttf"
const FONT_MONO_M_PATH := "res://assets/fonts/JetBrainsMono-Medium.ttf"
const FONT_UI_PATH := "res://assets/fonts/Fredoka-SemiBold.ttf"
const FONT_UI_BOLD_PATH := "res://assets/fonts/Fredoka-Bold.ttf"
const FONT_UI_MED_PATH := "res://assets/fonts/Fredoka-Medium.ttf"

## JetBrains Mono als MSDF (multichannel signed distance field): letters/woorden blijven scherp bij camerazoom
## 0,6–1,6 en bij schaal-tweens. Bij schaal 1 even scherp als gewone rendering (getest, ART.md §3).
## Fredoka NIET als MSDF: de statische instanties hebben overlappende contouren -> artefacten ("a" wordt "c").
## Fredoka-tekst hoort dus in de UI-laag (CanvasLayer, zoom 1), niet in de gezoomde wereld.
static var MONO: Font = _msdf(FONT_MONO_PATH)
static var MONO_B: Font = _msdf(FONT_MONO_B_PATH)
static var MONO_M: Font = _msdf(FONT_MONO_M_PATH)
static var UI: Font = load(FONT_UI_PATH)
static var UI_BOLD: Font = load(FONT_UI_BOLD_PATH)
static var UI_MED: Font = load(FONT_UI_MED_PATH)

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


static func season(s: int) -> Dictionary:
	return SEASONS[clampi(s, 0, SEASONS.size() - 1)]


static func bg_path(s: int) -> String:
	return ASSETS + "art/bg/bg_%s.jpg" % season(s).id


static func fg_path(s: int) -> String:
	return ASSETS + "art/bg/fg_%s.png" % season(s).id


## Textuur uit assets/ (gecachet). `rel` bv. "art/particles/leaf.png".
static func tex(rel: String) -> Texture2D:
	if not _tex_cache.has(rel):
		var p := ASSETS + rel
		_tex_cache[rel] = load(p) if ResourceLoader.exists(p) else null
	return _tex_cache[rel]


static func particle(name_: String) -> Texture2D:
	return tex("art/particles/%s.png" % name_)


## Chipkleur voor een letter. `alphabet` = het alfabet van het level (bepaalt de cyclus); groot alfabet -> neutraal.
static func letter_color(ch: String, alphabet := "ACGT_") -> Color:
	var up := ch.to_upper()
	if alphabet.to_upper() == "ACGT_" or (alphabet.length() <= 5 and LETTER_COLORS.has(up)):
		return LETTER_COLORS.get(up, CHIP_NEUTRAL)
	if ch == "_":
		return LETTER_COLORS["_"]
	if alphabet.length() > LETTER_CYCLE.size():
		return CHIP_NEUTRAL
	var i := alphabet.find(ch)
	if i < 0:
		return CHIP_NEUTRAL
	return LETTER_CYCLE[i % LETTER_CYCLE.size()]


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
	s.corner_detail = 10
	if shadow > 0:
		s.shadow_color = shadow_col
		s.shadow_size = shadow
		s.shadow_offset = shadow_off
	return s


## Papier/chip met dikke onderrand ("tastbaar"), gecachet.
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
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var asc := font.get_ascent(size)
	var desc := font.get_descent(size)
	ci.draw_string(font, Vector2(round(center.x - w.x / 2.0), round(center.y + (asc - desc) / 2.0)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


static func text_l(ci: CanvasItem, font: Font, left_mid: Vector2, s: String, size: int, col: Color) -> float:
	var asc := font.get_ascent(size)
	var desc := font.get_descent(size)
	ci.draw_string(font, Vector2(round(left_mid.x), round(left_mid.y + (asc - desc) / 2.0)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func text_r(ci: CanvasItem, font: Font, right_mid: Vector2, s: String, size: int, col: Color) -> float:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var asc := font.get_ascent(size)
	var desc := font.get_descent(size)
	ci.draw_string(font, Vector2(round(right_mid.x - w), round(right_mid.y + (asc - desc) / 2.0)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	return w


static func text_outline_c(ci: CanvasItem, font: Font, center: Vector2, s: String, size: int, col: Color, outline := 8, ocol := OUTLINE) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var asc := font.get_ascent(size)
	var desc := font.get_descent(size)
	var p := Vector2(round(center.x - w.x / 2.0), round(center.y + (asc - desc) / 2.0))
	ci.draw_string_outline(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, ocol)
	ci.draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## Zin met gemengde fonts: parts = [["Komt ", "ui"], ["cac", "mono"], [" voor?", "ui"]]. Mono-stukken krijgen
## letterchips als `chips`. Geeft de breedte terug. `measure_only` tekent niets.
static func rich_line(ci: CanvasItem, left_mid: Vector2, parts: Array, size: int, col := INK, chips := true,
		alphabet := "ACGT_", measure_only := false) -> float:
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
			var f := UI_BOLD if kind == "bold" else UI
			var w2 := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			if not measure_only:
				text_l(ci, f, Vector2(x, left_mid.y), s, size, col)
			x += w2
	return x - left_mid.x


# ---------------------------------------------------------------- woorden (mono, letterchips)
static func char_w(size: int) -> float:
	return MONO.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func word_gap(size: int) -> float:
	return maxf(2.0, size * 0.10)


static func word_width(n: int, size: int) -> float:
	if n <= 0:
		return 0.0
	return n * char_w(size) + (n - 1) * word_gap(size)


## Woord in JetBrains Mono, gecentreerd op `center`. `chips`: kleurchip per letter (letterkleur), letters altijd INK.
## `ghost_from..ghost_to` (incl., 0-index): letters als holle "overgeslagen" chips (Patricia-skip).
## `hi_from..hi_to`: ring in `hi_col` rond die letters (bv. eerste verschilpositie j, (b,e)-bereik).
## `dim_after`: letters vanaf deze index gedimd (nog niet gelezen). Geeft de breedte terug.
static func word(ci: CanvasItem, center: Vector2, s: String, size: int, chips := true, alphabet := "ACGT_",
		hi_from := -1, hi_to := -1, hi_col := WARN, ghost_from := -1, ghost_to := -1, dim_after := -1, ink := INK) -> float:
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
		var ghost := i >= ghost_from and i <= ghost_to and ghost_from >= 0
		var dim := dim_after >= 0 and i >= dim_after
		var a := 0.38 if dim else 1.0
		if ghost:
			ring(ci, r, rad, Color(INK_SOFT, 0.55), 2)
		elif chips:
			var cc := letter_color(ch, alphabet)
			cc.a *= a
			ci.draw_style_box(sb(cc, rad), r)
		if i >= hi_from and i <= hi_to and hi_from >= 0:
			ring(ci, r.grow(3), rad + 3, hi_col, 3)
		var col := Color(ink, (0.35 if ghost else a))
		ci.draw_string(MONO, Vector2(round(x), round(center.y + (asc - desc) / 2.0)), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
		x += cw + gap
	return total


## Grootste fontgrootte (>= min_size) zodat een woord van n letters in `width` past.
static func fit_word(n: int, width: float, max_size: int, min_size := 18) -> int:
	var s := max_size
	while s > min_size and word_width(n, s) > width:
		s -= 1
	return s
