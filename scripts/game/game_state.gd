extends Node

signal game_started(puzzle_title: String, attempts_left: int)
signal selection_changed(selection: Array[String])
signal group_solved(group: Dictionary)
signal top_solved(word: String)
signal repeated_guess_attempted
signal guess_feedback(text: String)
signal guess_failed(attempts_left: int)
signal game_finished(won: bool, top_word: String)
signal hint_provided(text: String)
signal hint_placed(word: String, row_length: int)
signal hint_count_changed(used: int, limit: int)
signal rewarded_hint_required
signal puzzle_pool_completed(mode: String)
signal tutorial_completed

const FREE_HINT_LIMIT: int = 2
const DAILY_MODE: String = "daily"
const UNLIMITED_MODE: String = "unlimited"
const TUTORIAL_MODE: String = "tutorial"
const AUTO_SOLVE_ROW_INTERVAL: float = 0.95

var puzzle: Dictionary = {}
var selected_words: Array[String] = []
var solved_groups: Array[int] = []
var attempts_left: int = 0
var is_finished: bool = false
var completed_won: bool = false
var is_top_solved: bool = false
var is_auto_solving: bool = false
var wrong_guesses: Array = []
var last_failed_guess: Array[String] = []
var last_failed_active: bool = false
var daily_date: String = ""
var game_mode: String = "daily"
var hints_used: int = 0
var rewarded_hint_claimed: bool = false
var hinted_words_by_row: Dictionary = {}
var result_correct_count: int = -1
var result_solved_groups: Array[int] = []
var result_top_solved: bool = false
var result_progression: Dictionary = {}
var tutorial_allowed_words: Array[String] = []

func start_tutorial() -> bool:
	game_mode = TUTORIAL_MODE
	daily_date = ""
	puzzle = _tutorial_puzzle(PuzzleLoader.get_language())
	selected_words.clear()
	solved_groups.clear()
	is_top_solved = false
	attempts_left = int(SaveManager.settings.get("attempts", 4))
	hints_used = 0
	rewarded_hint_claimed = false
	is_finished = false
	completed_won = false
	is_auto_solving = false
	wrong_guesses.clear()
	last_failed_guess.clear()
	last_failed_active = false
	hinted_words_by_row.clear()
	result_correct_count = -1
	result_solved_groups.clear()
	result_top_solved = false
	result_progression.clear()
	tutorial_allowed_words.clear()
	game_started.emit(str(puzzle.get("title", SaveManager.text("tutorial_title"))), attempts_left)
	hint_count_changed.emit(hints_used, _get_hint_limit())
	return true

func set_tutorial_allowed_words(words: Array[String]) -> void:
	tutorial_allowed_words.assign(words)
	selection_changed.emit(selected_words)

func is_tutorial_word_allowed(word: String) -> bool:
	return game_mode != TUTORIAL_MODE or tutorial_allowed_words.has(word)

func tutorial_group_words(row_length: int) -> Array[String]:
	if row_length == 1:
		return [str(puzzle.get("top_word", ""))]
	for group_value: Variant in puzzle.get("groups", []):
		if group_value is Dictionary:
			var group: Dictionary = group_value
			if int(group.get("size", 0)) == row_length:
				return _get_required_words(group)
	return []

