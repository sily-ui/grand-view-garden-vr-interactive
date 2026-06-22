extends CanvasLayer

# 游戏内HUD
@onready var location_label: Label = $LocationLabel
@onready var time_label: Label = $TimeLabel
@onready var crosshair: TextureRect = $Crosshair

var time_system: Node = null

func _ready() -> void:
	add_to_group("game_hud")
	call_deferred("_find_time_system")

func _find_time_system() -> void:
	time_system = get_tree().get_first_node_in_group("time_system")

func _process(_delta: float) -> void:
	if time_system and time_label:
		time_label.text = time_system.get_time_string()

func update_location(loc_name: String) -> void:
	if location_label:
		location_label.text = loc_name
