extends Node

## 语音配音系统（本地预生成模式）
## 从 assets/audio/voice/ 加载预生成的 WAV 文件播放
## 读取 assets/config/tts_config.json（VoiceDesign 角色音色配置），
## 为每个角色绑定独立的播放速度，使旁白/刘姥姥/李纨等音色听感互不混淆。

signal speech_started(speaker: String, text: String)
signal speech_finished(speaker: String)

# 播放器
var audio_player: AudioStreamPlayer

# 状态
var is_speaking: bool = false
var current_speaker: String = ""
var enabled: bool = true
var speech_token: int = 0
# 全局默认播放速度（配置缺失或旁白时的回退值）
var playback_speed: float = 1.0

# VoiceDesign 角色音色配置（voice_key → {"speed": float, ...}）
var _voice_config: Dictionary = {}

# 角色名 → 语音key映射
var _speaker_voice_map: Dictionary = {
	"旁白": "narrator",
	"刘姥姥": "liulaolao",
	"贾母": "jiamu",
	"王熙凤": "xifeng",
	"林黛玉": "daiyu",
	"贾宝玉": "baoyu",
	"妙玉": "miaoyu",
	"李纨": "liwan",
	"薛宝钗": "baochai",
	"周瑞家": "zhou",
}

const TTS_CONFIG_PATH := "res://assets/config/tts_config.json"

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "TTSPlayer"
	# 使用 Voice 音频总线，若不存在则回退到 Master
	var voice_bus := AudioServer.get_bus_index("Voice")
	if voice_bus >= 0:
		audio_player.bus = "Voice"
	else:
		audio_player.bus = "Master"
	audio_player.finished.connect(_on_audio_finished)
	add_child(audio_player)
	# 读取 VoiceDesign 配置，建立各角色独立播放速度
	_load_voice_config()

## 读取 VoiceDesign 角色音色配置文件
func _load_voice_config() -> void:
	if not ResourceLoader.exists(TTS_CONFIG_PATH):
		push_warning("TTSSystem: 找不到音色配置 %s，回退全局速度" % TTS_CONFIG_PATH)
		return
	var file := FileAccess.open(TTS_CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("TTSSystem: 无法读取音色配置 %s" % TTS_CONFIG_PATH)
		return
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_warning("TTSSystem: 音色配置解析失败: %s" % json.get_error_message())
		return
	var data: Dictionary = json.data if json.data is Dictionary else {}
	# 全局默认速度
	playback_speed = float(data.get("global_speed_multiplier", data.get("playback_speed", 1.0)))
	var voices: Dictionary = data.get("voices", {})
	for voice_key in voices.keys():
		var cfg: Dictionary = voices[voice_key]
		_voice_config[voice_key] = {
			"speed": float(cfg.get("speed", playback_speed)),
		}

## 取某 voice_key 对应的独立播放速度
func _get_speed_for(voice_key: String) -> float:
	if _voice_config.has(voice_key):
		return _voice_config[voice_key].get("speed", playback_speed)
	return playback_speed

## 通过 dialog_id 播放本地预生成语音
func speak_dialog(dialog_id: String) -> void:
	if not enabled:
		return
	if not DialogData.dialogs.has(dialog_id):
		return

	var dialog: Dictionary = DialogData.dialogs[dialog_id]
	var speaker: String = str(dialog.get("speaker", "旁白"))
	var voice_key: String = _speaker_voice_map.get(speaker, "narrator")
	var local_path := "res://assets/audio/voice/%s/%s.wav" % [voice_key, dialog_id]

	# 停止当前播放
	if is_speaking:
		_stop_current_playback()

	if not ResourceLoader.exists(local_path):
		return

	speech_token += 1
	is_speaking = true
	current_speaker = speaker
	speech_started.emit(speaker, str(dialog.get("text", "")))

	var stream: AudioStream = load(local_path)
	if stream:
		audio_player.stream = stream
		# 按角色绑定独立播放速度（VoiceDesign 配置），不再全局统一音高
		audio_player.pitch_scale = _get_speed_for(voice_key)
		audio_player.play()
	else:
		push_warning("TTSSystem: 无法加载语音: " + local_path)
		_finish_speak(speech_token)

## 兼容旧接口
func speak(speaker: String, text: String) -> void:
	pass

func _on_audio_finished() -> void:
	_finish_speak(speech_token)

func _finish_speak(finished_token: int = -1) -> void:
	if finished_token != -1 and finished_token != speech_token:
		return
	if not is_speaking:
		return
	is_speaking = false
	current_speaker = ""
	speech_finished.emit(current_speaker)

## 停止当前语音（按 E/空格跳过对话时调用）
func stop() -> void:
	_stop_current_playback()
	_finish_speak(speech_token)

func _stop_current_playback() -> void:
	speech_token += 1
	if audio_player.playing:
		audio_player.stop()
