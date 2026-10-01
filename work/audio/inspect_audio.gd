extends SceneTree
func _initialize() -> void:
	for name in ["AudioEffectLimiter", "AudioEffectHardLimiter", "AudioEffectCapture"]:
		if ClassDB.class_exists(name):
			var effect = ClassDB.instantiate(name)
			print(name, " ", effect.get_property_list())
	quit()
