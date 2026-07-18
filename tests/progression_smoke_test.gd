extends Node

func _ready() -> void:
	SaveManager.save_path = "res://.godot-test-data/progression_save.json"
	SaveManager.progression = SaveManager.DEFAULT_PROGRESSION.duplicate(true)
	var original_language: String = PuzzleLoader.get_language()
	for language: String in ["en", "fi"]:
		assert(PuzzleLoader.set_language(language), "Progression test must load %s puzzles" % language)
		for mode: String in [GameState.DAILY_MODE, GameState.UNLIMITED_MODE]:
			for puzzle: Dictionary in PuzzleLoader.get_puzzles(mode):
				assert(PuzzleLoader.validate_puzzle(puzzle).is_empty(), "%s %s puzzle %s must validate" % [language, mode, puzzle.get("id", "")])
				assert(PuzzleLoader.get_difficulty_tier(puzzle) in [1, 2, 3, 4, 5], "Every puzzle needs a difficulty tier")
				var rating: int = PuzzleLoader.get_effective_difficulty_rating(puzzle)
				assert(rating >= 500 and rating <= 1600, "Every puzzle needs a valid fixed rating")
	assert(PuzzleLoader.set_language(original_language), "Progression test must restore the original language")
	var puzzles: Array[Dictionary] = PuzzleLoader.get_puzzles(GameState.UNLIMITED_MODE)
	assert(not puzzles.is_empty(), "Progression test needs Infinity puzzles")

	var first_puzzle: Dictionary = puzzles[0]
	var local_rating: int = PuzzleLoader.get_effective_difficulty_rating(first_puzzle)
	PuzzleLoader.set_difficulty_overrides({str(first_puzzle.get("id", "")): local_rating + 40})
	assert(PuzzleLoader.get_effective_difficulty_rating(first_puzzle) == local_rating + 40, "Future difficulty overrides must use the provider seam")
	PuzzleLoader.clear_difficulty_overrides()
	assert(PuzzleLoader.get_effective_difficulty_rating(first_puzzle) == local_rating, "Clearing overrides must restore authored metadata")

	var selected: Dictionary = PuzzleLoader.get_next_unplayed_puzzle_for_skill(
		GameState.UNLIMITED_MODE,
		[],
		SaveManager.get_player_skill_rating(),
		SaveManager.get_rated_games()
	)
	assert(not selected.is_empty(), "Skill-aware selection must return an available puzzle")

	var initial_skill: float = SaveManager.get_player_skill_rating()
	var win_reward: Dictionary = SaveManager.record_progression_result(first_puzzle, GameState.UNLIMITED_MODE, true, 5, 0, 0)
	assert(int(win_reward.get("xp_gained", 0)) > 0, "A completed puzzle must award XP")
	assert(SaveManager.get_total_xp() == int(win_reward.get("total_xp_after", -1)), "Awarded XP must persist in progression")
	assert(SaveManager.get_player_skill_rating() > initial_skill, "A strong Infinity result must increase the hidden skill rating")

	var repeated_reward: Dictionary = SaveManager.record_progression_result(first_puzzle, GameState.UNLIMITED_MODE, false, 1, 4, 2)
	assert(bool(repeated_reward.get("repeat_attempt", false)), "Replaying a puzzle must be recognized")
	assert(int(repeated_reward.get("xp_gained", 0)) > 0, "Partial progress must still award XP")
	assert(SaveManager.get_player_skill_rating() < float(win_reward.get("skill_after", 0.0)), "A weak result must lower the hidden skill rating")

	var previous_threshold: int = -1
	for level: int in range(1, 20):
		var threshold: int = SaveManager.xp_threshold_for_level(level)
		assert(threshold > previous_threshold, "XP level thresholds must increase forever")
		previous_threshold = threshold

	print("PROGRESSION_SMOKE_TEST_PASS")
	get_tree().quit()
