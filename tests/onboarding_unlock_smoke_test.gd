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
	var home_streak_calendar: VBoxContainer = main.get("_home_streak_calendar") as VBoxContainer
	var home_content: VBoxContainer = main.get_node("HomeLayer/Content") as VBoxContainer
	_assert(main.find_child("DebugHeartRewardButton", true, false) == null, "home UI must not expose a debug heart button")
	SaveManager.endless_state = {"date": "2000-01-01", "hearts": 1, "rewarded_heart_claimed": true}
	main.call("show_main_menu")
	await get_tree().process_frame
	await get_tree().process_frame
	_assert(SaveManager.get_endless_hearts() == SaveManager.ENDLESS_DAILY_HEARTS, "a new day must refill all Infinity hearts")
	var daily_refill_overlay: Control = main.get("_heart_reward_overlay") as Control
	_assert(is_instance_valid(daily_refill_overlay), "a visible main-menu day change must showcase the heart refill")
	var refill_title: Label = daily_refill_overlay.find_child("HeartRewardTitle", true, false) as Label
	_assert(refill_title != null and refill_title.text == SaveManager.text("daily_hearts_refilled"), "daily heart refill needs its own visible message")
	await get_tree().create_timer(3.0).timeout
	_assert(play_button.disabled, "Daily home action is disabled before level three")
	_assert(home_streak_calendar != null and not home_streak_calendar.visible, "The locked Daily card must show level progress instead of the streak calendar")
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
	_assert(home_streak_calendar.visible, "The unlocked Daily card must show the Nordic streak calendar")
	var home_previous_week: HBoxContainer = home_streak_calendar.find_child("HomeStreakPreviousWeek", true, false) as HBoxContainer
	var home_current_week: HBoxContainer = home_streak_calendar.find_child("HomeStreakCurrentWeek", true, false) as HBoxContainer
	_assert(home_previous_week != null and home_previous_week.get_child_count() == 7, "The home streak calendar must always show the full previous week")
	_assert(home_current_week != null and home_current_week.get_child_count() == 7, "The home streak calendar must always show the full current week")
	for day_node: Node in home_current_week.get_children():
		var day_cell: PanelContainer = day_node as PanelContainer
		var day_style: StyleBoxFlat = day_cell.get_theme_stylebox("panel") as StyleBoxFlat
		_assert(day_style != null and day_style.border_width_left > 0, "Every home streak day must retain a visible outline")
	var today_key: String = Time.get_date_string_from_system()
	var monday_key: String = str(main.call("_home_daily_week_monday", today_key))
	var joined_first_key: String = str(main.call("_home_date_key_offset", monday_key, -7))
	var joined_second_key: String = str(main.call("_home_date_key_offset", monday_key, -6))
	SaveManager.daily_results[joined_first_key] = {"completed": true, "won": true}
	SaveManager.daily_results[joined_second_key] = {"completed": true, "won": true}
	main.call("_refresh_home_streak_calendar", true)
	var joined_first: PanelContainer = home_streak_calendar.find_child("HomeStreakDay%s" % joined_first_key.replace("-", ""), true, false) as PanelContainer
	var joined_second: PanelContainer = home_streak_calendar.find_child("HomeStreakDay%s" % joined_second_key.replace("-", ""), true, false) as PanelContainer
	var joined_first_style: StyleBoxFlat = joined_first.get_theme_stylebox("panel") as StyleBoxFlat
	var joined_second_style: StyleBoxFlat = joined_second.get_theme_stylebox("panel") as StyleBoxFlat
	_assert(joined_first_style.corner_radius_top_right == 0 and joined_second_style.corner_radius_top_left == 0, "Adjacent successful Daily days must join into one streak capsule")
	_assert(joined_first_style.border_width_right > 0 and joined_second_style.border_width_left > 0, "Joined streak days must keep their individual outlines")
	_assert(daily_card.get_global_rect().end.x <= 390.5, "The streak calendar must keep the unlocked Daily card inside the phone viewport")
	_assert(GameState.start_new_game(GameState.DAILY_MODE), "Daily opens through game state after unlocking")

	main.call("show_settings")
	await get_tree().process_frame
	var settings_sheet: PanelContainer = main.get("_settings_sheet") as PanelContainer
	_assert(settings_sheet != null, "settings sheet opens for UI verification")
	for button_node: Node in settings_sheet.find_children("*", "Button", true, false):
		var settings_button: Button = button_node as Button
		var button_text: String = settings_button.text.to_lower()
		_assert(not button_text.contains("debug"), "settings must not expose development buttons")
	var settings_text: String = ""
	for label_node: Node in settings_sheet.find_children("*", "Label", true, false):
		settings_text += " " + (label_node as Label).text.to_lower()
	_assert(not settings_text.contains("attempts per puzzle") and not settings_text.contains("yrityksiä per pulma"), "settings must not expose an attempt-count option")

	print("ONBOARDING_UNLOCK_SMOKE_TEST_PASS")
	main.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _assert(condition: bool, description: String) -> void:
	if condition:
		return
	push_error("Onboarding unlock smoke test failed: %s" % description)
	get_tree().quit(1)
