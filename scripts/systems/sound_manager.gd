extends Node

const SELECT_CLICK: AudioStream = preload("res://addons/kenney_ui_audio/click1.wav")
const DESELECT_CLICK: AudioStream = preload("res://addons/kenney_ui_audio/click2.wav")
const ROW_CORRECT: AudioStream = preload("res://assets/audio/sfx/kenney_interface/row_correct.wav")
const WRONG_ANSWER: AudioStream = preload("res://assets/audio/sfx/kenney_interface/wrong_answer.wav")
const BACKGROUND_MUSIC: AudioStreamOggVorbis = preload("res://assets/audio/music/word_pyramid_background_loop.ogg")
const SAMPLE_PLAYER_COUNT: int = 4
const SKIP_UI_CLICK_SOUND_META: StringName = &"skip_ui_click_sound"

var enabled: bool = true
var music_enabled: bool = true
var _music_player: AudioStreamPlayer
var _sample_players: Array[AudioStreamPlayer] = []
var _next_sample_player: int = 0

func _ready() -> void:
	enabled = bool(SaveManager.settings.get("sound_enabled", true))
	music_enabled = bool(SaveManager.settings.get("music_enabled", true))
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
