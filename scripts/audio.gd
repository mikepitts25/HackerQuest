extends Node
## Central audio (autoload "Audio"). One-shot SFX from a small player pool and a
## single looping music track. Files live in res://assets/audio/sfx/<name>.mp3
## and res://assets/audio/music/<track>.mp3 — generated via tools/gen_audio.sh
## (ElevenLabs). A missing file is a silent no-op, so the game runs the same with
## or without the audio assets present.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const POOL := 8

var _sfx_players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _music_track := ""
var _cache := {}  # path -> AudioStream (null = known-missing)


func _ready() -> void:
	_ensure_buses()
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)

	# Centralized event SFX, so gameplay code stays clean of audio calls.
	GameState.busted.connect(func() -> void: sfx("bust"))
	GameState.trace_started.connect(func(_r: String, _s: float) -> void: sfx("alarm"))
	GameState.trace_cleared.connect(func(escaped: bool) -> void:
		if escaped:
			sfx("escape"))
	GameState.day_changed.connect(func(_d: int) -> void: sfx("sleep"))
	GameState.jobs_changed.connect(func() -> void: sfx("gig"))
	GameState.leveled_up.connect(func() -> void: sfx("levelup"))


func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


# Play a one-shot sound effect (round-robins the player pool). A little random
# pitch keeps repeated sounds from feeling mechanical.
func sfx(name: String, pitch_var := 0.06) -> void:
	var stream := _load(SFX_DIR + name + ".mp3")
	if stream == null:
		return
	var p := _sfx_players[_next]
	_next = (_next + 1) % POOL
	p.stream = stream
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()


# Switch the looping background track (no-op if it's already playing).
func music(track: String) -> void:
	if track == _music_track:
		return
	_music_track = track
	var stream := _load(MUSIC_DIR + track + ".mp3")
	if stream == null:
		_music.stop()
		return
	_music.stream = stream
	_music.play()


func set_music_volume_db(db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)


func set_sfx_volume_db(db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)


func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path)
		# Music loops; one-shot SFX don't.
		if stream is AudioStreamMP3:
			stream.loop = path.begins_with(MUSIC_DIR)
	_cache[path] = stream
	return stream
