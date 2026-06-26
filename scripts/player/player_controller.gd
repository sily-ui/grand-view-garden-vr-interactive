extends CharacterBody3D

# 玩家控制器 - 刘姥姥第一人称视角
@export var walk_speed: float = 3.0
@export var run_speed: float = 5.5
@export var jump_velocity: float = 4.5
@export var step_height: float = 0.45
@export var mouse_sensitivity: float = 0.002
@export var look_limit: float = 80.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera: Camera3D = $Camera3D
@onready var raycast: RayCast3D = $Camera3D/InteractionRaycast
@onready var interaction_prompt: Label = $UILayer/HUD/InteractionPrompt
@onready var location_label: Label = $UILayer/HUD/LocationLabel
@onready var time_label: Label = $UILayer/HUD/TimeLabel

var is_running: bool = false
var can_interact: bool = false
var current_interactable: Node = null
var current_location: String = "大观园"
const NEARBY_INTERACT_DISTANCE := 3.2
const NEARBY_INTERACT_FORWARD_DOT := 0.25

func _ready() -> void:
	floor_snap_length = step_height
	floor_max_angle = deg_to_rad(50.0)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	interaction_prompt.visible = false
	location_label.visible = false
	time_label.visible = false
	EventBus.building_entered.connect(_on_building_entered)
	EventBus.building_exited.connect(_on_building_exited)
	EventBus.time_changed.connect(_on_time_changed)

func _input(event: InputEvent) -> void:
	if _has_blocking_mouse_ui():
		return

	if event is InputEventMouseButton and event.pressed and GameManager.is_playing() and Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-look_limit), deg_to_rad(look_limit))
	
	# 对话中暂停玩家交互，对话输入交给 DialogUI 统一处理
	if GameManager.is_dialog_active():
		return
	
	# 场景交互统一使用 E；左键留给立牌小传和对话 UI。
	if event.is_action_pressed("interact") and can_interact and current_interactable:
		if GameManager.is_playing():
			current_interactable.interact(self)

func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	if _has_blocking_mouse_ui():
		velocity.x = move_toward(velocity.x, 0, walk_speed)
		velocity.z = move_toward(velocity.z, 0, walk_speed)
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		if get_viewport().gui_get_focus_owner() != null:
			return
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# 重力
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# 跳跃
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# 移动
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	is_running = Input.is_action_pressed("sprint")
	var current_speed := run_speed if is_running else walk_speed
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	move_and_slide()
	check_interaction()

func _has_blocking_mouse_ui() -> bool:
	for node in get_tree().get_nodes_in_group("blocking_mouse_ui"):
		if bool(node.get("visible")):
			return true
	return false

func check_interaction() -> void:
	current_interactable = null
	can_interact = false
	interaction_prompt.visible = false

	var target := _get_raycast_interactable()
	if not target:
		target = _get_nearby_interactable()
	if not target:
		return

	current_interactable = target
	can_interact = true
	var info: Dictionary = target.get_interaction_info()
	var action: String = info.get("action", "交互")
	# action 为空表示建筑未解锁/前置剧情未满足，不显示准星提示，
	# 避免"按 e 键稍后进入大观楼"等冗余文案干扰主线任务指引。
	if action == "":
		can_interact = false
		current_interactable = null
		return
	interaction_prompt.text = "按 [E] %s：%s" % [action, info.get("name", "目标")]
	interaction_prompt.visible = true

func _get_raycast_interactable() -> Node:
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.has_method("get_interaction_info"):
			return collider
	return null

func _get_nearby_interactable() -> Node:
	var best: Node = null
	var best_score := INF
	var forward := -camera.global_transform.basis.z
	for node in get_tree().get_nodes_in_group("npc"):
		if not node is Node3D or not node.has_method("get_interaction_info"):
			continue
		var to_target: Vector3 = node.global_position - camera.global_position
		var distance := to_target.length()
		if distance > NEARBY_INTERACT_DISTANCE:
			continue
		var flat_target := Vector3(to_target.x, 0, to_target.z)
		if flat_target.length() > 0.01:
			var dot := Vector3(forward.x, 0, forward.z).normalized().dot(flat_target.normalized())
			if dot < NEARBY_INTERACT_FORWARD_DOT:
				continue
		var score := distance
		if score < best_score:
			best_score = score
			best = node
	return best

func _on_building_entered(building_name: String) -> void:
	current_location = building_name
	location_label.text = ""
	GameState.current_area = building_name

func _on_building_exited(_building_name: String) -> void:
	current_location = "大观园"
	location_label.text = ""
	GameState.current_area = ""

func _on_time_changed(hour: int, minute: int) -> void:
	if time_label:
		time_label.text = ""
