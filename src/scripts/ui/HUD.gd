extends Control

@onready var clean_money_label: Label = $TopBar/MoneyContainer/CleanMoneyLabel
@onready var dirty_money_label: Label = $TopBar/MoneyContainer/DirtyMoneyLabel
@onready var approval_label: Label = $TopBar/StatsContainer/ApprovalLabel
@onready var heat_label: Label = $TopBar/StatsContainer/HeatLabel
@onready var time_label: Label = $TopBar/StatsContainer/TimeLabel

@onready var pause_button: Button = $TopBar/SpeedContainer/PauseButton
@onready var speed_1x_button: Button = $TopBar/SpeedContainer/Speed1xButton
@onready var speed_2x_button: Button = $TopBar/SpeedContainer/Speed2xButton
@onready var speed_3x_button: Button = $TopBar/SpeedContainer/Speed3xButton

@onready var tab_container: TabContainer = $BottomPanel/TabContainer
@onready var notification_container: VBoxContainer = $NotificationContainer

# Legal buttons
@onready var garbage_button: Button = $BottomPanel/TabContainer/Legal/LegalButtons/GarbageButton
@onready var transport_button: Button = $BottomPanel/TabContainer/Legal/LegalButtons/TransportButton
@onready var police_button: Button = $BottomPanel/TabContainer/Legal/LegalButtons/PoliceButton
@onready var public_works_button: Button = $BottomPanel/TabContainer/Legal/LegalButtons/PublicWorksButton

# Illegal buttons
@onready var bar_button: Button = $BottomPanel/TabContainer/Illegal/IllegalButtons/BarButton
@onready var club_button: Button = $BottomPanel/TabContainer/Illegal/IllegalButtons/ClubButton
@onready var workshop_button: Button = $BottomPanel/TabContainer/Illegal/IllegalButtons/WorkshopButton
@onready var ngo_button: Button = $BottomPanel/TabContainer/Illegal/IllegalButtons/NGOButton
@onready var launder_button: Button = $BottomPanel/TabContainer/Illegal/IllegalButtons/LaunderButton

var notification_scene = preload("res://src/scenes/ui/Notification.tscn")

func _ready() -> void:
	connect_signals()
	setup_buttons()
	update_display()

func connect_signals() -> void:
	# Economy signals
	Economy.money_changed.connect(_on_money_changed)
	Economy.laundering_completed.connect(_on_laundering_completed)
	
	# CitySim signals
	CitySim.approval_changed.connect(_on_approval_changed)
	
	# RiskSystem signals
	RiskSystem.heat_changed.connect(_on_heat_changed)
	
	# TimeManager signals
	TimeManager.hour_passed.connect(_on_hour_passed)
	
	# EventBus signals
	EventBus.ui_notification.connect(_on_notification)
	
	# Speed buttons
	pause_button.pressed.connect(_on_pause_pressed)
	speed_1x_button.pressed.connect(func(): GameManager.set_game_speed(1.0))
	speed_2x_button.pressed.connect(func(): GameManager.set_game_speed(2.0))
	speed_3x_button.pressed.connect(func(): GameManager.set_game_speed(3.0))
	
	# Legal service buttons
	garbage_button.pressed.connect(func(): invest_in_service("garbage"))
	transport_button.pressed.connect(func(): invest_in_service("transport"))
	police_button.pressed.connect(func(): invest_in_service("police"))
	public_works_button.pressed.connect(func(): invest_in_service("public_works"))
	
	# Illegal business buttons
	bar_button.pressed.connect(func(): start_building("bar"))
	club_button.pressed.connect(func(): start_building("club"))
	workshop_button.pressed.connect(func(): start_building("workshop"))
	ngo_button.pressed.connect(func(): start_building("ngo"))
	launder_button.pressed.connect(_on_launder_pressed)

