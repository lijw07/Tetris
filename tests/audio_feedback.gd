extends SceneTree

var checks := 0
var failures: Array[String] = []
var played: Array[StringName] = []
var requested: Array[StringName] = []


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func run() -> void:
	var profile_path := "res://work/audio/test_profile.cfg"
	var config := ConfigFile.new()
	config.set_value("settings", "sound", 80.0)
	config.set_value("settings", "music", 0.0)
	config.save(profile_path)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	main.profile = ProfileStore.new(profile_path)
	main.get_node("ScreenScaler").free()
	root.add_child(main)
	main.music_player.stop()
	main.sound_player.sound_played.connect(func(cue: StringName): played.append(cue))
	main.gameplay.sound_requested.connect(func(cue: StringName): requested.append(cue))
	await process_frame
	check(played.is_empty(), "Initial menu focus is silent")
	var sound: SoundPlayer = main.sound_player
	var game: Gameplay = main.gameplay
	for cue in SoundPlayer.CUES:
		var audio := load("res://assets/audio/sfx/%s.wav" % cue) as AudioStreamWAV
		check(audio != null, "Imported effect exists: " + str(cue))
		check(audio.mix_rate == 44100 and not audio.stereo, "Imported mono 44.1kHz format: " + str(cue))
		check(audio.loop_mode == AudioStreamWAV.LOOP_DISABLED and audio.get_length() < 1.0, "Short one-shot: " + str(cue))
	check(sound.get_child_count() == 6, "Playback has bounded voice pool")
	check(AudioServer.get_bus_effect(0, 0) is AudioEffectHardLimiter, "Master mix limiter")
	check(AudioServer.get_bus_index(&"SFX") > 0, "Independent sound effects bus")
	var settings_button: Button = main.menu.get_node("SettingsButton")
	settings_button.mouse_entered.emit()
	settings_button.grab_focus()
	check(played == ([&"ui_move"] as Array[StringName]), "Hover and focus together do not double-play")
	await wait_ms(80)
	main.menu.get_node("HowToPlayButton").grab_focus()
	check(played.back() == &"ui_move" and played.size() == 2, "Keyboard focus traversal plays navigation tick")
	settings_button.disabled = true
	await wait_ms(80)
	settings_button.mouse_entered.emit()
	check(played.size() == 2, "Disabled button is silent")
	settings_button.disabled = false
	settings_button.pressed.emit()
	check(main.current_menu == "settings" and played.back() == &"ui_confirm", "Click survives menu replacement")
	var music_volume: float = main.music_player.volume_db
	main.menu.get_node("SoundSlider").value = 0
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"SFX")), "Sound zero truly mutes the bus")
	check(sound.get_children().all(func(v: Node): return not v.playing), "Muting stops active tails")
	var count := played.size()
	sound.play(&"rotate")
	check(played.size() == count, "Muted cues are not started")
	check(main.music_player.volume_db == music_volume, "Sound slider leaves music level unchanged")
	await wait_ms(90)
	main.menu.get_node("SoundSlider").value = 35
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index(&"SFX")), "Raising Sound unmutes")
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"SFX")) - linear_to_db(.35)) < .01, "Sound slider controls bus gain")
	check(played.back() == &"ui_adjust", "Sound slider auditions at new level")
	var persisted := ConfigFile.new()
	persisted.load(profile_path)
	check(float(persisted.get_value("settings", "sound")) == 35.0, "Sound setting persists")
	main.menu.get_node("GhostToggle").button_pressed = false
	check(played.back() == &"ui_confirm", "Toggle feedback")
	main.menu.get_node("DoneButton").pressed.emit()
	check(played.back() == &"ui_back", "Back button sound")
	main.menu.get_node("PlayButton").pressed.emit()
	game.set_process(false)
	check(played.back() == &"game_start", "Game start cue")
	game.piece = ActivePiece.new("T", Vector2i(3, 5))
	requested.clear()
	game._try_move(Vector2i.LEFT)
	check(requested == ([&"move"] as Array[StringName]), "Successful lateral move")
	requested.clear()
	game._try_move(Vector2i(-100, 0))
	game._try_move(Vector2i.DOWN)
	check(requested.is_empty(), "Blocked movement and ordinary gravity remain silent")
	game._try_rotate(1)
	check(requested == ([&"rotate"] as Array[StringName]), "Successful rotation cue")
	requested.clear()
	var occupied: Array[Vector2i] = []
	for y in range(Matrix.HEIGHT):
		for x in range(Matrix.WIDTH):
			var cell := Vector2i(x, y)
			if not game.piece.cells().has(cell): occupied.append(cell)
	game.matrix.place(occupied, "J")
	game._try_rotate(1)
	check(requested.is_empty(), "Blocked rotation is silent")
	game.new_game()
	requested.clear()
	game._hold()
	game._hold()
	check(requested.count(&"hold") == 1, "Hold only sounds when accepted")
	requested.clear()
	game._hard_drop()
	check(requested.count(&"hard_drop") == 1 and not requested.has(&"lock"), "Hard drop does not double-play lock")
	game.matrix.clear()
	game._spawn("T")
	game.piece = game._landing_piece()
	requested.clear()
	game._lock_piece()
	check(requested.has(&"lock"), "Gravity lock impact")
	game.new_game()
	requested.clear()
	Input.action_press("soft_drop")
	game._update_fall(.1)
	Input.action_release("soft_drop")
	check(requested.has(&"soft_drop"), "Manual soft-drop ticks")
	for lines in range(1, 5):
		game.matrix.clear()
		game.scores.reset()
		game.piece = ActivePiece.new("I", Vector2i(3, Matrix.HEIGHT - 4), 1)
		var filled: Array[Vector2i] = []
		for y in range(Matrix.HEIGHT - lines, Matrix.HEIGHT):
			for x in range(Matrix.WIDTH):
				if x != 5: filled.append(Vector2i(x, y))
		game.matrix.place(filled, "J")
		requested.clear()
		game._hard_drop()
		var cue := StringName("clear_%d" % lines)
		check(requested.count(cue) == 1 and game.phase == Gameplay.Phase.CLEARING, "Distinct %d-line clear cue" % lines)
		if lines == 1: game.scores.lines = 9
		game._finish_line_clear()
		if lines == 1: check(requested.has(&"level_up"), "Level-up cue at threshold")
	game._request_pause()
	check(main.current_menu == "pause" and played.back() == &"pause", "Pause cue")
	main.menu.get_node("ResumeButton").pressed.emit()
	check(main.menu == null and played.back() == &"resume", "Resume cue")
	occupied.clear()
	for y in range(Matrix.HEIGHT):
		for x in range(Matrix.WIDTH): occupied.append(Vector2i(x, y))
	game.matrix.place(occupied, "Z")
	game._spawn("T")
	check(main.current_menu == "game_over" and played.back() == &"game_over", "Game-over cue survives transition")
	sound.stop_all()
	await wait_ms(120)
	played.clear()
	for i in range(100): sound.play(&"move")
	check(played.size() == 1 and sound.get_child_count() == 6, "Rapid movement is throttled without allocating nodes")
	sound.stop_all()
	var capture_report := {}
	if DisplayServer.get_name() != "headless":
		capture_report = await check_native_mix(main)
	main.music_player.stop()
	sound.stop_all()
	main.queue_free()
	await process_frame
	await wait_ms(100)
	var report := {"checks": checks, "failures": failures, "effects": SoundPlayer.CUES.size(), "native_mix": capture_report}
	var f := FileAccess.open("res://outputs/audio-review/validation.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "\t")); f.close()
	print("AUDIO_FEEDBACK ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)


func check_native_mix(main: Control) -> Dictionary:
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 1.0
	var slot := AudioServer.get_bus_effect_count(0)
	AudioServer.add_bus_effect(0, capture)
	main.sound_player.set_level(100)
	main.music_player.set_level(100)
	main.music_player.play()
	await wait_ms(80)
	capture.clear_buffer()
	for cue in [&"ui_confirm", &"hard_drop", &"rotate", &"hold", &"clear_4", &"level_up"]:
		main.sound_player.play(cue)
	await wait_ms(450)
	var frames := capture.get_buffer(capture.get_frames_available())
	var peak := 0.0
	var pcm := PackedByteArray()
	pcm.resize(frames.size() * 4)
	for i in range(frames.size()):
		peak = maxf(peak, maxf(absf(frames[i].x), absf(frames[i].y)))
		pcm.encode_s16(i*4, int(clampf(frames[i].x, -1, 1) * 32767))
		pcm.encode_s16(i*4+2, int(clampf(frames[i].y, -1, 1) * 32767))
	check(frames.size() > 1000 and peak > .005, "Native mixer produces non-silent audio")
	check(peak <= .92, "Overlapping sounds plus full music stay below clipping")
	var recording := AudioStreamWAV.new()
	recording.format = AudioStreamWAV.FORMAT_16_BITS
	recording.stereo = true
	recording.mix_rate = int(AudioServer.get_mix_rate())
	recording.data = pcm
	recording.save_to_wav(ProjectSettings.globalize_path("res://outputs/audio-review/runtime-mix.wav"))
	main.music_player.stop()
	main.sound_player.set_level(0)
	await wait_ms(150)
	capture.clear_buffer()
	main.sound_player.play(&"clear_4")
	await wait_ms(120)
	var muted := capture.get_buffer(capture.get_frames_available())
	var muted_peak := 0.0
	for frame in muted: muted_peak = maxf(muted_peak, maxf(absf(frame.x), absf(frame.y)))
	check(muted_peak < .0001, "Zero Sound produces silence in native mixer")
	AudioServer.remove_bus_effect(0, slot)
	return {"frames": frames.size(), "peak": peak, "muted_peak": muted_peak, "mix_rate": recording.mix_rate}


func wait_ms(milliseconds: int) -> void:
	var deadline := Time.get_ticks_msec() + milliseconds
	while Time.get_ticks_msec() < deadline:
		await process_frame
