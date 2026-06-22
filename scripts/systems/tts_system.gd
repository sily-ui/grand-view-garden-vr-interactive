extends Node

## AI 语音配音系统
## 调用 TTS API 生成角色语音和旁白，缓存到本地后播放

signal speech_started(speaker: String, text: String)
signal speech_finished(speaker: String)

# 配置
var api_base_url: String = ""
var api_key: String = ""
var model: String = "mimo-v2.5-tts"
var cache_dir: String = "user://tts_cache/"
var voices: Dictionary = {}

# 播放器
var audio_player: AudioStreamPlayer
var http_request: HTTPRequest

# 状态
var is_speaking: bool = false
var current_speaker: String = ""
var current_text: String = ""
var speech_queue: Array[Dictionary] = []
var enabled: bool = true

# 角色名 → 语音key映射
var _speaker_voice_map: Dictionary = {
	"旁白": "narrator",
	"刘姥姥": "liulaolao",
	"贾母": "jiamu",
	"王熙凤": "xifeng",
	"林黛玉": "daiyu",
	"贾宝玉": "baoyu",
	"妙玉": "miaoyu",
	"周瑞家": "zhou",
}

func _ready() -> void:
	# 创建播放器
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "TTSPlayer"
	audio_player.bus = "Master"
	audio_player.finished.connect(_on_audio_finished)
	add_child(audio_player)
	
	# 创建 HTTP 请求节点
	http_request = HTTPRequest.new()
	http_request.name = "TTSRequest"
	http_request.timeout = 15.0
	http_request.request_completed.connect(_on_request_completed)
	add_child(http_request)
	
	# 加载配置
	_load_config()
	
	# 创建缓存目录
	DirAccess.make_dir_recursive_absolute(cache_dir)

func _load_config() -> void:
	var config_path := "res://assets/config/tts_config.json"
	if not FileAccess.file_exists(config_path):
		push_warning("TTSSystem: 配置文件不存在: " + config_path)
		enabled = false
		return
	
	var file := FileAccess.open(config_path, FileAccess.READ)
	if not file:
		push_warning("TTSSystem: 无法读取配置文件")
		enabled = false
		return
	
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_warning("TTSSystem: 配置文件 JSON 解析失败")
		enabled = false
		return
	
	var data: Dictionary = json.data
	api_base_url = data.get("api_base_url", "")
	api_key = data.get("api_key", "")
	model = data.get("model", "mimo-v2.5-tts")
	cache_dir = data.get("cache_dir", "user://tts_cache/")
	voices = data.get("voices", {})
	
	if api_key == "" or api_key == "YOUR_API_KEY_HERE":
		push_warning("TTSSystem: 请在 tts_config.json 中配置 api_key")
		enabled = false
		return
	
	if api_base_url == "":
		push_warning("TTSSystem: 请在 tts_config.json 中配置 api_base_url")
		enabled = false
		return

## 为对话文本生成并播放语音
func speak(speaker: String, text: String) -> void:
	if not enabled:
		return
	
	# 清理文本（去掉括号动作描述）
	var clean_text := _clean_text(text)
	if clean_text.is_empty():
		return
	
	# 如果正在播放，加入队列
	if is_speaking:
		speech_queue.append({"speaker": speaker, "text": clean_text})
		return
	
	_start_speak(speaker, clean_text)

func _start_speak(speaker: String, text: String) -> void:
	is_speaking = true
	current_speaker = speaker
	current_text = text
	speech_started.emit(speaker, text)
	
	# 检查缓存
	var cache_path := _get_cache_path(speaker, text)
	if FileAccess.file_exists(cache_path):
		_play_cached(cache_path)
		return
	
	# 调用 API 生成语音
	_request_tts(speaker, text)

func _clean_text(text: String) -> String:
	# 去掉括号内的动作/表情描述，如（噗嗤一笑）
	var regex := RegEx.new()
	regex.compile("[\\(（][^\\)）]*[\\)）]")
	var cleaned := regex.sub(text, "", true)
	# 去掉省略号、换行
	cleaned = cleaned.replace("……", "。").replace("…", "。").replace("\n", " ")
	return cleaned.strip_edges()

