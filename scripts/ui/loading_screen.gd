extends CanvasLayer

const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
const MINIMUM_DISPLAY_TIME: float = 1.65
const FADE_DURATION: float = 0.38
const PROGRESS_WIDTH: float = 116.0

@onready var _screen: Control = $Screen
@onready var _progress_fill: Panel = $Screen/Loader/ProgressFill
@onready var _loader_dots: Array[Panel] = [
	$Screen/Loader/DotPurple,
	$Screen/Loader/DotTeal,
	$Screen/Loader/DotYellow,
]

var _started_at: float
var _displayed_progress: float = 0.0
var _resource_progress: Array = []
var _dot_origins: Array[Vector2] = []
var _transitioning: bool = false
var _thread_request_failed: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_started_at = Time.get_ticks_msec() / 1000.0
	for dot: Panel in _loader_dots:
		dot.pivot_offset = dot.size * 0.5
		_dot_origins.append(dot.position)

	var request_error: Error = ResourceLoader.load_threaded_request(
		MAIN_SCENE_PATH,
		"PackedScene",
		true
	)
	_thread_request_failed = request_error != OK

func _process(delta: float) -> void:
	var elapsed: float = Time.get_ticks_msec() / 1000.0 - _started_at
	_animate_loading_indicator(elapsed, delta)

	if _transitioning:
		return

	var loaded: bool = _thread_request_failed
	if not _thread_request_failed:
		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(
			MAIN_SCENE_PATH,
			_resource_progress
		)
		loaded = status == ResourceLoader.THREAD_LOAD_LOADED
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_thread_request_failed = true
			loaded = true

	if loaded and elapsed >= MINIMUM_DISPLAY_TIME:
		_finish_loading()

func _animate_loading_indicator(elapsed: float, delta: float) -> void:
	var time_progress: float = clampf(elapsed / MINIMUM_DISPLAY_TIME, 0.0, 1.0)
	var threaded_progress: float = 0.0
	if not _resource_progress.is_empty():
		threaded_progress = clampf(float(_resource_progress[0]), 0.0, 1.0)
	var target_progress: float = maxf(time_progress, threaded_progress)
	_displayed_progress = move_toward(
		_displayed_progress,
		target_progress,
		delta * 0.72
	)
	_progress_fill.size.x = maxf(8.0, PROGRESS_WIDTH * _displayed_progress)

	for index: int in _loader_dots.size():
		var pulse: float = (sin(elapsed * 5.2 - index * 0.78) + 1.0) * 0.5
		var lift: float = pow(pulse, 2.2) * 5.0
		var dot: Panel = _loader_dots[index]
		dot.position = _dot_origins[index] + Vector2(0.0, -lift)
		var scale_value: float = 0.88 + pulse * 0.18
		dot.scale = Vector2.ONE * scale_value
		dot.modulate.a = 0.66 + pulse * 0.34

func _finish_loading() -> void:
	if _transitioning:
		return
	_transitioning = true
	_displayed_progress = 1.0
	_progress_fill.size.x = PROGRESS_WIDTH
	await get_tree().create_timer(0.12).timeout

	var packed_main: PackedScene
	if _thread_request_failed:
		packed_main = load(MAIN_SCENE_PATH) as PackedScene
	else:
		packed_main = ResourceLoader.load_threaded_get(MAIN_SCENE_PATH) as PackedScene
	if packed_main == null:
		push_error("Loading screen could not load %s." % MAIN_SCENE_PATH)
		_transitioning = false
		return

	var main_scene: Node = packed_main.instantiate()
	get_tree().root.add_child(main_scene)
	get_tree().current_scene = main_scene
	await get_tree().process_frame

	var fade: Tween = create_tween()
	fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade.set_trans(Tween.TRANS_QUAD)
	fade.set_ease(Tween.EASE_IN_OUT)
	fade.tween_property(_screen, "modulate:a", 0.0, FADE_DURATION)
	await fade.finished
	queue_free()
