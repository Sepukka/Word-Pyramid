extends Node

const SELECT_CLICK: AudioStream = preload("res://assets/audio/sfx/kenney_interface/menu_select.wav")
const DESELECT_CLICK: AudioStream = preload("res://assets/audio/sfx/kenney_interface/menu_deselect.wav")
const ROW_CORRECT: AudioStream = preload("res://assets/audio/sfx/kenney_interface/row_correct.wav")
const WRONG_ANSWER: AudioStream = preload("res://assets/audio/sfx/kenney_interface/wrong_answer_b.wav")
const GAME_COMPLETE: AudioStream = preload("res://assets/audio/sfx/mixkit/game_complete.wav")
const LEVEL_UP: AudioStream = preload("res://assets/audio/sfx/pixabay/level_up.mp3")
const XP_GAIN: AudioStreamWAV = preload("res://assets/audio/sfx/mixkit/xp_gain_loop.wav")
const ACHIEVEMENT_UNLOCK: AudioStream = preload("res://assets/audio/sfx/mixkit/achievement_unlocked.wav")
const WORD_MOVE: AudioStream = preload("res://assets/audio/sfx/mixkit/word_move.wav")
const XP_COMPLETE: AudioStream = preload("res://assets/audio/sfx/mixkit/xp_complete.wav")
const HEART_GAIN: AudioStream = preload("res://assets/audio/sfx/mixkit/heart_gain.wav")
const BACKGROUND_MUSIC: AudioStreamOggVorbis = preload("res://assets/audio/music/word_pyramid_background_loop.ogg")
const SAMPLE_PLAYER_COUNT: int = 4
const SKIP_UI_CLICK_SOUND_META: StringName = &"skip_ui_click_sound"
const XP_GAIN_VOLUME_DB: float = -12.0

var enabled: bool = true
var music_enabled: bool = true
var _music_player: AudioStreamPlayer
var _sample_players: Array[AudioStreamPlayer] = []
var _next_sample_player: int = 0
var _xp_player: AudioStreamPlayer
var _xp_fade_tween: Tween

func _ready() -> void:
	enabled = bool(SaveManager.settings.get("sound_enabled", true))
	music_enabled = bool(SaveManager.settings.get("music_enabled", true))
	for _index: int in SAMPLE_PLAYER_COUNT:
		var sample_player: AudioStreamPlayer = AudioStreamPlayer.new()
		sample_player.volume_db = -8.0
		add_child(sample_player)
		_sample_players.append(sample_player)
	_xp_player = AudioStreamPlayer.new()
	_xp_player.stream = _xp_loop_stream()
	_xp_player.volume_db = XP_GAIN_VOLUME_DB
	add_child(_xp_player)
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = BACKGROUND_MUSIC
	_music_player.volume_db = -18.0
	add_child(_music_player)
	_sync_music_state()
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_register_existing_buttons")

func click(selecting: bool = true) -> void:
	_play_sample(SELECT_CLICK if selecting else DESELECT_CLICK)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_register_ui_button(node as BaseButton)

func _register_existing_buttons() -> void:
	_register_buttons_in(get_tree().root)

func _register_buttons_in(node: Node) -> void:
	if node is BaseButton:
		_register_ui_button(node as BaseButton)
	for child: Node in node.get_children():
		_register_buttons_in(child)

func _register_ui_button(button: BaseButton) -> void:
	if bool(button.get_meta(SKIP_UI_CLICK_SOUND_META, false)):
		return
	if not button.pressed.is_connected(_on_ui_button_pressed):
		button.pressed.connect(_on_ui_button_pressed)

func _on_ui_button_pressed() -> void:
	click()

func success() -> void:
	_play_sample(ROW_CORRECT, -9.0)

func failure() -> void:
	_play_sample(WRONG_ANSWER, -8.5)

func game_complete(delay: float = 0.34) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	_play_sample(GAME_COMPLETE, -7.5)

func level_up() -> void:
	_play_sample(LEVEL_UP, -7.5)

func xp_gain() -> void:
	if not enabled or not is_instance_valid(_xp_player):
		return
	if _xp_fade_tween != null and _xp_fade_tween.is_running():
		_xp_fade_tween.kill()
	_xp_player.volume_db = XP_GAIN_VOLUME_DB
	_xp_player.play()

func stop_xp_gain(fade_duration: float = 0.12) -> void:
	if not is_instance_valid(_xp_player) or not _xp_player.playing:
		return
	if _xp_fade_tween != null and _xp_fade_tween.is_running():
		_xp_fade_tween.kill()
	if fade_duration <= 0.0:
		_xp_player.stop()
		_xp_player.volume_db = XP_GAIN_VOLUME_DB
		return
	_xp_fade_tween = create_tween()
	_xp_fade_tween.tween_property(_xp_player, "volume_db", -36.0, fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_xp_fade_tween.tween_callback(func() -> void:
		_xp_player.stop()
		_xp_player.volume_db = XP_GAIN_VOLUME_DB
	)

func achievement_unlock() -> void:
	_play_sample(ACHIEVEMENT_UNLOCK, -9.0)

func word_move() -> void:
	_play_sample(WORD_MOVE, -13.0)

func xp_complete() -> void:
	_play_sample(XP_COMPLETE, -15.5)

func heart_gain() -> void:
	_play_sample(HEART_GAIN, -11.5)

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

func _play_sample(stream: AudioStream, volume_db: float = -8.0) -> void:
	if not enabled or _sample_players.is_empty():
		return
	var sample_player: AudioStreamPlayer = _sample_players[_next_sample_player]
	_next_sample_player = (_next_sample_player + 1) % _sample_players.size()
	sample_player.stream = stream
	sample_player.volume_db = volume_db
	sample_player.play()

func _xp_loop_stream() -> AudioStreamWAV:
	var loop_stream: AudioStreamWAV = XP_GAIN.duplicate() as AudioStreamWAV
	loop_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	var bytes_per_sample: int = 1 if loop_stream.format == AudioStreamWAV.FORMAT_8_BITS else 2
	var channel_count: int = 2 if loop_stream.stereo else 1
	loop_stream.loop_begin = 0
	loop_stream.loop_end = int(loop_stream.data.size() / (bytes_per_sample * channel_count))
	return loop_stream
