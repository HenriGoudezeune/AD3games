class_name TtSnd
extends Object
## Trietuin-geluid: speelt de effecten uit games/trietuin/assets/sfx/ op de bussen van de gedeelde autoload Sfx
## (SFX/UI/Music bestaan daar al), zonder Sfx te wijzigen. Muziek: seizoenslus (assets/music/tt_<id>_loop.ogg, als
## die bestaat) + ambience-lus per seizoen. Alles statisch; de spelers hangen onder /root/Sfx.

const DIR := "res://games/trietuin/assets/"
const MAX_POLY := 5

static var _streams := {}
static var _pools := {}
static var _loops := {}
static var _music: AudioStreamPlayer
static var _amb: AudioStreamPlayer
static var _bloom: AudioStreamPlayer
static var _music_path := ""
static var _amb_path := ""
static var muted := false   # bots/tests


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


## Speel een effect: `name` = bestandsnaam zonder extensie in assets/sfx ("bud_plop").
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


## Toonhoogte per letter (houten tik, toonhoogte = positie in het alfabet).
static func letter(ch: String, letters: String) -> void:
	var i := maxi(0, letters.find(ch))
	var semis := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21]
	var st: int = semis[i % semis.size()] + 12 * (i / semis.size())
	play("letter_tick", -3.0, pow(2.0, st / 12.0) * 0.9, false)


## Noot per parel (finale): a = C, c = E, g = G, t = A, b = D, _ = hoge C.
static func note(ch: String, vol := -4.0) -> void:
	var map := {"a": "note_a", "b": "note_b", "c": "note_c", "g": "note_g", "t": "note_t"}
	if map.has(ch):
		play(map[ch], vol, 1.0, false)
	else:
		play("note_end", vol, 1.0, false)


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


## Seizoensmuziek (basis + bloei-laag, synchroon) + ambience. season: 0..3 (TtPal), 4 = finale, -1 = titel/kaart.
static func season_music(season: int) -> void:
	var host := _host()
	if host == null:
		return
	if host.has_method("stop_layers"):
		host.stop_layers(0.4)
	var tr = host.get("_track")
	if tr is AudioStreamPlayer and (tr as AudioStreamPlayer).playing:
		(tr as AudioStreamPlayer).create_tween().tween_property(tr, "volume_db", -80.0, 0.6)
	var s := clampi(season, 0, 3)
	var id: String = TtPal.season(s).id
	var mp := "music/tt_%s_loop.ogg" % id
	var bp := "music/tt_%s_bloom_loop.ogg" % id
	if season == 4:
		mp = "music/tt_finale_loop.ogg"
		bp = ""
	elif season < 0:
		mp = "music/tt_title_loop.ogg"
		bp = ""
	var same: bool = _music != null and is_instance_valid(_music) and _music.has_meta("rel") and _music.get_meta("rel") == mp
	_music = _swap(_music, mp, -6.0, "Music")
	if not same:
		if _bloom != null and is_instance_valid(_bloom):
			_bloom.queue_free()
		_bloom = null
		if bp != "" and stream(bp) != null and _music != null:
			_bloom = _swap(null, bp, -80.0, "Music")
	_music_path = mp
	var ap := "sfx/amb_%s_loop.ogg" % id
	_amb = _swap(_amb, ap, -16.0 if season >= 0 else -22.0, "SFX")
	_amb_path = ap


## Bloei-laag aan/uit (Bloei, sterren).
static func bloom_layer(on: bool) -> void:
	if _bloom != null and is_instance_valid(_bloom):
		_bloom.create_tween().tween_property(_bloom, "volume_db", -6.0 if on else -80.0, 0.8 if on else 1.2)


## Rapportjingle naar sterren (1..3).
static func jingle(n: int) -> void:
	var host := _host()
	if host == null or muted:
		return
	var s := stream("music/tt_jingle_%d.ogg" % clampi(n, 1, 3))
	if s == null:
		return
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = false
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.bus = "Music"
	p.volume_db = -2.0
	host.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


static func _swap(cur: AudioStreamPlayer, rel: String, vol: float, bus: String) -> AudioStreamPlayer:
	var host := _host()
	if cur != null and is_instance_valid(cur) and cur.has_meta("rel") and cur.get_meta("rel") == rel and cur.playing:
		cur.create_tween().tween_property(cur, "volume_db", vol, 0.5)
		return cur
	if cur != null and is_instance_valid(cur):
		var old := cur
		var tw := old.create_tween()
		tw.tween_property(old, "volume_db", -60.0, 0.8)
		tw.tween_callback(old.queue_free)
	var s := stream(rel)
	if s == null or muted:
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


## Muziek zachter (pauze/rapport) of terug.
static func duck(on: bool) -> void:
	if _music != null and is_instance_valid(_music):
		_music.create_tween().tween_property(_music, "volume_db", -14.0 if on else -4.0, 0.4)


static func stop_music() -> void:
	for p in [_music, _amb, _bloom]:
		if p != null and is_instance_valid(p):
			var tw: Tween = p.create_tween()
			tw.tween_property(p, "volume_db", -60.0, 0.5)
			tw.tween_callback(p.queue_free)
	_music = null
	_amb = null
	_bloom = null
