extends Node

signal ui_notification(message: String, type: String)
signal building_selected(building: Dictionary)
signal building_placed(building: Dictionary)
signal district_clicked(district_id: int)
signal money_transaction(amount: float, is_income: bool)
signal event_triggered(event: Dictionary)

func _ready() -> void:
	print("EventBus initialized")

func notify(message: String, type: String = "info") -> void:
	ui_notification.emit(message, type)
	print("[", type.to_upper(), "] ", message)
	print("DEBUG: ui_notification has ", ui_notification.get_connections().size(), " connections")

func notify_success(message: String) -> void:
	notify(message, "success")

func notify_warning(message: String) -> void:
	notify(message, "warning")

func notify_error(message: String) -> void:
	notify(message, "error")

func notify_money_gain(amount: float, source: String = "") -> void:
	var message = "+$" + str(int(amount))
	if source != "":
		message += " from " + source
	notify(message, "success")
	money_transaction.emit(amount, true)

func notify_money_loss(amount: float, reason: String = "") -> void:
	var message = "-$" + str(int(amount))
	if reason != "":
		message += " for " + reason
	notify(message, "warning")
	money_transaction.emit(amount, false)
