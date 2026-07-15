extends Node

const SELECT_CLICK: AudioStream = preload("res://addons/kenney_ui_audio/click1.wav")
const DESELECT_CLICK: AudioStream = preload("res://addons/kenney_ui_audio/click2.wav")
const BACKGROUND_MUSIC: AudioStreamOggVorbis = preload("res://assets/audio/music/word_pyramid_background_loop.ogg")
const SAMPLE_PLAYER_COUNT: int = 4

var enabled: bool = true
var music_enabled: bool = true
var _player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _generator: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback
var _queue: Array[Dictionary] = []
var _active: Dictionary = {}
var _sample_players: Array[AudioStreamPlayer] = []
var _next_sample_player: int = 0

func _ready() -> void:
	enabled = bool(SaveManager.settings.get("sound_enabled", true))
	music_enabled = bool(SaveManager.settings.get("music_enabled", true))
	_generator = AudioStreamGenerator.new()
	_generator.mix_rate = 22050.0
	_generator.buffer_length = 0.3
	_player = AudioStreamPlayer.new()
	_player.stream = _generator
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	for _index: int in SAMPLE_PLAYER_COUNT:
		var sample_player: AudioStreamPlayer = AudioStreamPlayer.new()
		sample_player.volume_db = -8.0
		add_child(sample_player)
		_sample_players.append(sample_player)
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = BACKGROUND_MUSIC
	_music_player.volume_db = -18.0
	add_child(_music_player)
	_sync_music_state()

func click(selecting: bool = true) -> void:
	_play_sample(SELECT_CLICK if selecting else DESELECT_CLICK)

func success() -> void:
	_enqueue(660.0, 0.10, 0.16)
	_enqueue(880.0, 0.14, 0.16)

func failure() -> void:
	_enqueue(190.0, 0.18, 0.18)

func set_music_enabled(value: bool) -> void:
	music_enabled = value
	_sync_music_state()

func _sync_music_state() -> void:
	if not is_instance_valid(_music_player):
		return
	if music_enabled:
		if not _music_player.playing:
			_music_player.play()
	elif _music_player.playing:
		_music_player.stop()

func _play_sample(stream: AudioStream) -> void:
	if not enabled or _sample_players.is_empty():
		return
	var sample_player: AudioStreamPlayer = _sample_players[_next_sample_player]
	_next_sample_player = (_next_sample_player + 1) % _sample_players.size()
	sample_player.stream = stream
	sample_player.play()

func _enqueue(frequency: float, duration: float, volume: float) -> void:
	if enabled:
		_queue.append({"frequency": frequency, "remaining": duration, "volume": volume, "phase": 0.0})

func _process(_delta: float) -> void:
	if _playback == null:
		_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
		return
	var frames: int = _playback.get_frames_available()
	for _index: int in frames:
		if _active.is_empty() and not _queue.is_empty():
			_active = _queue.pop_front()
		if _active.is_empty():
			_playback.push_frame(Vector2.ZERO)
			continue
		var phase: float = float(_active["phase"])
		var sample: float = sin(phase) * float(_active["volume"])
		_playback.push_frame(Vector2(sample, sample))
		_active["phase"] = phase + TAU * float(_active["frequency"]) / _generator.mix_rate
		_active["remaining"] = float(_active["remaining"]) - 1.0 / _generator.mix_rate
		if float(_active["remaining"]) <= 0.0:
			_active.clear()
