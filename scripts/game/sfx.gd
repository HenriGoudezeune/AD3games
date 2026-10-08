extends Node
## Autoload "Sfx": geluid + adaptieve muziek (ART.md Â§8, MANIFEST.md).
## Bussen worden bij opstart aangemaakt: Music (lowpass), SFX, UI.

const MAX_POLY := 4
const VAR_FILES := {
	"drop_box": ["sfx/kenney/drop_box_1.ogg", "sfx/kenney/drop_box_2.ogg", "sfx/kenney/drop_box_3.ogg"],
	"rack_place": ["sfx/kenney/rack_place_1.ogg", "sfx/kenney/rack_place_2.ogg", "sfx/kenney/rack_place_3.ogg"],
}
## namen die op de UI-bus horen
const UI_PREFIX := "sfx/kenney/ui_"

var _streams := {}
var _pools := {}   # path -> Array[AudioStreamPlayer]
var _loops := {}   # naam -> AudioStreamPlayer
var _layers := {}  # "base"/"busy"/"tension" -> player
var _track: AudioStreamPlayer
var _track_name := ""
var _layer_target := {"base": 0.0, "busy": -80.0, "tension": -80.0}
var _lowpass: AudioEffectLowPassFilter
var _music_bus := -1
var _slow := 0.0   # 0..1
var _slow_target := 0.0
var _pitch_mul := 1.0

var music_volume := 0.8:
	set(v):
		music_volume = clampf(v, 0.0, 1.0)
		if _music_bus >= 0:
			AudioServer.set_bus_volume_db(_music_bus, linear_to_db(maxf(music_volume, 0.0001)) - 10.0)
var sfx_volume := 0.9:
	set(v):
		sfx_volume = clampf(v, 0.0, 1.0)
		var i := AudioServer.get_bus_index("SFX")
		if i >= 0:
			AudioServer.set_bus_volume_db(i, linear_to_db(maxf(sfx_volume, 0.0001)))
		var j := AudioServer.get_bus_index("UI")
		if j >= 0:
			AudioServer.set_bus_volume_db(j, linear_to_db(maxf(sfx_volume, 0.0001)) - 6.0)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_bus("Music")
	_make_bus("SFX")
	_make_bus("UI")
	_music_bus = AudioServer.get_bus_index("Music")
	_lowpass = AudioEffectLowPassFilter.new()
	_lowpass.cutoff_hz = 20000.0
	AudioServer.add_bus_effect(_music_bus, _lowpass)
	music_volume = music_volume
	sfx_volume = sfx_volume
	for k in ["base", "busy", "tension"]:
		var p := AudioStreamPlayer.new()
		p.bus = "Music"
		p.volume_db = -80.0
		add_child(p)
		_layers[k] = p
	_layers["base"].stream = _stream_of("music/layer_base_loop.ogg")
	_layers["busy"].stream = _stream_of("music/layer_busy_loop.ogg")
	_layers["tension"].stream = _stream_of("music/layer_tension_loop.ogg")
	_track = AudioStreamPlayer.new()
	_track.bus = "Music"
	_track.volume_db = -80.0
	add_child(_track)


func _make_bus(name_: String) -> void:
	if AudioServer.get_bus_index(name_) >= 0:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, name_)
	AudioServer.set_bus_send(i, "Master")


func _stream_of(path: String) -> AudioStream:
	if _streams.has(path):
		return _streams[path]
	var full := "res://assets/" + path
	var s: AudioStream = null
	if ResourceLoader.exists(full):
		s = load(full)
	else:
		push_warning("Sfx: ontbreekt " + full)
	_streams[path] = s
	return s


## Speel een effect. `path` relatief t.o.v. assets/ ("sfx/coin.wav") of een variantnaam ("rack_place").
func play(path: String, vol_db := 0.0, pitch := 1.0, rand_pitch := true) -> AudioStreamPlayer:
	if VAR_FILES.has(path):
		var arr: Array = VAR_FILES[path]
		path = arr[randi() % arr.size()]
	var s := _stream_of(path)
	if s == null:
		return null
	var pool: Array = _pools.get(path, [])
	_pools[path] = pool
	var p: AudioStreamPlayer = null
	for q in pool:
		if not q.playing:
			p = q
			break
	if p == null:
		if pool.size() < MAX_POLY:
			p = AudioStreamPlayer.new()
			p.stream = s
			p.bus = "UI" if path.begins_with(UI_PREFIX) or path == "sfx/ui_whoosh.wav" else "SFX"
			add_child(p)
			pool.append(p)
		else:
			p = pool[0]
			pool.remove_at(0)
			pool.append(p)
	p.volume_db = vol_db
	p.pitch_scale = pitch * (randf_range(0.92, 1.08) if rand_pitch else 1.0)
	p.play()
	return p


