extends Node

const DEFAULT_SETTINGS: Dictionary = {"attempts": 4, "sound_enabled": true, "music_enabled": true, "language": "en"}
const SAVE_PATH: String = "user://word_pyramid_save.json"
const ENDLESS_DAILY_HEARTS: int = 3
const ONBOARDING_VERSION: int = 1
const DEFAULT_ONBOARDING: Dictionary = {"version": 0, "language_selected": false}
const TEXT: Dictionary = {
	"en": {
		"settings": "Settings",
		"daily_button": "Daily\nToday's challenge",
		"view_result": "View result",
		"unlimited_button": "Infinity Mode",
		"endless_subtitle": "Endless word pyramids",
		"endless_play_button": "Play Infinity ->",
		"endless_play_locked": "Hearts reset tomorrow",
		"endless_reset_in": "Resets in %dh %02dm",
		"endless_hearts": "Endless hearts: %d / %d",
		"endless_no_hearts": "No hearts · resets tomorrow",
		"endless_watch_ad": "Watch ad  +1 heart",
		"endless_ad_claimed": "Bonus heart claimed today",
		"endless_heart_earned": "Extra Endless heart earned!",
		"all_played": "All played",
		"all_played_daily": "All played\nDaily challenges",
		"daily_pool": "daily challenges",
		"unlimited_pool": "unlimited challenges",
		"daily_challenge_label": "Daily Challenge",
		"unlimited_mode_label": "Infinity Mode",
		"home_subtitle": "Daily word challenge",
		"home_daily_title": "Around the Kitchen",
		"home_card_meta": "Food & Cooking · 15 words · 4 categories",
		"home_streak": "%d-day streak",
		"home_hint_markup": "Build a [b][color=#1A0A5E]15-word[/color][/b] pyramid — any order.\nYou get [b][color=#1A0A5E]2 hints[/color][/b] and [b][color=#1A0A5E]4 lives[/color][/b] before the pyramid falls.",
		"pool_complete": "Congratulations! You have played all %s.",
		"statistics_title": "Statistics",
		"statistics_subtitle": "Your Word Pyramid record",
		"settings_title": "Settings",
		"settings_subtitle": "Personalize the challenge",
		"language": "Language",
		"attempts_per_puzzle": "Attempts per puzzle",
		"sound_effects": "Sound effects",
		"music": "Music",
		"settings_note": "New attempt settings are applied when a new puzzle starts.",
		"replay_tutorial": "Replay tutorial",
		"choose_language_title": "Choose your language",
		"choose_language_subtitle": "Valitse kieli · You can change this later in Settings.",
		"tutorial_mode_label": "Tutorial",
		"tutorial_title": "Practice Pyramid",
		"tutorial_skip": "Skip",
		"tutorial_select_group": "Tap the highlighted words that belong together.",
		"tutorial_press_check": "Great! Now press Check to place the group.",
		"tutorial_use_hint": "Hints lock one word into its correct row. Press Hint.",
		"tutorial_finish_row": "Select the remaining highlighted words, then press Check.",
		"tutorial_top_word": "Finish the pyramid: select the highlighted top word and press Check.",
		"tutorial_complete": "You're ready!",
		"tutorial_complete_title": "Tutorial complete!",
		"tutorial_complete_subtitle": "You’re ready to build today’s Word Pyramid.",
		"tutorial_continue_daily": "Continue to Daily Challenge",
		"continue_to_unlimited": "Continue to unlimited",
		"continue_to_next": "Continue to next puzzle",
		"debug_reset_progress": "Debug: Reset all progress",
		"debug_reset_confirm": "Tap again to reset everything",
		"back": "Back",
		"wins": "Wins",
		"losses": "Losses",
		"win_rate": "Win rate",
		"current_streak": "Current streak",
		"best_streak": "Best streak",
		"result_score": "Result: %d/%d",
		"share_result": "Share",
		"result_copied": "Result copied.",
		"share_daily_result": "Word Pyramid %s\nResult: %d/%d\nStreak: %d",
		"aftermath_win_title": "Pyramid Complete!",
		"aftermath_loss_title": "Pyramid Fell!",
		"aftermath_flawless": "Flawless solve - no mistakes!",
		"aftermath_solved_mistakes": "Solved with %d mistakes",
		"aftermath_loss_subtitle": "%d/%d correct - better luck tomorrow",
		"aftermath_endless_loss_subtitle": "%d/%d correct · %d hearts left",
		"aftermath_endless_better_luck": "Better luck next time",
		"endless_hearts_remaining": "%d hearts remaining",
		"endless_out_of_hearts": "Out of hearts!",
		"endless_new_puzzle": "New Puzzle ->",
		"back_to_home": "Back to Home",
		"aftermath_results": "Results",
		"aftermath_streak_current": "%d day streak",
		"aftermath_streak": "%d → %d day streak",
		"aftermath_streak_lost": "Streak lost",
		"aftermath_endless_hearts": "Endless hearts left",
		"aftermath_group_found": "Found",
		"aftermath_group_missed": "Missed",
		"stat_mistakes": "Mistakes",
		"stat_groups": "Groups",
		"stat_hints_used": "Hints used",
		"instructions": "Instructions",
		"instructions_title": "How to play",
		"instructions_subtitle": "Build the pyramid one related group at a time.",
		"instructions_back_game": "Back to game",
		"instructions_find_title": "Find a word group",
		"instructions_find_body": "Select words that share one clear connection. Groups contain 2 to 5 words.",
		"instructions_check_title": "Check your selection",
		"instructions_check_body": "Press Check when the whole group is selected. A correct group locks into its row.",
		"instructions_hint_title": "Use hints wisely",
		"instructions_hint_body": "A hint reveals and locks one word into the correct row.",
		"instructions_mistake_title": "Protect your attempts",
		"instructions_mistake_body": "A wrong group costs one attempt. Repeated guesses cannot be checked again.",
		"instructions_top_title": "Reach the top",
		"instructions_top_body": "After the four groups are complete, select the final top word to finish the pyramid.",
		"instructions_group_sizes": "GROUPS  2 · 3 · 4 · 5",
		"instructions_quick_tip": "TIP  Start with the strongest connection you can see.",
		"instructions_variant_a": "A  Pyramid",
		"instructions_variant_b": "B  Steps",
		"instructions_variant_c": "C  Quick",
		"instructions_concept_a": "A · Visual pyramid journey",
		"instructions_concept_b": "B · Large step-by-step lesson cards",
		"instructions_concept_c": "C · Compact quick-reference dashboard",
		"board_title": "Select related words",
		"daily_message": "Daily challenge · find words that belong together.",
		"unlimited_message": "Endless mode · failed puzzles use one daily heart.",
		"hint": "Hint",
		"clear": "Clear",
		"check": "Check",
		"new_game": "New game",
		"menu": "Menu",
		"select_tooltip": "Select %s",
		"hint_tooltip": "Hint: locked into the correct row",
		"mistakes_left": "Mistakes left: %d / %d",
		"selected": "Selected: %s",
		"select_words": "Select 1-5 words to check",
		"select_up_to": "Select 1-%d words to check",
		"hint_count": "Hint %d",
		"hint_zero": "Hint 0",
		"bonus_hint": "Bonus hint",
		"ad_hint": "Ad +1",
		"game_complete": "Pyramid complete - top word: %s",
		"game_failed": "No attempts left - showing the solution.",
		"guess_failed": "These words do not form a group. Try again.",
		"repeated_guess": "You already tried this combination.",
		"missing_word": "One word is missing.",
		"extra_word": "One word too many.",
		"unlimited_hint_limit": "Unlimited mode has two hints per puzzle.",
		"hint_placed": "Hint: %s was placed into the correct row.",
		"bonus_hint_earned": "Bonus hint earned! Use the Hint button.",
		"rewarded_hint_required": "Two free hints have been used. Watch a rewarded ad to get a bonus hint.",
		"rewarded_ad_unavailable": "Rewarded ads are available only in Android or iOS test builds.",
		"rewarded_ad_loading": "The ad is loading. It will open shortly.",
		"rewarded_ad_failed": "The ad could not be loaded: %s",
		"instructions_text": "Find groups of 2, 3, 4 and 5 words, then guess the top word with one selection."
	},
	"fi": {
		"settings": "Asetukset",
		"daily_button": "Päivän haaste\nTämän päivän pulma",
		"view_result": "Näytä tulos",
		"unlimited_button": "Ääretön peli",
		"endless_subtitle": "Loputtomasti sanapyramideja",
		"endless_play_button": "Pelaa ääretöntä ->",
		"endless_play_locked": "Sydämet palautuvat huomenna",
		"endless_reset_in": "Palautuu %d h %02d min kuluttua",
		"endless_hearts": "Äärettömän pelin sydämet: %d / %d",
		"endless_no_hearts": "Ei sydämiä · palautuvat huomenna",
		"endless_watch_ad": "Katso mainos  +1 sydän",
		"endless_ad_claimed": "Bonussydän lunastettu tänään",
		"endless_heart_earned": "Sait ylimääräisen sydämen!",
		"all_played": "Kaikki pelattu",
		"all_played_daily": "Kaikki pelattu\nPäivittäiset haasteet",
		"daily_pool": "päivittäiset haasteet",
		"unlimited_pool": "rajattomat haasteet",
		"daily_challenge_label": "Päivän haaste",
		"unlimited_mode_label": "Ääretön peli",
		"home_subtitle": "Päivän sanahaaste",
		"home_daily_title": "Keittiön äärellä",
		"home_card_meta": "Ruoka ja kokkaus · 15 sanaa · 4 kategoriaa",
		"home_streak": "%d päivän putki",
		"home_hint_markup": "Rakenna [b][color=#1A0A5E]15 sanan[/color][/b] pyramidi — missä järjestyksessä tahansa.\nSaat [b][color=#1A0A5E]2 vihjettä[/color][/b] ja [b][color=#1A0A5E]4 elämää[/color][/b] ennen kuin pyramidi kaatuu.",
		"pool_complete": "Onneksi olkoon! Olet pelannut kaikki %s.",
		"statistics_title": "Tilastot",
		"statistics_subtitle": "Word Pyramid -tuloksesi",
		"settings_title": "Asetukset",
		"settings_subtitle": "Muokkaa haastetta",
		"language": "Kieli",
		"attempts_per_puzzle": "Yrityksiä per pulma",
		"sound_effects": "Äänitehosteet",
		"music": "Musiikki",
		"settings_note": "Uusi yritysmäärä tulee käyttöön, kun uusi pulma alkaa.",
		"replay_tutorial": "Pelaa opastus uudelleen",
		"choose_language_title": "Valitse kieli",
		"choose_language_subtitle": "Choose your language · Voit vaihtaa kielen myöhemmin asetuksista.",
		"tutorial_mode_label": "Opastus",
		"tutorial_title": "Harjoituspyramidi",
		"tutorial_skip": "Ohita",
		"tutorial_select_group": "Napauta korostettuja sanoja, jotka kuuluvat yhteen.",
		"tutorial_press_check": "Hyvä! Sijoita ryhmä painamalla Tarkista.",
		"tutorial_use_hint": "Vihje lukitsee yhden sanan oikealle riville. Paina Vihje.",
		"tutorial_finish_row": "Valitse loput korostetut sanat ja paina Tarkista.",
		"tutorial_top_word": "Viimeistele pyramidi: valitse korostettu huippusana ja paina Tarkista.",
		"tutorial_complete": "Olet valmis pelaamaan!",
		"tutorial_complete_title": "Opastus suoritettu!",
		"tutorial_complete_subtitle": "Olet valmis rakentamaan päivän sanapyramidin.",
		"tutorial_continue_daily": "Jatka päivän haasteeseen",
		"continue_to_unlimited": "Jatka äärettömään peliin",
		"continue_to_next": "Jatka seuraavaan pulmaan",
		"debug_reset_progress": "Debug: Nollaa kaikki edistyminen",
		"debug_reset_confirm": "Nollaa kaikki napauttamalla uudelleen",
		"back": "Takaisin",
		"wins": "Voitot",
		"losses": "Tappiot",
		"win_rate": "Voittoprosentti",
		"current_streak": "Nykyinen putki",
		"best_streak": "Paras putki",
		"result_score": "Tulos: %d/%d",
		"share_result": "Jaa",
		"result_copied": "Tulos kopioitu.",
		"share_daily_result": "Word Pyramid %s\nTulos: %d/%d\nPutki: %d",
		"aftermath_win_title": "Pyramidi valmis!",
		"aftermath_loss_title": "Pyramidi kaatui!",
		"aftermath_flawless": "Täydellinen ratkaisu - ei virheitä!",
		"aftermath_solved_mistakes": "Ratkaistu %d virheellä",
		"aftermath_loss_subtitle": "%d/%d oikein - huomenna uudestaan",
		"aftermath_endless_loss_subtitle": "%d/%d oikein · %d sydäntä jäljellä",
		"aftermath_endless_better_luck": "Ensi kerralla paremmin",
		"endless_hearts_remaining": "%d sydäntä jäljellä",
		"endless_out_of_hearts": "Sydämet loppuivat!",
		"endless_new_puzzle": "Uusi pulma ->",
		"back_to_home": "Takaisin kotiin",
		"aftermath_results": "Tulokset",
		"aftermath_streak_current": "%d päivän putki",
		"aftermath_streak": "%d → %d päivän putki",
		"aftermath_streak_lost": "Putki katkesi",
		"aftermath_endless_hearts": "Äärettömän pelin sydämet",
		"aftermath_group_found": "Löydetty",
		"aftermath_group_missed": "Puuttui",
		"stat_mistakes": "Virheet",
		"stat_groups": "Ryhmät",
		"stat_hints_used": "Vihjeet",
		"instructions": "Ohjeet",
		"instructions_title": "Näin pelaat",
		"instructions_subtitle": "Rakenna pyramidi yksi sanaryhmä kerrallaan.",
		"instructions_back_game": "Takaisin peliin",
		"instructions_find_title": "Etsi sanaryhmä",
		"instructions_find_body": "Valitse sanat, joita yhdistää yksi selkeä asia. Ryhmissä on 2–5 sanaa.",
		"instructions_check_title": "Tarkista valintasi",
		"instructions_check_body": "Paina Tarkista, kun koko ryhmä on valittu. Oikea ryhmä lukittuu rivilleen.",
		"instructions_hint_title": "Käytä vihjeet harkiten",
		"instructions_hint_body": "Vihje paljastaa yhden sanan ja lukitsee sen oikealle riville.",
		"instructions_mistake_title": "Säästä yrityksiäsi",
		"instructions_mistake_body": "Väärä ryhmä kuluttaa yhden yrityksen. Samaa arvausta ei voi tarkistaa uudelleen.",
		"instructions_top_title": "Saavuta huippu",
		"instructions_top_body": "Kun neljä ryhmää ovat valmiit, viimeistele pyramidi valitsemalla huippusana.",
		"instructions_group_sizes": "RYHMÄT  2 · 3 · 4 · 5",
		"instructions_quick_tip": "VINKKI  Aloita selvimmästä näkemästäsi yhteydestä.",
		"instructions_variant_a": "A  Pyramidi",
		"instructions_variant_b": "B  Vaiheet",
		"instructions_variant_c": "C  Pikaohje",
		"instructions_concept_a": "A · Visuaalinen matka pyramidin huipulle",
		"instructions_concept_b": "B · Suuret vaiheittaiset ohjekortit",
		"instructions_concept_c": "C · Tiivis pikaohjenäkymä",
		"board_title": "Valitse yhteen kuuluvat sanat",
		"daily_message": "Päivän haaste · etsi samaan ryhmään kuuluvat sanat.",
		"unlimited_message": "Ääretön peli · epäonnistunut pulma käyttää yhden päivittäisen sydämen.",
		"hint": "Vihje",
		"clear": "Tyhjennä",
		"check": "Tarkista",
		"new_game": "Uusi peli",
		"menu": "Valikko",
		"select_tooltip": "Valitse %s",
		"hint_tooltip": "Vihje: lukittu oikealle riville",
		"mistakes_left": "Virheitä jäljellä: %d / %d",
		"selected": "Valitut: %s",
		"select_words": "Valitse 1-5 sanaa tarkistettavaksi",
		"select_up_to": "Valitse 1-%d sanaa tarkistettavaksi",
		"hint_count": "Vihje %d",
		"hint_zero": "Vihje 0",
		"bonus_hint": "Bonusvihje",
		"ad_hint": "Mainos +1",
		"game_complete": "Pyramidi valmis - huippusana: %s",
		"game_failed": "Virheet loppuivat - ratkaisu näytetään.",
		"guess_failed": "Nämä sanat eivät muodosta ryhmää. Kokeile uudelleen.",
		"repeated_guess": "Olet jo kokeillut tätä yhdistelmää.",
		"missing_word": "Yksi sana puuttuu.",
		"extra_word": "Yksi sana liikaa.",
		"unlimited_hint_limit": "Rajattomassa pelissä on kaksi vihjettä per pulma.",
		"hint_placed": "Vihje: %s sijoitettiin oikealle riville.",
		"bonus_hint_earned": "Bonusvihje ansaittu! Käytä Vihje-painiketta.",
		"rewarded_hint_required": "Kaksi maksutonta vihjettä on käytetty. Katso palkittu mainos saadaksesi bonusvihjeen.",
		"rewarded_ad_unavailable": "Palkitut mainokset toimivat vain Android- tai iOS-testiversiossa.",
		"rewarded_ad_loading": "Mainosta ladataan. Se avautuu hetken kuluttua.",
		"rewarded_ad_failed": "Mainosta ei saatu ladattua: %s",
		"instructions_text": "Etsi 2, 3, 4 ja 5 sanan ryhmät sekä arvaa huippusana yhdellä valinnalla."
	}
}

