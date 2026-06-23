extends Control

# 对话UI控制器 - 清代中式古风
@onready var speaker_label: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/SpeakerLabel
@onready var text_label: RichTextLabel = $Panel/MarginContainer/HBoxContainer/VBoxContainer/TextLabel
@onready var choices_container: VBoxContainer = $Panel/MarginContainer/HBoxContainer/VBoxContainer/ChoicesContainer
@onready var continue_hint: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/ContinueHint
@onready var panel: PanelContainer = $Panel
@onready var avatar_rect: TextureRect = $Panel/MarginContainer/HBoxContainer/AvatarPanel/AvatarRect
@onready var avatar_panel: PanelContainer = $Panel/MarginContainer/HBoxContainer/AvatarPanel

var is_showing: bool = false
var typewriter_tween: Tween = null
var full_text: String = ""
var text_fully_visible: bool = false
var scroll_tween: Tween = null

# 色彩常量
const COLOR_RICE_PAPER := Color(0.95, 0.91, 0.8, 0.97)
const COLOR_ROSEWOOD := Color(0.35, 0.2, 0.1, 0.95)
const COLOR_INK := Color(0.2, 0.15, 0.08, 1)
const COLOR_GOLD := Color(0.55, 0.3, 0.08, 1)
const COLOR_WOOD_DARK := Color(0.22, 0.14, 0.06, 0.95)
const COLOR_WOOD_MID := Color(0.35, 0.22, 0.1, 0.95)
const COLOR_WOOD_LIGHT := Color(0.45, 0.3, 0.15, 0.95)
const COLOR_GOLD_TEXT := Color(0.82, 0.7, 0.35, 1)
const COLOR_GOLD_BRIGHT := Color(1.0, 0.9, 0.5, 1)
const TYPEWRITER_SECONDS_PER_CHAR := 0.035

# 角色头像映射
var avatar_map: Dictionary = {
	"贾母": "res://assets/textures/ui/avatar_jiamu.png",
	"刘姥姥": "res://assets/textures/ui/avatar_liulaolao.png",
	"贾宝玉": "res://assets/textures/ui/avatar_jiabaoyu.png",
	"林黛玉": "res://assets/textures/ui/avatar_lindaiyu.png",
	"王熙凤": "res://assets/textures/ui/avatar_wangxifeng.png",
	"袭人": "res://assets/textures/ui/avatar_xiren.png",
	"晴雯": "res://assets/textures/ui/avatar_qingwen.png",
	"薛宝钗": "res://assets/textures/ui/avatar_xuebaochai.png",
	"周瑞家": "res://assets/textures/ui/avatar_liulaolao.png",
}

func _ready() -> void:
	visible = false
	add_to_group("dialog_ui")
	DialogManager.dialog_started.connect(_on_dialog_started)
	# 确保鼠标事件能穿透到选项按钮
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	avatar_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in _get_all_children(self):
		if child is Container and child != panel:
			child.mouse_filter = Control.MOUSE_FILTER_PASS
	# 头像古典边框
	var avatar_frame := StyleBoxFlat.new()
	avatar_frame.bg_color = Color(0.35, 0.2, 0.1, 0.3)
	avatar_frame.border_width_left = 3
	avatar_frame.border_width_top = 3
	avatar_frame.border_width_right = 3
	avatar_frame.border_width_bottom = 3
	avatar_frame.border_color = Color(0.45, 0.28, 0.12, 0.9)
	avatar_frame.corner_radius_top_left = 0
	avatar_frame.corner_radius_top_right = 0
	avatar_frame.corner_radius_bottom_right = 0
	avatar_frame.corner_radius_bottom_left = 0
	avatar_panel.add_theme_stylebox_override("panel", avatar_frame)

func _input(event: InputEvent) -> void:
	if not is_showing:
		return
	
	# 鼠标：让按钮自己处理
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		return
	
	if event.is_action_pressed("interact") or event.is_action_pressed("dialog_next"):
		if not text_fully_visible:
			# 打字机还没结束 → 跳过，直接显示全文
			_show_full_text()
			return
		# 全文已显示
		if choices_container.get_child_count() > 0:
			# 有选项时，E/空格自动选择第一个选项
			var first_btn: Button = choices_container.get_child(0)
			if first_btn:
				first_btn.pressed.emit()
			return
		# 无选项，推进对话
		DialogManager.advance_dialog()

func show_dialog(speaker: String, text: String, choices: Array = []) -> void:
	is_showing = true
	text_fully_visible = false
	visible = true
	
	speaker_label.text = speaker
	full_text = text
	text_label.text = ""
	
	# 设置头像
	if speaker == "旁白" or speaker == "周瑞家":
		avatar_panel.visible = false
	elif avatar_map.has(speaker):
		avatar_rect.texture = load(avatar_map[speaker])
		avatar_panel.visible = true
	else:
		avatar_rect.texture = null
		avatar_panel.visible = false
	
	# 设置说话人颜色
	if speaker == "刘姥姥":
		speaker_label.add_theme_color_override("font_color", COLOR_GOLD)
	elif speaker == "旁白":
		speaker_label.add_theme_color_override("font_color", Color(0.4, 0.25, 0.08, 1))
	else:
		speaker_label.add_theme_color_override("font_color", COLOR_GOLD)
	
	# 清除旧选项
	for child in choices_container.get_children():
		child.queue_free()
	
	# 卷轴展开动画
	_play_scroll_open_animation()
	
	# 打字机效果
	_start_typewriter()
	
	# 显示选项（如果有）
	if choices.size() > 0:
		continue_hint.text = "请选择："
	else:
		continue_hint.text = "按 [E] 或 空格 继续..."

