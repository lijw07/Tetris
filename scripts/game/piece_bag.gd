class_name PieceBag
extends RefCounted

var _queue: Array[String] = []


func take() -> String:
	_refill_when_empty()
	return _queue.pop_front()


func peek() -> String:
	_refill_when_empty()
	return _queue.front()


func _refill_when_empty() -> void:
	if not _queue.is_empty():
		return
	var bag := TetrominoData.KINDS.duplicate()
	bag.shuffle()
	_queue.assign(bag)
