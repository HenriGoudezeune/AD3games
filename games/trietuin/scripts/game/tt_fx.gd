class_name TtFx
extends Object
## Trietuin: partikel-recepten (design/ART.md §6.3). CPUParticles2D (werkt in GL Compatibility).
## Texturen zijn wit (assets/art/particles/), kleur via `color` / ramp. Gedeelde texturen van Hash & Dash
## (glow, ring, sparkle, star, puff) worden via res://assets/art/particles/ hergebruikt.


static func _shared(name_: String) -> Texture2D:
	var p := "res://assets/art/particles/%s.png" % name_
	return load(p) if ResourceLoader.exists(p) else null


static func _tex(name_: String) -> Texture2D:
	var t := TtPal.particle(name_)
	return t if t else _shared(name_)


static func _fade_ramp(peak := 0.15) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(peak, Color(1, 1, 1, 1))
	g.add_point(0.75, Color(1, 1, 1, 0.85))
	return g


static func _add_mat() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


## Sfeerdeeltjes over het hele scherm per seizoen: lente bloemblaadjes, zomer stuifmeel, herfst bladeren,
## winter sneeuw. Zet hem achter de boom (z_index laag) en eventueel een tweede, kleinere laag ervoor.
static func ambient(parent: Node, season: int, rect := Rect2(0, 0, 1920, 1080), density := 1.0) -> CPUParticles2D:
	var se := TtPal.season(season)
	var p := CPUParticles2D.new()
	p.texture = _tex(se.particle)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(rect.size.x * 0.6, 10)
	p.position = Vector2(rect.get_center().x + rect.size.x * 0.1, rect.position.y - 30)
	p.lifetime = 14.0
	p.preprocess = 14.0
	p.amount = int(28 * density)
	p.direction = Vector2(-0.35, 1)
	p.spread = 18
	p.gravity = Vector2(0, 14)
	p.initial_velocity_min = 40
	p.initial_velocity_max = 80
	p.angle_min = -180
	p.angle_max = 180
	p.angular_velocity_min = -70
	p.angular_velocity_max = 70
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.7
	p.color = se.particle_col
	p.color_ramp = _fade_ramp(0.06)
	match se.id:
		"zomer":
			p.texture = _tex("pollen")
			p.gravity = Vector2(0, -4)
			p.direction = Vector2(0.4, -0.2)
			p.spread = 180
			p.initial_velocity_min = 8
			p.initial_velocity_max = 22
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			p.emission_rect_extents = rect.size / 2.0
			p.position = rect.get_center()
			p.lifetime = 8.0
			p.preprocess = 8.0
			p.amount = int(46 * density)
			p.scale_amount_min = 0.25
			p.scale_amount_max = 0.6
			p.material = _add_mat()
			p.color = Color(se.particle_col, 0.8)
		"winter":
			p.amount = int(70 * density)
			p.initial_velocity_min = 30
			p.initial_velocity_max = 60
			p.scale_amount_min = 0.12
			p.scale_amount_max = 0.38
			p.angular_velocity_min = -40
			p.angular_velocity_max = 40
		"herfst":
			p.amount = int(22 * density)
			p.scale_amount_min = 0.4
			p.scale_amount_max = 0.75
			var gi := Gradient.new()
			gi.offsets = PackedFloat32Array([0.0, 0.33, 0.66])
			gi.colors = PackedColorArray([Color("#E98A3A"), Color("#F2B33D"), Color("#C9472C")])
			gi.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
			p.color = Color.WHITE
			p.color_initial_ramp = gi
	parent.add_child(p)
	p.emitting = true
	return p


## Eenmalige burst. `tex_name` uit assets/art/particles van Trietuin (of gedeeld). Ruimt zichzelf op.
static func burst(parent: Node, pos: Vector2, tex_name: String, amount: int, life: float, vmin: float, vmax: float,
		col: Color, gravity := 0.0, smin := 0.3, smax := 0.6, add := false, dir := Vector2.UP, spread := 180.0,
		colors: Array = []) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = _tex(tex_name)
	p.amount = amount
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
	p.angle_min = -180
	p.angle_max = 180
	p.angular_velocity_min = -200
	p.angular_velocity_max = 200
	p.damping_min = 30 if gravity == 0 else 0
	p.damping_max = 80 if gravity == 0 else 0
	p.color = col
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.6, Color(1, 1, 1, 0.85))
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
		p.material = _add_mat()
	p.position = pos
	p.z_index = 40
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


