class_name Matrix
extends RefCounted

const WIDTH := 10
const HEIGHT := 22
const HIDDEN_ROWS := 2
const EMPTY := ""

var _rows: Array[PackedStringArray] = []


func _init() -> void:
	clear()


func clear() -> void:
	_rows.clear()
	for row in range(HEIGHT):
		_rows.append(_empty_row())


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < WIDTH and cell.y >= 0 and cell.y < HEIGHT


func is_free(cell: Vector2i) -> bool:
	return is_inside(cell) and kind_at(cell) == EMPTY


func fits(cells: Array[Vector2i]) -> bool:
	return cells.all(is_free)


func kind_at(cell: Vector2i) -> String:
	return _rows[cell.y][cell.x]


func place(cells: Array[Vector2i], kind: String) -> void:
	for cell in cells:
		_rows[cell.y][cell.x] = kind


func full_rows() -> Array[int]:
	var rows: Array[int] = []
	for y in range(HEIGHT):
		if not _rows[y].has(EMPTY):
			rows.append(y)
	return rows


func remove_rows(rows: Array[int]) -> void:
	var ordered := rows.duplicate()
	ordered.sort()
	for y in ordered:
		_rows.remove_at(y)
		_rows.insert(0, _empty_row())


func occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(HEIGHT):
		for x in range(WIDTH):
			if _rows[y][x] != EMPTY:
				cells.append(Vector2i(x, y))
	return cells


func _empty_row() -> PackedStringArray:
	var row := PackedStringArray()
	row.resize(WIDTH)
	row.fill(EMPTY)
	return row
