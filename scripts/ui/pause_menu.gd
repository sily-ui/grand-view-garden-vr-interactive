extends CanvasLayer

# 暂停菜单
@onready var panel: PanelContainer = $Panel
@onready var resume_btn: Button = $Panel/VBoxContainer/ResumeButton
@onready var save_btn: Button = $Panel/VBoxContainer/SaveButton
@onready var load_btn: Button = $Panel/VBoxContainer/LoadButton
@onready var menu_btn: Button = $Panel/VBoxContainer/MenuButton
@onready var quit_btn: Button = $Panel/VBoxContainer/QuitButton
@onready var menu_items: VBoxContainer = $Panel/VBoxContainer

var tts_speed_label: Label = null
var tts_speed_buttons: Array[Button] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	resume_btn.pressed.connect(_on_resume)
	save_btn.pressed.connect(_on_save)
	load_btn.pressed.connect(_on_load)
	menu_btn.pressed.connect(_on_return_menu)
	quit_btn.pressed.connect(_on_quit)
	_init_tts_speed_controls()
	_apply_tts_playback_speed(TTSSystem.playback_speed if TTSSystem else 1.0)

func _init_tts_speed_controls() -> void:
	var separator := HSeparator.new()
	separator.name = "TTSSpeedSeparator"
	menu_items.add_child(separator)
	menu_items.move_child(separator, menu_btn.get_index())

	tts_speed_label = Label.new()
	tts_speed_label.name = "TTSSpeedLabel"
	tts_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tts_speed_label.add_theme_font_size_override("font_size", 20)
	tts_speed_label.add_theme_color_override("font_color", Color(0.88, 0.82, 0.65, 1))
	menu_items.add_child(tts_speed_label)
	menu_items.move_child(tts_speed_label, menu_btn.get_index())

	var speed_row := HBoxContainer.new()
	speed_row.name = "TTSSpeedRow"
	speed_row.alignment = BoxContainer.ALIGNMENT_CENTER
	speed_row.add_theme_constant_override("separation", 8)
	menu_items.add_child(speed_row)
	menu_items.move_child(speed_row, menu_btn.get_index())

	for speed in [1.0, 1.25, 1.5]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(88, 40)
		button.text = "%.2fx" % speed
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_color_override("font_color", Color(0.88, 0.82, 0.65, 1))
		button.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.75, 1))
		button.pressed.connect(func() -> void: _apply_tts_playback_speed(speed))
		speed_row.add_child(button)
		tts_speed_buttons.append(button)

func _apply_tts_playback_speed(speed: float) -> void:
	var clamped_speed := clampf(speed, 0.5, 2.0)
	if TTSSystem and TTSSystem.has_method("set_playback_speed"):
		TTSSystem.set_playback_speed(clamped_speed)
	if tts_speed_label:
		tts_speed_label.text = "配音速度 %.2fx" % clamped_speed
	for button in tts_speed_buttons:
		button.disabled = abs(float(button.text.trim_suffix("x")) - clamped_speed) < 0.01

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
