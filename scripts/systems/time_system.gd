extends Node

# 时间与天气系统
signal time_changed(hour: int, minute: int)

@export var day_duration_real_minutes: float = 24.0
@export var start_hour: int = 8
@export var start_minute: int = 0

var current_hour: int = 8
var current_minute: int = 0
var time_scale: float = 1.0
var paused: bool = false

var sun: DirectionalLight3D = null
var env_node: WorldEnvironment = null

var sky_presets: Dictionary = {
	"morning": {"sun_color": Color(1.0, 0.95, 0.8), "sun_energy": 0.8, "fog_color": Color(0.9, 0.85, 0.75)},
	"noon": {"sun_color": Color(1.0, 0.98, 0.95), "sun_energy": 1.2, "fog_color": Color(0.85, 0.88, 0.9)},
	"evening": {"sun_color": Color(1.0, 0.7, 0.4), "sun_energy": 0.6, "fog_color": Color(0.9, 0.6, 0.4)},
	"night": {"sun_color": Color(0.2, 0.2, 0.4), "sun_energy": 0.1, "fog_color": Color(0.1, 0.1, 0.2)}
}

func _ready() -> void:
	current_hour = start_hour
	current_minute = start_minute
	call_deferred("_find_nodes")

func _find_nodes() -> void:
	var tree := get_tree()
	if tree:
		sun = tree.get_first_node_in_group("sun")
		env_node = tree.get_first_node_in_group("world_environment")

func _process(delta: float) -> void:
	if paused:
		return
	_update_time(delta)
	_update_environment()

func _update_time(delta: float) -> void:
	var minutes_per_second := (24.0 * 60.0) / (day_duration_real_minutes * 60.0)
	current_minute += minutes_per_second * delta * time_scale
	
	if current_minute >= 60:
		current_minute -= 60
		current_hour += 1
		if current_hour >= 24:
			current_hour = 0
	
	GameState.current_hour = current_hour
	GameState.current_minute = int(current_minute)
	EventBus.time_changed.emit(current_hour, int(current_minute))

func _update_environment() -> void:
	var time_factor := current_hour + current_minute / 60.0
	var preset: Dictionary = _get_time_preset(time_factor)
	
	if sun:
		var sun_angle := -90.0 + (time_factor / 24.0) * 360.0
		sun.rotation_degrees.x = clamp(sun_angle, -90.0, 0.0)
		sun.light_color = preset["sun_color"]
		sun.light_energy = preset["sun_energy"]
	
	if env_node and env_node is WorldEnvironment and env_node.environment:
		var env: Environment = env_node.environment
		env.fog_light_color = preset["fog_color"]

func _get_time_preset(hour: float) -> Dictionary:
	if hour < 6:
		return sky_presets.night
	elif hour < 9:
		return sky_presets.morning
	elif hour < 17:
		return sky_presets.noon
	elif hour < 20:
		return sky_presets.evening
	else:
		return sky_presets.night

func get_time_string() -> String:
	return "%02d:%02d" % [current_hour, int(current_minute)]

func set_paused(p: bool) -> void:
	paused = p
