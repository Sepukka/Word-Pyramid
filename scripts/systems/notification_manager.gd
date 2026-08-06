extends Node

const REMINDER_HOUR: int = 10
const REMINDER_MINUTE: int = 0
const BRIDGE_CLASS: String = "com.sepukka.wordpyramid.notifications.DailyReminderBridge"

var _android_runtime: Object
var _bridge: JavaClass

func _ready() -> void:
	if not OS.has_feature("android"):
		return
	_android_runtime = Engine.get_singleton("AndroidRuntime")
	if _android_runtime == null:
		push_warning("AndroidRuntime is unavailable; daily notifications are disabled.")
		return
	_bridge = JavaClassWrapper.wrap(BRIDGE_CLASS)
	call_deferred("refresh_schedule")

func is_supported() -> bool:
	return OS.has_feature("android") and _android_runtime != null and _bridge != null

func set_daily_reminders_enabled(enabled: bool, request_permission: bool = true) -> void:
	SaveManager.settings["notification_consent_answered"] = true
	SaveManager.settings["daily_notifications_enabled"] = enabled
	SaveManager.save_data()
	if not is_supported():
		return
	if enabled:
		if request_permission:
			_request_permission()
		refresh_schedule()
	else:
		_cancel_schedule()

func refresh_schedule() -> void:
	if not is_supported():
		return
	if not bool(SaveManager.settings.get("daily_notifications_enabled", false)) or not SaveManager.is_daily_unlocked():
		_cancel_schedule()
		return
	var context: Object = _android_runtime.getApplicationContext()
	if context == null:
		return
	_bridge.scheduleDailyReminder(
		context,
		REMINDER_HOUR,
		REMINDER_MINUTE,
		SaveManager.is_daily_challenge_completed(),
		SaveManager.text("daily_notification_title"),
		SaveManager.text("daily_notification_body"),
		SaveManager.text("daily_notification_channel")
	)

func _request_permission() -> void:
	var activity: Object = _android_runtime.getActivity()
	if activity != null:
		_bridge.requestNotificationPermission(activity)

func _cancel_schedule() -> void:
	if not is_supported():
		return
	var context: Object = _android_runtime.getApplicationContext()
	if context != null:
		_bridge.cancelDailyReminder(context)
