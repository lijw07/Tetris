class_name SoundPlayer
extends Node

signal sound_played(sound: StringName)

const CUES := {
	&"ui_move": -8.0, &"ui_confirm": -5.0, &"ui_back": -6.0, &"ui_adjust": -10.0,
	&"move": -10.0, &"soft_drop": -13.0, &"rotate": -6.0, &"hold": -6.0,
	&"lock": -5.0, &"hard_drop": -3.0,
	&"clear_1": -3.0, &"clear_2": -3.0, &"clear_3": -3.0, &"clear_4": -3.0,
	&"level_up": -4.0, &"game_over": -4.0, &"game_start": -5.0,
	&"pause": -7.0, &"resume": -7.0,
}
const COOLDOWNS := {&"ui_move": 60, &"ui_adjust": 80, &"move": 60, &"soft_drop": 85}
const STINGERS: Array[StringName] = [&"clear_1", &"clear_2", &"clear_3", &"clear_4", &"level_up", &"game_over", &"game_start"]

var _streams: Dictionary = {}
var _last_played: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _next_game_voice := 1
var _next_stinger_voice := 4
var _level := 80.0


func _ready() -> void:
	for cue in CUES:
		_streams[cue] = load("res://assets/audio/sfx/%s.wav" % cue) as AudioStreamWAV
	for i in range(6):
		var voice := AudioStreamPlayer.new()
		voice.name = "Voice%d" % i
		voice.bus = &"SFX"
		add_child(voice)
		_voices.append(voice)
	set_level(_level)


func play(cue: StringName) -> void:
	if _level <= 0.0 or not _streams.has(cue) or _streams[cue] == null:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(cue, -10000)) < int(COOLDOWNS.get(cue, 0)):
		return
	_last_played[cue] = now
	var voice: AudioStreamPlayer
	if str(cue).begins_with("ui_") or cue in [&"pause", &"resume"]:
		voice = _voices[0]
	elif cue in STINGERS:
		voice = _voices[_next_stinger_voice]
		_next_stinger_voice = 5 if _next_stinger_voice == 4 else 4
	else:
		voice = _voices[_next_game_voice]
		_next_game_voice = 1 + _next_game_voice % 3
	voice.stop()
	voice.stream = _streams[cue]
	voice.volume_db = float(CUES[cue])
	voice.play()
	sound_played.emit(cue)


func set_level(percent: float) -> void:
	_level = clampf(percent, 0.0, 100.0)
	var bus := AudioServer.get_bus_index(&"SFX")
	if bus >= 0:
		AudioServer.set_bus_mute(bus, _level <= 0.0)
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(_level / 100.0, 0.0001)))
	if _level <= 0.0:
		stop_all()


func stop_all() -> void:
	for voice in _voices:
		voice.stop()
