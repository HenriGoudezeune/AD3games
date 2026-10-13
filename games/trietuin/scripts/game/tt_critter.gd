class_name TtCritter
extends Node2D
## Een beestje in de tuin: zaadje (toevoegen), bij (opzoeken), wesp (vermomde bij, Patricia), vuurvliegje
## (Ukkonen-wijzer) of snoeischaar. Tekent zichzelf met TtDraw; beweging via tweens van buitenaf
## (`fly_path`, `hop_to`, `bonk`, ...). `read_pos` = letter die het beestje nu leest (ring op het label).

enum K { SEED, BEE, WASP, FIREFLY, SHEARS }

var kind := K.BEE
var word := ""
var letters := "ACGT_"
var mood := 0                 # bij: 0 vliegt, 1 twijfel, 2 blij, 3 weggejaagd
var read_pos := -1
var ghost_to := -1            # Patricia: overgeslagen letters (holle chips) t.e.m. deze index
var facing := 1.0
var striped := false          # wesp ontmaskerd
var badge := -1               # vuurvliegje: x̄ (-1 = geen)
var label_on := true
var t := 0.0
var squash := Vector2.ONE
var se: Dictionary = {}
var trail: CPUParticles2D
var open := 0.4               # schaar


func _init(k := K.BEE, w := "", alpha := "ACGT_", season_ := {}) -> void:
	kind = k
	word = w
	letters = alpha
	se = season_
	z_index = 20


func _ready() -> void:
	if kind == K.BEE or kind == K.WASP:
		trail = CPUParticles2D.new()
		trail.texture = TtPal.particle("pollen")
		trail.amount = 14
		trail.lifetime = 0.7
		trail.local_coords = false
		trail.gravity = Vector2(0, 30)
		trail.initial_velocity_min = 5
		trail.initial_velocity_max = 20
		trail.scale_amount_min = 0.15
		trail.scale_amount_max = 0.3
		trail.color = Color(TtPal.STAR, 0.8)
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0.9))
		g.set_color(1, Color(1, 1, 1, 0))
		trail.color_ramp = g
		trail.position = Vector2(-20, 4)
		add_child(trail)
	elif kind == K.FIREFLY:
		trail = CPUParticles2D.new()
		trail.texture = TtPal.particle("twinkle")
		trail.amount = 18
		trail.lifetime = 0.9
		trail.local_coords = false
		trail.gravity = Vector2(0, -10)
		trail.initial_velocity_min = 4
		trail.initial_velocity_max = 16
		trail.scale_amount_min = 0.12
		trail.scale_amount_max = 0.28
		trail.color = Color("#FFF2A0")
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		trail.material = m
		add_child(trail)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, squash)
	match kind:
		K.BEE, K.WASP:
			_draw_bee()
		K.SEED:
			_draw_seed()
		K.FIREFLY:
			_draw_firefly()
		K.SHEARS:
			TtDraw.shears(self, Vector2.ZERO, 1.25, open)


func _draw_bee() -> void:
	var w := word if label_on else ""
	TtDraw.bee(self, Vector2.ZERO, 1.0, t, facing, mood, w, letters, read_pos, true, ghost_to)
	if kind == K.WASP and striped:
		# wespenstrepen: extra zwarte banden + angel, gemene oogjes
		for bx in [-6.0, 6.0, 15.0]:
			var p := Vector2(bx * facing, sin(t * 7.0) * 3.0)
			draw_line(p + Vector2(0, -15), p + Vector2(0, 15), Color("#1C140E"), 5.0, true)
		var tail := Vector2(-30 * facing, 2 + sin(t * 7.0) * 3.0)
		draw_colored_polygon(PackedVector2Array([tail + Vector2(0, -5), tail + Vector2(-16 * facing, 0), tail + Vector2(0, 5)]), Color("#1C140E"))
		draw_line(Vector2(8 * facing, -14), Vector2(20 * facing, -9), Color("#1C140E"), 3.0, true)


