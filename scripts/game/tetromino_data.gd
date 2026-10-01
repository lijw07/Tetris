class_name TetrominoData
extends RefCounted

const KINDS: Array[String] = ["I", "O", "T", "S", "Z", "J", "L"]

const SPAWN_CELLS := {
	"I": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
	"O": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	"T": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	"S": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
	"Z": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
	"J": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	"L": [Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
}

const BOX_SIZE := {"I": 4, "O": 2, "T": 3, "S": 3, "Z": 3, "J": 3, "L": 3}

const SPAWN_ORIGIN := {
	"I": Vector2i(3, 0),
	"O": Vector2i(4, 0),
	"T": Vector2i(3, 0),
	"S": Vector2i(3, 0),
	"Z": Vector2i(3, 0),
	"J": Vector2i(3, 0),
	"L": Vector2i(3, 0),
}

const BLOCK_SCENES := {
	"I": preload("res://scenes/game/blocks/block_i.tscn"),
	"O": preload("res://scenes/game/blocks/block_o.tscn"),
	"T": preload("res://scenes/game/blocks/block_t.tscn"),
	"S": preload("res://scenes/game/blocks/block_s.tscn"),
	"Z": preload("res://scenes/game/blocks/block_z.tscn"),
	"J": preload("res://scenes/game/blocks/block_j.tscn"),
	"L": preload("res://scenes/game/blocks/block_l.tscn"),
}

const PIECE_SCENES := {
	"I": preload("res://scenes/game/pieces/piece_i.tscn"),
	"O": preload("res://scenes/game/pieces/piece_o.tscn"),
	"T": preload("res://scenes/game/pieces/piece_t.tscn"),
	"S": preload("res://scenes/game/pieces/piece_s.tscn"),
	"Z": preload("res://scenes/game/pieces/piece_z.tscn"),
	"J": preload("res://scenes/game/pieces/piece_j.tscn"),
	"L": preload("res://scenes/game/pieces/piece_l.tscn"),
}

const STANDARD_KICKS := {
	Vector2i(0, 1): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	Vector2i(1, 0): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	Vector2i(1, 2): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	Vector2i(2, 1): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	Vector2i(2, 3): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
	Vector2i(3, 2): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	Vector2i(3, 0): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	Vector2i(0, 3): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
}

const LINE_PIECE_KICKS := {
	Vector2i(0, 1): [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)],
	Vector2i(1, 0): [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, -1), Vector2i(-1, 2)],
	Vector2i(1, 2): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, -2), Vector2i(2, 1)],
	Vector2i(2, 1): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, 2), Vector2i(-2, -1)],
	Vector2i(2, 3): [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, -1), Vector2i(-1, 2)],
	Vector2i(3, 2): [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)],
	Vector2i(3, 0): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, 2), Vector2i(-2, -1)],
	Vector2i(0, 3): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, -2), Vector2i(2, 1)],
}


static func cells_for(kind: String, rotation: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.assign(SPAWN_CELLS[kind])
	for turn in range(posmod(rotation, 4)):
		cells = _rotated_clockwise(cells, BOX_SIZE[kind])
	return cells


static func kicks(kind: String, from_rotation: int, to_rotation: int) -> Array[Vector2i]:
	var offsets: Array[Vector2i] = [Vector2i.ZERO]
	if kind == "O":
		return offsets
	var table: Dictionary = LINE_PIECE_KICKS if kind == "I" else STANDARD_KICKS
	offsets.assign(table[Vector2i(from_rotation, to_rotation)])
	return offsets


static func block_scene(kind: String) -> PackedScene:
	return BLOCK_SCENES[kind]


static func piece_scene(kind: String) -> PackedScene:
	return PIECE_SCENES[kind]


static func _rotated_clockwise(cells: Array[Vector2i], box_size: int) -> Array[Vector2i]:
	var rotated: Array[Vector2i] = []
	for cell in cells:
		rotated.append(Vector2i(box_size - 1 - cell.y, cell.x))
	return rotated
