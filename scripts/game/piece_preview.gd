class_name PiecePreview
extends Control

const CELL_SIZE := 24
const DIMMED_COLOR := Color(1, 1, 1, 0.35)

var _piece: Node2D
var _dimmed := false


func show_kind(kind: String) -> void:
	if _piece:
		_piece.queue_free()
		_piece = null
	if kind.is_empty():
		return
	_piece = TetrominoData.piece_scene(kind).instantiate() as Node2D
	var bounds := _cell_bounds(_piece.get_meta("cells"))
	_piece.position = (size - bounds.size * CELL_SIZE) / 2.0 - bounds.position * CELL_SIZE
	add_child(_piece)
	_apply_dimming()


func set_dimmed(dimmed: bool) -> void:
	_dimmed = dimmed
	_apply_dimming()


func _apply_dimming() -> void:
	if _piece:
		_piece.modulate = DIMMED_COLOR if _dimmed else Color.WHITE


func _cell_bounds(cells: PackedVector2Array) -> Rect2:
	var bounds := Rect2(cells[0], Vector2.ONE)
	for cell in cells:
		bounds = bounds.expand(cell).expand(cell + Vector2.ONE)
	return bounds
