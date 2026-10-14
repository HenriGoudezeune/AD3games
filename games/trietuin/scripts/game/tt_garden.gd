extends Node2D
## De tuin: één scène voor alle levels (GDD §4, §8.11). Bouwt alles in code: achtergrond, wereld (boom +
## camera), HUD, slinger, werkbank, Uil, overlays. Verbindt TtDirector/TtTreeModel (core) met de weergave:
## elke spelerszet gaat via `do_move()` -> `model.apply()`; de `changed(fx)`-beschrijvingen worden daarna in
## volgorde afgespeeld (juice + geluid), pas dan mag de volgende invoer.
## QA: `-- level=1-2 bot=perfect|errors|random speed=2`.

const TREE_RECT := Rect2(40, 100, 1840, 750)
const TREE_RECT_STR := Rect2(40, 250, 1840, 600)
const TREE_RECT_UKK := Rect2(40, 300, 1840, 550)

var spec: TtLevelSpec
var director: TtDirector
var model: TtTreeModel
var scoring: TtScoring
var kind := 0
var letters := "ACGT_"
var season := 0
var art_season := 0
var level_id := "1-1"
var swarm := false

var backdrop: TtBackdrop
var world: Node2D
var cam: Camera2D
var view: TtTreeView
var wfx: Node2D
var ui: CanvasLayer
var hud: TtHud
var bench: TtWorkbench
var strip: TtStringView
var owl: TtOwl
var hand: TtGhostHand
var overlay: CanvasLayer
var hedge: TtInspector
var critter: TtCritter
var firefly: TtCritter

var fxq: Array = []
var busy := false
var state := "intro"            # intro | play | bloom | report | paused
var cam_auto := true
var _cam_zoom := 1.0
var _cam_pos := Vector2.ZERO
var _drag := false
var _drag_from := Vector2.ZERO
var t := 0.0
var idle_t := 0.0
var bot: TtBot
var bot_t := 0.0
var bot_delay := 0.55
var compare_cursor := 0
var hop_cursor := 0
var pick_cursor := 0
var path_cursor := 0
var picked_leaves: Array = []
var picked_owners: Array = []
var num_value := ""
var used_hint := false
var _tut_done := {}
var _last_phase := -1
var _bloom_skip := false
var _pause_menu: Control
var _card_done_pending := false
var _bloom_results: Array = []
var _bloom_icons: Array = []
var _report: Control
var _hive := Vector2.ZERO
var _first_card := true
var _intro_node: Control
var _ascii_storm := false
var _timeline_q: Array = []
var _shown_card: TtCard = null
var _ghost_until := 0
var _ghost_t := 0.0


# ================================================================ opbouw
func _ready() -> void:
	level_id = TtSession.level_id
	if TtSession.has("level"):
		level_id = TtSession.consume("level")
		TtSession.level_id = level_id
	if level_id == "endless":
		spec = TtLevels.endless()
	else:
		spec = TtLevels.get_spec(level_id)
	if spec == null:
		push_error("Trietuin: onbekend level " + level_id)
		spec = TtLevels.get_spec("1-1")
	kind = spec.kind
	season = TtSession.season_of(level_id)
	art_season = TtSession.art_season(level_id)
	swarm = spec.mode == TtCodes.Mode.SWARM
	director = TtDirector.new()
	director.start(spec)
	model = director.model
	scoring = director.scoring
	letters = "".join(model.alphabet.letters)
	_build()
	_connect()
	for tu in spec.tutorial:
		if str(tu.get("trigger", "")) == "ghost_iterations":
			_ghost_until = int(tu.get("until_it", 0))
	var bm := TtSession.consume("bot")
	if bm != "":
		bot = TtBot.new(bm, int(TtSession.arg("seed", "7")))
		TtSnd.muted = TtSession.has("mute")
	var sp := TtSession.arg("speed", "")
	if sp != "":
		Engine.time_scale = float(sp)
	TtSnd.season_music(4 if season == 4 else art_season)
	_apply_settings()
	if TtSession.has("pause"):
		get_tree().create_timer(float(TtSession.arg("pause", "2"))).timeout.connect(_open_pause)
	if TtSession.has("hint"):
		get_tree().create_timer(float(TtSession.arg("hint", "3"))).timeout.connect(_hint)
	if TtSession.arg("intro", "1") == "0" or bot != null:
		_begin_play()
	else:
		_show_intro()


func _apply_settings() -> void:
	var sh: float = float(TtSave.setting("shake", 1.0))
	Juice.shake_scale = sh


func _build() -> void:
	backdrop = TtBackdrop.new(art_season, true, -10)
	add_child(backdrop)
	world = Node2D.new()
	add_child(world)
	cam = Camera2D.new()
	cam.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	cam.position = Vector2(0, -300)
	world.add_child(cam)
	cam.make_current()
	Juice.camera = null   # Juice zou zoom elke frame op 1 zetten; de tuin schudt zelf (shake())
	view = TtTreeView.new()
	world.add_child(view)
	var vopts := {"pos_base": spec.pos_base, "text": model.get("text") if model.get("text") != null else spec.text}
	if kind == TtCodes.Kind.SUFFIX or kind == TtCodes.Kind.UKKONEN:
		view.show_strings = spec.labels == "strings"
		view.it_cur = _it_now()
		vopts["leaf_cut"] = _leaf_cuts()
	view.setup(model, kind, letters, art_season, vopts)
	if kind == TtCodes.Kind.SUFFIX and not spec.owners_spec.is_empty():
		for o in spec.owners_spec:
			view.owner_cols.append(_owner_color(view.owner_cols.size()))
	wfx = Node2D.new()
	wfx.z_index = 30
	world.add_child(wfx)
	ui = CanvasLayer.new()
	ui.layer = 5
	add_child(ui)
	var root_ui := Control.new()
	root_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.theme = TtUi.theme()
	ui.add_child(root_ui)
	strip = TtStringView.new()
	strip.visible = kind == TtCodes.Kind.SUFFIX or kind == TtCodes.Kind.UKKONEN
	strip.season = art_season
	strip.letters = letters
	strip.pos_base = spec.pos_base
	strip.text = _full_text()
	strip.mist = level_id == "4-4"
	if not spec.owners_spec.is_empty():
		var i := 0
		for o in spec.owners_spec:
			strip.owners.append({"name": o.get("name", "?"), "from": int(o.get("from", 0)), "to": int(o.get("to", 0)), "col": _owner_color(i)})
			i += 1
	root_ui.add_child(strip)
	hud = TtHud.new()
	hud.season = season
	hud.letters = letters
	root_ui.add_child(hud)
	bench = TtWorkbench.new()
	bench.letters = letters
	bench.season = art_season
	bench.hint = spec.letter_hint
	root_ui.add_child(bench)
	hedge = TtInspector.new()
	hedge.visible = false
	root_ui.add_child(hedge)
	owl = TtOwl.new()
	owl.letters = letters
	owl.enabled_hint = spec.hints_allowed and not swarm
	root_ui.add_child(owl)
	hand = TtGhostHand.new()
	root_ui.add_child(hand)
	overlay = CanvasLayer.new()
	overlay.layer = 20
	add_child(overlay)
	hud.title = "%s %s · %s" % [TtSession.season_name(season).to_upper(), level_id, spec.title] if level_id != "endless" else "VRIJE TUIN · " + spec.title
	hud.sub = spec.notes_ref
	hud.set_sap(model.sap_used(), model.sap_budget)
	hud.sap_shown = model.sap_used()
	hud.lives = 3 if level_id == "endless" else -1
	_hive = Vector2(-260, 150)
	_update_queue()


func _connect() -> void:
	model.changed.connect(func(fx: Dictionary): fxq.append(fx))
	model.sap_changed.connect(func(used: int, delta: int): hud.set_sap(used, model.sap_budget, delta))
	model.card_finished.connect(func(_c, _o): _card_done_pending = true)
	if scoring:
		scoring.honey_changed.connect(_on_honey)
		if scoring.has_signal("combo_changed"):
			scoring.combo_changed.connect(func(c: int): hud.combo = c)
		if scoring.has_signal("bee_dance"):
			scoring.bee_dance.connect(_bee_dance)
	director.card_queued.connect(func(_c): _update_queue())
	director.timeline_event.connect(func(ev: Dictionary): _timeline_q.append(ev))
	director.budget_changed.connect(func(b: int): hud.set_sap(model.sap_used(), b))
	director.card_expired.connect(_on_expired)
	hud.pause_pressed.connect(_open_pause)
	bench.action.connect(_on_action)
	bench.cell_clicked.connect(_on_cell)
	owl.clicked.connect(_hint)
	strip.pearl_clicked.connect(_on_pearl)
	view.hovered.connect(func(_h): pass)


func _full_text() -> String:
	if model.get("text") != null:
		return str(model.get("text"))
	return spec.text


func _it_now() -> int:
	if kind == TtCodes.Kind.UKKONEN and model.has_method("active"):
		return int(model.active().get("it", 0))
	return _full_text().length()


func _leaf_cuts() -> Dictionary:
	return {}


func _owner_color(i: int) -> Color:
	return [Color("#8E7CC3"), Color("#E06C75"), Color("#56B6C2"), Color("#E5C07B")][i % 4]


# ================================================================ intro
func _show_intro() -> void:
	state = "intro"
	_intro_node = TtIntroCard.new()
	var se := TtPal.season(art_season)
	_intro_node.setup(TtSession.season_name(season), level_id, spec.title, spec.notes_ref, spec.intro, se)
	overlay.add_child(_intro_node)
	_intro_node.finished.connect(func():
		_intro_node = null
		_begin_play())


func _begin_play() -> void:
	state = "play"
	_fit_camera(true)
	if spec.intro != "" and bot == null:
		owl.say(spec.intro, 5.0)
	if swarm:
		_refresh_ui()
		return
	await get_tree().create_timer(0.35).timeout
	_next_card()


# ================================================================ kaartenstroom
func _update_queue() -> void:
	var q := []
	if swarm:
		for c in director.waiting():
			var inf := _card_info(c)
			inf["arrived"] = true
			if c.patience > 0.0:
				inf["pat"] = clampf(1.0 - (director.time - c.t) / c.patience, 0.0, 1.0)
			q.append(inf)
	for c in director.queue():
		if swarm and c.t > director.time + 12.0:
			continue
		q.append(_card_info(c))
	if swarm:
		hud.queue = q
	else:
		hud.set_queue(q)


func _card_info(c: TtCard) -> Dictionary:
	var k := "seed"
	match c.kind:
		TtCodes.CardKind.SEED:
			k = "seed"
		TtCodes.CardKind.BEE:
			k = "bee"
		TtCodes.CardKind.PRUNE:
			k = "prune"
		TtCodes.CardKind.PATRICIFY:
			k = "patricify"
		TtCodes.CardKind.TERNARIFY:
			k = "ternarify"
		TtCodes.CardKind.BEDS:
			k = "beds"
		TtCodes.CardKind.SUFFIX:
			k = "suffix"
		TtCodes.CardKind.ASK:
			k = "ask"
		TtCodes.CardKind.UKKONEN:
			k = "ukkonen"
	var w := c.word
	if c.kind == TtCodes.CardKind.SUFFIX and c.j >= 0:
		w = _full_text().substr(c.j)
	return {"kind": k, "word": w, "wasp": c.wasp}


func _next_card() -> void:
	if state != "play":
		return
	if model.card != null:
		await _card_arrival(model.card)
		return
	await _run_timeline()
	if director.all_done():
		_start_bloom()
		return
	var c: TtCard = director.next_card()
	_update_queue()
	if c == null:
		if not swarm:
			_start_bloom()
		return
	await _card_arrival(c)