func start_new_game(mode: String = "daily") -> bool:
	if not _is_valid_mode(mode):
		push_error("Unsupported game mode: %s" % mode)
		return false
	game_mode = mode
	daily_date = Time.get_date_string_from_system()
	if game_mode == UNLIMITED_MODE and not SaveManager.can_start_endless(daily_date):
		return false
	var played_ids: Array[String] = SaveManager.get_played_puzzle_ids(_progress_key())
	if played_ids.size() >= PuzzleLoader.get_puzzles(game_mode).size():
		if game_mode == UNLIMITED_MODE:
			var previous_puzzle_id: String = str(puzzle.get("id", ""))
			played_ids = [previous_puzzle_id] if not previous_puzzle_id.is_empty() else []
			SaveManager.replace_played_puzzle_ids(_progress_key(), played_ids)
		else:
			puzzle_pool_completed.emit(game_mode)
			return false
	if game_mode == DAILY_MODE:
		puzzle = PuzzleLoader.get_daily_puzzle(daily_date)
	else:
		puzzle = PuzzleLoader.get_next_unplayed_puzzle_for_skill(
			game_mode,
			played_ids,
			SaveManager.get_player_skill_rating(),
			SaveManager.get_rated_games()
		)
	if puzzle.is_empty():
		puzzle_pool_completed.emit(game_mode)
		return false
	selected_words.clear()
	solved_groups.clear()
	is_top_solved = false
	attempts_left = int(SaveManager.settings.get("attempts", 4))
	hints_used = 0
	rewarded_hint_claimed = false
	is_finished = false
	completed_won = false
	is_auto_solving = false
	wrong_guesses.clear()
	last_failed_guess.clear()
	last_failed_active = false
	hinted_words_by_row.clear()
	result_correct_count = -1
	result_solved_groups.clear()
	result_top_solved = false
	result_progression.clear()
	_save_active_game()
	game_started.emit(str(puzzle.get("title", "Daily Challenge")), attempts_left)
	hint_count_changed.emit(hints_used, _get_hint_limit())
	return true

func view_daily_result() -> bool:
	game_mode = DAILY_MODE
	daily_date = Time.get_date_string_from_system()
	if not SaveManager.is_daily_challenge_completed(daily_date):
		return false
	puzzle = PuzzleLoader.get_daily_puzzle(daily_date)
	if puzzle.is_empty():
		return false
	selected_words.clear()
	solved_groups.clear()
	for index: int in puzzle.get("groups", []).size():
		solved_groups.append(index)
	is_top_solved = true
	attempts_left = int(SaveManager.settings.get("attempts", 4))
	hints_used = 0
	rewarded_hint_claimed = false
	is_finished = true
	var saved_result: Dictionary = SaveManager.get_daily_result(daily_date)
	completed_won = bool(saved_result.get("won", false))
	result_correct_count = int(saved_result.get("correct_count", _total_word_count() if completed_won else 0))
	result_solved_groups.assign(_to_int_array(saved_result.get("solved_groups", [])))
	result_top_solved = bool(saved_result.get("top_solved", completed_won))
	var saved_progression: Variant = saved_result.get("progression_reward", {})
	result_progression = saved_progression.duplicate(true) if saved_progression is Dictionary else {}
	if completed_won and result_solved_groups.is_empty():
		for index: int in puzzle.get("groups", []).size():
			result_solved_groups.append(index)
	is_auto_solving = false
	wrong_guesses.clear()
	last_failed_guess.clear()
	last_failed_active = false
	hinted_words_by_row.clear()
	_save_active_game()
	game_started.emit(str(puzzle.get("title", "Daily Challenge")), attempts_left)
	selection_changed.emit(selected_words)
	hint_count_changed.emit(hints_used, _get_hint_limit())
	game_finished.emit(completed_won, str(puzzle.get("top_word", "")))
	return true

func restart_current() -> bool:
	if game_mode == UNLIMITED_MODE and not puzzle.is_empty() and not is_finished:
		SaveManager.consume_endless_heart()
		if not SaveManager.can_start_endless():
			return false
	if puzzle.is_empty() or (game_mode == "daily" and daily_date != Time.get_date_string_from_system()):
		return start_new_game(game_mode)
	selected_words.clear()
	solved_groups.clear()
	is_top_solved = false
	attempts_left = int(SaveManager.settings.get("attempts", 4))
	hints_used = 0
	rewarded_hint_claimed = false
	is_finished = false
	completed_won = false
	is_auto_solving = false
	wrong_guesses.clear()
	last_failed_guess.clear()
	last_failed_active = false
	hinted_words_by_row.clear()
	result_correct_count = -1
	result_solved_groups.clear()
	result_top_solved = false
	result_progression.clear()
	_save_active_game()
	game_started.emit(str(puzzle.get("title", "Daily Challenge")), attempts_left)
	hint_count_changed.emit(hints_used, _get_hint_limit())
	return true

