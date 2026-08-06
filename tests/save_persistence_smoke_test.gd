extends Node

const TEST_SAVE: String = "res://.godot-test-data/save_persistence.json"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot-test-data"))
	SaveManager.save_path = TEST_SAVE
	SaveManager.reset_to_defaults()
	SaveManager.settings["language"] = "fi"
	SaveManager.settings["sound_enabled"] = false
	SaveManager.settings["music_enabled"] = false
	# Simulate a legacy save made while the attempt selector still existed.
	SaveManager.settings["attempts"] = 5
	SaveManager.statistics = {"wins": 7, "losses": 2, "streak": 3, "best_streak": 5}
	SaveManager.active_game = {"mode": "daily", "attempts_left": 2, "selected_words": ["A"]}
	SaveManager.daily_results = {"2026-07-21": {"completed": true, "won": true}}
	SaveManager.played_puzzle_ids = {"daily": ["daily-1"], "unlimited": ["unlimited-1"]}
	SaveManager.endless_state = {"date": "2026-07-21", "hearts": 1, "rewarded_heart_claimed": true}
	SaveManager.onboarding = {"version": SaveManager.ONBOARDING_VERSION, "language_selected": true}
	SaveManager.progression["total_xp"] = 432
	SaveManager.progression["skill_rating"] = 975.0
	SaveManager.achievements["seen_stars"] = 2
	SaveManager.save_data()

	SaveManager.reset_to_defaults()
	SaveManager.load_data()
	_assert(str(SaveManager.settings.get("language", "")) == "fi", "language setting survives save/load")
	_assert(not bool(SaveManager.settings.get("sound_enabled", true)), "sound setting survives save/load")
	_assert(not bool(SaveManager.settings.get("music_enabled", true)), "music setting survives save/load")
	_assert(not SaveManager.settings.has("attempts"), "legacy attempt selector is removed from loaded settings")
	_assert(int(SaveManager.statistics.get("wins", 0)) == 7, "statistics survive save/load")
	_assert(int(SaveManager.active_game.get("attempts_left", 0)) == 2, "unfinished game survives save/load")
	_assert(bool(SaveManager.daily_results.get("2026-07-21", {}).get("won", false)), "Daily result survives save/load")
	_assert(SaveManager.get_played_puzzle_ids("unlimited").has("unlimited-1"), "played puzzle history survives save/load")
	_assert(int(SaveManager.endless_state.get("hearts", 0)) == 1, "Infinity hearts survive save/load")
	_assert(bool(SaveManager.onboarding.get("language_selected", false)), "onboarding state survives save/load")
	_assert(SaveManager.get_total_xp() == 432, "XP survives save/load")
	_assert(int(SaveManager.achievements.get("seen_stars", 0)) == 2, "achievement state survives save/load")
	_assert(SaveManager.MAX_ATTEMPTS == 3, "new puzzles use three fixed Stamina")

	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	SaveManager.save_path = SaveManager.SAVE_PATH
	SaveManager.reset_to_defaults()
	print("SAVE_PERSISTENCE_SMOKE_TEST_PASS")
	get_tree().quit()

func _assert(condition: bool, description: String) -> void:
	if condition:
		return
	push_error("Save persistence smoke test failed: %s" % description)
	get_tree().quit(1)