func _play_scroll_open_animation() -> void:
	if scroll_tween:
		scroll_tween.kill()
	
	panel.modulate.a = 0.0
	
	scroll_tween = create_tween()
	scroll_tween.tween_property(panel, "modulate:a", 1.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# 淡入内部内容
	speaker_label.modulate.a = 0.0
	text_label.modulate.a = 0.0
	continue_hint.modulate.a = 0.0
	scroll_tween.chain().tween_property(speaker_label, "modulate:a", 1.0, 0.15)
	scroll_tween.chain().tween_property(text_label, "modulate:a", 1.0, 0.15)
	scroll_tween.chain().tween_property(continue_hint, "modulate:a", 1.0, 0.15)

func _start_typewriter() -> void:
	if typewriter_tween:
		typewriter_tween.kill()
	
	text_label.visible_characters = 0
	text_label.text = full_text
	var total_chars: int = full_text.length()
	
	typewriter_tween = create_tween()
	typewriter_tween.tween_property(text_label, "visible_characters", total_chars, total_chars * TYPEWRITER_SECONDS_PER_CHAR)
	typewriter_tween.finished.connect(_on_typewriter_finished)

func _show_full_text() -> void:
	if typewriter_tween:
		typewriter_tween.kill()
	text_label.visible_characters = -1
	_on_typewriter_finished()

func _on_typewriter_finished() -> void:
	text_fully_visible = true
	_show_choices()

func _show_choices() -> void:
	if not DialogManager.current_dialog.has("choices"):
		return
	
	var choices: Array = DialogManager.current_dialog.choices
	continue_hint.visible = false
	
	for i in range(choices.size()):
		var btn := Button.new()
		btn.text = choices[i].text
		btn.add_theme_font_size_override("font_size", 24)
		btn.custom_minimum_size.y = 52
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# 木质牌匾样式 - 正常态
		var style_normal := StyleBoxFlat.new()
		style_normal.bg_color = COLOR_WOOD_MID
		style_normal.border_width_left = 3
		style_normal.border_width_top = 3
		style_normal.border_width_right = 3
		style_normal.border_width_bottom = 3
		style_normal.border_color = Color(0.2, 0.12, 0.05, 0.9)
		style_normal.corner_radius_top_left = 0
		style_normal.corner_radius_top_right = 0
		style_normal.corner_radius_bottom_right = 0
		style_normal.corner_radius_bottom_left = 0
		style_normal.content_margin_left = 24
		style_normal.content_margin_right = 24
		style_normal.content_margin_top = 8
		style_normal.content_margin_bottom = 8
		btn.add_theme_stylebox_override("normal", style_normal)
		
		# 木质牌匾样式 - 悬停态（提亮）
		var style_hover := StyleBoxFlat.new()
		style_hover.bg_color = COLOR_WOOD_LIGHT
		style_hover.border_width_left = 3
		style_hover.border_width_top = 3
		style_hover.border_width_right = 3
		style_hover.border_width_bottom = 3
		style_hover.border_color = Color(0.55, 0.35, 0.1, 0.95)
		style_hover.corner_radius_top_left = 0
		style_hover.corner_radius_top_right = 0
		style_hover.corner_radius_bottom_right = 0
		style_hover.corner_radius_bottom_left = 0
		style_hover.content_margin_left = 24
		style_hover.content_margin_right = 24
		style_hover.content_margin_top = 8
		style_hover.content_margin_bottom = 8
		btn.add_theme_stylebox_override("hover", style_hover)
		btn.add_theme_stylebox_override("pressed", style_hover)
		
		# 金色文字
		btn.add_theme_color_override("font_color", COLOR_GOLD_TEXT)
		btn.add_theme_color_override("font_hover_color", COLOR_GOLD_BRIGHT)
		btn.add_theme_color_override("font_pressed_color", COLOR_GOLD_BRIGHT)
		
		var idx := i
		btn.pressed.connect(func() -> void: _on_choice_selected(idx))
		choices_container.add_child(btn)

func _on_choice_selected(index: int) -> void:
	DialogManager.select_choice(index)

func hide_dialog() -> void:
	is_showing = false
	if typewriter_tween:
		typewriter_tween.kill()
	if scroll_tween:
		scroll_tween.kill()
	
	# 卷轴收起动画
	var close_tween := create_tween()
	close_tween.tween_property(panel, "modulate:a", 0.0, 0.25).set_ease(Tween.EASE_IN)
	close_tween.finished.connect(func() -> void: visible = false)

func _on_dialog_started(_id: String) -> void:
	pass

func _get_all_children(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_get_all_children(child))
	return result
