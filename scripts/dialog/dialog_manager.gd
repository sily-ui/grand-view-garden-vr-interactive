extends Node

# 对话管理器
signal dialog_started(dialog_id: String)
signal dialog_ended(dialog_id: String)
signal choice_selected(dialog_id: String, choice_index: int)

var current_dialog_id: String = ""
var current_dialog: Dictionary = {}
var is_active: bool = false
var history: Array[String] = []

@onready var dialog_ui: Control = null

func _ready() -> void:
	# 延迟获取UI节点，等待场景初始化
	call_deferred("_setup_ui")

func _setup_ui() -> void:
	_find_dialog_ui()

func _find_dialog_ui() -> void:
	var tree := get_tree()
	if tree:
		var ui = tree.get_first_node_in_group("dialog_ui")
		if ui:
			dialog_ui = ui
			return
		var current_scene := tree.current_scene
		if current_scene:
			ui = current_scene.get_node_or_null("Systems/DialogUI")
			if ui:
				dialog_ui = ui

func start_dialog(dialog_id: String) -> void:
	if not DialogData.dialogs.has(dialog_id):
		push_warning("Dialog not found: " + dialog_id)
		return

	_find_dialog_ui()
	if not dialog_ui:
		push_warning("Dialog UI not found, skipping dialog: " + dialog_id)
		GameManager.change_state(GameManager.GameStateType.PLAYING)
		return
	
	current_dialog_id = dialog_id
	current_dialog = DialogData.dialogs[dialog_id]
	is_active = true
	history.append(dialog_id)
	
	GameManager.change_state(GameManager.GameStateType.DIALOG)
	
	# 显示对话UI
	dialog_ui.show_dialog(
		current_dialog.get("speaker", ""),
		current_dialog.get("text", ""),
		current_dialog.get("choices", [])
	)
	
	# AI 语音配音
	if TTSSystem:
		TTSSystem.speak(
			current_dialog.get("speaker", ""),
			current_dialog.get("text", "")
		)
	
	dialog_started.emit(dialog_id)
	
	# 没有选项、没有next、也没有events → 直接结束
	if not current_dialog.has("choices") and not current_dialog.has("next") and not current_dialog.has("events"):
		end_dialog()
	# 有events但没有next和choices → 执行事件后自动结束
	elif current_dialog.has("events") and not current_dialog.has("next") and not current_dialog.has("choices"):
		advance_dialog()

func advance_dialog() -> void:
	if not is_active:
		return
	
	# 执行事件
	if current_dialog.has("events"):
		for event_id in current_dialog.events:
			_execute_event(event_id)
	
	# 跳转下一个对话
	if current_dialog.has("next"):
		start_dialog(current_dialog.next)
	else:
		end_dialog()

func select_choice(choice_index: int) -> void:
	if not is_active or not current_dialog.has("choices"):
		return
	
	if choice_index < 0 or choice_index >= current_dialog.choices.size():
		return
	
	var choice: Dictionary = current_dialog.choices[choice_index]
	choice_selected.emit(current_dialog_id, choice_index)
	
	# 执行事件
	if current_dialog.has("events"):
		for event_id in current_dialog.events:
			_execute_event(event_id)
	
	# 跳转
	if choice.has("next"):
		start_dialog(choice.next)
	else:
		end_dialog()

func end_dialog() -> void:
	var ended_id := current_dialog_id
	is_active = false
	current_dialog = {}
	current_dialog_id = ""
	
	# 停止语音
	if TTSSystem:
		TTSSystem.stop()
	
	_find_dialog_ui()
	if dialog_ui:
		dialog_ui.hide_dialog()
	
	GameManager.change_state(GameManager.GameStateType.PLAYING)
	dialog_ended.emit(ended_id)

func _execute_event(event_id: String) -> void:
	EventBus.trigger_event(event_id)
	
	match event_id:
		# === 入场流程 ===
		"intro_complete":
			GameState.set_condition("intro_done", true)
		# === 路径氛围 ===
		"path_complete":
			GameState.set_condition("path_done", true)
		# === 拜见贾母 ===
		"meet_jiamu_complete":
			GameState.set_condition("met_jiamu", true)
		"unlock_xiaoxiang":
			GameState.unlock_area("xiaoxiang_guan")
		"unlock_yihong":
			GameState.unlock_area("yihong_yuan")
		"unlock_longcui":
			GameState.unlock_area("longcui_an")
		# === 见王熙凤 ===
		"meet_xifeng_complete":
			GameState.set_condition("met_xifeng", true)
		# === 参观院落 ===
		"visit_xiaoxiang_complete":
			GameState.set_condition("visited_xiaoxiang", true)
		"visit_yihong_complete":
			GameState.set_condition("visited_yihong", true)
		"tea_ceremony_complete":
			GameState.set_condition("completed_tea", true)
		"collect_teacup":
			GameState.collect_item("miaoyu_teacup")
		# === 宴席 ===
		"banquet_complete":
			GameState.set_condition("attended_banquet", true)
		# === 结局 ===
		"game_complete":
			GameState.set_condition("game_completed", true)
		_:
			push_warning("DialogManager: 未知事件 '%s'" % event_id)
	match event_id:
		"intro_complete":
			GameState.set_condition("intro_done", true)
		"path_complete":
			GameState.set_condition("path_done", true)
		"meet_jiamu_complete":
			GameState.set_condition("met_jiamu", true)
		"unlock_xiaoxiang":
			GameState.unlock_area("xiaoxiang_guan")
		"unlock_yihong":
			GameState.unlock_area("yihong_yuan")
		"unlock_longcui":
			GameState.unlock_area("longcui_an")
		"visit_xiaoxiang_complete":
			GameState.set_condition("visited_xiaoxiang", true)
		"visit_yihong_complete":
			GameState.set_condition("visited_yihong", true)
		"tea_ceremony_complete":
			GameState.set_condition("had_tea", true)
		"collect_teacup":
			GameState.collect_item("teacup")
		"banquet_complete":
			GameState.set_condition("attended_banquet", true)
			GameState.unlock_area("farewell")
		"game_complete":
			GameState.set_condition("game_completed", true)
	
	EventBus.trigger_event(event_id)
