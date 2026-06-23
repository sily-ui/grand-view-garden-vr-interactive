extends Control

# 主菜单控制器

@onready var new_game_btn: Button = $MenuContainer/ButtonContainer/NewGameButton
@onready var continue_btn: Button = $MenuContainer/ButtonContainer/ContinueButton
@onready var settings_btn: Button = $MenuContainer/ButtonContainer/SettingsButton
@onready var quit_btn: Button = $MenuContainer/ButtonContainer/QuitButton
@onready var title_label: Label = $MenuContainer/TitleLabel
@onready var subtitle_label: Label = $MenuContainer/SubtitleLabel
@onready var menu_container: VBoxContainer = $MenuContainer

var settings_panel: PanelContainer = null

func _ready() -> void:
	get_tree().auto_accept_quit = false
	print("[MainMenu] ready; auto_accept_quit=false")
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
	if settings_panel:
		settings_panel.visible = not settings_panel.visible
		menu_container.visible = not settings_panel.visible
		return
	_create_settings_panel()

func _on_quit() -> void:
	print("[MainMenu] quit button pressed")
	get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("[MainMenu] window close request intercepted")
	elif what == NOTIFICATION_EXIT_TREE:
		print("[MainMenu] exiting scene tree")

func _fade_to_scene(scene_path: String) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)

# ============================================================
# 设置面板
# ============================================================
func _create_settings_panel() -> void:
	# 隐藏主菜单
	menu_container.visible = false
	
	settings_panel = PanelContainer.new()
	settings_panel.name = "SettingsPanel"
	settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	settings_panel.custom_minimum_size = Vector2(440, 360)
	settings_panel.offset_left = -220
	settings_panel.offset_right = 220
	settings_panel.offset_top = -180
	settings_panel.offset_bottom = 180
	settings_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	settings_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var panel_bg := StyleBoxFlat.new()
	panel_bg.bg_color = Color(0.1, 0.08, 0.05, 0.92)
	panel_bg.border_width_left = 2
	panel_bg.border_width_top = 2
	panel_bg.border_width_right = 2
	panel_bg.border_width_bottom = 2
	panel_bg.border_color = Color(0.55, 0.45, 0.22, 0.6)
	panel_bg.corner_radius_top_left = 4
	panel_bg.corner_radius_top_right = 4
	panel_bg.corner_radius_bottom_right = 4
	panel_bg.corner_radius_bottom_left = 4
	panel_bg.content_margin_left = 30
	panel_bg.content_margin_top = 20
	panel_bg.content_margin_right = 30
	panel_bg.content_margin_bottom = 20
	settings_panel.add_theme_stylebox_override("panel", panel_bg)
	add_child(settings_panel)
	
	var vbox := VBoxContainer.new()
	vbox.name = "SettingsVBox"
	vbox.add_theme_constant_override("separation", 20)
	settings_panel.add_child(vbox)
	
	# 标题
	var title := Label.new()
	title.text = "设 置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.79, 0.66, 0.3, 1))
	vbox.add_child(title)
	
	# BGM音量
	vbox.add_child(_create_volume_slider("主音量", "Master", 1.0))
	# 鼠标灵敏度
	vbox.add_child(_create_sensitivity_slider())
	
	# 返回按钮
	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(200, 44)
	back_btn.add_theme_font_size_override("font_size", 22)
	back_btn.add_theme_color_override("font_color", Color(0.88, 0.82, 0.65, 1))
	back_btn.pressed.connect(_on_settings_back)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.12, 0.1, 0.06, 0.6)
	btn_style.border_width_left = 1
	btn_style.border_width_top = 1
	btn_style.border_width_right = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = Color(0.55, 0.45, 0.22, 0.4)
	btn_style.corner_radius_top_left = 2
	btn_style.corner_radius_top_right = 2
	btn_style.corner_radius_bottom_right = 2
	btn_style.corner_radius_bottom_left = 2
	btn_style.content_margin_left = 16
	btn_style.content_margin_top = 6
	btn_style.content_margin_right = 16
	btn_style.content_margin_bottom = 6
	back_btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover: StyleBoxFlat = btn_style.duplicate()
	btn_hover.bg_color = Color(0.2, 0.15, 0.08, 0.85)
	btn_hover.border_color = Color(0.79, 0.66, 0.3, 0.9)
	back_btn.add_theme_stylebox_override("hover", btn_hover)
	back_btn.add_theme_stylebox_override("pressed", btn_hover)
	var btn_center := CenterContainer.new()
	btn_center.add_child(back_btn)
	vbox.add_child(btn_center)

func _create_volume_slider(label_text: String, bus_name: String, default_val: float) -> VBoxContainer:
	var container := VBoxContainer.new()
	
	var label := Label.new()
	label.text = "%s: %d%%" % [label_text, int(default_val * 100)]
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.7, 0.63, 0.5, 0.9))
	container.add_child(label)
	
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = default_val
	slider.custom_minimum_size = Vector2(300, 20)
	
	# 获取当前总线音量
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	
	slider.value_changed.connect(func(val: float) -> void:
		var idx := AudioServer.get_bus_index(bus_name)
		if idx >= 0:
			AudioServer.set_bus_volume_db(idx, linear_to_db(val))
		label.text = "%s: %d%%" % [label_text, int(val * 100)]
	)
	container.add_child(slider)
	
	return container

func _create_sensitivity_slider() -> VBoxContainer:
	var container := VBoxContainer.new()
	
	var player: Node = get_tree().get_first_node_in_group("player")
	var current_sens := 0.002
	if player:
		current_sens = player.mouse_sensitivity
	
	var label := Label.new()
	label.text = "鼠标灵敏度: %.0f%%" % [current_sens * 1000.0 / 2.0 * 100.0]
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.7, 0.63, 0.5, 0.9))
	container.add_child(label)
	
	var slider := HSlider.new()
	slider.min_value = 0.0005
	slider.max_value = 0.005
	slider.step = 0.0001
	slider.value = current_sens
	slider.custom_minimum_size = Vector2(300, 20)
	slider.value_changed.connect(func(val: float) -> void:
		var p: Node = get_tree().get_first_node_in_group("player")
		if p:
			p.mouse_sensitivity = val
		label.text = "鼠标灵敏度: %.0f%%" % [val * 1000.0 / 2.0 * 100.0]
	)
	container.add_child(slider)
	
	return container

func _on_settings_back() -> void:
	if settings_panel:
		settings_panel.queue_free()
		settings_panel = null
	menu_container.visible = true
