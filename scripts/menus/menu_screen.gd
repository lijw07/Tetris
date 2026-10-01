class_name MenuScreen
extends Control

signal action_requested(action: String)
signal setting_changed(setting: String, value: Variant)
signal sound_requested(sound: StringName)

@export var cancel_action := ""


func _ready() -> void:
	for child in get_children():
		if child is Button and child.has_meta("action"):
			_connect_action_button(child)
		if child.has_meta("setting"):
			_connect_setting_control(child)


func apply_settings(values: Dictionary) -> void:
	for child in get_children():
		if child.has_meta("setting") and values.has(child.get_meta("setting")):
			_show_setting(child, values[child.get_meta("setting")])


func _unhandled_key_input(event: InputEvent) -> void:
	if cancel_action.is_empty() or not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	_play_action_sound(cancel_action)
	action_requested.emit(cancel_action)


func _connect_action_button(button: Button) -> void:
	button.mouse_entered.connect(_navigation_sound.bind(button))
	button.focus_entered.connect(_navigation_sound.bind(button))
	button.pressed.connect(func() -> void:
		var action := str(button.get_meta("action"))
		_play_action_sound(action)
		action_requested.emit(action)
	)
	if button.get_meta("initial_focus", false):
		button.grab_focus()


func _connect_setting_control(control: Control) -> void:
	control.mouse_entered.connect(_navigation_sound.bind(control))
	control.focus_entered.connect(_navigation_sound.bind(control))
	var setting := str(control.get_meta("setting"))
	if control is Range:
		control.value_changed.connect(func(value: float) -> void: _on_setting_changed(control, setting, value))
	elif control is BaseButton:
		control.toggled.connect(func(enabled: bool) -> void: _on_setting_changed(control, setting, enabled))


func _on_setting_changed(control: Control, setting: String, value: Variant) -> void:
	_update_readout(control, value)
	setting_changed.emit(setting, value)
	sound_requested.emit(&"ui_adjust" if control is Range else &"ui_confirm")


func _navigation_sound(control: Control) -> void:
	if not control.is_visible_in_tree():
		return
	if control is BaseButton and control.disabled:
		return
	sound_requested.emit(&"ui_move")


func _play_action_sound(action: String) -> void:
	if action in ["play", "resume"]:
		return
	sound_requested.emit(&"ui_back" if action in ["back", "main_menu"] else &"ui_confirm")


func _show_setting(control: Control, value: Variant) -> void:
	if control is Range:
		control.set_value_no_signal(float(value))
	elif control is BaseButton:
		control.set_pressed_no_signal(bool(value))
	_update_readout(control, value)


func _update_readout(control: Control, value: Variant) -> void:
	var readout := get_node_or_null(str(control.name).replace("Slider", "Value")) as Label
	if control is Range and readout:
		readout.text = "%d%%" % int(value)
