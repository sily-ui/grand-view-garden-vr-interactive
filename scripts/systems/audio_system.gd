extends Node

# 音频管理系统
var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var water_player: AudioStreamPlayer

var current_bgm_path: String = ""
var _bgm_change_id: int = 0
var bgm_enabled: bool = true

const GLOBAL_BGM_PATH := "res://assets/audio/bgm/bgm_outdoor_main.ogg"
const COURTYARD_BGM_PATH := "res://assets/audio/bgm/bgm_courtyard_quiet.ogg"
const DIALOG_BGM_PATH := "res://assets/audio/bgm/bgm_dialog_narrative.ogg"
const COURTYARD_AMBIENT_PATH := "res://assets/audio/ambient/wind_leaves_loop.ogg"
const WATER_AMBIENT_PATH := "res://assets/audio/ambient/water_stream_loop.ogg"

var sfx_aliases: Dictionary = {
	"door_open": "res://assets/audio/sfx/gate_wood_open.ogg",
	"gate_open": "res://assets/audio/sfx/gate_wood_open.ogg",
}

# 中文建筑名 → 场景key映射
var _building_name_map: Dictionary = {
	"大门": "entrance", "荣国府": "entrance", "入口": "entrance",
	"潇湘馆": "xiaoxiang_guan",
	"怡红院": "yihong_yuan",
	"栊翠庵": "longcui_an",
	"大观楼": "banquet", "宴席": "banquet",
	"稻香村": "daoxiang_cun", "蘅芜苑": "hengwu_yuan",
}

var scene_audio: Dictionary = {
	"entrance": {"bgm": GLOBAL_BGM_PATH, "volume": -14.0},
	"xiaoxiang_guan": {"bgm": COURTYARD_BGM_PATH, "volume": -17.0},
	"yihong_yuan": {"bgm": COURTYARD_BGM_PATH, "volume": -17.0},
	"longcui_an": {"bgm": COURTYARD_BGM_PATH, "volume": -17.0},
	"banquet": {"bgm": COURTYARD_BGM_PATH, "volume": -17.0},
	"daoxiang_cun": {"bgm": COURTYARD_BGM_PATH, "volume": -17.0},
	"hengwu_yuan": {"bgm": COURTYARD_BGM_PATH, "volume": -17.0},
}

func _ready() -> void:
	add_to_group("audio_system")
	_init_players()
	EventBus.building_entered.connect(_on_building_entered)
	EventBus.building_exited.connect(_on_building_exited)
	EventBus.dialog_started.connect(_on_dialog_started)
	EventBus.dialog_ended.connect(_on_dialog_ended)
	if bgm_enabled:
		play_bgm(GLOBAL_BGM_PATH, 2.0, -14.0)
	_play_looping_layer(ambient_player, COURTYARD_AMBIENT_PATH, -26.0)
	_play_looping_layer(water_player, WATER_AMBIENT_PATH, -24.0)

func _init_players() -> void:
	bgm_player = get_node_or_null("BGMPlayer") as AudioStreamPlayer
	if not bgm_player:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "BGMPlayer"
		add_child(bgm_player)
	bgm_player.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"

	sfx_player = get_node_or_null("SFXPlayer") as AudioStreamPlayer
	if not sfx_player:
		sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer"
		add_child(sfx_player)
	sfx_player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"

	ambient_player = get_node_or_null("CourtyardAmbientPlayer") as AudioStreamPlayer
	if not ambient_player:
		ambient_player = AudioStreamPlayer.new()
		ambient_player.name = "CourtyardAmbientPlayer"
		add_child(ambient_player)
	ambient_player.bus = sfx_player.bus

	water_player = get_node_or_null("WaterAmbientPlayer") as AudioStreamPlayer
	if not water_player:
		water_player = AudioStreamPlayer.new()
		water_player.name = "WaterAmbientPlayer"
		add_child(water_player)
	water_player.bus = sfx_player.bus

