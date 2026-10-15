class_name TtTreeView
extends Node2D
## Tekent de boom van een TtTreeModel (alle structuren) uit `render_nodes()` + TtViewLayout, met zachte
## overgangen: toppen glijden naar hun nieuwe plaats, nieuwe takken groeien, vruchten ploppen, afgeknipte
## delen vallen. Klikzones (`pick`) voor knoppen, vruchten, knoesten, takken, boogpunten en bollen.
## Wereldcoördinaten: wortelknoest op (0,0), de boom groeit naar -y.

signal hovered(hit: Dictionary)

const LEAF_R := 24.0

var model: TtTreeModel
var kind := 0
var letters := "ACGT_"
var season := 0
var se: Dictionary = {}
var opts := {}
var t := 0.0
var pos_base := 0

var rn := {}            # id -> render dict (laatste sync)
var vs := {}            # id -> {"p": Vector2, "target": Vector2, "g": float, "pop": float, "wither": float, "grey": float}
var lay := {}
var bounds := Rect2(-300, -400, 600, 600)
var dying: Array = []   # vallende/verdwijnende delen
var root_id := -1

# highlights (gezet door de tuin)
var hl_node := -1
var hl_bud := {}        # {"node": id, "letter": c}
var hl_path: Array = []
var hl_edges := {}      # id -> Color (gloed onder de tak naar id)
var fruit_state := {}   # id -> 0..3
var candidates: Array = []
var selectable := {}    # "bud"/"fruit"/"knot"/"edge"/"point"/"ball" -> true
var hover := {}
var hl_point := {}      # suffix: {"node","off"} (loep/afwijkpunt)
var hl_be := -1         # suffix: bord dat oplicht
var show_depth := false # suffix: toon l_t op de toppen
var show_counts := false
var show_strings := false   # suffix: strings op de bogen (4-1)
var hide_letters := false   # suffix in mist: geen letters op de boogparels
var ghost_link := {}    # Ukkonen: hangende rank {"from": id, "to_pos": Vector2}
var it_cur := 0         # Ukkonen: huidige `it` (open bladbogen)
var pack_col := {}      # ternary: pack -> kleur van de cluster
var owner_cols: Array = []   # veralgemeend: kleur per eigenaar (1..k)
var dim_all := 0.0
var show_hive := true
var queen_frown := false
var hive_pulse := 0.0
const HIVE_OFF := Vector2(-330, 172)

var _edge_cache := {}   # id -> PackedVector2Array (dit frame)
## QA (leesbaarheid brede bomen 4-4/4-5): labels groeien mee als de camera ver uitzoomt, zodat ze op het scherm
## leesbaar blijven (de tuin zet dit elke frame: ≈ 0,8 / zoom, begrensd). 1.0 = getekende maat.
var label_scale := 1.0
var _tag_pos := {}      # id -> Vector2 middelpunt van het (b,e)-bord (dit frame, zonder overlap geplaatst)
var _tag_rect := {}     # id -> Rect2


func setup(m: TtTreeModel, kind_: int, letters_: String, season_: int, opts_ := {}) -> void:
	model = m
	kind = kind_
	letters = letters_
	season = season_
	se = TtPal.season(season)
	opts = opts_
	pos_base = opts.get("pos_base", 0)
	sync(true)
	for id in vs:
		vs[id].p = vs[id].target


# ================================================================ synchronisatie
## Lees de modelboom. Nieuwe toppen zijn verborgen (g = 0) tot `reveal()` ze laat groeien (of `reveal_all`).
## Verdwenen toppen vallen of vervagen (tenzij al door een fx afgehandeld).
func sync(reveal_all := false) -> void:
	var nodes: Array = model.render_nodes()
	var fresh := {}
	for d in nodes:
		fresh[int(d.id)] = d
	# verdwenen
	for id in rn.keys():
		if not fresh.has(id):
			if vs.has(id) and not vs[id].get("handled", false):
				_spawn_dying(id, "fade")
			vs.erase(id)
	rn = fresh
	root_id = _find_root()
	var lo := _layout_opts()
	lay = TtViewLayout.compute(nodes, kind, letters, lo)
	var hgt: float = (lay.get("bounds", Rect2()) as Rect2).size.y
	if kind != TtCodes.Kind.TERNARY and hgt > 1150.0:
		lo["vs"] = clampf(1.0 - (hgt - 1150.0) / maxf(hgt - 400.0, 1.0), 0.62, 1.0)
		lay = TtViewLayout.compute(nodes, kind, letters, lo)
	var P: Dictionary = lay.get("pos", {})
	for id in rn:
		var target: Vector2 = P.get(id, Vector2.ZERO)
		if not vs.has(id):
			var start := target
			var par := _parent_of(id)
			if par >= 0 and vs.has(par):
				start = vs[par].p
			vs[id] = {"p": target, "target": target, "g": 1.0 if reveal_all else 0.0, "pop": 1.0, "wither": 0.0,
				"grey": 0.0, "born": t}
		else:
			vs[id].target = target
		var dd: Dictionary = rn[id]
		vs[id].wither_target = 1.0 if dd.get("dead", false) else 0.0
	bounds = lay.get("bounds", bounds)


func _layout_opts() -> Dictionary:
	var o := {"label_size": 22, "patricia": kind == TtCodes.Kind.PATRICIA}
	if kind == TtCodes.Kind.SUFFIX or kind == TtCodes.Kind.UKKONEN:
		var lens := {}
		for id in rn:
			lens[id] = edge_chars(id)
		o["edge_chars"] = lens
		o["strings"] = show_strings
		o["leaf_w"] = 112.0 if show_strings else 132.0
	return o


func _find_root() -> int:
	if model and model.get("root") != null:
		return int(model.root)
	for id in rn:
		if int(rn[id].get("parent", -1)) < 0:
			return id
	return -1