var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var statistics: Dictionary = {"wins": 0, "losses": 0, "streak": 0, "best_streak": 0}
var active_game: Dictionary = {}
var daily_results: Dictionary = {}
var played_puzzle_ids: Dictionary = {"daily": [], "unlimited": []}
var endless_state: Dictionary = {"date": "", "hearts": ENDLESS_DAILY_HEARTS, "rewarded_heart_claimed": false}
var onboarding: Dictionary = DEFAULT_ONBOARDING.duplicate(true)

func _ready() -> void:
	load_data()

func load_data() -> void:
	reset_to_defaults()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return
	var saved: Dictionary = parsed
	_merge_settings(saved.get("settings", {}))
	statistics = _merge_dictionary(statistics, saved.get("statistics", {}))
	active_game = _dictionary_or_empty(saved.get("active_game", {}))
	daily_results = _dictionary_or_empty(saved.get("daily_results", {}))
	played_puzzle_ids = _merge_dictionary(played_puzzle_ids, saved.get("played_puzzle_ids", {}))
	endless_state = _merge_dictionary(endless_state, saved.get("endless_state", {}))
	onboarding = _merge_dictionary(onboarding, saved.get("onboarding", {}))

func reset_to_defaults() -> void:
	settings = DEFAULT_SETTINGS.duplicate(true)
	statistics = {"wins": 0, "losses": 0, "streak": 0, "best_streak": 0}
	active_game = {}
	daily_results = {}
	played_puzzle_ids = {"daily": [], "unlimited": []}
	endless_state = {"date": "", "hearts": ENDLESS_DAILY_HEARTS, "rewarded_heart_claimed": false}
	onboarding = DEFAULT_ONBOARDING.duplicate(true)

