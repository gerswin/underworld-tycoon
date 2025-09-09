extends Node
class_name NotificationHistory

signal notification_added(notification: Dictionary)

var notifications: Array[Dictionary] = []
var max_history: int = 100

func _ready() -> void:
	# Connect to EventBus to capture all notifications
	if EventBus:
		EventBus.ui_notification.connect(_on_notification_received)
	print("NotificationHistory initialized")

func _on_notification_received(message: String, type: String) -> void:
	add_notification(message, type)

func add_notification(message: String, type: String) -> void:
	var notification = {
		"message": message,
		"type": type,
		"timestamp": Time.get_datetime_string_from_system(),
		"game_time": TimeManager.get_formatted_date() if TimeManager else "Day 1 - 6:00 AM",
		"id": notifications.size()
	}
	
	notifications.append(notification)
	notification_added.emit(notification)
	
	# Limit history size
	while notifications.size() > max_history:
		notifications.pop_front()
	
	print("[HISTORY] ", type.to_upper(), ": ", message)

func get_recent_notifications(count: int = 10) -> Array[Dictionary]:
	var recent: Array[Dictionary] = []
	var start_index = max(0, notifications.size() - count)
	
	for i in range(start_index, notifications.size()):
		recent.append(notifications[i])
	
	return recent

func get_notifications_by_type(type: String) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for notification in notifications:
		if notification["type"] == type:
			filtered.append(notification)
	return filtered

func get_all_notifications() -> Array[Dictionary]:
	return notifications.duplicate()

func clear_history() -> void:
	notifications.clear()

func get_notification_count() -> int:
	return notifications.size()

func get_notification_stats() -> Dictionary:
	var stats = {
		"total": 0,
		"success": 0,
		"warning": 0,
		"error": 0,
		"info": 0
	}
	
	for notification in notifications:
		stats["total"] += 1
		var type = notification.get("type", "info")
		if type in stats:
			stats[type] += 1
		else:
			stats["info"] += 1
	
	return stats