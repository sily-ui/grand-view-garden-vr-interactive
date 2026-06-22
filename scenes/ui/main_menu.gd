extends Control

# 主菜单控制器

@onready var new_game_btn: Button = $VBoxContainer/NewGameButton
@onready var continue_btn: Button = $VBoxContainer/ContinueButton
@onready var settings_btn: Button = $VBoxContainer/SettingsButton
@onready var quit_btn: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	
	# 检查是否有存档
	continue_btn.disabled = not SaveSystem.has_save(0)
	
	# 淡入动画
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)

func _on_new_game() -> void:
	_fade_to_scene("res://main.tscn")

func _on_continue() -> void:
	if SaveSystem.load_game(0):
		_fade_to_scene("res://main.tscn")

func _on_settings() -> void:
	pass # TODO: 设置界面

func _on_quit() -> void:
	get_tree().quit()

func _fade_to_scene(scene_path: String) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)