func reset_all_data() -> void:
	reset_to_defaults()
	save_data()

func save_data() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save data to %s" % SAVE_PATH)
		return
	var data: Dictionary = {
		"settings": settings,
		"statistics": statistics,
		"active_game": active_game,
		"daily_results": daily_results,
		"played_puzzle_ids": played_puzzle_ids,
		"endless_state": endless_state,
		"onboarding": onboarding
	}
	file.store_string(JSON.stringify(data))

func text(key: String) -> String:
	var language: String = str(settings.get("language", DEFAULT_SETTINGS["language"]))
	var table: Dictionary = TEXT.get(language, TEXT["en"])
	return str(table.get(key, TEXT["en"].get(key, key)))

func needs_language_onboarding() -> bool:
	return int(onboarding.get("version", 0)) < ONBOARDING_VERSION and not bool(onboarding.get("language_selected", false))

func needs_tutorial_onboarding() -> bool:
	return int(onboarding.get("version", 0)) < ONBOARDING_VERSION

func mark_onboarding_language_selected() -> void:
	onboarding["language_selected"] = true
	save_data()

func complete_onboarding() -> void:
	onboarding["language_selected"] = true
	onboarding["version"] = ONBOARDING_VERSION
	save_data()

func record_result(won: bool, day_key: String = "", mode: String = "", correct_count: int = 0, total_count: int = 0, solved_groups: Array[int] = []) -> void:
	if won:
		statistics["wins"] = int(statistics.get("wins", 0)) + 1
		statistics["streak"] = int(statistics.get("streak", 0)) + 1
		statistics["best_streak"] = max(int(statistics.get("best_streak", 0)), int(statistics["streak"]))
	else:
		statistics["losses"] = int(statistics.get("losses", 0)) + 1
		statistics["streak"] = 0
	if mode == "daily" and not day_key.is_empty():
		daily_results[day_key] = {
			"completed": true,
			"won": won,
			"correct_count": correct_count,
			"total_count": total_count,
			"solved_groups": solved_groups.duplicate()
		}
	save_data()

