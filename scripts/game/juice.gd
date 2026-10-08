extends Node
## Autoload "Juice": schermschok, camera-punch, hitstop, floaters en partikel-bursts (GDD §8, ART.md §6–7).

var shake_scale := 1.0          # instelling 0 / 0.5 / 1
var camera: Camera2D            # gezet door de actieve scène
var _trauma := 0.0              # in px
var _trauma_t := 0.0
var _trauma_dur := 0.0
var _noise := FastNoiseLite.new()
var _nt := 0.0
var _zoom_punch := 0.0
var _tex := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_noise.frequency = 0.9
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX


func tex(name_: String) -> Texture2D:
	if not _tex.has(name_):
		_tex[name_] = load("res://assets/art/particles/%s.png" % name_)
	return _tex[name_]


func icon(name_: String) -> Texture2D:
	var k := "icon_" + name_
	if not _tex.has(k):
		_tex[k] = load("res://assets/art/icons/%s.png" % name_)
	return _tex[k]


## Schok: `px` maximale uitwijking, kwadratische decay over `dur` seconden.
func shake(px: float, dur := 0.25) -> void:
	px *= shake_scale
	if px <= 0.0:
		return
	if px >= _trauma * (1.0 - _trauma_t / maxf(_trauma_dur, 0.001)):
		_trauma = px
		_trauma_dur = dur
		_trauma_t = 0.0


func punch(amount := 0.02) -> void:
	_zoom_punch = maxf(_zoom_punch, amount)


## Hitstop: bevriest alles (ook tweens) gedurende `sec` echte seconden.
func hitstop(sec := 0.08) -> void:
	Engine.time_scale = 0.0
	await get_tree().create_timer(sec, true, false, true).timeout
	Engine.time_scale = 1.0


func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.001) if Engine.time_scale > 0.0 else 0.016
	_nt += real * 40.0
	var off := Vector2.ZERO
	if _trauma > 0.0:
		_trauma_t += real
		var k := 1.0 - _trauma_t / maxf(_trauma_dur, 0.001)
		if k <= 0.0:
			_trauma = 0.0
		else:
			var amp := _trauma * k * k
			off = Vector2(_noise.get_noise_2d(_nt, 0.0), _noise.get_noise_2d(0.0, _nt + 100.0)) * amp * 1.6
	_zoom_punch = move_toward(_zoom_punch, 0.0, real * 0.12)
	if is_instance_valid(camera):
		camera.offset = off
		var z := 1.0 + _zoom_punch
		camera.zoom = Vector2(z, z)


# ---------------------------------------------------------------- floaters
## Tekst die 40 px stijgt en vervaagt (0,6 s). Fredoka Bold met outline.
func floater(parent: Node, pos: Vector2, text: String, col: Color, size := 34, rise := 40.0, dur := 0.7) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", Pal.UI_BOLD)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Pal.OUTLINE)
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 50
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


# ---------------------------------------------------------------- partikels
## Eenmalige burst (CPUParticles2D, werkt in de Compatibility-renderer).
func burst(parent: Node, pos: Vector2, tex_name: String, amount: int, life: float, vmin: float, vmax: float,
		col: Color, gravity := 0.0, smin := 0.3, smax := 0.6, add := false, dir := Vector2.UP, spread := 180.0,
		ramp_alpha := true, colors: Array = []) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = tex(tex_name)
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
	p.angular_velocity_min = -360 if gravity > 0 else -60
	p.angular_velocity_max = 360 if gravity > 0 else 60
	p.damping_min = 20 if gravity == 0 else 0
	p.damping_max = 60 if gravity == 0 else 0
	p.color = col
	if ramp_alpha:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.6, Color(1, 1, 1, 0.8))
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


func dust(parent: Node, pos: Vector2, amount := 6) -> void:
	burst(parent, pos, "puff", amount, 0.45, 40, 90, Color(Pal.KRAFT, 0.6), -30, 0.25, 0.55, false, Vector2.UP, 70)


func sparks(parent: Node, pos: Vector2, amount := 8) -> void:
	burst(parent, pos, "dot", amount, 0.3, 200, 350, Pal.WARN, 600, 0.08, 0.18, true, Vector2.UP, 75, true, [Pal.WARN, Pal.ERR])


func confetti(parent: Node, pos: Vector2, amount := 10, cols: Array = []) -> void:
	if cols.is_empty():
		cols = Pal.BUCKET_COLORS
	burst(parent, pos, "confetti", amount, 0.8, 220, 420, Color.WHITE, 900, 0.5, 0.9, false, Vector2.UP, 55, true, cols)


func cardboard(parent: Node, pos: Vector2, amount := 20) -> void:
	burst(parent, pos, "confetti", amount, 0.8, 250, 450, Color.WHITE, 900, 0.6, 1.1, false, Vector2.UP, 120, true, [Pal.KRAFT, Pal.KRAFT_DARK, Pal.TAPE])


func coin_sparkle(parent: Node, pos: Vector2) -> void:
	burst(parent, pos, "sparkle", 5, 0.35, 80, 140, Pal.COIN, 0, 0.2, 0.4, true)


## Expanderende ring (DASH, nieuwe luiken).
func ring_wave(parent: Node, pos: Vector2, col: Color, from_s := 0.2, to_s := 3.0, dur := 0.4) -> void:
	var s := Sprite2D.new()
	s.texture = tex("ring")
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


## Zachte lichtvlek (add) die even oplicht.
func flash_glow(parent: Node, pos: Vector2, col: Color, size := 1.0, dur := 0.35) -> void:
	var s := Sprite2D.new()
	s.texture = tex("glow")
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
