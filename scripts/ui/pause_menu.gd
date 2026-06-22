extends CanvasLayer

# 暂停菜单
@onready var panel: PanelContainer = $Panel
@onready var resume_btn: Button = $Panel/VBoxContainer/ResumeButton
@onready var save_btn: Button = $Panel/VBoxContainer/SaveButton
@onready var load_btn: Button = $Panel/VBoxContainer/LoadButton
@onready var menu_btn: Button = $Panel/VBoxContainer/MenuButton
@onready var quit_btn: Button = $Panel/VBoxContainer/QuitButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	resume_btn.pressed.connect(_on_resume)
	save_btn.pressed.connect(_on_save)
	load_btn.pressed.connect(_on_load)
	menu_btn.pressed.connect(_on_return_menu)
	quit_btn.pressed.connect(_on_quit)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if DialogManager.is_active:
			return
		if visible:
			_on_resume()
		else:
			_show_pause()

func _show_pause() -> void:
	visible = true
	GameManager.pause_game()

func _on_resume() -> void:
	visible = false
	GameManager.resume_game()

func _on_save() -> void:
	var save_sys := get_node_or_null("../Systems/SaveSystem")
	if save_sys:
		save_sys.save_game(0)
	# 显示保存提示
	var tween := create_tween()
	tween.tween_property($SaveHint, "modulate:a", 1.0, 0.1)
	tween.tween_interval(1.0)
	tween.tween_property($SaveHint, "modulate:a", 0.0, 0.5)

func _on_load() -> void:
	var save_sys := get_node_or_null("../Systems/SaveSystem")
	if save_sys and save_sys.has_save(0):
		save_sys.load_game(0)
		_on_resume()

func _on_return_menu() -> void:
	get_tree().paused = false
	GameManager.change_state(GameManager.GameStateType.MENU)
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_quit() -> void:
	get_tree().quit()