func get_daily_streak(today_key: String = "") -> int:
	var current_day: String = today_key if not today_key.is_empty() else Time.get_date_string_from_system()
	# A loss today breaks the visible daily streak. Previously this skipped back
	# to yesterday and made a lost challenge look as though the streak survived.
	if _daily_challenge_completed(current_day) and not _daily_challenge_won(current_day):
		return 0
	if not _daily_challenge_won(current_day):
		current_day = _date_offset(current_day, -1)
	var streak: int = 0
	while _daily_challenge_won(current_day):
		streak += 1
		current_day = _date_offset(current_day, -1)
	return streak

func get_daily_streak_before(day_key: String) -> int:
	var current_day: String = _date_offset(day_key, -1)
	var streak: int = 0
	while _daily_challenge_won(current_day):
		streak += 1
		current_day = _date_offset(current_day, -1)
	return streak

func daily_streak_text(today_key: String = "") -> String:
	return text("home_streak") % get_daily_streak(today_key)

func is_daily_challenge_completed(day_key: String = "") -> bool:
	var current_day: String = day_key if not day_key.is_empty() else Time.get_date_string_from_system()
	return _daily_challenge_completed(current_day)

func get_daily_result(day_key: String = "") -> Dictionary:
	var current_day: String = day_key if not day_key.is_empty() else Time.get_date_string_from_system()
	var result: Variant = daily_results.get(current_day, {})
	return result.duplicate(true) if result is Dictionary else {}

