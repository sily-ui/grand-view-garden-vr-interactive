extends Node

# 游戏全局状态
var current_area: String = ""
var unlocked_areas: Array[String] = ["entrance"]
var collected_items: Array[String] = []
var dialog_history: Array[String] = []
var player_position: Vector3 = Vector3.ZERO
var current_hour: int = 8
var current_minute: int = 0

# 条件系统
var conditions: Dictionary = {}

func set_condition(key: String, value: Variant) -> void:
	conditions[key] = value

func get_condition(key: String, default: Variant = null) -> Variant:
	return conditions.get(key, default)

func check_condition(key: String, expected: Variant) -> bool:
	return conditions.get(key) == expected

func unlock_area(area_name: String) -> void:
	if area_name not in unlocked_areas:
		unlocked_areas.append(area_name)
		EventBus.area_unlocked.emit(area_name)

func is_area_unlocked(area_name: String) -> bool:
	return area_name in unlocked_areas

func collect_item(item_id: String) -> void:
	if item_id not in collected_items:
		collected_items.append(item_id)
		EventBus.item_collected.emit(item_id)

func has_item(item_id: String) -> bool:
	return item_id in collected_items

func serialize() -> Dictionary:
	return {
		"current_area": current_area,
		"unlocked_areas": unlocked_areas,
		"collected_items": collected_items,
		"dialog_history": dialog_history,
		"conditions": conditions,
		"current_hour": current_hour,
		"current_minute": current_minute
	}

func deserialize(data: Dictionary) -> void:
	current_area = data.get("current_area", "")
	unlocked_areas = data.get("unlocked_areas", ["entrance"])
	collected_items = data.get("collected_items", [])
	dialog_history = data.get("dialog_history", [])
	conditions = data.get("conditions", {})
	current_hour = data.get("current_hour", 8)
	current_minute = data.get("current_minute", 0)
