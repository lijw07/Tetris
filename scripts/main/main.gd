extends Control

const DESIGN_SIZE := Vector2(960, 640)
const MENUS := {
	"main_menu": preload("res://scenes/menus/main_menu.tscn"),
	"how_to_play": preload("res://scenes/menus/how_to_play_menu.tscn"),
	"settings": preload("res://scenes/menus/settings_menu.tscn"),
	"pause": preload("res://scenes/menus/pause_menu.tscn"),
	"restart": preload("res://scenes/menus/restart_menu.tscn"),
	"game_over": preload("res://scenes/menus/game_over_menu.tscn"),
}
const WEB_EXIT_SCRIPT := "window.close(); if (!window.closed && history.length > 1) { history.back(); }"

var profile := ProfileStore.new()
var current_menu := ""
var menu: MenuScreen
var menu_history: Array[String] = []
var _closing := false

@onready var stage: Control = $Stage
@onready var gameplay: Gameplay = $Stage/Gameplay
@onready var music_player: MusicPlayer = $MusicPlayer
@onready var sound_player: SoundPlayer = $SoundPlayer


func _ready() -> void:
	get_tree().auto_accept_quit = false
	profile.load_profile()
	gameplay.action_requested.connect(_on_action_requested)
	gameplay.sound_requested.connect(sound_player.play)
	gameplay.apply_settings(profile.settings)
	sound_player.set_level(float(profile.settings.sound))
	music_player.set_level(float(profile.settings.music))
	music_player.set_enabled(true)
	resized.connect(_fit_stage)
	_fit_stage()
	_return_to_menu()


func _fit_stage() -> void:
	var factor := maxf(minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y), 0.05)
	stage.scale = Vector2.ONE * factor
	stage.position = (size - DESIGN_SIZE * factor) / 2.0


func _on_action_requested(action: String) -> void:
	match action:
		"quit":
			_quit_game()
		"back":
			_open_menu(menu_history.pop_back() if not menu_history.is_empty() else "main_menu")
		"play":
			_start_game()
		"resume":
			_resume_game()
		"pause":
			_pause_game()
		"game_over":
			_show_game_over()
		"main_menu":
			_return_to_menu()
		_:
			menu_history.append(current_menu)
			_open_menu(action)


func _on_setting_changed(setting: String, value: Variant) -> void:
	profile.change_setting(setting, value)
	gameplay.apply_settings(profile.settings)
	if setting == "music":
		music_player.set_level(float(value))
	elif setting == "sound":
		sound_player.set_level(float(value))


func _start_game() -> void:
	_close_menu()
	gameplay.visible = true
	gameplay.new_game()
	_set_gameplay_running(true)


func _resume_game() -> void:
	sound_player.play(&"resume")
	_close_menu()
	_set_gameplay_running(true)


func _pause_game() -> void:
	sound_player.play(&"pause")
	_set_gameplay_running(false)
	menu_history.clear()
	_open_menu("pause")


func _return_to_menu() -> void:
	_set_gameplay_running(false)
	gameplay.visible = false
	menu_history.clear()
	_open_menu("main_menu")


func _show_game_over() -> void:
	_set_gameplay_running(false)
	menu_history.clear()
	var is_new_best := profile.record_score(gameplay.scores.score)
	_open_menu("game_over")
	menu.get_node("ScoreValue").text = "%06d" % gameplay.scores.score
	menu.get_node("Stats").text = "LEVEL %02d   LINES %03d" % [gameplay.scores.level, gameplay.scores.lines]
	if is_new_best:
		menu.get_node("Subtitle").text = "New best!"


func _open_menu(key: String) -> void:
	_close_menu()
	current_menu = key
	menu = MENUS[key].instantiate()
	stage.add_child(menu)
	menu.action_requested.connect(_on_action_requested)
	menu.setting_changed.connect(_on_setting_changed)
	menu.sound_requested.connect(sound_player.play)
	menu.apply_settings(profile.settings)
	if key == "main_menu":
		menu.get_node("BestScore").text = "BEST  %06d" % profile.best_score


func _close_menu() -> void:
	current_menu = ""
	if menu:
		stage.remove_child(menu)
		menu.queue_free()
		menu = null


func _set_gameplay_running(running: bool) -> void:
	gameplay.process_mode = Node.PROCESS_MODE_INHERIT if running else Node.PROCESS_MODE_DISABLED


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_game()


func _quit_game() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval(WEB_EXIT_SCRIPT)
		return
	if _closing:
		return
	_closing = true
	_set_gameplay_running(false)
	sound_player.stop_all()
	music_player.stop()
	# Let the audio thread release active playback before the engine shuts down.
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()
