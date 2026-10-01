extends SceneTree

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func run() -> void:
	check_rotation()
	check_wall_kicks()
	check_matrix()
	check_bag()
	check_scoring()
	check_screen_scaling()
	await check_game_flow()
	await process_frame
	print("gameplay_rules: %d checks, %d failures" % [checks, failures.size()])
	for failure in failures:
		print("  FAIL ", failure)
	quit(1 if failures.size() > 0 else 0)


func sorted(cells: Array[Vector2i]) -> Array[Vector2i]:
	var copy := cells.duplicate()
	copy.sort()
	return copy


func check_rotation() -> void:
	var expected_t: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]
	check(sorted(TetrominoData.cells_for("T", 1)) == sorted(expected_t), "T clockwise state")
	var expected_i: Array[Vector2i] = [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)]
	check(sorted(TetrominoData.cells_for("I", 1)) == sorted(expected_i), "I clockwise state")
	check(sorted(TetrominoData.cells_for("O", 3)) == sorted(TetrominoData.cells_for("O", 0)), "O does not change when rotated")
	for kind in TetrominoData.KINDS:
		check(sorted(TetrominoData.cells_for(kind, 4)) == sorted(TetrominoData.cells_for(kind, 0)), "Four turns return %s to spawn" % kind)
		var piece_scene := TetrominoData.piece_scene(kind).instantiate()
		check((piece_scene.get_meta("cells") as PackedVector2Array).size() == 4, "Piece scene %s has four cells" % kind)
		piece_scene.free()


func check_wall_kicks() -> void:
	var matrix := Matrix.new()
	var vertical_i := ActivePiece.new("I", Vector2i(-2, 5), 1)
	check(matrix.fits(vertical_i.cells()), "Vertical I against left wall fits")
	var rotated := vertical_i.rotated(1)
	check(not matrix.fits(rotated.cells()), "Unkicked I rotation leaves the matrix")
	var kicked := false
	for kick in TetrominoData.kicks("I", 1, 2):
		if matrix.fits(rotated.moved(kick).cells()):
			kicked = true
			break
	check(kicked, "I rotation kicks away from the wall")


func check_matrix() -> void:
	var matrix := Matrix.new()
	var bottom: Array[Vector2i] = []
	for x in range(Matrix.WIDTH):
		bottom.append(Vector2i(x, Matrix.HEIGHT - 1))
	matrix.place(bottom, "I")
	var marker: Array[Vector2i] = [Vector2i(0, Matrix.HEIGHT - 2)]
	matrix.place(marker, "T")
	check(matrix.full_rows() == ([Matrix.HEIGHT - 1] as Array[int]), "Full row detected")
	matrix.remove_rows(matrix.full_rows())
	check(matrix.kind_at(Vector2i(0, Matrix.HEIGHT - 1)) == "T", "Rows above shift down after clear")
	check(matrix.occupied_cells().size() == 1, "Cleared row removed")
	check(not matrix.is_free(Vector2i(-1, 0)), "Outside cells are blocked")


func check_bag() -> void:
	var bag := PieceBag.new()
	var seen := {}
	for draw in range(7):
		seen[bag.take()] = true
	check(seen.size() == 7, "Each bag deals all seven pieces")


func check_scoring() -> void:
	var scores := ScoreKeeper.new()
	scores.add_line_clear(4)
	check(scores.score == 800, "Four-line clear scores 800 at level 1")
	scores.add_line_clear(3)
	scores.add_line_clear(3)
	check(scores.level == 2 and scores.lines == 10, "Level rises every 10 lines")
	check(scores.seconds_per_row() < 1.0, "Gravity speeds up with level")


