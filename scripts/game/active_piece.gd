class_name ActivePiece
extends RefCounted

var kind: String
var origin: Vector2i
var rotation: int


func _init(piece_kind: String, piece_origin: Vector2i, piece_rotation: int = 0) -> void:
	kind = piece_kind
	origin = piece_origin
	rotation = piece_rotation


static func spawned(piece_kind: String) -> ActivePiece:
	return ActivePiece.new(piece_kind, TetrominoData.SPAWN_ORIGIN[piece_kind])


func cells() -> Array[Vector2i]:
	var placed: Array[Vector2i] = []
	for cell in TetrominoData.cells_for(kind, rotation):
		placed.append(cell + origin)
	return placed


func moved(offset: Vector2i) -> ActivePiece:
	return ActivePiece.new(kind, origin + offset, rotation)


func rotated(turns: int) -> ActivePiece:
	return ActivePiece.new(kind, origin, posmod(rotation + turns, 4))
