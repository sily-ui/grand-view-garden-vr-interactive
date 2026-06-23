extends CharacterBody3D
class_name NPCBase

# NPC基类
@export var npc_name: String = ""
@export var npc_title: String = ""
@export var dialog_id: String = ""
@export var patrol_speed: float = 2.0
@export var patrol_points: Array[Vector3] = []

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var name_label: Label3D = $NameLabel
@onready var anim_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

var current_patrol_index: int = 0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var has_talked: bool = false

enum NPCState { IDLE, PATROL, TALKING }
var current_state: NPCState = NPCState.IDLE

func _ready() -> void:
	NPCVisualBuilder.apply_to_npc(self, npc_name)
	if name_label:
		name_label.text = npc_name
		name_label.position = Vector3(0, 2.55, 0)
		name_label.font_size = 28
		name_label.pixel_size = 0.01
		name_label.modulate = Color(0.9, 0.76, 0.28, 1)
		name_label.outline_size = 6
		name_label.outline_modulate = Color(0.06, 0.04, 0.01, 1)
		name_label.double_sided = true
		name_label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if patrol_points.size() > 0:
		current_state = NPCState.PATROL

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	match current_state:
		NPCState.IDLE:
			pass
		NPCState.PATROL:
			_do_patrol()
		NPCState.TALKING:
			velocity = Vector3.ZERO
	
	move_and_slide()

func _do_patrol() -> void:
	if patrol_points.size() == 0:
		return
	
	var target: Vector3 = patrol_points[current_patrol_index]
	nav_agent.target_position = target
	
	if nav_agent.is_navigation_finished():
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		return
	
	var next_pos := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()
	velocity.x = direction.x * patrol_speed
	velocity.z = direction.z * patrol_speed
	
	if velocity.length() > 0.1:
		var look_target := Vector3(next_pos.x, global_position.y, next_pos.z)
		look_at(look_target, Vector3.UP)

func interact(_player: Node) -> void:
	if has_talked:
		return
	current_state = NPCState.TALKING
	look_at_player(_player)
	if dialog_id != "":
		has_talked = true
		DialogManager.start_dialog(dialog_id)
		DialogManager.dialog_ended.connect(_on_dialog_ended, CONNECT_ONE_SHOT)

func look_at_player(player: Node) -> void:
	if player:
		var target_pos := Vector3(player.global_position.x, global_position.y, player.global_position.z)
		look_at(target_pos, Vector3.UP)

func _on_dialog_ended(_id: String) -> void:
	current_state = NPCState.PATROL if patrol_points.size() > 0 else NPCState.IDLE

func get_interaction_info() -> Dictionary:
	return {"name": npc_name, "action": "与%s对话" % npc_name, "key": "E"}
