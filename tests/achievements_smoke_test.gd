extends Node

const TEST_SAVE: String = "res://.godot-test-data/achievements_save.json"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot-test-data"))
	SaveManager.save_path = TEST_SAVE
	SaveManager.reset_to_defaults()
	SaveManager.onboarding = {"version": SaveManager.ONBOARDING_VERSION, "language_selected": true}
	SaveManager.settings["language"] = "en"
	assert(SaveManager.get_max_achievement_stars() == 24, "Achievement catalog star count changed unexpectedly")
	assert(SaveManager.get_total_achievement_stars() == 0, "Fresh progress must not contain achievement stars")
	var emitted_unlocks: Array[Dictionary] = []
	var capture_unlock := func(unlock: Dictionary) -> void:
		emitted_unlocks.append(unlock.duplicate(true))
	SaveManager.achievement_unlocked.connect(capture_unlock)

	for day: int in range(1, 11):
		var date_key := "2026-01-%02d" % day
		SaveManager.record_result(true, date_key, "daily", 15, 15, [2, 3, 4, 5], true, {}, 0, 0)
	assert(_snapshot("daily_legend").get("stars", 0) == 1, "Ten Daily wins must award the first Daily Legend star")
	assert(_snapshot("first_pyramid").get("stars", 0) == 1, "The first win must unlock First Pyramid")
	assert(_snapshot("perfect_precision").get("stars", 0) == 1, "Five mistake-free wins must award a precision star")
	assert(_snapshot("sharp_mind").get("stars", 0) == 1, "Five hint-free wins must award a Sharp Mind star")
	assert(_snapshot("burning_streak").get("stars", 0) >= 2, "A ten-day streak must award its first two stars")
	assert(not emitted_unlocks.is_empty(), "Unlocking an achievement must emit banner data")
	assert(str(emitted_unlocks[0].get("title", "")) != "", "Unlock banner data must include the achievement title")
	assert(int(emitted_unlocks[0].get("unlocked_star", 0)) == 1, "Unlock banner data must identify the earned star")

	SaveManager.record_result(true, "", "unlimited", 15, 15, [2, 3, 4, 5], true, {}, 3, 1)
	assert(_snapshot("master_of_modes").get("stars", 0) == 1, "Winning both modes must unlock Master of Modes")
	assert(_snapshot("last_chance").get("stars", 0) == 1, "Winning with one attempt left must unlock Last Chance")
	assert(SaveManager.get_unseen_achievement_stars() > 0, "New stars must create a menu notification")

	var stars_before_reload := SaveManager.get_total_achievement_stars()
	SaveManager.load_data()
	assert(SaveManager.get_total_achievement_stars() == stars_before_reload, "Achievement progress must survive save/load")
	SaveManager.mark_achievements_seen()
	assert(SaveManager.get_unseen_achievement_stars() == 0, "Opening the panel must clear the new-star marker")
	SaveManager.settings["language"] = "fi"

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main: Control = main_scene.instantiate()
	add_child(main)
	await get_tree().process_frame
	var trophy_button: Button = main.get_node("HomeLayer/Content/Header/AchievementsButton") as Button
	assert(trophy_button.icon != null, "Main menu achievement entry must use a real trophy icon")
	main.call("show_achievements")
	await get_tree().process_frame
	await get_tree().process_frame
	var overlay: Control = main.get_node("AchievementsOverlay") as Control
	var list: VBoxContainer = overlay.find_child("AchievementList", true, false) as VBoxContainer
	assert(list != null and list.get_child_count() == 10, "Achievement Hall must show every catalog entry")
	var right_edge: float = overlay.get_global_rect().end.x
	for section_name: String in ["AchievementHeader", "AchievementSummary", "AchievementScroll"]:
		var section: Control = overlay.find_child(section_name, true, false) as Control
		assert(section != null and section.get_global_rect().end.x <= right_edge + 0.5, "%s overflowed the phone viewport" % section_name)
	for card: Control in list.get_children():
		assert(card.get_global_rect().end.x <= right_edge + 0.5, "Achievement card overflowed the phone viewport: %s" % card.name)

	var banner_sample: Dictionary = _snapshot("daily_legend").duplicate(true)
	banner_sample["unlocked_star"] = 1
	main.call("_on_achievement_unlocked", banner_sample)
	await get_tree().process_frame
	await get_tree().process_frame
	var banner: Control = main.find_child("AchievementUnlockBanner", true, false) as Control
	assert(banner != null, "An earned achievement must create a visible unlock banner")
	assert(banner.size.y <= 80.0, "Unlock banner must stay compact and out of the gameplay's way")
	assert(banner.get_global_rect().end.x <= right_edge + 0.5, "Unlock banner overflowed the phone viewport")
	assert(banner.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Unlock banner must not block controls behind it")

	SaveManager.achievement_unlocked.disconnect(capture_unlock)
	main.queue_free()
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	SaveManager.save_path = SaveManager.SAVE_PATH
	SaveManager.reset_to_defaults()
	print("ACHIEVEMENTS_SMOKE_TEST_PASS")
	get_tree().quit()

func _snapshot(achievement_id: String) -> Dictionary:
	for snapshot: Dictionary in SaveManager.get_achievement_snapshots():
		if str(snapshot.get("id", "")) == achievement_id:
			return snapshot
	return {}
