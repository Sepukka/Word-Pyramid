extends Node

var enabled: bool = true
var _player: AudioStreamPlayer
var _generator: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback
var _queue: Array[Dictionary] = []
var _active: Dictionary = {}

func _ready() -> void:
	enabled = bool(SaveManager.settings.get("sound_enabled", true))
	_generator = AudioStreamGenerator.new()
	_generator.mix_rate = 22050.0
	_generator.buffer_length = 0.3
	_player = AudioStreamPlayer.new()
	_player.stream = _generator
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback

func click() -> void:
	_enqueue(560.0, 0.045, 0.13)

func success() -> void:
	_enqueue(660.0, 0.10, 0.16)
	_enqueue(880.0, 0.14, 0.16)

func failure() -> void:
	_enqueue(190.0, 0.18, 0.18)

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