func setup_buttons() -> void:
	# Set toggle mode for speed buttons
	pause_button.toggle_mode = true
	speed_1x_button.toggle_mode = true
	speed_2x_button.toggle_mode = true
	speed_3x_button.toggle_mode = true
	speed_1x_button.button_pressed = true

func update_display() -> void:
	_on_money_changed(Economy.clean_money, Economy.dirty_money)
	_on_approval_changed(CitySim.city_approval)
	_on_heat_changed(RiskSystem.global_heat)
	_update_time_display()

func _on_money_changed(clean: float, dirty: float) -> void:
	clean_money_label.text = "Clean: $" + format_money(clean)
	dirty_money_label.text = "Dirty: $" + format_money(dirty)
	
	# Update button states based on available money
	update_button_affordability()

func _on_approval_changed(approval: float) -> void:
	approval_label.text = "Approval: " + str(int(approval)) + "%"
	
	if approval < 30:
		approval_label.modulate = Color.RED
	elif approval < 50:
		approval_label.modulate = Color.YELLOW
	else:
		approval_label.modulate = Color.GREEN

func _on_heat_changed(heat: float) -> void:
	heat_label.text = "Heat: " + str(int(heat)) + "%"
	
	if heat > 70:
		heat_label.modulate = Color.RED
	elif heat > 50:
		heat_label.modulate = Color.ORANGE
	elif heat > 30:
		heat_label.modulate = Color.YELLOW
	else:
		heat_label.modulate = Color.WHITE

func _on_hour_passed(hour: int) -> void:
	_update_time_display()

func _update_time_display() -> void:
	time_label.text = TimeManager.get_formatted_date()

func _on_pause_pressed() -> void:
	GameManager.pause_game(pause_button.button_pressed)
	pause_button.text = "▶" if pause_button.button_pressed else "⏸"

func invest_in_service(service: String) -> void:
	var cost = CitySim.public_services[service]["cost"]
	if Economy.spend_clean_money(cost):
		CitySim.update_service_quality(service, cost)
		EventBus.notify_success("Invested in " + service)
	else:
		EventBus.notify_error("Not enough clean money")

func start_building(building_type: String) -> void:
	get_tree().get_root().get_node("Main").start_building_placement(building_type)

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
	# Update legal service buttons
	garbage_button.disabled = Economy.clean_money < CitySim.public_services["garbage"]["cost"]
	transport_button.disabled = Economy.clean_money < CitySim.public_services["transport"]["cost"]
	police_button.disabled = Economy.clean_money < CitySim.public_services["police"]["cost"]
	public_works_button.disabled = Economy.clean_money < CitySim.public_services["public_works"]["cost"]
	
	# Update illegal business buttons
	bar_button.disabled = Economy.dirty_money < ShadowOps.business_types["bar"]["cost"]
	club_button.disabled = Economy.dirty_money < ShadowOps.business_types["club"]["cost"]
	workshop_button.disabled = Economy.dirty_money < ShadowOps.business_types["workshop"]["cost"]
	ngo_button.disabled = Economy.dirty_money < ShadowOps.business_types["ngo"]["cost"]

func _on_notification(message: String, type: String) -> void:
	show_notification(message, type)

func show_notification(text: String, type: String = "info") -> void:
	if notification_scene:
		var notification = notification_scene.instantiate()
		notification.setup(text, type)
		notification_container.add_child(notification)
		
		# Limit notifications to 5
		while notification_container.get_child_count() > 5:
			notification_container.get_child(0).queue_free()
	else:
		# Fallback if scene not available
		print("[", type.to_upper(), "] ", text)

func format_money(amount: float) -> String:
	if amount >= 1000000:
		return str(snapped(amount / 1000000.0, 0.1)) + "M"
	elif amount >= 1000:
		return str(snapped(amount / 1000.0, 0.1)) + "K"
	else:
		return str(int(amount))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_panel"):
		tab_container.current_tab = (tab_container.current_tab + 1) % tab_container.get_tab_count()