func reset_debug_state() -> void:
	puzzle.clear()
	selected_words.clear()
	solved_groups.clear()
	attempts_left = 0
	is_finished = false
	completed_won = false
	is_top_solved = false
	is_auto_solving = false
	wrong_guesses.clear()
	last_failed_guess.clear()
	last_failed_active = false
	daily_date = ""
	game_mode = DAILY_MODE
	hints_used = 0
	rewarded_hint_claimed = false
	hinted_words_by_row.clear()
	result_correct_count = -1
	result_solved_groups.clear()
	result_top_solved = false
	result_progression.clear()
	tutorial_allowed_words.clear()

func has_resumable_game(mode: String) -> bool:
	var saved: Dictionary = SaveManager.active_game
	return (
		not saved.is_empty()
		and saved.has("puzzle")
		and str(saved.get("game_mode", "")) == mode
		and not bool(saved.get("is_finished", false))
		and str(saved.get("language", PuzzleLoader.get_language())) == PuzzleLoader.get_language()
	)

func restore_game() -> bool:
	var saved: Dictionary = SaveManager.active_game
	if saved.is_empty() or not saved.has("puzzle"):
		return false
	daily_date = str(saved.get("daily_date", ""))
	game_mode = str(saved.get("game_mode", DAILY_MODE))
	# Daily puzzles expire at midnight, while Infinity games must remain
	# resumable regardless of the calendar date.
	var saved_language: String = str(saved.get("language", PuzzleLoader.get_language()))
	var expired_daily: bool = game_mode == DAILY_MODE and daily_date != Time.get_date_string_from_system()
	if not _is_valid_mode(game_mode) or saved_language != PuzzleLoader.get_language() or expired_daily:
		SaveManager.active_game.clear()
		SaveManager.save_data()
		return false
	var saved_puzzle: Variant = saved.get("puzzle", {})
	if not (saved_puzzle is Dictionary):
		SaveManager.active_game.clear()
		SaveManager.save_data()
		return false
	puzzle = saved_puzzle.duplicate(true)
	if not PuzzleLoader.validate_puzzle(puzzle).is_empty():
		SaveManager.active_game.clear()
		SaveManager.save_data()
		return false
	selected_words.assign(_to_string_array(saved.get("selected_words", [])))
	solved_groups.assign(_to_int_array(saved.get("solved_groups", [])))
	is_top_solved = bool(saved.get("is_top_solved", false))
	attempts_left = int(saved.get("attempts_left", SaveManager.settings.get("attempts", 4)))
	hints_used = int(saved.get("hints_used", 0))
	rewarded_hint_claimed = bool(saved.get("rewarded_hint_claimed", false))
	result_correct_count = int(saved.get("result_correct_count", -1))
	result_solved_groups.assign(_to_int_array(saved.get("result_solved_groups", [])))
	is_finished = bool(saved.get("is_finished", false))
	completed_won = bool(saved.get("completed_won", false))
	result_top_solved = bool(saved.get("result_top_solved", completed_won))
	var saved_progression: Variant = saved.get("result_progression", {})
	result_progression = saved_progression.duplicate(true) if saved_progression is Dictionary else {}
	if is_finished and result_correct_count < 0:
		result_correct_count = _total_word_count() if completed_won else _player_correct_count()
	if is_finished and completed_won and result_solved_groups.is_empty():
		for index: int in puzzle.get("groups", []).size():
			result_solved_groups.append(index)
	is_auto_solving = false
	wrong_guesses.clear()
	for guess_value: Variant in saved.get("wrong_guesses", []):
		wrong_guesses.append(_to_string_array(guess_value))
	last_failed_guess.assign(_to_string_array(saved.get("last_failed_guess", [])))
	last_failed_active = bool(saved.get("last_failed_active", false))
	var saved_hints: Variant = saved.get("hinted_words_by_row", {})
	hinted_words_by_row = saved_hints.duplicate(true) if saved_hints is Dictionary else {}
	game_started.emit(str(puzzle.get("title", "Daily Challenge")), attempts_left)
	selection_changed.emit(selected_words)
	hint_count_changed.emit(hints_used, _get_hint_limit())
	if is_finished:
		game_finished.emit(completed_won, str(puzzle.get("top_word", "")))
	return true

