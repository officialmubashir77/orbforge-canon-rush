extends Node
class_name OrbAudio

var clips: Dictionary = {}
var channels: Array[AudioStreamPlayer] = []
var channel_index: int = 0
var music_player: AudioStreamPlayer
var music_level: float = 0.35
var sfx_level: float = 0.65

func _ready() -> void:
    for name in ["shot", "impact", "split", "coin", "hurt", "win", "button", "upgrade"]:
        clips[name] = load("res://assets/audio/" + name + ".wav")
    for i in range(10):
        var player: AudioStreamPlayer = AudioStreamPlayer.new()
        add_child(player)
        channels.append(player)
    music_player = AudioStreamPlayer.new()
    music_player.stream = load("res://assets/audio/ambient.wav")
    music_player.volume_db = -22.0
    add_child(music_player)
    music_player.finished.connect(_loop_music)
    music_player.play()

func _loop_music() -> void:
    if music_level > 0.01 and music_player != null:
        music_player.play()

func set_levels(music: float, sound_effects: float) -> void:
    music_level = clampf(music, 0.0, 1.0)
    sfx_level = clampf(sound_effects, 0.0, 1.0)
    if music_player != null:
        music_player.volume_db = -80.0 if music_level < 0.01 else linear_to_db(music_level) - 13.0
        if not music_player.playing and music_level > 0.01:
            music_player.play()

func play_sfx(id: String) -> void:
    if sfx_level < 0.01 or not clips.has(id):
        return
    var channel: AudioStreamPlayer = channels[channel_index]
    channel_index = (channel_index + 1) % channels.size()
    channel.stop()
    channel.stream = clips[id]
    channel.volume_db = linear_to_db(sfx_level) - 8.0
    channel.pitch_scale = randf_range(0.94, 1.06) if id == "impact" or id == "shot" else 1.0
    channel.play()