func consume_daily_streak_animation(day_key: String) -> bool:
	if day_key.is_empty():
		return false
	var result_value: Variant = daily_results.get(day_key, {})
	if not (result_value is Dictionary):
		return false
	var result: Dictionary = result_value
	if not bool(result.get("completed", false)) or bool(result.get("streak_animation_seen", false)):
		return false
	result["streak_animation_seen"] = true
	daily_results[day_key] = result
	save_data()
	return true

func get_endless_hearts(day_key: String = "") -> int:
	_refresh_endless_day(day_key)
	return clampi(int(endless_state.get("hearts", ENDLESS_DAILY_HEARTS)), 0, ENDLESS_DAILY_HEARTS)

func endless_reset_countdown_text() -> String:
	var local_time: Dictionary = Time.get_time_dict_from_system()
	var elapsed_seconds: int = (
		int(local_time.get("hour", 0)) * 3600
		+ int(local_time.get("minute", 0)) * 60
		+ int(local_time.get("second", 0))
	)
	var remaining_minutes: int = maxi(ceili(float(86400 - elapsed_seconds) / 60.0), 1)
	var hours: int = remaining_minutes / 60
	var minutes: int = remaining_minutes % 60
	return text("endless_reset_in") % [hours, minutes]

func can_start_endless(day_key: String = "") -> bool:
	return get_endless_hearts(day_key) > 0

