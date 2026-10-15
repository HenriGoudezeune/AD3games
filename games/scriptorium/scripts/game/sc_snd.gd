class_name ScSnd
extends Object
## Kortschrift-geluid (design/ART.md §8, assets/MANIFEST.md): speelt de effecten uit games/scriptorium/assets/sfx/ op
## de bussen van de gedeelde autoload Sfx (SFX/UI/Music), zonder Sfx te wijzigen. Muziek: eigen lussen
## (Sfx.play_track kent enkel Hash & Dash). Alles statisch; de spelers hangen onder /root/Sfx.

const DIR := "res://games/scriptorium/assets/"
const MAX_POLY := 4
const DORIAN := [0, 2, 3, 5, 7, 9, 10, 12]
const PENTA := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]

static var _streams := {}
static var _pools := {}
static var _loops := {}
static var _music: AudioStreamPlayer
static var _pad: AudioStreamPlayer
static var _amb: AudioStreamPlayer
static var _pad_on := false
static var muted := false


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


## Effect: `name_` = bestandsnaam zonder extensie in assets/sfx (bv. "twine_bind").
static func play(name_: String, vol_db := 0.0, pitch := 1.0, rand_pitch := true) -> void:
	if muted:
		return
	var host := _host()
	if host == null:
		return
	var rel := "sfx/%s.wav" % name_
	var s := stream(rel)
	if s == null:
		rel = "sfx/%s.ogg" % name_
		s = stream(rel)
	if s == null:
		return
	var pool: Array = _pools.get(rel, [])
	_pools[rel] = pool
	var p: AudioStreamPlayer = null
	for q in pool:
		if is_instance_valid(q) and not q.playing:
			p = q
			break
	if p == null:
		if pool.size() < MAX_POLY:
			p = AudioStreamPlayer.new()
			p.stream = s
			p.bus = "SFX"
			host.add_child(p)
			pool.append(p)
		else:
			p = pool[0]
			pool.remove_at(0)
			pool.append(p)
	p.volume_db = vol_db
	p.pitch_scale = pitch * (randf_range(0.94, 1.06) if rand_pitch else 1.0)
	p.play()


## Letterzang (voorlezing): klinker volgens de letter, toonhoogte in D-dorisch (ART §8).
static func sing(ch: String, vol := -6.0) -> void:
	var c := ch.to_lower()
	var vowel := "sing_a"
	if c in ["o", "u", "w", "m", "b", "p"]:
		vowel = "sing_o"
	elif c in ["e", "i", "y", "j", "s", "z", "t", "d", "n", "l", "r"]:
		vowel = "sing_e"
	var st: int = DORIAN[absi(c.hash()) % DORIAN.size()]
	play(vowel, vol, pow(2.0, st / 12.0), false)


## Bit schrijven: ganzenveer kort (0) of lang (1).
static func bit(b: String, vol := -10.0) -> void:
	play("quill_1" if b == "1" else "quill_0", vol)


## Stijgende toon (draad, zoomtunnel): stap k in de pentatoniek.
static func pluck(k: int, name_ := "thread_pluck", vol := -8.0) -> void:
	var st: int = PENTA[clampi(k, 0, PENTA.size() - 1)]
	play(name_, vol, pow(2.0, st / 12.0) * 0.9, false)


## Gewicht +1: belletje, hoger per niveau.
static func bell(level: int, vol := -10.0) -> void:
	play("weight_bell", vol, pow(1.12, level), false)


static func loop(key: String, name_: String, on: bool, vol_db := -14.0) -> void:
	var host := _host()
	if host == null:
		return
	var p: AudioStreamPlayer = _loops.get(key)
	if p != null and not is_instance_valid(p):
		p = null
	if p == null:
		if not on or muted:
			return
		var s := stream("sfx/%s.wav" % name_)
		if s == null:
			s = stream("sfx/%s.ogg" % name_)
		if s == null:
			return
		p = AudioStreamPlayer.new()
		p.stream = s
		p.bus = "SFX"
		host.add_child(p)
		_loops[key] = p
	if on:
		if not p.playing:
			p.volume_db = -40.0
			p.play()
		p.create_tween().tween_property(p, "volume_db", vol_db, 0.4)
	elif p.playing:
		var tw := p.create_tween()
		tw.tween_property(p, "volume_db", -50.0, 0.4)
		tw.tween_callback(p.stop)


