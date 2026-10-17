extends Node2D
## Hoofdscène "depot": bouwt alle views in code, vertaalt input naar core-acties (ExtHashModel/DayDirector)
## en speelt elke statusverandering geanimeerd af (GDD §2, §8). Structurele animaties (verdubbelen, zagen,
## verdelen, herpoging) lopen via een sequentiële animatiewachtrij; pakjes-drops lopen parallel.

const WALL_RECT := Rect2(400, 250, 160, 790)
const HATCH_TOP := 330.0
const HATCH_BOTTOM := 1024.0
const RACK_X := 960.0
const RACK_W := 540.0
const RACK_TOP := 250.0
const RACK_BOTTOM := 1040.0
const LEVER_POS := Vector2(140, 262)
const BELT_END_X := 236.0
const BELT_START_X := 1790.0
const BELT_SPACING := 200.0
const CALM_SPEED := 340.0
const BELT_BOX := Vector2(176, 104)
const STUCK_BOX := Vector2(104, 52)
const STUCK_F := 0.84
const BIN2 := Rect2(140, 640, 220, 300)     # overloopbak (onder de hendel)

# ---------------------------------------------------------------- core
var spec
var director
var model: ExtHashModel
var scoring
var day := 1
var hint_level := 0
var calm := true

# ---------------------------------------------------------------- views
var cam: Camera2D
var world: Node2D
var belt: BeltView
var lever: LeverView
var wall: Node2D
var hatch_layer: Node2D
var hatches: Array = []           # HatchView per dir-index
var pipe_layers: Array = []       # [out, body, shine, glow]
var pipes: Array = []             # PipeView per dir-index
var bulge_layer: Node2D
var rack_layer: Node2D
var racks := {}                   # bucket_id -> RackView
var parcel_layer: Node2D
var fx_layer: Node2D
var table: SortTable
var hud: HudView
var hud_layer: CanvasLayer
var overlay: Node2D               # typbuffer, spookhand, ballon (wereld-coördinaten, boven alles)
var vignette: ColorRect
var vig_mat: ShaderMaterial
var pause_menu: Control
var wall_shift := 0.0

# ---------------------------------------------------------------- toestand
var belt_views := {}              # pid -> ParcelView (op de band)
var belt_x := {}                  # pid -> x
var belt_age := {}                # pid -> wereldtijd op de band
var stuck_views := {}             # pid -> ParcelView (vast in buis)
var table_views := {}             # pid -> ParcelView (op de sorteertafel)
var drag_view: ParcelView = null
var drag_from := ""               # "belt" | "table"
var drag_offset := Vector2.ZERO
var drag_vel := Vector2.ZERO
var drag_lever := false
var lever_press_y := 0.0
var lever_moved := false
var hover_hatch := -1
var hover_rack := -1
var type_buf := ""
var _queue: Array = []
var _running := false
var _lock := false                # structurele actie bezig
var _in_player := false           # signaal komt van een directe spelersactie
var _coin_queue: Array = []
var _coin_timer := 0.0
var world_scale := 1.0
var alarm_on := false
var alarm_level := 0.0
var chain_level := 0
var time_s := 0.0
var real_s := 0.0
var finished := false
var paused := false
var wrong_sides: Array = []       # bucket-ids met een verkeerd verdeeld pakje (lampje bij dichtklappen)
var bot := false
var bot_t := 0.0
var _t := 0.0
var _idle := 0.0
var loupe := false
var _last_front_id := -1
var _report: Dictionary = {}
var parent_spec                   # dag 7: ouder met phases
var zones: Node2D
var counter_layer: Node2D
var desk_layer: Node2D
var cust_views := {}              # customer id -> CustomerView
var cust_busy := {}               # id -> true (serve-animatie bezig)
var cust_focus := false
var bin_view: Node2D
var bin_count := 0
var ff_btn: Button
var fast := false
var _ending := false
var hints_done := {}
var _pending_hint: Dictionary = {}
var _pending_since := 0.0
var _chef_text := ""
var _chef_k := 0.0
var _bot_mistake_done := false
var _card_end := 0.0
var _expected_racks := 0
var _split_info: Dictionary = {}   # visuele split-toestand (oude bordjes tot na het verdelen)
# leerpad (design/LEARNING_PATH_hashdash.md): Kijk/Samen-les in plaats van een dag
var lesson: Dictionary = {}        # {part, phase} of {}
var coach: LessonCoach = null
var lesson_hold := false           # coach zet de wereld stil (Kijk: tussen de stappen)


func _ready() -> void:
	day = Game.current_day
	bot = Game.cmd.has("bot")
	if not bot and not Game.lesson_queue.is_empty():
		lesson = Game.lesson_queue[0]
	_build_world()
	if not lesson.is_empty():
		coach = LessonCoach.new()
		coach.depot = self
		coach.part_id = str(lesson.part)
		coach.phase = str(lesson.phase)
		add_child(coach)
		_kb_tip_done = true
	_start_day()
	Juice.camera = cam
	Juice.base_zoom = 1.0
	if coach:
		coach.start()
	if Game.cmd.has("speed"):
		Engine.time_scale = float(Game.cmd["speed"])
	# gedeelde navigatie (design/SHARED_UX.md §1): huisje links in de HUD-balk, in een level met bevestiging
	HubNav.set_context({"in_level": true, "level_select_scene": Game.SCENE_MAP, "corner_offset": HudView.HOME_OFFSET})
	# eerste keer een nieuwe mechaniek: korte tutorial (onthouden in de save)
	var tut := HDGuide.pending_tutorial(day)
	if tut != "" and not bot and not Game.cmd.has("no_tutorial") and coach == null:
		_open_tutorial.call_deferred(tut)


func _exit_tree() -> void:
	Sfx.loop("alarm", "", false)
	Sfx.loop("belt", "", false)
	Sfx.set_slowmo(false)
	Engine.time_scale = 1.0
	Juice.base_zoom = 1.0


# ================================================================ opbouw
func _build_world() -> void:
	cam = Camera2D.new()
	cam.position = Vector2(960, 540)
	add_child(cam)
	cam.make_current()
	_build_background()
	world = Node2D.new()
	add_child(world)
	zones = Node2D.new()
	zones.draw.connect(func(): _draw_zones(zones))
	world.add_child(zones)
	belt = BeltView.new()
	world.add_child(belt)
	lever = LeverView.new()
	lever.position = LEVER_POS
	world.add_child(lever)
	pipe_layers = []
	for i in 4:
		var l := Node2D.new()
		world.add_child(l)
		pipe_layers.append(l)
	bulge_layer = Node2D.new()
	bulge_layer.draw.connect(_draw_bulges)
	world.add_child(bulge_layer)
	wall = Node2D.new()
	wall.draw.connect(_draw_wall)
	world.add_child(wall)
	hatch_layer = Node2D.new()
	wall.add_child(hatch_layer)
	rack_layer = Node2D.new()
	world.add_child(rack_layer)
	counter_layer = Node2D.new()
	world.add_child(counter_layer)
	desk_layer = Node2D.new()
	desk_layer.draw.connect(_draw_desk)
	world.add_child(desk_layer)
	bin_view = Node2D.new()
	bin_view.position = BIN2.get_center()
	bin_view.draw.connect(_draw_bin)
	bin_view.visible = false
	world.add_child(bin_view)
	fx_layer = Node2D.new()
	world.add_child(fx_layer)
	table = SortTable.new()
	table.visible = false
	world.add_child(table)
	parcel_layer = Node2D.new()
	world.add_child(parcel_layer)
	overlay = Node2D.new()
	overlay.z_index = 60
	overlay.draw.connect(_draw_overlay)
	world.add_child(overlay)
	# vignet (rood bij alarm)
	var vl := CanvasLayer.new()
	vl.layer = 5
	add_child(vl)
	vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform float amount = 0.0;
