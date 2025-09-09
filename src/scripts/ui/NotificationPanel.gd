extends Control
class_name NotificationPanel

@onready var background: ColorRect
@onready var title_bar: HBoxContainer
@onready var close_button: Button
@onready var clear_button: Button
@onready var scroll_container: ScrollContainer
@onready var notifications_list: VBoxContainer
@onready var stats_label: Label
@onready var filter_buttons: HBoxContainer

var notification_history: NotificationHistory
var current_filter: String = "all"

func _ready() -> void:
	setup_panel()
	setup_controls()
	
	# Find or create notification history
	notification_history = get_tree().get_first_node_in_group("notification_history")
	if !notification_history:
		notification_history = NotificationHistory.new()
		notification_history.add_to_group("notification_history")
		get_tree().root.add_child(notification_history)
	
	notification_history.notification_added.connect(_on_notification_added)
	
	visible = false
	modulate.a = 0.0

func setup_panel() -> void:
	# Main background
	background = ColorRect.new()
	background.color = Color(0.1, 0.1, 0.1, 0.95)
	background.size = Vector2(500, 600)
	background.position = Vector2(50, 50)
	add_child(background)
	
	# Title bar
	title_bar = HBoxContainer.new()
	title_bar.size = Vector2(480, 40)
	title_bar.position = Vector2(10, 10)
	
	var title_label = Label.new()
	title_label.text = "Notification History"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_bar.add_child(title_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(spacer)
	
	# Clear button
	clear_button = Button.new()
	clear_button.text = "Clear"
	clear_button.size = Vector2(60, 30)
	clear_button.pressed.connect(_on_clear_pressed)
	title_bar.add_child(clear_button)
	
	# Close button
	close_button = Button.new()
	close_button.text = "✕"
	close_button.size = Vector2(30, 30)
	close_button.pressed.connect(hide_panel)
	title_bar.add_child(close_button)
	
	add_child(title_bar)

func setup_controls() -> void:
	# Filter buttons
	filter_buttons = HBoxContainer.new()
	filter_buttons.position = Vector2(10, 60)
	filter_buttons.size = Vector2(480, 30)
	
	var filters = ["all", "success", "warning", "error", "info"]
	for filter in filters:
		var btn = Button.new()
		btn.text = filter.capitalize()
		btn.toggle_mode = true
		btn.button_pressed = (filter == "all")
		btn.pressed.connect(_on_filter_changed.bind(filter))
		filter_buttons.add_child(btn)
	
	add_child(filter_buttons)
	
	# Stats label
	stats_label = Label.new()
	stats_label.position = Vector2(10, 100)
	stats_label.add_theme_font_size_override("font_size", 12)
	stats_label.add_theme_color_override("font_color", Color.GRAY)
	add_child(stats_label)
	
	# Scroll container
	scroll_container = ScrollContainer.new()
	scroll_container.position = Vector2(10, 130)
	scroll_container.size = Vector2(480, 450)
	
	notifications_list = VBoxContainer.new()
	notifications_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(notifications_list)
	
	add_child(scroll_container)

func show_panel() -> void:
	visible = true
	refresh_notifications()
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	# Move to center of screen
	var screen_size = get_viewport().get_visible_rect().size
	var panel_size = background.size
	var center_pos = (screen_size - panel_size) / 2
	background.position = center_pos

func hide_panel() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): visible = false)

func refresh_notifications() -> void:
	# Clear existing notifications
	for child in notifications_list.get_children():
		child.queue_free()
	
	# Get filtered notifications
	var notifications = get_filtered_notifications()
	
	# Add notifications to list
	for notification in notifications:
		add_notification_item(notification)
	
	# Update stats
	update_stats()

func get_filtered_notifications() -> Array[Dictionary]:
	if !notification_history:
		return []
	
	if current_filter == "all":
		return notification_history.get_recent_notifications(50)
	else:
		return notification_history.get_notifications_by_type(current_filter)

func add_notification_item(notification: Dictionary) -> void:
	var item_container = HBoxContainer.new()
	item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Time label
	var time_label = Label.new()
	time_label.text = notification.get("game_time", "")
	time_label.add_theme_font_size_override("font_size", 10)
	time_label.add_theme_color_override("font_color", Color.GRAY)
	time_label.custom_minimum_size.x = 100
	item_container.add_child(time_label)
	
	# Type indicator
	var type_label = Label.new()
	var type = notification.get("type", "info")
	type_label.text = "[" + type.to_upper() + "]"
	type_label.add_theme_font_size_override("font_size", 10)
	type_label.custom_minimum_size.x = 80
	
	match type:
		"success":
			type_label.add_theme_color_override("font_color", Color.GREEN)
		"warning":
			type_label.add_theme_color_override("font_color", Color.YELLOW)
		"error":
			type_label.add_theme_color_override("font_color", Color.RED)
		_:
			type_label.add_theme_color_override("font_color", Color.WHITE)
	
	item_container.add_child(type_label)
	
	# Message label
	var message_label = Label.new()
	message_label.text = notification.get("message", "")
	message_label.add_theme_font_size_override("font_size", 12)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_container.add_child(message_label)
	
	notifications_list.add_child(item_container)
	
	# Add separator
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 1)
	notifications_list.add_child(separator)

func update_stats() -> void:
	if !notification_history:
		return
	
	var stats = notification_history.get_notification_stats()
	var stats_text = "Total: %d | Success: %d | Warnings: %d | Errors: %d | Info: %d" % [
		stats.get("total", 0),
		stats.get("success", 0),
		stats.get("warning", 0),
		stats.get("error", 0),
		stats.get("info", 0)
	]
	
	if stats_label:
		stats_label.text = stats_text

func _on_notification_added(notification: Dictionary) -> void:
	if visible and current_filter in ["all", notification.get("type", "info")]:
		refresh_notifications()

func _on_filter_changed(filter: String) -> void:
	current_filter = filter
	
	# Update button states
	for child in filter_buttons.get_children():
		if child is Button:
			child.button_pressed = (child.text.to_lower() == filter)
	
	refresh_notifications()

func _on_clear_pressed() -> void:
	if notification_history:
		notification_history.clear_history()
		refresh_notifications()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide_panel()