func toggle_word(word: String) -> void:
	if is_finished or is_auto_solving or is_word_solved(word):
		return
	if game_mode == TUTORIAL_MODE and not tutorial_allowed_words.has(word):
		return
	last_failed_active = false
	var selecting: bool = not selected_words.has(word)
	if not selecting:
		selected_words.erase(word)
	else:
		if selected_words.size() >= get_selection_limit():
			return
		selected_words.append(word)
	SoundManager.click(selecting)
	_save_active_game()
	selection_changed.emit(selected_words)

func clear_selection() -> void:
	if selected_words.is_empty():
		return
	last_failed_active = false
	selected_words.clear()
	_save_active_game()
	selection_changed.emit(selected_words)

func request_hint() -> void:
	if is_finished or is_auto_solving:
		return
	var hint_limit: int = _get_hint_limit()
	if hints_used >= hint_limit and game_mode == "unlimited":
		hint_provided.emit(SaveManager.text("unlimited_hint_limit"))
		return
	if hints_used >= hint_limit and not rewarded_hint_claimed:
		rewarded_hint_required.emit()
		return
	var target: Dictionary = _find_next_hint_target()
	if target.is_empty():
		return
	var group: Dictionary = target["group"]
	var row_length: int = int(target["row_length"])
	var hinted_word: String = str(target["word"])
	var existing_hints: Array[String] = get_hint_words_for_row(row_length)
	# A hint tile becomes locked and cannot remain part of the player's active
	# selection. Remove it first so visual and gameplay state stay synchronized.
	if selected_words.has(hinted_word):
		selected_words.erase(hinted_word)
		last_failed_active = false
	existing_hints.append(hinted_word)
	hinted_words_by_row[row_length] = existing_hints
	_unlock_newly_valid_hint_guess(group)
	hints_used += 1
	_save_active_game()
	hint_placed.emit(hinted_word, row_length)
	hint_provided.emit(SaveManager.text("hint_placed") % hinted_word)
	hint_count_changed.emit(hints_used, hint_limit)
	selection_changed.emit(selected_words)

func _find_next_hint_target() -> Dictionary:
	var candidates: Dictionary = {}
	for row_length: int in [5, 4, 3, 2]:
		for index: int in puzzle.get("groups", []).size():
			if solved_groups.has(index):
				continue
			var group: Dictionary = puzzle["groups"][index]
			if int(group.get("size", 0)) != row_length:
				continue
			var words: Array[String] = _to_string_array(group.get("words", []))
			var existing_hints: Array[String] = get_hint_words_for_row(row_length)
			var hinted_word: String = ""
			for candidate: String in words:
				if not existing_hints.has(candidate):
					hinted_word = candidate
					break
			if not hinted_word.is_empty():
				candidates[row_length] = {
					"group": group,
					"row_length": row_length,
					"word": hinted_word,
					"word_count": words.size(),
					"hint_count": existing_hints.size(),
				}
			break
	# First distribute hints across separate rows, from the bottom upward.
	for row_length: int in [5, 4, 3, 2]:
		if candidates.has(row_length) and int((candidates[row_length] as Dictionary)["hint_count"]) == 0:
			return candidates[row_length]
	# Once each available row has a hint, repeat the least-hinted rows first.
	# Never complete a row using hints while another non-completing option exists.
	var best: Dictionary = {}
	var best_hint_count: int = 1000000
	for row_length: int in [5, 4, 3, 2]:
		if not candidates.has(row_length):
			continue
		var candidate: Dictionary = candidates[row_length]
		var candidate_hint_count: int = int(candidate["hint_count"])
		if candidate_hint_count + 1 >= int(candidate["word_count"]):
			continue
		if candidate_hint_count < best_hint_count:
			best = candidate
			best_hint_count = candidate_hint_count
	if not best.is_empty():
		return best
	# If every remaining option would finish its row, keep bottom-to-top order.
	for row_length: int in [5, 4, 3, 2]:
		if candidates.has(row_length):
			return candidates[row_length]
	return {}

func grant_rewarded_hint() -> void:
	if is_finished or is_auto_solving or game_mode == "unlimited" or rewarded_hint_claimed:
		return
	rewarded_hint_claimed = true
	_save_active_game()
	hint_provided.emit(SaveManager.text("bonus_hint_earned"))
	hint_count_changed.emit(hints_used, _get_hint_limit())