func ui(name_: String, vol_db := 0.0) -> void:
	play("sfx/kenney/ui_%s.ogg" % name_, vol_db, 1.0, false)


## Lus aan/uit (band, alarm).
func loop(name_: String, path: String, on: bool, vol_db := 0.0, pitch := 1.0) -> void:
	var p: AudioStreamPlayer = _loops.get(name_)
	if p == null:
		if not on:
			return
		p = AudioStreamPlayer.new()
		p.stream = _stream_of(path)
		p.bus = "SFX"
		add_child(p)
		_loops[name_] = p
	p.pitch_scale = pitch
	if on:
		if not p.playing:
			p.volume_db = -40.0
			p.play()
		create_tween().tween_property(p, "volume_db", vol_db, 0.25)
	elif p.playing:
		var tw := create_tween()
		tw.tween_property(p, "volume_db", -50.0, 0.25)
		tw.tween_callback(p.stop)


func loop_pitch(name_: String, pitch: float) -> void:
	var p: AudioStreamPlayer = _loops.get(name_)
	if p:
		p.pitch_scale = maxf(0.05, pitch)


func stop_loops() -> void:
	for k in _loops:
		var p: AudioStreamPlayer = _loops[k]
		p.stop()


# ---------------------------------------------------------------- muziek
## In-game: drie synchrone lagen.
func start_layers() -> void:
	_fade(_track, -80.0, 0.6, true)
	_track_name = ""
	var started: bool = _layers["base"].playing
	for k in _layers:
		var p: AudioStreamPlayer = _layers[k]
		if not started:
			p.volume_db = -80.0
			p.play()
	set_layer("base", true)
	set_layer("busy", false)
	set_layer("tension", false)


func stop_layers(t := 0.6) -> void:
	for k in _layers:
		_fade(_layers[k], -80.0, t, true)


func set_layer(k: String, on: bool, level_db := 0.0) -> void:
	var target := level_db if on else -80.0
	if is_equal_approx(_layer_target.get(k, -99.0), target):
		return
	_layer_target[k] = target
	var p: AudioStreamPlayer = _layers[k]
	if p.playing:
		_fade(p, target, 0.5, false)


## Losse muziektrack: "calm" (titel/kaart) of "rush" (endless).
func play_track(name_: String) -> void:
	if _track_name == name_ and _track.playing:
		return
	stop_layers()
	_track_name = name_
	var path := "music/depot_calm_loop.ogg" if name_ == "calm" else "music/depot_rush_loop.ogg"
	_track.stream = _stream_of(path)
	_track.volume_db = -40.0
	_track.play()
	_fade(_track, 0.0, 1.0, false)


func stinger(path: String, vol := 0.0) -> void:
	play(path, vol, 1.0, false)


func _fade(p: AudioStreamPlayer, to_db: float, t: float, stop_after: bool) -> void:
	if p == null:
		return
	var tw := create_tween()
	tw.tween_property(p, "volume_db", to_db, t).set_trans(Tween.TRANS_SINE)
	if stop_after:
		tw.tween_callback(p.stop)


## Slow-mo/alarm: lowpass 800 Hz + pitch âˆ’2 halve tonen op de muziek.
func set_slowmo(on: bool) -> void:
	_slow_target = 1.0 if on else 0.0


func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.001)
	_slow = move_toward(_slow, _slow_target, real / 0.3)
	var e := _slow * _slow * (3.0 - 2.0 * _slow)
	_lowpass.cutoff_hz = lerpf(20000.0, 800.0, sqrt(e))
	var pitch := lerpf(1.0, 0.89, e) * _pitch_mul
	for k in _layers:
		_layers[k].pitch_scale = pitch
	_track.pitch_scale = pitch