func _parent_of(id: int) -> int:
	if not rn.has(id):
		return -1
	var d: Dictionary = rn[id]
	if kind == TtCodes.Kind.TERNARY:
		match int(d.type):
			TtNode.Type.BALL:
				var p := int(d.get("parent", -1))
				return p if p >= 0 else int(d.get("pack", -1))
			TtNode.Type.PACK:
				return int(d.get("parent", -1))
			TtNode.Type.LEAF:
				return int(d.get("parent", -1))
	return int(d.get("parent", -1))


## Laat een (verborgen) top groeien. mode: "grow" (tak groeit, knoest ontvouwt), "pop" (vrucht ploft elastisch).
func reveal(id: int, dur := 0.3, mode := "grow") -> void:
	if not vs.has(id):
		return
	var st: Dictionary = vs[id]
	if st.g >= 1.0:
		return
	var tw := create_tween()
	tw.tween_method(func(v: float):
		if vs.has(id):
			vs[id].g = v, st.g, 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if mode == "pop":
		st.pop = 0.01
		tw.tween_method(func(v: float):
			if vs.has(id):
				vs[id].pop = v, 0.01, 1.0, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func reveal_all_now() -> void:
	for id in vs:
		if vs[id].g < 1.0:
			reveal(id, 0.25, "pop" if is_leaf(id) else "grow")


func pop_node(id: int, amount := 1.25) -> void:
	if not vs.has(id):
		return
	vs[id].pop = amount
	var tw := create_tween()
	tw.tween_method(func(v: float):
		if vs.has(id):
			vs[id].pop = v, amount, 1.0, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func set_grey(id: int, on := true) -> void:
	if not vs.has(id):
		return
	var tw := create_tween()
	tw.tween_method(func(v: float):
		if vs.has(id):
			vs[id].grey = v, vs[id].grey, 1.0 if on else 0.0, 0.8)


## Markeer een top als "al afgehandeld" zodat sync hem niet nog eens laat vervagen.
func mark_handled(id: int) -> void:
	if vs.has(id):
		vs[id].handled = true


func _spawn_dying(id: int, how: String) -> void:
	if not vs.has(id) or not rn.has(id):
		return
	var d: Dictionary = rn[id].duplicate()
	var e := edge_pts(id)
	var item := {"d": d, "p": vs[id].p, "edge": e, "how": how, "t": 0.0, "rot": 0.0,
		"vel": Vector2(randf_range(-80, 80), -120), "spin": randf_range(-2.5, 2.5), "a": 1.0}
	dying.append(item)


## Laat een deel van de boom vallen (knip, wesp): `ids` = alle toppen die verdwijnen.
func drop_nodes(ids: Array, how := "fall") -> void:
	for id in ids:
		if vs.has(id) and rn.has(id):
			_spawn_dying(id, how)
			vs[id].handled = true


# ================================================================ geometrie
func is_leaf(id: int) -> bool:
	return rn.has(id) and int(rn[id].type) == TtNode.Type.LEAF


func node_type(id: int) -> int:
	return int(rn[id].type) if rn.has(id) else -1


func pos_of(id: int) -> Vector2:
	if vs.has(id):
		return vs[id].p
	return Vector2.ZERO


func knot_gap() -> float:
	return TtViewLayout.knot_gap(letters.length())


func bud_top(id: int, letter: String) -> Vector2:
	var c := pos_of(id)
	if kind == TtCodes.Kind.SUFFIX or kind == TtCodes.Kind.UKKONEN:
		var ks := suffix_kid_letters(id)
		var i := ks.find(letter)
		var g := 30.0
		return Vector2(c.x - (ks.length() - 1) * g / 2.0 + maxi(i, 0) * g, c.y - 20)
	var n := letters.length()
	var i2 := letters.find(letter)
	var gap := knot_gap()
	return Vector2(c.x - (n - 1) * gap / 2.0 + maxi(i2, 0) * gap, c.y - 20)


## Vruchtmidden (de vrucht hangt onder de taktop).
func fruit_center(id: int) -> Vector2:
	var tip := pos_of(id)
	var s := _scale_of(id)
	return tip + Vector2(0, (LEAF_R * 0.75 + LEAF_R) * s)


func label_rect(id: int) -> Rect2:
	var c := fruit_center(id)
	var lab := leaf_label(id)
	var ls := 22.0
	if kind == TtCodes.Kind.SUFFIX or kind == TtCodes.Kind.UKKONEN:
		ls = round(22.0 * label_scale)
	var lw := TtPal.word_width(lab.length(), int(ls)) + ls * 0.8
	return Rect2(c.x - lw / 2.0, c.y + LEAF_R + 12, lw, ls * 1.55)


func _scale_of(id: int) -> float:
	if not vs.has(id):
		return 1.0
	return clampf(vs[id].g, 0.0, 1.0) * vs[id].pop


func leaf_label(id: int) -> String:
	if not rn.has(id):
		return ""
	var d: Dictionary = rn[id]
	if kind == TtCodes.Kind.SUFFIX or kind == TtCodes.Kind.UKKONEN:
		return "#%d" % (int(d.get("start", 0)) + pos_base)
	return str(d.get("label", ""))


## Inkomende tak (polyline) van top `id`, met de huidige posities.
func edge_pts(id: int) -> PackedVector2Array:
	if _edge_cache.has(id):
		return _edge_cache[id]
	var out := PackedVector2Array()
	if not rn.has(id):
		return out
	var d: Dictionary = rn[id]
	match kind:
		TtCodes.Kind.TERNARY:
			out = _ternary_edge(id, d)
		_:
			var par := int(d.get("parent", -1))
			if par < 0 or not vs.has(par):
				return out
			var via := str(d.get("via", ""))
			var p0 := bud_top(par, via)
			var leaf := int(d.type) == TtNode.Type.LEAF
			var p1 := pos_of(id) + (Vector2.ZERO if leaf else Vector2(0, 20))
			var bend := 0.08 if p1.x < p0.x else -0.08
			var arch := leaf and absf(p1.x - p0.x) > 70.0
			out = TtDraw.branch_curve(p0, p1, Vector2.UP, bend, 24, arch)
	_edge_cache[id] = out
	return out


func _ternary_edge(id: int, d: Dictionary) -> PackedVector2Array:
	var typ := int(d.type)
	var out := PackedVector2Array()
	if typ == TtNode.Type.BALL:
		var par := int(d.get("parent", -1))
		if par < 0 or not vs.has(par):
			return out
		var pd: Dictionary = rn.get(par, {})
		var side := -1.0 if int(pd.get("lo", -1)) == id else 1.0
		var pc := pos_of(par)
		var a := pc + Vector2(side * 0.94, -0.34) * 56.0
		var b := pos_of(id) + Vector2(-side * 30.0, 6.0)
		for k in 25:
			var u := k / 24.0
			out.append(a.lerp(b, u) + Vector2(0, -sin(u * PI) * 26.0))
		return out
	if typ == TtNode.Type.PACK:
		var par2 := int(d.get("parent", -1))
		if par2 < 0 or not vs.has(par2):
			return out
		var p0 := pos_of(par2) + Vector2(0, -50)
		var p1 := pos_of(id) + Vector2(0, 34)
		return TtDraw.branch_curve(p0, p1, Vector2.UP, 0.0, 20)
	if typ == TtNode.Type.LEAF:
		var par3 := int(d.get("parent", -1))
		if par3 < 0 or not vs.has(par3):
			return out
		var p0b := pos_of(par3) + Vector2(0, -50)
		var p1b := pos_of(id)
		return TtDraw.branch_curve(p0b, p1b, Vector2.UP, 0.0, 20, absf(p1b.x - p0b.x) > 70.0)
	return out


# ---------------------------------------------------------------- suffix-helpers
func edge_chars(id: int) -> int:
	if not rn.has(id):
		return 0
	var d: Dictionary = rn[id]
	var b := int(d.get("b", -1))
	var e := int(d.get("e", -1))
	if b < 0:
		return 0
	if e == TtCodes.OPEN:
		e = it_cur - 1
	var n := e - b + 1
	# veralgemeende suffixboom (Oef. 30a): een bladboog stopt visueel na het eerste afsluitteken
	var text: String = opts.get("text", "")
	if text.contains("1"):
		for k in range(b, mini(b + n, text.length())):
			if "123".contains(text[k]):
				n = k - b + 1
				break
	return maxi(n, 0)


func edge_string(id: int) -> String:
	if not rn.has(id):
		return ""
	var text: String = opts.get("text", "")
	var d: Dictionary = rn[id]
	var b := int(d.get("b", -1))
	if b < 0:
		return ""
	var n := edge_chars(id)
	return text.substr(b, n)


func suffix_kid_letters(id: int) -> String:
	if not rn.has(id):
		return ""
	var kids: Dictionary = rn[id].get("kids", {})
	var ks := kids.keys()
	ks.sort_custom(func(a, b): return _ord(str(a)) < _ord(str(b)))
	var s := ""
	for k in ks:
		s += str(k)
	return s


func _ord(ch: String) -> int:
	var i := letters.find(ch)
	return i if i >= 0 else 1000 + ch.unicode_at(0)


## Punt op een suffixboog na `off` tekens (0 = de top zelf).
func point_pos(id: int, off: int) -> Vector2:
	if off <= 0:
		return pos_of(id)
	var pts := edge_pts(id)
	var n := edge_chars(id)
	if pts.size() < 2 or n <= 0:
		return pos_of(id)
	return TtDraw.path_point(pts, float(off) / n)


func display_char(ch: String) -> String:
	match ch:
		"1":
			return "₁"
		"2":
			return "₂"
		"3":
			return "₃"
	return ch


# ================================================================ update + teken
func _process(delta: float) -> void:
	t += delta
	_edge_cache.clear()
	var k := 1.0 - exp(-delta * 9.0)
	for id in vs:
		var st: Dictionary = vs[id]
		st.p = st.p.lerp(st.target, k)
		var wt: float = st.get("wither_target", 0.0)
		st.wither = move_toward(st.wither, wt, delta / 0.6)
	var keep := []
	for it in dying:
		it.t += delta
		if it.how == "fall":
			it.vel.y += 1400.0 * delta
			it.p += it.vel * delta
			it.rot += it.spin * delta
			it.a = clampf(1.4 - it.t, 0.0, 1.0)
		else:
			it.a = clampf(1.0 - it.t / 0.45, 0.0, 1.0)
		if it.a > 0.0:
			keep.append(it)
	dying = keep
	queue_redraw()


func hive_pos() -> Vector2:
	return pos_of(root_id) + HIVE_OFF if root_id >= 0 else HIVE_OFF


func _draw() -> void:
	if show_hive and root_id >= 0 and vs.has(root_id):
		TtDraw.hive(self, hive_pos(), 1.0, t, true, queen_frown, hive_pulse)
	match kind:
		TtCodes.Kind.TERNARY:
			_draw_ternary()
		TtCodes.Kind.SUFFIX, TtCodes.Kind.UKKONEN:
			_draw_suffix()
		_:
			_draw_trie()
	_draw_dying()


func _depth_w(id: int) -> Array:
	var dd := 0
	var cur := id
	while cur >= 0 and rn.has(cur) and dd < 40:
		cur = _parent_of(cur)
		dd += 1
	var w0 := clampf(26.0 - dd * 2.6, 11.0, 26.0)
	return [w0, w0 * 0.68]


# ---------------------------------------------------------------- trie / Patricia
func _draw_trie() -> void:
	if root_id < 0 or not vs.has(root_id):
		return
	var rp := pos_of(root_id)
	TtDraw.root(self, rp + Vector2(0, 175), rp + Vector2(0, 22), se, t)
	if kind == TtCodes.Kind.PATRICIA:
		var rs := int(rn[root_id].get("skip", 0))
		if rs > 0:
			var trunk := TtDraw.branch_curve(rp + Vector2(0, 172), rp + Vector2(0, 22), Vector2.UP, 0.04, 20)
			TtDraw.graft_wrap(self, trunk, 0.2, 40)
	# takken
	var order := rn.keys()
	order.sort()
	for id in order:
		if id == root_id:
			continue
		_draw_trie_edge(id)
	# knoesten
	for id in order:
		if node_type(id) == TtNode.Type.INNER:
			_draw_knot(id)
	# lettertjes op de takken
	for id in order:
		if id == root_id or not rn.has(id):
			continue
		var g: float = vs[id].g
		if g < 0.6:
			continue
		var e := edge_pts(id)
		if e.size() < 2:
			continue
		var leaf := is_leaf(id)
		var f := 0.2 if leaf else 0.42
		if kind == TtCodes.Kind.PATRICIA:
			f = 0.2
		var lit := Color(0, 0, 0, 0)
		if hl_path.has(id):
			lit = Color(TtPal.INFO, 0.9)
		var hov: bool = hover.get("t", "") == "edge" and int(hover.get("id", -1)) == id
		if hov:
			lit = Color(TtPal.WARN, 0.95)
		TtDraw.letter_tag(self, TtDraw.path_point(e, f), str(rn[id].get("via", "")), 24 if letters.length() <= 8 else 20, letters, lit)
	# Patricia: jaarringplaatjes
	if kind == TtCodes.Kind.PATRICIA:
		for id in order:
			if node_type(id) == TtNode.Type.INNER and vs[id].g > 0.5:
				_draw_skip_plate(id)
	# vruchten
	for id in order:
		if is_leaf(id):
			_draw_fruit(id)


func _draw_trie_edge(id: int) -> void:
	var e := edge_pts(id)
	if e.size() < 2:
		return
	var st: Dictionary = vs[id]
	var g: float = st.g
	if g <= 0.02:
		return
	var pts := e
	if g < 1.0:
		var n := maxi(4, int(ceil(e.size() * clampf(g * 1.4, 0.0, 1.0))))
		pts = e.slice(0, n)
	var ww := _depth_w(id)
	var glow := Color(0, 0, 0, 0)
	if hl_edges.has(id):
		glow = hl_edges[id]
	elif hl_path.has(id):
		glow = Color(TtPal.INFO, 0.28)
	var hov: bool = hover.get("t", "") == "edge" and int(hover.get("id", -1)) == id
	if hov:
		glow = Color(TtPal.WARN, 0.35)
	var wither: float = st.wither
	if is_leaf(id):
		wither = maxf(wither, st.grey * 0.6)
	TtDraw.branch(self, pts, ww[0], ww[1], se, id * 7 + 3, t, 2 if not is_leaf(id) else 1, glow, wither)
	if kind == TtCodes.Kind.PATRICIA and node_type(id) == TtNode.Type.INNER:
		var sk := int(rn[id].get("skip", 0))
		if sk > 0 and g >= 1.0:
			TtDraw.ghost_beads(self, e, 0.42, 0.88, sk, t)
			TtDraw.graft_wrap(self, e, 0.33, ww[0] * 0.8)


func _draw_knot(id: int) -> void:
	var st: Dictionary = vs[id]
	var g: float = clampf(st.g, 0.0, 1.0)
	if g <= 0.02:
		return
	var c := pos_of(id)
	var d: Dictionary = rn[id]
	var kids: Dictionary = d.get("kids", {})
	var used := []
	for ch in letters:
		used.append(kids.has(ch))
	var hi := -1
	if int(hl_bud.get("node", -1)) == id:
		hi = letters.find(str(hl_bud.get("letter", "")))
	if hover.get("t", "") == "bud" and int(hover.get("node", -1)) == id:
		hi = letters.find(str(hover.get("letter", "")))
	var s: float = st.pop
	draw_set_transform(c, 0.0, Vector2(lerpf(0.3, 1.0, g) * s, g * s))
	if id == hl_node:
		var kw := TtViewLayout.knot_width(letters.length())
		var pr := 0.5 + 0.5 * sin(t * 4.0)
		draw_style_box(TtPal.sb(Color(TtPal.INFO, 0.18 + 0.12 * pr), 24), Rect2(-kw / 2.0 - 10, -30, kw + 20, 60))
	if st.wither > 0.3:
		modulate_knot_dead(st.wither)
	TtDraw.knot(self, Vector2.ZERO, letters, used, knot_gap(), hi, t, letters.length() > 8)
	if hover.get("t", "") == "knot" and int(hover.get("id", -1)) == id:
		var kw2 := TtViewLayout.knot_width(letters.length())
		TtPal.ring(self, Rect2(-kw2 / 2.0 - 6, -24, kw2 + 12, 48), 22, TtPal.WARN, 4)
		if selectable.get("prune", false):
			TtDraw.shears(self, Vector2(kw2 / 2.0 + 30, -10), 0.9, 0.5 + 0.4 * sin(t * 8.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func modulate_knot_dead(w: float) -> void:
	var kw := TtViewLayout.knot_width(letters.length())
	draw_style_box(TtPal.sb(Color(0.45, 0.4, 0.35, 0.35 * w), 18), Rect2(-kw / 2.0 - 4, -22, kw + 8, 44))


func _draw_skip_plate(id: int) -> void:
	var d: Dictionary = rn[id]
	var c := pos_of(id)
	var kw := TtViewLayout.knot_width(letters.length())
	var hi: bool = (hover.get("t", "") == "knot" and int(hover.get("id", -1)) == id) or id == hl_node
	var g: float = clampf(vs[id].g, 0.0, 1.0) * vs[id].pop
	draw_set_transform(c + Vector2(kw / 2.0 + 34, 2), 0.0, Vector2(g, g))
	TtDraw.skip_ring(self, Vector2.ZERO, int(d.get("skip", 0)), int(d.get("pos", 0)), 24.0, t, hi)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_fruit(id: int) -> void:
	var st: Dictionary = vs[id]
	var s := _scale_of(id)
	if s <= 0.02:
		return
	var tip := pos_of(id)
	var state: int = fruit_state.get(id, 0)
	if st.grey > 0.5:
		state = 2
	if candidates.has(id):
		state = 1
	var hov: bool = hover.get("t", "") == "fruit" and int(hover.get("id", -1)) == id
	draw_set_transform(tip, 0.0, Vector2(s, s))
	if hov:
		draw_circle(Vector2(0, 42), 40, Color(TtPal.WARN, 0.25), true, -1, true)
	var lab := leaf_label(id)
	TtDraw.fruit(self, Vector2.ZERO, se, lab, t + id * 0.37, state, LEAF_R, letters, 22, -1, -1, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------------------------------------------------------------- ternary
func _draw_ternary() -> void:
	if root_id < 0 or not vs.has(root_id):
		return
	var rp := pos_of(root_id)
	TtDraw.root(self, rp + Vector2(0, 175), rp + Vector2(0, 30), se, t)
	var order := rn.keys()
	order.sort()
	# rankknoop-clusters (één trie-top = één pointerboompje)
	for id in order:
		if node_type(id) != TtNode.Type.PACK:
			continue
		var balls := _balls_of_pack(id)
		var r := Rect2(pos_of(id) - Vector2(46, 46), Vector2(92, 92))
		for b in balls:
			if vs.has(b) and vs[b].g > 0.3:
				r = r.merge(Rect2(pos_of(b) - Vector2(48, 50), Vector2(96, 96)))
		var col: Color = pack_col.get(id, Color(se.leaf[0], 0.07))
		if id == hl_node:
			col = Color(TtPal.INFO, 0.22 + 0.08 * sin(t * 4.0))
		draw_style_box(TtPal.sb(col, 40), r.grow(6))
		TtPal.ring(self, r.grow(6), 40, Color(1, 1, 1, 0.28), 2)
		if balls.is_empty():
			# lege rankknoop: opgekrulde rank in een potje
			TtDraw._curl(self, pos_of(id) + Vector2(-6, 18), Vector2(0, -1), 26.0, t, TtPal.TENDRIL)
			TtPal.text_c(self, TtPal.UI_BOLD, pos_of(id) + Vector2(0, 30), "leeg", 18, Color(TtPal.INK, 0.6))
	# eq-takken (naar volgende rankknoop of vrucht)
	for id in order:
		var tp := node_type(id)
		if tp == TtNode.Type.PACK and int(rn[id].get("parent", -1)) >= 0:
			_draw_t_branch(id)
		elif tp == TtNode.Type.LEAF:
			_draw_t_branch(id)
	# ranken lo/hi
	for id in order:
		if node_type(id) == TtNode.Type.BALL and int(rn[id].get("parent", -1)) >= 0:
			var e := edge_pts(id)
			var g: float = vs[id].g
			if e.size() >= 2 and g > 0.0:
				var pd: Dictionary = rn.get(int(rn[id].parent), {})
				var lo: bool = int(pd.get("lo", -1)) == id
				var n := maxi(4, int(e.size() * clampf(g, 0.0, 1.0)))
				var pts := e.slice(0, n)
				var col := TtPal.LESS if lo else TtPal.GREATER
				if hl_path.has(id):
					draw_polyline(pts, Color(TtPal.INFO, 0.35), 16, true)
				draw_polyline(pts, col.darkened(0.3), 6.5, true)
				draw_polyline(pts, col, 4.5, true)
	# bollen
	for id in order:
		if node_type(id) == TtNode.Type.BALL:
			_draw_ball(id)
	for id in order:
		if is_leaf(id):
			_draw_fruit(id)


func _balls_of_pack(pack: int) -> Array:
	var out := []
	for id in rn:
		if node_type(id) == TtNode.Type.BALL and int(rn[id].get("pack", -1)) == pack:
			out.append(id)
	return out


func _draw_t_branch(id: int) -> void:
	var e := edge_pts(id)
	if e.size() < 2:
		return
	var st: Dictionary = vs[id]
	if st.g <= 0.02:
		return
	var pts := e
	if st.g < 1.0:
		pts = e.slice(0, maxi(4, int(ceil(e.size() * clampf(st.g * 1.4, 0.0, 1.0)))))
	var glow := Color(0, 0, 0, 0)
	if hl_path.has(id):
		glow = Color(TtPal.INFO, 0.28)
	var ww := _depth_w(id)
	TtDraw.branch(self, pts, ww[0] * 0.8, ww[1] * 0.8, se, id * 5 + 1, t, 1, glow, st.wither)


func _draw_ball(id: int) -> void:
	var st: Dictionary = vs[id]
	var g: float = clampf(st.g, 0.0, 1.0)
	if g <= 0.02:
		return
	var d: Dictionary = rn[id]
	var c := pos_of(id)
	var exits := [int(d.get("lo", -1)) >= 0, int(d.get("eq", -1)) >= 0, int(d.get("hi", -1)) >= 0]
	var hi := -1
	if id == int(hl_bud.get("node", -1)):
		hi = ["lo", "eq", "hi"].find(str(hl_bud.get("letter", "")))
	if hover.get("t", "") == "ball" and int(hover.get("id", -1)) == id:
		hi = ["lo", "eq", "hi"].find(str(hover.get("dir", "")))
	draw_set_transform(c, 0.0, Vector2(g, g) * st.pop)
	if id == hl_node or hl_path.has(id):
		draw_circle(Vector2.ZERO, 50, Color(TtPal.INFO, 0.25 + 0.1 * sin(t * 5.0)), true, -1, true)
	TtDraw.rank_knot(self, Vector2.ZERO, str(d.get("ch", "?")), t + id, exits, 30.0, letters, hi)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------------------------------------------------------------- suffixboom
func _draw_suffix() -> void:
	if root_id < 0 or not vs.has(root_id):
		return
	var rp := pos_of(root_id)
	TtDraw.root(self, rp + Vector2(0, 175), rp + Vector2(0, 22), se, t)
	var order := rn.keys()
	order.sort()
	for id in order:
		if id != root_id:
			_draw_s_edge(id)
	# suffix links (Ukkonen)
	for id in order:
		var ln := int(rn[id].get("link", -1))
		if ln >= 0 and ln != id and vs.has(ln) and not is_leaf(id) and id != root_id:
			_draw_link(pos_of(id), pos_of(ln), 1.0)
	if not ghost_link.is_empty() and vs.has(int(ghost_link.get("from", -1))):
		_draw_link(pos_of(int(ghost_link.from)), ghost_link.get("to_pos", pos_of(int(ghost_link.from)) + Vector2(80, 60)), 0.6)
	for id in order:
		if not is_leaf(id):
			_draw_s_knot(id)
	_place_tags(order)
	for id in order:
		if id != root_id:
			_draw_s_labels(id)
	for id in order:
		if is_leaf(id):
			_draw_s_leaf(id)
	if not hl_point.is_empty() and vs.has(int(hl_point.get("node", -1))):
		var pp := point_pos(int(hl_point.node), int(hl_point.get("off", 0)))
		var pr := 0.5 + 0.5 * sin(t * 6.0)
		draw_circle(pp, 22 + 4 * pr, Color(TtPal.INFO, 0.25), true, -1, true)
		draw_arc(pp, 18, 0, TAU, 32, Color(TtPal.INFO, 0.9), 4.0, true)
	if hover.get("t", "") == "point":
		var hp := point_pos(int(hover.node), int(hover.off))
		draw_circle(hp, 16, Color(TtPal.WARN, 0.35), true, -1, true)
		draw_arc(hp, 16, 0, TAU, 28, TtPal.WARN, 3.0, true)


func _draw_link(a: Vector2, b: Vector2, alpha: float) -> void:
	var mid := (a + b) / 2.0 + Vector2(0, -50) + (b - a).orthogonal().normalized() * 30.0
	var pts := PackedVector2Array()
	for k in 25:
		var u := k / 24.0
		pts.append(a.lerp(mid, u).lerp(mid.lerp(b, u), u))
	var col := Color("#FFE680", 0.75 * alpha)
	draw_polyline(pts, Color(col, 0.25 * alpha), 10.0, true)
	draw_polyline(pts, col, 3.0, true)
	draw_circle(b, 7, col, true, -1, true)
	draw_circle(b, 4, Color(1, 1, 1, alpha), true, -1, true)


func _draw_s_edge(id: int) -> void:
	var e := edge_pts(id)
	if e.size() < 2:
		return
	var st: Dictionary = vs[id]
	if st.g <= 0.02:
		return
	var pts := e
	if st.g < 1.0:
		pts = e.slice(0, maxi(4, int(ceil(e.size() * clampf(st.g * 1.4, 0.0, 1.0)))))
	var glow := Color(0, 0, 0, 0)
	if hl_edges.has(id):
		glow = hl_edges[id]
	elif hl_path.has(id):
		glow = Color(TtPal.INFO, 0.3)
	if hl_be == id:
		glow = Color(TtPal.STAR, 0.4)
	var ww := _depth_w(id)
	TtDraw.branch(self, pts, ww[0] * 0.85, ww[1] * 0.85, se, id * 11 + 5, t, 1 if is_leaf(id) else 2, glow, st.wither)


func _draw_s_knot(id: int) -> void:
	var st: Dictionary = vs[id]
	var g: float = clampf(st.g, 0.0, 1.0)
	if g <= 0.02:
		return
	var c := pos_of(id)
	var ks := suffix_kid_letters(id)
	var disp := ""
	for ch in ks:
		disp += display_char(ch)
	if disp == "":
		disp = " "
	var used := []
	for i in disp.length():
		used.append(true)
	draw_set_transform(c, 0.0, Vector2(lerpf(0.3, 1.0, g), g) * st.pop)
	if id == hl_node:
		var kw := disp.length() * 30.0 + 30
		draw_style_box(TtPal.sb(Color(TtPal.INFO, 0.25 + 0.1 * sin(t * 4.0)), 24), Rect2(-kw / 2.0 - 8, -28, kw + 16, 56))
	var hov: bool = hover.get("t", "") == "point" and int(hover.get("node", -1)) == id and int(hover.get("off", 0)) == 0
	TtDraw.knot(self, Vector2.ZERO, disp, used, 30.0, -1, t)
	if hov:
		var kw2 := disp.length() * 30.0 + 20
		TtPal.ring(self, Rect2(-kw2 / 2.0 - 6, -24, kw2 + 12, 48), 22, TtPal.WARN, 4)
	var ls := label_scale   # QA: ringen en telbadges groeien mee bij ver uitzoomen
	if show_depth and id != root_id:
		var dep := int(rn[id].get("depth", 0))
		var r := Rect2(-disp.length() * 15.0 - 12 - 40 * ls, -16 * ls, 40 * ls, 32 * ls)
		draw_style_box(TtPal.sb_thick(Color("#CFE3FF"), int(16 * ls), 3, Color("#8FB0D8")), r)
		TtPal.text_c(self, TtPal.MONO, r.get_center(), str(dep), int(20 * ls), TtPal.INK)
	if show_counts:
		var cnt := _leaf_count(id)
		var r2 := Rect2(disp.length() * 15.0 + 12, -16 * ls, 44 * ls, 32 * ls)
		draw_style_box(TtPal.sb_thick(TtPal.STAR, int(16 * ls), 3, TtPal.STAR_DARK), r2)
		TtPal.text_c(self, TtPal.MONO, r2.get_center(), "×%d" % cnt, int(18 * ls), TtPal.INK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _leaf_count(id: int) -> int:
	if is_leaf(id):
		return 1
	var n := 0
	for k in rn[id].get("kids", {}).values():
		if rn.has(int(k)):
			n += _leaf_count(int(k))
	return n


func _draw_s_labels(id: int) -> void:
	var st: Dictionary = vs[id]
	if st.g < 0.7:
		return
	var e := edge_pts(id)
	if e.size() < 2:
		return
	var n := edge_chars(id)
	var s := edge_string(id)
	# parels per teken op de boog (klikbare punten ertussen)
	for k in n:
		var f := (k + 0.5) / maxf(n, 1)
		var p := TtDraw.path_point(e, lerpf(0.1, 0.92, f))
		if show_strings and not hide_letters:
			continue
		else:
			draw_circle(p, 5.5, Color(TtPal.PAPER, 0.75), true, -1, true)
			draw_arc(p, 5.5, 0, TAU, 12, Color(TtPal.ROPE_DARK, 0.7), 1.5, true)
	if show_strings and not hide_letters:
		var disp := ""
		for ch in s:
			disp += display_char(ch)
		TtDraw.edge_pearls(self, e, disp, 0.1, 0.92, letters)
	if not show_strings:
		var lab := _be_text(id)
		var c: Vector2 = _tag_pos.get(id, TtDraw.path_point(e, 0.5 if not is_leaf(id) else 0.42) + Vector2(34, 0))
		var hi: bool = hl_be == id or (hover.get("t", "") == "be" and int(hover.get("id", -1)) == id)
		var bg := TtPal.STAR if hi else TtPal.PAPER
		TtDraw.tag(self, c, lab, int(round(20 * label_scale)), bg, bg.darkened(0.18), TtPal.INK, TtPal.ROPE)


func _be_text(id: int) -> String:
	var d: Dictionary = rn[id]
	var b := int(d.get("b", 0))
	var ee := int(d.get("e", 0))
	var lab := "%d,%s" % [b + pos_base, "it" if ee == TtCodes.OPEN else str(ee + pos_base)]
	var tx: String = opts.get("text", "")
	if tx.contains("1") and is_leaf(id) and edge_chars(id) < ee - b + 1:
		lab += "⋯"
	return lab


## Plaatst alle (b,e)-borden zonder overlap: per bord een reeks kandidaatposities langs de eigen tak (links en
## rechts ervan); de eerste die geen vruchtlabel, knoest of eerder geplaatst bord raakt, wint (anders de minst
## overlappende). Zo blijven ook de dichte bundels van 4-4/4-5 leesbaar.
var _tag_t := -1.0
var _tag_ls := 0.0


func _place_tags(order: Array) -> void:
	# herbereken een paar keer per seconde (en meteen bij nieuwe borden of een andere labelschaal)
	var fresh := true
	for id in order:
		if id != root_id and not _tag_pos.has(id) and vs.has(id) and float(vs[id].g) >= 0.7:
			fresh = false
			break
	if fresh and t - _tag_t < 0.12 and absf(_tag_ls - label_scale) < 0.02:
		return
	_tag_t = t
	_tag_ls = label_scale
	_tag_pos.clear()
	_tag_rect.clear()
	if show_strings:
		return
	var fs := 20.0 * label_scale
	var obst: Array[Rect2] = []
	for id in order:
		if not vs.has(id):
			continue
		if is_leaf(id):
			obst.append(label_rect(id).grow(2))
			var fc := fruit_center(id)
			obst.append(Rect2(fc - Vector2(30, 34), Vector2(60, 64)))   # de vrucht zelf (+ steeltje)
		else:
			var kw := suffix_kid_letters(id).length() * 30.0 + 24.0
			var kr := Rect2(pos_of(id) - Vector2(kw / 2.0, 22), Vector2(kw, 44))
			if show_depth:
				kr = kr.grow_individual(16 + 40 * label_scale, 0, 0, 0)
			if show_counts:
				kr = kr.grow_individual(0, 0, 16 + 44 * label_scale, 0)
			obst.append(kr)
	# eerst de korte (vaak dichte) bogen, dan de lange: die hebben meer plaats om uit te wijken
	var ids: Array = []
	for id in order:
		if id != root_id and vs.has(id) and float(vs[id].g) >= 0.7 and edge_pts(id).size() >= 2:
			ids.append(id)
	ids.sort_custom(func(a, b): return _edge_len(a) < _edge_len(b))
	for id in ids:
		var e := edge_pts(id)
		var w := TtPal.MONO.get_string_size(_be_text(id), HORIZONTAL_ALIGNMENT_LEFT, -1, int(round(fs))).x + fs * 0.9
		var hsz := Vector2(w, fs * 1.5)
		var base := 0.5 if not is_leaf(id) else 0.42
		var best := Vector2.ZERO
		var best_ov := INF
		for f in [base, base + 0.14, base - 0.14, base + 0.28, base - 0.26, base + 0.4, 0.88, 0.12]:
			var pp := TtDraw.path_point(e, clampf(f, 0.08, 0.92))
			for side in [1.0, -1.0, 0.0]:
				var c: Vector2 = pp + Vector2(side * (w / 2.0 + 8.0), 0)
				var r := Rect2(c - hsz / 2.0, hsz)
				var ov := 0.0
				for o in obst:
					if o.intersects(r):
						ov += o.intersection(r).get_area()
				if ov < best_ov:
					best_ov = ov
					best = c
				if ov <= 0.0:
					break
			if best_ov <= 0.0:
				break
		_tag_pos[id] = best
		_tag_rect[id] = Rect2(best - hsz / 2.0, hsz)
		obst.append(_tag_rect[id].grow(2))


func _edge_len(id: int) -> float:
	var e := edge_pts(id)
	var L := 0.0
	for i in range(1, e.size()):
		L += e[i].distance_to(e[i - 1])
	return L


func be_rect(id: int) -> Rect2:
	if _tag_rect.has(id):
		return _tag_rect[id]
	var e := edge_pts(id)
	if e.size() < 2:
		return Rect2()
	var f2 := 0.5 if not is_leaf(id) else 0.42
	var c := TtDraw.path_point(e, f2) + Vector2(34, 0)
	return Rect2(c - Vector2(46, 16), Vector2(92, 32))


func _draw_s_leaf(id: int) -> void:
	var s := _scale_of(id)
	if s <= 0.02:
		return
	var tip := pos_of(id)
	var d: Dictionary = rn[id]
	var state: int = fruit_state.get(id, 0)
	if vs[id].grey > 0.5:
		state = 2
	if candidates.has(id):
		state = 1
	var hov: bool = hover.get("t", "") == "fruit" and int(hover.get("id", -1)) == id
	draw_set_transform(tip, 0.0, Vector2(s, s))
	if hov:
		draw_circle(Vector2(0, 42), 40, Color(TtPal.WARN, 0.25), true, -1, true)
	var sev := se.duplicate()
	var ow := int(d.get("owner", 0))
	if ow > 0 and ow - 1 < owner_cols.size():
		var oc: Color = owner_cols[ow - 1]
		sev["fruit"] = oc
		sev["fruit_hi"] = oc.lightened(0.4)
		sev["fruit_dark"] = oc.darkened(0.3)
	TtDraw.fruit(self, Vector2.ZERO, sev, leaf_label(id), t + id * 0.37, state, 22.0, "", int(round(22 * label_scale)), -1, -1, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------------------------------------------------------------- vallende delen
func _draw_dying() -> void:
	for it in dying:
		var d: Dictionary = it.d
		var a: float = it.a
		var p: Vector2 = it.p
		draw_set_transform(p, it.rot, Vector2.ONE)
		var e: PackedVector2Array = it.edge
		var local := PackedVector2Array()
		for q in e:
			local.append(q - (e[e.size() - 1] if e.size() > 0 else p) + Vector2.ZERO)
		if local.size() >= 2 and it.how == "fall":
			draw_polyline(local, Color(TtPal.BARK, a), 9.0, true)
		match int(d.get("type", 0)):
			TtNode.Type.LEAF:
				var sev := se.duplicate()
				TtDraw.fruit(self, Vector2.ZERO, sev, "", t, 2 if it.how == "fall" else 0, LEAF_R * a)
			TtNode.Type.INNER:
				var kw := TtViewLayout.knot_width(letters.length()) * 0.8
				draw_style_box(TtPal.sb(Color(TtPal.KNOT, a), 16), Rect2(-kw / 2.0, -16, kw, 32))
			TtNode.Type.BALL:
				draw_circle(Vector2.ZERO, 30 * a, Color(TtPal.KNOT, a), true, -1, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ================================================================ klikzones
## Wat ligt onder wereldpunt `p`? Enkel types in `selectable` (leeg = alles).
func pick(p: Vector2, only := {}) -> Dictionary:
	var sel := only if not only.is_empty() else selectable
	var allow := func(k: String) -> bool: return sel.is_empty() or sel.get(k, false)
	# vruchten (bovenop)
	if allow.call("fruit"):
		for id in rn:
			if is_leaf(id) and _scale_of(id) > 0.5:
				if fruit_center(id).distance_to(p) < 34.0 or label_rect(id).grow(6).has_point(p):
					return {"t": "fruit", "id": id}
	if kind == TtCodes.Kind.TERNARY:
		if allow.call("ball"):
			for id in rn:
				if node_type(id) == TtNode.Type.BALL:
					var c := pos_of(id)
					if c.distance_to(p) < 60.0:
						var v := p - c
						var dir := "eq"
						if v.y > -30.0 or absf(v.x) > 28.0:
							dir = "lo" if v.x < 0 else "hi"
						if absf(v.x) < 22.0:
							dir = "eq"
						return {"t": "ball", "id": id, "dir": dir}
		if allow.call("knot"):
			for id in rn:
				if node_type(id) == TtNode.Type.PACK and pos_of(id).distance_to(p) < 60.0:
					return {"t": "knot", "id": id}
		return {}
	if kind == TtCodes.Kind.SUFFIX or kind == TtCodes.Kind.UKKONEN:
		if allow.call("be"):
			for id in rn:
				if id != root_id and be_rect(id).grow(4).has_point(p):
					return {"t": "be", "id": id}
		if allow.call("point"):
			var best := {}
			var bd := 26.0
			for id in rn:
				if not is_leaf(id) and pos_of(id).distance_to(p) < 40.0:
					return {"t": "point", "node": id, "off": 0}
			for id in rn:
				if id == root_id:
					continue
				var n := edge_chars(id)
				var e := edge_pts(id)
				if e.size() < 2:
					continue
				for k in range(1, n):
					var q := TtDraw.path_point(e, lerpf(0.1, 0.92, float(k) / n))
					var dd := q.distance_to(p)
					if dd < bd:
						bd = dd
						best = {"t": "point", "node": id, "off": k}
			if not best.is_empty():
				return best
		return {}
	# knoppen
	if allow.call("bud"):
		for id in rn:
			if node_type(id) != TtNode.Type.INNER:
				continue
			var c2 := pos_of(id)
			var kw := TtViewLayout.knot_width(letters.length())
			if Rect2(c2.x - kw / 2.0, c2.y - 44, kw, 66).has_point(p):
				var gap := knot_gap()
				var i := int(round((p.x - (c2.x - (letters.length() - 1) * gap / 2.0)) / gap))
				i = clampi(i, 0, letters.length() - 1)
				return {"t": "bud", "node": id, "letter": letters[i]}
	if allow.call("knot"):
		for id in rn:
			if node_type(id) != TtNode.Type.INNER:
				continue
			var c3 := pos_of(id)
			var kw3 := TtViewLayout.knot_width(letters.length()) + (130.0 if kind == TtCodes.Kind.PATRICIA else 0.0)
			if Rect2(c3.x - TtViewLayout.knot_width(letters.length()) / 2.0, c3.y - 30, kw3, 60).has_point(p):
				return {"t": "knot", "id": id}
	if allow.call("edge"):
		var best_id := -1
		var bd2 := 18.0
		for id in rn:
			if id == root_id:
				continue
			var e2 := edge_pts(id)
			for k in range(1, e2.size()):
				var q2 := Geometry2D.get_closest_point_to_segment(p, e2[k - 1], e2[k])
				var dd2 := q2.distance_to(p)
				if dd2 < bd2:
					bd2 = dd2
					best_id = id
		if best_id >= 0:
			return {"t": "edge", "id": best_id}
	return {}


func set_hover(h: Dictionary) -> void:
	if h != hover:
		hover = h
		hovered.emit(h)


## Rechthoek (wereld) rond alles wat getekend is, voor de camera.
func content_rect() -> Rect2:
	var r := bounds
	if root_id >= 0 and vs.has(root_id):
		r = r.merge(Rect2(pos_of(root_id) + Vector2(-140, 0), Vector2(280, 200)))
	return r
