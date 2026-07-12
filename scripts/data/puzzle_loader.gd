extends Node

const PUZZLE_PATHS: Dictionary = {
	"en": {"daily": "res://data/daily_puzzles.json", "unlimited": "res://data/unlimited_puzzles.json"},
	"fi": {"daily": "res://data/daily_puzzles_fi.json", "unlimited": "res://data/unlimited_puzzles_fi.json"}
}
const DAILY_MODE: String = "daily"
const UNLIMITED_MODE: String = "unlimited"

var _puzzles_by_mode: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _language: String = "en"

func _ready() -> void:
	_rng.randomize()
	load_puzzles()

func load_puzzles() -> bool:
	_puzzles_by_mode.clear()
	_language = str(SaveManager.settings.get("language", "en"))
	if not PUZZLE_PATHS.has(_language):
		_language = "en"
	var paths: Dictionary = PUZZLE_PATHS[_language]
	var daily_loaded: bool = _load_pool(DAILY_MODE, str(paths[DAILY_MODE]))
	var unlimited_loaded: bool = _load_pool(UNLIMITED_MODE, str(paths[UNLIMITED_MODE]))
	return daily_loaded and unlimited_loaded

func set_language(language: String) -> bool:
	if not PUZZLE_PATHS.has(language):
		return false
	SaveManager.settings["language"] = language
	return load_puzzles()

func get_language() -> String:
	return _language

func _load_pool(mode: String, path: String) -> bool:
	var puzzles: Array[Dictionary] = []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open %s puzzle data: %s" % [mode, path])
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary) or not parsed.has("puzzles") or not (parsed["puzzles"] is Array):
		push_error("%s puzzle data has an invalid root format." % mode)
		return false
	var schedule: Dictionary = parsed.get("schedule", {}) as Dictionary
	for candidate: Variant in parsed["puzzles"]:
		if candidate is Dictionary:
			var puzzle_data: Dictionary = candidate.duplicate(true)
			var scheduled_date: String = str(schedule.get(str(puzzle_data.get("id", "")), ""))
			if not scheduled_date.is_empty():
				puzzle_data["date"] = scheduled_date
			var errors: PackedStringArray = validate_puzzle(puzzle_data)
			if errors.is_empty():
				puzzles.append(puzzle_data)
			else:
				push_error("Invalid puzzle '%s': %s" % [str(candidate.get("id", "unknown")), "; ".join(errors)])
	if puzzles.is_empty():
		push_error("No valid %s puzzles were loaded." % mode)
		return false
	_puzzles_by_mode[mode] = puzzles
	return true

func get_random_puzzle(mode: String, exclude_id: String = "") -> Dictionary:
	var pool: Array[Dictionary] = get_puzzles(mode)
	var choices: Array[Dictionary] = []
	for puzzle: Dictionary in pool:
		if puzzle.get("id", "") != exclude_id or pool.size() == 1:
			choices.append(puzzle)
	if choices.is_empty():
		return {}
	return choices[_rng.randi_range(0, choices.size() - 1)].duplicate(true)

func get_daily_puzzle(date_key: String) -> Dictionary:
	var pool: Array[Dictionary] = get_puzzles(DAILY_MODE)
	if pool.is_empty():
		return {}
	for puzzle: Dictionary in pool:
		if str(puzzle.get("date", "")) == date_key:
			return puzzle.duplicate(true)
	# Daily entries are authored in chronological ID order. This also covers a
	# newly appended entry before its optional schedule map is updated.
	var epoch: int = Time.get_unix_time_from_datetime_string("2026-07-12T00:00:00")
	var requested: int = Time.get_unix_time_from_datetime_string("%sT00:00:00" % date_key)
	var offset: int = int((requested - epoch) / 86400.0)
	if offset >= 0 and offset < pool.size():
		return pool[offset].duplicate(true)
	var parts: PackedStringArray = date_key.split("-")
	if parts.size() != 3:
		return get_random_puzzle(DAILY_MODE)
	var day_number: int = int(parts[0]) * 372 + int(parts[1]) * 31 + int(parts[2])
	return pool[posmod(day_number, pool.size())].duplicate(true)

func get_next_unplayed_puzzle(mode: String, played_ids: Array[String]) -> Dictionary:
	var choices: Array[Dictionary] = []
	for puzzle: Dictionary in get_puzzles(mode):
		if not played_ids.has(str(puzzle.get("id", ""))):
			choices.append(puzzle)
	if choices.is_empty():
		return {}
	return choices[_rng.randi_range(0, choices.size() - 1)].duplicate(true)

func get_puzzles(mode: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var pool_value: Variant = _puzzles_by_mode.get(mode, [])
	if pool_value is Array:
		for puzzle_value: Variant in pool_value:
			if puzzle_value is Dictionary:
				result.append(puzzle_value)
	return result

func validate_puzzle(puzzle: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	var expected_sizes: Array[int] = [2, 3, 4, 5]
	if str(puzzle.get("id", "")).is_empty():
		errors.append("missing id")
	if str(puzzle.get("top_word", "")).strip_edges().is_empty():
		errors.append("missing top word")
	if not (puzzle.get("groups", null) is Array):
		errors.append("groups must be an array")
		return errors
	var groups: Array = puzzle["groups"]
	if groups.size() != 4:
		errors.append("requires exactly four groups")
	var found_sizes: Array[int] = []
	var all_words: Dictionary = {}
	for group_value: Variant in groups:
		if not group_value is Dictionary:
			errors.append("each group must be an object")
			continue
		var group: Dictionary = group_value
		var words: Variant = group.get("words", [])
		var declared_size: int = int(group.get("size", 0))
		found_sizes.append(declared_size)
		if not (words is Array) or words.size() != declared_size:
			errors.append("group size does not match its words")
			continue
		if str(group.get("label", "")).strip_edges().is_empty():
			errors.append("group missing label")
		for word_value: Variant in words:
			var word: String = str(word_value).strip_edges().to_upper()
			if word.is_empty() or all_words.has(word):
				errors.append("words must be non-empty and unique")
			all_words[word] = true
	found_sizes.sort()
	if found_sizes != expected_sizes:
		errors.append("group sizes must be 2, 3, 4 and 5")
	if all_words.size() != 14:
		errors.append("groups must contain 14 unique words")
	if all_words.has(str(puzzle.get("top_word", "")).to_upper()):
		errors.append("top word must not occur in a group")
	return errors
