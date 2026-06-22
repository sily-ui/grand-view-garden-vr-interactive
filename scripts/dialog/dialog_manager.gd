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
	var tree := get_tree()
	if tree:
		var ui = tree.get_first_node_in_group("dialog_ui")
		if ui:
			dialog_ui = ui

func start_dialog(dialog_id: String) -> void:
	if not DialogData.dialogs.has(dialog_id):
		push_warning("Dialog not found: " + dialog_id)
		return
	
	current_dialog_id = dialog_id
	current_dialog = DialogData.dialogs[dialog_id]
	is_active = true
	history.append(dialog_id)
	
	GameManager.change_state(GameManager.GameStateType.DIALOG)
	
	# 显示对话UI
	if dialog_ui:
		dialog_ui.show_dialog(
			current_dialog.get("speaker", ""),
			current_dialog.get("text", ""),
			current_dialog.get("choices", [])
		)
	
	dialog_started.emit(dialog_id)
	
	# 如果没有选项且有next，等待玩家点击后自动跳转
	if not current_dialog.has("choices") and not current_dialog.has("next") and not current_dialog.has("events"):
		end_dialog()

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
	
	if dialog_ui:
		dialog_ui.hide_dialog()
	
	GameManager.change_state(GameManager.GameStateType.PLAYING)
	dialog_ended.emit(ended_id)

func _execute_event(event_id: String) -> void:
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