func _get_cache_path(speaker: String, text: String) -> String:
	var hash_str := speaker + "|" + text
	var hash_val := hash_str.hash()
	return "%s%s_%d.wav" % [cache_dir, speaker, hash_val]

func _request_tts(speaker: String, text: String) -> void:
	var voice_key: String = _speaker_voice_map.get(speaker, "narrator")
	var voice_config: Dictionary = voices.get(voice_key, voices.get("narrator", {}))
	var speed: float = voice_config.get("speed", 1.0)
	var voice_model: String = voice_config.get("model", model)
	
	# MiMo TTS 使用 chat/completions 格式
	# assistant 消息的内容就是要朗读的文本
	var messages := [
		{"role": "user", "content": "请用语音朗读以下内容"},
		{"role": "assistant", "content": text}
	]
	
	var request_data := {
		"model": voice_model,
		"messages": messages,
		"speed": speed,
	}
	
	# voicedesign 模型额外携带 voice_description
	if voice_config.has("voice_description"):
		request_data["voice_description"] = voice_config["voice_description"]
	
	var body := JSON.stringify(request_data)
	
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key,
	])
	
	var error := http_request.request(api_base_url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_warning("TTSSystem: HTTP 请求发起失败: %d" % error)
		_finish_speak()

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_warning("TTSSystem: TTS 请求失败 result=%d code=%d" % [result, response_code])
		if body.size() > 0:
			push_warning("TTSSystem: 响应: %s" % body.get_string_from_utf8().substr(0, 200))
		_finish_speak()
		return
	
	# MiMo 返回 JSON: {"choices":[{"message":{"audio":{"data":"base64..."}}}]}
	var json := JSON.new()
	var error := json.parse(body.get_string_from_utf8())
	if error != OK:
		push_warning("TTSSystem: JSON 解析失败")
		_finish_speak()
		return
	
	var data: Dictionary = json.data
	var choices: Array = data.get("choices", [])
	if choices.is_empty():
		push_warning("TTSSystem: 响应中无 choices")
		_finish_speak()
		return
	
	var message: Dictionary = choices[0].get("message", {})
	var audio_data: Dictionary = message.get("audio", {})
	var base64_audio: String = audio_data.get("data", "")
	
	if base64_audio.is_empty():
		push_warning("TTSSystem: 响应中无音频数据")
		_finish_speak()
		return
	
	# 解码 base64 → WAV 字节
	var wav_bytes := Marshalls.base64_to_raw(base64_audio)
	
	# 缓存到本地
	var cache_path := _get_cache_path(current_speaker, _get_current_text())
	var file := FileAccess.open(cache_path, FileAccess.WRITE)
	if file:
		file.store_buffer(wav_bytes)
		file.close()
	
	# 播放 WAV
	_play_wav_buffer(wav_bytes)

func _play_cached(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("TTSSystem: 无法读取缓存: " + path)
		_finish_speak()
		return
	var data := file.get_buffer(file.get_length())
	file.close()
	_play_wav_buffer(data)

func _play_wav_buffer(data: PackedByteArray) -> void:
	# 使用 AudioStreamWAV 播放原始 WAV 数据
	var stream := AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 24000
	stream.stereo = false
	
	if stream.data.size() > 0:
		audio_player.stream = stream
		audio_player.play()
	else:
		push_warning("TTSSystem: WAV 数据为空")
		_finish_speak()

func _on_audio_finished() -> void:
	_finish_speak()

func _finish_speak() -> void:
	is_speaking = false
	var prev_speaker := current_speaker
	current_speaker = ""
	current_text = ""
	speech_finished.emit(prev_speaker)
	
	# 播放队列中的下一条
	if speech_queue.size() > 0:
		var next: Dictionary = speech_queue.pop_front()
		_start_speak(next.speaker, next.text)

func _get_current_text() -> String:
	return current_text

## 停止当前语音
func stop() -> void:
	if audio_player.playing:
		audio_player.stop()
	speech_queue.clear()
	_finish_speak()

## 清空语音缓存
func clear_cache() -> void:
	var dir := DirAccess.open(cache_dir)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				DirAccess.remove_absolute(cache_dir + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
