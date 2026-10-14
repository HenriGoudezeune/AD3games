class_name TxSnd
extends Object
## TELEX-geluid: speelt games/telex/assets/sfx/*.wav op de bussen van de gedeelde autoload Sfx (SFX/UI/Music
## bestaan daar al), zonder Sfx te wijzigen. Muziek: één lus per stemming ("title", "calm", "live", "rhythm") met een
## tweede, synchrone laag ("think" bij CALM, "tension" bij LIVE). Alles statisch; de spelers hangen onder /root/Sfx.

const DIR := "res://games/telex/assets/"
const MAX_POLY := 6
const MUSIC := {
	"title": ["music/title_jazz_loop.ogg", ""],
	"calm": ["music/calm_base_loop.ogg", "music/calm_think_loop.ogg"],
	"live": ["music/live_drive_loop.ogg", "music/live_tension_loop.ogg"],
	"rhythm": ["music/rhythm_100_loop.ogg", ""],
}

static var _streams := {}
static var _pools := {}
static var _loops := {}
static var _music: AudioStreamPlayer
static var _layer: AudioStreamPlayer
static var _music_name := ""
static var _layer_on := false
static var muted := false          # bots/tests
static var _last := {}             # naam -> tijd (ms) van de laatste keer (anti-spam)


static func _host() -> Node:
	var ml := Engine.get_main_loop() as SceneTree
	if ml == null:
		return null
	return ml.root.get_node_or_null("Sfx")


static func stream(rel: String) -> AudioStream:
	if _streams.has(rel):
		return _streams[rel]
	var p := DIR + rel
	var s: AudioStream = load(p) if ResourceLoader.exists(p) else null
	_streams[rel] = s
	return s


static func _sfx_stream(name_: String) -> AudioStream:
	var s := stream("sfx/%s.wav" % name_)
	if s == null:
		s = stream("sfx/%s.ogg" % name_)
	return s


## Speel een effect: `name_` = bestandsnaam zonder extensie in assets/sfx ("bell"). min_gap_ms: niet vaker dan dat.
static func play(name_: String, vol_db := 0.0, pitch := 1.0, rand_pitch := true, min_gap_ms := 0) -> void:
	if muted:
		return
	var host := _host()
	if host == null:
		return
	if min_gap_ms > 0:
		var now := Time.get_ticks_msec()
		if now - int(_last.get(name_, -100000)) < min_gap_ms:
			return
		_last[name_] = now
	var s := _sfx_stream(name_)
	if s == null:
		return
	var pool: Array = _pools.get(name_, [])
	_pools[name_] = pool
	var p: AudioStreamPlayer = null
	for q in pool:
		if is_instance_valid(q) and not q.playing:
			p = q
			break
	if p == null:
		if pool.size() < MAX_POLY:
			p = AudioStreamPlayer.new()
			p.stream = s
			p.bus = "UI" if name_.begins_with("ui_") else "SFX"
			host.add_child(p)
			pool.append(p)
		else:
			p = pool[0]
			pool.remove_at(0)
			pool.append(p)
	p.volume_db = vol_db
	p.pitch_scale = maxf(0.05, pitch * (randf_range(0.95, 1.05) if rand_pitch else 1.0))
	p.play()


## Een van de typehamer-varianten (tak_1..3).
static func tak(vol := -6.0, pitch := 1.0) -> void:
	play("tak_%d" % (randi() % 3 + 1), vol, pitch)


## Naaldtikje: gelijk = hoger, verschil = lager + zoem.
static func needle(eq: bool, vol := -4.0) -> void:
	if eq:
		play("needle_eq", vol, 1.0)
	else:
		play("needle_ne", vol, 1.0)


static func ui(kind := "key") -> void:
	match kind:
		"hover":
			play("ui_hover", -14.0, 1.0, true, 40)
		"switch":
			play("ui_switch", -6.0)
		_:
			play("ui_key", -6.0)


static func loop(key: String, name_: String, on: bool, vol_db := -6.0, pitch := 1.0) -> void:
	var host := _host()
	if host == null:
		return
	var p: AudioStreamPlayer = _loops.get(key)
	if p != null and not is_instance_valid(p):
		p = null
	if p == null:
		if not on or muted:
			return
		var s := _sfx_stream(name_)
		if s == null:
			return
		if s is AudioStreamWAV:
			s = (s as AudioStreamWAV).duplicate()
			(s as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
			(s as AudioStreamWAV).loop_begin = 0
			(s as AudioStreamWAV).loop_end = int((s as AudioStreamWAV).get_length() * (s as AudioStreamWAV).mix_rate)
		elif s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = true
		p = AudioStreamPlayer.new()
		p.stream = s
		p.bus = "SFX"
		host.add_child(p)
		_loops[key] = p
	p.pitch_scale = pitch
	if on:
		if not p.playing:
			p.volume_db = -40.0
			p.play()
		p.create_tween().tween_property(p, "volume_db", vol_db, 0.25)
	elif p.playing:
		var tw := p.create_tween()
		tw.tween_property(p, "volume_db", -50.0, 0.25)
		tw.tween_callback(p.stop)


static func stop_loops() -> void:
	for k in _loops:
		var p: AudioStreamPlayer = _loops[k]
		if is_instance_valid(p):
			p.stop()


# ---------------------------------------------------------------- muziek
## name_: "title" | "calm" | "live" | "rhythm" | "" (stil).
static func music(name_: String) -> void:
	var host := _host()
	if host == null:
		return
	if name_ == _music_name and _music != null and is_instance_valid(_music) and _music.playing:
		return
	_music_name = name_
	_fade_out(_music)
	_fade_out(_layer)
	_music = null
	_layer = null
	_layer_on = false
	if name_ == "" or muted or not MUSIC.has(name_):
		return
	var pair: Array = MUSIC[name_]
	_music = _start(str(pair[0]), -5.0)
	if str(pair[1]) != "":
		_layer = _start(str(pair[1]), -80.0)


## Tweede laag (CALM: nadenken/alarm; LIVE: spanning).
static func layer(on: bool) -> void:
	if _layer == null or not is_instance_valid(_layer) or on == _layer_on:
		return
	_layer_on = on
	_layer.create_tween().tween_property(_layer, "volume_db", -7.0 if on else -80.0, 1.0 if on else 1.6)


static func _start(rel: String, vol: float) -> AudioStreamPlayer:
	var host := _host()
	var s := stream(rel)
	if s == null or host == null:
		return null
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.bus = "Music"
	host.add_child(p)
	p.volume_db = -50.0 if vol > -60.0 else vol
	p.play()
	if vol > -60.0:
		p.create_tween().tween_property(p, "volume_db", vol, 1.2)
	return p


static func _fade_out(p: AudioStreamPlayer) -> void:
	if p == null or not is_instance_valid(p):
		return
	var tw := p.create_tween()
	tw.tween_property(p, "volume_db", -60.0, 0.7)
	tw.tween_callback(p.queue_free)


## Muziek zachter (pauze, debrief) of terug.
static func duck(on: bool) -> void:
	if _music != null and is_instance_valid(_music):
		_music.create_tween().tween_property(_music, "volume_db", -16.0 if on else -5.0, 0.4)


## Lowpass op de muziekbus (lusbak bijna vol, slow-mo).
static func lowpass(on: bool) -> void:
	var host := _host()
	if host != null and host.has_method("set_slowmo"):
		host.set_slowmo(on)


## Debrief-jingle naar sterren (0..3).
static func jingle(n: int) -> void:
	play("jingle_%d" % clampi(n, 0, 3), -2.0, 1.0, false)
