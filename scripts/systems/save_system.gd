extends Node

# 存档系统
const SAVE_PATH = "user://saves/"
const SAVE_FILE = "save_%d.json"

func save_game(slot: int = 0) -> bool:
	var player := get_tree().get_first_node_in_group("player")
	var save_data := {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"player": {
			"position": var_to_str(player.global_position if player else Vector3.ZERO),
			"rotation": var_to_str(player.global_rotation if player else Vector3.ZERO)
		},
		"game_state": GameState.serialize(),
		"dialog_history": DialogManager.history,
		"completed_events": EventBus.get_completed_events()
	}
	
	DirAccess.make_dir_recursive_absolute(SAVE_PATH)
	var file_path := SAVE_PATH + SAVE_FILE % slot
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		return true
	return false

func load_game(slot: int = 0) -> bool:
	var file_path := SAVE_PATH + SAVE_FILE % slot
	if not FileAccess.file_exists(file_path):
		return false
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false
	
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		return false
	
	var data: Dictionary = json.data
	_apply_save(data)
	return true

func _apply_save(data: Dictionary) -> void:
	# 恢复游戏状态
	if data.has("game_state"):
		GameState.deserialize(data.game_state)
	
	if data.has("completed_events"):
		EventBus.load_completed_events(data.completed_events)
	
	if data.has("dialog_history"):
		DialogManager.history = data.dialog_history
	
	# 恢复玩家位置
	var player := get_tree().get_first_node_in_group("player")
	if player and data.has("player"):
		player.global_position = str_to_var(data.player.position)
		player.global_rotation = str_to_var(data.player.rotation)

func has_save(slot: int = 0) -> bool:
	return FileAccess.file_exists(SAVE_PATH + SAVE_FILE % slot)

func delete_save(slot: int = 0) -> void:
	var file_path := SAVE_PATH + SAVE_FILE % slot
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
