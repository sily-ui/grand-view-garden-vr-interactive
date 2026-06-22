extends Node

# 音频管理系统
var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var current_bgm_path: String = ""

# 中文建筑名 → 场景key映射
var _building_name_map: Dictionary = {
	"大门": "entrance", "荣国府": "entrance", "入口": "entrance",
	"潇湘馆": "xiaoxiang_guan",
	"怡红院": "yihong_yuan",
	"栊翠庵": "longcui_an",
	"大观楼": "banquet", "宴席": "banquet",
	"稻香村": "entrance", "蘅芜苑": "entrance",
}

var scene_audio: Dictionary = {
	"entrance": {"bgm": "", "ambient": "birds"},
	"xiaoxiang_guan": {"bgm": "", "ambient": "bamboo"},
	"yihong_yuan": {"bgm": "", "ambient": "birds"},
	"longcui_an": {"bgm": "", "ambient": "wind"},
	"banquet": {"bgm": "", "ambient": "birds"}
}

func _ready() -> void:
	# 动态创建子节点，避免依赖场景配置
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "Master"
	add_child(bgm_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = "Master"
	add_child(sfx_player)
	
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
	# 先尝试中文名映射，再尝试英文key直接匹配
	var key: String = ""
	if _building_name_map.has(building_name):
		key = _building_name_map[building_name]
	else:
		key = building_name.to_lower().replace(" ", "_")
	
	if scene_audio.has(key):
		var config: Dictionary = scene_audio[key]
		if config.has("bgm") and config.bgm != "":
			play_bgm(config.bgm)