func _run_timeline() -> void:
	while not _timeline_q.is_empty():
		var ev: Dictionary = _timeline_q.pop_front()
		match str(ev.get("event", "")):
			"ascii_storm":
				owl.say(str(ev.get("text", "")), 3.0)
				var st := TtAsciiStorm.new()
				st.rank_sap = model.sap_used()
				overlay.add_child(st)
				await st.finished
			"stamp":
				var lab := TtStampFlash.new()
				lab.text = str(ev.get("text", ""))
				overlay.add_child(lab)
				TtSnd.play("stamp", 0.0)
				await get_tree().create_timer(1.2).timeout
			"badges":
				view.show_counts = true
				owl.say(str(ev.get("text", "")), 5.0)
				TtSnd.play("bee_happy", -6.0)
				for id in view.rn:
					if not view.is_leaf(id):
						view.pop_node(id, 1.2)
				await get_tree().create_timer(0.8).timeout


func _card_arrival(c: TtCard) -> void:
	busy = true
	_shown_card = c
	view.sync(true)
	var info := _card_info(c)
	bench.card_kind = "wasp" if c.wasp else info.kind
	if c.wasp:
		bench.card_kind = "bee"
	bench.card_word = info.word
	bench.pop()
	_spawn_critter(c)
	# eventuele fx van begin() (bv. Ukkonen-iteratie)
	if not fxq.is_empty():
		await _play_fx()
	if c.kind == TtCodes.CardKind.ASK:
		hedge.visible = true
		hedge.arrive(_question_text(c), letters)
		TtSnd.play("steps", -4.0)
	_tutorial("card_%s" % info.kind)
	_tutorial("card", c.id - 1)
	if _first_card:
		_first_card = false
		if spec.tutorial.size() > 0 and str(spec.tutorial[0].get("text", "")) != spec.intro:
			_tutorial("first_card")
	busy = false
	if model.card == null:
		_card_done_pending = false
		await _after_move({"done": true})
		return
	_refresh_ui()


func _spawn_critter(c: TtCard) -> void:
	if critter and is_instance_valid(critter):
		critter.queue_free()
	critter = null
	var se := TtPal.season(art_season)
	var root_p := view.pos_of(model.root)
	match c.kind:
		TtCodes.CardKind.SEED:
			critter = TtCritter.new(TtCritter.K.SEED, c.word, letters, se)
			critter.label_on = false
			world.add_child(critter)
			critter.position = _screen_to_world(Vector2(760, 50))
			var tw := critter.fly_to(_rest_pos(model.root), 0.42, -120)
			tw.tween_callback(func():
				critter.pop(1.25, 0.8, 0.3)
				TtFx.burst(wfx, critter.position + Vector2(0, 14), "pollen", 4, 0.5, 30, 80, se.light, 0, 0.2, 0.4))
			TtSnd.play("seed_land", -4.0)
		TtCodes.CardKind.BEE, TtCodes.CardKind.PRUNE:
			var k := TtCritter.K.BEE
			if c.kind == TtCodes.CardKind.PRUNE:
				k = TtCritter.K.SHEARS
			critter = TtCritter.new(k, c.word, letters, se)
			critter.label_on = false
			if c.wasp:
				critter.kind = TtCritter.K.WASP
			world.add_child(critter)
			critter.position = view.hive_pos() + Vector2(0, -40)
			critter.fly_to(_rest_pos(model.root), 0.55, -80)
			TtSnd.play("buzz_soft", -8.0)
		_:
			pass
	if critter and kind == TtCodes.Kind.PATRICIA:
		critter.ghost_to = -1


func _rest_pos(id: int) -> Vector2:
	if not view.vs.has(id):
		return Vector2.ZERO
	var p := view.pos_of(id)
	if view.is_leaf(id):
		return view.fruit_center(id) + Vector2(78, -40)
	match kind:
		TtCodes.Kind.TERNARY:
			return p + Vector2(76, -54)
		TtCodes.Kind.SUFFIX, TtCodes.Kind.UKKONEN:
			return p + Vector2(60, -40)
	var kw := TtViewLayout.knot_width(letters.length())
	return p + Vector2(kw / 2.0 + 40, -44)


func _after_move(res: Dictionary) -> void:
	if _card_done_pending or bool(res.get("done", false)):
		_card_done_pending = false
		await _card_end_anim()
		if state != "play":
			return
		if swarm:
			_refresh_ui()
			return
		await get_tree().create_timer(0.3).timeout
		_next_card()
	else:
		_refresh_ui()


