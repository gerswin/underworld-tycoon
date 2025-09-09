extends Control
class_name SimpleHUD

# Dynamic references to avoid @onready issues
var clean_money_label: Label
var dirty_money_label: Label
var approval_label: Label
var heat_label: Label
var time_label: Label

var tab_container: TabContainer
var notification_container: VBoxContainer

var all_buttons: Array[Button] = []

func _ready() -> void:
	setup_ui_references()
	connect_signals()
	setup_buttons_safe()
	update_display()
	print("SimpleHUD initialized")

func setup_ui_references() -> void:
	# Find UI elements dynamically instead of using @onready
	clean_money_label = find_node_by_path("TopBar/MoneyContainer/CleanMoneyLabel")
	dirty_money_label = find_node_by_path("TopBar/MoneyContainer/DirtyMoneyLabel")
	approval_label = find_node_by_path("TopBar/StatsContainer/ApprovalLabel")
	heat_label = find_node_by_path("TopBar/StatsContainer/HeatLabel")
	time_label = find_node_by_path("TopBar/StatsContainer/TimeLabel")
	tab_container = find_node_by_path("BottomPanel/TabContainer")
	notification_container = find_node_by_path("NotificationContainer")
	
	# Collect all buttons
	collect_buttons()

func find_node_by_path(path: String) -> Node:
	var node = get_node_or_null(path)
	if !node:
		print("Warning: Could not find node at path: ", path)
	return node

func collect_buttons() -> void:
	all_buttons.clear()
	
	# Find buttons recursively
	find_buttons_recursive(self)
	
	print("Found ", all_buttons.size(), " buttons")

func find_buttons_recursive(node: Node) -> void:
	if node is Button:
		all_buttons.append(node as Button)
	
	for child in node.get_children():
		find_buttons_recursive(child)

func connect_signals() -> void:
	# System signals
	if Economy:
		if !Economy.money_changed.is_connected(_on_money_changed):
			Economy.money_changed.connect(_on_money_changed)
		if !Economy.laundering_completed.is_connected(_on_laundering_completed):
			Economy.laundering_completed.connect(_on_laundering_completed)
	
	if CitySim:
		if !CitySim.approval_changed.is_connected(_on_approval_changed):
			CitySim.approval_changed.connect(_on_approval_changed)
	
	if RiskSystem:
		if !RiskSystem.heat_changed.is_connected(_on_heat_changed):
			RiskSystem.heat_changed.connect(_on_heat_changed)
	
	if TimeManager:
		if !TimeManager.hour_passed.is_connected(_on_hour_passed):
			TimeManager.hour_passed.connect(_on_hour_passed)
	
	if EventBus:
		if !EventBus.ui_notification.is_connected(_on_notification):
			EventBus.ui_notification.connect(_on_notification)

func setup_buttons_safe() -> void:
	# Setup buttons by finding them by name
	for button in all_buttons:
		setup_individual_button(button)

func setup_individual_button(button: Button) -> void:
	var button_name = button.name.to_lower()
	
	# Speed buttons
	if "pause" in button_name:
		button.toggle_mode = true
		if !button.pressed.is_connected(_on_pause_pressed):
			button.pressed.connect(_on_pause_pressed)
	elif "speed" in button_name and "1x" in button_name:
		button.toggle_mode = true
		button.button_pressed = true
		if !button.pressed.is_connected(func(): GameManager.set_game_speed(1.0)):
			button.pressed.connect(func(): GameManager.set_game_speed(1.0))
	elif "speed" in button_name and "2x" in button_name:
		button.toggle_mode = true
		if !button.pressed.is_connected(func(): GameManager.set_game_speed(2.0)):
			button.pressed.connect(func(): GameManager.set_game_speed(2.0))
	elif "speed" in button_name and "3x" in button_name:
		button.toggle_mode = true
		if !button.pressed.is_connected(func(): GameManager.set_game_speed(3.0)):
			button.pressed.connect(func(): GameManager.set_game_speed(3.0))
	
	# Legal service buttons
	elif "garbage" in button_name:
		if !button.pressed.is_connected(func(): invest_in_service("garbage")):
			button.pressed.connect(func(): invest_in_service("garbage"))
	elif "transport" in button_name:
		if !button.pressed.is_connected(func(): invest_in_service("transport")):
			button.pressed.connect(func(): invest_in_service("transport"))
	elif "police" in button_name:
		if !button.pressed.is_connected(func(): invest_in_service("police")):
			button.pressed.connect(func(): invest_in_service("police"))
	elif "works" in button_name:
		if !button.pressed.is_connected(func(): invest_in_service("public_works")):
			button.pressed.connect(func(): invest_in_service("public_works"))
	
	# Illegal business buttons
	elif "bar" in button_name and "garbage" not in button_name:
		if !button.pressed.is_connected(func(): start_building("bar")):
			button.pressed.connect(func(): start_building("bar"))
	elif "club" in button_name:
		if !button.pressed.is_connected(func(): start_building("club")):
			button.pressed.connect(func(): start_building("club"))
	elif "workshop" in button_name:
		if !button.pressed.is_connected(func(): start_building("workshop")):
			button.pressed.connect(func(): start_building("workshop"))
	elif "ngo" in button_name:
		if !button.pressed.is_connected(func(): start_building("ngo")):
			button.pressed.connect(func(): start_building("ngo"))
	elif "launder" in button_name:
		if !button.pressed.is_connected(_on_launder_pressed):
			button.pressed.connect(_on_launder_pressed)