func _unlock_newly_valid_hint_guess(group: Dictionary) -> void:
	# A placed hint is removed from the required answer. A four-word selection
	# that was previously a failed five-word attempt can therefore become the
	# exact correct answer and must no longer be blocked as a repeated mistake.
	var required_words: Array[String] = _get_required_words(group)
	for index: int in range(wrong_guesses.size() - 1, -1, -1):
		if _has_same_words(_to_string_array(wrong_guesses[index]), required_words):
			wrong_guesses.remove_at(index)
	if last_failed_active and _has_same_words(last_failed_guess, required_words):
		last_failed_guess.clear()
		last_failed_active = false

func _get_hint_limit() -> int:
	# Unlimited has exactly two hints per puzzle. Daily mode can still expose
	# its existing rewarded third-hint flow after these two free hints.
	return FREE_HINT_LIMIT + 1 if rewarded_hint_claimed and game_mode != "unlimited" else FREE_HINT_LIMIT

func get_hint_word_for_row(row_length: int) -> String:
	var words: Array[String] = get_hint_words_for_row(row_length)
	return words[0] if not words.is_empty() else ""

func get_hint_words_for_row(row_length: int) -> Array[String]:
	var value: Variant = hinted_words_by_row.get(row_length, hinted_words_by_row.get(str(row_length), []))
	# Older saves stored one String per row. Keep those saves resumable while the
	# current format supports multiple locked hint words in the same row.
	if value is String:
		return [str(value)] if not str(value).is_empty() else []
	return _to_string_array(value)

func can_check_selection() -> bool:
	if is_finished or is_auto_solving:
		return false
	var has_valid_size: bool = selected_words.size() == 1 and not is_top_solved
	for index: int in puzzle.get("groups", []).size():
		if not solved_groups.has(index):
			var group: Dictionary = puzzle["groups"][index]
			if selected_words.size() == _get_required_words(group).size():
				has_valid_size = true
	return (
		(has_valid_size or not get_near_miss_feedback().is_empty())
		and not is_current_failed_guess()
		and not is_repeated_wrong_guess()
	)

func get_selection_limit() -> int:
	var largest_unsolved: int = 1 if not is_top_solved else 0
	for index: int in puzzle.get("groups", []).size():
		if solved_groups.has(index):
			continue
		var group: Dictionary = puzzle["groups"][index]
		largest_unsolved = maxi(largest_unsolved, int(group.get("size", 0)))
	return clampi(largest_unsolved, 1, 5)

func is_current_failed_guess() -> bool:
	return last_failed_active and _has_same_words(selected_words, last_failed_guess)

func is_repeated_wrong_guess() -> bool:
	for guess_value: Variant in wrong_guesses:
		var previous_guess: Array[String] = _to_string_array(guess_value)
		if _has_same_words(selected_words, previous_guess):
			return true
	return false

func get_near_miss_feedback() -> String:
	for index: int in puzzle.get("groups", []).size():
		if solved_groups.has(index):
			continue
		var group: Dictionary = puzzle["groups"][index]
		var group_size: int = int(group.get("size", 0))
		if group_size <= 2:
			continue
		var group_words: Array[String] = _get_required_words(group)
		var matches: int = 0
		for word: String in selected_words:
			if group_words.has(word):
				matches += 1
		var required_size: int = group_words.size()
		if selected_words.size() == required_size - 1 and matches == required_size - 1:
			return SaveManager.text("missing_word")
		if selected_words.size() == required_size + 1 and matches == required_size:
			return SaveManager.text("extra_word")
	return ""

