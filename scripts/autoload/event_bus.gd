extends Node

# 游戏事件总线 - 全局信号中心
signal building_entered(building_name: String)
signal building_exited(building_name: String)
signal dialog_started(dialog_id: String)
signal dialog_ended(dialog_id: String)
signal item_collected(item_id: String)
signal event_triggered(event_id: String)
signal area_unlocked(area_name: String)
signal time_changed(hour: int, minute: int)
signal player_interacted(target: Node)

var completed_events: Array[String] = []

func trigger_event(event_id: String) -> void:
	if event_id not in completed_events:
		completed_events.append(event_id)
	event_triggered.emit(event_id)

func is_event_completed(event_id: String) -> bool:
	return event_id in completed_events

func get_completed_events() -> Array[String]:
	return completed_events

func load_completed_events(events: Array[String]) -> void:
	completed_events = events
