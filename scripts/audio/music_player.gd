class_name MusicPlayer
extends AudioStreamPlayer


func _ready() -> void:
	var loop := stream as AudioStreamWAV
	if loop:
		loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
		loop.loop_begin = 0
		loop.loop_end = roundi(loop.get_length() * loop.mix_rate)


func set_enabled(enabled: bool) -> void:
	if enabled and not playing:
		play()
	elif not enabled:
		stop()


func set_level(percent: float) -> void:
	volume_db = linear_to_db(maxf(percent / 100.0, 0.0001)) - 2.0