func check_selection() -> void:
	if not can_check_selection():
		return
	if is_repeated_wrong_guess():
		repeated_guess_attempted.emit()
		return
	if selected_words.size() == 1 and not is_top_solved:
		if selected_words[0] == str(puzzle.get("top_word", "")):
			is_top_solved = true
			result_top_solved = true
			SoundManager.success()
			top_solved.emit(selected_words[0])
			selected_words.clear()
			if _is_complete():
				_finish(true)
			else:
				_save_active_game()
			selection_changed.emit(selected_words)
			return
	for index: int in puzzle.get("groups", []).size():
		if solved_groups.has(index):
			continue
		var group: Dictionary = puzzle["groups"][index]
		var words: Array[String] = _get_required_words(group)
		if _has_same_words(selected_words, words):
			solved_groups.append(index)
			solved_groups.sort()
			SoundManager.success()
			group_solved.emit(group)
			selected_words.clear()
			if _is_complete():
				_finish(true)
			else:
				_save_active_game()
			selection_changed.emit(selected_words)
			return
	wrong_guesses.append(selected_words.duplicate())
	last_failed_guess = selected_words.duplicate()
	last_failed_active = true
	var feedback: String = get_near_miss_feedback()
	attempts_left -= 1
	SoundManager.failure()
	guess_failed.emit(attempts_left)
	if not feedback.is_empty():
		guess_feedback.emit(feedback)
	if attempts_left <= 0:
		result_correct_count = _player_correct_count()
		result_solved_groups.assign(solved_groups)
		result_top_solved = is_top_solved
		selected_words.clear()
		is_auto_solving = true
		_auto_solve_remaining()
	else:
		_save_active_game()
	selection_changed.emit(selected_words)

func get_unsolved_words() -> Array[String]:
	var words: Array[String] = []
	for group_value: Variant in puzzle.get("groups", []):
		if group_value is Dictionary:
			words.append_array(_to_string_array(group_value.get("words", [])))
	if not is_top_solved:
		words.append(str(puzzle.get("top_word", "")))
	for index: int in solved_groups:
		var group: Dictionary = puzzle["groups"][index]
		for word: String in _to_string_array(group.get("words", [])):
			words.erase(word)
	return words

func is_word_solved(word: String) -> bool:
	return not get_unsolved_words().has(word)

func get_solved_group_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index: int in solved_groups:
		result.append(puzzle["groups"][index])
	return result

func _get_required_words(group: Dictionary) -> Array[String]:
	var words: Array[String] = _to_string_array(group.get("words", []))
	for hinted_word: String in get_hint_words_for_row(int(group.get("size", 0))):
		words.erase(hinted_word)
	return words

func _is_complete() -> bool:
	return solved_groups.size() == 4 and is_top_solved

func _auto_solve_remaining() -> void:
	await get_tree().create_timer(0.28).timeout
	if not is_top_solved:
		selected_words.append(str(puzzle.get("top_word", "")))
		is_top_solved = true
		SoundManager.success()
		top_solved.emit(selected_words[0])
		selected_words.clear()
		selection_changed.emit(selected_words)
		await get_tree().create_timer(AUTO_SOLVE_ROW_INTERVAL).timeout
	for group_size: int in [2, 3, 4, 5]:
		for index: int in puzzle.get("groups", []).size():
			if solved_groups.has(index):
				continue
			var group: Dictionary = puzzle["groups"][index]
			if int(group.get("size", 0)) != group_size:
				continue
			selected_words.assign(_get_required_words(group))
			solved_groups.append(index)
			solved_groups.sort()
			SoundManager.success()
			group_solved.emit(group)
			selected_words.clear()
			selection_changed.emit(selected_words)
			await get_tree().create_timer(AUTO_SOLVE_ROW_INTERVAL).timeout
			break
	is_auto_solving = false
	_finish(false)

func _finish(won: bool) -> void:
	is_finished = true
	completed_won = won
	if won:
		result_solved_groups.assign(solved_groups)
		result_top_solved = true
	if result_correct_count < 0:
		result_correct_count = _player_correct_count()
	if game_mode == TUTORIAL_MODE:
		tutorial_allowed_words.clear()
		tutorial_completed.emit()
		return
	var solved_row_count: int = result_solved_groups.size() + (1 if result_top_solved else 0)
	var max_attempts: int = maxi(int(SaveManager.settings.get("attempts", 4)), 1)
	var mistakes_used: int = clampi(max_attempts - attempts_left, 0, max_attempts)
	result_progression = SaveManager.record_progression_result(
		puzzle,
		game_mode,
		won,
		solved_row_count,
		mistakes_used,
		hints_used
	)
	_save_active_game()
	if not won and game_mode == UNLIMITED_MODE:
		SaveManager.consume_endless_heart()
	SaveManager.record_result(won, daily_date, game_mode, result_correct_count, _total_word_count(), result_solved_groups, result_top_solved, result_progression)
	SaveManager.record_puzzle_played(_progress_key(), str(puzzle.get("id", "")))
	game_finished.emit(won, str(puzzle.get("top_word", "")))
	if game_mode == DAILY_MODE and SaveManager.get_played_puzzle_ids(_progress_key()).size() >= PuzzleLoader.get_puzzles(game_mode).size():
		puzzle_pool_completed.emit(game_mode)

