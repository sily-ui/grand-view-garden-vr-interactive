extends Node

# 游戏总管理器
enum GameStateType { MENU, PLAYING, DIALOG, PAUSED, CUTSCENE }
var current_state: GameStateType = GameStateType.MENU

signal game_state_changed(old_state: GameStateType, new_state: GameStateType)

func change_state(new_state: GameStateType) -> void:
	var old_state = current_state
	current_state = new_state
	game_state_changed.emit(old_state, new_state)
	
	match new_state:
		GameStateType.PLAYING:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_tree().paused = false
		GameStateType.DIALOG:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GameStateType.PAUSED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true

func start_new_game() -> void:
	GameState.current_area = "entrance"
	GameState.unlocked_areas = ["entrance"]
	GameState.collected_items = []
	GameState.dialog_history = []
	GameState.conditions = {}
	EventBus.completed_events = []
	change_state(GameStateType.PLAYING)

func pause_game() -> void:
	if current_state == GameStateType.PLAYING:
		change_state(GameStateType.PAUSED)

func resume_game() -> void:
	if current_state == GameStateType.PAUSED:
		change_state(GameStateType.PLAYING)

func is_playing() -> bool:
	return current_state == GameStateType.PLAYING

func is_dialog_active() -> bool:
	return current_state == GameStateType.DIALOG