func check_game_flow() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	main.profile = ProfileStore.new("user://test_profile.cfg")
	root.add_child(main)
	await process_frame
	var gameplay = main.gameplay
	check(main.current_menu == "main_menu", "Game opens on main menu")
	check(not gameplay.visible, "Board hidden behind main menu")
	main.menu.get_node("PlayButton").pressed.emit()
	await process_frame
	check(main.menu == null and gameplay.visible, "Play starts the game")
	check(gameplay.phase == gameplay.Phase.FALLING and gameplay.piece != null, "First piece spawned")
	check(gameplay.get_node("Playfield/Piece").get_child_count() > 0, "Falling piece drawn with block scenes")
	var first_kind: String = gameplay.piece.kind
	gameplay._hold()
	check(gameplay.held_kind == first_kind and gameplay.hold_used, "Hold stores the current piece")
	gameplay._hold()
	check(gameplay.held_kind == first_kind, "Hold works once per piece")
	gameplay._hard_drop()
	check(gameplay.matrix.occupied_cells().size() == 4, "Hard drop locks the piece")
	check(gameplay.scores.score > 0, "Hard drop awards points")
	check(not gameplay.hold_used, "Hold unlocks after a piece locks")
	gameplay.matrix.clear()
	var almost_full: Array[Vector2i] = []
	for x in range(Matrix.WIDTH):
		if x < 3 or x > 6:
			almost_full.append(Vector2i(x, Matrix.HEIGHT - 1))
	gameplay.matrix.place(almost_full, "J")
	gameplay.piece = ActivePiece.new("I", Vector2i(3, 0))
	var score_before: int = gameplay.scores.score
	gameplay._hard_drop()
	check(gameplay.phase == gameplay.Phase.CLEARING, "Completed row starts the clear flash")
	check(gameplay.get_node("Playfield/Flashes").get_child_count() == Matrix.WIDTH, "Clear flash covers the row")
	for frame in range(30):
		await process_frame
		gameplay._process(0.02)
	check(gameplay.scores.lines == 1, "Line counted")
	check(gameplay.scores.score >= score_before + 100, "Single line scores 100")
	check(gameplay.matrix.occupied_cells().is_empty(), "Row cleared from matrix")
	await check_soft_drop(gameplay)
	gameplay._request_pause()
	await process_frame
	check(main.current_menu == "pause" and gameplay.process_mode == Node.PROCESS_MODE_DISABLED, "Pause freezes the game")
	check(main.menu.get_node_or_null("BoardPreview") == null, "Pause shows the live board behind it")
	main.menu.get_node("SettingsButton").pressed.emit()
	await process_frame
	main.menu.get_node("GhostToggle").toggled.emit(false)
	check(not gameplay.get_node("Playfield/Ghost").visible, "Ghost setting hides ghost")
	main.menu.get_node("GhostToggle").toggled.emit(true)
	main.menu.get_node("DoneButton").pressed.emit()
	await process_frame
	check(main.current_menu == "pause", "Settings returns to pause")
	main.menu.get_node("ResumeButton").pressed.emit()
	await process_frame
	check(main.menu == null and gameplay.process_mode == Node.PROCESS_MODE_INHERIT, "Resume continues the game")
	var blocked: Array[Vector2i] = []
	for x in range(Matrix.WIDTH):
		for y in range(Matrix.HEIGHT):
			if x != 0:
				blocked.append(Vector2i(x, y))
	gameplay.matrix.place(blocked, "Z")
	gameplay._spawn("T")
	await process_frame
	check(main.current_menu == "game_over", "Blocked spawn ends the game")
	check(main.menu.get_node("ScoreValue").text == "%06d" % gameplay.scores.score, "Game over shows final score")
	main.menu.get_node("MainMenuButton").pressed.emit()
	await process_frame
	check(main.menu.get_node("BestScore").text == "BEST  %06d" % gameplay.scores.score, "Best score shown on menu")
	main.music_player.stop()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_profile.cfg"))
	main.queue_free()


func check_soft_drop(gameplay) -> void:
	gameplay.matrix.clear()
	gameplay.playfield.show_settled(gameplay.matrix)
	gameplay._spawn("T")
	gameplay._process(0.9)
	var start_row: int = gameplay.piece.origin.y
	Input.action_press("soft_drop")
	gameplay._process(1.0 / 60.0)
	check(gameplay.piece.origin.y - start_row <= 1, "Soft drop does not spend banked gravity time at once")
	for frame in range(30):
		gameplay._process(1.0 / 60.0)
	var dropped: int = gameplay.piece.origin.y - start_row
	check(dropped >= 8 and dropped <= 12, "Soft drop moves about 20 rows per second at level 1")
	Input.action_release("soft_drop")


func check_screen_scaling() -> void:
	check(is_equal_approx(ScreenScaler.window_scale_for(Vector2(1920, 1080)), 1080 * 0.85 / 640), "Window fills most of a 1080p screen")
	check(is_equal_approx(ScreenScaler.window_scale_for(Vector2(2560, 1440)), 1440 * 0.85 / 640), "Window grows on a 1440p screen")
	check(ScreenScaler.window_scale_for(Vector2(300, 200)) == ScreenScaler.MINIMUM_WINDOW_SCALE, "Window never shrinks below half size")
