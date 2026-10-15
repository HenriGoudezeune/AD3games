class_name TxFx
extends Object
## TELEX-juice: partikel-bursts met de eigen texturen (assets/art/particles), floaters, ringen en gloed.
## Schermschok, camera-punch en hitstop via de autoload Juice (die schaalt met de instelling schermschok).

const PT := "particles/%s.png"


static func burst(parent: Node, pos: Vector2, tex_name: String, amount: int, life: float, vmin: float, vmax: float,
		col: Color, gravity := 0.0, smin := 0.3, smax := 0.6, add := false, dir := Vector2.UP, spread := 180.0,
		colors: Array = [], spin := true) -> CPUParticles2D:
	if parent == null or not is_instance_valid(parent):
		return null
	var p := CPUParticles2D.new()
	p.texture = TxPal.tex(PT % tex_name)
	p.amount = maxi(1, amount)
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 0.95
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = vmin
	p.initial_velocity_max = vmax
	p.gravity = Vector2(0, gravity)
	p.scale_amount_min = smin
	p.scale_amount_max = smax
	if spin:
		p.angle_min = -180
		p.angle_max = 180
		p.angular_velocity_min = -360 if gravity > 0 else -60
		p.angular_velocity_max = 360 if gravity > 0 else 60
	p.damping_min = 20 if gravity == 0 else 0
	p.damping_max = 60 if gravity == 0 else 0
	p.color = col
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.65, Color(1, 1, 1, 0.85))
	p.color_ramp = g
	if not colors.is_empty():
		var gi := Gradient.new()
		var offs := PackedFloat32Array()
		var cols := PackedColorArray()
		for i in colors.size():
			offs.append(float(i) / colors.size())
			cols.append(colors[i])
		gi.offsets = offs
		gi.colors = cols
		gi.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
		p.color_initial_ramp = gi
	if add:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		p.material = m
	p.position = pos
	p.z_index = 40
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


## Vonken (klem, botsende tanden).
static func sparks(parent: Node, pos: Vector2, amount := 8) -> void:
	burst(parent, pos, "spark", amount, 0.35, 180, 360, Color.WHITE, 700, 0.25, 0.5, true, Vector2.UP, 75, [TxPal.SIG_AMBER, TxPal.HEAT, TxPal.SIG_WHITE])


## Papierrondjes van de ponsmachine.
static func punch_dots(parent: Node, pos: Vector2, amount := 6) -> void:
	burst(parent, pos, "punch_dot", amount, 0.7, 120, 260, Color.WHITE, 900, 0.35, 0.6, false, Vector2.UP, 60, [TxPal.MANILA, TxPal.PAPER, TxPal.MANILA_LO])


## Snippers uit de versnipperaar (rood bij een gemist codewoord).
static func snippets(parent: Node, pos: Vector2, amount := 12, red := false) -> void:
	var cols := [TxPal.PAPER, TxPal.PAPER_SHADE, TxPal.PAPER_HI]
	if red:
		cols = [TxPal.SIG_NE, TxPal.PAPER, TxPal.STAMP_RED]
	burst(parent, pos, "snipper", amount, 0.9, 60, 180, Color.WHITE, 600, 0.35, 0.7, false, Vector2.DOWN, 50, cols)


static func dust(parent: Node, pos: Vector2, amount := 6) -> void:
	burst(parent, pos, "dust", amount, 0.55, 30, 90, Color(TxPal.PAPER_SHADE, 0.7), -30, 0.3, 0.6, false, Vector2.UP, 80)


static func smoke(parent: Node, pos: Vector2, amount := 3) -> void:
	burst(parent, pos, "smoke", amount, 1.4, 10, 40, Color(0.35, 0.33, 0.3, 0.6), -40, 0.3, 0.7, false, Vector2.UP, 25)


static func straw(parent: Node, pos: Vector2, amount := 24) -> void:
	burst(parent, pos, "straw", amount, 1.3, 160, 420, Color.WHITE, 650, 0.4, 0.8, false, Vector2.UP, 70, [Color("#E5C36A"), Color("#C9A24B"), Color("#F0DA95")])


static func ink(parent: Node, pos: Vector2, col: Color, amount := 7) -> void:
	burst(parent, pos, "ink_splat", amount, 0.45, 80, 200, col, 300, 0.15, 0.35, false, Vector2.UP, 180)


static func splinters(parent: Node, pos: Vector2, amount := 10) -> void:
	burst(parent, pos, "splinter", amount, 0.8, 150, 380, Color.WHITE, 900, 0.3, 0.6, false, Vector2.UP, 70, [TxPal.PAPER, TxPal.PAPER_SHADE])


## Treffer-glinster (groen, additief).
static func glints(parent: Node, pos: Vector2, col := TxPal.SIG_EQ, amount := 10) -> void:
	burst(parent, pos, "spark", amount, 0.5, 80, 220, col, 0, 0.2, 0.45, true, Vector2.UP, 180)


## Expanderende ring.
static func ring(parent: Node, pos: Vector2, col: Color, from_s := 0.2, to_s := 2.4, dur := 0.4) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var s := Sprite2D.new()
	s.texture = TxPal.tex(PT % "ring")
	s.modulate = col
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = m
	s.position = pos
	s.scale = Vector2(from_s, from_s)
	s.z_index = 45
	parent.add_child(s)
	var tw := s.create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector2(to_s, to_s), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(s.queue_free)


static func flash(parent: Node, pos: Vector2, col: Color, size := 1.0, dur := 0.35) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var s := Sprite2D.new()
	s.texture = TxPal.tex(PT % "glow")
	s.modulate = col
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = m
	s.position = pos
	s.scale = Vector2(size, size)
	s.z_index = 44
	parent.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
	tw.tween_callback(s.queue_free)


## Getypte tekst die opstijgt (punten, "+10", "klem").
static func floater(parent: Node, pos: Vector2, text: String, col: Color, size := 30, rise := 46.0, dur := 0.8) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", TxPal.UI_BOLD)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", TxPal.NIGHT)
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 60
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	l.reset_size()
	l.pivot_offset = l.size / 2.0
	l.position = pos - l.size / 2.0
	l.scale = Vector2(0.4, 0.4)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y - rise, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, dur * 0.45).set_delay(dur * 0.55)
	tw.chain().tween_callback(l.queue_free)


static func shake(px: float, dur := 0.2) -> void:
	var j := TxSession._node("Juice")
	if j != null:
		j.shake(px, dur)


static func punch(amount := 0.012) -> void:
	var j := TxSession._node("Juice")
	if j != null:
		j.punch(amount)


static func hitstop(sec := 0.08) -> void:
	var j := TxSession._node("Juice")
	if j != null:
		j.hitstop(sec)
