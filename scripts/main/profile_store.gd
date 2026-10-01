class_name ProfileStore
extends RefCounted

const DEFAULT_PATH := "user://profile.cfg"
const DEFAULT_SETTINGS := {"music": 50.0, "sound": 80.0, "ghost": true}

var settings := DEFAULT_SETTINGS.duplicate()
var best_score := 0
var _path: String


func _init(path: String = DEFAULT_PATH) -> void:
	_path = path


func load_profile() -> void:
	var file := ConfigFile.new()
	file.load(_path)
	for key in DEFAULT_SETTINGS:
		settings[key] = file.get_value("settings", key, DEFAULT_SETTINGS[key])
	best_score = int(file.get_value("records", "best_score", 0))


func save_profile() -> void:
	var file := ConfigFile.new()
	for key in settings:
		file.set_value("settings", key, settings[key])
	file.set_value("records", "best_score", best_score)
	file.save(_path)


func change_setting(setting: String, value: Variant) -> void:
	settings[setting] = value
	save_profile()


func record_score(score: int) -> bool:
	if score <= best_score:
		return false
	best_score = score
	save_profile()
	return true
