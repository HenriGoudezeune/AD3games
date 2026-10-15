class_name TtReplayView
extends SubViewportContainer
## Herbeleving in de terugblik: een tweede, alleen-lezen model (`TtLevels.make_model` + `restore(before)`)
## in een eigen SubViewport. Toont de tuin van vóór de misstap met jouw zet in het rood; na een tel speelt de
## juiste zet (hint) zich af in het groen (de "groene spookhand").

var vp: SubViewport
var root2d: Node2D
var cam: Camera2D
var view: TtTreeView
var model: TtTreeModel
var _gen := 0
var _mark_yours := {}
var _mark_right := {}
var t := 0.0
var _hand_p := Vector2.ZERO
var _hand_a := 0.0
var _label := ""


func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	vp = SubViewport.new()
	vp.transparent_bg = false
	vp.size = Vector2i(size)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	root2d = Node2D.new()
	vp.add_child(root2d)
	var bg := Node2D.new()
	bg.draw.connect(func():
		bg.draw_rect(Rect2(-5000, -5000, 10000, 10000), Color("#DCEBD5")))
	root2d.add_child(bg)
	cam = Camera2D.new()
	root2d.add_child(cam)
	cam.make_current()
	var ov := Node2D.new()
	ov.z_index = 60
	ov.draw.connect(func(): _draw_marks(ov))
	root2d.add_child(ov)
	set_meta("ov", ov)


func show_moment(spec: TtLevelSpec, kind: int, letters: String, season: int, before: Dictionary, yours: Dictionary,
		right: Dictionary, mistake: bool) -> void:
	_gen += 1
	var g := _gen
	if view and is_instance_valid(view):
		view.queue_free()
	model = TtLevels.make_model(spec)
	if not before.is_empty():
		model.restore(before)
	view = TtTreeView.new()
	var vopts := {"pos_base": spec.pos_base, "text": spec.text}
	if model.get("text") != null:
		vopts["text"] = model.get("text")
	root2d.add_child(view)
	root2d.move_child(view, 1)
	view.show_strings = spec.labels == "strings"
	view.setup(model, kind, letters, season, vopts)
	_mark_yours = {}
	_mark_right = {}
	_fit()
	_mark_yours = _target(yours) if mistake else {}
	_label = ""
	if not mistake:
		_mark_right = _target(yours)
		_fit()
		return
	_fit()
	await get_tree().create_timer(1.3).timeout
	if g != _gen:
		return
	_mark_right = _target(right)
	_hand_a = 1.0
	var tw := create_tween()
	tw.tween_property(self, "_hand_a", 0.0, 1.5).set_delay(1.0)
	await get_tree().create_timer(0.9).timeout
	if g != _gen or right.is_empty() or model.card == null:
		return
	# speel de juiste zet af in het replay-model
	var res: Dictionary = model.apply(right)
	if bool(res.get("ok", false)):
		view.sync(false)
		view.reveal_all_now()
		TtSnd.play("bud_plop", -10.0, 1.2)
	_fit()


func _target(mv: Dictionary) -> Dictionary:
	if mv.is_empty() or model == null:
		return {}
	var cur: Dictionary = model.cursor() if model.card != null else {}
	match str(mv.get("act", "")):
		"move":
			return {"p": view.bud_top(int(cur.get("node", model.root)), str(mv.letter)), "txt": str(mv.letter)}
		"split":
			return {"p": view.fruit_center(int(cur.get("leaf", -1))) + Vector2(0, 80), "txt": "j = %d" % int(mv.j)}
		"answer", "same":
			return {"p": view.fruit_center(int(cur.get("leaf", -1))), "txt": ""}
		"cut":
			var e := view.edge_pts(int(mv.node))
			return {"p": TtDraw.path_point(e, 0.4) if e.size() > 1 else view.pos_of(int(mv.node)), "txt": "✂"}
		"prune":
			return {"p": view.pos_of(int(mv.node)), "txt": "✂"}
		"pick_leaf":
			return {"p": view.fruit_center(int(mv.leaf)), "txt": ""}
		"attach", "locate":
			return {"p": view.point_pos(int(mv.node), int(mv.get("off", 0))), "txt": ""}
		"hop", "link":
			return {"p": view.pos_of(int(mv.node)), "txt": ""}
		"go":
			var ball := int(cur.get("ball", -1))
			var off: Vector2 = {"lo": Vector2(-44, -16), "eq": Vector2(0, -44), "hi": Vector2(44, -16)}.get(str(mv.dir), Vector2.ZERO)
			return {"p": view.pos_of(ball) + off, "txt": ""}
		"read":
			return {"p": view.pos_of(int(cur.get("node", model.root))) + Vector2(0, -60), "txt": "pos %d" % int(mv.pos)}
	return {"p": view.pos_of(int(cur.get("node", model.root))) + Vector2(0, -60), "txt": ""}


