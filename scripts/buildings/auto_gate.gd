extends Node3D

@export var open_distance: float = 4.0
@export var close_distance: float = 5.5
@export var open_angle_degrees: float = 82.0
@export var animation_time: float = 1.2

var _player: Node3D = null
var _left_door: Node3D = null
var _right_door: Node3D = null
var _is_open: bool = false
var _tween: Tween = null

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node3D
	_find_or_create_doors()
	set_process(true)

func _process(_delta: float) -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as Node3D
		return
	var distance := global_position.distance_to(_player.global_position)
	if not _is_open and distance <= open_distance:
		_set_open(true)
	elif _is_open and distance >= close_distance:
		_set_open(false)

func _find_or_create_doors() -> void:
	_left_door = find_child("Door_L", true, false) as Node3D
	_right_door = find_child("Door_R", true, false) as Node3D
	if _left_door and _right_door:
		return
	_left_door = _create_door("Door_L", Vector3(-0.72, 1.55, -0.08))
	_right_door = _create_door("Door_R", Vector3(0.72, 1.55, -0.08))

func _create_door(door_name: String, local_position: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = door_name
	pivot.position = local_position
	add_child(pivot)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.35, 2.65, 0.12)
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(0, 0, 0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.62, 0.08, 0.04, 1)
	material.roughness = 0.58
	mesh_instance.material_override = material
	pivot.add_child(mesh_instance)
	return pivot

func _set_open(open: bool) -> void:
	if not _left_door or not _right_door:
		return
	_is_open = open
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	var angle := deg_to_rad(open_angle_degrees)
	_tween.tween_property(_left_door, "rotation:y", -angle if open else 0.0, animation_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_right_door, "rotation:y", angle if open else 0.0, animation_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
