extends Node

# 音频管理系统
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

var current_bgm_path: String = ""

var scene_audio: Dictionary = {
	"entrance": {"bgm": "", "ambient": "birds"},
	"xiaoxiang_guan": {"bgm": "", "ambient": "bamboo"},
	"yihong_yuan": {"bgm": "", "ambient": "birds"},
	"longcui_an": {"bgm": "", "ambient": "wind"},
	"banquet": {"bgm": "", "ambient": "birds"}
}

func _ready() -> void:
	EventBus.building_entered.connect(_on_building_entered)

func play_bgm(stream_path: String, fade_time: float = 1.0) -> void:
	if stream_path == current_bgm_path:
		return
	current_bgm_path = stream_path
	
	if not ResourceLoader.exists(stream_path):
		return
	
	if bgm_player.playing:
		var tween := create_tween()
		tween.tween_property(bgm_player, "volume_db", -40.0, fade_time * 0.5)
		await tween.finished
	
	bgm_player.stream = load(stream_path)
	bgm_player.volume_db = -40.0
	bgm_player.play()
	var tween := create_tween()
	tween.tween_property(bgm_player, "volume_db", 0.0, fade_time * 0.5)

func stop_bgm(fade_time: float = 1.0) -> void:
	if bgm_player.playing:
		var tween := create_tween()
		tween.tween_property(bgm_player, "volume_db", -40.0, fade_time)
		await tween.finished
		bgm_player.stop()
	current_bgm_path = ""

func play_sfx(stream_path: String) -> void:
	if not ResourceLoader.exists(stream_path):
		return
	sfx_player.stream = load(stream_path)
	sfx_player.play()

func _on_building_entered(building_name: String) -> void:
	var key := building_name.to_lower().replace(" ", "_")
	if scene_audio.has(key):
		var config: Dictionary = scene_audio[key]
		if config.has("bgm") and config.bgm != "":
			play_bgm(config.bgm)
