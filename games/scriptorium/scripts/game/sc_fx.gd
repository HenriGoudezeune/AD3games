class_name ScFx
extends Object
## Kortschrift: partikel-recepten (design/ART.md §6.3). CPUParticles2D (werkt in GL Compatibility). Texturen zijn wit
## (assets/art/particles/), kleur via `color`/ramp. Gedeelde texturen van Hash & Dash (ring, sparkle, puff ...) via
## res://assets/art/particles/.


static func _shared(name_: String) -> Texture2D:
	var p := "res://assets/art/particles/%s.png" % name_
	return load(p) if ResourceLoader.exists(p) else null


static func _tex(name_: String) -> Texture2D:
	var t := ScPal.particle(name_)
	return t if t else _shared(name_)


static func _add_mat() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


static func _fade_ramp(peak := 0.15) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(peak, Color(1, 1, 1, 1))
	g.add_point(0.75, Color(1, 1, 1, 0.85))
	return g


## Sfeer: stofjes die traag door het kaarslicht zweven (altijd, achter de werktuigen, z laag). Additief.
static func ambient_dust(parent: Node, rect := Rect2(0, 0, 1920, 1080), density := 1.0, col := Color(1.0, 0.86, 0.6, 0.55)) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = _tex("dust")
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = rect.size / 2.0
	p.position = rect.get_center()
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.amount = int(60 * density)
	p.direction = Vector2(0.3, -1)
	p.spread = 180
	p.gravity = Vector2(0, -3)
	p.initial_velocity_min = 4
	p.initial_velocity_max = 14
	p.scale_amount_min = 0.12
	p.scale_amount_max = 0.35
	p.color = col
	p.color_ramp = _fade_ramp(0.3)
	p.material = _add_mat()
	parent.add_child(p)
	p.emitting = true
	return p


## Eenmalige burst. Ruimt zichzelf op. `colors` = willekeurige beginkleur per deeltje.
static func burst(parent: Node, pos: Vector2, tex_name: String, amount: int, life: float, vmin: float, vmax: float,
		col: Color, gravity := 0.0, smin := 0.3, smax := 0.6, add := false, dir := Vector2.UP, spread := 180.0,
		colors: Array = [], spin := 200.0) -> CPUParticles2D:
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
	p.angular_velocity_min = -spin
	p.angular_velocity_max = spin
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


## Bit/letter geschreven: drie inktspatjes van de veer (#2).
static func ink_flick(parent: Node, pos: Vector2) -> void:
	burst(parent, pos, "ink_drop", 3, 0.35, 40, 110, ScPal.INK, 600, 0.08, 0.16, false, Vector2(0.4, -1), 50)


## Inktvlek: anders gelezen letter (#11, #13). Spetters + één grote vlek die de front-end zelf tekent (ScDraw.ink_blot).
static func ink_splash(parent: Node, pos: Vector2) -> void:
	burst(parent, pos, "ink_drop", 8, 0.5, 120, 260, ScPal.SEPIA, 900, 0.12, 0.26, false, Vector2.UP, 160)
	burst(parent, pos, "ink_splat", 1, 0.6, 0, 0, Color(ScPal.SEPIA, 0.6), 0, 0.5, 0.5, false, Vector2.UP, 0, [], 0)


## Lakzegel / ster gedrukt: wasspetters (#3, #36).
static func wax_splat(parent: Node, pos: Vector2, col := ScPal.WAX) -> void:
	burst(parent, pos, "wax_drop", 9, 0.45, 120, 240, Color.WHITE, 700, 0.10, 0.22, false, Vector2.UP, 180,
		[col, col.lightened(0.2), col.darkened(0.2)])
	burst(parent, pos, "wax_crumb", 5, 0.6, 60, 140, Color.WHITE, 500, 0.15, 0.3, false, Vector2.UP, 120, [col.darkened(0.3)])


