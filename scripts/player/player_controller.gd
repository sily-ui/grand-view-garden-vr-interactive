extends CharacterBody3D

# 玩家控制器 - 刘姥姥第一人称视角
@export var walk_speed: float = 3.0
@export var run_speed: float = 5.5
@export var jump_velocity: float = 4.5
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

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	interaction_prompt.visible = false
	EventBus.building_entered.connect(_on_building_entered)
	EventBus.building_exited.connect(_on_building_exited)
	EventBus.time_changed.connect(_on_time_changed)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-look_limit), deg_to_rad(look_limit))
	
	if event.is_action_pressed("interact") and can_interact and current_interactable:
		if GameManager.is_playing():
			current_interactable.interact(self)

func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	
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

func check_interaction() -> void:
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.has_method("get_interaction_info"):
			current_interactable = collider
			can_interact = true
			var info: Dictionary = collider.get_interaction_info()
			interaction_prompt.text = "按 [E] %s" % info.get("action", "交互")
			interaction_prompt.visible = true
			return
	current_interactable = null
	can_interact = false
	interaction_prompt.visible = false

func _on_building_entered(building_name: String) -> void:
	current_location = building_name
	location_label.text = building_name
	GameState.current_area = building_name

func _on_building_exited(_building_name: String) -> void:
	current_location = "大观园"
	location_label.text = "大观园"
	GameState.current_area = ""

func _on_time_changed(hour: int, minute: int) -> void:
	if time_label:
		time_label.text = "%02d:%02d" % [hour, minute]
