extends SceneTree

const DEMO_SCENE: PackedScene = preload("res://scenes/aftermath_style_demo.tscn")

func _initialize() -> void:
	var demo: Control = DEMO_SCENE.instantiate() as Control
	root.add_child(demo)
	await process_frame
	for variant_index: int in 3:
		demo.call("_show_variant", variant_index)
		await process_frame
		await process_frame
		assert(demo.get_child_count() > 0, "Aftermath demo did not build variant %d" % variant_index)
		var page: VBoxContainer = demo.find_child("VariantPage", true, false) as VBoxContainer
		assert(page != null, "Aftermath demo variant %d has no page container" % variant_index)
		assert(page.get_combined_minimum_size().y <= 752.0, "Aftermath demo variant %d overflows the phone viewport" % variant_index)
	print("Aftermath style demo smoke test passed: 3 variants")
	demo.queue_free()
	await process_frame
	quit()