func update_display() -> void:
	_on_money_changed(Economy.clean_money, Economy.dirty_money)
	_on_approval_changed(CitySim.city_approval)
	_on_heat_changed(RiskSystem.global_heat)
	_update_time_display()

func _on_money_changed(clean: float, dirty: float) -> void:
	if clean_money_label:
		clean_money_label.text = "Clean: $" + format_money(clean)
	if dirty_money_label:
		dirty_money_label.text = "Dirty: $" + format_money(dirty)
	update_button_affordability()

func _on_approval_changed(approval: float) -> void:
	if approval_label:
		approval_label.text = "Approval: " + str(int(approval)) + "%"
		
		if approval < 30:
			approval_label.modulate = Color.RED
		elif approval < 50:
			approval_label.modulate = Color.YELLOW
		else:
			approval_label.modulate = Color.GREEN

func _on_heat_changed(heat: float) -> void:
	if heat_label:
		heat_label.text = "Heat: " + str(int(heat)) + "%"
		
		if heat > 70:
			heat_label.modulate = Color.RED
		elif heat > 50:
			heat_label.modulate = Color.ORANGE
		elif heat > 30:
			heat_label.modulate = Color.YELLOW
		else:
			heat_label.modulate = Color.WHITE

func _on_hour_passed(_hour: int) -> void:
	_update_time_display()

func _update_time_display() -> void:
	if time_label and TimeManager:
		time_label.text = TimeManager.get_formatted_date()

func _on_pause_pressed() -> void:
	var pause_button = find_button_by_name("pause")
	if pause_button:
		GameManager.pause_game(pause_button.button_pressed)
		pause_button.text = "▶" if pause_button.button_pressed else "⏸"

func find_button_by_name(search_name: String) -> Button:
	for button in all_buttons:
		if search_name.to_lower() in button.name.to_lower():
			return button
	return null

func invest_in_service(service: String) -> void:
	var cost = CitySim.public_services[service]["cost"]
	if Economy.spend_clean_money(cost):
		CitySim.update_service_quality(service, cost)
		EventBus.notify_success("Invested in " + service)
	else:
		EventBus.notify_error("Not enough clean money")

func start_building(building_type: String) -> void:
	var main_scene = get_tree().get_root().get_node_or_null("Main")
	if main_scene and main_scene.has_method("start_building_placement"):
		main_scene.start_building_placement(building_type)

func _on_launder_pressed() -> void:
	if Economy.dirty_money > 0:
		var laundered = Economy.launder_money(10000.0)
		if laundered > 0:
			EventBus.notify_success("Laundered $" + format_money(laundered))
		else:
			EventBus.notify_warning("Cannot launder money right now")
	else:
		EventBus.notify_error("No dirty money to launder")

func _on_laundering_completed(amount: float) -> void:
	RiskSystem.add_heat(amount / 1000.0, "laundering")

func update_button_affordability() -> void:
	# This is simplified - just disable if no money
	for button in all_buttons:
		var button_name = button.name.to_lower()
		if "bar" in button_name and "garbage" not in button_name:
			button.disabled = Economy.dirty_money < 8000.0
		elif "club" in button_name:
			button.disabled = Economy.dirty_money < 18000.0
		elif "workshop" in button_name:
			button.disabled = Economy.dirty_money < 15000.0
		elif "ngo" in button_name:
			button.disabled = Economy.dirty_money < 30000.0

func _on_notification(message: String, type: String) -> void:
	show_notification(message, type)

func show_notification(text: String, type: String = "info") -> void:
	print("[", type.to_upper(), "] ", text)
	
	# Simple fallback notification
	if notification_container:
		var label = Label.new()
		label.text = text
		label.add_theme_font_size_override("font_size", 14)
		
		match type:
			"success":
				label.modulate = Color.GREEN
			"warning":
				label.modulate = Color.YELLOW
			"error":
				label.modulate = Color.RED
			_:
				label.modulate = Color.WHITE
		
		notification_container.add_child(label)
		
		# Auto-remove after 3 seconds
		get_tree().create_timer(3.0).timeout.connect(func(): 
			if label and is_instance_valid(label):
				label.queue_free()
		)
		
		# Limit notifications
		while notification_container.get_child_count() > 5:
			var first_child = notification_container.get_child(0)
			if first_child:
				first_child.queue_free()

func format_money(amount: float) -> String:
	if amount >= 1000000:
		return str(snapped(amount / 1000000.0, 0.1)) + "M"
	elif amount >= 1000:
		return str(snapped(amount / 1000.0, 0.1)) + "K"
	else:
		return str(int(amount))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_panel") and tab_container:
		tab_container.current_tab = (tab_container.current_tab + 1) % tab_container.get_tab_count()