func consume_endless_heart(day_key: String = "") -> int:
	_refresh_endless_day(day_key)
	var hearts: int = get_endless_hearts(day_key)
	if hearts > 0:
		hearts -= 1
		endless_state["hearts"] = hearts
		save_data()
	return hearts

func can_claim_rewarded_endless_heart(day_key: String = "") -> bool:
	_refresh_endless_day(day_key)
	return not bool(endless_state.get("rewarded_heart_claimed", false)) and get_endless_hearts(day_key) < ENDLESS_DAILY_HEARTS

func grant_rewarded_endless_heart(day_key: String = "") -> bool:
	if not can_claim_rewarded_endless_heart(day_key):
		return false
	endless_state["hearts"] = mini(get_endless_hearts(day_key) + 1, ENDLESS_DAILY_HEARTS)
	endless_state["rewarded_heart_claimed"] = true
	save_data()
	return true

func _refresh_endless_day(day_key: String = "") -> void:
	var current_day: String = day_key if not day_key.is_empty() else Time.get_date_string_from_system()
	if str(endless_state.get("date", "")) == current_day:
		return
	endless_state = {
		"date": current_day,
		"hearts": ENDLESS_DAILY_HEARTS,
		"rewarded_heart_claimed": false
	}
	save_data()

func _daily_challenge_completed(day_key: String) -> bool:
	var result: Variant = daily_results.get(day_key, {})
	if not (result is Dictionary):
		return false
	return bool(result.get("completed", result.get("won", false)))