func _card_end_anim() -> void:
	_shown_card = null
	hedge.leave_if_done(model.card == null)
	if critter and is_instance_valid(critter):
		if critter.kind == TtCritter.K.SEED:
			var c := critter
			var tw := c.create_tween()
			tw.tween_property(c, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tw.tween_callback(c.queue_free)
		elif not critter.is_queued_for_deletion():
			critter.leave(Vector2(-1, -0.5), 0.6)
		critter = null
	bench.card_kind = ""
	bench.mode = "info"
	bench.word = ""
	bench.subtitle = ""
	bench.title_parts = [["De wind brengt het volgende kaartje…", "ui"]] if not director.all_done() else [["Alles geplant. Tijd voor de Bloei!", "ui"]]
	bench.set_buttons([])
	_clear_highlights()
	await get_tree().create_timer(0.25).timeout


# ================================================================ zetten
func do_move(mv: Dictionary) -> void:
	if busy or state != "play" or model.card == null:
		return
	busy = true
	idle_t = 0.0
	hand.stop()
	fxq.clear()
	_card_done_pending = false
	model.now = director.time if director.get("time") != null else t
	var was_ask: bool = model.card.kind == TtCodes.CardKind.ASK
	var res: Dictionary = model.apply(mv)
	if not bool(res.get("ok", true)):
		bench.bump()
	elif was_ask:
		var good := int(res.get("verdict", 0)) == TtCodes.Verdict.OK
		hedge.react(good)
		TtSnd.play("dog_happy" if good else "dog_bark", -6.0)
		if good:
			TtSnd.play("stamp", -4.0)
	await _play_fx()
	busy = false
	await _after_move(res)


func _play_fx() -> void:
	view.it_cur = _it_now()
	view.sync(false)
	while not fxq.is_empty():
		var fx: Dictionary = fxq.pop_front()
		var d: float = await _fx(fx)
		if d > 0.0 and not _bloom_skip:
			await get_tree().create_timer(d).timeout
	view.reveal_all_now()
	view.sync(false)
	_fit_camera(false)


# ================================================================ fx-afspeler
func _fx(fx: Dictionary) -> float:
	var se := TtPal.season(art_season)
	match str(fx.get("fx", "")):
		"move":
			var to := int(fx.to)
			var letter := str(fx.get("letter", ""))
			TtSnd.letter(letter, letters)
			view.hl_edges[to] = Color(TtPal.INFO, 0.4)
			_unglow_later(to, 0.5)
			if critter:
				var e := view.edge_pts(to)
				var pts := PackedVector2Array()
				pts.append(critter.position)
				for p in e:
					pts.append(p + Vector2(0, -26))
				pts.append(_rest_pos(to))
				critter.fly_path(pts, 0.34 if critter.kind == TtCritter.K.SEED else 0.3)
				critter.read_pos = mini(critter.read_pos + 1, critter.word.length() - 1) if critter.read_pos >= 0 else 0
			bench.pop()
			return 0.34
		"bee_null":
			var at := int(fx.at)
			var bp := view.bud_top(at, str(fx.get("letter", "")))
			if critter:
				critter.fly_to(bp + Vector2(0, -34), 0.25, -30)
				await get_tree().create_timer(0.27).timeout
				critter.mood = 1
				critter.bonk(Vector2(0, 1))
				TtSnd.play("bee_bonk", -2.0)
				TtFx.poof(wfx, bp)
				_world_text(bp + Vector2(0, -70), "lege knop", TtPal.TEXT)
			return 0.6
		"hang":
			var leaf := int(fx.leaf)
			var node := int(fx.node)
			var bp2 := view.bud_top(node, str(fx.get("letter", "")))
			TtSnd.play("bud_plop", -2.0)
			if critter and critter.kind == TtCritter.K.SEED:
				critter.fly_to(bp2 + Vector2(0, -20), 0.2, -20)
				await get_tree().create_timer(0.2).timeout
				critter.label_on = false
				var c := critter
				var tw := c.create_tween()
				tw.tween_property(c, "scale", Vector2(0.2, 0.2), 0.18)
				tw.tween_callback(c.hide)
			view.reveal(leaf, 0.28, "grow")
			await get_tree().create_timer(0.24).timeout
			view.pop_node(leaf, 0.2)
			_pop_leaf(leaf)
			TtSnd.play("fruit_plop", -2.0)
			TtFx.ripen(wfx, view.fruit_center(leaf), art_season)
			return 0.35
		"grow":
			var ids: Array = fx.get("nodes", [])
			var k := 0
			for id in ids:
				var idd := int(id)
				var delay := 0.13 * k
				get_tree().create_timer(delay).timeout.connect(func():
					view.reveal(idd, 0.3, "grow")
					TtSnd.play("grow_wood", -6.0, 1.0 + 0.06 * k)
					TtSnd.play("bud_plop", -10.0, 1.3)
					TtFx.grow(wfx, view.pos_of(idd), art_season)
					TtFx.sap(wfx, view.pos_of(idd) + Vector2(0, -20), 4))
				k += 1
			TtSnd.play("sap_drop", -6.0)
			return 0.18 + 0.13 * ids.size()
		"rehang":
			var lf := int(fx.leaf)
			TtSnd.play("graft", -6.0)
			view.pop_node(lf, 1.2)
			return 0.32
		"compare":
			TtSnd.play("ribbon_roll", -4.0)
			bench.pop()
			return 0.25
		"answer":
			return await _fx_answer(fx)
		"same":
			var lf2 := int(fx.get("leaf", -1))
			if bool(fx.get("correct", false)):
				view.pop_node(lf2, 1.3)
				TtSnd.play("pick_ok", -4.0)
				TtFx.found(wfx, view.fruit_center(lf2))
				if critter:
					critter.fly_to(view.fruit_center(lf2), 0.25, -20)
			else:
				TtSnd.play("ui_whoosh", -4.0)
				if critter:
					critter.leave(Vector2(1, -0.4), 0.8)
					critter = null
			return 0.5
		"cut":
			var node2 := int(fx.node)
			var e2 := view.edge_pts(node2)
			var cp := TtDraw.path_point(e2, 0.35) if e2.size() > 1 else view.pos_of(node2)
			if critter and critter.kind == TtCritter.K.SHEARS:
				critter.fly_to(cp, 0.2, -10)
				await get_tree().create_timer(0.2).timeout
				critter.open = 0.0
			TtSnd.play("snip", 0.0)
			TtFx.snip(wfx, cp, art_season)
			shake(3.0, 0.15)
			var ids2: Array = []
			for i in fx.get("removed", []):
				ids2.append(int(i))
			for i in fx.get("fallen", []):
				if not ids2.has(int(i)):
					ids2.append(int(i))
			if not ids2.has(node2):
				ids2.append(node2)
			view.drop_nodes(ids2, "fall")
			get_tree().create_timer(0.45).timeout.connect(func(): TtSnd.play("branch_fall", -2.0))
			TtSnd.play("sap_return", -6.0)
			return 0.6
		"dead_wood":
			TtSnd.play("rot", -10.0)
			return 0.3
		"bump":
			TtSnd.play("clonk", -2.0)
			shake(2.0, 0.12)
			bench.bump()
			var at2 := int(fx.get("at", -1))
			var bpos := view.pos_of(at2) if at2 >= 0 and view.vs.has(at2) else (critter.position if critter else Vector2.ZERO)
			TtFx.burst(wfx, bpos, "chip", 6, 0.35, 120, 240, Color.WHITE, 500, 0.25, 0.45, false, Vector2.UP, 80, [TtPal.WARN, TtPal.BARK_LIGHT])
			if critter:
				critter.pop(0.85, 1.15, 0.3)
			_bump_reason(str(fx.get("reason", "")), bpos)
			return 0.3
		"prune":
			var pn := int(fx.node)
			var ch := int(fx.get("child", -1))
			var pp := view.pos_of(pn)
			var sh := TtCritter.new(TtCritter.K.SHEARS, "", letters, se)
			world.add_child(sh)
			sh.position = pp + Vector2(160, -60)
			sh.open = 0.9
			sh.fly_to(pp + Vector2(40, -10), 0.18, -20)
			await get_tree().create_timer(0.2).timeout
			sh.open = 0.0
			TtSnd.play("shears", -2.0)
			TtFx.snip(wfx, pp, art_season)
			view.drop_nodes([pn], "fade")
			sh.leave(Vector2(1, -1), 0.6)
			get_tree().create_timer(0.25).timeout.connect(func():
				if view.vs.has(ch):
					view.pop_node(ch, 1.35)
					TtSnd.play("graft", -4.0))
			TtSnd.play("sap_return", -8.0)
			return 0.55
		"read":
			var p := int(fx.get("pos", 0))
			var from := bench.read_hint if bench.read_hint >= 0 else 0
			bench.chosen = p
			TtSnd.letter(str(fx.get("letter", "")), letters)
			if critter:
				critter.read_pos = p
				critter.ghost_to = p - 1
			var hops := absi(p - hop_cursor)
			hop_cursor = p
			return 0.12 + 0.03 * mini(hops, 10)
		"short":
			if critter:
				critter.fly_to(critter.position + Vector2(40, -60), 0.25, -40)
				critter.mood = 1
				TtFx.poof(wfx, critter.position + Vector2(40, -60))
			TtSnd.play("ui_whoosh", -4.0, 1.3)
			_world_text(critter.position + Vector2(0, -80) if critter else Vector2.ZERO, "te kort", TtPal.TEXT)
			return 0.45
		"pick":
			var pl := int(fx.leaf)
			view.pop_node(pl, 1.3)
			TtSnd.play("bud_plop", -4.0, 1.2)
			TtFx.ring_wave(wfx, view.fruit_center(pl), Color(TtPal.OK, 0.8), 0.3, 1.6, 0.4)
			if critter:
				critter.fly_to(_rest_pos(pl), 0.35, -60)
			return 0.4
		"graft":
			var gn := int(fx.node)
			view.reveal(gn, 0.3, "grow")
			view.pop_node(gn, 1.25)
			TtSnd.play("graft", -2.0)
			TtFx.grow(wfx, view.pos_of(gn), art_season)
			for k2 in fx.get("skips", {}).keys():
				view.pop_node(int(k2), 1.2)
			return 0.45
		"ball":
			var b := int(fx.ball)
			view.reveal(b, 0.3, "pop")
			TtSnd.play("tendril", -4.0)
			TtFx.grow(wfx, view.pos_of(b), art_season)
			return 0.35
		"go":
			var to2 := int(fx.to)
			if critter:
				critter.fly_to(_rest_pos(to2), 0.28, -30)
			TtSnd.play("tendril", -10.0, 1.4)
			view.hl_edges[to2] = Color(TtPal.INFO, 0.4)
			_unglow_later(to2, 0.5)
			return 0.3
		"place":
			TtSnd.play("bud_plop", -4.0)
			return 0.2
		"split_edge":
			var nn := int(fx.get("new_node", -1))
			view.reveal(nn, 0.3, "grow")
			view.pop_node(nn, 1.35)
			TtSnd.play("graft", -2.0)
			TtFx.grow(wfx, view.pos_of(nn), art_season)
			return 0.4
		"attach":
			var al := int(fx.leaf)
			view.reveal(al, 0.35, "grow")
			await get_tree().create_timer(0.3).timeout
			_pop_leaf(al)
			TtSnd.play("fruit_plop", -2.0)
			TtFx.ripen(wfx, view.fruit_center(al), art_season)
			return 0.3
		"label":
			var ln := int(fx.node)
			view.hl_be = ln
			TtSnd.play("stamp", -6.0)
			get_tree().create_timer(0.8).timeout.connect(func(): view.hl_be = -1)
			return 0.3
		"loupe":
			var lp := view.point_pos(int(fx.node), int(fx.get("off", 0)))
			view.hl_point = {"node": int(fx.node), "off": int(fx.get("off", 0))}
			TtSnd.play("loupe", -4.0)
			TtFx.ring_wave(wfx, lp, Color(TtPal.INFO, 0.9), 0.3, 2.0, 0.4)
			return 0.45
		"leaf_grow":
			view.it_cur = int(fx.get("it", view.it_cur))
			view.sync(false)
			TtSnd.play("chord_it", -6.0)
			for id in view.rn:
				if view.is_leaf(id):
					view.pop_node(id, 1.18)
			return 0.4
		"firefly":
			_move_firefly(int(fx.p), int(fx.x))
			return 0.3
		"hop":
			_move_firefly(int(fx.to), int(fx.get("x", 0)))
			TtSnd.play("ui_whoosh", -8.0, 1.5)
			return 0.35
		"link":
			view.ghost_link = {}
			TtSnd.play("link_twang", -4.0)
			TtFx.ring_wave(wfx, view.pos_of(int(fx.to)), Color("#FFE680", 0.8), 0.2, 1.4, 0.35)
			return 0.4
		"bed":
			_rebuild_beds()
			var bi := int(fx.get("bed", 0))
			var blown: Array = fx.get("blown", [])
			TtSnd.play("grow_wood", -4.0)
			if not blown.is_empty():
				TtSnd.play("ui_whoosh", -2.0)
				owl.say("Sap op: %d zaadjes waaien weg." % blown.size(), 3.0)
				shake(3.0, 0.2)
			elif bi < _bed_views.size():
				TtFx.grow(wfx, _bed_views[bi].position, art_season)
			return 0.9
		"iteration":
			var ii := int(fx.get("i", 0))
			strip.shown = ii
			strip.add_pearl_anim(ii - 1)
			TtSnd.note(str(fx.get("ch", "_")))
			TtSnd.play("pearl_tick", -6.0)
			return 0.45
	return 0.0


func _pop_leaf(id: int) -> void:
	view.pop_node(id, 0.4)


func _unglow_later(id: int, d: float) -> void:
	get_tree().create_timer(d).timeout.connect(func(): view.hl_edges.erase(id))


func _world_text(p: Vector2, s: String, col: Color) -> void:
	Juice.floater(wfx, p, s, col, 26, 40, 0.9)


func _bump_reason(reason: String, p: Vector2) -> void:
	var map := {"same_letter": "gelijk!", "before_d": "al gelezen", "no_diff": "geen verschil", "past_end": "voorbij het einde",
		"not_in_subtree": "niet onder deze top", "branching": "vertakt", "duplicate_first": "dubbel", "no_sap": "sap op",
		"occupied": "bezet", "no_letter_left": "al geplant"}
	if map.has(reason):
		_world_text(p + Vector2(0, -60), map[reason], TtPal.WARN)


func _fx_answer(fx: Dictionary) -> float:
	var found := bool(fx.get("found", false))
	var correct := bool(fx.get("correct", false))
	var wasp := bool(fx.get("wasp", false))
	var stolen := bool(fx.get("stolen", false))
	var leaf := int(model.cursor().get("leaf", -1))
	if leaf < 0 and critter:
		leaf = _nearest_leaf(critter.position)
	var fc := view.fruit_center(leaf) if view.vs.has(leaf) else (critter.position if critter else Vector2.ZERO)
	if correct and found:
		view.fruit_state[leaf] = 3
		get_tree().create_timer(1.2).timeout.connect(func(): view.fruit_state.erase(leaf))
		TtFx.found(wfx, fc)
		TtSnd.play("pick_ok", -2.0)
		get_tree().create_timer(0.25).timeout.connect(func(): TtSnd.play("honey", -4.0))
		get_tree().create_timer(0.9).timeout.connect(_hive_pulse)
		if critter:
			critter.mood = 2
			var c := critter
			c.fly_to(fc + Vector2(0, -30), 0.2, -10)
			get_tree().create_timer(0.35).timeout.connect(func():
				if is_instance_valid(c):
					c.fly_to(view.hive_pos() + Vector2(0, -40), 0.6, -140))
		return 0.7
	if correct and not found:
		if critter:
			if wasp:
				critter.striped = true
				critter.mood = 3
				TtSnd.play("wasp_reveal", -2.0)
				_flash(Color(TtPal.STAR, 0.08))
				_world_text(critter.position + Vector2(0, -80), "wesp!", TtPal.STAR)
				critter.pop(1.3, 0.8, 0.3)
				var c2 := critter
				get_tree().create_timer(0.45).timeout.connect(func():
					if is_instance_valid(c2):
						c2.leave(Vector2(1, -0.8), 0.7))
				critter = null
			else:
				critter.mood = 1
				TtSnd.play("bee_hmm", -4.0)
				critter.pop(1.1, 0.9, 0.3)
				var c3 := critter
				get_tree().create_timer(0.4).timeout.connect(func():
					if is_instance_valid(c3):
						c3.leave(Vector2(-1, -0.4), 0.8))
				critter = null
		return 0.6
	# fout
	if found and wasp and stolen:
		TtSnd.play("wasp_steal", 0.0)
		shake(4.0, 0.25)
		if critter:
			critter.striped = true
			critter.mood = 3
			critter.kind = TtCritter.K.WASP
			view.drop_nodes([leaf], "fade")
			var carried := TtCritter.new(TtCritter.K.SEED, "", letters, TtPal.season(art_season))
			carried.visible = false
			var c4 := critter
			var pts := PackedVector2Array()
			for k in 9:
				pts.append(c4.position + Vector2(k * 110, -k * 70 + (40 if k % 2 == 0 else -40)))
			c4.fly_path(pts, 1.0)
			get_tree().create_timer(1.0).timeout.connect(func():
				if is_instance_valid(c4):
					c4.queue_free())
			critter = null
		return 0.8
	if found:
		# verkeerde honing
		TtSnd.play("queen_frown", -2.0)
		shake(2.0, 0.15)
		view.queen_frown = true
		get_tree().create_timer(1.4).timeout.connect(func(): view.queen_frown = false)
		_world_text(view.hive_pos() + Vector2(0, -40) + Vector2(0, -60), "−10", TtPal.ERR)
		TtFx.burst(wfx, view.hive_pos() + Vector2(0, -40), "drop", 6, 0.6, 60, 140, Color.WHITE, 600, 0.2, 0.32, false, Vector2.UP, 70, [TtPal.SAP, TtPal.SAP_LIGHT])
		if critter:
			critter.mood = 1
			critter.fly_to(view.hive_pos() + Vector2(0, -40), 0.6, -140)
		return 0.8
	# "niet hier" bij de juiste vrucht: lege korf
	TtSnd.play("bee_hmm", -4.0, 0.8)
	if critter:
		critter.mood = 1
		var c5 := critter
		get_tree().create_timer(0.3).timeout.connect(func():
			if is_instance_valid(c5):
				c5.leave(Vector2(-1, -0.4), 0.8))
		critter = null
	return 0.6


func _hive_pulse() -> void:
	view.hive_pulse = 1.0
	var tw := create_tween()
	tw.tween_property(view, "hive_pulse", 0.0, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _nearest_leaf(p: Vector2) -> int:
	var best := -1
	var bd := 1e9
	for id in view.rn:
		if view.is_leaf(id):
			var d := view.fruit_center(id).distance_to(p)
			if d < bd:
				bd = d
				best = id
	return best


func _flash(col: Color) -> void:
	var r := ColorRect.new()
	r.color = col
	r.size = Vector2(1920, 1080)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(r)
	var tw := r.create_tween()
	tw.tween_property(r, "modulate:a", 0.0, 0.35)
	tw.tween_callback(r.queue_free)


func _move_firefly(p: int, x: int) -> void:
	if firefly == null or not is_instance_valid(firefly):
		firefly = TtCritter.new(TtCritter.K.FIREFLY, "", letters, TtPal.season(art_season))
		world.add_child(firefly)
		firefly.position = view.pos_of(model.root)
	firefly.badge = x
	var target := view.pos_of(p) + Vector2(0, -36)
	if x > 0:
		# lichtspoor: x̄ tekens verder langs de boog van het volgende teken
		pass
	firefly.fly_to(target, 0.3, -30)


func _on_honey(total: int, delta: int, _reason: String) -> void:
	hud.set_honey(total)
	if delta != 0:
		var p := critter.position if critter and is_instance_valid(critter) else view.pos_of(model.root) + Vector2(0, -80)
		Juice.floater(wfx, p + Vector2(0, -70), ("+%d" % delta) if delta > 0 else str(delta), TtPal.STAR if delta > 0 else TtPal.ERR, 30)


func _bee_dance() -> void:
	Juice.hitstop(0.08)
	TtSnd.play("bee_happy", 0.0)
	owl.say("Bijendans!", 1.5)
	for k in 6:
		var b := TtCritter.new(TtCritter.K.BEE, "", letters, TtPal.season(art_season))
		world.add_child(b)
		var c := view.content_rect().get_center()
		b.position = c
		var pts := PackedVector2Array()
		for s in 33:
			var a := s / 32.0 * TAU
			pts.append(c + Vector2(sin(a) * 260, sin(a * 2.0) * 90) + Vector2(k * 12, 0))
		b.fly_path(pts, 1.6, false)
		get_tree().create_timer(1.6).timeout.connect(b.queue_free)


func _on_expired(c: TtCard, reason: String) -> void:
	_update_queue()
	match reason:
		"patience":
			TtSnd.play("queen_frown", -6.0)
			owl.say("Die bij wachtte te lang.", 2.0)
		"blown":
			TtSnd.play("ui_whoosh", -4.0)
		"no_sap":
			TtSnd.play("bee_hmm", -6.0, 0.7)
			owl.say("Sap op: het zaadje waait weg.", 2.0)
	if model.card == null and critter:
		critter.leave(Vector2(1, -0.5), 0.6)
		critter = null
		bench.card_kind = ""
		bench.mode = ""
		bench.set_buttons([])


# ================================================================ UI-toestand per fase
func _clear_highlights() -> void:
	view.hl_node = -1
	view.hl_bud = {}
	view.hl_path = []
	view.candidates = []
	view.selectable = {}
	view.hl_point = {}
	bench.clickable = false
	bench.read_hint = -1
	bench.chosen = -1
	bench.numpad = false
	strip.clickable = false
	strip.picked = []


func _refresh_ui() -> void:
	_clear_highlights()
	if state != "play":
		return
	var c: TtCard = model.card
	if c == null:
		bench.mode = ""
		bench.set_buttons(_base_buttons())
		if swarm:
			_swarm_idle_ui()
		return
	var ph: int = model.phase
	var cur: Dictionary = model.cursor()
	var newphase := ph != _last_phase
	_last_phase = ph
	var hint: int = director.letter_hint()
	if bool(TtSave.setting("always_hint", false)):
		hint = TtCodes.Hint.FULL
	bench.hint = hint
	if c.kind == TtCodes.CardKind.SEED or c.kind == TtCodes.CardKind.BEE or c.kind == TtCodes.CardKind.PRUNE:
		bench.word = c.word
	var btns := []
	match ph:
		TtCodes.Phase.WALK:
			_ui_walk(c, cur, hint, btns, newphase)
		TtCodes.Phase.COMPARE:
			_ui_compare(c, cur, btns, newphase)
		TtCodes.Phase.AT_LEAF:
			_ui_at_leaf(c, cur, btns)
		TtCodes.Phase.CUT:
			_ui_cut(c, cur, btns)
		TtCodes.Phase.PICK_LEAF:
			_ui_pick_leaf(c, cur, btns, newphase)
		TtCodes.Phase.PRUNING:
			_ui_pruning(cur, btns)
		TtCodes.Phase.PLACING:
			_ui_placing(cur, btns)
		TtCodes.Phase.ATTACH:
			_ui_attach(c, cur, btns)
		TtCodes.Phase.LABEL:
			_ui_label(c, cur, btns)
		TtCodes.Phase.LOCATE:
			_ui_locate(c, cur, btns)
		TtCodes.Phase.ANSWER:
			_ui_answer(c, cur, btns, newphase)
		TtCodes.Phase.U_CANON, TtCodes.Phase.U_RULE, TtCodes.Phase.U_LINK, TtCodes.Phase.U_FOLLOW:
			_ui_ukkonen(ph, cur, btns)
		TtCodes.Phase.BED:
			_ui_beds(cur, btns)
		_:
			bench.mode = "info"
	btns.append_array(_base_buttons())
	bench.set_buttons(btns)
	# beestje op zijn rustplek
	if critter and is_instance_valid(critter) and not busy:
		var at := int(cur.get("node", cur.get("pack", -1)))
		if ph == TtCodes.Phase.COMPARE or ph == TtCodes.Phase.AT_LEAF:
			at = int(cur.get("leaf", at))
		if at >= 0 and view.vs.has(at):
			var rp := _rest_pos(at)
			if critter.position.distance_to(rp) > 12.0:
				critter.fly_to(rp, 0.3, -20)


func _base_buttons() -> Array:
	var out := []
	if not swarm and spec.hints_allowed and level_id != "endless":
		out.append({"id": "rewind", "text": "⟲", "kind": TtUi.Kind.GHOST, "row": 1, "w": 70, "size": 28})
	return out


func _ui_walk(c: TtCard, cur: Dictionary, hint: int, btns: Array, newphase: bool) -> void:
	var node := int(cur.get("node", cur.get("pack", model.root)))
	var dd := int(cur.get("depth", 0))
	var word := c.word
	bench.word = word
	bench.d = dd
	match kind:
		TtCodes.Kind.TRIE:
			bench.mode = "word"
			view.hl_node = node
			view.selectable = {"bud": true}
			if dd < word.length():
				if hint == TtCodes.Hint.FULL:
					bench.read_hint = dd
					view.hl_bud = {"node": node, "letter": word[dd]}
				elif hint == TtCodes.Hint.CURSOR:
					bench.read_hint = dd
			if critter:
				critter.read_pos = dd if hint != TtCodes.Hint.NONE else -1
			if c.kind == TtCodes.CardKind.SEED:
				bench.title_parts = [["Volg de letters van ", "ui"], [word, "mono"], [": klik de knop (of typ).", "ui"]]
			elif c.kind == TtCodes.CardKind.PRUNE:
				bench.title_parts = [["Zoek de vrucht ", "ui"], [word, "mono"], [" om te knippen.", "ui"]]
			else:
				bench.title_parts = [["De bij zoekt ", "ui"], [word, "mono"], [": volg haar letters.", "ui"]]
			bench.subtitle = "op diepte %d lees je letter %d" % [dd, dd]
		TtCodes.Kind.PATRICIA:
			bench.mode = "hop"
			view.hl_node = node
			var nxt := int(cur.get("next", 0))
			var rp := int(cur.get("read_pos", nxt))
			var m := int(cur.get("m", word.length() - 1))
			if newphase or hop_cursor < 0:
				hop_cursor = nxt if hint == TtCodes.Hint.NONE else clampi(rp, 0, word.length() - 1)
			hop_cursor = clampi(hop_cursor, 0, word.length() - 1)
			bench.clickable = true
			bench.clickable_from = 0
			bench.cursor = hop_cursor
			bench.d = 0
			bench.ghost_from = nxt
			bench.ghost_to = hop_cursor - 1
			if hint == TtCodes.Hint.FULL and rp <= m:
				bench.read_hint = rp
			var sk := int(cur.get("skip", 0))
			bench.title_parts = [["next = ", "ui"], [str(nxt), "mono"], ["  ·  skip = ", "ui"], [str(sk), "mono"], ["  →  welke positie lees je?", "ui"]]
			bench.subtitle = "klik een letter (←/→ + Enter) · te kort? (T)"
			btns.append({"id": "short", "text": "te kort  T", "kind": TtUi.Kind.SECONDARY, "w": 190})
			if critter:
				critter.read_pos = -1
		TtCodes.Kind.TERNARY:
			bench.mode = "ternary"
			var ball := int(cur.get("ball", -1))
			view.hl_node = ball if ball >= 0 else int(cur.get("pack", -1))
			view.selectable = {"ball": true}
			bench.ball_letter = str(model.node(ball).ch) if ball >= 0 and model.node(ball) else ""
			bench.cmp_letter = word[dd] if dd < word.length() else ""
			if hint == TtCodes.Hint.FULL and dd < word.length():
				bench.read_hint = dd
				var cmp: int = model.alphabet.compare(word[dd], bench.ball_letter)
				view.hl_bud = {"node": ball, "letter": ["lo", "eq", "hi"][cmp + 1]}
			elif hint == TtCodes.Hint.CURSOR:
				bench.read_hint = dd
			bench.title_parts = [["Vergelijk ", "ui"], [bench.cmp_letter, "mono"], [" met de bol ", "ui"], [bench.ball_letter, "mono"], [": kleiner, gelijk of groter?", "ui"]]
			bench.subtitle = "← kleiner   ·   ↑ gelijk   ·   groter →"
			btns.append({"id": "lo", "text": "← kleiner", "kind": TtUi.Kind.SECONDARY, "w": 150, "size": 24})
			btns.append({"id": "eq", "text": "= gelijk", "kind": TtUi.Kind.PRIMARY, "w": 140, "size": 24})
			btns.append({"id": "hi", "text": "groter →", "kind": TtUi.Kind.SECONDARY, "w": 150, "size": 24})


func _ui_compare(c: TtCard, cur: Dictionary, btns: Array, newphase: bool) -> void:
	var leaf := int(cur.get("leaf", -1))
	var l := str(model.node(leaf).label) if leaf >= 0 and model.node(leaf) else ""
	bench.mode = "compare"
	bench.word = l
	bench.word2 = c.word
	bench.row_names = ["vrucht", "zaadje"]
	var dd := int(cur.get("depth", 0))
	var jmin := int(cur.get("j_min", dd))
	if kind == TtCodes.Kind.PATRICIA:
		jmin = 0
		dd = 0
	bench.d = dd
	bench.clickable = true
	bench.clickable_from = jmin
	if newphase:
		compare_cursor = jmin
	bench.cursor = compare_cursor
	view.fruit_state[leaf] = 1
	_unstate_later(leaf)
	bench.title_parts = [["Waar verschillen ", "ui"], [l, "mono"], [" en ", "ui"], [c.word, "mono"], [" het eerst?", "ui"]]
	bench.subtitle = "klik de kolom j (←/→ + Enter) · gelijk? Zit er al (Z)"
	btns.append({"id": "same", "text": "Zit er al  Z", "kind": TtUi.Kind.SECONDARY, "w": 200})
	_tutorial("first_compare")


func _unstate_later(id: int) -> void:
	pass


func _ui_at_leaf(c: TtCard, cur: Dictionary, btns: Array) -> void:
	var leaf := int(cur.get("leaf", -1))
	var l := str(model.node(leaf).label) if leaf >= 0 and model.node(leaf) else ""
	bench.mode = "answer"
	bench.word = l
	bench.word2 = c.word
	bench.d = 0
	bench.row_names = ["vrucht", "bij"]
	view.fruit_state[leaf] = 1
	bench.title_parts = [["De bij is bij ", "ui"], [l, "mono"], [". Zocht ze dit woord?", "ui"]]
	bench.subtitle = "Pluk (Enter) als het hele woord klopt, anders Niet hier (N)"
	btns.append({"id": "pluck", "text": "Pluk  ⏎", "kind": TtUi.Kind.PRIMARY, "w": 170})
	btns.append({"id": "nothere", "text": "Niet hier  N", "kind": TtUi.Kind.SECONDARY, "w": 200})
	_tutorial("first_leaf")


func _ui_cut(c: TtCard, cur: Dictionary, btns: Array) -> void:
	bench.mode = "cut"
	bench.word = c.word
	bench.d = c.word.length()
	view.selectable = {"edge": true}
	var path := _path_to(int(cur.get("leaf", cur.get("node", -1))))
	view.hl_path = path
	path_cursor = clampi(path_cursor, 0, maxi(0, path.size() - 1))
	bench.title_parts = [["Knip ", "ui"], [c.word, "mono"], [" weg: welke tak knip je?", "ui"]]
	bench.subtitle = "klik een tak op het pad (↑/↓ + S) · knip onder de laatste top met twee kinderen"
	if critter:
		critter.kind = TtCritter.K.SHEARS
	_tutorial("first_cut")


func _path_to(id: int) -> Array:
	var out := []
	var cur := id
	var guard := 0
	while cur >= 0 and cur != model.root and guard < 64:
		out.push_front(cur)
		var n := model.node(cur)
		cur = n.parent if n else -1
		guard += 1
	return out


func _ui_pick_leaf(c: TtCard, cur: Dictionary, btns: Array, newphase: bool) -> void:
	bench.mode = "word"
	bench.word = c.word
	bench.d = 0
	var cand: Array = cur.get("candidates", [])
	view.candidates = cand
	view.selectable = {"fruit": true}
	if newphase:
		pick_cursor = 0
	bench.title_parts = [["Overgeslagen letters kwijt: kies een vrucht onder deze top.", "ui"]]
	bench.subtitle = "elke glanzende vrucht is goed (Tab + Enter)"
	_tutorial("first_pick")


func _ui_pruning(cur: Dictionary, btns: Array) -> void:
	bench.mode = "prune"
	bench.word = ""
	view.selectable = {"knot": true, "prune": true}
	bench.title_parts = [["Snoei: knip elke top met maar één kind. Tel de ringen.", "ui"]]
	bench.subtitle = "klik een knoest (Tab + S) · klaar? (Enter)"
	btns.append({"id": "prune_done", "text": "Klaar  ⏎", "kind": TtUi.Kind.PRIMARY, "w": 170})
	_tutorial("first_prune")


func _ui_placing(cur: Dictionary, btns: Array) -> void:
	bench.mode = "place"
	var rem: PackedStringArray = cur.get("remaining", PackedStringArray())
	bench.place_letters = Array(rem)
	bench.clickable = true
	bench.clickable_from = 0
	var pn := int(cur.get("placing_node", -1))
	view.hl_node = _pack_for_trie_node(pn)
	bench.title_parts = [["Plant de letters van deze top in een rankknoop. Volgorde?", "ui"]]
	bench.subtitle = "kleiner links, groter rechts · gebalanceerd = korte bijenvluchten"
	_tutorial("first_place")


func _pack_for_trie_node(_pn: int) -> int:
	var cur: Dictionary = model.cursor()
	return int(cur.get("pack", -1))


func _ui_attach(c: TtCard, cur: Dictionary, btns: Array) -> void:
	bench.mode = "suffix"
	var j := int(cur.get("j", c.j))
	var suf := str(cur.get("suffix", _full_text().substr(j)))
	bench.word = suf
	bench.index_offset = j + spec.pos_base
	bench.d = 0
	view.selectable = {"point": true}
	strip.hl_b = j
	strip.hl_e = _full_text().length() - 1
	bench.title_parts = [["Hang het staartje ", "ui"], [suf, "mono"], [" in de boom: waar wijkt het af?", "ui"]]
	bench.subtitle = "klik een top of een plek tussen twee parels op een boog"
	_tutorial("first_attach")


func _ui_label(c: TtCard, cur: Dictionary, btns: Array) -> void:
	bench.mode = "label"
	var j := int(cur.get("j", c.j))
	var suf := str(cur.get("suffix", _full_text().substr(j)))
	bench.word = suf
	bench.index_offset = j + spec.pos_base
	strip.clickable = true
	strip.hl_b = -1
	var pt: Dictionary = cur.get("point", {})
	var l := 0
	if not pt.is_empty() and model.has_method("point_string"):
		l = str(model.point_string(pt)).length()
	bench.title_parts = [["Nieuwe boog vanuit diepte ", "ui"], [str(l), "mono"], [": kies b op de slinger.", "ui"]]
	bench.subtitle = "e = laatste parel (automatisch)"
	_tutorial("first_label")


func _ui_locate(c: TtCard, cur: Dictionary, btns: Array) -> void:
	bench.mode = "ask"
	bench.word = ""
	view.selectable = {"point": true}
	view.show_depth = level_id == "4-4" or level_id == "4-3"
	bench.title_parts = [["Zet de loep waar ", "ui"], [c.word, "mono"], [" eindigt.", "ui"]]
	bench.subtitle = "klik het punt in de boom · komt het niet voor? (X)"
	btns.append({"id": "absent", "text": "Komt niet voor  X", "kind": TtUi.Kind.SECONDARY, "w": 260})
	_tutorial("first_locate")


func _ui_answer(c: TtCard, cur: Dictionary, btns: Array, newphase: bool) -> void:
	bench.mode = "ask"
	var q := c.q
	if newphase:
		num_value = ""
		picked_leaves = []
		picked_owners = []
	match q:
		"where":
			strip.clickable = true
			bench.title_parts = [["Waar begint ", "ui"], [c.word, "mono"], ["? Klik de parel op de slinger.", "ui"]]
			bench.subtitle = "positie = b − l_t"
		"count":
			bench.numpad = true
			bench.clickable = true
			bench.num_value = num_value
			bench.title_parts = [["Hoe vaak komt ", "ui"], [c.word, "mono"], [" voor?", "ui"]]
			bench.subtitle = "tel de vruchten onder de loep · cijfers + Enter"
			btns.append({"id": "num_ok", "text": "OK  ⏎", "kind": TtUi.Kind.PRIMARY, "w": 140})
		"all":
			view.selectable = {"fruit": true}
			view.candidates = picked_leaves
			bench.title_parts = [["Wijs alle verdachten aan voor ", "ui"], [c.word, "mono"], [".", "ui"]]
			bench.subtitle = "klik de vruchten (opnieuw = weg) · Klaar (Enter)"
			btns.append({"id": "pick_ok", "text": "Klaar  ⏎", "kind": TtUi.Kind.PRIMARY, "w": 170})
		"owner":
			bench.title_parts = [["Van wie is het spoor ", "ui"], [c.word, "mono"], ["?", "ui"]]
			bench.subtitle = "kies de eigenaar(s) · Klaar (Enter)"
			var i := 1
			for o in spec.owners_spec:
				var on := picked_owners.has(i)
				btns.append({"id": "owner_%d" % i, "text": ("✓ " if on else "") + str(o.get("name", "?")), "kind": TtUi.Kind.PRIMARY if on else TtUi.Kind.SECONDARY, "w": 120, "size": 22, "row": 0})
				i += 1
			btns.append({"id": "owner_ok", "text": "Klaar  ⏎", "kind": TtUi.Kind.SAP, "w": 150, "row": 1})
		_:
			bench.title_parts = [["Komt ", "ui"], [c.word, "mono"], [" voor?", "ui"]]


func _ui_ukkonen(ph: int, cur: Dictionary, btns: Array) -> void:
	bench.mode = "ukkonen"
	var a: Dictionary = model.active() if model.has_method("active") else {}
	bench.card_word = _full_text().substr(0, int(a.get("it", 0)))
	if _ghost_until > 0 and int(a.get("it", 99)) <= _ghost_until:
		bench.subtitle = "de Uil doet iteraties 1–%d voor: kijk mee" % _ghost_until
	strip.sigmas = model.sigmas() if model.has_method("sigmas") else []
	strip.it_i = int(a.get("i", 0)) + 1
	strip.shown = int(a.get("it", 0))
	var p := int(a.get("p", model.root))
	var x := int(a.get("x", 0))
	view.hl_node = p
	_move_firefly(p, x)
	var ch := str(a.get("ch", ""))
	bench.word = ""
	match ph:
		TtCodes.Phase.U_CANON:
			view.selectable = {"point": true}
			bench.title_parts = [["x̄ = ", "ui"], [str(x), "mono"], [" ≥ booglengte: spring naar de top aan het eind (klik).", "ui"]]
			bench.subtitle = "H = spring · klik de top aan het einde van de juiste boog"
			btns.append({"id": "hop", "text": "Spring  H", "kind": TtUi.Kind.PRIMARY, "w": 170})
			btns.append({"id": "stop", "text": "Zit er al  Z", "kind": TtUi.Kind.SECONDARY, "w": 190, "row": 1})
			btns.append({"id": "grow", "text": "Groei!  G", "kind": TtUi.Kind.SAP, "w": 160, "row": 1})
		TtCodes.Phase.U_RULE:
			bench.title_parts = [["Volgt na het vuurvliegje al ", "ui"], [ch, "mono"], ["?", "ui"]]
			bench.subtitle = "Zit er al (Z) = stop de iteratie · Groei! (G) = nieuw blad (ii) of splits (iii)"
			btns.append({"id": "hop", "text": "Spring  H", "kind": TtUi.Kind.GHOST, "w": 150})
			btns.append({"id": "stop", "text": "Zit er al  Z", "kind": TtUi.Kind.SECONDARY, "w": 190, "row": 1})
			btns.append({"id": "grow", "text": "Groei!  G", "kind": TtUi.Kind.SAP, "w": 160, "row": 1})
		TtCodes.Phase.U_LINK:
			view.selectable = {"point": true}
			var pend := int(a.get("pending", -1))
			view.ghost_link = {"from": pend, "to_pos": view.pos_of(pend) + Vector2(90, 70)}
			bench.title_parts = [["Hecht de suffix link van de nieuwe top vast: klik de doeltop.", "ui"]]
			bench.subtitle = "de top die dezelfde string zonder eerste letter voorstelt"
		TtCodes.Phase.U_FOLLOW:
			bench.title_parts = [["Volgende extensie: volg de suffix link of x − 1?", "ui"]]
			bench.subtitle = "p = wortel → x − 1 (W) · anders volg je de link (V)"
			btns.append({"id": "follow", "text": "Volg link  V", "kind": TtUi.Kind.PRIMARY, "w": 200})
			btns.append({"id": "minus", "text": "x − 1  W", "kind": TtUi.Kind.SECONDARY, "w": 160})
	if _ghost_until > 0 and int(a.get("it", 99)) <= _ghost_until:
		bench.subtitle = "de Uil doet iteraties 1–%d voor: kijk mee" % _ghost_until


var _bed_views: Array = []


func _rebuild_beds() -> void:
	for v in _bed_views:
		if is_instance_valid(v):
			v.queue_free()
	_bed_views.clear()
	if not model.has_method("bed_model"):
		return
	var n: int = model.beds.size()
	view.visible = false
	for i in n:
		var m: TtTreeModel = model.bed_model(i)
		var holder := Node2D.new()
		world.add_child(holder)
		_bed_views.append(holder)
		var lab := Node2D.new()
		var b: Dictionary = model.beds[i]
		lab.z_index = 25
		lab.draw.connect(func():
			var r := Rect2(-330, 200, 660, 70)
			lab.draw_style_box(TtPal.sb(Color(TtPal.PANEL, 0.9), 20), r)
			var ch := str(b.get("choice", ""))
			var txt := "Bed %s · |A| = %d · budget %d" % [["A", "B", "C"][i], int(b.get("size", 0)), int(b.get("budget", 0))]
			if ch != "":
				txt += " · " + ("array-boom" if ch == "array" else "rankboom") + " %d sap" % (m.sap_used() if m else 0)
			TtPal.text_c(lab, TtPal.UI_BOLD, r.get_center(), txt, 30, TtPal.TEXT))
		holder.add_child(lab)
		if m == null:
			continue
		var tv := TtTreeView.new()
		tv.show_hive = false
		holder.add_child(tv)
		tv.setup(m, m.kind, "".join(m.alphabet.letters), art_season, {})
	# naast elkaar leggen
	var x := 0.0
	var union := Rect2()
	for i in _bed_views.size():
		var h: Node2D = _bed_views[i]
		var cr := Rect2(-340, -300, 680, 600)
		for c in h.get_children():
			if c is TtTreeView:
				var tv: TtTreeView = c
				cr = cr.merge(tv.content_rect())
				for id in tv.vs:
					cr = cr.expand(tv.vs[id].target + Vector2(-90, -60)).expand(tv.vs[id].target + Vector2(90, 140))
		h.position = Vector2(x - cr.position.x, 0)
		var placed := Rect2(cr.position + h.position, cr.size)
		union = placed if i == 0 else union.merge(placed)
		x += cr.size.x + 120.0
	union = union.grow(60)
	var tr := _tree_rect()
	cam_auto = false
	_cam_zoom = clampf(minf(tr.size.x / union.size.x, tr.size.y / union.size.y) * 0.82, 0.22, 1.0)
	_cam_pos = union.get_center() - (tr.get_center() - Vector2(960, 540)) / _cam_zoom


func _ui_beds(cur: Dictionary, btns: Array) -> void:
	bench.mode = "beds"
	bench.word = ""
	if _bed_views.is_empty():
		_rebuild_beds()
	bench.title_parts = [["Oefening 20: kies per tuinbed een array-boom of een rankboom.", "ui"]]
	bench.subtitle = "het sap beslist: |A| pointers per top tegenover 3 per bol"
	var bs: Array = cur.get("beds", [])
	for i in bs.size():
		var b: Dictionary = bs[i]
		if str(b.get("choice", "")) != "" and int(b.get("blown", 0)) == 0:
			continue
		var nm: String = ["A", "B", "C"][i]
		btns.append({"id": "bed_%d_array" % i, "text": "%s: array" % nm, "kind": TtUi.Kind.SECONDARY, "w": 150, "size": 22, "row": i})
		btns.append({"id": "bed_%d_ternary" % i, "text": "%s: rank" % nm, "kind": TtUi.Kind.SAP, "w": 150, "size": 22, "row": i})


func _swarm_idle_ui() -> void:
	bench.mode = "info"
	var w: Array = director.waiting() if director.has_method("waiting") else []
	bench.title_parts = [["Wacht op de wind…", "ui"]] if w.is_empty() else [["%d kaart(en) wachten" % w.size(), "ui"]]


# ================================================================ invoer
func _on_action(id: String) -> void:
	if state != "play":
		return
	match id:
		"rewind":
			_rewind()
		"same":
			do_move({"act": "same"})
		"pluck":
			do_move({"act": "answer", "found": true})
		"nothere":
			do_move({"act": "answer", "found": false})
		"short":
			do_move({"act": "short"})
		"prune_done":
			do_move({"act": "prune_done"})
		"lo", "eq", "hi":
			do_move({"act": "go", "dir": id})
		"absent":
			do_move({"act": "absent"})
		"num_ok":
			if num_value != "":
				do_move({"act": "count", "n": int(num_value)})
		"pick_ok":
			do_move({"act": "pick", "leaves": picked_leaves.duplicate()})
		"owner_ok":
			do_move({"act": "owner", "texts": picked_owners.duplicate()})
		"hop":
			var tgt := _hop_target_guess()
			if tgt >= 0:
				do_move({"act": "hop", "node": tgt})
		"stop":
			do_move({"act": "rule", "grow": false})
		"grow":
			do_move({"act": "rule", "grow": true})
		"follow":
			do_move({"act": "follow", "mode": "link"})
		"minus":
			do_move({"act": "follow", "mode": "minus"})
		_:
			if id.begins_with("bed_"):
				var parts := id.split("_")
				do_move({"act": "bed", "bed": int(parts[1]), "choice": parts[2]})
				return
			if id.begins_with("owner_"):
				var k := int(id.substr(6))
				if picked_owners.has(k):
					picked_owners.erase(k)
				else:
					picked_owners.append(k)
				TtSnd.play("bud_plop", -6.0)
				_refresh_ui()


## "Spring" met de knop: het doel is de top aan het einde van de boog die met het volgende teken begint.
func _hop_target_guess() -> int:
	var a: Dictionary = model.active() if model.has_method("active") else {}
	var p := int(a.get("p", model.root))
	var x := int(a.get("x", 0))
	var i0 := int(a.get("i0", int(a.get("i", 1)) - 1))
	var text := _full_text()
	var first_idx := i0 - x + 1
	if first_idx < 0 or first_idx >= text.length():
		return -1
	var n := model.node(p)
	if n == null:
		return -1
	return int(n.kids.get(text[first_idx], -1))


func _on_cell(row: String, i: int) -> void:
	if state != "play" or busy or model.card == null:
		return
	match row:
		"col":
			do_move({"act": "split", "j": i})
		"s":
			if model.phase == TtCodes.Phase.WALK and kind == TtCodes.Kind.PATRICIA:
				do_move({"act": "read", "pos": i})
		"place":
			if i < bench.place_letters.size():
				do_move({"act": "place", "letter": str(bench.place_letters[i])})
		"num":
			num_value += str(i)
			if num_value.length() > 2:
				num_value = num_value.substr(num_value.length() - 2)
			bench.num_value = num_value
			TtSnd.play("letter_tick", -6.0)


func _on_pearl(i: int) -> void:
	if state != "play" or busy or model.card == null:
		return
	match model.phase:
		TtCodes.Phase.LABEL:
			do_move({"act": "label", "b": i})
		TtCodes.Phase.ANSWER:
			if model.card.q == "where":
				do_move({"act": "where", "pos": i})


func _world_click(p: Vector2) -> void:
	if state != "play" or busy or model.card == null:
		return
	var h := view.pick(p)
	if h.is_empty():
		return
	var ph: int = model.phase
	match str(h.t):
		"bud":
			if ph == TtCodes.Phase.WALK and kind == TtCodes.Kind.TRIE:
				var cur := int(model.cursor().get("node", -1))
				if int(h.node) == cur:
					do_move({"act": "move", "letter": str(h.letter)})
				else:
					view.pop_node(int(h.node), 1.06)
		"edge":
			if ph == TtCodes.Phase.CUT:
				do_move({"act": "cut", "node": int(h.id)})
		"fruit":
			if ph == TtCodes.Phase.PICK_LEAF:
				do_move({"act": "pick_leaf", "leaf": int(h.id)})
			elif ph == TtCodes.Phase.CUT:
				do_move({"act": "cut", "node": int(h.id)})
			elif ph == TtCodes.Phase.ANSWER and model.card.q == "all":
				var id := int(h.id)
				if picked_leaves.has(id):
					picked_leaves.erase(id)
				else:
					picked_leaves.append(id)
				TtSnd.play("bud_plop", -6.0, 1.2)
				view.pop_node(id, 1.2)
				_refresh_ui()
		"knot":
			if ph == TtCodes.Phase.PRUNING:
				do_move({"act": "prune", "node": int(h.id)})
		"ball":
			if ph == TtCodes.Phase.WALK:
				var curb := int(model.cursor().get("ball", -1))
				if int(h.id) == curb:
					do_move({"act": "go", "dir": str(h.dir)})
		"point":
			match ph:
				TtCodes.Phase.ATTACH:
					do_move({"act": "attach", "node": int(h.node), "off": int(h.off)})
				TtCodes.Phase.LOCATE:
					do_move({"act": "locate", "node": int(h.node), "off": int(h.off)})
				TtCodes.Phase.U_CANON:
					if int(h.off) == 0:
						do_move({"act": "hop", "node": int(h.node)})
				TtCodes.Phase.U_LINK:
					if int(h.off) == 0:
						do_move({"act": "link", "node": int(h.node)})


func _unhandled_input(ev: InputEvent) -> void:
	if state == "report" or state == "intro":
		return
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_by(1.1)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_by(1.0 / 1.1)
		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			_drag = mb.pressed
			_drag_from = mb.position
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if state == "bloom":
				_bloom_skip = true
				return
			_world_click(world.get_global_mouse_position())
	elif ev is InputEventMouseMotion:
		if _drag:
			var mm := ev as InputEventMouseMotion
			cam_auto = false
			_cam_pos -= mm.relative / _cam_zoom
		else:
			var wp := world.get_global_mouse_position()
			view.set_hover(view.pick(wp) if state == "play" and not busy else {})
			if (kind == TtCodes.Kind.SUFFIX or kind == TtCodes.Kind.UKKONEN) and not view.show_strings:
				_be_hover(view.pick(wp, {"be": true}))
	elif ev is InputEventKey and ev.pressed:
		_key(ev as InputEventKey)


## Hover op een (b,e)-bord: de parels b..e lichten op de slinger op (ook in de mist).
var _be_hovering := -1


func _be_hover(h: Dictionary) -> void:
	var id := int(h.get("id", -1)) if not h.is_empty() else -1
	if id == _be_hovering:
		return
	_be_hovering = id
	if id < 0 or not view.rn.has(id):
		view.hl_be = -1
		if model.phase != TtCodes.Phase.ATTACH:
			strip.hl_b = -1
			strip.hl_e = -1
		return
	var d: Dictionary = view.rn[id]
	view.hl_be = id
	strip.hl_b = int(d.get("b", -1))
	var e := int(d.get("e_now", d.get("e", -1)))
	strip.hl_e = e if e >= 0 else _full_text().length() - 1
	TtSnd.play("pearl_tick", -12.0, 1.3)


func _key(k: InputEventKey) -> void:
	var code := k.keycode
	if code == KEY_ESCAPE:
		if state == "play" or state == "bloom":
			_open_pause()
		return
	if state == "bloom" and code == KEY_SPACE:
		_bloom_skip = true
		return
	if code == KEY_0 or code == KEY_KP_0:
		if not (model.card and model.phase == TtCodes.Phase.ANSWER):
			cam_auto = true
			return
	if code == KEY_PLUS or code == KEY_KP_ADD or code == KEY_EQUAL:
		_zoom_by(1.12)
		return
	if code == KEY_MINUS and not (model.card and model.phase == TtCodes.Phase.WALK and letters.contains("_")):
		_zoom_by(1.0 / 1.12)
		return
	if state != "play" or busy or model.card == null:
		return
	if code == KEY_F1:
		_hint()
		return
	if code == KEY_Z and k.ctrl_pressed:
		_rewind()
		return
	var ch := _key_char(k)
	var ph: int = model.phase
	match ph:
		TtCodes.Phase.WALK:
			match kind:
				TtCodes.Kind.TRIE:
					if ch != "":
						do_move({"act": "move", "letter": ch})
				TtCodes.Kind.PATRICIA:
					var w := model.card.word
					if code == KEY_RIGHT:
						hop_cursor = mini(hop_cursor + 1, w.length() - 1)
						TtSnd.play("letter_tick", -12.0, 1.4)
						_refresh_ui()
					elif code == KEY_LEFT:
						hop_cursor = maxi(hop_cursor - 1, 0)
						TtSnd.play("letter_tick", -12.0, 1.2)
						_refresh_ui()
					elif code == KEY_ENTER or code == KEY_KP_ENTER:
						do_move({"act": "read", "pos": hop_cursor})
					elif code == KEY_T:
						do_move({"act": "short"})
				TtCodes.Kind.TERNARY:
					if code == KEY_LEFT:
						do_move({"act": "go", "dir": "lo"})
					elif code == KEY_RIGHT:
						do_move({"act": "go", "dir": "hi"})
					elif code == KEY_UP or code == KEY_ENTER or code == KEY_KP_ENTER:
						do_move({"act": "go", "dir": "eq"})
		TtCodes.Phase.COMPARE:
			var n := maxi(bench.word.length(), bench.word2.length())
			if code == KEY_RIGHT:
				compare_cursor = mini(compare_cursor + 1, n - 1)
				TtSnd.play("letter_tick", -12.0, 1.4)
				bench.cursor = compare_cursor
			elif code == KEY_LEFT:
				compare_cursor = maxi(compare_cursor - 1, bench.clickable_from)
				TtSnd.play("letter_tick", -12.0, 1.2)
				bench.cursor = compare_cursor
			elif code == KEY_ENTER or code == KEY_KP_ENTER:
				do_move({"act": "split", "j": compare_cursor})
			elif code == KEY_Z:
				do_move({"act": "same"})
		TtCodes.Phase.AT_LEAF:
			if code == KEY_ENTER or code == KEY_KP_ENTER or code == KEY_J:
				do_move({"act": "answer", "found": true})
			elif code == KEY_N or code == KEY_BACKSPACE:
				do_move({"act": "answer", "found": false})
		TtCodes.Phase.CUT:
			var path := _path_to(int(model.cursor().get("leaf", -1)))
			if code == KEY_UP:
				path_cursor = mini(path_cursor + 1, path.size() - 1)
			elif code == KEY_DOWN:
				path_cursor = maxi(path_cursor - 1, 0)
			elif code == KEY_S and path_cursor < path.size():
				do_move({"act": "cut", "node": int(path[path_cursor])})
			if path_cursor < path.size():
				view.hl_edges.clear()
				view.hl_edges[int(path[path_cursor])] = Color(TtPal.WARN, 0.4)
		TtCodes.Phase.PICK_LEAF:
			var cand: Array = model.cursor().get("candidates", [])
			if code == KEY_TAB and not cand.is_empty():
				pick_cursor = (pick_cursor + 1) % cand.size()
				view.set_hover({"t": "fruit", "id": int(cand[pick_cursor])})
			elif (code == KEY_ENTER or code == KEY_KP_ENTER) and not cand.is_empty():
				do_move({"act": "pick_leaf", "leaf": int(cand[pick_cursor % cand.size()])})
		TtCodes.Phase.PRUNING:
			var un: Array = model.unary_nodes() if model.has_method("unary_nodes") else []
			if code == KEY_TAB and not un.is_empty():
				pick_cursor = (pick_cursor + 1) % un.size()
				view.set_hover({"t": "knot", "id": int(un[pick_cursor])})
			elif code == KEY_S and not un.is_empty():
				do_move({"act": "prune", "node": int(un[pick_cursor % un.size()])})
			elif code == KEY_ENTER or code == KEY_KP_ENTER:
				do_move({"act": "prune_done"})
		TtCodes.Phase.PLACING:
			if ch != "" and bench.place_letters.has(ch):
				do_move({"act": "place", "letter": ch})
		TtCodes.Phase.LOCATE:
			if code == KEY_X:
				do_move({"act": "absent"})
		TtCodes.Phase.ANSWER:
			if model.card.q == "count":
				if code >= KEY_0 and code <= KEY_9:
					_on_cell("num", code - KEY_0)
				elif code == KEY_BACKSPACE:
					num_value = num_value.substr(0, maxi(0, num_value.length() - 1))
					bench.num_value = num_value
				elif (code == KEY_ENTER or code == KEY_KP_ENTER) and num_value != "":
					do_move({"act": "count", "n": int(num_value)})
			elif code == KEY_ENTER or code == KEY_KP_ENTER:
				if model.card.q == "all":
					do_move({"act": "pick", "leaves": picked_leaves.duplicate()})
				elif model.card.q == "owner":
					do_move({"act": "owner", "texts": picked_owners.duplicate()})
		TtCodes.Phase.U_CANON, TtCodes.Phase.U_RULE, TtCodes.Phase.U_LINK, TtCodes.Phase.U_FOLLOW:
			match code:
				KEY_H:
					_on_action("hop")
				KEY_Z:
					_on_action("stop")
				KEY_G:
					_on_action("grow")
				KEY_V:
					_on_action("follow")
				KEY_W:
					_on_action("minus")


func _key_char(k: InputEventKey) -> String:
	if k.unicode == 0:
		if k.keycode == KEY_SPACE:
			return "_" if letters.contains("_") else ""
		return ""
	var s := char(k.unicode)
	if s == "-" or s == " ":
		s = "_"
	if letters.contains(s):
		return s
	if letters.contains(s.to_upper()):
		return s.to_upper()
	if letters.contains(s.to_lower()):
		return s.to_lower()
	return ""


# ================================================================ hint, terugspoelen, tutorial
func _hint() -> void:
	if state != "play" or busy or model.card == null or not spec.hints_allowed or swarm:
		return
	var mv: Dictionary = director.hint()
	used_hint = true
	TtSnd.play("owl", -4.0)
	_show_ghost(mv)
	owl.say(_hint_text(mv), 3.5)


func _hint_text(mv: Dictionary) -> String:
	match str(mv.get("act", "")):
		"move":
			return "Knop %s." % str(mv.letter)
		"split":
			return "Het eerste verschil staat op %d." % int(mv.j)
		"same":
			return "Die woorden zijn gelijk."
		"answer":
			return "Pluk!" if bool(mv.found) else "Niet hier: vergelijk het hele woord."
		"read":
			return "Lees positie %d." % int(mv.pos)
		"short":
			return "Het lint is te kort."
		"cut":
			return "Knip daar."
		"prune":
			return "Die top heeft maar één kind."
		"prune_done":
			return "Alles is gesnoeid."
		"go":
			return {"lo": "Kleiner: links.", "eq": "Gelijk: rechtdoor.", "hi": "Groter: rechts."}.get(str(mv.dir), "")
		"place":
			return "Plant eerst %s." % str(mv.letter)
		"attach":
			return "Daar wijkt het af."
		"label":
			return "b = j + l = %d." % (int(mv.b) + spec.pos_base)
		"locate":
			return "Daar eindigt het."
		"absent":
			return "Het komt niet voor."
		"where":
			return "b − l_t = %d." % (int(mv.pos) + spec.pos_base)
		"count":
			return "Tel de vruchten: %d." % int(mv.n)
		"rule":
			return "Groei!" if bool(mv.grow) else "Zit er al: stop."
		"hop":
			return "Spring naar de top."
		"follow":
			return "Volg de link." if str(mv.mode) == "link" else "Bij de wortel: x − 1."
		"link":
			return "Hecht hem daar."
	return "Kijk goed…"


func _resolve_path(path: String) -> Dictionary:
	for id in view.rn:
		var d: Dictionary = view.rn[id]
		if str(d.get("path", d.get("string", "#"))) == path:
			return {"node": id, "off": 0}
	for id in view.rn:
		var d2: Dictionary = view.rn[id]
		var s := str(d2.get("string", ""))
		var e := str(d2.get("edge", ""))
		if s.begins_with(path) and s.length() - e.length() < path.length():
			return {"node": id, "off": path.length() - (s.length() - e.length())}
	return {}


func _show_ghost(mv: Dictionary) -> void:
	if mv.has("path") and not mv.has("node"):
		mv = mv.duplicate()
		mv.merge(_resolve_path(str(mv.path)))
		if not mv.has("node"):
			return
	var p := Vector2(-1, -1)
	match str(mv.get("act", "")):
		"move":
			p = _w2s(view.bud_top(int(model.cursor().get("node", model.root)), str(mv.letter)))
		"split":
			p = _bench_col_pos(int(mv.j))
		"read":
			p = _bench_word_pos(int(mv.pos))
		"cut":
			var e := view.edge_pts(int(mv.node))
			p = _w2s(TtDraw.path_point(e, 0.4) if e.size() > 1 else view.pos_of(int(mv.node)))
		"prune":
			p = _w2s(view.pos_of(int(mv.node)))
		"pick_leaf":
			p = _w2s(view.fruit_center(int(mv.leaf)))
		"attach", "locate":
			p = _w2s(view.point_pos(int(mv.node), int(mv.get("off", 0))))
		"hop", "link":
			p = _w2s(view.pos_of(int(mv.node)))
		"label", "where":
			p = strip.pearl_pos(int(mv.get("b", mv.get("pos", 0))))
		"go":
			var ball := int(model.cursor().get("ball", -1))
			var off: Vector2 = {"lo": Vector2(-44, -16), "eq": Vector2(0, -44), "hi": Vector2(44, -16)}.get(str(mv.dir), Vector2.ZERO)
			p = _w2s(view.pos_of(ball) + off)
		_:
			var id := _button_for(mv)
			var b := bench.button(id)
			if b:
				p = b.global_position + b.size / 2.0
	if p.x >= 0:
		hand.tap(p)


func _button_for(mv: Dictionary) -> String:
	match str(mv.get("act", "")):
		"same":
			return "same"
		"answer":
			return "pluck" if bool(mv.found) else "nothere"
		"short":
			return "short"
		"prune_done":
			return "prune_done"
		"absent":
			return "absent"
		"rule":
			return "grow" if bool(mv.grow) else "stop"
		"follow":
			return "follow" if str(mv.mode) == "link" else "minus"
		"count":
			return "num_ok"
		"pick":
			return "pick_ok"
		"owner":
			return "owner_ok"
	return ""


func _bench_col_pos(j: int) -> Vector2:
	for c in bench._cells:
		if c.row == "col" and int(c.i) == j:
			return (c.rect as Rect2).get_center()
	return Vector2(860, 990)


func _bench_word_pos(i: int) -> Vector2:
	for c in bench._cells:
		if c.row == "s" and int(c.i) == i:
			return (c.rect as Rect2).get_center()
	return Vector2(860, 990)


func _rewind() -> void:
	if swarm or busy or state != "play":
		return
	if director.rewind():
		TtSnd.play("ui_whoosh", -4.0, 0.8)
		used_hint = true
		if critter and is_instance_valid(critter):
			critter.queue_free()
		critter = null
		view.dying.clear()
		view.vs.clear()
		view.rn.clear()
		view.sync(true)
		hud.set_sap(model.sap_used(), model.sap_budget)
		_update_queue()
		if model.card != null:
			await _card_arrival(model.card)
		else:
			_next_card()


func _tutorial(trigger: String, card_idx := -1) -> void:
	var key := trigger + str(card_idx)
	if _tut_done.has(key) or bot != null:
		return
	for tu in spec.tutorial:
		if str(tu.get("trigger", "")) == trigger and (card_idx < 0 or int(tu.get("card", -1)) == card_idx):
			_tut_done[key] = true
			var txt := str(tu.get("text", ""))
			if txt != "":
				owl.say(txt, 4.5)
			var gh: Dictionary = tu.get("ghost", {})
			if not gh.is_empty():
				await get_tree().create_timer(0.4).timeout
				_show_ghost(gh)
			return


# ================================================================ camera
func _min_zoom() -> float:
	if state == "bloom":
		return 0.3
	return 0.5 if kind == TtCodes.Kind.TRIE else 0.45


func _tree_rect() -> Rect2:
	if kind == TtCodes.Kind.UKKONEN:
		return TREE_RECT_UKK
	if kind == TtCodes.Kind.SUFFIX:
		return TREE_RECT_STR
	return TREE_RECT


func _fit_camera(instant: bool) -> void:
	if not cam_auto:
		return
	var r := view.content_rect().grow_individual(80, 30, 80, 30)
	var tr := _tree_rect()
	var z := minf(tr.size.x / maxf(r.size.x, 1.0), tr.size.y / maxf(r.size.y, 1.0))
	var fits := z >= _min_zoom()
	z = clampf(z, _min_zoom(), 1.2)
	# camera-midden zodat r.center op tr.center staat
	var focus := r.get_center()
	if not fits:
		# te grote boom: volg de actieve top (beestje), binnen de randen van de boom
		var fp := focus
		if critter and is_instance_valid(critter):
			fp = critter.position
		elif model.card != null:
			var cid := int(model.cursor().get("node", model.cursor().get("leaf", -1)))
			if view.vs.has(cid):
				fp = view.pos_of(cid)
		var half := tr.size / z / 2.0
		focus.x = clampf(fp.x, r.position.x + half.x, maxf(r.end.x - half.x, r.position.x + half.x))
		focus.y = clampf(fp.y, r.position.y + half.y, maxf(r.end.y - half.y, r.position.y + half.y))
	var center := focus - (tr.get_center() - Vector2(960, 540)) / z
	_cam_zoom = z
	_cam_pos = center
	if instant:
		cam.position = _cam_pos
		cam.zoom = Vector2(z, z)


func _zoom_by(f: float) -> void:
	cam_auto = false
	_cam_zoom = clampf(_cam_zoom * f, 0.4, 1.6)


func _w2s(p: Vector2) -> Vector2:
	return world.get_viewport().get_canvas_transform() * p


func _screen_to_world(p: Vector2) -> Vector2:
	return world.get_viewport().get_canvas_transform().affine_inverse() * p


# ================================================================ frame
func _process(delta: float) -> void:
	if TtSession.has("fps") and int(t + delta) != int(t) and int(t) % 3 == 0:
		print("fps %d" % Engine.get_frames_per_second())
	t += delta
	idle_t += delta
	TtSession.qa_tick(self, delta)
	if cam_auto and state != "report":
		_fit_camera(false)
	var k := 1.0 - exp(-delta * 5.0)
	cam.position = cam.position.lerp(_cam_pos, k)
	var z := lerpf(cam.zoom.x, _cam_zoom, k)
	cam.zoom = Vector2(z, z)
	_shake_tick(delta)
	if state == "play":
		if director.has_method("tick"):
			director.tick(delta)
		if swarm:
			_swarm_tick()
			_update_queue()
		if not busy and _shown_card != null and model.card == null:
			_shown_card = null
			_after_move({"done": true})
		if model.card != null and model.card.patience > 0.0 and model.card.started_at >= 0.0:
			var since: float = model.card.t if swarm else model.card.started_at
			var frac := clampf(1.0 - (director.time - since) / model.card.patience, 0.0, 1.0)
			hedge.patience = frac if model.card.kind == TtCodes.CardKind.ASK else -1.0
		else:
			hedge.patience = -1.0
		if _ghost_until > 0 and bot == null and not busy and model.card != null and kind == TtCodes.Kind.UKKONEN:
			var it := int(model.active().get("it", 99))
			if it <= _ghost_until:
				_ghost_t += delta
				if _ghost_t > 1.5:
					_ghost_t = 0.0
					var gm := model.correct_move()
					_show_ghost(gm)
					get_tree().create_timer(0.75).timeout.connect(func(): do_move(gm))
			elif _ghost_until > 0:
				_ghost_until = 0
				owl.say("Nu jij!", 2.5)
		elif bot and not busy and model.card != null:
			bot_t += delta
			if bot_t > bot_delay:
				bot_t = 0.0
				var mv := bot.choose(model)
				if not mv.is_empty() and str(mv.get("act", "none")) != "none":
					do_move(mv)
		elif not busy and model.card != null and idle_t > 5.0 and not used_hint and _first_card and bot == null:
			idle_t = -999.0
			_tutorial("idle")
	if level_id == "endless":
		hud.lives = maxi(0, 3 - director.misses)
	if level_id == "endless" and director.get("time") != null:
		var s := int(director.time)
		hud.clock_label = "%d:%02d" % [s / 60, s % 60]


func _swarm_tick() -> void:
	if busy:
		return
	if director.finished or director.all_done():
		if state == "play":
			_start_bloom()
		return
	if model.card == null:
		var w: Array = director.waiting() if director.has_method("waiting") else []
		if not w.is_empty():
			var c: TtCard = director.next_card()
			_update_queue()
			if c:
				_card_arrival(c)


# ================================================================ Bloei
func _start_bloom() -> void:
	if state == "bloom" or state == "report":
		return
	state = "bloom"
	_clear_highlights()
	bench.set_buttons([])
	bench.card_kind = ""
	bench.mode = "bloom"
	bench.word = ""
	bench.title_parts = [["Bloei! De zwerm test je boom.", "ui"]]
	bench.subtitle = "spatie = overslaan"
	if critter and is_instance_valid(critter):
		critter.queue_free()
	critter = null
	if firefly and is_instance_valid(firefly):
		firefly.queue_free()
	hedge.visible = false
	cam_auto = _bed_views.is_empty()
	if spec.endless:
		TtSnd.play("queen_frown", -4.0)
		owl.say("Drie missers: de tuin sluit.", 2.5)
		await get_tree().create_timer(1.6).timeout
		_finish_level()
		return
	TtSnd.play("bloom", -2.0)
	TtSnd.bloom_layer(true)
	_bloom_results = director.run_bloom()
	view.sync(false)
	view.reveal_all_now()
	# bloesemgolf van wortel naar kruin
	var leaves := []
	for id in view.rn:
		if view.is_leaf(id):
			leaves.append(id)
	leaves.sort_custom(func(a, b): return view.pos_of(a).y > view.pos_of(b).y)
	var k := 0
	for id in leaves:
		var idd: int = id
		get_tree().create_timer(0.04 * k).timeout.connect(func():
			view.pop_node(idd, 1.2)
			TtFx.ripen(wfx, view.fruit_center(idd), art_season))
		k += 1
	await get_tree().create_timer(0.5 + 0.04 * k).timeout
	var running := 0
	var idx := 0
	for r in _bloom_results:
		if _bloom_skip:
			break
		_bloom_bee(r, idx)
		idx += 1
		await get_tree().create_timer(0.22).timeout
	if not _bloom_skip:
		await get_tree().create_timer(1.6).timeout
	for r in _bloom_results:
		if not bool(r.get("ok", true)) and bool(r.get("expected", true)):
			var e := int(r.get("end", -1))
			_grey_misplaced(str(r.get("word", "")))
	await get_tree().create_timer(0.6).timeout
	_finish_level()


func _grey_misplaced(word: String) -> void:
	for id in view.rn:
		if view.is_leaf(id) and str(view.rn[id].get("label", "")) == word:
			if view.rn[id].get("misplaced", false):
				view.set_grey(id, true)
				TtFx.burst(wfx, view.fruit_center(id), "dot", 3, 1.2, 20, 40, Color(0.2, 0.2, 0.2, 0.8), -10, 0.1, 0.18)
				TtSnd.play("rot", -8.0)


func _bloom_bee(r: Dictionary, idx: int) -> void:
	var path: Array = r.get("path", [])
	var b := TtCritter.new(TtCritter.K.BEE, str(r.get("word", "")), letters, TtPal.season(art_season))
	b.label_on = false
	world.add_child(b)
	var start := view.hive_pos() + Vector2(0, -40)
	b.position = start
	var pts := PackedVector2Array([start])
	for id in path:
		var iid := int(id)
		if not view.vs.has(iid):
			continue
		var e := view.edge_pts(iid)
		for p in e:
			pts.append(p + Vector2(0, -24))
		if view.is_leaf(iid):
			pts.append(view.fruit_center(iid) + Vector2(0, -30))
	var dur := 0.6 + 0.08 * pts.size() / 12.0
	b.fly_path(pts, dur, false)
	var ok := bool(r.get("ok", true))
	TtSnd.play("buzz_soft", -14.0, 1.0 + 0.05 * idx)
	get_tree().create_timer(dur).timeout.connect(func():
		if not is_instance_valid(b):
			return
		if ok:
			b.mood = 2
			var end := int(r.get("end", -1))
			if view.vs.has(end) and view.is_leaf(end):
				view.fruit_state[end] = 3
				TtFx.found(wfx, view.fruit_center(end))
			TtSnd.play("bee_bell", -6.0, pow(2.0, mini(idx, 12) / 12.0))
			b.fly_to(view.hive_pos() + Vector2(0, -40), 0.7, -160)
			get_tree().create_timer(0.7).timeout.connect(b.queue_free)
		else:
			b.mood = 1
			TtSnd.play("bee_hmm", -6.0)
			TtFx.poof(wfx, b.position)
			b.leave(Vector2(-1, 0.3), 1.0))
	_bloom_icons.append(ok)


func _finish_level() -> void:
	var rep: Dictionary = director.finish()
	state = "report"
	var n := int(rep.get("n_stars", 0))
	TtSession.map_stars_before = TtSave.all_stars().duplicate()
	if level_id != "endless":
		TtSave.set_stars(level_id, n)
		TtSave.set_best(level_id, int(rep.get("honey", 0)))
		TtSession.map_focus = level_id
	TtSnd.bloom_layer(true)
	TtSnd.jingle(maxi(1, n))
	TtSnd.duck(true)
	var tw := create_tween()
	tw.tween_property(ui.get_child(0), "modulate:a", 0.0, 0.4)
	_report = TtReport.new()
	_report.setup(self, rep, spec, level_id)
	overlay.add_child(_report)


# ================================================================ pauze
func _open_pause() -> void:
	if _pause_menu or state == "report":
		return
	var prev := state
	state = "paused"
	get_tree().paused = false
	_pause_menu = TtPauseMenu.new()
	_pause_menu.setup(level_id, season)
	overlay.add_child(_pause_menu)
	TtSnd.duck(true)
	_pause_menu.closed.connect(_on_pause_closed.bind(prev))


func _on_pause_closed(choice: String, prev: String) -> void:
	_pause_menu = null
	TtSnd.duck(false)
	state = prev
	_apply_settings()
	match choice:
		"restart":
			restart()
		"map", "quit":
			goto_map()


func restart() -> void:
	Engine.time_scale = 1.0
	Transition.goto(TtSession.SCENE_GARDEN)


func goto_map() -> void:
	Engine.time_scale = 1.0
	Transition.goto(TtSession.SCENE_MAP)


func goto_next() -> void:
	Engine.time_scale = 1.0
	var nxt := TtLevels.next_id(level_id, TtLevels.ids())
	if nxt != "" and TtLevels.is_unlocked(nxt, TtSave.all_stars(), TtLevels.ids()):
		TtSession.level_id = nxt
		Transition.goto(TtSession.SCENE_GARDEN)
	else:
		goto_map()


## Schermschok (eigen versie: Juice zou de camerazoom overschrijven). Schaalt met de instelling.
var _sh_amp := 0.0
var _sh_t := 0.0
var _sh_dur := 0.0
var _sh_noise := FastNoiseLite.new()


func shake(px: float, dur := 0.25) -> void:
	px *= Juice.shake_scale
	if px <= 0.0:
		return
	if px >= _sh_amp * (1.0 - _sh_t / maxf(_sh_dur, 0.001)):
		_sh_amp = px
		_sh_dur = dur
		_sh_t = 0.0


func _shake_tick(delta: float) -> void:
	var off := Vector2.ZERO
	if _sh_amp > 0.0:
		_sh_t += delta
		var k := 1.0 - _sh_t / maxf(_sh_dur, 0.001)
		if k <= 0.0:
			_sh_amp = 0.0
		else:
			var a := _sh_amp * k * k
			off = Vector2(_sh_noise.get_noise_2d(t * 60.0, 0.0), _sh_noise.get_noise_2d(0.0, t * 60.0 + 100.0)) * a * 1.6
	cam.offset = off / maxf(cam.zoom.x, 0.1)


func _exit_tree() -> void:
	if director:
		director.dispose()
	Juice.camera = null


func _question_text(c: TtCard) -> String:
	match c.q:
		"exists":
			return "Komt %s voor?" % c.word
		"where":
			return "Waar komt %s voor?" % c.word
		"first":
			return "Waar komt %s eerst voor?" % c.word
		"count":
			return "Hoe vaak komt %s voor?" % c.word
		"all":
			return "Alle verdachten voor %s?" % c.word
		"owner":
			return "Van wie is het spoor %s?" % c.word
	return "%s?" % c.word
