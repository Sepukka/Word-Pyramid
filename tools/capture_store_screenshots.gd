extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const DEFAULT_OUTPUT_DIR: String = "res://assets/store/screenshots/phone"
const DEFAULT_STORE_IMAGE_SIZE: Vector2i = Vector2i(1080, 1920)
const MAX_CAPTURE_VIEWPORT_HEIGHT: int = 960

var _main: Control
var _output_dir: String = DEFAULT_OUTPUT_DIR
var _store_image_size: Vector2i = DEFAULT_STORE_IMAGE_SIZE
var _capture_viewport_size: Vector2i
var _home_only: bool = false
var _locked_home: bool = false

func _ready() -> void:
	_read_capture_arguments()
	_configure_capture_viewport()
	await get_tree().process_frame
	await get_tree().process_frame
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(_output_dir)
	)
	assert(directory_error == OK, "Could not create screenshot directory: %s" % _output_dir)

	# Never touch the player's real save while producing marketing material.
	SaveManager.save_path = "res://.godot/store_capture_save.json"
	SaveManager.reset_to_defaults()
	SaveManager.complete_onboarding()
	SaveManager.progression["total_xp"] = (
		0
		if _locked_home
		else SaveManager.xp_threshold_for_level(SaveManager.DAILY_UNLOCK_LEVEL)
	)
	SaveManager.endless_state = {
		"date": Time.get_date_string_from_system(),
		"hearts": SaveManager.ENDLESS_DAILY_HEARTS,
		"rewarded_heart_claimed": false
	}
	PuzzleLoader.set_language("en")
	SaveManager.settings["language"] = "en"
	SaveManager.settings["analytics_consent_answered"] = true
	SaveManager.settings["analytics_enabled"] = false
	SaveManager.save_data()

	_main = MAIN_SCENE.instantiate() as Control
	get_tree().root.add_child.call_deferred(_main)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.45).timeout

	await _capture("01-home.png")
	if _home_only:
		print("STORE_HOME_SCREENSHOT_CAPTURED")
		get_tree().quit()
		return
	await _capture_daily_selection()
	await _capture_solved_groups()
	await _capture_infinity()
	await _capture_results()

	print("STORE_SCREENSHOTS_CAPTURED")
	get_tree().quit()

func _capture_daily_selection() -> void:
	assert(GameState.start_new_game(GameState.DAILY_MODE))
	await _main.show_game()
	var words: Array[String] = _group_words(5)
	for word: String in words:
		GameState.toggle_word(word)
	await get_tree().create_timer(0.38).timeout
	await _capture("02-daily-selection.png")

func _capture_solved_groups() -> void:
	GameState.check_selection()
	await get_tree().create_timer(1.35).timeout
	var words: Array[String] = _group_words(4)
	for word: String in words:
		GameState.toggle_word(word)
	GameState.check_selection()
	await get_tree().create_timer(1.35).timeout
	await _capture("03-solved-groups.png")

func _capture_infinity() -> void:
	# Recreate Main between modes. This prevents any unfinished Daily row tween
	# from influencing the clean Infinity marketing frame.
	_main.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(GameState.start_new_game(GameState.UNLIMITED_MODE))
	_main = MAIN_SCENE.instantiate() as Control
	get_tree().root.add_child.call_deferred(_main)
	await get_tree().process_frame
	await get_tree().process_frame
	await _main.show_game()
	var words: Array[String] = _group_words(3)
	for word: String in words:
		GameState.toggle_word(word)
	await get_tree().create_timer(0.38).timeout
	await _capture("04-infinity-mode.png")

func _capture_results() -> void:
	GameState.debug_auto_solve()
	# The solution reveals row by row before the full-screen aftermath arrives.
	await get_tree().create_timer(8.2).timeout
	await _capture("05-results.png")

func _capture(file_name: String) -> void:
	# Scene changes can briefly let desktop window sizing follow a Control's
	# minimum size. Restore the device viewport before every individual frame.
	if get_window().size != _capture_viewport_size:
		get_window().size = _capture_viewport_size
		await get_tree().process_frame
		await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	# Google Play requires an opaque 24-bit PNG without an alpha channel.
	image.convert(Image.FORMAT_RGB8)
	# The viewport is rendered at the exact same aspect ratio as the delivery
	# image. Resizing therefore increases resolution without stretching the UI.
	assert(
		image.get_width() * _store_image_size.y == image.get_height() * _store_image_size.x,
		"Capture viewport aspect ratio does not match the store image size."
	)
	if image.get_size() != _store_image_size:
		image.resize(_store_image_size.x, _store_image_size.y, Image.INTERPOLATE_LANCZOS)
	var target: String = "%s/%s" % [_output_dir, file_name]
	var error: Error = image.save_png(target)
	assert(error == OK, "Could not save store screenshot: %s" % target)
	print("CAPTURED %s (%dx%d)" % [target, image.get_width(), image.get_height()])

func _read_capture_arguments() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = 0
	while index < arguments.size():
		var argument: String = arguments[index]
		if argument == "--output-dir" and index + 1 < arguments.size():
			_output_dir = arguments[index + 1]
			index += 2
		elif argument == "--width" and index + 1 < arguments.size():
			_store_image_size.x = maxi(320, int(arguments[index + 1]))
			index += 2
		elif argument == "--height" and index + 1 < arguments.size():
			_store_image_size.y = maxi(320, int(arguments[index + 1]))
			index += 2
		elif argument == "--home-only":
			_home_only = true
			index += 1
		elif argument == "--locked-home":
			_locked_home = true
			_home_only = true
			index += 1
		else:
			index += 1

func _configure_capture_viewport() -> void:
	var divisor: int = _greatest_common_divisor(_store_image_size.x, _store_image_size.y)
	var aspect_units: Vector2i = Vector2i(
		_store_image_size.x / divisor,
		_store_image_size.y / divisor
	)
	var scale: int = maxi(1, MAX_CAPTURE_VIEWPORT_HEIGHT / aspect_units.y)
	var viewport_size: Vector2i = aspect_units * scale
	_capture_viewport_size = viewport_size
	get_window().size = _capture_viewport_size
	print(
		"CAPTURE_VIEWPORT %dx%d -> STORE_IMAGE %dx%d"
		% [
			viewport_size.x,
			viewport_size.y,
			_store_image_size.x,
			_store_image_size.y
		]
	)

func _greatest_common_divisor(first: int, second: int) -> int:
	var left: int = absi(first)
	var right: int = absi(second)
	while right != 0:
		var remainder: int = left % right
		left = right
		right = remainder
	return maxi(1, left)

func _group_words(row_length: int) -> Array[String]:
	for value: Variant in GameState.puzzle.get("groups", []):
		if value is Dictionary:
			var group: Dictionary = value
			if int(group.get("size", 0)) == row_length:
				var words: Array[String] = []
				for word: Variant in group.get("words", []):
					words.append(str(word))
				return words
	return []
