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

	for day: int in range(1, 11):
		var date_key := "2026-01-%02d" % day
		SaveManager.record_result(true, date_key, "daily", 15, 15, [2, 3, 4, 5], true, {}, 0, 0)
	assert(_snapshot("daily_legend").get("stars", 0) == 1, "Ten Daily wins must award the first Daily Legend star")
	assert(_snapshot("first_pyramid").get("stars", 0) == 1, "The first win must unlock First Pyramid")
	assert(_snapshot("perfect_precision").get("stars", 0) == 1, "Five mistake-free wins must award a precision star")
	assert(_snapshot("sharp_mind").get("stars", 0) == 1, "Five hint-free wins must award a Sharp Mind star")
	assert(_snapshot("burning_streak").get("stars", 0) >= 2, "A ten-day streak must award its first two stars")

	SaveManager.record_result(true, "", "unlimited", 15, 15, [2, 3, 4, 5], true, {}, 3, 1)
	assert(_snapshot("master_of_modes").get("stars", 0) == 1, "Winning both modes must unlock Master of Modes")
	assert(_snapshot("last_chance").get("stars", 0) == 1, "Winning with one attempt left must unlock Last Chance")
	assert(SaveManager.get_unseen_achievement_stars() > 0, "New stars must create a menu notification")

	var stars_before_reload := SaveManager.get_total_achievement_stars()
	SaveManager.load_data()
	assert(SaveManager.get_total_achievement_stars() == stars_before_reload, "Achievement progress must survive save/load")
	SaveManager.mark_achievements_seen()
	assert(SaveManager.get_unseen_achievement_stars() == 0, "Opening the panel must clear the new-star marker")

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main: Control = main_scene.instantiate()
	add_child(main)
	await get_tree().process_frame
	var trophy_button: Button = main.get_node("HomeLayer/Content/Header/AchievementsButton") as Button
	assert(trophy_button.icon != null, "Main menu achievement entry must use a real trophy icon")
	main.call("show_achievements")
	await get_tree().process_frame
	var overlay: Control = main.get_node("AchievementsOverlay") as Control
	var list: VBoxContainer = overlay.find_child("AchievementList", true, false) as VBoxContainer
	assert(list != null and list.get_child_count() == 10, "Achievement Hall must show every catalog entry")

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