func _daily_challenge_won(day_key: String) -> bool:
	var result: Variant = daily_results.get(day_key, {})
	if not (result is Dictionary):
		return false
	return bool(result.get("won", false))

func _date_offset(day_key: String, offset_days: int) -> String:
	var unix_time: int = Time.get_unix_time_from_datetime_string("%sT00:00:00" % day_key)
	var shifted_time: int = unix_time + offset_days * 86400
	var shifted_date: Dictionary = Time.get_date_dict_from_unix_time(shifted_time)
	return "%04d-%02d-%02d" % [
		int(shifted_date.get("year", 1970)),
		int(shifted_date.get("month", 1)),
		int(shifted_date.get("day", 1))
	]

func get_played_puzzle_ids(mode: String) -> Array[String]:
	var result: Array[String] = []
	var saved_ids: Variant = played_puzzle_ids.get(mode, [])
	if not (saved_ids is Array):
		return result
	for value: Variant in saved_ids:
		result.append(str(value))
	return result

func record_puzzle_played(mode: String, puzzle_id: String) -> void:
	if puzzle_id.is_empty():
		return
	var ids: Array[String] = get_played_puzzle_ids(mode)
	if not ids.has(puzzle_id):
		ids.append(puzzle_id)
		played_puzzle_ids[mode] = ids
		save_data()

func replace_played_puzzle_ids(mode: String, puzzle_ids: Array[String]) -> void:
	played_puzzle_ids[mode] = puzzle_ids.duplicate()
	save_data()

func _merge_settings(saved_settings: Variant) -> void:
	if not (saved_settings is Dictionary):
		return
	for key: Variant in DEFAULT_SETTINGS.keys():
		if saved_settings.has(key):
			settings[key] = saved_settings[key]
	if not TEXT.has(str(settings.get("language", "en"))):
		settings["language"] = DEFAULT_SETTINGS["language"]

func _merge_dictionary(defaults: Dictionary, saved_value: Variant) -> Dictionary:
	var result: Dictionary = defaults.duplicate(true)
	if saved_value is Dictionary:
		for key: Variant in saved_value.keys():
			result[key] = saved_value[key]
	return result

func _dictionary_or_empty(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}
