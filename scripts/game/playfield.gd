class_name Playfield
extends Node2D

const CELL_SIZE := 24
const GHOST_SCENE := preload("res://scenes/game/blocks/ghost_block.tscn")
const CLEAR_FLASH_SCENE := preload("res://scenes/game/effects/clear_flash.tscn")

@onready var _settled_layer: Node2D = $Settled
@onready var _ghost_layer: Node2D = $Ghost
@onready var _piece_layer: Node2D = $Piece
@onready var _flash_layer: Node2D = $Flashes


func reset() -> void:
	for layer in [_settled_layer, _ghost_layer, _piece_layer, _flash_layer]:
		_clear_layer(layer)


func set_ghost_enabled(enabled: bool) -> void:
	_ghost_layer.visible = enabled


func show_settled(matrix: Matrix) -> void:
	_clear_layer(_settled_layer)
	for cell in matrix.occupied_cells():
		_add_block(_settled_layer, TetrominoData.block_scene(matrix.kind_at(cell)), cell)


func show_piece(piece: ActivePiece, landing: ActivePiece) -> void:
	_show_cells(_ghost_layer, GHOST_SCENE, landing.cells())
	_show_cells(_piece_layer, TetrominoData.block_scene(piece.kind), piece.cells())


func hide_piece() -> void:
	_clear_layer(_ghost_layer)
	_clear_layer(_piece_layer)


func flash_rows(rows: Array[int]) -> void:
	for y in rows:
		for x in range(Matrix.WIDTH):
			_add_block(_flash_layer, CLEAR_FLASH_SCENE, Vector2i(x, y))


func clear_flashes() -> void:
	_clear_layer(_flash_layer)


func _show_cells(layer: Node2D, scene: PackedScene, cells: Array[Vector2i]) -> void:
	_clear_layer(layer)
	for cell in cells:
		_add_block(layer, scene, cell)


func _add_block(layer: Node2D, scene: PackedScene, cell: Vector2i) -> void:
	if cell.y < Matrix.HIDDEN_ROWS:
		return
	var block := scene.instantiate() as Node2D
	block.position = Vector2(cell.x, cell.y - Matrix.HIDDEN_ROWS) * CELL_SIZE
	layer.add_child(block)


func _clear_layer(layer: Node2D) -> void:
	for child in layer.get_children():
		layer.remove_child(child)
		child.queue_free()
