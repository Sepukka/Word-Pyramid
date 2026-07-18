extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _ready() -> void:
	get_tree().root.size = Vector2i(390, 844)
	SaveManager.reset_all_data()
	SaveManager.complete_onboarding()
	PuzzleLoader.set_language("en")
	PuzzleLoader.load_puzzles()
	_assert(SaveManager.get_player_level() == 1, "fresh progression starts at level one")
	_assert(not SaveManager.is_daily_unlocked(), "Daily starts locked")
	_assert(not GameState.start_new_game(GameState.DAILY_MODE), "Daily cannot be opened through game state before level three")

	var hearts_before: int = SaveManager.get_endless_hearts()
	_assert(SaveManager.consume_endless_heart() == hearts_before, "starter Infinity does not consume onboarding hearts")
	_assert(GameState.start_new_game(GameState.UNLIMITED_MODE), "starter Infinity can open")
	_assert(PuzzleLoader.get_difficulty_tier(GameState.puzzle) == 1, "starter Infinity selects a tier-one puzzle")
	GameState.reset_debug_state()

	var main: Control = MAIN_SCENE.instantiate() as Control
	get_tree().root.add_child.call_deferred(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var play_button: Button = main.get("_play_button") as Button
	var daily_card: PanelContainer = main.get("_daily_card") as PanelContainer
	var card_meta: Label = main.get("_card_meta") as Label
	var home_content: VBoxContainer = main.get_node("HomeLayer/Content") as VBoxContainer
	_assert(play_button.disabled, "Daily home action is disabled before level three")
	_assert(play_button.icon != null, "Daily home action displays a real lock icon")
	var locked_style: StyleBoxFlat = daily_card.get_theme_stylebox("panel") as StyleBoxFlat
	_assert(locked_style != null and locked_style.bg_color.is_equal_approx(Color("eeebf1")), "Daily card uses its muted locked surface")
	_assert(card_meta.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "locked Daily explanation wraps on narrow phones")
	_assert(home_content.get_global_rect().end.x <= 390.5, "locked home content stays inside a 390-pixel phone viewport")
	_assert(daily_card.get_global_rect().end.x <= 390.5, "locked Daily card stays inside the phone viewport")
	PuzzleLoader.set_language("fi")
	main.call("_apply_home_texts")
	await get_tree().process_frame
	_assert(home_content.get_global_rect().end.x <= 390.5, "Finnish locked home content stays inside a 390-pixel phone viewport")
	_assert(daily_card.get_global_rect().end.x <= 390.5, "Finnish locked Daily card stays inside the phone viewport")
	PuzzleLoader.set_language("en")
	main.call("_apply_home_texts")

	# Completing the tutorial must route into the starter Infinity journey.
	main.call("_start_tutorial")
	await get_tree().create_timer(0.60).timeout
	_assert(not bool(main.get("_is_transitioning")), "tutorial board finishes its entrance before completion")
	main.call("_on_tutorial_exit", true)
	await get_tree().create_timer(1.15).timeout
	_assert(GameState.game_mode == GameState.UNLIMITED_MODE, "tutorial completion opens Infinity instead of Daily (mode=%s, transitioning=%s)" % [GameState.game_mode, str(main.get("_is_transitioning"))])
	_assert(PuzzleLoader.get_difficulty_tier(GameState.puzzle) == 1, "post-tutorial puzzle remains easy")
	GameState.reset_debug_state()

	var starter_puzzles: Array[Dictionary] = []
	for puzzle: Dictionary in PuzzleLoader.get_puzzles(GameState.UNLIMITED_MODE):
		if PuzzleLoader.get_difficulty_tier(puzzle) == 1:
			starter_puzzles.append(puzzle)
	_assert(starter_puzzles.size() >= 4, "each language has enough starter puzzles")
	for index: int in 4:
		var reward: Dictionary = SaveManager.record_progression_result(starter_puzzles[index], GameState.UNLIMITED_MODE, true, 5, 0, 0)
		_assert(int(reward.get("xp_gained", 0)) >= SaveManager.ONBOARDING_UNLIMITED_MIN_WIN_XP, "starter win %d grants onboarding XP" % (index + 1))
	_assert(SaveManager.get_player_level() >= SaveManager.DAILY_UNLOCK_LEVEL, "four starter wins reach level three")
	_assert(SaveManager.is_daily_unlocked(), "Daily unlocks at level three")

	main.call("show_main_menu")
	await get_tree().process_frame
	_assert(not play_button.disabled, "Daily home action becomes interactive at level three")
	_assert(play_button.icon == null, "lock icon is removed after unlocking")
	_assert(GameState.start_new_game(GameState.DAILY_MODE), "Daily opens through game state after unlocking")

	print("ONBOARDING_UNLOCK_SMOKE_TEST_PASS")
	main.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _assert(condition: bool, description: String) -> void:
	if condition:
		return
	push_error("Onboarding unlock smoke test failed: %s" % description)
	get_tree().quit(1)
