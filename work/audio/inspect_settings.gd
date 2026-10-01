extends SceneTree
func _initialize() -> void:
	for setting in ProjectSettings.get_property_list():
		if "audio" in setting.name and "bus" in setting.name:
			print(setting.name, " = ", ProjectSettings.get_setting(setting.name))
	var audio = load("res://assets/audio/sfx/ui_move.wav")
	print("FORMAT ", audio.format, " RATE ", audio.mix_rate)
	print("BUS FILE ", load("res://resources/audio_bus_layout.tres"))
	quit()