func _progress_key() -> String:
	return "%s:%s" % [PuzzleLoader.get_language(), game_mode]

func _is_valid_mode(mode: String) -> bool:
	return mode == DAILY_MODE or mode == UNLIMITED_MODE

func _save_active_game() -> void:
	if game_mode == TUTORIAL_MODE:
		return
	SaveManager.active_game = {
		"puzzle": puzzle.duplicate(true),
		"selected_words": selected_words.duplicate(),
		"solved_groups": solved_groups.duplicate(),
		"is_top_solved": is_top_solved,
		"attempts_left": attempts_left,
		"is_finished": is_finished,
		"completed_won": completed_won,
		"wrong_guesses": wrong_guesses.duplicate(true),
		"last_failed_guess": last_failed_guess.duplicate(),
		"last_failed_active": last_failed_active,
		"daily_date": daily_date,
		"game_mode": game_mode,
		"language": PuzzleLoader.get_language(),
		"hints_used": hints_used,
		"rewarded_hint_claimed": rewarded_hint_claimed,
		"result_correct_count": result_correct_count,
		"result_solved_groups": result_solved_groups.duplicate(),
		"result_top_solved": result_top_solved,
		"result_progression": result_progression.duplicate(true),
		"hinted_words_by_row": hinted_words_by_row.duplicate(true)
	}
	SaveManager.save_data()

func result_total_count() -> int:
	return _total_word_count()

func _player_correct_count() -> int:
	var count: int = 1 if is_top_solved else 0
	for index: int in solved_groups:
		if index >= 0 and index < puzzle.get("groups", []).size():
			var group: Dictionary = puzzle["groups"][index]
			count += int(group.get("size", 0))
	return count

func _total_word_count() -> int:
	var count: int = 0
	for group_value: Variant in puzzle.get("groups", []):
		if group_value is Dictionary:
			count += int(group_value.get("size", 0))
	if not str(puzzle.get("top_word", "")).is_empty():
		count += 1
	return count

func _has_same_words(left: Array[String], right: Array[String]) -> bool:
	if left.size() != right.size():
		return false
	var remaining: Array[String] = right.duplicate()
	for word: String in left:
		if not remaining.has(word):
			return false
		remaining.erase(word)
	return remaining.is_empty()

func _to_string_array(values: Variant) -> Array[String]:
	var result: Array[String] = []
	if values is Array:
		for value: Variant in values:
			result.append(str(value))
	return result

func _to_int_array(values: Variant) -> Array[int]:
	var result: Array[int] = []
	if values is Array:
		for value: Variant in values:
			result.append(int(value))
	return result

func _tutorial_puzzle(language: String) -> Dictionary:
	if language == "fi":
		return {
			"id": "tutorial-fi",
			"title": "Eläinmaailma",
			"top_word": "ELÄIN",
			"groups": [
				{"size": 2, "label": "Lemmikit", "words": ["KISSA", "KOIRA"]},
				{"size": 3, "label": "Maatilan eläimet", "words": ["LEHMÄ", "SIKA", "KANA"]},
				{"size": 4, "label": "Linnut", "words": ["KOTKA", "PÖLLÖ", "JOUTSEN", "ANKKA"]},
				{"size": 5, "label": "Meren eläimet", "words": ["HAI", "VALAS", "HYLJE", "RAPU", "RAUSKU"]}
			]
		}
	return {
		"id": "tutorial-en",
		"title": "Animal World",
		"top_word": "ANIMAL",
		"groups": [
			{"size": 2, "label": "Pets", "words": ["CAT", "DOG"]},
			{"size": 3, "label": "Farm animals", "words": ["COW", "PIG", "HEN"]},
			{"size": 4, "label": "Birds", "words": ["EAGLE", "OWL", "SWAN", "DUCK"]},
			{"size": 5, "label": "Sea animals", "words": ["SHARK", "WHALE", "SEAL", "CRAB", "RAY"]}
		]
	}
