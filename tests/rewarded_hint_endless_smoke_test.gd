extends Node

func _ready() -> void:
	SaveManager.save_path = "res://.godot-test-data/rewarded_hint_endless_save.json"
	SaveManager.reset_to_defaults()
	_assert(PuzzleLoader.set_language("en"), "English puzzles load")
	_assert(GameState.start_new_game(GameState.UNLIMITED_MODE), "Endless puzzle starts")

	GameState.request_hint()
	GameState.request_hint()
	_assert(GameState.hints_used == 2, "two free hints are consumed")
	_assert(GameState.get_remaining_hint_count() == 0, "no free hints remain")
	_assert(not GameState.rewarded_hint_claimed, "reward has not been claimed yet")

	# Simulate the AdManager reward callback after a completed rewarded ad.
	GameState.grant_rewarded_hint()
	_assert(GameState.rewarded_hint_claimed, "Endless accepts the rewarded hint")
	_assert(GameState.get_remaining_hint_count() == 1, "one bonus hint becomes available")
	GameState.request_hint()
	_assert(GameState.hints_used == 3, "the bonus hint can be placed")
	_assert(GameState.get_remaining_hint_count() == 0, "the bonus hint is consumed")

	GameState.grant_rewarded_hint()
	_assert(GameState.get_remaining_hint_count() == 0, "a second reward is rejected in the same puzzle")

	print("REWARDED_HINT_ENDLESS_SMOKE_TEST_PASS")
	get_tree().quit()

func _assert(condition: bool, description: String) -> void:
	if condition:
		return
	push_error("Rewarded Endless hint smoke test failed: %s" % description)
	get_tree().quit(1)
