extends Node

# Firebase Analytics is Android-only and deliberately opt-in. All methods are
# safe no-ops in the editor and on platforms where the Android SDK is absent.

var _analytics: Variant = null
var _bundle_class: Variant = null
var _available: bool = false

func _ready() -> void:
	if OS.get_name() != "Android":
		return
	var android_runtime: Variant = Engine.get_singleton("AndroidRuntime")
	if android_runtime == null:
		return
	var analytics_class: Variant = JavaClassWrapper.wrap("com.google.firebase.analytics.FirebaseAnalytics")
	_bundle_class = JavaClassWrapper.wrap("android.os.Bundle")
	if analytics_class == null or _bundle_class == null:
		push_warning("Firebase Analytics classes are unavailable.")
		return
	_analytics = analytics_class.getInstance(android_runtime.getApplicationContext())
	_available = _analytics != null
	set_collection_enabled(
		bool(SaveManager.settings.get("analytics_enabled", false))
		and bool(SaveManager.settings.get("analytics_consent_answered", false))
	)
	if not SaveManager.achievement_unlocked.is_connected(_on_achievement_unlocked):
		SaveManager.achievement_unlocked.connect(_on_achievement_unlocked)

func set_collection_enabled(enabled: bool) -> void:
	if not _available:
		return
	_analytics.setAnalyticsCollectionEnabled(enabled)
	if enabled:
		log_event("analytics_enabled")

func log_event(event_name: String, parameters: Dictionary = {}) -> void:
	if not _available or not bool(SaveManager.settings.get("analytics_consent_answered", false)) or not bool(SaveManager.settings.get("analytics_enabled", false)):
		return
	var safe_event_name: String = _sanitize_name(event_name)
	if safe_event_name.is_empty():
		return
	var bundle: Variant = _bundle_class.Bundle()
	for raw_key: Variant in parameters.keys():
		var key: String = _sanitize_name(str(raw_key))
		if key.is_empty():
			continue
		var value: Variant = parameters[raw_key]
		if value is bool:
			bundle.putLong(key, 1 if value else 0)
		elif value is int:
			bundle.putLong(key, value)
		elif value is float:
			bundle.putDouble(key, value)
		elif value != null:
			bundle.putString(key, str(value).left(100))
	_analytics.logEvent(safe_event_name, bundle)

func _on_achievement_unlocked(unlock: Dictionary) -> void:
	log_event("achievement_unlocked", {
		"achievement_id": str(unlock.get("id", "unknown")),
		"star": int(unlock.get("unlocked_star", 1))
	})

func _sanitize_name(value: String) -> String:
	var result: String = ""
	for character: String in value.strip_edges().to_lower():
		if (character >= "a" and character <= "z") or (character >= "0" and character <= "9") or character == "_":
			result += character
		else:
			result += "_"
	result = result.left(40)
	if result.is_empty() or result[0] < "a" or result[0] > "z":
		return ""
	if result.begins_with("firebase_") or result.begins_with("google_") or result.begins_with("ga_"):
		return ""
	return result
