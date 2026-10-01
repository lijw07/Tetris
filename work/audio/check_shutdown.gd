extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.get_node("ScreenScaler").free()
	main.profile = ProfileStore.new("res://work/audio/test_profile.cfg")
	root.add_child(main)
	main.sound_player.set_level(80)
	main.sound_player.play(&"clear_4")
	await create_timer(.15).timeout
	print("Testing graceful audio shutdown")
	main._quit_game()