## Nieuwe tak/knop groeit: blaadjes in seizoenskleur + stuifmeel.
static func grow(parent: Node, pos: Vector2, season: int) -> void:
	var se := TtPal.season(season)
	burst(parent, pos, "leaf_round", 7, 0.7, 90, 180, Color.WHITE, 220, 0.2, 0.38, false, Vector2.UP, 70, se.leaf)
	burst(parent, pos, "pollen", 8, 0.5, 40, 110, se.light, 0, 0.2, 0.4, true)


## Vrucht verschijnt/rijpt: twinkels + ring in seizoenslicht.
static func ripen(parent: Node, pos: Vector2, season: int) -> void:
	var se := TtPal.season(season)
	burst(parent, pos, "twinkle", 6, 0.55, 60, 130, se.light, 0, 0.18, 0.36, true)
	burst(parent, pos, se.particle if se.id != "zomer" else "petal", 6, 0.9, 80, 160, Color.WHITE, 260, 0.25, 0.45, false,
		Vector2.UP, 80, [se.fruit, se.fruit_hi, se.accent])


## Snoeien (Patricia): houtsnippers + blaadjes vallen.
static func snip(parent: Node, pos: Vector2, season: int) -> void:
	var se := TtPal.season(season)
	burst(parent, pos, "chip", 10, 0.8, 150, 300, Color.WHITE, 800, 0.4, 0.8, false, Vector2.UP, 100,
		[TtPal.BARK, TtPal.BARK_LIGHT, TtPal.RAFFIA])
	burst(parent, pos, "leaf", 4, 1.2, 60, 140, Color.WHITE, 160, 0.3, 0.5, false, Vector2.UP, 120, se.leaf)


## Sap gebruikt / druppel valt.
static func sap(parent: Node, pos: Vector2, amount := 5) -> void:
	burst(parent, pos, "drop", amount, 0.6, 60, 160, Color.WHITE, 700, 0.18, 0.32, false, Vector2.UP, 60,
		[TtPal.SAP, TtPal.SAP_LIGHT])


## Bij vindt de juiste vrucht: gouden twinkels + hartjesachtige ring.
static func found(parent: Node, pos: Vector2) -> void:
	burst(parent, pos, "twinkle", 10, 0.6, 90, 200, TtPal.STAR, 0, 0.2, 0.42, true)
	ring_wave(parent, pos, Color(TtPal.STAR, 0.8), 0.3, 2.4, 0.45)


## Bij verdwaalt / wordt weggejaagd: zachte grijze pluim (geen rood).
static func poof(parent: Node, pos: Vector2) -> void:
	burst(parent, pos, "puff", 7, 0.55, 40, 100, Color(0.92, 0.9, 0.85, 0.7), -20, 0.3, 0.6, false, Vector2.UP, 180)


## Seizoenswissel: een golf blaadjes/sneeuw over het scherm.
static func season_wave(parent: Node, season: int) -> void:
	var se := TtPal.season(season)
	for k in 6:
		burst(parent, Vector2(-40, 120 + k * 160), se.particle, 10, 2.4, 500, 900, Color.WHITE, 60, 0.4, 0.8, false,
			Vector2(1, -0.1), 14, [se.particle_col, se.accent, se.leaf[0]])


static func ring_wave(parent: Node, pos: Vector2, col: Color, from_s := 0.2, to_s := 3.0, dur := 0.4) -> void:
	var s := Sprite2D.new()
	s.texture = _shared("ring")
	s.modulate = col
	s.material = _add_mat()
	s.position = pos
	s.scale = Vector2(from_s, from_s)
	s.z_index = 45
	parent.add_child(s)
	var tw := s.create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector2(to_s, to_s), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(s.queue_free)
