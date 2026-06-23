extends Node3D
class_name BuildingBase

# 建筑基类
@export var building_name: String = ""
@export var building_description: String = ""
@export var associated_character: String = ""
@export var unlock_condition: String = ""
@export var associated_dialog: String = ""

@onready var entrance_area: Area3D = $EntranceArea if has_node("EntranceArea") else null
@onready var name_plate: Label3D = $NamePlate if has_node("NamePlate") else null

func _ready() -> void:
	if name_plate:
		name_plate.text = building_name
		name_plate.position = Vector3(0, 5.4, 2.1)
		name_plate.font_size = 34
		name_plate.pixel_size = 0.011
		name_plate.modulate = Color(0.88, 0.72, 0.24, 1)
		name_plate.outline_size = 7
		name_plate.outline_modulate = Color(0.05, 0.03, 0.01, 1)
		name_plate.double_sided = true
		name_plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if entrance_area:
		entrance_area.body_entered.connect(_on_body_entered)
		entrance_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		EventBus.building_entered.emit(building_name)
		_show_info()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		EventBus.building_exited.emit(building_name)
		_hide_info()

func _show_info() -> void:
	if building_description != "" or _get_dialog_id() != "":
		var prompt_ui := _get_prompt_ui()
		if prompt_ui and prompt_ui.has_method("show_for_building"):
			prompt_ui.show_for_building(self)

func _hide_info() -> void:
	var prompt_ui := _get_prompt_ui()
	if prompt_ui and prompt_ui.has_method("hide_for_building"):
		prompt_ui.hide_for_building(self)

func _get_prompt_ui() -> CanvasLayer:
	var current_scene := get_tree().current_scene
	if not current_scene:
		return null
	var prompt_ui := current_scene.get_node_or_null("BuildingPromptUI") as BuildingPromptUI
	if prompt_ui:
		return prompt_ui
	prompt_ui = BuildingPromptUI.new()
	current_scene.add_child(prompt_ui)
	return prompt_ui

func is_unlocked() -> bool:
	if unlock_condition == "":
		return true
	return GameState.is_area_unlocked(unlock_condition)

func get_interaction_info() -> Dictionary:
	return {"name": building_name, "action": "进入%s" % building_name, "key": "E"}

func interact(player: Node) -> void:
	var dialog_id := _get_dialog_id()
	if dialog_id != "" and DialogManager:
		DialogManager.start_dialog(dialog_id)

func get_dialog_id() -> String:
	return _get_dialog_id()

func _get_dialog_id() -> String:
	if associated_dialog != "":
		return associated_dialog
	match building_name:
		"潇湘馆":
			return "visit_xiaoxiang"
		"怡红院":
			return "visit_yihong"
		"栊翠庵":
			return "tea_ceremony"
		"大观楼":
			return "banquet"
		_:
			return ""
