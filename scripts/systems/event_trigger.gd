extends Area3D
class_name EventTrigger

# 事件触发区域
@export var event_id: String = ""
@export var dialog_id: String = ""
@export var trigger_once: bool = true
@export var required_condition: String = ""
@export var required_value: Variant = true

var has_triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if trigger_once and has_triggered:
		return
	# 对话进行中时不再触发新对话
	if DialogManager.is_active:
		return
	if required_condition != "" and not GameState.check_condition(required_condition, required_value):
		return
	
	has_triggered = true
	
	if dialog_id != "":
		DialogManager.start_dialog(dialog_id)
	elif event_id != "":
		EventBus.trigger_event(event_id)
