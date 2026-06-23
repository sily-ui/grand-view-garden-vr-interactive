extends StaticBody3D
class_name InteractableItem

# 可交互物品
@export var item_name: String = ""
@export var item_description: String = ""
@export var item_id: String = ""
@export var collectable: bool = false
@export var dialog_id: String = ""
@export var hint_radius: float = 3.0

@onready var name_label: Label3D = $NameLabel if has_node("NameLabel") else null

var _hint_label: Label3D = null
var _player: Node3D = null

func _ready() -> void:
	if name_label:
		name_label.text = item_name
		name_label.modulate = Color(1.0, 0.86, 0.28, 1)
		name_label.outline_size = 6
		name_label.outline_modulate = Color(0.06, 0.04, 0.01, 1)
		name_label.double_sided = true
		name_label.visible = false
	_create_hint_label()
	_player = get_tree().get_first_node_in_group("player") as Node3D
	set_process(true)

func _process(_delta: float) -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as Node3D
		return
	if not _hint_label:
		return
	var is_near := global_position.distance_to(_player.global_position) <= hint_radius
	_hint_label.visible = is_near
	if name_label:
		name_label.visible = is_near
	if is_near:
		var pulse: float = 0.55 + 0.45 * abs(sin(Time.get_ticks_msec() * 0.006))
		_hint_label.modulate.a = pulse
		if name_label:
			name_label.modulate.a = pulse

func interact(_player: Node) -> void:
	if collectable and item_id != "":
		GameState.collect_item(item_id)
		queue_free()
	elif dialog_id != "":
		DialogManager.start_dialog(dialog_id)
	elif item_description != "":
		_show_item_description()

func get_interaction_info() -> Dictionary:
	var action := "拾取" if collectable else "查看"
	return {"name": item_name, "action": action, "key": "E"}

func _create_hint_label() -> void:
	_hint_label = Label3D.new()
	_hint_label.name = "InteractionHint"
	_hint_label.text = "按 E 拾取" if collectable else "按 E 查看"
	_hint_label.font_size = 20
	_hint_label.position = Vector3(0, 1.15, 0)
	_hint_label.modulate = Color(1.0, 0.86, 0.28, 1)
	_hint_label.outline_size = 5
	_hint_label.outline_modulate = Color(0.06, 0.04, 0.01, 1)
	_hint_label.double_sided = true
	_hint_label.visible = false
	add_child(_hint_label)

func _show_item_description() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = item_name
	dialog.dialog_text = item_description
	dialog.exclusive = false
	get_tree().current_scene.add_child(dialog)
	dialog.popup_centered(Vector2i(460, 220))
	dialog.confirmed.connect(dialog.queue_free)
