extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const PHONE_SIZE := Vector2i(390, 844)

func _ready() -> void:
	get_tree().root.size = PHONE_SIZE
	SaveManager.reset_all_data()
	SaveManager.complete_onboarding()
	SaveManager.settings["analytics_consent_answered"] = false
	SaveManager.settings["analytics_enabled"] = false
	SaveManager.save_data()

	var main: Control = MAIN_SCENE.instantiate() as Control
	get_tree().root.add_child.call_deferred(main)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var consent: Control = main.find_child("AnalyticsConsent", true, false) as Control
	_assert(consent != null, "existing players receive the one-time analytics choice")
	var card: PanelContainer = consent.find_child("AnalyticsConsentCard", true, false) as PanelContainer
	var accept_button: Button
	var decline_button: Button
	for button_node: Node in consent.find_children("*", "Button", true, false):
		var button: Button = button_node as Button
		if button.text == SaveManager.text("analytics_consent_accept"):
			accept_button = button
		elif button.text == SaveManager.text("analytics_consent_decline"):
			decline_button = button
	_assert(card != null and card.get_global_rect().end.x <= PHONE_SIZE.x + 0.5, "consent card fits the phone width")
	_assert(card.get_global_rect().end.y <= PHONE_SIZE.y + 0.5, "consent card fits the phone height")
	_assert(accept_button != null and decline_button != null, "both consent choices are visible")
	_assert(accept_button.size.y > decline_button.size.y, "the helpful choice has stronger visual emphasis")

	main.call("_apply_analytics_choice", true, false)
	await get_tree().process_frame
	_assert(bool(SaveManager.settings.get("analytics_consent_answered", false)), "the choice is remembered")
	_assert(bool(SaveManager.settings.get("analytics_enabled", false)), "accepting enables analytics")

	main.call("show_settings")
	await get_tree().process_frame
	var settings_sheet: PanelContainer = main.get("_settings_sheet") as PanelContainer
	_assert(settings_sheet != null, "settings open after consent")
	var privacy_row_found: bool = false
	for button_node: Node in settings_sheet.find_children("*", "Button", true, false):
		var button: Button = button_node as Button
		if button.text.contains(SaveManager.text("privacy_and_data")):
			privacy_row_found = true
	_assert(privacy_row_found, "settings contain a compact privacy and data row")
	for toggle_node: Node in settings_sheet.find_children("*", "CheckButton", true, false):
		_assert((toggle_node as CheckButton).text != SaveManager.text("usage_analytics"), "analytics is not a prominent settings toggle")

	main.call("_show_analytics_consent", true)
	await get_tree().process_frame
	main.call("_apply_analytics_choice", false, true)
	await get_tree().process_frame
	_assert(not bool(SaveManager.settings.get("analytics_enabled", true)), "the privacy screen can disable analytics later")

	print("ANALYTICS_CONSENT_SMOKE_TEST_PASS")
	main.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _assert(condition: bool, description: String) -> void:
	if condition:
		return
	push_error("Analytics consent smoke test failed: %s" % description)
	get_tree().quit(1)
