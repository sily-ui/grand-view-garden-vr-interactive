extends Area3D
class_name EventTrigger

# 事件触发区域
@export var event_id: String = ""
@export var dialog_id: String = ""
@export var trigger_once: bool = true
@export var required_condition: String = ""
@export var required_value: Variant = true
@export var blocked_condition: String = ""
@export var blocked_value: Variant = true
@export var visible_npc_name: String = ""
@export var visible_npc_offset: Vector3 = Vector3.ZERO
@export var hide_visible_npc_after_trigger: bool = false
# 对话结束后是否保留 NPC 在场景中（true=保留，false=按 trigger_once 规则隐藏）
@export var persist_after_trigger: bool = false
# 为 true 时，玩家进入区域不会自动触发，需要在区域内按 E 键才会触发。
# 默认 false：走近 NPC 即自动开始对话，契合"见到 NPC 推进主线"的体验。
@export var require_e_key: bool = false
# require_e_key 模式下显示的交互提示文字
@export var e_key_prompt: String = "上前对话"

var has_triggered: bool = false
var _visible_npc: Node3D = null
var _player_inside: bool = false
var _prompt_label: Label3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_create_visible_npc()
	_update_visible_npc()
	set_process(true)

func _process(_delta: float) -> void:
	_update_visible_npc()
	if require_e_key and _player_inside and not has_triggered and not GameManager.is_dialog_active():
		if Input.is_action_just_pressed("interact"):
			_fire_trigger()
	_update_prompt_label()

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if require_e_key:
		_player_inside = true
		_ensure_prompt_label()
		return
	_try_auto_trigger()

func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if require_e_key:
		_player_inside = false
	_update_prompt_label()

func _try_auto_trigger() -> void:
	if trigger_once and has_triggered:
		return
	if GameManager.is_dialog_active():
		return
	if required_condition != "" and not GameState.check_condition(required_condition, required_value):
		return
	if blocked_condition != "" and GameState.check_condition(blocked_condition, blocked_value):
		return
	_fire_trigger()

func _fire_trigger() -> void:
	if trigger_once and has_triggered:
		return
	if GameManager.is_dialog_active():
		return
	if required_condition != "" and not GameState.check_condition(required_condition, required_value):
		return
	if blocked_condition != "" and GameState.check_condition(blocked_condition, blocked_value):
		return
	has_triggered = true
	if dialog_id != "":
		DialogManager.start_dialog(dialog_id)
		_play_dialog_scene_effect(dialog_id)
	elif event_id != "":
		EventBus.trigger_event(event_id)
	# 对话开始瞬间强制可见 NPC：杜绝"只弹对话文字却看不到人"。
	# persist_after_trigger=true 的 NPC 之后会一直保留；其余 NPC 由
	# _update_visible_npc() 在对话结束、条件变化后再决定是否隐藏。
	if _visible_npc:
		_visible_npc.visible = true
	if hide_visible_npc_after_trigger and _visible_npc:
		_visible_npc.visible = false
	_update_prompt_label()

func _ensure_prompt_label() -> void:
	if _prompt_label:
		return
	_prompt_label = Label3D.new()
	_prompt_label.name = "EKeyPrompt"
	_prompt_label.text = e_key_prompt
	_prompt_label.position = Vector3(0, 2.6, 0)
	_prompt_label.font_size = 28
	_prompt_label.pixel_size = 0.012
	_prompt_label.modulate = Color(0.95, 0.85, 0.4, 1.0)
	_prompt_label.outline_size = 6
	_prompt_label.outline_modulate = Color(0.06, 0.04, 0.01, 1.0)
	_prompt_label.double_sided = true
	_prompt_label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_prompt_label.visible = false
	add_child(_prompt_label)

func _update_prompt_label() -> void:
	if not _prompt_label:
		return
	var should_show: bool = require_e_key and _player_inside and not has_triggered
	if should_show and required_condition != "" and not GameState.check_condition(required_condition, required_value):
		should_show = false
	if should_show and blocked_condition != "" and GameState.check_condition(blocked_condition, blocked_value):
		should_show = false
	if should_show and GameManager.is_dialog_active():
		should_show = false
	_prompt_label.visible = should_show

func _create_visible_npc() -> void:
	var npc_name := visible_npc_name
	if npc_name == "":
		npc_name = _infer_visible_npc_name()
	if npc_name == "":
		return
	_visible_npc = NPCVisualBuilder.apply_to_trigger(self, npc_name, visible_npc_offset)

func _update_visible_npc() -> void:
	if not _visible_npc:
		return
	# 同步：若 blocked_condition 已被其他系统（如立牌 signboard）设置，
	# 则视为本触发器已完成，避免 NPC 被误隐藏或对话重复触发。
	if not has_triggered and blocked_condition != "" and GameState.check_condition(blocked_condition, blocked_value):
		has_triggered = true
	var can_show := true
	# persist_after_trigger=true 时，触发后保留 NPC；否则按 trigger_once 规则隐藏
	if not persist_after_trigger and trigger_once and has_triggered:
		can_show = false
	if required_condition != "" and not GameState.check_condition(required_condition, required_value):
		can_show = false
	# persist_after_trigger=true 且已触发后，跳过 blocked_condition 隐藏检查
	# （blocked_condition 仍用于阻止重复触发对话，但不再隐藏已保留的 NPC）
	if not (persist_after_trigger and has_triggered):
		if blocked_condition != "" and GameState.check_condition(blocked_condition, blocked_value):
			can_show = false
	# 对话进行中保持 NPC 可见，避免 blocked_condition 立即隐藏
	if GameManager.is_dialog_active():
		can_show = true
	_visible_npc.visible = can_show

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
