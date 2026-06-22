extends StaticBody3D
class_name InteractableItem

# 可交互物品
@export var item_name: String = ""
@export var item_description: String = ""
@export var item_id: String = ""
@export var collectable: bool = false
@export var dialog_id: String = ""

@onready var name_label: Label3D = $NameLabel if has_node("NameLabel") else null

func _ready() -> void:
	if name_label:
		name_label.text = item_name

func interact(_player: Node) -> void:
	if collectable and item_id != "":
		GameState.collect_item(item_id)
		queue_free()
	elif dialog_id != "":
		DialogManager.start_dialog(dialog_id)

func get_interaction_info() -> Dictionary:
	var action := "拾取" if collectable else "查看"
	return {"name": item_name, "action": action, "key": "E"}