func _draw_seed() -> void:
	var bob := sin(t * 4.0) * 2.0
	var c := Vector2(0, bob)
	# label (het woord) hangt onder het zaadje
	if word != "" and label_on:
		var ls := 22
		var lw := TtPal.word_width(word.length(), ls) + ls * 0.8
		var lr := Rect2(-lw / 2.0, 34 + bob, lw, ls * 1.5)
		draw_line(c + Vector2(0, 14), Vector2(0, lr.position.y + 2), TtPal.INK_SOFT, 1.6, true)
		draw_style_box(TtPal.sb(Color(0, 0, 0, 0), 8, 4, Vector2(2, 4)), lr)
		draw_style_box(TtPal.sb_thick(TtPal.PAPER, 8, 3, TtPal.PAPER_EDGE), lr)
		TtPal.word(self, lr.get_center(), word, ls, true, letters, read_pos, read_pos, TtPal.INFO, -1, -1,
			read_pos + 1 if read_pos >= 0 else -1)
	# zaadje: bruine druppelvorm met kiempje en pluisje
	TtDraw.ellipse(self, c + Vector2(4, 6), 18, 13, TtPal.SHADOW_SOFT)
	var body := TtDraw.ellipse_pts(c, 17, 13, -0.35, 28)
	TtDraw.fill(self, body, TtPal.BARK)
	TtDraw.fill(self, TtDraw.ellipse_pts(c + Vector2(-2, -2), 14, 10, -0.35, 28), TtPal.BARK_LIGHT)
	TtDraw.ellipse(self, c + Vector2(-6, -5), 4, 2.5, Color(1, 1, 1, 0.5), -0.4)
	TtDraw.sprout(self, c + Vector2(4, -10), 1.0, TtPal.BRAND)
	for k in 5:
		var a := -PI * 0.5 + (k - 2) * 0.32 + sin(t * 3.0 + k) * 0.05
		var tip := c + Vector2(-10, -8) + Vector2(cos(a - 0.6), sin(a - 0.6)) * 20.0
		draw_line(c + Vector2(-10, -8), tip, Color(1, 1, 1, 0.75), 1.4, true)
		draw_circle(tip, 2.2, Color(1, 1, 1, 0.85), true, -1, true)


func _draw_firefly() -> void:
	TtDraw.firefly(self, Vector2.ZERO, 1.25, t, badge, facing)


# ---------------------------------------------------------------- bewegingen
## Vlieg langs een polyline (wereldcoördinaten in de ouder) in `dur` s.
func fly_path(pts: PackedVector2Array, dur: float, ease_out := true) -> Tween:
	var tw := create_tween()
	if pts.size() < 2:
		tw.tween_interval(0.01)
		return tw
	var m := tw.tween_method(func(f: float):
		var p := TtDraw.path_point(pts, f)
		var tg := TtDraw.path_tangent(pts, f)
		if absf(tg.x) > 0.15:
			facing = signf(tg.x)
		position = p, 0.0, 1.0, dur)
	if ease_out:
		m.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tw


func fly_to(p: Vector2, dur := 0.4, arc := -60.0) -> Tween:
	var a := position
	var mid := (a + p) / 2.0 + Vector2(0, arc)
	var pts := PackedVector2Array()
	for k in 17:
		var u := k / 16.0
		pts.append(a.lerp(mid, u).lerp(mid.lerp(p, u), u))
	return fly_path(pts, dur)


func pop(sx := 1.25, sy := 0.8, dur := 0.25) -> void:
	squash = Vector2(sx, sy)
	var tw := create_tween()
	tw.tween_property(self, "squash", Vector2.ONE, dur).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func bonk(dir: Vector2) -> Tween:
	var a := position
	var tw := create_tween()
	tw.tween_property(self, "position", a + dir * 26.0, 0.12).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): pop(0.8, 1.2, 0.3))
	tw.tween_property(self, "position", a - dir * 10.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tw


func leave(dir := Vector2(1, -0.6), dur := 0.7) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "position", position + dir * 900.0, dur).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "modulate:a", 0.0, dur).set_delay(dur * 0.5)
	tw.chain().tween_callback(queue_free)
