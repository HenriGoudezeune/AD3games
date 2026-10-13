class_name TtBackdrop
extends CanvasLayer
## Trietuin-achtergrond (vaste laag achter de wereld): seizoensachtergrond, drijvende wolken, sfeerdeeltjes
## en (optioneel) de voorgrond met gras/bloemen. Seizoen wisselen = zachte overvloei + golf blaadjes.

var season := 0
var show_fg := true
var dim := 0.0:
	set(v):
		dim = v
		if _dim_rect:
			_dim_rect.color = Color(0.03, 0.06, 0.04, dim)

var _back: TextureRect
var _front: TextureRect
var _fg: TextureRect
var _clouds: Array[Sprite2D] = []
var _amb: CPUParticles2D
var _dim_rect: ColorRect
var _fx: Node2D


func _init(season_ := 0, fg := true, layer_ := -10) -> void:
	season = season_
	show_fg = fg
	layer = layer_


func _ready() -> void:
	_back = _rect()
	_front = _rect()
	var t1 := TtPal.tex("art/bg/cloud_1.png")
	var t2 := TtPal.tex("art/bg/cloud_2.png")
	for i in 4:
		var s := Sprite2D.new()
		s.texture = t1 if i % 2 == 0 else t2
		s.position = Vector2(150 + i * 560 + randf() * 120, 120 + (i % 2) * 120 + randf() * 40)
		s.scale = Vector2.ONE * (0.7 + 0.15 * i)
		add_child(s)
		_clouds.append(s)
	_fg = TextureRect.new()
	_fg.position = Vector2(0, 1080 - 180)
	_fg.size = Vector2(1920, 180)
	_fg.stretch_mode = TextureRect.STRETCH_SCALE
	_fg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fg.visible = show_fg
	add_child(_fg)
	_fx = Node2D.new()
	add_child(_fx)
	_dim_rect = ColorRect.new()
	_dim_rect.size = Vector2(1920, 1080)
	_dim_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim_rect.color = Color(0.03, 0.06, 0.04, dim)
	add_child(_dim_rect)
	set_season(season, true)


func _rect() -> TextureRect:
	var r := TextureRect.new()
	r.size = Vector2(1920, 1080)
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func set_season(s: int, instant := false) -> void:
	season = clampi(s, 0, 3)
	var se := TtPal.season(season)
	var tex: Texture2D = load(TtPal.bg_path(season)) if ResourceLoader.exists(TtPal.bg_path(season)) else null
	_back.texture = _front.texture if _front.texture else tex
	_front.texture = tex
	if ResourceLoader.exists(TtPal.fg_path(season)):
		_fg.texture = load(TtPal.fg_path(season))
	if instant:
		_front.modulate.a = 1.0
	else:
		_front.modulate.a = 0.0
		create_tween().tween_property(_front, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
		TtFx.season_wave(_fx, season)
	for c in _clouds:
		c.modulate = Color(1, 1, 1, 0.3) if se.night else Color(1, 1, 1, 0.75)
	if _amb:
		_amb.queue_free()
	_amb = TtFx.ambient(self, season)
	move_child(_amb, _front.get_index() + 1 + _clouds.size())


func _process(delta: float) -> void:
	for i in _clouds.size():
		var c := _clouds[i]
		c.position.x += delta * (7.0 + i * 4.0)
		if c.position.x > 2200:
			c.position.x = -280
