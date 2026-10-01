class_name Gameplay
extends Control

signal action_requested(action: String)
signal sound_requested(sound: StringName)

enum Phase { FALLING, CLEARING, OVER }

const AUTO_SHIFT_DELAY := 0.17
const AUTO_REPEAT_INTERVAL := 0.05
const SOFT_DROP_SPEEDUP := 20.0
const LOCK_DELAY := 0.5
const MAX_LOCK_RESETS := 15
const LINE_CLEAR_DURATION := 0.25

var matrix := Matrix.new()
var scores := ScoreKeeper.new()
var bag := PieceBag.new()
var piece: ActivePiece
var held_kind := ""
var hold_used := false
var phase := Phase.OVER

var _fall_elapsed := 0.0
var _soft_dropping := false
var _lock_elapsed := 0.0
var _lock_resets := 0
var _lowest_origin_row := 0
var _shift_direction := 0
var _shift_elapsed := 0.0
var _clearing_rows: Array[int] = []
var _clear_elapsed := 0.0

@onready var playfield: Playfield = $Playfield
@onready var hold_slot: PiecePreview = $HoldSlot
@onready var next_slot: PiecePreview = $NextSlot
@onready var score_value: Label = $ScoreValue
@onready var level_value: Label = $LevelValue
@onready var lines_value: Label = $LinesValue


func _ready() -> void:
	$PauseButton.pressed.connect(_request_pause)
	$PauseButton.mouse_entered.connect(_pause_navigation_sound)
	$PauseButton.focus_entered.connect(_pause_navigation_sound)


func _pause_navigation_sound() -> void:
	if $PauseButton.is_visible_in_tree() and not $PauseButton.disabled:
		sound_requested.emit(&"ui_move")


func apply_settings(values: Dictionary) -> void:
	playfield.set_ghost_enabled(bool(values.get("ghost", true)))


func new_game() -> void:
	matrix.clear()
	scores.reset()
	bag = PieceBag.new()
	held_kind = ""
	hold_used = false
	hold_slot.show_kind(held_kind)
	hold_slot.set_dimmed(false)
	playfield.reset()
	_update_hud()
	_spawn(bag.take())
	if phase == Phase.FALLING:
		sound_requested.emit(&"game_start")


func _process(delta: float) -> void:
	match phase:
		Phase.FALLING:
			_update_auto_shift(delta)
			_update_fall(delta)
		Phase.CLEARING:
			_update_line_clear(delta)


func _unhandled_input(event: InputEvent) -> void:
	if phase == Phase.OVER:
		return
	if event.is_action_pressed("pause"):
		_request_pause()
	elif phase != Phase.FALLING:
		return
	elif event.is_action_pressed("move_left"):
		_start_shift(-1)
	elif event.is_action_pressed("move_right"):
		_start_shift(1)
	elif event.is_action_pressed("rotate_clockwise"):
		_try_rotate(1)
	elif event.is_action_pressed("rotate_counterclockwise"):
		_try_rotate(-1)
	elif event.is_action_pressed("hard_drop"):
		_hard_drop()
	elif event.is_action_pressed("hold"):
		_hold()
	else:
		return
	get_viewport().set_input_as_handled()


func _request_pause() -> void:
	action_requested.emit("pause")


func _spawn(kind: String) -> void:
	piece = ActivePiece.spawned(kind)
	next_slot.show_kind(bag.peek())
	_reset_piece_timers()
	if not matrix.fits(piece.cells()):
		_end_game()
		return
	phase = Phase.FALLING
	var entered := piece.moved(Vector2i.DOWN)
	if matrix.fits(entered.cells()):
		piece = entered
	_lowest_origin_row = piece.origin.y
	_refresh_piece()


func _reset_piece_timers() -> void:
	_fall_elapsed = 0.0
	_lock_elapsed = 0.0
	_lock_resets = 0


func _start_shift(direction: int) -> void:
	_shift_direction = direction
	_shift_elapsed = 0.0
	_try_move(Vector2i(direction, 0))


func _update_auto_shift(delta: float) -> void:
	var held_direction := int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	if held_direction == 0:
		_shift_direction = 0
		return
	if held_direction != _shift_direction:
		_start_shift(held_direction)
		return
	_shift_elapsed += delta
	while _shift_elapsed >= AUTO_SHIFT_DELAY:
		_shift_elapsed -= AUTO_REPEAT_INTERVAL
		_try_move(Vector2i(_shift_direction, 0))


