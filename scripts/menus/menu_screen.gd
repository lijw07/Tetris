class_name MenuScreen
extends Control

signal action_requested(action: String)
signal setting_changed(setting: String, value: Variant)
signal sound_requested(sound: StringName)

const FOCUS_FRAME_PADDING := 8.0

@export var cancel_action := ""

@onready var _focus_frame := get_node_or_null("FocusFrame") as Control


func _ready() -> void:
	for child in get_children():
		if child is Control and child.focus_mode != Control.FOCUS_NONE:
			_make_focus_follow_mouse(child)
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


func _make_focus_follow_mouse(control: Control) -> void:
	control.mouse_entered.connect(control.grab_focus)
	control.focus_entered.connect(_navigation_sound.bind(control))
	control.focus_entered.connect(_frame_focused_row.bind(control))
	if control is Button:
		control.focus_entered.connect(_keep_text_readable_while_focused.bind(control))
		control.focus_exited.connect(control.remove_theme_color_override.bind("font_hover_color"))


func _frame_focused_row(control: Control) -> void:
	if not _focus_frame:
		return
	var row_label := _row_label_for(control)
	_focus_frame.visible = row_label != null
	if row_label:
		var row := row_label.get_rect().merge(control.get_rect()).grow(FOCUS_FRAME_PADDING)
		_focus_frame.position = row.position
		_focus_frame.size = row.size


func _row_label_for(control: Control) -> Control:
	if not control.has_meta("setting"):
		return null
	return get_node_or_null(str(control.get_meta("setting")).capitalize() + "Label") as Control


func _keep_text_readable_while_focused(button: Button) -> void:
	button.add_theme_color_override("font_hover_color", button.get_theme_color("font_focus_color"))


func _connect_action_button(button: Button) -> void:
	button.pressed.connect(func() -> void:
		var action := str(button.get_meta("action"))
		_play_action_sound(action)
		action_requested.emit(action)
	)
	if button.get_meta("initial_focus", false):
		button.grab_focus()


func _connect_setting_control(control: Control) -> void:
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