func play_bgm(stream_path: String, fade_time: float = 1.0, target_volume_db: float = -12.0) -> void:
	if not bgm_enabled:
		return
	if stream_path == current_bgm_path:
		return
	_bgm_change_id += 1
	var change_id: int = _bgm_change_id
	
	if not ResourceLoader.exists(stream_path):
		if stream_path != GLOBAL_BGM_PATH and ResourceLoader.exists(GLOBAL_BGM_PATH):
			play_bgm(GLOBAL_BGM_PATH, fade_time, target_volume_db)
		return
	current_bgm_path = stream_path
	
	if bgm_player.playing:
		var tween := create_tween()
		tween.tween_property(bgm_player, "volume_db", -40.0, fade_time * 0.5)
		await tween.finished
		if change_id != _bgm_change_id:
			return
	
	var loaded_stream: Resource = load(stream_path)
	var audio_stream := loaded_stream as AudioStream
	if not audio_stream:
		return
	_set_stream_loop(audio_stream)
	bgm_player.stream = audio_stream
	bgm_player.volume_db = -40.0
	bgm_player.play()
	var tween := create_tween()
	tween.tween_property(bgm_player, "volume_db", target_volume_db, fade_time * 0.5)

func stop_bgm(fade_time: float = 1.0) -> void:
	_bgm_change_id += 1
	if bgm_player.playing:
		var tween := create_tween()
		tween.tween_property(bgm_player, "volume_db", -40.0, fade_time)
		await tween.finished
		bgm_player.stop()
	current_bgm_path = ""

func play_sfx(stream_path: String) -> void:
	if sfx_aliases.has(stream_path):
		stream_path = sfx_aliases[stream_path]
	if not ResourceLoader.exists(stream_path):
		return
	var loaded_stream: Resource = load(stream_path)
	var audio_stream := loaded_stream as AudioStream
	if not audio_stream:
		return
	sfx_player.stream = audio_stream
	sfx_player.volume_db = -9.0
	sfx_player.play()

func _play_looping_layer(player: AudioStreamPlayer, stream_path: String, volume_db: float) -> void:
	if not player or not ResourceLoader.exists(stream_path):
		return
	var loaded_stream: Resource = load(stream_path)
	var audio_stream := loaded_stream as AudioStream
	if not audio_stream:
		return
	_set_stream_loop(audio_stream)
	player.stream = audio_stream
	player.volume_db = volume_db
	player.play()

func _set_stream_loop(audio_stream: AudioStream) -> void:
	if audio_stream is AudioStreamOggVorbis:
		(audio_stream as AudioStreamOggVorbis).loop = true
	elif audio_stream is AudioStreamMP3:
		(audio_stream as AudioStreamMP3).loop = true
	elif audio_stream is AudioStreamWAV:
		(audio_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD

func _on_building_entered(building_name: String) -> void:
	if not bgm_enabled:
		return
	var key: String = ""
	if _building_name_map.has(building_name):
		key = _building_name_map[building_name]
	else:
		key = building_name.to_lower().replace(" ", "_")
	
	if scene_audio.has(key):
		var config: Dictionary = scene_audio[key]
		var bgm_path: String = config.get("bgm", "")
		var vol: float = config.get("volume", -17.0)
		if not bgm_path.is_empty():
			play_bgm(bgm_path, 1.8, vol)

func _on_building_exited(_building_name: String) -> void:
	if bgm_enabled:
		play_bgm(GLOBAL_BGM_PATH, 1.8, -14.0)

func _on_dialog_started(_dialog_id: String) -> void:
	if bgm_enabled:
		play_bgm(DIALOG_BGM_PATH, 1.0, -20.0)

func _on_dialog_ended(_dialog_id: String) -> void:
	if bgm_enabled:
		play_bgm(GLOBAL_BGM_PATH, 1.5, -14.0)
