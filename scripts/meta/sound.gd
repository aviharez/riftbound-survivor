extends Node
## Autoload "Sound": sound effects and music (design doc section 9). The files are made by
## tools/audio/make_audio.py (procedural synthesis, no samples): assets/audio/sfx/<name>.wav and
## assets/audio/music/<name>.ogg (looping). Settings (music / sfx on or off) live in user://settings.cfg,
## not in the save, so autotests and save resets never touch them.
##   Sound.play("kill")        one-shot, throttled per name, small random pitch so repeats don't drone
##   Sound.music("rift")       cross-fades to a loop ("" stops)

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const SETTINGS_PATH := "user://settings.cfg"
const POOL := 14
const MUSIC_DB := -9.0
const FADE := 0.8
# minimum seconds between two plays of the same effect (busy fights fire hundreds of hits a second)
const THROTTLE := {"hit": 0.045, "crit": 0.06, "kill": 0.035, "gem": 0.05, "coin": 0.08, "shoot": 0.06,
	"zap": 0.08, "explosion": 0.07, "hurt": 0.25, "freeze": 0.15, "ui_click": 0.03}
const VOLUME_DB := {"hit": -10.0, "crit": -6.0, "kill": -8.0, "gem": -10.0, "coin": -6.0, "shoot": -14.0,
	"zap": -8.0, "explosion": -4.0, "ui_click": -6.0, "whoosh": -6.0}

var music_on := true
var sfx_on := true
var _players: Array = []
var _streams := {}
var _last := {}
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_name := ""
var _time := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	for m in [_music_a, _music_b]:
		m.volume_db = -80.0
		add_child(m)
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		music_on = bool(cfg.get_value("audio", "music", true))
		sfx_on = bool(cfg.get_value("audio", "sfx", true))


func _process(delta: float) -> void:
	_time += delta


func _stream(path: String) -> AudioStream:
	if not _streams.has(path):
		_streams[path] = load(path) if ResourceLoader.exists(path) else null
	return _streams[path]


func play(name: String, pitch_jitter := 0.06, extra_db := 0.0) -> void:
	if not sfx_on:
		return
	var gap: float = THROTTLE.get(name, 0.0)
	if gap > 0.0 and _time - float(_last.get(name, -10.0)) < gap:
		return
	_last[name] = _time
	var s := _stream(SFX_DIR + name + ".wav")
	if s == null:
		return
	var p: AudioStreamPlayer = null
	for q in _players:
		if not q.playing:
			p = q
			break
	if p == null:
		return   # every voice busy: drop it rather than cut another sound
	p.stream = s
	p.volume_db = float(VOLUME_DB.get(name, -4.0)) + extra_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


func music(name: String) -> void:
	if name == _music_name:
		return
	_music_name = name
	var old := _music_a if _music_a.playing else _music_b
	var new := _music_b if old == _music_a else _music_a
	if old.playing:
		var tw := create_tween()
		tw.tween_property(old, "volume_db", -80.0, FADE)
		tw.tween_callback(old.stop)
	if name == "" or not music_on:
		return
	var s := _stream(MUSIC_DIR + name + ".ogg")
	if s == null:
		return
	new.stream = s
	new.volume_db = -40.0
	new.play()
	create_tween().tween_property(new, "volume_db", MUSIC_DB, FADE)


func set_music_on(on: bool) -> void:
	music_on = on
	var keep := _music_name
	_music_name = ""
	if on:
		music(keep)
	else:
		for m in [_music_a, _music_b]:
			m.stop()
		_music_name = keep
	_save()


func set_sfx_on(on: bool) -> void:
	sfx_on = on
	_save()


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_on)
	cfg.set_value("audio", "sfx", sfx_on)
	cfg.save(SETTINGS_PATH)


func _exit_tree() -> void:
	for p in _players + [_music_a, _music_b]:
		p.stop()
		p.stream = null
	_streams.clear()