uniform vec4 col : source_color = vec4(1.0, 0.25, 0.2, 1.0);
void fragment() {
	vec2 q = UV - 0.5;
	float v = smoothstep(0.25, 0.75, length(q * vec2(1.0, 1.3)));
	COLOR = vec4(col.rgb, v * amount);
}
"""
	vig_mat = ShaderMaterial.new()
	vig_mat.shader = sh
	vignette.material = vig_mat
	vl.add_child(vignette)
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)
	hud = HudView.new()
	hud_layer.add_child(hud)
	ff_btn = UIKit.button("Doorspoelen  ⏩", Pal.WARN, Pal.INK, 30, 300)
	ff_btn.position = Vector2(1580, 960)
	ff_btn.visible = false
	ff_btn.pressed.connect(_fast_forward)
	hud_layer.add_child(ff_btn)


func _build_background() -> void:
	var rect := ColorRect.new()
	rect.size = Vector2(2200, 1300)
	rect.position = Vector2(-140, -110)
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform vec4 c_bg : source_color;
uniform vec4 c_deep : source_color;
uniform vec4 c_line : source_color;
void fragment() {
	vec2 px = UV * vec2(2200.0, 1300.0) - vec2(140.0, 110.0);
	vec2 g = abs(fract(px / 64.0) - 0.5);
	float line = 1.0 - smoothstep(0.475, 0.49, max(g.x, g.y));
	vec3 col = mix(c_bg.rgb, c_line.rgb, (1.0 - line) * 0.9);
	vec2 q = px / vec2(1920.0, 1080.0) - vec2(0.5, 0.55);
	float v = smoothstep(0.35, 0.95, length(q * vec2(1.0, 1.25)));
	col = mix(col, c_deep.rgb, v * 0.85);
	COLOR = vec4(col, 1.0);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("c_bg", Pal.BG)
	mat.set_shader_parameter("c_deep", Pal.BG_DEEP)
	mat.set_shader_parameter("c_line", Pal.FLOOR_LINE)
	rect.material = mat
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)


func _draw_zones(n: Node2D) -> void:
	var zs := [Rect2(120, 240, 460, 820), Rect2(930, 240, 600, 820)]
	if _has_desk():
		zs.append(Rect2(1548, 240, 356, 820))
	for r in zs:
		var s := Pal.sbn(Color(1, 1, 1, 0.022), 24)
		s.border_color = Color(1, 1, 1, 0.05)
		s.set_border_width_all(2)
		n.draw_style_box(s, r)
	if not _has_desk():
		_draw_decor(n)


func _draw_decor(n: Node2D) -> void:
	# pallets en een plant aan de rand (ART.md §10): nooit in het speelveld
	for k in 2:
		var p := Vector2(1600 + k * 130, 930 - k * 20)
		n.draw_style_box(Pal.sb(Color("#3a2f2a"), 6, 8, Vector2(0, 6)), Rect2(p, Vector2(110, 22)))
		for s in 3:
			n.draw_rect(Rect2(p + Vector2(6 + s * 36, 22), Vector2(22, 10)), Color("#2b2320"))
		n.draw_style_box(Pal.sb(Pal.KRAFT, 8), Rect2(p + Vector2(8, -60), Vector2(92, 60)))
		n.draw_rect(Rect2(p + Vector2(48, -60), Vector2(12, 56)), Color(Pal.TAPE, 0.55))
	var pc := Vector2(1820, 380)
	n.draw_style_box(Pal.sb(Color("#B55A3C"), 10, 8, Vector2(0, 6)), Rect2(pc + Vector2(-30, 0), Vector2(60, 56)))
	for k in 5:
		var ang := -PI / 2 + (k - 2) * 0.45
		n.draw_circle(pc + Vector2(cos(ang), sin(ang)) * 46 + Vector2(0, -10), 24, Color("#2E9E6A").darkened(0.1 * (k % 2)), true, -1, true)
	# heftruck-parking (ritten)
	Pal.truck(n, Vector2(1700, 560), 3.0)
	Pal.text_c(n, Pal.UI, Vector2(1700, 640), "heftruck", 20, Color(Pal.TEXT_DIM, 0.6))


func _has_desk() -> bool:
	if spec == null:
		return false
	return spec.has_customers()


# ================================================================ dag starten
func _start_day() -> void:
	parent_spec = Days.get_day(day) if coach == null else HDLessons.spec(coach.part_id, coach.phase)
	director = DayDirector.new()
	director.parcel_spawned.connect(_on_spawned)
	director.day_finished.connect(_on_day_finished)
	director.customer_arrived.connect(_on_customer_arrived)
	director.customer_left.connect(_on_customer_left)
	director.start(parent_spec)
	_begin_phase(true)


## (Her)start een fase: nieuw model + scoring van de director (dag 7: ochtend → middag).


func _connect_core() -> void:
	model.parcel_placed.connect(_on_placed)
	model.parcel_blocked.connect(_on_blocked)
	model.still_blocked.connect(_on_still_blocked)
	model.directory_doubled.connect(_on_doubled)
	model.double_refused.connect(_on_double_refused)
	model.split_started.connect(_on_split_started)
	model.split_refused.connect(_on_split_refused)
	model.parcel_assigned.connect(_on_assigned)
	model.split_finished.connect(_on_split_finished)
	model.parcel_lost.connect(_on_lost)
	model.parcel_dumped.connect(_on_dumped)
	model.io_changed.connect(func(r, w): hud.set_io(r, w))
	scoring.coins_changed.connect(_on_coins)
	scoring.combo_changed.connect(_on_combo)
	scoring.dash.connect(_on_dash)
	scoring.reputation_changed.connect(_on_rep)


# ================================================================ layout
## a >= 6: de muur verbreedt letterlijk tot twee kolommen luiken (GDD §5.2 endless).
func wall_cols(a: int) -> int:
	return 2 if a >= 6 else 1


func wall_rect_for(a: int) -> Rect2:
	return Rect2(WALL_RECT.position, Vector2(WALL_RECT.size.x + 140.0 * (wall_cols(a) - 1), WALL_RECT.size.y))


func hatch_step(a: int) -> float:
	return (HATCH_BOTTOM - HATCH_TOP) / float((1 << a) / wall_cols(a))


func hatch_rect(i: int, a: int) -> Rect2:
	var step := hatch_step(a)
	var rows := (1 << a) / wall_cols(a)
	var col := i / rows
	var row := i % rows
	var gap := clampf(step * 0.16, 3.0, 24.0)
	var h := minf(150.0, step - gap)
	return Rect2(WALL_RECT.position.x + 14 + col * 140.0, HATCH_TOP + row * step + (step - h) / 2.0, WALL_RECT.size.x - 28, h)


func pipe_start_x(a: int) -> float:
	return wall_rect_for(a).end.x - 6


func pipe_width(a: int) -> float:
	return clampf(hatch_step(a) * 0.42, 8.0, 24.0)


## bucket_id -> {pos (midden), size}
func rack_targets() -> Dictionary:
	var L := model.layout()
	var cnt := L.size()
	if cnt > 12:
		return _rack_grid(L)
	var hc := maxi(cnt, mini(_expected_racks, 12))   # QA P1-2: geen layoutwissel midden in een zaag
	var gap := 18.0 if hc <= 4 else 10.0
	var h := clampf((RACK_BOTTOM - RACK_TOP - gap * (hc - 1)) / hc, 56.0, 214.0)
	var ys: Array[float] = []
	for e in L:
		var s: int = e.start
		var sp: int = e.span
		var y0 := hatch_rect(s, model.a).get_center().y
		var y1 := hatch_rect(s + sp - 1, model.a).get_center().y
		ys.append((y0 + y1) / 2.0)
	for i in cnt:
		ys[i] = maxf(ys[i], RACK_TOP + h / 2.0)
		if i > 0:
			ys[i] = maxf(ys[i], ys[i - 1] + h + gap)
	for i in range(cnt - 1, -1, -1):
		ys[i] = minf(ys[i], RACK_BOTTOM - h / 2.0)
		if i < cnt - 1:
			ys[i] = minf(ys[i], ys[i + 1] - h - gap)
	var out := {}
	for i in cnt:
		out[int(L[i].bucket_id)] = {"pos": Vector2(RACK_X + RACK_W / 2.0, ys[i]), "size": Vector2(RACK_W, h), "order": i}
	return out


## Veel rekken (endless): raster van 2–3 kolommen, kolom per kolom in pointerarray-volgorde.
func _rack_grid(L: Array) -> Dictionary:
	var cnt := L.size()
	var cols := 2 if cnt <= 28 else 3
	var rows := int(ceil(cnt / float(cols)))
	var gap := 6.0
	var h := clampf((RACK_BOTTOM - RACK_TOP - gap * (rows - 1)) / rows, 24.0, 80.0)
	var w := (RACK_W + 20.0 - 10.0 * (cols - 1)) / cols
	var out := {}
	for i in cnt:
		var col := i / rows
		var row := i % rows
		var pos := Vector2(RACK_X + col * (w + 10.0) + w / 2.0, RACK_TOP + row * (h + gap) + h / 2.0)
		out[int(L[i].bucket_id)] = {"pos": pos, "size": Vector2(w, h), "order": i}
	return out


func pipe_end_for(bid: int, tg: Dictionary) -> Vector2:
	var t: Dictionary = tg[bid]
	var p: Vector2 = t.pos
	var s: Vector2 = t.size
	var dy := 28.0 if s.y >= 150 else 0.0
	return Vector2(p.x - s.x / 2.0 + 4, p.y + dy)


func pipe_mid_for(bid: int, tg: Dictionary) -> float:
	var o: int = tg[bid].order
	var base := pipe_start_x(model.a) + 126.0
	return base + (o % 2) * (90.0 if model.a < 6 else 50.0)


func rack_color(bid: int) -> Color:
	return Pal.bucket_color(bid)


## Alles in één keer opbouwen volgens het model (start van de dag, herbeleving).
func _rebuild_all() -> void:
	for h in hatches:
		h.queue_free()
	hatches.clear()
	for p in pipes:
		p.queue_free()
	pipes.clear()
	for k in racks:
		racks[k].queue_free()
	racks.clear()
	var a := model.a
	_wall_w = wall_rect_for(a).size.x
	var tg := rack_targets()
	for i in model.dir.size():
		var hv := HatchView.new()
		var r := hatch_rect(i, a)
		hv.idx = i
		hv.code = HashUtil.bits(i, a)
		hv.size = r.size
		hv.position = r.get_center()
		hv.col = rack_color(model.dir[i])
		hatch_layer.add_child(hv)
		hatches.append(hv)
	for i in model.dir.size():
		pipes.append(_make_pipe(i, tg))
	for e in model.layout():
		var bid: int = e.bucket_id
		_make_rack(bid, tg[bid])
	for bid in racks:
		var rv: RackView = racks[bid]
		var b: Bucket = model.buckets[bid]
		for p in b.parcels:
			var s := rv.free_slot()
			var pv := _make_parcel_view(p)
			rv.add_child(pv)
			_fit_parcel_to_rack(pv, rv)
			pv.position = rv.slot_center(s)
			rv.slots[s] = pv
	wall.queue_redraw()


func _make_pipe(i: int, tg: Dictionary) -> PipeView:
	var p := PipeView.new()
	var bid := model.dir[i]
	p.idx = i
	p.col = rack_color(bid)
	p.width = pipe_width(model.a)
	p.p_start = Vector2(pipe_start_x(model.a), hatch_rect(i, model.a).get_center().y)
	p.p_end = pipe_end_for(bid, tg)
	p.mid_x = pipe_mid_for(bid, tg)
	add_child(p)
	p.attach(pipe_layers[0], pipe_layers[1], pipe_layers[2], pipe_layers[3])
	return p


func _make_rack(bid: int, t: Dictionary) -> RackView:
	var rv := RackView.new()
	rv.bucket_id = bid
	rv.col = rack_color(bid)
	rv.n = model.n
	rv.a = model.a
	rv.set_g(model.g)
	rv.ab = model.buckets[bid].ab
	rv.label = model.label_of(bid)
	rv.size = t.size
	rv.position = t.pos
	rack_layer.add_child(rv)
	racks[bid] = rv
	_refresh_rack(rv)
	return rv


func _refresh_rack(rv: RackView) -> void:
	rv.a = model.a
	if _split_info.has("bid") and (rv.bucket_id == int(_split_info.bid) or rv.bucket_id == int(_split_info.nbid)):
		# QA P0-1: tijdens het verdelen toont het oude rek nog zijn oude bordje/ab; het nieuwe rek bestaat visueel
		# pas na het verdelen (volgorde van de notas p. 7–8).
		rv.label = str(_split_info.old_label)
		rv.ab = int(_split_info.old_ab)
		rv.saw_visible = false
		return
	var b: Bucket = model.buckets[rv.bucket_id]
	rv.ab = b.ab
	rv.label = model.label_of(rv.bucket_id)
	var stuck_here := false
	for e in model.blocked:
		if model.dir[int(e.via_index)] == rv.bucket_id:
			stuck_here = true
	rv.saw_visible = b.ab < model.a or stuck_here


## Emmer zoals de speler hem nu ziet (tijdens een split wijzen de omgezette pointers visueel nog naar het oude rek).


func _make_parcel_view(p: Parcel) -> ParcelView:
	var pv := ParcelView.new()
	pv.setup(p.id, p.hv, model.n, p.key_label)
	pv.apply_hint(hint_level, model.a, loupe)
	return pv


func _fit_parcel_to_rack(pv: ParcelView, rv: RackView) -> void:
	pv.visible = not rv.is_mini()
	pv.set_size(rv.slot_box(), rv.slot_label_size())
	pv.apply_hint(hint_level, model.a, loupe)
	if pv.key_label != "":
		pv.set_size(rv.slot_box(), rv.slot_label_size() + 6)


## Rekken + buizen naar hun doelposities (na split/verdubbeling).
func _relayout(dur := 0.35) -> void:
	var tg := rack_targets()
	for bid in racks:
		if not tg.has(bid):
			continue
		var rv: RackView = racks[bid]
		var t: Dictionary = tg[bid]
		var tw := rv.create_tween().set_parallel(true)
		tw.tween_property(rv, "position", t.pos, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		if rv.size != t.size:
			tw.tween_property(rv, "size", t.size, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			_reslot_later(rv, dur)
		_refresh_rack(rv)
	for i in pipes.size():
		var p: PipeView = pipes[i]
		var bid := model.dir[i]
		var tw2 := create_tween().set_parallel(true)
		tw2.tween_property(p, "p_end", pipe_end_for(bid, tg), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw2.tween_property(p, "mid_x", pipe_mid_for(bid, tg), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func _reslot_later(rv: RackView, dur: float) -> void:
	# pakjes volgen de nieuwe rekmaat (vakken krimpen/groeien mee)
	var tw := rv.create_tween()
	tw.tween_method(func(_v): _reslot(rv, false), 0.0, 1.0, dur)
	tw.tween_callback(func(): _reslot(rv, false))


func _reslot(rv: RackView, animated := true) -> void:
	for s in rv.slots.size():
		var pv = rv.slots[s]
		if pv == null or not is_instance_valid(pv):
			continue
		_fit_parcel_to_rack(pv, rv)
		if animated:
			pv.create_tween().tween_property(pv, "position", rv.slot_center(s), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			pv.position = rv.slot_center(s)


## Zekerheid: rekinhoud gelijk aan het model (na elke structurele animatie).
func _reconcile() -> void:
	for bid in racks:
		var rv: RackView = racks[bid]
		var b: Bucket = model.buckets[bid]
		var want := {}
		for p in b.parcels:
			want[p.id] = p
		for s in rv.slots.size():
			var pv = rv.slots[s]
			if pv != null and (not is_instance_valid(pv) or not want.has(pv.pid)):
				if is_instance_valid(pv) and pv.get_parent() == rv:
					pv.queue_free()
				rv.slots[s] = null
		var have := {}
		for pv in rv.slots:
			if pv != null:
				have[pv.pid] = true
		for pid in want:
			if have.has(pid):
				continue
			var s2 := rv.free_slot()
			if s2 < 0:
				continue
			var pv2 := _make_parcel_view(want[pid])
			rv.add_child(pv2)
			_fit_parcel_to_rack(pv2, rv)
			pv2.position = rv.slot_center(s2)
			pv2.scale = Vector2(0.2, 0.2)
			pv2.create_tween().tween_property(pv2, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			rv.slots[s2] = pv2
		_refresh_rack(rv)


# ================================================================ muur tekenen
func _draw_wall() -> void:
	var r := WALL_RECT
	r.size.x = _wall_w
	r.position.x += wall_shift
	wall.draw_style_box(Pal.sb(Pal.PANEL, 24, 18, Vector2(0, 10)), r)
	Pal.head(wall, Rect2(r.position, Vector2(r.size.x, 64)), Pal.PANEL_HI, 24)
	var a := model.a if model else 1
	var badge := Rect2(r.get_center().x - 56, r.position.y + 8, 112, 34)
	var full := model != null and a >= model.n
	wall.draw_style_box(Pal.sb(Pal.ERR if (full and _wall_flash > 0.5) else Pal.TEXT, 17), badge)
	Pal.text_c(wall, Pal.UI_BOLD, badge.get_center(), "a = %d" % a, 26, Pal.INK)
	Pal.text_c(wall, Pal.UI, Vector2(r.get_center().x, r.position.y + 54), "%d luiken" % (1 << a), 17, Pal.TEXT_DIM)

var _wall_flash := 0.0
var _wall_w := 160.0


# ================================================================ hoofdlus
func _process(delta: float) -> void:
	_t += delta
	if finished or _ending:
		_update_views(delta)
		_update_customers(delta)
		return
	# QA P1-3: zolang een animatie de input blokkeert (zaag, tafel, heftruck) staat de wereld stil
	director.set_world_hold(_lock or _running or lesson_hold)
	var frozen: bool = director.is_world_frozen()
	var target_scale: float = 0.0 if frozen else director.world_time_scale()
	world_scale = move_toward(world_scale, target_scale, delta / 0.25)
	var dtw := delta * world_scale
	real_s += delta
	time_s += dtw
	director.tick(dtw, delta)
	_update_alarm(delta)
	if hud.opt_r >= 0:
		var ol: Dictionary = director.optimum_live()
		hud.opt_r = int(ol.get("reads", hud.opt_r))
		hud.opt_w = int(ol.get("writes", hud.opt_w))
	_update_belt(dtw, delta)
	_update_drag(delta)
	_update_views(delta)
	_update_customers(delta)
	_coin_timer -= delta
	if _coin_timer <= 0.0 and not _coin_queue.is_empty():
		_release_coins(Vector2(960, 300))
	if bot:
		_bot_step(delta)
	_idle += delta
	_update_hints()
	if spec.no_stars and not fast and model.doubles >= 2 and alarm_on and not ff_btn.visible:
		ff_btn.visible = true
		UIKit.pop_in(ff_btn)
		_hint("two_cycles")
	if spec.endless:
		hud.time_left = -1.0


func _is_blocked(pid: int) -> bool:
	for e in model.blocked:
		if (e.parcel as Parcel).id == pid:
			return true
	return false


func _update_views(delta: float) -> void:
	# opruimen: vaste-pakje-views zonder vastloper in het model
	for pid in stuck_views.keys():
		var sv: ParcelView = stuck_views[pid]
		if not is_instance_valid(sv):
			stuck_views.erase(pid)
		elif not sv.has_meta("anim") and not _is_blocked(pid) and sv != drag_view:
			stuck_views.erase(pid)
			sv.queue_free()
	# vastzittende pakjes volgen hun buis
	for e in model.blocked:
		var pid: int = (e.parcel as Parcel).id
		var v: ParcelView = stuck_views.get(pid)
		if v == null or v.has_meta("anim"):
			continue
		var via := int(e.via_index)
		if via < pipes.size():
			var tgt: Vector2 = pipes[via].point_at(STUCK_F)
			v.position = v.position.lerp(tgt, 1.0 - exp(-14.0 * delta))
	bulge_layer.queue_redraw()
	overlay.queue_redraw()
	desk_layer.queue_redraw()
	if bin_view.visible:
		bin_view.queue_redraw()
	belt.scroll += (0.0 if belt.stopped else 1.0) * delta * world_scale * (CALM_SPEED if calm else _belt_speed())
	# hover-highlights (#34)
	_update_hover(delta)
	wall.queue_redraw()


func _belt_speed() -> float:
	var bt: float = spec.belt_time if spec.belt_time > 0 else 14.0
	return (BELT_START_X - BELT_END_X) / bt


# ================================================================ band
func _on_spawned(p: Parcel) -> void:
	var pv := _make_parcel_view(p)
	pv.set_size(BELT_BOX, Pal.fit_bits(model.n, BELT_BOX.x * 0.88 - 14, 40, 24))
	parcel_layer.add_child(pv)
	var x := BELT_START_X
	pv.position = Vector2(x, -120)
	belt_views[p.id] = pv
	belt_x[p.id] = x
	belt_age[p.id] = 0.0
	pv.set_meta("anim", true)
	var by := belt.center_y()
	var tw := pv.create_tween()
	tw.tween_property(pv, "position:y", by, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func():
		Sfx.play("sfx/band_land.wav", -2.0)
		pv.scale = Vector2(1.2, 0.8))
	tw.tween_property(pv, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): pv.remove_meta("anim"))


func _belt_order() -> Array:
	var out: Array = []
	for p in director.belt():
		out.append(p.id)
	return out


func _update_belt(dtw: float, delta: float) -> void:
	var order := _belt_order()
	var moving := false
	for i in order.size():
		var pid: int = order[i]
		if not belt_views.has(pid):
			continue
		belt_age[pid] = belt_age.get(pid, 0.0) + dtw
		var x: float = belt_x[pid]
		var target: float
		if director.has_method("belt_progress"):
			target = BELT_START_X - director.belt_progress(pid) * (BELT_START_X - BELT_END_X)
			x = target
		else:
			var speed := CALM_SPEED if calm else _belt_speed()
			var min_x := BELT_END_X + i * BELT_SPACING if calm else BELT_END_X - 30.0
			if i > 0 and belt_x.has(order[i - 1]):
				min_x = maxf(min_x, belt_x[order[i - 1]] + BELT_SPACING)
			x = maxf(min_x, x - speed * dtw)
		if absf(x - belt_x[pid]) > 0.01:
			moving = true
		belt_x[pid] = x
		var pv: ParcelView = belt_views[pid]
		if pv == drag_view or pv.has_meta("anim") and pv.position.y < belt.center_y() - 1:
			# valt nog in of wordt gesleept: enkel x bijhouden
			if pv != drag_view:
				pv.position.x = x
			continue
		if pv.has_meta("anim"):
			pv.position.x = x
			continue
		pv.position = pv.position.lerp(Vector2(x, belt.center_y()), 1.0 - exp(-18.0 * delta))
		pv.rotation = lerp_angle(pv.rotation, 0.0, 1.0 - exp(-12.0 * delta))
	belt.stopped = not moving
	Sfx.loop_pitch("belt", (0.7 + 0.3 * world_scale) if moving else 0.4)
	# voorste pakje: hint-markering
	var front := _front_view()
	var fid := front.pid if front else -1
	if fid != _last_front_id:
		_last_front_id = fid
		type_buf = ""
		_update_type_highlight()


func _front_view() -> ParcelView:
	for pid in _belt_order():
		if belt_views.has(pid):
			return belt_views[pid]
	return null


func _front_parcel() -> Parcel:
	var b: Array = director.belt()
	return b[0] if not b.is_empty() else null


# ================================================================ input
func _unhandled_input(ev: InputEvent) -> void:
	if finished or paused:
		return
	if coach and coach.blocks_input():
		return
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		var pos := _world_mouse()
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_idle = 0.0
			_on_press(pos)
		elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_on_release(pos)
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		_idle = 0.0
		_on_key(ev as InputEventKey)
	elif ev is InputEventKey and not ev.pressed:
		if (ev as InputEventKey).keycode == KEY_SHIFT and loupe:
			_set_loupe(false)


var mouse_override = null   # Vector2 of null: testscripts sturen hiermee de "muis" (headless)


func _world_mouse() -> Vector2:
	if mouse_override != null:
		return mouse_override
	return get_global_mouse_position()


func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and (ev as InputEventKey).keycode == KEY_ESCAPE:
		_toggle_pause()
		get_viewport().set_input_as_handled()
	elif ev is InputEventKey and ev.pressed and not ev.echo and (ev as InputEventKey).keycode == KEY_F1:
		open_guide()
		get_viewport().set_input_as_handled()
	elif ev is InputEventMouseButton and ev.pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var cp := (ev as InputEventMouseButton).position * _screen_to_canvas()
		if hud.hit_pause(cp):
			_toggle_pause()
			get_viewport().set_input_as_handled()
		elif hud.hit_help(cp):
			open_guide()
			get_viewport().set_input_as_handled()


# ================================================================ gids (HubGuide) en tutorials
var _guide: HubGuide


## Opent de gids (Doel · Handelingen · Theorie) voor de huidige dag. F1 / "?" / pauzemenu.
func open_guide(tab := "doel") -> void:
	if finished or (_guide and is_instance_valid(_guide)):
		return
	Sfx.ui("open")
	_guide = HubGuide.open(self, HDGuide.content(spec, tab), HDGuide.style())
	_guide.closed.connect(func(): _guide = null)


func _open_tutorial(key: String) -> void:
	if finished or (_guide and is_instance_valid(_guide)):
		return
	_guide = HubGuide.open(self, HDGuide.tutorial(key), HDGuide.style(true))
	_guide.closed.connect(func():
		_guide = null
		HDGuide.mark_seen(key)
		hud.pulse_help())


func _screen_to_canvas() -> Vector2:
	var vs := get_viewport().get_visible_rect().size
	return Vector2(1920.0 / vs.x, 1080.0 / vs.y) if vs.x > 0 else Vector2.ONE


func _on_press(pos: Vector2) -> void:
	# sorteertafel
	if table.visible and not table.mid.is_empty():
		for pv in table.mid:
			if (pv as ParcelView).rect_global().grow(8).has_point(pos):
				_start_drag(pv, "table", pos)
				return
	# hendel
	if lever.hit(pos) and not _lock:
		drag_lever = true
		lever_press_y = pos.y
		lever_moved = false
		Sfx.play("sfx/pickup.wav", -6.0, 0.7)
		return
	# zaag op een rek
	for bid in racks:
		var rv: RackView = racks[bid]
		if rv.saw_visible and rv.saw_rect_global().has_point(pos):
			_try_split(bid)
			return
	# rek aanklikken (geen actie, wel een wiebel: klanten zoek je via het luik)
	for bid in racks:
		var rv2: RackView = racks[bid]
		if Rect2(rv2.position - rv2.size / 2.0, rv2.size).has_point(pos):
			rv2.wobble(1.5)
			Sfx.play("rack_place", -12.0, 1.3)
			return
	# pakje op de band
	var grab := _belt_parcel_near(pos)
	if grab:
		_start_drag(grab, "belt", pos)
		return
	# vastzittend pakje → naar de overloopbak slepen
	if spec.overflow_bin:
		for pid in stuck_views:
			var sv: ParcelView = stuck_views[pid]
			if is_instance_valid(sv) and sv.rect_global().grow(10).has_point(pos):
				_start_drag(sv, "stuck", pos)
				return
	# luik aanklikken = klant helpen (opzoeken via de pointerarray)
	var hi := _hatch_at(pos)
	if hi >= 0 and not director.customers().is_empty() and Rect2(hatches[hi].position - hatches[hi].size / 2.0, hatches[hi].size).grow(6).has_point(pos):
		_serve(hi)
		return
	# klant aanklikken = focus (toetsenbord)
	if not director.customers().is_empty() and Rect2(1560, 300, 340, 460).has_point(pos):
		_set_cust_focus(not cust_focus)


## Pakje op de band onder/nabij de cursor (QA P1-4): ruime hitbox, anders het dichtstbijzijnde binnen 80 px.
func _belt_parcel_near(pos: Vector2) -> ParcelView:
	var best: ParcelView = null
	var bd := 80.0
	for pid in _belt_order():
		var pv: ParcelView = belt_views.get(pid)
		if pv == null or pv.has_meta("anim"):
			continue
		if pv.rect_global().grow(24).has_point(pos):
			return pv
		var d := pv.rect_global().get_center().distance_to(pos) - pv.box.x * 0.5
		if d < bd:
			bd = d
			best = pv
	return best


func _start_drag(pv: ParcelView, from: String, pos: Vector2) -> void:
	drag_view = pv
	drag_from = from
	drag_offset = pv.position - pos
	drag_vel = Vector2.ZERO
	pv.set_lifted(true)
	pv.z_index = 40
	if from == "belt" and director.has_method("set_held"):
		director.set_held(pv.pid, true)
	Sfx.play("sfx/pickup.wav")
	Sfx.play("sfx/kenney/paper_slide.ogg", -14.0)
	var tw := pv.create_tween()
	tw.tween_property(pv, "scale", Vector2(1.06, 1.06), 0.08)


func _update_drag(delta: float) -> void:
	if drag_lever:
		var m := _world_mouse()
		var want := lever.pull_from_global_y(m.y)
		if absf(m.y - lever_press_y) > 6:
			lever_moved = true
		# weerstand: volgt trager naarmate dieper
		lever.pull = lerpf(lever.pull, want * 0.92, 1.0 - exp(-10.0 * delta))
		if lever.pull > 0.7:
			drag_lever = false
			_lever_commit()
		return
	if drag_view == null:
		return
	if not is_instance_valid(drag_view):
		drag_view = null
		return
	var m2 := _world_mouse() + drag_offset
	var tgt_h := _drag_target()
	if tgt_h >= 0 and tgt_h < hatches.size():
		# magnetisch: het pakje klikt op het luik onder de cursor
		m2 = m2.lerp(hatches[tgt_h].position + hatches[tgt_h].hole_rect().get_center() * 0.3, 0.6)
	var before := drag_view.position
	# zwierig volgen: lerp 0.35 per frame (60 fps)
	var k := 1.0 - pow(1.0 - 0.35, delta * 60.0)
	drag_view.position = drag_view.position.lerp(m2, k)
	drag_vel = drag_vel.lerp((drag_view.position - before) / maxf(delta, 0.001), 0.3)
	drag_view.rotation = lerp_angle(drag_view.rotation, deg_to_rad(clampf(drag_vel.x * 0.004, -3.0, 3.0)), 0.3)
	if drag_from == "table":
		table.hover_side = table.side_at(drag_view.position)


func _on_release(pos: Vector2) -> void:
	if drag_lever:
		drag_lever = false
		if not lever_moved:
			_pull_lever()
		else:
			var tw := lever.create_tween()
			tw.tween_property(lever, "pull", 0.0, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		return
	if drag_view == null:
		return
	var pv := drag_view
	drag_view = null
	pv.set_lifted(false)
	pv.z_index = 0
	pv.create_tween().tween_property(pv, "scale", Vector2.ONE, 0.1)
	if drag_from == "table":
		var side := table.side_at(pv.position)
		table.hover_side = -1
		if side >= 0:
			_do_assign(pv.pid, side)
		else:
			table.layout_mid(true)
			Sfx.play("sfx/drop_soft.wav", -4.0)
		return
	var in_bin: bool = spec.overflow_bin and BIN2.grow(20).has_point(pv.position)
	if drag_from == "stuck":
		pv.z_index = 5
		if in_bin:
			_dump_blocked(pv.pid)
		else:
			Sfx.play("sfx/drop_soft.wav", -6.0)
		return
	director.set_held(pv.pid, false)
	if in_bin and not _lock:
		_dump_belt(pv.pid)
		return
	var hi := _hatch_at(pos)
	if hi >= 0 and not _lock:
		_do_drop(pv.pid, hi, false)
	else:
		Sfx.play("drop_box", -8.0)
		pv.rotation = 0.0


## Luik onder een punt: de luikkolom wordt in gelijke banden verdeeld (geen gaten tussen luiken), met wat marge
## links/rechts. Eén functie voor highlight én drop (QA P0-2).
func _hatch_at(pos: Vector2) -> int:
	var a := model.a
	var cols := wall_cols(a)
	var rows := (1 << a) / cols
	var step := hatch_step(a)
	for c in cols:
		var x0 := WALL_RECT.position.x + c * 140.0
		var x1 := x0 + WALL_RECT.size.x
		var left := 40.0 if c == 0 else 6.0
		var right := 90.0 if c == cols - 1 else 6.0
		if pos.x < x0 - left or pos.x > x1 + right:
			continue
		var row := int(floor((pos.y - HATCH_TOP) / step))
		if row < 0 or row >= rows:
			return -1
		return c * rows + row
	return -1


## Het luik waar het gesleepte pakje nu naartoe gaat (cursorpositie). Highlight en drop gebruiken exact dit.
func _drag_target() -> int:
	if drag_view == null or drag_from != "belt":
		return -1
	return _hatch_at(_world_mouse())


func _on_key(k: InputEventKey) -> void:
	var code := k.keycode
	if table.visible and not table.mid.is_empty():
		if code == KEY_0 or code == KEY_KP_0 or code == KEY_LEFT:
			_do_assign(table.front().pid, 0)
		elif code == KEY_1 or code == KEY_KP_1 or code == KEY_RIGHT:
			_do_assign(table.front().pid, 1)
		return
	match code:
		KEY_0, KEY_KP_0:
			_type_bit("0")
		KEY_1, KEY_KP_1:
			_type_bit("1")
		KEY_BACKSPACE:
			if type_buf.length() > 0:
				type_buf = type_buf.substr(0, type_buf.length() - 1)
				Sfx.play("sfx/kenney/ui_back.ogg", -8.0)
				_update_type_highlight()
		KEY_D:
			_pull_lever()
		KEY_S:
			var bid := -1
			if not model.blocked.is_empty():
				bid = model.dir[int(model.blocked[0].via_index)]
			elif hover_rack >= 0:
				bid = hover_rack
			if bid >= 0:
				_try_split(bid)
		KEY_K:
			_key_dump()
		KEY_TAB:
			_set_cust_focus(not cust_focus)
		KEY_SHIFT:
			if spec.loupe_allowed and not loupe:
				_set_loupe(true)


func _refresh_all_hints() -> void:
	for pid in belt_views:
		belt_views[pid].apply_hint(hint_level, model.a, loupe)
	for pid in stuck_views:
		if is_instance_valid(stuck_views[pid]):
			stuck_views[pid].apply_hint(hint_level, model.a, loupe)
	for bid in racks:
		for pv in racks[bid].slots:
			if pv != null and is_instance_valid(pv):
				pv.apply_hint(hint_level, model.a, loupe)


func _set_loupe(on: bool) -> void:
	loupe = on
	if on and scoring.has_method("on_loupe_used"):
		scoring.on_loupe_used()
	_refresh_all_hints()
	Sfx.play("sfx/kenney/ui_toggle.ogg", -6.0)


func _type_bit(b: String) -> void:
	var front := _front_view()
	if cust_focus and not director.customers().is_empty():
		front = null
	elif front == null or _lock or front.has_meta("anim"):
		Sfx.play("sfx/kenney/ui_error.ogg", -12.0)
		return
	type_buf += b
	var pos := type_buf.length()
	Sfx.play("sfx/key_bit_%d.wav" % clampi(pos, 1, 6), -2.0, 1.0, false)
	_buf_pop = 1.5
	_update_type_highlight()
	if type_buf.length() >= model.a:
		var idx := HashUtil.from_bits(type_buf)
		type_buf = ""
		if front == null:
			_serve(idx)
			_set_cust_focus(false)
		else:
			_do_drop(front.pid, idx, true)
		_update_type_highlight()


var _buf_pop := 1.0


func _update_type_highlight() -> void:
	for h in hatches:
		var hv: HatchView = h
		var match_ := type_buf == "" or hv.code.begins_with(type_buf)
		var tgt := 1.0 if match_ else 0.3
		hv.create_tween().tween_property(hv, "dim", tgt, 0.1)
		var full := type_buf != "" and match_
		hv.glow = 0.0 if not full else 0.6


var _hover_held := -1


func _update_hover(delta: float) -> void:
	var m := _world_mouse()
	if not bot:
		var hp := -1
		if drag_view == null and m.y < 240:
			var near := _belt_parcel_near(m)
			if near and near.rect_global().grow(24).has_point(m):
				hp = near.pid
		if hp != _hover_held:
			if _hover_held >= 0 and (drag_view == null or drag_view.pid != _hover_held):
				director.set_held(_hover_held, false)
			if hp >= 0:
				director.set_held(hp, true)
			_hover_held = hp
	var hh := -1
	if drag_view != null and drag_from == "belt":
		hh = _hatch_at(m)
	elif drag_view == null:
		hh = _hatch_at(m)
		if hh >= 0 and not Rect2(hatches[hh].position - hatches[hh].size / 2.0, hatches[hh].size).has_point(m):
			hh = -1
	var hr := -1
	if drag_view == null and hh < 0:
		for bid in racks:
			var rv: RackView = racks[bid]
			if Rect2(rv.position - rv.size / 2.0, rv.size).has_point(m):
				hr = bid
	if hh != hover_hatch and hh >= 0 and drag_view != null:
		Sfx.play("sfx/kenney/ui_hover.ogg", -14.0, 1.2)
	hover_hatch = hh
	hover_rack = hr
	var lit_bucket := -1
	if hh >= 0 and hh < model.dir.size():
		lit_bucket = model.dir[hh]
	elif hr >= 0:
		lit_bucket = hr
	for i in hatches.size():
		var hv: HatchView = hatches[i]
		var want := 0.0
		if i == hh or (hr >= 0 and model.dir[i] == hr):
			want = 1.0
		hv.hover = move_toward(hv.hover, want, delta / 0.1)
	for i in pipes.size():
		var p: PipeView = pipes[i]
		if p.has_meta("pulse"):
			continue
		var want2 := 0.55 if (lit_bucket >= 0 and model.dir[i] == lit_bucket) else 0.0
		p.lit = move_toward(p.lit, want2, delta / 0.1)
	for bid in racks:
		var rv2: RackView = racks[bid]
		var saw_h := rv2.saw_visible and rv2.saw_rect_global().has_point(m)
		rv2.hover = move_toward(rv2.hover, 1.0 if (bid == lit_bucket or saw_h) else 0.0, delta / 0.1)
	# hendel-affordance: gloeit als verdubbelen nu de juiste zet is (tutorial-dagen) of bij idle
	var cm: Dictionary = {}
	if not model.blocked.is_empty() and model.splitting.is_empty():
		cm = model.correct_move()
	var want_lever := 0.0
	var want_saw := -1
	if coach:
		cm = {}
		match str(coach.focus.get("kind", "")):
			"lever": want_lever = 1.0
			"saw": want_saw = int(coach.focus.get("bid", -1))
	if cm.get("action", "") == "double" and (day <= 2 or _idle > 4.0):
		want_lever = 1.0
	if cm.get("action", "") == "split" and (day <= 3 or _idle > 4.0):
		want_saw = int(cm.bucket_id)
	lever.glow = move_toward(lever.glow, want_lever, delta / 0.3)
	for bid in racks:
		var rv3: RackView = racks[bid]
		rv3.hint_saw = move_toward(rv3.hint_saw, 1.0 if bid == want_saw else 0.0, delta / 0.3)


# ================================================================ acties
var _kb_tip_done := false


## Leerpad (Samen): de coach keurt elke zet eerst goed; een foute zet wordt niet uitgevoerd (uitleg + herkansing).
func _guard(kind: String, data: Dictionary) -> bool:
	return coach == null or coach.allow(kind, data)


func _do_drop(pid: int, idx: int, from_keys: bool) -> void:
	var gp: Parcel = null
	for q in director.belt():
		if q.id == pid:
			gp = q
	if gp != null and not _guard("drop", {"pid": pid, "idx": idx, "parcel": gp}):
		return
	if not from_keys and not _kb_tip_done and day >= 1 and day <= 3 and not bot:
		_kb_tip_done = true
		get_tree().create_timer(1.2).timeout.connect(func(): _say("Sneller: typ de eerste bits (0 / 1)."))
	var pv: ParcelView = belt_views.get(pid)
	if pv == null:
		return
	var parcel: Parcel = director.take(pid)
	if parcel == null:
		return
	belt_views.erase(pid)
	belt_x.erase(pid)
	belt_age.erase(pid)
	_in_player = true
	var res: Dictionary = model.drop(parcel, idx)
	_in_player = false
	_anim_drop(pv, parcel, idx, res, from_keys)


func _pull_lever() -> void:
	if _lock or finished:
		return
	if not _guard("double", {}):
		_lever_refused()
		return
	_lock = true
	Sfx.play("sfx/lever.wav")
	var tw := lever.create_tween()
	tw.tween_property(lever, "pull", 0.72, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(_lever_commit_locked)


func _lever_commit() -> void:
	if _lock:
		return
	if not _guard("double", {}):
		_lever_refused()
		return
	_lock = true
	Sfx.play("sfx/lever.wav")
	_lever_commit_locked()


func _lever_refused() -> void:
	Sfx.play("sfx/kenney/ui_error.ogg", -8.0)
	var tw := lever.create_tween()
	tw.tween_property(lever, "pull", 0.0, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _lever_commit_locked() -> void:
	# doorklikken (snap 0,06 s) + camera-punch
	var tw := lever.create_tween()
	tw.tween_property(lever, "pull", 1.0, 0.06)
	Juice.punch(0.02)
	Sfx.play("sfx/kenney/metal_heavy.ogg", -6.0)
	await tw.finished
	_in_player = true
	model.double_dir()
	_in_player = false
	_kick_queue()


func _try_split(bid: int) -> void:
	if _lock or finished or not model.splitting.is_empty():
		return
	if not _guard("split", {"bid": bid}):
		Sfx.play("sfx/kenney/ui_error.ogg", -8.0)
		var rv: RackView = racks.get(bid)
		if rv:
			rv.wobble(2.0)
		return
	_lock = true
	_in_player = true
	model.begin_split(bid)
	_in_player = false
	_kick_queue()


func _do_assign(pid: int, side: int) -> void:
	if not table_views.has(pid):
		return
	var tp: Parcel = null
	for q in model.splitting.get("pending", []):
		if (q as Parcel).id == pid:
			tp = q
	if tp != null and not _guard("assign", {"pid": pid, "side": side, "parcel": tp}):
		Sfx.play("sfx/kenney/ui_error.ogg", -8.0)
		table.layout_mid(true)
		return
	_in_player = true
	model.assign(pid, side)
	_in_player = false
	_kick_queue()


# ================================================================ animatiewachtrij
func _enqueue(c: Callable) -> void:
	_queue.append(c)
	_kick_queue()


func _kick_queue() -> void:
	if _running:
		return
	if _queue.is_empty():
		if _lock and model.splitting.is_empty() or (_lock and table.visible):
			_lock = false
		return
	_run_queue()


func _run_queue() -> void:
	_running = true
	while not _queue.is_empty():
		var c: Callable = _queue.pop_front()
		await c.call()
	_running = false
	_lock = false
	_reconcile()
	_update_alarm_state()


# ================================================================ signalen → animaties
func _on_placed(parcel: Parcel, bid: int, idx: int, verdict: int) -> void:
	if _in_player:
		return   # directe drop: _anim_drop regelt het
	var sv: ParcelView = stuck_views.get(parcel.id)
	if sv and is_instance_valid(sv):
		sv.set_meta("anim", true)   # niet opruimen: de herpoging-animatie gebruikt deze view
	_enqueue(func(): await _anim_retry_place(parcel, bid, idx, verdict))


func _on_blocked(_parcel: Parcel, _bid: int, _idx: int) -> void:
	pass   # directe drop: _anim_drop


func _on_still_blocked(parcel: Parcel, bid: int) -> void:
	_enqueue(func(): await _anim_still_blocked(parcel, bid))


func _on_doubled(old_a: int, new_a: int, verdict: int) -> void:
	var snap_dir := model.dir.duplicate()
	_enqueue(func(): await _anim_double(old_a, new_a, verdict, snap_dir))


func _on_double_refused() -> void:
	_enqueue(func(): await _anim_end_stop())


func _on_split_started(bid: int, nbid: int, bit_pos: int, changed: PackedInt32Array, to_sort: Array, verdict: int) -> void:
	var lab := model.label_of(bid)
	_split_info = {"bid": bid, "nbid": nbid, "bit_pos": bit_pos, "changed": changed, "verdict": verdict,
		"old_label": lab.substr(0, lab.length() - 1), "old_ab": model.buckets[bid].ab - 1}
	var rv: RackView = racks.get(bid)
	if rv:
		_refresh_rack(rv)
	_enqueue(func(): await _anim_split(bid, nbid, bit_pos, to_sort))


## Zagen (#19, #21): zaag + zaaglijn, daarna springen de pakjes uit het rek naar de sorteertafel.
## Bordjes, ab, het nieuwe rek en het omklappen van de buizen komen pas ná het verdelen (_anim_split_end).


func _on_split_refused(bid: int) -> void:
	_enqueue(func(): await _anim_klonk(bid))


func _on_assigned(parcel: Parcel, side: int, verdict: int) -> void:
	if _in_player and not _running:
		_anim_assign(parcel.id, side, verdict)
	else:
		_enqueue(func(): _anim_assign(parcel.id, side, verdict); await get_tree().create_timer(0.12).timeout)


func _on_split_finished(bid: int, nbid: int) -> void:
	_enqueue(func(): await _anim_split_end(bid, nbid))


func _on_lost(parcel: Parcel, reason: String) -> void:
	match reason:
		"belt":
			_anim_fell_off(parcel)
		"burst":
			_enqueue(func(): await _anim_burst(parcel))
		_:
			pass


func _on_coins(_coins: int, delta: int, _reason: String) -> void:
	if delta > 0:
		_coin_queue.append(delta)
		_coin_timer = 1.5
	elif delta < 0:
		hud.set_coins(_coins)
		if hud.show_coins and (delta <= -2 or _reason != "trip"):
			Juice.floater(hud_layer, HudView.COIN_POS + Vector2(40, 40), "%d" % delta, Pal.ERR, 26, 20, 0.8)


func _on_combo(c: int) -> void:
	hud.set_combo(c)
	if c > 1:
		Sfx.play("sfx/combo_%d.wav" % clampi(c, 1, 5), -6.0, 1.0, false)


func _on_dash() -> void:
	Sfx.play("sfx/dash.wav", -2.0, 1.0, false)
	Juice.hitstop(0.08)
	Juice.ring_wave(hud_layer, Vector2(1810, 38), Pal.COIN, 0.2, 3.0, 0.5)
	Juice.punch(0.03)
	var l := Label.new()
	l.text = "DASH!"
	l.add_theme_font_override("font", Pal.UI_BOLD)
	l.add_theme_font_size_override("font_size", 64)
	l.add_theme_color_override("font_color", Pal.COIN)
	l.add_theme_color_override("font_outline_color", Pal.OUTLINE)
	l.add_theme_constant_override("outline_size", 18)
	hud_layer.add_child(l)
	l.reset_size()
	l.pivot_offset = l.size / 2.0
	l.position = Vector2(1640, 120) - l.size / 2.0
	l.scale = Vector2(0.2, 0.2)
	l.rotation = -0.15
	var tw := l.create_tween().set_ignore_time_scale(true)
	tw.tween_property(l, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "scale", Vector2.ONE, 0.1)
	tw.tween_interval(0.4)
	tw.tween_property(l, "modulate:a", 0.0, 0.2)
	tw.tween_callback(l.queue_free)


func _on_rep(r: int) -> void:
	if r < hud.rep:
		Sfx.play("sfx/heart_break.wav")
	hud.set_rep(r)


func _release_coins(world_pos: Vector2) -> void:
	if _coin_queue.is_empty():
		return
	if not hud.show_coins:  # les: geen muntenregen
		_coin_queue.clear()
		hud.set_coins(scoring.coins, false)
		return
	var total := 0
	for d in _coin_queue:
		total += int(d)
	_coin_queue.clear()
	Juice.floater(fx_layer, world_pos + Vector2(0, -40), "+%d" % total, Pal.COIN, 34)
	Sfx.play("sfx/coin.wav", -4.0)
	Juice.coin_sparkle(fx_layer, world_pos)
	var target_coins: int = scoring.coins
	for k in 3:
		var c := Node2D.new()
		c.draw.connect(func(): Pal.coin(c, Vector2.ZERO, 12))
		c.position = world_pos + Vector2(randf_range(-20, 20), randf_range(-10, 10))
		c.z_index = 55
		hud_layer.add_child(c)
		var start := c.position
		var end := HudView.COIN_POS
		var ctrl := (start + end) / 2.0 + Vector2(randf_range(-160, 160), -220)
		var tw := c.create_tween()
		tw.tween_interval(k * 0.06)
		tw.tween_method(func(f: float):
			var q := start.lerp(ctrl, f).lerp(ctrl.lerp(end, f), f)
			c.position = q
			c.scale = Vector2.ONE * (1.0 + 0.4 * sin(f * PI)), 0.0, 1.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			if k == 2:
				hud.set_coins(target_coins)
				hud.pulse_coins()
				Sfx.play("sfx/coin.wav", -10.0, 1.3)
			c.queue_free())


# ================================================================ animaties: drop
func _anim_drop(pv: ParcelView, parcel: Parcel, idx: int, res: Dictionary, from_keys: bool) -> void:
	var hv: HatchView = hatches[idx]
	pv.set_meta("anim", true)
	pv.z_index = 35
	pv.set_lifted(false)
	var hole := hv.position + hv.hole_rect().get_center()
	if from_keys:
		# boogje van band naar luik
		var start := pv.position
		var ctrl := Vector2((start.x + hole.x) / 2.0, minf(start.y, hole.y) - 120)
		var tw0 := pv.create_tween()
		tw0.tween_method(func(f: float): pv.position = start.lerp(ctrl, f).lerp(ctrl.lerp(hole, f), f), 0.0, 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await tw0.finished
	else:
		var tw1 := pv.create_tween()
		tw1.tween_property(pv, "position", hole, 0.08)
		await tw1.finished
	if not is_instance_valid(pv):
		return
	hv.open_flap()
	Sfx.play("sfx/kenney/hatch_flap.ogg", -4.0)
	# opzuigen (#7): stretch richting buis
	var tw2 := pv.create_tween().set_parallel(true)
	tw2.tween_property(pv, "scale", Vector2(0.7, 1.3), 0.06)
	tw2.tween_property(pv, "rotation", 0.0, 0.06)
	tw2.chain().tween_property(pv, "scale", Vector2(0.08, 0.3), 0.08).set_ease(Tween.EASE_IN)
	await tw2.finished
	if not is_instance_valid(pv):
		return
	pv.visible = false
	var bid: int = res.bucket_id
	var placed: bool = int(res.status) == ExtHashModel.Drop.PLACED
	var pipe: PipeView = pipes[idx] if idx < pipes.size() else null
	Sfx.play("sfx/tube_whoosh.wav", -6.0)
	if placed:
		await _pulse(pipe, bid, 1.0)
		_land_in_rack(pv, bid)
		var rv: RackView = racks.get(bid)
		if int(res.verdict) != ExtHashModel.Verdict.OK and rv and day <= 3:
			await get_tree().create_timer(0.15).timeout
			rv.blink_lamp()
			Sfx.play("sfx/mistake.wav", -6.0)
	else:
		# vastloper: pakje schuift tot vlak voor het rek en blijft steken (#12)
		await _pulse(pipe, bid, STUCK_F)
		if not is_instance_valid(pv):
			return
		if not _is_blocked(parcel.id):
			# intussen al herplaatst (of kwijt): het model is leidend
			pv.queue_free()
			_reconcile()
			return
		pv.visible = true
		pv.set_size(STUCK_BOX, 18)
		pv.scale = Vector2(1.3, 0.7)
		pv.position = pipe.point_at(STUCK_F) if pipe else pv.position
		pv.z_index = 5
		stuck_views[parcel.id] = pv
		pv.remove_meta("anim")
		pv.create_tween().tween_property(pv, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		Sfx.play("sfx/rack_full.wav", -2.0)
		_idle = 0.0
		Juice.shake(3.0, 0.2)
		_hint("first_block")
		var rv2: RackView = racks.get(bid)
		if rv2:
			rv2.wobble(3.0)
			_refresh_rack(rv2)
		_update_alarm_state()


## Lichtpuls langs de buis (#8). `to_f` = tot waar (1 = rek). Licht ook de verzamelbuis op.
func _pulse(pipe: PipeView, bid: int, to_f: float, dur := 0.35) -> void:
	if pipe == null:
		await get_tree().create_timer(dur).timeout
		return
	var glow := Sprite2D.new()
	glow.texture = Juice.tex("glow")
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = m
	glow.modulate = pipe.col.lightened(0.5)
	glow.scale = Vector2(0.55, 0.55)
	glow.z_index = 8
	fx_layer.add_child(glow)
	var core := Sprite2D.new()
	core.texture = Juice.tex("soft_circle")
	core.material = m
	core.modulate = Color(1, 1, 1, 0.9)
	core.scale = Vector2(0.35, 0.35)
	glow.add_child(core)
	for i in pipes.size():
		if model.dir[i] == bid:
			var p: PipeView = pipes[i]
			p.set_meta("pulse", true)
			var twl := p.create_tween()
			twl.tween_property(p, "lit", 1.0, 0.08)
			twl.tween_interval(dur * 0.6)
			twl.tween_property(p, "lit", 0.0, 0.3)
			twl.tween_callback(func(): if is_instance_valid(p): p.remove_meta("pulse"))
	var tw := glow.create_tween()
	tw.tween_method(func(f: float):
		if is_instance_valid(pipe):
			glow.position = pipe.point_at(f), 0.0, to_f, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(glow, "modulate:a", 0.0, 0.12)
	tw.tween_callback(glow.queue_free)
	await get_tree().create_timer(dur).timeout


## Pakje schuift in een vrij vak (#9) + munten (#10).
func _land_in_rack(pv: ParcelView, bid: int) -> void:
	var rv: RackView = racks.get(bid)
	if rv == null or not is_instance_valid(pv):
		return
	var s := rv.free_slot()
	if s < 0:
		pv.queue_free()
		return
	pv.reparent(rv, false)
	rv.slots[s] = pv
	pv.visible = true
	_fit_parcel_to_rack(pv, rv)
	var tgt := rv.slot_center(s)
	pv.position = Vector2(rv.rect().position.x + 20, tgt.y)
	pv.scale = Vector2(0.6, 0.6)
	pv.rotation = 0.0
	pv.z_index = 0
	var tw := pv.create_tween().set_parallel(true)
	tw.tween_property(pv, "position", tgt, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(pv, "scale", Vector2(1.15, 0.85), 0.1)
	tw.chain().tween_property(pv, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(func(): if is_instance_valid(pv): pv.remove_meta("anim"))
	rv.wobble(2.0)
	Sfx.play("rack_place", -2.0)
	Juice.dust(fx_layer, rv.to_global(tgt) + Vector2(0, 30), 6)
	_release_coins(rv.to_global(tgt))
	_refresh_rack(rv)


# ================================================================ animaties: herpoging / ketting
func _anim_retry_place(parcel: Parcel, bid: int, idx: int, verdict: int) -> void:
	var pv: ParcelView = stuck_views.get(parcel.id)
	stuck_views.erase(parcel.id)
	if pv == null or not is_instance_valid(pv):
		pv = _make_parcel_view(parcel)
		parcel_layer.add_child(pv)
		pv.position = hatches[idx].position if idx < hatches.size() else Vector2(700, 600)
	pv.set_meta("anim", true)
	# "schiet los" (#24): pop + luchtstoot
	var tw := pv.create_tween()
	tw.tween_property(pv, "scale", Vector2(1.4, 1.4), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(pv, "scale", Vector2(0.3, 0.3), 0.08)
	Juice.burst(fx_layer, pv.position, "puff", 8, 0.35, 80, 160, Color(1, 1, 1, 0.5), 0, 0.2, 0.4)
	Sfx.play("sfx/tube_whoosh.wav", -4.0, 1.2)
	await tw.finished
	if is_instance_valid(pv):
		pv.visible = false
	var pipe: PipeView = pipes[idx] if idx < pipes.size() else null
	if pipe:
		# reis vanaf de vastloopplek naar het rek
		await _pulse(pipe, bid, 1.0, 0.2)
	_land_in_rack(pv, bid)
	var rv: RackView = racks.get(bid)
	if verdict != ExtHashModel.Verdict.OK and rv and day <= 3:
		rv.blink_lamp()
	_update_alarm_state()
	await get_tree().create_timer(0.1).timeout


func _anim_still_blocked(_parcel: Parcel, bid: int) -> void:
	# kettingreactie (#25): alarm hoger, vignet erbij
	chain_level += 1
	_idle = 0.0
	_hint("still_blocked")
	Sfx.play("sfx/rack_full.wav", 0.0, 1.0 + 0.1 * chain_level, false)
	Juice.shake(4.0, 0.25)
	var rv: RackView = racks.get(bid)
	if rv:
		rv.wobble(3.0)
		_refresh_rack(rv)
	_update_alarm_state()
	await get_tree().create_timer(0.2).timeout


# ================================================================ animaties: verdubbelen (#15–17)
func _anim_double(old_a: int, new_a: int, _verdict: int, new_dir: PackedInt32Array) -> void:
	var p := Sfx.play("sfx/wall_expand.wav", -2.0, 1.0, false)
	if p:
		p.play(1.45)
	hud.zero_trips()
	lever.a = new_a
	# anticipatie: muur deinst 24 px naar links en terug
	var tw0 := create_tween()
	tw0.tween_method(func(v: float): wall_shift = v; wall.queue_redraw(), 0.0, -24.0, 0.08).set_ease(Tween.EASE_OUT)
	tw0.tween_method(func(v: float): wall_shift = v; wall.queue_redraw(), -24.0, 0.0, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Juice.shake(3.0, 0.25)
	Juice.burst(fx_layer, Vector2(WALL_RECT.get_center().x, WALL_RECT.end.y - 10), "k_smoke_04", 10, 0.8, 40, 120, Color(Pal.PANEL_HI, 0.5), -20, 0.4, 0.9, false, Vector2.UP, 80)
	await tw0.finished
	if wall_cols(new_a) != wall_cols(old_a):
		# de muur verbreedt letterlijk
		create_tween().tween_property(self, "_wall_w", wall_rect_for(new_a).size.x, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Juice.shake(5.0, 0.3)
	var old_hatches := hatches.duplicate()
	var old_pipes := pipes.duplicate()
	var tg := rack_targets()
	hatches = []
	pipes = []
	hatches.resize(1 << new_a)
	pipes.resize(1 << new_a)
	var w := pipe_width(new_a)
	for i in old_hatches.size():
		var oh: HatchView = old_hatches[i]
		var op: PipeView = old_pipes[i]
		for b in 2:
			var j := i * 2 + b
			var nh := HatchView.new()
			var r := hatch_rect(j, new_a)
			nh.idx = j
			nh.code = HashUtil.bits(j, new_a)
			nh.size = oh.size
			nh.position = oh.position
			nh.col = rack_color(new_dir[j])
			nh.label_alpha = 0.0
			nh.new_bit_pop = 1.7
			hatch_layer.add_child(nh)
			hatches[j] = nh
			var delay := i * 0.03
			var tw := nh.create_tween().set_parallel(true)
			tw.tween_property(nh, "position", r.get_center(), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
			tw.tween_property(nh, "size", r.size, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
			tw.tween_property(nh, "label_alpha", 1.0, 0.15).set_delay(delay + 0.12)
			tw.tween_property(nh, "new_bit_pop", 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay + 0.2)
			# buis: Y-stuk (beide kinderen delen de buis van de ouder)
			var np := PipeView.new()
			np.idx = j
			np.col = op.col
			np.width = op.width
			np.p_start = op.p_start
			np.p_end = op.p_end
			np.mid_x = op.mid_x
			add_child(np)
			np.attach(pipe_layers[0], pipe_layers[1], pipe_layers[2], pipe_layers[3])
			pipes[j] = np
			var twp := np.create_tween().set_parallel(true)
			twp.tween_property(np, "p_start", Vector2(pipe_start_x(new_a), r.get_center().y), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
			twp.tween_property(np, "width", w, 0.3).set_delay(delay)
			twp.tween_property(np, "p_end", pipe_end_for(new_dir[j], tg), 0.35).set_delay(delay)
			twp.tween_property(np, "mid_x", pipe_mid_for(new_dir[j], tg), 0.35).set_delay(delay)
			if b == 1:
				get_tree().create_timer(delay + 0.25).timeout.connect(func():
					Sfx.play("sfx/pipe_click.wav", -8.0, 1.0 + 0.02 * i)
					Juice.burst(fx_layer, r.get_center() + Vector2(30, 0), "sparkle", 3, 0.3, 40, 90, Pal.COIN, 0, 0.15, 0.3, true))
		oh.queue_free()
		op.queue_free()
	var total := 0.35 + old_hatches.size() * 0.03
	var twl := lever.create_tween()
	twl.tween_interval(0.1)
	twl.tween_property(lever, "pull", 0.0, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(total).timeout
	for bid in racks:
		var rv: RackView = racks[bid]
		var had_saw := rv.saw_visible
		_refresh_rack(rv)
		if rv.saw_visible and not had_saw:
			Juice.burst(fx_layer, rv.to_global(rv.saw_center()), "sparkle", 5, 0.35, 60, 120, Pal.TEXT, 0, 0.2, 0.35, true)
	_refresh_all_hints()
	type_buf = ""
	_update_type_highlight()
	_relayout(0.3)
	_hint("first_double")
	await get_tree().create_timer(0.2).timeout


func _anim_end_stop() -> void:
	# eindaanslag (#18): hendel stuit, dreun, shake 6 px, plaat knippert rood 3×
	Sfx.play("sfx/end_stop.wav", 0.0, 1.0, false)
	_hint("double_refused")
	Juice.shake(6.0, 0.25)
	var tw := create_tween()
	for k in 3:
		tw.tween_callback(func(): _wall_flash = 1.0; lever.jam = 1.0)
		tw.tween_interval(0.12)
		tw.tween_callback(func(): _wall_flash = 0.0; lever.jam = 0.0)
		tw.tween_interval(0.1)
	var twl := lever.create_tween()
	twl.tween_property(lever, "pull", 0.0, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tw.finished


# ================================================================ animaties: zagen (#14, #19–21)
func _anim_klonk(bid: int) -> void:
	var rv: RackView = racks.get(bid)
	if rv == null:
		return
	var tw := rv.create_tween()
	tw.tween_property(rv, "saw_drop", 1.0, 0.12).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		Sfx.play("sfx/saw_clonk.wav")
		Juice.sparks(fx_layer, rv.to_global(rv.saw_center() + Vector2(0, 30)), 8)
		Juice.shake(2.0, 0.1))
	tw.tween_property(rv, "saw_drop", 0.0, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tw.finished


func _anim_split(bid: int, nbid: int, bit_pos: int, to_sort: Array) -> void:
	var rv: RackView = racks.get(bid)
	if rv == null:
		return
	wrong_sides.clear()
	Sfx.play("sfx/saw.wav")
	rv.saw_visible = true
	var tw := rv.create_tween().set_parallel(true)
	tw.tween_property(rv, "saw_rot", rv.saw_rot + TAU * 1.5, 0.45)
	tw.tween_property(rv, "cut", 1.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT).set_delay(0.1)
	await get_tree().create_timer(0.2).timeout
	for k in 3:
		Juice.sparks(fx_layer, rv.to_global(Vector2(lerpf(-rv.size.x / 2.0, rv.size.x / 2.0, 0.2 + 0.3 * k), rv.shelf_rect().get_center().y)), 6)
	Juice.shake(3.0, 0.15)
	await tw.finished
	rv.cut = 0.0
	rv.saw_visible = false
	if to_sort.is_empty():
		return
	_open_table(bid, nbid, bit_pos)
	await get_tree().create_timer(0.12).timeout
	var views: Array = []
	for p2 in to_sort:
		var pv: ParcelView = null
		for s in rv.slots.size():
			var q = rv.slots[s]
			if q != null and is_instance_valid(q) and q.pid == (p2 as Parcel).id:
				pv = q
				rv.slots[s] = null
		if pv == null:
			pv = _make_parcel_view(p2)
			rv.add_child(pv)
		var gp := pv.global_position
		pv.reparent(parcel_layer, false)
		pv.global_position = gp
		pv.visible = true
		pv.set_meta("anim", true)
		table_views[pv.pid] = pv
		views.append(pv)
	table.mid = views
	rv.wobble(3.0)
	for i in views.size():
		var pv2: ParcelView = views[i]
		var start := pv2.position
		var big := i == 0
		pv2.set_size(Vector2(176, 104) if big else Vector2(110, 62), Pal.fit_bits(model.n, 140, 40, 24) if big else 20)
		var end := table.position + table.mid_target(i)
		var ctrl := (start + end) / 2.0 + Vector2(0, -160)
		var twj := pv2.create_tween()
		twj.tween_interval(i * 0.06)
		twj.tween_callback(func(): Sfx.play("sfx/pickup.wav", -6.0, 1.0 + 0.08 * i))
		twj.tween_method(func(f: float): pv2.position = start.lerp(ctrl, f).lerp(ctrl.lerp(end, f), f), 0.0, 1.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		twj.tween_callback(func(): pv2.remove_meta("anim"))
	await get_tree().create_timer(0.3 + views.size() * 0.06).timeout
	table.layout_mid(true)


func _open_table(bid: int, nbid: int, bit_pos: int) -> void:
	var rv: RackView = racks[bid]
	var ry: float = rv.position.y
	var top := clampf(ry - SortTable.SIZE.y / 2.0, 236.0, 1044.0 - SortTable.SIZE.y)
	table.position = Vector2(RACK_X + RACK_W + 14, top)
	table.link_y = ry - top
	table.old_label = model.label_of(bid)
	table.new_label = model.label_of(nbid)
	table.old_col = rack_color(bid)
	table.new_col = rack_color(nbid)
	table.bit_pos = bit_pos
	table.hint = hint_level
	table.cap = model.g
	table.pulse_bit = hint_level <= 1 or day <= 4
	table.left = []
	table.right = []
	table.mid = []
	table.visible = true
	table.open_k = 1.0
	table.scale = Vector2(0.0, 0.85)
	table.modulate.a = 0.0
	Sfx.play("sfx/ui_whoosh.wav", -4.0)
	_hint("first_sort")
	var tw := table.create_tween().set_parallel(true)
	tw.tween_property(table, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(table, "modulate:a", 1.0, 0.1)


func _anim_assign(pid: int, side: int, verdict: int) -> void:
	var pv: ParcelView = table_views.get(pid)
	if pv == null:
		return
	table.mid.erase(pv)
	var arr: Array = table.left if side == 0 else table.right
	arr.append(pv)
	pv.set_pulse(0)
	pv.set_lifted(false)
	var tgt := table.position + table.bin_target(side, arr.size() - 1)
	var b := table.small_box()
	Sfx.play("sfx/sort_%d.wav" % side, -2.0)
	# snelle zwiep met spoor (#22)
	var trail := Line2D.new()
	trail.width = 30
	trail.default_color = Color(table.old_col if side == 0 else table.new_col, 0.35)
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	fx_layer.add_child(trail)
	var start := pv.position
	var tw := pv.create_tween()
	tw.tween_method(func(f: float):
		if not is_instance_valid(pv):
			return
		pv.position = start.lerp(tgt, f)
		trail.add_point(pv.position)
		if trail.get_point_count() > 6:
			trail.remove_point(0), 0.0, 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		pv.set_size(b, Pal.fit_bits(model.n, b.x * 0.88 - 12, 24, 18))
		pv.scale = Vector2(1.25, 0.75))
	tw.tween_property(pv, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var tt := trail.create_tween()
	tt.tween_property(trail, "modulate:a", 0.0, 0.3)
	tt.tween_callback(trail.queue_free)
	if verdict != ExtHashModel.Verdict.OK and _split_info.has("bid"):
		wrong_sides.append(int(_split_info.bid) if side == 0 else int(_split_info.nbid))
	table.layout_mid(true)


## Na het verdelen (#20, #23): nieuw rek schuift onder het oude uit, bordjes krijgen een bit (ab + 1), de onderste
## helft van de buisbundel klapt om naar het nieuwe rek, de pakjes van de tafel landen in hun rek.


func _anim_split_end(bid: int, nbid: int) -> void:
	await get_tree().create_timer(0.2).timeout
	var info := _split_info
	var changed: PackedInt32Array = info.get("changed", PackedInt32Array())
	_split_info = {}
	var rv: RackView = racks.get(bid)
	if rv == null:
		return
	var tg := rack_targets()
	# nieuw rek komt onder het oude vandaan
	var nrv := _make_rack(nbid, {"pos": rv.position, "size": rv.size})
	nrv.modulate.a = 0.0
	rack_layer.move_child(nrv, rv.get_index())
	_refresh_rack(rv)
	_refresh_rack(nrv)
	Sfx.play("sfx/split.wav", -2.0)
	var twn := nrv.create_tween().set_parallel(true)
	twn.tween_property(nrv, "modulate:a", 1.0, 0.12)
	twn.tween_property(nrv, "position", rv.position + Vector2(0, 72), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for r in [rv, nrv]:
		r.plate_pop = 1.4
		r.create_tween().tween_property(r, "plate_pop", 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.18).timeout
	# alle rekken naar hun plek
	for b2 in racks:
		var r2: RackView = racks[b2]
		if not tg.has(b2):
			continue
		var tw2 := r2.create_tween().set_parallel(true)
		tw2.tween_property(r2, "position", tg[b2].pos, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		if r2.size != tg[b2].size:
			tw2.tween_property(r2, "size", tg[b2].size, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			_reslot_later(r2, 0.4)
	# pointers omzetten: onderste helft van de bundel zwaait naar het nieuwe rek
	var ncol := rack_color(nbid)
	for i in pipes.size():
		var p: PipeView = pipes[i]
		var b3 := model.dir[i]
		if not tg.has(b3):
			continue
		var twp := p.create_tween().set_parallel(true)
		if changed.has(i):
			var k := changed.find(i)
			var d := 0.05 + k * 0.04
			twp.tween_property(p, "p_end", pipe_end_for(b3, tg), 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT).set_delay(d)
			twp.tween_property(p, "mid_x", pipe_mid_for(b3, tg), 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT).set_delay(d)
			twp.tween_property(p, "col", ncol, 0.15).set_delay(d)
			var hv: HatchView = hatches[i]
			get_tree().create_timer(d + 0.3).timeout.connect(func():
				Sfx.play("sfx/pipe_click.wav", -4.0, 1.0 + 0.05 * k)
				hv.col = ncol
				p.lit = 1.0
				p.create_tween().tween_property(p, "lit", 0.0, 0.3))
		else:
			twp.tween_property(p, "p_end", pipe_end_for(b3, tg), 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			twp.tween_property(p, "mid_x", pipe_mid_for(b3, tg), 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(0.45 + changed.size() * 0.04).timeout
	# pakjes van de tafel naar hun rek
	var groups := [[table.left, rv], [table.right, nrv]]
	var k2 := 0
	for gr in groups:
		var arr: Array = gr[0]
		var r: RackView = gr[1]
		for pv in arr:
			if not is_instance_valid(pv):
				continue
			var s := r.free_slot()
			if s < 0:
				pv.queue_free()
				continue
			r.slots[s] = pv
			var gp: Vector2 = pv.global_position
			pv.reparent(r, false)
			pv.global_position = gp
			_fit_parcel_to_rack(pv, r)
			var tw: Tween = pv.create_tween()
			tw.tween_interval(k2 * 0.06)
			tw.tween_property(pv, "position", r.slot_center(s), 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tw.tween_callback(func(): Sfx.play("rack_place", -6.0))
			table_views.erase(pv.pid)
			k2 += 1
	table.left = []
	table.right = []
	table.mid = []
	table_views.clear()
	var tw3 := table.create_tween().set_parallel(true)
	tw3.tween_property(table, "scale", Vector2(0.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw3.tween_property(table, "modulate:a", 0.0, 0.15)
	await get_tree().create_timer(0.34 + k2 * 0.06).timeout
	table.visible = false
	# rekken klappen dicht, heftruck schrijft beide rekken weg
	for r2 in [rv, nrv]:
		r2.plate_pop = 0.8
		r2.create_tween().tween_property(r2, "plate_pop", 1.0, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		r2.wobble(2.0)
		_refresh_rack(r2)
	Sfx.play("sfx/warehouse_trip.wav", -8.0)
	_drive_truck([rv, nrv])
	for wb in wrong_sides:
		var wr: RackView = racks.get(wb)
		if wr and day <= 4:
			wr.blink_lamp()
			Sfx.play("sfx/mistake.wav", -6.0)
	wrong_sides.clear()
	# leeg rek galmt (#25): doorbuigen, rode teller, holle echo, stof
	for r3 in [rv, nrv]:
		if model.buckets[r3.bucket_id].parcels.is_empty():
			Sfx.play("sfx/hollow_echo.wav", -2.0)
			r3.echo = 1.0
			r3.empty_flash = 1.0
			var te: Tween = r3.create_tween()
			te.tween_property(r3, "position:y", r3.position.y + 8, 0.12).set_ease(Tween.EASE_OUT)
			te.tween_property(r3, "position:y", r3.position.y, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			te.tween_interval(1.0)
			te.tween_property(r3, "echo", 0.0, 0.8)
			te.parallel().tween_property(r3, "empty_flash", 0.0, 0.8)
			Juice.burst(fx_layer, r3.global_position + Vector2(0, -r3.size.y / 2.0), "puff", 10, 1.2, 10, 40, Color(Pal.TEXT_DIM, 0.45), 40, 0.25, 0.5, false, Vector2.DOWN, 60)
	await get_tree().create_timer(0.3).timeout


func _drive_truck(rs: Array) -> void:
	var tr := Node2D.new()
	tr.draw.connect(func(): Pal.truck(tr, Vector2.ZERO, 2.2))
	tr.z_index = 30
	fx_layer.add_child(tr)
	tr.position = Vector2(1560, 1060)
	var tw := tr.create_tween()
	for r in rs:
		if r == null:
			continue
		tw.tween_property(tr, "position", Vector2(RACK_X + RACK_W + 40, (r as RackView).position.y + 20), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.tween_callback(func(): Sfx.play("sfx/kenney/ui_click.ogg", -8.0, 1.4))
	tw.tween_property(tr, "position", Vector2(1960, 1060), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(tr.queue_free)


# ================================================================ animaties: verlies
func _anim_fell_off(parcel: Parcel) -> void:
	var pv: ParcelView = belt_views.get(parcel.id)
	belt_views.erase(parcel.id)
	belt_x.erase(parcel.id)
	if pv == null:
		return
	if pv == drag_view:
		drag_view = null
	pv.set_meta("anim", true)
	pv.set_lifted(false)
	var bin_c := BeltView.BIN_RECT.get_center()
	var tw := pv.create_tween()
	tw.tween_property(pv, "rotation", -0.6, 0.15).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(pv, "position", Vector2(140, belt.center_y() + 10), 0.15)
	tw.tween_property(pv, "position", bin_c, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(pv, "scale", Vector2(0.4, 0.4), 0.2)
	tw.tween_callback(func():
		Sfx.play("sfx/package_lost.wav", -2.0)
		Sfx.play("drop_box", -2.0)
		Juice.shake(4.0, 0.2)
		belt.bin_count += 1
		var tb := belt.create_tween()
		tb.tween_property(belt, "bin_wobble", 0.12, 0.06)
		tb.tween_property(belt, "bin_wobble", -0.08, 0.08)
		tb.tween_property(belt, "bin_wobble", 0.0, 0.2).set_trans(Tween.TRANS_BACK)
		pv.queue_free())


func _anim_burst(parcel: Parcel) -> void:
	var pv: ParcelView = stuck_views.get(parcel.id)
	stuck_views.erase(parcel.id)
	var pos := pv.position if pv else Vector2(800, 600)
	Sfx.play("sfx/burst.wav", 0.0, 1.0, false)
	Sfx.play("sfx/package_lost.wav", -4.0)
	Juice.cardboard(fx_layer, pos, 20)
	Juice.shake(10.0, 0.3)
	Juice.flash_glow(fx_layer, pos, Pal.ERR, 1.6, 0.3)
	if pv:
		pv.set_meta("anim", true)
		pv.z_index = 45
		var tw := pv.create_tween().set_parallel(true)
		tw.tween_property(pv, "position", pos + Vector2(randf_range(-80, 80), 700), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(pv, "rotation", randf_range(-6, 6), 0.9)
		tw.chain().tween_callback(pv.queue_free)
	_update_alarm_state()
	await get_tree().create_timer(0.3).timeout


# ================================================================ alarm / slow-mo (#12, #13)
func _update_alarm_state() -> void:
	var on := not model.blocked.is_empty()
	for bid in racks:
		_refresh_rack(racks[bid])
	if on == alarm_on:
		return
	alarm_on = on
	if on:
		Sfx.play("sfx/tape_stop.wav", -6.0, 1.0, false)
		Sfx.loop("alarm", "sfx/alarm_loop.wav", true, -10.0)
		Sfx.set_layer("tension", true)
		Sfx.set_slowmo(true)
	else:
		chain_level = 0
		Sfx.play("sfx/tape_start.wav", -6.0, 1.0, false)
		Sfx.loop("alarm", "", false)
		Sfx.set_layer("tension", false)
		Sfx.set_slowmo(false)


func _update_alarm(delta: float) -> void:
	var target := 0.15 + 0.1 * mini(chain_level, 2) if alarm_on else 0.0
	alarm_level = move_toward(alarm_level, target, delta / 0.3 * 0.2)
	vig_mat.set_shader_parameter("amount", alarm_level * (0.85 + 0.15 * sin(_t * 8.0)))
	if alarm_on:
		Sfx.loop_pitch("alarm", 1.0 + 0.12 * chain_level)
	for bid in racks:
		var rv: RackView = racks[bid]
		var stuck := 0.0
		for e in model.blocked:
			if _vis_bucket(int(e.via_index)) == bid:
				stuck = 1.0
		rv.stuck = move_toward(rv.stuck, stuck, delta / 0.3)
	# drukte-laag: band > 50 % vol
	var busy: bool = director.belt().size() >= 4
	Sfx.set_layer("busy", busy, -3.0 if calm else 0.0)


func _draw_bulges() -> void:
	for e in model.blocked:
		var pid: int = (e.parcel as Parcel).id
		var v: ParcelView = stuck_views.get(pid)
		if v == null or not is_instance_valid(v) or not v.visible:
			continue
		var via := int(e.via_index)
		if via >= pipes.size():
			continue
		var p: PipeView = pipes[via]
		var sw := 1.0 + 0.15 * sin(_t * TAU * 4.0)
		var left := -1.0
		if director.has_method("burst_left"):
			left = director.burst_left(pid)
		if left >= 0.0 and spec.burst_time > 0:
			sw += 0.25 * (1.0 - clampf(left / spec.burst_time, 0.0, 1.0))
		var r := Rect2(v.position - Vector2(64, 31) * sw, Vector2(128, 62) * sw)
		bulge_layer.draw_style_box(Pal.sb(Pal.OUTLINE, 30), r.grow(5))
		bulge_layer.draw_style_box(Pal.sb(p.col.darkened(0.12), 30), r)
		bulge_layer.draw_style_box(Pal.sb(Color(p.col.lightened(0.45), 0.6), 10), Rect2(r.position + Vector2(18, 6), Vector2(r.size.x - 36, 6)))


# ================================================================ overlay: typbuffer, ghost-luik
func _draw_overlay() -> void:
	_draw_chef()
	var front := _front_view()
	var c: Vector2
	if cust_focus:
		c = Vector2(1732, 300)
	else:
		if front == null or front.has_meta("anim") or front == drag_view:
			return
		c = Vector2(front.position.x, 246)
	if table.visible:
		return
	var a := model.a
	var s := ""
	for i in a:
		s += type_buf[i] if i < type_buf.length() else "_"
	var ghost := ""
	if hint_level == 0 and type_buf == "" and not cust_focus and front:
		ghost = "→ " + HashUtil.bits(model.index_of(front.hv), a)
	var txt := s if (type_buf != "" or cust_focus) else ghost
	if txt == "":
		return
	if type_buf != "" or cust_focus:
		txt = " ".join(s.split(""))
	var w := Pal.MONO.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + 32
	var r := Rect2(c - Vector2(w / 2.0, 20), Vector2(w, 40))
	_buf_pop = move_toward(_buf_pop, 1.0, 0.08)
	if _buf_pop > 1.0:
		r = Rect2(r.get_center() - r.size * _buf_pop / 2.0, r.size * _buf_pop)
	overlay.draw_style_box(Pal.sb(Color(Pal.BG_DEEP, 0.92), 20), r)
	if type_buf != "" or cust_focus:
		Pal.ring(overlay, r, 20, Color(Pal.INFO, 0.8), 3)
		Pal.text_c(overlay, Pal.MONO, r.get_center(), " ".join(s.split("")), int(26 * _buf_pop), Pal.TEXT)
	else:
		Pal.text_c(overlay, Pal.MONO, r.get_center(), ghost, 24, Color(Pal.TEXT_DIM, 0.8 + 0.2 * sin(_t * 3.0)))


# ================================================================ dagkaart / einde
func _show_day_card() -> void:
	var card := Node2D.new()
	card.z_index = 70
	hud_layer.add_child(card)
	var title := ("DAG %d" % day) if day > 0 else "PIEKDAG"
	if coach:
		title = coach.phase.to_upper()
	var sub: String = spec.title
	var intro: String = spec.intro
	card.draw.connect(func():
		var r := Rect2(-480, -110, 960, 220)
		card.draw_style_box(Pal.sb(Pal.PANEL, 28, 24, Vector2(0, 12)), r)
		Pal.head(card, Rect2(r.position, Vector2(r.size.x, 14)), Pal.WARN, 28)
		Pal.text_c(card, Pal.UI_BOLD, Vector2(0, -40), title, 72, Pal.TEXT)
		Pal.text_c(card, Pal.UI, Vector2(0, 26), sub, 34, Pal.WARN)
		if intro != "":
			Pal.text_c(card, Pal.UI_MED, Vector2(0, 74), intro, 24, Pal.TEXT_DIM))
	card.position = Vector2(960, -200)
	_card_end = _t + (2.5 if not bot else 1.4)
	var tw := card.create_tween()
	tw.tween_property(card, "position", Vector2(960, 480), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.6 if not bot else 0.6)
	tw.tween_property(card, "position", Vector2(960, 1300), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(card.queue_free)


func _on_day_finished(report: Dictionary) -> void:
	if _ending or finished:
		return
	if coach:
		_ending = true
		while _running or not _queue.is_empty():
			await get_tree().process_frame
		await get_tree().create_timer(0.5).timeout
		coach.on_finished(report)
		return
	_ending = true
	_report = report
	while _running or not _queue.is_empty():
		await get_tree().process_frame
	await get_tree().create_timer(0.6, true, false, true).timeout
	Engine.time_scale = 1.0
	if bool(report.get("has_next_phase", false)):
		var line := ""
		for e in model.log.entries:
			if e.type == "DOUBLE_REFUSED" or (e.type == "LOST" and bool(e.data.get("excused", false))):
				line = model.log.coach_line(e).replace("`", "")
		if line != "":
			_say(line)
		await _lights_out()
		_stamp("OCHTEND VOORBIJ", Pal.WARN)
		Sfx.play("sfx/day_failed.wav" if bool(report.get("failed", false)) else "sfx/day_complete.wav", -4.0, 1.0, false)
		await get_tree().create_timer(2.2).timeout
		fast = false
		bot = Game.cmd.has("bot")
		director.next_phase()
		_begin_phase(false)
		return
	finished = true
	Sfx.loop("belt", "", false)
	Sfx.loop("alarm", "", false)
	Sfx.set_slowmo(false)
	Sfx.stop_layers(1.0)
	Game.last_report = report
	Game.last_log = model.log.entries.duplicate()
	Game.last_model_snapshot = report.get("end_snapshot", model.snapshot())
	Game.last_spec = spec if not spec.endless else spec
	Game.last_title = parent_spec.title
	Game.last_time = real_s
	var stars := int(report.get("star_count", 0))
	if day > 0:
		Game.record_stars(day, stars)
	var ok: bool = not bool(report.get("failed", false)) and scoring.rep > 0
	Sfx.play("sfx/day_complete.wav" if ok else "sfx/day_failed.wav", -2.0, 1.0, false)
	if spec.endless:
		_stamp("DEPOT GESLOTEN", Pal.ERR)
	else:
		_stamp("DEPOT DICHT" if ok else "DEPOT GESLOTEN", Pal.OK if ok else Pal.ERR)
	await get_tree().create_timer(1.6).timeout
	if Game.cmd.has("quit-after-day"):
		print("DAY_DONE ", report.get("stars", []), " reads=", model.reads, " writes=", model.writes, " coins=", report.get("coins", 0), " mistakes=", report.get("mistakes", []).size())
		get_tree().quit()
		return
	Transition.goto(Game.SCENE_REPORT)


## Dag 7 ochtend: het licht valt uit (de methode faalt), dan flikkert het terug.
func _lights_out() -> void:
	var dark := ColorRect.new()
	dark.color = Color(0, 0, 0, 0)
	dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cl := CanvasLayer.new()
	cl.layer = 6
	add_child(cl)
	cl.add_child(dark)
	Sfx.play("sfx/kenney/metal_heavy.ogg", -2.0, 0.6)
	Sfx.loop("belt", "", false)
	var tw := dark.create_tween()
	tw.tween_property(dark, "color:a", 0.78, 0.12)
	tw.tween_interval(1.6)
	for k in 2:
		tw.tween_property(dark, "color:a", 0.3, 0.05)
		tw.tween_property(dark, "color:a", 0.7, 0.08)
	tw.tween_property(dark, "color:a", 0.0, 0.4)
	tw.tween_callback(cl.queue_free)
	await tw.finished


# ================================================================ klanten (dag 4+)


func _stamp(text: String, col: Color) -> void:
	var st := Node2D.new()
	st.z_index = 80
	hud_layer.add_child(st)
	st.draw.connect(func():
		var w := Pal.UI_BOLD.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 96).x + 80
		var r := Rect2(-w / 2.0, -80, w, 160)
		var sb := Pal.sbn(Color(Pal.BG_DEEP, 0.9), 24)
		sb.border_color = col
		sb.set_border_width_all(8)
		st.draw_style_box(sb, r)
		Pal.text_c(st, Pal.UI_BOLD, Vector2.ZERO, text, 96, col))
	st.position = Vector2(960, 520)
	st.rotation = -0.08
	st.scale = Vector2(3, 3)
	st.modulate.a = 0.0
	var tw := st.create_tween().set_parallel(true)
	tw.tween_property(st, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(st, "modulate:a", 1.0, 0.1)
	tw.chain().tween_callback(func(): Juice.shake(6.0, 0.2); Sfx.play("sfx/kenney/metal_heavy.ogg", 0.0))
	tw.chain().tween_interval(1.9)
	tw.chain().tween_property(st, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(st.queue_free)


# ================================================================ pauze
func _toggle_pause() -> void:
	if finished:
		return
	if pause_menu and is_instance_valid(pause_menu):
		_close_pause()
		return
	paused = true
	get_tree().paused = true
	Sfx.ui("open")
	pause_menu = PauseMenu.new()
	pause_menu.depot = self
	var cl := CanvasLayer.new()
	cl.layer = 30
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(cl)
	cl.add_child(pause_menu)


func _close_pause() -> void:
	if pause_menu and is_instance_valid(pause_menu):
		Sfx.ui("close")
		var cl := pause_menu.get_parent()
		pause_menu.close_anim()
		await get_tree().create_timer(0.15, true, false, true).timeout
		cl.queue_free()
	pause_menu = null
	paused = false
	get_tree().paused = false


func restart_day() -> void:
	get_tree().paused = false
	if coach:
		Transition.goto(Game.SCENE_DEPOT)   # zelfde les opnieuw
		return
	Game.goto_day(day)


# ================================================================ bot (opnames, attract-mode)
func _bot_step(delta: float) -> void:
	bot_t -= delta
	if bot_t > 0.0 or _lock or _running or drag_view != null or _ending:
		return
	# klanten eerst (zoals DayBot)
	if model.splitting.is_empty():
		for c in director.customers():
			var cid := int(c.id)
			if not cust_busy.has(cid) and model.is_findable(int(c.hv)):
				_serve(model.index_of(int(c.hv)), cid)
				bot_t = 0.5
				return
	if not model.splitting.is_empty():
		if table.visible and not table.mid.is_empty() and not (table.front() as ParcelView).has_meta("anim"):
			var m := model.correct_move()
			if m.action == "assign":
				_do_assign(int(m.parcel_id), int(m.side))
				bot_t = 0.45
		return
	var front := _front_parcel()
	var fv := _front_view()
	var ready := fv != null and not fv.has_meta("anim")
	var cm := model.correct_move(front if ready else null)
	match cm.get("action", "none"):
		"double", "fail":
			bot_t = 1.2
			_pull_lever()
		"split":
			bot_t = 1.2
			_try_split(int(cm.bucket_id))
		"retry":
			model.retry_blocked()
			bot_t = 0.5
		"dump":
			bot_t = 0.8
			_key_dump()
		"drop":
			bot_t = 0.25
			var di := int(cm.dir_index)
			if Game.cmd.has("mistake") and not _bot_mistake_done and model.a >= 1 and not spec.no_stars:
				# demo-fout (opnames): door een luik van een ander rek
				for j in model.dir.size():
					if model.dir[j] != model.dir[di]:
						di = j
						_bot_mistake_done = true
						break
			_bot_type(HashUtil.bits(di, model.a))
		_:
			bot_t = 0.3


func _bot_type(bits: String) -> void:
	bot_t = 0.3 + 0.22 * bits.length() + 0.5
	for c in bits:
		_type_bit(c)
		await get_tree().create_timer(0.22).timeout
		if _lock:
			return


func _begin_phase(first: bool) -> void:
	spec = director.spec
	model = director.model
	scoring = director.scoring
	hint_level = int(spec.bit_hint)
	calm = not spec.is_realtime()
	_connect_core()
	for pid in belt_views:
		belt_views[pid].queue_free()
	belt_views.clear()
	belt_x.clear()
	belt_age.clear()
	for pid in stuck_views:
		if is_instance_valid(stuck_views[pid]):
			stuck_views[pid].queue_free()
	stuck_views.clear()
	for pid in table_views:
		if is_instance_valid(table_views[pid]):
			table_views[pid].queue_free()
	table_views.clear()
	table.visible = false
	for cid in cust_views:
		cust_views[cid].queue_free()
	cust_views.clear()
	cust_busy.clear()
	cust_focus = false
	_queue.clear()
	_lock = false
	finished = false
	_ending = false
	alarm_on = false
	chain_level = 0
	time_s = 0.0
	hints_done.clear()
	_pending_hint = {}
	hud.day_label = ("DAG %d" % day) if day > 0 else "PIEKDAG"
	if coach:
		hud.day_label = coach.phase.to_upper()
		hud.show_combo = false
		hud.show_coins = false  # munten tellen niet in een les (en konden kort -1 tonen)
	hud.day_title = spec.title
	hud.rep = scoring.rep
	hud.rep_max = scoring.rep_max
	hud.show_rep = not calm
	hud.set_coins(scoring.coins, false)
	hud.set_io(0, 0)
	hud.set_combo(1)
	hud.opt_r = -1
	hud.opt_w = -1
	if not spec.endless and not spec.no_stars:
		var opt: Dictionary = Days.optimum(spec)
		hud.opt_r = int(opt.get("reads", -1))
		hud.opt_w = int(opt.get("writes", -1))
	lever.a = model.a
	lever.n = model.n
	lever.pull = 0.0
	bin_count = 0
	bin_view.visible = spec.overflow_bin
	ff_btn.visible = false
	zones.queue_redraw()
	_expected_racks = 0
	var ee: Dictionary = spec.expect_end
	if ee.has("layout"):
		_expected_racks = (ee.layout as Array).size()
	_rebuild_all()
	if first:
		if spec.endless:
			Sfx.play_track("rush")
		else:
			Sfx.start_layers()
	Sfx.stinger("music/kenney/stinger_day_start.ogg", -4.0)
	Sfx.loop("belt", "sfx/conveyor_loop.wav", true, -14.0)
	_update_alarm_state()
	_show_day_card()
	_hint("start")


func _on_customer_arrived(c: Dictionary) -> void:
	var cv := CustomerView.new().setup(int(c.id), int(c.hv), model.n)
	cv.position = Vector2(2080, 960)
	cv.scale = Vector2(0.62, 0.62)
	counter_layer.add_child(cv)
	cust_views[int(c.id)] = cv
	Sfx.play("sfx/customer_arrive.wav", -8.0)
	_layout_customers()
	_hint("first_customer")


func _layout_customers() -> void:
	var k := 0
	for c in director.customers():
		var cid := int(c.id)
		var cv: CustomerView = cust_views.get(cid)
		if cv == null:
			continue
		var at_desk := k == 0
		var tgt := Vector2(1732, 700) if at_desk else Vector2(1620 + (k - 1) * 120, 990)
		var sc := Vector2.ONE if at_desk else Vector2(0.62, 0.62)
		if cv.get_meta("tgt", Vector2.ZERO) != tgt:
			cv.set_meta("tgt", tgt)
			var tw := cv.create_tween().set_parallel(true)
			tw.tween_property(cv, "position", tgt, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(cv, "scale", sc, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(cv, "modulate", Color.WHITE if at_desk else Color(0.75, 0.78, 0.9, 1.0), 0.2)
			if at_desk and not cv.at_desk:
				cv.at_desk = true
				cv.balloon = 0.0
				tw.tween_property(cv, "balloon", 1.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.2)
				get_tree().create_timer(0.2).timeout.connect(func(): Sfx.play("sfx/kenney/ui_open.ogg", -8.0))
		k += 1


func _update_customers(_delta: float) -> void:
	if director == null:
		return
	for c in director.customers():
		var cv: CustomerView = cust_views.get(int(c.id))
		if cv:
			cv.patience = float(c.patience_left) / maxf(float(c.patience), 0.001)
			cv.focus = cust_focus and cv.at_desk
			match hint_level:
				0:
					cv.chips = model.a
					cv.knip = model.a
				1:
					cv.chips = model.n
					cv.knip = model.a
				_:
					cv.chips = 0
					cv.knip = 0


func _set_cust_focus(on: bool) -> void:
	if on and director.customers().is_empty():
		return
	cust_focus = on
	type_buf = ""
	_update_type_highlight()
	Sfx.play("sfx/kenney/ui_toggle.ogg", -8.0)


## Klant aan de balie helpen via luik idx (= opzoeken: pointer volgen).


func _serve(idx: int, cid := -1) -> void:
	var list: Array = director.customers()
	if list.is_empty():
		return
	if cid < 0:
		for c in list:
			if not cust_busy.has(int(c.id)):
				cid = int(c.id)
				break
	if cid < 0 or cust_busy.has(cid):
		return
	var chv := -1
	for c in list:
		if int(c.id) == cid:
			chv = int(c.hv)
	if not _guard("serve", {"idx": idx, "cid": cid, "hv": chv}):
		Sfx.play("sfx/kenney/ui_error.ogg", -8.0)
		return
	_idle = 0.0
	cust_busy[cid] = true
	var r: Dictionary = director.serve(cid, idx)
	if r.is_empty():
		cust_busy.erase(cid)
		return
	_anim_serve(cid, idx, r)


func _anim_serve(cid: int, idx: int, r: Dictionary) -> void:
	var hv: HatchView = hatches[idx]
	hv.open_flap()
	Sfx.play("sfx/kenney/hatch_flap.ogg", -6.0, 1.2)
	var bid := int(r.bucket_id)
	await _pulse(pipes[idx] if idx < pipes.size() else null, bid, 1.0, 0.3)
	var rv: RackView = racks.get(bid)
	# heftruck haalt het rek naar de balie (1 leesrit)
	var desk := Vector2(1600, 660)
	var tr := Node2D.new()
	tr.draw.connect(func():
		Pal.truck(tr, Vector2.ZERO, 2.4)
		tr.draw_style_box(Pal.sb(rv.col if rv else Pal.PANEL_HI, 6), Rect2(Vector2(30, -40), Vector2(40, 30))))
	tr.z_index = 30
	fx_layer.add_child(tr)
	tr.position = (rv.global_position + Vector2(rv.size.x / 2.0 + 20, 0)) if rv else Vector2(1500, 600)
	if rv:
		rv.wobble(2.0)
	Sfx.play("sfx/warehouse_trip.wav", -6.0)
	var tw := tr.create_tween()
	tw.tween_property(tr, "position", desk, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	# scannerstraal
	Juice.flash_glow(fx_layer, desk + Vector2(40, -30), Pal.OK if r.found else Pal.TEXT_DIM, 1.2, 0.25)
	var cv: CustomerView = cust_views.get(cid)
	if bool(r.found):
		Sfx.play("sfx/scan_ok.wav")
		Sfx.play("sfx/customer_happy.wav", -6.0)
		Juice.confetti(fx_layer, Vector2(1732, 520), 10)
		if cv:
			cv.mood = 1
		_release_coins(Vector2(1732, 480))
		await get_tree().create_timer(0.45).timeout
		_customer_leave(cid, true)
	else:
		Sfx.play("sfx/scan_fail.wav")
		if cv:
			cv.shake = 0.0
			cv.create_tween().tween_property(cv, "shake", 1.0, 0.5)
		var still := false
		for c in director.customers():
			if int(c.id) == cid:
				still = true
		cust_busy.erase(cid)
		if not still:
			_customer_leave(cid, false)
	var tw2 := tr.create_tween()
	tw2.tween_property(tr, "position", Vector2(1960, desk.y + 40), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw2.tween_callback(tr.queue_free)


func _on_customer_left(c: Dictionary, happy: bool) -> void:
	if cust_busy.has(int(c.id)):
		return   # de serve-animatie handelt het vertrek af
	_customer_leave(int(c.id), happy)


func _customer_leave(cid: int, happy: bool) -> void:
	cust_busy.erase(cid)
	var cv: CustomerView = cust_views.get(cid)
	cust_views.erase(cid)
	if cv == null:
		_layout_customers()
		return
	cv.mood = 1 if happy else -1
	if not happy:
		Sfx.play("sfx/customer_angry.wav", -2.0)
		cv.shake = 0.0
		cv.create_tween().tween_property(cv, "shake", 1.0, 0.4)
	var tw := cv.create_tween()
	tw.tween_interval(0.35 if not happy else 0.1)
	tw.tween_property(cv, "balloon", 0.0, 0.12)
	tw.tween_property(cv, "position", Vector2(2120, cv.position.y + 40), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(cv.queue_free)
	if cust_views.is_empty():
		cust_focus = false
	get_tree().create_timer(0.3).timeout.connect(_layout_customers)


func _draw_desk() -> void:
	if not _has_desk():
		return
	var d := desk_layer
	var desk := Rect2(1580, 636, 324, 112)
	d.draw_style_box(Pal.sb(Pal.PANEL_HI, 20, 16, Vector2(0, 10)), desk)
	Pal.head(d, Rect2(desk.position, Vector2(desk.size.x, 20)), Pal.PANEL_HI.lightened(0.14), 20)
	var bell := Vector2(desk.end.x - 40, desk.position.y)
	d.draw_arc(bell + Vector2(0, -2), 14, PI, TAU, 16, Pal.COIN, 12, true)
	d.draw_line(bell + Vector2(-20, 4), bell + Vector2(20, 4), Pal.COIN_DARK, 5)
	Pal.text_c(d, Pal.UI_BOLD, Vector2(desk.get_center().x, desk.get_center().y + 14), "BALIE", 26, Color(1, 1, 1, 0.22))
	var n: int = director.customers().size() if director else 0
	if n > 1:
		Pal.text_c(d, Pal.UI, Vector2(1726, 1050), "wachtrij: %d" % (n - 1), 22, Pal.TEXT_DIM)
	if n > 0 and not cust_focus and day == 4:
		Pal.text_c(d, Pal.UI, Vector2(1742, 790), "klik het luik · of Tab + bits", 20, Color(Pal.TEXT_DIM, 0.8))


# ================================================================ overloopbak (dag 7 middag, endless)


func _draw_bin() -> void:
	var b := bin_view
	var r := Rect2(BIN2.position - bin_view.position, BIN2.size)
	b.draw_style_box(Pal.sb(Pal.PANEL, 24, 16, Vector2(0, 10)), r)
	var hs := Pal.sbn(Pal.PANEL_HI, 24)
	hs.corner_radius_bottom_left = 0
	hs.corner_radius_bottom_right = 0
	b.draw_style_box(hs, Rect2(r.position, Vector2(r.size.x, 52)))
	Pal.text_c(b, Pal.UI_BOLD, Vector2(r.get_center().x - 20, r.position.y + 26), "overloop", 22, Pal.TEXT)
	var kr := Rect2(r.end.x - 52, r.position.y + 10, 40, 32)
	b.draw_style_box(Pal.sb(Color(0, 0, 0, 0.3), 10), kr)
	Pal.text_c(b, Pal.MONO, kr.get_center(), "K", 22, Pal.TEXT)
	var inner := Rect2(r.position + Vector2(16, 66), r.size - Vector2(32, 82))
	b.draw_style_box(Pal.sb(Pal.SLOT, 14), inner)
	for k in mini(bin_count, 6):
		var y := inner.end.y - 26 - k * 30
		b.draw_style_box(Pal.sb(Pal.KRAFT if k % 2 == 0 else Pal.KRAFT_DARK, 6), Rect2(inner.position.x + 20 + (k % 2) * 10, y, inner.size.x - 50, 24))
	var hot := drag_view != null and (drag_from == "belt" or drag_from == "stuck") and BIN2.grow(20).has_point(drag_view.position)
	if hot:
		Pal.ring(b, r.grow(6), 30, Color(Pal.WARN, 0.8), 5)


func _key_dump() -> void:
	if not spec.overflow_bin or _lock:
		Sfx.play("sfx/kenney/ui_error.ogg", -10.0)
		return
	if not model.blocked.is_empty():
		_dump_blocked((model.blocked[0].parcel as Parcel).id)
		return
	var f := _front_view()
	if f and not f.has_meta("anim"):
		_dump_belt(f.pid)


func _dump_belt(pid: int) -> void:
	if not _guard("dump", {"pid": pid}):
		Sfx.play("sfx/kenney/ui_error.ogg", -8.0)
		return
	var pv: ParcelView = belt_views.get(pid)
	var parcel: Parcel = director.take(pid)
	if parcel == null or pv == null:
		return
	belt_views.erase(pid)
	belt_x.erase(pid)
	belt_age.erase(pid)
	_anim_to_bin(pv)
	model.dump(parcel)


func _dump_blocked(pid: int) -> void:
	if not _guard("dump", {"pid": pid}):
		Sfx.play("sfx/kenney/ui_error.ogg", -8.0)
		return
	var parcel: Parcel = null
	for e in model.blocked:
		if (e.parcel as Parcel).id == pid:
			parcel = e.parcel
	if parcel == null:
		return
	var pv: ParcelView = stuck_views.get(pid)
	stuck_views.erase(pid)
	if pv:
		_anim_to_bin(pv)
	model.dump(parcel)
	_update_alarm_state()


func _anim_to_bin(pv: ParcelView) -> void:
	pv.set_meta("anim", true)
	pv.set_lifted(false)
	pv.z_index = 40
	var start := pv.position
	var end := BIN2.get_center() + Vector2(0, 40)
	var ctrl := (start + end) / 2.0 + Vector2(0, -200)
	var tw := pv.create_tween()
	tw.tween_method(func(f: float):
		pv.position = start.lerp(ctrl, f).lerp(ctrl.lerp(end, f), f)
		pv.rotation = f * 2.5
		pv.scale = Vector2.ONE * (1.0 - 0.5 * f), 0.0, 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		Sfx.play("drop_box", 0.0, 0.8)
		Sfx.play("sfx/kenney/metal_heavy.ogg", -10.0)
		Juice.dust(fx_layer, end, 8)
		Juice.shake(3.0, 0.15)
		bin_count += 1
		var tb := bin_view.create_tween()
		tb.tween_property(bin_view, "rotation", 0.05, 0.06)
		tb.tween_property(bin_view, "rotation", -0.03, 0.08)
		tb.tween_property(bin_view, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_BACK)
		pv.queue_free())


func _on_dumped(_parcel: Parcel, verdict: int) -> void:
	if verdict == ExtHashModel.Verdict.OK:
		Juice.floater(fx_layer, BIN2.get_center() + Vector2(0, -90), "kloon!", Pal.OK, 30)
		_coin_timer = 0.5


func _fast_forward() -> void:
	if fast:
		return
	fast = true
	bot = true
	ff_btn.visible = false
	Engine.time_scale = 3.0
	Sfx.play("sfx/tape_start.wav", -4.0, 1.4, false)


# ================================================================ tutorial: chef + spookhand (GDD §5.1)


func _hint(trigger: String) -> void:
	if hints_done.has(trigger) or spec == null:
		return
	for h in spec.hints:
		if str(h.get("trigger", "")) == trigger:
			hints_done[trigger] = true
			_pending_hint = h
			_pending_since = 0.0
			return


func _update_hints() -> void:
	if _pending_hint.is_empty() or _t < _card_end:
		return
	_pending_since += get_process_delta_time()
	var trig := str(_pending_hint.get("trigger", ""))
	var immediate := trig in ["double_refused", "still_blocked", "two_cycles", "first_customer", "start"]
	var need := 0.8 if immediate else 4.0
	if _idle < need and not immediate:
		return
	if _pending_since < need:
		return
	if not _ghost_ready(str(_pending_hint.get("ghost", ""))):
		return
	var h := _pending_hint
	_pending_hint = {}
	var txt := str(h.get("text", ""))
	if txt != "":
		_say(txt)
	_ghost(str(h.get("ghost", "")))


func _ghost_ready(kind: String) -> bool:
	match kind:
		"drag_parcel":
			var f := _front_view()
			return f != null and not f.has_meta("anim")
		"sort_parcel":
			return table.visible and table.front() != null and not table.front().has_meta("anim")
		"click_saw", "count_pipes":
			return not model.blocked.is_empty() and not _running
		"click_hatch":
			return not director.customers().is_empty()
	return true


func _say(txt: String) -> void:
	if coach:
		return
	_chef_text = txt
	_chef_k = 0.0
	Sfx.play("sfx/kenney/ui_open.ogg", -6.0)
	var tw := create_tween()
	tw.tween_property(self, "_chef_k", 1.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(3.2)
	tw.tween_property(self, "_chef_k", 0.0, 0.15).set_ease(Tween.EASE_IN)


func _draw_chef() -> void:
	if _chef_k <= 0.01 or _chef_text == "":
		return
	var o := overlay
	var at := Vector2(820, 1010)
	o.draw_set_transform(at, 0, Vector2(_chef_k, _chef_k))
	# chef: rond hoofd met koksmuts
	o.draw_circle(Vector2(-150, 0), 40, Pal.OUTLINE, true, -1, true)
	o.draw_circle(Vector2(-150, 0), 36, Pal.SKIN[1], true, -1, true)
	o.draw_style_box(Pal.sb(Pal.LABEL, 14), Rect2(-180, -74, 60, 40))
	o.draw_circle(Vector2(-160, -70), 18, Pal.LABEL, true, -1, true)
	o.draw_circle(Vector2(-140, -72), 20, Pal.LABEL, true, -1, true)
	for ex in [-12.0, 12.0]:
		o.draw_circle(Vector2(-150 + ex, -2), 4.5, Pal.INK, true, -1, true)
	o.draw_line(Vector2(-164, 14), Vector2(-136, 14), Color("#3a2a20"), 6, true)
	var w := Pal.UI_BOLD.get_string_size(_chef_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x + 48
	var r := Rect2(-100, -34, w, 68)
	o.draw_style_box(Pal.sb(Pal.LABEL, 24, 10, Vector2(0, 6)), r)
	o.draw_colored_polygon(PackedVector2Array([Vector2(-100, -6), Vector2(-100, 18), Vector2(-122, 10)]), Pal.LABEL)
	Pal.text_l(o, Pal.UI_BOLD, Vector2(-76, 0), _chef_text, 28, Pal.INK)
	o.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## Spookhand doet de handeling één keer voor (INFO-blauw, half doorzichtig).


func _ghost(kind: String) -> void:
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var drag := true
	match kind:
		"drag_parcel":
			var f := _front_view()
			if f == null:
				return
			from = f.position
			to = hatches[model.index_of(f.hv)].position
		"drag_lever":
			from = lever.knob_global()
			to = from + Vector2(0, 130)
		"click_saw", "count_pipes":
			if model.blocked.is_empty():
				return
			var bid := model.dir[int(model.blocked[0].via_index)]
			if kind == "count_pipes":
				await _count_pipes(bid)
			var rv: RackView = racks.get(bid)
			if rv == null:
				return
			to = rv.saw_rect_global().get_center()
			from = to + Vector2(-140, 120)
			drag = false
		"sort_parcel":
			if not table.visible or table.front() == null:
				return
			from = table.front().position
			var m := model.correct_move()
			if m.get("action", "") != "assign":
				return
			to = table.position + (SortTable.LEFT if int(m.side) == 0 else SortTable.RIGHT).get_center()
		"click_hatch":
			var cs: Array = director.customers()
			if cs.is_empty():
				return
			to = hatches[model.index_of(int(cs[0].hv))].position
			from = to + Vector2(160, 160)
			drag = false
		_:
			return
	var g := Node2D.new()
	g.z_index = 65
	var state := {"p": from, "pressed": false, "a": 0.0}
	var carry := ""
	var gpid := -1
	if kind == "drag_parcel" and _front_view():
		carry = _front_view().bits_str
		gpid = _front_view().pid
	elif kind == "sort_parcel" and table.front():
		carry = table.front().bits_str
	g.draw.connect(func():
		if gpid >= 0 and not belt_views.has(gpid):
			# QA P2-3: het voorgedane pakje is al weg (geplaatst) → spookhand stopt
			g.queue_free()
			return
		g.modulate.a = state.a * 0.85
		if carry != "" and state.pressed:
			Pal.parcel(g, state.p + Vector2(0, 10), Vector2(176, 104), carry, Pal.fit_bits(carry.length(), 140, 40, 24), 0, 0, true)
		Pal.hand(g, state.p + Vector2(10, 20), Pal.INFO, 1.6, state.pressed))
	world.add_child(g)
	var tw := g.create_tween()
	tw.tween_method(func(v): state.a = v; g.queue_redraw(), 0.0, 1.0, 0.2)
	if drag:
		tw.tween_callback(func(): state.pressed = true; g.queue_redraw())
		tw.tween_interval(0.2)
		tw.tween_method(func(f: float): state.p = from.lerp(to, f); g.queue_redraw(), 0.0, 1.0, 1.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.tween_callback(func(): state.pressed = false; g.queue_redraw())
	else:
		tw.tween_method(func(f: float): state.p = from.lerp(to, f); g.queue_redraw(), 0.0, 1.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		for k in 2:
			tw.tween_callback(func():
				state.pressed = true
				g.queue_redraw()
				Juice.ring_wave(fx_layer, to, Pal.INFO, 0.1, 0.8, 0.3))
			tw.tween_interval(0.15)
			tw.tween_callback(func(): state.pressed = false; g.queue_redraw())
			tw.tween_interval(0.25)
	tw.tween_interval(0.3)
	tw.tween_method(func(v): state.a = v; g.queue_redraw(), 1.0, 0.0, 0.25)
	tw.tween_callback(g.queue_free)


## Dag 3: de buizen van het rek lichten één voor één op (tellen = 2^(a−ab)), dan de zaag.


func _count_pipes(bid: int) -> void:
	var k := 0
	for i in pipes.size():
		if model.dir[i] == bid:
			var p: PipeView = pipes[i]
			p.set_meta("pulse", true)
			p.lit = 1.0
			hatches[i].warn = 1.0
			Sfx.play("sfx/pipe_click.wav", -4.0, 1.0 + 0.1 * k)
			var tw := p.create_tween()
			tw.tween_interval(0.5)
			tw.tween_property(p, "lit", 0.0, 0.3)
			tw.tween_callback(func(): p.remove_meta("pulse"))
			var h: HatchView = hatches[i]
			h.create_tween().tween_property(h, "warn", 0.0, 0.8)
			k += 1
			await get_tree().create_timer(0.15).timeout


# ================================================================ bot (opnames, attract-mode, "Doorspoelen")


func _vis_bucket(dir_index: int) -> int:
	var b := model.dir[dir_index]
	if _split_info.has("bid") and b == int(_split_info.nbid):
		return int(_split_info.bid)
	return b


