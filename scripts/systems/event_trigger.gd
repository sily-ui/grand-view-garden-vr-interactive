extends Area3D
class_name EventTrigger

# 事件触发区域
@export var event_id: String = ""
@export var dialog_id: String = ""
@export var trigger_once: bool = true
@export var required_condition: String = ""
@export var required_value: Variant = true
@export var visible_npc_name: String = ""
@export var visible_npc_offset: Vector3 = Vector3.ZERO
@export var hide_visible_npc_after_trigger: bool = false

var has_triggered: bool = false
var _visible_npc: Node3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_create_visible_npc()

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
		_play_dialog_scene_effect(dialog_id)
	elif event_id != "":
		EventBus.trigger_event(event_id)
	if hide_visible_npc_after_trigger and _visible_npc:
		_visible_npc.visible = false

func _create_visible_npc() -> void:
	var npc_name := visible_npc_name
	if npc_name == "":
		npc_name = _infer_visible_npc_name()
	if npc_name == "":
		return
	_visible_npc = NPCVisualBuilder.apply_to_trigger(self, npc_name, visible_npc_offset)

func _infer_visible_npc_name() -> String:
	match dialog_id:
		"intro_arrival":
			return "周瑞家"
		"farewell":
			return "刘姥姥"
		_:
			return ""

func _play_dialog_scene_effect(started_dialog_id: String) -> void:
	if started_dialog_id != "path_garden":
		return
	var ambience := get_tree().get_first_node_in_group("scene_ambience")
	if ambience and ambience.has_method("play_koi_jump_sequence"):
		ambience.play_koi_jump_sequence()