## Touw knoopt dicht (binderij #7): korte vezeltjes.
static func twine_knot(parent: Node, pos: Vector2) -> void:
	burst(parent, pos, "straw", 7, 0.5, 60, 150, Color.WHITE, 300, 0.25, 0.45, false, Vector2.UP, 140, [ScPal.TWINE, ScPal.TWINE_DARK])


## Schaar knipt (meetlat #20, codeboom #5): perkamentsnippers.
static func snip(parent: Node, pos: Vector2) -> void:
	burst(parent, pos, "scrap", 6, 0.9, 80, 200, Color.WHITE, 700, 0.18, 0.32, false, Vector2.UP, 120, [ScPal.VELLUM, ScPal.VELLUM_EDGE])


## Stempel snijden / houten klem: houtkrullen (#29, #6).
static func shavings(parent: Node, pos: Vector2, amount := 8) -> void:
	burst(parent, pos, "shaving", amount, 0.8, 90, 220, Color.WHITE, 800, 0.2, 0.38, false, Vector2.UP, 120,
		[ScPal.OAK_LIGHT, ScPal.OAK, Color("#D8B080")])


## Klem / lege lade: stofwolkje (#6, #30). Grijsbruin, nooit rood.
static func dust_puff(parent: Node, pos: Vector2) -> void:
	burst(parent, pos, "smoke", 7, 0.7, 30, 90, Color(0.85, 0.78, 0.68, 0.6), -20, 0.4, 0.8, false, Vector2.UP, 180, [], 40)


## Kist gaat open (#37): stro + goudglans.
static func crate_open(parent: Node, pos: Vector2) -> void:
	burst(parent, pos, "straw", 14, 1.0, 140, 300, Color.WHITE, 600, 0.3, 0.6, false, Vector2.UP, 70, [Color("#E2C26A"), Color("#C9A24A")])
	burst(parent, pos, "gold_flake", 10, 0.9, 60, 160, ScPal.GOLD_LIGHT, -30, 0.12, 0.25, true)


## Voorlezing geslaagd (#12): bladgoud dwarrelt over de kopie.
static func gold_rain(parent: Node, rect: Rect2) -> void:
	for k in 4:
		burst(parent, Vector2(rect.position.x + rect.size.x * (k + 0.5) / 4.0, rect.position.y - 20), "gold_flake", 10, 2.2,
			20, 90, Color.WHITE, 120, 0.14, 0.3, false, Vector2.DOWN, 70, [ScPal.GOLD, ScPal.GOLD_LIGHT, ScPal.GOLD_DARK])


## Duif vertrekt / landt: veertjes (#10).
static func feathers(parent: Node, pos: Vector2) -> void:
	burst(parent, pos, "feather", 6, 1.6, 40, 120, Color.WHITE, 60, 0.3, 0.5, false, Vector2.UP, 160, [ScPal.DOVE, ScPal.DOVE_DARK], 90)


## Kaars laait op (Nachtwake "Volle vlam" #39): vonkjes.
static func embers(parent: Node, pos: Vector2) -> void:
	burst(parent, pos, "ember", 16, 1.1, 60, 180, ScPal.FLAME, -120, 0.08, 0.2, true, Vector2.UP, 50)


## Ring die uitdijt (bladgoud): juiste lezing, naald in het goud.
static func ring_wave(parent: Node, pos: Vector2, col := ScPal.GOLD, from_s := 0.2, to_s := 2.6, dur := 0.4) -> void:
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


## Additieve gloed-sprite (kaarsen, lantaarn): flakkert zelf als `flicker` > 0.
static func glow_sprite(parent: Node, pos: Vector2, radius := 160.0, col := Color(1.0, 0.7, 0.35, 0.35)) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = _tex("light_pool")
	s.material = _add_mat()
	s.modulate = col
	s.position = pos
	s.scale = Vector2.ONE * (radius * 2.0 / 256.0)
	parent.add_child(s)
	return s
