class_name ClearFlash
extends AnimatedSprite2D

@export var play_on_ready := true


func _ready() -> void:
	if play_on_ready:
		replay()


func replay() -> void:
	frame = 0
	play(&"clear")