func _fit() -> void:
	if view == null:
		return
	var r := view.content_rect().grow(40)
	var z := minf(size.x / maxf(r.size.x, 1.0), size.y / maxf(r.size.y, 1.0))
	z = clampf(z, 0.3, 1.0)
	var c := r.get_center()
	# QA (4-4/4-5): een brede boom past enkel op ≈ 0,3 en wordt onleesbaar; zoom dan in op de plek van de misstap
	var focus: Dictionary = _mark_yours if not _mark_yours.is_empty() else _mark_right
	if z < 0.55 and not focus.is_empty():
		z = 0.55
		var half := size / z / 2.0
		var fp: Vector2 = focus.p
		c = Vector2(clampf(fp.x, r.position.x + half.x, maxf(r.end.x - half.x, r.position.x + half.x)),
			clampf(fp.y, r.position.y + half.y, maxf(r.end.y - half.y, r.position.y + half.y)))
	cam.zoom = Vector2(z, z)
	cam.position = c
	view.label_scale = clampf(snappedf(0.8 / z, 0.1), 1.0, 1.7) if view.kind == TtCodes.Kind.SUFFIX or view.kind == TtCodes.Kind.UKKONEN else 1.0


func _process(delta: float) -> void:
	t += delta
	if vp and Vector2i(size) != vp.size:
		vp.size = Vector2i(size)
	if has_meta("ov"):
		(get_meta("ov") as Node2D).queue_redraw()


func _draw_marks(ci: Node2D) -> void:
	if not _mark_yours.is_empty():
		var p: Vector2 = _mark_yours.p
		var pr := 0.5 + 0.5 * sin(t * 6.0)
		ci.draw_circle(p, 30 + 4 * pr, Color(TtPal.ERR, 0.25), true, -1, true)
		ci.draw_arc(p, 30, 0, TAU, 32, TtPal.ERR, 4.0, true)
		if str(_mark_yours.get("txt", "")) != "":
			TtPal.text_outline_c(ci, TtPal.UI_BOLD, p + Vector2(0, -48), "jij: " + str(_mark_yours.txt), 26, TtPal.ERR, 6, Color.WHITE)
	if not _mark_right.is_empty():
		var q: Vector2 = _mark_right.p
		var pr2 := 0.5 + 0.5 * sin(t * 6.0 + 1.0)
		ci.draw_circle(q, 34 + 4 * pr2, Color(TtPal.OK, 0.25), true, -1, true)
		ci.draw_arc(q, 34, 0, TAU, 32, TtPal.OK, 5.0, true)
		if str(_mark_right.get("txt", "")) != "":
			TtPal.text_outline_c(ci, TtPal.UI_BOLD, q + Vector2(0, 52), "juist: " + str(_mark_right.txt), 26, Color("#1F8A5B"), 6, Color.WHITE)
		if _hand_a > 0.01:
			var hp := q + Vector2(20, 30)
			ci.draw_set_transform(hp, -0.35, Vector2.ONE)
			ci.draw_style_box(TtPal.sb(Color(1, 1, 1, _hand_a), 12), Rect2(-9, -4, 18, 44))
			ci.draw_style_box(TtPal.sb(Color(1, 1, 1, _hand_a), 22), Rect2(-22, 26, 52, 48))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
