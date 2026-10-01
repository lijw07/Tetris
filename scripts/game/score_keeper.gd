class_name ScoreKeeper
extends RefCounted

const LINE_CLEAR_POINTS: Array[int] = [0, 100, 300, 500, 800]
const LINES_PER_LEVEL := 10
const SOFT_DROP_POINTS_PER_ROW := 1
const HARD_DROP_POINTS_PER_ROW := 2

var score := 0
var lines := 0
var level := 1


func reset() -> void:
	score = 0
	lines = 0
	level = 1


func add_line_clear(cleared_rows: int) -> void:
	score += LINE_CLEAR_POINTS[cleared_rows] * level
	lines += cleared_rows
	level = 1 + floori(float(lines) / LINES_PER_LEVEL)


func add_soft_drop(rows: int) -> void:
	score += rows * SOFT_DROP_POINTS_PER_ROW


func add_hard_drop(rows: int) -> void:
	score += rows * HARD_DROP_POINTS_PER_ROW


func seconds_per_row() -> float:
	return pow(0.8 - (level - 1) * 0.007, level - 1)
