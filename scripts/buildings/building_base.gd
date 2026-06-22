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

func _show_info() -> void:
	if building_description != "":
		# 可以在这里显示建筑介绍UI
		pass

func is_unlocked() -> bool:
	if unlock_condition == "":
		return true
	return GameState.is_area_unlocked(unlock_condition)

func get_interaction_info() -> Dictionary:
	return {"name": building_name, "action": "进入%s" % building_name, "key": "E"}

func interact(player: Node) -> void:
	if associated_dialog != "" and DialogManager:
		DialogManager.start_dialog(associated_dialog)
