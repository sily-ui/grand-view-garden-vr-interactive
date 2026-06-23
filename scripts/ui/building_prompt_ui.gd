extends CanvasLayer
class_name BuildingPromptUI

var _panel: PanelContainer
var _title_label: Label
var _desc_label: Label
var _action_button: Button
var _active_building: BuildingBase = null

func _ready() -> void:
	name = "BuildingPromptUI"
	layer = 8
	visible = false
	_build_ui()

func show_for_building(building: BuildingBase) -> void:
	_active_building = building
	_title_label.text = building.building_name
	_desc_label.text = building.building_description if building.building_description != "" else "靠近后可查看此处讲解。"
	_action_button.text = "查看讲解"
	_action_button.disabled = building.get_dialog_id() == ""
	visible = true

func hide_for_building(building: BuildingBase) -> void:
	if building == _active_building:
		visible = false
		_active_building = null

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "BuildingPromptPanel"
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_panel.offset_left = -380
	_panel.offset_top = -168
	_panel.offset_right = -28
	_panel.offset_bottom = -28
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.09, 0.04, 0.88)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.75, 0.56, 0.22, 0.9)
	style.content_margin_left = 18
	style.content_margin_top = 14
	style.content_margin_right = 18
	style.content_margin_bottom = 14
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)

	_title_label = Label.new()
	_title_label.name = "BuildingPromptTitle"
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.32, 1))
	vbox.add_child(_title_label)

	_desc_label = Label.new()
	_desc_label.name = "BuildingPromptDesc"
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.add_theme_font_size_override("font_size", 18)
	_desc_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.72, 1))
	vbox.add_child(_desc_label)

	_action_button = Button.new()
	_action_button.name = "BuildingPromptButton"
	_action_button.custom_minimum_size = Vector2(180, 42)
	_action_button.focus_mode = Control.FOCUS_ALL
	_action_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_action_button.pressed.connect(_on_action_pressed)
	_add_button_style()
	vbox.add_child(_action_button)

func _add_button_style() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.34, 0.2, 0.08, 0.95)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.58, 0.4, 0.14, 0.9)
	_action_button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.48, 0.3, 0.12, 0.98)
	hover.border_color = Color(0.9, 0.72, 0.28, 1)
	_action_button.add_theme_stylebox_override("hover", hover)
	_action_button.add_theme_stylebox_override("focus", hover)
	_action_button.add_theme_stylebox_override("pressed", hover)
	_action_button.add_theme_color_override("font_color", Color(0.95, 0.86, 0.55, 1))
	_action_button.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.72, 1))

func _on_action_pressed() -> void:
	if _active_building:
		_active_building.interact(null)