static func stop_loops() -> void:
	for k in _loops:
		var p: AudioStreamPlayer = _loops[k]
		if is_instance_valid(p):
			p.stop()


## Muziek per scherm: "title", "bench", "wake", "codex". Werkbank en Nachtwake hebben een synchrone tweede laag.
static func music(kind: String) -> void:
	var host := _host()
	if host == null:
		return
	if host.has_method("stop_layers"):
		host.stop_layers(0.4)
	var tr = host.get("_track")
	if tr is AudioStreamPlayer and (tr as AudioStreamPlayer).playing:
		(tr as AudioStreamPlayer).create_tween().tween_property(tr, "volume_db", -80.0, 0.6)
	var mp := "music/sc_title_loop.ogg"
	var pp := ""
	match kind:
		"bench":
			mp = "music/sc_bench_loop.ogg"
			pp = "music/sc_bench_pad_loop.ogg"
		"wake":
			mp = "music/sc_wake_loop.ogg"
			pp = "music/sc_wake_heart_loop.ogg"
		"codex":
			mp = "music/sc_codex_loop.ogg"
	var same := _music != null and is_instance_valid(_music) and _music.get_meta("rel", "") == mp and _music.playing
	_music = _swap(_music, mp, -9.0, "Music")
	if not same:
		if _pad != null and is_instance_valid(_pad):
			_pad.queue_free()
		_pad = null
		_pad_on = false
		if pp != "" and _music != null:
			_pad = _swap(null, pp, -80.0, "Music")
	_amb = _swap(_amb, "sfx/amb_scriptorium_loop.ogg", -16.0 if kind != "title" else -22.0, "SFX")


## Denklaag (werkbank, na 8 s nadenken) of hartslag (Nachtwake, weinig kaars).
static func pad(on: bool) -> void:
	if _pad == null or not is_instance_valid(_pad) or on == _pad_on:
		return
	_pad_on = on
	_pad.create_tween().tween_property(_pad, "volume_db", -10.0 if on else -80.0, 2.0 if on else 1.2)


## Muziek zachter (voorlezing, pauze) of terug.
static func duck(on: bool, deep := false) -> void:
	var to := (-40.0 if deep else -18.0) if on else -9.0
	if _music != null and is_instance_valid(_music):
		_music.create_tween().tween_property(_music, "volume_db", to, 0.6)
	if _pad != null and is_instance_valid(_pad) and _pad_on:
		_pad.create_tween().tween_property(_pad, "volume_db", -80.0 if on else -10.0, 0.6)


## Terugblik-jingle naar sterren (0..3).
static func jingle(n: int) -> void:
	var host := _host()
	if host == null or muted:
		return
	var s := stream("music/sc_jingle_%d.ogg" % clampi(n, 1, 3))
	if s == null:
		return
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = false
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.bus = "Music"
	p.volume_db = -4.0
	host.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


static func _swap(cur: AudioStreamPlayer, rel: String, vol: float, bus: String) -> AudioStreamPlayer:
	var host := _host()
	if cur != null and is_instance_valid(cur) and cur.get_meta("rel", "") == rel and cur.playing:
		cur.create_tween().tween_property(cur, "volume_db", vol, 0.5)
		return cur
	if cur != null and is_instance_valid(cur):
		var old := cur
		var tw := old.create_tween()
		tw.tween_property(old, "volume_db", -60.0, 0.8)
		tw.tween_callback(old.queue_free)
	var s := stream(rel)
	if s == null or muted or host == null:
		return null
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.bus = bus
	p.set_meta("rel", rel)
	host.add_child(p)
	p.volume_db = -50.0
	p.play()
	p.create_tween().tween_property(p, "volume_db", vol, 1.2)
	return p


static func stop_music() -> void:
	for p in [_music, _pad, _amb]:
		if p != null and is_instance_valid(p):
			var tw: Tween = p.create_tween()
			tw.tween_property(p, "volume_db", -60.0, 0.5)
			tw.tween_callback(p.queue_free)
	_music = null
	_pad = null
	_amb = null
	stop_loops()
