class_name ScreenScaler
extends Node

const DESIGN_SIZE := Vector2(960, 640)
const SCREEN_FILL := 0.85
const MINIMUM_WINDOW_SCALE := 0.5


func _ready() -> void:
	if _manages_window():
		DisplayServer.window_set_min_size(Vector2i(DESIGN_SIZE * MINIMUM_WINDOW_SCALE))
		_fit_window_to_screen()


func _fit_window_to_screen() -> void:
	var usable := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var window_size := Vector2i(DESIGN_SIZE * window_scale_for(Vector2(usable.size)))
	DisplayServer.window_set_size(window_size)
	DisplayServer.window_set_position(usable.position + (usable.size - window_size) / 2)


static func window_scale_for(screen_size: Vector2) -> float:
	var fitting := screen_size * SCREEN_FILL / DESIGN_SIZE
	return maxf(minf(fitting.x, fitting.y), MINIMUM_WINDOW_SCALE)


func _manages_window() -> bool:
	var embedded := OS.has_feature("web") or OS.has_feature("mobile")
	return not embedded and DisplayServer.get_name() != "headless"
