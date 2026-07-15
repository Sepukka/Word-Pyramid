extends Node

signal rewarded_hint_earned
signal rewarded_heart_earned
signal rewarded_ad_unavailable(message: String)

# Google's official Android rewarded test unit. Replace this only for a
# release build after creating a real rewarded ad unit in AdMob.
const REWARDED_TEST_UNIT_ID: String = "ca-app-pub-3940256099942544/5224354917"

var _rewarded_ad: RewardedAd
var _reward_listener: OnUserEarnedRewardListener = OnUserEarnedRewardListener.new()
var _load_callback: RewardedAdLoadCallback = RewardedAdLoadCallback.new()
var _content_callback: FullScreenContentCallback = FullScreenContentCallback.new()
var _is_loading: bool = false
var _show_when_loaded: bool = false
var _reward_context: String = ""

func _ready() -> void:
	if not _is_mobile_platform():
		return
	_reward_listener.on_user_earned_reward = _on_user_earned_reward
	_load_callback.on_ad_loaded = _on_ad_loaded
	_load_callback.on_ad_failed_to_load = _on_ad_failed_to_load
	_content_callback.on_ad_dismissed_full_screen_content = _discard_rewarded_ad
	_content_callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
		_discard_rewarded_ad()
	MobileAds.initialize()
	_load_rewarded_ad()

func request_rewarded_hint() -> void:
	_request_rewarded_ad("hint")

func request_rewarded_heart() -> void:
	_request_rewarded_ad("heart")

func _request_rewarded_ad(context: String) -> void:
	if not _is_mobile_platform():
		rewarded_ad_unavailable.emit(SaveManager.text("rewarded_ad_unavailable"))
		return
	_reward_context = context
	if _rewarded_ad == null:
		_show_when_loaded = true
		if not _is_loading:
			_load_rewarded_ad()
		rewarded_ad_unavailable.emit(SaveManager.text("rewarded_ad_loading"))
		return
	_show_rewarded_ad()

func _load_rewarded_ad() -> void:
	if _is_loading or _rewarded_ad != null:
		return
	_is_loading = true
	RewardedAdLoader.new().load(REWARDED_TEST_UNIT_ID, AdRequest.new(), _load_callback)

func _on_ad_loaded(ad: RewardedAd) -> void:
	_is_loading = false
	_rewarded_ad = ad
	_rewarded_ad.full_screen_content_callback = _content_callback
	if _show_when_loaded:
		_show_rewarded_ad()

func _on_ad_failed_to_load(error: LoadAdError) -> void:
	_is_loading = false
	_show_when_loaded = false
	_reward_context = ""
	rewarded_ad_unavailable.emit(SaveManager.text("rewarded_ad_failed") % error.message)

func _on_user_earned_reward(_item: RewardedItem) -> void:
	if _reward_context == "heart":
		rewarded_heart_earned.emit()
	else:
		rewarded_hint_earned.emit()
	_reward_context = ""

func _discard_rewarded_ad() -> void:
	if _rewarded_ad != null:
		_rewarded_ad.destroy()
		_rewarded_ad = null
	_reward_context = ""
	_load_rewarded_ad()

func _show_rewarded_ad() -> void:
	if _rewarded_ad == null:
		return
	_show_when_loaded = false
	_rewarded_ad.show(_reward_listener)

func _is_mobile_platform() -> bool:
	return OS.get_name() == "Android" or OS.get_name() == "iOS"