func _update_fall(delta: float) -> void:
	var soft_dropping := Input.is_action_pressed("soft_drop")
	if soft_dropping != _soft_dropping:
		_soft_dropping = soft_dropping
		_fall_elapsed = 0.0
	var interval := scores.seconds_per_row()
	if soft_dropping:
		interval /= SOFT_DROP_SPEEDUP
	_fall_elapsed += delta
	while _fall_elapsed >= interval:
		_fall_elapsed -= interval
		if not _try_move(Vector2i.DOWN):
			_fall_elapsed = 0.0
			break
		if soft_dropping:
			sound_requested.emit(&"soft_drop")
			scores.add_soft_drop(1)
			_update_hud()
	if _is_grounded():
		_lock_elapsed += delta
		if _lock_elapsed >= LOCK_DELAY:
			_lock_piece()


func _update_line_clear(delta: float) -> void:
	_clear_elapsed += delta
	if _clear_elapsed >= LINE_CLEAR_DURATION:
		_finish_line_clear()


func _is_grounded() -> bool:
	return not matrix.fits(piece.moved(Vector2i.DOWN).cells())


func _try_move(offset: Vector2i) -> bool:
	var candidate := piece.moved(offset)
	if not matrix.fits(candidate.cells()):
		return false
	_commit(candidate)
	if offset.x != 0:
		sound_requested.emit(&"move")
	return true


func _try_rotate(turns: int) -> void:
	var rotated := piece.rotated(turns)
	for kick in TetrominoData.kicks(piece.kind, piece.rotation, rotated.rotation):
		var candidate := rotated.moved(kick)
		if matrix.fits(candidate.cells()):
			_commit(candidate)
			sound_requested.emit(&"rotate")
			return


func _commit(candidate: ActivePiece) -> void:
	piece = candidate
	if piece.origin.y > _lowest_origin_row:
		_lowest_origin_row = piece.origin.y
		_lock_resets = 0
		_lock_elapsed = 0.0
	elif _lock_elapsed > 0.0 and _lock_resets < MAX_LOCK_RESETS:
		_lock_resets += 1
		_lock_elapsed = 0.0
	_refresh_piece()


func _landing_piece() -> ActivePiece:
	var landing := piece
	while matrix.fits(landing.moved(Vector2i.DOWN).cells()):
		landing = landing.moved(Vector2i.DOWN)
	return landing


func _hard_drop() -> void:
	var landing := _landing_piece()
	scores.add_hard_drop(landing.origin.y - piece.origin.y)
	piece = landing
	sound_requested.emit(&"hard_drop")
	_lock_piece(false)


func _hold() -> void:
	if hold_used:
		return
	hold_used = true
	sound_requested.emit(&"hold")
	var released_kind := held_kind
	held_kind = piece.kind
	hold_slot.show_kind(held_kind)
	hold_slot.set_dimmed(true)
	_spawn(bag.take() if released_kind.is_empty() else released_kind)


func _lock_piece(play_lock_sound: bool = true) -> void:
	if play_lock_sound:
		sound_requested.emit(&"lock")
	var cells := piece.cells()
	matrix.place(cells, piece.kind)
	playfield.hide_piece()
	playfield.show_settled(matrix)
	hold_used = false
	hold_slot.set_dimmed(false)
	_update_hud()
	if cells.all(func(cell: Vector2i) -> bool: return cell.y < Matrix.HIDDEN_ROWS):
		_end_game()
		return
	var full_rows := matrix.full_rows()
	if full_rows.is_empty():
		_spawn(bag.take())
		return
	_clearing_rows = full_rows
	_clear_elapsed = 0.0
	phase = Phase.CLEARING
	sound_requested.emit(StringName("clear_%d" % full_rows.size()))
	playfield.flash_rows(full_rows)


func _finish_line_clear() -> void:
	matrix.remove_rows(_clearing_rows)
	var old_level := scores.level
	scores.add_line_clear(_clearing_rows.size())
	if scores.level > old_level:
		sound_requested.emit(&"level_up")
	playfield.clear_flashes()
	playfield.show_settled(matrix)
	_update_hud()
	_spawn(bag.take())


func _refresh_piece() -> void:
	playfield.show_piece(piece, _landing_piece())


func _end_game() -> void:
	phase = Phase.OVER
	sound_requested.emit(&"game_over")
	playfield.hide_piece()
	action_requested.emit("game_over")


func _update_hud() -> void:
	score_value.text = "%06d" % scores.score
	level_value.text = "%02d" % scores.level
	lines_value.text = "%03d" % scores.lines
